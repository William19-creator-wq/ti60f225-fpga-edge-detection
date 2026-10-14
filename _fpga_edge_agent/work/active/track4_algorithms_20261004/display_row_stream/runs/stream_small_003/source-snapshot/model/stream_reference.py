"""RS01..06独立数学/实际事件/二进制像素参考，不读取RTL内部状态。"""
import hashlib
import json
import struct
import sys
from pathlib import Path


TICKET = [(k, 64) for k in ("gen", "seq", "scan", "result", "policy")] + [
    ("origin", 195), ("y", 11), ("sy", 11), ("mode", 3), ("mask", 3)]
BUNDLE = [("op", 4), ("status", 4), ("source", 64), ("result", 64), ("origin", 195),
          ("cj", 142), ("body", 400), ("policy", 64), ("source_slot", 3), ("result_slot", 2)]
RECEIPT = [("bank", 2), ("ticket", 543), ("status", 3), ("granted", 1),
           ("outcome", 2), ("reason", 8), ("drained", 1), ("returned", 1),
           ("prepared", 11), ("delivered", 11), ("beats", 32)]
RENDER = [("mode", 3), ("split", 11), ("edge_color", 24), ("ann01", 24),
          ("ann10", 24), ("ann11", 24), ("show_edge", 1), ("show_ann", 1)]


def unpack(value, fields):
    value = int(value, 16) if isinstance(value, str) else value
    d = {}
    for name, width in reversed(fields):
        d[name] = value & ((1 << width)-1)
        value >>= width
    assert value == 0
    return d


def frame_ref(t):
    return (((t["seq"] << 64 | t["result"]) << 64 | t["policy"]) << 195) | t["origin"]


def pixel(x, y, f):
    return ((37*x+11*y+3*f) % 256 << 16) | ((13*x+47*y+7*f) % 256 << 8) | (53*x+19*y+17*f) % 256


def pair(t, a):
    x, y, f = 2*a, t["sy"], (t["origin"] & 7)+1
    color = (pixel(x, y, f) | pixel(x+1, y, f) << 24) if t["mask"] & 1 else 0
    edge = (int((x+y+f) % 3 == 0) | int((x+1+y+f) % 3 == 0) << 1) if t["mask"] & 2 else 0
    ann = ((7*x+3*y+f) % 4 | ((7*(x+1)+3*y+f) % 4) << 2) if t["mask"] & 4 else 0
    return color | edge << 48 | ann << 50


