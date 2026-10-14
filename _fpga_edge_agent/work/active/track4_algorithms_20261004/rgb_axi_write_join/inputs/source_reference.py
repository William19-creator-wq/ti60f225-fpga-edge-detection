"""SW-T01：只按图像顺序生成RGB字节，参考不模拟carry/bank/packet状态机。"""
import argparse,hashlib,json,pathlib,random

def pixels(w,h,kind):
    rng=random.Random(0x535700+kind)
    for y in range(h):
        for x in range(w):
            if kind==0:r,g,b=0,0,0
            elif kind==1:r,g,b=(0x11,0x22,0x33) if x%2==0 else (0x44,0x55,0x66)
            elif kind==2:r,g,b=255,255,255
            elif kind==3:r,g,b=(x*13+y*5)%256,(x*7+y*19)%256,(x+y*31)%256
            elif kind==4:r,g,b=(255,0,0) if x<w//3 else ((0,255,0) if x<2*w//3 else (0,0,255))
            else:r,g,b=(rng.randrange(256) for _ in range(3))
            yield r,g,b

def generate(path,w,h,full):
    assert 4<=w<=1920 and w%2==0 and 2<=h<=1080
    frames=[]
    for index,kind in enumerate([3] if full else range(6)):
        raw=bytes(v for p in pixels(w,h,kind) for v in p)
        allocation=(len(raw)+63)//64*64;padded=raw+bytes(allocation-len(raw))
        stem=f'frame_{index:02d}'
        with (path/(stem+'.input.hex')).open('w') as f:
            for offset in range(0,len(raw),6):f.write(raw[offset:offset+6].hex()[6:]+raw[offset:offset+6].hex()[:6]+'\n')
        with (path/(stem+'.lines.hex')).open('w') as f:
            for offset in range(0,len(padded),64):f.write(padded[offset:offset+64][::-1].hex()+'\n')
        (path/(stem+'.expected.rgb')).write_bytes(padded)
        frames.append(dict(stem=stem,kind=kind,width=w,height=h,pairs=w*h//2,logical_bytes=len(raw),physical_bytes=allocation,
                           expected_sha256=hashlib.sha256(padded).hexdigest()))
    (path/'frame-list.txt').write_text(str(len(frames))+'\n'+'\n'.join(x['stem'] for x in frames)+'\n')
    (path/'reference-inputs.json').write_text(json.dumps(dict(frames=frames,full1080p=full),indent=2))
    print(f'Generated {len(frames)} independent RGB frames {w}x{h}')

def audit(path):
    inputs=json.loads((path/'reference-inputs.json').read_text());results=(path/'actual-results.txt').read_text().splitlines()
    assert len(results)==len(inputs['frames'])
    maximum=0
    for frame,row in zip(inputs['frames'],results):
        stem,pairs,logical,physical,lines,outcome,reason,cycles=row.split()
        assert stem==frame['stem'] and int(pairs)==frame['pairs']
        assert int(logical)==frame['logical_bytes'] and int(physical)==frame['physical_bytes']
        assert int(lines)==frame['physical_bytes']//64 and int(outcome)==int(reason)==0
        actual=(path/(stem+'.actual.rgb')).read_bytes()
        assert actual==(path/(stem+'.expected.rgb')).read_bytes(),stem
        assert hashlib.sha256(actual).hexdigest()==frame['expected_sha256']
        maximum=max(maximum,int(cycles))
    protocol=json.loads((path/'protocol-metrics.json').read_text());assert protocol['finished']
    result=dict(status='PASS',frames=len(results),logical_bytes=sum(x['logical_bytes'] for x in inputs['frames']),
                physical_bytes=sum(x['physical_bytes'] for x in inputs['frames']),max_cycles=maximum,
                full1080p=inputs['full1080p'],protocol=protocol,actual_ddr_verified=False,production_pnr_verified=False,full_project_goal_complete=False)
    (path/'reference-audit.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','audit']);p.add_argument('directory',type=pathlib.Path)
    p.add_argument('--width',type=int,default=34);p.add_argument('--height',type=int,default=19);p.add_argument('--full',action='store_true')
    a=p.parse_args();generate(a.directory,a.width,a.height,a.full) if a.action=='generate' else audit(a.directory)
