"""SC21..27：按真实事件重建租约/银行/切帧；数学像素独立于RTL调度。"""
import collections
import hashlib
import json
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'deps'))
import frame_owner_reference as owner

TICKET = [(k,64) for k in ('gen','seq','scan','result','policy')]+[
    ('origin',195),('y',11),('sy',11),('mode',3),('mask',3)]
DEMAND = TICKET[1:]
RECEIPT = [('bank',2),('ticket',543),('status',3),('granted',1),('outcome',2),
    ('reason',8),('drained',1),('returned',1),('prepared',11),('delivered',11),('beats',32)]
CONTROL = [('kind',3),('seq',64),('cause',64),('policy',64),('bundle',942)]
RESPONSE = [('kind',3),('status',3),('seq',64),('cause',64),('policy',64),
    ('bundle',942),('previous',64),('active',1),('held',1),('closed',1)]
RENDER = [('mode',3),('split',11),('edge',24),('ann1',24),('ann2',24),('ann3',24),('show_edge',1),('show_ann',1)]

def unpack(v, fields):
    return owner.decode(int(v,16) if isinstance(v,str) else v,fields)

def ref(t):
    return (((t['seq']<<64 | t['result'])<<64 | t['policy'])<<195) | t['origin']

def bundle_ref(seq,b):
    return ref(dict(seq=seq,result=b['result'],policy=b['policy'],origin=b['origin']))

def key(bank,t):
    return bank,t['gen'],t['seq'],t['y']

def pixel(x,y,f):
    return ((37*x+11*y+3*f)%256<<16) | ((13*x+47*y+7*f)%256<<8) | (53*x+19*y+17*f)%256

def pair(t,a):
    x,y,f=2*a,t['sy'],(t['origin']&7)+1
    rgb=pixel(x,y,f) | pixel(x+1,y,f)<<24 if t['mask']&1 else 0
    edge=int((x+y+f)%3==0) | int((x+1+y+f)%3==0)<<1 if t['mask']&2 else 0
    ann=(7*x+3*y+f)%4 | ((7*(x+1)+3*y+f)%4)<<2 if t['mask']&4 else 0
    return rgb | edge<<48 | ann<<50

