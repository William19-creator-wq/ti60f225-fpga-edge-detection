"""Apply the Catalog controller only inside this disposable candidate copy."""
from pathlib import Path
import re, json, hashlib
import xml.etree.ElementTree as ET
p=Path(__file__).resolve().parent
top=p/'rtl/ti60f225_oob_top.v'
s=top.read_text(encoding='utf-8')
start=s.index('ddr3_top                 u_ddr3_top')
end=s.index('//***************************************************************************',start)
a=(p/'rtl/catalog_axi_adapter.sv').read_text()
ports=re.findall(r'(?:input|output) logic(?:\s+\[[^\]]+\])?\s+(\w+)',a.split(');')[0])
# Clock/reset/enable share declarations in the adapter header.
ports=['clk','rst','enable']+[n for n in ports if n!='clk']
widths={}
for match in re.finditer(r'(?:input|output) logic\s*(\[[^\]]+\])?\s+(axi_\w+)',a.split(');')[0]):
    widths[match[2]]=match[1] or ''
block='// Efinity Catalog DDR3 Soft Controller 5.16; see ip/frame_ddr3/settings.json.\n'
block+='\n'.join('wire '+w+' '+n+';' for n,w in widths.items())+'\n'
block+='wire catalog_fault, catalog_done, catalog_pass;\n'
block+='reg [1:0] catalog_ready_sync;\n'
block+='always @(posedge core_clk or negedge w_arstn)\n  if(!w_arstn) catalog_ready_sync<=0;\n  else catalog_ready_sync<={catalog_ready_sync[0],catalog_done&&catalog_pass};\n'
block+='assign cal_done=catalog_ready_sync[1];\n'
block+='assign ddr_ck_hi=1\'b0; assign ddr_ck_lo=1\'b1;\n'
block+='assign app_sr_active=0; assign app_ref_ack=0; assign app_zq_ack=0;\n'
block+='assign wrlvl_dq_check=0; assign rd_level_dqs_check=0; assign init_cur_state=0; assign idelay_ld=0; assign mpr_rdlvl_dly=0;\n'
connections=[]
for n in ports:
    val={'clk':'core_clk','rst':'!w_arstn','enable':'cal_done','fault':'catalog_fault'}.get(n,n)
    if n.startswith('s_'): val='canny_ddr_'+n[2:]
    connections.append(f'.{n}({val})')
block+='catalog_axi_adapter catalog_bus (\n'+',\n'.join(connections)+'\n);\n'
connections={'clk':'core_clk','core_clk':'tx_cal_clk','twd_clk':'tx_cal_clk_90edge','tdqss_clk':'sdram_clk','tac_clk':'rx_cal_clk',
 'reset_n':'w_arstn','reset':'ddr_reset_n','cs':'ddr_cs_n','ras':'ddr_ras_n','cas':'ddr_cas_n','we':'ddr_we_n',
 'cke':'ddr_cke','addr':'ddr_addr','ba':'ddr_ba','odt':'ddr_odt','shift':'pll_shift','shift_sel':'pll_shift_sel','shift_ena':'pll_shift_ena',
 'cal_ena':"1'b1",'cal_done':'catalog_done','cal_pass':'catalog_pass','cal_shift_val':'','cal_fail_log':'',
 'o_dm_hi':'ddr_dm_hi','o_dm_lo':'ddr_dm_lo','i_dqs_hi':'ddr_dqs_in_hi','i_dqs_lo':'ddr_dqs_in_lo',
 'i_dqs_n_hi':'~ddr_dqs_in_hi','i_dqs_n_lo':'~ddr_dqs_in_lo','o_dqs_hi':'ddr_dqs_out_hi','o_dqs_lo':'ddr_dqs_out_lo',
 'o_dqs_n_hi':'','o_dqs_n_lo':'','o_dqs_oe':'ddr_dqs_oe','o_dqs_n_oe':'ddr_dqs_oe_n',
 'i_dq_hi':'ddr_dq_in_hi','i_dq_lo':'ddr_dq_in_lo','o_dq_hi':'ddr_dq_out_hi','o_dq_lo':'ddr_dq_out_lo','o_dq_oe':'ddr_dq_oe'}
connections.update({n:n for n in widths})
block+='frame_ddr3 u_frame_ddr3 (\n'+',\n'.join(f'.{k}({v})' for k,v in connections.items())+'\n);\n\n'
top.write_text(s[:start]+block+s[end:],encoding='utf-8')
f=p/'ti60f225_oob.peri.xml'; s=f.read_text()
# Reuse physical DDR pins, change PHY timing to the Catalog half-rate architecture.
s=s.replace('name="tx_cal_clk_90edge" number="0" out_divider="8" is_dyn_phase="true" phase_setting="0"',
 'name="tx_cal_clk_90edge" number="0" out_divider="8" is_dyn_phase="false" phase_setting="4"')
s=s.replace('name="tx_cal_clk" number="3" out_divider="8" is_dyn_phase="true"',
 'name="tx_cal_clk" number="3" out_divider="16" is_dyn_phase="false"')
s=s.replace('clock_name="tx_cal_clk"','clock_name="sdram_clk"')
f.write_text(s,encoding='utf-8')
f=p/'ti60f225_oob.xml';s=f.read_text()
# Keep shared vendor FIFO implementation and parameter header, remove the old controller.
s=re.sub(r'^.*<efx:design_file name="rtl/ddr3_controller/(?!common/|ddr3_parameter)[^\n]+\n','',s,flags=re.M)
extra=''.join(f'        <efx:design_file name="{n}" version="sv_09" library="default" />\n' for n in ['rtl/catalog_axi_adapter.sv','ip/frame_ddr3/frame_ddr3.sv'])
s=s.replace('<efx:top_vhdl_arch',extra+'<efx:top_vhdl_arch')
assert 'rtl/catalog_axi_adapter.sv' in s
f.write_text(s,encoding='utf-8')
f=p/'ti60f225_oob.sdc';s=f.read_text()
s=s.replace('create_clock -period 2.500 -name tx_cal_clk_90edge','create_clock -waveform {0.625 1.875} -period 2.500 -name tx_cal_clk_90edge')
s=s.replace('create_clock -period 2.500 -name tx_cal_clk ','create_clock -period 5.000 -name tx_cal_clk ')
# Remove only the old broad exclusivity line: related PHY launch paths must be timed.
s='\n'.join(l for l in s.splitlines() if not l.startswith('set_clock_groups -exclusive -group {core_clk}'))+'\n'
s+='\n# Catalog 5.16 half-rate PHY; core_clk is the independent AXI/application clock.\n'
s+='set_clock_groups -asynchronous -group {core_clk} -group {tx_cal_clk tx_cal_clk_90edge sdram_clk rx_cal_clk} -group {i_mipi_tx_pclk} -group {vid_clk_dvi2} -group {CLK_5M} -group {i_mipi_rx_pclk}\n'
s+='set_false_path -from [get_clocks {tx_cal_clk_90edge rx_cal_clk sdram_clk}] -to [get_clocks tx_cal_clk]\n'
f.write_text(s,encoding='utf-8')
files=[f for f in (p/'ip/frame_ddr3').rglob('*') if f.is_file()]
(p/'catalog-generated-sha256.json').write_text(json.dumps({str(f.relative_to(p)):hashlib.sha256(f.read_bytes()).hexdigest() for f in files},indent=2))
print('Catalog instantiated; PLL and SDC changed; compilation and hardware verification pending.')
