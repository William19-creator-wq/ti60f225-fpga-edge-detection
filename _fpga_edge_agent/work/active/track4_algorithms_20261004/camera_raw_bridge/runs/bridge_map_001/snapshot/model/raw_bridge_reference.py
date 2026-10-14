"""RB02/04: 从外部实际pair日志独立重算像素、数量、身份、坐标和标记。"""
import csv,json,struct,sys
from pathlib import Path

def audit(root):
    root=Path(root);m=json.loads((root/'protocol-metrics.json').read_text())
    assert m['finished'] is True and m['reception_closure_proven'] is False
    rows=list(csv.DictReader((root/'cases.csv').open()))
    cases={int(r['handle'],16):r for r in rows};seen={h:0 for h in cases}
    data=(root/'pairs.bin').read_bytes();assert len(data)%16==0
    width,height=m['width'],m['height']
    for offset in range(0,len(data),16):
        raw,flags,y,x,handle=struct.unpack_from('<3sBHHQ',data,offset)
        assert handle in cases
        i=seen[handle];ex=(i%(width//2))*2;ey=i//(width//2)
        r=cases[handle];seed=int(r['seed']);assert ey<height
        p=lambda px: (37*px+53*ey+7*(px^ey)+101*seed)&1023
        expected=p(ex)|(p(ex+1)<<10)
        ef=(int(ey==height-1 and ex==width-2)<<2)|(int(ex==width-2)<<1)|int(i==0)
        assert (int.from_bytes(raw,'little'),x,y,flags)==(expected,ex,ey,ef), (handle,i,offset)
        seen[handle]+=1
    for h,r in cases.items():
        g,d,drop=map(int,(r['groups'],r['delivered'],r['discarded']))
        assert d==seen[h]
        if r['drained']=='1':assert d+drop==g*2 and r['known']=='1'
        if r['shape']=='1':assert int(r['outcome'])==0 and g==width*height//4 and d+drop==width*height//2
        if r['known']=='0':assert r['drained']=='0' and int(r['outcome'])==3
    assert len(rows)==m['cases'] and sum(seen.values())==m['pairs']
    result={'status':'PASS','cases':len(rows),'pairs':sum(seen.values()),'raw10_pixels_compared':sum(seen.values())*2,'reception_closure_proven':False}
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result))
if __name__=='__main__':audit(sys.argv[1])
