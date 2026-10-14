"""DR01..07: independent immutable row contents and borrow-set audit."""
from pathlib import Path
from collections import deque,Counter
import json,sys

MAX=(1<<64)-1
FIELDS=[('generation',64),('sequence',64),('scan',64),('result',64),('policy',64),('origin',195),('target',11),('source',11),('mode',3),('mask',3)]
def decode(x):
    result={}
    for name,width in reversed(FIELDS):result[name]=x&((1<<width)-1);x>>=width
    assert not x
    return result
def valid(t,h):
    mode,y=t['mode'],t['target'];mask=[1 if y<h//2 else 2,1,1,2,3,7][mode] if mode<6 else 0
    sy=2*(y%(h//2)) if mode==0 else y
    return all(t[k] for k in ['sequence','scan','result','policy']) and t['origin']>>131!=0 and t['origin']>>131==(t['origin']>>3)&MAX and t['origin']&7<6 and y<h and t['source']<h and mode<6 and t['mask']==mask and t['source']==sy
def pattern(t,address):
    value=0;y=t['source'];f=(t['origin']>>99)&0xffffffff
    for lane in range(2):
        x=2*address+lane
        rgb=(((x*37+y*11+f*3)%256)<<16)|(((x*13+y*47+f*7)%256)<<8)|((x*53+y*19+f*17)%256)
        value|=rgb<<(lane*24)
        value|=int((x+y+f)%3==0)<<(48+lane)
        value|=((x*7+y*3+f)%4)<<(50+2*lane)
    return value
def audit(root):
    root=Path(root);m=json.loads((root/'protocol-metrics.json').read_text(encoding='utf-8'));assert m['finished']
    banks=None;counts=Counter();writes=reads=errors=rows=returns=resets=reset_aborted=0
    for line in (root/'row-events.csv').read_text(encoding='utf-8').splitlines():
        row=line.split(',');kind=row[0];counts[kind]+=1
        if kind=='RESET':
            if banks:
                assert all(not b['pending'] for b in banks),'safe reset test must stop native pending accesses'
                reset_aborted+=sum(b['state']=='owned' for b in banks)
            w,h=int(row[2]),int(row[3]);initial=int(row[4],16)
            banks=[dict(generation=initial,ticket=None,value=None,state='free',memory={},pending=deque(),issued=0,served=0,released=None) for _ in range(3)];resets+=1;continue
        b=int(row[2]);s=banks[b]
        if kind=='FILL':
            assert s['state']=='free'
            s.update(ticket=decode(int(row[3],16)),value=int(row[3],16),state='reply',memory={},issued=0,served=0,released=None)
        elif kind=='FILL_REPLY':
            assert s['state']=='reply' and int(row[3],16)==s['value']
            t=s['ticket'];status=1 if not valid(t,h) else 2 if t['generation']!=s['generation'] else 0
            assert int(row[4])==status
            s['state']='fill' if status==0 else 'free'
        elif kind=='WRITE':
            writes+=1;assert s['state']=='fill';gen,address,data=int(row[3],16),int(row[4]),int(row[5],16)
            if gen!=s['generation'] or address!=len(s['memory']):s['state']='q'
            else:
                assert address<w//2 and data==pattern(s['ticket'],address)
                s['memory'][address]=data
        elif kind=='PUBLISH':
            assert s['state']=='fill' and int(row[3],16)==s['generation'] and row[4:6]==['1','1'] and len(s['memory'])==w//2
            s['state']='published'
        elif kind=='ABORT':
            assert s['state']=='fill' and int(row[3],16)==s['generation'] and row[4:6]==['1','1']
            assert not s['pending'];s['released']=1;s['state']='returned'
        elif kind=='ROW':
            assert s['state']=='published' and int(row[3],16)==s['value'];s['state']='owned';rows+=1
        elif kind=='READ':
            assert s['state']=='owned';gen,address=int(row[3],16),int(row[4])
            bad=gen!=s['generation'] or address!=s['issued'] or address>=w//2
            s['pending'].append((address,0 if bad else s['memory'][address],int(bad)))
            if not bad:s['issued']+=1
        elif kind=='DATA':
            assert s['state']=='owned' and s['pending']
            actual=int(row[3]),int(row[4],16),int(row[5]);expected=s['pending'].popleft();assert actual==expected,(b,actual,expected)
            reads+=1;errors+=actual[2]
            if not actual[2]:s['served']+=1
        elif kind=='RELEASE':
            assert s['state']=='owned' and not s['pending']
            gen,k=int(row[3],16),int(row[4])
            if gen==s['generation'] and k<2 and (k==1 or s['served']==w//2):s['released']=k;s['state']='returned'
            else:s['bad_release']=True
        elif kind=='RELEASE_ERROR':
            # 下一周期脉冲可以与随后正确release同沿；必须有先前错误凭证。
            assert s.pop('bad_release',False)
        elif kind=='WRITE_ERROR':assert s['state']=='q'
        elif kind=='RETURN':
            assert s['state']=='returned' and int(row[3],16)==s['value'] and int(row[4])==s['released'];returns+=1
            s['state']='free';s['generation']=None if s['generation']==MAX else s['generation']+1
        else:raise AssertionError(row)
    assert (writes,reads,errors,rows,returns,resets)==tuple(m[k] for k in ['writes','reads','errors','rows','returns','resets'])
    assert all(not b['pending'] for b in banks) and reset_aborted==m['safe_reset_aborted_rows'] and rows-reset_aborted==m['row_count']
    if m.get('join'):
        assert reads==1 and errors==0 and all(b['state']=='free' for b in banks)
        join_result=audit_join(root,m)
    elif m['near_max']:
        assert reads==rows*(m['width']//2)+3 and all(b['generation'] is None and b['state']=='free' for b in banks)
    else:assert [b['state'] for b in banks]==['q','free','free']
    if not m.get('join'):assert reads==(rows-reset_aborted)*(m['width']//2)+3
    result=dict(status='PASS',writes=writes,read_responses=reads,error_responses=errors,complete_rows=rows-reset_aborted,safe_reset_aborted_rows=reset_aborted,returns=returns,events=dict(counts),all_54_bits_verified=True,borrow_sets_verified=True,actual_ddr_verified=False,physical_cdc_verified=False)
    if m.get('join'):result['handoff_join']=join_result
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))
def unpack(value,fields):
    out={}
    for name,width in reversed(fields):out[name]=value&((1<<width)-1);value>>=width
    assert not value;return out
def audit_join(root,m):
    req_fields=[('kind',3),('sequence',64),('cause',64),('target',64),('bundle',942)]
    rsp_fields=[('kind',3),('status',3),('sequence',64),('cause',64),('policy',64),('bundle',942),('previous',64),('active',1),('hold',1),('closed',1)]
    requests={};returned={};closed=None;ticks=[];applies=[];responses=[];canceled=False
    for line in (root/'handoff-link-events.csv').read_text(encoding='utf-8').splitlines():
        row=line.split(',');kind=row[0];time=int(row[1])
        if kind=='REQ':
            q=unpack(int(row[2],16),req_fields);assert q['kind']==0 and q['target']==1 and q['cause']==0 and q['sequence'] not in requests;requests[q['sequence']]=q
        elif kind=='TICK':
            old_scan=int(row[2],16);t=decode(int(row[3],16));qualified=int(row[4]);ticks.append((time,old_scan,t,qualified))
            assert old_scan==len(ticks)-1
        elif kind=='APPLY':
            assert not canceled and ticks[-1][1]==1 and ticks[-1][2]['scan']==2 and ticks[-1][2]['sequence']==777 and ticks[-1][3]
            assert int(row[2],16)==requests[777]['bundle'] and int(row[3],16)==2;applies.append(time)
        elif kind=='CANCEL':assert int(row[2],16)==778;canceled=True
        elif kind=='ROW_RETURN':returned[int(row[2])]=(time,int(row[3],16))
        elif kind=='CLOSED':
            assert 2 in returned and time>returned[2][0] and int(row[2],16)==returned[2][1]
            assert decode(int(row[2],16))['sequence']==778;closed=(time,int(row[2],16))
        elif kind=='RSP':
            r=unpack(int(row[2],16),rsp_fields);q=requests[r['sequence']]
            expected=dict(kind=0,status=0 if r['sequence']==777 else 4,sequence=q['sequence'],cause=0,policy=1,bundle=q['bundle'],previous=0,active=1,hold=0,closed=0 if r['sequence']==777 else 1)
            assert r==expected
            if r['sequence']==778:assert canceled and closed and time>closed[0]
            responses.append(r['sequence'])
        else:raise AssertionError(row)
    assert responses==[777,778] and len(applies)==1 and len(ticks)==3 and len(returned)==2 and m['requests']==m['responses']==2
    return dict(status='PASS',qualified_apply=1,canceled_after_actual_row_return=1,held_last_record_blocks_closure=True,complete_messages_verified=True)
if __name__=='__main__':audit(sys.argv[1])
