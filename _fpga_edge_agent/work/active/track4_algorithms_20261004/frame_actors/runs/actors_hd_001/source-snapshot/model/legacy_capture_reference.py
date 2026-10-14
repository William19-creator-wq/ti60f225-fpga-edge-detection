"""DH-T1..5：独立旧二维RAW/CFA、R2/BFS及新的公共总线/并发显示审计。"""
import argparse,importlib.util,json,pathlib,struct,hashlib,collections
shared=pathlib.Path(__file__).resolve().parents[1]/'deps/reference'
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);result=importlib.util.module_from_spec(spec);spec.loader.exec_module(result);return result
raw_ref=module('capture_raw_math',shared/'raw10_color_stream/model/raw_color_reference.py')
canny_ref=module('capture_canny_math',shared/'canny_full_sw/model/full_canny_reference.py')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def generate_capture(root,w,h,full,edge_bits):
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
        # PB01/02：由独立BFS最终pixel位打包，不借用RTL分组或slave私有内存。
        if edge_bits==1:
            result=bytes(sum(int(edges[j])<<(j-i) for j in range(i,min(i+8,n))) for i in range(0,n,8))
            assert all(((result[i//8]>>(i%8))&1)==bool(edges[i]) for i in range(n))
            assert not (n%8) or result[-1]>>(n%8)==0
        else:
            result=bytes(255 if edge else 0 for edge in edges)
        result+=bytes((-len(result))%64);(root/(stem+'.result.bin')).write_bytes(result)
        fs=(scope<<3)|(p<<99)|(p<<120)
        status=cj|(7<<179)|(30<<183)|((255 if retain else 127)<<379)|(sum(v==2 for v in math['class'])<<387)|(sum(v==1 for v in math['class'])<<408)|(fs<<429)
        for port in range(8):status|=(p if port<7 or retain else 0)<<(211+port*21)
        metadata.append(dict(id=ident,cj=cj,origin=origin,handle=handle,phase=phase,retain=retain,pairs=p,n=n,edges=sum(edges),status=status))
    (root/'cases.txt').write_text(''.join(f'{v["cj"]:036x} {v["origin"]:049x} {v["handle"]:016x} {v["phase"]} {v["edges"]} {int(v["retain"])}\n' for v in metadata))
    (root/'vector-summary.json').write_text(json.dumps(dict(width=w,height=h,cases=metadata,full1080p=full,result_item_bits=edge_bits),indent=2));print(f'Generated {len(metadata)} same-source RAW/Canny frames {w}x{h}')

def layout(w,h,edge_bits):
    n=w*h;s=(3*n+63)//64*64;c=(n+255)//256*64;q=(n+15)//16*64;e=(n*edge_bits+511)//512*64
    cb=s+64;qb=cb+c+64;eb=qb+q+64;db=eb+e+64;mem=db+s+64
    return dict(n=n,source=0,source_bytes=s,classes=cb,class_bytes=c,queue=qb,queue_bytes=q,result=eb,result_bytes=e,display=db,display_bytes=s,memory_bytes=mem)

def generate(root,w,h,full,edge_bits):
    assert edge_bits in (1,8)
    generate_capture(root,w,h,full,edge_bits)
    l=layout(w,h,edge_bits);display=bytes(((a*37)^(a>>3))&255 for a in range(l['display'],l['display']+l['display_bytes']))
    (root/'expected-display.bin').write_bytes(display)
    (root/'expected-display.hex').write_text(''.join(display[i:i+16][::-1].hex()+'\n' for i in range(0,len(display),16)),encoding='ascii')
    (root/'layout.json').write_text(json.dumps(l,indent=2),encoding='utf-8')
    meta=json.loads((root/'vector-summary.json').read_text());meta['display_sha256']=sha(root/'expected-display.bin')
    (root/'vector-summary.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')

def audit_hub(root):
    """T3：从公开接纳和物理事务重建所有权、回执与byte memory。"""
    capacity=32768
    def initial_memory():return bytearray(((i*37)^(i>>3))&255 for i in range(capacity))
    def integer(bits):
        assert bits and set(bits)<=set('01'),('effective value contains X/Z',bits[:64])
        return int(bits,2)
    def fire(bits):return bits[:2]=='11'
    def address_fields(bits):
        v=integer(bits[2:]);return (v>>17,(v>>13)&15,(v>>5)&255,(v>>2)&7,v&3)
    def line_legal(address):return address%64==0 and 0<=address<=capacity-64
    counts=collections.Counter();cases=collections.defaultdict(collections.Counter)
    camera=algorithm=span=writes=reads=None;memory=initial_memory();previous=None;last_cycle=0
    hold_ports=('camreq','camrsp','algreq','algrsp','spanreq','displayword','displaydone','aw','w','b','ar','r')
    expected_alg={i:(1,1) for i in range(5,9)}
    expected_alg.update({17:(1,1),18:(1,1),**{i:(1,0) for i in range(19,25)},26:(1,0)})
    with (root/'hub-public.tsv').open(encoding='ascii') as stream:
        names=stream.readline().strip().split('\t')
        assert names==['case','cycle','controls','camreq','camrsp','algreq','algrsp','spanreq','displayword','displaydone','aw','w','b','ar','r','diagnostics']
        for line in stream:
            fields=line.strip().split('\t');assert len(fields)==len(names)
            row=dict(zip(names,fields));case=int(row['case']);cycle=int(row['cycle']);assert cycle==last_cycle+1;last_cycle=cycle
            assert all(len(row[k])==width for k,width in dict(controls=5,camreq=546,camrsp=4,algreq=547,algrsp=516,spanreq=48,displayword=130,displaydone=13,aw=51,w=147,b=8,ar=51,r=137,diagnostics=8).items())
            controls=row['controls'];diag=row['diagnostics'];integer(controls)
            if controls[0]=='1':
                if previous is not None and previous['controls'][0]=='0':
                    counts['cold_resets']+=1
                    if writes is not None:counts['reset_aborted_write']+=1
                    if reads is not None:counts['reset_aborted_read']+=1
                camera=algorithm=span=writes=reads=None;memory=initial_memory();previous=row;continue
            # 账采在正沿前；第一次reset沿之前FF诊断可以尚未初始化。
            integer(diag)
            if previous is not None and previous['controls'][0]=='0':
                for port in hold_ports:
                    if previous[port][:2]=='10':assert row[port][0]=='1' and row[port][2:]==previous[port][2:],(case,cycle,'public holding changed',port)
            if diag[0]=='1' or controls[1]=='0':
                assert row['camreq'][1]==row['algreq'][1]==row['spanreq'][1]=='0',(case,cycle,'new request accepted in Q/disable')
            if algorithm is not None:
                assert diag[4]=='1' and row['algreq'][1]=='0',(case,cycle,'algorithm direction/borrow released early')
                if algorithm.get('notice_consumed'):counts['unknown_algorithm_borrow_held']+=1
            if row['camrsp'][0]=='1' and diag[1]=='1' and row['camrsp'][2:]=='01':counts['safe_camera_reply_in_read_q']+=1
            if row['algrsp'][0]=='1' and diag[2]=='1' and row['algrsp'][-2:]=='01':counts['safe_algorithm_reply_in_write_q']+=1
            if fire(row['camreq']):
                assert camera is None
                camera=dict(address=integer(row['camreq'][2:34]),data=integer(row['camreq'][34:]).to_bytes(64,'little'),write=True,started=False,physical_done=False)
                assert line_legal(camera['address']);counts['camera_requests']+=1;cases[case]['camera_requests']+=1
            if fire(row['algreq']):
                assert algorithm is None
                algorithm=dict(address=integer(row['algreq'][3:35]),write=bool(integer(row['algreq'][2])),data=integer(row['algreq'][35:]).to_bytes(64,'little'),started=False,physical_done=False,read_data=bytearray())
                counts['algorithm_requests']+=1;cases[case]['algorithm_requests']+=1
            if fire(row['spanreq']):
                assert span is None
                address=integer(row['spanreq'][2:34]);length=integer(row['spanreq'][34:]);legal=address%16==0 and 16<=length<=8192 and length%16==0 and address+length<=capacity
                span=dict(address=address,length=length,legal=legal,planned=0,delivered=0,good_reads=bytearray(),expected=bytes(memory[address:address+length]) if legal else b'')
                counts['span_requests']+=1;cases[case]['span_requests']+=1
            if fire(row['aw']):
                address,identity,length,size,burst=address_fields(row['aw'])
                assert writes is None and (identity,length,size,burst)==(0,3,4,1) and line_legal(address)
                candidates=[t for t in (camera,algorithm) if t is not None and t['write'] and not t['started'] and t['address']==address]
                assert len(candidates)==1,(case,cycle,'AW has no unique accepted write grant')
                owner=candidates[0];owner['started']=True;writes=dict(owner=owner,index=0);counts['aw']+=1;cases[case]['aw']+=1
            if fire(row['w']):
                assert writes is not None
                v=integer(row['w'][2:]);data=(v>>17).to_bytes(16,'little');strobe=(v>>1)&65535;last=v&1;i=writes['index'];owner=writes['owner']
                assert i<4 and strobe==65535 and last==int(i==3) and data==owner['data'][16*i:16*i+16],(case,cycle,'actual W differs from accepted producer packet')
                a=owner['address']+16*i;memory[a:a+16]=data;writes['index']+=1;counts['w']+=1
            if fire(row['b']):
                assert writes is not None and writes['index']==4
                v=integer(row['b'][2:]);identity=v>>2;response=v&3;counts['b']+=1
                if identity==0:writes['owner']['physical_done']=True;writes['owner']['response_error']=response!=0;writes=None
                else:assert case in (19,27,28);counts['wrong_bid']+=1
            if fire(row['ar']):
                address,identity,length,size,burst=address_fields(row['ar']);assert reads is None and identity in (0,2) and (size,burst)==(4,1)
                assert 0<=length<64 and address%16==0 and address%4096+(length+1)*16<=4096 and address+(length+1)*16<=capacity
                if identity==0:
                    assert algorithm is not None and not algorithm['write'] and not algorithm['started'] and algorithm['address']==address and length==3 and address%64==0
                    owner=algorithm;owner['started']=True;counts['algorithm_ar']+=1
                else:
                    assert span is not None and span['legal'];owner=span
                    expected_address=span['address']+span['planned'];remaining=(span['length']-span['planned'])//16
                    assert address==expected_address and length+1==min(64,remaining,(4096-address%4096)//16)
                    span['planned']+=(length+1)*16;counts['display_ar']+=1
                    if diag[0]=='1' and diag[2]=='1':assert case==28;counts['old_span_ar_after_write_q']+=1
                reads=dict(owner=owner,address=address,identity=identity,count=length+1,index=0);counts['ar']+=1;cases[case]['ar']+=1
            if fire(row['r']):
                assert reads is not None
                v=integer(row['r'][2:]);data=(v>>7).to_bytes(16,'little');identity=(v>>3)&15;response=(v>>1)&3;last=v&1;i=reads['index'];address=reads['address']+16*i
                assert data==bytes(memory[address:address+16]).ljust(16,b'\0'),(case,cycle,'R differs from independent physical byte ledger')
                if identity!=reads['identity']:assert case in (20,26);counts['wrong_rid']+=1
                if last!=int(i==reads['count']-1):assert case in (21,22);counts['malformed_last']+=1
                if response:assert case==18;counts['rresp_error']+=1
                if reads['identity']==0:reads['owner']['read_data'].extend(data)
                elif response==0 and identity==2:reads['owner']['good_reads'].extend(data)
                reads['index']+=1;counts['r']+=1
                if identity==reads['identity'] and last:reads['owner']['physical_done']=True;reads=None
            if writes is not None and reads is not None:counts['physical_duplex_overlap']+=1
            if controls[1]=='0' and (writes is not None or reads is not None):counts['live_enable_loss']+=1
            if fire(row['displayword']):
                assert span is not None and span['legal'];offset=span['delivered'];data=integer(row['displayword'][2:]).to_bytes(16,'little')
                assert offset+16<=len(span['good_reads']) and data==span['expected'][offset:offset+16],(case,cycle,'display fabricated/duplicated/reordered bytes')
                span['delivered']+=16;counts['display_words']+=1;cases[case]['display_words']+=1
            for port,token,label in [('camrsp',camera,'camera'),('algrsp',algorithm,'algorithm')]:
                b=row[port]
                if b[0]!='1':continue
                assert token is not None and not token.get('notice_consumed'),(case,cycle,'reply has no live application owner',label)
                error=integer(b[-2]);drained=integer(b[-1])
                expected=expected_alg.get(case,(0,1)) if label=='algorithm' else ((1,0) if case in (27,28) else (0,1))
                assert (error,drained)==expected,(case,cycle,label,'error/drain',error,drained)
                if not token.get('notice_seen'):
                    if drained:
                        if line_legal(token['address']):assert token['physical_done'],(case,cycle,'safe reply before physical closure')
                        else:assert error and not token['started']
                    if label=='algorithm':
                        data=integer(b[2:-2]).to_bytes(64,'little')
                        if token['write']:assert data==bytes(64),'write reply wrongly used current read proposal'
                        elif not error:assert data==bytes(token['read_data']) and len(data)==64,'read reply wrongly used current write proposal'
                    token['notice_seen']=True;counts[label+'_reply_exposures']+=1
                if fire(b):
                    counts[label+'_replies']+=1;cases[case][label+'_replies']+=1
                    if drained:
                        if label=='camera':camera=None
                        else:algorithm=None
                    else:token['notice_consumed']=True
            if row['displaydone'][0]=='1':
                assert span is not None
                b=row['displaydone'];outcome=integer(b[2:4]);reason=integer(b[4:12]);drained=integer(b[-1]);expected=1 if 9<=case<=13 else 2 if case in (15,16) else 0
                assert (outcome,drained)==(expected,1)
                if outcome==0:assert reason==0 and span['planned']==span['length'] and span['delivered']==span['length'] and reads is None
                elif outcome==1:assert reason==1 and not span['legal'] and span['planned']==0 and span['delivered']==0
                else:assert reason==128 and reads is None
                if fire(b):span=None;counts['display_dones']+=1;cases[case]['display_dones']+=1
            previous=row
    complete=[list(map(int,line.split())) for line in (root/'hub-cases.tsv').read_text(encoding='ascii').splitlines()]
    assert [v[0] for v in complete]==list(range(1,34)) and all(v[1]>0 for v in complete)
    metrics=json.loads((root/'hub-protocol-metrics.json').read_text(encoding='utf-8'));assert metrics['finished'] and metrics['cases']==33 and metrics['cycles']==last_cycle
    for key in ('camera_requests','algorithm_requests','span_requests','display_words'):assert counts[key]==metrics[key],(key,counts[key],metrics[key])
    assert (cases[3]['camera_requests'],cases[3]['camera_replies'],cases[3]['algorithm_requests'],cases[3]['algorithm_replies'],cases[3]['display_words'])==(16,16,12,12,512)
    assert cases[28]['display_words']==512
    for case in range(5,14):assert cases[case]['aw']==cases[case]['ar']==0
    for key in ('physical_duplex_overlap','unknown_algorithm_borrow_held','safe_camera_reply_in_read_q','safe_algorithm_reply_in_write_q','old_span_ar_after_write_q','live_enable_loss','reset_aborted_write','reset_aborted_read'):assert counts[key]>0,(key,'required witness missing')
    assert counts['wrong_bid']==3 and counts['wrong_rid']==2 and counts['malformed_last']>=2
    result=dict(status='PASS',cases=33,metrics=metrics,public_port_ledger=dict(counts),case_counts={str(k):dict(v) for k,v in cases.items()},public_trace_sha256=sha(root/'hub-public.tsv'),private_dut_state_used_as_expectation=False,actual_ddr_verified=False)
    (root/'hub-protocol-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    return result

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
    assert metrics['physical_read_write_overlap']>0 and metrics['display_words']>0 and metrics['algorithm_ar']>0 and metrics['actual_read_contention']>0
    # 每笔AR/AW的完整49bit公共身份，全部R/W的128bit正文与byte memory共同核对。
    l=json.loads((root/'layout.json').read_text());memory=bytearray(((i*37)^(i>>3))&255 for i in range(l['memory_bytes']))
    reads=None;writes=None;counts=collections.Counter();current_case=None;bus_cycle=None;before_read=False;before_write=False
    with (root/'axi-events.tsv').open(encoding='ascii') as f:
        assert f.readline().strip()=='case\tcycle\tevent\tvalues'
        for row in f:
            case,cycle,event,values=row.rstrip().split('\t');case=int(case);cycle=int(cycle);values=values.split();counts['events']+=1
            if bus_cycle!=(case,cycle):
                bus_cycle=(case,cycle);before_read=reads is not None;before_write=writes is not None
                if before_read and before_write:counts['public_duplex_cycle_start']+=1
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
            elif event=='OVERLAP':
                # J2：标记采在正沿；同沿B/RLAST之后的归属不能否定沿前真实并行。
                assert (before_read and before_write) or (reads is not None and writes is not None),(case,cycle,'overlap lacks public ownership')
                counts['overlap_witness']+=1
            else:raise AssertionError((case,cycle,event))
    for field in ('aw','w','b','r'):assert counts[field]==metrics[field],(field,counts[field],metrics[field])
    assert counts['ar']==metrics['display_ar']+metrics['algorithm_ar']
    assert counts['public_duplex_cycle_start']>0,'No independently reconstructed duplex ownership'
    protocols=audit_hub(root)
    if meta['full1080p']:assert len(verified)==1 and verified[0]['pixels']==2073600
    result=dict(status='PASS',images=len(rows),pixels_compared=sum(v['n'] for v in meta['cases']),max_cycles=maximum,full1080p=meta['full1080p'],metrics=metrics,physical_public_bus=dict(counts),verified_images=verified,hub_protocol=protocols,
                actual_algorithm_producer_instanced=True,actual_native_ram_verified=True,private_dut_state_used_as_expectation=False,actual_ddr_verified=False,production_csi_verified=False,frame_reference_authority_verified=False,production_pnr_sta_bit_verified=False,full_project_goal_complete=False)
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps({k:result[k] for k in ['status','images','pixels_compared','max_cycles','full1080p','physical_public_bus','metrics']}))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','audit']);p.add_argument('directory',type=pathlib.Path)
    p.add_argument('--width',type=int,default=34);p.add_argument('--height',type=int,default=19);p.add_argument('--full',action='store_true');p.add_argument('--edge-bits',type=int,choices=(1,8),default=1);a=p.parse_args()
    generate(a.directory,a.width,a.height,a.full,a.edge_bits) if a.action=='generate' else audit(a.directory)
