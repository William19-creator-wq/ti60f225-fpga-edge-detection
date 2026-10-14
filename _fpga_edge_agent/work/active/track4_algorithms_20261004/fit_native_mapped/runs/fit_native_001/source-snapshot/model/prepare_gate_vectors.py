"""NM01: deterministic additional mapped check; preserve original full suite."""
from pathlib import Path
import json, hashlib, shutil, sys, collections

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest().upper()

def prepare(inputs, output):
    inputs=Path(inputs);output=Path(output);assert not output.exists()
    manifest=json.loads((inputs/"full-manifest.json").read_text(encoding="utf-8"))
    source=inputs/"full-numeric.tsv";lines=source.read_text(encoding="ascii").splitlines()
    assert manifest["count"]==14517 and len(lines)==14517 and sha(source)==manifest["vectors_sha256"]
    groups={}
    for case in manifest["cases"]:groups.setdefault((case["kind"],case["label"]),[]).append(case["index"])
    selected=set()
    for key,indices in groups.items():
        if len(indices)<100:selected.update(indices)
        else:selected.update(indices[(len(indices)-1)*part//3] for part in range(4))
    indices=sorted(selected);assert len(indices)==225
    output.mkdir(parents=True);numeric=output/"numeric.tsv"
    numeric.write_text("\n".join(lines[i] for i in indices)+"\n",encoding="ascii")
    shutil.copyfile(inputs/"full-cache-directed.tsv",output/"cache-directed.tsv")
    current={**manifest,"count":225,"vectors_sha256":sha(numeric),"cases":[case for case in manifest["cases"] if case["index"] in selected]}
    (output/"manifest.json").write_text(json.dumps(current,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    counts=dict(collections.Counter(c["kind"] for c in current["cases"]));assert counts=={11:48,12:44,13:20,14:37,15:30,17:23,18:23}
    selection={"scope":"ADDITIONAL_MAPPED225_WITH_FULL_ORIGINAL_PROTOCOL_NOT_FULL14517_MAPPED","source_count":14517,"source_vectors_sha256":sha(source),"source_manifest_sha256":sha(inputs/"full-manifest.json"),"selection":"all groups<100; four fixed evenly distributed positions per large(kind,label)","indices":indices,"selected_count":225,"counts_by_kind":counts,"selected_vectors_sha256":sha(numeric),"original_full_rtl_suite_modified":False}
    (output/"selection.json").write_text(json.dumps(selection,ensure_ascii=False,indent=2)+"\n",encoding="utf-8");print(json.dumps({"selected":225,"counts":counts},ensure_ascii=False))

if __name__=="__main__":
    if len(sys.argv)!=3:raise SystemExit("usage: prepare_gate_vectors.py INPUTS OUTPUT")
    prepare(sys.argv[1],sys.argv[2])
