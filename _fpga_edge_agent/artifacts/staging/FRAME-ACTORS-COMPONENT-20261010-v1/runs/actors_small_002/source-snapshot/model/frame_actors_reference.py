"""FA-T1..4：独立 CFA/R2/BFS 期望，以及两个实际执行模块的公共总线审计。"""
import argparse
import collections
import importlib.util
import json
import pathlib
import struct

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('frozen_capture_math', HERE/'legacy_capture_reference.py')
legacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(legacy)


def generate(root, width, height, full):
    legacy.generate_capture(root, width, height, full, 1)
    metadata = json.loads((root/'vector-summary.json').read_text(encoding='utf-8'))
    for item in metadata['cases']:
        body = (root/f'case-{item["id"]}.source.bin').read_bytes()
        (root/f'case-{item["id"]}.display.hex').write_text(
            ''.join(body[i:i+16][::-1].hex()+'\n' for i in range(0, len(body), 16)), encoding='ascii')
    old = metadata['cases'][-1]
    pixels = width*height
    source = (root/f'case-{old["id"]}.source.bin').read_bytes()
    rgb = tuple(tuple(source[i:i+3]) for i in range(0, 3*pixels, 3))
    scope = (old['cj'] & ((1 << 64)-1)) | ((((old['cj'] >> 64) & 0xffffffff)+1) << 64)
    cj = scope | (width << 96) | (height << 107) | (16 << 118) | (80 << 129) | (1 << 140) | (1 << 141)
    math = legacy.canny_ref.r2.stream_image(rgb, width, height, True, True, 16, 80)
    edges, order = legacy.canny_ref.bfs.breadth_first(math['class'], width, height)
    fps, gradients = [], []
    for y in range(height):
        for x in range(0, width, 2):
            index = y*width+x
            pair = gradient = 0
            for lane in range(2):
                r, g, b = rgb[index+lane]
                pair |= (b | (g << 8) | (r << 16)) << (24*lane)
                gradient |= ((math['gx'][index+lane] & 2047) | ((math['gy'][index+lane] & 2047) << 11) | (math['dir'][index+lane] << 22)) << (32*lane)
            markers = int(index == 0) | (int(x == width-2) << 1) | (int(index == pixels-2) << 2)
            fps.append(pair | (x << 48) | (y << 59) | (markers << 70))
            gradients.append(gradient | (x << 64) | (y << 75) | (scope << 86) | (markers << 182))
    result = bytes(sum(int(edges[j]) << (j-i) for j in range(i, min(i+8, pixels))) for i in range(0, pixels, 8))
    result += bytes((-len(result)) % 64)
    after = [3 if edge else old_class for old_class, edge in zip(math['class'], edges)]
    fs = (scope << 3) | ((pixels//2) << 99) | ((pixels//2) << 120)
    status = cj | (7 << 179) | (30 << 183) | (255 << 379) | (sum(v == 2 for v in math['class']) << 387) | (sum(v == 1 for v in math['class']) << 408) | (fs << 429)
    for port in range(8):
        status |= (pixels//2) << (211+port*21)
    replay = dict(old, cj=cj, retain=True, edges=sum(edges), status=status, source_case=old['id'])
    (root/'replay.fp').write_text(''.join(f'{v:019x}\n' for v in fps), encoding='ascii')
    (root/'replay.grad').write_text(''.join(f'{v:047x}\n' for v in gradients), encoding='ascii')
    (root/'replay.class.bin').write_bytes(legacy.canny_ref.bfs.packed_states(math['class'], pixels))
    (root/'replay.state.bin').write_bytes(legacy.canny_ref.bfs.packed_states(after, pixels))
    (root/'replay.queue.bin').write_bytes(struct.pack(f'<{len(order)}I', *order))
    (root/'replay.result.bin').write_bytes(result)
    (root/'replay.txt').write_text(f'{cj:036x} {old["origin"]:049x} {old["handle"]:016x} {old["phase"]} {sum(edges)} 1\n', encoding='ascii')
    metadata['replay'] = replay
    if full:
        # 下一帧使用独立身份、Bayer和二维RAW图案，只生成采集所需的CFA期望。
        phase = 1
        raw = [(x*29+y*53+211*legacy.raw_ref.cfa.PATTERNS[phase][y % 2][x % 2]) % 1024
               for y in range(height) for x in range(width)]
        packed = [raw[i] | (raw[i+1] << 10) for i in range(0, pixels, 2)]
        body = bytearray()
        for y in range(height):
            for x in range(width):
                rgb_value = legacy.raw_ref.cfa.color(legacy.raw_ref.windows(raw, width, height, x, y), x, y, phase)
                body.extend(((rgb_value >> 16) & 255, (rgb_value >> 8) & 255, rgb_value & 255))
        body.extend(bytes((-len(body)) % 64))
        old_cj = metadata['cases'][0]['cj']
        b_scope = (old_cj & 0xffffffff) | ((((old_cj >> 32) & 0xffffffff)+1) << 32) | (old_cj & (((1 << 32)-1) << 64))
        b_cj = (old_cj & ~((1 << 96)-1)) | b_scope
        b_handle = metadata['cases'][0]['handle']+1
        b_origin = (metadata['cases'][0]['origin'] & ~((1 << 131)-1)) | 1 | ((b_handle & ((1 << 64)-1)) << 3) | ((b_scope & ((1 << 64)-1)) << 67)
        (root/'capture-b.raw').write_text(''.join(f'{v:05x}\n' for v in packed), encoding='ascii')
        (root/'capture-b.source.bin').write_bytes(body)
        (root/'capture-b.txt').write_text(f'{b_cj:036x} {b_origin:049x} {b_handle:016x} {phase} 0 0\n', encoding='ascii')
        metadata['capture_b'] = dict(cj=b_cj, origin=b_origin, handle=b_handle, phase=phase)
    layout = legacy.layout(width, height, 1)
    layout['capture_b'] = layout.pop('display')
    layout['capture_b_bytes'] = layout.pop('display_bytes')
    (root/'layout.json').write_text(json.dumps(layout, indent=2), encoding='utf-8')
    (root/'vector-summary.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')


def audit(root):
    metadata = json.loads((root/'vector-summary.json').read_text(encoding='utf-8'))
    layout = json.loads((root/'layout.json').read_text(encoding='utf-8'))
    metrics = json.loads((root/'protocol-metrics.json').read_text(encoding='utf-8'))
    width, height = metadata['width'], metadata['height']
    pixels = width*height
    expected = {row['id']: row for row in metadata['cases']}
    expected[100] = metadata['replay']
    memory = None
    write = read = None
    counts = collections.Counter()
    capture = algorithm = None
    last_cycle = 0
    class_first = {}
    current_case = None
    for line in (root/'axi-events.tsv').read_text(encoding='ascii').splitlines()[1:]:
        fields = line.split('\t')
        assert len(fields) == 4
        case, cycle, event, values = int(fields[0]), int(fields[1]), fields[2], fields[3].split()
        assert cycle >= last_cycle
        last_cycle = cycle
        if event == 'RESET':
            memory = bytearray(((i*37) ^ (i >> 3)) & 255 for i in range(layout['memory_bytes']))
            write = read = capture = algorithm = None
            counts['cold_resets'] += 1
            continue
        assert memory is not None
        if event == 'CAP_START':
            assert capture is None
            capture = tuple(int(v, 16) for v in values)
            assert capture[0] in (0, layout['capture_b'])
            if algorithm:
                assert capture[0] != 0, 'Capture rewrites immutable algorithm Source'
                other = metadata['capture_b'] if metadata['full1080p'] else metadata['cases'][(case+1) % len(metadata['cases'])]
                assert capture == (layout['capture_b'], other['handle'], other['cj'] & ((1 << 96)-1))
                assert capture[1] != algorithm[2] and capture[2] & ((1 << 64)-1) != algorithm[0] & ((1 << 64)-1)
                counts['capture_started_while_algorithm_active'] += 1
            counts['capture_jobs'] += 1
        elif event == 'CAP_DONE':
            assert capture is not None
            handle, scope, outcome, reason, raw, rgb, lines, discarded, logical, physical = (int(v, 16) for v in values)
            assert (handle, scope) == capture[1:]
            if not outcome:
                assert reason == discarded == 0 and raw == rgb == pixels//2
                assert physical == layout['source_bytes'] and logical == 3*pixels and lines == physical//64
            capture = None
            counts['capture_done'] += 1
        elif event == 'ALG_START':
            assert algorithm is None
            cj, origin, handle = (int(v, 16) for v in values)
            algorithm = (cj, origin, handle)
            class_first[case] = {}
            current_case = case
            if case in expected:
                e = expected[case]
                assert algorithm == (e['cj'], e['origin'], e['handle'])
                source_case = e.get('source_case', e['id'])
                assert memory[:layout['source_bytes']] == (root/f'case-{source_case}.source.bin').read_bytes()
            counts['algorithm_jobs'] += 1
        elif event == 'ALG_DONE':
            scope, origin, outcome, reason, reader, inputs, classes, outputs, edges, discard = (int(v, 16) for v in values)
            assert algorithm is not None and (scope, origin) == (algorithm[0] & ((1 << 96)-1), algorithm[1])
            if case in expected:
                e = expected[case]
                assert outcome == reason == discard == 0 and reader == inputs == classes == pixels//2
                assert outputs == pixels and edges == e['edges']
            algorithm = None
            counts['algorithm_done'] += 1
        elif event == 'AW':
            assert write is None
            address, ident, length, size, burst = (int(v, 16) for v in values)
            assert ident == 0 and length == 3 and size == 4 and burst == 1 and address % 64 == 0
            assert address+64 <= len(memory)
            if algorithm and case in expected:
                assert address >= layout['classes'], 'Algorithm rewrites immutable Source'
            write = [address, 0, bytearray()]
            counts['aw'] += 1
        elif event == 'W':
            assert write is not None
            data, strobe, last = (int(v, 16) for v in values)
            assert strobe == 65535 and bool(last) == (write[1] == 3)
            body = data.to_bytes(16, 'little')
            address = write[0]+write[1]*16
            memory[address:address+16] = body
            write[2].extend(body)
            write[1] += 1
            counts['w'] += 1
        elif event == 'B':
            ident, response = (int(v, 16) for v in values)
            assert write is not None and write[1] == 4 and ident == 0
            if current_case in class_first and layout['classes'] <= write[0] < layout['classes']+layout['class_bytes']:
                class_first[current_case].setdefault(write[0]-layout['classes'], bytes(write[2]))
            write = None
            counts['b'] += 1
            counts['b_error'] += int(response != 0)
        elif event == 'AR':
            assert read is None
            address, ident, length, size, burst = (int(v, 16) for v in values)
            assert ident in (0, 2) and size == 4 and burst == 1 and address % 16 == 0
            assert length <= 63 and address % 4096+(length+1)*16 <= 4096 and address+(length+1)*16 <= len(memory)
            if ident == 0:
                assert length == 3 and address % 64 == 0
            read = [address, ident, length+1, 0]
            counts['algorithm_ar' if ident == 0 else 'display_ar'] += 1
        elif event == 'R':
            ident, response, last, data = (int(v, 16) for v in values)
            assert read is not None
            if case in expected:
                assert ident == read[1] and response == 0 and bool(last) == (read[3] == read[2]-1)
                address = read[0]+read[3]*16
                assert data.to_bytes(16, 'little') == memory[address:address+16]
            read[3] += 1
            if last and ident == read[1]:
                read = None
            counts['r'] += 1
        elif event == 'RAW_DURING_ALGORITHM':
            counts['raw_during_algorithm'] += int(values[0])
        elif event == 'PHYSICAL_OVERLAP':
            counts['physical_overlap_events'] += 1
        elif event == 'Q':
            counts['quarantines'] += 1
        else:
            assert event == 'NOTE', event
    # 文件只能作为actual；期望是冻结的二维数学参考重新生成的独立结果。
    compared_pixels = 0
    for case, e in expected.items():
        stem = 'replay' if case == 100 else f'case-{case}'
        actual = f'actual-{case}'
        for suffix in ('fp', 'grad', 'state.bin', 'queue.bin', 'result.bin'):
            assert (root/f'{actual}.{suffix}').read_bytes() == (root/f'{stem}.{suffix}').read_bytes(), (case, suffix)
        assert int((root/f'{actual}.status').read_text(encoding='ascii'), 16) == e['status']
        source_case = e.get('source_case', e['id'])
        assert (root/f'{actual}.source.bin').read_bytes() == (root/f'case-{source_case}.source.bin').read_bytes()
        if case != 100:
            next_case = (case+1) % len(metadata['cases'])
            b_source = root/'capture-b.source.bin' if metadata['full1080p'] else root/f'case-{next_case}.source.bin'
            assert (root/f'{actual}.source-b.bin').read_bytes() == b_source.read_bytes()
            assert (root/f'{actual}.display.bin').read_bytes() == (root/f'case-{case}.source.bin').read_bytes()
        actual_classes = b''.join(class_first[case][offset] for offset in range(0, layout['class_bytes'], 64))
        assert actual_classes == (root/f'{stem}.class.bin').read_bytes(), (case, 'first real class writes')
        compared_pixels += pixels
    assert metrics['finished'] and metrics['replay_jobs'] == 1
    assert counts['raw_during_algorithm'] > 0 and counts['physical_overlap_events'] > 0
    assert counts['capture_started_while_algorithm_active'] == len(metadata['cases'])
    for name in ('aw', 'w', 'b', 'algorithm_ar', 'display_ar', 'r', 'capture_jobs', 'algorithm_jobs', 'capture_done', 'algorithm_done'):
        assert counts[name] == metrics[name], (name, counts[name], metrics[name])
    result = dict(status='PASS', pixels_compared=compared_pixels, algorithm_images=len(expected), concurrent_capture_images=len(metadata['cases']),
                  shared_source_replay=True, public_bus_counts=dict(counts), actual_ddr_phy_verified=False,
                  autonomous_frame_publisher_verified=False, full_project_goal_complete=False)
    (root/'reference-audit.json').write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=('generate', 'audit'))
    parser.add_argument('root', type=pathlib.Path)
    parser.add_argument('--width', type=int, default=34)
    parser.add_argument('--height', type=int, default=19)
    parser.add_argument('--full', action='store_true')
    args = parser.parse_args()
    if args.command == 'generate':
        generate(args.root, args.width, args.height, args.full)
    else:
        audit(args.root)
