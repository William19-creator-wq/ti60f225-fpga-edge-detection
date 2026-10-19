from pathlib import Path
import re
w=Path(__file__).resolve().parents[1];root=w.parents[2]
p=w/'rtl/ti60f225_oob_top.v';s=p.read_text(encoding='utf-8')
anchor='   //Clocks '
assert s.count(anchor)==1
s=s.replace(anchor,'    input wire key_inc_n,key_dec_n,key_mode_n,\n\n'+anchor)
s=s.replace('wire algorithm_sticky_fault;','''wire algorithm_sticky_fault;
wire [2:0] algorithm_mode;
wire [10:0] algorithm_threshold;
v7_algorithm_control algorithm_controls(
    .clk(vid_clk_dvi2),.rst(!vid_rst_n),
    .key_inc_n(key_inc_n),.key_dec_n(key_dec_n),.key_mode_n(key_mode_n),
    .mode(algorithm_mode),.threshold(algorithm_threshold));''')
assert s.count(".cfg_mode(3'd5),.cfg_threshold(11'd256)")==1
s=s.replace(".cfg_mode(3'd5),.cfg_threshold(11'd256)",'.cfg_mode(algorithm_mode),.cfg_threshold(algorithm_threshold)')
p.write_text(s,encoding='utf-8')
p=w/'rtl/v7_algorithm_video_pair.sv';s=p.read_text(encoding='utf-8')
s=s.replace('HTOTAL=1100','HTOTAL=1100, HUD_ENABLE=1')
s=s.replace('reg [53:0]','reg [64:0]')
s=s.replace('reg [10:0] x_pending;','reg [10:0] x_pending,y_pending;\n    wire [47:0] rendered_pair;')
s=s.replace('reg [7:0] gray;','reg [7:0] gray,difference,amplified;')
s=s.replace('gray=gray8(rgb);','gray=gray8(rgb);\n            difference=gray>=filtered?gray-filtered:filtered-gray;\n            amplified=difference>=32?8\'d255:{difference[4:0],3\'b000};')
s=s.replace('default:display_pixel=rgb;',"6:if(available)display_pixel={amplified,amplified,amplified};\n                default:display_pixel=rgb;")
anchor='    always @(posedge clk) begin'
pos=s.index(anchor)
s=s[:pos]+'''    generate for(genvar lane=0;lane<2;lane=lane+1)begin:display_lane
        wire [10:0] pixel_x=x_pending+11'(lane);
        wire [23:0] processed=display_pixel(pixel_pending[lane*24+:24],
            result_read[lane*8+:8],result_read[16+lane],pending_result,
            pixel_pending[53:51],pixel_x);
        if(HUD_ENABLE)begin:status_enabled
            v7_algorithm_status_pixel status_pixel(.rgb(processed),.x(pixel_x),.y(y_pending),
                .mode(pixel_pending[53:51]),.threshold(pixel_pending[64:54]),
                .available(pending_result),.pixel(rendered_pair[lane*24+:24]));
        end else begin:status_disabled
            assign rendered_pair[lane*24+:24]=processed;
        end
    end endgenerate

'''+s[pos:]
s=s.replace('{frame_mode,in_vs','{frame_threshold,frame_mode,in_vs')
s=s.replace('pixel_pending<=0;x_pending<=0;','pixel_pending<=0;x_pending<=0;y_pending<=0;')
s=s.replace('pixel_pending<=scan_read;x_pending<=display_x;','pixel_pending<=scan_read;x_pending<=display_x;y_pending<=display_y;')
start=s.index('            for(integer lane=0;lane<2;lane=lane+1)')
end=s.index('            if((input_valid',start)
s=s[:start]+'            out_rgb<=rendered_pair;\n'+s[end:]
p.write_text(s,encoding='utf-8')
# Only append the three unused input GPIO nodes; KEY0 reset mapping stays exactly as v7.
p=w/'ti60f225_oob.peri.xml';s=p.read_text(encoding='utf-8')
old=(root/'work/active/track4_board_refine_from031_20261013/track4_board.peri.xml').read_text(encoding='utf-8')
nodes=[]
for name,gpio in [('key_inc_n','GPIOR_22'),('key_dec_n','GPIOR_21'),('key_mode_n','GPIOL_03')]:
    assert f'gpio_def="{gpio}"' not in s,gpio
    node=re.search(r'    <efxpt:comp_gpio name="'+name+r'".*?</efxpt:comp_gpio>',old,re.S)[0]
    node=re.sub(r'gpio_def="[^"]+"',f'gpio_def="{gpio}"',node)
    nodes.append(node)
s=s.replace('        <efxpt:global_unused_config','\n'.join(nodes)+'\n        <efxpt:global_unused_config',1)
p.write_text(s,encoding='utf-8')
p=w/'ti60f225_oob.sdc'
with p.open('a',encoding='utf-8') as f:
    f.write('\n# Asynchronous buttons: exempt only pad -> first synchronizer D.\n')
    for port,cell in [('key_inc_n','thresholds/increment_key'),('key_dec_n','thresholds/decrement_key'),('key_mode_n','mode_key')]:
        f.write('set_false_path -from [get_ports {'+port+'}] -to [get_pins {algorithm_controls/'+cell+'/key_sync_first~FF|D}]\n')
p=w/'ti60f225_oob.xml';s=p.read_text(encoding='utf-8')
files=['rtl/v7_algorithm_control.sv','rtl/v7_algorithm_status_pixel.sv','algorithm/control/key_press_debouncer.sv','algorithm/control/live_threshold_control.sv']
s=s.replace('        <efx:top_vhdl_arch',''.join('        <efx:design_file name="'+x+'" version="sv_09" library="default" />\n' for x in files)+'        <efx:top_vhdl_arch')
p.write_text(s,encoding='utf-8')
print('Integrated keys, full-frame modes, difference x8 and status; reset/PLL/DDR unchanged.')
