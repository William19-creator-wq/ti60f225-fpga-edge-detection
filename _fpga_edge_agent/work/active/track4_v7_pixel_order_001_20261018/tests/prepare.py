from pathlib import Path
import json,hashlib,shutil,datetime
W=Path(__file__).resolve().parents[1];ROOT=W.parents[2];R=ROOT/'reports/TRACK4-V7-PIXEL-ORDER-001'
OLD=ROOT/'work/active/track4_v7_detail_001_20261018';DR=ROOT/'reports/TRACK4-V7-DETAIL-001'
R.mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inputs=json.loads((DR/'build-inputs.json').read_text(encoding='utf-8'))
files=[]; exclusions=[]
for f in inputs['files']:
    s=OLD/f['relative'];d=W/f['relative']
    if f['relative']=='rtl/frame_buffer_V4/~$调试总结 .docx' and not s.exists():
        assert f['relative'] not in (OLD/'ti60f225_oob.xml').read_text(encoding='utf-8')
        exclusions.append(dict(f,reason='Missing ephemeral Word owner-lock sidecar; not referenced by project XML, not a synthesis/build input. No substitute created.'))
        continue
    assert sha(s)==f['sha256'] or (f['relative']=='ti60f225_oob.xml' and hashlib.sha256(s.read_bytes().replace(b'\r\n',b'\n')).hexdigest()==f['sha256'])
    if d.exists():assert sha(d)==sha(s),f['relative']
    else:d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(s,d)
    files.append(dict(relative=f['relative'],sha256=sha(d)))
with (R/'baseline.json').open('x',encoding='utf-8') as out:json.dump(dict(source=str(OLD),count=len(files),files=files,exclusions=exclusions),out,indent=2)
auth=dict(timestamp=datetime.datetime.now().astimezone().isoformat(),task='TRACK4-V7-PIXEL-ORDER-001',
    scope='Verify 32-to-128-to-16 pixel ordering with existing pack/unpack RTL; if reproduced, correct only top-level input halfword order, simulate/build/register for manual download.',
    user_authorization='无需我的批准, 也不用再写草图, 你按照你的見解写代码測試即可',
    download_preference='我自行下载，请给文件路径',local_audit_exception='continued; formal state/database untouched',hardware_operation=False,
    source_document='https://www.efinixinc.com/docs/mipi-csi2-rx-core-ug-v3.2.pdf#page=14',source_fact='RAW10 Table 19: first pixel bits9:0, then19:10,29:20,39:30')
with (R/'authorization.json').open('x',encoding='utf-8') as out:json.dump(auth,out,ensure_ascii=False,indent=2)
obs=dict(timestamp=auth['timestamp'],task='TRACK4-V7-DETAIL-001',event='human_visual_observation',
    original='就算比较第三到六列, 我覺得上方的细线图的平均质量比中间好',
    clarification='条纹仍完整，主要是边缘发软或有细彩边',camera_live=True,
    inference='Qualitatively consistent with bilinear reference; no observed gross missing/repeated stripes. Not pixel-exact proof; camera/DDR content remains unvalidated.',
    bit_association='Context associates with v7_detail_001_v1_20261018.bit; hardware bit hash not read back',root_cause_closed=False)
with (DR/'hardware-observation-001.json').open('x',encoding='utf-8') as out:json.dump(obs,out,ensure_ascii=False,indent=2)
for obj in [obs,dict(auth,event='independent_order_verification_started')]:
    for dest in [ROOT/f"runtime/events/2026/10/18/{obj['task']}.jsonl",ROOT/f"side_effects/ledger/{obj['task']}-20261018.jsonl"]:
        dest.parent.mkdir(parents=True,exist_ok=True)
        with dest.open('a',encoding='utf-8') as out:out.write(json.dumps(obj,ensure_ascii=False)+'\n')
print(f'Verified/copied {len(files)} inputs; {len(exclusions)} documented non-build exclusion; recorded live observation and continued authorization')
