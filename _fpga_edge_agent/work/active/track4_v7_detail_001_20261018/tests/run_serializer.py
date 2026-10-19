from pathlib import Path
import datetime,json,subprocess,hashlib
T=Path(__file__).absolute().parent;W=T.parent;Q=Path('C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64')
out=T/'serializer_runs'/datetime.datetime.now().strftime('%H%M%S');out.mkdir(parents=True)
top=(W/'rtl/ti60f225_oob_top.v').read_text(encoding='utf-8')
block=top.split("reg rgb_vs_r = 'd0;",1)[1].split('//==============================================================================',1)[0]
block="reg rgb_vs_r = 'd0;"+block
source='module serializer_from_top(input hdmi_tx_slow_clk,rgb_vs,rgb_hs,rgb_de,input [47:0] rgb_datax2,output out_vs,out_hs,out_de,output [23:0] out_pixel);\nwire pos_vs;\n'+block+'\nassign out_vs=hdmi_tx_vs;assign out_hs=hdmi_tx_hs;assign out_de=hdmi_tx_de;assign out_pixel={hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata};\nendmodule\n'
(out/'serializer_from_top.v').write_text(source,encoding='utf-8')
cmds=[[str(Q/'vlib.exe'),'work'],[str(Q/'vlog.exe'),'-sv','serializer_from_top.v',str(T/'tb_serializer.sv')],[str(Q/'vsim.exe'),'-c','-onfinish','stop','tb_serializer','-do','onerror {quit -code 2}; run -all; quit -code 0']]
records=[]
for i,c in enumerate(cmds):
 p=subprocess.run(c,cwd=out,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,timeout=120)
 (out/f'{i}.log').write_bytes(p.stdout);records.append(dict(argv=c,returncode=p.returncode))
 (out/'commands.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
 print(p.stdout.decode(errors='replace')[-1400:],flush=True)
 assert p.returncode==0 and b'Fatal:' not in p.stdout and b'Error:' not in p.stdout
assert b'SERIALIZER_PASS' in p.stdout
(out/'source.json').write_text(json.dumps(dict(extracted_from=str(W/'rtl/ti60f225_oob_top.v'),source_sha256=hashlib.sha256((W/'rtl/ti60f225_oob_top.v').read_bytes()).hexdigest(),block_sha256=hashlib.sha256(block.encode()).hexdigest(),testbench_sha256=hashlib.sha256((T/'tb_serializer.sv').read_bytes()).hexdigest(),limitations='RTL ideal phase-aligned clocks only, not gate-level/SI/monitor scaling'),indent=2),encoding='utf-8')
