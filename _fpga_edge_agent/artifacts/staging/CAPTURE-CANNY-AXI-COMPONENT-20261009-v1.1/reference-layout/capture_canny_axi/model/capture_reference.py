"""CA-T01：二维RAW/CFA→真实源RGB参考→独立R2+BFS；从不模拟父FSM或AXI。"""
import argparse,importlib.util,json,pathlib,struct
shared=pathlib.Path(__file__).resolve().parents[2]
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);result=importlib.util.module_from_spec(spec);spec.loader.exec_module(result);return result
raw_ref=module('capture_raw_math',shared/'raw10_color_stream/model/raw_color_reference.py')
canny_ref=module('capture_canny_math',shared/'canny_full_sw/model/full_canny_reference.py')
def generate(root,w,h,full):
    n=w*h;p=n//2;metadata=[]
    configurations=[(phase,pattern,bool(pattern%2),bool(phase%2)) for phase in range(4) for pattern in range(5)]
    if full:configurations=[(0,1,False,False)]
    for ident,(phase,pattern,median,retain) in enumerate(configurations):
        raw=[];rgb=[]
        for y in range(h):
            for x in range(w):
                color=raw_ref.cfa.PATTERNS[phase][y%2][x%2]
                if pattern==0:value=0
                elif pattern==1:value=1023 if x>=w//2 else 0
                elif pattern==2:value=((1023,13,71),(31,911,6),(101,7,733))[(3*x//w)%3][color]
                elif pattern==3:value=(x*73+y*181)%1024
                else:
                    inside=(x-w//2)**2+(y-h//2)**2<=(min(w,h)//3)**2
                    value=((880,600,200) if inside else (31,17,61))[color]
                raw.append(value)
        for y in range(h):
            for x in range(w):
                value=raw_ref.cfa.color(raw_ref.windows(raw,w,h,x,y),x,y,phase)
                rgb.append(((value>>16)&255,(value>>8)&255,value&255))
        scope=0x5a431002|((0xabcdaa55+ident)<<32)|((0xae123400+ident)<<64)
        origin=(ident%6)|((0x1234567800000000+ident)<<3)|((scope&0xffffffff)<<67)|(((scope>>32)&0xffffffff)<<99)|((0x9988000000000000+ident)<<131)
        cj=scope|(w<<96)|(h<<107)|(0<<118)|(64<<129)|(int(median)<<140)|(int(retain)<<141)
        handle=0xfedc000000000001+ident
        math=canny_ref.r2.stream_image(tuple(rgb),w,h,median,retain,0,64)
        edges,order=canny_ref.bfs.breadth_first(math['class'],w,h)
        stem=f'case-{ident}';source=bytes(v for pixel in rgb for v in pixel);source+=bytes((-len(source))%64)
        (root/(stem+'.source.bin')).write_bytes(source)
        raw_words=[];fps=[];grad=[]
        for y in range(h):
            for x in range(0,w,2):
                i=y*w+x;raw_words.append(raw[i]|raw[i+1]<<10);pair=0;g_pair=0
                for lane in range(2):
                    r,g,b=rgb[i+lane];pair|=(b|g<<8|r<<16)<<(24*lane)
                    g_pair|=((math['gx'][i+lane]&2047)|((math['gy'][i+lane]&2047)<<11)|(math['dir'][i+lane]<<22))<<(32*lane)
                markers=int(x==0 and y==0)|(int(x==w-2)<<1)|(int(x==w-2 and y==h-1)<<2)
                fps.append(pair|(x<<48)|(y<<59)|(markers<<70))
                grad.append(g_pair|(x<<64)|(y<<75)|(scope<<86)|(markers<<182))
        (root/(stem+'.raw')).write_text(''.join(f'{v:05x}\n' for v in raw_words))
        (root/(stem+'.fp')).write_text(''.join(f'{v:019x}\n' for v in fps))
        (root/(stem+'.grad')).write_text(''.join(f'{v:047x}\n' for v in grad) if retain else '')
        (root/(stem+'.class.bin')).write_bytes(canny_ref.bfs.packed_states(math['class'],n))
        after=[3 if edge else old for old,edge in zip(math['class'],edges)]
        (root/(stem+'.state.bin')).write_bytes(canny_ref.bfs.packed_states(after,n))
        (root/(stem+'.queue.bin')).write_bytes(struct.pack(f'<{len(order)}I',*order))
        result=bytes(255 if edge else 0 for edge in edges);result+=bytes((-len(result))%64);(root/(stem+'.result.bin')).write_bytes(result)
        fs=(scope<<3)|(p<<99)|(p<<120)
        status=cj|(7<<179)|(30<<183)|((255 if retain else 127)<<379)|(sum(v==2 for v in math['class'])<<387)|(sum(v==1 for v in math['class'])<<408)|(fs<<429)
        for port in range(8):status|=(p if port<7 or retain else 0)<<(211+port*21)
        metadata.append(dict(id=ident,cj=cj,origin=origin,handle=handle,phase=phase,retain=retain,pairs=p,n=n,edges=sum(edges),status=status))
    (root/'cases.txt').write_text(''.join(f'{v["cj"]:036x} {v["origin"]:049x} {v["handle"]:016x} {v["phase"]} {v["edges"]} {int(v["retain"])}\n' for v in metadata))
    (root/'vector-summary.json').write_text(json.dumps(dict(width=w,height=h,cases=metadata,full1080p=full),indent=2));print(f'Generated {len(metadata)} same-source RAW/Canny frames {w}x{h}')
def audit(root):
    meta=json.loads((root/'vector-summary.json').read_text());rows=(root/'actual-results.txt').read_text().splitlines();assert len(rows)==len(meta['cases']);maximum=0
    for expected,row in zip(meta['cases'],rows):
        values=list(map(int,row.split()));ident,outcome,reason,source,reader,inputs,classes,outputs,edges,discard,cycles=values
        assert (ident,outcome,reason,source,reader,inputs,classes,outputs,edges,discard)==(expected['id'],0,0,expected['pairs'],expected['pairs'],expected['pairs'],expected['pairs'],expected['n'],expected['edges'],0)
        for kind in ('source.bin','class.bin','state.bin','queue.bin','result.bin','fp','grad'):
            if kind in ('fp','grad'):assert (root/f'actual-{ident}.{kind}').read_text()==(root/f'case-{ident}.{kind}').read_text(),(ident,kind)
            else:assert (root/f'actual-{ident}.{kind}').read_bytes()==(root/f'case-{ident}.{kind}').read_bytes(),(ident,kind)
        assert int((root/f'actual-{ident}.status').read_text().strip(),16)==expected['status']
        assert int((root/f'actual-{ident}.origin').read_text().strip(),16)==expected['origin']
        maximum=max(maximum,cycles)
    metrics=json.loads((root/'protocol-metrics.json').read_text());assert metrics['finished']
    result=dict(status='PASS',images=len(rows),pixels_compared=sum(v['n'] for v in meta['cases']),max_cycles=maximum,full1080p=meta['full1080p'],metrics=metrics,
                production_ddr_verified=False,production_csi_verified=False,frame_manager_publish_verified=False,production_pnr_verified=False,full_project_goal_complete=False)
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','audit']);p.add_argument('directory',type=pathlib.Path)
    p.add_argument('--width',type=int,default=34);p.add_argument('--height',type=int,default=19);p.add_argument('--full',action='store_true');a=p.parse_args()
    generate(a.directory,a.width,a.height,a.full) if a.action=='generate' else audit(a.directory)
