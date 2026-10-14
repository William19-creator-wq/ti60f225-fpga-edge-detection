"""DH-T1..5：独立旧二维RAW/CFA、R2/BFS及新的公共总线/并发显示审计。"""
import argparse,importlib.util,json,pathlib,struct,hashlib,collections
shared=pathlib.Path(__file__).resolve().parents[1]/'deps/reference'
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);result=importlib.util.module_from_spec(spec);spec.loader.exec_module(result);return result
raw_ref=module('capture_raw_math',shared/'raw10_color_stream/model/raw_color_reference.py')
canny_ref=module('capture_canny_math',shared/'canny_full_sw/model/full_canny_reference.py')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def generate_capture(root,w,h,full):
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

def layout(w,h):
    n=w*h;s=(3*n+63)//64*64;c=(n+255)//256*64;q=(n+15)//16*64;e=(n+63)//64*64
    cb=s+64;qb=cb+c+64;eb=qb+q+64;db=eb+e+64;mem=db+s+64
    return dict(n=n,source=0,source_bytes=s,classes=cb,class_bytes=c,queue=qb,queue_bytes=q,result=eb,result_bytes=e,display=db,display_bytes=s,memory_bytes=mem)

def generate(root,w,h,full):
    generate_capture(root,w,h,full)
    l=layout(w,h);display=bytes(((a*37)^(a>>3))&255 for a in range(l['display'],l['display']+l['display_bytes']))
    (root/'expected-display.bin').write_bytes(display)
    (root/'expected-display.hex').write_text(''.join(display[i:i+16][::-1].hex()+'\n' for i in range(0,len(display),16)),encoding='ascii')
    (root/'layout.json').write_text(json.dumps(l,indent=2),encoding='utf-8')
    meta=json.loads((root/'vector-summary.json').read_text());meta['display_sha256']=sha(root/'expected-display.bin')
    (root/'vector-summary.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')

