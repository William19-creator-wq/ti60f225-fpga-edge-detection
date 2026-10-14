// 整机选择器：接单时锁定算法，直到真实 DONE 消费后才允许下一任务。
module board_algorithm_rpc #(
    parameter integer WIDTH = 1920, HEIGHT = 1080, RESULT_ITEM_BITS = 1,
    parameter logic [32:0] ADDRESS_BYTES = 33'h10000000
)(
    input wire sobel_mode,
    input logic clk, rst, axi_enable,
    input logic job_valid, output wire job_ready,
    input logic [141:0] job_cj,
    input logic [194:0] job_origin,
    input logic [63:0] job_handle,
    input logic [31:0] source_base, class_base, queue_base, result_base, gradient_base,
    input logic cancel_valid, input logic [95:0] cancel_scope,
    output wire grad_valid, input logic grad_ready, output wire [184:0] grad_payload,
    output wire done_valid, input logic done_ready,
    output wire [95:0] done_scope, output wire [194:0] done_origin,
    output logic [1:0] outcome, output logic [31:0] reason,
    output logic [20:0] reader_pairs, canny_input, canny_class,
    output logic [21:0] output_pixels, edge_pixels, discarded_fp,
    output wire [591:0] r2_status_snapshot,
    output wire [3:0] phase, output wire quarantined, producer_local_quarantined,
    output wire algorithm_req_valid, input logic algorithm_req_ready,
    output wire algorithm_write, output wire [31:0] algorithm_addr,
    output wire [511:0] algorithm_wdata,
    output wire [2559:0] flat_wdata,output wire [4:0] flat_select,
    input logic algorithm_rsp_valid, output wire algorithm_rsp_ready,
    input logic [511:0] algorithm_rdata,
    input logic algorithm_error, algorithm_drained, memory_quarantined
);
    wire [2047:0] canny_flat_data;
    wire [3:0] canny_flat_select;
    wire [1:0] external_data_select;
    // reader恒为read；Sobel写仍来自共用EDGE writer，识别各stage写共用gradient pack。
    assign flat_wdata={gradient_data,canny_flat_data[2047:1024],writer_line_wdata,canny_flat_data[511:0]};
    assign flat_select={external_data_select[1],
        external_data_select[0]&!choose_sobel&canny_flat_select[3],
        external_data_select[0]&!choose_sobel&canny_flat_select[2],
        external_data_select[0]&(choose_sobel||canny_flat_select[1]),
        external_data_select[0]&!choose_sobel&canny_flat_select[0]};

    // 共享 owner 从 job_fire 到 DONE 消费保持。valid/ready 隔离，数据字段广播以减少 LUT。
    wire  c_frontend_job_valid,s_frontend_job_valid,frontend_job_valid;
    assign frontend_job_valid=choose_sobel?s_frontend_job_valid:c_frontend_job_valid;
    wire  c_frontend_job_ready,s_frontend_job_ready,frontend_job_ready;
    assign c_frontend_job_ready=choose_sobel?'0:frontend_job_ready;
    assign s_frontend_job_ready=choose_sobel?frontend_job_ready:'0;
    wire [109:0] c_frontend_job,s_frontend_job,frontend_job;
    assign frontend_job=choose_sobel?s_frontend_job:c_frontend_job;
    wire  c_frontend_input_valid,s_frontend_input_valid,frontend_input_valid;
    assign frontend_input_valid=choose_sobel?s_frontend_input_valid:c_frontend_input_valid;
    wire  c_frontend_input_ready,s_frontend_input_ready,frontend_input_ready;
    assign c_frontend_input_ready=choose_sobel?'0:frontend_input_ready;
    assign s_frontend_input_ready=choose_sobel?frontend_input_ready:'0;
    wire [73:0] c_frontend_input,s_frontend_input,frontend_input;
    assign frontend_input=choose_sobel?s_frontend_input:c_frontend_input;
    wire  c_frontend_output_valid,s_frontend_output_valid,frontend_output_valid;
    assign c_frontend_output_valid=choose_sobel?'0:frontend_output_valid;
    assign s_frontend_output_valid=choose_sobel?frontend_output_valid:'0;
    wire  c_frontend_output_ready,s_frontend_output_ready,frontend_output_ready;
    assign frontend_output_ready=choose_sobel?s_frontend_output_ready:c_frontend_output_ready;
    wire [138:0] c_frontend_output,s_frontend_output,frontend_output;
    assign c_frontend_output=frontend_output;
    assign s_frontend_output=frontend_output;
    wire  c_frontend_status_valid,s_frontend_status_valid,frontend_status_valid;
    assign c_frontend_status_valid=choose_sobel?'0:frontend_status_valid;
    assign s_frontend_status_valid=choose_sobel?frontend_status_valid:'0;
    wire  c_frontend_status_ready,s_frontend_status_ready,frontend_status_ready;
    assign frontend_status_ready=choose_sobel?s_frontend_status_ready:c_frontend_status_ready;
    wire [162:0] c_frontend_status,s_frontend_status,frontend_status;
    assign c_frontend_status=frontend_status;
    assign s_frontend_status=frontend_status;
    wire  c_frontend_cancel,s_frontend_cancel,frontend_cancel;
    assign frontend_cancel=choose_sobel?s_frontend_cancel:c_frontend_cancel;
    wire  c_reader_job_valid,s_reader_job_valid,reader_job_valid;
    assign reader_job_valid=choose_sobel?s_reader_job_valid:c_reader_job_valid;
    wire  c_reader_job_ready,s_reader_job_ready,reader_job_ready;
    assign c_reader_job_ready=choose_sobel?'0:reader_job_ready;
    assign s_reader_job_ready=choose_sobel?reader_job_ready:'0;
    wire [95:0] c_reader_job,s_reader_job,reader_job;
    assign reader_job=choose_sobel?s_reader_job:c_reader_job;
    wire  c_reader_config_valid,s_reader_config_valid,reader_config_valid;
    assign c_reader_config_valid=choose_sobel?'0:reader_config_valid;
    assign s_reader_config_valid=choose_sobel?reader_config_valid:'0;
    wire  c_reader_config_ready,s_reader_config_ready,reader_config_ready;
    assign reader_config_ready=choose_sobel?s_reader_config_ready:c_reader_config_ready;
    wire  c_reader_config_error,s_reader_config_error,reader_config_error;
    assign c_reader_config_error=choose_sobel?'0:reader_config_error;
    assign s_reader_config_error=choose_sobel?reader_config_error:'0;
    wire  c_reader_pixel_valid,s_reader_pixel_valid,reader_pixel_valid;
    assign c_reader_pixel_valid=choose_sobel?'0:reader_pixel_valid;
    assign s_reader_pixel_valid=choose_sobel?reader_pixel_valid:'0;
    wire  c_reader_pixel_ready,s_reader_pixel_ready,reader_pixel_ready;
    assign reader_pixel_ready=choose_sobel?s_reader_pixel_ready:c_reader_pixel_ready;
    wire [137:0] c_reader_pixel,s_reader_pixel,reader_pixel;
    assign c_reader_pixel=reader_pixel;
    assign s_reader_pixel=reader_pixel;
    wire  c_reader_done_valid,s_reader_done_valid,reader_done_valid;
    assign c_reader_done_valid=choose_sobel?'0:reader_done_valid;
    assign s_reader_done_valid=choose_sobel?reader_done_valid:'0;
    wire  c_reader_done_ready,s_reader_done_ready,reader_done_ready;
    assign reader_done_ready=choose_sobel?s_reader_done_ready:c_reader_done_ready;
    wire [161:0] c_reader_status,s_reader_status,reader_status;
    assign c_reader_status=reader_status;
    assign s_reader_status=reader_status;
    wire  c_reader_cancel,s_reader_cancel,reader_cancel;
    assign reader_cancel=choose_sobel?s_reader_cancel:c_reader_cancel;
    wire [63:0] c_reader_cancel_id,s_reader_cancel_id,reader_cancel_id;
    assign reader_cancel_id=choose_sobel?s_reader_cancel_id:c_reader_cancel_id;
    wire  c_reader_line_valid,s_reader_line_valid,reader_line_valid;
    assign c_reader_line_valid=choose_sobel?'0:reader_line_valid;
    assign s_reader_line_valid=choose_sobel?reader_line_valid:'0;
    wire  c_reader_line_ready,s_reader_line_ready,reader_line_ready;
    assign reader_line_ready=choose_sobel?s_reader_line_ready:c_reader_line_ready;
    wire  c_reader_line_write,s_reader_line_write,reader_line_write;
    assign c_reader_line_write=choose_sobel?'0:reader_line_write;
    assign s_reader_line_write=choose_sobel?reader_line_write:'0;
    wire [31:0] c_reader_line_addr,s_reader_line_addr,reader_line_addr;
    assign c_reader_line_addr=reader_line_addr;
    assign s_reader_line_addr=reader_line_addr;
    wire [511:0] c_reader_line_wdata,s_reader_line_wdata,reader_line_wdata;
    assign c_reader_line_wdata=reader_line_wdata;
    assign s_reader_line_wdata=reader_line_wdata;
    wire  c_reader_reply_valid,s_reader_reply_valid,reader_reply_valid;
    assign reader_reply_valid=choose_sobel?s_reader_reply_valid:c_reader_reply_valid;
    wire  c_reader_reply_ready,s_reader_reply_ready,reader_reply_ready;
    assign c_reader_reply_ready=choose_sobel?'0:reader_reply_ready;
    assign s_reader_reply_ready=choose_sobel?reader_reply_ready:'0;
    wire [511:0] c_reader_reply_data,s_reader_reply_data,reader_reply_data;
    assign reader_reply_data=choose_sobel?s_reader_reply_data:c_reader_reply_data;
    wire  c_reader_reply_error,s_reader_reply_error,reader_reply_error;
    assign reader_reply_error=choose_sobel?s_reader_reply_error:c_reader_reply_error;
    wire  c_reader_reply_drained,s_reader_reply_drained,reader_reply_drained;
    assign reader_reply_drained=choose_sobel?s_reader_reply_drained:c_reader_reply_drained;
    wire  c_writer_config_valid,s_writer_config_valid,writer_config_valid;
    assign writer_config_valid=choose_sobel?s_writer_config_valid:c_writer_config_valid;
    wire  c_writer_config_ready,s_writer_config_ready,writer_config_ready;
    assign c_writer_config_ready=choose_sobel?'0:writer_config_ready;
    assign s_writer_config_ready=choose_sobel?writer_config_ready:'0;
    wire [95:0] c_writer_config,s_writer_config,writer_config;
    assign writer_config=choose_sobel?s_writer_config:c_writer_config;
    wire  c_writer_config_reply_valid,s_writer_config_reply_valid,writer_config_reply_valid;
    assign c_writer_config_reply_valid=choose_sobel?'0:writer_config_reply_valid;
    assign s_writer_config_reply_valid=choose_sobel?writer_config_reply_valid:'0;
    wire  c_writer_config_reply_ready,s_writer_config_reply_ready,writer_config_reply_ready;
    assign writer_config_reply_ready=choose_sobel?s_writer_config_reply_ready:c_writer_config_reply_ready;
    wire  c_writer_config_error,s_writer_config_error,writer_config_error;
    assign c_writer_config_error=choose_sobel?'0:writer_config_error;
    assign s_writer_config_error=choose_sobel?writer_config_error:'0;
    wire  c_writer_pixel_valid,s_writer_pixel_valid,writer_pixel_valid;
    assign writer_pixel_valid=choose_sobel?s_writer_pixel_valid:c_writer_pixel_valid;
    wire  c_writer_pixel_ready,s_writer_pixel_ready,writer_pixel_ready;
    assign c_writer_pixel_ready=choose_sobel?'0:writer_pixel_ready;
    assign s_writer_pixel_ready=choose_sobel?writer_pixel_ready:'0;
    wire [85:0] c_writer_pixel,s_writer_pixel,writer_pixel;
    assign writer_pixel=choose_sobel?s_writer_pixel:c_writer_pixel;
    wire  c_writer_abort,s_writer_abort,writer_abort;
    assign writer_abort=choose_sobel?s_writer_abort:c_writer_abort;
    wire [63:0] c_writer_abort_id,s_writer_abort_id,writer_abort_id;
    assign writer_abort_id=choose_sobel?s_writer_abort_id:c_writer_abort_id;
    wire  c_writer_done_valid,s_writer_done_valid,writer_done_valid;
    assign c_writer_done_valid=choose_sobel?'0:writer_done_valid;
    assign s_writer_done_valid=choose_sobel?writer_done_valid:'0;
    wire  c_writer_done_ready,s_writer_done_ready,writer_done_ready;
    assign writer_done_ready=choose_sobel?s_writer_done_ready:c_writer_done_ready;
    wire [25:0] c_writer_status,s_writer_status,writer_status;
    assign c_writer_status=writer_status;
    assign s_writer_status=writer_status;
    wire  c_writer_line_valid,s_writer_line_valid,writer_line_valid;
    assign c_writer_line_valid=choose_sobel?'0:writer_line_valid;
    assign s_writer_line_valid=choose_sobel?writer_line_valid:'0;
    wire  c_writer_line_ready,s_writer_line_ready,writer_line_ready;
    assign writer_line_ready=choose_sobel?s_writer_line_ready:c_writer_line_ready;
    wire  c_writer_line_write,s_writer_line_write,writer_line_write;
    assign c_writer_line_write=choose_sobel?'0:writer_line_write;
    assign s_writer_line_write=choose_sobel?writer_line_write:'0;
    wire [31:0] c_writer_line_addr,s_writer_line_addr,writer_line_addr;
    assign c_writer_line_addr=writer_line_addr;
    assign s_writer_line_addr=writer_line_addr;
    wire [511:0] c_writer_line_wdata,s_writer_line_wdata,writer_line_wdata;
    assign c_writer_line_wdata=writer_line_wdata;
    assign s_writer_line_wdata=writer_line_wdata;
    wire  c_writer_reply_valid,s_writer_reply_valid,writer_reply_valid;
    assign writer_reply_valid=choose_sobel?s_writer_reply_valid:c_writer_reply_valid;
    wire  c_writer_reply_ready,s_writer_reply_ready,writer_reply_ready;
    assign c_writer_reply_ready=choose_sobel?'0:writer_reply_ready;
    assign s_writer_reply_ready=choose_sobel?writer_reply_ready:'0;
    wire [511:0] c_writer_reply_data,s_writer_reply_data,writer_reply_data;
    assign writer_reply_data=choose_sobel?s_writer_reply_data:c_writer_reply_data;
    wire  c_writer_reply_error,s_writer_reply_error,writer_reply_error;
    assign writer_reply_error=choose_sobel?s_writer_reply_error:c_writer_reply_error;
    wire  c_writer_reply_drained,s_writer_reply_drained,writer_reply_drained;
    assign writer_reply_drained=choose_sobel?s_writer_reply_drained:c_writer_reply_drained;
    wire shared_sobel_start,shared_sobel_flush,shared_sobel_open;
    wire shared_sobel_in_valid,shared_sobel_in_ready,shared_sobel_out_valid,shared_sobel_out_ready,shared_sobel_empty;
    wire [40:0] shared_sobel_input;
    wire [108:0] shared_sobel_output;
    reg busy,selected,gradient_enabled,point_started,stats_started,seed_started,dense_started;
    reg [31:0] locked_gradient_base,locked_edge_base;
    wire point_start_ready,point_done,point_fault,point_pack_valid;
    wire [20:0] point_count;
    wire [2:0] point_pack_index;
    wire [63:0] point_pack_data;
    wire point_req_valid,point_req_ready,point_write,point_rsp_valid,point_rsp_ready;
    wire [31:0] point_addr;
    wire stats_start_ready,stats_done,stats_fault,stats_pack_valid;
    wire [2:0] stats_pack_index;
    wire [63:0] stats_pack_data;
    wire stats_req_valid,stats_req_ready,stats_write,stats_rsp_valid,stats_rsp_ready;
    wire [31:0] stats_addr;
    wire anchor_start_ready,anchor_done,anchor_fault,anchor_point_valid,anchor_point_ready;
    wire [63:0] anchor_point;
    wire [9:0] anchor_count;
    wire anchor_req_valid,anchor_req_ready,anchor_rsp_valid,anchor_rsp_ready,anchor_pack_valid;
    wire [31:0] anchor_addr;
    wire [2:0] anchor_pack_index;
    wire [63:0] anchor_pack_data;
    wire seed_start_ready,seed_done,seed_fault,seed_req_valid,seed_req_ready,seed_req_write,seed_rsp_valid,seed_rsp_ready;
    wire seed_pack_valid;wire [31:0] seed_addr;wire [2:0] seed_pack_index;wire [63:0] seed_pack_data;
    wire [8:0] seed_count;
    wire dense_start_ready,dense_done,dense_fault,dense_req_valid,dense_req_ready,dense_req_write;
    wire dense_rsp_valid,dense_rsp_ready,dense_pack_valid;
    wire [31:0] dense_addr;wire [2:0] dense_pack_index;wire [63:0] dense_pack_data;
    wire dense_start=busy&&gradient_enabled&&seed_started&&seed_done&&!seed_fault&&
        !point_fault&&!stats_fault&&!anchor_fault&&!gradient_fault&&!rpc_fault&&
        !dense_started&&dense_start_ready&&gradient_drained;

    wire fit_num_req_valid,fit_num_req_ready,fit_num_rsp_valid,fit_num_rsp_ready,fit_num_cancel_valid;
    wire [621:0] fit_num_req_body;wire [175:0] fit_num_cancel_id;
    wire seed_num_req_valid,seed_num_req_ready,seed_num_rsp_valid,seed_num_rsp_ready;
    wire [621:0] seed_num_req_body;
    wire shared_num_req_ready,shared_num_rsp_valid,shared_num_quiet;
    wire [584:0] shared_num_rsp_body;
    wire [3:0] shared_num_initializer_word_index;
    wire shared_num_initializer_operand_b;
    reg [15:0] shared_num_initializer_word16;
    wire fit_num_b_zero=fit_num_req_body[605:414]==192'd0;
    wire seed_num_b_zero=seed_num_req_body[605:414]==192'd0;
    wire shared_num_b_zero=seed_started ? seed_num_b_zero : fit_num_b_zero;
    // 当前owned正文保持至回复消费/quiet；此读字与B零侧带不能按req_valid门控。
    // 48个固定16位片段提前选字，避免先构造192/384位owner正文再动态切片。
    always @*begin
        shared_num_initializer_word16=16'd0;
        case({seed_started,shared_num_initializer_operand_b,shared_num_initializer_word_index})
            6'd0:shared_num_initializer_word16=fit_num_req_body[222+:16];
            6'd1:shared_num_initializer_word16=fit_num_req_body[238+:16];
            6'd2:shared_num_initializer_word16=fit_num_req_body[254+:16];
            6'd3:shared_num_initializer_word16=fit_num_req_body[270+:16];
            6'd4:shared_num_initializer_word16=fit_num_req_body[286+:16];
            6'd5:shared_num_initializer_word16=fit_num_req_body[302+:16];
            6'd6:shared_num_initializer_word16=fit_num_req_body[318+:16];
            6'd7:shared_num_initializer_word16=fit_num_req_body[334+:16];
            6'd8:shared_num_initializer_word16=fit_num_req_body[350+:16];
            6'd9:shared_num_initializer_word16=fit_num_req_body[366+:16];
            6'd10:shared_num_initializer_word16=fit_num_req_body[382+:16];
            6'd11:shared_num_initializer_word16=fit_num_req_body[398+:16];
            6'd16:shared_num_initializer_word16=fit_num_req_body[414+:16];
            6'd17:shared_num_initializer_word16=fit_num_req_body[430+:16];
            6'd18:shared_num_initializer_word16=fit_num_req_body[446+:16];
            6'd19:shared_num_initializer_word16=fit_num_req_body[462+:16];
            6'd20:shared_num_initializer_word16=fit_num_req_body[478+:16];
            6'd21:shared_num_initializer_word16=fit_num_req_body[494+:16];
            6'd22:shared_num_initializer_word16=fit_num_req_body[510+:16];
            6'd23:shared_num_initializer_word16=fit_num_req_body[526+:16];
            6'd24:shared_num_initializer_word16=fit_num_req_body[542+:16];
            6'd25:shared_num_initializer_word16=fit_num_req_body[558+:16];
            6'd26:shared_num_initializer_word16=fit_num_req_body[574+:16];
            6'd27:shared_num_initializer_word16=fit_num_req_body[590+:16];
            6'd32:shared_num_initializer_word16=seed_num_req_body[222+:16];
            6'd33:shared_num_initializer_word16=seed_num_req_body[238+:16];
            6'd34:shared_num_initializer_word16=seed_num_req_body[254+:16];
            6'd35:shared_num_initializer_word16=seed_num_req_body[270+:16];
            6'd36:shared_num_initializer_word16=seed_num_req_body[286+:16];
            6'd37:shared_num_initializer_word16=seed_num_req_body[302+:16];
            6'd38:shared_num_initializer_word16=seed_num_req_body[318+:16];
            6'd39:shared_num_initializer_word16=seed_num_req_body[334+:16];
            6'd40:shared_num_initializer_word16=seed_num_req_body[350+:16];
            6'd41:shared_num_initializer_word16=seed_num_req_body[366+:16];
            6'd42:shared_num_initializer_word16=seed_num_req_body[382+:16];
            6'd43:shared_num_initializer_word16=seed_num_req_body[398+:16];
            6'd48:shared_num_initializer_word16=seed_num_req_body[414+:16];
            6'd49:shared_num_initializer_word16=seed_num_req_body[430+:16];
            6'd50:shared_num_initializer_word16=seed_num_req_body[446+:16];
            6'd51:shared_num_initializer_word16=seed_num_req_body[462+:16];
            6'd52:shared_num_initializer_word16=seed_num_req_body[478+:16];
            6'd53:shared_num_initializer_word16=seed_num_req_body[494+:16];
            6'd54:shared_num_initializer_word16=seed_num_req_body[510+:16];
            6'd55:shared_num_initializer_word16=seed_num_req_body[526+:16];
            6'd56:shared_num_initializer_word16=seed_num_req_body[542+:16];
            6'd57:shared_num_initializer_word16=seed_num_req_body[558+:16];
            6'd58:shared_num_initializer_word16=seed_num_req_body[574+:16];
            6'd59:shared_num_initializer_word16=seed_num_req_body[590+:16];
            default:shared_num_initializer_word16=16'd0;
        endcase
    end
    wire [4:0] fit_num_rsp_word_index,seed_num_rsp_word_index;
    wire [4:0] shared_num_rsp_word_index=seed_started?seed_num_rsp_word_index:fit_num_rsp_word_index;
    wire [399:0] shared_num_rsp_word_view={15'd0,shared_num_rsp_body[584:200]};
    // FIT bridge在child quiet后仍借用结果：不能按shared rsp_valid/quiet门掉正文。
    // idx24保留bit384，其高15位由每个消费者按原extension补齐；非法索引输出0。
    wire [15:0] shared_num_rsp_word16=shared_num_rsp_word_index < 5'd25 ?
        shared_num_rsp_word_view[shared_num_rsp_word_index*16+:16]:16'd0;
    wire anchor_exporting=stats_started&&stats_done&&!stats_fault&&!seed_started;
    // 阶段切换在FIT完整关闭（包括BORROW_RESULT）、anchor写回及原生信用排空之后。
    wire seed_start=busy&&gradient_enabled&&stats_started&&stats_done&&!stats_fault&&anchor_done&&!anchor_fault&&
        !point_fault&&!gradient_fault&&!rpc_fault&&!seed_started&&seed_start_ready&&shared_num_quiet&&gradient_drained;
    wire stats_start=busy&&gradient_enabled&&point_started&&point_done&&!point_fault&&
        !rpc_fault&&!stats_started&&stats_start_ready&&anchor_start_ready&&gradient_drained;
    wire point_start=busy&&gradient_enabled&&c_done_valid&&c_outcome==0&&gradient_done&&
        !gradient_fault&&!rpc_fault&&!point_started&&point_start_ready;
    wire gradient_start_ready,gradient_input_ready,gradient_done,gradient_fault,rpc_fault;
    wire gradient_req_valid,gradient_req_ready,gradient_rsp_valid,gradient_rsp_ready,gradient_drained;
    wire [31:0] gradient_addr;
    wire [511:0] gradient_data;
    wire core_req_valid,core_req_ready,core_write,core_rsp_valid,core_rsp_ready,core_drained;
    wire [31:0] core_addr;
    wire [511:0] core_wdata;
    wire result_commit_barrier=!gradient_enabled||(gradient_done&&
        (c_outcome!=0||gradient_fault||(point_started&&point_done&&stats_started&&stats_done&&anchor_done&&seed_started&&seed_done&&dense_started&&dense_done)));
    wire canny_grad_ready=grad_ready&&(!gradient_enabled||gradient_input_ready);
    wire choose_sobel=busy?selected:sobel_mode;
    wire  c_job_ready,s_job_ready;
    assign job_ready=!busy&&gradient_start_ready&&point_start_ready&&stats_start_ready&&anchor_start_ready&&seed_start_ready&&dense_start_ready&&(choose_sobel?s_job_ready:c_job_ready);
    wire  c_grad_valid,s_grad_valid;
    assign grad_valid=choose_sobel?s_grad_valid:(c_grad_valid&&(!gradient_enabled||gradient_input_ready));
    wire [184:0] c_grad_payload,s_grad_payload;
    assign grad_payload=choose_sobel?s_grad_payload:c_grad_payload;
    wire  c_done_valid,s_done_valid;
    assign done_valid=(choose_sobel?s_done_valid:c_done_valid)&&result_commit_barrier;
    wire [95:0] c_done_scope,s_done_scope;
    assign done_scope=choose_sobel?s_done_scope:c_done_scope;
    wire [194:0] c_done_origin,s_done_origin;
    assign done_origin=choose_sobel?s_done_origin:c_done_origin;
    wire [1:0] c_outcome,s_outcome;
    assign outcome=gradient_enabled&&(gradient_fault||point_fault||stats_fault||anchor_fault||seed_fault||dense_fault)?2'd1:(choose_sobel?s_outcome:c_outcome);
    wire [31:0] c_reason,s_reason;
    assign reason=gradient_enabled&&dense_fault?32'h80000020:gradient_enabled&&seed_fault?32'h80000010:gradient_enabled&&anchor_fault?32'h80000008:gradient_enabled&&stats_fault?32'h80000004:gradient_enabled&&point_fault?32'h80000002:
        gradient_enabled&&gradient_fault?32'h80000001:(choose_sobel?s_reason:c_reason);
    wire [20:0] c_reader_pairs,s_reader_pairs;
    assign reader_pairs=choose_sobel?s_reader_pairs:c_reader_pairs;
    wire [20:0] c_canny_input,s_canny_input;
    assign canny_input=choose_sobel?s_canny_input:c_canny_input;
    wire [20:0] c_canny_class,s_canny_class;
    assign canny_class=choose_sobel?s_canny_class:c_canny_class;
    wire [21:0] c_output_pixels,s_output_pixels;
    assign output_pixels=choose_sobel?s_output_pixels:c_output_pixels;
    wire [21:0] c_edge_pixels,s_edge_pixels;
    assign edge_pixels=choose_sobel?s_edge_pixels:c_edge_pixels;
    wire [21:0] c_discarded_fp,s_discarded_fp;
    assign discarded_fp=choose_sobel?s_discarded_fp:c_discarded_fp;
    wire [591:0] c_r2_status_snapshot,s_r2_status_snapshot;
    assign r2_status_snapshot=choose_sobel?s_r2_status_snapshot:c_r2_status_snapshot;
    wire [3:0] c_phase,s_phase;
    assign phase=choose_sobel?s_phase:c_phase;
    wire  c_quarantined,s_quarantined;
    assign quarantined=(choose_sobel?s_quarantined:c_quarantined)||gradient_fault||point_fault||stats_fault||anchor_fault||seed_fault||dense_fault||rpc_fault;
    wire  c_producer_local_quarantined,s_producer_local_quarantined;
    assign producer_local_quarantined=(choose_sobel?s_producer_local_quarantined:c_producer_local_quarantined)||gradient_fault||point_fault||stats_fault||anchor_fault||seed_fault||dense_fault||rpc_fault;
    wire  c_algorithm_req_valid,s_algorithm_req_valid;
    assign core_req_valid=choose_sobel?s_algorithm_req_valid:c_algorithm_req_valid;
    wire  c_algorithm_write,s_algorithm_write;
    assign core_write=choose_sobel?s_algorithm_write:c_algorithm_write;
    wire [31:0] c_algorithm_addr,s_algorithm_addr;
    assign core_addr=choose_sobel?s_algorithm_addr:c_algorithm_addr;
    wire [511:0] c_algorithm_wdata,s_algorithm_wdata;
    assign core_wdata=choose_sobel?s_algorithm_wdata:c_algorithm_wdata;
    wire  c_algorithm_rsp_ready,s_algorithm_rsp_ready;
    assign core_rsp_ready=choose_sobel?s_algorithm_rsp_ready:c_algorithm_rsp_ready;
    always @(posedge clk)begin
        if(rst)begin
            busy<=0;selected<=0;gradient_enabled<=0;point_started<=0;stats_started<=0;seed_started<=0;dense_started<=0;
            locked_gradient_base<=0;locked_edge_base<=0;
        end
        else begin
            if(job_valid&&job_ready)begin
                busy<=1;selected<=sobel_mode;gradient_enabled<=!sobel_mode&&job_cj[141];point_started<=0;stats_started<=0;seed_started<=0;dense_started<=0;
                locked_gradient_base<=gradient_base;locked_edge_base<=result_base;
            end
            if(point_start)point_started<=1;
            if(stats_start)stats_started<=1;
            if(seed_start)seed_started<=1;
            if(dense_start)dense_started<=1;
            if(done_valid&&done_ready)busy<=0;
        end
    end
    frame_canny_rpc #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.RESULT_ITEM_BITS(RESULT_ITEM_BITS),.ADDRESS_BYTES(ADDRESS_BYTES)) canny(
        .flat_wdata(canny_flat_data),.flat_select(canny_flat_select),.shared_sobel_start,.shared_sobel_flush,.shared_sobel_open,.shared_sobel_in_valid,.shared_sobel_in_ready,
        .shared_sobel_input,.shared_sobel_out_valid,.shared_sobel_out_ready,.shared_sobel_output,.shared_sobel_empty,
        .frontend_job_valid(c_frontend_job_valid), .frontend_job_ready(c_frontend_job_ready), .frontend_job(c_frontend_job), .frontend_input_valid(c_frontend_input_valid), .frontend_input_ready(c_frontend_input_ready), .frontend_input(c_frontend_input), .frontend_output_valid(c_frontend_output_valid), .frontend_output_ready(c_frontend_output_ready), .frontend_output(c_frontend_output), .frontend_status_valid(c_frontend_status_valid), .frontend_status_ready(c_frontend_status_ready), .frontend_status(c_frontend_status), .frontend_cancel(c_frontend_cancel), .reader_job_valid(c_reader_job_valid), .reader_job_ready(c_reader_job_ready), .reader_job(c_reader_job), .reader_config_valid(c_reader_config_valid), .reader_config_ready(c_reader_config_ready), .reader_config_error(c_reader_config_error), .reader_pixel_valid(c_reader_pixel_valid), .reader_pixel_ready(c_reader_pixel_ready), .reader_pixel(c_reader_pixel), .reader_done_valid(c_reader_done_valid), .reader_done_ready(c_reader_done_ready), .reader_status(c_reader_status), .reader_cancel(c_reader_cancel), .reader_cancel_id(c_reader_cancel_id), .reader_line_valid(c_reader_line_valid), .reader_line_ready(c_reader_line_ready), .reader_line_write(c_reader_line_write), .reader_line_addr(c_reader_line_addr), .reader_line_wdata(c_reader_line_wdata), .reader_reply_valid(c_reader_reply_valid), .reader_reply_ready(c_reader_reply_ready), .reader_reply_data(c_reader_reply_data), .reader_reply_error(c_reader_reply_error), .reader_reply_drained(c_reader_reply_drained), .writer_config_valid(c_writer_config_valid), .writer_config_ready(c_writer_config_ready), .writer_config(c_writer_config), .writer_config_reply_valid(c_writer_config_reply_valid), .writer_config_reply_ready(c_writer_config_reply_ready), .writer_config_error(c_writer_config_error), .writer_pixel_valid(c_writer_pixel_valid), .writer_pixel_ready(c_writer_pixel_ready), .writer_pixel(c_writer_pixel), .writer_abort(c_writer_abort), .writer_abort_id(c_writer_abort_id), .writer_done_valid(c_writer_done_valid), .writer_done_ready(c_writer_done_ready), .writer_status(c_writer_status), .writer_line_valid(c_writer_line_valid), .writer_line_ready(c_writer_line_ready), .writer_line_write(c_writer_line_write), .writer_line_addr(c_writer_line_addr), .writer_line_wdata(c_writer_line_wdata), .writer_reply_valid(c_writer_reply_valid), .writer_reply_ready(c_writer_reply_ready), .writer_reply_data(c_writer_reply_data), .writer_reply_error(c_writer_reply_error), .writer_reply_drained(c_writer_reply_drained),
        .clk(clk),
        .rst(rst),
        .axi_enable(axi_enable),
        .job_valid(job_valid&&job_ready&&!sobel_mode),
        .job_ready(c_job_ready),
        .job_cj(job_cj),
        .job_origin(job_origin),
        .job_handle(job_handle),
        .source_base(source_base),
        .class_base(class_base),
        .queue_base(queue_base),
        .result_base(result_base),
        .cancel_valid(cancel_valid),
        .cancel_scope(cancel_scope),
        .grad_valid(c_grad_valid),
        .grad_ready(canny_grad_ready),
        .grad_payload(c_grad_payload),
        .done_valid(c_done_valid),
        .done_ready(done_ready&&result_commit_barrier),
        .done_scope(c_done_scope),
        .done_origin(c_done_origin),
        .outcome(c_outcome),
        .reason(c_reason),
        .reader_pairs(c_reader_pairs),
        .canny_input(c_canny_input),
        .canny_class(c_canny_class),
        .output_pixels(c_output_pixels),
        .edge_pixels(c_edge_pixels),
        .discarded_fp(c_discarded_fp),
        .r2_status_snapshot(c_r2_status_snapshot),
        .phase(c_phase),
        .quarantined(c_quarantined),
        .producer_local_quarantined(c_producer_local_quarantined),
        .algorithm_req_valid(c_algorithm_req_valid),
        .algorithm_req_ready(core_req_ready),
        .algorithm_write(c_algorithm_write),
        .algorithm_addr(c_algorithm_addr),
        .algorithm_wdata(c_algorithm_wdata),
        .algorithm_rsp_valid(core_rsp_valid),
        .algorithm_rsp_ready(c_algorithm_rsp_ready),
        .algorithm_rdata(algorithm_rdata),
        .algorithm_error(algorithm_error),
        .algorithm_drained(core_drained),
        .memory_quarantined(memory_quarantined));
    board_sobel_rpc #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) sobel(
        .frontend_job_valid(s_frontend_job_valid), .frontend_job_ready(s_frontend_job_ready), .frontend_job(s_frontend_job), .frontend_input_valid(s_frontend_input_valid), .frontend_input_ready(s_frontend_input_ready), .frontend_input(s_frontend_input), .frontend_output_valid(s_frontend_output_valid), .frontend_output_ready(s_frontend_output_ready), .frontend_output(s_frontend_output), .frontend_status_valid(s_frontend_status_valid), .frontend_status_ready(s_frontend_status_ready), .frontend_status(s_frontend_status), .frontend_cancel(s_frontend_cancel), .reader_job_valid(s_reader_job_valid), .reader_job_ready(s_reader_job_ready), .reader_job(s_reader_job), .reader_config_valid(s_reader_config_valid), .reader_config_ready(s_reader_config_ready), .reader_config_error(s_reader_config_error), .reader_pixel_valid(s_reader_pixel_valid), .reader_pixel_ready(s_reader_pixel_ready), .reader_pixel(s_reader_pixel), .reader_done_valid(s_reader_done_valid), .reader_done_ready(s_reader_done_ready), .reader_status(s_reader_status), .reader_cancel(s_reader_cancel), .reader_cancel_id(s_reader_cancel_id), .reader_line_valid(s_reader_line_valid), .reader_line_ready(s_reader_line_ready), .reader_line_write(s_reader_line_write), .reader_line_addr(s_reader_line_addr), .reader_line_wdata(s_reader_line_wdata), .reader_reply_valid(s_reader_reply_valid), .reader_reply_ready(s_reader_reply_ready), .reader_reply_data(s_reader_reply_data), .reader_reply_error(s_reader_reply_error), .reader_reply_drained(s_reader_reply_drained), .writer_config_valid(s_writer_config_valid), .writer_config_ready(s_writer_config_ready), .writer_config(s_writer_config), .writer_config_reply_valid(s_writer_config_reply_valid), .writer_config_reply_ready(s_writer_config_reply_ready), .writer_config_error(s_writer_config_error), .writer_pixel_valid(s_writer_pixel_valid), .writer_pixel_ready(s_writer_pixel_ready), .writer_pixel(s_writer_pixel), .writer_abort(s_writer_abort), .writer_abort_id(s_writer_abort_id), .writer_done_valid(s_writer_done_valid), .writer_done_ready(s_writer_done_ready), .writer_status(s_writer_status), .writer_line_valid(s_writer_line_valid), .writer_line_ready(s_writer_line_ready), .writer_line_write(s_writer_line_write), .writer_line_addr(s_writer_line_addr), .writer_line_wdata(s_writer_line_wdata), .writer_reply_valid(s_writer_reply_valid), .writer_reply_ready(s_writer_reply_ready), .writer_reply_data(s_writer_reply_data), .writer_reply_error(s_writer_reply_error), .writer_reply_drained(s_writer_reply_drained),
        .clk(clk),
        .rst(rst),
        .axi_enable(axi_enable),
        .job_valid(job_valid&&job_ready&&sobel_mode),
        .job_ready(s_job_ready),
        .job_cj(job_cj),
        .job_origin(job_origin),
        .job_handle(job_handle),
        .source_base(source_base),
        .result_base(result_base),
        .done_valid(s_done_valid),
        .done_ready(done_ready&&result_commit_barrier),
        .done_scope(s_done_scope),
        .done_origin(s_done_origin),
        .outcome(s_outcome),
        .reason(s_reason),
        .algorithm_req_valid(s_algorithm_req_valid),
        .algorithm_req_ready(core_req_ready),
        .algorithm_write(s_algorithm_write),
        .algorithm_addr(s_algorithm_addr),
        .algorithm_wdata(s_algorithm_wdata),
        .algorithm_rsp_valid(core_rsp_valid),
        .algorithm_rsp_ready(s_algorithm_rsp_ready),
        .algorithm_rdata(algorithm_rdata),
        .algorithm_error(algorithm_error),
        .algorithm_drained(core_drained),
        .quarantined(s_quarantined));
    assign s_grad_valid='0;
    assign s_grad_payload='0;
    assign s_reader_pairs='0;
    assign s_canny_input='0;
    assign s_canny_class='0;
    assign s_output_pixels='0;
    assign s_edge_pixels='0;
    assign s_discarded_fp='0;
    assign s_r2_status_snapshot='0;
    assign s_phase='0;
    assign s_producer_local_quarantined=s_quarantined;
    // 下游的一次grad接受同时交付给显示候选与DDR；任一方停顿时两方都不接受。
    board_gradient_store #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ORDERED_PACK(1),.RAM_PACK(1),.ADDRESS_BYTES(ADDRESS_BYTES)) gradient_store(
        .clk,.rst,.start(job_valid&&job_ready&&!sobel_mode&&job_cj[141]),
        .producer_finished(c_done_valid&&gradient_enabled),.base(gradient_base),.scope(job_cj[95:0]),
        .start_ready(gradient_start_ready),
        .in_valid(c_grad_valid&&grad_ready&&gradient_enabled),.in_ready(gradient_input_ready),.in_payload(c_grad_payload),
        .point_pack_valid(dense_started?dense_pack_valid:seed_started?seed_pack_valid:anchor_exporting?anchor_pack_valid:stats_started?stats_pack_valid:point_pack_valid),
        .point_pack_index(dense_started?dense_pack_index:seed_started?seed_pack_index:anchor_exporting?anchor_pack_index:stats_started?stats_pack_index:point_pack_index),
        .point_pack_data(dense_started?dense_pack_data:seed_started?seed_pack_data:anchor_exporting?anchor_pack_data:stats_started?stats_pack_data:point_pack_data),
        .req_valid(gradient_req_valid),.req_ready(gradient_req_ready),.req_addr(gradient_addr),.req_data(gradient_data),
        .rsp_valid(gradient_rsp_valid&&!point_started&&!stats_started),.rsp_ready(gradient_rsp_ready),.rsp_error(algorithm_error),.rsp_drained(gradient_drained),
        .done(gradient_done),.fault(gradient_fault),.accepted_pairs());
    // 完整最终EDGE读回与同帧GRAD逐像素配对；16MiB POINT容量覆盖整幅每像素都是边缘的情况。
    board_recognition_points #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ADDRESS_BYTES(ADDRESS_BYTES),.BORROW_SCOPE(1'b1)) recognition_points(
        .clk,.rst,.start(point_start),.scope(c_done_scope),.start_ready(point_start_ready),.done(point_done),.fault(point_fault),.point_count,
        .edge_base(locked_edge_base),.gradient_base(locked_gradient_base),.point_base(32'h05000000),
        .req_valid(point_req_valid),.req_ready(point_req_ready),.req_write(point_write),.req_addr(point_addr),
        .rsp_valid(point_rsp_valid),.rsp_ready(point_rsp_ready),.rsp_data(algorithm_rdata),
        .rsp_error(algorithm_error),.rsp_drained(gradient_drained),.pack_valid(point_pack_valid),.pack_index(point_pack_index),.pack_data(point_pack_data));
    board_recognition_stats #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ADDRESS_BYTES(ADDRESS_BYTES),.BORROW_SCOPE(1'b1),.SHARED_RETURN_WORDS(1'b1)) recognition_stats(
        .clk,.rst,.start(stats_start),.scope(c_done_scope),.points(point_count),
        .point_base(32'h05000000),.stat_base(32'h06000000),
        .start_ready(stats_start_ready),.done(stats_done),.fault(stats_fault),
        .req_valid(stats_req_valid),.req_ready(stats_req_ready),.req_write(stats_write),.req_addr(stats_addr),
        .rsp_valid(stats_rsp_valid),.rsp_ready(stats_rsp_ready),.rsp_data(algorithm_rdata),
        .anchor_point_valid,.anchor_point_ready,.anchor_point,
        .rsp_error(algorithm_error),.rsp_drained(gradient_drained),
        .pack_valid(stats_pack_valid),.pack_index(stats_pack_index),.pack_data(stats_pack_data),
        .shared_req_valid(fit_num_req_valid),.shared_req_body(fit_num_req_body),.shared_req_ready(fit_num_req_ready),
        .shared_rsp_valid(fit_num_rsp_valid),.shared_rsp_body(shared_num_rsp_body),.shared_rsp_ready(fit_num_rsp_ready),
        .shared_cancel_valid(fit_num_cancel_valid),.shared_cancel_id(fit_num_cancel_id),.shared_quiet(shared_num_quiet),
        .shared_rsp_word_index(fit_num_rsp_word_index),.shared_rsp_word16(shared_num_rsp_word16));
    assign point_req_ready=gradient_req_ready&&point_started&&!stats_started;
    assign point_rsp_valid=gradient_rsp_valid&&point_started&&!stats_started;
    board_recognition_anchors #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ADDRESS_BYTES(ADDRESS_BYTES)) anchors(
        .clk,.rst,.start(stats_start),.scope(c_done_scope),.expected_points(point_count),.anchor_base(32'h06001000),
        .in_valid(anchor_point_valid),.in_ready(anchor_point_ready),.in_point(anchor_point),.finish(stats_done),
        .start_ready(anchor_start_ready),.done(anchor_done),.fault(anchor_fault),.anchor_count,
        .req_valid(anchor_req_valid),.req_ready(anchor_req_ready),.req_addr(anchor_addr),
        .rsp_valid(anchor_rsp_valid),.rsp_ready(anchor_rsp_ready),.rsp_error(algorithm_error),.rsp_drained(gradient_drained),
        .pack_valid(anchor_pack_valid),.pack_index(anchor_pack_index),.pack_data(anchor_pack_data));
    assign stats_req_ready=gradient_req_ready&&stats_started&&!anchor_exporting&&!seed_started;
    assign stats_rsp_valid=gradient_rsp_valid&&stats_started&&!anchor_exporting&&!seed_started;
    assign anchor_req_ready=gradient_req_ready&&anchor_exporting;
    assign anchor_rsp_valid=gradient_rsp_valid&&anchor_exporting;
    board_circle_seeds #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ADDRESS_BYTES(ADDRESS_BYTES),.DSP_RECORDS(1'b1),.BORROW_SCOPE(1'b1),.SHARED_RETURN_WORDS(1'b1)) circle_seeds(
        .clk,.rst,.start(seed_start),.scope(c_done_scope),.points(point_count),.anchors(anchor_count),
        .anchor_base(32'h06001000),.seed_base(32'h06003000),.start_ready(seed_start_ready),.done(seed_done),.fault(seed_fault),
        .seed_count,.pairs_visited(),.legal_occurrences(),.local_rejected(),.geometry_rejected(),
        .duplicates(),.rank_pruned(),.rank_replaced(),
        .req_valid(seed_req_valid),.req_ready(seed_req_ready),.req_write(seed_req_write),.req_addr(seed_addr),
        .rsp_valid(seed_rsp_valid),.rsp_ready(seed_rsp_ready),.rsp_data(algorithm_rdata),
        .rsp_error(algorithm_error),.rsp_drained(gradient_drained),
        .pack_valid(seed_pack_valid),.pack_index(seed_pack_index),.pack_data(seed_pack_data),
        .num_req_valid(seed_num_req_valid),.num_req_ready(seed_num_req_ready),.num_req_body(seed_num_req_body),
        .num_rsp_valid(seed_num_rsp_valid),.num_rsp_ready(seed_num_rsp_ready),.num_rsp_body(shared_num_rsp_body),.num_quiet(shared_num_quiet),
        .num_rsp_word_index(seed_num_rsp_word_index),.num_rsp_word16(shared_num_rsp_word16));
    assign seed_req_ready=gradient_req_ready&&seed_started&&!dense_started;
    assign seed_rsp_valid=gradient_rsp_valid&&seed_started&&!dense_started;
    board_hough_dense #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.LANES(4),.ADDRESS_BYTES(ADDRESS_BYTES),.BORROW_SCOPE(1'b1)) hough_dense(
        .clk,.rst,.start(dense_start),.scope(c_done_scope),.points(point_count),
        .point_base(32'h05000000),.dense_base(32'h06400000),.metadata_base(32'h06500000),
        .line_base(32'h06700000),.line_min_support(21'd16),.line_count(),
        .start_ready(dense_start_ready),.done(dense_done),.fault(dense_fault),
        .point_passes(),.point_visits(),.vote_updates(),
        .req_valid(dense_req_valid),.req_ready(dense_req_ready),.req_write(dense_req_write),.req_addr(dense_addr),
        .rsp_valid(dense_rsp_valid),.rsp_ready(dense_rsp_ready),.rsp_data(algorithm_rdata),
        .rsp_error(algorithm_error),.rsp_drained(gradient_drained),
        .pack_valid(dense_pack_valid),.pack_index(dense_pack_index),.pack_data(dense_pack_data));
    assign dense_req_ready=gradient_req_ready&&dense_started;
    assign dense_rsp_valid=gradient_rsp_valid&&dense_started;
    assign fit_num_req_ready=!seed_started&&shared_num_req_ready;
    assign fit_num_rsp_valid=!seed_started&&shared_num_rsp_valid;
    assign seed_num_req_ready=seed_started&&shared_num_req_ready;
    assign seed_num_rsp_valid=seed_started&&shared_num_rsp_valid;
    scalar_core_words #(.BORROW_PAYLOAD(1'b1),.AREA_RAM_WORDS(1'b1),.RAM_RESULT(1'b1),.BORROW_HEADER(1'b1),.BORROW_INITIALIZER_WORDS(1'b1)) shared_recognition_arithmetic(
        .clk,.rst,.req_valid(seed_started?seed_num_req_valid:fit_num_req_valid),
        .req_body(seed_started?seed_num_req_body:fit_num_req_body),.req_ready(shared_num_req_ready),
        .rsp_valid(shared_num_rsp_valid),.rsp_body(shared_num_rsp_body),
        .rsp_ready(seed_started?seed_num_rsp_ready:fit_num_rsp_ready),
        .cancel_valid(!seed_started&&fit_num_cancel_valid),.cancel_id(fit_num_cancel_id),.quiet(shared_num_quiet),
        .initializer_word_index(shared_num_initializer_word_index),.initializer_operand_b(shared_num_initializer_operand_b),
        .borrowed_initializer_word16(shared_num_initializer_word16),.borrowed_b_zero(shared_num_b_zero));
    // 返回数据广播，只有被选中的valid/ready有效；不添加第二份512位快照。
    board_native_rpc_arbiter2 gradient_memory_port(
        .data_select(external_data_select),.clk,.rst,
        .a_valid(core_req_valid),.a_ready(core_req_ready),.a_write(core_write),.a_addr(core_addr),.a_wdata(core_wdata),
        .a_rsp_valid(core_rsp_valid),.a_rsp_ready(core_rsp_ready),.a_drained(core_drained),
        .b_valid(dense_started?dense_req_valid:seed_started?seed_req_valid:anchor_exporting?anchor_req_valid:stats_started?stats_req_valid:point_started?point_req_valid:gradient_req_valid),.b_ready(gradient_req_ready),
        .b_write(dense_started?dense_req_write:seed_started?seed_req_write:anchor_exporting?1'b1:stats_started?stats_write:point_started?point_write:1'b1),
        .b_addr(dense_started?dense_addr:seed_started?seed_addr:anchor_exporting?anchor_addr:stats_started?stats_addr:point_started?point_addr:gradient_addr),.b_wdata(gradient_data),
        .b_rsp_valid(gradient_rsp_valid),.b_rsp_ready(dense_started?dense_rsp_ready:seed_started?seed_rsp_ready:anchor_exporting?anchor_rsp_ready:stats_started?stats_rsp_ready:point_started?point_rsp_ready:gradient_rsp_ready),.b_drained(gradient_drained),
        .req_valid(algorithm_req_valid),.req_ready(algorithm_req_ready),.req_write(algorithm_write),
        .req_addr(algorithm_addr),.req_wdata(algorithm_wdata),
        .rsp_valid(algorithm_rsp_valid),.rsp_ready(algorithm_rsp_ready),.drained(algorithm_drained),.fault(rpc_fault));
    // 原算法模块自身不被替代；三份物理资源仅在串行任务之间复用。
    frontend_frame_pair #(.W(WIDTH),.H(HEIGHT)) shared_frontend(
        .external_sobel_owner(!choose_sobel),.external_sobel_start(shared_sobel_start),
        .external_sobel_flush(shared_sobel_flush),.external_sobel_open(shared_sobel_open),
        .external_sobel_in_valid(shared_sobel_in_valid),.external_sobel_in_ready(shared_sobel_in_ready),
        .external_sobel_input(shared_sobel_input),.external_sobel_out_valid(shared_sobel_out_valid),
        .external_sobel_out_ready(shared_sobel_out_ready),.external_sobel_output(shared_sobel_output),
        .external_sobel_empty(shared_sobel_empty),
        .clk,.rst,.job_valid(frontend_job_valid),.job_ready(frontend_job_ready),
        .job_epoch(frontend_job[31:0]),.job_frame_id(frontend_job[63:32]),.job_config_id(frontend_job[95:64]),
        .job_median_enable(frontend_job[96]),.job_output_kind(frontend_job[98:97]),.job_threshold(frontend_job[109:99]),
        .in_valid(frontend_input_valid),.in_ready(frontend_input_ready),.in_rgb(frontend_input[47:0]),
        .in_x_even(frontend_input[58:48]),.in_y(frontend_input[69:59]),.in_sof(frontend_input[70]),
        .in_eol(frontend_input[71]),.in_eof(frontend_input[72]),.in_bad(frontend_input[73]),
        .out_valid(frontend_output_valid),.out_ready(frontend_output_ready),.out_y_filtered(frontend_output[15:0]),
        .out_edge(frontend_output[17:16]),.out_x_even(frontend_output[28:18]),.out_y(frontend_output[39:29]),
        .out_sof(frontend_output[40]),.out_eol(frontend_output[41]),.out_eof(frontend_output[42]),
        .out_epoch(frontend_output[74:43]),.out_frame_id(frontend_output[106:75]),.out_config_id(frontend_output[138:107]),
        .cancel(frontend_cancel),.status_valid(frontend_status_valid),.status_ready(frontend_status_ready),
        .status_code(frontend_status[2:0]),.status_epoch(frontend_status[34:3]),.status_frame_id(frontend_status[66:35]),
        .status_config_id(frontend_status[98:67]),.status_in_pairs(frontend_status[119:99]),.status_out_pairs(frontend_status[140:120]),
        .status_error_x(frontend_status[151:141]),.status_error_y(frontend_status[162:152]));
    rgb_frame_reader #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) shared_reader(
        .clk,.rst,.job_valid(reader_job_valid),.job_ready(reader_job_ready),.job_base(reader_job[31:0]),.job_handle(reader_job[95:32]),
        .job_rsp_valid(reader_config_valid),.job_rsp_ready(reader_config_ready),.job_rsp_error(reader_config_error),
        .out_valid(reader_pixel_valid),.out_ready(reader_pixel_ready),.out_fp(reader_pixel[73:0]),.out_id(reader_pixel[137:74]),
        .cancel_valid(reader_cancel),.cancel_id(reader_cancel_id),.done_valid(reader_done_valid),.done_ready(reader_done_ready),
        .done_id(reader_status[63:0]),.outcome(reader_status[65:64]),.reason(reader_status[73:66]),
        .prepared_pairs(reader_status[94:74]),.output_pairs(reader_status[115:95]),.read_lines(reader_status[137:116]),
        .discarded_lines(reader_status[159:138]),.source_stop(reader_status[160]),.quarantined(reader_status[161]),
        .line_req_valid(reader_line_valid),.line_req_ready(reader_line_ready),.line_write(reader_line_write),
        .line_addr(reader_line_addr),.line_wdata(reader_line_wdata),.line_rsp_valid(reader_reply_valid),.line_rsp_ready(reader_reply_ready),
        .line_rdata(reader_reply_data),.line_error(reader_reply_error),.line_drained(reader_reply_drained));
    edge_frame_writer #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ITEM_BITS(1)) shared_writer(
        .clk,.rst,.cfg_valid(writer_config_valid),.cfg_ready(writer_config_ready),.cfg_base(writer_config[31:0]),.cfg_id(writer_config[95:32]),
        .cfg_rsp_valid(writer_config_reply_valid),.cfg_rsp_ready(writer_config_reply_ready),.cfg_rsp_error(writer_config_error),
        .in_valid(writer_pixel_valid),.in_ready(writer_pixel_ready),.in_index(writer_pixel[21:1]),.in_edge(writer_pixel[0]),.in_id(writer_pixel[85:22]),
        .abort_valid(writer_abort),.abort_id(writer_abort_id),.done_valid(writer_done_valid),.done_ready(writer_done_ready),
        .count(writer_status[21:0]),.done_error(writer_status[22]),.done_aborted(writer_status[23]),.done_drained(writer_status[24]),.quarantined(writer_status[25]),
        .line_req_valid(writer_line_valid),.line_req_ready(writer_line_ready),.line_write(writer_line_write),
        .line_addr(writer_line_addr),.line_wdata(writer_line_wdata),.line_rsp_valid(writer_reply_valid),.line_rsp_ready(writer_reply_ready),
        .line_rdata(writer_reply_data),.line_error(writer_reply_error),.line_drained(writer_reply_drained));

endmodule
