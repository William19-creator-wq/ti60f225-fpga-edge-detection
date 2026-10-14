"""AW08 independent oracle: public transactions -> actual bytes -> authorized rows.

Source/EDGE are declared fixtures. ANN starts poisoned and is changed only by
observed AXI W. No private RTL arrays or generated RTL expected outputs are read.
"""
import argparse
import hashlib
import json
from pathlib import Path


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def unpack(value, fields):
    result = {}
    for name, width in reversed(fields):
        result[name] = value & ((1 << width) - 1)
        value >>= width
    require(value == 0, "packed value exceeds public width")
    return result


REPLY = [("op", 4), ("status", 4), ("source", 64), ("result", 64),
         ("origin", 195), ("cj", 142), ("body", 400), ("policy", 64),
         ("source_slot", 3), ("result_slot", 2)]
CMD = [("op", 4), ("flags", 8), ("source", 64), ("result", 64),
       ("origin", 195), ("cj", 142), ("body", 400), ("policy", 64)]
DEMAND = [("sequence", 64), ("scan", 64), ("result", 64), ("policy", 64),
          ("origin", 195), ("target_y", 11), ("source_y", 11), ("mode", 3), ("mask", 3)]
TICKET = [("generation", 64)] + DEMAND


def align(n, a=64):
    return (n + a - 1) // a * a


def desc(base, length):
    return (base << 64) | (length << 32) | align(length)


