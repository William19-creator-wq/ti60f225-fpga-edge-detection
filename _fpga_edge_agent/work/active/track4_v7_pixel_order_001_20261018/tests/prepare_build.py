from pathlib import Path
import hashlib,json,re
W=Path(__file__).resolve().parents[1];ROOT=W.parents[2]
OLD=W.parent/'track4_v7_detail_001_20261018';R=ROOT/'reports/TRACK4-V7-PIXEL-ORDER-001'
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
baseline=json.loads(read(R/'baseline.json'))
files=[dict(relative=f['relative'],sha256=sha(W/f['relative'])) for f in baseline['files']]
changed=[a['relative'] for a,b in zip(files,baseline['files']) if a['sha256']!=b['sha256']]
assert changed==['rtl/ti60f225_oob_top.v'],changed
# Record actual-source simulation, including extracted top-level vin wiring.
runs=sorted((W/'tests/runs').glob('*/sources.json'))
run=runs[-1].parent
log=read(run/'2.log')
assert 'PIXEL_ORDER_PASS' in log and '# Errors: 0, Warnings: 2' in log
assert len(re.findall(r'ORDER_CASE_PASS',log))==6
sources=json.loads(read(run/'sources.json'))
for s in sources:assert sha(Path(s['path']))==s['sha256']
# This vendor parameter is unused; with 128/32 the selected generate branch
# has SHIFT_FLOAT==0. Retain the vendor source and explicitly review warning.
packer=read(W/'rtl/frame_buffer_V4/ser2par_v1.v')
assert packer.count('I_VID_DIV')==1
assert 'localparam I_VID_DIV = I_VID_WIDTH/SHIFT_FLOAT;' in packer
inherited=json.loads(read(ROOT/'reports/TRACK4-V7-DETAIL-001/simulation-checks.json'))
same=[]
for s in inherited['sources']:
    p=Path(s['path'])
    if '/rtl/' in p.as_posix():
        relative=p.as_posix().split('/rtl/')[1]
        q=W/'rtl'/relative;assert sha(q)==s['sha256'];same.append(str(q))
sim=dict(state='PASS',sources=sources,run=str(run),pixels_per_variant=11520,
    scenarios=['continuous','input bubbles','input bubbles plus output almost-full stalls'],
    original_order='2,3,0,1 per four source pixels (index XOR 2)',corrected_order='0,1,2,3',
    warning_review='Two existing vendor unused-constant divide-by-zero warnings (one per instance): I_VID_DIV has no references; active divisible-width generate branch does not use it.',
    limitations='Actual packer/unpacker RTL and actual top vin expressions, ideal transparent 128-bit memory queue. Not full DDR controller/PHY, sensor or hardware verification.',
    inherited_detail_simulation=dict(report=str(ROOT/'reports/TRACK4-V7-DETAIL-001/simulation-checks.json'),unchanged_rtl=same))
with (R/'simulation-checks.json').open('x',encoding='utf-8') as f:json.dump(sim,f,indent=2)
with (R/'build-inputs.json').open('x',encoding='utf-8') as f:json.dump(dict(count=len(files),files=files),f,indent=2)
script=read(OLD/'tests/run_build.py').replace('TRACK4-V7-DETAIL-001','TRACK4-V7-PIXEL-ORDER-001')
with (W/'tests/run_build.py').open('x',encoding='utf-8') as f:f.write(script)
script=read(OLD/'tests/check_build.py')
script=script.replace('TRACK4-V7-DETAIL-001','TRACK4-V7-PIXEL-ORDER-001').replace('track4_v7_fps_001_20261017','track4_v7_detail_001_20261018').replace('TRACK4-V7-FPS-001','TRACK4-V7-DETAIL-001')
script=script.replace("['rtl/colorcard_overlay.v', 'rtl/rawcard_overlay.v', 'rtl/detail_pattern_gray.v', 'ti60f225_oob.xml']","['rtl/ti60f225_oob_top.v']")
script=script.replace("fromfile='RGB/'","fromfile='DETAIL/'").replace("tofile='CARD/'","tofile='PIXEL_ORDER/'")
script=script.replace('spatial_and_pattern_simulation=True','pixel_order_simulation=True')
script=script.replace('v7_detail_001_v1_20261018.bit','v7_pixel_order_001_v1_20261018.bit')
with (W/'tests/check_build.py').open('x',encoding='utf-8') as f:f.write(script)
print('Frozen',len(files),'inputs, production changes:',changed,'actual-source simulation:',run)
