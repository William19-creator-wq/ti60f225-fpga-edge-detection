"""R1 v1 的纯公式图样、160 bit 记录及非反射 CRC 参考。

这里只表达有限图和记录数学；不模拟监督器、流水寄存器或 RTL 状态机。
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

WORK_ROOT = Path(__file__).resolve().parents[1]
POLYNOMIAL = 0x04C11DB7


def unsigned(value: int, bits: int, name: str) -> int:
    if type(value) is not int or not 0 <= value < (1 << bits):
        raise ValueError(f"{name} must be unsigned{bits}")
    return value


def job_pattern(k: int) -> dict:
    unsigned(k, 32, "k")
    return {"epoch": 1, "frame_id": k, "config_id": k,
            "median_enable": bool(k & 1), "output_kind": (k >> 1) & 1,
            "pattern": (k >> 2) & 3,
            "threshold": (0, 64, 512, 1530)[(k >> 4) & 3]}


def pattern_rgb(x: int, y: int, width: int, height: int, pattern: int) -> tuple:
    from frontend_reference import dimensions
    dimensions(width, height)
    if type(x) is not int or type(y) is not int or not (0 <= x < width and 0 <= y < height):
        raise ValueError("pattern coordinate outside image")
    unsigned(pattern, 2, "pattern")
    if pattern == 0:
        return x % 256, y % 256, (x ^ y) % 256
    if pattern == 1:
        q = 0 if x < width // 2 else 255
    elif pattern == 2:
        q = 0 if y < height // 2 else 255
    else:
        q = 239 if ((x >> 5) ^ (y >> 5)) & 1 else 16
    return q, q, q


def pack_data_record(filtered: int, edge: int, x: int, y: int,
                     epoch: int, frame_id: int, config_id: int,
                     sof: bool, eol: bool, eof: bool) -> int:
    fields = ((filtered, 16, 0, "filtered"), (edge, 2, 16, "edge"),
              (x, 11, 18, "x"), (y, 11, 29, "y"),
              (epoch, 32, 40, "epoch"), (frame_id, 32, 72, "frame_id"),
              (config_id, 32, 104, "config_id"))
    if x & 1:
        raise ValueError("x must name the even lane")
    result = sum(unsigned(v, n, name) << shift for v, n, shift, name in fields)
    for flag, shift in ((sof, 136), (eol, 137), (eof, 138)):
        if type(flag) is not bool:
            raise ValueError("marker must be bool")
        result |= int(flag) << shift
    return unsigned(result, 160, "data record")


def pack_status_record(code: int, in_pairs: int, out_pairs: int,
                       epoch: int, frame_id: int, config_id: int) -> int:
    if type(code) is not int or not 0 <= code <= 6:
        raise ValueError("reserved/invalid status code")
    return sum(unsigned(v, n, name) << shift for v, n, shift, name in
               ((code, 3, 0, "code"), (in_pairs, 21, 3, "in_pairs"),
                (out_pairs, 21, 24, "out_pairs"), (epoch, 32, 45, "epoch"),
                (frame_id, 32, 77, "frame_id"), (config_id, 32, 109, "config_id")))


def crc_record(record: int, crc: int = 0xFFFFFFFF) -> int:
    unsigned(record, 160, "record")
    unsigned(crc, 32, "crc")
    for bit_index in range(159, -1, -1):
        feedback = (crc >> 31) ^ ((record >> bit_index) & 1)
        crc = (crc << 1) & 0xFFFFFFFF
        if feedback:
            crc ^= POLYNOMIAL
    return crc


def crc_records(records) -> int:
    crc = 0xFFFFFFFF
    for record in records:
        crc = crc_record(record, crc)
    return crc ^ 0xFFFFFFFF


def _polynomial_crc(records) -> int:
    """独立的逐 byte 多项式除法，用于自检 bit 递推和首末值。"""
    crc = 0xFFFFFFFF
    divisor = (1 << 32) | POLYNOMIAL
    for record in records:
        for byte in record.to_bytes(20, "big"):
            remainder = (crc << 8) ^ (byte << 32)
            while remainder.bit_length() > 32:
                remainder ^= divisor << (remainder.bit_length() - 33)
            crc = remainder
    return crc ^ 0xFFFFFFFF


def reference_self_checks() -> dict:
    # 零记录仍必须处理；不同记录次序具有不同数学输入。
    records = [0, 1, 1 << 159, (1 << 160) - 1,
               pack_data_record(0xAB12, 2, 2, 1, 1, 2, 3, False, True, True),
               pack_status_record(0, 6, 6, 1, 2, 3)]
    cases = [[], records[:1], records, list(reversed(records))]
    checks = []
    for values in cases:
        bit_crc, polynomial_crc = crc_records(values), _polynomial_crc(values)
        if bit_crc != polynomial_crc:
            raise AssertionError("independent CRC division disagrees")
        checks.append({"record_count": len(values), "bit_crc": f"{bit_crc:08x}",
                       "polynomial_crc": f"{polynomial_crc:08x}"})
    k_fields = [job_pattern(k) for k in range(64)]
    combinations = {(v["median_enable"], v["output_kind"], v["pattern"], v["threshold"])
                    for v in k_fields}
    if len(combinations) != 64:
        raise AssertionError("k0..63 lacks a pattern/config combination")
    return {"crc_comparisons": checks, "k_combinations_checked": 64,
            "data_record_example": f"{records[4]:040x}",
            "status_record_example": f"{records[5]:040x}"}


def generate_reference_vectors(output_directory: str) -> dict:
    from frontend_reference import create_output_directory, frontend_image, write_hex, file_digest
    out = create_output_directory(output_directory)
    manifest = {"schema_version": 1, "suite": "r1-pattern-crc-v1",
                "status": "INCOMPLETE", "cases": [], "source_only_cases": [], "component_cases": []}
    (out / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    try:
        for width, height in ((4, 3), (8, 5)):
            for k in range(64):
                cfg = job_pattern(k)
                rgb = tuple(pattern_rgb(x, y, width, height, cfg["pattern"])
                            for y in range(height) for x in range(width))
                result = frontend_image(rgb, width, height, cfg["median_enable"],
                                        cfg["output_kind"], cfg["threshold"])
                records = []
                for y in range(height):
                    for x in range(0, width, 2):
                        i = y * width + x
                        records.append(pack_data_record(result["m"][i] | result["m"][i+1] << 8,
                            result["edge"][i] | result["edge"][i+1] << 1, x, y, 1, k, k,
                            x == y == 0, x == width-2, x == width-2 and y == height-1))
                count = width * height // 2
                records.append(pack_status_record(0, count, count, 1, k, k))
                cid = f"R1-W{width}-H{height}-k{k:02d}"
                name = cid + ".records.hex"
                write_hex(out / name, records, 160)
                running, crc = [], 0xFFFFFFFF
                for record in records:
                    crc = crc_record(record, crc)
                    running.append(crc)
                crc_name = cid + ".running-crc.hex"
                write_hex(out / crc_name, running, 32)
                if (crc ^ 0xFFFFFFFF) != _polynomial_crc(records):
                    raise AssertionError("record CRC oracle disagreement")
                manifest["cases"].append({"case_id": cid, "width": width, "height": height,
                    "k": k, **cfg, "data_records": count, "terminal_records": 1,
                    "record_count": len(records), "records_file": name,
                    "records_sha256": file_digest(out / name), "running_crc_file": crc_name,
                    "running_crc_sha256": file_digest(out / crc_name),
                    "final_crc": f"{crc ^ 0xFFFFFFFF:08x}"})
        # J/K typed端口测试输入；故障状态由输入明示，黄金CRC由纯公式算出。
        components = [("normal",6,0,6,6,0,True,True,True),
            ("feed-early-error",1,2,1,1,0,False,False,True),
            ("ok-wrong-id",6,0,6,6,0,True,False,True),
            ("ok-wrong-count",6,0,5,6,0,True,False,True),
            ("ok-in-feed-prefix",1,0,1,1,0,False,False,True),
            ("cancelled-drain",6,1,6,6,0,True,False,True),
            ("exhausted-penultimate",6,0,6,6,0xFFFFFFFE,True,True,True),
            ("exhausted-last",6,0,6,6,0xFFFFFFFF,True,True,False)]
        for cid,n,code,sin,sout,k,drain,good,reset_before in components:
            records = [pack_data_record((0x1234+j*17)&0xFFFF,j&3,(j%2)*2,j//2,1,k,k,
                                       j==0,j%2==1,j==5) for j in range(n)]
            status_id = 99 if cid=="ok-wrong-id" else k
            records.append(pack_status_record(code,sin,sout,1,status_id,k))
            name,crc_name = "component-"+cid+".records.hex","component-"+cid+".running-crc.hex"
            write_hex(out/name,records,160)
            running,crc = [],0xFFFFFFFF
            for record in records:
                crc=crc_record(record,crc)
                running.append(crc)
            write_hex(out/crc_name,running,32)
            assert (crc^0xFFFFFFFF)==_polynomial_crc(records)
            manifest["component_cases"].append({"case_id":cid,"data_records":n,"job_sequence":k,
                "drain_before_status":drain,"expected_good":good,"reset_before":reset_before,
                "record_count":len(records),"records_file":name,"records_sha256":file_digest(out/name),
                "running_crc_file":crc_name,"running_crc_sha256":file_digest(out/crc_name),
                "final_crc":f"{crc^0xFFFFFFFF:08x}"})
        for pattern in range(4):
            width = height = 258
            name = f"R1-source-pattern{pattern}-W258-H258.hex"
            packed = []
            for y in range(height):
                for x in range(0, width, 2):
                    a = pattern_rgb(x, y, width, height, pattern)
                    b = pattern_rgb(x+1, y, width, height, pattern)
                    packed.append(((a[0] << 16) | (a[1] << 8) | a[2]) |
                                  ((b[0] << 16) | (b[1] << 8) | b[2]) << 24)
            write_hex(out / name, packed, 48)
            manifest["source_only_cases"].append({"pattern": pattern, "width": 258,
                "height": 258, "pairs": len(packed), "input_file": name,
                "input_sha256": file_digest(out / name),
                "coordinates_checked": [[31, 31], [32, 32], [128, 128], [129, 129],
                                        [255, 255], [256, 256]]})
        manifest["self_checks"] = reference_self_checks()
        manifest["model_sha256"] = file_digest(Path(__file__).resolve())
        manifest["status"] = "COMPLETE"
        (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        return manifest
    except Exception as error:
        (out / "manifest.json").write_text(json.dumps({**manifest, "error": str(error)}, indent=2), encoding="utf-8")
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", required=True)
    parser.add_argument("--suite", choices=["r1-pattern-crc-v1"], required=True)
    args = parser.parse_args()
    try:
        manifest = generate_reference_vectors(args.out_dir)
    except ValueError as error:
        parser.error(str(error))
    except Exception as error:
        print(f"reference generation failed: {error}")
        return 1
    print(json.dumps({"status": manifest["status"], "cases": len(manifest["cases"]),
                      "source_cases": len(manifest["source_only_cases"])}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
