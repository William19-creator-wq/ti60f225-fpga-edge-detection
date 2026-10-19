from pathlib import Path
import hashlib,json,difflib,datetime,xml.etree.ElementTree as ET
w=Path(__file__).resolve().parents[1];root=w.parents[2]
r=root/'reports/TRACK4-V7-ALGORITHM-CONTROL-001';old=root/'work/active/track4_v7_algorithm_bridge_001_20261018'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
base=json.loads((r/'baseline.json').read_text(encoding='utf-8'));changed=[];diff=[]
for f in base['files']:
    src=Path(f['source']);dst=w/f['relative'];assert sha(src)==f['sha256']
    if sha(dst)!=f['sha256']:
        changed.append(f['relative'])
        diff+=list(difflib.unified_diff(src.read_text(encoding='utf-8-sig').splitlines(True),dst.read_text(encoding='utf-8-sig').splitlines(True),fromfile='BASE/'+f['relative'],tofile='CONTROL/'+f['relative']))
assert sorted(changed)==sorted(['rtl/ti60f225_oob_top.v','rtl/v7_algorithm_video_pair.sv','ti60f225_oob.xml','ti60f225_oob.sdc','ti60f225_oob.peri.xml']),changed
new=['rtl/v7_algorithm_control.sv','rtl/v7_algorithm_status_pixel.sv']
for name in new:diff+=list(difflib.unified_diff([], (w/name).read_text(encoding='utf-8').splitlines(True),fromfile='/dev/null',tofile='CONTROL/'+name))
(r/'production.diff').write_text(''.join(diff),encoding='utf-8')
# Whitelist only three new input GPIO nodes. All other periphery trees must be identical.
original=ET.parse(old/'ti60f225_oob.peri.xml').getroot();current=ET.parse(w/'ti60f225_oob.peri.xml').getroot()
added=[]
for parent in current.iter():
    for child in list(parent):
        if child.tag.endswith('comp_gpio') and child.get('name') in ['key_inc_n','key_dec_n','key_mode_n']:
            added.append(dict(child.attrib));parent.remove(child)
def canonical(e):return(e.tag,sorted(e.attrib.items()),(e.text or '').strip(),[canonical(c) for c in e])
assert canonical(original)==canonical(current),'Unexpected periphery change'
assert {x['name']:x['gpio_def'] for x in added}=={'key_inc_n':'GPIOR_22','key_dec_n':'GPIOR_21','key_mode_n':'GPIOL_03'}
assert all(x['mode']=='input' and x['io_standard']=='3.3 V LVCMOS' for x in added)
(r/'periphery-check.json').write_text(json.dumps(dict(result='PASS',only_added=added,baseline_reset_preserved='KEY0 GPIOL_07 C4'),indent=2),encoding='utf-8')
paths=[f['relative'] for f in base['files']]+new
inputs={'timestamp':datetime.datetime.now().astimezone().isoformat(),'count':len(paths),'files':[dict(relative=p,sha256=sha(w/p)) for p in sorted(paths)]}
(r/'build-inputs.json').write_text(json.dumps(inputs,indent=2),encoding='utf-8')
print('Frozen',len(paths),'build inputs; original and periphery invariants verified.')
