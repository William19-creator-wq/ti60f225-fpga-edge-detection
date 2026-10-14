"""RJ-T1..5：坐标数值生成与公开事务账；不复制writer的bank/carry/packet结构。"""
import argparse
import collections
import hashlib
import heapq
import json
import pathlib
import random


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def rgb_pixels(width, height, kind):
    rng = random.Random(0x535700 + kind)
    for y in range(height):
        for x in range(width):
            if kind == 0:
                yield 0, 0, 0
            elif kind == 1:
                yield (0x11, 0x22, 0x33) if x % 2 == 0 else (0x44, 0x55, 0x66)
            elif kind == 2:
                yield 255, 255, 255
            elif kind == 3:
                yield (x * 13 + y * 5) % 256, (x * 7 + y * 19) % 256, (x + y * 31) % 256
            elif kind == 4:
                yield (255, 0, 0) if x < width // 3 else ((0, 255, 0) if x < 2 * width // 3 else (0, 0, 255))
            else:
                yield tuple(rng.randrange(256) for _ in range(3))


def algorithm_payload(index):
    if index % 8 == 0:
        return bytes(64)
    if index % 8 == 1:
        return bytes([255]) * 64
    if index % 8 == 2:
        return bytes([1]) + bytes(63)
    if index % 8 == 3:
        return bytes(63) + bytes([128])
    seed = 0x431060F225A5C39D
    return bytes(((i * 37 + index * 73 + 101) ^ (index >> (i % 5)) ^ (seed >> ((i % 8) * 8))) & 255 for i in range(64))


