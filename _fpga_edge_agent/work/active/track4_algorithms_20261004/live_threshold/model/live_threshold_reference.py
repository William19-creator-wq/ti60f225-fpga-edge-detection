"""LT-T01…04：真实GPIO逐拍参考；空样本队列隔离复位占位值。"""
import argparse
import hashlib
import json
import random
from pathlib import Path

PARAMETERS = ((7, 256, 16), (2, 0, 1), (2, 2047, 2047))

class KeyHistory:
    def __init__(self, n):
        self.n = n
        self.reset()

    def reset(self):
        self.pipeline = []
        self.history = []
        self.level = 1
        self.armed = False
        self.press = 0

    def advance(self, raw):
        self.press = 0
        self.pipeline.append(raw)
        if len(self.pipeline) <= 2:
            return
        sample = self.pipeline.pop(0)
        if not self.armed:
            self.history = (self.history + [sample]) if sample else []
            if len(self.history) == self.n:
                self.armed = True
                self.history = []
        elif sample == self.level:
            self.history = []
        else:
            self.history.append(sample)
            if len(self.history) == self.n:
                self.level = sample
                self.press = 1 - sample
                self.history = []

class Control:
    def __init__(self, n, initial, step):
        self.keys = (KeyHistory(n), KeyHistory(n))
        self.initial, self.step = initial, step
        self.pending = self.active = initial

    def tick(self, reset, inc, dec, job):
        if reset:
            for key in self.keys:
                key.reset()
            self.pending = self.active = self.initial
        else:
            old_pending = self.pending
            direction = self.keys[0].press - self.keys[1].press
            self.pending = max(0, min(2047, self.pending + direction * self.step))
            if job:
                self.active = old_pending
            for key, raw in zip(self.keys, (inc, dec)):
                key.advance(raw)
        return [self.pending, self.active, self.keys[0].press, self.keys[1].press,
                int(self.keys[0].armed and self.keys[0].level == 0),
                int(self.keys[1].armed and self.keys[1].level == 0)]

def stimuli():
    rng = random.Random(0x43106025)
    rows = []
    def segment(length, inc, dec, reset=0):
        for _ in range(length):
            rows.append((reset, inc, dec, int(rng.randrange(5) == 0)))
    segment(4, 0, 0, 1)
    segment(50, 0, 0)  # 启动按住不能触发，包括最小N=2。
    segment(20, 1, 1)
    for _ in range(8):
        segment(1, 0, 1); segment(1, 1, 1)
    segment(6, 0, 1); segment(20, 1, 1)  # N=7拒绝N-1。
    segment(7, 0, 1); segment(20, 1, 1)
    segment(100, 0, 1); segment(20, 1, 1)  # 长按不重复。
    for _ in range(150):
        segment(12, 0, 1); segment(12, 1, 1)
    for _ in range(180):
        segment(12, 1, 0); segment(12, 1, 1)
    for _ in range(8):
        segment(12, 0, 0); segment(12, 1, 1)
    for _ in range(2000):
        segment(rng.randrange(1, 33), rng.randrange(2), rng.randrange(2),
                int(rng.randrange(83) == 0))
    return rows

def generate(root):
    root.mkdir(parents=True, exist_ok=True)
    controls = [Control(*params) for params in PARAMETERS]
    rows, expected = [], []
    coincident = 0
    for cycle, (rst, inc, dec, job) in enumerate(stimuli()):
        # 刻意在控制器消费旧press时启动任务，检查同沿旧pending规则。
        if not rst and any(c.keys[0].press or c.keys[1].press for c in controls):
            job = 1
            coincident += 1
        rows.append(f"{rst} {inc} {dec} {job}\n")
        values = [v for c in controls for v in c.tick(rst, inc, dec, job)]
        expected.append(f"{cycle} " + " ".join(map(str, values)) + "\n")
    (root / 'stimulus.txt').write_text(''.join(rows), encoding='ascii')
    (root / 'expected.txt').write_text(''.join(expected), encoding='ascii')
    (root / 'vector-summary.json').write_text(json.dumps({
        'cycles': len(rows), 'parameters': PARAMETERS, 'seed': '43106025',
        'event_job_coincidences': coincident}, indent=2), encoding='utf-8')

def audit(root):
    expected = (root / 'expected.txt').read_bytes()
    actual = (root / 'actual.txt').read_bytes()
    # 仿真宿主可能使用CRLF，统一行结束而不改变字段。
    e_rows = expected.decode('ascii').splitlines()
    a_rows = actual.decode('ascii').splitlines()
    if e_rows != a_rows:
        mismatch = next((i for i, pair in enumerate(zip(e_rows, a_rows)) if pair[0] != pair[1]),
                        min(len(e_rows), len(a_rows)))
        raise AssertionError(f'cycle {mismatch}: actual output differs; lengths {len(a_rows)}/{len(e_rows)}')
    edges = []
    for line in a_rows:
        vals = list(map(int, line.split()))
        thresholds = [vals[2 + i*6] for i in range(3)]
        for threshold in thresholds:
            # 严格M>T；这里验证配置域/比较边界，不冒称运行真实Sobel核。
            count = max(0, 1530-threshold)
            assert sum(m > threshold for m in range(1531)) == count
            edges.append(count)
    result = {'status': 'PASS', 'cycles': len(a_rows), 'instances': 3,
              'compared_fields': len(a_rows)*18,
              'actual_sha256': hashlib.sha256(actual).hexdigest(),
              'threshold_domain': [0,2047], 'comparison': 'M > T',
              'real_sobel_join': 'NOT_RUN', 'physical_cdc': 'NOT_RUN'}
    (root / 'audit-result.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=('generate','audit'))
    parser.add_argument('root', type=Path)
    args = parser.parse_args()
    (generate if args.action == 'generate' else audit)(args.root)
