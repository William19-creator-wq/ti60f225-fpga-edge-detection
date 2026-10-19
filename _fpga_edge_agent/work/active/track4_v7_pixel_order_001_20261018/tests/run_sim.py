from pathlib import Path
import datetime,json,subprocess,hashlib,re
T=Path(__file__).absolute().parent;W=T.parent;Q=Path('C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64')
out=T/'runs'/datetime.datetime.now().strftime('%H%M%S');out.mkdir(parents=True)
tops=[W.parent/'track4_v7_detail_001_20261018/rtl/ti60f225_oob_top.v',W/'rtl/ti60f225_oob_top.v']
wrapper=out/'actual_vin.sv';modules=[]
for name,p in zip(['original','corrected'],tops):
    expr=re.findall(r'/\*i\*/\.vin\s*\((\{[^}]+\})\s*\)',p.read_text(encoding='utf-8'))
    assert len(expr)==1
    modules.append(f'module vin_{name}(input wire [39:0] w_mipi_rx_data,output wire [31:0] din);\nassign din={expr[0]};\nendmodule\n')
wrapper.write_text(''.join(modules),encoding='utf-8')
sources=[W/'rtl/frame_buffer_V4'/n for n in ['ser2par_v1.v','vid_par2ser.v']]+[wrapper,T/'tb_order.sv']
cmds=[[str(Q/'vlib.exe'),'work'],[str(Q/'vlog.exe'),'-sv',*map(str,sources)],[str(Q/'vsim.exe'),'-c','-onfinish','stop','tb_order','-do','onerror {quit -code 2}; run -all; quit -code 0']]
records=[]
for i,c in enumerate(cmds):
 p=subprocess.run(c,cwd=out,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,timeout=120)
 (out/f'{i}.log').write_bytes(p.stdout);records.append(dict(argv=c,returncode=p.returncode))
 (out/'commands.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
 print(p.stdout.decode(errors='replace')[-4500:],flush=True)
 assert p.returncode==0 and b'Fatal:' not in p.stdout and b'Error:' not in p.stdout
assert b'PIXEL_ORDER_PASS' in p.stdout
(out/'sources.json').write_text(json.dumps([dict(path=str(s),sha256=hashlib.sha256(s.read_bytes()).hexdigest()) for s in sources+tops],indent=2),encoding='utf-8')
print(out)
