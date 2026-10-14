"""R2 OBS独立值/协议参考：图样、完整位序、逐bit608 CRC、终态合同。

不模拟19拍CRC移位器，不从DUT最终CRC倒推期望；输入record次序必须来自真实fire。
终态检查读取原CS判合同，不篡改它，不作为CS592逐位黄金的替代。
"""
from __future__ import annotations
from canny_stream_reference import integer, dimensions


def job_config(k,width=1920,height=1080):
    integer(k,0,0xffffffff,'k');dimensions(width,height)
    tl,th=((0,64),(64,512),(512,1530),(1530,2047))[(k>>4)&3]
    return {'epoch':1,'frame':k,'config':k,'width':width,'height':height,
            'median':bool(k&1),'retain':bool(k&2),'pattern':(k>>2)&3,
            'tl':tl,'th':th,'fault':bool(k&64)}


def pack_cj(config):
    dimensions(config['width'],config['height'])
    value=0
    for name,offset,bits in (('epoch',0,32),('frame',32,32),('config',64,32),
        ('width',96,11),('height',107,11),('tl',118,11),('th',129,11)):
        value|=integer(config[name],0,(1<<bits)-1,name)<<offset
    integer(config['th'],config['tl'],2047,'TH')
    for name,offset in (('median',140),('retain',141)):
        if type(config[name]) is not bool:raise ValueError('bool configuration required')
        value|=int(config[name])<<offset
    return value


def pattern_pixel(x,y,width,height,pattern):
    dimensions(width,height);integer(x,0,width-1,'x');integer(y,0,height-1,'y')
    integer(pattern,0,3,'pattern')
    if pattern==0:return x%256,y%256,(x^y)%256
    if pattern==1:value=255 if x>=width//2 else 0
    elif pattern==2:value=255 if y>=height//2 else 0
    else:value=239 if bool(x&32)!=bool(y&32) else 16
    return value,value,value


