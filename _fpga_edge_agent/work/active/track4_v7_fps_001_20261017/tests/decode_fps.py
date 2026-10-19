"""Decode one Efinity LA capture (1 segment, 1024 samples) from FPS-001 only.

VCD timestamps exported by this debugger are SAMPLE INDICES, not clock periods.
Camera rate is calculated exclusively from the measured 50 MHz cycle counter.
"""
from pathlib import Path
import argparse, datetime, hashlib, json, re

def decode(path, simulation=False):
    text=Path(path).read_text(encoding='utf-8-sig')
    header,body=text.split('$enddefinitions $end',1)
    vars={name:(code,int(width)) for width,code,name in re.findall(r'\$var\s+\S+\s+(\d+)\s+(\S+)\s+(\S+)\s+\$end',header)}
    wanted={'ch0_g':8,'ch0_b':8,'ch0_de':1,'cal_done':1}
    for name,width in wanted.items():
        if name not in vars or vars[name][1]!=width:raise ValueError('Unexpected FPS probe contract: '+name)
    codes={v[0]:n for n,v in vars.items() if n in wanted}
    events={};t=0;tokens=iter(body.split());last_time=0
    for token in tokens:
        if token.startswith('#'):
            t=int(token[1:])
            if t<last_time or t>1023:raise ValueError('Expected one segment of 1024 sample indices; do not use segmented capture')
            last_time=t;events.setdefault(t,{})
        elif token[0:1].lower()=='b':
            code=next(tokens);value=token[1:]
            if code in codes:events.setdefault(t,{})[codes[code]]=None if re.search('[xz]',value,re.I) else int(value,2)
        elif token[0:1] in '01xXzZ' and len(token)>1:
            if token[1:] in codes:events.setdefault(t,{})[codes[token[1:]]]=None if token[0] not in '01' else int(token[0])
    state={n:None for n in wanted};samples=[]
    for t in range(last_time+1):
        state.update(events.get(t,{}));samples.append(dict(state))
    packets=[];bad=[]
    for i in range(len(samples)-15):
        x=samples[i]
        if x['ch0_de']!=1 or x['ch0_g']!=0x5a or x['ch0_b']!=0xa5:continue
        seq=samples[i:i+16]
        if any(s[n] is None for s in seq for n in wanted):bad.append(i);continue
        words=[s['ch0_g']|(s['ch0_b']<<8) for s in seq]
        checksum=0
        for w in words[:14]:checksum^=w
        if words[1]!=1 or words[14]!=checksum or words[15]!=0x5aa5 or any(s['ch0_de'] for s in seq[1:]) or any(s['cal_done']!=(words[11]&1) for s in seq):
            bad.append(i);continue
        flags=words[11];period=words[4]|words[5]<<16
        packets.append(dict(sample_index=i,sequence=words[2]|words[3]<<16,period_cycles=period,
            accepted_words=words[6]|words[7]<<16,pixels=(words[6]|words[7]<<16)*4,
            lines=words[8],min_line_pixels=words[9]*4,max_line_pixels=words[10]*4,
            flags=flags,camera_frame_valid=(flags==1),ready=bool(flags&1),stale=bool(flags&2),overflow=bool(flags&4),
            geometry_mismatch=bool(flags&8),boundary_error=bool(flags&16),
            age_cycles=words[12]|words[13]<<16,
            fps=50000000/period if period and flags&1 and not flags&22 else None))
    if bad:raise ValueError('Corrupted/misaligned telemetry packets at sample indices '+str(bad[:10]))
    if len(packets)<2:raise ValueError('Fewer than two valid FPS-001 packets; check bit/profile, capture length and Run Immediate')
    measurements=[];seen=set()
    for p in packets:
        key=(p['sequence'],p['period_cycles'],p['pixels'],p['lines'],p['flags'])
        if key not in seen:seen.add(key);measurements.append(p)
    return dict(source='synthetic_simulation' if simulation else 'user_saved_debugger_capture',
        path=str(Path(path).resolve()),sha256=hashlib.sha256(Path(path).read_bytes()).hexdigest(),
        timestamp=datetime.datetime.now().astimezone().isoformat(),reference_clock_hz=50000000,
        clock_accuracy='nominal configured clock; no external frequency-counter calibration',
        valid_packets=len(packets),measurements=measurements,
        note='Repeated sequence in a short capture is expected; separate captures seconds apart establish ongoing input frames')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('vcd');p.add_argument('--simulation',action='store_true');p.add_argument('--output')
    args=p.parse_args();result=decode(args.vcd,args.simulation);data=json.dumps(result,ensure_ascii=False,indent=2)
    if args.output:
        with Path(args.output).open('x',encoding='utf-8') as f:f.write(data+'\n')
    print(data)
