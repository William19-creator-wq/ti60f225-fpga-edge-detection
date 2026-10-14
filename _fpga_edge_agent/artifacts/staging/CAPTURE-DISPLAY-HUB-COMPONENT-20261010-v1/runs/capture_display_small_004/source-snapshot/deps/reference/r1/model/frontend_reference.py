"""批准的 FE v1 / R1 v1.1 独立二维整数参考及固定向量。

灰度用直接整数式，中值用普通排序，两个邻域分别按有限图夹紧。
不模拟 RAM、流水、比较网络或状态机；scenario 只供 TB 注入协议事件。
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
import random
import re
import sys
from pathlib import Path

WORK_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = WORK_ROOT.parents[4]
NAME = re.compile(r"[A-Za-z0-9_-]+\Z")
DESIGNS = {
    "_fpga_edge_agent/planning/design-TRACK4-FRONTEND-001.md":
        "45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114",
    "_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R1-001.md":
        "F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00",
    "_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R1-001-v1.1.md":
        "DD2CCF11D0FEEE7CCFE8A3A679B004B5CD33998A2D7B3B2F79306911793B21E0",
}


def integer(value, low: int, high: int, name: str) -> int:
    if type(value) is not int or not low <= value <= high:
        raise ValueError(f"{name}: expected integer in [{low},{high}]")
    return value


def dimensions(width: int, height: int) -> int:
    integer(width, 4, 1920, "width")
    integer(height, 3, 1080, "height")
    if width % 2:
        raise ValueError("width must be even")
    return width * height


def _image_values(values, width, height, name) -> tuple:
    size = dimensions(width, height)
    if isinstance(values, (str, bytes)) or len(values) != size:
        raise ValueError(f"{name}: wrong complete image length")
    snapshot = tuple(values)
    for value in snapshot:
        integer(value, 0, 255, name)
    return snapshot


def _gray_pixel(pixel) -> int:
    if type(pixel) is not tuple or len(pixel) != 3:
        raise ValueError("RGB pixel must be an integer triple tuple")
    r, g, b = (integer(v, 0, 255, "RGB channel") for v in pixel)
    return (77*r + 150*g + 29*b + 128) // 256


def gray_image(rgb, width: int, height: int) -> list:
    size = dimensions(width, height)
    if type(rgb) is not tuple or len(rgb) != size:
        raise ValueError("RGB input must be a complete immutable tuple")
    # 先验证整个输入，失败不返回任何部分图。
    for pixel in rgb:
        _gray_pixel(pixel)
    return [(77*r + 150*g + 29*b + 128) // 256 for r, g, b in rgb]


def _window_unchecked(values, width, height, x, y) -> tuple:
    return tuple(values[min(height-1, max(0, y+dy))*width + min(width-1, max(0, x+dx))]
                 for dy in (-1, 0, 1) for dx in (-1, 0, 1))


def median_image(gray, width: int, height: int, enabled: bool) -> list:
    values = _image_values(gray, width, height, "gray")
    if type(enabled) is not bool:
        raise ValueError("median enabled must be bool")
    if not enabled:
        return list(values)
    return [sorted(_window_unchecked(values, width, height, x, y))[4]
            for y in range(height) for x in range(width)]


def median_window(window) -> int:
    if len(window) != 9:
        raise ValueError("window must contain exactly nine values")
    values = [integer(v, 0, 255, "window") for v in window]
    return sorted(values)[4]


def sobel_window(window, threshold: int) -> dict:
    integer(threshold, 0, 2047, "threshold")
    if len(window) != 9:
        raise ValueError("window must contain exactly nine values")
    a, b, c, d, e, f, g, h, i = [integer(v, 0, 255, "window") for v in window]
    gx, gy = c + 2*f + i - a - 2*d - g, g + 2*h + i - a - 2*b - c
    l1 = abs(gx) + abs(gy)
    integer(gx, -1020, 1020, "gx")
    integer(gy, -1020, 1020, "gy")
    integer(l1, 0, 1530, "l1")
    return {"gx": gx, "gy": gy, "l1": l1, "edge": int(l1 > threshold), "m": e}


def sobel_image(filtered, width: int, height: int, threshold: int) -> dict:
    values = _image_values(filtered, width, height, "filtered")
    integer(threshold, 0, 2047, "threshold")
    result = {key: [] for key in ("gx", "gy", "l1", "edge")}
    # 直接读取夹紧后的二维坐标，完全不共享中值的外侧延拓。
    for y in range(height):
        top, middle, bottom = max(0, y-1)*width, y*width, min(height-1, y+1)*width
        for x in range(width):
            left, right = max(0, x-1), min(width-1, x+1)
            gx = (values[top+right] + 2*values[middle+right] + values[bottom+right]
                  - values[top+left] - 2*values[middle+left] - values[bottom+left])
            gy = (values[bottom+left] + 2*values[bottom+x] + values[bottom+right]
                  - values[top+left] - 2*values[top+x] - values[top+right])
            l1 = abs(gx) + abs(gy)
            if not (-1020 <= gx <= 1020 and -1020 <= gy <= 1020 and 0 <= l1 <= 1530):
                raise AssertionError("Sobel mathematical bound violated")
            for key, value in (("gx", gx), ("gy", gy), ("l1", l1), ("edge", int(l1 > threshold))):
                result[key].append(value)
    return result


def frontend_image(rgb, width, height, median_enable, output_kind, threshold) -> dict:
    integer(output_kind, 0, 1, "output_kind")
    y = gray_image(rgb, width, height)
    m = median_image(y, width, height, median_enable)
    sobel = sobel_image(m, width, height, threshold)
    return {"y": y, "m": m, **sobel,
            "edge": sobel["edge"] if output_kind else [0] * len(m)}


def file_digest(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1048576), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def create_output_directory(output_directory: str) -> Path:
    path = Path(output_directory)
    if not path.is_absolute() or ".." in path.parts:
        raise ValueError("output must be an absolute path without ..")
    path = path.resolve()
    try:
        parts = path.relative_to(WORK_ROOT).parts
    except ValueError:
        raise ValueError("output must remain inside the approved R1 work root") from None
    # 标准sim向量目录；根本轮分工允许的独立参考自检仅写model/runs。
    valid = ((len(parts) == 5 and parts[:3] in (("sim", "frontend", "runs"),("sim", "r1", "runs"))) or
             (len(parts) == 4 and parts[:2] == ("model", "runs")))
    if not valid or not NAME.fullmatch(parts[-2]) or parts[-1] not in ("vectors", "r1-vectors"):
        raise ValueError("output must be a new runs/<RunId>/vectors child")
    if path.exists():
        raise ValueError("output directory already exists; never overwrite a run")
    path.mkdir(parents=True, exist_ok=False)
    return path


def write_hex(path: Path, values, bits: int) -> int:
    count = 0
    digits = (bits+3)//4
    with path.open("x", encoding="ascii", newline="\n") as target:
        for value in values:
            integer(value, 0, (1 << bits)-1, "hex value")
            target.write(f"{value:0{digits}x}\n")
            count += 1
    return count


def _rgb_pairs(rgb):
    for j in range(0, len(rgb), 2):
        a, b = rgb[j:j+2]
        yield ((a[0] << 16) | (a[1] << 8) | a[2]) | ((b[0] << 16) | (b[1] << 8) | b[2]) << 24


def _byte_pairs(values):
    return (values[j] | values[j+1] << 8 for j in range(0, len(values), 2))


def _packed_window(window):
    return sum(integer(v, 0, 255, "window") << (8*j) for j, v in enumerate(window))


def _paired_windows(windows):
    return (_packed_window(windows[j]) | _packed_window(windows[j+1]) << 72
            for j in range(0, len(windows), 2))


def _paired_sobel(windows, threshold):
    for j in range(0, len(windows), 2):
        a, b = sobel_window(windows[j], threshold), sobel_window(windows[j+1], threshold)
        yield ((a["m"] | b["m"] << 8) | (a["edge"] | b["edge"] << 1) << 16 |
               ((a["gx"] & 2047) | (b["gx"] & 2047) << 11) << 18 |
               ((a["gy"] & 2047) | (b["gy"] & 2047) << 11) << 40 |
               (a["l1"] | b["l1"] << 11) << 62)


def reference_self_checks() -> dict:
    colors = [((0,0,0),0), ((255,255,255),255), ((255,0,0),77),
              ((0,255,0),149), ((0,0,255),29)]
    for rgb, expected in colors:
        assert _gray_pixel(rgb) == expected
    for value in range(256):
        assert _gray_pixel((value,value,value)) == value
    max_l1 = 0
    for bits in itertools.product((0,255), repeat=9):
        assert median_window(bits) == (255 if bits.count(255) >= 5 else 0)
        max_l1 = max(max_l1, sobel_window(bits, 0)["l1"])
    assert max_l1 == 1530
    ramp = [0,1,2,3,10,11,12,13,20,21,22,23]
    expected_m = [1,2,3,3,10,11,12,13,20,20,21,22]
    m = median_image(ramp, 4, 3, True)
    assert m == expected_m
    corners = [0,3,8,11]
    med_l1 = sobel_image(m,4,3,0)["l1"]
    bypass_l1 = sobel_image(ramp,4,3,0)["l1"]
    assert [med_l1[i] for i in corners] == [40]*4
    assert [bypass_l1[i] for i in corners] == [44]*4
    invalid = [(lambda: dimensions(True,3)), (lambda: dimensions(5,3)),
               (lambda: dimensions(4,2)), (lambda: median_window([0]*8)),
               (lambda: median_window([False]*9)), (lambda: sobel_window([0]*9,2048)),
               (lambda: gray_image(((0,0,0),)*11,4,3)),
               (lambda: gray_image(((256,0,0),)*12,4,3)),
               (lambda: median_image([0]*12,4,3,1))]
    for call in invalid:
        try:
            call()
        except ValueError:
            continue
        raise AssertionError("invalid reference input was accepted")
    source = [1]*12
    copied = median_image(source,4,3,False)
    copied[0] = 2
    assert source[0] == 1
    return {"gray_hand_cases": [[list(rgb), y] for rgb,y in colors], "gray_levels_checked":256,
            "binary_windows_checked":512, "max_binary_sobel_l1":max_l1,
            "double_border_m":m, "double_border_corner_l1":[med_l1[i] for i in corners],
            "bypass_corner_l1":[bypass_l1[i] for i in corners],
            "invalid_inputs_rejected":len(invalid), "bypass_alias_check":True}


class SuiteWriter:
    def __init__(self, out):
        self.out, self.cases = out, []

    def add(self, cid, kind, stimulus, expected, *, width=4, height=3,
            median=False, output_kind=1, threshold=0, scenario=None):
        if not NAME.fullmatch(cid) or any(v["case_id"] == cid for v in self.cases):
            raise ValueError("invalid/duplicate case id")
        dimensions(width,height)
        if type(median) is not bool:
            raise ValueError("median_enable must be bool")
        integer(output_kind,0,3,"output_kind")
        integer(threshold,0,2047,"threshold")
        widths = {"gray":(48,16), "median":(144,16), "sobel":(144,84),
                  "window":(16,144), "frontend":(48,18)}
        stimulus_bits, expected_bits = widths[kind]
        inp, exp = cid+".input.hex", cid+".expected.hex"
        n_in = write_hex(self.out/inp,stimulus,stimulus_bits)
        n_out = write_hex(self.out/exp,expected,expected_bits)
        scenario = scenario or {"name":"normal", "mode":"normal", "events":[]}
        scenario.setdefault("expected_status",0 if kind=="frontend" else "NA")
        scenario.setdefault("allowed_prefix", {"minimum":0, "maximum":n_out})
        scenario.setdefault("ft",cid.split("-")[0].replace("FT","FT-"))
        i = len(self.cases)+1
        self.cases.append({"case_id":cid,"id":cid,"kind":kind,
            "tb":"rgb" if kind=="gray" else kind,"width":width,"height":height,"W":width,"H":height,
            "job_epoch":1,"job_frame_id":i,"job_config_id":i+0x1000,
            "three_ids":{"epoch":1,"frame_id":i,"config_id":i+0x1000},
            "median_enable":median,"output_kind":output_kind,"threshold":threshold,
            "stimulus_pairs":n_in,"expected_pairs":n_out,"vectors":n_in,
            "scenario":scenario,"input_file":inp,"stimulus_file":inp,"expected_file":exp,
            "input_sha256":file_digest(self.out/inp),"stimulus_sha256":file_digest(self.out/inp),
            "expected_sha256":file_digest(self.out/exp),
            "stimulus_bits":stimulus_bits,"expected_bits":expected_bits})
        if scenario.get("name") == "lfsr":
            self.cases[-1]["protocol_seed"] = scenario["seed"]
            scenario["random_stalls"] = True

    def image(self,cid,rgb,width,height,median=False,output_kind=1,threshold=0,scenario=None):
        # BAD_CONFIG仍保存完整正常数值黄金供实际已交付前缀/恢复job比较；原job不准输出。
        values = frontend_image(rgb,width,height,median,min(output_kind,1),threshold)
        expected = ((values["m"][j] | values["m"][j+1] << 8) |
                    (values["edge"][j] | values["edge"][j+1] << 1) << 16
                    for j in range(0,len(rgb),2))
        self.add(cid,"frontend",_rgb_pairs(rgb),expected,width=width,height=height,
                 median=median,output_kind=output_kind,threshold=threshold,scenario=scenario)
        if scenario and scenario.get("next_job_recovery") and scenario["mode"] in ("cancel","input_error","bad_config"):
            # 失败/取消后不复位直接接受下一合法job；完整黄金另列，绝非PASS标签。
            case = self.cases[-1]
            recovery_kind = output_kind if output_kind < 2 else 0
            recovery = frontend_image(rgb,width,height,median,recovery_kind,threshold)
            inp,exp = cid+".followup.input.hex",cid+".followup.expected.hex"
            n_in = write_hex(self.out/inp,_rgb_pairs(rgb),48)
            n_out = write_hex(self.out/exp,((recovery["m"][j] | recovery["m"][j+1]<<8) |
                (recovery["edge"][j] | recovery["edge"][j+1]<<1)<<16 for j in range(0,len(rgb),2)),18)
            case["follow_up"] = {"width":width,"height":height,"job_epoch":2,
                "job_frame_id":case["job_frame_id"]+0x01000000,"job_config_id":case["job_config_id"]+0x01000000,
                "median_enable":median,"output_kind":recovery_kind,"threshold":threshold,
                "input_file":inp,"stimulus_file":inp,"expected_file":exp,
                "stimulus_pairs":n_in,"expected_pairs":n_out,"stimulus_bits":48,"expected_bits":18,
                "input_sha256":file_digest(self.out/inp),"stimulus_sha256":file_digest(self.out/inp),
                "expected_sha256":file_digest(self.out/exp)}


def _gray_rgb(values):
    return tuple((v,v,v) for v in values)


def _scenario(name,ft,events=None,mode="normal",status=0,**extra):
    return {"name":name,"ft":ft,"mode":mode,"events":events or [],"expected_status":status,**extra}


def _build_suite(writer):
    rng = random.Random(0x431)
    samples = [(0,0,0),(255,255,255),(255,0,0),(0,255,0),(0,0,255)]
    samples += [(v,v,v) for v in range(256)]
    samples += list(itertools.product((0,1,127,128,254,255),repeat=3))
    if len(samples)%2:
        samples.append(samples[-1])
    writer.add("FT01-gray-fixed","gray",_rgb_pairs(tuple(samples)),_byte_pairs([_gray_pixel(p) for p in samples]))
    samples = tuple(tuple(rng.randrange(256) for _ in range(3)) for _ in range(8192))
    writer.add("FT01-gray-random","gray",_rgb_pairs(samples),_byte_pairs([_gray_pixel(p) for p in samples]))
    binary = list(itertools.product((0,255),repeat=9))
    duplicate = [(0,)*9,(255,)*9,(127,)*5+(128,)*4,(128,)*5+(127,)*4]
    random_windows = [tuple(rng.randrange(256) for _ in range(9)) for _ in range(8192)]
    for label,windows in (("binary512",binary),("duplicates",duplicate),("random4096",random_windows)):
        for enabled in (False,True):
            med = [median_window(w) if enabled else w[4] for w in windows]
            writer.add(f"FT02-median-{label}-m{int(enabled)}","median",_paired_windows(windows),_byte_pairs(med),median=enabled)
    sobel_windows = [(0,)*9,(255,)*9,(0,0,255,0,0,255,0,0,255),
                     (0,0,0,0,0,0,255,255,255),(0,0,255,0,255,255,255,255,255),
                     (0,0,0,0,128,255,0,255,255)]
    sobel_windows += [tuple(reversed(w)) for w in sobel_windows[2:]]
    for index,window in enumerate(sobel_windows):
        l1 = sobel_window(window,0)["l1"]
        for threshold in sorted({0,2047,max(0,l1-1),l1,min(2047,l1+1)}):
            writer.add(f"FT03-sobel-w{index:02d}-t{threshold}","sobel",
                       _paired_windows([window,window]),_paired_sobel([window,window],threshold),threshold=threshold)
    for width,height in ((4,3),(8,3),(10,5)):
        values = [16*y+x for y in range(height) for x in range(width)]
        windows = [_window_unchecked(values,width,height,x,y) for y in range(height) for x in range(width)]
        writer.add(f"FT04-window-W{width}-H{height}","window",_byte_pairs(values),_paired_windows(windows),width=width,height=height)
    width,height = 8,3
    values = [16*y+x for y in range(height) for x in range(width)]
    windows = [_window_unchecked(values,width,height,x,y) for y in range(height) for x in range(width)]
    writer.add("FT05-ram-transitions","window",_byte_pairs(values),_paired_windows(windows),width=width,height=height,
        scenario=_scenario("ram-transitions","FT-05",[{"event":"input_bubble","at_input_pair":3,"cycles":2},
             {"event":"output_stall","at_output_pair":0,"cycles":2}],status="NA",ram_checks=True))
    ramp = _gray_rgb([0,1,2,3,10,11,12,13,20,21,22,23])
    line = _gray_rgb([0,1,2,3]*3)
    for median in (False,True):
        writer.image(f"FT06-double-border-m{int(median)}",ramp,4,3,median=median,threshold=4)
        writer.image(f"FT06-horizontal-ramp-m{int(median)}",line,4,3,median=median,threshold=4)
    for index in range(6):
        for event,key in (("input_bubble","at_input_pair"),("output_stall","at_output_pair")):
            writer.image(f"FT07-{event.replace('_','-')}-p{index}",ramp,4,3,median=True,threshold=4,
                scenario=_scenario("flow","FT-07",[{"event":event,key:index,"cycles":2}]))
    for seed in (0x431,0x1060):
        writer.image(f"FT07-lfsr-{seed:x}",ramp,4,3,median=True,threshold=4,
            scenario=_scenario("lfsr","FT-07",seed=seed,max_consecutive_stall=8,
                               lfsr_taps=[31,21,1,0],update="each_falling_edge"))
    for median,kind,t in ((False,0,0),(True,1,4)):
        writer.image(f"FT08-config-m{int(median)}-k{kind}",ramp,4,3,median=median,output_kind=kind,threshold=t,
            scenario=_scenario("configuration","FT-08",[{"event":"config_change","at_input_pair":1,
                "changes":{"median_enable":not median,"output_kind":1-kind,"threshold":2047,
                           "job_epoch":9,"job_frame_id":999,"job_config_id":777}},
                {"event":"output_stall","at_output_pair":0,"cycles":3},
                {"event":"status_stall","cycles":3}],mode="configuration",next_job_recovery=True))
        case = writer.cases[-1]
        changed = {"median_enable":not median,"output_kind":1-kind,"threshold":2047,
                   "job_epoch":9,"job_frame_id":999,"job_config_id":777}
        second = frontend_image(ramp,4,3,changed["median_enable"],changed["output_kind"],changed["threshold"])
        inp,exp = case["case_id"]+".followup.input.hex",case["case_id"]+".followup.expected.hex"
        count_in = write_hex(writer.out/inp,_rgb_pairs(ramp),48)
        count_out = write_hex(writer.out/exp,((second["m"][j] | second["m"][j+1] << 8) |
                         (second["edge"][j] | second["edge"][j+1] << 1) << 16 for j in range(0,12,2)),18)
        case["follow_up"] = {**changed,"width":4,"height":3,"input_file":inp,"stimulus_file":inp,
            "expected_file":exp,"stimulus_pairs":count_in,"expected_pairs":count_out,
            "stimulus_bits":48,"expected_bits":18,"input_sha256":file_digest(writer.out/inp),
            "stimulus_sha256":file_digest(writer.out/inp),"expected_sha256":file_digest(writer.out/exp)}
    errors = [("bad",[{"event":"bad","at_input_pair":1,"value":1}],2),
        ("odd-x",[{"event":"coordinate","at_input_pair":1,"field":"x","value":1}],3),
        ("skip-x",[{"event":"coordinate","at_input_pair":1,"field":"x","value":4}],3),
        ("repeat-x",[{"event":"coordinate","at_input_pair":1,"field":"x","value":0}],3),
        ("wrong-y",[{"event":"coordinate","at_input_pair":1,"field":"y","value":1}],3),
        ("sof",[{"event":"marker","at_input_pair":0,"field":"sof","value":0}],4),
        ("eol-missing",[{"event":"marker","at_input_pair":1,"field":"eol","value":0}],4),
        ("eol-early",[{"event":"marker","at_input_pair":0,"field":"eol","value":1}],4),
        ("eof-early",[{"event":"marker","at_input_pair":0,"field":"eof","value":1}],4),
        ("eof-missing",[{"event":"marker","at_input_pair":5,"field":"eof","value":0}],4),
        ("priority",[{"event":"bad","at_input_pair":1,"value":1},
                     {"event":"coordinate","at_input_pair":1,"field":"x","value":1},
                     {"event":"marker","at_input_pair":1,"field":"sof","value":1}],2)]
    for label,events,code in errors:
        writer.image("FT09-"+label,ramp,4,3,threshold=4,scenario=_scenario("input-error","FT-09",events,
            mode="input_error",status=code,expected_accepted_pairs=events[0]["at_input_pair"]+1,next_job_recovery=True))
    for kind in (2,3):
        writer.image(f"FT09-kind{kind}",ramp,4,3,output_kind=kind,threshold=4,
            scenario=_scenario("bad-config","FT-09",mode="bad_config",status=5,
                               expected_accepted_pairs=0,allowed_prefix={"minimum":0,"maximum":0},next_job_recovery=True))
    # 时序/阶段由TB真实信号核查；这里不根据RTL延迟伪造已交付前缀。
    for index in (0,1,5):
        writer.image(f"FT10-cancel-input{index}",ramp,4,3,median=True,threshold=4,
            scenario=_scenario("cancel-input","FT-10",[{"event":"cancel","at_input_pair":index,"when":"accepted"}],mode="cancel",status=1,next_job_recovery=True))
    for index in (0,5):
        writer.image(f"FT10-cancel-output{index}",ramp,4,3,median=True,threshold=4,
            scenario=_scenario("cancel-output","FT-10",[{"event":"cancel","at_output_pair":index,"when":"fire"}],mode="cancel",status=1,next_job_recovery=True))
    writer.image("FT10-cancel-blocked",ramp,4,3,median=True,threshold=4,
        scenario=_scenario("cancel-blocked","FT-10",[{"event":"output_stall","at_output_pair":0,"cycles":4},
            {"event":"cancel","at_output_pair":0,"when":"before"}],mode="cancel",status=1,next_job_recovery=True))
    for index in (0,1,5):
        writer.image(f"FT10-reset-input{index}",ramp,4,3,median=True,threshold=4,
            scenario=_scenario("reset","FT-10",[{"event":"reset","at_input_pair":index,"restart":True,"cycles":2}],mode="reset",status=0,
                               old_job_status_required=False,next_job_recovery=True))
    writer.image("FT10-status-late-cancel",ramp,4,3,median=True,threshold=4,
        scenario=_scenario("status-late-cancel","FT-10",[{"event":"status_stall","cycles":3},
            {"event":"cancel","when":"status"}],status=0))
    phase_rgb = _gray_rgb([16*y+x for y in range(5) for x in range(8)])
    targets = ("f1","window_a_fill","median","window_b_fill","sobel",
               "window_a_replay","window_a_tail","window_b_replay","window_b_tail")
    for target in targets:
        for action in ("cancel","reset"):
            writer.image(f"FT10-{action}-phase-{target.replace('_','-')}",phase_rgb,8,5,median=True,threshold=4,
                scenario=_scenario("phase-"+action,"FT-10",[{"event":action,"target":target,
                    "when":"phase","cycles":2 if action=="reset" else 1,"restart":action=="reset"}],
                    mode=action,status=0 if action=="reset" else 1,next_job_recovery=True,
                    old_job_status_required=action!="reset",required_actual_phase=target))
    width,height = 1920,1080
    specifications = [("constant-m0-y",False,0,0),("vertical-m1-y",True,0,64),
                      ("diagonal-m0-sobel",False,1,512),("saltpepper-m1-sobel",True,1,1530)]
    for label,median,kind,threshold in specifications:
        print(f"generating FT11-{label}: {width}x{height}",flush=True)
        if label.startswith("constant"):
            rgb = ((128,128,128),)*(width*height)
        elif label.startswith("vertical"):
            rgb = tuple((0,0,0) if x<width//2 else (255,255,255) for y in range(height) for x in range(width))
        elif label.startswith("diagonal"):
            rgb = tuple((255,255,255) if x*height >= y*width else (0,0,0) for y in range(height) for x in range(width))
        else:
            noise = random.Random(0x1060)
            pixels = []
            for _ in range(width*height):
                u = noise.random()
                pixels.append((0,0,0) if u<0.0025 else (255,255,255) if u<0.005 else (128,128,128))
            rgb = tuple(pixels)
            del pixels
        writer.image("FT11-"+label,rgb,width,height,median,kind,threshold,
            _scenario("normal","FT-11",expected_status=0,full_pixel_comparison=width*height,
                      seed=0x1060 if label.startswith("salt") else None))


def validate_manifest(directory: Path, manifest: dict) -> dict:
    seen_ids, seen_files = set(),set()
    count = 0
    for case in manifest["cases"]:
        if case["case_id"] in seen_ids or not NAME.fullmatch(case["case_id"]):
            raise ValueError("duplicate or invalid manifest case_id")
        seen_ids.add(case["case_id"])
        records = [case] + ([case["follow_up"]] if "follow_up" in case else [])
        for record,role,bits_field,count_field in ((record,role,bits_field,count_field)
            for record in records for role,bits_field,count_field in
            (("input","stimulus_bits","stimulus_pairs"),("expected","expected_bits","expected_pairs"))):
            relative = Path(record[role+"_file"])
            if relative.is_absolute() or ".." in relative.parts or str(relative) in seen_files:
                raise ValueError("unsafe/duplicate manifest path")
            seen_files.add(str(relative))
            path = (directory/relative).resolve()
            if not path.is_relative_to(directory.resolve()) or file_digest(path) != record[role+"_sha256"]:
                raise ValueError("manifest file/hash mismatch")
            bits = record[bits_field]
            with path.open("r",encoding="ascii") as source:
                n = 0
                for line in source:
                    value = line.removesuffix("\n")
                    if not re.fullmatch(r"[0-9a-f]{"+str((bits+3)//4)+r"}",value) or int(value,16) >= 1<<bits:
                        raise ValueError("noncanonical hex vector")
                    n += 1
            if n != record[count_field]:
                raise ValueError("manifest vector line count mismatch")
            count += n
    covered = {case["scenario"]["ft"] for case in manifest["cases"]}
    if covered != {f"FT-{i:02d}" for i in range(1,12)}:
        raise ValueError("fixed FT coverage incomplete")
    full = [case for case in manifest["cases"] if case["scenario"]["ft"]=="FT-11"]
    if len(full)!=4 or {(c["median_enable"],c["output_kind"]) for c in full}!={(False,0),(True,0),(False,1),(True,1)}:
        raise ValueError("four production jobs incomplete")
    if any(c["stimulus_pairs"]!=1036800 or c["expected_pairs"]!=1036800 for c in full):
        raise ValueError("production complete count mismatch")
    return {"case_count":len(seen_ids),"files_checked":len(seen_files),"hex_lines_checked":count,
            "ft_coverage":sorted(covered),"production_jobs":len(full),"production_expected_pixels":8294400}


def generate_vectors(output_directory: str, suite_name: str) -> dict:
    if suite_name != "frontend-v1":
        raise ValueError("unknown suite; only frontend-v1 is approved")
    evidence = []
    for name,expected in DESIGNS.items():
        path = PROJECT_ROOT/name
        if file_digest(path)!=expected:
            raise ValueError(f"design baseline changed: {name}")
        evidence.append({"path":name,"sha256":expected,"bytes":path.stat().st_size})
    out = create_output_directory(output_directory)
    manifest = {"schema_version":1,"design_version":"FE v1 inherited by R1 v1.1",
                "suite":suite_name,"status":"INCOMPLETE","fixed_seeds":{"numeric":0x431,"saltpepper":0x1060},
                "source_evidence":evidence,"cases":[],"rtl_used_for_reference_generation":False}
    manifest_path = out/"manifest.json"
    manifest_path.write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    writer = SuiteWriter(out)
    try:
        checks = reference_self_checks()
        _build_suite(writer)
        manifest["cases"] = writer.cases
        manifest["reference_self_checks"] = checks
        # 调用可走 ASCII junction；证据与边界都使用实际规范路径。
        for path in (Path(__file__).resolve(),Path(__file__).resolve().with_name("r1_pattern_crc_reference.py")):
            manifest["source_evidence"].append({"path":str(path.relative_to(PROJECT_ROOT)),
                                               "sha256":file_digest(path),"bytes":path.stat().st_size})
        ram = Path(r"C:\Users\34528\FPGAEdgeLinks\Efinity2026_1\sim_models\verilog\efx_ram10.v")
        manifest["vendor_model_evidence"] = {"path":str(ram),"sha256":file_digest(ram),"used_for_generation":False}
        manifest["validation"] = validate_manifest(out,manifest)
        manifest["status"] = "COMPLETE"
        manifest_path.write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
        return manifest
    except Exception as error:
        manifest.update({"status":"INCOMPLETE","error":str(error),"cases":writer.cases})
        manifest_path.write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir",required=True)
    parser.add_argument("--suite",choices=["frontend-v1"],required=True)
    args = parser.parse_args()
    try:
        manifest = generate_vectors(args.out_dir,args.suite)
    except ValueError as error:
        parser.error(str(error))
    except Exception as error:
        print(f"reference generation failed: {error}",file=sys.stderr)
        return 1
    print(json.dumps(manifest["validation"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
