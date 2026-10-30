from pathlib import Path
p=Path(__file__).parent
f=p/'rtl/ti60f225_oob_top.v';s=f.read_text(encoding="utf-8")
s=s.replace('wire [7:0] history_command_data;','''wire [20:0] history_command_data;
wire compare_requested,compare_read_mode,compare_rgb_valid,compare_rgb_ready;
wire [5:0] compare_requested_a,compare_requested_b;
wire [47:0] compare_rgb;
wire [129:0] compare_status_axi,compare_status_video;
reg compare_show=0,compare_frame_missing=0;
reg [9:0] compare_x=0;reg [10:0] compare_y=0;
reg [31:0] compare_missing_frames=0;''')
s=s.replace('frame_descriptor_mailbox #(.WIDTH(8)) history_commands(', 'frame_descriptor_mailbox #(.WIDTH(21)) history_commands(')
s=s.replace('.src_data({history_requested_mode,history_requested_position})','.src_data({compare_requested,compare_requested_a,compare_requested_b,history_requested_mode,history_requested_position})')
s=s.replace('.command_valid(history_command_axi),.command_mode(history_command_data[7:6]),.command_index(history_command_data[5:0]),', '''.command_valid(history_command_axi),.command_mode(history_command_data[7:6]),.command_index(history_command_data[5:0]),
 .command_compare(history_command_data[20]),.command_a(history_command_data[19:14]),.command_b(history_command_data[13:8]),
 .video_rgb_vs(camera_rgb_vs),.video_rgb_de(camera_rgb_de),.video_rgb(camera_rgb_datax2),
 .compare_rgb(compare_rgb),.compare_rgb_valid(compare_rgb_valid),.compare_rgb_ready(compare_rgb_ready),
 .compare_read_mode(compare_read_mode),.compare_status(compare_status_axi),''')
s=s.replace('.history_mode(history_requested_mode),.history_position(history_requested_position),.history_command(history_command_pulse),', '''.history_mode(history_requested_mode),.history_position(history_requested_position),.history_command(history_command_pulse),
    .compare_enable(compare_requested),.compare_a(compare_requested_a),.compare_b(compare_requested_b),''')
s=s.replace('integration_status_osd #(.HISTORY_STATUS(1)) status_overlay (','''frame_descriptor_mailbox #(.WIDTH(130)) compare_status_transfer(
 .src_clk(core_clk),.src_rst(!vid_rst_n),.src_valid(1'b1),.src_ready(),.src_data(compare_status_axi),
 .dst_clk(vid_clk_dvi2),.dst_rst(!vid_rst_n),.dst_valid(),.dst_ready(1'b1),.dst_data(compare_status_video));
integration_status_osd #(.HISTORY_STATUS(1)) status_overlay (
    .compare_status(compare_status_video),.compare_a_selection(compare_requested_a),.compare_b_selection(compare_requested_b),''')
s=s.replace('.cfg_mode(algorithm_display_mode),', ".cfg_mode((compare_status_video[129]||history_status_video[78:77]==2)?3'd0:algorithm_display_mode),")
s=s.replace('assign display_pixels=show_canny&&canny_snapshot_valid?', '''// Pixel coordinates follow the final bridge timing, before its OSD register.
wire compare_region=compare_y>=270&&compare_y<810;
assign compare_rgb_ready=compare_read_mode&&bridge_de&&compare_region&&!compare_frame_missing;
always @(posedge vid_clk_dvi2)begin
 if(!vid_rst_n)begin compare_x<=0;compare_y<=0;compare_show<=0;compare_frame_missing<=0;compare_missing_frames<=0;end
 else if(bridge_vs&&!bridge_vs_previous)begin
   compare_x<=0;compare_y<=0;compare_show<=compare_status_video[129];compare_frame_missing<=0;
 end else if(bridge_de)begin
   if(compare_x==959)begin compare_x<=0;compare_y<=compare_y+1;end else compare_x<=compare_x+1;
   if(compare_show&&compare_read_mode&&compare_region&&!compare_rgb_valid&&!compare_frame_missing)begin
     compare_frame_missing<=1;compare_missing_frames<=compare_missing_frames+1;
   end
 end
end
assign display_pixels=compare_show?
    ((compare_read_mode&&compare_region&&compare_rgb_valid&&!compare_frame_missing)?compare_rgb:48'd0):
    show_canny&&canny_snapshot_valid?''')
s=s.replace('algorithm_display_mode==5&&baseline_frames==3','algorithm_display_mode==5&&baseline_frames==3&&!compare_requested&&history_status_video[78:77]!=2')
f.write_text(s,encoding="utf-8")
f=p/'rtl/integration_status_osd.sv';s=f.read_text(encoding="utf-8")
s=s.replace('input wire [79:0] history_status,','''input wire [79:0] history_status,
    input wire [129:0] compare_status,input wire [5:0] compare_a_selection,compare_b_selection,''')
s=s.replace('default:glyph=0;', '''27:glyph=35'b10001_11001_11001_10101_10011_10011_10001; // N
            28:glyph=35'b01110_10001_10000_10111_10001_10001_01110; // G
            default:glyph=0;''')
# Insert before the pixel function's end, after existing overlays.
anchor='''        end
    endfunction'''
assert s.count(anchor)==1
s=s.replace(anchor,'''            if(HISTORY_STATUS&&px>=840&&px<1272&&py>=80&&py<208)begin
                cell_x=(int'(px)-840)/24;gx=((int'(px)-840)%24)/4;gy=((int'(py)-80)%32)/4;c=31;
                if(py<112)case(cell_x)
                    0:c=10;1:c={3'd0,compare_a_selection[5:4]};2:c={1'b0,compare_a_selection[3:0]};
                    4:c=11;5:c={3'd0,compare_b_selection[5:4]};6:c={1'b0,compare_b_selection[3:0]};
                    8:c=12;9:c={4'd0,compare_status[129]};default:c=31;
                endcase
                else if(compare_status[129]&&py<144)case(cell_x)
                    0:c=10;2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17:c={1'b0,compare_status[64+(17-cell_x)*4+:4]};default:c=31;
                endcase
                else if(compare_status[129]&&py<176)case(cell_x)
                    0:c=11;2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17:c={1'b0,compare_status[(17-cell_x)*4+:4]};default:c=31;
                endcase
                else if(compare_status[129]&&compare_status[128])case(cell_x)
                    0:c=20;1:c=23;2:c=14;3:c=20;4:c=10;5:c=23;6:c=21;7:c=27;8:c=28;default:c=31;
                endcase
                bits=glyph(c);pixel=24'h101018;
                if(gx<5&&gy<7&&bits[34-(gy*5+gx)])pixel=24'hffff80;
            end
''' +anchor)
f.write_text(s,encoding="utf-8")
f=p/'ti60f225_oob.xml';s=f.read_text(encoding="utf-8")
names=['thumbnail_frame_pack','rgb_thumbnail_2x2','thumbnail_capture_engine','history_compare_control','frame_write_share','span_read_dma','comparison_read_dma','rgb32_pair_unpack']
lines='\n'.join(f'        <efx:design_file name="rtl/{n}.sv" version="sv_09" library="default" />' for n in names)
s=s.replace('        <efx:top_module name="ti60f225_oob_top" />','        <efx:top_module name="ti60f225_oob_top" />\n'+lines)
f.write_text(s,encoding="utf-8")

