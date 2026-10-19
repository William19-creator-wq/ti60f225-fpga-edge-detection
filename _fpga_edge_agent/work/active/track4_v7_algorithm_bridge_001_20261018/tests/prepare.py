from pathlib import Path
import hashlib, json, shutil, datetime
W=Path(__file__).resolve().parents[1]; ROOT=W.parents[2]
TASK='TRACK4-V7-ALGORITHM-BRIDGE-001'; R=ROOT/'reports'/TASK
OLD=ROOT/'work/active/track4_v7_pixel_order_001_20261018'
ALGO=ROOT/'work/active/track4_board_refine_from031_20261013/algorithm/deps/r1/rtl/frontend'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
R.mkdir(parents=True,exist_ok=True)
records=[]
for item in json.loads((ROOT/'reports/TRACK4-V7-PIXEL-ORDER-001/build-inputs.json').read_text(encoding='utf-8'))['files']:
    src=OLD/item['relative']; dst=W/item['relative']
    assert sha(src)==item['sha256'], str(src)
    assert not dst.exists(), str(dst)
    dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(src,dst)
    records.append(dict(source=str(src),relative=item['relative'],sha256=sha(src)))
for src in sorted(ALGO.glob('*.sv')):
    dst=W/'algorithm/frontend'/src.name
    dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(src,dst)
    records.append(dict(source=str(src),relative=dst.relative_to(W).as_posix(),sha256=sha(src)))
assert len(list((W/'algorithm/frontend').glob('*.sv')))==6
(R/'baseline.json').write_text(json.dumps(dict(count=len(records),files=records),ensure_ascii=False,indent=2),encoding='utf-8')
auth=dict(timestamp=datetime.datetime.now().astimezone().isoformat(),task=TASK,event='algorithm_bridge_started',
    user_request='目前我想解決的是你自研版与demo版有差異, 整体架框上, 我想你把算法等等的东西加进去',
    continued_authorization='无需我的批准, 也不用再写草图, 你按照你的見解写代码測試即可',
    local_audit_exception='continued; no formal database or state updates',
    scope='First hardware checkpoint: reuse R1 gray/median/Sobel with independent v7 scanning, aligned raw/gray/median/edge/overlay display; later checkpoints retain full Canny and recognition scope.',
    design=str(ROOT/'planning'/f'design-{TASK}.md'),hardware_operation=False)
(R/'authorization.json').write_text(json.dumps(auth,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [ROOT/f'runtime/events/2026/10/18/{TASK}.jsonl',ROOT/f'side_effects/ledger/{TASK}-20261018.jsonl']:
    p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('a',encoding='utf-8') as f:f.write(json.dumps(auth,ensure_ascii=False)+'\n')
print('Copied and verified',len(records),'inputs; original work copies untouched')
