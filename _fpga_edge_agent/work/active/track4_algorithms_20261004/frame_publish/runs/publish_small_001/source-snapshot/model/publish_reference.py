"""FP01..08：集合账本与公开因果关系；不复制RTL控制状态机。

producer/row0/closed是明确端点fixture，1920×1080参数只检查身份及计数范围。
"""
import collections
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'deps'))
import frame_read_authority_reference as authority

owner = authority.legacy
CONTROL = [('kind', 3), ('sequence', 64), ('cause', 64), ('policy', 64), ('bundle', 942)]
RESPONSE = [('kind', 3), ('status', 3), ('sequence', 64), ('cause', 64), ('policy', 64),
            ('bundle', 942), ('previous', 64), ('active', 1), ('held', 1), ('closed', 1)]


def decode(value, fields):
    return owner.decode(int(value, 16) if isinstance(value, str) else value, fields)


def ref(sequence, bundle):
    return (((sequence << 64 | bundle['result']) << 64 | bundle['policy']) << 195) | bundle['origin']


def same_identity(a, b):
    return all(a[k] == b[k] for k in ('source', 'result', 'origin', 'cj', 'body', 'policy', 'ss', 'rs'))


def audit(root):
    root = Path(root)
    metrics = json.loads((root / 'publish-metrics.json').read_text(encoding='utf-8'))
    assert metrics['finished'] and metrics['endpoint_fixture_only']
    w, h = metrics['width'], metrics['height']
    counters = collections.Counter()
    cases = set()
    ledger = None
    pending = current = None
    frames = {}
    active = None
    released = set()
    candidate_closed = set()
    last_allocated_sequence = 0
    for line in (root / 'publish-events.jsonl').open(encoding='utf-8'):
        e = json.loads(line)
        event = e['event']
        counters[event] += 1
        if event == 'reset':
            if current is not None:
                assert current.get('unknown') or current.get('halted'), ('unexplained unfinished request', current)
                counters['requests_abandoned_at_common_cold'] += 1
            assert pending is None, 'No owner command may disappear without an explicit audited cold case'
            assert (e['width'], e['height']) == (w, h)
            ledger = authority.Authority(w, h, 1)
            frames = {}
            active = None
            current = None
            released = set()
            candidate_closed = set()
            last_allocated_sequence = 0
        elif event == 'request':
            assert ledger is not None and current is None
            current = {k: int(e[k], 16) for k in ('token', 'source', 'origin', 'cj', 'render')}
            current.update(mode=current['render'] >> 109, cancel=False, job=None, done=None,
                           halted=False, unknown=False, actor_cancelled=False, route_cancelled=False)
        elif event == 'cancel':
            if current is not None and int(e['token'], 16) == current['token']:
                current['cancel'] = True
        elif event == 'halt':
            assert current is not None
            current['halted'] = True
        elif event == 'command':
            assert ledger is not None and pending is None
            command = decode(e['command'], owner.CMD)
            sequence = int(e['sequence'], 16)
            op = command['op']
            before = ledger.ledger
            if op in (3, 4, 5, 6, 7):
                assert current is not None
            if op == 3:
                assert command['flags'] == 0
                assert command['source'] == current['source'] and command['origin'] == current['origin']
                assert command['cj'] == current['cj'] and command['body'] == current['render']
            if op == 4:
                assert command['result'] == current['bundle']['result']
                flags = command['flags']
                done = current['done']
                good = done is not None and done['outcome'] == 0 and done['pixels'] == w*h and done['discard'] == 0
                if flags == 7:
                    assert (current['mode'] in (1, 2) and current['job'] is None) or good
                elif flags == 6:
                    assert ((current['job'] is None and current['cancel']) or
                            (done is not None and done['outcome'] != 3 and
                             (done['outcome'] in (1, 2) or not good or current['cancel'])))
                else:
                    assert flags == 0
                    current['unknown'] = True
                current['end_flags'] = flags
            if op == 5:
                assert current.get('end_ok') and current['end_flags'] == 7
                assert sequence == current['sequence'] and sequence != 0
            if op == 6:
                response = current.get('route_reply')
                assert response and response['status'] == 0 and response['active'] and not response['closed']
                assert command['result'] == decode(response['bundle'], owner.REP)['result']
            if op == 7 and command['flags'] & 8:
                response = current.get('route_reply')
                assert response and response['status'] == 4 and response['closed']
                assert (response['sequence'], command['result']) in candidate_closed
            retire_ref = None
            if op == 8:
                matches = [r for r, item in frames.items() if item['bundle']['result'] == command['result']]
                assert len(matches) == 1
                retire_ref = matches[0]
                assert retire_ref != active and frames[retire_ref]['closed']
                assert command['flags'] == 10
                _, obj = before.active_result(command['result'])
                assert obj and obj['state'] == 5
            expected = ledger.event(command, sequence)
            pending = (command, expected, retire_ref)
        elif event == 'reply':
            assert pending is not None
            command, expected, retire_ref = pending
            actual = decode(e['reply'], owner.REP)
            assert actual == expected, (command, actual, expected)
            public = [int(e[k], 16) for k in ('ss', 'rs', 'latest', 'freeze', 'policy')]
            public += [e[k] for k in ('frozen', 'q', 'se', 're')]
            assert public == ledger.public_state(), ('public owner state', public, ledger.public_state())
            op = command['op']
            if op == 3:
                current['allocation'] = actual
                if actual['status'] == 0:
                    current['bundle'] = actual
                    assert actual['cj'] >> 64 == current['cj'] >> 64
                    assert actual['body'] & ((1 << 112)-1) == current['render']
            elif op == 4:
                current['end_ok'] = actual['status'] == 0
                current['end_reply'] = actual
            elif op == 5:
                current['offer_reply'] = actual
            elif op == 6:
                current['apply_reply'] = actual
            elif op == 7:
                current['drop_reply'] = actual
            elif op == 8:
                assert actual['status'] == 0
                released.add(retire_ref)
            pending = None
        elif event == 'job':
            assert current is not None and current['job'] is None
            bundle = decode(e['bundle'], owner.REP)
            assert bundle == current['bundle'] and bundle['op'] == 3 and bundle['status'] == 0
            assert current['mode'] not in (1, 2)
            _, item = ledger.ledger.active_result(bundle['result'])
            assert item and item['state'] == 1
            current['job'] = bundle
        elif event == 'producer_done':
            assert current is not None and current['job'] is not None
            bundle = current['bundle']
            match = (int(e['result'], 16), int(e['origin'], 16), int(e['scope'], 16)) == (
                bundle['result'], bundle['origin'], bundle['cj'] & ((1 << 96)-1))
            if match:
                assert current['done'] is None
                current['done'] = e
            else:
                counters['wrong_done_consumed_ignored'] += 1
        elif event == 'producer_cancel':
            assert current is not None and current['job'] is not None and not current['actor_cancelled']
            assert current['cancel'] or current['halted']
            assert (int(e['result'], 16), int(e['scope'], 16)) == (
                current['bundle']['result'], current['bundle']['cj'] & ((1 << 96)-1))
            current['actor_cancelled'] = True
        elif event == 'sequence':
            assert current is not None and current.get('end_ok')
            value = int(e['value'], 16)
            if value:
                assert value > last_allocated_sequence
                last_allocated_sequence = value
            current['sequence'] = value
        elif event == 'route':
            assert current is not None
            route = decode(e['request'], CONTROL)
            assert route['kind'] == 0 and route['cause'] == 0 and route['sequence'] == current['sequence']
            assert decode(route['bundle'], owner.REP) == current['offer_reply']
            assert current['offer_reply']['status'] == 0
            current['route'] = route
        elif event == 'route_cancel':
            assert current is not None and current.get('route') and not current['route_cancelled']
            assert current['cancel'] and int(e['sequence'], 16) == current['sequence']
            current['route_cancelled'] = True
        elif event == 'candidate_closed_fixture':
            candidate_closed.add((int(e['sequence'], 16), int(e['result'], 16)))
        elif event == 'route_reply':
            assert current is not None and current.get('route')
            response = decode(e['reply'], RESPONSE)
            route = current['route']
            assert all(response[k] == route[k] for k in ('kind', 'sequence', 'cause', 'policy', 'bundle'))
            assert response['status'] in (0, 4)
            if response['status'] == 4:
                assert response['closed']
                assert (response['sequence'], decode(response['bundle'], owner.REP)['result']) in candidate_closed
            current['route_reply'] = response
        elif event == 'applied':
            assert current is not None
            bundle = decode(e['bundle'], owner.REP)
            assert bundle == current['apply_reply'] and bundle['op'] == 6 and bundle['status'] == 0
            sequence = int(e['sequence'], 16)
            assert sequence == current['sequence']
            previous = int(e['previous'], 16)
            assert previous == (frames[active]['bundle']['result'] if active is not None else 0)
            active = ref(sequence, bundle)
            assert active not in frames
            frames[active] = dict(bundle=bundle, closed=False)
            current['applied'] = active
        elif event == 'oldclosed':
            value = int(e['ref'], 16)
            if value in frames:
                frames[value]['closed'] = True
            else:
                counters['wrong_closed_consumed_ignored'] += 1
        elif event == 'retired':
            value = int(e['ref'], 16)
            assert value in released and value in frames and value != active
            released.remove(value)
            del frames[value]
        elif event == 'complete':
            assert current is not None and int(e['token'], 16) == current['token'] and not current['unknown']
            bundle = decode(e['bundle'], owner.REP)
            if e['outcome'] == 0:
                assert e['status'] == 0 and current.get('applied') == ref(current['sequence'], bundle)
                assert bundle == current['apply_reply']
            elif current['allocation']['status'] != 0:
                assert e['outcome'] == 1 and e['status'] == current['allocation']['status']
                assert bundle == current['allocation'] and current['job'] is None
            else:
                expected = current.get('drop_reply') or current.get('end_reply')
                assert expected and expected['status'] == 0 and bundle == expected
                if e['outcome'] == 2:
                    assert current['cancel'] or (current['done'] and current['done']['outcome'] == 2)
                elif current['done'] is not None:
                    assert current['done']['outcome'] == 1 or current['done']['pixels'] != w*h or current['done']['discard'] != 0
                    if current['done']['outcome'] == 0:
                        assert int(e['reason'], 16) & (1 << 32)
            current = None
        elif event == 'case':
            assert e['name'] not in cases
            cases.add(e['name'])
        else:
            raise AssertionError(event)
    assert current is None and pending is None and not released
    required = {'no_source', 'wrong_oldclosed', 'early_oldclosed', 'full_pool_no_job', 'late_close_slot_reuse',
                'retired_event_and_applied_holding', 'cancel_before_job', 'cancel_held_job', 'cancel_wait_done',
                'cancel_held_route_requires_close', 'wrong_result_scope_origin_done', 'safe_producer_error',
                'bad_normal_count', 'sequence_exhausted_no_wrap', 'sequence_zero_safe_drop',
                'unknown_requires_common_cold', 'halt_held_job', 'late_halt_held_safe_completion',
                'owner_held_result_source_competition', 'policy_window_reply_holding'} | {'mode_'+str(i) for i in range(6)}
    assert cases == required and metrics['cases'] == len(cases)
    for key, event in [('requests', 'request'), ('jobs', 'job'), ('producer_done', 'producer_done'),
                       ('completions', 'complete'), ('retired', 'retired'), ('applied', 'applied'),
                       ('actor_cancels', 'producer_cancel'), ('route_cancels', 'route_cancel'),
                       ('owner_commands', 'command'), ('owner_replies', 'reply')]:
        assert metrics[key] == counters[event]
    assert counters['wrong_done_consumed_ignored'] == 3
    assert counters['wrong_closed_consumed_ignored'] >= 1
    assert counters['requests_abandoned_at_common_cold'] == 2
    return dict(status='PASS', cases=len(cases), counters=dict(counters), metrics=metrics,
                actual_owner_handoff_protocol_verified=True, producer_row0_and_closed_endpoint_fixture_only=True,
                actual_pixel_algorithm_execution_verified=False, production_freeze_controller_verified=False,
                actual_ddr_verified=False, full_project_goal_complete=False,
                event_sha256=hashlib.sha256((root/'publish-events.jsonl').read_bytes()).hexdigest().upper())


if __name__ == '__main__':
    root = Path(sys.argv[1])
    result = audit(root)
    (root / 'reference-result.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=True))
