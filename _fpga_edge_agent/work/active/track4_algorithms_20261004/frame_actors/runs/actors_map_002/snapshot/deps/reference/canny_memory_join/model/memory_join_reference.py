"""独立八邻域BFS + packed外存字节；没有cache/RTL FSM仿真。"""
import argparse, collections, hashlib, json, pathlib, random, struct

def breadth_first(classes,width,height):
    order=[i for i,value in enumerate(classes) if value==2]
    seen=set(order); fifo=collections.deque(order)
    while fifo:
        i=fifo.popleft(); x=i%width; y=i//width
        for yy in range(max(0,y-1),min(height,y+2)):
            for xx in range(max(0,x-1),min(width,x+2)):
                j=yy*width+xx
                if classes[j] in (1,2) and j not in seen:
                    seen.add(j);order.append(j);fifo.append(j)
    return [int(i in seen) for i in range(len(classes))],order

def packed_states(states,n):
    raw=bytearray(((n+255)//256)*64)
    for index,state in enumerate(states):raw[index//4]|=state<<(2*(index%4))
    return bytes(raw)

def generate(root,width,height,full):
    root=pathlib.Path(root);root.mkdir(parents=True,exist_ok=True);n=width*height;rng=random.Random(0x712431)
    cases=[]
    def add(name,states):cases.append((name,states))
    add('no_seed',[rng.randrange(2) for _ in range(n)])
    add('all_strong',[2]*n)
    add('connected_weak',[2]+[1]*(n-1))
    states=[0]*n;states[0]=2;states[-1]=1;add('isolated_weak',states)
    states=[0]*n
    for i in range(min(width,height)):states[i*width+i]=2 if i==0 else 1
    add('diagonal',states)
    states=[0]*n;states[width-1]=2;states[width]=1;add('cross_row_counterexample',states)
    if not full:
        for k in range(24):add(f'random_{k}',[rng.choices((0,1,2),weights=(5,8,1))[0] for _ in range(n)])
    else:
        # 先完成全地址域稀疏场景，密集耗时另run，不能由此冒称最重吞吐。
        cases=[cases[i] for i in (0,3,4,5)]
    metadata=[]
    for index,(name,states) in enumerate(cases):
        edges,order=breadth_first(states,width,height)
        (root/f'case-{index}.class').write_text(''.join(f'{s}\n' for s in states),encoding='ascii')
        (root/f'case-{index}.edge').write_bytes(bytes(edges))
        after=[3 if edge else state for state,edge in zip(states,edges)]
        (root/f'case-{index}.state.bin').write_bytes(packed_states(after,n))
        (root/f'case-{index}.queue.bin').write_bytes(struct.pack(f'<{len(order)}I',*order))
        metadata.append({'id':index,'name':name,'edges':sum(edges),'n':n})
    (root/'cases.txt').write_text(''.join(f'{c["edges"]}\n' for c in metadata),encoding='ascii')
    (root/'vector-summary.json').write_text(json.dumps({'width':width,'height':height,'cases':metadata,'full1080p':width==1920 and height==1080},indent=2),encoding='utf-8')
    print(f'Generated {len(cases)} independent BFS images, {width}x{height}')

def audit(root):
    root=pathlib.Path(root);meta=json.loads((root/'vector-summary.json').read_text());rows=[]
    for line in (root/'actual-results.txt').read_text().splitlines():rows.append(list(map(int,line.split())))
    assert len(rows)==len(meta['cases'])
    pixels=0;maximum=0
    for case,row in zip(meta['cases'],rows):
        ident,outcome,reason,enq,pop,count,edge_count,cycles=row
        assert (ident,outcome,reason,enq,pop,count,edge_count)==(case['id'],0,0,case['edges'],case['edges'],case['n'],case['edges'])
        for kind in ('edge','state.bin','queue.bin'):
            actual=(root/f'actual-{ident}.{kind}').read_bytes();gold=(root/f'case-{ident}.{kind}').read_bytes()
            assert actual==gold,(ident,kind,'exact byte comparison failed')
        pixels+=count;maximum=max(maximum,cycles)
    metrics=json.loads((root/'protocol-metrics.json').read_text())
    assert metrics['finished']
    if not meta['full1080p']:
        assert metrics['cancel_cases']>=9 and metrics['safe_error'] and metrics['unknown_quarantine']
    assert metrics['atomic_pairs']==sum(c['edges'] for c in meta['cases'])
    report={'status':'PASS','cases':len(rows),'pixels_compared':pixels,'max_cycles':maximum,'full1080p':meta['full1080p'],
            'metrics':metrics,'production_ddr_verified':False,'production_pnr_verified':False,'full_project_goal_complete':False,
            'results_sha256':hashlib.sha256((root/'actual-results.txt').read_bytes()).hexdigest()}
    (root/'reference-audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','audit']);p.add_argument('root')
    p.add_argument('--width',type=int,default=32);p.add_argument('--height',type=int,default=24);p.add_argument('--full',action='store_true')
    a=p.parse_args()
    if a.action=='generate':generate(a.root,a.width,a.height,a.full)
    else:audit(a.root)
