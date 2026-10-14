"""R2严格向量及有限场景清单；当前已实现家庭之外明确列为未生成。

COMPLETE表示本次文件写出/预审完成，不表示230场景已实现或仿真通过。
完整套件交付前必须覆盖required_case_ids；诊断筛选永远标PARTIAL。
"""
from __future__ import annotations
import argparse, hashlib, itertools, json, re, random
from pathlib import Path
from canny_stream_reference import gradient_direction, classify_window, gaussian_image, self_check

NAME=re.compile(r'[A-Za-z0-9_-]+\Z')
REQUIRED_STREAM=(['U-G%03d'%n for n in range(1,45)]
    +['U-D%03d'%n for n in range(1,50)]+['U-F%03d'%n for n in range(1,7)]
    +['U-NW%03d'%n for n in range(1,13)]+['U-NC%03d'%n for n in range(1,25)]
    +['C0-C%02d'%n for n in range(1,22)]+['MD%03d'%n for n in range(1,25)]
    +['HD%03d'%n for n in range(1,5)]+['HD-F%03d'%n for n in range(1,3)])
REQUIRED_OBSERVER=(['OBS-B%03d'%n for n in range(1,15)]
    +['OBS-R%03d'%n for n in range(1,25)]+['SRC%03d'%n for n in range(1,5)]
    +['TOP-S001','TOP-HD001'])


def digest(path):
    h=hashlib.sha256()
    with Path(path).open('rb') as f:
        for block in iter(lambda:f.read(1048576),b''):
            h.update(block)
    return h.hexdigest().upper()


def ids(n,recovery=False):
    return 2 | ((n+(0x10000 if recovery else 0))<<32) | ((0x10000000+n+int(recovery))<<64)


def side(x,y,w,h,identity):
    return x | (y<<11) | (identity<<22) | (int(x==0 and y==0)<<118) \
        | (int(x==w-2)<<119) | (int(x==w-2 and y==h-1)<<120)


def signed11(v):
    if type(v) is not int or not -1024<=v<=1023:
        raise ValueError('signed11 representation')
    return v&2047


def gradient_lane(gx,gy,m):
    if type(m) is not int or not 0<=m<=2047:
        raise ValueError('magnitude representation')
    return signed11(gx) | (signed11(gy)<<11) | (m<<22)


def write_vector(root,relative,bits,values):
    path=Path(relative)
    if path.is_absolute() or '..' in path.parts or not NAME.fullmatch(path.stem):
        raise ValueError('unsafe vector path')
    target=root/path
    target.parent.mkdir(parents=True,exist_ok=True)
    digits=(bits+3)//4
    rows=0
    with target.open('x',encoding='ascii',newline='\n') as f:
        for value in values:
            if type(value) is not int or not 0<=value<(1<<bits):
                raise ValueError('vector value outside exact width')
            f.write(f'{value:0{digits}x}\n'); rows+=1
    if not rows:
        raise ValueError('empty vector')
    return {'schema':1,'path':relative,'bits':bits,'digits':digits,'rows':rows,'sha256':digest(target)}


def validate_vector(root,meta):
    rel=Path(meta['path'])
    if rel.is_absolute() or '..' in rel.parts:
        raise ValueError('vector outside run')
    path=(root/rel).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError('vector outside run')
    if type(meta['rows']) is not int or meta['rows']<=0 or meta['digits']!=(meta['bits']+3)//4:
        raise ValueError('invalid vector schema')
    count=0
    with path.open('rb') as f:
        for line in f:
            if len(line)!=meta['digits']+1 or line[-1:]!=b'\n' \
                or re.fullmatch(b'[0-9a-f]+\n',line) is None:
                raise ValueError('strict lowercase hex/LF required')
            if int(line[:-1],16)>=(1<<meta['bits']):
                raise ValueError('nonzero high padding')
            count+=1
    if count!=meta['rows'] or digest(path)!=meta['sha256']:
        raise ValueError('vector rows/hash differ')


