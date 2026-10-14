"""WT1..7: independent request/full-word/bus/byte-memory ledger, no DUT hierarchy."""
from pathlib import Path
from collections import Counter
import csv,json,hashlib,sys

def n(bits):
    assert set(bits)<={'0','1'},f'unknown active field {bits}'
    return int(bits,2)

def bit(bits,p):return n(bits[-1-p])
def known(bits):return set(bits)<={'0','1'}
def aw_fields(bits):return tuple(n(bits[a:b]) for a,b in ((0,32),(32,36),(36,44),(44,47),(47,49)))

def audit(directory):
    root=Path(directory);app=None;credit=3;local=False;bridge=False;reason=0;held={};counts=Counter()
    accepted={};replied={};reset_aborted={};grants={};final={};seen=set();observed_memory={};expected_memory={}
    with (root/'write-memory.tsv').open(encoding='utf-8',newline='') as f:
        snapshots={int(row['cycle']):row for row in csv.DictReader(f,delimiter='\t')}
    snapshots_seen=set()
    def check(ok,msg):
        if not ok:raise AssertionError(f'case {case} cycle {cycle}: {msg}')
    with (root/'write-events.tsv').open(encoding='utf-8',newline='') as f:
        for row in csv.DictReader(f,delimiter='\t'):
            case=int(row['case']);cycle=int(row['cycle']);seen.add(case)
            check(cycle==counts['cycles'],'missing/duplicate public trace cycle');counts['cycles']+=1
            rst=n(row['rst']);enable=n(row['enable']);cr=n(row['cr']);rv=n(row['rv']);rr=n(row['rr'])
            av=n(row['av']);ar=n(row['ar']);wv=n(row['wv']);wr=n(row['wr']);bv=n(row['bv']);br=n(row['br'])
            af=bool(av and ar);wf=bool(wv and wr);bf=bool(bv and br);replies=rv&rr
            if rst:
                check(cr==rv==av==wv==br==0,'reset permitted application or bus handshake')
                if app is not None:
                    if not app['notice_consumed']:
                        reset_aborted.setdefault(app['case'],Counter())[app['owner']]+=1;counts['reset_aborted_applications']+=1
                    else:counts['reset_retained_unknown_records']+=1
                    if app['aw'] and not app['confirmed']:counts['reset_aborted_physical_records']+=1
                app=None;credit=3;local=False;bridge=False;reason=0;held.clear();observed_memory.clear();expected_memory.clear();counts['reset_rows']+=1
                continue
            q=n(row['q']);lq=n(row['lq']);bq=n(row['bq']);busy=n(row['busy'])
            check((lq,bq,q)==(int(local),int(bridge),int(local or bridge)),'quarantine/actual OR wrong')
            check(int(row['fault'])==(reason if reason else (4 if bridge else 0)),'first fault wrong')
            check(busy==int(app is not None or q),'unknown owner was released/false busy')
            if q:check(cr==0,'Q admitted new request');counts['q_rows']+=1
            check(rv in (0,1,2),'two client notices at once')
            for name,valid,ready,body in [('AW',av,ar,row['a']),('W',wv,wr,row['w']),('B',bv,br,row['b'])]:
                if name in held:check(valid and body==held[name],name+' withdrawn/changed while stalled')
                if valid and not ready:held[name]=body;counts[name+'_stall_rows']+=1
                else:held.pop(name,None)
            for p in (0,1):
                name='reply'+str(p);valid=bit(row['rv'],p);ready=bit(row['rr'],p);body=row['er'][-1-p]+row['dr'][-1-p]
                if name in held:check(valid and body==held[name],name+' body changed while stalled')
                if valid and not ready:held[name]=body;counts['reply_stall_rows']+=1
                else:held.pop(name,None)
            cv=row['cv'];b_id=n(row['b'][:4]);b_resp=n(row['b'][4:]);fault=0
            # Public phase evidence defines error handling; no hidden bridge state is copied.
            if app is None and bv:fault=2;counts['unowned_b_rows']+=1
            elif app is not None and app['words']<4 and not rv and bv and not(wf and n(row['w'][-1])==1):
                fault=3;app['early']=True;counts['early_b_rows']+=1
            elif app is None and not q and enable and (not known(cv) or n(cv)!=0):
                chosen=0 if cv[-1]=='1' and not(cv[-2]=='1' and credit==0) else 1
                if not known(cv) or not known(row['ca'+str(chosen)]):fault=1;counts['unknown_request_rows']+=1
            expected_ready=0
            if app is None and not q and enable and fault==0 and known(cv) and n(cv)!=0:
                chosen=0 if bit(cv,0) and not(bit(cv,1) and credit==0) else 1
                expected_ready=1<<chosen
            check(cr==expected_ready,'client ready not actual permitted selection')
            fire=(n(cv)&cr) if known(cv) else 0
            if fire:
                p=0 if fire==1 else 1;check(fire in (1,2) and app is None,'multiple live client requests')
                body=row['ca'+str(p)];addr=n(body[:32]);value=n(body[32:])
                app={'case':case,'owner':p,'addr':addr,'data':value,'valid':addr%64==0 and addr+64<=0x10000000,
                     'aw':False,'words':0,'confirmed':False,'uncertain':False,'wrong_b':False,'early':False,'b_resp':None,'notice_consumed':False}
                credit=3 if p==1 else max(0,credit-1)
                accepted.setdefault(case,Counter())[p]+=1;grants.setdefault(case,[]).append(p);counts['requests']+=1
            if app is not None and app['valid'] and not app['confirmed'] and not rv and not enable:
                app['uncertain']=True
            if av:
                check(app is not None and app['valid'] and not app['aw'],'AW without accepted valid app')
                check(aw_fields(row['a'])==(app['addr'],0,3,4,1),'full49 AW differs from captured address/geometry')
            if af:app['aw']=True;counts['physical_aw']+=1
            if wv:
                check(app is not None and app['aw'] and app['words']<4,'W without correct physical identity')
                value=n(row['w'][:128]);strobe=n(row['w'][128:144]);last=n(row['w'][144:])
                check((value,strobe,last)==((app['data']>>(128*app['words']))&((1<<128)-1),65535,int(app['words']==3)),'full145 W/data/strobe/last mismatch')
            if wf:
                addr=app['addr']+16*app['words'];want=(app['data']>>(128*app['words']))&((1<<128)-1);got=n(row['w'][:128])
                for i in range(16):
                    observed_memory[addr+i]=(got>>(8*i))&255;expected_memory[addr+i]=(want>>(8*i))&255
                app['words']+=1;counts['physical_w']+=1;counts['physically_written_bytes']+=16
                if q:counts['old_w_consumed_in_q']+=1
            if bf:
                check(app is not None and app['aw'] and app['words']==4,'B consumed before complete physical write')
                if b_id!=0:app['wrong_b']=True;bridge=True;counts['wrong_bid_events']+=1
                else:
                    snap=snapshots.get(cycle);check(snap is not None,'missing actual byte-memory snapshot')
                    check(int(snap['case'])==case and n(snap['addr'])==app['addr'] and n(snap['data'])==app['data'],'full512 actual slave memory differs')
                    reconstructed=sum(observed_memory[app['addr']+i]<<(8*i) for i in range(64))
                    check(reconstructed==app['data'] and observed_memory==expected_memory,'all actual byte side effects differ')
                    snapshots_seen.add(cycle);counts['full512_memory_snapshots']+=1
                    if app['uncertain']:bridge=True
                    if app['wrong_b'] or app['early'] or app['uncertain']:counts['unqualified_correct_b_events']+=1
                    else:app['confirmed']=True;app['b_resp']=b_resp
                    if b_resp:counts['nonok_b_events']+=1
                if q:counts['old_b_consumed_in_q']+=1
                counts['physical_b']+=1
            if rv:
                check(app is not None and rv==(1<<app['owner']) and not app['notice_consumed'],'notice lost/duplicated/wrong owner')
                unknown=app['wrong_b'] or app['early'] or app['uncertain']
                if not app['valid']:error,drained=1,1;check(not app['aw'],'invalid input produced AW')
                elif unknown:error,drained=1,0;check(app['wrong_b'] or app['b_resp'] is None,'unknown without fault')
                else:
                    check(app['confirmed'] and app['words']==4,'success/error reply before real B')
                    error,drained=int(app['b_resp']!=0),1
                p=app['owner'];check((bit(row['er'],p),bit(row['dr'],p))==(error,drained),'reply error/drained altered')
            if replies:
                p=app['owner'];check(replies==1<<p,'other client consumed this result')
                replied.setdefault(case,Counter())[p]+=1;counts['replies']+=1
                if q:counts['old_reply_consumed_in_q']+=1
                if bit(row['dr'],p):app=None
                else:app['notice_consumed']=True
            if fault and not local:local=True;reason=fault
            final[case]=(q,lq,bq,int(row['fault']),busy)
    result=json.loads((root/'write-result.json').read_text(encoding='utf-8'))
    assert result['finished'] is True and result['cases']==35 and seen==set(range(1,36))
    for k in ('cycles','requests','replies','physical_aw','physical_w','physical_b'):assert result[k]==counts[k],(k,result[k],counts[k])
    assert snapshots_seen==set(snapshots)
    assert grants[1]==grants[2]==[0,0,0,1]*16
    assert grants[3]==[0]*24 and grants[4]==[1]*24
    limits={1:(48,16),2:(48,16),3:(24,0),4:(0,24),5:(16,16),6:(1,0),7:(1,0),8:(0,1),9:(3,0),10:(0,3),11:(3,3),12:(3,1)}
    for case in range(1,36):
        a=accepted.get(case,Counter());r=replied.get(case,Counter());z=reset_aborted.get(case,Counter())
        if case in limits:assert (a[0],a[1])==limits[case],(case,a)
        if case in (26,27,28,29):assert (a[0],a[1])==(2,1) and z[0]==1 and z[1]==0
        elif 13<=case<=18:assert a[case%2]==1
        elif case in (19,20,24,25,34):assert (a[0],a[1])==(1,0)
        elif case in (21,22):assert (a[0],a[1])==(0,1)
        elif case in (23,30,31,32,33,35):assert not a and not r
        # UNKNOWN physical records remain occupied even after their notification was consumed.
        assert a==r+z,(case,a,r,z)
        if 13<=case<=18 or case in (21,22):assert final[case]==(1,0,1,4,1),(case,final[case])
        elif case in (20,23):assert final[case]==(1,1,0,2,1),(case,final[case])
        elif case==24:assert final[case]==(1,1,0,3,1)
        elif case in (30,31,32,33,35):assert final[case]==(1,1,0,1,1)
        else:assert final[case]==(0,0,0,0,0),(case,final[case])
    assert counts['full512_memory_snapshots']>=200 and counts['physical_w']>=800
    assert counts['AW_stall_rows']>0 and counts['W_stall_rows']>0 and counts['reply_stall_rows']>0
    assert counts['wrong_bid_events']>=3 and counts['early_b_rows']>0 and counts['unowned_b_rows']>0 and counts['unknown_request_rows']>0
    assert counts['reset_aborted_applications']>=4 and counts['old_b_consumed_in_q']>=3 and counts['old_reply_consumed_in_q']>=9
    assert app is None and local and reason==1 and not held.get('AW') and not held.get('W')
    audit={'status':'PASS','cases':35,'counts':dict(counts),'public_full_bus_and_application_ledger':True,'full512_slave_memory_verified':True,
           'fair_grants_case1':grants[1],'fair_grants_case2':grants[2],'reset_aborted_by_case':{str(k):dict(v) for k,v in reset_aborted.items()},
           'trace_sha256':hashlib.sha256((root/'write-events.tsv').read_bytes()).hexdigest().upper(),
           'memory_snapshots_sha256':hashlib.sha256((root/'write-memory.tsv').read_bytes()).hexdigest().upper(),
           'actual_bridge_verified':True,'actual_producer_integration_verified':False,'actual_ddr_verified':False,'frame_reference_authority_verified':False,
           'qos_deadline_verified':False,'warm_reset_drain_verified':False,'full_project_goal_complete':False}
    (root/'write-audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(audit,ensure_ascii=False))

if __name__=='__main__':
    assert len(sys.argv)==3 and sys.argv[1]=='audit'
    audit(sys.argv[2])