def color(x,y,b,h):
    cfg=unpack(b['body']&((1<<112)-1),RENDER);m=cfg['mode'];sy=2*(y%(h//2)) if m==0 else y
    f=b['ss']+1;rgb=pixel(x,sy,f);edge=(x+sy+f)%3==0;ann=(7*x+3*sy+f)%4
    gray=(77*(rgb>>16)+150*((rgb>>8)&255)+29*(rgb&255)+128)>>8
    if m==0:return gray*0x010101 if y<h//2 else 0xffffff if edge else 0
    if m==1:return rgb
    if m==2:return gray*0x010101
    if m==3:return 0xffffff if edge else 0
    if m==5 and cfg['show_ann'] and ann:return cfg['ann'+str(ann)]
    return cfg['edge'] if cfg['show_edge'] and edge else rgb

def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest().upper()

def audit(root):
    root=Path(root);metrics=json.loads((root/'scan-metrics.json').read_text(encoding='utf-8'))
    assert metrics['finished'];w,h=metrics['width'],metrics['height'];p=w//2;ht,vt=p+140,h+45
    independent_owner=owner.audit(root)
    ledger=owner.Ledger(w,h,1)
    counts=collections.Counter();controls={};offered={};frames={};tickets={};releases={}
    planned=[None]*3;video_banks=[None]*3;core_banks=[None]*3;generations=[1]*3;return_debt=[None]*3
    current=None;service=None;transport=None;fence=None;notified=set();closed=set();cancel_closed=set()
    active=None;scan=0;pending_switch=None;candidate=None;cancelled=set();old_refs=set();qualification={}
    policy=1;frozen=False;held=False;prepare_seq=0;burst=0
    def quiet_core(r):
        return all(t is None or ref(t)!=r for t in core_banks) and all(t is None or ref(t)!=r for t in return_debt) and transport!=r
    for line in (root/'scan-events.jsonl').open(encoding='utf-8'):
        e=json.loads(line);event=e['event'];counts[event]+=1
        if event=='reset':assert (e['width'],e['height'])==(w,h)
        elif event=='owner':
            c=unpack(e['command'],owner.CMD);actual=unpack(e['reply'],owner.REP);assert ledger.event(c)==actual
            if c['op']==8:assert any((r>>259)&((1<<64)-1)==c['result'] for r in notified),('RETIRE before actual fence',c)
            if c['op']==7 and c['flags']&8:assert any((r>>259)&((1<<64)-1)==c['result'] for r in cancel_closed)
        elif event=='offer':
            b=unpack(e['bundle'],owner.REP);_,r=ledger.active_result(b['result']);assert r and r['state']==3;offered[b['result']]=int(e['bundle'],16)
        elif event=='control':
            c=unpack(e['packet'],CONTROL);assert c['seq'] and c['seq'] not in controls;controls[c['seq']]=c
            if c['kind']==0:
                b=unpack(c['bundle'],owner.REP);assert offered[b['result']]==c['bundle'] and b['policy']==policy
        elif event=='candidate':
            c=controls[int(e['sequence'],16)];assert c['kind']==0 and c['bundle']==int(e['bundle'],16) and int(e['scan'],16)==scan+1
            candidate=c
        elif event=='cancel':cancelled.add(int(e['sequence'],16))
        elif event=='candidate_cancel':assert int(e['sequence'],16) in cancelled
        elif event=='qualification':qualification[e['bank']]=e
        elif event=='vs':
            assert int(e['scan_before'],16)==scan and int(e['target_scan'],16)==scan+1
            genuine=False
            if e['candidate'] and not e['cancel']:
                c=controls[int(e['sequence'],16)];b=unpack(c['bundle'],owner.REP);r=bundle_ref(c['seq'],b)
                for bank,qv in qualification.items():
                    t=unpack(qv['ticket'],TICKET)
                    if video_banks[bank] is not None and ref(t)==r and t['scan']==scan+1 and t['y']==0 and qv['owned'] and qv['valid'] and not qv['error'] and qv['address']==0 and qv['issued']==2:
                        assert int(qv['data'],16)==pair(t,0);genuine=True
            assert bool(e['prepared'])==genuine,('Fabricated row0 qualification',e,qualification)
            if genuine and e['retire_capacity']:
                c=controls[int(e['sequence'],16)];pending_switch=(c['seq'],c['bundle'],scan+1,active)
            # PREPARE/RESUME在VS生效，其回复另外核对完整snapshot。
            for c in controls.values():
                if not c.get('replied') and c['seq'] not in cancelled and c['kind'] in (1,3):
                    policy=c['policy'];frozen=c['kind']==1;held=frozen and active is not None
                    if frozen:prepare_seq=c['seq']
            scan+=1;qualification={}
        elif event=='active':
            assert pending_switch is not None;seq,b,at,old=pending_switch
            assert (int(e['sequence'],16),int(e['bundle'],16),int(e['scan'],16))==(seq,b,at)
            if old:old_refs.add(bundle_ref(old[0],unpack(old[1],owner.REP)))
            active=(seq,b);pending_switch=None
        elif event=='control_reply':
            a=unpack(e['packet'],RESPONSE);c=controls[a['seq']];assert a['kind']==c['kind'] and a['cause']==c['cause']
            assert a['policy']==policy;c['replied']=True
            if c['kind']==0:
                b=unpack(c['bundle'],owner.REP);r=bundle_ref(c['seq'],b);assert a['bundle']==c['bundle']
                if a['status']==4:assert a['closed'] and r in cancel_closed and c['seq'] in cancelled
                else:assert a['status']==0 and active==(c['seq'],c['bundle']) and not a['closed']
            elif c['kind']==1:
                assert a['status']==0 and a['closed'] and a['bundle']==(active[1] if active else 0) and bool(a['held'])==held
            elif c['kind']==2:
                assert c['cause']==prepare_seq and a['bundle']==c['bundle'] and a['status']==0;held=False
            elif c['kind']==3:assert a['status']==0 and not a['held'] and a['bundle']==active[1]
        elif event=='frame':
            actual=(int(e['sequence'],16),int(e['bundle'],16));assert bool(e['active'])==(active is not None)
            assert actual==(active if active else (0,0)) and int(e['scan'],16)==scan
            frames[e['frame']]=e
        elif event=='watched':assert frames[e['frame']]['sequence']==e['sequence']
        elif event=='promise':
            assert current is None;v=int(e['request'],16);bank=v>>479;t=unpack(v&((1<<479)-1),DEMAND)
            assert bank<3 and planned[bank] is None and video_banks[bank] is None
            assert t['scan'] and t['seq'] in controls and t['y']<h
            mask=[1 if t['y']<h//2 else 2,1,1,2,3,7][t['mode']]
            assert t['mask']==mask and t['sy']==(2*(t['y']%(h//2)) if t['mode']==0 else t['y'])
            current=(bank,t);planned[bank]=t
        elif event in ('request','service'):
            v=int(e['request'],16);assert current and (v>>479,unpack(v&((1<<479)-1),DEMAND))==current
            if event=='service':service=current
        elif event=='lookup':
            d=unpack(e['demand'],DEMAND);b=unpack(e['bundle'],owner.REP);assert service and d==service[1]
            _,r=ledger.active_result(d['result']);assert r and r['state'] in (3,4,5) and e['permitted']==1
            assert b['result']==d['result'] and b['origin']==d['origin'] and b['policy']==d['policy'] and b['body']==r['body'] and b['cj']==r['cj']
        elif event=='grant':
            bank=e['bank'];t=unpack(e['ticket'],TICKET);assert service and service[0]==bank and {k:t[k] for k,_ in DEMAND}==service[1]
            assert t['gen']==generations[bank] and core_banks[bank] is None;core_banks[bank]=t;tickets[key(bank,t)]=t
        elif event=='core_receipt':service=None
        elif event=='receipt':
            a=unpack(e['packet'],RECEIPT);t=unpack(a['ticket'],TICKET);bank=a['bank'];assert current and current[0]==bank and current[1]=={k:t[k] for k,_ in DEMAND}
            assert a['drained'] and a['outcome']!=3
            if a['outcome']==0:assert a['status']==0 and a['granted'] and not a['returned'] and a['prepared']==a['delivered']==p
            else:assert not a['granted'] or a['returned'];planned[bank]=None
            current=None
        elif event=='reserve':
            bank=e['bank'];t=unpack(e['ticket'],TICKET);assert planned[bank]=={k:t[k] for k,_ in DEMAND} and core_banks[bank]==t and video_banks[bank] is None
            video_banks[bank]=t;planned[bank]=None
        elif event=='release':
            bank=e['bank'];t=unpack(e['ticket'],TICKET);assert video_banks[bank]==t and e['issued']==e['popped']
            assert e['kind'] in (0,1) and (e['kind']!=0 or e['shown']==p);releases[key(bank,t)]=e
        elif event in ('return_core','return_internal'):
            bank=e['bank'];v=int(e['packet'],16)>>2 if event=='return_core' else int(e['ticket'],16);t=unpack(v,TICKET)
            assert core_banks[bank]==t;core_banks[bank]=None;generations[bank]+=1
            if event=='return_core':assert key(bank,t) in releases;return_debt[bank]=t
        elif event=='return_video':
            bank=e['bank'];t=unpack(int(e['packet'],16)>>2,TICKET);assert video_banks[bank]==return_debt[bank]==t;video_banks[bank]=None
        elif event=='return_ack':
            bank=e['bank'];t=unpack(int(e['packet'],16)>>2,TICKET);assert return_debt[bank]==t and video_banks[bank] is None;return_debt[bank]=None
        elif event=='transport':transport=int(e['ref'],16) if e['live'] else None
        elif event=='fence':
            assert fence is None;fence=int(e['packet'],16);r=fence&((1<<387)-1)
            assert not current or ref(current[1])!=r
            assert all(t is None or ref(t)!=r for t in video_banks)
            if fence>>387:assert r in old_refs
            else:assert r>>323 in cancelled
        elif event=='old_closed':
            r=int(e['ref'],16);assert fence==(1<<387)|r and quiet_core(r);notified.add(r)
        elif event=='fence_done':
            assert int(e['packet'],16)==fence;r=fence&((1<<387)-1);assert quiet_core(r)
            if fence>>387:assert r in notified;closed.add(r)
            else:cancel_closed.add(r)
            fence=None
        elif event=='ar':
            assert burst==0 and e['id']==2 and 1<=e['length']<=64 and e['address']%16==0
            assert e['address']//4096==(e['address']+16*e['length']-1)//4096;burst=e['length']
        elif event=='r':
            assert burst>0 and e['id']==2 and e['response']==0 and bool(e['last'])==(burst==1);burst-=1
        elif event=='end':
            assert burst==0 and current is None and service is None and transport is None
            assert all(t is not None for t in video_banks) and len(video_banks)==e['retained_rows']==3
        elif event=='missed_test':assert int(e['sequence'],16) in controls and (active is None or active[0]!=int(e['sequence'],16))
        else:raise AssertionError(('Unknown event',event))
    # 每条native记录完整绑定bank/GEN/sequence/行，不从RTL状态推导数学期望。
    native_counts=collections.Counter();visible=collections.Counter();fmt=struct.Struct('<BQQHHQB')
    with (root/'native.bin').open('rb') as f:
        while data:=f.read(fmt.size):
            assert len(data)==fmt.size;bank,gen,seq,y,a,value,shown=fmt.unpack(data);k=(bank,gen,seq,y);t=tickets[k]
            assert a==native_counts[k] and a<p and value==pair(t,a) and shown in (0,1);native_counts[k]+=1;visible[k]+=shown
    for k,e in releases.items():assert native_counts[k]==e['popped']==e['issued'] and visible[k]==e['shown']
    slots=collections.Counter();active_pixels=0;fmt=struct.Struct('<I6sHHH')
    with (root/'output.bin').open('rb') as f:
        while data:=f.read(fmt.size):
            assert len(data)==fmt.size;frame,rgb,x,y,flags=fmt.unpack(data);e=frames[frame];a=slots[frame];row,col=divmod(a,ht)
            de=row<h and col<p;ex,ey=(2*col,row) if de else (0,0)
            expected_flags=int(de) | int(p+44<=col<p+66)<<1 | int(h+4<=row<h+9)<<2 | int(a==0)<<3
            if de and not e['active']:expected_flags|=1<<4
            assert (x,y,flags)==(ex,ey,expected_flags),(frame,a,(x,y,flags),(ex,ey,expected_flags))
            value=int.from_bytes(rgb,'little');b=unpack(e['bundle'],owner.REP)
            expected=color(ex,ey,b,h) | color(ex+1,ey,b,h)<<24 if de and e['active'] else 0
            assert value==expected,('Pixel',frame,a,hex(value),hex(expected));slots[frame]+=1;active_pixels+=2*int(de)
    for frame in range(1,metrics['completed_frames']+1):assert slots[frame]==ht*vt,(frame,slots[frame],ht*vt)
    for e in frames.values():assert slots[e['frame']]<=ht*vt
    assert counts['active']==metrics['changes'] and counts['old_closed']==metrics['closed'] and counts['return_core']==metrics['returns']
    assert sum(native_counts.values())==metrics['pops'] and sum(slots.values())==metrics['output_slots']
    assert metrics['requests']-metrics['pops']==6
    result={'status':'PASS','completed_frames':metrics['completed_frames'],'frames_with_prefix':metrics['frames'],'modes_verified':sorted({unpack(frames[e['frame']]['bundle'],owner.REP)['body']>>109&7 for e in [json.loads(x) for x in (root/'scan-events.jsonl').read_text(encoding='utf-8').splitlines() if '"event":"watched"' in x]}),'time_slots':sum(slots.values()),'active_pixels':active_pixels,'native_pops':metrics['pops'],'returns':metrics['returns'],'old_closed':metrics['closed'],'owner_transactions':metrics['owner_transactions'],'retained_active_rows':3,'actual_ddr_verified':False,'physical_cdc_verified':False,'production_root_controller_verified':False,'full_project_goal_complete':False,'events_sha256':sha(root/'scan-events.jsonl'),'output_sha256':sha(root/'output.bin'),'native_sha256':sha(root/'native.bin')}
    assert result['modes_verified']==list(range(6));(root/'reference-result.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':audit(sys.argv[1])
