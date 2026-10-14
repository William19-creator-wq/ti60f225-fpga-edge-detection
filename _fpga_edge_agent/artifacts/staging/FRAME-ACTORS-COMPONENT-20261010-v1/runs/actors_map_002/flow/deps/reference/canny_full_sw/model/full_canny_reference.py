"""原R2独立二维整数数学 + 独立BFS；核实际完整外存结果，不模拟RTL FSM。"""
import argparse,hashlib,importlib.util,json,pathlib,random,struct
shared=pathlib.Path(__file__).resolve().parents[2]
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);result=importlib.util.module_from_spec(spec);spec.loader.exec_module(result);return result
r2=module('r2_math',shared/'r2/model/canny_stream_reference.py')
bfs=module('bfs_math',shared/'canny_memory_join/model/memory_join_reference.py')

def generate(root,width,height,full):
    root=pathlib.Path(root);root.mkdir(parents=True,exist_ok=True);n=width*height;p=n//2;rng=random.Random(0x431060)
    configurations=[]
    for pattern in range(6):
        for median in (False,True):
            for retain in (False,True):configurations.append((pattern,median,retain,(0,64,128)[pattern%3],(64,128,512)[pattern%3]))
    configurations.extend((1,False,False,t,t) for t in (0,64,512,2047))
    if full:configurations=[(1,False,False,0,64)]
    metadata=[]
    for ident,(pattern,median,retain,tl,th) in enumerate(configurations):
        rgb=[]
        for y in range(height):
            for x in range(width):
                if pattern==0:value=(0,0,0)
                elif pattern==1:
                    level=255 if x>=width//2 else 0;value=(level,level,level)
                elif pattern==2:
                    level=255 if x>=y*width//height else 0;value=(level,level,level)
                elif pattern==3:value=((x*17)%256,(y*29)%256,((x^y)*31)%256)
                elif pattern==4:
                    inside=(x-width//2)**2+(y-height//2)**2<=(min(width,height)//3)**2
                    value=(220,70,15) if inside else (15,5,35)
                else:value=tuple(rng.randrange(256) for _ in range(3))
                rgb.append(value)
        scope=0x5A431002 | (0xABCDAA55<<32) | ((0xAE123400+ident)<<64)
        cj=scope | (width<<96) | (height<<107) | (tl<<118) | (th<<129) | (int(median)<<140) | (int(retain)<<141)
        math=r2.stream_image(tuple(rgb),width,height,median,retain,tl,th)
        edges,order=bfs.breadth_first(math['class'],width,height)
        inputs=[];gradients=[]
        for y in range(height):
            for x in range(0,width,2):
                marker=int(x==0 and y==0)|(int(x==width-2)<<1)|(int(x==width-2 and y==height-1)<<2)
                raw=0;gradient=0
                for lane in range(2):
                    i=y*width+x+lane;r,g,b=rgb[i];raw|=(b|(g<<8)|(r<<16))<<(24*lane)
                    gradient|=((math['gx'][i]&2047)|((math['gy'][i]&2047)<<11)|(math['dir'][i]<<22))<<(32*lane)
                inputs.append(raw|(x<<48)|(y<<59)|(marker<<70))
                gradients.append(gradient|(x<<64)|(y<<75)|(scope<<86)|(marker<<182))
        (root/f'case-{ident}.fp').write_text(''.join(f'{v:019x}\n' for v in inputs),encoding='ascii')
        (root/f'case-{ident}.grad').write_text(''.join(f'{v:047x}\n' for v in gradients) if retain else '',encoding='ascii')
        (root/f'case-{ident}.class.bin').write_bytes(bfs.packed_states(math['class'],n))
        after=[3 if edge else old for old,edge in zip(math['class'],edges)]
        (root/f'case-{ident}.state.bin').write_bytes(bfs.packed_states(after,n))
        (root/f'case-{ident}.queue.bin').write_bytes(struct.pack(f'<{len(order)}I',*order))
        result=bytes(255 if edge else 0 for edge in edges);result+=bytes((-len(result))%64)
        (root/f'case-{ident}.result.bin').write_bytes(result)
        fs=(scope<<3)|(p<<99)|(p<<120)
        status=cj|(7<<179)|(30<<183)|((255 if retain else 127)<<379)|(sum(v==2 for v in math['class'])<<387)|(sum(v==1 for v in math['class'])<<408)|(fs<<429)
        for port in range(8):status|=(p if port<7 or retain else 0)<<(211+port*21)
        metadata.append({'id':ident,'cj':cj,'scope':scope,'edges':sum(edges),'retain':retain,'status':status,'n':n,'pairs':p})
    (root/'cases.txt').write_text(''.join(f'{c["cj"]:036x} {c["edges"]} {int(c["retain"])}\n' for c in metadata),encoding='ascii')
    (root/'vector-summary.json').write_text(json.dumps({'width':width,'height':height,'cases':metadata,'full1080p':width==1920 and height==1080},indent=2),encoding='utf-8')
    print(f'Generated {len(metadata)} complete independent Canny images {width}x{height}')

def audit(root):
    root=pathlib.Path(root);meta=json.loads((root/'vector-summary.json').read_text());rows=(root/'actual-results.txt').read_text().splitlines()
    assert len(rows)==len(meta['cases']);total=0;maximum=0
    for expected,line in zip(meta['cases'],rows):
        ident,outcome,reason,inputs,classes,outputs,edge_count,discarded,clocks=map(int,line.split())
        assert (ident,outcome,reason,inputs,classes,outputs,edge_count,discarded)==(expected['id'],0,0,expected['pairs'],expected['pairs'],expected['n'],expected['edges'],0)
        for kind in ('class.bin','state.bin','queue.bin','result.bin'):
            assert (root/f'actual-{ident}.{kind}').read_bytes()==(root/f'case-{ident}.{kind}').read_bytes(),(ident,kind)
        actual_grad=(root/f'actual-{ident}.grad').read_text();gold_grad=(root/f'case-{ident}.grad').read_text();assert actual_grad==gold_grad,(ident,'gradient')
        actual_status=int((root/f'actual-{ident}.status').read_text().strip(),16);assert actual_status==expected['status'],(ident,'raw CS592')
        total+=outputs;maximum=max(maximum,clocks)
    metrics=json.loads((root/'protocol-metrics.json').read_text());assert metrics['finished']
    if not meta['full1080p']:assert metrics['cancels']>=9 and metrics['safe_errors']>=3 and metrics['unknown_quarantine']
    result={'status':'PASS','images':len(rows),'pixels_compared':total,'max_cycles':maximum,'full1080p':meta['full1080p'],
        'metrics':metrics,'production_ddr_verified':False,'production_pnr_verified':False,'full_project_goal_complete':False,
        'results_sha256':hashlib.sha256((root/'actual-results.txt').read_bytes()).hexdigest()}
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','audit']);p.add_argument('root')
    p.add_argument('--width',type=int,default=34);p.add_argument('--height',type=int,default=19);p.add_argument('--full',action='store_true');a=p.parse_args()
    if a.action=='generate':generate(a.root,a.width,a.height,a.full)
    else:audit(a.root)
