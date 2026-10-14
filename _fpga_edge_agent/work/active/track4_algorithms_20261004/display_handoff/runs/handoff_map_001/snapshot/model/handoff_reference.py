"""DH01..08: independently check complete messages and observable causal events.

No RTL state or next-register values are read. Mailbox pattern, owner lease set,
VS qualifications, complete snapshot and reply fields are checked independently.
"""
from pathlib import Path
import collections
import importlib.util
import json
import sys

MAX = (1 << 64) - 1
REQ = [('kind',3),('sequence',64),('cause',64),('target',64),('bundle',942)]
RSP = [('kind',3),('status',3),('sequence',64),('cause',64),('policy',64),('bundle',942),('previous',64),('active',1),('hold',1),('closed',1)]
BUNDLE = [('op',4),('status',4),('source',64),('result',64),('origin',195),('cj',142),('body',400),('policy',64),('ss',3),('rs',2)]

def decode(value, fields):
    result = {}
    for name, width in reversed(fields):
        result[name] = value & ((1 << width)-1)
        value >>= width
    assert value == 0
    return result

def source_identity(b):
    return b['source'] != 0 and b['ss'] < 6 and b['origin'] >> 131 == b['source'] and (b['origin'] >> 3) & MAX == b['source'] and b['origin'] & 7 == b['ss']

def descriptor(base, length):
    return (base << 64) | (length << 32) | ((length+15) & ~15)

