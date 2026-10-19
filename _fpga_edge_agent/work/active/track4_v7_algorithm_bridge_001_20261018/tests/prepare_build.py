from pathlib import Path
import datetime,difflib,hashlib,json
w=Path(__file__).resolve().parent.parent;root=w.parents[2]
r=root/'reports/TRACK4-V7-ALGORITHM-BRIDGE-001'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
base=json.loads((r/'baseline.json').read_text(encoding='utf-8'));changed=[];diff=[]
for f in base['files']:
    original=Path(f['source']);p=w/f['relative']
    assert sha(original)==f['sha256'],'Original changed: '+str(original)
    if sha(p)!=f['sha256']:
        changed.append(f['relative'])
        diff+=list(difflib.unified_diff(original.read_text(encoding='utf-8-sig').splitlines(True),
            p.read_text(encoding='utf-8-sig').splitlines(True),fromfile='BASE/'+f['relative'],tofile='BRIDGE/'+f['relative']))
assert sorted(changed)==sorted(['rtl/rawcard_overlay.v','rtl/ti60f225_oob_top.v','ti60f225_oob.xml']),changed
new='rtl/v7_algorithm_video_pair.sv'
diff+=list(difflib.unified_diff([], (w/new).read_text(encoding='utf-8').splitlines(True),fromfile='/dev/null',tofile='BRIDGE/'+new))
(r/'production.diff').write_text(''.join(diff),encoding='utf-8')
paths=[f['relative'] for f in base['files']]+[new]
inputs={'timestamp':datetime.datetime.now().astimezone().isoformat(),'count':len(paths),
        'files':[dict(relative=p,sha256=sha(w/p)) for p in sorted(paths)]}
(r/'build-inputs.json').write_text(json.dumps(inputs,indent=2),encoding='utf-8')
driver=(root/'work/active/track4_v7_pixel_order_001_20261018/tests/run_build.py').read_text(encoding='utf-8')
(w/'tests/run_build.py').write_text(driver.replace('TRACK4-V7-PIXEL-ORDER-001','TRACK4-V7-ALGORITHM-BRIDGE-001'),encoding='utf-8')
print('Frozen',len(paths),'build inputs. Unchanged original and frontend hashes verified.')
