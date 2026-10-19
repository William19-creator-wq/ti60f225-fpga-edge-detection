from pathlib import Path
import hashlib,json,shutil,datetime,re
W=Path(__file__).resolve().parents[1];ROOT=W.parents[2]
TASK='TRACK4-V7-ALGORITHM-CONTROL-001';R=ROOT/'reports'/TASK
OLD=ROOT/'work/active/track4_v7_algorithm_bridge_001_20261018'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
R.mkdir(parents=True,exist_ok=True)
records=[]
for f in json.loads((ROOT/'reports/TRACK4-V7-ALGORITHM-BRIDGE-001/delivery.json').read_text(encoding='utf-8'))['inputs']:
    src=OLD/f['relative'];dst=W/f['relative']
    assert sha(src)==f['sha256'],str(src)
    assert not dst.exists(),str(dst)
    dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    records.append(dict(source=str(src),relative=f['relative'],sha256=sha(src)))
for name in ['key_press_debouncer.sv','live_threshold_control.sv']:
    src=ROOT/'work/active/track4_board_refine_from031_20261013/board/live_threshold'/name
    dst=W/'algorithm/control'/name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    records.append(dict(source=str(src),relative=dst.relative_to(W).as_posix(),sha256=sha(src)))
(R/'baseline.json').write_text(json.dumps(dict(count=len(records),files=records),indent=2),encoding='utf-8')
for name in ['run_build.py','run_sim.py','tb_bridge.sv']:
    s=(OLD/'tests'/name).read_text(encoding='utf-8').replace('TRACK4-V7-ALGORITHM-BRIDGE-001',TASK)
    (W/'tests'/name).write_text(s,encoding='utf-8')
auth=dict(timestamp=datetime.datetime.now().astimezone().isoformat(),task=TASK,event='started',
    user_request='那你可以继续了',continued_authorization='无需我的批准, 也不用再写草图, 你按照你的见解写代码测试即可',
    scope='Mode keys, live threshold, same-coordinate median difference x8 and status overlay',
    local_audit_exception=True,formal_state_database_updated=False,hardware_operation=False)
(R/'authorization.json').write_text(json.dumps(auth,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [ROOT/f'runtime/events/2026/10/18/{TASK}.jsonl',ROOT/f'side_effects/ledger/{TASK}-20261018.jsonl']:
    with p.open('a',encoding='utf-8') as f:f.write(json.dumps(auth,ensure_ascii=False)+'\n')
print('Copied verified baseline inputs:',len(records))
