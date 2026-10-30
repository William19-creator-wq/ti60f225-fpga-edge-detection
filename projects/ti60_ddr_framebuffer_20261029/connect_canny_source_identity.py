from pathlib import Path
p=Path(__file__).parent
def read(n): return (p/n).read_text(encoding='utf-8')
def write(n,s): (p/n).write_text(s,encoding='utf-8')
n='canny_board/canny_board_worker.sv';s=read(n)
s=s.replace('FIFO_DEPTH=1024,GRAY_SNAPSHOT=0','FIFO_DEPTH=1024,GRAY_SNAPSHOT=0,HISTORY_SOURCE=0')
s=s.replace('input logic video_vs,video_de,input logic [47:0] video_rgb,','''input logic video_vs,video_de,input logic [47:0] video_rgb,
    input wire video_source_valid,input wire [5:0] video_source_slot,input wire [63:0] video_source_id,
    output reg [63:0] source_pins,output wire [5:0] publish_source_slot,''')
s=s.replace('logic [63:0] cap_handle,cap_next_handle,cap_frame;', '''logic [63:0] cap_handle,cap_next_handle,cap_frame;
    wire snap_source_valid;wire [5:0] snap_source_slot;
    logic [5:0] cap_source_slot,pre_source_slot,trace_source_slot;
    logic [5:0] result_source_slot[0:1];logic [1:0] result_source_valid;
    assign publish_source_slot=trace_source_slot;''')
s=s.replace('.GRAY_ONLY(GRAY_SNAPSHOT)) snapshot(','.GRAY_ONLY(GRAY_SNAPSHOT),.HISTORY_SOURCE(HISTORY_SOURCE)) snapshot(\n        .video_source_valid,.video_source_slot,.video_source_id,.source_pin_valid(snap_source_valid),.source_pin_slot(snap_source_slot),')
s=s.replace('cap_threshold<=96;cap_filter<=1;cap_config<=0;cap_frame<=0;', 'cap_threshold<=96;cap_filter<=1;cap_config<=0;cap_frame<=0;cap_source_slot<=0;')
s=s.replace('cap_frame<=snap_video_frame;cap_state<=CAP_READY;', 'cap_frame<=snap_video_frame;cap_source_slot<=snap_source_slot;cap_state<=CAP_READY;')
s=s.replace('pre_handle<=0;pre_sensor_frame<=0;', 'pre_source_slot<=0;pre_handle<=0;pre_sensor_frame<=0;')
s=s.replace('source_bank<=cap_bank;pre_handle<=cap_handle;pre_sensor_frame<=cap_frame;', 'source_bank<=cap_bank;pre_handle<=cap_handle;pre_sensor_frame<=cap_frame;pre_source_slot<=cap_source_slot;')
s=s.replace('sensor_frame<=0;processing_cycles<=0;', 'sensor_frame<=0;processing_cycles<=0;trace_source_slot<=0;result_source_valid<=0;result_source_slot[0]<=0;result_source_slot[1]<=0;')
s=s.replace('trace_bank<=pre_bank;handle<=pre_handle;sensor_frame<=pre_sensor_frame;', 'trace_bank<=pre_bank;handle<=pre_handle;sensor_frame<=pre_sensor_frame;trace_source_slot<=pre_source_slot;')
s=s.replace('publish_toggle<=!publish_toggle;completed_jobs<=completed_jobs+1;', 'result_source_valid[slot]<=1;result_source_slot[slot]<=trace_source_slot;\n                    publish_toggle<=!publish_toggle;completed_jobs<=completed_jobs+1;')
s=s.replace('endmodule','''// RAW source ownership spans the complete capture/preprocess/trace/result
    // lifecycle, even after its entry ages out of the 60-frame history ring.
    // A result slot is replaced only after the display's drain acknowledgment.
    always_comb begin
        source_pins=0;
        if(HISTORY_SOURCE)begin
            if((cap_state==CAP_START||cap_state==CAP_WAIT)&&snap_source_valid)source_pins[snap_source_slot]=1;
            if(cap_state==CAP_READY)source_pins[cap_source_slot]=1;
            if(pre_state!=PRE_IDLE)source_pins[pre_source_slot]=1;
            if(state!=IDLE)source_pins[trace_source_slot]=1;
            for(integer ps=0;ps<2;ps++)if(result_source_valid[ps])source_pins[result_source_slot[ps]]=1;
        end
    end
endmodule''')
write(n,s)
n='canny_board/integration_frame_system.sv';s=read(n)
s=s.replace('EDGE_ONLY_DISPLAY=0)','EDGE_ONLY_DISPLAY=0,HISTORY_SOURCE=0)')
s=s.replace('input wire video_vs,video_de,input wire [47:0] video_rgb,','''input wire video_vs,video_de,input wire [47:0] video_rgb,
    input wire video_source_valid,input wire [5:0] video_source_slot,input wire [63:0] video_source_id,
    output wire [63:0] source_pins,output wire [5:0] display_source_slot,''')
s=s.replace('wire pub_toggle,pub_slot,retired_valid,', 'wire [5:0] pub_source_slot;\nwire pub_toggle,pub_slot,retired_valid,')
s=s.replace('.GRAY_SNAPSHOT(EDGE_ONLY_DISPLAY)) worker(', '.GRAY_SNAPSHOT(EDGE_ONLY_DISPLAY),.HISTORY_SOURCE(HISTORY_SOURCE)) worker(\n .video_source_valid,.video_source_slot,.video_source_id,.source_pins,.publish_source_slot(pub_source_slot),')
s=s.replace('display_reader(\n', 'display_reader(\n .publish_source_slot(pub_source_slot),.display_source_slot(display_source_slot),\n')
write(n,s)
n='rtl/integration_frame_reader.sv';s=read(n)
s=s.replace('input logic publish_toggle,publish_slot,input logic [63:0] publish_frame,','''input logic publish_toggle,publish_slot,input logic [63:0] publish_frame,
    input wire [5:0] publish_source_slot,output reg [5:0] display_source_slot,''')
s=s.replace('current_config_id<=0;current_sensor_frame<=0;', 'display_source_slot<=0;current_config_id<=0;current_sensor_frame<=0;')
s=s.replace('current_config_id<=publish_config_id;current_sensor_frame<=publish_sensor_frame;', 'display_source_slot<=publish_source_slot;current_config_id<=publish_config_id;current_sensor_frame<=publish_sensor_frame;')
write(n,s)
n='rtl/ti60f225_oob_top.v';s=read(n)
s=s.replace('wire compare_requested,compare_read_mode,compare_rgb_valid,compare_rgb_ready;','''wire compare_requested,compare_read_mode,compare_rgb_valid,compare_rgb_ready;
wire video_source_valid;wire [5:0] video_source_slot,canny_source_slot;
wire [63:0] video_source_id,canny_source_pins,canny_source_frame;''')
s=s.replace(')checker0(\n', ')checker0(\n .processing_source_pins(canny_source_pins),.video_source_valid(video_source_valid),.video_source_slot(video_source_slot),.video_source_id(video_source_id),\n')
s=s.replace('integration_frame_system #(.EDGE_ONLY_DISPLAY(1)) full_frame_canny(','''integration_frame_system #(.EDGE_ONLY_DISPLAY(1),.HISTORY_SOURCE(1)) full_frame_canny(
    .video_source_valid(video_source_valid),.video_source_slot(video_source_slot),.video_source_id(video_source_id),
    .source_pins(canny_source_pins),.display_source_slot(canny_source_slot),''')
s=s.replace('.display_sensor_frame(),', '.display_sensor_frame(canny_source_frame),')
write(n,s)
