"""R2严格向量及有限场景清单；当前已实现家庭之外明确列为未生成。

COMPLETE表示本次文件写出/预审完成，不表示230场景已实现或仿真通过。
完整套件交付前必须覆盖required_case_ids；诊断筛选永远标PARTIAL。
"""
from __future__ import annotations
import argparse, hashlib, itertools, json, re, random
from pathlib import Path
from canny_stream_reference import gradient_direction, classify_window, gaussian_image, nms_windows_image, stream_image, self_check
from r2_observer_reference import pack_cj, pack_fs, pack_cs, pattern_pixel, fp_pair, job_config, self_check as observer_self_check

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


def generate(root,suite='r2-stream-v1'):
    if root.exists():
        raise ValueError('output directory must be new')
    root.mkdir(parents=True)
    if suite=='r2-stream-v1':
        required=REQUIRED_STREAM
        cases=(list(gaussian_cases(root))+list(direction_cases(root))+list(fork_cases(root))
               +list(nms_window_cases(root))+list(classify_cases(root))+list(controller_cases(root))+list(metadata_cases(root)))
    elif suite=='r2-observer-v1':required=REQUIRED_OBSERVER;cases=list(source_cases(root))
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
    parser.add_argument('--manifest',type=Path)
    parser.add_argument('--case-id')
    parser.add_argument('--suite',choices=('r2-stream-v1','r2-observer-v1'),default='r2-stream-v1')
    args=parser.parse_args()
    if args.audit_top:
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
