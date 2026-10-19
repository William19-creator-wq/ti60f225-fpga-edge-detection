"""Parse exported LA VCD; legacy cal_done means row parity only in RAWTAG bit."""
from pathlib import Path
import hashlib,json,re,statistics,sys
p=Path(sys.argv[1]);text=p.read_text(encoding='utf-8-sig');names={}
for width,code,name in re.findall(r'\$var wire (\d+) (\S+) (\S+) \$end',text):names[code]=name
assert set(names.values())=={'ch0_g','ch0_b','ch0_de','cal_done'}
state={};samples=[];active=False;segment=-1
for m in re.finditer(r'#(\d+)([^#]*)',text):
    t=int(m[1]);body=m[2]
    if '$dumpon' in body:active=True;segment+=1
    for line in body.splitlines():
        if line.startswith('b'):
            v,c=line[1:].split();state[names[c]]=None if any(z in v.lower() for z in 'xz') else int(v,2)
        elif line and line[0] in '01xz' and line[1:] in names:
            state[names[line[1:]]]=int(line[0]) if line[0] in '01' else None
    if '$dumpoff' in body:active=False
    if active:samples.append(dict(t=t,segment=segment,**state))
valid=[s for s in samples if s.get('ch0_de')==1]
assert len(samples)==1024 and valid and all(all(s.get(k) is not None for k in names.values()) for s in valid)
def stats(a):return dict(n=len(a),minimum=min(a),maximum=max(a),mean=statistics.mean(a)) if a else None
r=dict(path=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),samples=len(samples),valid=len(valid),probe3_semantics='raw_y_odd; NOT cal_done',by_parity={},segments=[])
for parity in [0,1]:
    ss=[s for s in valid if s['cal_done']==parity]
    r['by_parity'][str(parity)]={n:stats([s[n] for s in ss]) for n in ['ch0_g','ch0_b']}
for seg in sorted({s['segment'] for s in samples}):
    ss=[s for s in valid if s['segment']==seg]
    r['segments'].append(dict(segment=seg,valid=len(ss),parities=sorted({s['cal_done'] for s in ss})))
out=p.with_suffix('.stats.json');assert not out.exists();out.write_text(json.dumps(r,indent=2),encoding='utf-8');print(json.dumps(r,indent=2))
