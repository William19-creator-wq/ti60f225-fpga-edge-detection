"""RJ-T01：独立二维RAW参考→逐像素RGB字节，不调用任何writer/bank实现。"""
import argparse,hashlib,importlib.util,json,pathlib,random
origin=pathlib.Path(__file__).resolve().parents[2]/'raw10_color_stream/model/raw_color_reference.py'
spec=importlib.util.spec_from_file_location('raw_reference',origin);raw_ref=importlib.util.module_from_spec(spec);spec.loader.exec_module(raw_ref)

def generate(root,w,h,full):
    configurations=[(p,k) for p in range(4) for k in range(10)]
    if full:configurations=[(p,6) for p in range(4)]
    frames=[];rng=random.Random(0x43150)
    for number,(phase,pattern) in enumerate(configurations):
        raw=[]
        for y in range(h):
            for x in range(w):
                color=raw_ref.cfa.PATTERNS[phase][y%2][x%2]
                if pattern<3:value=(0,2,1023)[pattern]
                elif pattern<6:value=1023 if color==pattern-3 else 0
                elif pattern==6:value=((1023,13,71),(31,911,6),(101,7,733))[(3*x//w)%3][color]
                elif pattern==7:value=(x*73+y*181)%1024
                elif pattern==8:value=rng.randrange(1024)
                else:value=1023 if x==w//2 and y==h//2 else 0
                raw.append(value)
        stem=f'frame_{number:02d}';rgb=bytearray()
        with (root/(stem+'.input.hex')).open('w') as f:
            for y in range(h):
                for x in range(0,w,2):
                    i=y*w+x;f.write(f'{raw[i]|(raw[i+1]<<10):05x}\n')
                    for lane in range(2):
                        packed=raw_ref.cfa.color(raw_ref.windows(raw,w,h,x+lane,y),x+lane,y,phase)
                        rgb.extend(((packed>>16)&255,(packed>>8)&255,packed&255))
        logical=len(rgb);allocation=(logical+63)//64*64;rgb.extend(bytes(allocation-logical))
        (root/(stem+'.expected.rgb')).write_bytes(rgb)
        with (root/(stem+'.lines.hex')).open('w') as f:
            for i in range(0,len(rgb),64):f.write(rgb[i:i+64][::-1].hex()+'\n')
        frames.append(dict(stem=stem,phase=phase,pattern=pattern,pairs=w*h//2,logical_bytes=logical,physical_bytes=allocation,sha256=hashlib.sha256(rgb).hexdigest()))
    (root/'frame-list.txt').write_text(str(len(frames))+'\n'+''.join(f'{v["stem"]} {v["phase"]}\n' for v in frames))
    (root/'reference-inputs.json').write_text(json.dumps(dict(width=w,height=h,frames=frames,full1080p=full),indent=2))
    print(f'Generated {len(frames)} independent RAW-source frames {w}x{h}')

def audit(root):
    meta=json.loads((root/'reference-inputs.json').read_text());rows=(root/'actual-results.txt').read_text().splitlines();assert len(rows)==len(meta['frames'])
    maximum=0
    for frame,row in zip(meta['frames'],rows):
        stem,raw,rgb,logical,physical,lines,discard,outcome,reason,cycles=row.split()
        assert stem==frame['stem'] and int(raw)==int(rgb)==frame['pairs']
        assert int(logical)==frame['logical_bytes'] and int(physical)==frame['physical_bytes'] and int(lines)==int(physical)//64
        assert int(discard)==int(outcome)==int(reason)==0
        actual=(root/(stem+'.actual.rgb')).read_bytes();assert actual==(root/(stem+'.expected.rgb')).read_bytes(),stem
        maximum=max(maximum,int(cycles))
    protocol=json.loads((root/'protocol-metrics.json').read_text());assert protocol['finished']
    report=dict(status='PASS',frames=len(rows),pixels_compared=sum(v['pairs']*2 for v in meta['frames']),
                logical_bytes=sum(v['logical_bytes'] for v in meta['frames']),max_cycles=maximum,full1080p=meta['full1080p'],
                protocol=protocol,actual_csi_verified=False,actual_ddr_verified=False,frame_publish_verified=False,production_pnr_verified=False,full_project_goal_complete=False)
    (root/'reference-audit.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','audit']);p.add_argument('directory',type=pathlib.Path)
    p.add_argument('--width',type=int,default=64);p.add_argument('--height',type=int,default=32);p.add_argument('--full',action='store_true');a=p.parse_args()
    generate(a.directory,a.width,a.height,a.full) if a.action=='generate' else audit(a.directory)