def fp_pair(x,y,config):
    width,height=config['width'],config['height']
    integer(x,0,width-2,'even x')
    if x%2:raise ValueError('even x required')
    value=0
    for lane in range(2):
        r,g,b=pattern_pixel(x+lane,y,width,height,config['pattern'])
        value|=(r|(g<<8)|(b<<16))<<(lane*24)
    value|=x<<48|y<<59
    value|=int(x==0 and y==0)<<70|int(x==width-2)<<71
    value|=int(x==width-2 and y==height-1)<<72
    value|=int(config['fault'] and y==height//2 and x==2)<<73
    return value


def typed_record(kind,payload):
    bits=(125,185,592)
    integer(kind,0,2,'record type')
    integer(payload,0,(1<<bits[kind])-1,'payload')
    return kind|(payload<<2)


def crc_records(records):
    crc=0xffffffff
    count=0
    for record in records:
        integer(record,0,(1<<608)-1,'record608')
        for position in range(607,-1,-1):
            feedback=((crc>>31)^((record>>position)&1))&1
            crc=(crc<<1)&0xffffffff
            if feedback:crc^=0x04c11db7
        count+=1
    if not count:raise ValueError('terminal record stream cannot be empty')
    return crc^0xffffffff


def pack_fs(code,identity,input_pairs,output_pairs,error_x=0,error_y=0):
    return (integer(code,0,7,'FS code') | (integer(identity,0,(1<<96)-1,'IDs')<<3)
        | (integer(input_pairs,0,(1<<21)-1,'FS in')<<99)
        | (integer(output_pairs,0,(1<<21)-1,'FS out')<<120)
        | (integer(error_x,0,2047,'FS x')<<141)|(integer(error_y,0,2047,'FS y')<<152))


def pack_cs(cj,reason,mask,flags,location,counts,eof,strong,weak,fs):
    integer(cj,0,(1<<142)-1,'CJ');integer(reason,0,18,'reason')
    integer(mask,0,(1<<19)-1,'mask')
    if mask&1:raise ValueError('reserved mask bit0')
    integer(flags,0,15,'facts');integer(eof,0,255,'EOF')
    if len(counts)!=8:raise ValueError('eight independent counts required')
    valid,stage,lane,x,y=location
    if type(valid) is not bool:raise ValueError('loc_valid bool required')
    integer(stage,0,15,'stage');integer(lane,0,1,'lane')
    integer(x,0,2047,'raw x');integer(y,0,2047,'raw y')
    if not valid and (stage,lane,x,y)!=(15,0,0,0):raise ValueError('canonical no-location required')
    loc=int(valid)|(stage<<1)|(lane<<5)|(x<<6)|(y<<17)
    packed_counts=sum(integer(value,0,(1<<21)-1,'count')<<(21*i) for i,value in enumerate(counts))
    return (cj|(reason<<142)|(mask<<147)|(flags<<179)|(loc<<183)|(packed_counts<<211)
        |(eof<<379)|(integer(strong,0,(1<<21)-1,'strong')<<387)
        |(integer(weak,0,(1<<21)-1,'weak')<<408)|(integer(fs,0,(1<<163)-1,'FS')<<429))


def decode_cs(value):
    integer(value,0,(1<<592)-1,'CS592')
    fs=(value>>429)&((1<<163)-1)
    return {'cj':value&((1<<142)-1),'reason':(value>>142)&31,'mask':(value>>147)&0xffffffff,
        'flags':(value>>179)&15,'loc_valid':bool((value>>183)&1),'stage':(value>>184)&15,
        'lane':(value>>188)&1,'x':(value>>189)&2047,'y':(value>>200)&2047,
        'counts':tuple((value>>(211+21*i))&((1<<21)-1) for i in range(8)),
        'eof':(value>>379)&255,'strong':(value>>387)&((1<<21)-1),
        'weak':(value>>408)&((1<<21)-1),'fs':fs,'fs_code':fs&7,
        'fs_ids':(fs>>3)&((1<<96)-1),'fs_in':(fs>>99)&((1<<21)-1),
        'fs_out':(fs>>120)&((1<<21)-1),'fs_x':(fs>>141)&2047,'fs_y':(fs>>152)&2047}


def terminal_flags(cs,config,source_count,source_last,ledger,owner_drain):
    """ledger来自CLASS/GRAD真实fire独立账；没有声称独立测量内部其它六口。"""
    d=decode_cs(cs);counts=d['counts'];retain=config['retain']
    p=config['width']*config['height']//2
    identity=config['epoch']|(config['frame']<<32)|(config['config']<<64)
    common=(d['cj']==pack_cj(config) and d['flags']==7 and d['fs_ids']==identity
        and ledger['protocol_ok'] and ledger['class_count']==counts[6] and ledger['grad_count']==counts[7]
        and ledger['class_eof']==bool(d['eof']&64) and ledger['grad_eof']==bool(d['eof']&128)
        and ledger['strong']==d['strong'] and ledger['weak']==d['weak']
        and d['strong']+d['weak']<=2*counts[6]
        and (retain or counts[7]==0 and not(d['eof']&128)))
    complete=(common and d['reason']==0 and d['mask']==0 and not d['loc_valid']
        and (d['stage'],d['lane'],d['x'],d['y'])==(15,0,0,0)
        and d['fs_code']==0 and d['fs_in']==p and d['fs_out']==p and d['fs_x']==0 and d['fs_y']==0
        and counts[:7]==(p,)*7 and counts[7]==(p if retain else 0)
        and d['eof']==(255 if retain else 127) and source_count==p and source_last and owner_drain)
    fault_count=(config['height']//2)*(config['width']//2)+2
    fault=(common and d['reason']==5 and d['mask']==32 and d['loc_valid']
        and (d['stage'],d['lane'],d['x'],d['y'])==(1,0,2,config['height']//2)
        and d['fs_code']==2 and d['fs_x']==2 and d['fs_y']==config['height']//2
        and counts[0]==source_count==d['fs_in']==fault_count
        and counts[1]==d['fs_out'] and counts[1]<=counts[0]-1
        and counts[6]<=counts[5]<=counts[4]<=counts[3]<=counts[2]<=counts[1]
        and counts[7]<=counts[4] and d['eof']==0)
    return {'complete_ok':bool(complete),'fixture_match':bool(fault if config['fault'] else complete)}
