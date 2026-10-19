"""Validate complete build evidence; warn-review is explicit, never silently waived."""
from pathlib import Path
from collections import Counter
import datetime,hashlib,json,re,sys
w=Path(__file__).resolve().parents[1];root=w.parents[2]
r=root/'reports/TRACK4-V7-ALGORITHM-BRIDGE-001'
old=root/'work/active/track4_v7_pixel_order_001_20261018'
read=lambda p:p.read_text(encoding='utf-8-sig',errors='replace')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
normalizations=[]
for f in json.loads(read(r/'build-inputs.json'))['files']:
    p=w/f['relative']
    if sha(p)!=f['sha256']:
        assert f['relative']=='ti60f225_oob.xml',f['relative']
        assert hashlib.sha256(p.read_bytes().replace(b'\r\n',b'\n')).hexdigest()==f['sha256']
        normalizations.append(dict(relative=f['relative'],before=f['sha256'],after=sha(p),reason='Only Efinity LF-to-CRLF normalization'))
for stage in ['map','interface','pnr']:
    assert json.loads(read(sorted(r.glob(f'build-*-{stage}.json'))[-1]))['returncode']==0,stage
def relationships(t):
    a=t.split('Setup (Max) Clock Relationship')[1].split('Hold (Min) Clock Relationship')
    parse=lambda s:[(m[0],m[1],float(m[2]),float(m[3])) for m in re.findall(r'^\s*(\S+)\s+(\S+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+\(R-R\)',s,re.M)]
    return parse(a[0]),parse(a[1].split('NOTE:')[0])
s,h=relationships(read(w/'outflow/ti60f225_oob.timing.rpt'))
os,oh=relationships(read(old/'outflow/ti60f225_oob.timing.rpt'))
for current,previous in [(s,os),(h,oh)]:
    assert len(current)==len(previous)==18
    assert {x[:3] for x in current}=={x[:3] for x in previous},'Clock relationships changed'
    assert min(x[3] for x in current)>=0,('Timing failure',current)
place=read(w/'outflow/ti60f225_oob.place.rpt');oldplace=read(old/'outflow/ti60f225_oob.place.rpt')
for name in ['IO Interface Summary','IO Placement Summary']:
    cut=lambda t:t.split(name+' (begin)')[1].split(name+' (end)')[0]
    assert cut(place)==cut(oldplace),'Pin/interface placement changed'
resources={k:int(re.search(r'^'+re.escape(label)+r':\s*(\d+)',place,re.M)[1]) for k,label in [('xlr','XLRs'),('ram','Memory Blocks'),('dsp','DSP Blocks')]}
def warning_lines(folder):
    counts=Counter()
    for line in read(folder/'outflow/ti60f225_oob.warn.log').splitlines():
        if line.startswith('[EFX-'):
            line=re.sub(r'\([^\n]*?[/\\](rtl|ip|algorithm)[/\\](.*?):\d+\)',lambda m:'('+m[1]+'/'+m[2].replace('\\','/')+':LINE)',line)
            line=re.sub(r'\([^\n]*?[/\\]debug_top.v:(\d+)\)',r'(debug_top.v:\1)',line)
            counts[line]+=1
    return counts
nw,ow=warning_lines(w),warning_lines(old)
delta={'added':list((nw-ow).elements()),'removed':list((ow-nw).elements())}
(r/'warning-delta.json').write_text(json.dumps(delta,indent=2),encoding='utf-8')
simulations=[]
for case in ['small','fault','reset','full']:
    sim=json.loads(read(r/f'sim-{case}-result.json'));assert sim['result']=='PASS'
    for path,expected in sim['sources'].items():assert sha(Path(path))==expected,('Simulation source changed',path)
    simulations.append(dict(case=case,pixels=sim['W']*sim['H']*sim['frames'],source_snapshot=sim['snapshot']))
result={'timestamp':datetime.datetime.now().astimezone().isoformat(),'state':'AWAITING_WARNING_REVIEW',
 'setup_min_ns':min(x[3] for x in s),'hold_min_ns':min(x[3] for x in h),'resources':resources,
 'setup_clock_relationships':s,'hold_clock_relationships':h,'simulations':simulations,
 'source_normalizations':normalizations,'hardware_programmed':False,'hardware_passed':False}
(r/'checks.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k not in ['setup_clock_relationships','hold_clock_relationships']},indent=2))
print('New warnings:',len(delta['added']))
if '--accept-review' in sys.argv:
    review=json.loads(read(r/'warning-review.json'))
    assert sorted(review['reviewed_added'])==sorted(delta['added'])
    assert not review['unreviewed']
    assert review['flow_logs_reviewed'] is True
    result['state']='SOFTWARE_CHECKED'
    (r/'checks.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print('All software checks passed; generation permitted; hardware not yet verified.')
