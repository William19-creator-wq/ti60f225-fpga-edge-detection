"""Fresh Catalog controller build; logs are not evidence of hardware operation."""
from pathlib import Path
import os,subprocess,json,sys,hashlib,datetime
p=Path('C:/Users/34528/FPGAEdgeLinks/Work/active/track4_ddr_tag_ram_20261029')
t=Path('C:/Users/34528/FPGAEdgeLinks/Efinity2026_1')
r=p/os.environ.get('FRAME_BUILD_DIR','catalog_build');r.mkdir(exist_ok=True)
c=r/'config';c.mkdir(exist_ok=True)
i=c/'user_dir.ini';i.write_text('[General]\nEFINITY_USER_DIR='+c.as_posix()+'\n')
env=os.environ.copy()
env.update(EFINITY_HOME=t.as_posix(),PYTHONHOME=str(t/'python311'),EFINITY_USER_DIR_INI=str(i),EFINITY_USER_DIR=str(c),
 EFXPT_HOME=str(t/'pt'),EFXPGM_HOME=str(t/'pgm'),EFXDBG_HOME=str(t/'debugger'),EFXIPM_HOME=str(t/'ipm'),
 EFXSVF_HOME=str(t/'debugger/svf_player'),EFXSERDESDBG_HOME=str(t/'debugger/serdes_debug_tool'),
 QT_PLUGIN_PATH=str(t/'python311'),QT_QPA_PLATFORM_PLUGIN_PATH=str(t/'python311/platforms'))
env['PATH']=';'.join(str(t/x) for x in ['bin','python311/bin','scripts','pgm/bin'])+';'+env['PATH']
for flow in sys.argv[1:] or ['map']:
 command=[str(t/'python311/bin/python.exe'),str(t/'scripts/efx_run.py'),'ti60f225_oob.xml','--flow',flow,'--output_dir',str(r/'outflow'),'--work_dir',str(r/'work'),'--timeout',os.environ.get('FRAME_FLOW_TIMEOUT','7200')]
 with (r/(flow+'.log')).open('wb') as log:
  proc=subprocess.run(command,cwd=p,env=env,stdout=log,stderr=subprocess.STDOUT)
 (r/(flow+'-result.json')).write_text(json.dumps({'exit':proc.returncode,'hardware_passed':False,'time':datetime.datetime.now().isoformat()},indent=2))
 print(flow,proc.returncode,flush=True)
 if proc.returncode:
  print((r/(flow+'.log')).read_text(errors='replace')[-3000:]);raise SystemExit(proc.returncode)