def generate(path, width, height, full, protocol):
    assert 4 <= width <= 1920 and width % 2 == 0 and 2 <= height <= 1080
    assert not full or (width, height) == (1920, 1080)
    frames = []
    for index, kind in enumerate([3] if full else range(6)):
        raw = bytes(value for pixel in rgb_pixels(width, height, kind) for value in pixel)
        padded = raw + bytes((-len(raw)) % 64)
        stem = f'frame_{index:02d}'
        (path / (stem + '.expected.rgb')).write_bytes(padded)
        with (path / (stem + '.input.hex')).open('w', encoding='ascii') as file:
            for offset in range(0, len(raw), 6):
                pair = raw[offset:offset + 6]
                file.write(pair[3:].hex() + pair[:3].hex() + '\n')
        frames.append(dict(stem=stem, kind=kind, width=width, height=height, pairs=width * height // 2,
                           logical_bytes=len(raw), physical_bytes=len(padded), expected_sha256=sha(path / (stem + '.expected.rgb')),
                           input_sha256=sha(path / (stem + '.input.hex'))))
    (path / 'frame-list.txt').write_text(str(len(frames)) + '\n' + '\n'.join(f['stem'] for f in frames) + '\n', encoding='ascii')
    with (path / 'algorithm.hex').open('w', encoding='ascii') as file:
        for index in range(4096):
            file.write(algorithm_payload(index)[::-1].hex() + '\n')
    manifest = dict(frames=frames, full1080p=full, protocol=protocol, algorithm_count=4096 if full else 16,
                    algorithm_hex_sha256=sha(path / 'algorithm.hex'))
    (path / 'reference-inputs.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    print(f'Generated {len(frames)} full numeric frames {width}x{height}; protocol={protocol}')


def hex_value(value):
    return None if any(c in value.lower() for c in 'xz') else int(value, 16)


def events(path, public):
    priority = {'CTRL': 0, 'J': 2 if public else 1, 'C': 3, 'P': 4, 'E': 5, 'L': 6,
                'A': 6, 'AW': 7, 'W': 8, 'B': 9, 'R': 10, 'D': 11, 'Q': 12}
    with path.open(encoding='ascii') as file:
        assert file.readline().strip() == 'case\tcycle\tevent\tvalues'
        for row in file:
            case, cycle, event, values = row.rstrip().split('\t')
            yield (int(cycle), priority[event], public, int(case), event, values.split())


def audit(path):
    inputs = json.loads((path / 'reference-inputs.json').read_text(encoding='utf-8'))
    results = [json.loads(row) for row in (path / 'case-results.jsonl').read_text(encoding='utf-8').splitlines()]
    frames = {frame['stem']: frame for frame in inputs['frames']}
    expected_cases = set(range(1, len(frames) + 1)) | (set(range(10, 36)) if inputs['protocol'] else set())
    assert {record['case'] for record in results} == expected_cases
    assert len(results) == len(expected_cases)
    by_case = {record['case']: record for record in results}
    for frame in frames.values():
        assert sha(path / (frame['stem'] + '.expected.rgb')) == frame['expected_sha256']
        assert sha(path / (frame['stem'] + '.input.hex')) == frame['input_sha256']
    assert sha(path / 'algorithm.hex') == inputs['algorithm_hex_sha256']
    width, height = inputs['frames'][0]['width'], inputs['frames'][0]['height']
    pairs, logical, allocation = width * height // 2, width * height * 3, inputs['frames'][0]['physical_bytes']
    expected_images = {name: (path / (name + '.expected.rgb')).read_bytes() for name in frames}
    counts = collections.Counter()
    cases = collections.defaultdict(collections.Counter)
    normal_kinds = {'normal', 'wrong_cancel_normal', 'late_disable_done', 'late_cancel_done'}
    state = None
    rst, enabled, q = True, True, False
    physical = None
    pending = None
    stream = bytearray()
    camera_memory = bytearray(allocation)
    algorithm_memory = bytearray(4096 * 64)
    source_public = None
    epoch = 0
    for cycle, _, public, case, event, values in heapq.merge(events(path / 'join-events.tsv', False), events(path / 'source-public.tsv', True)):
        counts['events'] += 1
        per = cases[case]
        if event == 'CTRL':
            new_rst, enabled, cancel = map(int, values[:3])
            if new_rst and not rst:
                if pending is not None:
                    counts['reset_retained_applications'] += 1
                    if pending['unknown']:
                        counts['reset_retained_unknown_applications'] += 1
                if physical is not None:
                    counts['reset_aborted_physical_writes'] += 1
            if new_rst and (not rst or state is None):
                epoch += 1
                state = dict(job=None, outer_job=None, cfg=None, child_jobs=0, pixels=0, good_pixels=0,
                             camera_requests=0, camera_replies=0, written=0, algorithm_requests=0, algorithm_replies=0,
                             camera_aw=0, done=False, epoch=epoch)
                physical = pending = source_public = None
                stream = bytearray()
                camera_memory = bytearray(allocation)
                algorithm_memory = bytearray(4096 * 64)
                q = False
                per['cold_resets'] += 1
            if not new_rst and not enabled and pending is not None and not pending['notice_consumed'] and pending['b'] is None:
                pending['disabled_live'] = True
            rst = bool(new_rst)
            continue
        assert not rst, (case, cycle, event, 'event during reset')
        if event == 'J' and not public:
            assert enabled and not q and state['job'] is None and state['cfg'] is None
            base, handle = map(hex_value, values)
            legal = base is not None and handle is not None and base % 64 == 0 and base + allocation <= 0x10000000
            state['outer_job'] = (base, handle, cycle)
            state['cfg'] = int(not legal)
            if legal:
                state['job'] = (base, handle)
            per['jobs'] += 1
            counts['jobs'] += 1
        elif event == 'J':
            base, handle = map(hex_value, values)
            assert state['cfg'] == 0 and state['outer_job'] == (base, handle, cycle), (case, 'one-sided job fire')
            state['child_jobs'] += 1
            per['child_jobs'] += 1
        elif event == 'C':
            assert int(values[0]) == state['cfg']
            if state['cfg'] == 0:
                assert state['child_jobs'] == 1
            else:
                assert state['child_jobs'] == 0
            state['cfg'] = None
            per['config_replies'] += 1
        elif event == 'P':
            assert state['job'] is not None and state['cfg'] is None and enabled and not q
            rgb, x, y, marker, bad, handle = values
            index = state['pixels']
            x, y, marker, bad, handle = int(x, 16), int(y, 16), int(marker, 16), int(bad), int(handle, 16)
            expected_x, expected_y = (index % (width // 2)) * 2, index // (width // 2)
            expected_marker = (int(index == pairs - 1) << 2) | (int(expected_x == width - 2) << 1) | int(index == 0)
            numeric = int(rgb, 16)
            actual_pair = ((numeric & 0xFFFFFF).to_bytes(3, 'big') + (numeric >> 24).to_bytes(3, 'big'))
            name = by_case[case]['stem']
            assert actual_pair == expected_images[name][index * 6:index * 6 + 6], (case, cycle, index, 'input numeric identity')
            tuple_good = not bad and handle == state['job'][1] and (x, y, marker) == (expected_x, expected_y, expected_marker)
            if tuple_good:
                stream.extend(actual_pair)
                state['good_pixels'] += 1
            else:
                per['bad_tuples'] += 1
            state['pixels'] += 1
            counts['pixels'] += 1
        elif event in ('E', 'L'):
            address, numeric = (int(v, 16) for v in values)
            data = numeric.to_bytes(64, 'little')
            assert state['job'] is not None
            base = state['job'][0]
            offset = address - base
            assert offset % 64 == 0 and 0 <= offset <= allocation - 64
            if len(stream) < logical:
                assert offset + 64 <= len(stream), (case, cycle, 'unaccepted RGB used by writer')
            expected = bytes(stream[offset:offset + 64]).ljust(64, b'\0')
            assert data == expected, (case, cycle, address, 'source PUBLIC bytes')
            if event == 'E':
                source_public = (address, data)
                per['public_exposures'] += 1
            else:
                assert not q and pending is None and physical is None
                assert source_public == (address, data)
                pending = dict(owner='camera', address=address, data=data, unknown=False, disabled_live=False,
                               b=None, notice_consumed=False, cycle=cycle)
                source_public = None
                state['camera_requests'] += 1
                counts['camera_requests'] += 1
        elif event == 'A':
            assert not q and enabled and pending is None and physical is None
            address, numeric = (int(v, 16) for v in values)
            index = (address - 0x02000000) // 64
            assert address % 64 == 0 and 0 <= index < 4096
            data = numeric.to_bytes(64, 'little')
            assert data == algorithm_payload(index)
            pending = dict(owner='algorithm', address=address, data=data, unknown=False, disabled_live=False,
                           b=None, notice_consumed=False, cycle=cycle)
            state['algorithm_requests'] += 1
            counts['algorithm_requests'] += 1
        elif event == 'AW':
            address, identity, length, size, burst = (int(v, 16) for v in values)
            assert physical is None and pending is not None
            assert address == pending['address'] and (identity, length, size, burst) == (0, 3, 4, 1)
            physical = dict(address=address, owner=pending['owner'], data=bytearray(), cycle=cycle)
            counts['aw'] += 1
            if q:
                counts['old_aw_in_q'] += 1
            if pending['owner'] == 'camera':
                state['camera_aw'] += 1
        elif event == 'W':
            assert physical is not None and pending is not None
            numeric, strobe = int(values[0], 16), int(values[1], 16)
            word = numeric.to_bytes(16, 'little')
            offset = len(physical['data'])
            assert offset < 64 and strobe == 0xFFFF and int(values[2]) == int(offset == 48)
            assert word == pending['data'][offset:offset + 16], (case, cycle, 'full AXI W value')
            physical['data'].extend(word)
            if physical['owner'] == 'camera':
                target = camera_memory
                destination = physical['address'] - state['job'][0] + offset
            else:
                target = algorithm_memory
                destination = physical['address'] - 0x02000000 + offset
            target[destination:destination + 16] = word
            counts['w'] += 1
            counts['physically_written_bytes'] += 16
            if q:
                counts['old_w_in_q'] += 1
        elif event == 'B':
            assert physical is not None and pending is not None and len(physical['data']) == 64
            identity, response = (int(v, 16) for v in values)
            assert bytes(physical['data']) == pending['data']
            counts['b'] += 1
            if identity != 0:
                pending['unknown'] = True
                counts['wrong_bids'] += 1
            else:
                pending['b'] = response
                physical = None
                counts['correct_bids'] += 1
                if q:
                    counts['old_correct_b_in_q'] += 1
        elif event == 'R':
            assert pending is not None
            owner = 'camera' if public else 'algorithm'
            assert pending['owner'] == owner and not pending['notice_consumed']
            error, drained = map(int, values)
            unsafe = pending['unknown'] or pending['disabled_live']
            if unsafe:
                assert (error, drained) == (1, 0)
                pending['unknown'] = True
                pending['notice_consumed'] = True
                counts['unknown_notices'] += 1
                per['unknown_notices'] += 1
            else:
                assert pending['b'] is not None and physical is None
                assert (error, drained) == (int(pending['b'] != 0), 1)
                if owner == 'camera' and not error:
                    state['written'] += 1
                pending = None
            state[owner + '_replies'] += 1
            counts[owner + '_replies'] += 1
            if q:
                counts['old_replies_in_q'] += 1
        elif event == 'D':
            handle, outcome, reason = (int(v, 16) for v in values[:3])
            accepted, written, logical_bytes, physical_bytes = map(int, values[3:])
            record = by_case[case]
            assert handle == state['job'][1]
            assert (outcome, reason) == (record['expected_outcome'], record['expected_reason'])
            assert accepted == state['pixels'] and written == state['written']
            assert logical_bytes == len(stream) and 0 <= physical_bytes <= allocation
            assert source_public is None and (pending is None or pending['owner'] == 'algorithm')
            if record['kind'] in normal_kinds or record['kind'] == 'safe_done_then_algorithm_q':
                assert (accepted, written, logical_bytes, physical_bytes) == (pairs, allocation // 64, logical, allocation)
                assert bytes(camera_memory) == expected_images[record['stem']], (case, 'complete physical RGB frame')
                per['full_frame_verified'] += 1
                counts['full_frame_verified'] += 1
                if record['kind'] in normal_kinds:
                    assert state['algorithm_requests'] == state['algorithm_replies'] == inputs['algorithm_count']
                    assert bytes(algorithm_memory[:inputs['algorithm_count'] * 64]) == b''.join(algorithm_payload(i) for i in range(inputs['algorithm_count']))
            state['done'] = True
            counts['done'] += 1
            per['done'] += 1
        elif event == 'Q':
            source_q, write_q, busy = map(int, values)
            q = bool(source_q or write_q)
            if q:
                per['q_observed'] += 1
                assert busy
            if case == 22 and q:
                assert source_public is not None and not source_q and not state['done']
                per['camera_public_retained_in_q'] += 1
        else:
            raise AssertionError((case, cycle, public, event, values))
    assert state is not None
    for case, record in by_case.items():
        per = cases[case]
        if record['kind'] == 'rejected_grant':
            assert per['jobs'] == per['config_replies'] == 1 and not per['child_jobs'] and not per['done']
        elif record['kind'] in {'camera_wrong_bid', 'live_backend_disable', 'algorithm_q_camera_public'}:
            assert per['q_observed'] and per['unknown_notices'] == 1 and not per['done']
        else:
            assert per['done'] == 1
    assert not inputs['protocol'] or cases[22]['camera_public_retained_in_q'] > 0
    metrics = json.loads((path / 'join-result.json').read_text(encoding='utf-8'))
    assert metrics['finished'] and metrics['cases'] == len(expected_cases)
    for key, metric in [('pixels', 'camera_inputs'), ('algorithm_requests', 'algorithm_requests'), ('algorithm_replies', 'algorithm_replies'), ('aw', 'aw'), ('w', 'w'), ('b', 'b')]:
        assert counts[key] == metrics[metric], (key, counts[key], metrics[metric])
    for metric in ['aw_stalls', 'w_stalls', 'input_stalls', 'cfg_stalls', 'done_stalls', 'algorithm_reply_stalls']:
        assert metrics[metric] > 0, metric
    for frame in frames.values():
        actual = path / (frame['stem'] + '.actual.rgb')
        assert actual.read_bytes() == expected_images[frame['stem']]
        assert (path / (frame['stem'] + '.actual.algorithm')).read_bytes() == b''.join(algorithm_payload(i) for i in range(inputs['algorithm_count']))
    result = dict(status='PASS', cases=len(expected_cases), counts=dict(counts), cases_checked={str(k): dict(v) for k, v in sorted(cases.items())},
                  full1080p=inputs['full1080p'], geometry=[width, height], protocol=metrics,
                  public_source_ports_observed=True, private_state_used_as_expectation=False,
                  actual_four_rtl_integration_verified=True, actual_native_ram_verified=True,
                  actual_ddr_verified=False, frame_reference_authority_verified=False,
                  production_pnr_sta_bit_verified=False, full_project_goal_complete=False,
                  events_sha256=sha(path / 'join-events.tsv'), source_events_sha256=sha(path / 'source-public.tsv'))
    (path / 'join-audit.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps({k: result[k] for k in ['status', 'cases', 'counts', 'geometry', 'full1080p']}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['generate', 'audit'])
    parser.add_argument('directory', type=pathlib.Path)
    parser.add_argument('--width', type=int, default=34)
    parser.add_argument('--height', type=int, default=19)
    parser.add_argument('--full', action='store_true')
    parser.add_argument('--protocol', action='store_true')
    arguments = parser.parse_args()
    if arguments.action == 'generate':
        generate(arguments.directory, arguments.width, arguments.height, arguments.full, arguments.protocol)
    else:
        audit(arguments.directory)
