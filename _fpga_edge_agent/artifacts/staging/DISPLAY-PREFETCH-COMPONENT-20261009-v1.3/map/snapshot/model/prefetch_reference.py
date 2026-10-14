"""PF01..07 独立事件审计：公开packed协议/字节地址/实际握手；不读RTL状态。"""
import hashlib
import json
import sys
from pathlib import Path


def unpack(value, fields):
    value = int(value, 16)
    result = {}
    for name, width in reversed(fields):
        result[name] = value & ((1 << width) - 1)
        value >>= width
    assert value == 0, "Packed width overflow"
    return result


TICKET = [(n, 64) for n in ("gen", "seq", "scan", "result", "policy")] + [
    ("origin", 195), ("y", 11), ("sy", 11), ("mode", 3), ("mask", 3)]
BUNDLE = [("op", 4), ("status", 4), ("source", 64), ("result", 64),
          ("origin", 195), ("cj", 142), ("body", 400), ("policy", 64),
          ("source_slot", 3), ("result_slot", 2)]


def pixel(x, y, f):
    return ((37*x + 11*y + 3*f) % 256 << 16) | (
        (13*x + 47*y + 7*f) % 256 << 8) | (53*x + 19*y + 17*f) % 256


def pair(t, address):
    x, y, f = address * 2, t["sy"], (t["origin"] & 7) + 1
    rgb = pixel(x, y, f) | pixel(x+1, y, f) << 24 if t["mask"] & 1 else 0
    edge = int((x+y+f) % 3 == 0) | int((x+1+y+f) % 3 == 0) << 1 if t["mask"] & 2 else 0
    ann = (7*x+3*y+f) % 4 | ((7*(x+1)+3*y+f) % 4) << 2 if t["mask"] & 4 else 0
    return rgb | edge << 48 | ann << 50


