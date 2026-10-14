"""PB-C1：从公开输入、AXI及行输出独立重建字节；不把TB PASS或DUT私有数组当期望。"""
import argparse, collections, hashlib, json, pathlib, shutil

TASK = pathlib.Path(__file__).resolve().parents[1]
MASK64 = (1 << 64) - 1
COMMAND_FIELDS = [('op',4),('flags',8),('source',64),('result',64),('origin',195),('cj',142),('body',400),('policy',64)]
REPLY_FIELDS = [('op',4),('status',4),('source',64),('result',64),('origin',195),('cj',142),('body',400),('policy',64),('source_slot',3),('result_slot',2)]
TICKET_FIELDS = [('generation',64),('sequence',64),('scan',64),('result',64),('policy',64),('origin',195),('target_y',11),('source_y',11),('mode',3),('mask',3)]

def unpack(value, fields):
    answer = {}
    for name, width in reversed(fields):
        answer[name] = value & ((1 << width) - 1)
        value >>= width
    assert value == 0
    return answer

def allocation(n):
    return (n + 63) // 64 * 64

def source_bytes(w, h, slot, golden=None):
    if golden is not None:
        return bytes(v ^ (slot * 29) for v in golden[:w*h*3]) + bytes((-w*h*3) % 64)
    return bytes(v % 256 for y in range(h) for x in range(w) for v in
                 (37*x+11*y+3*(slot+1), 13*x+47*y+7*(slot+1), 53*x+19*y+17*(slot+1))) + bytes((-w*h*3) % 64)

def edge_value(i, pattern, w, golden=None):
    x, y = i % w, i // w
    return (1, 0, (x+y)%2, int(i%17 == 0), int((31*x+7*y)%29 < 4), golden[i] if golden is not None else 0)[pattern]