def ranges(t, b, w):
    def aligned(base, start, end):
        return base+start//16*16, base+(end+15)//16*16
    result, sy = [], t["sy"]
    base = 0x03000000 + b["result_slot"]*0x00800000
    if t["mask"] & 2:
        bit = sy*w
        result.append(aligned(base, bit//8, (bit+w+7)//8))
    if t["mask"] & 4:
        bit = sy*w*2
        result.append(aligned(base+0x00100000+4224, bit//8, (bit+2*w+7)//8))
    if t["mask"] & 1:
        result.append(aligned(b["source_slot"]*0x00800000, sy*w*3, (sy+1)*w*3))
    return result


def color(x, y, frame, h):
    mode, b = frame["mode"], frame["b"]
    cfg = unpack(b["body"] & ((1<<112)-1), RENDER)
    sy = 2*(y % (h//2)) if mode == 0 else y
    f = b["source_slot"]+1
    rgb = pixel(x, sy, f)
    gray = (77*(rgb >> 16)+150*((rgb >> 8) & 255)+29*(rgb & 255)+128) >> 8
    edge, ann = (x+sy+f) % 3 == 0, (7*x+3*sy+f) % 4
    if mode == 0: return gray*0x010101 if y < h//2 else (0xffffff if edge else 0)
    if mode == 1: return rgb
    if mode == 2: return gray*0x010101
    if mode == 3: return 0xffffff if edge else 0
    if mode == 5 and cfg["show_ann"] and ann: return cfg[f"ann{ann:02b}"]
    return cfg["edge_color"] if cfg["show_edge"] and edge else rgb


def sha(path):
    with path.open("rb") as f: return hashlib.file_digest(f, "sha256").hexdigest().upper()


def audit(root):
    metrics = json.loads((root/"stream-metrics.json").read_text(encoding="utf-8-sig"))
    assert metrics["finished"] is True
    w, h, p = metrics["width"], metrics["height"], metrics["width"]//2
    frames, jobs, gen, banks = {}, {}, [1]*3, [None]*3
    ar_active = None
    ar_count = r_count = returns = reset_aborted = pauses = 0
    for text in (root/"stream-events.jsonl").open(encoding="utf-8"):
        e = json.loads(text);kind, f = e["event"], e["frame"]
        if kind == "reset":
            assert ar_active is None, "Reset cannot hide AXI obligation"
            reset_aborted += sum(b is not None for b in banks)
            gen, banks = [1]*3, [None]*3
        elif kind == "frame":
            assert f not in frames
            frames[f] = dict(e, b=unpack(e["bundle"], BUNDLE), jobs=[], reserve=[], release=[], returns=[], end=None)
        elif kind == "job":
            t = unpack(e["ticket"], TICKET);b=e["bank"];key=(f,b,t["y"])
            assert key not in jobs and banks[b] is None and t["gen"]==gen[b]
            frame=frames[f];bundle=frame["b"]
            assert (t["result"],t["policy"],t["origin"])==(bundle["result"],bundle["policy"],bundle["origin"])
            assert t["mode"]==frame["mode"] and t["y"] < h
            expected_sy=2*(t["y"]%(h//2)) if t["mode"]==0 else t["y"]
            expected_mask=1 if t["mode"] in (1,2) else 2 if t["mode"]==3 else 3 if t["mode"]==4 else 7
            if t["mode"]==0:expected_mask=1 if t["y"]<h//2 else 2
            assert (t["sy"],t["mask"])==(expected_sy,expected_mask)
            jobs[key]=dict(e,t=t,ars=[],beats=0,receipt=None,reserve=None,release=None,returned=False)
            banks[b]=key;frame["jobs"].append(key)
        elif kind == "ar":
            assert ar_active is None
            j=jobs[(f,e["bank"],e["y"])];a=e["a"];end=a+16*(e["len"]+1)
            assert e["id"]==2 and a%16==0 and 0<=e["len"]<64 and a//4096==(end-1)//4096
            assert any(lo<=a<end<=hi for lo,hi in ranges(j["t"],frames[f]["b"],w))
            j["ars"].append(e);ar_active=dict(job=j,length=e["len"]+1,seen=0);ar_count+=1
        elif kind == "r":
            assert ar_active is not None
            ar_active["seen"]+=1
            assert (e["id"],e["resp"],e["last"])==(2,0,int(ar_active["seen"]==ar_active["length"]))
            ar_active["job"]["beats"]+=1;r_count+=1
            if e["last"]:ar_active=None
        elif kind == "receipt":
            packet=unpack(e["packet"],RECEIPT);t=unpack(packet["ticket"],TICKET);key=(f,packet["bank"],t["y"]);j=jobs[key]
            assert packet["ticket"]==int(j["ticket"],16) and j["receipt"] is None
            assert (packet["status"],packet["granted"],packet["outcome"],packet["drained"],packet["returned"],packet["prepared"],packet["delivered"],packet["beats"])==(0,1,0,1,0,p,p,j["beats"])
            j["receipt"]=packet
        elif kind == "reserve":
            t=unpack(e["ticket"],TICKET);key=(f,e["bank"],t["y"]);j=jobs[key];frame=frames[f]
            assert j["reserve"] is None and e["ticket"]==j["ticket"]
            expected=int(j["ticket"],16) ^ ((1<<479) if frame["fault"]==11 else 0)
            assert int(e["presented"],16)==expected
            assert e["discard"]==int(frame["fault"]==1)
            j["reserve"]=e;frame["reserve"].append(key)
        elif kind == "release":
            t=unpack(e["ticket"],TICKET);key=(f,e["bank"],t["y"]);j=jobs[key];frame=frames[f]
            assert j["release"] is None and j["ticket"]==e["ticket"]
            assert e["requests"]==e["pops"] and e["shown"]<=e["pops"]<=p
            assert e["vc"]-e["last_pixel"]>2
            expected_gen=t["gen"] ^ (1 if frame["fault"]==12 else 0)
            assert int(e["generation"],16)==expected_gen
            consumed=frame["fault"] in (0,8,12,13,14)
            assert e["kind"]==int(not consumed)
            j["release"]=e;frame["release"].append(key)
        elif kind == "return":
            t=unpack(e["ticket"],TICKET);b=e["bank"];key=(f,b,t["y"]);j=jobs[key]
            assert not j["returned"] and banks[b]==key and j["release"] is not None
            assert e["ticket"]==j["ticket"] and e["kind"]==j["release"]["kind"]
            assert int(j["release"]["generation"],16)==t["gen"]==gen[b]
            gen[b]+=1;banks[b]=None;j["returned"]=True;returns+=1;frames[f]["returns"].append(key)
        elif kind == "frame_end":
            assert frames[f]["end"] is None;frames[f]["end"]=e
        elif kind == "scope":
            ref=int(e["ref"],16)
            expected_frame=unpack(frames[f]["demand0"],TICKET[1:])
            assert ref==frame_ref(expected_frame),"Query must equal the frame input identity, not an old implicit function value"
            expected=int(any(k is not None and frame_ref(jobs[k]["t"])==ref for k in banks))
            assert e["live"]==e["expected"]==expected
        elif kind == "video_pause":
            assert frames[f]["fault"]==14 and e["edges"]==200;pauses+=1
        else:raise AssertionError(kind)
    assert ar_active is None and len(frames)==metrics["frames"]
    total_slots=total_pops=total_pixels=total_shown=0
    hashes=[]
    for fid,frame in frames.items():
        fault=frame["fault"];end=frame["end"];assert end is not None
        normal=fault==0
        count=(p+140)*(h+45) if normal else p
        assert end["slots"]==end["output_slots"]==count
        expected_q=int(fault in (11,12,15,16))
        assert end["q"]==expected_q
        assert len(frame["jobs"])==(h if normal else 1)
        assert len(frame["reserve"])==len(frame["jobs"])
        assert len(frame["release"])==(len(frame["jobs"]) if fault not in (11,15,16) else 0)
        assert len(frame["returns"])==(len(frame["jobs"]) if not expected_q else 0)
        pops={key:[] for key in frame["jobs"]}
        native=root/f"native-{fid}.bin";data=native.read_bytes();assert len(data)%14==0
        for bank,visible,y,a,word in struct.iter_unpack("<BBHHQ",data):
            key=(fid,bank,y);j=jobs[key]
            assert a==len(pops[key]) and a<p and word==pair(j["t"],a)
            assert visible in (0,1);pops[key].append(visible)
        actual_native=[0]*3;actual_visible=[0]*3
        for key,flags in pops.items():
            j=jobs[key];b=key[1];actual_native[b]+=len(flags);actual_visible[b]+=sum(flags)
            if j["release"]:
                assert len(flags)==j["release"]["pops"] and sum(flags)==j["release"]["shown"]
            if normal:assert flags==[1]*p
            elif fault in (8,12,13,14):assert flags==[1]*p
            elif fault in (3,4,5,6,7):assert flags[:p//2]==[1]*(p//2) and not any(flags[p//2:])
            else:assert not any(flags)
            expected=ranges(j["t"],frame["b"],w);plane=0;cursor=expected[0][0]
            for ar in j["ars"]:
                assert ar["a"]==cursor
                cursor+=16*(ar["len"]+1);assert cursor<=expected[plane][1]
                if cursor==expected[plane][1]:
                    plane+=1
                    if plane<len(expected):cursor=expected[plane][0]
            assert plane==len(expected)
        assert actual_native==end["pops"] and actual_visible==end["shown"]
        if not expected_q:assert end["requests"]==end["pops"]
        raw=root/f"frame-{fid}.bin";image=raw.read_bytes();assert len(image)==12*count
        cutoff=p//2
        for slot,(rgb,x,y,flags) in enumerate(struct.iter_unpack("<6sHHH",image)):
            if normal:
                v,c=divmod(slot,p+140);de=int(v<h and c<p)
                xx,yy=(2*c,v) if de else (0,0)
                hs=int(p+44<=c<p+66);vs=int(h+4<=v<h+9);start=int(slot==0);error=0
                visible=bool(de)
            else:
                xx,yy=2*slot,0;de=int(not(fault==7 and slot==cutoff));hs=vs=0;start=int(slot==0)
                visible=fault in (8,12,13,14) or (fault in (3,4,5,6,7) and slot<cutoff)
                error=0 if visible or not de else (3 if fault in (5,6,11,15,16) else 1)
            expected_flags=de|hs<<1|vs<<2|start<<3|error<<4
            expected_rgb=(color(xx,yy,frame,h)|color(xx+1,yy,frame,h)<<24) if visible else 0
            assert (x,y,flags,int.from_bytes(rgb,"little"))==(xx,yy,expected_flags,expected_rgb),(fid,slot,"output mismatch",x,y,flags,int.from_bytes(rgb,"little"),xx,yy,expected_flags,expected_rgb)
            total_pixels+=2*de
        total_slots+=count;total_pops+=sum(actual_native);total_shown+=sum(actual_visible)
        hashes.append(dict(frame=fid,output_sha256=sha(raw),native_sha256=sha(native),output_slots=count))
    assert total_slots==metrics["slots"] and total_pops==metrics["native_pops"]
    assert sum(sum(fr["end"]["requests"]) for fr in frames.values())==metrics["native_requests"]
    assert metrics["writes"]==len(jobs)*p and returns==metrics["returns"]
    result=dict(status="PASS",frames=len(frames),normal_frames=6,fault_frames=metrics["fault_frames"],
                width=w,height=h,time_slots=total_slots,active_pixels=total_pixels,native_pops=total_pops,
                visible_native_pairs=total_shown,native_requests=metrics["native_requests"],writes=metrics["writes"],
                ar=ar_count,r=r_count,actual_returns=returns,reset_aborted_rows=reset_aborted,
                retained_quarantined_rows=sum(b is not None for b in banks),
                video_pauses=pauses,full54_and_rgb_control_verified=True,same_bundle_continuous_frames_verified=True,
                owner_handoff_join_verified=False,actual_ddr_verified=False,physical_cdc_verified=False,
                hardware_verified=False,full_project_goal_complete=False,events_sha256=sha(root/"stream-events.jsonl"),binary_traces=hashes)
    (root/"reference-result.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in result.items() if k!="binary_traces"}))


if __name__=="__main__":audit(Path(sys.argv[1]))
