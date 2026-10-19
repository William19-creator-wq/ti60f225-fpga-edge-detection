from pathlib import Path
import json,hashlib,shutil,datetime
W=Path(__file__).resolve().parents[1];ROOT=W.parents[2]
OLD=ROOT/'work/active/track4_v7_fps_001_20261017'
R=ROOT/'reports/TRACK4-V7-DETAIL-001';R.mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inputs=json.loads((ROOT/'reports/TRACK4-V7-FPS-001/build-inputs.json').read_text(encoding='utf-8'))
files=[]
for item in inputs['files']:
    s=OLD/item['relative'];d=W/item['relative']
    if sha(s)!=item['sha256']:
        assert item['relative']=='ti60f225_oob.xml'
        assert hashlib.sha256(s.read_bytes().replace(b'\r\n',b'\n')).hexdigest()==item['sha256']
    assert not d.exists();d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(s,d)
    files.append(dict(relative=item['relative'],sha256=sha(d)))
(R/'baseline.json').write_text(json.dumps(dict(source=str(OLD),files=files),indent=2),encoding='utf-8')
auth=dict(timestamp=datetime.datetime.now().astimezone().isoformat(),task='TRACK4-V7-DETAIL-001',user_scope='继续检查空间细节；用户此前明确无需另行批准或草图，允许自行写代码测试',local_audit_exception='continued',original_references='read only',download_preference='manual by user',stage='independent spatial verification; no production behavior change yet')
(R/'authorization.json').write_text(json.dumps(auth,ensure_ascii=False,indent=2),encoding='utf-8')
print('Copied and verified 146 production inputs; independent spatial verification only')
