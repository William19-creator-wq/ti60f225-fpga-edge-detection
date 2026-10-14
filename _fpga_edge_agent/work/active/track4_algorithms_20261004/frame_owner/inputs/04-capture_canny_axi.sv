// CA01..03：真实源写回/完整RX closure→真实源reader→完整Canny，唯一128bit AXI。
module capture_canny_axi #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000
)(
    input logic clk,rst,axi_enable,
    input logic job_valid,output wire job_ready,input logic [141:0] job_cj,
    input logic [194:0] job_origin,input logic [63:0] job_handle,input logic [1:0] bayer_phase,
    input logic [31:0] source_base,class_base,queue_base,result_base,
    input logic in_valid,output wire in_ready,input logic [19:0] raw_pair,
    input logic [10:0] in_x_even,in_y,input logic [2:0] in_markers,input logic in_bad,input logic [63:0] in_handle,
    input logic rx_close_valid,output wire rx_close_ready,input logic [63:0] rx_close_handle,
    input logic [194:0] rx_close_origin,input logic rx_close_good,
    input logic cancel_valid,input logic [95:0] cancel_scope,
    output wire grad_valid,input logic grad_ready,output wire [184:0] grad_payload,
    output wire done_valid,input logic done_ready,output wire [95:0] done_scope,output wire [194:0] done_origin,
    output logic [1:0] outcome,output logic [31:0] reason,
    output logic [21:0] source_pairs,output logic [20:0] reader_pairs,canny_input,canny_class,
    output logic [21:0] output_pixels,edge_pixels,discarded_fp,output wire [591:0] r2_status_snapshot,
    output wire [3:0] phase,output wire source_stop,quarantined,
    output wire m_axi_awvalid,input logic m_axi_awready,output wire [31:0] m_axi_awaddr,
    output wire [3:0] m_axi_awid,output wire [7:0] m_axi_awlen,output wire [2:0] m_axi_awsize,output wire [1:0] m_axi_awburst,
    output wire m_axi_wvalid,input logic m_axi_wready,output wire [127:0] m_axi_wdata,output wire [15:0] m_axi_wstrb,output wire m_axi_wlast,
    input logic m_axi_bvalid,output wire m_axi_bready,input logic [3:0] m_axi_bid,input logic [1:0] m_axi_bresp,
    output wire m_axi_arvalid,input logic m_axi_arready,output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid,output wire [7:0] m_axi_arlen,output wire [2:0] m_axi_arsize,output wire [1:0] m_axi_arburst,
    input logic m_axi_rvalid,output wire m_axi_rready,input logic [127:0] m_axi_rdata,
    input logic [3:0] m_axi_rid,input logic [1:0] m_axi_rresp,input logic m_axi_rlast
);
    localparam integer N=WIDTH*HEIGHT,P=N/2;
    localparam logic [32:0] SBYTES=33'(((3*N+63)/64)*64),CBYTES=33'(((N+255)/256)*64),
        QBYTES=33'(((N+15)/16)*64),RBYTES=33'(((N+63)/64)*64);
    typedef enum logic [3:0] {IDLE,START_SOURCE,CAPTURE,WAIT_RX,START_CANNY,START_READER,WAIT_READER_CFG,PROCESS,DRAIN,DONE,QUARANTINE} state_t;
    state_t state;
    logic [141:0] cj;logic [194:0] origin;logic [63:0] handle;logic [1:0] locked_bayer;
    logic [31:0] sb,cb,qb,rb;
    logic s_started,s_closed,s_ok,r_started,r_closed,c_started,c_closed,rx_seen,rx_good,stopping,s_cancel_sent;
    wire matching_cancel=cancel_valid && cancel_scope==cj[95:0] && !stopping && state!=IDLE && state!=DONE && state!=QUARANTINE;
    wire child_cancel=stopping || matching_cancel;
    // source父把cancel作为事件；它自己保留停止状态，重复电平不能阻碍终态推进。
    wire source_cancel=child_cancel && s_started && !s_closed && !s_cancel_sent;
    wire [32:0] send={1'b0,source_base}+SBYTES,cend={1'b0,class_base}+CBYTES,
        qend={1'b0,queue_base}+QBYTES,rend={1'b0,result_base}+RBYTES;
    wire legal=job_cj[106:96]==11'(WIDTH) && job_cj[117:107]==11'(HEIGHT) && job_cj[128:118]<=job_cj[139:129] &&
        job_origin[2:0]<6 && job_cj[31:0]==job_origin[98:67] && job_cj[63:32]==job_origin[130:99] &&
        (source_base[5:0]|class_base[5:0]|queue_base[5:0]|result_base[5:0])==0 &&
        send<=ADDRESS_BYTES && cend<=ADDRESS_BYTES && qend<=ADDRESS_BYTES && rend<=ADDRESS_BYTES &&
        (send<={1'b0,class_base} || cend<={1'b0,source_base}) && (send<={1'b0,queue_base} || qend<={1'b0,source_base}) &&
        (send<={1'b0,result_base} || rend<={1'b0,source_base}) && (cend<={1'b0,queue_base} || qend<={1'b0,class_base}) &&
        (cend<={1'b0,result_base} || rend<={1'b0,class_base}) && (qend<={1'b0,result_base} || rend<={1'b0,queue_base});
    wire s_job_ready,s_input_ready,s_done_valid,s_done_ready,s_stop,s_q;
    wire [63:0] s_done_id;wire [95:0] s_done_scope;wire [1:0] s_outcome,s_failed_stage;wire [7:0] s_reason;
    wire [21:0] s_raw,s_rgb,s_lines,s_discard;wire [31:0] s_logical,s_physical;
    wire r_job_ready,r_cfg_valid,r_cfg_error,r_done_valid,r_done_ready,r_stop,r_q,r_out_valid,r_out_ready;
    wire [73:0] r_fp;wire [63:0] r_id,r_done_id;wire [1:0] r_outcome;wire [7:0] r_reason;
    wire [20:0] r_prepared,r_output;wire [21:0] r_lines,r_discard;
    wire c_job_ready,c_input_ready,c_done_valid,c_done_ready,c_stop,c_q;
    wire [95:0] c_done_scope;wire [1:0] c_outcome;wire [31:0] c_reason;
    wire [20:0] c_input,c_classes;wire [21:0] c_output,c_edges,c_discard;
    wire [591:0] c_status_snapshot;
    logic [1:0] sr_valid,sr_ready,sr_write,sr_rsp_valid,sr_rsp_ready;
    logic [31:0] sr_addr[0:1];logic [511:0] sr_data[0:1],sr_rdata;wire sr_error,sr_drained,sr_q;
    logic [1:0] outer_valid,outer_ready,outer_write,outer_rsp_valid,outer_rsp_ready;
    logic [31:0] outer_addr[0:1];logic [511:0] outer_data[0:1],outer_rdata;wire outer_error,outer_drained,outer_q;
    wire line_req_valid,line_req_ready,line_write,line_rsp_valid,line_rsp_ready,line_error,line_drained,bridge_q;
    wire [31:0] line_addr;wire [511:0] line_wdata,line_rdata;
    wire s_fire=s_done_valid && s_done_ready,r_fire=r_done_valid && r_done_ready,c_fire=c_done_valid && c_done_ready;
    wire cfg_fire=state==WAIT_READER_CFG && r_cfg_valid;
    wire rx_fire=rx_close_valid && rx_close_ready;
    wire rx_match=rx_close_handle==handle && rx_close_origin==origin;
    wire discard_enabled=c_closed && child_cancel && r_started && !r_closed && state!=QUARANTINE;
    wire all_closed=s_closed && r_closed && c_closed && (!s_started || rx_seen);
    wire counts_bad=source_pairs!=22'(P) || reader_pairs!=21'(P) || canny_input!=21'(P) || canny_class!=21'(P) || output_pixels!=22'(N) || discarded_fp!=0;
    logic [31:0] error_events;
    always_comb begin
        error_events=0;
        if(state==IDLE && job_valid && job_ready && !legal)error_events[0]=1;
        if(rx_fire && rx_match && !rx_close_good)error_events[1]=1;
        if(s_fire && s_outcome==1)error_events[2]=1;
        if((r_fire && r_outcome==1) || (cfg_fire && r_cfg_error))error_events[3]=1;
        if(c_fire && c_outcome==1)error_events[4]=1;
        if(state==DRAIN && all_closed && outcome==0 && !child_cancel && counts_bad)error_events[5]=1;
    end
    assign job_ready=!rst && state==IDLE && axi_enable && !quarantined && s_job_ready && r_job_ready && c_job_ready;
    assign in_ready=!rst && state==CAPTURE && !child_cancel && !quarantined && s_input_ready;
    assign rx_close_ready=!rst && s_started && !rx_seen && state!=IDLE && state!=DONE && state!=QUARANTINE;
    assign done_valid=!rst && state==DONE;assign done_scope=cj[95:0];assign done_origin=origin;assign phase=state;
    assign r2_status_snapshot=c_started ? c_status_snapshot : 592'd0;
    assign source_stop=child_cancel || s_stop || state!=CAPTURE || quarantined;
    assign quarantined=s_q || r_q || c_q || sr_q || outer_q || bridge_q || state==QUARANTINE;
    assign s_done_ready=!rst && s_started && !s_closed && state!=QUARANTINE;
    assign r_done_ready=!rst && r_started && !r_closed && state!=QUARANTINE;
    assign c_done_ready=!rst && c_started && !c_closed && state!=QUARANTINE;
    assign r_out_ready=discard_enabled || (c_started && !c_closed && c_input_ready);
    raw_source_join #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) capture(
        .clk(clk),.rst(rst),.job_valid(state==START_SOURCE),.job_ready(s_job_ready),.job_base(sb),.job_handle(handle),.job_scope(cj[95:0]),.phase(locked_bayer),
        .in_valid(in_valid && state==CAPTURE && !child_cancel && !quarantined),.in_ready(s_input_ready),.raw_pair(raw_pair),
        .in_x_even(in_x_even),.in_y(in_y),.in_markers(in_markers),.in_bad(in_bad),.in_handle(in_handle),
        .cancel_valid(source_cancel),.cancel_id(handle),.done_valid(s_done_valid),.done_ready(s_done_ready),.done_id(s_done_id),.done_scope(s_done_scope),
        .outcome(s_outcome),.reason(s_reason),.failed_stage(s_failed_stage),.accepted_raw(s_raw),.accepted_rgb(s_rgb),
        .written_lines(s_lines),.discarded_rgb(s_discard),.logical_bytes(s_logical),.physical_bytes(s_physical),.source_stop(s_stop),.quarantined(s_q),
        .line_req_valid(sr_valid[0]),.line_req_ready(sr_ready[0]),.line_write(sr_write[0]),.line_addr(sr_addr[0]),.line_wdata(sr_data[0]),
        .line_rsp_valid(sr_rsp_valid[0]),.line_rsp_ready(sr_rsp_ready[0]),.line_rdata(sr_rdata),.line_error(sr_error),.line_drained(sr_drained));
    rgb_frame_reader #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) reader(
        .clk(clk),.rst(rst),.job_valid(state==START_READER),.job_ready(r_job_ready),.job_base(sb),.job_handle(handle),
        .job_rsp_valid(r_cfg_valid),.job_rsp_ready(state==WAIT_READER_CFG),.job_rsp_error(r_cfg_error),
        .out_valid(r_out_valid),.out_ready(r_out_ready),.out_fp(r_fp),.out_id(r_id),.cancel_valid(child_cancel),.cancel_id(handle),
        .done_valid(r_done_valid),.done_ready(r_done_ready),.done_id(r_done_id),.outcome(r_outcome),.reason(r_reason),
        .prepared_pairs(r_prepared),.output_pairs(r_output),.read_lines(r_lines),.discarded_lines(r_discard),.source_stop(r_stop),.quarantined(r_q),
        .line_req_valid(sr_valid[1]),.line_req_ready(sr_ready[1]),.line_write(sr_write[1]),.line_addr(sr_addr[1]),.line_wdata(sr_data[1]),
        .line_rsp_valid(sr_rsp_valid[1]),.line_rsp_ready(sr_rsp_ready[1]),.line_rdata(sr_rdata),.line_error(sr_error),.line_drained(sr_drained));
    canny_full_top #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) canny(
        .clk(clk),.rst(rst),.cj_valid(state==START_CANNY),.cj_ready(c_job_ready),.cj(cj),.class_base(cb),.queue_base(qb),.result_base(rb),
        .in_valid(r_out_valid && c_started && !c_closed),.in_ready(c_input_ready),.in_fp(r_fp),
        .grad_valid(grad_valid),.grad_ready(grad_ready),.grad_payload(grad_payload),.cancel_valid(child_cancel),.cancel_scope(cj[95:0]),.source_stop(c_stop),
        .done_valid(c_done_valid),.done_ready(c_done_ready),.done_scope(c_done_scope),.outcome(c_outcome),.reason(c_reason),
        .input_pairs(c_input),.class_pairs(c_classes),.output_pixels(c_output),.edge_pixels(c_edges),.r2_status_snapshot(c_status_snapshot),.discarded_pixels(c_discard),
        .line_req_valid(outer_valid[1]),.line_req_ready(outer_ready[1]),.line_write(outer_write[1]),.line_addr(outer_addr[1]),.line_wdata(outer_data[1]),
        .line_rsp_valid(outer_rsp_valid[1]),.line_rsp_ready(outer_rsp_ready[1]),.line_rdata(outer_rdata),.line_error(outer_error),.line_drained(outer_drained),.quarantined(c_q));
    line_rpc_arbiter2 source_group(.clk(clk),.rst(rst),.req_valid(sr_valid),.req_ready(sr_ready),.req_write(sr_write),.req_addr(sr_addr),.req_data(sr_data),
        .rsp_valid(sr_rsp_valid),.rsp_ready(sr_rsp_ready),.rsp_data(sr_rdata),.rsp_error(sr_error),.rsp_drained(sr_drained),
        .line_req_valid(outer_valid[0]),.line_req_ready(outer_ready[0]),.line_write(outer_write[0]),.line_addr(outer_addr[0]),.line_wdata(outer_data[0]),
        .line_rsp_valid(outer_rsp_valid[0]),.line_rsp_ready(outer_rsp_ready[0]),.line_rdata(outer_rdata),.line_error(outer_error),.line_drained(outer_drained),.quarantined(sr_q));
    line_rpc_arbiter2 memory_group(.clk(clk),.rst(rst),.req_valid(outer_valid),.req_ready(outer_ready),.req_write(outer_write),.req_addr(outer_addr),.req_data(outer_data),
        .rsp_valid(outer_rsp_valid),.rsp_ready(outer_rsp_ready),.rsp_data(outer_rdata),.rsp_error(outer_error),.rsp_drained(outer_drained),
        .line_req_valid(line_req_valid),.line_req_ready(line_req_ready),.line_write(line_write),.line_addr(line_addr),.line_wdata(line_wdata),
        .line_rsp_valid(line_rsp_valid),.line_rsp_ready(line_rsp_ready),.line_rdata(line_rdata),.line_error(line_error),.line_drained(line_drained),.quarantined(outer_q));
    axi_line_bridge #(.ADDRESS_BYTES(ADDRESS_BYTES)) memory_bridge(.clk(clk),.rst(rst),.enable(axi_enable),
        .line_req_valid(line_req_valid),.line_req_ready(line_req_ready),.line_write(line_write),.line_addr(line_addr),.line_wdata(line_wdata),
        .line_rsp_valid(line_rsp_valid),.line_rsp_ready(line_rsp_ready),.line_rdata(line_rdata),.line_error(line_error),.line_drained(line_drained),.quarantined(bridge_q),
        .m_axi_awvalid(m_axi_awvalid),.m_axi_awready(m_axi_awready),.m_axi_awaddr(m_axi_awaddr),.m_axi_awid(m_axi_awid),.m_axi_awlen(m_axi_awlen),.m_axi_awsize(m_axi_awsize),.m_axi_awburst(m_axi_awburst),
        .m_axi_wvalid(m_axi_wvalid),.m_axi_wready(m_axi_wready),.m_axi_wdata(m_axi_wdata),.m_axi_wstrb(m_axi_wstrb),.m_axi_wlast(m_axi_wlast),
        .m_axi_bvalid(m_axi_bvalid),.m_axi_bready(m_axi_bready),.m_axi_bid(m_axi_bid),.m_axi_bresp(m_axi_bresp),
        .m_axi_arvalid(m_axi_arvalid),.m_axi_arready(m_axi_arready),.m_axi_araddr(m_axi_araddr),.m_axi_arid(m_axi_arid),.m_axi_arlen(m_axi_arlen),.m_axi_arsize(m_axi_arsize),.m_axi_arburst(m_axi_arburst),
        .m_axi_rvalid(m_axi_rvalid),.m_axi_rready(m_axi_rready),.m_axi_rdata(m_axi_rdata),.m_axi_rid(m_axi_rid),.m_axi_rresp(m_axi_rresp),.m_axi_rlast(m_axi_rlast));
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;cj<=0;origin<=0;handle<=0;locked_bayer<=0;sb<=0;cb<=0;qb<=0;rb<=0;
            s_started<=0;r_started<=0;c_started<=0;s_closed<=1;r_closed<=1;c_closed<=1;s_ok<=0;rx_seen<=0;rx_good<=0;stopping<=0;s_cancel_sent<=0;
            outcome<=0;reason<=0;source_pairs<=0;reader_pairs<=0;canny_input<=0;canny_class<=0;output_pixels<=0;edge_pixels<=0;discarded_fp<=0;
        end else begin
            if(source_cancel)s_cancel_sent<=1;
            if(r_out_valid && r_out_ready && discard_enabled)discarded_fp<=discarded_fp+22'd1;
            case(state)
                IDLE:if(job_valid && job_ready)begin
                    cj<=job_cj;origin<=job_origin;handle<=job_handle;locked_bayer<=bayer_phase;sb<=source_base;cb<=class_base;qb<=queue_base;rb<=result_base;
                    s_started<=0;r_started<=0;c_started<=0;s_closed<=1;r_closed<=1;c_closed<=1;s_ok<=0;rx_seen<=0;rx_good<=0;stopping<=0;s_cancel_sent<=0;
                    outcome<=0;reason<=0;source_pairs<=0;reader_pairs<=0;canny_input<=0;canny_class<=0;output_pixels<=0;edge_pixels<=0;discarded_fp<=0;
                    if(!legal)begin state<=DRAIN;stopping<=1;outcome<=1;reason<=1;end
                    else if(cancel_valid && cancel_scope==job_cj[95:0])begin state<=DRAIN;stopping<=1;outcome<=2;end
                    else state<=START_SOURCE;
                end
                START_SOURCE:if(s_job_ready)begin s_started<=1;s_closed<=0;state<=child_cancel ? DRAIN : CAPTURE;end
                WAIT_RX:if(child_cancel)state<=DRAIN;else if(s_closed && s_ok && rx_seen && rx_good)state<=START_CANNY;
                START_CANNY:if(c_job_ready)begin c_started<=1;c_closed<=0;state<=child_cancel ? DRAIN : START_READER;end
                START_READER:if(r_job_ready)begin r_started<=1;r_closed<=0;state<=WAIT_READER_CFG;end
                WAIT_READER_CFG:if(r_cfg_valid)begin
                    if(r_cfg_error)begin r_closed<=1;stopping<=1;state<=DRAIN;end
                    else state<=child_cancel ? DRAIN : PROCESS;
                end
                DRAIN:if(all_closed && !quarantined)state<=DONE;
                DONE:if(done_ready)state<=IDLE;
                default:begin end
            endcase
            if(rx_fire && rx_match)begin
                rx_seen<=1;rx_good<=rx_close_good;
                if(!rx_close_good)begin stopping<=1;if(state!=START_SOURCE)state<=DRAIN;end
            end
            if(matching_cancel)begin
                stopping<=1;if(outcome==0)outcome<=2;
                if(state!=START_SOURCE && state!=START_CANNY && state!=START_READER && state!=WAIT_READER_CFG)state<=DRAIN;
            end
            if(s_fire)begin
                s_closed<=1;s_ok<=s_outcome==0;source_pairs<=s_raw;
                state<=s_outcome==0 && !child_cancel ? WAIT_RX : DRAIN;
                if(s_outcome!=0)begin stopping<=1;if(outcome==0 && s_outcome==2)outcome<=2;end
            end
            if(r_fire)begin
                r_closed<=1;reader_pairs<=r_output;state<=DRAIN;
                if(r_outcome!=0)begin stopping<=1;if(outcome==0 && r_outcome==2)outcome<=2;end
            end
            if(c_fire)begin
                c_closed<=1;canny_input<=c_input;canny_class<=c_classes;output_pixels<=c_output;edge_pixels<=c_edges;state<=DRAIN;
                if(c_outcome!=0)begin stopping<=1;if(outcome==0 && c_outcome==2)outcome<=2;end
            end
            if(|error_events)begin reason<=((state==IDLE)?32'd0:reason)|error_events;outcome<=1;stopping<=1;end
            if(quarantined)begin state<=QUARANTINE;stopping<=1;outcome<=1;end
        end
    end
    // synthesis translate_off
    initial if(WIDTH<6 || WIDTH>1920 || WIDTH%2 || HEIGHT<5 || HEIGHT>1080)$fatal(1,"Capture-Canny geometry");
    always @(posedge clk)if(!rst)begin
        if(done_valid && (!all_closed || quarantined))$fatal(1,"Capture-Canny done before closure");
        if(s_fire && (s_done_id!=handle || s_done_scope!=cj[95:0]))$fatal(1,"Capture source identity changed");
        if(r_fire && r_done_id!=handle)$fatal(1,"Reader identity changed");
        if(c_fire && c_done_scope!=cj[95:0])$fatal(1,"Canny identity changed");
        if(r_out_valid && r_out_ready && r_id!=handle)$fatal(1,"Reader FP job changed");
    end
    // synthesis translate_on
endmodule