def valid_offer(b, w, h):
    n = w*h
    mode = (b['body'] >> 109) & 7
    src = descriptor(b['ss'] * 0x800000, 3*n)
    edge = descriptor(0x3000000+b['rs']*0x800000, (n+7)//8) if mode not in (1,2) else 0
    ann = descriptor(0x3100000+b['rs']*0x800000, 4224+(n+3)//4) if mode == 5 else 0
    return b['op']==5 and b['status']==0 and source_identity(b) and b['result']!=0 and b['rs']<3 and b['cj'] & MAX == (b['origin']>>67)&MAX and (b['cj']>>96)&2047==w and (b['cj']>>107)&2047==h and (b['cj']>>118)&2047 <= (b['cj']>>129)&2047 and mode<6 and (b['body']>>98)&2047 == h//2 and b['body']>>112 == (src<<192)|(edge<<96)|ann

def mailbox(root, m):
    queue = collections.deque()
    accepted = delivered = resets = aborted = 0
    width = m['width']
    for line in (root/'mailbox-events.csv').read_text(encoding='utf-8').splitlines():
        row = line.split(',')
        if row[0] == 'RESET':
            aborted += len(queue);queue.clear();resets += 1
        elif row[0] == 'S':
            seed, actual = int(row[1]), int(row[2],16)
            expected = sum(int((seed*37+bit*11+7)%17<8)<<bit for bit in range(width))
            assert actual == expected
            queue.append(actual);accepted += 1
        else:
            assert row[0]=='D' and queue and queue.popleft()==int(row[1],16)
            delivered += 1
    assert not queue and (accepted,delivered,resets)==(m['accepted'],m['delivered'],m['resets'])
    assert accepted==195 and delivered==194 and aborted==1 and resets==2 and m['held_cycles']>30
    return dict(status='PASS',width=width,accepted=accepted,delivered=delivered,reset_aborted=aborted,all_payload_bits_verified=True)

def handoff(root, m):
    pending = None;active = 0;policy = scan = last_sequence = prepare_sequence = 0
    frozen = committed = hold = False;frozen_source = frozen_origin = snapshot = 0
    counts = collections.Counter();hist = collections.Counter();last_tick = None;full_ticks = []
    for line in (root/'handoff-events.csv').read_text(encoding='utf-8').splitlines():
        row = line.split(',');event = row[0];time = int(row[1]);counts[event] += 1
        if event == 'RESET':
            assert pending is None, 'reset cannot silently erase a business request in this suite'
            w,h = map(int,row[2:4]);policy,scan,last_sequence = (int(x,16) for x in row[4:7])
            active = snapshot = frozen_source = frozen_origin = prepare_sequence = 0
            frozen = committed = hold = False;last_tick = None
        elif event == 'REQ':
            assert pending is None
            r = decode(int(row[2],16),REQ);b = decode(r['bundle'],BUNDLE);status = 0
            expected = dict(kind=r['kind'],status=0,sequence=r['sequence'],cause=r['cause'],policy=policy,bundle=0,previous=0,active=int(bool(active)),hold=int(hold),closed=0)
            if r['sequence']==0 or r['sequence']<=last_sequence:status=2
            elif r['kind']==0:
                if r['cause'] or not valid_offer(b,w,h):status=1
                elif r['target']!=policy or b['policy']!=policy or frozen and (not committed or b['source']!=frozen_source):status=3
            elif r['kind'] in (1,3):
                if r['cause'] or r['bundle']:status=1
                elif policy==MAX:status=5
                elif r['target']!=policy+1 or (r['kind']==1 and frozen) or (r['kind']==3 and (not frozen or not committed or hold)):status=3
            elif r['kind']==2:
                snap = decode(snapshot,BUNDLE)
                if not frozen or r['target']!=policy:status=3
                elif r['cause']!=prepare_sequence:status=2
                elif b['op']!=9 or b['status']!=0 or b['policy']!=policy:status=1
                elif snap['source']:
                    if any(b[k]!=snap[k] for k in ('source','result','origin','cj','body','ss','rs')):status=2
                elif b['source']==0:
                    if any(b[k] for k in ('result','origin','cj','body')) or b['ss']!=7 or b['rs']!=3:status=1
                elif not source_identity(b) or any(b[k] for k in ('result','cj','body')) or b['rs']!=3:status=1
                if status==0 and frozen_source and (b['source']!=frozen_source or b['origin']!=frozen_origin):status=2
            else:status=1
            if r['sequence']>last_sequence:last_sequence=r['sequence']
            expected['status']=status
            pending=dict(request=r,bundle=b,expected=expected,canceled=False,closed=False,effect=False)
        elif event == 'CANCEL':
            if pending and int(row[2],16)==pending['request']['sequence'] and not pending['effect']:
                pending['canceled']=True
        elif event == 'TICK':
            old_scan=int(row[2],16);de,pv=map(int,row[3:5]);ps,p_scan,pr,pp,po=(int(x,16) for x in row[5:10]);capacity=int(row[10])
            assert old_scan==scan
            last_tick=dict(time=time,de=de,pv=pv,seq=ps,scan=p_scan,result=pr,policy=pp,origin=po,capacity=capacity)
            if not de and scan!=MAX:scan+=1
            if m['full_scan']:
                assert de==0;full_ticks.append(time)
        elif event == 'CLOSED':
            if pending:
                r,b=pending['request'],pending['bundle']
                observed=tuple(int(x,16) for x in row[2:6])
                if observed==(r['sequence'],b['result'],r['target'],b['origin']):pending['closed']=True
        elif event == 'APPLY':
            assert pending and pending['request']['kind']==0 and pending['expected']['status']==0 and not pending['canceled']
            r,b=pending['request'],pending['bundle'];e=pending['expected'];t=last_tick
            assert t and time-t['time']<=1 and not t['de'] and t['pv'] and t['capacity']
            assert (t['seq'],t['scan'],t['result'],t['policy'],t['origin'])==(r['sequence'],scan,b['result'],r['target'],b['origin'])
            previous=decode(active,BUNDLE)['result'] if active else 0
            assert tuple(int(x,16) for x in row[2:5])==(r['bundle'],previous,scan)
            active=r['bundle'];e.update(bundle=active,previous=previous,active=1);pending['effect']=True
        elif event == 'CONTROL':
            assert pending and pending['expected']['status']==0 and not pending['canceled']
            r,b,e=pending['request'],pending['bundle'],pending['expected']
            if r['kind']==1:
                assert last_tick and time-last_tick['time']<=1 and not last_tick['de']
                snapshot=active;sb=decode(snapshot,BUNDLE);prepare_sequence=r['sequence'];policy=r['target']
                frozen=True;committed=False;hold=bool(active);frozen_source=sb['source'];frozen_origin=sb['origin']
                e.update(policy=policy,bundle=active,active=int(bool(active)),hold=int(hold),closed=1)
            elif r['kind']==2:
                committed=True;hold=False;frozen_source=b['source'];frozen_origin=b['origin'];e.update(bundle=r['bundle'],hold=0,closed=1)
            else:
                assert r['kind']==3 and last_tick and time-last_tick['time']<=1 and not last_tick['de']
                policy=r['target'];frozen=committed=hold=False;frozen_source=frozen_origin=0;e.update(policy=policy,bundle=active,hold=0,closed=1)
            observed=(int(row[2],16),*(int(x) for x in row[3:6]),int(row[6],16))
            assert observed==(policy,int(frozen),int(committed),int(hold),frozen_source)
            pending['effect']=True
        elif event == 'RSP':
            assert pending
            r,e=pending['request'],pending['expected']
            # 重复同一个COMMIT可无外部状态变化，仍必须返回完整bundle。
            if e['status']==0 and r['kind']==2 and not pending['canceled'] and not pending['effect']:
                e.update(bundle=r['bundle'],hold=0,closed=1)
                assert committed and not hold and pending['bundle']['source']==frozen_source
            if e['status']==0 and pending['canceled'] and not pending['effect']:
                if r['kind']==0:
                    assert pending['closed'];e.update(bundle=r['bundle'])
                e.update(status=4,closed=1)
            actual=decode(int(row[2],16),RSP)
            assert actual==e,(counts['RSP'],r,actual,e)
            if actual['status']==0 and r['kind'] in (0,1,3):assert pending['effect']
            hist[actual['status']]+=1;pending=None
        elif event == 'FAULT':
            reason=int(row[2]);sequence=int(row[3],16)
            assert reason in (1,2,3,4)
            if reason==2:assert pending and sequence==pending['request']['sequence']
            if reason==3:assert scan==MAX
            if reason==4:assert last_tick and last_tick['de']
        else:raise AssertionError(row)
    assert pending is None
    assert (counts['REQ'],counts['RSP'],counts['APPLY'],counts['TICK'],counts['RESET'])==(m['requests'],m['responses'],m['changes'],m['ticks'],m['resets'])
    if m['full_scan']:
        assert len(full_ticks)==2 and full_ticks[1]-full_ticks[0]==1237500*13468
    # Frozen copy of independently implemented owner lease reference, no source edits.
    audit_dir=root/'owner-audit';audit_dir.mkdir()
    (audit_dir/'events.csv').write_text((root/'owner-events.csv').read_text(encoding='utf-8'),encoding='utf-8')
    (audit_dir/'protocol-metrics.json').write_text(json.dumps(dict(finished=True,transactions=m['owner_events'],resets=m['resets']))+'\n',encoding='utf-8')
    module_path=Path(__file__).resolve().parents[1]/'deps/frame_owner_reference.py'
    spec=importlib.util.spec_from_file_location('frozen_owner_reference',module_path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    module.audit(audit_dir)
    return dict(status='PASS',requests=counts['REQ'],responses=counts['RSP'],changes=counts['APPLY'],ticks=counts['TICK'],faults=counts['FAULT'],status_counts=dict(hist),complete_bundle_verified=True,owner_reference_verified=True,full_scan_cycles=1237500 if m['full_scan'] else None,physical_cdc_verified=False)

def audit(path):
    root=Path(path);m=json.loads((root/'protocol-metrics.json').read_text(encoding='utf-8'));assert m['finished']
    result=mailbox(root,m) if m['kind']=='mailbox' else handoff(root,m)
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':audit(sys.argv[1])
