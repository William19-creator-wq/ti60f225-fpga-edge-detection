"""PF01..07 独立事件审计：公开packed协议/字节地址/实际握手；不读RTL状态。"""
import hashlib
import json
import sys
from pathlib import Path


def unpack(value, fields):
    value = int(value, 16)
    result = {}
    for name, width in reversed(fields):
        result[name] = value & ((1 << width) - 1)
        value >>= width
    assert value == 0, "Packed width overflow"
    return result


TICKET = [(n, 64) for n in ("gen", "seq", "scan", "result", "policy")] + [
    ("origin", 195), ("y", 11), ("sy", 11), ("mode", 3), ("mask", 3)]
BUNDLE = [("op", 4), ("status", 4), ("source", 64), ("result", 64),
          ("origin", 195), ("cj", 142), ("body", 400), ("policy", 64),
          ("source_slot", 3), ("result_slot", 2)]


def pixel(x, y, f):
    return ((37*x + 11*y + 3*f) % 256 << 16) | (
        (13*x + 47*y + 7*f) % 256 << 8) | (53*x + 19*y + 17*f) % 256


def pair(t, address):
    x, y, f = address * 2, t["sy"], (t["origin"] & 7) + 1
    rgb = pixel(x, y, f) | pixel(x+1, y, f) << 24 if t["mask"] & 1 else 0
    edge = int((x+y+f) % 3 == 0) | int((x+1+y+f) % 3 == 0) << 1 if t["mask"] & 2 else 0
    ann = (7*x+3*y+f) % 4 | ((7*(x+1)+3*y+f) % 4) << 2 if t["mask"] & 4 else 0
    return rgb | edge << 48 | ann << 50


