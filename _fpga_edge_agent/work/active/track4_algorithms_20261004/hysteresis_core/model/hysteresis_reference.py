"""HY05：独立deque可达集合；不模拟RTL状态机、除法器或cache。"""
import argparse
import hashlib
import json
import random
from collections import deque
from pathlib import Path

def reachable(classes, width, height):
    seeds = [i for i,s in enumerate(classes) if s == 2]
    seen = set(seeds)
    queue = deque(seeds)
    while queue:
        i = queue.popleft()
        x,y = i % width, i // width
        for yy in range(max(0,y-1),min(height,y+2)):
            for xx in range(max(0,x-1),min(width,x+2)):
                j = yy*width+xx
                if classes[j] in (1,2) and j not in seen:
                    seen.add(j)
                    queue.append(j)
    return [int(i in seen) for i in range(len(classes))]

def generate(root, width, height, full):
    root.mkdir(parents=True,exist_ok=True)
    n = width*height
    rng = random.Random(0x43106025)
    cases = []
    def add(name, values, kind=0, outcome=0, reason=0):
        cases.append({'name':name,'classes':values,'kind':kind,'outcome':outcome,'reason':reason})
    add('no_seed',[rng.randrange(2) for _ in range(n)])
    add('all_strong',[2]*n)
    add('full_connected_weak',[2]+[1]*(n-1))
    isolated = [0]*n
    isolated[0]=2
    isolated[-1]=1
    add('isolated_weak',isolated)
    diagonal = [0]*n
    for i in range(min(width,height)):
        diagonal[i*width+i]=2 if i == 0 else 1
    add('diagonal',diagonal)
    crossed = [0]*n
    crossed[width-1]=2
    crossed[width]=1
    add('no_cross_row_wrap',crossed)
    if not full:
        for case in range(128):
            values = [rng.choices((0,1,2),weights=(5,8,1))[0] for _ in range(n)]
            add('random_%03d'%case,values)
        for kind in range(1,14):
            values = [2]+[1]*(n-1)
            outcome = 1 if kind <= 5 else (0 if kind in (9,10,11) else 2)
            reason = {1:1,2:3,3:1,4:2,5:3}.get(kind,0)
            if kind == 1:
                values[0]=3
            add('protocol_%02d'%kind,values,kind,outcome,reason)
    else:
        # 完整图的最重“全连接弱”场景会独立记录运行时间，不能预称FPS达标。
        cases = [cases[0],cases[2],cases[4],cases[5]]
    meta = []
    for index,case in enumerate(cases):
        values = case.pop('classes')
        stem = f'case-{index}'
        (root / (stem+'.class')).write_text(''.join(str(v)+'\n' for v in values),encoding='ascii')
        edges = reachable(values,width,height) if case['outcome'] == 0 else []
        (root / (stem+'.edge')).write_text(''.join(str(v)+'\n' for v in edges),encoding='ascii')
        meta.append(dict(case,id=index,expected_edges=sum(edges),pixel_count=n,
                         class_sha256=hashlib.sha256((root/(stem+'.class')).read_bytes()).hexdigest()))
    (root/'cases.txt').write_text(''.join(f"{c['kind']} {c['outcome']} {c['reason']} {c['expected_edges']}\n" for c in meta),encoding='ascii')
    (root/'vector-summary.json').write_text(json.dumps({'width':width,'height':height,'cases':meta,
        'seed':'43106025','full1080p':width==1920 and height==1080},indent=2),encoding='utf-8')

def audit(root):
    metadata = json.loads((root/'vector-summary.json').read_text())
    results = [list(map(int,line.split())) for line in (root/'actual-results.txt').read_text().splitlines()]
    assert len(results) == len(metadata['cases'])
    max_cycles = 0
    for expected,actual in zip(metadata['cases'],results):
        case,outcome,reason,enqueued,popped,pixels,edges,cycles = actual
        assert (case,outcome,reason) == (expected['id'],expected['outcome'],expected['reason'])
        assert 0 <= popped <= enqueued <= expected['pixel_count']
        if outcome == 0:
            assert pixels == expected['pixel_count']
            assert enqueued == popped == edges == expected['expected_edges']
            actual_edges = (root/f'actual-{case}.edge').read_text().splitlines()
            golden = (root/f'case-{case}.edge').read_text().splitlines()
            assert actual_edges == golden, f'edge mismatch in case {case}'
        max_cycles = max(max_cycles,cycles)
    result = {'status':'PASS','cases':len(results),'max_cycles':max_cycles,
              'full1080p':metadata['full1080p'],'seed':'43106025',
              'behavioral_memory_service':True,'production_ddr_verified':False,
              'results_sha256':hashlib.sha256((root/'actual-results.txt').read_bytes()).hexdigest()}
    (root/'audit-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action',choices=('generate','audit'))
    parser.add_argument('root',type=Path)
    parser.add_argument('--width',type=int,default=12)
    parser.add_argument('--height',type=int,default=9)
    parser.add_argument('--full',action='store_true')
    args = parser.parse_args()
    if args.action == 'generate':
        generate(args.root,args.width,args.height,args.full)
    else:
        audit(args.root)
