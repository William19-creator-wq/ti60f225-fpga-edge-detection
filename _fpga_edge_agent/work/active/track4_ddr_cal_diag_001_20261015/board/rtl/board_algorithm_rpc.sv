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
    input logic algorithm_rsp_valid, output wire algorithm_rsp_ready,
    input logic [511:0] algorithm_rdata,
    input logic algorithm_error, algorithm_drained, memory_quarantined
);
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
    // REFINE-001 C1：已移除未上屏的识别数值链（gradient_store/POINT/统计/锚点）。
    // 模式5的框与C/R仍由 board_frame_system 内的 board_shape_tracker 从 grad 流得到。
    reg busy,selected;
    // Canny/Sobel 共用的 64B 访存口；单一调用方，直接连到 video_memory_hub。
    wire core_req_valid,core_req_ready,core_write,core_rsp_valid,core_rsp_ready,core_drained;
    wire [31:0] core_addr;
    wire [511:0] core_wdata;
    wire choose_sobel=busy?selected:sobel_mode;
    wire  c_job_ready,s_job_ready;
    assign job_ready=!busy&&(choose_sobel?s_job_ready:c_job_ready);
    wire  c_grad_valid,s_grad_valid;
    assign grad_valid=choose_sobel?s_grad_valid:c_grad_valid;
    wire [184:0] c_grad_payload,s_grad_payload;
    assign grad_payload=choose_sobel?s_grad_payload:c_grad_payload;
    wire  c_done_valid,s_done_valid;
    assign done_valid=choose_sobel?s_done_valid:c_done_valid;
    wire [95:0] c_done_scope,s_done_scope;
    assign done_scope=choose_sobel?s_done_scope:c_done_scope;
    wire [194:0] c_done_origin,s_done_origin;
    assign done_origin=choose_sobel?s_done_origin:c_done_origin;
    wire [1:0] c_outcome,s_outcome;
    assign outcome=choose_sobel?s_outcome:c_outcome;
    wire [31:0] c_reason,s_reason;
    assign reason=choose_sobel?s_reason:c_reason;
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
    assign quarantined=choose_sobel?s_quarantined:c_quarantined;
    wire  c_producer_local_quarantined,s_producer_local_quarantined;
    assign producer_local_quarantined=choose_sobel?s_producer_local_quarantined:c_producer_local_quarantined;
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
            busy<=0;selected<=0;
        end
        else begin
            // 接单时锁定 Canny/Sobel 选择，直到 DONE 被消费。
            if(job_valid&&job_ready)begin busy<=1;selected<=sobel_mode;end
            if(done_valid&&done_ready)busy<=0;
        end
    end
    frame_canny_rpc #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.RESULT_ITEM_BITS(RESULT_ITEM_BITS),.ADDRESS_BYTES(ADDRESS_BYTES)) canny(
        .shared_sobel_start,.shared_sobel_flush,.shared_sobel_open,.shared_sobel_in_valid,.shared_sobel_in_ready,
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
        .grad_ready(grad_ready),
        .grad_payload(c_grad_payload),
        .done_valid(c_done_valid),
        .done_ready(done_ready),
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
        .done_ready(done_ready),
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
    // REFINE-001 C1：原 gradient_memory_port 仲裁器在只剩一个调用方后去掉，访存口直连。
    // 握手不变：请求在 valid&&ready 同拍被 hub 接收；回复在 rsp_valid&&rsp_ready 同拍被消费。
    assign algorithm_req_valid=core_req_valid;
    assign core_req_ready=algorithm_req_ready;
    assign algorithm_write=core_write;
    assign algorithm_addr=core_addr;
    assign algorithm_wdata=core_wdata;
    assign core_rsp_valid=algorithm_rsp_valid;
    assign algorithm_rsp_ready=core_rsp_ready;
    assign core_drained=algorithm_drained;
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
