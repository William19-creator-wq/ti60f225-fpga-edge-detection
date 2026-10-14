"""AN-T01…12：固定原始请求、独立线性角度/投影期望、真实probe来源审核。"""
import argparse,json,random,hashlib
from pathlib import Path
from angle_reference import *

def digest(path):
    with Path(path).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def gradient(x,y):return (x&2047)|((y&2047)<<11)
def radial(x,y):return (x&524287)|((y&524287)<<19)
def project(x,y,theta):return x|(y<<11)|(theta<<22)
def generate(run):
    run=Path(run);root=run/'vectors';root.mkdir(parents=True,exist_ok=False)
    records=[];meta=[];sequence=0
    def add(label,k,p=0,**kwargs):
        nonlocal sequence
        req=request(k,p,sequence=sequence,**kwargs);records.append((req,evaluate(req)));meta.append(label);sequence+=1
    for k,pack,limit in ((8,gradient,1020),(9,radial,262143)):
        for x,y in ((1,0),(0,1),(1,1),(-1,1),(-1,0),(0,-1),(-1,-1),(1,-1),(limit,limit),(-limit,limit),(1,limit),(limit,1)):
            add(f'axes-diagonal-{k}-{x}-{y}',k,pack(x,y))
        if k==9:
            add('radial-wrap-positive',9,radial(-10000,16));add('radial-wrap-negative',9,radial(10000,-16))
        boundaries,_=constants()
        for index,(c,s) in enumerate(boundaries):
            base=(limit*s)//c
            for m in (max(0,base-1),base,min(limit,base+1)):
                for swap in (False,True):
                    for sx,sy in ((1,1),(-1,1),(1,-1),(-1,-1)):
                        x,y=(m,limit) if swap else (limit,m)
                        add(f'boundary-{k}-{index}-{m}-{swap}-{sx}-{sy}',k,pack(x*sx,y*sy))
        rng=random.Random(20261009 if k==8 else 20261010)
        for index in range(2048 if k==8 else 4096):
            x,y=rng.randint(-limit,limit),rng.randint(-limit,limit)
            if x==y==0:x=1
            add(f'random-{k}-{index}',k,pack(x,y))
    for theta in range(512):add(f'coefficient-{theta}',16,theta)
    large_points=((0,0),(1919,0),(0,1079),(1919,1079),(960,0),(960,1079),(0,540),(1919,540),(960,540))
    for x,y in large_points:
        for theta in range(512):add(f'1080p-projection-{x}-{y}-{theta}',10,project(x,y,theta))
    for y in range(5):
        for x in range(6):
            for theta in range(512):add(f'small-projection-{x}-{y}-{theta}',10,project(x,y,theta),width=6,height=5)
    for height in (17,49,81):
        for offset in (-20,-12,-4,4,12,20):
            y=(height-1)//2+offset
            if 0<=y<height:add(f'projection-RNE-tie-{height}-{offset}',10,project(7,y,256),width=16,height=height)
    for w in (0,7,2047):add(f'bad-width-{w}',8,gradient(1,1),width=w)
    for h in (0,2047):add(f'bad-height-{h}',8,gradient(1,1),height=h)
    add('bad-version',8,gradient(1,1),version=0);add('bad-owner',8,gradient(1,1),owner=1)
    for k in (0,7,11,19,31):add(f'unsupported-{k}',k)
    for k,p,used in ((8,gradient(1,1),22),(9,radial(1,1),38),(10,project(1,1,0),31),(16,0,9)):
        add(f'padding-{k}',k,p|(1<<used));add(f'flag-a-{k}',k,p,flags=1);add(f'flag-b-{k}',k,p,flags=2);add(f'target-{k}',k,p,target=511)
    for g in (-1024,-1021,1021):
        add(f'Gx-{g}',8,gradient(g,1));add(f'Gy-{g}',8,gradient(1,g))
    add('radial-min-x',9,radial(-262144,1));add('radial-min-y',9,radial(1,-262144))
    add('gradient-zero',8);add('radial-zero',9)
    add('x-outside',10,project(1920,1,0));add('y-outside',10,project(1,1080,0))
    add('multiple-errors-width-first',9,1<<38,width=7,version=0,owner=1,flags=1,target=1)
    add('multiple-errors-version-first',8,1<<22,version=0,flags=1)
    add('multiple-errors-format-first',8,gradient(-1024,0)|(1<<22))
    (root/'cases.txt').write_text(str(len(records))+'\n'+''.join(f'{req:0156x} {rsp:0147x}\n' for req,rsp in records),encoding='ascii')
    protocol=[request(8,gradient(1020,17),sequence=900000),request(9,radial(-10000,16),sequence=900001),
              request(16,255,sequence=900002),request(10,project(1919,1079,511),sequence=900003)]
    (root/'protocol.txt').write_text(''.join(f'{r:0156x} {evaluate(r):0147x}\n' for r in protocol),encoding='ascii')
    (root/'manifest.json').write_text(json.dumps(dict(cases=len(records),scenario_names=meta,seeds=[20261009,20261010],
        cases_sha256=digest(root/'cases.txt'),protocol_sha256=digest(root/'protocol.txt'),large_projection_cases=4608,small_projection_cases=15360),indent=2),encoding='utf-8')
    print(json.dumps(dict(cases=len(records),gradient_random=2048,radial_random=4096,large_projection=4608,small_projection=15360)))

