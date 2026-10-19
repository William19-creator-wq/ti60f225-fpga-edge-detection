from pathlib import Path
from collections import Counter
import datetime,hashlib,json,re
w=Path(__file__).resolve().parents[1];root=w.parents[2]
r=root/'reports/TRACK4-V7-ALGORITHM-CONTROL-001';old=root/'work/active/track4_v7_algorithm_bridge_001_20261018'
read=lambda p:p.read_text(encoding='utf-8-sig',errors='replace')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
normalizations=[]
for f in json.loads(read(r/'build-inputs.json'))['files']:
    p=w/f['relative']
    if sha(p)!=f['sha256']:
        assert f['relative']=='ti60f225_oob.xml'
        assert hashlib.sha256(p.read_bytes().replace(b'\r\n',b'\n')).hexdigest()==f['sha256']
        normalizations.append(dict(relative=f['relative'],before=f['sha256'],after=sha(p),reason='Efinity LF-to-CRLF only'))
for stage in ['map','interface','pnr']:
    assert json.loads(read(sorted(r.glob(f'build-*-{stage}.json'))[-1]))['returncode']==0
def relationships(t):
    a=t.split('Setup (Max) Clock Relationship')[1].split('Hold (Min) Clock Relationship')
    parse=lambda s:[(m[0],m[1],float(m[2]),float(m[3])) for m in re.findall(r'^\s*(\S+)\s+(\S+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+\(R-R\)',s,re.M)]
    return parse(a[0]),parse(a[1].split('NOTE:')[0])
s,h=relationships(read(w/'outflow/ti60f225_oob.timing.rpt'))
os,oh=relationships(read(old/'outflow/ti60f225_oob.timing.rpt'))
for current,previous in [(s,os),(h,oh)]:
    assert len(current)==len(previous)==18
    assert {x[:3] for x in current}=={x[:3] for x in previous}
    assert min(x[3] for x in current)>=0,('Timing failure',current)
place=read(w/'outflow/ti60f225_oob.place.rpt');oldplace=read(old/'outflow/ti60f225_oob.place.rpt')
for name in ['IO Interface Summary','IO Placement Summary']:
    cut=lambda t:t.split(name+' (begin)')[1].split(name+' (end)')[0]
    assert cut(place)==cut(oldplace),'Unexpected missing/unassigned interfaces'
resources={k:int(re.search(r'^'+re.escape(label)+r':\s*(\d+)',place,re.M)[1]) for k,label in [('xlr','XLRs'),('ram','Memory Blocks'),('dsp','DSP Blocks')]}
def warnings(folder):
    c=Counter()
    for line in read(folder/'outflow/ti60f225_oob.warn.log').splitlines():
        if line.startswith('[EFX-'):
            line=re.sub(r'\([^\n]*?[/\\](rtl|ip|algorithm)[/\\](.*?):\d+\)',lambda m:'('+m[1]+'/'+m[2].replace('\\','/')+':LINE)',line)
            line=re.sub(r'\([^\n]*?[/\\]debug_top.v:(\d+)\)',r'(debug_top.v:\1)',line)
            c[line]+=1
    return c
n,o=warnings(w),warnings(old)
(r/'warning-delta.json').write_text(json.dumps({'added':list((n-o).elements()),'removed':list((o-n).elements())},indent=2),encoding='utf-8')
sims=[]
for case in ['small','fault','reset','hud','hud_fault','full']:
    record=json.loads(read(r/f'sim-{case}-result.json'));assert record['result']=='PASS'
    for path,expected in record['sources'].items():assert sha(Path(path))==expected,path
    sims.append(dict(case=case,pixels=record['W']*record['H']*record['frames'],snapshot=record['snapshot']))
control=json.loads(read(r/'control-result.json'));assert control['result']=='PASS'
for path,expected in control['sources'].items():assert sha(Path(path))==expected,path
assert json.loads(read(r/'periphery-check.json'))['result']=='PASS'
netlist=read(w/'outflow/ti60f225_oob.map.v')
sync_checks=[]
for port,instance in [('key_inc_n','thresholds/increment_key'),('key_dec_n','thresholds/decrement_key'),('key_mode_n','mode_key')]:
    head='algorithm_controls/'+instance+'/key_sync_first~FF'
    tail='algorithm_controls/'+instance+'/key_sync_second~FF'
    a=re.search(r'EFX_FF\s+\\'+re.escape(head)+r'\s+\((.*?);',netlist,re.S)
    b=re.search(r'EFX_FF\s+\\'+re.escape(tail)+r'\s+\((.*?);',netlist,re.S)
    assert a and b,(head,tail)
    assert re.search(r'\.D\('+port+r'\)',a[1]),a[1]
    first_q=re.search(r'\.Q\(([^)]+)\)',a[1])[1]
    assert re.search(r'\.D\('+re.escape(first_q)+r'\)',b[1]),b[1]
    sync_checks.append(dict(port=port,first=head,second=tail,first_q=first_q,chain_verified=True))
result=dict(timestamp=datetime.datetime.now().astimezone().isoformat(),state='AWAITING_WARNING_REVIEW',
 setup_min_ns=min(x[3] for x in s),hold_min_ns=min(x[3] for x in h),resources=resources,
 setup_clock_relationships=s,hold_clock_relationships=h,simulations=sims,controls=control,
 button_synchronizers=sync_checks,source_normalizations=normalizations,hardware_programmed=False,hardware_passed=False)
(r/'checks.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({k:result[k] for k in ['state','setup_min_ns','hold_min_ns','resources','button_synchronizers']},indent=2))
