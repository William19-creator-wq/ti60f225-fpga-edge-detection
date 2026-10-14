"""FT-T01…10：固定种子输入、独立期望、原始观察审核。失败不改变种子。"""
import argparse
import hashlib
import json
import random
from pathlib import Path
from fit_reference import (KINDS,INPUT_FIELDS,field,packed,encode_request,evaluate,response,
                           rne_root,rne_div,crc_bits,rational_distance,primitive_reference)

def write_json(path,value):
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest().upper()

def statistics(points,width,height,tls=False):
    if tls:
        centered=[(2*x-(width-1),2*y-(height-1)) for x,y,*_ in points]
        return (len(centered),sum(x for x,y in centered),sum(y for x,y in centered),
                sum(x*x for x,y in centered),sum(y*y for x,y in centered),sum(x*y for x,y in centered))
    rows=[(gy,-gx,gy*x-gx*y) for x,y,gx,gy in points]
    return (len(rows),sum(a*a for a,b,d in rows),sum(a*b for a,b,d in rows),
            sum(b*b for a,b,d in rows),sum(a*d for a,b,d in rows),sum(b*d for a,b,d in rows))

def source_request(lfsr,sequence):
    """按批准中文来源重建622位源；不调用RTL生成器或读取DUT中间值。"""
    kind=(11,12,13,14,15,17,18,14)[sequence&7]
    def pixel(low,limit):
        raw=field(lfsr,low,11)
        return raw-limit if raw>=limit else raw
    x,y=pixel(0,1920),pixel(11,1080)
    if sequence&8:
        values=[]; low=0
        for bits,signed in INPUT_FIELDS[kind]: values.append(field(lfsr,low,bits,signed)); low+=bits
        if kind in (11,17,12,18):
            n=values[0]; n=n-2073600 if n>2073600 else n
            values[0]=max(n,3 if kind in (11,17) else 2)
        if kind in (13,14):
            for index,low in ((0,0),(1,32))+(((3,82),(4,114)) if kind==13 else ()):
                magnitude=field(lfsr,low,30); values[index]=-magnitude if field(lfsr,low+31,1) else magnitude
        if kind==14: values[3:]=[pixel(82,1920),pixel(93,1080)]
        if kind==15: values[4:]=[pixel(72,1920),pixel(83,1080)]
    elif kind in (11,17):
        g=1+field(lfsr,0,5); xc=1+field(lfsr,5,10); yc=1+field(lfsr,15,9); g2=g*g
        values=[3,2*g2,g2,2*g2,g2*(2*xc+yc),g2*(xc+2*yc)]
        if kind==11: values.append(0)
    elif kind in (12,18):
        a=2*field(lfsr,0,6)+1; b=2*field(lfsr,6,6)+1
        if field(lfsr,12,1): b=-b
        values=[2,0,0,2*a*a,2*b*b,2*a*b]
        if kind==12: values.append(0)
    elif kind==13: values=[1<<30,0,16*x,0,1<<30,16*y]
    elif kind==14: values=[1<<30,0,16*field(lfsr,22,10),x,y]
    else:
        ax=x if x!=1919 else 1918
        values=[16*ax,16*y,16*(ax+1),16*y,pixel(32,1920),pixel(43,1080)]
    return encode_request(kind,values,sequence=sequence)