def gaussian_cases(root):
    fixtures=[(6,5,[value]*30,0,False) for value in (0,255)]
    for x,y in ((0,0),(5,0),(0,4),(5,4),(1,1),(4,1),(1,3),(4,3),(2,2)):
        for value in (30,31,32,33):
            source=[0]*30;source[y*6+x]=value
            fixtures.append((6,5,source,0,False))
    ramp=[16*y+x for y in range(5) for x in range(6)]
    fixtures.append((6,5,ramp,0,True))
    fixtures.append((1920,5,[(x+16*y)%256 for y in range(5) for x in range(1920)],0,False))
    rng=random.Random(0x431)
    noisy=[rng.randrange(256) for _ in range(30)]
    for position,value in zip(random.Random(0x1060).sample(range(30),2),(0,255)):
        noisy[position]=value
    for phase in range(1,5):
        fixtures.append((6,5,noisy if phase==4 else ramp,phase,False))
    for index,(w,h,source,phase,stalls) in enumerate(fixtures):
        n=index+1;g8=gaussian_image(source,w,h)
        stimulus=[];expected=[]
        for p in range(w*h//2):
            x=2*(p%(w//2));y=p//(w//2);identity=ids(n)
            stimulus.append(source[2*p]|(source[2*p+1]<<8)|(side(x,y,w,h,identity)<<16))
            expected.append(g8[2*p]|(g8[2*p+1]<<8)|(side(x,y,w,h,identity)<<16))
        yield {'case_id':f'U-G{n:03d}','kind':'gaussian','width':w,'height':h,'phase':phase,
            'random_stalls':stalls,'identity':f'{ids(n):024x}','expected_pairs':w*h//2,
            'input':write_vector(root,f'U-G{n:03d}/input.hex',137,stimulus),
            'expected':write_vector(root,f'U-G{n:03d}/expected.hex',137,expected)}


def direction_cases(root):
    pairs=((0,0),(1020,0),(0,1020),(128,53),(128,54),(53,128),(54,128),
           (300,300),(424,1020),(765,765))
    signs=tuple(itertools.product((1,-1),repeat=2))
    fixtures=tuple((x*sx,y*sy) for x,y in pairs for sx,sy in signs)
    for case_index in range(49):
        n=45+case_index # 全套件从U-G44之后的权威n身份。
        bad=case_index>=40
        stimulus=[]; expected=[]; follow=[]; follow_expected=[]
        for p in range(20):
            x=2*(p%4);y=p//4
            lanes=[]; dirs=[]
            for lane in range(2):
                gx,gy=fixtures[(case_index+lane)%40] if not bad else (128,53)
                m=abs(gx)+abs(gy)
                d=gradient_direction(gx,gy,m)
                if bad and p==4:
                    fault=case_index-40
                    if lane==0 and fault in (0,8): gx=-1024
                    elif lane==0 and fault==1: gx=1021
                    elif lane==0 and fault==2: gy=-1024
                    elif lane==0 and fault==3: gy=1021
                    elif lane==0 and fault==4: m=1531
                    elif lane==0 and fault==5: m=180
                    elif fault==6 and lane==1: gx=1021
                    elif fault==7: gx=1021
                lanes.append(gradient_lane(gx,gy,m)); dirs.append(d)
            packed=lanes[0]|(lanes[1]<<33)
            stimulus.append(packed | (side(x,y,8,5,ids(n))<<66))
            expected.append(packed | (dirs[0]<<66)|(dirs[1]<<68)
                            | (side(x,y,8,5,ids(n))<<70))
            good=gradient_lane(128,53,181)
            follow.append(good|(good<<33)|(side(x,y,8,5,ids(n,True))<<66))
            follow_expected.append(good|(good<<33)|(side(x,y,8,5,ids(n,True))<<70))
        case={'case_id':f'U-D{case_index+1:03d}','kind':'direction','width':8,'height':5,
              'identity':f'{ids(n):024x}','bad':bad,'flush_error':case_index==48,
              'input':write_vector(root,f'U-D{case_index+1:03d}/input.hex',187,stimulus),
              'expected':write_vector(root,f'U-D{case_index+1:03d}/expected.hex',191,expected),
              'expected_pairs':20,'bad_pair_index':4 if bad else None}
        if bad:
            lane=int(case_index==46)
            derr=(ids(n)<<24)|(1<<23)|(lane<<22)|(1<<11)|lane
            case['error']=write_vector(root,f'U-D{case_index+1:03d}/error.hex',120,[derr])
            case['recovery_identity']=f'{ids(n,True):024x}'
            case['recovery_input']=write_vector(root,f'U-D{case_index+1:03d}/recovery_input.hex',187,follow)
            case['recovery_expected']=write_vector(root,f'U-D{case_index+1:03d}/recovery_expected.hex',191,follow_expected)
        yield case


def classify_cases(root):
    profiles=((0,0,0,0,0),(10,0,10,9,10),(10,10,0,0,9),
              (100,200,0,99,100),(256,255,256,255,256),(1530,1023,1024,1530,2047))
    for direction in range(4):
        for profile in range(6):
            index=direction*6+profile
            n=44+49+6+12+index+1
            tl,th=profiles[profile][3:]
            stimulus=[];expected=[]
            for p in range(24):
                x,y=2*(p%4),p//4
                payload=0;classes=0
                for lane in range(2):
                    center,neg,pos,_,_=profiles[(profile+lane)%6]
                    cells=[0]*9; cells[4]=center|(direction<<11)
                    a,b=((3,5),(0,8),(1,7),(6,2))[direction]
                    cells[a]=neg; cells[b]=pos
                    payload|=sum(value<<(lane*144+i*16) for i,value in enumerate(cells))
                    classes|=classify_window(cells,x+lane,y,8,6,tl,th)<<(lane*2)
                stimulus.append(payload|(side(x,y,8,6,ids(n))<<288))
                expected.append(classes|(side(x,y,8,6,ids(n))<<4))
            yield {'case_id':f'U-NC{index+1:03d}','kind':'classify','width':8,'height':6,
                'identity':f'{ids(n):024x}','tl':tl,'th':th,'expected_pairs':24,
                'input':write_vector(root,f'U-NC{index+1:03d}/input.hex',409,stimulus),
                'expected':write_vector(root,f'U-NC{index+1:03d}/expected.hex',125,expected)}


def fork_cases(root):
    for schedule in range(1,7):
        n=44+49+schedule
        files={k:[] for k in ('input','expected_n','expected_grad','recovery_input','recovery_n','recovery_grad')}
        for p in range(20):
            x,y=2*(p%4),p//4
            lanes=[];directions=[]
            for lane in range(2):
                gx,gy=(127+p+lane,53-lane) if p%2==0 else (-53-lane,128+p)
                m=abs(gx)+abs(gy)
                lanes.append((gx,gy,m));directions.append(gradient_direction(gx,gy,m))
            raw=sum(gradient_lane(*v)<<(lane*33) for lane,v in enumerate(lanes)) \
                | (directions[0]<<66) | (directions[1]<<68)
            n_pair=sum((v[2]|(directions[lane]<<11))<<(lane*16) for lane,v in enumerate(lanes))
            grad_pair=sum((signed11(v[0])|(signed11(v[1])<<11)|(directions[lane]<<22))<<(lane*32)
                          for lane,v in enumerate(lanes))
            for recovery in (False,True):
                prefix='recovery_' if recovery else ''
                identity=ids(n,recovery)
                files[prefix+'input'].append(raw|(side(x,y,8,5,identity)<<70))
                files['recovery_n' if recovery else 'expected_n'].append(n_pair|(side(x,y,8,5,identity)<<32))
                files['recovery_grad' if recovery else 'expected_grad'].append(grad_pair|(side(x,y,8,5,identity)<<64))
        case={'case_id':f'U-F{schedule:03d}','kind':'fork','width':8,'height':5,
              'schedule':schedule,'identity':f'{ids(n):024x}','expected_pairs':20}
        bits={'input':191,'expected_n':153,'expected_grad':185,
              'recovery_input':191,'recovery_n':153,'recovery_grad':185}
        for key,values in files.items():
            if key.startswith('recovery_') and schedule!=4:
                continue
            case[key]=write_vector(root,f'U-F{schedule:03d}/{key}.hex',bits[key],values)
        yield case


def generate(root):
    if root.exists():
        raise ValueError('output directory must be new')
    root.mkdir(parents=True)
    cases=list(gaussian_cases(root))+list(direction_cases(root))+list(fork_cases(root))+list(classify_cases(root))
    for case in cases:
        for value in case.values():
            if isinstance(value,dict) and 'sha256' in value:
                validate_vector(root,value)
    actual=[c['case_id'] for c in cases]
    manifest={'schema_version':1,'suite':'r2-stream-v1','status':'COMPLETE',
        'scope_status':'PARTIAL_IMPLEMENTATION','required_case_ids':REQUIRED_STREAM,
        'generated_case_ids':actual,'not_generated_case_ids':[i for i in REQUIRED_STREAM if i not in actual],
        'rtl_used_for_reference_generation':False,'self_check':self_check(),'cases':cases}
    (root/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return manifest


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--out-dir',type=Path)
    parser.add_argument('--self-check',action='store_true')
    args=parser.parse_args()
    if args.self_check:
        print(json.dumps(self_check()))
    elif args.out_dir:
        m=generate(args.out_dir)
        print(json.dumps({'status':m['status'],'scope_status':m['scope_status'],
                          'generated':len(m['cases']),'required':len(REQUIRED_STREAM)}))
    else:
        parser.error('--out-dir or --self-check required')
