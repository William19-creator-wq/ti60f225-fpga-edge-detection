from pathlib import Path
import subprocess, json, hashlib, shutil, sys
from datetime import datetime, timezone
root=Path(r"D:\大三\FPGA_verilog")
agent=root/"_fpga_edge_agent"
work=agent/"work/active/environment_probe_20260923"
work.mkdir(parents=True,exist_ok=True)
out=agent/"reports/audit/environment_20260923"
hdk=next(root.glob("VF-Ti60F225_HDK*文件包"))/"VF-Ti60F225_HDK_V2.1_20251009"/"VF-Ti60F225_HDK_V2.1_20251009"
src=hdk/"06-FPGA_HDL_Basic-2023.2/01_LED_8bit_Test/src"
manifest=[]
for p in [src/"LED_8bit_Test.v",src/"led_index/led_water_display.v"]:
 dst=work/p.name
 if dst.exists() and dst.read_bytes()!=p.read_bytes(): raise RuntimeError("Existing probe copy differs")
 shutil.copyfile(p,dst)
 manifest.append({"source":str(p),"copy":str(dst),"sha256":hashlib.sha256(p.read_bytes()).hexdigest()})
(work/"SOURCE_MANIFEST.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf8")
tb="""`timescale 1ns/1ns
module tb_env;
 reg clk=0;
 reg locked=1;
 wire [7:0] led;
 integer failures=0;
 LED_8bit_Test dut(.pll_inst1_CLKOUT0(clk),.pll_inst1_LOCKED(locked),.led_data(led));
 always #5 clk=~clk;
 initial begin
  #1 locked=0;
  #2 if(led!==8'hff) begin $display("ENV_FAIL_RESET"); failures=failures+1; end
  repeat(3) @(negedge clk);
  locked=1;
  repeat(5) @(negedge clk);
  if(led!==8'h7f) begin $display("ENV_FAIL_FIRST_PATTERN"); failures=failures+1; end
  locked=0;
  #1 if(led!==8'hff) begin $display("ENV_FAIL_RE_RESET"); failures=failures+1; end
  if(failures==0) $display("ENV_SMOKE_PASS");
  else $display("ENV_SMOKE_FAIL");
  $finish;
 end
endmodule
"""
(work/"tb_env.v").write_text(tb,encoding="ascii")
model=Path(r"D:\modelism_\modelsim\Modelsim 10.1c\Modelsim 10.1c\win64")
cmds=[("vlib",[str(model/"vlib.exe"),"work"]),("vlog",[str(model/"vlog.exe"),"-work","work","LED_8bit_Test.v","led_water_display.v","tb_env.v"]),("vsim",[str(model/"vsim.exe"),"-c","-l","vsim.log","work.tb_env","-do","onerror {quit -code 2}; run -all; quit -code 0"])]
result={"at":datetime.now(timezone.utc).isoformat(),"kind":"local_simulation_smoke","hardware_programmed":False,"scope":"VF LED top reset + initial output; not full divider period or Efinity primitive/IP validation","commands":[]}
for name,args in cmds:
 try:
  p=subprocess.run(args,cwd=work,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=30)
  text=p.stdout.decode("utf8",errors="replace")
  (out/f"simulation_{name}.txt").write_text(text,encoding="utf8")
  result["commands"].append({"name":name,"args":args,"returncode":p.returncode,"output":text})
  print(name,"exit",p.returncode,text[:1500])
  if p.returncode: break
 except subprocess.TimeoutExpired:
  result["commands"].append({"name":name,"status":"TIMEOUT","seconds":30})
  print(name,"TIMEOUT");break
result["passed"]=any(x.get("name")=="vsim" and x.get("returncode")==0 and "ENV_SMOKE_PASS" in x.get("output","") for x in result["commands"])
(out/"simulation_probe.json").write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf8")
print("SIMULATION_SMOKE_PASS",result["passed"])

