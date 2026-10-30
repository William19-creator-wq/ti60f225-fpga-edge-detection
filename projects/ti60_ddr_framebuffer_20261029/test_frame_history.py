from pathlib import Path
import subprocess,json,sys
sys.stdout.reconfigure(encoding='utf-8')
p=Path('C:/Users/34528/FPGAEdgeLinks/Work/active/track4_ddr_framebuffer_20261029')
q=Path('C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64')
v=p/'verification/frame_history';v.mkdir(exist_ok=True)
checks=[]
for name,args in [('library',['vlib.exe','work']),('compile',['vlog.exe','-sv',str(p/'rtl/frame_history_owner.sv'),str(p/'verification/tb_frame_history.sv')]),('run',['vsim.exe','-c','work.tb_frame_history','-do','onerror {quit -code 1}; onbreak {quit -code 1}; run -all; quit -code 0'])]:
 r=subprocess.run([str(q/args[0])]+args[1:],cwd=v,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 text=r.stdout.decode(errors='replace');(v/(name+'.log')).write_text(text,encoding='utf-8')
 ok=r.returncode==0 and '** Error' not in text and '** Fatal' not in text and (name!='run' or 'FRAME_HISTORY_PASS' in text)
 checks.append({'name':name,'pass':ok,'exit':r.returncode});(v/'result.json').write_text(json.dumps(checks,indent=2))
 print(name,ok,text[-1100:])
 if not ok:raise SystemExit(1)
