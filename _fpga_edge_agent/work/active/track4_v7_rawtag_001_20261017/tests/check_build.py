from pathlib import Path
from collections import Counter
import datetime,difflib,hashlib,json,re,shutil,sys
W=Path(__file__).resolve().parents[1];ROOT=W.parents[2]
R=ROOT/'reports/TRACK4-V7-RAWTAG-001'
OLD=ROOT/'work/active/track4_v7_rawcard_001_20261017'
OR=ROOT/'reports/TRACK4-V7-RAWCARD-001'
read=lambda p:p.read_text(encoding='utf-8-sig',errors='replace')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inputs=json.loads(read(R/'build-inputs.json')); changed=[];diff=[];normalizations=[]
for f in inputs['files']:
    p=W/f['relative']
    if sha(p)!=f['sha256']:
        # Efinity将新写的XML从LF改为CRLF；只允许这项逐字节可还原的变化。
        assert f['relative']=='ti60f225_oob.xml'
        assert hashlib.sha256(p.read_bytes().replace(b'\r\n',b'\n')).hexdigest()==f['sha256']
        normalizations.append(dict(relative=f['relative'],before=f['sha256'],after=sha(p),reason='Efinity LF to CRLF only; exact normalized hash matches'))
    old=OLD/f['relative']
    if not old.exists() or sha(old)!=sha(p):
        changed.append(f['relative'])
        diff.extend(difflib.unified_diff(read(old).splitlines(True) if old.exists() else [],read(p).splitlines(True),fromfile='RGB/'+f['relative'],tofile='CARD/'+f['relative']))
assert sorted(changed)==sorted(['rtl/ti60f225_oob_top.v','rtl/rawcard_overlay.v'])
(R/'production.diff').write_text(''.join(diff),encoding='utf-8')
top=read(W/'rtl/ti60f225_oob_top.v')
assert '.video_format     (2\'b00)' in top
assert '.camera_r(hdmi_tx_bdata), .camera_g(hdmi_tx_gdata), .camera_b(hdmi_tx_rdata)' in top
assert 'assign gamma_sel = 1\'b0;' in top
for stage in ['map','interface','pnr']:
    assert json.loads(read(R/f'build-01-{stage}.json'))['returncode']==0
def relationships(t):
    a=t.split('Setup (Max) Clock Relationship')[1].split('Hold (Min) Clock Relationship')
    parse=lambda s:[(m[0],m[1],float(m[2]),float(m[3])) for m in re.findall(r'^\s*(\S+)\s+(\S+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+\(R-R\)',s,re.M)]
    return parse(a[0]),parse(a[1].split('NOTE:')[0])
s,h=relationships(read(W/'outflow/ti60f225_oob.timing.rpt'))
os,oh=relationships(read(OLD/'outflow/ti60f225_oob.timing.rpt'))
for a,b in [(s,os),(h,oh)]:
    assert len(a)==len(b)==18
    assert {x[:3] for x in a}=={x[:3] for x in b}
    assert min(x[3] for x in a)>=0
place=read(W/'outflow/ti60f225_oob.place.rpt'); oldplace=read(OLD/'outflow/ti60f225_oob.place.rpt')
for name in ['IO Interface Summary','IO Placement Summary']:
    cut=lambda t:t.split(name+' (begin)')[1].split(name+' (end)')[0]
    assert cut(place)==cut(oldplace)
resources={k:int(re.search(r'^'+re.escape(label)+r':\s*(\d+)',place,re.M)[1]) for k,label in [('xlr','XLRs'),('ram','Memory Blocks'),('dsp','DSP Blocks')]}
assert resources['xlr']<18000 and resources['ram']<=89 and resources['dsp']==0
def warnings(folder):
    c=Counter()
    for line in read(folder/'outflow/ti60f225_oob.warn.log').splitlines():
        if line.startswith('[EFX-'):
            line=re.sub(r'\([^\n]*?[/\\](rtl|ip)[/\\](.*?):\d+\)',lambda m:'('+m[1]+'/'+m[2].replace('\\','/')+':LINE)',line)
            line=re.sub(r'\([^\n]*?[/\\]debug_top.v:(\d+)\)',r'(debug_top.v:\1)',line)
            c[line]+=1
    return c
n,o=warnings(W),warnings(OLD);delta=dict(added=list((n-o).elements()),removed=list((o-n).elements()))
(R/'warning-delta.json').write_text(json.dumps(delta,indent=2),encoding='utf-8')
assert not delta['added'],'New synthesis warnings need review'
def flow(folder):
    c=Counter()
    for stage in ['map','interface','pnr']:
        for line in read(folder/f'build-01-{stage}.log').splitlines():
            if re.match(r'\s*WARNING\b',line):
                c[stage+': '+re.sub(r'\[SDC .*?ti60f225_oob.sdc:', '[SDC PROJECT/ti60f225_oob.sdc:',line.strip())]+=1
    return c
n,o=flow(R),flow(OR);fd=dict(added=list((n-o).elements()),removed=list((o-n).elements()))
(R/'flow-warning-delta.json').write_text(json.dumps(fd,indent=2),encoding='utf-8')
assert not fd['added'],'New flow warnings need review'
logs=list((W/'tests/runs').glob('*/2.log'));assert len(logs)==1 and 'RAWTAG_PASS raw_words=825600' in read(logs[0])
result=dict(timestamp=datetime.datetime.now().astimezone().isoformat(),state='SOFTWARE_CHECKED',setup_min_ns=min(x[3] for x in s),hold_min_ns=min(x[3] for x in h),resources=resources,changes=changed,new_warnings=delta['added'],hardware_passed=False,simulated_raw_words=825600,tool_line_endings=normalizations)
(R/'checks.json').write_text(json.dumps(result,indent=2),encoding='utf-8'); print(json.dumps(result,indent=2))
if '--register' in sys.argv:
    assert json.loads(read(R/'build-01-pgm.json'))['returncode']==0
    target=ROOT/'artifacts/staging/TRACK4-V7-RAWTAG-001';target.mkdir(parents=True,exist_ok=True)
    bit=target/'v7_rawtag_001_v1_20261017.bit';assert not bit.exists()
    shutil.copy2(W/'outflow/ti60f225_oob.bit',bit)
    result.update(state='READY_FOR_AUTHORIZED_JTAG',bit=dict(path=str(bit),sha256=sha(bit)),hardware_programmed=False,
        evidence=[dict(path=str(p),sha256=sha(p)) for p in sorted(R.iterdir()) if p.is_file()],
        verification=[dict(path=str(p),sha256=sha(p)) for p in sorted((W/'tests').rglob('*')) if p.is_file() and p.suffix in ['.py','.sv','.json','.log']])
    (target/'manifest.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print('REGISTERED '+str(bit))
