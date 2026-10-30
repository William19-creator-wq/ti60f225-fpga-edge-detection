from pathlib import Path
p=Path(__file__).resolve().parent
f=p/'rtl/integration_controls.sv';s=f.read_text(encoding='utf-8')
s=s.replace('parameter integer DEBOUNCE_CYCLES=', 'parameter integer HISTORY_AVAILABLE=0,\n    parameter integer DEBOUNCE_CYCLES=')
s=s.replace('output reg [31:0] config_id','output reg [1:0] history_mode,\n    output reg [5:0] history_position,\n    output reg history_command,\n    output reg [31:0] config_id')
s=s.replace('if(rst)begin','history_command<=0;\n        if(rst)begin',1)
s=s.replace('mode<=0;threshold<=64;', 'history_mode<=0;history_position<=0;\n            mode<=0;threshold<=64;')
s=s.replace('(FRAME_WORKER_AVAILABLE?5:(EDGE_SELECT_AVAILABLE?1:0))','(HISTORY_AVAILABLE?3:(FRAME_WORKER_AVAILABLE?5:(EDGE_SELECT_AVAILABLE?1:0)))')
s=s.replace('end else case(menu_item)','''end else if(HISTORY_AVAILABLE&&menu_item==2)begin
                    history_mode<=plus_event?history_mode+2'd1:history_mode-2'd1;history_command<=1;
                end else if(HISTORY_AVAILABLE&&menu_item==3)begin
                    history_position<=plus_event?(history_position==59?0:history_position+1):(history_position==0?59:history_position-1);
                    history_mode<=3;history_command<=1;
                end else case(menu_item)''')
f.write_text(s,encoding='utf-8')
f=p/'rtl/ti60f225_oob_top.v';s=f.read_text(encoding='utf-8')
marker='// IMX219\n'
code='''// History control crosses video -> AXI via a stable handshake mailbox.
wire [1:0] history_requested_mode,history_actual_mode;
wire [5:0] history_requested_position,history_actual_position;
wire history_command_pulse,history_command_ready,history_command_axi;
wire [7:0] history_command_data;
wire [6:0] history_count;
wire [63:0] history_source_frame;
wire history_fault;
reg history_command_pending=0;
always @(posedge vid_clk_dvi2)begin
 if(!vid_rst_n)history_command_pending<=0;
 else if(history_command_pulse)history_command_pending<=1;
 else if(history_command_pending&&history_command_ready)history_command_pending<=0;
end
frame_descriptor_mailbox #(.WIDTH(8)) history_commands(
 .src_clk(vid_clk_dvi2),.src_rst(!vid_rst_n),.src_valid(history_command_pending),.src_ready(history_command_ready),
 .src_data({history_requested_mode,history_requested_position}),.dst_clk(core_clk),.dst_rst(!vid_rst_n),
 .dst_valid(history_command_axi),.dst_ready(1'b1),.dst_data(history_command_data));
'''
assert marker in s
s=s.replace(marker,code+marker,1).replace('  frame_buffer #(','  history_frame_buffer #(',1)
s=s.replace(')checker0(',''')checker0(
 .command_valid(history_command_axi),.command_mode(history_command_data[7:6]),.command_index(history_command_data[5:0]),
 .bresp(s_axi_bresp),.playback_mode(history_actual_mode),.playback_position(history_actual_position),
 .history_count(history_count),.source_frame_id(history_source_frame),.history_fault(history_fault),''',1)
s=s.replace('integration_controls #(.CANNY_ONLY_AVAILABLE(1)', 'integration_controls #(.HISTORY_AVAILABLE(1),.CANNY_ONLY_AVAILABLE(1)',1)
s=s.replace('fullscreen_mode_control (','fullscreen_mode_control (\n    .history_mode(history_requested_mode),.history_position(history_requested_position),.history_command(history_command_pulse),',1)
f.write_text(s,encoding='utf-8')
f=p/'ti60f225_oob.xml';s=f.read_text()
names=['frame_descriptor_mailbox','frame_history_owner','frame_playback_select','raw_capture_frontend','raw_capture_fifo','raw_frame_write_dma','raw_capture_engine','raw_frame_store','raw_frame_read_dma','history_frame_buffer']
entries=''.join(f'        <efx:design_file name="rtl/{name}.sv" version="sv_09" library="default" />\n' for name in names)
s=s.replace('<efx:top_vhdl_arch',entries+'<efx:top_vhdl_arch')
f.write_text(s,encoding='utf-8')
print('History store and leased read DMA connected to board top; menu items 2/3 drive mode/index. Unverified until compile and simulation.')