def spans(t, b, w):
    base = 0x03000000 + b["result_slot"] * 0x00800000
    def aligned(addr, start, end):
        return addr + start // 16 * 16, addr + (end+15) // 16 * 16
    ranges = []
    if t["mask"] & 2:
        bit = t["sy"] * w
        ranges.append(aligned(base, bit//8, (bit+w+7)//8))
    if t["mask"] & 4:
        bit = t["sy"] * w * 2
        ranges.append(aligned(base+0x00100000+4224, bit//8, (bit+2*w+7)//8))
    if t["mask"] & 1:
        start = t["sy"] * w * 3
        ranges.append(aligned(b["source_slot"]*0x00800000, start, start+3*w))
    return ranges


def byte_at(addr, b, w, h):
    n = w*h
    if addr < 0x03000000:
        slot, offset = addr//0x00800000, addr % 0x00800000
        if slot < 6 and offset < 3*n:
            p, channel = divmod(offset, 3)
            color = pixel(p % w, p//w, slot+1)
            return (color >> (16-8*channel)) & 255
    elif addr < 0x04800000:
        slot, offset = divmod(addr-0x03000000, 0x00800000)
        assert slot == b["result_slot"], "Reading another result"
        f = b["source_slot"] + 1
        if offset < (n+7)//8:
            return sum(int(((offset*8+i) % w + (offset*8+i)//w + f) % 3 == 0) << i
                       for i in range(8) if offset*8+i < n)
        map_offset = offset - 0x00100000 - 4224
        if 0 <= map_offset < (n+3)//4:
            return sum(((7*((map_offset*4+i) % w) + 3*((map_offset*4+i)//w) + f) % 4) << (2*i)
                       for i in range(4) if map_offset*4+i < n)
    return 0xE5


RECEIPT = [("bank", 2), ("ticket", 543), ("status", 3), ("granted", 1),
           ("outcome", 2), ("reason", 8), ("drained", 1), ("returned", 1),
           ("prepared", 11), ("delivered", 11), ("beats", 32)]


def frame_ref(t):
    return (((t["seq"] << 64 | t["result"]) << 64 | t["policy"]) << 195) | t["origin"]


def audit(root):
    metrics = json.loads((root/"protocol-metrics.json").read_text(encoding="utf-8-sig"))
    assert metrics["finished"] is True
    w, h, p = metrics["width"], metrics["height"], metrics["width"]//2
    start = int(metrics["initial_generation"], 16)
    generations, refs, exhausted = [start]*3, [None]*3, [False]*3
    jobs, counts = {}, {"write": 0, "read": 0, "ar": 0, "r": 0, "queries": 0}
    for line in (root/"fetch-events.jsonl").open(encoding="utf-8"):
        e = json.loads(line)
        if e["event"] == "reset":
            generations, refs, exhausted = [start]*3, [None]*3, [False]*3
            continue
        c, kind = e["case"], e["event"]
        if kind == "job":
            t = unpack(e["ticket"], TICKET)
            expected_gen = generations[e["bank"]] if e["bank"] < 3 else 0
            assert t["gen"] == expected_gen, "Test request expectation failed actual return GEN ledger"
            jobs[c] = dict(e, t=t, b=unpack(e["bundle"], BUNDLE), ars=[], active=None, responses=0,
                           writes=[], reads=[], receipt=None, core_receipt=None, claimed=False,
                           granted=False, publish=0, abort=0, abort_return=0, returned=0)
            continue
        j = jobs[c]
        if kind == "claim":
            assert not j["claimed"]
            assert int(e["request"], 16) == (j["bank"] << 479 | (int(j["ticket"], 16) & ((1<<479)-1)))
            j["claimed"] = True
        elif kind == "grant":
            assert not j["granted"] and e["ticket"] == j["ticket"]
            bank = j["bank"]
            assert bank < 3 and refs[bank] is None and not exhausted[bank]
            refs[bank] = frame_ref(j["t"]);j["granted"] = True
        elif kind == "ar":
            assert j["active"] is None and j["granted"]
            assert e["id"] == 2 and 0 <= e["len"] < 64 and e["address"] % 16 == 0
            end = e["address"] + 16*(e["len"]+1)
            assert e["address"]//4096 == (end-1)//4096
            assert any(a <= e["address"] < end <= b for a, b in spans(j["t"], j["b"], w))
            j["ars"].append(e);j["active"] = dict(e, index=0);counts["ar"] += 1
        elif kind == "r":
            ar = j["active"];assert ar is not None
            index = ar["index"]
            expected_id = 3 if j["fault"] == 2 and index == 0 else 2
            expected_resp = 2 if j["fault"] == 1 and index == 0 else 0
            expected_last = int(index == ar["len"])
            if j["fault"] == 3 and index == 0: expected_last = 1
            if j["fault"] == 4: expected_last = int(index == ar["len"]+1)
            assert (e["id"], e["resp"], e["last"]) == (expected_id, expected_resp, expected_last)
            data = sum(byte_at(ar["address"]+16*index+i, j["b"], w, h) << (8*i) for i in range(16))
            if j["fault"] == 4 and index == ar["len"]+1: data = 0
            assert int(e["data"], 16) == data
            ar["index"] += 1;j["responses"] += 1;counts["r"] += 1
            if index == ar["len"]+int(j["fault"] == 4): j["active"] = None
        elif kind in ("write", "read"):
            bucket = "writes" if kind == "write" else "reads"
            assert j["granted"] and e["address"] == len(j[bucket]) and e["address"] < p
            assert int(e["data"], 16) == pair(j["t"], e["address"])
            j[bucket].append(e["data"]);counts[kind] += 1
        elif kind in ("publish", "abort"):
            assert j["active"] is None and j["granted"]
            j[kind] += 1
        elif kind in ("abort_return", "return"):
            assert e["ticket"] == j["ticket"] and e["kind"] == int(kind == "abort_return")
            bank = j["bank"]
            assert j["granted"] and refs[bank] == frame_ref(j["t"]) and generations[bank] == j["t"]["gen"]
            refs[bank] = None
            if generations[bank] == (1<<64)-1: exhausted[bank] = True
            else: generations[bank] += 1
            if kind == "return": j["returned"] += 1
            else: j["abort_return"] += 1
        elif kind in ("core_receipt", "receipt"):
            packet = unpack(e["packet"], RECEIPT)
            assert packet["bank"] == j["bank"] and packet["ticket"] == int(j["ticket"], 16)
            assert (packet["status"], packet["outcome"]) == (j["expect_status"], j["expect_outcome"])
            assert packet["granted"] == int(j["granted"])
            if kind == "core_receipt":
                assert j["core_receipt"] is None;j["core_receipt"] = e["packet"];j["claimed"] = False
            else:
                assert j["receipt"] is None and e["packet"] == j["core_receipt"]
                j["receipt"] = packet
        elif kind == "query":
            ref = int(e["ref"], 16)
            expected = int(ref in refs or any(x["claimed"] and frame_ref(x["t"]) == ref for x in jobs.values()))
            assert e["live"] == expected == e["expected"]
            counts["queries"] += 1
        else: raise AssertionError(f"Unknown event {kind}")
    for j in jobs.values():
        d = j["receipt"];assert d is not None
        if d["status"]:
            assert not j["ars"] and not j["writes"] and not j["granted"]
            assert d["drained"] == 1 and d["returned"] == d["prepared"] == d["delivered"] == d["beats"] == 0
        elif d["outcome"] == 0:
            assert d["prepared"] == d["delivered"] == p and d["drained"] == 1 and not d["returned"]
            assert len(j["reads"]) == p and j["publish"] == 1 and j["returned"] == 1 and j["active"] is None
            expected = spans(j["t"], j["b"], w);plane=0;cursor=expected[0][0]
            for ar in j["ars"]:
                assert ar["address"] == cursor
                cursor += 16*(ar["len"]+1);assert cursor <= expected[plane][1]
                if cursor == expected[plane][1]:
                    plane += 1
                    if plane < len(expected): cursor=expected[plane][0]
            assert plane == len(expected) and d["beats"] == j["responses"]
        elif d["outcome"] in (1, 2):
            assert d["drained"] == d["returned"] == 1 and j["active"] is None
            assert j["abort"] == j["abort_return"] == 1 and not j["publish"] and not j["reads"]
            assert d["beats"] == j["responses"]
        else:
            assert d["drained"] == d["returned"] == j["publish"] == j["abort"] == j["abort_return"] == 0
        assert d["delivered"] == len(j["writes"]) and d["prepared"]-d["delivered"] in (0, 1)
    assert len(jobs) == metrics["cases"] and counts["read"]*2 == metrics["read_pixels"]
    result=dict(status="PASS",cases=len(jobs),**counts,initial_generation=f"{start:016X}",
                actual_return_gen_verified=True,full615_echo_verified=True,
                actual_ddr_verified=False,full_scan_handoff_join_verified=False,hardware_verified=False,
                events_sha256=sha(root/"fetch-events.jsonl"))
    (root/"reference-result.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result))


def sha(path):
    with path.open("rb") as stream: return hashlib.file_digest(stream,"sha256").hexdigest().upper()


if __name__ == "__main__": audit(Path(sys.argv[1]))
