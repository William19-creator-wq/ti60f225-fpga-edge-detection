"""Root授权的FT06数值反例补验；只读冻结独立参考，不改主suite。"""
import hashlib
import importlib.util
import json
from pathlib import Path

run = Path(__file__).resolve().parent
source = run.parents[3] / "model" / "frontend_reference.py"
before = hashlib.sha256(source.read_bytes()).hexdigest().upper()
spec = importlib.util.spec_from_file_location("approved_frontend_reference", source)
reference = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reference)
out = reference.create_output_directory(str(run / "vectors"))
rgb = tuple((value, value, value) for value in (0,1,2,3,10,11,12,13,20,21,22,23))
manifest = {"scope":"SUPPLEMENTAL_FT06_DOUBLE_BORDER_DISCRIMINATOR",
            "reference_source":str(source),"reference_sha256":before,"cases":[]}
for median in (False,True):
    result = reference.frontend_image(rgb,4,3,median,1,41)
    filtered = reference.median_image(reference.gray_image(rgb,4,3),4,3,median)
    diagnostic = reference.sobel_image(filtered,4,3,41)
    corners = (0,3,8,11)
    expected_l1, expected_edge = (40,0) if median else (44,1)
    assert [diagnostic["l1"][i] for i in corners] == [expected_l1]*4
    assert [result["edge"][i] for i in corners] == [expected_edge]*4
    cid = "FT06-T41-m"+str(int(median))
    stimulus, expected = out/(cid+".input.hex"),out/(cid+".expected.hex")
    reference.write_hex(stimulus,reference._rgb_pairs(rgb),48)
    reference.write_hex(expected,((result["m"][j] | result["m"][j+1] << 8) |
        (result["edge"][j] | result["edge"][j+1] << 1) << 16 for j in range(0,12,2)),18)
    manifest["cases"].append({"case_id":cid,"median_enable":median,"stimulus_pairs":6,
        "expected_pairs":6,"stimulus_file":stimulus.name,"expected_file":expected.name,
        "stimulus_sha256":reference.file_digest(stimulus),"expected_sha256":reference.file_digest(expected),
        "corner_pixel_indices":list(corners),"corner_reference_l1":[expected_l1]*4,
        "corner_expected_edges":[expected_edge]*4,"threshold":41,"output_kind":1})
assert hashlib.sha256(source.read_bytes()).hexdigest().upper() == before
manifest["status"] = "COMPLETE"
(out/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
print(json.dumps(manifest))
