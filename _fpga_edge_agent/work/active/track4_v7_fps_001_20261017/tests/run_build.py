"""Approved local Efinity stages. Never invokes a hardware program flow."""
from pathlib import Path
import datetime, json, os, subprocess, sys
sys.stdout.reconfigure(encoding='utf-8',errors='replace')
w=Path(__file__).absolute().parent.parent
report=Path('D:/大三/FPGA_verilog/_fpga_edge_agent/reports/TRACK4-V7-FPS-001')
report.mkdir(exist_ok=True)
tool=Path('C:/Users/34528/FPGAEdgeLinks/Efinity2026_1')
env=os.environ.copy()
env.update(EFINITY_HOME=tool.as_posix(),PYTHONHOME=str(tool/'python311'),
 EFXPT_HOME=str(tool/'pt'),EFXPGM_HOME=str(tool/'pgm'),EFXDBG_HOME=str(tool/'debugger'),
 EFXIPM_HOME=str(tool/'ipm'),EFXSVF_HOME=str(tool/'debugger/svf_player'),
 EFXSERDESDBG_HOME=str(tool/'debugger/serdes_debug_tool'),
 EFINITY_USER_DIR_INI=str(Path(os.environ['LOCALAPPDATA'])/'efinity/user_dir.ini'),
 QT_PLUGIN_PATH=str(tool/'python311'),QT_QPA_PLATFORM_PLUGIN_PATH=str(tool/'python311/platforms'),
 QTWEBENGINE_CHROMIUM_FLAGS='--disable-gpu')
env['PATH']=os.pathsep.join(str(tool/p) for p in ['python311/bin','bin','pgm/bin','debugger/bin','debugger/svf_player/bin','scripts'])+os.pathsep+env['PATH']
for stage in sys.argv[1:]:
 assert stage in ['map','interface','pnr','pgm']
 log=report/f'build-01-{stage}.log'; result=report/f'build-01-{stage}.json'
 assert not log.exists(), 'Do not overwrite prior evidence'
 cmd=[str(tool/'python311/bin/python.exe'),str(tool/'scripts/efx_run.py'),
 'ti60f225_oob.xml','--flow',stage,'--output_dir','outflow','--work_dir','work_compile','--timeout','10800']
 record=dict(stage=stage,argv=cmd,cwd=str(w),started_at=datetime.datetime.now().astimezone().isoformat(),hardware_operation=False)
 result.write_text(json.dumps(record,indent=2),encoding='utf-8')
 print('Starting '+stage,flush=True)
 with log.open('wb') as out:
  p=subprocess.run(cmd,cwd=w,env=env,stdout=out,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,timeout=11000)
 record.update(returncode=p.returncode,ended_at=datetime.datetime.now().astimezone().isoformat())
 result.write_text(json.dumps(record,indent=2),encoding='utf-8')
 print(stage+' returncode='+str(p.returncode),flush=True)
 if p.returncode: sys.exit(p.returncode)
