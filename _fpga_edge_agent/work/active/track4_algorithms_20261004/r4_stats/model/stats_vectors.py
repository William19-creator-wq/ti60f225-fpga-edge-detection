"""ST-T01…12：实际输入生成、独立终态和来源审核；固定种子，保留每次原文件。"""
import argparse, hashlib, json, random
from pathlib import Path
from stats_reference import *

def digest(path): return hashlib.file_digest(path.open('rb'),'sha256').hexdigest()

def generate(root):
    root=Path(root); root.mkdir(parents=True,exist_ok=False)
    rows=[]; inputs=root/'tokens.bin'; meta=[]
    def save(name,tokens,stat=None,continuous=False):
        tokens=list(tokens)
        if stat is None: stat=evaluate_tokens(tokens)
        with inputs.open('ab') as f:
            for raw in tokens: f.write(raw.to_bytes(33,'big'))
        rows.append(f'{len(tokens)} {stat:0158x} {fit_result(stat):0147x} {int(continuous)}')
        meta.append(dict(name=name,tokens=len(tokens),points=sum(field(t,176,2)==1 for t in tokens),stat=f'{stat:0158x}'))
    for k in KINDS:
        rng=random.Random(20261021 if k in (11,17) else 20261022)
        for j in range(256):
            w,v=((6,5),(8,7),(16,9),(1920,1080))[j%4]; e=rng.randrange(min(128,w*v)+1)
            xy=sorted(rng.sample(range(w*v),e)); context=identity(k*1000+j)
            threshold=(0,1,32768,65535)[j%4] if k in (11,12) else 0
            body=[start(context,k,w,v,e,threshold)]
            for ordinal,index in enumerate(xy):
                gx=rng.choice((0,-1,1,-1020,1020,rng.randint(-1020,1020)))
                gy=rng.choice((0,-1,1,-1020,1020,rng.randint(-1020,1020)))
                include=(True,False,ordinal%2==0,bool(rng.getrandbits(1)))[j%4]
                body.append(point(context,ordinal,index%w,index//w,gx,gy,include))
            body.append(close(context,e)); save(f'normal-{k}-{j}',body,continuous=j%8==0)
    # 每个反例有明确名字和真正同ID关闭，不以随机命中代替。
    c=identity(99999); good=[start(c,11,6,5,3),point(c,0,1,1,-1,-1),point(c,1,3,1,1,-1),point(c,2,2,3,0,1),close(c,3)]
    save('readable-LS',good); save('zero-E',[start(c,11,6,5,0),close(c,0)])
    for w in (0,7,2047): save(f'bad-width-{w}',[start(c,11,w,5,0),close(c,0)])
    for v in (0,2047): save(f'bad-height-{v}',[start(c,11,6,v,0),close(c,0)])
    for label,head in [('version',start(c,11,6,5,3,version=0)),('owner',start(c|1<<96,11,6,5,3)),
                       ('kind',start(c,13,6,5,3)),('diag-threshold',start(c,17,6,5,3,1)),
                       ('header-pad',start(c,11,6,5,3,padding=1)),('E>N',start(c,11,6,5,31))]:
        own=field(head,0,176); save(label,[head,point(own,0,1,1,1,1),close(own,0,abort=True)])
    badpoints=[('repeat-ordinal',point(c,0,3,1,1,-1)),('skip-ordinal',point(c,2,3,1,1,-1)),
               ('x=W',point(c,1,6,1,1,-1)),('y=H',point(c,1,3,5,1,-1)),
               ('point-pad',point(c,1,3,1,1,-1,padding=1)),('duplicate-coordinate',point(c,1,1,1,1,-1)),
               ('reverse-row',point(c,1,0,0,1,-1)),('point-ID',point(c^1,1,3,1,1,-1))]
    for axis in (0,1):
        for g in (-1024,-1021,1021):
            badpoints.append((f'gradient-{axis}-{g}',point(c,1,3,1,g if axis==0 else 1,g if axis else 1)))
    for label,bad in badpoints: save(label,[good[0],good[1],bad,close(c,0,abort=True)])
    for label,end in [('early-END',close(c,1)),('END-count',close(c,4)),('END-pad',close(c,3,padding=1)),
                      ('ABORT-pad',close(c,0,abort=True,padding=1))]: save(label,good[:-1]+[end])
    save('wrong-close-ID',good[:-1]+[close(c^1,3),close(c,3)])
    save('wrong-abort-ID',good[:-1]+[close(c^1,0,abort=True),close(c,3)])
    save('repeated-start',[good[0],good[0],close(c,0,abort=True)])
    save('idle-nonSTART',[good[1]])
    for accepted in range(4): save(f'ABORT-after-{accepted}',good[:1+accepted]+[close(c,0,abort=True)],continuous=True)
    save('ABORT-same-first-commit',[start(c,11,6,5,4),point(c,0,1,1,-1,-1),point(c,1,3,1,1,-1),
        point(c,2,2,3,0,1),point(c,3,4,3,2,1),close(c,0,abort=True)],continuous=True)
    for k in KINDS:
        for n in (0,1,2): save(f'small-{k}-{n}',[start(c,k,6,5,n)]+[point(c,i,i,1,0,0) for i in range(n)]+[close(c,n)])
    save('TLS-isotropic',[start(c,12,6,5,4)]+[point(c,i,x,y,1,1) for i,(x,y) in enumerate(((1,1),(3,1),(1,3),(3,3)))]+[close(c,4)])
    for axis in ('horizontal','vertical','diagonal'):
        xy=[(i,1) if axis=='horizontal' else ((1,i) if axis=='vertical' else (i,i)) for i in range(4)]
        save('TLS-'+axis,[start(c,12,6,5,4)]+[point(c,i,x,y,0,0) for i,(x,y) in enumerate(xy)]+[close(c,4)])
    # 全N输入不用巨大的Python点列表；流式写磁盘，黄金用独立集合公式。
    corners={(0,0),(1919,0),(960,540),(123,777),(777,999),(0,1079),(1919,1079)}
    for sparse in (False,True):
        for k in (11,12):
            context=identity(100000+k+int(sparse)*100); e=2073600
            with inputs.open('ab') as f:
                f.write(start(context,k,count=e).to_bytes(33,'big'))
                for ordinal in range(e):
                    y,x=divmod(ordinal,1920)
                    raw=point(context,ordinal,x,y,1020 if y&1 else -1020,1020 if x&1 else -1020,
                              (x,y) in corners if sparse else True)
                    f.write(raw.to_bytes(33,'big'))
                f.write(close(context,e).to_bytes(33,'big'))
            stat=full_statistics(k,sparse)
            rows.append(f'{e+2} {stat:0158x} {fit_result(stat):0147x} 1')
            meta.append(dict(name=f'1080p-{k}-sparse-{sparse}',tokens=e+2,points=e,stat=f'{stat:0158x}'))
    (root/'cases.txt').write_text(str(len(rows))+'\n'+'\n'.join(rows)+'\n',encoding='ascii')
    result=dict(cases=len(rows),points=sum(r['points'] for r in meta),scenarios=meta,
                tokens_sha256=digest(inputs),cases_sha256=digest(root/'cases.txt'),seeds=[20261021,20261022,20261023])
    (root/'manifest.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k!='scenarios'}))

def audit_core(run,label):
    run=Path(run); expected=json.loads((run/'vectors/manifest.json').read_text())
    result=json.loads((run/f'{label}-result.json').read_text())
    if not result.get('finished') or result.get('status')!='PASS': raise ValueError('unfinished suite')
    if result['cases']!=expected['cases'] or result['points']!=expected['points']: raise ValueError('coverage count')
    actual=(run/f'{label}-stat.tsv').read_text().splitlines()
    if len(actual)!=expected['cases']: raise ValueError('actual STAT count')
    for index,(line,row) in enumerate(zip(actual,expected['scenarios'])):
        if int(line.split()[0])!=index or int(line.split()[1],16)!=int(row['stat'],16): raise ValueError(f'STAT case{index}')
    # 输入33byte对应真实fire日志；按流式比较核真实接受数，不只比较最终CRC。
    with (run/'vectors/tokens.bin').open('rb') as raw, (run/f'{label}-tokens.bin').open('rb') as accepted:
        while chunk:=raw.read(1<<20):
            if chunk!=accepted.read(len(chunk)): raise ValueError('actual token stream differs')
        if accepted.read(1): raise ValueError('extra accepted token')
    print(json.dumps(dict(status='PASS',cases=result['cases'],points=result['points'],tokens=digest(run/f'{label}-tokens.bin'))))

def audit_probe(run):
    run=Path(run); contexts={}; totals=dict(jobs=0,points=0,stat=0,num=0,rsp=0,observer=0,crc=0)
    def advance(lfsr):
        return ((lfsr<<1)&0xffffffff)|(((lfsr>>31)^(lfsr>>21)^(lfsr>>1)^lfsr)&1)
    for line in (run/'probe-ledger.tsv').read_text().splitlines():
        who,seg,event,cycle,word=line.split();key=(who,int(seg));word=int(word,16)
        if event=='B':
            if key in contexts: raise ValueError('duplicate reset segment')
            contexts[key]=dict(seq=word,lfsr=0x43106025,crc=0xffffffff,jobs=0,stream=None,stat=None,num=False,rsp=False,observer=False)
            continue
        c=contexts[key];seq=c['seq'];kind=KINDS[seq&3];bad=bool(seq&8);own=identity(seq)
        if event=='T':
            if c['stream'] is None:
                if c['observer']: raise ValueError('new START before CRC completion')
                e=32+(c['lfsr']&511);w=7 if bad and kind==11 else 1920
                expected=start(own,kind,w,1080,e);c['extent']=e;c['cursor']=0
                c['x']=c['lfsr']&1023;c['y']=(c['lfsr']>>10)&1023
                if c['y']==540:c['y']=541
                c['stream']=[];c['closed']=False
            else:
                npoints=(1 if kind==11 else 4) if bad and kind in (11,17,18) else c['extent']
                if c['cursor']<npoints:
                    cursor,x,y=c['cursor'],c['x'],c['y']
                    expected=point(own,cursor,x,y,x-960,y-540,bool(c['lfsr']&(1<<22)) or cursor<3,
                                   int(bad and kind==17 and cursor==2))
                    c['cursor']+=1;c['lfsr']=advance(c['lfsr']);c['x']+=17
                    if c['x']>=1920:c['x']-=1920;c['y']+=1
                    totals['points']+=1
                else:
                    expected=close(own,c['cursor']+int(bad and kind==12),abort=bad and kind in (11,17,18));c['closed']=True
            if word!=expected: raise ValueError(f'{key} seq{seq} source token differs at cursor{c["cursor"]}')
            c['stream'].append(word)
        elif event=='S':
            if not c['closed'] or c['stat'] is not None:raise ValueError('STAT without closure or duplicate')
            c['stat']=evaluate_tokens(c['stream'])
            if word!=c['stat']:raise ValueError('probe actual statistics')
            totals['stat']+=1
        elif event=='N':
            if c['stat'] is None or field(c['stat'],622,2)!=0 or c['num'] or word!=field(c['stat'],0,622):raise ValueError('NUM transfer')
            c['num']=True;totals['num']+=1
        elif event=='R':
            if not c['num'] or c['rsp'] or word!=fit_result(c['stat']):raise ValueError('FIT actual response')
            c['rsp']=True;totals['rsp']+=1
        elif event=='O':
            if c['stat'] is None or c['observer'] or word!=fit_result(c['stat']):raise ValueError('observer actual response')
            if field(c['stat'],622,2)==0 and not c['rsp']:raise ValueError('observer missing FIT')
            c['observer']=True;totals['observer']+=1
            for bit in range(584,-1,-1):
                feedback=((c['crc']>>31)^(word>>bit))&1;c['crc']=(c['crc']<<1)&0xffffffff
                if feedback:c['crc']^=0x04c11db7
        elif event=='C':
            if not c['observer'] or word!=c['crc']:raise ValueError('585bit CRC mismatch')
            totals['crc']+=1;totals['jobs']+=1;c['jobs']+=1
            if c['seq']!=(1<<64)-1:c['seq']+=1
            c.update(stream=None,stat=None,num=False,rsp=False,observer=False)
        else:raise ValueError('unknown event')
    for key,n in ((('M',0),64),(('M',1),4),(('T',0),2)):
        if contexts[key]['jobs']!=n or contexts[key]['stream'] is not None:raise ValueError('job accounting')
    if totals['stat']!=70 or totals['observer']!=70 or totals['crc']!=70 or totals['num']!=totals['rsp']:raise ValueError('three ledger accounting')
    result=json.loads((run/'probe-result.json').read_text())
    if result.get('status')!='PASS' or not result.get('finished'):raise ValueError('probe unfinished')
    (run/'probe-audit.json').write_text(json.dumps(dict(status='PASS',totals=totals,ledger_sha256=digest(run/'probe-ledger.tsv')),indent=2))
    print(json.dumps(dict(status='PASS',totals=totals)))

if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('action',choices=('generate','audit-core','audit-fit','audit-probe'))
    p.add_argument('path'); a=p.parse_args()
    if a.action=='generate': generate(a.path)
    elif a.action=='audit-probe':audit_probe(a.path)
    else: audit_core(a.path,a.action[6:])
