"""S07：有限场景、严格解析、实际probe事务独立数学/CRC复核。"""
import argparse
import hashlib
import json
import random
from pathlib import Path
from scalar_reference import encode_request, evaluate, field, crc_bits, MASK192, MAX_TARGET


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest().upper()


def parse_hex(text, bits):
    if not text or any(c not in "0123456789abcdefABCDEF" for c in text):
        raise ValueError("non-hex input")
    value = int(text, 16)
    if value >= 1 << bits:
        raise ValueError(f"value exceeds {bits} bits")
    return value


def make_vectors(output):
    output.mkdir(parents=True, exist_ok=False)
    rng = random.Random(20261006)
    rows, index = [], []

    def add(group, kind, a=0, b=0, **kw):
        ordinal = len(rows)
        req = encode_request(kind, a, b, sequence=ordinal, **kw)
        expect = evaluate(req)
        gap, stall = ordinal % 3, ordinal % 32
        rows.append(f"{req:0156x} {expect:0147x} {gap} {stall}\n")
        index.append(dict(case_id=f"{group}-{ordinal:05d}", group=group, ordinal=ordinal,
                          kind=kind, outcome=field(expect,190,2), reason=field(expect,192,8)))

    for kind in range(8):
        for a, b in [(0,0), (1,1), (2,1), (17,3), (MASK192,1), (1<<191,MASK192)]:
            add("SC-01",kind,a,0 if kind in (4,7) else b)
    patterns = [0,1,65535,1<<191,MASK192,int("ffff0000"*6,16)]
    for flags in range(4):
        for a in patterns:
            for b in patterns:
                add("SC-02",0,a,b,a_signed=flags&1,b_signed=flags>>1)
    for bit in (0,15,16,31,32,175,176,191):
        add("SC-02",0,1<<bit,MASK192)
    for kind in (1,2):
        for flags in range(4):
            for a in (0,1,(1<<191)-1,1<<191,MASK192):
                for b in (0,1,MASK192):
                    for target in (1,2,191,192,193,194):
                        add("SC-03",kind,a,b,a_signed=flags&1,b_signed=flags>>1,target=target)
    for a in (-5,-3,-1,0,1,3,5):
        add("SC-04",3,a,2,a_signed=1)
    for kind in (3,6):
        for a in (0,1,2,3,5,7,MASK192,1<<191):
            for b in (1,2,3,(1<<191)-1,MASK192):
                add("SC-04",kind,a,b)
    add("SC-04",3,-(1<<191),1,a_signed=1)
    for root in (0,1,2,3,65535,1<<48,(1<<96)-1):
        for a in (root*root-1,root*root,root*root+1):
            if 0 <= a <= MASK192:
                for kind in (4,7):
                    add("SC-05",kind,a)
    for kind in (4,7):
        for a in (2,3,8,15,16,MASK192):
            for target in (1,96,97):
                add("SC-05",kind,a,target=target)
    for flags in range(4):
        for a in patterns[:5]:
            for b in patterns[:5]:
                add("SC-06",5,a,b,a_signed=flags&1,b_signed=flags>>1)
    add("SC-06",5,1,2,target=1)
    add("SC-06",5,1,2,target=3)
    for kw in (dict(width=0),dict(width=5),dict(width=7),dict(width=1921),
               dict(height=0),dict(height=4),dict(height=1081),dict(version=0),
               dict(version=2),dict(owner=1),dict(target=0),dict(target=386),dict(padding=1)):
        add("SC-07",0,1,2,**kw)
    add("SC-07",0,1,2,width=0,version=0,owner=1,target=0,padding=1)
    for kind in range(8,32):
        add("SC-07",kind,1,2,target=0)
    for kind in (4,6,7):
        add("SC-07",kind,1,0 if kind in (4,7) else 2,a_signed=1)
        add("SC-07",kind,1,0 if kind in (4,7) else 2,b_signed=1)
    for kind in (4,7):
        add("SC-07",kind,1,1)
        add("SC-07",kind,1,padding=1)
    add("SC-07",3,1,0)
    add("SC-07",6,1,0)
    add("SC-07",3,1,-1,b_signed=1)
    add("SC-07",3,1,0,padding=1)
    add("SC-07",0,1,2,width=6,height=5)

    def random_case(group, kind, full_target):
        a, b = rng.getrandbits(192), rng.getrandbits(192)
        sa, sb = rng.randrange(2), rng.randrange(2)
        if kind in (4,7):
            b, sa, sb = 0,0,0
        elif kind == 6:
            sa, sb, b = 0,0,b|1
        elif kind == 3:
            b = (b & ((1<<191)-1))|1 if sb else b|1
        target = MAX_TARGET[kind] if full_target or kind == 5 else rng.randint(1,MAX_TARGET[kind])
        add(group,kind,a,b,a_signed=sa,b_signed=sb,target=target)

    for kind in range(8):
        for sample in range(256):
            random_case("SC-08",kind,sample%2==0)
    rng.seed(20261008)
    for sample in range(10000):
        random_case("SC-12",sample%8,True)
    vector_path = output/"core.txt"
    vector_path.write_text("".join(rows),encoding="ascii",newline="\n")
    # 协议fixture的数学值同样由oracle生成；TB只覆盖时间/取消/复位。
    fixtures=[]
    for kind in range(8):
        request=encode_request(kind,MASK192,0 if kind in (4,7) else MASK192,
                               sequence=100000+kind)
        fixtures.append(f"{request:0156x} {evaluate(request):0147x}\n")
    (output/"fixtures.txt").write_text("".join(fixtures),encoding="ascii",newline="\n")
    manifest=dict(schema_version=1,seed=20261006,stress_seed=20261008,cases=index,
                  count=len(rows),vector_sha256=digest(vector_path),
                  fixture_sha256=digest(output/"fixtures.txt"),
                  reference_sha256=digest(Path(__file__).with_name("scalar_reference.py")))
    (output/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf-8")
    return manifest


def audit_core(directory):
    vectors=directory/"vectors"
    expected=[]
    for line in (vectors/"core.txt").read_text(encoding="ascii").splitlines():
        columns=line.split()
        if len(columns)!=4:
            raise ValueError("vector columns")
        req,resp=parse_hex(columns[0],622),parse_hex(columns[1],585)
        if evaluate(req)!=resp:
            raise ValueError("oracle mismatch in generated vector")
        expected.append(resp)
    lines=(directory/"core-observed.txt").read_text(encoding="ascii").splitlines()
    if len(lines)!=len(expected):
        raise ValueError("observed count mismatch")
    for ordinal,(line,resp) in enumerate(zip(lines,expected)):
        columns=line.split()
        if len(columns)!=2 or int(columns[0])!=ordinal or parse_hex(columns[1],585)!=resp:
            raise ValueError(f"core observed mismatch at {ordinal}")
    result=json.loads((directory/"core-result.json").read_text())
    if result.get("status")!="PASS" or result.get("finished") is not True:
        raise ValueError("core terminal missing")
    manifest=json.loads((vectors/"manifest.json").read_text())
    groups={}
    for case in manifest["cases"]:
        groups[case["group"]]=groups.get(case["group"],0)+1
    return dict(status="PASS",numeric_records=len(expected),groups=groups,
                actual_events=result,observed_sha256=digest(directory/"core-observed.txt"))


def audit_probe(directory):
    rows=(directory/"probe-observed.txt").read_text(encoding="ascii").splitlines()
    crc=0xffffffff
    lfsr=1
    epochs=[]
    count=0
    for line in rows:
        columns=line.split()
        if len(columns)==2 and columns[0]=="RESET":
            epochs.append(count)
            count=0
            crc=0xffffffff
            lfsr=1
            continue
        if len(columns)!=4:
            raise ValueError("probe columns")
        request,actual=parse_hex(columns[0],622),parse_hex(columns[1],585)
        actual_crc=parse_hex(columns[2],32)
        sequence=field(request,104,64)
        kind=sequence%8
        if kind!=field(request,206,5) or sequence!=count:
            raise ValueError("probe source identity/kind")
        if (field(request,176,11),field(request,187,11))!=(1920,1080):
            raise ValueError("probe default size")
        sa=(sequence>>3)&1 if kind in (0,1,2,3,5) else 0
        sb=(sequence>>4)&1 if kind in (0,1,2,5) else 0
        a,b=lfsr&MASK192,lfsr>>192
        if kind in (3,6):
            b|=1
        if kind in (4,7):
            b=0
        source_expected=encode_request(kind,a,b,a_signed=sa,b_signed=sb,sequence=sequence)
        if request!=source_expected:
            raise ValueError("actual probe source body does not follow frozen recurrence")
        feedback=((lfsr>>383)^(lfsr>>382)^(lfsr>>380)^(lfsr>>377))&1
        lfsr=((lfsr<<1)|feedback)&((1<<384)-1)
        if evaluate(request)!=actual:
            raise ValueError("probe mathematical response")
        crc=crc_bits(crc,actual)
        if crc!=actual_crc or int(columns[3])!=((count+1)//1024)%2:
            raise ValueError("probe actual CRC/LED")
        count+=1
    epochs.append(count)
    if epochs!=[1024,32]:
        raise ValueError(f"probe epoch lengths {epochs}")
    return dict(status="PASS",epochs=epochs,observed_sha256=digest(directory/"probe-observed.txt"))


def rejection_probes():
    probes=[("",622),("xyz",622),("-1",622),(hex(1<<622)[2:],622)]
    for value,bits in probes:
        try:
            parse_hex(value,bits)
        except ValueError:
            continue
        raise AssertionError("input rejection did not reject")
    return dict(status="PASS",rejected=len(probes))


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("mode",choices=("generate","audit-core","audit-probe","input-probes"))
    parser.add_argument("directory",type=Path,nargs="?")
    args=parser.parse_args()
    if args.mode=="input-probes":
        print(json.dumps(rejection_probes()))
    elif args.mode=="generate":
        if args.directory is None:
            parser.error("directory required")
        generated=make_vectors(args.directory)
        print(json.dumps(dict(status="GENERATED",count=generated["count"])))
    else:
        if args.directory is None:
            parser.error("directory required")
        result=audit_core(args.directory) if args.mode=="audit-core" else audit_probe(args.directory)
        (args.directory/(args.mode+".json")).write_text(json.dumps(result,indent=2),encoding="utf-8")
        print(json.dumps(dict(status=result["status"])))
