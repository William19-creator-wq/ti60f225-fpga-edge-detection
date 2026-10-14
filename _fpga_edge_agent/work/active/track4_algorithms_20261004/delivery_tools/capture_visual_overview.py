"""CP-V01..04：实际字节数据3×3最大值概览；旧native/检查点不改。"""
import datetime, hashlib, json, pathlib
from PIL import Image, ImageDraw, ImageFont
ROOT = pathlib.Path('D:/大三/FPGA_verilog/_fpga_edge_agent')
OUT = ROOT / 'experiments/track4_algorithms_20261004/05_delivery'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def fresh(path):
    assert path.resolve().is_relative_to(ROOT.resolve()) and not path.exists()
    return path

def write(path, value):
    fresh(path).write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')
    assert read(path) == value

def main():
    old_path = OUT / 'fast-batch-checkpoint-20261009-v4.json'
    old = read(old_path)
    for name in ('delivery', 'visualization', 'provenance'):
        assert sha(pathlib.Path(old[name])) == old[name + '_sha256']
    for entry in old['new_files_checked']:
        assert sha(pathlib.Path(entry['path'])) == entry['sha256']
    for entry in old['registered_components']:
        assert sha(ROOT / 'artifacts/staging' / entry['artifact'] / 'artifact-manifest.json') == entry['manifest_sha256']
    original = read(pathlib.Path(old['provenance']))
    for entry in original['pictures']:
        assert sha(pathlib.Path(entry['path'])) == entry['sha256']
    source_path, edge_path = pathlib.Path(original['source_path']), pathlib.Path(original['edge_path'])
    assert sha(source_path) == original['source_sha256'] and sha(edge_path) == original['edge_sha256']
    source, edges = source_path.read_bytes(), edge_path.read_bytes()
    assert len(source) == 1920 * 1080 * 3 and len(edges) == 1920 * 1080
    assert set(edges) <= {0, 255} and edges.count(255) == 1078
    coarse = bytearray(640 * 360)
    for index, value in enumerate(edges):
        if value:
            x, y = index % 1920, index // 1920
            coarse[(y // 3) * 640 + x // 3] = 255
    # 每个native edge映射的格子实际非零；合并不是计数丢失的算法修改。
    assert all(coarse[(i // 1920 // 3) * 640 + (i % 1920 // 3)] == 255 for i, v in enumerate(edges) if v)
    rgb = Image.frombytes('RGB', (1920, 1080), source).resize((640, 360), Image.Resampling.NEAREST)
    edge = Image.frombytes('L', (640, 360), bytes(coarse)).convert('RGB')
    overlay = bytearray(rgb.tobytes())
    for i, value in enumerate(coarse):
        if value:
            overlay[i * 3:i * 3 + 3] = b'\xff\x00\x00'
    bitmap = Image.new('RGB', (1920, 500), (15, 23, 42))
    draw = ImageDraw.Draw(bitmap)
    font = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc', 26)
    for i, (tile, label) in enumerate(zip((rgb, edge, Image.frombytes('RGB', (640, 360), bytes(overlay))),
                                         ('实际RAW插值的RGB源图', '实际同源Canny边缘', '同源观察叠加（软件）'))):
        draw.text((i * 640 + 24, 18), label, font=font, fill='white')
        bitmap.paste(tile, (i * 640, 72))
    draw.text((24, 446), '实际仿真1920×1080，边缘1,078。概览按3×3保留细边缘；精确结果见原尺寸图。', font=font, fill='white')
    panel = fresh(OUT / 'capture-canny-1080p-actual-panel-20261009-v2.png')
    bitmap.save(panel)
    provenance_path = OUT / 'capture-canny-1080p-overview-20261009-v2.provenance.json'
    write(provenance_path, dict(label='ACTUAL_SOFTWARE_SIMULATION_NOT_HARDWARE',
                               source_path=str(source_path), source_sha256=sha(source_path),
                               edge_path=str(edge_path), edge_sha256=sha(edge_path),
                               native_edge_pixels=1078, displayed_coarse_cells=coarse.count(255),
                               rule='any native edge255 in3x3 -> coarse255; coarse overlay red',
                               previous_native_provenance=str(pathlib.Path(old['provenance'])), previous_native_provenance_sha256=old['provenance_sha256'],
                               panel=str(panel), panel_sha256=sha(panel), size=[1920, 500], rtl_color_overlay_integrated=False))
    report = fresh(OUT / 'CONTINUATION_20261009_READBACK_CANNY-v2.md')
    body = pathlib.Path(old['delivery']).read_text(encoding='utf-8-sig')
    assert body.count(pathlib.Path(old['visualization']).as_posix()) == 1
    body = body.replace(pathlib.Path(old['visualization']).as_posix(), panel.as_posix())
    body += '\n人工观察概览修订：普通nearest缩小会遗漏单像素边缘，旧图/原尺寸图保持；新概览在每个3×3区域存在边缘时高亮。精确像素数1078来自native数据，概览格数不是原像素数。v5沿v4的4579条完整hash核验，另复核14新工作文件和10个Manifest摘要；本轮不虚构重新读取所有4579条。\n'
    report.write_text(body, encoding='utf-8')
    current = dict(old)
    current.update(at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                   previous_checkpoint_sha256=sha(old_path), delivery=str(report), delivery_sha256=sha(report),
                   visualization=str(panel), visualization_sha256=sha(panel), provenance=str(provenance_path), provenance_sha256=sha(provenance_path),
                   checkpoint_tool_sha256=sha(pathlib.Path(__file__)), visual_validation='MAXPOOL_DATA_CHECK_PASS_TOOL_VIEW_PENDING',
                   current_recheck=dict(new_work_files=14, registered_manifests=10, full_registered_files='inherited_from_v4'))
    checkpoint = OUT / 'fast-batch-checkpoint-20261009-v5.json'
    write(checkpoint, current)
    event = dict(event_id='EV-FAST-BATCH-20261008-023', at_utc=current['at_utc'], status=current['status'], classification='progress',
                 checkpoint=str(checkpoint), checkpoint_sha256=sha(checkpoint), native_edge_pixels=1078, displayed_coarse_cells=coarse.count(255),
                 image=str(panel), image_sha256=sha(panel), full_project_goal_complete=False, hardware_actions=False, formal_state_changed=False)
    journals = [ROOT / 'runtime/events/2026/10/session-FAST-BATCH-20261008.jsonl', ROOT / 'experiments/track4_algorithms_20261004/03_review/side-effects.jsonl']
    for path in journals:
        assert event['event_id'] not in path.read_text(encoding='utf-8-sig')
    for path in journals:
        with path.open('a', encoding='utf-8') as stream:
            stream.write(json.dumps(event, ensure_ascii=False) + '\n')
    print(json.dumps(event, ensure_ascii=False))

if __name__ == '__main__':
    main()
