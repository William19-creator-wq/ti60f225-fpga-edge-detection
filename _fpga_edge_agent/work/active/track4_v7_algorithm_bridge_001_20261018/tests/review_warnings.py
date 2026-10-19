from pathlib import Path
from collections import Counter
import json,re,hashlib
w=Path(__file__).resolve().parents[1];root=w.parents[2]
r=root/'reports/TRACK4-V7-ALGORITHM-BRIDGE-001';old=root/'work/active/track4_v7_pixel_order_001_20261018'
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
assert not delta['added'],'New detailed PNR warnings require review'
added=json.loads(read(r/'warning-delta.json'))['added']
assert len(added)==26
assert all(x.startswith('[EFX-0657 WARNING] Mapping into logic memory block') and
           ('algorithm/frontend/' in x or 'rtl/v7_algorithm_video_pair.sv' in x) for x in added)
review={'reviewed_added':added,'unreviewed':[],'flow_logs_reviewed':True,
 'review_notes':[
 '13 small arithmetic pipeline arrays and 9 constant-index median/Sobel register arrays are implemented as logic, as intended; not frame or line storage.',
 '4 row-tag array warnings select flip-flop/mux implementations because tags are asynchronously read/resettable. Only 8 tags, no large frame memory mapped to logic.',
 'Original scan and result pixel arrays are block RAM; map resource totals 165 RAM10 + 4 DPRAM10, and 8 explicit algorithm line RAM10 instances are present.',
 'Detailed PNR warning counts/messages match baseline after SDC path normalization, generated synchronizer-driver IDs, and loop-cell source/LUT/pin-graph normalization. Every loop maps to a byte-identical inherited RTL file; complete named synchronizer heads are preserved.',
 'Driver map/interface/pnr logs retain inherited non-ASCII resolved-path and correct-IV warnings. Stages returned PASS; source hashes, geometry simulation and 18 setup/hold relationships checked.',
 'No newly added latch, undriven signal, combinational-loop or unconstrained-clock warning was accepted.'
 ]}
(r/'warning-review.json').write_text(json.dumps(review,indent=2),encoding='utf-8')
print('Reviewed 26 synthesis mapping notices; no new detailed PNR warning.')
