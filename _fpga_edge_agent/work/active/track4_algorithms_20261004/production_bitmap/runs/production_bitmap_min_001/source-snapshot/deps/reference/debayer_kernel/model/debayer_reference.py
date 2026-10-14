"""DK01…04：显式颜色表/邻居选择/整数平均，对照真实事件账。"""
import argparse
import json
import random
from collections import deque
from pathlib import Path

PATTERNS = (((0,1),(1,2)),((1,0),(2,1)),((1,2),(0,1)),((2,1),(1,0)))
BASE_ID = 0x100000000000000

def color(window,x,y,phase):
    site = PATTERNS[phase][y%2][x%2]
    channels = []
    for target in range(3):
        if target == site:
            indices = [4]
        elif site != 1:
            indices = [1,3,5,7] if target == 1 else [0,2,6,8]
        else:
            horizontal = PATTERNS[phase][y%2][(x+1)%2]
            indices = [3,5] if target == horizontal else [1,7]
        numerator = sum(window[i] for i in indices)
        quotient,remainder = divmod(numerator,4*len(indices))
        channels.append(min(255,quotient+int(2*remainder>=4*len(indices))))
    return (channels[0]<<16)|(channels[1]<<8)|channels[2]

def generate(root):
    rng = random.Random(0x43106025)
    rows = []
    def add(windows,x,y,phase):
        packed = sum(value<<(90*lane+10*i) for lane,w in enumerate(windows) for i,value in enumerate(w))
        rgb = color(windows[0],x,y,phase)|(color(windows[1],x+1,y,phase)<<24)
        index = len(rows)
        rows.append({'index':index,'window':packed,'x':x,'y':y,'phase':phase,
                     'job':BASE_ID+index,'markers':rng.randrange(8),'rgb':rgb})
    for phase in range(4):
        for y in (0,1):
            for value in range(1024):
                add([[value]*9]*2,0,y,phase)
            for i in range(9):
                for value in (1,2,3,4,1020,1021,1022,1023):
                    w = [0]*9
                    w[i]=value
                    add([w,list(reversed(w))],1918,y,phase)
    for _ in range(16384):
        add([[rng.randrange(1024) for _ in range(9)] for _ in range(2)],
            2*rng.randrange(960),rng.randrange(1080),rng.randrange(4))
    root.mkdir(parents=True,exist_ok=True)
    (root/'stimulus.txt').write_text(''.join(f"{r['window']:045x} {r['x']} {r['y']} {r['phase']} {r['job']:016x} {r['markers']}\n" for r in rows),encoding='ascii')
    (root/'expected.json').write_text(json.dumps(rows,separators=(',',':')),encoding='utf-8')
    print(json.dumps({'items':len(rows),'pixels':len(rows)*2,'four_phases':True,'seed':'43106025'}))

def audit(root):
    vectors = json.loads((root/'expected.json').read_text())
    pending = deque()
    accepted = delivered = reset_aborted = reset_checks = 0
    for line in (root/'events.txt').read_text().splitlines():
        values = line.split()
        if values[0] == 'A':
            index = int(values[1])
            assert index == accepted
            pending.append(index)
            accepted += 1
        elif values[0] == 'O':
            index,rgb,x,y,markers,job = int(values[1]),int(values[2],16),int(values[3]),int(values[4]),int(values[5]),int(values[6],16)
            assert pending.popleft() == index
            row = vectors[index]
            assert (rgb,x,y,markers,job)==(row['rgb'],row['x'],row['y'],row['markers'],row['job']),f'item {index} differs'
            delivered += 1
        elif values[0] == 'R':
            if pending:
                reset_checks += 1
            reset_aborted += len(pending)
            pending.clear()
        else:
            raise AssertionError('unknown event')
    assert not pending and accepted == len(vectors) and accepted == delivered+reset_aborted
    assert reset_checks > 0
    result = {'status':'PASS','accepted_pairs':accepted,'delivered_pairs':delivered,
              'reset_aborted_pairs':reset_aborted,'reset_checks':reset_checks,
              'four_phases':True,'raw_precision':10,'rgb_precision':8,
              'real_row_window_verified':False,'production_camera_verified':False}
    (root/'audit-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action',choices=('generate','audit'))
    parser.add_argument('root',type=Path)
    args = parser.parse_args()
    (generate if args.action=='generate' else audit)(args.root)
