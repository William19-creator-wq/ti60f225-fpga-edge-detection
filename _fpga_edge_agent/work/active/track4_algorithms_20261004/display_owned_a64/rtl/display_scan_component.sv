// SC21..27：实际handoff/取数/native/行消费/renderer以及全引用fence的组合。
module display_scan_component #(
    parameter integer IMAGE_WIDTH=1920,IMAGE_HEIGHT=1080,FRAME_ALIGNMENT=64,
    parameter integer WATCHDOG_CYCLES=50500000,
    parameter logic [63:0] INIT_GENERATION=1,INIT_SCAN=0,INIT_POLICY=1
)(
    input logic core_clk,video_clk,safe_reset_n,enable,
    input logic control_valid,output wire control_ready,input logic [1136:0] control_request,
    output wire control_response_valid,input logic control_response_ready,output wire [1206:0] control_response,
    input logic cancel_valid,input logic [63:0] cancel_sequence,input logic root_retire_capacity,
    input logic in_de,in_hs,in_vs,in_frame_start,input logic [10:0] in_x_even,in_y,
    output wire [47:0] out_rgb_pair,output wire out_de,out_hs,out_vs,out_frame_start,
    output wire [10:0] out_x_even,out_y,output wire [1:0] out_error,
    output wire lookup_valid,input logic lookup_ready,output wire [478:0] lookup_demand,
    input logic [941:0] lookup_bundle,input logic lookup_permitted,
    output wire old_closed_valid,input logic old_closed_ready,output wire [386:0] old_closed_ref,
    output wire m_axi_arvalid,input logic m_axi_arready,output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid,output wire [7:0] m_axi_arlen,
    output wire [2:0] m_axi_arsize,output wire [1:0] m_axi_arburst,
    input logic m_axi_rvalid,output wire m_axi_rready,input logic [127:0] m_axi_rdata,
    input logic [3:0] m_axi_rid,input logic [1:0] m_axi_rresp,input logic m_axi_rlast,
    output wire active_valid,output wire [941:0] active_bundle,
    output wire [63:0] active_sequence,scan_token,video_policy,
    output wire frozen,committed,snapshot_hold,quarantined,
    output wire [31:0] underrun_lines
);
    import display_fetch_pkg::*;
    import display_row_pkg::*;
    (* ASYNC_REG="TRUE" *) logic [1:0] video_reset,core_reset,capacity_sync,core_fault_sync,video_fault_sync;
    logic previous_vs;
    wire video_running=video_reset==0,core_running=core_reset==0;
    wire vsync_tick=video_running && in_vs && !previous_vs;
    wire candidate_valid,cancel_candidate,prepare_selected,active_changed;
    wire [941:0] candidate_bundle;
    wire [63:0] candidate_sequence,candidate_target_scan,previous_result,frozen_source;
    wire prepared_valid;
    wire [63:0] prepared_sequence,prepared_scan,prepared_result,prepared_policy;
    wire [194:0] prepared_origin;
    wire candidate_closed_valid;
    frame_ref_t candidate_closed_ref;
    wire close_capacity,video_q,core_inflight,handoff_q;
    wire [2:0] handoff_error;
    wire [63:0] handoff_error_sequence;
    wire request_valid,request_ready,request_cancel,receipt_valid,receipt_ready;
    wire [480:0] request,service_request;
    wire [614:0] receipt,service_receipt;
    wire video_busy,fetch_video_q,service_valid,service_ready,service_cancel,service_receipt_valid,service_receipt_ready;
    wire transport_live,core_idle,fetch_core_q,engine_q;
    wire [386:0] transport_ref,scope_query_ref;
    wire scope_query_valid,engine_scope_live,scope_live;
    wire [2:0] return_valid,return_ready,row_valid,row_ready,owned;
    wire [2:0][542:0] return_ticket,row_ticket,reserve_ticket;
    wire [2:0][1:0] return_kind;
    wire [2:0] reserve_valid,reserve_ready,reserve_discard,prepared,stream_live,stream_q;
    wire [2:0][386:0] stream_ref;
    wire [2:0] display_start,display_de,discard,rd_request_valid,rd_request_ready,rd_response_valid,rd_response_ready,rd_error;
    wire [478:0] display_demand;
    wire [2:0][63:0] rd_generation,release_generation;
    wire [2:0][9:0] rd_address,rd_response_address;
    wire [2:0][53:0] rd_data,stream_pair;
    wire [2:0] release_valid,release_ready,release_error,stream_pixels_valid,stream_identity_good;
    wire [2:0][1:0] release_kind,line_error;
    wire [2:0][10:0] shown,issued,popped;
    wire [2:0] returned_valid,returned_ready;
    wire [2:0][544:0] returned;
    wire [53:0] pixels;
    wire pixels_valid,identity_good;
    wire [111:0] render;
    wire [2:0] banks_free;
    wire fence_valid,fence_ready,fence_done_valid,fence_done_ready,fence_video_q,fence_core_q;
    wire [387:0] fence_request,fence_done;
    wire core_fault=engine_q || fetch_core_q || handoff_q || video_fault_sync[1];
    wire video_fault=fetch_video_q || fence_video_q || core_fault_sync[1];
    assign quarantined=video_q || (|stream_q) || fetch_video_q || fetch_core_q || engine_q || handoff_q || fence_core_q || fence_video_q;
    logic returns_scope_live;
    // atomic_mailbox.dst_data就是core源寄存器source_hold；在core域查自身保存的545，非异步宽采样。
    always_comb begin
        returns_scope_live=0;
        for(integer b=0;b<3;b++)begin
            row_return_t rr;
            rr=returned[b];
            if(core_running && !return_ready[b] && ticket_ref(rr.ticket)==scope_query_ref)returns_scope_live=1;
        end
    end
    assign scope_live=engine_scope_live || (transport_live && transport_ref==scope_query_ref) || returns_scope_live;
    always_ff @(posedge video_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin video_reset<=3;capacity_sync<=0;core_fault_sync<=0;previous_vs<=0;end
        else begin
            video_reset<={video_reset[0],1'b0};capacity_sync<={capacity_sync[0],root_retire_capacity};
            core_fault_sync<={core_fault_sync[0],engine_q || fetch_core_q || handoff_q || fence_core_q};
            if(video_running)previous_vs<=in_vs;
        end
    end
    always_ff @(posedge core_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin core_reset<=3;video_fault_sync<=0;end
        else begin core_reset<={core_reset[0],1'b0};video_fault_sync<={video_fault_sync[0],video_q || (|stream_q) || fetch_video_q || fence_video_q};end
    end
    display_handoff #(.IMAGE_WIDTH(IMAGE_WIDTH),.IMAGE_HEIGHT(IMAGE_HEIGHT),.FRAME_ALIGNMENT(FRAME_ALIGNMENT),.WATCHDOG_CYCLES(WATCHDOG_CYCLES),.INIT_SCAN(INIT_SCAN),.INIT_POLICY(INIT_POLICY)) handoff (
        .core_clk,.video_clk,.safe_reset_n,.request_valid(control_valid),.request_ready(control_ready),.request(control_request),
        .response_valid(control_response_valid),.response_ready(control_response_ready),.response(control_response),.cancel_valid,.cancel_sequence,
        .vsync_tick,.scan_de(in_de),.prepared_valid,.prepared_sequence,.prepared_scan,.prepared_result,.prepared_policy,.prepared_origin,
        .retire_capacity(capacity_sync[1] && close_capacity),.closed_valid(candidate_closed_valid),
        .closed_sequence(candidate_closed_ref.sequence_id),.closed_result(candidate_closed_ref.result_handle),
        .closed_policy(candidate_closed_ref.policy),.closed_origin(candidate_closed_ref.origin),
        .candidate_valid,.candidate_bundle,.candidate_sequence,.candidate_target_scan,.cancel_candidate,.prepare_selected,
        .active_valid,.active_bundle,.active_changed,.previous_result,.scan_token,.video_policy,.frozen_source,.frozen,.committed,.snapshot_hold,
        .core_inflight,.quarantined(handoff_q),.error_reason(handoff_error),.error_sequence(handoff_error_sequence));
    display_scan_video #(.IMAGE_WIDTH(IMAGE_WIDTH),.IMAGE_HEIGHT(IMAGE_HEIGHT)) scan (
        .video_clk,.safe_reset_n,.vsync_tick,.scan_de(in_de),.scan_x_even(in_x_even),.scan_y(in_y),
        .candidate_valid,.candidate_bundle,.candidate_sequence,.candidate_target_scan,.cancel_candidate,
        .active_valid,.active_bundle,.active_changed,.scan_token,.prepared_valid,.prepared_sequence,.prepared_scan,.prepared_result,.prepared_policy,.prepared_origin,
        .candidate_closed_valid,.candidate_closed_ref,.close_capacity,
        .request_valid,.request_ready,.request,.request_cancel,.receipt_valid,.receipt_ready,.receipt,
        .row_valid,.row_ticket,.reserve_valid,.reserve_ready,.reserve_ticket,.reserve_discard,
        .stream_prepared(prepared),.stream_live,.stream_quarantined(stream_q),.owned,.stream_ref,
        .display_start,.display_de,.discard,.display_demand,.stream_pair,.stream_pixels_valid,.stream_identity_good,
        .pixels,.pixels_valid,.identity_good,.render,.returned_valid,.returned_ready,.returned,
        .fence_valid,.fence_ready,.fence_request,.fence_done_valid,.fence_done_ready,.fence_done,
        .fault(video_fault),.quarantined(video_q),.active_sequence,.banks_free,.underrun_lines);
    display_fetch_link link (
        .core_clk,.video_clk,.safe_reset_n,.video_request_valid(request_valid),.video_request_ready(request_ready),.video_request(request),
        .video_cancel(request_cancel),.video_receipt_valid(receipt_valid),.video_receipt_ready(receipt_ready),.video_receipt(receipt),.video_busy,.video_quarantined(fetch_video_q),
        .service_valid,.service_claim_ready(service_ready),.service_request,.service_cancel,.service_receipt_valid,.service_receipt_ready,.service_receipt,
        .transport_live,.transport_ref,.core_idle,.core_quarantined(fetch_core_q));
    display_scan_prefetch_core #(.IMAGE_WIDTH(IMAGE_WIDTH),.IMAGE_HEIGHT(IMAGE_HEIGHT),.FRAME_ALIGNMENT(FRAME_ALIGNMENT),.INIT_GENERATION(INIT_GENERATION)) prefetch (
        .core_clk,.video_clk,.safe_reset_n,.enable,.service_valid,.service_claim_ready(service_ready),.service_request,.service_cancel,
        .service_receipt_valid,.service_receipt_ready,.service_receipt,.lookup_valid,.lookup_ready,.lookup_demand,.lookup_bundle,.lookup_permitted,
        .scope_query_valid,.scope_query_ref,.local_scope_live(engine_scope_live),.quarantined(engine_q),
        .return_valid,.return_ready,.return_ticket,.return_kind,.row_valid,.row_ready,.row_ticket,.owned,
        .rd_request_valid,.rd_request_ready,.rd_generation,.rd_address,.rd_response_valid,.rd_response_ready,.rd_data,.rd_response_address,.rd_error,
        .release_valid,.release_ready,.release_generation,.release_kind,.release_error,
        .m_axi_arvalid,.m_axi_arready,.m_axi_araddr,.m_axi_arid,.m_axi_arlen,.m_axi_arsize,.m_axi_arburst,
        .m_axi_rvalid,.m_axi_rready,.m_axi_rdata,.m_axi_rid,.m_axi_rresp,.m_axi_rlast);
    for(genvar b=0;b<3;b++)begin: banks
        atomic_mailbox #(.PAYLOAD_WIDTH(545)) return_ack (
            .src_clk(core_clk),.dst_clk(video_clk),.safe_reset_n,
            .src_valid(return_valid[b]),.src_ready(return_ready[b]),.src_data({return_ticket[b],return_kind[b]}),
            .dst_valid(returned_valid[b]),.dst_ready(returned_ready[b]),.dst_data(returned[b]),.src_running(),.dst_running());
        display_row_streamer #(.IMAGE_WIDTH(IMAGE_WIDTH),.IMAGE_HEIGHT(IMAGE_HEIGHT)) stream (
            .video_clk,.safe_reset_n,.reserve_valid(reserve_valid[b]),.reserve_ready(reserve_ready[b]),.reserve_ticket(reserve_ticket[b]),.reserve_discard(reserve_discard[b]),
            .row_valid(row_valid[b]),.row_ready(row_ready[b]),.row_ticket(row_ticket[b]),.owned(owned[b]),.prepared(prepared[b]),
            .display_start(display_start[b]),.display_de(display_de[b]),.display_x_even(in_x_even),.display_demand,.discard(discard[b]),
            .rd_request_valid(rd_request_valid[b]),.rd_request_ready(rd_request_ready[b]),.rd_generation(rd_generation[b]),.rd_address(rd_address[b]),
            .rd_response_valid(rd_response_valid[b]),.rd_response_ready(rd_response_ready[b]),.rd_data(rd_data[b]),.rd_response_address(rd_response_address[b]),.rd_error(rd_error[b]),
            .release_valid(release_valid[b]),.release_ready(release_ready[b]),.release_generation(release_generation[b]),.release_kind(release_kind[b]),.release_error(release_error[b]),
            .pixel_pair(stream_pair[b]),.pixel_valid(stream_pixels_valid[b]),.identity_good(stream_identity_good[b]),.quarantined(stream_q[b]),.local_live(stream_live[b]),.local_ref(stream_ref[b]),
            .line_error(line_error[b]),.shown(shown[b]),.issued(issued[b]),.popped(popped[b]));
    end
    display_scope_fence fence (
        .core_clk,.video_clk,.safe_reset_n,.video_request_valid(fence_valid),.video_request_ready(fence_ready),.video_request(fence_request),
        .video_done_valid(fence_done_valid),.video_done_ready(fence_done_ready),.video_done(fence_done),
        .scope_query_valid,.scope_query_ref,.scope_live,.core_fault,.old_closed_valid,.old_closed_ready,.old_closed_ref,
        .video_quarantined(fence_video_q),.core_quarantined(fence_core_q));
    display_renderer #(.IMAGE_WIDTH(IMAGE_WIDTH),.IMAGE_HEIGHT(IMAGE_HEIGHT)) renderer (
        .clk(video_clk),.rst(!video_running),.in_de,.in_hs,.in_vs,.in_frame_start,.in_x_even,.in_y,
        .in_pair(pixels),.in_render(render),.in_pixels_valid(pixels_valid),.in_identity_good(identity_good),
        .out_rgb_pair,.out_de,.out_hs,.out_vs,.out_frame_start,.out_x_even,.out_y,.out_error);
endmodule
