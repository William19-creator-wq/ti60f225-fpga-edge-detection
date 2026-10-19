from pathlib import Path
import json,tempfile
from decode_fps import decode
T=Path(__file__).resolve().parent
captures=list((T/'runs').glob('*/synthetic_capture.vcd'));assert len(captures)==1
source=captures[0];result=decode(source,True)
assert result['valid_packets']>=60
assert len(result['measurements'])==1
p=result['measurements'][0]
assert p['sequence']==4 and p['period_cycles']==1666667 and p['pixels']==1920*1080
assert p['lines']==1080 and p['min_line_pixels']==p['max_line_pixels']==1920
assert p['flags']==1 and abs(p['fps']-30)<0.00001
with tempfile.TemporaryDirectory(dir=T) as d:
    path=Path(d)/'damaged.vcd'
    s=source.read_text()
    assert 'b01011010 0' in s
    # Corrupt the trailer's low byte, preserving its header, to prove rejection.
    assert 'b10100101 0' in s
    path.write_text(s.replace('b10100101 0','b10100100 0'))
    try:decode(path,True)
    except ValueError:pass
    else:raise AssertionError('Checksum corruption accepted')
    path.write_text(s+'\n#0\nb0 0\n')
    try:decode(path,True)
    except ValueError:pass
    else:raise AssertionError('Segment reset accepted')
R=T.parents[3]/'reports/TRACK4-V7-FPS-001'
(R/'decoder-test.json').write_text(json.dumps(dict(status='PASS',checks=['sparse signal changes expanded by sample index','16-bit word ordering and packet checksum','exact 1666667-cycle interval','geometry 1920x1080','reject checksum corruption','reject segmented capture'],synthetic_capture=result),indent=2),encoding='utf-8')
print('FPS_DECODER_PASS simulation_only; no hardware FPS measurement yet')
