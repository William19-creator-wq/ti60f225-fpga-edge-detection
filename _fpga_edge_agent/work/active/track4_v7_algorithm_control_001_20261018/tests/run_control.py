from pathlib import Path
import subprocess,hashlib,json,datetime
w=Path(__file__).absolute().parents[1]
r=Path('D:/大三/FPGA_verilog/_fpga_edge_agent/reports/TRACK4-V7-ALGORITHM-CONTROL-001')
q=Path('C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64');sim=w/'sim_keys';sim.mkdir(exist_ok=True)
def run(name,args):
    p=r/(name+'.log');n=1
    while p.exists():p=r/f'{name}-{n:02d}.log';n+=1
    with p.open('wb') as f:
        result=subprocess.run([str(x) for x in args],cwd=sim,stdout=f,stderr=subprocess.STDOUT,
            creationflags=subprocess.CREATE_NO_WINDOW,timeout=120)
    t=p.read_text(errors='replace');print(name,result.returncode,flush=True)
    assert result.returncode==0 and '** Error' not in t and '** Fatal' not in t,t[-4000:]
    return t
sources=sorted((w/'algorithm/control').glob('*.sv'))+[w/'rtl/v7_algorithm_control.sv',w/'tests/tb_control.sv']
if not(sim/'work').exists():run('control-library',[q/'vlib.exe','work'])
run('control-compile',[q/'vlog.exe','-sv','-timescale','1ns/1ps']+sources)
for n in [2,4,31]:
    t=run('control-'+str(n),[q/'vsim.exe','-c','work.tb_control',f'-gN={n}','-do','onbreak {quit -code 1}; onerror {quit -code 1}; run -all; quit -code 0'])
    assert 'CONTROL_PASS' in t
result=dict(result='PASS',debounce_tests=[2,4,31],timestamp=datetime.datetime.now().astimezone().isoformat(),
    sources={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources})
(r/'control-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
