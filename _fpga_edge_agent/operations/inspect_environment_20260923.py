import json, os, subprocess, hashlib, shutil, sys, xml.etree.ElementTree as ET
from pathlib import Path
from datetime import datetime, timezone
root=Path(r"D:\大三\FPGA_verilog")
agent=root/"_fpga_edge_agent"
out=agent/"reports/audit/environment_20260923"
out.mkdir(parents=True,exist_ok=True)
ef=root/"efinity-2026.1.132-windows-x64.tar/efinity-2026.1.132-windows-x64/efinity/2026.1"
model=Path(r"D:\modelism_\modelsim\Modelsim 10.1c\Modelsim 10.1c\win64")
results={"at":datetime.now(timezone.utc).isoformat(),"root":str(root),"requested_literal_path_exists":Path(r"D:\大三\FPGA\_verilog").exists(),"probes":[],"projects":[]}
def run(name,args,env=None,cwd=None,timeout=25):
 try:
  p=subprocess.run([str(x) for x in args],cwd=str(cwd or out),env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
  output=p.stdout.decode("utf-8",errors="replace")
  results["probes"].append({"name":name,"args":[str(x) for x in args],"returncode":p.returncode,"output":output})
  (out/(name+".txt")).write_text(output,encoding="utf8")
  print(name,"returncode",p.returncode,output[:700])
 except Exception as exc:
  results["probes"].append({"name":name,"error":type(exc).__name__})
  print(name,type(exc).__name__)
run("modelsim_version",[model/"vsim.exe","-version"])
run("vlog_version",[model/"vlog.exe","-version"])
# Current process only: use the environment values declared by vendor setup.bat.
ev=os.environ.copy()
ev.update({"EFINITY_HOME":str(ef).replace("\\","/"),"EFXPT_HOME":str(ef/"pt"),"EFXPGM_HOME":str(ef/"pgm"),"EFXDBG_HOME":str(ef/"debugger"),"EFXIPM_HOME":str(ef/"ipm"),"PYTHONHOME":str(ef/"python311"),"PYTHONDONTWRITEBYTECODE":"1"})
ev["PATH"]=str(ef/"python311/bin")+os.pathsep+str(ef/"bin")+os.pathsep+ev.get("PATH","")
ev["PYTHONPATH"]=str(ef/"scripts")
run("efinity_python_imports",[ef/"python311/bin/python.exe","-B","-c","import sys; from PyQt6.QtCore import QSettings; from devicedb.pydevicedb import EFXDeviceDatabase; print(sys.version); print('PyQt6 + devicedb imports OK')"],env=ev)
# Call parser directly; do not run __main__, which writes user_dir.ini even for --help.
run("efinity_cli_parser_help",[ef/"python311/bin/python.exe","-B","-c","import sys,efx_run; sys.argv=['efx_run.py','--help']; efx_run.parse_options()"],env=ev)
hdk=next(root.glob("VF-Ti60F225_HDK*文件包"))/"VF-Ti60F225_HDK_V2.1_20251009"/"VF-Ti60F225_HDK_V2.1_20251009"
ns={"e":"http://www.efinixinc.com/enf_proj"}
for folder in ["06-FPGA_HDL_Basic-2023.2","07-FPGA_HDL_Image-2023.2"]:
 for prjdir in sorted((hdk/folder).iterdir()):
  if not prjdir.is_dir(): continue
  for file in prjdir.glob("*.xml"):
   try: tree=ET.parse(file).getroot()
   except ET.ParseError: continue
   if tree.tag!="{http://www.efinixinc.com/enf_proj}project": continue
   refs=tree.findall(".//e:design_file",ns)+tree.findall(".//e:sdc_file",ns)
   missing=[ref.attrib["name"] for ref in refs if ref.get("name") and not (prjdir/ref.get("name")).is_file()]
   iprefs=tree.findall(".//e:ip",ns)
   missing_ip=[ref.get("path") for ref in iprefs if ref.get("path") and not (prjdir/ref.get("path")).is_file()]
   device=tree.find(".//e:device",ns); top=tree.find(".//e:top_module",ns)
   results["projects"].append({"path":str(file.relative_to(root)),"sw_version":tree.get("sw_version"),"historical_state":tree.get("last_run_state"),"device":device.get("name") if device is not None else None,"top":top.get("name") if top is not None else None,"source_and_sdc_refs":len(refs),"missing_sources_sdc":missing,"missing_ip_settings":missing_ip,"project_sha256":hashlib.sha256(file.read_bytes()).hexdigest()})
results["tool_path"]={x:shutil.which(x) for x in ["efinity","vsim","iverilog","vvp","verilator","python","gcc","g++","cmake","psql"]}
results["no_device_programming"]=True
results["no_efinity_build"]=True
results["no_install_download"]=True
(out/"environment_probe.json").write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding="utf8")
print("PROJECTS",len(results["projects"]))
print("MISSING",[(p["path"],p["missing_sources_sdc"],p["missing_ip_settings"]) for p in results["projects"] if p["missing_sources_sdc"] or p["missing_ip_settings"]])

