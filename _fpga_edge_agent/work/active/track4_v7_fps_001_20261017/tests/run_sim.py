from pathlib import Path
import datetime,hashlib,json,subprocess
T=Path(__file__).absolute().parent;W=T.parent
Q=Path('C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64')
out=T/'runs'/datetime.datetime.now().strftime('%H%M%S');out.mkdir(parents=True)
sources=[W/'rtl/camera_fps_monitor.v',T/'tb_fps.sv']
cmds=[[str(Q/'vlib.exe'),'work'],[str(Q/'vlog.exe'),'-sv',*map(str,sources)],
 [str(Q/'vsim.exe'),'-c','-onfinish','stop','tb_fps','-do','onerror {quit -code 2}; run -all; quit -code 0']]
records=[]
for i,c in enumerate(cmds):
    p=subprocess.run(c,cwd=out,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,timeout=300)
    (out/f'{i}.log').write_bytes(p.stdout);records.append(dict(argv=c,returncode=p.returncode))
    (out/'commands.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
    print(p.stdout.decode(errors='replace')[-1800:],flush=True)
    assert p.returncode==0 and b'Fatal:' not in p.stdout and b'Error:' not in p.stdout
assert b'FPS_MONITOR_PASS' in p.stdout
(out/'sources.json').write_text(json.dumps([dict(path=str(s),sha256=hashlib.sha256(s.read_bytes()).hexdigest()) for s in sources],indent=2),encoding='utf-8')
print(str(out),flush=True)
