"""RR01..05 数值/固定延迟/六个HD整帧的独立公开接口参考。"""
import csv
import hashlib
import json
import sys
from pathlib import Path


def configuration(mode, height, flags):
    value = mode
    for field, width in ((height//2, 11), (0xF12345, 24), (0x13AB57, 24),
                         (0x2468DE, 24), (0xF0E1D2, 24), (flags, 2)):
        value = value << width | field
    return value


def gray(rgb):
    r, g, b = rgb >> 16 & 255, rgb >> 8 & 255, rgb & 255
    return (77*r + 150*g + 29*b + 128) // 256


def compose(pair, config, controls, x, y, pixels, identity, width, height):
    if not controls & 8:
        return 0, 0
    mode, split = config >> 109, config >> 98 & 2047
    if mode >= 6 or split != height//2 or x % 2 or x >= width or y >= height:
        return 0, 2
    if not identity:
        return 0, 3
    if not pixels:
        return 0, 1
    result = 0
    for lane in range(2):
        original = pair >> (lane*24) & 0xFFFFFF
        edge = pair >> (48+lane) & 1
        ann = pair >> (50+lane*2) & 3
        luminance = gray(original)
        color = original
        if mode == 0:
            color = luminance * 0x010101 if y < split else 0xFFFFFF * edge
        elif mode == 2:
            color = luminance * 0x010101
        elif mode == 3:
            color = 0xFFFFFF * edge
        elif mode in (4, 5):
            if config & 2 and edge:
                color = config >> 74 & 0xFFFFFF
            if mode == 5 and config & 1 and ann:
                color = config >> {1: 50, 2: 26, 3: 2}[ann] & 0xFFFFFF
        result |= color << (lane*24)
    return result, 0


def image_rgb(x, y, frame):
    return ((37*x+11*y+3*frame) % 256 << 16) | (
        (13*x+47*y+7*frame) % 256 << 8) | ((53*x+19*y+17*frame) % 256)


def image_pair(mode, x, y, height):
    source_y = 2*(y % (height//2)) if mode == 0 else y
    mask = (1 if y < height//2 else 2) if mode == 0 else {1: 1, 2: 1, 3: 2, 4: 3, 5: 7}[mode]
    value = 0
    for lane in range(2):
        px = x+lane
        if mask & 1:
            value |= image_rgb(px, source_y, mode+1) << (24*lane)
        if mask & 2:
            value |= int((px+source_y+mode+1) % 3 == 0) << (48+lane)
        if mask & 4:
            value |= ((7*px+3*source_y+mode+1) % 4) << (50+2*lane)
    return value


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest().upper()


def audit(root):
    metrics = json.loads((root/"protocol-metrics.json").read_text(encoding="utf-8-sig"))
    assert metrics["finished"] is True
    width, height = metrics["width"], metrics["height"]
    assert metrics["accepted"] == metrics["delivered"] + metrics["reset_aborted"] + metrics["pending_at_finish"]
    assert metrics["resets"] == 2 and metrics["reset_aborted"] == 1
    cases, modes, flags, errors, rg_coverage, metadata = 0, set(), set(), set(), set(), set()
    previous_input = -1
    with (root/"renderer-trace.csv").open(encoding="utf-8", newline="") as stream:
        for e in csv.DictReader(stream):
            incoming, outgoing = int(e["in_cycle"]), int(e["out_cycle"])
            assert incoming > previous_input and outgoing == incoming+1, "Actual accepted-edge latency changed"
            previous_input = incoming
            pair, render = int(e["pair"], 16), int(e["render"], 16)
            ctrl, x, y = int(e["in_ctrl"]), int(e["in_x"]), int(e["in_y"])
            expected, error = compose(pair, render, ctrl, x, y, int(e["pixels"]), int(e["identity"]), width, height)
            assert int(e["out_rgb"], 16) == expected, f"RGB differs at input edge {incoming}"
            assert (int(e["out_ctrl"]), int(e["out_x"]), int(e["out_y"]), int(e["error"])) == (ctrl, x, y, error)
            mode = render >> 109
            modes.add(mode);flags.add(render & 3);errors.add(error);metadata.add(pair >> 48)
            if mode == 2 and error == 0 and ctrl & 8:
                rg_coverage.add(pair >> 8 & 0xFFFF)
            cases += 1
    assert cases == metrics["trace_cases"] and cases >= 69911
    assert set(range(8)) <= modes and flags == {0, 1, 2, 3} and errors == {0, 1, 2, 3}
    assert len(rg_coverage) == 65536 and metadata == set(range(64))
    frames = []
    if metrics["hd_frames"]:
        assert (width, height, metrics["hd_frames"]) == (1920, 1080, 6)
        for mode in range(6):
            path = root/f"frame-mode{mode}.bin"
            assert path.stat().st_size == 1237500*12
            configuration_bits = configuration(mode, height, 0 if mode == 0 else 3)
            digest = hashlib.sha256()
            active_pixels = 0
            with path.open("rb") as stream:
                for v in range(1125):
                    row = bytearray()
                    for h in range(1100):
                        de = h < 960 and v < 1080
                        control = (int(de)<<3) | (int(1004 <= h < 1026)<<2) | (int(1084 <= v < 1089)<<1) | int(h == v == 0)
                        x, y = (h*2, v) if de else (0, 0)
                        source = image_pair(mode, x, y, height) if de else 0
                        rgb, error = compose(source, configuration_bits, control, x, y, 1, 1, width, height)
                        row.extend(rgb.to_bytes(6, "little"))
                        row.extend((control, error));row.extend(x.to_bytes(2, "little"));row.extend(y.to_bytes(2, "little"))
                        active_pixels += 2*de
                    actual = stream.read(1100*12)
                    if actual != row:
                        diff = next(n for n in range(1100) if actual[n*12:(n+1)*12] != row[n*12:(n+1)*12])
                        raise AssertionError(f"HD mode {mode} v={v} h={diff}: RGB/timing/coordinate/error differs")
                    digest.update(row)
                assert not stream.read(1)
            assert active_pixels == 2073600 and digest.hexdigest().upper() == sha(path)
            frames.append(dict(mode=mode, actual_time_slots=1237500, active_pixels=active_pixels,
                               bytes=path.stat().st_size, sha256=digest.hexdigest().upper()))
            print(f"HD mode {mode}: full RGB/control/coordinates PASS", flush=True)
    result = dict(status="PASS", trace_cases=cases, all_rg_combinations=len(rg_coverage),
                  metadata_combinations=len(metadata), modes=sorted(modes), error_codes=sorted(errors),
                  sampled_input_to_output_edges=1, registered_stages=2, resets=metrics["resets"],
                  reset_aborted=metrics["reset_aborted"], hd_frames=frames,
                  trace_sha256=sha(root/"renderer-trace.csv"), actual_ddr_verified=False,
                  full_scan_handoff_join_verified=False, hardware_verified=False)
    (root/"reference-result.json").write_text(json.dumps(result, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in result.items() if k != "hd_frames"}))


if __name__ == "__main__": audit(Path(sys.argv[1]))
