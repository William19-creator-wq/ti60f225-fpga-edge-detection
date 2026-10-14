"""CO08: independent 2D CFA and public ownership/AXI closure audit.

UNIT scenes explicitly model producer metadata at manager ports; physical image
claims are restricted to the separate real RAW/owner/writer/AXI combination.
"""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def unpack(value, fields):
    data = {}
    for key, width in reversed(fields):
        data[key] = value & ((1 << width)-1)
        value >>= width
    require(value == 0, "packed width")
    return data


CMD = [("op",4),("flags",8),("source",64),("result",64),("origin",195),
       ("cj",142),("body",400),("policy",64)]
REPLY = [("op",4),("status",4),("source",64),("result",64),("origin",195),
         ("cj",142),("body",400),("policy",64),("source_slot",3),("result_slot",2)]


def generate(run, width, height, hd):
    require(4<=width<=1920 and width%2==0 and 2<=height<=1080 and height%2==0,"geometry")
    require(not hd or (width,height)==(1920,1080),"full1080 required")
    path = Path(__file__).resolve().parents[1]/"deps/reference/raw10_color_stream/model/raw_color_reference.py"
    spec = importlib.util.spec_from_file_location("frozen_co_cfa",path)
    math = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(math)
    vectors = [1] if hd else list(range(8))
    for vector in vectors:
        phase, pattern = divmod(vector,2)
        raw = [0 if pattern==0 else (73*x+181*y+211*math.cfa.PATTERNS[phase][y%2][x%2])%1024
               for y in range(height) for x in range(width)]
        body = bytearray()
        for y in range(height):
            for x in range(width):
                rgb = math.cfa.color(math.windows(raw,width,height,x,y),x,y,phase)
                body += bytes((rgb>>16,(rgb>>8)&255,rgb&255))
        body += bytes((-len(body))%64)
        (run/f"vector-{vector}.source.bin").write_bytes(body)
        (run/f"vector-{vector}.raw").write_text("".join(f"{raw[i] | (raw[i+1]<<10):05x}\n" for i in range(0,len(raw),2)),encoding="ascii")
    meta={"width":width,"height":height,"hd":hd,"vectors":vectors,"source_expected_seeded":False,
          "rx_close":"explicit endpoint fixture, not CSI CRC execution",
          "unit_scenes":"pure manager public producer/control fixture; not physical image proof"}
    (run/"input-metadata.json").write_text(json.dumps(meta,indent=2)+"\n",encoding="utf-8")
    print(f"Generated {len(vectors)} independent RAW/CFA images {width}x{height}")


