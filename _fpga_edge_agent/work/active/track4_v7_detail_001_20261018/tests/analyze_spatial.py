from pathlib import Path
import csv,json,sys
T=Path(__file__).resolve().parent;R=T.parents[3]/'reports/TRACK4-V7-DETAIL-001'
def raw(y,x,p):
    if p==0:return (x*37+y*83+x*y*3)%192+32
    if p==1:return 208 if (x//4)%2 else 48
    if p==2:return 208 if (y//4)%2 else 48
    if p==3:return 208 if (x//8+y//8)%2 else 48
    return 208 if (x//2)%2 else 48
def reference(y,x,p):
    c=raw(y,x,p);h=(raw(y,x-1,p)+raw(y,x+1,p))//2
    v=(raw(y-1,x,p)+raw(y+1,x,p))//2
    cross=(raw(y,x-1,p)+raw(y,x+1,p)+raw(y-1,x,p)+raw(y+1,x,p))//4
    diag=sum(raw(y+dy,x+dx,p) for dy in [-1,1] for dx in [-1,1])//4
    if y%2==0 and x%2==0:return (diag,cross,c)
    if y%2==1 and x%2==1:return (c,cross,diag)
    if y%2==0:return (v,c,h)
    return (h,c,v)
def rgb(s):
    n=int(s,16);return (n>>16,(n>>8)&255,n&255)
path=Path(sys.argv[1]) if len(sys.argv)>1 else sorted((T/'runs').glob('*/spatial.csv'))[-1]
rows=list(csv.DictReader(path.open()))
sample=[r for r in rows if r['pattern']=='0' and 4<=int(r['input_row'])<10 and 5<=int(r['input_pair'])<40]
scores=[]
for dy in range(-3,1):
    for dx in range(-6,3):
        for swap in [False,True]:
            errors=0;exact=0
            for r in sample:
                for slot in [0,1]:
                    got=rgb(r[f'slot{slot}']);exp=reference(int(r['input_row'])+dy,int(r['input_pair'])*2+dx+(1-slot if swap else slot),0)
                    errors+=sum(abs(a-b) for a,b in zip(got,exp));exact+=got==exp
            scores.append(dict(dy=dy,dx=dx,swap=swap,absolute_error=errors,exact=exact,pixels=2*len(sample)))
scores.sort(key=lambda x:x['absolute_error']);best=scores[0]
assert (best['dy'],best['dx'],best['swap'])==(-1,-2,False),'Unexpected spatial alignment'
stats={p:dict(pixels=0,mismatch=0,max_error=0,absolute_error=0,examples=[]) for p in range(5)}
for r in rows:
    p=int(r['pattern']);y=int(r['input_row'])+best['dy'];x=int(r['input_pair'])*2+best['dx']
    if not (2<=y<22 and 4<=x<1914):continue
    if r['de']!='1' or r['valid']!='1':raise AssertionError('Lost valid')
    for s in [0,1]:
        got=rgb(r[f'slot{s}']);exp=reference(y,x+(1-s if best['swap'] else s),p)
        d=[abs(a-b) for a,b in zip(got,exp)];st=stats[p];st['pixels']+=1
        st['absolute_error']+=sum(d);st['max_error']=max(st['max_error'],max(d))
        if any(d):
            st['mismatch']+=1
            if len(st['examples'])<4:st['examples'].append(dict(y=y,x=x+s,got=got,expected=exp))
result=dict(source=str(path),definition='Independent BGGR bilinear: native component retained; missing component is 2/4-neighbor integer mean. Interior only, excludes startup and boundary padding.',alignment_candidates=scores[:6],stats=stats)
assert all(s['mismatch']==0 and s['pixels']==38200 for s in stats.values()),'Spatial reference mismatch'
print(json.dumps(result,indent=2))
output=R/'spatial-analysis-001.json'
if output.exists():assert json.loads(output.read_text())==json.loads(json.dumps(result))
else:
    with output.open('x',encoding='utf-8') as f:json.dump(result,f,indent=2)
