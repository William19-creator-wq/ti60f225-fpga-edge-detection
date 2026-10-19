from pathlib import Path
import datetime,json,subprocess,hashlib
T=Path(__file__).absolute().parent;W=T.parent;Q=Path('C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64')
out=T/'detail_runs'/datetime.datetime.now().strftime('%H%M%S');out.mkdir(parents=True)
sources=[W/'rtl'/n for n in ['detail_pattern_gray.v','rawcard_overlay.v','colorcard_overlay.v','true_dual_port_ram.v']]+[W/'rtl/debayer'/n for n in ['line_buffer.v','rgb_gain_v1.v','raw_to_rgb.v','debayer_top_2to1.v']]+[T/'tb_detail.sv']
cmds=[[str(Q/'vlib.exe'),'work'],[str(Q/'vlog.exe'),'-sv',*map(str,sources)],[str(Q/'vsim.exe'),'-c','-onfinish','stop','tb_detail','-do','onerror {quit -code 2}; run -all; quit -code 0']]
records=[]
for i,c in enumerate(cmds):
 p=subprocess.run(c,cwd=out,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,timeout=180)
 (out/f'{i}.log').write_bytes(p.stdout);records.append(dict(argv=c,returncode=p.returncode))
 (out/'commands.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
 print(p.stdout.decode(errors='replace')[-2000:],flush=True)
 assert p.returncode==0 and b'Fatal:' not in p.stdout and b'Error:' not in p.stdout
assert b'DETAIL_PASS raw_words=412800 direct_pixels=825600 bilinear_pixels=363280' in p.stdout
(out/'sources.json').write_text(json.dumps([dict(path=str(s),sha256=hashlib.sha256(s.read_bytes()).hexdigest()) for s in sources],indent=2),encoding='utf-8')
print(out)
