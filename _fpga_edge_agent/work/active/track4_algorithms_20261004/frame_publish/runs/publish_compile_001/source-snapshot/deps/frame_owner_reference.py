"""FO01..07：事件级对象/存活租约集合参考，无RTL数组next-state结构。"""
import json,sys,collections
from pathlib import Path

CMD=[('op',4),('flags',8),('source',64),('result',64),('origin',195),('cj',142),('body',400),('policy',64)]
REP=[('op',4),('status',4),('source',64),('result',64),('origin',195),('cj',142),('body',400),('policy',64),('ss',3),('rs',2)]
MAX=(1<<64)-1
def decode(value,fields):
    d={}
    for key,width in reversed(fields):d[key]=value&((1<<width)-1);value>>=width
    assert not value
    return d
def desc(base,length):return (base<<64)|(length<<32)|((length+15)//16*16)

class Ledger:
    def __init__(self,w,h,initial):
        self.w,self.h=w,h;self.source={};self.result={};self.next_s=self.next_r=self.policy=initial
        self.se=self.re=False;self.latest=self.freeze=0;self.frozen=self.q=False
    def active_source(self,key):return next(((i,s) for i,s in self.source.items() if s['state'] and s['key']==key),(-1,None))
    def active_result(self,key):return next(((i,s) for i,s in self.result.items() if s['state'] and s['key']==key),(-1,None))
    def collect(self):
        readers={r['source'] for r in self.result.values() if r['state']}
        keep=readers|{self.latest,self.freeze}
        for s in self.source.values():
            if s['state'] in (3,4) and s['key'] not in keep:s['state']=0
        for r in self.result.values():
            if r['state']:
                _,s=self.active_source(r['source']);assert s is not None
        assert sum(r['state']==3 for r in self.result.values())<=1
        assert sum(r['state']==4 for r in self.result.values())<=1
    def event(self,c):
        op,flags=c['op'],c['flags'];status=0;sk,s=self.active_source(c['source']);rk,r=self.active_result(c['result'])
        old_policy=self.policy;selected_s=None;selected_r=None
        sm=s is not None and s['origin']==c['origin']
        rm=r is not None and r['source']==c['source'] and self.source[r['ss']]['origin']==c['origin'] and r['cj']==c['cj'] and r['policy']==c['policy']
        masks={2:7,4:7,3:16,7:14,8:10,9:1}
        if op>11 or flags&~masks.get(op,0):status=5
        elif op==0:
            slot=next((i for i in range(6) if not self.source.get(i,{}).get('state',0)),-1)
            fe=(c['origin']>>67)&MAX
            collision=any(s['state'] and ((s['origin']>>67)&MAX)==fe for s in self.source.values())
            if self.q:status=8
            elif self.se:status=7
            elif collision:status=4
            elif slot<0:status=1
            else:
                t=self.next_s;self.source[slot]={'key':t,'origin':(t<<131)|(fe<<67)|(t<<3)|slot,'state':1,'ss':slot}
                selected_s=self.source[slot]
                if t==MAX:self.se=True
                else:self.next_s+=1
        elif op in (1,2):
            if not sm:status=4
            elif s['state'] not in (1,2):status=3
            elif op==1:
                if s['state']!=1:status=3
                else:s['state']=2;selected_s=s
            elif flags&6!=6:s['state']=5;self.q=True;status=8
            elif flags&1:
                if s['state']!=2:status=3
                else:
                    s['state']=3;self.latest=max(self.latest,s['key']);selected_s=s
                    if self.frozen and not self.freeze:self.freeze=s['key']
            else:s['state']=4;selected_s=s
        elif op==3:
            slot=next((i for i in range(3) if not self.result.get(i,{}).get('state',0)),-1)
            if c['source']:picked=(sk,s) if sm else (-1,None)
            else:picked=self.active_source(self.freeze if self.frozen else self.latest)
            ps,source=picked;mode=(c['body']>>109)&7
            if self.q:status=8
            elif self.re:status=7
            elif slot<0:status=1
            elif c['source'] and not sm:status=4
            elif source is None:status=2
            elif source['state']!=3 and not(flags&16 and c['source'] and source['state'] in (1,2)):status=6
            elif ((c['cj']>>96)&2047)!=self.w or ((c['cj']>>107)&2047)!=self.h or ((c['cj']>>118)&2047)>((c['cj']>>129)&2047) or mode>5 or ((c['body']>>98)&2047)!=self.h//2 or c['body']>>112:status=5
            else:
                n=self.w*self.h;src=desc(ps*0x800000,3*n);edge=desc(0x3000000+slot*0x800000,(n+7)//8) if mode not in (1,2) else 0
                ann=desc(0x3100000+slot*0x800000,4224+(n+3)//4) if mode==5 else 0
                self.result[slot]={'key':self.next_r,'state':1,'source':source['key'],'ss':ps,'rs':slot,'policy':self.policy,
                    'cj':((c['cj']>>64)<<64)|((source['origin']>>67)&MAX),'body':(src<<304)|(edge<<208)|(ann<<112)|(c['body']&((1<<112)-1))}
                selected_r=self.result[slot]
                if self.next_r==MAX:self.re=True
                else:self.next_r+=1
        elif op in (4,5,6,7,8):
            if not rm:status=4
            elif op==4:
                if r['state']!=1:status=3
                elif flags&6!=6:r['state']=6;self.q=True;status=8
                else:r['state']=2 if flags&1 else 0;selected_r=r
            elif op==5:
                if self.q:status=8
                elif r['state']!=2:status=3
                elif r['policy']!=self.policy or self.source[r['ss']]['state']!=3 or (self.frozen and r['source']!=self.freeze):status=6
                elif any(r['state']==3 for r in self.result.values()):status=1
                else:r['state']=3;selected_r=r
            elif op==6:
                if r['state']!=3:status=3
                else:
                    for old in self.result.values():
                        if old['state']==4:old['state']=5
                    r['state']=4;selected_r=r
            elif op==7:
                if r['state'] not in (1,2,3):status=3
                elif not(flags&2) or (r['state']==1 and not(flags&4)) or (r['state']==3 and not(flags&8)):r['state']=6;self.q=True;status=8
                else:r['state']=0;selected_r=r
            elif op==8:
                if r['state']!=5:status=3
                elif flags&10!=10:r['state']=6;self.q=True;status=8
                else:r['state']=0;selected_r=r
        elif op==9:
            if self.frozen:status=9
            elif self.policy==MAX:status=7
            elif flags&1 and not(sm and rm):status=4
            elif flags&1 and (s['state']!=3 or r['state'] not in (3,4,5)):status=3
            else:
                self.frozen=True;self.policy+=1;self.freeze=c['source'] if flags&1 else self.latest
                if flags&1:selected_r=r
                elif self.freeze:_,selected_s=self.active_source(self.freeze)
        elif op==10:
            if not self.frozen:status=9
            elif self.policy==MAX:status=7
            else:self.frozen=False;self.freeze=0;self.policy+=1
        elif op==11:
            if self.policy==MAX:status=7
            else:self.policy+=1
        out={k:0 for k,_ in REP};out.update(op=op,status=status,policy=old_policy,ss=7,rs=3)
        if status==0:
            if selected_s:out.update(source=selected_s['key'],origin=selected_s['origin'],ss=selected_s['ss'])
            if selected_r:
                out.update(source=selected_r['source'],result=selected_r['key'],origin=self.source[selected_r['ss']]['origin'],
                    cj=selected_r['cj'],body=selected_r['body'],policy=selected_r['policy'],ss=selected_r['ss'],rs=selected_r['rs'])
            if op in (9,10,11):out['policy']=self.policy
        self.collect();return out
    def states(self):
        return sum(s['state']<<(i*3) for i,s in self.source.items()),sum(r['state']<<(i*3) for i,r in self.result.items())

def audit(root):
    root=Path(root);metrics=json.loads((root/'protocol-metrics.json').read_text(encoding='utf-8'))
    ledger=None;events=resets=0;hist=collections.Counter();ops=collections.Counter()
    for line in (root/'events.csv').read_text().splitlines():
        row=line.split(',')
        if row[0]=='RESET':ledger=Ledger(int(row[1]),int(row[2]),int(row[3],16));resets+=1;continue
        assert row[0]=='EVENT' and len(row)==12 and ledger is not None
        cmd=decode(int(row[1],16),CMD);actual=decode(int(row[2],16),REP);expected=ledger.event(cmd)
        assert actual==expected,(events,cmd,actual,expected)
        ss,rs=ledger.states();observed=[int(x,16) for x in row[3:8]]+[int(x) for x in row[8:12]]
        assert observed==[ss,rs,ledger.latest,ledger.freeze,ledger.policy,int(ledger.frozen),int(ledger.q),int(ledger.se),int(ledger.re)],(events,observed,ledger.states())
        hist[actual['status']]+=1;ops[cmd['op']]+=1;events+=1
    assert metrics['finished'] and metrics['transactions']==events and metrics['resets']==resets
    result={'status':'PASS','events':events,'resets':resets,'status_counts':dict(hist),'operation_counts':dict(ops),'lease_set_verified':True,'physical_fence_verified':False}
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
if __name__=='__main__':audit(sys.argv[1])
