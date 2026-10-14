"""独立deque/字节外存参考；不复制RTL的bank/prefetch状态机。"""
import argparse, collections, hashlib, json, pathlib, random, struct

def generate(root, width, height):
    root=pathlib.Path(root); root.mkdir(parents=True,exist_ok=True)
    n=width*height; rng=random.Random(0x7134); operations=[]; expected=[]
    fifo=collections.deque(); pending=None; head=tail=0
    def emit(op, index=0):
        nonlocal head,tail,pending
        error=0; value=0
        if op=='C':
            assert pending is None and tail<n
            fifo.append(index);pending=index;tail+=1;value=index
        elif op=='P':
            error=int(pending!=index)
            if not error:value=pending;pending=None
        elif op=='O':
            error=int(pending is not None or not fifo)
            if not error:value=fifo.popleft();head+=1
        elif op=='S':assert pending is None
        elif op=='E':error=int(bool(fifo) or pending is not None)
        operations.append((op,index));expected.append((op,value,error,head,tail))
    emit('O');emit('P',0)
    # 1..15前缀封存后继续追加，覆盖原64B块时必须保留旧entry。
    for length in range(1,16):
        for _ in range(length):
            value=rng.randrange(n);emit('C',value);emit('P',value)
        emit('S')
        for _ in range(length):emit('O')
    count=min(n-tail,2100)
    for i in range(count):
        value=(i*371+19)%n;emit('C',value)
        if i in (0,255,256):emit('P',(value+1)%n);emit('O')
        emit('P',value)
        if i%23==0:emit('O')
        if i%377==0:emit('S')
    emit('E') # 非空end必须拒绝且保留job。
    # 混合forward/prefetch；部分c快照末尾之后增长，旧padding不得命中。
    for _ in range(min(len(fifo),129)):emit('O')
    emit('S')
    while fifo:emit('O')
    emit('O');emit('E')
    with (root/'commands.txt').open('w',encoding='ascii') as f:
        for op,index in operations:f.write(f'{op} {index}\n')
    (root/'expected.json').write_text(json.dumps(expected),encoding='utf-8')
    (root/'geometry.json').write_text(json.dumps({'width':width,'height':height,'n':n,'operations':len(operations)}),encoding='utf-8')
    print(f'Generated {len(operations)} independent FIFO operations, N={n}')

def audit(root):
    root=pathlib.Path(root); expected=json.loads((root/'expected.json').read_text())
    actual=[line.split() for line in (root/'actual-results.txt').read_text().splitlines()]
    assert len(actual)==len(expected),(len(actual),len(expected))
    entries=[]
    for row,want in zip(actual,expected):
        got=[row[0]]+list(map(int,row[1:]))
        assert got==want,(got,want)
        if got[0]=='C':entries.append(got[1])
    memory=(root/'final-memory.bin').read_bytes()
    words=struct.unpack(f'<{len(memory)//4}I',memory)
    assert list(words[:len(entries)])==entries,'DDR committed prefix differs from actual claimed FIFO'
    assert all(v==0 for v in words[len(entries):]),'Unwritten padding unexpectedly changed'
    metrics=json.loads((root/'tb-metrics.json').read_text())
    assert metrics['finished'] and metrics['claims']==len(entries)
    assert metrics['prefix_seals']>=15 and metrics['forward']>0 and metrics['prefetch']>0
    assert metrics['unknown_quarantine'] and metrics['abort_scenarios']>=6 and metrics['safe_error']
    report={'status':'PASS','operations':len(expected),'claims':len(entries),'compared_bytes':len(memory),
            'memory_sha256':hashlib.sha256(memory).hexdigest(),'metrics':metrics,
            'actual_ddr_verified':False,'full_project_goal_complete':False}
    (root/'reference-audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','audit']);p.add_argument('root')
    p.add_argument('--width',type=int,default=1920);p.add_argument('--height',type=int,default=1080)
    a=p.parse_args()
    if a.action=='generate':generate(a.root,a.width,a.height)
    else:audit(a.root)
