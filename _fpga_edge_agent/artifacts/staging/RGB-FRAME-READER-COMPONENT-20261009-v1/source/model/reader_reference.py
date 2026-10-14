"""FR-T01：逐像素RGB→FP元数据，参考不模拟slot/cursor/RPC状态。"""
import argparse,hashlib,json,pathlib,random
def generate(root,w,h,full):
    cases=[]
    for ident,pattern in enumerate([3] if full else range(6)):
        rng=random.Random(0x465200+pattern);rgb=bytearray();fps=[]
        for y in range(h):
            for x in range(w):
                if pattern==0:pixel=(0,0,0)
                elif pattern==1:pixel=(0x11,0x22,0x33) if x%2==0 else (0x44,0x55,0x66)
                elif pattern==2:pixel=(255,255,255)
                elif pattern==3:pixel=((x*13+y*5)%256,(x*7+y*19)%256,(x+y*31)%256)
                elif pattern==4:pixel=(255,0,0) if x<w//3 else ((0,255,0) if x<2*w//3 else (0,0,255))
                else:pixel=tuple(rng.randrange(256) for _ in range(3))
                rgb.extend(pixel)
        for y in range(h):
            for x in range(0,w,2):
                i=(y*w+x)*3;r0,g0,b0,r1,g1,b1=rgb[i:i+6]
                pair=(r0<<16)|(g0<<8)|b0|(r1<<40)|(g1<<32)|(b1<<24)
                markers=int(x==0 and y==0)|(int(x==w-2)<<1)|(int(x==w-2 and y==h-1)<<2)
                fps.append(pair|(x<<48)|(y<<59)|(markers<<70))
        stem=f'frame_{ident:02d}';logical=len(rgb);rgb.extend(bytes((-logical)%64))
        (root/(stem+'.rgb')).write_bytes(rgb)
        (root/(stem+'.fp')).write_text(''.join(f'{v:019x}\n' for v in fps))
        (root/(stem+'.lines')).write_text(''.join(rgb[i:i+64][::-1].hex()+'\n' for i in range(0,len(rgb),64)))
        cases.append(dict(stem=stem,pairs=w*h//2,lines=len(rgb)//64,logical_bytes=logical,physical_bytes=len(rgb),sha256=hashlib.sha256(rgb).hexdigest()))
    (root/'frame-list.txt').write_text(str(len(cases))+'\n'+''.join(v['stem']+'\n' for v in cases))
    (root/'reference-inputs.json').write_text(json.dumps(dict(width=w,height=h,frames=cases,full1080p=full),indent=2));print(f'Generated {len(cases)} RGB reader frames {w}x{h}')
def audit(root):
    meta=json.loads((root/'reference-inputs.json').read_text());rows=(root/'actual-results.txt').read_text().splitlines();assert len(rows)==len(meta['frames']);maximum=0
    for frame,row in zip(meta['frames'],rows):
        stem,prepared,output,reads,discard,outcome,reason,cycles=row.split()
        assert stem==frame['stem'] and int(prepared)==int(output)==frame['pairs'] and int(reads)==frame['lines']
        assert int(discard)==int(outcome)==int(reason)==0
        assert (root/(stem+'.actual.fp')).read_text()==(root/(stem+'.fp')).read_text(),stem
        maximum=max(maximum,int(cycles))
    protocol=json.loads((root/'protocol-metrics.json').read_text());assert protocol['finished']
    if not meta['full1080p']:assert protocol['cancel_cases']>=5 and protocol['safe_errors']>=1 and protocol['unknown_quarantine']
    result=dict(status='PASS',frames=len(rows),pixels_compared=sum(v['pairs']*2 for v in meta['frames']),max_cycles=maximum,full1080p=meta['full1080p'],protocol=protocol,
                production_ddr_verified=False,production_pnr_verified=False,full_project_goal_complete=False)
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','audit']);p.add_argument('directory',type=pathlib.Path)
    p.add_argument('--width',type=int,default=34);p.add_argument('--height',type=int,default=19);p.add_argument('--full',action='store_true');a=p.parse_args()
    generate(a.directory,a.width,a.height,a.full) if a.action=='generate' else audit(a.directory)