def spans(t, b, w):
    base = 0x03000000 + b["result_slot"] * 0x00800000
    def aligned(addr, start, end):
        return addr + start // 16 * 16, addr + (end+15) // 16 * 16
    ranges = []
    if t["mask"] & 2:
        bit = t["sy"] * w
        ranges.append(aligned(base, bit//8, (bit+w+7)//8))
    if t["mask"] & 4:
        bit = t["sy"] * w * 2
        ranges.append(aligned(base+0x00100000+4224, bit//8, (bit+2*w+7)//8))
    if t["mask"] & 1:
        start = t["sy"] * w * 3
        ranges.append(aligned(b["source_slot"]*0x00800000, start, start+3*w))
    return ranges


def byte_at(addr, b, w, h):
    n = w*h
    if addr < 0x03000000:
        slot, offset = addr//0x00800000, addr % 0x00800000
        if slot < 6 and offset < 3*n:
            p, channel = divmod(offset, 3)
            color = pixel(p % w, p//w, slot+1)
            return (color >> (16-8*channel)) & 255
    elif addr < 0x04800000:
        slot, offset = divmod(addr-0x03000000, 0x00800000)
        assert slot == b["result_slot"], "Reading another result"
        f = b["source_slot"] + 1
        if offset < (n+7)//8:
            return sum(int(((offset*8+i) % w + (offset*8+i)//w + f) % 3 == 0) << i
                       for i in range(8) if offset*8+i < n)
        map_offset = offset - 0x00100000 - 4224
        if 0 <= map_offset < (n+3)//4:
            return sum(((7*((map_offset*4+i) % w) + 3*((map_offset*4+i)//w) + f) % 4) << (2*i)
                       for i in range(4) if map_offset*4+i < n)
    return 0xE5


def audit(root):
    metrics = json.loads((root/"protocol-metrics.json").read_text(encoding="utf-8-sig"))
    assert metrics["finished"] is True
    w, h, p = metrics["width"], metrics["height"], metrics["width"]//2
    jobs, counts, last = {}, {"write": 0, "read": 0, "ar": 0, "r": 0}, None
    all_modes, prefixes, q_reasons = set(), set(), set()
    def finish(j):
        assert j["ack"] == j["expect_status"]
        if j["ack"]:
            assert j["closed"] and not j["ars"] and not j["writes"] and j["done"] is None
            return
        d = j["done"]
        assert d is not None and d["outcome"] == j["expect_outcome"]
        assert d["delivered"] == len(j["writes"]) and d["prepared"] - d["delivered"] in (0, 1)
        if d["outcome"] == 0:
            assert d["prepared"] == d["delivered"] == p and d["drained"] == 1 and not d["returned"]
            assert len(j["reads"]) == p and j["publish"] == 1 and j["return"] == 1
            assert not j["abort"] and j["active"] is None
            expected = spans(j["t"], j["b"], w)
            cursor, plane = expected[0][0], 0
            for ar in j["ars"]:
                assert ar["address"] == cursor, "Read omitted/duplicated a plane span"
                cursor += 16*(ar["len"]+1)
                assert cursor <= expected[plane][1]
                if cursor == expected[plane][1]:
                    plane += 1
                    if plane < len(expected): cursor = expected[plane][0]
            assert plane == len(expected)
            assert d["beats"] == j["responses"]
        elif d["outcome"] in (1, 2):
            assert d["drained"] == 1 and d["returned"] == 1 and j["active"] is None
            assert j["abort"] == j["abort_return"] == 1 and not j["publish"] and not j["reads"]
            assert d["beats"] == j["responses"]
        else:
            assert d["drained"] == d["returned"] == 0 and j["publish"] == j["abort"] == j["abort_return"] == 0
            q_reasons.add(d["reason"])
    with (root/"prefetch-events.jsonl").open(encoding="utf-8") as source:
        for line in source:
            e = json.loads(line)
            if e["event"] == "reset": continue
            c, kind = e["case"], e["event"]
            if kind == "job":
                j = dict(e, t=unpack(e["ticket"], TICKET), b=unpack(e["bundle"], BUNDLE),
                         ars=[], active=None, responses=0, writes=[], reads=[], ack=None, done=None,
                         publish=0, abort=0, abort_return=0, return_count=0, closed=False)
                j["return"] = 0
                jobs[c], last = j, c
                if e["expect_status"] == 0:
                    all_modes.add(j["t"]["mode"])
                    prefixes.add((j["t"]["sy"]*w*3 % 16, j["t"]["sy"]*w % 128, j["t"]["sy"]*w*2 % 128))
                continue
            j = jobs[c]
            if kind == "ar":
                assert j["active"] is None, "Second AR without actual prior end"
                assert e["id"] == 2 and 0 <= e["len"] < 64 and e["address"] % 16 == 0
                end = e["address"] + 16*(e["len"]+1)
                assert e["address"]//4096 == (end-1)//4096
                assert any(a <= e["address"] < end <= b for a, b in spans(j["t"], j["b"], w)), "AR outside row descriptor allocation"
                j["ars"].append(e);j["active"] = dict(e, index=0)
                counts["ar"] += 1
            elif kind == "r":
                ar = j["active"]
                assert ar is not None, "R without real AR"
                index = ar["index"]
                expected_id = 3 if j["fault"] == 2 and index == 0 else 2
                expected_resp = 2 if j["fault"] == 1 and index == 0 else 0
                expected_last = int(index == ar["len"])
                if j["fault"] == 3 and index == 0: expected_last = 1
                if j["fault"] == 4: expected_last = int(index == ar["len"]+1)
                assert (e["id"], e["resp"], e["last"]) == (expected_id, expected_resp, expected_last)
                data = sum(byte_at(ar["address"]+16*index+i, j["b"], w, h) << (8*i) for i in range(16))
                if j["fault"] == 4 and index == ar["len"]+1: data = 0
                assert int(e["data"], 16) == data, "AXI byte source diverged from independent model"
                ar["index"] += 1;j["responses"] += 1;counts["r"] += 1
                if index == ar["len"] + int(j["fault"] == 4): j["active"] = None
            elif kind in ("write", "read"):
                bucket = "writes" if kind == "write" else "reads"
                assert e["address"] == len(j[bucket]) and e["address"] < p
                assert int(e["data"], 16) == pair(j["t"], e["address"]), "Full54 numeric/coordinate/mode mismatch"
                j[bucket].append(e["data"]);counts[kind] += 1
            elif kind == "ack":
                assert j["ack"] is None;j["ack"] = e["status"]
            elif kind == "done":
                assert j["done"] is None;j["done"] = e
            elif kind in ("publish", "abort", "abort_return", "return"):
                j[kind] += 1
                if kind in ("abort_return", "return"):
                    assert e["ticket"] == j["ticket"] and e["kind"] == int(kind == "abort_return")
                if kind in ("publish", "abort"):
                    assert j["active"] is None, "Row closed before actual R tail"
            elif kind == "reject_closed": j["closed"] = True
            else: raise AssertionError(f"Unknown event {kind}")
    for j in jobs.values(): finish(j)
    # busy测试的上一行延迟归还，直到下一job才处理；其日志case归属由TB固定。
    assert len(jobs) == metrics["cases"] and all_modes == set(range(6))
    assert counts["read"] * 2 == metrics["read_pixels"]
    result = dict(status="PASS", cases=len(jobs), **counts, modes=sorted(all_modes),
                  distinct_prefixes=len(prefixes), quarantine_reasons=sorted(q_reasons),
                  ideal_mode5_cycles=metrics["ideal_mode5_cycles"],
                  ideal_mode5_us=metrics["ideal_mode5_cycles"]*.01,
                  row_budget_us=14.814815, actual_ddr_verified=False, hardware_verified=False,
                  events_sha256=hashlib.file_digest((root/"prefetch-events.jsonl").open("rb"), "sha256").hexdigest())
    (root/"reference-result.json").write_text(json.dumps(result, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(result))


if __name__ == "__main__": audit(Path(sys.argv[1]))
