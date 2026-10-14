"""VF01..05：只按外部写接受/读交付核位值和完整序列，不复刻Gray或RAM状态。"""
import argparse,json,pathlib
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def value(index,epoch,width):
    if index==0:return 0
    if index==1:return (1<<width)-1
    if index==2:return 1<<(epoch%width)
    result=0
    for j in range(5):
        block=(((index+0x146ce572)*0x9e3779b97f4a7c15)&((1<<64)-1))^(epoch<<32)^(0xfedcba9876543210>>(j+1))^j
        result|=(block&((1<<64)-1))<<(64*j)
    return result&((1<<width)-1)
def audit(root):
    metrics=read(root/'protocol-metrics.json');assert metrics['finished']
    rows=read(root/'fifo-results.json');assert len(rows)==metrics['cases']
    incoming={};outgoing={};attempts={};loss={}
    for line in (root/'fifo-wire.csv').read_text(encoding='ascii').splitlines():
        f=line.split(',');case=int(f[1]);incoming.setdefault(case,[]);outgoing.setdefault(case,[])
        if f[0]=='W':
            index=int(f[2]);accepted=int(f[3]);payload=int(f[4],16)
            assert payload==value(index,case,metrics['width'])
            assert index==attempts.get(case,0);attempts[case]=index+1
            if accepted:incoming[case].append(payload)
            else:loss[case]=loss.get(case,0)+1
        elif f[0]=='R':outgoing[case].append(int(f[2],16))
        else:raise AssertionError(f)
    for row in rows:
        case=row['case'];assert incoming[case]==outgoing[case]
        assert len(incoming[case])==row['accepted']==row['delivered']
        assert attempts[case]==row['attempted'] and loss.get(case,0)==row['lost']
        if row['kind']=='continuous':assert row['accepted']==metrics['records'] and row['lost']==0
        elif row['kind']=='overflow_held':assert row['accepted']==metrics['depth']+2 and row['lost']==6
        elif row['kind']=='stopped_reader':assert row['accepted']==metrics['depth'] and row['lost']==7
        else:assert row['lost']==0
    assert sum(r['accepted'] for r in rows)==metrics['accepted']==metrics['delivered']
    assert sum(r['lost'] for r in rows)==metrics['lost']
    result=dict(status='PASS',metrics=metrics,rows=rows,records_compared=metrics['delivered'],
                actual_csi_verified=False,physical_cdc_timing_verified=False,hardware_verified=False,full_project_goal_complete=False)
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['audit']);p.add_argument('directory',type=pathlib.Path);a=p.parse_args();audit(a.directory)
