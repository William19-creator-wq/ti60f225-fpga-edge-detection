"""RPT1..7: public application and bus ledger; never reads DUT hierarchy/state."""
from pathlib import Path
from collections import Counter, deque
import csv, json, hashlib, sys

def n(bits):
    assert set(bits) <= {'0', '1'}, f'unknown public field {bits}'
    return int(bits, 2)

def ar(bits):
    return tuple(n(bits[a:b]) for a,b in ((0,32),(32,36),(36,44),(44,47),(47,49)))

def word(address):
    return int.from_bytes(bytes(((address+i)*37+11)%256 for i in range(16)), 'little')

def line(address):
    return sum(word(address+16*i) << (128*i) for i in range(4))

def expected_line(case):
    if case in {23,27,28,29}: return 1,0
    if case in {8,9,16}: return 1,1
    return 0,1

def expected_span(case):
    if 10<=case<=15: return 1,1,1
    if case==17: return 1,2,1
    if 18<=case<=21: return 2,128,1
    if 24<=case<=26: return 3,4,0
    if 30<=case<=32: return 3,3,0
    return 0,0,1

def wanted_requests(case):
    if case==1:return 16,4
    if case==2:return 8,3
    if case in {3,4,5,7,10,11,12,13,14,15,17,18,19,20,21,22,24,25,26}:return 0,1
    if case in {6,8,9,16,23,27,28,29}:return 1,0
    if case in {30,31,32}:return 1,1
    if case in {33,34,35}:return 2,2
    if case==36:return 3,2
    if case==37:return 2,0
    if case==38:return 3,3
    raise AssertionError(case)