def audit_core(run):
    run=Path(run);manifest=json.loads((run/'vectors/manifest.json').read_text());rows=(run/'vectors/cases.txt').read_text().splitlines()[1:]
    events=(run/'core-numeric.tsv').read_text().splitlines()
    if len(events)!=manifest['cases']:raise ValueError('actual numeric event count')
    for index,(expected,actual) in enumerate(zip(rows,events)):
        req,rsp=(int(x,16) for x in expected.split());items=actual.split()
        if int(items[0])!=index or (int(items[1],16),int(items[2],16))!=(req,rsp):raise ValueError(f'actual req/rsp{index}')
    r=json.loads((run/'core-result.json').read_text())
    if not r.get('finished') or r.get('status')!='PASS' or r['cases']!=len(rows) or r['formation_max']>96:raise ValueError('core scope or time')
    if r['accepted']!=r['consumed']+r['reset_aborted']:raise ValueError('one request one terminal ledger')
    if r['rom_reads']!=r['rom_returns']+r['rom_reset'] or r['products']!=r['product_returns']+r['product_reset']:raise ValueError('private return ledger')
    print(json.dumps(dict(status='PASS',cases=len(rows),formation_max=r['formation_max'],cancel_checks=r['cancel_checks'],reset_checks=r['reset_checks'])))

def probe_request(seq,lfsr):
    k=(8,9,10,16)[seq&3]
    if k==8:
        x,y=lfsr&1023,(lfsr>>10)&1023;x=x if x<=1020 else 1020;y=y if y<=1020 else 1020
        if x==y==0:x=1
        p=gradient(-x if lfsr&(1<<20) else x,-y if lfsr&(1<<21) else y)
    elif k==9:
        x,y=lfsr&262143,(lfsr>>18)&262143
        if x==y==0:x=1
        p=radial(-x if lfsr&(1<<36) else x,-y if lfsr&(1<<37) else y)
    elif k==10:
        x,y=lfsr&2047,(lfsr>>11)&2047
        if x>=1920:x-=1920
        if y>=1080:y-=1080
        p=project(x,y,(lfsr>>22)&511)
    else:p=lfsr&511
    return request(k,p,sequence=seq)
def audit_probe(run):
    run=Path(run);seq=0;lfsr=1;crc=0xffffffff;pending=None;observed=None;counts=[0,0];segment=0
    for line in (run/'probe-ledger.tsv').read_text().splitlines():
        seg,event,cycle,raw=line.split();seg=int(seg);value=int(raw,16)
        if event=='B':
            if pending is not None or observed is not None:raise ValueError('reset segment incomplete')
            segment=seg;seq=0;lfsr=1;crc=0xffffffff;continue
        if seg!=segment:raise ValueError('segment tag')
        if event=='Q':
            expected=probe_request(seq,lfsr)
            if pending is not None or observed is not None or value!=expected:raise ValueError('probe real source')
            pending=value;seq+=1
            feedback=((lfsr>>191)^(lfsr>>190)^(lfsr>>187)^(lfsr>>185))&1;lfsr=((lfsr<<1)&((1<<192)-1))|feedback
        elif event=='R':
            if pending is None or value!=evaluate(pending):raise ValueError('probe real response')
            observed=value;pending=None
            for bit in range(584,-1,-1):
                feedback=((crc>>31)^(value>>bit))&1;crc=(crc<<1)&0xffffffff
                if feedback:crc^=0x04c11db7
        elif event=='C':
            if observed is None or value!=crc:raise ValueError('probe actual 585bit CRC')
            observed=None;counts[segment]+=1
        else:raise ValueError('unknown probe event')
    if counts!=[1024,32] or pending is not None or observed is not None:raise ValueError('probe terminal accounting')
    (run/'probe-audit.json').write_text(json.dumps(dict(status='PASS',requests=1056,crc_words=1056,ledger_sha256=digest(run/'probe-ledger.tsv')),indent=2))
    print('PASS probe1056 original sources, responses and complete585bit CRC')
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('action',choices=('generate','audit-core','audit-probe','audit-constants'))
    parser.add_argument('run');a=parser.parse_args()
    if a.action=='generate':generate(a.run)
    elif a.action=='audit-core':audit_core(a.run)
    elif a.action=='audit-probe':audit_probe(a.run)
    else:
        task=Path(__file__).resolve().parents[1]
        r=audit_constants(task/'rtl',task/'runs/constant_generation_001/certificate.json')
        Path(a.run).mkdir(parents=True,exist_ok=True);(Path(a.run)/'constant-audit.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
