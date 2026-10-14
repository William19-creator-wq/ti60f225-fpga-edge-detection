"""RA-T1..7: independent full bus event ledger; no DUT hierarchy or internals."""
from pathlib import Path
import csv, json, hashlib, sys

def number(bits):
    return int(bits, 2) if set(bits) <= {"0", "1"} else None

def bit(vector, port):
    return number(vector[-1-port])

def ar_fields(bits):
    return tuple(number(bits[a:b]) for a,b in ((0,32),(32,36),(36,44),(44,47),(47,49)))

def legal(bits, port):
    addr,rid,length,size,burst=ar_fields(bits)
    return None not in (addr,rid,length,size,burst) and rid == (2 if port==0 else 0) and size==4 and burst==1 and addr%16==0 and (length<=63 if port==0 else length==3) and addr+16*(length+1)<=0x10000000 and addr%4096+16*(length+1)<=4096

def memory_word(address):
    return int.from_bytes(bytes(((address+i)*37+11)%256 for i in range(16)), "little")

def audit(directory):
    root=Path(directory); pending=None; active=None; credit=3; q=False; reason=0
    counters={"cycles":0,"physical_ar":0,"physical_r":0,"full128_words":0,"rst_rows":0,"reset_aborted_bursts":0,"ar_stall_rows":0,"r_stall_rows":0,"zero_delay_ar_r_rows":0,"resp_error_words":0,"four_state_fault_rows":0}
    grants={}; cases=set(); fault_cases={}; last_ar=None; last_r=None
    with (root/"read-events.tsv").open(encoding="utf-8",newline="") as f:
        for row in csv.DictReader(f,delimiter="\t"):
            case=int(row["case"]);cases.add(case);cycle=int(row["cycle"])
            def check(condition,message):
                if not condition: raise AssertionError(f"case {case} cycle {cycle}: {message}")
            check(cycle==counters["cycles"],"missing/duplicate trace cycle");counters["cycles"]+=1
            rst=number(row["rst"]);enable=number(row["enable"])
            cav=row["cav"];car=row["car"];ca=[row["ca0"],row["ca1"]]
            mav=number(row["mav"]);mar=number(row["mar"]);mrv=number(row["mrv"]);mrr=number(row["mrr"])
            mr=row["mr"];crv=row["crv"];crr=row["crr"]
            check(row["cr0"]==mr and row["cr1"]==mr,"full135 return bus changed")
            if rst:
                check(not mav and not mrr and number(car)==0 and number(crv)==0,"handshake enabled in reset")
                if active is not None:counters["reset_aborted_bursts"]+=1
                pending=None;active=None;credit=3;q=False;reason=0;last_ar=None;last_r=None;counters["rst_rows"]+=1
                continue
            check(number(row["q"])==int(q) and int(row["reason"])==reason,"wrong quarantine/first reason")
            check(number(row["occupied"])==int(pending is not None or active is not None or q),"unknown occupancy erased")
            check(number(row["idle"])==int(pending is None and active is None and not q),"false idle")
            if q:fault_cases[case]=reason
            check(mav==int(pending is not None),"AR valid timing")
            expected_ready=0 if pending is None else (mar<<pending[0])
            check(number(car)==expected_ready,"AR ready assigned to wrong client")
            if pending is not None:check(row["ma"]==pending[1],"full49 held AR changed")
            expected_rvalid=0 if active is None else (mrv<<active["port"])
            expected_rready=0 if active is None else bit(crr,active["port"])
            check(number(crv)==expected_rvalid and mrr==expected_rready,"R routing/ready differs")
            if last_ar is not None:check(mav==1 and row["ma"]==last_ar,"AR withdrawn while stalled")
            if last_r is not None:check(mrv==1 and mr==last_r,"test slave withdrew held R")
            last_ar=row["ma"] if mav and not mar else None
            last_r=mr if mrv and not mrr else None
            if mav and not mar:counters["ar_stall_rows"]+=1
            if mrv and not mrr:counters["r_stall_rows"]+=1
            af=bool(mav and mar);rf=bool(mrv and mrr)
            candidate=None
            if pending is None and active is None and not q and enable and (bit(cav,0)==1 or bit(cav,1)==1):
                port=0 if bit(cav,0)==1 and not(bit(cav,1)==1 and credit==0) else 1
                candidate=(port,ca[port])
            fault=0
            if candidate is not None and not legal(candidate[1],candidate[0]):fault=1
            elif pending is not None and (bit(cav,pending[0])!=1 or ca[pending[0]]!=pending[1]):fault=2
            elif rf and number(mr[128:132])!=active["id"]:fault=3
            elif rf and number(mr[-1:])!=int(active["remaining"]==1):fault=4
            elif active is None and mrv and not af:fault=5
            if "x" in cav or "x" in ca[0] or "x" in ca[1]:counters["four_state_fault_rows"]+=1
            if af:
                check(active is None and pending is not None,"extra physical AR without owner")
                port,body=pending;addr,rid,length,size,burst=ar_fields(body)
                active={"port":port,"id":rid,"address":addr,"remaining":length+1,"data_index":0};pending=None
                credit=3 if port==1 else max(0,credit-1)
                grants.setdefault(case,[]).append(port);counters["physical_ar"]+=1
                if mrv:counters["zero_delay_ar_r_rows"]+=1
            if rf:
                check(active is not None,"physical R consumed without owner")
                check(number(mr[:128])==memory_word(active["address"]+16*active["data_index"]),"full128 data/address/beat mismatch")
                active["data_index"]+=1;counters["physical_r"]+=1;counters["full128_words"]+=1
                if number(mr[132:134])!=0:counters["resp_error_words"]+=1
                if not q and not fault:
                    active["remaining"]-=1
                    if active["remaining"]==0:active=None
            if candidate is not None and legal(candidate[1],candidate[0]):pending=candidate
            if fault and not q:q=True;reason=fault
    metrics=json.loads((root/"read-result.json").read_text(encoding="utf-8"))
    assert metrics["finished"] is True and metrics["cycles"]==counters["cycles"]
    assert metrics["physical_ar"]==counters["physical_ar"] and metrics["physical_r"]==counters["physical_r"]
    assert metrics["cases"]==26 and set(range(1,27))<=cases
    assert grants[1]==[0,0,0,1]*8 and grants[4]==[0,0,0,1]*8
    assert len(grants[2])==64 and set(grants[2])=={0} and len(grants[3])==32 and set(grants[3])=={1}
    assert fault_cases=={**{i:1 for i in range(10,17)},17:3,18:4,19:4,20:5,21:2,22:2,26:1},fault_cases
    assert counters["full128_words"]>2500 and counters["ar_stall_rows"]>100 and counters["r_stall_rows"]>100
    assert counters["zero_delay_ar_r_rows"]>=1 and counters["resp_error_words"]>0 and counters["four_state_fault_rows"]>0
    assert q and active is None and pending is None and reason==1
    result={"status":"PASS","full_bus_cycle_and_event_ledger":True,"cases":26,"counts":counters,"fair_grant_patterns":{"case1":grants[1],"case4":grants[4]},"fault_cases":fault_cases,"trace_sha256":hashlib.sha256((root/"read-events.tsv").read_bytes()).hexdigest().upper(),"actual_ddr_verified":False,"physical_cdc_verified":False,"actual_leaf_integration_verified":False,"full_project_goal_complete":False}
    (root/"read-audit.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8");print(json.dumps(result,ensure_ascii=False))

if __name__=="__main__":
    if len(sys.argv)!=3 or sys.argv[1]!="audit":raise SystemExit("usage: read_arbiter_reference.py audit RUN_DIR")
    audit(sys.argv[2])