def audit(directory):
    root=Path(directory); apps={0:None,2:None}; bus=None; bus_unknown=False
    display_queue=deque(); held={}; pending_ar=None
    counts=Counter(); accepted={}; completed={}; aborted={}; grants={}; seen=set(); final={}
    def check(ok, message):
        if not ok:raise AssertionError(f'case {case} cycle {cycle}: {message}')
    with (root/'pair-events.tsv').open(encoding='utf-8',newline='') as f:
        for row in csv.DictReader(f,delimiter='\t'):
            case=int(row['case']);cycle=int(row['cycle']);seen.add(case)
            check(cycle==counts['cycles'],'trace skipped/duplicated cycle');counts['cycles']+=1
            rst=n(row['rst']);q=n(row['q']);bq=n(row['bq']);sq=n(row['sq']);lq=n(row['lq'])
            mav=n(row['mav']);mar=n(row['mar']);mrv=n(row['mrv']);mrr=n(row['mrr'])
            af=bool(mav and mar);rf=bool(mrv and mrr)
            lv=n(row['lrv']);dv=n(row['dv']);nv=n(row['nev'])
            lfire=n(row['lqv']) and n(row['lqr']);sfire=n(row['sqv']) and n(row['sqr'])
            reply=lv and n(row['lrr']);data=dv and n(row['dr']);notice=nv and n(row['ner'])
            if rst:
                check(not(mav or mrr or lv or dv or nv or lfire or sfire),'reset permitted handshake')
                for owner,app in apps.items():
                    if app is not None:
                        aborted.setdefault(app['case'],Counter())[owner]+=1
                        counts['reset_aborted_applications']+=1
                if bus is not None:counts['reset_aborted_bursts']+=1
                apps={0:None,2:None};bus=None;bus_unknown=False;display_queue.clear();held.clear();pending_ar=None
                counts['reset_rows']+=1;continue
            check(q==(lq|sq|bq),'globalQ not actual OR')
            if q:
                check(n(row['lqr'])==0 and n(row['sqr'])==0,'Q admitted new application')
                counts['q_rows']+=1
            if bus_unknown:
                check(bq==1 and n(row['occupied'])==1 and n(row['idle'])==0,'unknown physical owner released')
            check(not(n(row['idle']) and n(row['occupied'])),'physical state contradicts itself')
            final[case]=(q,lq,sq,bq,int(row['fault']),n(row['idle']),n(row['occupied']))
            # Full payload stability applies only while valid is waiting for its consumer.
            for name,valid,ready,body in (
                ('AR',mav,mar,row['ma']),('R',mrv,mrr,row['mr']),
                ('line',lv,n(row['lrr']),row['lbody']),('data',dv,n(row['dr']),row['ddata']),
                ('notice',nv,n(row['ner']),row['nbody'])):
                if name in held:check(valid and body==held[name],f'{name} withdrawn/changed while stalled')
                if valid and not ready:held[name]=body;counts[name+'_stall_rows']+=1
                else:held.pop(name,None)
            if n(row['idle']) and (lv or dv or nv):counts['physical_idle_with_application_holding']+=1
            # Accept app identity before considering a later physical transaction.
            for owner,fire,addr,bytes_ in ((0,lfire,n(row['laddr']),64),(2,sfire,n(row['saddr']),int(row['sbytes']))):
                if fire:
                    check(apps[owner] is None,'duplicate live application identity')
                    valid=addr%(64 if owner==0 else 16)==0 and addr+bytes_<=0x10000000
                    if owner==2:valid &= 16<=bytes_<=8192 and bytes_%16==0
                    apps[owner]={'case':case,'addr':addr,'bytes':bytes_,'next':addr,'ars':0,'rwords':0,'data':0,
                                 'valid':valid,'stopped':bool(n(row['cancel'])) if owner==2 else False,
                                 'disabled':False,'bad':False,'resp_error':False}
                    accepted.setdefault(case,Counter())[owner]+=1;counts['line_requests' if owner==0 else 'span_requests']+=1
            for owner,app in apps.items():
                if app is not None:
                    if owner==2 and n(row['cancel']):app['stopped']=True
                    if not n(row['aen' if owner==0 else 'den']) and not(lv if owner==0 else nv):
                        app['disabled']=True
                        if owner==2:app['stopped']=True
            if mav:
                body=ar(row['ma']);addr,rid,length,size,burst=body
                check(rid in (0,2),'physical ID not an actual leaf')
                app=apps[rid];check(app is not None and app['valid'],'AR without valid app')
                check(size==4 and burst==1 and addr%16==0 and addr+16*(length+1)<=0x10000000,'physical AR geometry')
                check(addr%4096+16*(length+1)<=4096 and length<=63,'physical AR page/length')
                check(addr==app['next'],'AR duplicate or wrong application offset')
                if rid==0:check(length==3 and app['ars']==0,'algorithm read not exactly one 64B line')
                else:
                    left=(app['addr']+app['bytes']-addr)//16
                    check(length+1==min(left,64,(4096-addr%4096)//16),'display span split differs')
                    if app['stopped'] or app['resp_error']:
                        check(pending_ar==row['ma'],'new display burst after stop/error')
                pending_ar=row['ma']
            if af:
                check(bus is None,'more than one physical read outstanding')
                addr,rid,length,size,burst=ar(row['ma']);app=apps[rid]
                bus={'owner':rid,'addr':addr,'beats':length+1,'index':0}
                app['ars']+=1;app['next']=addr+16*(length+1);pending_ar=None
                grants.setdefault(case,[]).append(rid);counts['physical_ar']+=1
                if mrv:counts['same_ar_edge_r_valid']+=1;check(not rf,'zero-delay R consumed before leaf AR acceptance')
            if dv:
                check(apps[2] is not None and display_queue,'display data without previously accepted good R')
                check(n(row['ddata'])==display_queue[0],'full128 display word changed/address mismatch')
            if data:
                display_queue.popleft();apps[2]['data']+=1;counts['display_words']+=1
                if q:counts['old_display_data_consumed_in_q']+=1
            if rf:
                check(bus is not None,'R without physical read identity')
                value=n(row['mr'][:128]);rid=n(row['mr'][128:132]);resp=n(row['mr'][132:134]);last=n(row['mr'][134:])
                check(value==word(bus['addr']+16*bus['index']),'full128 slave address/beat value mismatch')
                app=apps[bus['owner']];check(app is not None,'physical R app identity lost')
                good=rid==bus['owner'] and last==int(bus['index']==bus['beats']-1)
                if not good and not bus_unknown:
                    app['bad']=True;bus_unknown=True;counts['malformed_r_events']+=1
                if good and not bus_unknown:
                    app['rwords']+=1
                    if resp:app['resp_error']=True;counts['resp_error_words']+=1
                    if bus['owner']==2 and resp==0 and not(app['stopped'] or app['resp_error']):
                        display_queue.append(value)
                if q:counts['old_r_consumed_in_q']+=1
                bus['index']+=1;counts['physical_r']+=1
                if good and not bus_unknown and bus['index']==bus['beats']:bus=None
            if lv:
                app=apps[0];check(app is not None,'line reply without app')
                error,drained=expected_line(case);body=n(row['lbody'])
                check((body&3)==(2*error+drained),'line error/drained disagrees with explicit scenario')
                check((body>>2)==(0 if error else line(app['addr'])),'full512 line result differs')
                if not error:check(app['ars']==1 and app['rwords']==4 and not app['bad'],'successful line missing real burst')
                if error and drained:
                    check((not app['valid'] and app['ars']==0) or (app['resp_error'] and app['rwords']==4),'error reply without rejected input/real drain')
                if error and not drained:check(app['bad'] or app['disabled'],'unknown line without real fault/disable')
            if reply:
                completed.setdefault(case,Counter())[0]+=1;apps[0]=None;counts['line_replies']+=1
                if q:counts['old_line_reply_consumed_in_q']+=1
            if nv:
                app=apps[2];check(app is not None,'display notice without app')
                check(not display_queue and not dv,'display notice outran old held data')
                outcome,reason,drained=expected_span(case)
                check(n(row['nbody'])==((outcome<<9)|(reason<<1)|drained),'display outcome/reason/drained differs')
                if outcome==0:
                    check(app['valid'] and app['data']==app['bytes']//16 and not(app['bad'] or app['resp_error']),'OK span incomplete')
                if outcome==1 and reason==1:check(not app['valid'] and app['ars']==0,'invalid span emitted physical request')
                if outcome==1 and reason==2:check(app['resp_error'],'display ERROR without RESP')
                if outcome==2:check(app['stopped'],'CANCEL without stop event')
                if outcome==3:check(app['bad'] or app['disabled'],'UNKNOWN without error/disable')
            if notice:
                completed.setdefault(case,Counter())[2]+=1;apps[2]=None;counts['span_dones']+=1
                if q:counts['old_notice_consumed_in_q']+=1
    metrics=json.loads((root/'pair-result.json').read_text(encoding='utf-8'))
    assert metrics['finished'] is True and metrics['cases']==38 and seen==set(range(1,39))
    for key in ('cycles','physical_ar','physical_r','line_requests','span_requests','line_replies','span_dones'):
        assert metrics[key]==counts[key],(key,metrics[key],counts[key])
    for case in range(1,39):
        la,sa=wanted_requests(case);actual=accepted.get(case,Counter());done=completed.get(case,Counter());reset=aborted.get(case,Counter())
        assert (actual[0],actual[2])==(la,sa),(case,actual)
        assert actual==done+reset,(case,actual,done,reset)
        if case in (33,34,35):assert reset[0]==reset[2]==1
        else:assert not reset
        if case in {8,9,10,11,12,13,14,15,18,24}:assert not grants.get(case),(case,grants.get(case))
        q,lq,sq,bq,fault,idle,occupied=final[case]
        if 23<=case<=26:
            assert q==1 and bq==0 and idle==1 and occupied==0
            assert (lq,sq)==((1,0) if case==23 else (0,1))
        elif 27<=case<=32:
            assert q==bq==occupied==1 and idle==0 and fault==(3 if case in (27,30) else 4)
            assert (lq,sq)==((1,0) if case<=29 else (0,1))
        else:assert (q,bq,idle,occupied)==(0,0,1,0),(case,final[case])
    assert apps=={0:None,2:None} and bus is None and not display_queue and not held
    assert counts['physical_r']>4500 and counts['display_words']>4000
    assert all(counts[k]>0 for k in ('AR_stall_rows','R_stall_rows','line_stall_rows','data_stall_rows','notice_stall_rows'))
    assert counts['same_ar_edge_r_valid']>=1 and counts['malformed_r_events']==6
    assert counts['old_r_consumed_in_q']>0 and counts['old_line_reply_consumed_in_q']>=3 and counts['old_notice_consumed_in_q']>=6
    assert counts['reset_aborted_applications']==6 and counts['reset_aborted_bursts']>=1
    result={'status':'PASS','cases':38,'public_app_and_full_bus_ledger':True,'counts':dict(counts),
            'requests_by_case':{str(k):dict(v) for k,v in accepted.items()},'reset_aborted_by_case':{str(k):dict(v) for k,v in aborted.items()},
            'physical_grants_by_case':grants,'trace_sha256':hashlib.sha256((root/'pair-events.tsv').read_bytes()).hexdigest().upper(),
            'actual_three_leaf_rtl_integration_verified':True,'actual_ddr_verified':False,'warm_reset_drain_verified':False,
            'frame_reference_authority_verified':False,'qos_deadline_verified':False,'full_project_goal_complete':False}
    (root/'pair-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False))

if __name__=='__main__':
    assert len(sys.argv)==3 and sys.argv[1]=='audit'
    audit(sys.argv[2])
