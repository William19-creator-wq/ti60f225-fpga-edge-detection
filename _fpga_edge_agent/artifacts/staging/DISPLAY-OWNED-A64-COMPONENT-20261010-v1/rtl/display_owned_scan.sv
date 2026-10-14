// DA01/03：唯一实际owner与完整显示扫描；不产生Source/Result关闭证明。
module display_owned_scan #(
    parameter integer IMAGE_WIDTH=1920,IMAGE_HEIGHT=1080,WATCHDOG_CYCLES=50500000,
    parameter logic [63:0] INIT_GENERATION=1,INIT_SCAN=0,INIT_POLICY=1
)(
    input logic cmd_valid,output wire cmd_ready,input logic [940:0] command,
    input logic [63:0] offer_sequence,
    output wire reply_valid,input logic reply_ready,output wire [941:0] reply,
    output wire [17:0] source_states,output wire [8:0] result_states,
    output wire [63:0] latest_handle,freeze_handle,owner_policy,
    output wire owner_frozen,owner_quarantined,source_exhausted,result_exhausted,
    input logic core_clk,video_clk,safe_reset_n,enable,
    input logic control_valid,output wire control_ready,input logic [1136:0] control_request,
    output wire control_response_valid,input logic control_response_ready,output wire [1206:0] control_response,
    input logic cancel_valid,input logic [63:0] cancel_sequence,input logic root_retire_capacity,
    input logic in_de,in_hs,in_vs,in_frame_start,input logic [10:0] in_x_even,in_y,
    output wire [47:0] out_rgb_pair,output wire out_de,out_hs,out_vs,out_frame_start,
    output wire [10:0] out_x_even,out_y,output wire [1:0] out_error,
    output wire lookup_valid,lookup_ready,output wire [478:0] lookup_demand,
    output wire [941:0] lookup_bundle,output wire lookup_permitted,
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
    wire scan_quarantined;
    assign quarantined=scan_quarantined || owner_quarantined;
    frame_owner_read_authority #(.IMAGE_WIDTH(IMAGE_WIDTH),.IMAGE_HEIGHT(IMAGE_HEIGHT),
        .FRAME_ALIGNMENT(64),.INIT_POLICY(INIT_POLICY)) owner (
        .core_clk,.safe_reset_n,.cmd_valid,.cmd_ready,.command,.offer_sequence,
        .lookup_valid,.lookup_ready,.lookup_demand,.lookup_permitted,.lookup_bundle,
        .reply_valid,.reply_ready,.reply,.source_states,.result_states,.latest_handle,.freeze_handle,
        .policy(owner_policy),.frozen(owner_frozen),.quarantined(owner_quarantined),.source_exhausted,.result_exhausted
    );
    display_scan_component #(.IMAGE_WIDTH(IMAGE_WIDTH),.IMAGE_HEIGHT(IMAGE_HEIGHT),
        .FRAME_ALIGNMENT(64),.WATCHDOG_CYCLES(WATCHDOG_CYCLES),.INIT_GENERATION(INIT_GENERATION),
        .INIT_SCAN(INIT_SCAN),.INIT_POLICY(INIT_POLICY)) scan (
        .core_clk,.video_clk,.safe_reset_n,.enable,.control_valid,.control_ready,
        .control_request,.control_response_valid,.control_response_ready,.control_response,.cancel_valid,.cancel_sequence,
        .root_retire_capacity,.in_de,.in_hs,.in_vs,.in_frame_start,.in_x_even,
        .in_y,.out_rgb_pair,.out_de,.out_hs,.out_vs,.out_frame_start,
        .out_x_even,.out_y,.out_error,.lookup_valid,.lookup_ready,.lookup_demand,
        .lookup_bundle,.lookup_permitted,.old_closed_valid,.old_closed_ready,.old_closed_ref,.m_axi_arvalid,
        .m_axi_arready,.m_axi_araddr,.m_axi_arid,.m_axi_arlen,.m_axi_arsize,.m_axi_arburst,
        .m_axi_rvalid,.m_axi_rready,.m_axi_rdata,.m_axi_rid,.m_axi_rresp,.m_axi_rlast,
        .active_valid,.active_bundle,.active_sequence,.scan_token,.video_policy,.frozen,
        .committed,.snapshot_hold,.quarantined(scan_quarantined),.underrun_lines
    );
endmodule