def audit(root):
    meta=json.loads((root/'vector-summary.json').read_text());rows=(root/'actual-results.txt').read_text().splitlines()
    assert len(rows)==len(meta['cases']);maximum=0;verified=[]
    for expected,row in zip(meta['cases'],rows):
        v=list(map(int,row.split()));ident,outcome,reason,source,reader,inputs,classes,outputs,edges,discard,cycles=v
        assert (ident,outcome,reason,source,reader,inputs,classes,outputs,edges,discard)==(expected['id'],0,0,expected['pairs'],expected['pairs'],expected['pairs'],expected['pairs'],expected['n'],expected['edges'],0)
        for kind in ('source.bin','class.bin','state.bin','queue.bin','result.bin','fp','grad'):
            actual=root/f'actual-{ident}.{kind}';gold=root/f'case-{ident}.{kind}'
            if kind in ('fp','grad'):assert actual.read_text()==gold.read_text(),(ident,kind)
            else:assert actual.read_bytes()==gold.read_bytes(),(ident,kind)
        assert int((root/f'actual-{ident}.status').read_text().strip(),16)==expected['status']
        assert int((root/f'actual-{ident}.origin').read_text().strip(),16)==expected['origin']
        assert (root/f'actual-{ident}.display.bin').read_bytes()==(root/'expected-display.bin').read_bytes()*2
        verified.append(dict(id=ident,cycles=cycles,pixels=expected['n'],source_sha256=sha(root/f'actual-{ident}.source.bin'),edge_sha256=sha(root/f'actual-{ident}.result.bin'),display_sha256=sha(root/f'actual-{ident}.display.bin')))
        maximum=max(maximum,cycles)
    metrics=json.loads((root/'protocol-metrics.json').read_text());assert metrics['finished']
    assert metrics['physical_read_write_overlap']>0 and metrics['display_words']>0 and metrics['algorithm_ar']>0
    # 每笔AR/AW的完整49bit公共身份，全部R/W的128bit正文与byte memory共同核对。
    l=json.loads((root/'layout.json').read_text());memory=bytearray(((i*37)^(i>>3))&255 for i in range(l['memory_bytes']))
    reads=None;writes=None;counts=collections.Counter();current_case=None
    with (root/'axi-events.tsv').open(encoding='ascii') as f:
        assert f.readline().strip()=='case\tcycle\tevent\tvalues'
        for row in f:
            case,cycle,event,values=row.rstrip().split('\t');case=int(case);cycle=int(cycle);values=values.split();counts['events']+=1
            if event=='RESET':
                if reads is not None:counts['reset_aborted_reads']+=1
                if writes is not None:counts['reset_aborted_writes']+=1
                memory=bytearray(((i*37)^(i>>3))&255 for i in range(l['memory_bytes']));reads=writes=None;current_case=case;continue
            if event=='AW':
                addr,identity,length,size,burst=map(lambda v:int(v,16),values)
                assert writes is None and (identity,length,size,burst)==(0,3,4,1) and addr%64==0 and 0<=addr<=len(memory)-64
                writes=dict(addr=addr,index=0);counts['aw']+=1
            elif event=='W':
                data,strobe,last=int(values[0],16),int(values[1],16),int(values[2]);assert writes is not None
                i=writes['index'];assert i<4 and strobe==65535 and last==int(i==3)
                a=writes['addr']+i*16;memory[a:a+16]=data.to_bytes(16,'little');writes['index']+=1;counts['w']+=1
            elif event=='B':
                identity,response=map(lambda v:int(v,16),values);assert writes is not None and writes['index']==4
                if identity==0:writes=None
                else:counts['wrong_bid']+=1
                counts['b']+=1
            elif event=='AR':
                addr,identity,length,size,burst=map(lambda v:int(v,16),values)
                assert reads is None and identity in (0,2) and (size,burst)==(4,1) and 0<=length<64 and addr%16==0
                assert addr%4096+(length+1)*16<=4096 and addr+(length+1)*16<=len(memory)
                if identity==0:assert length==3 and addr%64==0
                reads=dict(addr=addr,identity=identity,index=0,count=length+1);counts['ar']+=1
                counts['display_ar' if identity==2 else 'algorithm_ar']+=1
            elif event=='R':
                identity,response,last,data=int(values[0],16),int(values[1],16),int(values[2]),int(values[3],16)
                assert reads is not None
                a=reads['addr']+reads['index']*16;expected=bytes(memory[a:a+16]).ljust(16,b'\0')
                assert data.to_bytes(16,'little')==expected,(case,cycle,'physical R bytes')
                if identity!=reads['identity']:counts['wrong_rid']+=1
                reads['index']+=1
                if last and identity==reads['identity']:reads=None
                counts['r']+=1
            elif event=='OVERLAP':assert reads is not None and writes is not None;counts['overlap_witness']+=1
            else:raise AssertionError((case,cycle,event))
    for field in ('aw','w','b','r'):assert counts[field]==metrics[field],(field,counts[field],metrics[field])
    assert counts['ar']==metrics['display_ar']+metrics['algorithm_ar']
    protocol_path=root/'hub-protocol-result.json'
    protocols=json.loads(protocol_path.read_text()) if protocol_path.exists() else None
    if meta['full1080p']:assert len(verified)==1 and verified[0]['pixels']==2073600
    result=dict(status='PASS',images=len(rows),pixels_compared=sum(v['n'] for v in meta['cases']),max_cycles=maximum,full1080p=meta['full1080p'],metrics=metrics,physical_public_bus=dict(counts),verified_images=verified,hub_protocol=protocols,
                actual_algorithm_producer_instanced=True,actual_native_ram_verified=True,private_dut_state_used_as_expectation=False,actual_ddr_verified=False,production_csi_verified=False,frame_reference_authority_verified=False,production_pnr_sta_bit_verified=False,full_project_goal_complete=False)
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps({k:result[k] for k in ['status','images','pixels_compared','max_cycles','full1080p','physical_public_bus','metrics']}))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','audit']);p.add_argument('directory',type=pathlib.Path)
    p.add_argument('--width',type=int,default=34);p.add_argument('--height',type=int,default=19);p.add_argument('--full',action='store_true');a=p.parse_args()
    generate(a.directory,a.width,a.height,a.full) if a.action=='generate' else audit(a.directory)
