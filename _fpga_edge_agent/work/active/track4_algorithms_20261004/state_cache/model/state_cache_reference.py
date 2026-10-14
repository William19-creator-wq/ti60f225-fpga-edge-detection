"""SC01…05：独立2bit字节图，验证真实RAM/cache响应与最终外存。"""
import argparse
import json
import random
from pathlib import Path

def read_state(data,index):
    return (data[index//4] >> (2*(index%4))) & 3

def claim_state(data,index):
    shift=2*(index%4)
    data[index//4]=(data[index//4] & ~(3<<shift)) | (3<<shift)

def memory_lines(data):
    return [int.from_bytes(data[i:i+64],'little') for i in range(0,len(data),64)]

def generate(root,width,height):
    root.mkdir(parents=True,exist_ok=True)
    n=width*height
    allocation=((n+255)//256)*64
    rng=random.Random(0x43106025)
    image=bytearray(allocation)
    for index in range(n):
        image[index//4] |= rng.randrange(3) << (2*(index%4))
    # 同set五个tag保证全部为真正候选，随后多次命中/替换。
    collisions=[(tag<<13)+1 for tag in range(8) if (tag<<13)+1<n]
    for index in collisions:
        shift=2*(index%4)
        image[index//4]=(image[index//4]&~(3<<shift))|(1<<shift)
    (root/'initial-lines.mem').write_text(''.join(f'{line:0128x}\n' for line in memory_lines(image)),encoding='ascii')
    expected=bytearray(image)
    operations=[]
    def operation(op,index):
        error=int(index>=n or (op==3 and index!=0))
        old=0 if error or op==3 else read_state(expected,index)
        claimed=int(not error and ((op==1 and old==2) or (op==2 and old==1)))
        if claimed:
            claim_state(expected,index)
        operations.append((op,index,old,claimed,error))
    for index in [0,1,2,7,8,255,256,4095,4096,n-1,n]:
        if index>n:
            continue
        for op in (0,1,2,0):
            operation(op,index)
    for _ in range(5):
        for index in collisions:
            operation(2,index);operation(0,index)
        if collisions:
            operation(0,collisions[0])
    for _ in range(4096):
        operation(rng.randrange(3),rng.randrange(n))
    # 双字/同字邻居在更新后的新版本上读，保证slot不污染。
    for index in range(min(n,512)):
        operation(1,index);operation(2,index);operation(0,index)
    operation(3,1) # 非法FLUSH不得关闭/失效当前图。
    operation(0,1)
    operation(3,0)
    (root/'operations.txt').write_text(''.join(' '.join(map(str,row))+'\n' for row in operations),encoding='ascii')
    (root/'expected-lines.mem').write_text(''.join(f'{line:0128x}\n' for line in memory_lines(expected)),encoding='ascii')
    (root/'vector-summary.json').write_text(json.dumps({'width':width,'height':height,'pixels':n,
        'allocated_bytes':allocation,'operations':len(operations),'expected_claims':sum(r[3] for r in operations),
        'seed':'43106025','collision_indices':collisions},indent=2),encoding='utf-8')

def words(path):
    output=[]
    for line in path.read_text().splitlines():
        line=line.split('//')[0].strip()
        if line and not line.startswith('@'):
            output.extend(int(word,16) for word in line.split())
    return output

def audit(root):
    metadata=json.loads((root/'vector-summary.json').read_text())
    expected_ops=[tuple(map(int,row.split())) for row in (root/'operations.txt').read_text().splitlines()]
    expected_memory=words(root/'expected-lines.mem')
    results=[tuple(map(int,row.split())) for row in (root/'actual-results.txt').read_text().splitlines()]
    assert len(results)==2*len(expected_ops)
    for frame in range(2):
        for i,expected in enumerate(expected_ops):
            actual=results[frame*len(expected_ops)+i]
            assert actual==(frame,i,*expected),f'operation differs frame{frame}/item{i}: {actual}/{expected}'
        actual_memory=words(root/f'actual-frame{frame}.mem')
        assert actual_memory==expected_memory,f'final byte state differs frame{frame}'
    faults=json.loads((root/'fault-result.json').read_text())
    assert faults['read_error'] and faults['write_error'] and faults['quarantine'] and faults['install_reset'] and faults['bad_config'] and faults['address_end']
    assert faults['abort_checks']==10 and faults['abort_extra_claims']==3
    assert faults['atomic_claims']==2*metadata['expected_claims']+1+faults['abort_extra_claims']
    result={'status':'PASS','frames':2,'pixels_per_frame':metadata['pixels'],
            'checked_operations':len(results),'expected_atomic_claims':2*metadata['expected_claims'],
            'full_address_range':metadata['width']==1920 and metadata['height']==1080,
            'final_memory_lines':2*len(expected_memory),'fault_checks':faults,
            'actual_ddr_verified':False,'physical_ram_mapping_verified':False}
    (root/'audit-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result))

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('action',choices=('generate','audit'))
    parser.add_argument('root',type=Path)
    parser.add_argument('--width',type=int,default=1920)
    parser.add_argument('--height',type=int,default=1080)
    args=parser.parse_args()
    if args.action=='generate':
        generate(args.root,args.width,args.height)
    else:
        audit(args.root)
