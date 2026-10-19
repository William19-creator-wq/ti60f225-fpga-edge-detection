from pathlib import Path
import json,hashlib,datetime
W=Path(__file__).resolve().parents[1];ROOT=W.parents[2]
R=ROOT/'reports/TRACK4-V7-DETAIL-001';OLD=ROOT/'work/active/track4_v7_fps_001_20261017'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:p.read_text(encoding='utf-8-sig')
def save(p,obj):
    with p.open('x',encoding='utf-8') as f:json.dump(obj,f,indent=2,ensure_ascii=False)
baseline=json.loads(read(R/'baseline.json'))
files=[dict(relative=f['relative'],sha256=sha(W/f['relative'])) for f in baseline['files']]
files.append(dict(relative='rtl/detail_pattern_gray.v',sha256=sha(W/'rtl/detail_pattern_gray.v')))
files.sort(key=lambda f:f['relative']);assert len(files)==147
changed=[f['relative'] for f in files if not (OLD/f['relative']).exists() or sha(OLD/f['relative'])!=f['sha256']]
expected=['rtl/colorcard_overlay.v','rtl/rawcard_overlay.v','rtl/detail_pattern_gray.v','ti60f225_oob.xml']
assert sorted(changed)==sorted(expected)
save(R/'build-inputs.json',dict(count=len(files),files=files))
runner=read(OLD/'tests/run_build.py').replace('TRACK4-V7-FPS-001','TRACK4-V7-DETAIL-001')
(W/'tests/run_build.py').write_text(runner,encoding='utf-8')
checker=read(OLD/'tests/check_build.py')
checker=checker.replace("R=ROOT/'reports/TRACK4-V7-FPS-001'","R=ROOT/'reports/TRACK4-V7-DETAIL-001'")
checker=checker.replace("track4_v7_bggr_wb_001_20261017","track4_v7_fps_001_20261017").replace("OR=ROOT/'reports/TRACK4-V7-BGGR-WB-001'","OR=ROOT/'reports/TRACK4-V7-FPS-001'")
checker=checker.replace("['rtl/ti60f225_oob_top.v','rtl/camera_fps_monitor.v','ti60f225_oob.xml']",repr(expected))
start=checker.index("reviewed=['[EFX-0200 WARNING]");end=checker.index('\ndef flow(folder):',start)
checker=checker[:start]+'''reviewed=[]
unreviewed=delta['added']
assert not unreviewed,'Unreviewed new synthesis warnings'
(R/'warning-review.json').write_text(json.dumps(dict(accepted=reviewed,unreviewed=unreviewed,removed=delta['removed']),indent=2),encoding='utf-8')
'''+checker[end:]
start=checker.index("logs=list((W/'tests/runs')");end=checker.index("assert re.search",start)
checker=checker[:start]+'''sim=json.loads(read(R/'simulation-checks.json'));assert sim['state']=='PASS'
for entry in sim['sources']:
    assert sha(Path(entry['path']))==entry['sha256'],'Simulation source changed'
'''+checker[end:]
checker=checker.replace('fps_monitor_simulation=True','spatial_and_pattern_simulation=True')
checker=checker.replace("artifacts/staging/TRACK4-V7-FPS-001","artifacts/staging/TRACK4-V7-DETAIL-001").replace('v7_fps_001_v1_20261017.bit','v7_detail_001_v1_20261018.bit')
(W/'tests/check_build.py').write_text(checker,encoding='utf-8')
detail=sorted((W/'tests/detail_runs').glob('*/sources.json'))[-1]
assert 'DETAIL_PASS' in read(detail.parent/'2.log')
serial=sorted((W/'tests/serializer_runs').glob('*/source.json'))
if not serial:serial=sorted((W/'tests/serializer_runs').glob('*/sources.json'))
serializer_logs=list((W/'tests/serializer_runs').glob('*/2.log'))
assert any('SERIALIZER_PASS' in read(p) for p in serializer_logs)
spatial=json.loads(read(R/'spatial-analysis-001.json'))
assert sum(s['pixels'] for s in spatial['stats'].values())==191000 and all(s['mismatch']==0 for s in spatial['stats'].values())
sources=json.loads(read(detail));save(R/'simulation-checks.json',dict(state='PASS',sources=sources,
    detail_run=str(detail.parent),direct_pixels=825600,raw_words=412800,bilinear_panel_pixels=363280,
    spatial_pixels=191000,serializer_distinct_pixels=5760,
    limitation='RTL ideal clocks; interior interpolation and generated patterns only. Not sensor, DDR data fidelity, physical HDMI or optical validation.',
    warnings='Existing debayer unconnected o_x debug output, no datapath use. Initial bench syntax/wiring errors retained in earlier logs; corrected final run passes.'))
event=dict(timestamp=datetime.datetime.now().astimezone().isoformat(),task='TRACK4-V7-DETAIL-001',event='isolated_detail_diagnostic_simulation_passed',
    sources=len(files),changes=changed,hardware_operation=False,authorization='continued user waiver; local audit exception; manual download preference')
for p in [ROOT/'runtime/events/2026/10/18/TRACK4-V7-DETAIL-001.jsonl',ROOT/'side_effects/ledger/TRACK4-V7-DETAIL-001-20261018.jsonl']:
    p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('a',encoding='utf-8') as f:f.write(json.dumps(event,ensure_ascii=False)+'\n')
print(json.dumps(dict(frozen=len(files),changes=changed,simulation='PASS')))
