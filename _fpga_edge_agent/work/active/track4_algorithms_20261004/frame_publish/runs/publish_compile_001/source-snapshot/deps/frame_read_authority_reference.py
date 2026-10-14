"""RA01..08：对象/租约集合 + 完整FrameRef数学查询，公开事件逐项对照。"""
import argparse
import collections
import copy
import importlib.util
import json
from pathlib import Path

TASK = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('frozen_owner_reference', TASK / 'deps/frame_owner_reference.py')
legacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(legacy)


def describe64(base, length):
    return (base << 64) | (length << 32) | ((length + 63) // 64 * 64)


# 当前范围明确A64；原对象参考文件保持冻结，用数学描述函数配置其表示。
legacy.desc = describe64
DEMAND = [('sequence', 64), ('scan', 64), ('result', 64), ('policy', 64),
          ('origin', 195), ('target_y', 11), ('source_y', 11), ('mode', 3), ('mask', 3)]


class Authority:
    def __init__(self, width, height, initial=1, last_sequence=0):
        self.ledger = legacy.Ledger(width, height, initial)
        self.last_sequence = last_sequence

    def event(self, command, sequence):
        before = copy.deepcopy(self.ledger)
        answer = self.ledger.event(command)
        # 保留全部原检查优先级；只在原OFFER本会成功时增加绑定检查。
        if command['op'] == 5 and answer['status'] == 0:
            if sequence == 0 or sequence <= self.last_sequence:
                self.ledger = before
                answer = {name: 0 for name, _ in legacy.REP}
                answer.update(op=5, status=4, policy=before.policy, ss=7, rs=3)
            else:
                self.ledger.result[answer['rs']]['offer_sequence'] = sequence
                self.last_sequence = sequence
        for result in self.ledger.result.values():
            if result['state'] == 0:
                result.pop('offer_sequence', None)
        return answer

    def public_state(self):
        ledger = self.ledger
        source_states, result_states = ledger.states()
        return [source_states, result_states, ledger.latest, ledger.freeze, ledger.policy,
                int(ledger.frozen), int(ledger.q), int(ledger.se), int(ledger.re)]

    def query(self, demand):
        ledger = self.ledger
        if ledger.q or demand['sequence'] == 0 or demand['scan'] == 0 or demand['target_y'] >= ledger.h:
            return 0, {name: 0 for name, _ in legacy.REP}
        _, result = ledger.active_result(demand['result'])
        if result is None or result['state'] not in (3, 4, 5):
            return 0, {name: 0 for name, _ in legacy.REP}
        _, source = ledger.active_source(result['source'])
        if (source is None or source['state'] != 3 or source['origin'] != demand['origin'] or
                result['policy'] != demand['policy'] or result.get('offer_sequence', 0) != demand['sequence']):
            return 0, {name: 0 for name, _ in legacy.REP}
        mode = result['body'] >> 109 & 7
        y = demand['target_y']
        source_y = 2 * (y % (ledger.h // 2)) if mode == 0 else y
        mask = (1 if y < ledger.h // 2 else 2) if mode == 0 else {1: 1, 2: 1, 3: 2, 4: 3, 5: 7}[mode]
        if (demand['source_y'], demand['mode'], demand['mask']) != (source_y, mode, mask):
            return 0, {name: 0 for name, _ in legacy.REP}
        answer = {name: 0 for name, _ in legacy.REP}
        answer.update(op=5, status=0, source=source['key'], result=result['key'], origin=source['origin'],
                      cj=result['cj'], body=result['body'], policy=result['policy'], ss=source['ss'], rs=result['rs'])
        return 1, answer


def observed_state(fields):
    return [int(value, 16) for value in fields[:5]] + [int(value) for value in fields[5:]]


def audit_compat(root):
    metrics = json.loads((root / 'compat-metrics.json').read_text(encoding='utf-8'))
    authority = None
    events = resets = 0
    status_counts, operations = collections.Counter(), collections.Counter()
    for line in (root / 'compat-events.csv').read_text(encoding='ascii').splitlines():
        fields = line.split(',')
        if fields[0] == 'RESET':
            authority = Authority(int(fields[1]), int(fields[2]), int(fields[3], 16))
            resets += 1
            continue
        assert fields[0] == 'EVENT' and len(fields) == 13 and authority is not None
        command = legacy.decode(int(fields[1], 16), legacy.CMD)
        actual = legacy.decode(int(fields[3], 16), legacy.REP)
        expected = authority.event(command, int(fields[2], 16))
        assert actual == expected, (events, command, actual, expected)
        assert observed_state(fields[4:13]) == authority.public_state(), (events, 'compat public state')
        status_counts[actual['status']] += 1
        operations[command['op']] += 1
        events += 1
    assert metrics['finished'] and metrics['transactions'] == events and metrics['resets'] == resets
    return dict(status='PASS', events=events, resets=resets, metrics=metrics,
                status_counts=dict(status_counts), operation_counts=dict(operations))


def audit_queries(root):
    metrics = json.loads((root / 'authority-metrics.json').read_text(encoding='utf-8'))
    authority = None
    pending = held_query = None
    counts = collections.Counter()
    allowed_modes, denied_fields = collections.Counter(), collections.Counter()
    for line in (root / 'authority-events.csv').read_text(encoding='ascii').splitlines():
        fields = line.split(',')
        event = fields[0]
        if event == 'RESET':
            if pending is not None:
                counts['commands_discarded_at_explicit_cold'] += 1
            authority = Authority(int(fields[1]), int(fields[2]), int(fields[3], 16), int(fields[4], 16))
            pending = held_query = None
            counts['resets'] += 1
            continue
        assert authority is not None
        if event == 'COMMAND':
            assert pending is None
            command, sequence = int(fields[2], 16), int(fields[3], 16)
            expected = authority.event(legacy.decode(command, legacy.CMD), sequence)
            pending = (command, sequence, expected)
            counts['command_inputs'] += 1
        elif event == 'EVENT':
            assert len(fields) == 13 and pending is not None
            assert (int(fields[1], 16), int(fields[2], 16)) == pending[:2]
            assert legacy.decode(int(fields[3], 16), legacy.REP) == pending[2], ('query suite command reply', counts['commands'])
            assert observed_state(fields[4:13]) == authority.public_state(), ('query suite public state', counts['commands'])
            pending = None
            counts['commands'] += 1
        elif event == 'HREPLY':
            assert pending is not None and legacy.decode(int(fields[2], 16), legacy.REP) == pending[2]
            counts['reply_hold_samples'] += 1
        elif event == 'QHOLD':
            cycle, demand = int(fields[1]), int(fields[2], 16)
            assert int(fields[3]) == 0 and int(fields[4], 16) == 0
            if held_query is not None:
                assert cycle == held_query[0] + 1 and demand == held_query[1], 'held lookup changed or event omitted'
            held_query = (cycle, demand)
            counts['query_holds'] += 1
        elif event == 'LOOKUP':
            cycle, packed = int(fields[1]), int(fields[2], 16)
            if held_query is not None:
                assert cycle == held_query[0] + 1 and packed == held_query[1], 'lookup fire differs from held demand'
                held_query = None
            assert pending is None, 'lookup admitted with outstanding reply'
            demand = legacy.decode(packed, DEMAND)
            permitted, expected = authority.query(demand)
            assert int(fields[3]) == permitted and legacy.decode(int(fields[4], 16), legacy.REP) == expected, (demand, 'lookup result')
            assert len(fields) == 14 and observed_state(fields[5:14]) == authority.public_state(), 'query public state changed'
            counts['queries'] += 1
            counts['allowed' if permitted else 'denied'] += 1
            if permitted:
                allowed_modes[demand['mode']] += 1
            else:
                denied_fields['rejected_demands'] += 1
        else:
            raise AssertionError(event)
    assert pending is None and held_query is None
    assert counts['command_inputs'] == counts['commands'] + counts['commands_discarded_at_explicit_cold']
    for key in ('command_inputs', 'commands', 'queries', 'allowed', 'denied', 'resets', 'query_holds'):
        assert metrics[key] == counts[key], (key, metrics[key], counts[key])
    assert metrics['finished'] and counts['allowed'] > 0 and counts['denied'] > 0
    if not metrics['near_sequence']:
        assert set(allowed_modes) == set(range(6)) and counts['query_holds'] > 0
    return dict(status='PASS', metrics=metrics, counts=dict(counts), allowed_modes=dict(allowed_modes))


def audit(root):
    compat, queries = audit_compat(root), audit_queries(root)
    result = dict(status='PASS', compat=compat, queries=queries, current_a64_bundle_verified=True,
                  complete_frame_ref_verified=True, private_dut_state_used_as_expectation=False,
                  source_result_closure_explicit_environment_input=True, production_automatic_publish_verified=False,
                  production_scan_join_verified=False, physical_fence_verified=False, actual_ddr_verified=False,
                  full_project_goal_complete=False)
    (root / 'reference-audit.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('directory', type=Path)
    args = parser.parse_args()
    audit(args.directory)