def audit(run):
    meta=json.loads((run/"input-metadata.json").read_text(encoding="utf-8"))
    w,h=meta["width"],meta["height"]
    n,p=w*h,w*h//2;s=((3*n+63)//64)*64
    expected={i:(run/f"vector-{i}.source.bin").read_bytes() for i in meta["vectors"]}
    raw_expected={i:[int(v,16) for v in (run/f"vector-{i}.raw").read_text(encoding="ascii").splitlines()] for i in meta["vectors"]}
    memory=[bytearray([0xA5])*s for _ in range(6)]
    current=None;command=None;write=None;latest=0;next_handle=1
    ledger={};cases=[];counts={};pixels=0;normal_images=0;unit_models=0
    with (run/"capture-events.tsv").open(encoding="utf-8") as stream:
        for line in stream:
            case_s,cycle_s,kind,payload=line.rstrip("\n").split("\t")
            case,cycle=int(case_s),int(cycle_s);v=payload.split();where=f"case{case} cycle{cycle} {kind}"
            counts[kind]=counts.get(kind,0)+1
            if kind=="COLD":
                memory=[bytearray([0xA5])*s for _ in range(6)]
                latest=0;next_handle=1;ledger={};command=write=None
                continue
            if kind=="CASE":
                require(current is None,where+" overlapping case")
                current={"case":case,"type":v[0],"variant":int(v[1]),"raw":0,"cap_jobs":0,"capture_done":None,
                         "rx":None,"eof":False,"eof_ack":False,"end_flags":None,"end_ack":None,
                         "done":None,"grant":None,"cancel_pulses":0,"written":0,"q":False,"open":False,
                         "unit":None,"prior_latest":latest}
                continue
            require(current is not None and current["case"]==case,where+" outside case")
            scene=current["type"]
            vector=current["variant"] if scene in ("NORMAL","STALE","HELD_DONE_Q") else 0
            if kind=="FRAME":
                current["scope"]=int(v[0],16);current["phase"]=int(v[1],16)
                require(current["phase"]==vector//2,where+" phase input")
            elif kind=="OCMD":
                require(command is None,where+" two owner commands")
                c=unpack(int(v[0],16),CMD);command=c
                if c["op"]==0:
                    require(c["source"]==0 and c["flags"]==0 and ((c["origin"]>>67)&((1<<64)-1))==(current["scope"]&((1<<64)-1)),where+" allocation scope")
                elif c["op"] in (1,2):
                    b=current["allocation"]
                    require(c["source"]==b["source"] and c["origin"]==b["origin"],where+" owner Source identity")
                    if c["op"]==1:
                        require(current["eof"] and c["flags"]==0,where+" inferred or premature EOF")
                    else:
                        current["end_flags"]=c["flags"]
                        if c["flags"] in (6,7):
                            require(current["capture_done"] is not None and current["rx"] is not None and write is None,where+" safe END without both actual closures")
                            if c["flags"]==7:
                                cap=current["capture_done"]
                                require(current["eof_ack"] and current["rx"][3]==1 and cap[2]==0 and cap[4:]==[p,p,s//64,0,3*n,s],where+" false successful frame")
                        else:
                            require(c["flags"]==0 and scene=="UNKNOWN",where+" unexpected quarantine")
                else:
                    raise AssertionError(where+" unplanned operation")
            elif kind=="OREPLY":
                require(command is not None,where+" unsolicited owner response")
                c=command;b=unpack(int(v[0],16),REPLY);require(c["op"]==b["op"],where+" owner reply op")
                if c["op"]==0:
                    if b["status"]:
                        require(scene=="DUPLICATE" and b["status"]==4,where+" unexpected rejection")
                        current["rejection"]=b["status"]
                    else:
                        require(b["source"]==next_handle and b["source_slot"]<6,where+" allocator handle/slot")
                        origin=(b["source"]<<131)|((current["scope"]&((1<<64)-1))<<67)|(b["source"]<<3)|b["source_slot"]
                        require(b["origin"]==origin,where+" canonical Origin")
                        next_handle+=1;current["allocation"]=b;ledger[b["source"]]="WRITING"
                elif c["op"]==1:
                    require(b["status"]==0 and ledger[c["source"]]=="WRITING",where+" EOF status/state")
                    ledger[c["source"]]="DRAIN";current["eof_ack"]=True
                else:
                    current["end_ack"]=b["status"]
                    if c["flags"]==0:
                        require(b["status"]==8,where+" UNKNOWN not quarantined")
                        ledger[c["source"]]="Q"
                    else:
                        require(b["status"]==0,where+" safe END failed")
                        ledger[c["source"]]="COMPLETE" if c["flags"]==7 else "BAD"
                        if c["flags"]==7:latest=c["source"]
                command=None
            elif kind=="CAP_JOB":
                b=current["allocation"]
                base,handle,scope,phase=[int(x,16) for x in v]
                require(current["cap_jobs"]==0 and (base,handle,scope,phase)==(b["source_slot"]*0x800000,b["source"],current["scope"],current["phase"]),where+" capjob lacks current canonical allocation")
                current["cap_jobs"]+=1
            elif kind=="GRANT":
                status,handle,origin,scope,phase=[int(x,16) for x in v]
                require(scope==current["scope"] and phase==current["phase"],where+" config snapshot drift")
                if status:
                    require(scene=="DUPLICATE" and status==4 and handle==origin==0 and current["cap_jobs"]==0,where+" reject started producer")
                else:
                    b=current["allocation"]
                    require(current["cap_jobs"]==1 and handle==b["source"] and origin==b["origin"],where+" grant before actual job")
                current["grant"]=(status,handle,origin,scope,phase)
            elif kind=="RAW":
                require(current["grant"] is not None and current["grant"][0]==0,where+" RAW before grant")
                i=current["raw"];handle,data,x,y,markers,bad=int(v[0],16),int(v[1],16),int(v[2]),int(v[3]),int(v[4],16),int(v[5])
                x_expected=2*(i%(w//2));y_expected=i//(w//2)
                expected_markers=int(i==0)|(int(x_expected==w-2)<<1)|(int(i==p-1)<<2)
                require(handle==current["allocation"]["source"] and data==raw_expected[vector][i] and (x,y,markers,bad)==(x_expected,y_expected,expected_markers,0),where+" RAW public formula/order")
                current["raw"]+=1
                if markers&4:current["actual_eof"]=(handle,cycle)
            elif kind=="EOF_HOOK":
                handle,scope=int(v[0],16),int(v[1],16)
                require(current.get("actual_eof")== (handle,cycle) and scope==current["scope"] and not current["eof"],where+" EOF hook not actual RAW fire")
                current["eof"]=True
            elif kind=="RX":
                handle,scope,origin,good=int(v[0],16),int(v[1],16),int(v[2],16),int(v[3])
                b=current["allocation"]
                require(current["grant"] is not None,where+" RX accepted before grant")
                if (handle,scope,origin)==(b["source"],current["scope"],b["origin"]):
                    require(current["rx"] is None,where+" duplicate current close")
                    current["rx"]=(handle,scope,origin,good)
                else:
                    require(scene=="STALE",where+" unexpected stale RX")
            elif kind=="CAP_DONE":
                cap=[int(v[0],16),int(v[1],16),int(v[2],16),int(v[3],16)]+[int(x) for x in v[4:]]
                require(current["capture_done"] is None and cap[0]==current["allocation"]["source"] and cap[1]==current["scope"] and cap[4]==current["raw"] and write is None,where+" actual producer closure/identity")
                current["capture_done"]=cap
                if cap[2]==0:require(cap[4:]==[p,p,s//64,0,3*n,s],where+" producer normal count")
            elif kind=="CAP_CANCEL":
                require(int(v[0],16)==current["allocation"]["source"],where+" wrong Source cancelled")
                current["cancel_pulses"]+=1
                require(current["cancel_pulses"]<=1,where+" cancel repeated")
            elif kind=="CANCEL":
                pass
            elif kind=="WREQ":
                require(write is None and current["cap_jobs"]==1,where+" unowned write")
                b=current["allocation"];address,data=int(v[0],16),int(v[1],16)
                offset=current["written"]*64
                require(address==b["source_slot"]*0x800000+offset and data.to_bytes(64,"little")==expected[vector][offset:offset+64],where+" Source prefix/CFA/tail differs")
                write={"address":address,"data":data,"aw":False,"beats":0,"b":None}
            elif kind=="AW":
                require(write is not None and not write["aw"] and tuple(int(x,16) for x in v)==(write["address"],0,3,4,1),where+" AW ownership/format")
                write["aw"]=True
            elif kind=="W":
                require(write is not None and write["aw"] and write["beats"]<4,where+" W without AW")
                data,strobe,last=int(v[0],16),int(v[1],16),int(v[2])
                require(data==((write["data"]>>(128*write["beats"]))&((1<<128)-1)) and strobe==65535 and last==int(write["beats"]==3),where+" W payload/strobe/LAST")
                slot,offset=divmod(write["address"],0x800000)
                require(slot<6 and offset+64<=s,where+" Source address out of grant")
                start=offset+16*write["beats"]
                memory[slot][start:start+16]=data.to_bytes(16,"little");write["beats"]+=1
            elif kind=="B":
                require(write is not None and write["beats"]==4,where+" B before W close")
                bid,resp=int(v[0],16),int(v[1],16)
                require(bid==0 or scene=="UNKNOWN",where+" wrong B outside unknown scene")
                write["b"]=(bid,resp)
            elif kind=="WRSP":
                require(write is not None and write["b"] is not None,where+" closure without B")
                error,drained=int(v[0]),int(v[1])
                if drained:
                    require(write["b"][0]==0 and error==int(write["b"][1]!=0),where+" false write closure")
                    current["written"]+=1;write=None
                else:require(error==1 and scene=="UNKNOWN",where+" unknown not retained")
            elif kind=="DONE":
                handle,scope,origin,outcome,reason,states,reported_latest=[int(x,16) for x in v]
                b=current["allocation"]
                require(write is None and current["end_ack"]==0 and current["capture_done"] is not None and current["rx"] is not None and current["done"] is None,where+" frame done without actual source END closure")
                require((handle,scope,origin)==(b["source"],current["scope"],b["origin"]) and reported_latest==latest,where+" done identity/latest")
                if outcome==0:
                    require(current["end_flags"]==7 and current["raw"]==p and current["written"]==s//64 and reason==0 and ((states>>(3*b["source_slot"]))&7)==3,where+" normal source not fully complete")
                    require(memory[b["source_slot"]]==expected[vector],where+" full actual Source image/padding differs")
                    pixels+=n;normal_images+=1
                else:
                    require(current["end_flags"]==6 and latest==current["prior_latest"],where+" invalid frame became latest")
                    wanted={"RX_BAD":(1,12),"CANCEL":(2,8),"BRESP":(1,1)}[scene]
                    require((outcome,reason)==wanted,where+" error/cancel priority")
                current["done"]=(outcome,reason)
            elif kind=="OPEN_WAIT":
                require(scene=="EARLY_CLOSED" and current["raw"]<p and current["rx"] is not None and current["capture_done"] is None and current["end_flags"] is None,where+" open frame falsely ended")
                current["open"]=True
            elif kind=="Q":
                require(scene=="UNKNOWN" and current["end_flags"]==0 and current["end_ack"]==8 and current["done"] is None,where+" unknown Source completion")
                current["q"]=True
            elif kind=="UNIT_CHECK":
                k,done,states,unit_latest=int(v[0]),int(v[1]),int(v[2],16),int(v[3],16)
                require(scene=="UNIT" and k==current["variant"] and done==0 and states==[5,5,0,1][k] and unit_latest==0,where+" public manager unit oracle")
                current["unit"]=k;unit_models+=1
            elif kind=="CASE_END":
                require(command is None,where+" unfinished owner operation")
                if scene in ("NORMAL","STALE","HELD_DONE_Q"):
                    require(current["done"]==(0,0),where+" normal frame missing")
                elif scene=="DUPLICATE":
                    require(current["grant"] is not None and current["grant"][0]==4 and not current["cap_jobs"] and current["done"] is None,where+" rejected allocation started")
                elif scene in ("RX_BAD","CANCEL","BRESP"):
                    require(current["done"] is not None,where+" safe failed frame missing")
                elif scene=="UNKNOWN":require(current["q"],where+" Q missing")
                elif scene=="EARLY_CLOSED":require(current["open"],where+" no open wait proof")
                else:require(current["unit"]==current["variant"],where+" unit check missing")
                cases.append({"case":case,"type":scene,"variant":current["variant"]});current=None
            else:raise AssertionError(where+" unknown event")
    metrics=json.loads((run/"capture-metrics.json").read_text(encoding="utf-8"))
    require(current is None and command is None and write is None,"unfinished final obligations")
    sequence=[("NORMAL",1)] if meta["hd"] else ([("NORMAL",i) for i in range(8)]+[("DUPLICATE",0),("STALE",1),("RX_BAD",0),("CANCEL",0),("BRESP",0),("UNKNOWN",0),("NORMAL",0),("EARLY_CLOSED",0),("HELD_DONE_Q",1)]+[("UNIT",i) for i in range(4)])
    require([(c["type"],c["variant"]) for c in cases]==sequence,"scenarios missing/narrowed")
    require(metrics["frames"]==normal_images and metrics["pixels"]==pixels and metrics["passed"]==len(cases) and metrics["unit_cases"]==unit_models,"metrics mismatch")
    for event,metric in [("AW","aw"),("W","w"),("B","b"),("CAP_JOB","cap_jobs"),("CAP_DONE","cap_done"),("DONE","frame_done"),("CAP_CANCEL","cap_cancels")]:require(counts.get(event,0)==metrics[metric],"event counter "+event)
    result={"status":"PASS","actual_raw_owner_cfa_writer_axi_combination":True,"source_not_expected_seeded":True,
            "actual_source_end_driven_by_producer_and_rx_and_eof":True,"source_bytes_padding_and_public_closure_causality_verified":True,
            "rx_crc_physically_verified":False,"unit_models_separate_from_actual_image_proof":True,"unit_cases":unit_models,
            "frames":normal_images,"pixels":pixels,"cases":cases,"event_counts":counts,"actual_ddr_phy_verified":False,
            "events_sha256":hashlib.sha256((run/"capture-events.tsv").read_bytes()).hexdigest().upper()}
    (run/"independent-audit.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"status":"PASS","frames":normal_images,"pixels":pixels,"cases":len(cases),"unit_models":unit_models}))


def main():
    parser=argparse.ArgumentParser();parser.add_argument("command",choices=("generate","audit"));parser.add_argument("run",type=Path)
    parser.add_argument("--width",type=int,default=34);parser.add_argument("--height",type=int,default=20);parser.add_argument("--hd",action="store_true")
    args=parser.parse_args()
    if args.command=="generate":generate(args.run,args.width,args.height,args.hd)
    else:audit(args.run)


if __name__=="__main__":main()
