"""Small protocol regression: overlap, backpressure, 4 KiB rejection and reset."""
from pathlib import Path
import re, subprocess, json, sys
sys.stdout.reconfigure(encoding='utf-8')
p=Path('C:/Users/34528/FPGAEdgeLinks/Work/active/track4_ddr_framebuffer_20261029')
q=Path('C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64')
v=p/'verification/catalog_adapter';v.mkdir(parents=True,exist_ok=True)
header=(p/'rtl/catalog_axi_adapter.sv').read_text().split(');')[0].split('module catalog_axi_adapter (')[1]
decl=re.sub(r'\b(input|output)\s+logic', 'logic',header)
decl=re.sub(r',(?=\s*(?:logic|//))',';',decl)
decl=decl.rstrip().rstrip(',')+';'
tb='module tb;\n'+decl+'\n catalog_axi_adapter dut(.*);\n'
tb+='''
always #5 clk=~clk;
task tick; @(posedge clk); #1; endtask
task reset_all;
 rst=1; enable=0; s_awvalid=0;s_arvalid=0;s_wvalid=0;s_bready=0;s_rready=0;
 axi_aready=0;axi_wready=0;axi_bvalid=0;axi_rvalid=0;
 s_awaddr=32'h08000000;s_awid=3;s_awlen=1;s_awsize=4;s_awburst=1;
 s_araddr=32'h0ff00000;s_arid=7;s_arlen=1;s_arsize=4;s_arburst=1;
 s_wdata=128'h1234;s_wstrb=16'ha55a;s_wlast=0;
 axi_bid=3;axi_bresp=0;axi_rid=7;axi_rdata=128'hbeef;axi_rresp=0;axi_rlast=0;
 tick;tick;rst=0;enable=1;tick;
endtask
initial begin
 clk=0; reset_all;
 s_awvalid=1;s_arvalid=1; tick; s_awvalid=0;
 if(!axi_avalid||!axi_atype||axi_aid!=3||axi_aaddr!=32'h08000000) $fatal(1,"write arbitration");
 repeat(5) begin tick; if(!axi_avalid||axi_aid!=3||s_arready) $fatal(1,"address stability"); end
 axi_aready=1;tick;tick;s_arvalid=0;
 if(!axi_avalid||axi_atype||axi_aid!=7) $fatal(1,"read overlap");
 tick;axi_aready=0;s_wvalid=1;axi_wready=0;
 repeat(3)begin tick;if(!axi_wvalid||axi_wstrb!=16'ha55a||axi_wid!=3) $fatal(1,"write stability");end
 axi_wready=1;tick;s_wlast=1;tick;s_wvalid=0;
 axi_bvalid=1;repeat(3)begin tick;if(!s_bvalid) $fatal(1,"response retention");end
 s_bready=1;tick;axi_bvalid=0;
 axi_rvalid=1;s_rready=0;tick;if(!s_rvalid||s_rid!=7||s_rdata!=128'hbeef)$fatal(1,"read response");
 s_rready=1;tick;axi_rlast=1;tick;axi_rvalid=0;tick;
 if(fault) $fatal(1,"valid overlap fault");
 reset_all;
 s_awaddr=32'h08000ff0;s_awlen=1;s_awvalid=1;tick;s_awvalid=0;
 if(axi_avalid||!fault) $fatal(1,"4KiB crossing reached DDR");
 s_wvalid=1;tick;s_wlast=1;tick;s_wvalid=0;
 if(!s_bvalid||s_bresp!=3||s_bid!=3)$fatal(1,"invalid write response");
 s_bready=1;tick;
 reset_all;s_araddr=32'h08000001;s_arvalid=1;tick;s_arvalid=0;
 if(axi_avalid||!s_rvalid||s_rresp!=3||s_rlast)$fatal(1,"unaligned read reject");
 s_rready=1;tick;if(!s_rlast)$fatal(1,"reject read length");tick;
 reset_all;if(fault||axi_avalid||s_rvalid||s_bvalid)$fatal(1,"reset drain");
 $display("CATALOG_ADAPTER_PASS");$finish;
end
initial begin #100000; $fatal(1,"timeout");end
endmodule
'''
(v/'tb.sv').write_text(tb)
checks=[]
for name,args in [('library',['vlib.exe','work']),('compile',['vlog.exe','-sv',str(p/'rtl/catalog_axi_adapter.sv'),str(v/'tb.sv')]),('run',['vsim.exe','-c','work.tb','-do','onerror {quit -code 1}; onbreak {quit -code 1}; run -all; quit -code 0'])]:
    r=subprocess.run([str(q/args[0])]+args[1:],cwd=v,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    text=r.stdout.decode(errors='replace');(v/(name+'.log')).write_text(text,encoding='utf-8')
    ok=r.returncode==0 and '** Error' not in text and '** Fatal' not in text and (name!='run' or 'CATALOG_ADAPTER_PASS' in text)
    checks.append({'name':name,'pass':ok,'exit':r.returncode})
    (v/'result.json').write_text(json.dumps(checks,indent=2))
    print(name,ok,text[-1400:])
    if not ok:raise SystemExit(1)
