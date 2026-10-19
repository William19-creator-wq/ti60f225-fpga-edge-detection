"""Efinity segmented VCD: expand unchanged values over omitted sample timestamps."""
from pathlib import Path
import hashlib,json,re,statistics,sys
def parse(p):
    text=p.read_text(encoding='utf-8-sig');names={c:n for w,c,n in re.findall(r'\$var wire (\d+) (\S+) (\S+) \$end',text)}
    assert set(names.values())=={'ch0_g','ch0_b','ch0_de','cal_done'}
    state={};events={};boundaries=[];started=False
    for m in re.finditer(r'#(\d+)([^#]*)',text):
        t=int(m[1]);body=m[2]
        if '$dumpon' in body:started=True
        if '$dumpoff' in body:boundaries.append(t);continue
        for line in body.splitlines():
            if line.startswith('b'):
                v,c=line[1:].split();state[names[c]]=None if any(z in v.lower() for z in 'xz') else int(v,2)
            elif line and line[0] in '01xz' and line[1:] in names:
                state[names[line[1:]]]=int(line[0]) if line[0] in '01' else None
        if started:events[t]=dict(state)
    assert 0 in events and max(events)==1023 and boundaries==[512], (max(events),boundaries)
    samples=[];state={}
    for t in range(1024):
        if t in events:state=events[t]
        samples.append(dict(t=t,segment=int(t>=512),**state))
    return samples
def stats(a):return dict(n=len(a),minimum=min(a),maximum=max(a),mean=statistics.mean(a)) if a else None
if __name__=='__main__':
    p=Path(sys.argv[1]);samples=parse(p);valid=[s for s in samples if s.get('ch0_de')==1]
    assert valid and all(all(s.get(k) is not None for k in ['ch0_g','ch0_b','ch0_de','cal_done']) for s in valid)
    r=dict(path=str(p.resolve()),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),samples=len(samples),valid=len(valid),probe3_semantics='raw_y_odd; NOT DDR cal_done',by_parity={},segments=[])
    for parity in [0,1]:
        ss=[s for s in valid if s['cal_done']==parity]
        r['by_parity'][str(parity)]={n:stats([s[n] for s in ss]) for n in ['ch0_g','ch0_b']}
    for seg in [0,1]:
        ss=[s for s in valid if s['segment']==seg]
        r['segments'].append(dict(segment=seg,valid=len(ss),parities=sorted({s['cal_done'] for s in ss}),values={n:stats([s[n] for s in ss]) for n in ['ch0_g','ch0_b']}))
    out=p.with_suffix('.stats.json');assert not out.exists();out.write_text(json.dumps(r,indent=2),encoding='utf-8');print(json.dumps(r,indent=2))