def generate(root):
    root.mkdir(parents=True,exist_ok=False)
    vectors=[]; descriptions=[]
    def add(label,kind,values,**kwargs):
        request=encode_request(kind,values,sequence=len(vectors),**kwargs)
        vectors.append((request,evaluate(request)))
        descriptions.append({"index":len(vectors)-1,"label":label,"kind":kind})
    bases={11:(3,5,1,10,10,24,0),17:(3,5,1,10,10,24),
           12:(3,-7,-2,35,20,14,0),18:(3,-7,-2,35,20,14),
           13:(1<<30,0,16,0,1<<30,32),14:(1<<30,0,16,2,3),15:(0,0,1,0,1,0)}
    for kind in KINDS:
        add("normal",kind,bases[kind])
        for change in ({"width":5},{"height":4},{"version":2},{"owner":1},{"flags":1},{"target":1},{"padding":1}):
            add("format_first_error",kind,bases[kind],**change)
        if kind in (11,17,12,18):
            for n in (0,1,2,3,2073600,2073601): add("count",kind,(n,)+bases[kind][1:])
    add("ls_diag_geometry",11,(3,2,0,1,16384,0,0))
    add("ls_diag_valid",17,(3,2,0,1,16384,0))
    add("tls_diag_geometry",12,(2,3000000,0,4500000000001,0,0,0))
    add("tls_diag_valid",18,(2,3000000,0,4500000000001,0,0))
    for b in (-3,0,1,2,3):
        for threshold in (0,49150,49151,49152,65535): add("ls_delta_condition",11,(3,2,b,2,6,6,threshold))
    for stats in ((2,0,0,0,0,0),(2,1,0,0,0,0),(2,0,0,2,2,3),(2,0,0,2,2,0),
                  (2,0,0,2,0,0),(2,0,0,0,2,0),(2,0,0,2,8,-4)):
        for threshold in (0,32767,65535): add("tls_psd_direction",12,stats+(threshold,))
    for nx,ny in ((0,0),(1,0),((1<<29)-1,0),(1<<29,0),(1<<30,0),(-(1<<30),0),
                  ((1<<30)+1,0),(0,1<<30)):
        add("normal_k",14,(nx,ny,-131072,0,0))
        add("normal_k_intersect",13,(nx,ny,131071,0,1<<30,-131072))
    add("line_minus_correction",14,(715827872,-1,-1,0,1),width=6,height=5)
    add("line_plus_correction",14,(860054527,41448,-2,0,4),width=6,height=5)
    add("finite_fraction_1_5",15,(0,-1,1,1,0,0),width=6,height=5)
    add("finite_fraction_1_2",15,(0,-1,1,0,0,0),width=6,height=5)
    for edge in ((0,0,0,0),(-131072,-131072,131071,131071),(0,0,1,0),(0,0,16,0)):
        for x,y in ((0,0),(1,0),(0,1),(1919,1079)): add("finite_extreme_endpoint",15,edge+(x,y))
    # 缓存顺序：第五个key替换、不同rho/job，TLS安装后距离；期望每次独立重算。
    for repeat in range(3):
        for nx,ny in ((1<<30,0),(0,1<<30),(-(1<<30),0),(0,-(1<<30)),(1<<29,1<<29)):
            add("cache_replacement",14,(nx,ny,16*repeat,repeat,repeat))
    for kind,seed in ((11,20261011),(12,20261012)):
        rng=random.Random(seed)
        for index in range(512):
            count=rng.randrange(3 if kind==11 else 2,65)
            coords=rng.sample(range(2073600),count)
            points=[(p%1920,p//1920,rng.randrange(-1020,1021),rng.randrange(-1020,1021)) for p in coords]
            for j,(x,y,gx,gy) in enumerate(points):
                if gx==gy==0: points[j]=(x,y,1,0)
            stat=statistics(points,1920,1080,tls=kind==12)
            add("real_point_statistics",kind,stat+(0,))
            add("real_point_diagnostic",17 if kind==11 else 18,stat)
    rng=random.Random(20261014)
    for index in range(512):
        stat=(rng.randrange(3,2073601),(1<<42)|rng.getrandbits(42),rng.randrange(-(1<<41),(1<<41)),
              (1<<42)|rng.getrandbits(42),rng.randrange(-(1<<55),(1<<55)),rng.randrange(-(1<<55),(1<<55)))
        add("wide_ls",11,stat+(0,)); add("wide_ls_diag",17,stat)
    rng=random.Random(20261015)
    for index in range(512):
        a,b=rng.randrange(1,1<<21),rng.randrange(1,1<<21)
        if rng.getrandbits(1): b=-b
        stat=(rng.randrange(2,2073601),0,0,a*a,b*b,a*b)
        add("wide_tls_psd",12,stat+(0,)); add("wide_tls_diag",18,stat)
    for kind,count,seed in ((13,2048,20261016),(14,4096,20261017),(15,4096,20261018)):
        rng=random.Random(seed)
        for index in range(count):
            width,height=(6,5) if index%2 else (1920,1080)
            def unit():
                while True:
                    nx,ny=rng.randrange(-(1<<30),(1<<30)+1),rng.randrange(-(1<<30),(1<<30)+1)
                    if nx*nx+ny*ny>=(1<<58): return nx,ny
            if kind==13: values=(*unit(),rng.randrange(-131072,131072),*unit(),rng.randrange(-131072,131072))
            elif kind==14: values=(*unit(),rng.randrange(-131072,131072),rng.randrange(width),rng.randrange(height))
            else: values=tuple(rng.randrange(-131072,131072) for _ in range(4))+(rng.randrange(width),rng.randrange(height))
            add("random_geometry",kind,values,width=width,height=height)
    vector_path=root/"numeric.tsv"
    vector_path.write_text("".join(f"{request:0156x} {expected:0147x}\n" for request,expected in vectors),encoding="ascii")
    write_json(root/"manifest.json",{"count":len(vectors),"vectors_sha256":sha(vector_path),"cases":descriptions,
                                    "seeds":[20261011,20261012,20261014,20261015,20261016,20261017,20261018]})
    cache_inputs=[(14,(1<<30,0,3,2,4)),(14,(1<<30,0,3,2,4)),(14,(1<<30,0,4,3,5)),
                  (12,(2,0,0,2,2,2,0)),(14,(-759250330,759250330,0,2,4))]
    directed=[]
    for index,(kind,values) in enumerate(cache_inputs):
        request=encode_request(kind,values,sequence=1100000+index)
        if index==2: request=(request&~(((1<<32)-1)<<32))|(5<<32)
        directed.append((request,evaluate(request)))
    (root/"cache-directed.tsv").write_text("".join(f"{req:0156x} {rsp:0147x}\n" for req,rsp in directed),encoding="ascii")
    print(json.dumps({"vectors":len(vectors),"sha256":sha(vector_path)}))

def input_probes():
    assert rational_distance(1,2,19)==1 and rational_distance(1,5,19)==0
    for kind,stats in ((11,(3,5,1,10,10,24,0)),(17,(3,5,1,10,10,24)),(18,(3,-7,-2,35,20,14))):
        rsp=evaluate(encode_request(kind,stats,width=6,height=5))
        assert field(rsp,190,2)==0
        if kind==11: assert (field(rsp,200,18,1),field(rsp,218,18,1))==(25,36)
        if kind==18: assert field(rsp,221,16)==32768
    for kind,values,q in ((14,(715827872,-1,-1,0,1),1),(14,(860054527,41448,-2,0,4),3)):
        assert field(evaluate(encode_request(kind,values,width=6,height=5)),200,21)==q
    for bad in ((11,(1<<21,2,0,2,0,0,0)),(14,(1<<31,0,0,0,0))):
        try: encode_request(*bad)
        except ValueError: pass
        else: raise AssertionError("representation guard")
    print("PASS independent hand examples and representation probes")

def audit_core(root):
    manifest=json.loads((root/"vectors/manifest.json").read_text(encoding="utf-8"))
    rows=(root/"numeric-observed.tsv").read_text(encoding="ascii").splitlines()
    if len(rows)!=manifest["count"]: raise AssertionError("numeric observation count")
    max_cycles=0; counts={}
    for row in rows:
        req,rsp,cycles,calls= row.split()
        req,rsp=int(req,16),int(rsp,16)
        if rsp!=evaluate(req): raise AssertionError(f"independent mismatch {req:x}")
        max_cycles=max(max_cycles,int(cycles)); kind=field(req,206,5)
        counts[kind]=counts.get(kind,0)+1
        limits={11:17,12:46,13:17,14:22,15:26,17:7,18:20}
        if int(calls)>limits[kind] or int(cycles)>16384: raise AssertionError("execution budget")
    protocol=json.loads((root/"core-result.json").read_text(encoding="utf-8"))
    if not protocol["finished"] or protocol["errors"]: raise AssertionError("protocol suite")
    ledger=audit_transactions(root)
    write_json(root/"core-audit.json",{"status":"PASS","count":len(rows),"counts":counts,"max_forming_cycles":max_cycles,
                                      "numeric_file_sha256":sha(root/"numeric-observed.tsv"),"protocol":protocol,"independent_ledger":ledger})
    print(f"PASS core audit {len(rows)} max_forming={max_cycles}")

def audit_transactions(root):
    events=[]
    priority={"A":0,"C":1,"Q":2,"R":3,"B":4,"L":5,"Z":6,"J":7}
    for domain,name in (("outer_fit","outer-events.tsv"),("private_scalar","private-events.tsv")):
        for line in (root/name).read_text(encoding="ascii").splitlines():
            fields=line.split(); events.append((int(fields[1]),priority[fields[0]],domain,fields))
    events.sort(key=lambda event:(event[0],event[1]))
    outer={}; child={}; canceled=set(); sequence=0
    accepted=consumed=reset_count=child_accepted=child_consumed=child_reset=0
    last_child={}; bridge_results=0; local_writes=0
    for cycle,_,domain,parts in events:
        operation=parts[0]
        if domain=="outer_fit":
            body=int(parts[2],16); identity=field(body,0,176)
            if operation=="A":
                if outer: raise AssertionError("overlapping outer obligations")
                outer[identity]=body; accepted+=1
            elif operation=="C":
                if identity not in outer: raise AssertionError("cancel without matching owner")
                if int(parts[3]): canceled.add(identity)
            elif operation=="R":
                request=outer.pop(identity)
                expected=response(request,3,0) if identity in canceled else evaluate(request)
                if body!=expected: raise AssertionError("independent outer event result")
                canceled.discard(identity); consumed+=1
            elif operation=="Z":
                outer.pop(identity); canceled.discard(identity); reset_count+=1
                stale=[key for key,(owner,_) in child.items() if owner==identity]
                child_reset+=len(stale)
                for key in stale: child.pop(key)
                sequence=0; last_child.clear()
            elif operation=="J":
                if outer or child: raise AssertionError("quiet joint reset with live obligation")
                sequence=0; last_child.clear()
        elif operation in ("Q","R"):
            owner=int(parts[3],16); body=int(parts[5],16); identity=field(body,0,176)
            if owner not in outer: raise AssertionError("private operation outlived owner")
            if operation=="Q":
                if child: raise AssertionError("two private child obligations")
                if (field(identity,0,32),field(identity,32,32),field(identity,64,32),field(identity,96,8))!=(1,0,1,0): raise AssertionError("private execution domain")
                if field(identity,104,64)!=sequence or field(identity,168,8)>15: raise AssertionError("private sequence/destination")
                sequence+=1; child[identity]=(owner,body); child_accepted+=1
            else:
                accepted_owner,request=child.pop(identity)
                if owner!=accepted_owner: raise AssertionError("private outer mapping")
                if field(body,190,2)==3:
                    if owner not in canceled or body!=response(request,3,0): raise AssertionError("unexplained private DROP")
                elif body!=primitive_reference(request): raise AssertionError("independent primitive response")
                child_consumed+=1; last_child[owner]=body
        elif operation=="B":
            owner=int(parts[2],16); result=int(parts[5],16)
            if owner not in outer: raise AssertionError("bridge result without live parent")
            if owner in last_child:
                raw=last_child[owner]
                value=field(raw,200,385); reason=field(raw,192,8); outcome=field(raw,190,2)
                destination=field(raw,168,8)
                expected=destination | outcome<<8 | reason<<10 | value<<18
                dropped=destination | 3<<8
                if result!=expected and not(owner in canceled and result==dropped): raise AssertionError("independent bridge cache")
            elif not(owner in canceled and field(result,8,2)==3 and field(result,10,393)==0):
                raise AssertionError("bridge result without child or cancellation")
            bridge_results+=1
        elif operation=="L":
            owner=int(parts[2],16)
            if owner not in outer or owner in canceled: raise AssertionError("local write after cancellation")
            local_writes+=1
    if outer or child or accepted!=consumed+reset_count or child_accepted!=child_consumed+child_reset:
        raise AssertionError("independent obligation ledger not closed")
    return {"outer_accepted":accepted,"outer_consumed":consumed,"outer_reset_aborted":reset_count,
            "child_accepted":child_accepted,"child_consumed":child_consumed,"child_reset_aborted":child_reset,
            "bridge_results":bridge_results,"local_writes":local_writes}

def audit_probe(root):
    rows=(root/"probe-observed.tsv").read_text(encoding="ascii").splitlines()
    if len(rows)!=1056: raise AssertionError("probe 1024 + reset32 count")
    lfsr=1; sequence=0; crc=0xffffffff; outcomes={}
    for index,row in enumerate(rows):
        if index==1024: lfsr=1; sequence=0; crc=0xffffffff
        req,rsp,observed_crc=row.split(); req,rsp=int(req,16),int(rsp,16)
        if req!=source_request(lfsr,sequence): raise AssertionError(f"probe source {index}")
        if rsp!=evaluate(req): raise AssertionError(f"probe response {index}")
        crc=crc_bits(crc,rsp)
        if int(observed_crc,16)!=crc: raise AssertionError(f"probe CRC {index}")
        feedback=field(lfsr,383,1)^field(lfsr,382,1)^field(lfsr,380,1)^field(lfsr,377,1)
        lfsr=((lfsr<<1)|feedback)&((1<<384)-1); sequence+=1
        outcome=field(rsp,190,2); outcomes[outcome]=outcomes.get(outcome,0)+1
    write_json(root/"probe-audit.json",{"status":"PASS","count":len(rows),"outcomes":outcomes,"final_crc":f"{crc:08x}"})
    print("PASS 1056 source/request/response/585-bit CRC")

if __name__=="__main__":
    parser=argparse.ArgumentParser(); parser.add_argument("action",choices=("input-probes","generate","audit-core","audit-probe")); parser.add_argument("path",nargs="?")
    args=parser.parse_args()
    if args.action=="input-probes": input_probes()
    elif args.action=="generate": generate(Path(args.path))
    elif args.action=="audit-core": audit_core(Path(args.path))
    else: audit_probe(Path(args.path))