def annotation(n, w, slot):
    bits = [(7*(i%w)+3*(i//w)+slot+1) % 4 for i in range(n)]
    body = bytes(sum(bits[j] << (2*(j-i)) for j in range(i, min(i+4,n))) for i in range(0,n,4))
    return bytes(4224) + body + bytes((-4224-len(body)) % 64)

def generate(root, w, h, hd):
    assert w%2 == h%2 == 0 and 6 <= w <= 1920 and 6 <= h <= 1080
    if hd:
        assert (w,h) == (1920,1080)
        frozen = TASK/'inputs/consumer-C1-v1/hd'
        src = (frozen/'case-0.source.bin').read_bytes()
        packed = (frozen/'case-0.result.bin').read_bytes()
        assert len(src) == allocation(3*w*h) and len(packed) == allocation((w*h+7)//8)
        edge = bytes((packed[i//8] >> (i%8)) & 1 for i in range(w*h))
        (root/'source-input.bin').write_bytes(src)
        (root/'edge-input.bin').write_bytes(edge)
    else:
        src = edge = b''
    meta = dict(width=w,height=h,hd=hd,source_bytes=allocation(3*w*h),edge_bytes=allocation((w*h+7)//8),
                ann_bytes=allocation(4224+(w*h+3)//4),golden_source_sha256=hashlib.sha256(src).hexdigest().upper(),
                golden_edge_sha256=hashlib.sha256(edge).hexdigest().upper())
    (root/'consumer-layout.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')
    print(json.dumps(meta))

def audit(root):
    meta = json.loads((root/'consumer-layout.json').read_text(encoding='utf-8'))
    w,h,n = meta['width'],meta['height'],meta['width']*meta['height']
    s,e,a = (meta[k] for k in ('source_bytes','edge_bytes','ann_bytes'))
    golden_source = (root/'source-input.bin').read_bytes() if meta['hd'] else None
    golden_edge = (root/'edge-input.bin').read_bytes() if meta['hd'] else None
    counts = collections.Counter(); cases = {}; source_epochs = {}; results = {}
    holds = {}; mem = None; cfg = None; aw = ar = row = owner_cmd = None; current_frame = None

    def map_byte(address):
        if 0 <= address < 0x03000000:
            slot,offset = divmod(address,0x00800000)
            if slot < 6 and offset < s:
                return slot*s+offset
        elif address < 0x04800000:
            slot,offset = divmod(address-0x03000000,0x00800000)
            if slot < 3 and offset < e:
                return 6*s+slot*e+offset
            if slot < 3 and 0x100000 <= offset < 0x100000+a:
                return 6*s+3*e+slot*a+offset-0x100000
        return None

    def init_memory():
        value = bytearray([0xa5]) * (6*s+3*e+3*a)
        for slot in range(6):
            value[slot*s:(slot+1)*s] = source_bytes(w,h,slot,golden_source)
        for slot in range(3):
            start = 6*s+3*e+slot*a
            value[start:start+a] = annotation(n,w,0)
        return value

    def descriptors(reply):
        body, mode = reply['body'], reply['body'] >> 109 & 7
        src = (reply['source_slot']*0x00800000 << 64) | (3*n << 32) | s
        edge = ((0x03000000+reply['result_slot']*0x00800000) << 64) | ((n+7)//8 << 32) | e if mode not in (1,2) else 0
        ann = ((0x03100000+reply['result_slot']*0x00800000) << 64) | ((4224+(n+3)//4) << 32) | a if mode == 5 else 0
        assert body >> 112 == (src << 192) | (edge << 96) | ann
        assert body >> 98 & 2047 == h//2
        assert reply['cj'] >> 96 & 2047 == w and reply['cj'] >> 107 & 2047 == h

    def expected_pair(ticket, index, pattern):
        y,x,slot = ticket['source_y'],2*index,ticket['origin']&7
        rgb = source_bytes_cache[slot][3*(y*w+x):3*(y*w+x)+6] if ticket['mask']&1 else bytes(6)
        rgb_number = sum(rgb[k] << (8*(2-k if k<3 else 8-k)) for k in range(6))
        edge = sum(edge_value(y*w+x+lane,pattern,w,golden_edge) << lane for lane in range(2)) if ticket['mask']&2 else 0
        ann = sum(((7*(x+lane)+3*y+slot+1)%4) << (2*lane) for lane in range(2)) if ticket['mask']&4 else 0
        return rgb_number | (edge << 48) | (ann << 50)

    source_bytes_cache = [source_bytes(w,h,slot,golden_source) for slot in range(6)]
    with (root/'consumer-events.tsv').open(encoding='ascii') as stream:
        for line in stream:
            raw_case, raw_cycle, event, payload = line.rstrip('\n').split('\t')
            case,cycle = int(raw_case),int(raw_cycle)
            fields = payload.split()
            if event == 'COLD':
                # 数学后端共同cold是明确环境动作，不声称真实PHY安全复位。
                mem=init_memory();cfg=aw=ar=row=owner_cmd=None;holds.clear();source_epochs.clear();results.clear();counts['cold']+=1
                continue
            assert mem is not None
            if event.startswith('H_'):
                key=event[2:]
                if key in holds:
                    assert holds[key][1] == fields and holds[key][0]+1 == cycle,(case,cycle,event,'held packet changed or omitted')
                holds[key]=(cycle,fields);counts['hold_samples']+=1
                continue
            if event in holds:
                old=holds.pop(event)
                assert old[1] == fields and old[0]+1 == cycle,(case,cycle,event,'holding delivery changed')
            if event == 'FRAME':
                mode,pattern=map(int,fields);current_frame=dict(case=case,mode=mode,pattern=pattern,writer_done=False)
                cases[case]=dict(kind='FRAME',mode=mode,pattern=pattern);counts['frames']+=1
            elif event in ('WNEG','RNEG'):
                kind=int(fields[0]);cases[case]=dict(kind=event,variant=kind)
                if event=='WNEG':current_frame=dict(case=case,mode=-1,pattern=2,writer_done=False)
            elif event == 'OCMD':
                assert owner_cmd is None;owner_cmd=unpack(int(fields[0],16),COMMAND_FIELDS);counts['owner_commands']+=1
                if owner_cmd['op']==4:
                    assert owner_cmd['flags']==7
                    result=results[owner_cmd['result']]
                    assert result['mode'] in (1,2) or current_frame['writer_done'],'Result published without actual writer closure'
            elif event == 'OREPLY':
                b=unpack(int(fields[0],16),REPLY_FIELDS)
                assert owner_cmd is not None and b['op']==owner_cmd['op'] and b['status']==0
                if b['op']==0:
                    epoch=owner_cmd['origin']>>67 & MASK64
                    assert b['origin']==(b['source']<<131)|(epoch<<67)|(b['source']<<3)|b['source_slot']
                    source_epochs[b['source']]=epoch
                elif b['op'] in (3,4,5,6,8):
                    descriptors(b)
                    assert b['origin']>>131==b['source'] and (b['origin']>>3 & MASK64)==b['source'] and (b['origin']&7)==b['source_slot']
                    assert b['cj']&MASK64==source_epochs[b['source']]
                    if b['op']==3:
                        assert b['body']&((1<<112)-1)==owner_cmd['body']&((1<<112)-1)
                        results[b['result']]=dict(mode=b['body']>>109&7,body=b['body'],origin=b['origin'],cj=b['cj'],policy=b['policy'])
                    else:
                        old=results[b['result']]
                        assert all(b[k]==old[k] for k in ('body','origin','cj','policy'))
                owner_cmd=None
            elif event=='ANN_SEED':
                slot,source=map(int,fields);assert aw is None and ar is None and slot<3 and source<6
                start=6*s+3*e+slot*a;mem[start:start+a]=annotation(n,w,source);counts['ann_fixture_seeds']+=1
            elif event=='WCFG':
                base,identity=(int(v,16) for v in fields)
                cfg=dict(base=base,id=identity,accepted=0,good=0,start=0,pattern=current_frame['pattern'],aborted=False,req=None,error_seen=False,q=False)
            elif event=='WCFG_REPLY':
                bad=cfg['base']%64!=0 or cfg['base']+e>1<<32
                assert int(fields[0])==bad
                cfg['legal']=not bad
            elif event=='PIXEL':
                identity,index,edge=int(fields[0],16),int(fields[1]),int(fields[2]);assert cfg is not None and cfg['legal']
                actual_bad=identity!=cfg['id'] or index!=cfg['accepted']
                assert edge==edge_value(cfg['accepted'],cfg['pattern'],w,golden_edge)
                if actual_bad:
                    assert cases[case]['kind']=='WNEG' and cases[case]['variant'] in (2,3)
                    cfg['error_seen']=True
                else:cfg['good']+=1
                cfg['accepted']+=1;counts['input_pixels']+=1
            elif event=='ABORT':
                if cfg is not None and int(fields[0],16)==cfg['id']:cfg['aborted']=True
                else:counts['ignored_abort_samples']+=1
            elif event=='WREQ':
                address=int(fields[0],16);data=int(fields[1],16).to_bytes(64,'little')
                assert cfg is not None and cfg['req'] is None and address==cfg['base']+(cfg['start']//512)*64
                expected=sum(edge_value(i,cfg['pattern'],w,golden_edge) << (i-cfg['start']) for i in range(cfg['start'],cfg['good']))
                assert data==expected.to_bytes(64,'little'),(case,'writer packed bytes/padding')
                cfg['req']=dict(address=address,data=data,physical=False);counts['writer_requests']+=1
            elif event=='AW':
                address,identity,length,size,burst=(int(v,16) for v in fields)
                assert aw is None and cfg['req'] is not None and cfg['req']['address']==address and not cfg['req']['physical']
                index=map_byte(address);assert index is not None and map_byte(address+63)==index+63
                assert (identity,length,size,burst)==(0,3,4,1)
                cfg['req']['physical']=True;aw=dict(address=address,index=index,beats=0,data=cfg['req']['data']);counts['aw']+=1
            elif event=='W':
                data=int(fields[0],16).to_bytes(16,'little');strobe=int(fields[1],16);last=int(fields[2]);assert aw is not None
                i=aw['beats'];assert i<4 and strobe==65535 and last==(i==3) and data==aw['data'][i*16:(i+1)*16]
                mem[aw['index']+i*16:aw['index']+(i+1)*16]=data;aw['beats']+=1;counts['w']+=1
            elif event=='B':
                identity,response=(int(v,16) for v in fields);assert aw is not None and aw['beats']==4
                if identity==0:aw=None
                else:assert cases[case].get('variant')==6;counts['wrong_bid']+=1
                if response:cfg['error_seen']=True
                counts['b']+=1
            elif event=='WRSP':
                error,drained=map(int,fields);assert cfg['req'] is not None
                if not drained:assert error;cfg['q']=True
                elif cfg['req']['physical']:assert aw is None
                else:assert error and cfg['req']['address']+64>0x10000000
                if error:cfg['error_seen']=True
                cfg['req']=None;cfg['start']=cfg['good'];counts['writer_replies']+=1
            elif event=='WDONE':
                error,aborted,drained,count=map(int,fields);assert cfg is not None and not cfg['q'] and cfg['req'] is None and aw is None
                assert drained and count==cfg['accepted'] and aborted==cfg['aborted']
                assert error==bool(cfg['error_seen'] or cfg['aborted'])
                if not error:
                    assert count==n;current_frame['writer_done']=True
                counts['writer_dones']+=1
            elif event=='WQ':
                assert cfg['q'] and not current_frame['writer_done'];counts['writer_quarantines']+=1
            elif event=='RJOB':
                assert row is None
                ticket=unpack(int(fields[0],16),TICKET_FIELDS);bundle=unpack(int(fields[1],16),REPLY_FIELDS);permitted=int(fields[2])
                row=dict(ticket=ticket,bundle=bundle,permitted=permitted,pairs=0,rejected=False)
            elif event=='RACK':
                status=int(fields[0])
                if cases[case]['kind']=='RNEG' and cases[case]['variant']!=7:
                    assert status==(2 if cases[case]['variant']==1 else 1);counts['rejected_headers']+=1;row=None
                else:
                    assert status==0 and row['permitted'];descriptors(row['bundle'])
                    t,b=row['ticket'],row['bundle'];mode=b['body']>>109&7
                    expected_mask=(1 if t['target_y']<h//2 else 2) if mode==0 else {1:1,2:1,3:2,4:3,5:7}[mode]
                    expected_y=2*(t['target_y']%(h//2)) if mode==0 else t['target_y']
                    assert t['mode']==mode and t['mask']==expected_mask and t['source_y']==expected_y
                    assert all(t[k]==b[k] for k in ('result','origin','policy')) and all(t[k]>0 for k in ('generation','sequence','scan'))
            elif event=='AR':
                address,identity,length,size,burst=(int(v,16) for v in fields);assert ar is None and row is not None
                index=map_byte(address);length=(length+1)*16
                assert identity==2 and size==4 and burst==1 and address%16==0 and length<=1024 and address%4096+length<=4096
                assert index is not None and map_byte(address+length-1)==index+length-1
                b=row['bundle'];t=row['ticket'];allowed=[]
                if t['mask']&1:allowed.append((b['source_slot']*0x00800000,s))
                if t['mask']&2:allowed.append((0x03000000+b['result_slot']*0x00800000,e))
                if t['mask']&4:allowed.append((0x03100000+b['result_slot']*0x00800000,a))
                assert any(base<=address and address+length<=base+capacity for base,capacity in allowed)
                ar=dict(index=index,bytes=length,received=0,id=identity);counts['ar']+=1
            elif event=='R':
                identity,response,last=int(fields[0],16),int(fields[1],16),int(fields[2]);data=int(fields[3],16).to_bytes(16,'little')
                assert ar is not None and identity==ar['id'] and response==0
                i=ar['received'];assert data==mem[ar['index']+i:ar['index']+i+16] and last==(i+16==ar['bytes'])
                ar['received']+=16
                if last:ar=None
                counts['r']+=1
            elif event=='PAIR':
                generation,index,data=int(fields[0],16),int(fields[1]),int(fields[2],16)
                assert row is not None and generation==row['ticket']['generation'] and index==row['pairs']
                assert data==expected_pair(row['ticket'],index,current_frame['pattern']),(case,row['ticket']['target_y'],index,'actual pair differs')
                row['pairs']+=1;counts['output_pixels']+=2
            elif event=='RDONE':
                outcome,reason,drained,prepared,delivered=map(int,fields);assert row is not None and ar is None and drained
                if cases[case]['kind']=='RNEG':assert outcome==2 and prepared==delivered==row['pairs']==0
                else:assert outcome==reason==0 and prepared==delivered==row['pairs']==w//2;counts['rows']+=1
                row=None
            else:raise AssertionError((case,cycle,event))
    assert not holds and aw is None and ar is None and row is None and owner_cmd is None
    metrics=json.loads((root/'consumer-metrics.json').read_text(encoding='utf-8'))
    assert metrics['finished'] and len(cases)==metrics['cases']
    for key in ('frames','rows','aw','w','b','ar','r'):assert counts[key]==metrics[key],(key,counts[key],metrics[key])
    assert counts['output_pixels']==metrics['pixels']
    expected_frames=[(4,5)] if meta['hd'] else [(4,0),(4,1),(4,1),(4,2),(0,3),(1,3),(2,3),(3,4),(5,2)]
    assert [(v['mode'],v['pattern']) for v in cases.values() if v['kind']=='FRAME']==expected_frames
    assert counts['output_pixels']==n*len(expected_frames)
    if not meta['hd']:assert counts['writer_quarantines']==1 and counts['ignored_abort_samples']>0 and counts['rejected_headers']==6
    result=dict(status='PASS',layout=meta,cases=len(cases),metrics=metrics,public_counts=dict(counts),actual_edge_writer_and_axi_verified=True,
                actual_owner64_and_reader64_verified=True,actual_native_meta_ram_verified=True,private_dut_state_used_as_expectation=False,
                source_annotation_explicit_test_fixture=True,production_frame_reference_authority_verified=False,actual_ddr_verified=False,
                production_csi_verified=False,production_hdmi_scan_verified=False,full_project_goal_complete=False)
    (root/'consumer-audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=('generate','audit'));p.add_argument('directory',type=pathlib.Path)
    p.add_argument('--width',type=int,default=34);p.add_argument('--height',type=int,default=20);p.add_argument('--hd',action='store_true');args=p.parse_args()
    generate(args.directory,args.width,args.height,args.hd) if args.action=='generate' else audit(args.directory)
