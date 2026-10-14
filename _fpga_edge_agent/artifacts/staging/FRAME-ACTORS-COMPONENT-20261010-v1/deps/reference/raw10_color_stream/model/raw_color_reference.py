"""二维RAW图/显式CFA/reflect101，独立于行RAM/pending/水平状态机。"""
import argparse,hashlib,importlib.util,json,pathlib,random
path=pathlib.Path(__file__).resolve().parents[2]/'debayer_kernel/model/debayer_reference.py'
spec=importlib.util.spec_from_file_location('cfa_reference',path);cfa=importlib.util.module_from_spec(spec);spec.loader.exec_module(cfa)

def reflect(coordinate,limit):
    if coordinate<0:return -coordinate
    if coordinate>=limit:return 2*limit-2-coordinate
    return coordinate

def windows(raw,width,height,x,y):
    return [raw[reflect(y+dy,height)*width+reflect(x+dx,width)] for dy in (-1,0,1) for dx in (-1,0,1)]

def generate(root,width,height,full):
    root=pathlib.Path(root);root.mkdir(parents=True,exist_ok=True);rng=random.Random(0x43110);metadata=[]
    configurations=[(phase,pattern) for phase in range(4) for pattern in range(10)]
    if full:configurations=[(phase,6) for phase in range(4)]
    for ident,(phase,pattern) in enumerate(configurations):
        raw=[]
        for y in range(height):
            for x in range(width):
                color=cfa.PATTERNS[phase][y%2][x%2]
                if pattern<3:value=(0,2,1023)[pattern]
                elif pattern<6:value=1023 if color==pattern-3 else 0
                elif pattern==6:value=((1023,13,71),(31,911,6),(101,7,733))[(3*x//width)%3][color]
                elif pattern==7:value=(x*73+y*181)%1024
                elif pattern==8:value=rng.randrange(1024)
                else:value=1023 if x==width//2 and y==height//2 else 0
                raw.append(value)
        raw_file=(root/f'case-{ident}.raw').open('w',encoding='ascii')
        window_file=(root/f'case-{ident}.window').open('w',encoding='ascii')
        rgb_file=(root/f'case-{ident}.rgb').open('wb')
        for y in range(height):
            for x in range(0,width,2):
                i=y*width+x;pair=raw[i]|(raw[i+1]<<10);raw_file.write(f'{pair:05x}\n')
                samples=[windows(raw,width,height,x+lane,y) for lane in range(2)]
                packed=sum(v<<(lane*90+j*10) for lane,sample in enumerate(samples) for j,v in enumerate(sample))
                window_file.write(f'{packed:045x}\n')
                rgb=cfa.color(samples[0],x,y,phase)|(cfa.color(samples[1],x+1,y,phase)<<24)
                rgb_file.write(rgb.to_bytes(6,'little'))
        raw_file.close();window_file.close();rgb_file.close()
        metadata.append({'id':ident,'phase':phase,'pattern':pattern,'pixels':width*height,'pairs':width*height//2})
    (root/'cases.txt').write_text(''.join(f'{c["phase"]} {c["pattern"]}\n' for c in metadata),encoding='ascii')
    (root/'vector-summary.json').write_text(json.dumps({'width':width,'height':height,'cases':metadata,'full1080p':width==1920 and height==1080},indent=2),encoding='utf-8')
    print(f'Generated {len(metadata)} RAW10 reflect101 frames {width}x{height}')

def audit(root):
    root=pathlib.Path(root);meta=json.loads((root/'vector-summary.json').read_text());rows=[list(map(int,line.split())) for line in (root/'actual-results.txt').read_text().splitlines()]
    assert len(rows)==len(meta['cases']);pairs=0;maximum=0
    for expected,row in zip(meta['cases'],rows):
        ident,outcome,reason,accepted,window_count,output,discarded,clocks=row
        assert (ident,outcome,reason,accepted,window_count,output,discarded)==(expected['id'],0,0,expected['pairs'],expected['pairs'],expected['pairs'],0)
        actual=(root/f'actual-{ident}.rgb').read_bytes();gold=(root/f'case-{ident}.rgb').read_bytes();assert actual==gold,(ident,'RGB mismatch')
        pairs+=output;maximum=max(maximum,clocks)
    protocol=json.loads((root/'protocol-metrics.json').read_text());assert protocol['finished']
    if not meta['full1080p']:
        assert protocol['input_errors']==4 and protocol['cancel_cases']>=6 and protocol['pending_discard_cases']>0
    result={'status':'PASS','frames':len(rows),'pixels_compared':pairs*2,'window_pairs_compared':pairs,'max_cycles':maximum,
        'full1080p':meta['full1080p'],'protocol':protocol,'production_camera_verified':False,'production_pnr_verified':False,
        'full_project_goal_complete':False,'results_sha256':hashlib.sha256((root/'actual-results.txt').read_bytes()).hexdigest()}
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','audit']);p.add_argument('root')
    p.add_argument('--width',type=int,default=34);p.add_argument('--height',type=int,default=19);p.add_argument('--full',action='store_true');a=p.parse_args()
    if a.action=='generate':generate(a.root,a.width,a.height,a.full)
    else:audit(a.root)
