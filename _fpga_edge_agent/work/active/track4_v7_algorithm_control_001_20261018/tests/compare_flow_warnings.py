from pathlib import Path
from collections import Counter
import json,re,hashlib
w=Path(__file__).resolve().parents[1];root=w.parents[2]
r=root/'reports/TRACK4-V7-ALGORITHM-CONTROL-001';old=root/'work/active/track4_v7_algorithm_bridge_001_20261018'
read=lambda p:p.read_text(encoding='utf-8-sig',errors='replace')
def flow(folder):
    c=Counter()
    # Cell IDs change across synthesis. Resolve every loop cell to its actual source,
    # LUT function and pin-equality graph, not just a stripped numeric name.
    netlist=read(folder/'outflow/ti60f225_oob.map.v')
    cells={}
    for found in re.finditer(r'(EFX_LUT4\s+(i\d+)\s+\([^;]*;[^\n]*)',netlist):
        cells[found[2]]=found[1]
    loop_map={}
    for filename in ['ti60f225_oob.place.out','ti60f225_oob.route.out']:
        for line in read(folder/'outflow'/filename).splitlines():
            if re.match(r'^\s*(WARNING|ERROR)\b',line):
                line=re.sub(r'\[SDC .*?ti60f225_oob.sdc:', '[SDC PROJECT/ti60f225_oob.sdc:',line.strip())
                if 'CombinationalLoopDetected' in line:
                    cell=re.search(r'from (i\d+):',line)[1];cell_line=cells[cell]
                    source=re.search(r'[/\\](rtl[/\\].*?)\((\d+)\)',cell_line)
                    assert source,cell_line
                    relative=source[1].replace('\\','/')
                    assert hashlib.sha256((w/relative).read_bytes()).digest()==hashlib.sha256((old/relative).read_bytes()).digest()
                    pins=re.findall(r'\.(\w+)\(([^)]+)\)',cell_line)
                    nets={};canonical=[]
                    for pin,net in pins:
                        if not re.fullmatch(r"\d+'[bhd][0-9a-fx]+|GND|VCC",net,re.I):
                            if net not in nets:nets[net]=f'net{len(nets)}'
                            net=nets[net]
                        canonical.append(pin+'='+net)
                    mask=re.search(r'LUTMASK=([^ *]+)',cell_line)[1]
                    canonical_cell=f'{relative}:{source[2]} LUTMASK={mask} '+','.join(canonical)
                    loop_map[cell]=canonical_cell
                    line=re.sub(r'\bi\d+(?=:)',lambda m:canonical_cell,line)
                if 'SyncHeadDrivenByNonSeq' in line:
                    # Preserve the complete named head; only generated driver ID differs.
                    line=re.sub(r'source LUT__\d+:O','source LUT__AUTO:O',line)
                c[filename+': '+line]+=1
    (r/('loop-map-current.json' if folder==w else 'loop-map-baseline.json')).write_text(json.dumps(loop_map,indent=2),encoding='utf-8')
    return c
n,o=flow(w),flow(old)
delta={'added':list((n-o).elements()),'removed':list((o-n).elements()),'new_count':sum(n.values()),'old_count':sum(o.values())}
(r/'flow-warning-delta.json').write_text(json.dumps(delta,indent=2),encoding='utf-8')
print('PNR warning counts:',delta['new_count'],delta['old_count'])
print('Added unique messages:',json.dumps(list(set(delta['added']))[:12],indent=2))
print('Removed unique messages:',json.dumps(list(set(delta['removed']))[:12],indent=2))

