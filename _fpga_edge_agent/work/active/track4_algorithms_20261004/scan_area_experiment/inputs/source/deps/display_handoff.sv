// DH01/06/08：单business在途、独立cancel level、heartbeat与永久隔离。
module display_handoff #(
    parameter integer IMAGE_WIDTH=1920,IMAGE_HEIGHT=1080,WATCHDOG_CYCLES=50500000,
    parameter logic [63:0] INIT_POLICY=1,INIT_SCAN=0,INIT_LAST_SEQUENCE=0
)(
    input logic core_clk,video_clk,safe_reset_n,
    input logic request_valid,output wire request_ready,input logic [1136:0] request,
    output wire response_valid,input logic response_ready,output wire [1206:0] response,
    input logic cancel_valid,input logic [63:0] cancel_sequence,
    input logic vsync_tick,scan_de,
    input logic prepared_valid,input logic [63:0] prepared_sequence,prepared_scan,prepared_result,prepared_policy,
    input logic [194:0] prepared_origin,input logic retire_capacity,
    input logic closed_valid,input logic [63:0] closed_sequence,closed_result,closed_policy,input logic [194:0] closed_origin,
    output wire candidate_valid,output wire [941:0] candidate_bundle,output wire [63:0] candidate_sequence,candidate_target_scan,
    output wire cancel_candidate,prepare_selected,
    output wire active_valid,output wire [941:0] active_bundle,output wire active_changed,output wire [63:0] previous_result,
    output wire [63:0] scan_token,video_policy,frozen_source,output wire frozen,committed,snapshot_hold,
    output logic core_inflight,quarantined,output logic [2:0] error_reason,output logic [63:0] error_sequence
);
    import display_handoff_pkg::*;
    localparam integer TW=$clog2(WATCHDOG_CYCLES+1);
    (* ASYNC_REG="TRUE" *) logic [1:0] core_reset,video_idle_sync,heartbeat_sync,video_q_sync;
    logic cancel_level,last_heartbeat;logic [63:0] core_sequence;
    logic [TW-1:0] alive_timer,business_timer;
    wire core_running=core_reset==0;
    wire req_src_ready,req_src_running,req_dst_running,req_dst_valid,req_dst_ready;
    wire [1136:0] req_dst_data;
    wire rsp_src_valid,rsp_src_ready,rsp_src_running,rsp_dst_running;
    wire [1206:0] rsp_src_data;
    wire video_idle,heartbeat,video_q;wire [2:0] video_error;
    route_request_t request_view;route_response_t response_view;
    assign request_view=request;assign response_view=response;
    assign request_ready=core_running && !core_inflight && !quarantined && video_idle_sync[1] && req_src_ready;
    atomic_mailbox #(.PAYLOAD_WIDTH(1137)) request_link(
        .src_clk(core_clk),.dst_clk(video_clk),.safe_reset_n,
        .src_valid(request_valid && !core_inflight && !quarantined && video_idle_sync[1]),.src_ready(req_src_ready),.src_data(request),
        .dst_valid(req_dst_valid),.dst_ready(req_dst_ready),.dst_data(req_dst_data),.src_running(req_src_running),.dst_running(req_dst_running));
    atomic_mailbox #(.PAYLOAD_WIDTH(1207)) response_link(
        .src_clk(video_clk),.dst_clk(core_clk),.safe_reset_n,.src_valid(rsp_src_valid),.src_ready(rsp_src_ready),.src_data(rsp_src_data),
        .dst_valid(response_valid),.dst_ready(response_ready),.dst_data(response),.src_running(rsp_src_running),.dst_running(rsp_dst_running));
    display_route #(.IMAGE_WIDTH(IMAGE_WIDTH),.IMAGE_HEIGHT(IMAGE_HEIGHT),.INIT_POLICY(INIT_POLICY),.INIT_SCAN(INIT_SCAN),.INIT_LAST_SEQUENCE(INIT_LAST_SEQUENCE)) route(
        .video_clk,.safe_reset_n,.request_valid(req_dst_valid),.request_ready(req_dst_ready),.request(req_dst_data),
        .response_valid(rsp_src_valid),.response_ready(rsp_src_ready),.response(rsp_src_data),.response_transport_ready(rsp_src_ready),
        .cancel_level,.vsync_tick,.scan_de,.prepared_valid,.prepared_sequence,.prepared_scan,.prepared_result,.prepared_policy,.prepared_origin,.retire_capacity,
        .closed_valid,.closed_sequence,.closed_result,.closed_policy,.closed_origin,.candidate_valid,.candidate_bundle,.candidate_sequence,.candidate_target_scan,
        .cancel_candidate,.prepare_selected,.active_valid,.active_bundle,.active_changed,.previous_result,.scan_token,.policy(video_policy),.frozen_source,
        .frozen,.committed,.snapshot_hold,.video_quarantined(video_q),.video_error,.idle(video_idle),.heartbeat);
    always_ff @(posedge core_clk or negedge safe_reset_n)
        if(!safe_reset_n)core_reset<=2'b11;else core_reset<={core_reset[0],1'b0};
    always_ff @(posedge core_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin video_idle_sync<=0;heartbeat_sync<=0;video_q_sync<=0;end
        else begin video_idle_sync<={video_idle_sync[0],video_idle};heartbeat_sync<={heartbeat_sync[0],heartbeat};video_q_sync<={video_q_sync[0],video_q};end
    end
    always_ff @(posedge core_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin core_inflight<=0;quarantined<=0;error_reason<=0;error_sequence<=0;core_sequence<=0;cancel_level<=0;last_heartbeat<=0;alive_timer<=0;business_timer<=0;end
        else if(core_running)begin
            if(heartbeat_sync[1]!=last_heartbeat)begin last_heartbeat<=heartbeat_sync[1];alive_timer<=0;end
            else if(alive_timer<WATCHDOG_CYCLES-1)alive_timer<=alive_timer+1'b1;
            if(!core_inflight)business_timer<=0;else if(business_timer<WATCHDOG_CYCLES-1)business_timer<=business_timer+1'b1;
            if(request_valid && request_ready)begin core_inflight<=1;core_sequence<=request_view.sequence_id;cancel_level<=0;business_timer<=0;end
            if(core_inflight && cancel_valid && cancel_sequence==core_sequence)cancel_level<=1;
            if(response_valid && response_ready)begin
                core_inflight<=0;cancel_level<=0;
                if(!core_inflight || response_view.sequence_id!=core_sequence)begin quarantined<=1;error_reason<=5;error_sequence<=core_sequence;end
            end
            if(!quarantined)begin
                if(video_q_sync[1])begin quarantined<=1;error_reason<=video_error;error_sequence<=core_sequence;end
                else if(alive_timer==WATCHDOG_CYCLES-1)begin quarantined<=1;error_reason<=1;error_sequence<=core_sequence;end
                else if(core_inflight && business_timer==WATCHDOG_CYCLES-1 && !(response_valid && response_ready))begin quarantined<=1;error_reason<=2;error_sequence<=core_sequence;end
            end
        end
    end
    // synthesis translate_off
    initial if(WATCHDOG_CYCLES<1024 || IMAGE_WIDTH<4 || IMAGE_WIDTH>1920 || IMAGE_WIDTH%2!=0 || IMAGE_HEIGHT<2 || IMAGE_HEIGHT>1080 || IMAGE_HEIGHT%2!=0 || INIT_POLICY==0)$fatal(1,"Handoff parameters");
    // synthesis translate_on
endmodule