def label(i, pattern, source_slot, width):
    if pattern == 0:
        return 3
    if pattern == 1:
        return 0
    if pattern == 2:
        return (i % width + 2 * (i // width) + source_slot) % 4
    return 2 if i % 17 == 0 else 0


def rgb_byte(slot, offset, width):
    pixel, channel = divmod(offset, 3)
    y, x = divmod(pixel, width)
    f = slot + 1
    return [(37*x+11*y+3*f), (13*x+47*y+7*f), (53*x+19*y+17*f)][channel] % 256


def edge(i, width):
    return int((7*(i % width)+3*(i // width)) % 9 < 2)


def header_bytes(index, pattern, case):
    return bytes(((index*64+b)*37+index*11+pattern*17+case*3) % 256 for b in range(64))


def expected_ann(width, height, pattern, source_slot, case):
    n = width * height
    image = bytearray(align(4224+(n+3)//4))
    for block in range(66):
        image[64*block:64*block+64] = header_bytes(block, pattern, case)
    for i in range(n):
        image[4224+i//4] |= label(i, pattern, source_slot, width) << (2*(i % 4))
    return image


def canonical(b, width, height):
    n = width*height
    sb = b["source_slot"] * 0x800000
    rb = 0x3000000 + b["result_slot"] * 0x800000
    body = (desc(sb, 3*n) << 304) | (desc(rb, (n+7)//8) << 208) | (desc(rb+0x100000, 4224+(n+3)//4) << 112)
    origin = b["origin"]
    cj = b["cj"]
    return (b["op"] == 3 and b["status"] == 0 and b["source"] != 0 and b["result"] != 0 and
            b["policy"] != 0 and b["source_slot"] < 6 and b["result_slot"] < 3 and
            origin >> 131 == b["source"] and (origin >> 3) & ((1 << 64)-1) == b["source"] and
            origin & 7 == b["source_slot"] and cj & ((1 << 64)-1) == (origin >> 67) & ((1 << 64)-1) and
            (cj >> 96) & 2047 == width and (cj >> 107) & 2047 == height and
            (cj >> 118) & 2047 <= (cj >> 129) & 2047 and
            b["body"] >> 112 == body >> 112 and (b["body"] >> 109) & 7 == 5 and
            (b["body"] >> 98) & 2047 == height//2)


def span_plan(start, stop):
    address = start // 16 * 16
    end = align(stop, 16)
    plan = []
    while address < end:
        beats = min(64, (end-address)//16, (4096-(address % 4096))//16)
        plan.append((address, 2, beats-1, 4, 1))
        address += beats*16
    return plan


def audit(run):
    meta = json.loads((run/"input-metadata.json").read_text(encoding="utf-8"))
    width, height = meta["width"], meta["height"]
    n, p = width*height, width*height//2
    ann_size = align(4224+(n+3)//4)
    ann = [bytearray([0xA5])*ann_size for _ in range(3)]
    sources, results = {}, {}
    latest_source = 0
    active_result = 0
    pending_command = None
    pending_write = None
    pending_read = None
    row = None
    recent_lookup = None
    current = None
    all_cases = []
    event_counts = {}
    total_pixels = 0

    def physical_byte(address):
        if address < 0x3000000:
            slot, offset = divmod(address, 0x800000)
            require(slot < 6 and offset < align(3*n), "Source read outside fixture")
            return rgb_byte(slot, offset, width) if offset < 3*n else 0
        slot, offset = divmod(address-0x3000000, 0x800000)
        require(slot < 3, "Result read slot out of range")
        if offset < align((n+7)//8):
            return sum(edge(8*offset+b, width) << b for b in range(8) if 8*offset+b < n)
        require(0x100000 <= offset < 0x100000+ann_size, "ANN read outside allocation")
        return ann[slot][offset-0x100000]

    with (run/"annotation-events.tsv").open(encoding="utf-8") as stream:
        for line in stream:
            case_s, cycle_s, kind, payload = line.rstrip("\n").split("\t")
            case, cycle = int(case_s), int(cycle_s)
            v = payload.split()
            event_counts[kind] = event_counts.get(kind, 0) + 1
            where = f"case {case} cycle {cycle} {kind}"
            if kind == "COLD":
                ann = [bytearray([0xA5])*ann_size for _ in range(3)]
                sources, results = {}, {}
                latest_source = active_result = 0
                pending_command = pending_write = pending_read = row = recent_lookup = None
                continue
            if kind == "CASE":
                require(current is None, where+" unfinished case")
                current = {"case": case, "type": v[0], "variant": int(v[1]), "headers": [], "pixels": [],
                           "header_success": 0, "body_success": 0, "acks": [], "done": None, "q": False, "rows": 0}
                continue
            if kind == "OCMD":
                require(pending_command is None, where+" overlapping owner command")
                pending_command = (unpack(int(v[0], 16), CMD), int(v[1], 16), cycle)
                continue
            if kind == "OREPLY":
                require(pending_command is not None, where+" unsolicited owner reply")
                c, sequence, _ = pending_command
                b = unpack(int(v[0], 16), REPLY)
                require(b["op"] == c["op"] and b["status"] == 0, where+" owner identity/status")
                op = c["op"]
                if op == 0:
                    require(b["source"] not in sources, where+" reused Source handle")
                    require(b["origin"] >> 131 == b["source"] and b["origin"] & 7 == b["source_slot"], where+" Source origin")
                    sources[b["source"]] = {"state": "WRITING", "bundle": b}
                elif op in (1, 2):
                    s = sources[c["source"]]
                    require(s["bundle"]["origin"] == c["origin"], where+" Source scope")
                    if op == 1:
                        require(s["state"] == "WRITING", where+" EOF state")
                        s["state"] = "DRAIN"
                    else:
                        require(s["state"] == "DRAIN" and c["flags"] == 7, where+" fixture Source closure")
                        s["state"] = "COMPLETE"
                        latest_source = c["source"]
                elif op == 3:
                    require(canonical(b, width, height) and b["source"] == latest_source and sources[b["source"]]["state"] == "COMPLETE", where+" allocated canonical complete source")
                    require(b["result"] not in results, where+" reused Result handle")
                    results[b["result"]] = {"state": "WORKING", "bundle": b, "raw": int(v[0], 16), "sequence": 0}
                elif op == 4:
                    r = results[c["result"]]
                    require(r["state"] == "WORKING" and c["flags"] == 7 and current["done"] is not None and current["done"][3] == 0 and pending_write is None, where+" publication without actual normal writer closure")
                    r["state"] = "DONE"
                elif op == 5:
                    r = results[c["result"]]
                    require(r["state"] == "DONE" and sequence != 0, where+" offer before result completion")
                    r["state"] = "OFFERED";r["sequence"] = sequence
                elif op == 6:
                    r = results[c["result"]]
                    require(r["state"] == "OFFERED", where+" apply without offer")
                    if active_result:
                        results[active_result]["state"] = "RETIRING"
                    active_result = c["result"];r["state"] = "DISPLAY"
                elif op == 8:
                    r = results[c["result"]]
                    require(r["state"] == "RETIRING" and c["flags"] == 10 and pending_read is None and row is None, where+" retire with outstanding read")
                    r["state"] = "FREE"
                elif op == 7:
                    r = results[c["result"]]
                    require(r["state"] == "WORKING" and c["flags"] == 6 and pending_write is None, where+" unsafe drop")
                    r["state"] = "FREE"
                else:
                    raise AssertionError(where+" unplanned owner command")
                pending_command = None
                continue
            if kind == "SOURCE_FIXTURE":
                continue
            require(current is not None and current["case"] == case, where+" event outside current case")
            pattern = current["variant"] if current["type"] == "NORMAL" else 2
            if kind == "JOB":
                b = unpack(int(v[0], 16), REPLY)
                current["job"] = b
                require(canonical(b, width, height) == (current["type"] != "CONFIG"), where+" independent config result")
                if current["type"] != "CONFIG":
                    require(results[b["result"]]["state"] == "WORKING" and b == results[b["result"]]["bundle"], where+" writer start not fresh allocation")
            elif kind == "ACK":
                error = int(v[0]);current["acks"].append(error)
                require(error == int(current["type"] == "CONFIG"), where+" wrong config ack")
            elif kind == "HEADER":
                b = current["job"];ordinal = len(current["headers"])
                handle, index, data = int(v[0], 16), int(v[1]), int(v[2], 16)
                require(data.to_bytes(64, "little") == header_bytes(ordinal, pattern, case), where+" header input formula")
                current["headers"].append((handle, index, data))
                if current["type"] == "NORMAL":
                    require(handle == b["result"] and index == ordinal, where+" normal header identity")
            elif kind == "PIXEL":
                b = current["job"];ordinal = len(current["pixels"])
                handle, index, data, last = int(v[0], 16), int(v[1]), int(v[2], 16), int(v[3])
                require(current["header_success"] == 66, where+" body accepted before all header responses")
                expected = label(2*ordinal, pattern, b["source_slot"], width) | (label(2*ordinal+1, pattern, b["source_slot"], width) << 2)
                require(data == expected, where+" body input formula")
                current["pixels"].append((handle, index, data, last))
                if current["type"] == "NORMAL":
                    require(handle == b["result"] and index == ordinal and last == int(ordinal == p-1), where+" normal body identity")
            elif kind == "WREQ":
                require(pending_write is None, where+" overlapping write ownership")
                b = current["job"];address, data = int(v[0], 16), int(v[1], 16)
                base = 0x3100000+b["result_slot"]*0x800000
                if current["header_success"] < 66:
                    index = current["header_success"]
                    require(len(current["headers"]) == index+1, where+" header request without input")
                    handle, actual_index, saved_data = current["headers"][-1]
                    require(handle == b["result"] and actual_index == index, where+" invalid header wrote")
                    require(address == base+64*index and data == saved_data, where+" header request mapping")
                    phase = "header"
                else:
                    first = current["body_success"]*128
                    chunk = current["pixels"][first:first+128]
                    require(chunk and (len(chunk) == 128 or first+len(chunk) == p), where+" prematurely written partial body")
                    require(all(item[0] == b["result"] and item[1] == first+j and item[3] == int(first+j == p-1) for j, item in enumerate(chunk)), where+" invalid body wrote")
                    expected = sum(item[2] << (4*j) for j, item in enumerate(chunk))
                    require(address == base+4224+64*(first//128) and data == expected, where+" body packing/tail")
                    phase = "body"
                pending_write = {"address": address, "data": data, "phase": phase, "aw": False, "beats": 0, "b": None}
            elif kind == "AW":
                require(pending_write is not None and not pending_write["aw"], where+" AW has no unique RPC owner")
                require(tuple(int(x, 16) for x in v) == (pending_write["address"], 0, 3, 4, 1), where+" AW grant/format")
                pending_write["aw"] = True
            elif kind == "W":
                q = pending_write
                require(q is not None and q["aw"] and q["beats"] < 4, where+" W without AW")
                data, strobe, last = int(v[0], 16), int(v[1], 16), int(v[2])
                require(data == ((q["data"] >> (128*q["beats"])) & ((1 << 128)-1)) and strobe == 65535 and last == int(q["beats"] == 3), where+" W payload/strobe/LAST")
                slot, offset = divmod(q["address"]-0x3100000, 0x800000)
                require(0 <= slot < 3 and 0 <= offset <= ann_size-64, where+" write outside ANN allocation")
                start = offset+16*q["beats"]
                ann[slot][start:start+16] = data.to_bytes(16, "little")
                q["beats"] += 1
            elif kind == "B":
                require(pending_write is not None and pending_write["beats"] == 4, where+" B before W closure")
                bid, resp = int(v[0], 16), int(v[1], 16)
                require(bid == 0 or current["type"] == "UNKNOWN", where+" unexpected B identity")
                pending_write["b"] = (bid, resp)
            elif kind == "WRSP":
                q = pending_write
                require(q is not None and q["b"] is not None, where+" logical closure without B")
                error, drained = int(v[0]), int(v[1])
                if drained:
                    require(q["b"][0] == 0 and error == int(q["b"][1] != 0), where+" response error/closure")
                    if not error:
                        current[q["phase"]+"_success"] += 1
                    pending_write = None
                else:
                    require(error == 1 and current["type"] == "UNKNOWN", where+" unsafe closure was accepted")
            elif kind == "DONE":
                b = current["job"]
                done = [int(v[0],16),int(v[1],16),int(v[2],16),int(v[3]),int(v[4],16)] + [int(x) for x in v[5:]]
                require(pending_write is None and current["done"] is None, where+" duplicate/unsafe DONE")
                require(done[:3] == [b["result"],b["cj"] & ((1 << 96)-1),b["origin"]] and done[5:] == [current["header_success"],len(current["pixels"]),current["body_success"],1], where+" DONE counts/identity")
                if current["type"] == "NORMAL":
                    require(done[3:5] == [0,0] and len(current["headers"]) == 66 and len(current["pixels"]) == p and current["body_success"] == (p+127)//128, where+" incomplete normal image")
                    expected = expected_ann(width,height,pattern,b["source_slot"],case)
                    require(ann[b["result_slot"]] == expected, where+" actual full annotation bytes differ")
                current["done"] = done
            elif kind == "LOOKUP":
                d = unpack(int(v[0],16),DEMAND);permitted = int(v[1]);raw = int(v[2],16)
                r = results.get(d["result"])
                expected = bool(r and r["state"] in ("OFFERED","DISPLAY","RETIRING") and
                    d["sequence"] == r["sequence"] != 0 and d["scan"] != 0 and d["policy"] == r["bundle"]["policy"] and
                    d["origin"] == r["bundle"]["origin"] and d["mode"] == 5 and d["mask"] == 7 and
                    0 <= d["target_y"] < height and d["source_y"] == d["target_y"])
                require(permitted == int(expected), where+" independent ledger permission")
                expected_raw = ((r["raw"] & ((1 << 938)-1)) | (5 << 938)) if expected else 0
                require(raw == expected_raw, where+" lookup descriptor authority")
                recent_lookup = (d,permitted,raw)
            elif kind == "ROW":
                require(row is None and pending_read is None and pending_write is None and recent_lookup is not None, where+" row borrow collision")
                t = unpack(int(v[0],16),TICKET);b = unpack(int(v[1],16),REPLY)
                require({k:t[k] for k,_ in DEMAND} == recent_lookup[0] and int(v[2]) == recent_lookup[1] == 1 and int(v[1],16) == recent_lookup[2], where+" row lacks actual matching lookup")
                start = t["source_y"]*width
                rb = 0x3000000+b["result_slot"]*0x800000
                plan = span_plan(rb+start//8,rb+(start+width+7)//8)
                plan += span_plan(rb+0x100000+4224+start//4,rb+0x100000+4224+(start+width+3)//4)
                sb = b["source_slot"]*0x800000
                plan += span_plan(sb+3*start,sb+3*(start+width))
                row = {"ticket":t,"bundle":b,"plan":plan,"ar":0,"pairs":0,"returned":set(),"beats":0}
            elif kind == "AR":
                require(row is not None and pending_read is None and row["ar"] < len(row["plan"]), where+" unsolicited/extra AR")
                ar = tuple(int(x,16) for x in v)
                require(ar == row["plan"][row["ar"]], where+" nonminimal row span/4KiB split")
                row["ar"] += 1
                pending_read = {"address":ar[0],"id":ar[1],"count":ar[2]+1,"index":0}
            elif kind == "R":
                q = pending_read
                require(q is not None and row is not None, where+" R without AR")
                rid,resp,last,data = int(v[0],16),int(v[1],16),int(v[2]),int(v[3],16)
                address = q["address"]+q["index"]*16
                expected_data = bytes(physical_byte(address+i) for i in range(16))
                require(rid == q["id"] and resp == 0 and last == int(q["index"] == q["count"]-1) and data.to_bytes(16,"little") == expected_data, where+" R causality/data/identity/LAST")
                row["returned"].update(range(address,address+16));row["beats"] += 1;q["index"] += 1
                if last:pending_read=None
            elif kind == "PAIR":
                require(row is not None, where+" pair without row")
                t,b = row["ticket"],row["bundle"]
                generation,address,data = int(v[0],16),int(v[1]),int(v[2],16)
                require(generation == t["generation"] and address == row["pairs"], where+" pair order/identity")
                pixel = t["source_y"]*width+address*2
                sb = b["source_slot"]*0x800000
                rb = 0x3000000+b["result_slot"]*0x800000
                needed = set(range(sb+3*pixel,sb+3*pixel+6)) | {rb+pixel//8,rb+0x100000+4224+pixel//4}
                require(needed <= row["returned"], where+" pair produced before actual bytes returned")
                rgb0 = sum(rgb_byte(b["source_slot"],3*pixel+c,width) << (8*(2-c)) for c in range(3))
                rgb1 = sum(rgb_byte(b["source_slot"],3*pixel+3+c,width) << (8*(2-c)) for c in range(3))
                a = label(pixel,pattern,b["source_slot"],width) | (label(pixel+1,pattern,b["source_slot"],width) << 2)
                expected = rgb0 | (rgb1 << 24) | ((edge(pixel,width) | (edge(pixel+1,width) << 1)) << 48) | (a << 50)
                require(data == expected, where+" independent pixel result")
                row["pairs"] += 1;total_pixels += 2
            elif kind == "RDONE":
                require(row is not None and pending_read is None and row["ar"] == len(row["plan"]) and row["pairs"] == width//2, where+" premature row close")
                require([int(x) for x in v] == [0,0,1,width//2,width//2,row["beats"]], where+" row terminal counters")
                current["rows"] += 1;row=None
            elif kind == "Q":
                require(current["type"] == "UNKNOWN" and current["done"] is None and pending_write is not None, where+" false quarantine")
                current["q"] = True
            elif kind == "CANCEL":
                pass
            elif kind == "CASE_END":
                require(current["acks"] == [int(current["type"] == "CONFIG")], where+" missing/duplicate ACK")
                if current["type"] == "NORMAL":
                    require(current["rows"] == height and current["done"] is not None, where+" full frame not read")
                elif current["type"] == "CONFIG":
                    require(not current["headers"] and not current["pixels"] and current["done"] is None, where+" rejected config performed work")
                elif current["type"] == "UNKNOWN":
                    require(current["q"] and current["done"] is None, where+" UNKNOWN produced safe completion")
                else:
                    k=current["variant"]
                    expected_outcome = 1 if k in (0,1,2,3,4,9,10,13) else 2
                    expected_reason = 2 if k in (0,1) else 4 if k in (2,3,4) else 8 if k in (9,10,13) else 0
                    require(current["done"] is not None and current["done"][3:5] == [expected_outcome,expected_reason], where+" protocol error/cancel priority")
                all_cases.append({"case":case,"type":current["type"],"variant":current["variant"],"rows":current["rows"]})
                current=None
            else:
                raise AssertionError(where+" unknown event")

    metrics=json.loads((run/"annotation-metrics.json").read_text(encoding="utf-8"))
    require(current is None and pending_command is None and pending_write is None and pending_read is None and row is None,"unfinished final obligations")
    expected_cases = [("NORMAL",2)] if meta["hd"] else ([('NORMAL',x) for x in (0,0,1,2,3)] + [('CONFIG',x) for x in range(10)] + [('PROTOCOL',x) for x in range(15)] + [('UNKNOWN',0),('UNKNOWN',1),('NORMAL',1)])
    require([(c["type"],c["variant"]) for c in all_cases] == expected_cases,"scenario list missing or narrowed")
    require(metrics["pixels"] == total_pixels and metrics["rows"] == sum(c["rows"] for c in all_cases) and metrics["passed"] == len(all_cases),"metrics mismatch")
    for event,metric in [('AW','aw'),('W','w'),('B','b'),('AR','ar'),('R','r'),('LOOKUP','queries')]:
        require(event_counts.get(event,0) == metrics[metric],"physical event metrics mismatch "+event)
    result={"status":"PASS","independent_public_bus_audit":True,"actual_axi_ann_writes":True,"ann_expected_not_preseeded":True,"all_header_body_and_padding_bytes_compared":True,"owner_lookup_authoritative":True,"exact_minimal_row_ar_spans_and_byte_causality":True,"fixture_source_edge":True,"actual_ddr_phy_verified":False,"complex_recognition_verified":False,"cases":all_cases,"pixels":total_pixels,"event_counts":event_counts,"events_sha256":hashlib.sha256((run/"annotation-events.tsv").read_bytes()).hexdigest().upper()}
    (run/"independent-audit.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"status":"PASS","pixels":total_pixels,"cases":len(all_cases),"rows":metrics["rows"]}))


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("command",choices=("generate","audit"))
    parser.add_argument("run",type=Path)
    parser.add_argument("--width",type=int,default=34)
    parser.add_argument("--height",type=int,default=20)
    parser.add_argument("--hd",action="store_true")
    args=parser.parse_args()
    if args.command == "generate":
        require(4<=args.width<=1920 and args.width%2==0 and 2<=args.height<=1080 and args.height%2==0,"unsupported geometry")
        require(not args.hd or (args.width,args.height)==(1920,1080),"HD must be full1080p")
        meta={"width":args.width,"height":args.height,"hd":args.hd,"source_edge":"declared formula fixtures","annotation":"poisoned; actual AXI W only"}
        (args.run/"input-metadata.json").write_text(json.dumps(meta,indent=2)+"\n",encoding="utf-8")
    else:
        audit(args.run)


if __name__ == "__main__":
    main()
