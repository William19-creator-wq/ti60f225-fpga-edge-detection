"""R2严格向量及有限场景清单；当前已实现家庭之外明确列为未生成。

COMPLETE表示本次文件写出/预审完成，不表示230场景已实现或仿真通过。
完整套件交付前必须覆盖required_case_ids；诊断筛选永远标PARTIAL。
"""
from __future__ import annotations
import argparse, hashlib, itertools, json, re, random
from pathlib import Path
from canny_stream_reference import dimensions, gradient_direction, classify_window, gaussian_image, nms_windows_image, stream_image, self_check
from r2_observer_reference import pack_cj, pack_fs, pack_cs, pattern_pixel, fp_pair, job_config, crc_records, terminal_flags, self_check as observer_self_check

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


def probe_inputs(root):
    """G1 V001…012：调用实际入口拒绝坏输入；各拒绝原因单独记录。"""
    root.mkdir(parents=True,exist_ok=False)
    results=[]
    def reject(case_id,label,action,exception=ValueError):
        try:action()
        except exception as error:
            results.append({'case_id':case_id,'subcase':label,'status':'PASS',
                'expected_exception':exception.__name__,'actual_exception':type(error).__name__,'message':str(error)})
        else:raise AssertionError(f'{case_id}/{label}: invalid input was accepted')
    reject('V001','bool-width',lambda:dimensions(True,5))
    reject('V001','bool-gradient',lambda:gradient_direction(True,0))
    reject('V001','bool-job',lambda:job_config(True,6,5))
    reject('V001','bool-vector-value',lambda:write_vector(root,'bool.hex',8,[True]))
    reject('V002','odd-width',lambda:dimensions(7,5))
    reject('V003','below-dimensions',lambda:dimensions(4,3))
    reject('V004','threshold-order',lambda:classify_window([0]*9,2,2,6,5,65,64))
    reject('V005','channel-256',lambda:stream_image([(256,0,0)]+[(0,0,0)]*29,6,5,False,False,0,64))
    for value in (-1021,1021):
        reject('V006',f'gx-{value}',lambda value=value:gradient_direction(value,0))
        reject('V006',f'gy-{value}',lambda value=value:gradient_direction(0,value))
    for value in (-1025,1024):reject('V006',f'representation-{value}',lambda value=value:signed11(value))
    def bad_file(case_id,label,content,rows,bits=8):
        path=root/f'{case_id}-{label}.hex';path.write_bytes(content)
        meta={'schema':1,'path':path.name,'bits':bits,'digits':(bits+3)//4,'rows':rows,'sha256':digest(path)}
        reject(case_id,label,lambda:validate_vector(root,meta))
    bad_file('V007','short',b'00\n',2)
    bad_file('V008','long',b'00\n01\n02\n',2)
    bad_file('V009','uppercase',b'aF\n',1)
    bad_file('V009','illegal-hex',b'ag\n',1)
    bad_file('V010','x',b'0x\n',1);bad_file('V010','z',b'0z\n',1)
    bad_file('V011','padding',b'20\n',1,5)
    reject('V012','absolute',lambda:write_vector(root,str((root/'absolute.hex').resolve()),8,[0]))
    reject('V012','parent',lambda:write_vector(root,'../escape.hex',8,[0]))
    reject('V012','existing-directory',lambda:generate(root))
    existing=write_vector(root,'existing.hex',8,[0])
    reject('V012','existing-file',lambda:write_vector(root,'existing.hex',8,[1]),FileExistsError)
    validate_vector(root,existing) # 拒绝覆盖后原文件仍有效。
    expected={f'V{n:03d}' for n in range(1,13)}
    if {r['case_id'] for r in results}!=expected:raise AssertionError('input probe coverage missing')
    output={'schema_version':1,'status':'PASS','case_count':12,'subevent_count':len(results),
        'unexpected_accepts':0,'existing_file_preserved':True,'cases':results}
    with (root/'result.json').open('x',encoding='utf-8',newline='\n') as f:f.write(json.dumps(output,indent=2)+'\n')
    return {'status':output['status'],'case_count':12,'subevent_count':len(results)}


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


def nms_window_cases(root):
    values=(0,255,256,1023,1024,1530)
    for pattern in range(2):
        mags=tuple(values[(y*8+x)%6] if pattern==0 else (200 if x in (0,7) or y in (0,5) else 100)
                   for y in range(6) for x in range(8))
        dirs=tuple((x+y)%4 for y in range(6) for x in range(8))
        windows=nms_windows_image(mags,dirs,8,6)
        for schedule in range(6):
            index=pattern*6+schedule+1;n=44+49+6+index
            case={'case_id':f'U-NW{index:03d}','kind':'nms_window','width':8,'height':6,
                  'schedule':schedule,'expected_pairs':24,'identity':f'{ids(n):024x}'}
            for recovery in (False,True):
                if recovery and schedule!=5:
                    continue
                stimulus=[];expected=[]
                for p in range(24):
                    x,y=2*(p%4),p//4
                    raw=sum((mags[2*p+lane]|(dirs[2*p+lane]<<11))<<(16*lane) for lane in range(2))
                    window_pair=sum(cell<<(lane*144+i*16)
                        for lane in range(2) for i,cell in enumerate(windows[2*p+lane]))
                    identity=ids(n,recovery)
                    stimulus.append(raw|(side(x,y,8,6,identity)<<32))
                    expected.append(window_pair|(side(x,y,8,6,identity)<<288))
                prefix='recovery_' if recovery else ''
                case[prefix+'input']=write_vector(root,f'U-NW{index:03d}/{prefix}input.hex',153,stimulus)
                case[prefix+'expected']=write_vector(root,f'U-NW{index:03d}/{prefix}expected.hex',409,expected)
            yield case


def controller_cases(root):
    """C0§8事件合同的手工期望账；不执行/读取RTL或复制C0状态机。"""
    p=15
    no_location=(False,15,0,0,0)
    for scenario in range(1,22):
        n=135+scenario;identity=ids(n)
        config={'epoch':2,'frame':n,'config':0x10000000+n,'width':6,'height':5,
                'tl':0,'th':64,'median':False,'retain':scenario!=9}
        # 非法尺寸/阈值本身也必须原样留在CS中，pack_cj的合法性检查不能替它消错。
        cj=pack_cj(config)
        if scenario==1:
            cj=(cj&~(((1<<33)-1)<<96))|(4<<96)|(3<<107)|(65<<118)
        counts=[0]*8;eof=0;strong=weak=0;reason=0;mask=0;flags=7;loc=no_location;fs=0
        if scenario==1:reason=2;mask=(1<<2)|(1<<3);flags=0
        elif scenario==2:reason=1;mask=2;flags=8
        elif scenario in (3,4,19,20):
            reason=1;mask=2|(16 if scenario==19 else 0);flags=15
            fs=pack_fs(1,identity,0,0)
        elif scenario==5:
            counts[0]=1;reason=5;mask=1<<5;loc=(True,1,0,0,0)
            fs=pack_fs(2,identity,1,0)
        elif scenario==6:
            counts[0]=p;reason=7;mask=1<<7;loc=(True,1,0,4,4)
            fs=pack_fs(4,identity,p,0,4,4)
        elif scenario in (7,9,14,15,18):
            counts=[p]*8
            if scenario==9:counts[7]=0
            eof=127 if scenario==9 else 255;strong=weak=p
            fs=pack_fs(0,identity,p,p)
        elif scenario==8:
            counts[0]=counts[1]=p;counts[6]=1;eof=3;strong=weak=1
            reason=1;mask=2;flags=15;fs=pack_fs(0,identity,p,p)
        elif scenario==10:
            counts[3:]=[1]*5;strong=weak=1;reason=11;mask=1<<11;loc=(True,5,0,0,0)
            fs=pack_fs(1,identity,0,0)
        elif scenario==11:
            counts[0]=counts[1]=p;eof=3;reason=15;mask=1<<15
            fs=pack_fs(0,identity,p,p)
        elif scenario==12:
            reason=10;mask=1<<10;fs=pack_fs(7,identity^1,1,1)
        elif scenario==13:
            counts[3]=1;reason=11;mask=1<<11;loc=(True,5,1,1,0)
            fs=pack_fs(1,identity,0,0)
        elif scenario==17:
            counts[1:]=[1]*7;strong=1;reason=12
            mask=(1<<12)|(1<<13)|(1<<14)|(1<<16);loc=(True,2,0,3,0)
            fs=pack_fs(1,identity,0,1)
        elif scenario==21:
            counts[2]=1;reason=13;mask=1<<13;loc=(True,3,0,2047,2047)
            fs=pack_fs(1,identity,0,0)
        golden=[]
        if scenario!=16:
            golden.append(pack_cs(cj,reason,mask,flags,loc,counts,eof,strong,weak,fs))
        recovery=config|{'frame':n+0x10000,'config':0x10000000+n+1,'retain':True}
        recovery_cj=pack_cj(recovery)
        golden.append(pack_cs(recovery_cj,0,0,7,no_location,[p]*8,255,p,p,
                              pack_fs(0,ids(n,True),p,p)))
        case_id=f'C0-C{scenario:02d}'
        yield {'case_id':case_id,'kind':'controller','width':6,'height':5,'scenario':scenario,
               'identity':f'{identity:024x}','recovery_identity':f'{ids(n,True):024x}',
               'expected_pairs':len(golden),'reset_aborted_jobs':int(scenario==16),
               'input':write_vector(root,f'{case_id}/input.hex',142,[cj,recovery_cj]),
               'expected':write_vector(root,f'{case_id}/expected.hex',592,golden)}


def complete_stream_vectors(root,prefix,config,mutation=0):
    """直接完整图黄金；故障仍写P行，硬件只比真正已交付的独立前缀。"""
    w,h=config['width'],config['height'];identity=config['epoch']|(config['frame']<<32)|(config['config']<<64)
    rgb=tuple(pattern_pixel(x,y,w,h,config['pattern']) for y in range(h) for x in range(w))
    image=stream_image(rgb,w,h,config['median'],config['retain'],config['tl'],config['th'])
    nw=nms_windows_image(image['m'],image['dir'],w,h)
    values={key:[] for key in ('fp','msrc','g8','sobel','direction','ninput','nwindow','class','grad')}
    for p in range(w*h//2):
        x=2*(p%(w//2));y=p//(w//2);m=side(x,y,w,h,identity)
        s=sum(gradient_lane(image['gx'][2*p+l],image['gy'][2*p+l],image['m'][2*p+l])<<(l*33) for l in range(2))
        d=s|sum(image['dir'][2*p+l]<<(66+l*2) for l in range(2))
        ng=sum((image['m'][2*p+l]|(image['dir'][2*p+l]<<11))<<(16*l) for l in range(2))
        window_pair=sum(v<<(l*144+i*16) for l in range(2) for i,v in enumerate(nw[2*p+l]))
        cl=sum(image['class'][2*p+l]<<(2*l) for l in range(2))
        grad=sum((signed11(image['gx'][2*p+l])|(signed11(image['gy'][2*p+l])<<11)
                  |(image['dir'][2*p+l]<<22))<<(32*l) for l in range(2))
        gm=m
        if p==4:
            if mutation in (1,2):gm=(gm&~2047)|(1 if mutation==1 else 2047)
            elif mutation==3:gm=(gm&~(2047<<11))|(2047<<11)
            elif mutation==4:gm^=1<<120
            elif mutation==5:gm^=1<<119
            elif mutation==6:gm^=1<<22
        values['fp'].append(fp_pair(x,y,config))
        values['msrc'].append(image['msrc'][2*p]|(image['msrc'][2*p+1]<<8)|(m<<16))
        values['g8'].append(image['g8'][2*p]|(image['g8'][2*p+1]<<8)|(gm<<16))
        for key,bits,data in (('sobel',66,s),('direction',70,d),('ninput',32,ng),('nwindow',288,window_pair),
                              ('class',4,cl),('grad',64,grad)):
            values[key].append(data|(m<<bits))
    widths={'fp':74,'msrc':137,'g8':137,'sobel':187,'direction':191,'ninput':153,'nwindow':409,'class':125,'grad':185}
    return {key:write_vector(root,f'{prefix}/{key}.hex',widths[key],rows)
            for key,rows in values.items() if key!='grad' or config['retain']}


def metadata_cases(root):
    for mutation in range(1,7):
        for schedule in range(1,5):
            index=(mutation-1)*4+schedule;n=156+index;case_id=f'MD{index:03d}'
            config={'epoch':2,'frame':n,'config':0x10000000+n,'width':8,'height':5,
                    'tl':0,'th':64,'median':bool(index&1),'retain':True,'pattern':0,'fault':False}
            recovery=config|{'frame':n+0x10000,'config':0x10000000+n+1,'median':not config['median']}
            a=complete_stream_vectors(root,f'{case_id}/primary',config,mutation)
            b=complete_stream_vectors(root,f'{case_id}/recovery',recovery)
            yield {'case_id':case_id,'kind':'stream_top','width':8,'height':5,'mutation':mutation,'schedule':schedule,
                'identity':f'{ids(n):024x}','recovery_identity':f'{ids(n,True):024x}',
                'expected_pairs':20,'terminal_policy':'RESET_ABORTED' if schedule==4 else 'METADATA_FAILED',
                'input':write_vector(root,f'{case_id}/input.hex',142,[pack_cj(config),pack_cj(recovery)]),
                **{'primary_'+key:value for key,value in a.items()},**{'recovery_'+key:value for key,value in b.items()}}


def audit_top(result_path,manifest_path,case_id):
    """由外部输入及真实沿前端口账建立CS黄金，完全不取DUT的CS原因/计数作为期望。"""
    manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
    case=next(c for c in manifest['cases'] if c['case_id']==case_id)
    result=json.loads(result_path.read_text(encoding='utf-8'))
    if case['kind']!='stream_top' or result['case_id']!=case_id or not result['finished'] or result['status']!='PASS':
        raise ValueError('top result identity/terminal missing')
    if result['width']!=case['width'] or result['height']!=case['height'] or len(result['jobs'])!=2:
        raise ValueError('top result geometry/job count')
    cj_words=[int(v,16) for v in (manifest_path.parent/case['input']['path']).read_text().splitlines()]
    checks=[];p=case['width']*case['height']//2
    for index,job in enumerate(result['jobs']):
        if job['reset_aborted']:
            if index!=0 or case['schedule']!=4 or job['cs_hex'] is not None or job['fs_hex'] is not None:
                raise ValueError('reset policy violated')
            checks.append({'job':index,'status':'ABORTED_RESET','cs_checks':0});continue
        counts=job['accepted_counts'];eof=job['eof'];strong=job['strong'];weak=job['weak']
        if len(counts)!=8 or any(type(v) is not int or not 0<=v<=p for v in counts):raise ValueError('prefix range')
        if counts!=job['compared_counts'] or job['nwindow_compared']>p:raise ValueError('uncompared actual data')
        fs=int(job['fs_hex'],16);identity=cj_words[index]&((1<<96)-1)
        if (fs>>3)&((1<<96)-1)!=identity or (fs>>99)&((1<<21)-1)!=counts[0] \
            or (fs>>120)&((1<<21)-1)!=counts[1] or fs&7 not in (0,1):raise ValueError('real FS differs from observed FE prefix')
        flags=7|(8 if index==0 and case['schedule']==3 else 0)
        reason=0;mask=0;location=(False,15,0,0,0)
        if index==0:
            if case['schedule']==2 and job['ready_stall_cycles']!=8:raise ValueError('MD exact8 ready phase missing')
            if job['mutated_fires']!=1 or counts[2]!=5:raise ValueError('required raw mutation did not fire once')
            reason=13 if case['mutation']<=3 else (14 if case['mutation']<=5 else 12)
            mask=1<<reason
            x,y=0,1
            if case['mutation']==1:x=1
            elif case['mutation']==2:x=2047
            elif case['mutation']==3:y=2047
            location=(True,3,0,x,y)
            if case['schedule']==3:reason=1;mask|=2;location=(False,15,0,0,0)
            if fs&7==1 and not job['cancel_sent_before_fs']:mask|=16
        else:
            if counts!=[p]*8 or eof!=255 or job['nwindow_compared']!=p or fs&7!=0:
                raise ValueError('recovery did not complete the real chain')
        expected=pack_cs(cj_words[index],reason,mask,flags,location,counts,eof,strong,weak,fs)
        if int(job['cs_hex'],16)!=expected:raise ValueError('CS592 differs from independent event policy')
        checks.append({'job':index,'status':'PASS','cs_checks':592,'expected_cs_hex':f'{expected:0148x}'})
    audit={'schema_version':1,'case_id':case_id,'status':'PASS','rtl_used_for_expected_cs':False,
           'result_sha256':digest(result_path),'manifest_sha256':digest(manifest_path),'jobs':checks}
    path=result_path.with_name('protocol-audit.json')
    with path.open('x',encoding='utf-8',newline='\n') as f:f.write(json.dumps(audit,indent=2)+'\n')
    return audit


def source_cases(root):
    for pattern in range(4):
        config=job_config(pattern*4,258,258);case_id=f'SRC{pattern+1:03d}'
        yield {'case_id':case_id,'kind':'source','width':258,'height':258,'k':pattern*4,
            'identity':f'{1|((pattern*4)<<32)|((pattern*4)<<64):024x}','expected_pairs':33282,
            'input':write_vector(root,f'{case_id}/input.hex',142,[pack_cj(config)]),
            'expected':write_vector(root,f'{case_id}/expected.hex',74,
                (fp_pair(x,y,config) for y in range(258) for x in range(0,258,2)))}


def algorithm_top_cases(root):
    # TOP-S128正常/故障和reset warmup复用同一批独立数学黄金，不复制DUT数据。
    files={}
    for k in range(128):
        config=job_config(k,6,5)
        for key,value in complete_stream_vectors(root,f'TOP-S001/job{k:03d}',config).items():
            files[f'job{k:03d}_{key}']=value
    yield {'case_id':'TOP-S001','kind':'algorithm_top','width':6,'height':5,
        'expected_pairs':128,'expected_completed_jobs':128,'expected_warmup_jobs':5,
        'input':write_vector(root,'TOP-S001/input.hex',142,[pack_cj(job_config(k,6,5)) for k in range(128)]),**files}


def observer_fixture_files(root,prefix,config,mutation=0):
    """Typed组件固定原payload，不声称来自算法图；错只改声明字段。"""
    identity=config['epoch']|(config['frame']<<32)|(config['config']<<64)
    class_rows=[];grad_rows=[]
    for p in range(16 if mutation==7 else 15):
        position=min(p,14);x=2*(position%3);y=position//3
        meta=side(x,y,6,5,identity);cl=6
        if p==4:
            if mutation==1:cl=14
            elif mutation==4:meta^=1<<22
            elif mutation==5:meta=(meta&~2047)|1
            elif mutation==6:meta^=1<<119
        class_rows.append(cl|(meta<<4))
    for p in range(15):
        x,y=2*(p%3),p//3
        pair=(signed11(128+p)|(signed11(53)<<11)) \
            |((signed11(-53)|(signed11(128+p)<<11)|(2<<22))<<32)
        if p==4:
            if mutation==2:pair|=1<<24
            elif mutation==3:pair=(pair&~2047)|signed11(1021)
        grad_rows.append(pair|(side(x,y,6,5,identity)<<64))
    files={'class':write_vector(root,f'{prefix}/class.hex',125,class_rows)}
    if config['retain']:files['grad']=write_vector(root,f'{prefix}/grad.hex',185,grad_rows)
    return files


def observer_cases(root):
    for family,limit in (('B',14),('R',24)):
        for scenario in range(1,limit+1):
            case_id=f'OBS-{family}{scenario:03d}';files={}
            for k in range(3):
                for key,value in observer_fixture_files(root,f'{case_id}/warmup{k}',job_config(k,6,5)).items():
                    files[f'warmup{k}_{key}']=value
            primary_k=0xffffffff if family=='R' and scenario==24 else 3
            for key,value in observer_fixture_files(root,f'{case_id}/primary',job_config(primary_k,6,5),
                    scenario if family=='B' and scenario<=7 else 0).items():files['primary_'+key]=value
            for key,value in observer_fixture_files(root,f'{case_id}/recovery',job_config(0,6,5)).items():files['recovery_'+key]=value
            yield {'case_id':case_id,'kind':'observer','width':6,'height':5,'family':family,'scenario':scenario,
                'primary_k':primary_k,'identity':f'{1|(primary_k<<32)|(primary_k<<64):024x}',
                'expected_pairs':4 if family=='R' and scenario<=23 else 5,
                'terminal_policy':'RESET_ABORTED' if family=='R' and scenario<=23 else 'TYPED_FIXTURE',
                'input':write_vector(root,f'{case_id}/input.hex',142,[pack_cj(job_config(k,6,5)) for k in (0,1,2,3,0xffffffff)]),**files}


def audit_observer(result_path,manifest_path,case_id):
    """独立组件事件政策及逐bitCRC，不复制K移位/仲裁/J状态机。"""
    result=json.loads(result_path.read_text(encoding='utf-8'))
    manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
    case=next(c for c in manifest['cases'] if c['case_id']==case_id)
    if result['case_id']!=case_id or result['status']!='PASS' or not result['finished']:
        raise ValueError('observer result did not finish')
    if len(result['warmup_jobs'])!=3 or result['required_event_hits']!=1 or len(result['recovery_jobs'])!=1:
        raise ValueError('observer warmup/phase/recovery missing')
    is_reset=case['family']=='R' and case['scenario']<=23
    if is_reset:
        if result['primary_job'] is not None or result['reset_aborted_jobs']!=1:raise ValueError('reset produced old terminal')
        expected_phase=case['scenario']-2 if 2<=case['scenario']<=20 else None
        if expected_phase is not None and result['reset_chunk']!=expected_phase:raise ValueError('wrong CRC reset phase')
    elif result['primary_job'] is None:raise ValueError('primary terminal missing')
    checks=[]
    all_jobs=[('warmup',j) for j in result['warmup_jobs']]
    if result['primary_job'] is not None:all_jobs.append(('primary',result['primary_job']))
    all_jobs += [('recovery',j) for j in result['recovery_jobs']]
    for group,job in all_jobs:
        config=job_config(job['k'],6,5)
        records_path=(result_path.parent/job['records_path']).resolve()
        if not records_path.is_relative_to(result_path.parent.resolve()):raise ValueError('observer record path escaped')
        raw=records_path.read_text(encoding='ascii').splitlines()
        if any(re.fullmatch('[0-9a-f]{152}',line) is None for line in raw):raise ValueError('observer record format')
        records=[int(line,16) for line in raw];classes=[v>>2 for v in records if v&3==0];grads=[v>>2 for v in records if v&3==1]
        if len(records)!=len(classes)+len(grads)+1 or records[-1]&3!=2:raise ValueError('typed terminal missing/duplicated')
        strong=sum((cl>>(2*l))&3==2 for cl in classes for l in range(2))
        weak=sum((cl>>(2*l))&3==1 for cl in classes for l in range(2))
        ce=any(bool((v>>124)&1) for v in classes);ge=any(bool((v>>184)&1) for v in grads)
        if (len(classes),len(grads),strong,weak)!=(job['class_count'],job['grad_count'],job['strong'],job['weak']):
            raise ValueError('K87 does not equal independent actual typed ledger')
        source_count=job['source_count'];identity=1|(config['frame']<<32)|(config['config']<<64)
        counts=[15]*6+[len(classes),len(grads)];eof=63|(64 if ce else 0)|(128 if ge else 0)
        reason=0;mask=0;flags=7;location=(False,15,0,0,0);fs=pack_fs(0,identity,15,15)
        mutation=case['scenario'] if group=='primary' and case['family']=='B' else 0
        if mutation in range(1,8):
            branch_count=len(grads) if mutation in (2,3) else len(classes)
            if branch_count!=(16 if mutation==7 else 5):raise ValueError('declared bad typed candidate did not fire at exact position')
            if (len(classes)!=0 if mutation in (2,3) else len(grads)!=0):raise ValueError('unexpected other branch fixture')
            reason=1;mask=2;flags=15
            fs=pack_fs(1,identity,15,15)
        if mutation==13 or group=='primary' and case['family']=='R' and case['scenario']==24:
            counts=[8,0,0,0,0,0,0,0];eof=0;reason=5;mask=32;location=(True,1,0,2,2);fs=pack_fs(2,identity,8,0,2,2)
        if source_count!=(8 if reason==5 else 15):raise ValueError('J source count differs from typed source events')
        cj=pack_cj(config)
        if mutation==8:cj^=1<<32
        if mutation==9:counts[2]-=1
        expected_cs=pack_cs(cj,reason,mask,flags,location,counts,eof,strong,weak,fs)
        if int(job['cs_hex'],16)!=expected_cs or int(job['last_cs_hex'],16)!=expected_cs or records[-1]!=(2|(expected_cs<<2)):
            raise ValueError('unchanged original component CS592 was not preserved')
        protocol_ok=mutation not in range(1,8)
        before_ledger={'class_count':len(classes),'grad_count':len(grads),'class_eof':ce,'grad_eof':ge,
            'strong':strong,'weak':weak,'protocol_ok':protocol_ok}
        expected_flags=terminal_flags(expected_cs,config,source_count,job['source_last'],before_ledger,job['owner_drain'])
        if job['candidate_fixture_match']!=expected_flags['fixture_match'] or job['candidate_complete_ok']!=expected_flags['complete_ok']:
            raise ValueError('J used wrong or previous terminal candidate flags')
        if mutation==10:expected_flags={'fixture_match':False,'complete_ok':False};protocol_ok=False
        if job['fixture_match']!=expected_flags['fixture_match'] or job['complete_ok']!=expected_flags['complete_ok'] \
            or job['record_protocol_ok']!=protocol_ok:raise ValueError('K final flags/coexistence masking wrong')
        expected_crc=crc_records(records)
        if int(job['crc_hex'],16)!=expected_crc:raise ValueError('observer CRC omitted or reordered actual608 bits')
        if mutation==14 and job['status_hold_cycles']!=8:raise ValueError('CS exact8 hold missing')
        if mutation==12 and job['fairness_checks']<29:raise ValueError('both continuous branches were not fairly serviced')
        if job['min_capture_interval']<20:raise ValueError('capture occurred on old final chunk')
        checks.append({'group':group,'k':job['k'],'records':len(records),'records_sha256':digest(records_path),
            'cs_bits_checked':592,'crc_expected':f'{expected_crc:08x}',**expected_flags})
    audit={'schema_version':1,'case_id':case_id,'status':'PASS','completed_jobs':len(checks),
        'reset_aborted_jobs':int(is_reset),'result_sha256':digest(result_path),'manifest_sha256':digest(manifest_path),'jobs':checks}
    with result_path.with_name('protocol-audit.json').open('x',encoding='utf-8',newline='\n') as f:f.write(json.dumps(audit,indent=2)+'\n')
    return {key:value for key,value in audit.items() if key!='jobs'}


def audit_algorithm_top(result_path,manifest_path,case_id):
    result=json.loads(result_path.read_text(encoding='utf-8'))
    manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
    case=next(c for c in manifest['cases'] if c['case_id']==case_id)
    if result['case_id']!=case_id or result['status']!='PASS' or not result['finished']:
        raise ValueError('algorithm top did not finish')
    if len(result['jobs'])!=128 or len(result['warmup_jobs'])!=5 or result['reset_k']!=5 \
        or result['key_low_cycles']<4 or not 0<=result['reset_chunk']<=18:
        raise ValueError('TOP-S full sequence/reset missing')
    checks=[]
    for group in ('warmup_jobs','jobs'):
        for k,job in enumerate(result[group]):
            if job['k']!=k:raise ValueError('J reused/skipped/wrapped identity')
            config=job_config(k,6,5);counts=job['accepted_counts'];p=15
            if counts!=job['compared_counts'] or len(counts)!=8 or any(not 0<=v<=p for v in counts):
                raise ValueError('top actual prefixes were not numerically compared')
            if not config['fault']:
                required=[p]*7+[p if config['retain'] else 0]
                if counts!=required or job['eof']!=(255 if config['retain'] else 127) or job['nwindow_compared']!=p:
                    raise ValueError('short normal TOP job')
            fs=int(job['fs_hex'],16);identity=1|(k<<32)|(k<<64)
            if fs>>3&((1<<96)-1)!=identity or fs>>99&((1<<21)-1)!=counts[0] or fs>>120&((1<<21)-1)!=counts[1]:
                raise ValueError('real FE status differs from independent topology ledger')
            reason,mask,location=(5,32,(True,1,0,2,2)) if config['fault'] else (0,0,(False,15,0,0,0))
            expected_cs=pack_cs(pack_cj(config),reason,mask,7,location,counts,job['eof'],job['strong'],job['weak'],fs)
            if int(job['cs_hex'],16)!=expected_cs or int(job['last_cs_hex'],16)!=expected_cs:
                raise ValueError('C0 or K last snapshot differs from CS592 policy')
            ledger={'class_count':job['record_class'],'grad_count':job['record_grad'],
                'class_eof':bool(job['eof']&64),'grad_eof':bool(job['eof']&128),
                'strong':job['strong'],'weak':job['weak'],'protocol_ok':job['record_protocol_ok']}
            expected_flags=terminal_flags(expected_cs,config,counts[0],bool(job['eof']&1),ledger,job['owner_drain'])
            if not expected_flags['fixture_match'] or job['fixture_match']!=expected_flags['fixture_match'] \
                or job['complete_ok']!=expected_flags['complete_ok'] or job['led0']!=expected_flags['complete_ok']:
                raise ValueError('J/K flags or LED0 differ from independent terminal rules')
            records_path=result_path.parent/job['records_path']
            if not records_path.resolve().is_relative_to(result_path.parent.resolve()):raise ValueError('record path escaped')
            raw=records_path.read_text(encoding='ascii').splitlines()
            if any(re.fullmatch('[0-9a-f]{152}',line) is None for line in raw):raise ValueError('actual608 format')
            records=[int(line,16) for line in raw]
            if len(records)!=counts[6]+counts[7]+1 or records[-1]!=(2|(expected_cs<<2)):
                raise ValueError('record order/terminal payload missing')
            if sum((v&3)==0 for v in records)!=counts[6] or sum((v&3)==1 for v in records)!=counts[7]:
                raise ValueError('typed data record accounting')
            expected_crc=crc_records(records)
            if int(job['crc_hex'],16)!=expected_crc:raise ValueError('last CRC differs from per-bit608 oracle')
            checks.append({'group':group,'k':k,'records_sha256':digest(records_path),
                           'records':len(records),'cs_bits_checked':592,'crc_expected':f'{expected_crc:08x}',**expected_flags})
    audit={'schema_version':1,'case_id':case_id,'status':'PASS','completed_jobs':128,
        'warmup_jobs':5,'normal_jobs':64,'fault_jobs':64,'reset_aborted_jobs':1,
        'result_sha256':digest(result_path),'manifest_sha256':digest(manifest_path),'jobs':checks}
    with result_path.with_name('protocol-audit.json').open('x',encoding='utf-8',newline='\n') as f:
        f.write(json.dumps(audit,indent=2)+'\n')
    return {key:value for key,value in audit.items() if key!='jobs'}


def generate(root,suite='r2-stream-v1'):
    if root.exists():
        raise ValueError('output directory must be new')
    root.mkdir(parents=True)
    if suite=='r2-stream-v1':
        required=REQUIRED_STREAM
        cases=(list(gaussian_cases(root))+list(direction_cases(root))+list(fork_cases(root))
               +list(nms_window_cases(root))+list(classify_cases(root))+list(controller_cases(root))+list(metadata_cases(root)))
    elif suite=='r2-observer-v1':
        required=REQUIRED_OBSERVER;cases=list(observer_cases(root))+list(source_cases(root))+list(algorithm_top_cases(root))
    else:raise ValueError('unknown suite')
    for case in cases:
        for value in case.values():
            if isinstance(value,dict) and 'sha256' in value:
                validate_vector(root,value)
    actual=[c['case_id'] for c in cases]
    manifest={'schema_version':1,'suite':suite,'status':'COMPLETE',
        'scope_status':'PARTIAL_IMPLEMENTATION','required_case_ids':required,
        'generated_case_ids':actual,'not_generated_case_ids':[i for i in required if i not in actual],
        'rtl_used_for_reference_generation':False,'self_check':self_check(),'observer_self_check':observer_self_check(),'cases':cases}
    (root/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return manifest


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--out-dir',type=Path)
    parser.add_argument('--self-check',action='store_true')
    parser.add_argument('--audit-top',type=Path)
    parser.add_argument('--audit-algorithm-top',type=Path)
    parser.add_argument('--audit-observer',type=Path)
    parser.add_argument('--probe-inputs',type=Path)
    parser.add_argument('--manifest',type=Path)
    parser.add_argument('--case-id')
    parser.add_argument('--suite',choices=('r2-stream-v1','r2-observer-v1'),default='r2-stream-v1')
    args=parser.parse_args()
    if args.probe_inputs:
        print(json.dumps(probe_inputs(args.probe_inputs)))
    elif args.audit_observer:
        if not args.manifest or not args.case_id:parser.error('--manifest and --case-id required')
        print(json.dumps(audit_observer(args.audit_observer,args.manifest,args.case_id)))
    elif args.audit_algorithm_top:
        if not args.manifest or not args.case_id:parser.error('--manifest and --case-id required')
        print(json.dumps(audit_algorithm_top(args.audit_algorithm_top,args.manifest,args.case_id)))
    elif args.audit_top:
        if not args.manifest or not args.case_id:parser.error('--manifest and --case-id required')
        print(json.dumps(audit_top(args.audit_top,args.manifest,args.case_id)))
    elif args.self_check:
        print(json.dumps(self_check()))
    elif args.out_dir:
        m=generate(args.out_dir,args.suite)
        print(json.dumps({'status':m['status'],'scope_status':m['scope_status'],
                          'generated':len(m['cases']),'required':len(m['required_case_ids'])}))
    else:
        parser.error('--out-dir or --self-check required')
