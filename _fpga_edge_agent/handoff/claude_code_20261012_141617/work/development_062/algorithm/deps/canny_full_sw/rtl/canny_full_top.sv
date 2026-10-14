// PB01..03：RGB→原R2→真实外存分类→实际cache/queue/HY→明确1/8bit私有结果帧。
// done只在各子任务真实排空后公开；完整96bit scope不截断为64bit。
module canny_full_top #(
    parameter integer unsigned WIDTH=1920,HEIGHT=1080,RESULT_ITEM_BITS=8
)(
    input logic clk,rst,
    input logic cj_valid,output wire cj_ready,input logic [141:0] cj,
    input logic [31:0] class_base,queue_base,result_base,
    input logic in_valid,output wire in_ready,input logic [73:0] in_fp,
    output wire grad_valid,input logic grad_ready,output wire [184:0] grad_payload,
    input logic cancel_valid,input logic [95:0] cancel_scope,output wire source_stop,
    output wire done_valid,input logic done_ready,output wire [95:0] done_scope,
    output logic [1:0] outcome,output logic [31:0] reason,
    output logic [20:0] input_pairs,class_pairs,output logic [21:0] output_pixels,edge_pixels,
    output logic [591:0] r2_status_snapshot,output logic [21:0] discarded_pixels,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    output wire [2047:0] flat_wdata,output wire [3:0] flat_select,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained,output wire quarantined,
    output wire  frontend_job_valid,
    input wire  frontend_job_ready,
    output wire [109:0] frontend_job,
    output wire  frontend_input_valid,
    input wire  frontend_input_ready,
    output wire [73:0] frontend_input,
    input wire  frontend_output_valid,
    output wire  frontend_output_ready,
    input wire [138:0] frontend_output,
    input wire  frontend_status_valid,
    output wire  frontend_status_ready,
    input wire [162:0] frontend_status,
    output wire  frontend_cancel,
    output wire shared_sobel_start,shared_sobel_flush,shared_sobel_open,
    output wire shared_sobel_in_valid,input wire shared_sobel_in_ready,
    output wire [40:0] shared_sobel_input,
    input wire shared_sobel_out_valid,output wire shared_sobel_out_ready,
    input wire [108:0] shared_sobel_output,input wire shared_sobel_empty,
    output wire  writer_config_valid,
    input wire  writer_config_ready,
    output wire [95:0] writer_config,
    input wire  writer_config_reply_valid,
    output wire  writer_config_reply_ready,
    input wire  writer_config_error,
    output wire  writer_pixel_valid,
    input wire  writer_pixel_ready,
    output wire [85:0] writer_pixel,
    output wire  writer_abort,
    output wire [63:0] writer_abort_id,
    input wire  writer_done_valid,
    output wire  writer_done_ready,
    input wire [25:0] writer_status,
    input wire  writer_line_valid,
    output wire  writer_line_ready,
    input wire  writer_line_write,
    input wire [31:0] writer_line_addr,
    input wire [511:0] writer_line_wdata,
    output wire  writer_reply_valid,
    input wire  writer_reply_ready,
    output wire [511:0] writer_reply_data,
    output wire  writer_reply_error,
    output wire  writer_reply_drained
);
    wire [1023:0] memory_flat_data;
    wire [1:0] memory_flat_select,external_data_select;
    // 四叶按class/edge/cache/queue排列；仅公共write事务读取这些选择。
    assign flat_wdata={memory_flat_data,edge_rpc_data,class_rpc_data};
    assign flat_select={external_data_select[1]&memory_flat_select[1],
        external_data_select[1]&memory_flat_select[0],
        external_data_select[0]&hy_mode,external_data_select[0]&!hy_mode};

    localparam integer unsigned N=WIDTH*HEIGHT,P=N/2;
    localparam logic [32:0] CLASS_BYTES=33'(((N+255)/256)*64),QUEUE_BYTES=33'(((N+15)/16)*64),RESULT_BYTES=33'(((N*RESULT_ITEM_BITS+511)/512)*64);
    typedef enum logic [3:0] {IDLE,CFG_CLASS_REQ,CFG_CLASS_WAIT,START_R2,R2_RUN,
        CFG_RESULT_REQ,CFG_RESULT_WAIT,START_HY,HY_RUN,FINAL,DONE} state_t;
    state_t state;
    logic [141:0] active_cj;
    logic [31:0] saved_class_base,saved_queue_base,saved_result_base;
    logic [63:0] next_handle,active_handle;
    logic hy_mode,cancel_sticky,failure_sticky;
    logic r2_started,r2_seen,class_seen,hy_started,hy_seen,edge_seen;
    logic r2_success,class_success;
    logic [31:0] failure_mask;
    wire matching_cancel=cancel_valid && cancel_scope==((state==IDLE)?cj[95:0]:active_cj[95:0]);
    wire cancellation=cancel_sticky || matching_cancel;
    wire private_abort=state!=IDLE && state!=DONE && (cancellation || failure_sticky);
    wire [32:0] class_end={1'b0,class_base}+CLASS_BYTES,queue_end={1'b0,queue_base}+QUEUE_BYTES,result_end={1'b0,result_base}+RESULT_BYTES;
    wire class_queue_disjoint=class_end<={1'b0,queue_base} || queue_end<={1'b0,class_base};
    wire class_result_disjoint=class_end<={1'b0,result_base} || result_end<={1'b0,class_base};
    wire queue_result_disjoint=queue_end<={1'b0,result_base} || result_end<={1'b0,queue_base};
    wire job_legal=cj[106:96]==11'(WIDTH) && cj[117:107]==11'(HEIGHT) && cj[128:118]<=cj[139:129] &&
        class_base[5:0]==0 && queue_base[5:0]==0 && result_base[5:0]==0 &&
        class_end<=33'h100000000 && queue_end<=33'h100000000 && result_end<=33'h100000000 &&
        class_queue_disjoint && class_result_disjoint && queue_result_disjoint;
    logic r2_cj_ready,r2_in_ready,r2_class_valid,r2_class_ready,r2_status_valid;
    logic [124:0] r2_class_payload;logic [591:0] r2_status;
    logic class_cfg_ready,class_cfg_rsp_valid,class_cfg_rsp_error,class_done_valid,class_done_error,class_done_aborted,class_done_drained;
    logic [21:0] class_count;
    logic edge_cfg_ready,edge_cfg_rsp_valid,edge_cfg_rsp_error,edge_in_ready,edge_done_valid,edge_done_error,edge_done_aborted,edge_done_drained;
    logic [21:0] edge_count;
    logic class_rpc_valid,class_rpc_ready,class_rpc_write,class_rpc_rsp_ready,class_quarantined;
    logic [31:0] class_rpc_addr;logic [511:0] class_rpc_data;
    logic edge_rpc_valid,edge_rpc_ready,edge_rpc_write,edge_rpc_rsp_ready,edge_quarantined;
    logic [31:0] edge_rpc_addr;logic [511:0] edge_rpc_data;
    logic h_job_ready,h_pixel_valid,h_pixel_ready,h_pixel_edge,h_done_valid,h_quarantined;
    logic [20:0] h_pixel_index;logic [63:0] h_pixel_id,h_done_id;
    logic [1:0] h_outcome;logic [7:0] h_reason;logic [21:0] h_enqueue,h_pop,h_output;
    logic [1:0] rpc_valid,rpc_ready,rpc_write,rpc_rsp_valid,rpc_rsp_ready;
    logic [31:0] rpc_addr[0:1];logic [511:0] rpc_wdata[0:1],rpc_rdata;
    logic rpc_error,rpc_drained,a_quarantined;
    logic complete_r2;
    wire r2_status_fire=r2_status_valid && r2_started && !r2_seen;
    wire class_done_fire=class_done_valid && !class_seen;
    wire hy_done_fire=h_done_valid && hy_started && !hy_seen;
    wire edge_done_fire=edge_done_valid && !edge_seen;
    wire physical_error=line_rsp_valid && line_rsp_ready && line_error;
    assign cj_ready=!rst && state==IDLE && !quarantined && next_handle!=64'hffffffffffffffff;
    assign done_valid=!rst && state==DONE;
    assign done_scope=active_cj[95:0];
    assign source_stop=!rst && state!=IDLE && (private_abort || r2_seen || hy_mode || state==DONE);
    assign in_ready=!rst && !hy_mode && r2_started && !r2_seen && r2_in_ready;
    assign quarantined=class_quarantined || edge_quarantined || h_quarantined || a_quarantined;
    // v1.1：失败writer已真实done后，给HY旧held pixel明确discard消费出口。
    assign h_pixel_ready=edge_in_ready || (private_abort && (edge_seen || edge_done_valid));
    always_comb begin
        rpc_valid[0]=hy_mode ? edge_rpc_valid : class_rpc_valid;
        rpc_write[0]=hy_mode ? edge_rpc_write : class_rpc_write;
        rpc_addr[0]=hy_mode ? edge_rpc_addr : class_rpc_addr;
        rpc_wdata[0]=hy_mode ? edge_rpc_data : class_rpc_data;
        rpc_rsp_ready[0]=hy_mode ? edge_rpc_rsp_ready : class_rpc_rsp_ready;
        complete_r2=r2_status[141:0]==active_cj && r2_status[146:142]==0 && r2_status[178:147]==0 &&
            r2_status[210:183]==28'd30 && r2_status[182:179]==4'd7;
        // CS中的FS：code[431:429]、IDs[527:432]、输入/输出计数[548:528]/[569:549]。
        if(r2_status[431:429]!=0 || r2_status[527:432]!=active_cj[95:0] ||
           r2_status[548:528]!=21'(P) || r2_status[569:549]!=21'(P) || r2_status[591:570]!=0)complete_r2=0;
        for(integer port_number=0;port_number<8;port_number++)begin
            if(r2_status[211+port_number*21+:21]!=(port_number==7 && !active_cj[141] ? 21'd0 : 21'(P)))complete_r2=0;
        end
        if(r2_status[386:379]!=(active_cj[141] ? 8'hff : 8'h7f))complete_r2=0;
    end
    assign class_rpc_ready=!hy_mode && rpc_ready[0];
    assign edge_rpc_ready=hy_mode && rpc_ready[0];

    canny_stream_top #(.W(WIDTH),.H(HEIGHT)) stream(
        .shared_sobel_start,.shared_sobel_flush,.shared_sobel_open,.shared_sobel_in_valid,.shared_sobel_in_ready,
        .shared_sobel_input,.shared_sobel_out_valid,.shared_sobel_out_ready,.shared_sobel_output,.shared_sobel_empty,
        .frontend_job_valid, .frontend_job_ready, .frontend_job, .frontend_input_valid, .frontend_input_ready, .frontend_input, .frontend_output_valid, .frontend_output_ready, .frontend_output, .frontend_status_valid, .frontend_status_ready, .frontend_status, .frontend_cancel,
        
        .clk(clk),.rst(rst),.cancel(private_abort && !hy_mode),
        .cj_valid(state==START_R2),.cj_ready(r2_cj_ready),.cj(active_cj),
        .in_valid(in_valid && !hy_mode && r2_started && !r2_seen),.in_ready(r2_in_ready),.in_fp(in_fp),
        .class_valid(r2_class_valid),.class_ready(r2_class_ready),.class_payload(r2_class_payload),
        .grad_valid(grad_valid),.grad_ready(grad_ready),.grad_payload(grad_payload),
        .status_valid(r2_status_valid),.status_ready(r2_started && !r2_seen),.status_payload(r2_status));
    class_frame_writer #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) classification_writer(
        .clk(clk),.rst(rst),.cfg_valid(state==CFG_CLASS_REQ),.cfg_ready(class_cfg_ready),.cfg_base(saved_class_base),.cfg_id(active_cj[95:0]),
        .cfg_rsp_valid(class_cfg_rsp_valid),.cfg_rsp_ready(state==CFG_CLASS_WAIT),.cfg_rsp_error(class_cfg_rsp_error),
        .in_valid(r2_class_valid),.in_ready(r2_class_ready),.in_payload(r2_class_payload),.abort_valid(private_abort && !hy_mode),.abort_id(active_cj[95:0]),
        .done_valid(class_done_valid),.done_ready(!class_seen),.done_error(class_done_error),.done_aborted(class_done_aborted),.done_drained(class_done_drained),.count(class_count),
        .line_req_valid(class_rpc_valid),.line_req_ready(class_rpc_ready),.line_write(class_rpc_write),.line_addr(class_rpc_addr),.line_wdata(class_rpc_data),
        .line_rsp_valid(!hy_mode && rpc_rsp_valid[0]),.line_rsp_ready(class_rpc_rsp_ready),.line_rdata(rpc_rdata),.line_error(rpc_error),.line_drained(rpc_drained),.quarantined(class_quarantined));
    // 结果写帧器与 Sobel 共用，只有 HY 阶段才产生本任务像素。
    assign writer_config_valid=state==CFG_RESULT_REQ;assign edge_cfg_ready=writer_config_ready;
    assign writer_config={active_handle,saved_result_base};
    assign edge_cfg_rsp_valid=writer_config_reply_valid;assign writer_config_reply_ready=state==CFG_RESULT_WAIT;
    assign edge_cfg_rsp_error=writer_config_error;
    assign writer_pixel_valid=h_pixel_valid;assign edge_in_ready=writer_pixel_ready;
    assign writer_pixel={h_pixel_id,h_pixel_index,h_pixel_edge};
    assign writer_abort=private_abort&&hy_mode;assign writer_abort_id=active_handle;
    assign edge_done_valid=writer_done_valid;assign writer_done_ready=!edge_seen;
    assign edge_count=writer_status[21:0];assign edge_done_error=writer_status[22];
    assign edge_done_aborted=writer_status[23];assign edge_done_drained=writer_status[24];assign edge_quarantined=writer_status[25];
    assign edge_rpc_valid=writer_line_valid;assign writer_line_ready=edge_rpc_ready;
    assign edge_rpc_write=writer_line_write;assign edge_rpc_addr=writer_line_addr;assign edge_rpc_data=writer_line_wdata;
    assign writer_reply_valid=hy_mode&&rpc_rsp_valid[0];assign edge_rpc_rsp_ready=writer_reply_ready;
    assign writer_reply_data=rpc_rdata;assign writer_reply_error=rpc_error;assign writer_reply_drained=rpc_drained;
    canny_memory_top #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) memory_algorithm(
        .flat_wdata(memory_flat_data),.flat_select(memory_flat_select),.clk(clk),.rst(rst),.job_valid(state==START_HY),.job_ready(h_job_ready),.job_id(active_handle),.state_base(saved_class_base),.queue_base(saved_queue_base),
        .cancel_valid(private_abort && hy_mode),.cancel_id(active_handle),
        .pixel_valid(h_pixel_valid),.pixel_ready(h_pixel_ready),.pixel_index(h_pixel_index),.pixel_edge(h_pixel_edge),.pixel_job_id(h_pixel_id),
        .done_valid(h_done_valid),.done_ready(hy_started && !hy_seen),.done_job_id(h_done_id),.outcome(h_outcome),.reason(h_reason),
        .enqueue_count(h_enqueue),.pop_count(h_pop),.output_count(h_output),
        .line_req_valid(rpc_valid[1]),.line_req_ready(rpc_ready[1]),.line_write(rpc_write[1]),.line_addr(rpc_addr[1]),.line_wdata(rpc_wdata[1]),
        .line_rsp_valid(rpc_rsp_valid[1]),.line_rsp_ready(rpc_rsp_ready[1]),.line_rdata(rpc_rdata),.line_error(rpc_error),.line_drained(rpc_drained),.quarantined(h_quarantined));
    line_rpc_arbiter2 external_lines(.data_select(external_data_select),.clk(clk),.rst(rst),.req_valid(rpc_valid),.req_ready(rpc_ready),.req_write(rpc_write),.req_addr(rpc_addr),.req_data(rpc_wdata),
        .rsp_valid(rpc_rsp_valid),.rsp_ready(rpc_rsp_ready),.rsp_data(rpc_rdata),.rsp_error(rpc_error),.rsp_drained(rpc_drained),
        .line_req_valid(line_req_valid),.line_req_ready(line_req_ready),.line_write(line_write),.line_addr(line_addr),.line_wdata(line_wdata),
        .line_rsp_valid(line_rsp_valid),.line_rsp_ready(line_rsp_ready),.line_rdata(line_rdata),.line_error(line_error),.line_drained(line_drained),.quarantined(a_quarantined));

    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;active_cj<=0;saved_class_base<=0;saved_queue_base<=0;saved_result_base<=0;next_handle<=0;active_handle<=0;
            hy_mode<=0;cancel_sticky<=0;failure_sticky<=0;failure_mask<=0;
            r2_started<=0;r2_seen<=0;class_seen<=0;hy_started<=0;hy_seen<=0;edge_seen<=0;r2_success<=0;class_success<=0;
            outcome<=0;reason<=0;input_pairs<=0;class_pairs<=0;output_pixels<=0;edge_pixels<=0;r2_status_snapshot<=0;discarded_pixels<=0;
        end else begin
            if(state!=IDLE && state!=DONE)begin
                if(matching_cancel)cancel_sticky<=1;
                if(physical_error)begin failure_sticky<=1;failure_mask[22]<=1;end
                if(r2_status_fire)begin
                    r2_status_snapshot<=r2_status;r2_seen<=1;r2_success<=complete_r2;
                    input_pairs<=r2_status[231:211];class_pairs<=r2_status[357:337];
                    if(!complete_r2 && !(private_abort && (r2_status[178:147]&32'hfffffffd)==0))begin
                        failure_sticky<=1;failure_mask[24]<=1;
                    end
                end
                if(class_done_fire)begin
                    class_seen<=1;class_success<=!class_done_error && class_done_drained && class_count==22'(P);
                    if(class_done_error && !(class_done_aborted && private_abort))begin failure_sticky<=1;failure_mask[21]<=1;end
                end
                if(hy_done_fire)begin
                    hy_seen<=1;edge_pixels<=h_enqueue;
                    if(h_outcome==1 || (h_outcome==2 && !private_abort) || h_done_id!=active_handle ||
                       (h_outcome==0 && (h_pop!=h_enqueue || h_output!=22'(N))))begin failure_sticky<=1;failure_mask[23]<=1;end
                end
                if(edge_done_fire)begin
                    edge_seen<=1;output_pixels<=edge_count;
                    if(edge_done_error && !(edge_done_aborted && private_abort))begin failure_sticky<=1;failure_mask[21]<=1;end
                end
                if(h_pixel_valid && h_pixel_ready && !edge_in_ready)discarded_pixels<=discarded_pixels+22'd1;
            end
            if(!quarantined)case(state)
                IDLE:if(cj_valid && cj_ready)begin
                    active_cj<=cj;saved_class_base<=class_base;saved_queue_base<=queue_base;saved_result_base<=result_base;
                    active_handle<=next_handle+64'd1;next_handle<=next_handle+64'd1;
                    hy_mode<=0;cancel_sticky<=matching_cancel;failure_sticky<=0;failure_mask<=0;
                    r2_started<=0;r2_seen<=0;class_seen<=0;hy_started<=0;hy_seen<=0;edge_seen<=0;r2_success<=0;class_success<=0;
                    outcome<=0;reason<=0;input_pairs<=0;class_pairs<=0;output_pixels<=0;edge_pixels<=0;r2_status_snapshot<=0;discarded_pixels<=0;
                    if(!job_legal)begin outcome<=1;reason<=32'h00100000;state<=DONE;end else state<=CFG_CLASS_REQ;
                end
                CFG_CLASS_REQ:if(class_cfg_ready)state<=CFG_CLASS_WAIT;
                CFG_CLASS_WAIT:if(class_cfg_rsp_valid)begin
                    if(class_cfg_rsp_error)begin outcome<=1;reason<=32'h00100000;state<=DONE;end else state<=START_R2;
                end
                START_R2:if(r2_cj_ready)begin r2_started<=1;state<=R2_RUN;end
                R2_RUN:if(r2_seen && class_seen)begin
                    if(private_abort || !r2_success || !class_success)state<=FINAL;
                    else begin hy_mode<=1;state<=CFG_RESULT_REQ;end
                end
                CFG_RESULT_REQ:if(edge_cfg_ready)state<=CFG_RESULT_WAIT;
                CFG_RESULT_WAIT:if(edge_cfg_rsp_valid)begin
                    if(edge_cfg_rsp_error)begin outcome<=1;reason<=32'h00100000;state<=DONE;end else state<=START_HY;
                end
                START_HY:if(h_job_ready)begin hy_started<=1;state<=HY_RUN;end
                HY_RUN:if(hy_seen && edge_seen)state<=FINAL;
                FINAL:begin
                    if(failure_sticky)begin outcome<=1;reason<=failure_mask;end
                    else if(cancellation)begin outcome<=2;reason<=0;end
                    else if(!hy_seen || !edge_seen || output_pixels!=22'(N))begin outcome<=1;reason<=32'h01000000;end
                    else begin outcome<=0;reason<=0;end
                    state<=DONE;
                end
                DONE:if(done_ready)state<=IDLE;
                default:begin end
            endcase
        end
    end
    // synthesis translate_off
    initial if(RESULT_ITEM_BITS!=1 && RESULT_ITEM_BITS!=8) $fatal(1,"PB Canny result format");
    // synthesis translate_on
endmodule
