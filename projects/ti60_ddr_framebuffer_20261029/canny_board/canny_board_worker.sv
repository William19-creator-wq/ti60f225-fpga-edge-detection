// Independent source, classification and result double buffers. Source is
// exact luminance; this worker requires the existing edge-only M5 display.
// Result slots retire only after display ACK with old AXI reads drained.
// Gray-only M5: capture, preprocessing and tracing have separate jobs.
// One independent capture descriptor can run ahead into the
// OTHER source bank while the current job reads/processes its immutable bank.
// Result slots remain held until display ACK; only M5 source ownership changes.
// This specialization requires edge-only display; source/result banks are independent.
// No camera backpressure: overflow rejects a whole snapshot, never a partial job.
// Recognition is omitted in this build. Legacy metadata ports remain tied to zero
// for frame-reader compatibility; cfg_recognition is intentionally ignored.
module canny_board_worker #(parameter integer W=1920,H=1080,FIFO_DEPTH=1024,GRAY_SNAPSHOT=0,HISTORY_SOURCE=0)(
    output wire [87:0] debug_status,
    output logic [63:0] debug_perf,
    input logic core_clk,video_clk,cold_reset_n,enable,
    input logic video_vs,video_de,input logic [47:0] video_rgb,
    input wire video_source_valid,input wire [5:0] video_source_slot,input wire [63:0] video_source_id,
    output reg [63:0] source_pins,output wire [5:0] publish_source_slot,
    input logic [10:0] cfg_threshold,input logic [1:0] cfg_filter,
    input logic [31:0] cfg_config_id,input logic cfg_recognition,
    output logic [31:0] publish_config_id,
    output logic [63:0] publish_sensor_frame,
    output logic publish_recognition,output logic [3:0] publish_target_mask,
    output logic [7:0] publish_target_class,output logic [175:0] publish_target_box,
    output logic [95:0] publish_target_center2,
    output logic [21:0] publish_unknown_count,output logic [7:0] publish_unknown_reasons,
    output logic publish_target_overflow,output logic [63:0] publish_processing_cycles,
    output logic publish_toggle,publish_slot,
    output logic [63:0] publish_frame,
    output logic [10:0] publish_threshold,output logic [1:0] publish_filter,
    input logic retired_valid,input logic [63:0] retired_frame,
    input wire discarded_valid,input wire [63:0] discarded_frame,
    output wire quarantined,output logic [31:0] completed_jobs,failed_jobs,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained
);
    localparam integer N=W*H,P=N/2;
    typedef enum logic [3:0] {IDLE,CONFIG_WAIT,SNAP_START,SNAP_WAIT,CANNY_START,
        READER_START,READER_CONFIG,PROCESS,WAIT_DISPLAY,FAULT,PUBLISH} state_t;
    state_t state;
    (* ASYNC_REG="TRUE" *) logic [1:0] core_reset_pipe,video_reset_pipe;
    always_ff @(posedge core_clk or negedge cold_reset_n)
        if(!cold_reset_n)core_reset_pipe<=3;else core_reset_pipe<={core_reset_pipe[0],1'b0};
    always_ff @(posedge video_clk or negedge cold_reset_n)
        if(!cold_reset_n)video_reset_pipe<=3;else video_reset_pipe<={video_reset_pipe[0],1'b0};
    wire rst=|core_reset_pipe,video_rst=|video_reset_pipe;
    logic config_request,config_ack;
    (* ASYNC_REG="TRUE" *) logic [1:0] config_request_sync,config_ack_sync;
    logic [10:0] config_threshold_hold;
    logic [1:0] config_filter_hold;
    logic [31:0] config_id_hold;
    logic [63:0] sensor_frame,processing_cycles;
    // Bundled mailbox: video payload is stable from ACK until the next request.
    always_ff @(posedge video_clk)begin
        if(video_rst)begin config_request_sync<=0;config_ack<=0;config_threshold_hold<=96;config_filter_hold<=1;config_id_hold<=0;end
        else begin
            config_request_sync<={config_request_sync[0],config_request};
            if(config_request_sync[1]!=config_ack)begin
                config_threshold_hold<=cfg_threshold<2?11'd2:cfg_threshold;
                config_filter_hold<=cfg_filter==0?2'd0:2'd1;config_id_hold<=cfg_config_id;
                config_ack<=config_request_sync[1];
            end
        end
    end
    always_ff @(posedge core_clk)begin
        if(rst)config_ack_sync<=0;else config_ack_sync<={config_ack_sync[0],config_ack};
    end
    typedef enum logic [2:0] {PRE_IDLE,PRE_START,PRE_READER_START,PRE_READER_CONFIG,PRE_RUN,PRE_READY,PRE_FAULT} pre_t;
    pre_t pre_state;
    logic pre_bank,trace_bank;
    logic [63:0] pre_handle,pre_sensor_frame,pre_cycles;
    logic [10:0] pre_threshold;
    logic [1:0] pre_filter;
    logic [31:0] pre_config,pre_failures;
    logic [15:0] pre_capture_ms,pre_elapsed_ms;
    wire [31:0] pre_class_base=pre_bank?32'h06500000:32'h06400000;
    wire [31:0] trace_class_base=trace_bank?32'h06500000:32'h06400000;
    wire [95:0] pre_scope={95'd0,pre_handle[0]};
    wire [141:0] pre_job={1'b0,pre_filter!=0,pre_threshold,(pre_threshold>>1),11'(H),11'(W),pre_scope};
    wire pre_phase=pre_state==PRE_START||pre_state==PRE_READER_START||pre_state==PRE_READER_CONFIG||pre_state==PRE_RUN;
    wire pre_ready,pre_done,pre_in_ready,pre_q,pre_stop,pre_arb_q;
    wire [95:0] pre_done_scope;
    wire [1:0] pre_outcome;
    wire [20:0] pre_inputs,pre_classes;
    wire [21:0] pre_outputs;
    logic pre_closed,pre_good,pre_aborting;
    wire take_preprocessed=state==IDLE && enable && pre_state==PRE_READY;
    initial if(!GRAY_SNAPSHOT)$fatal(1,"Pipelined worker requires edge-only display/source independence");
    typedef enum logic [2:0] {CAP_IDLE,CAP_CONFIG,CAP_START,CAP_WAIT,CAP_READY,CAP_FAULT} capture_t;
    capture_t cap_state;
    logic cap_bank,source_bank;
    logic [63:0] cap_handle,cap_next_handle,cap_frame;
    wire snap_source_valid;wire [5:0] snap_source_slot;
    logic [5:0] cap_source_slot,pre_source_slot,trace_source_slot;
    logic [5:0] result_source_slot[0:1];logic [1:0] result_source_valid;
    assign publish_source_slot=trace_source_slot;
    logic [10:0] cap_threshold;
    logic [1:0] cap_filter;
    logic [31:0] cap_config,cap_failures,algorithm_failures;
    logic [15:0] cap_ms;
    wire take_capture=pre_state==PRE_IDLE && enable && cap_state==CAP_READY;
    wire [31:0] capture_base=cap_bank?32'h04800000:32'h04000000;
    logic slot;
    logic [63:0] handle;
    logic [10:0] threshold;
    logic [1:0] filter;
    logic [31:0] config_id;
    wire [31:0] source_base=source_bank?32'h04800000:32'h04000000;
    wire [31:0] result_base=slot?32'h06200000:32'h06000000;
    // Each stage admits ONE job at a time. Its subordinate engines and bus
    // transactions retire before that stage admits a subsequent job. Separate
    // stages overlap on distinct banks and arbitrate responses by owner.
    // An unknown drain quarantines the worker and prevents all tag reuse.
    // Therefore a one-bit alternating LOCAL transaction epoch is sufficient
    // within these serialized engines. It is not the public frame identity.
    // Source/display/mailbox retain full 64-bit handle, sensor frame and
    // 32-bit configuration; publication and retirement compare full handles.
    // Reducing replicated local tag registers does not reduce frame size,
    // queue capacity, public identity or error/drain checking.
    wire [95:0] scope={95'd0,handle[0]};
    wire [141:0] job={1'b0,filter!=0,threshold,(threshold>>1),11'(H),11'(W),scope};
    wire snap_ready,snap_done,snap_good,snap_q;
    wire [7:0] snap_reason;wire [63:0] snap_handle,snap_video_frame;
    wire [31:0] snap_config,snap_pairs;
    wire snap_req,snap_req_ready,snap_rsp_ready;
    wire [31:0] snap_addr;wire [511:0] snap_data;
    wire capturing=cap_state==CAP_START||cap_state==CAP_WAIT;
    wire snap_memory_rsp,alg_memory_rsp;
    wire overlap_q;
    rgb_snapshot_capture #(.WIDTH(W),.HEIGHT(H),.FIFO_DEPTH(FIFO_DEPTH),.GRAY_ONLY(GRAY_SNAPSHOT),.HISTORY_SOURCE(HISTORY_SOURCE)) snapshot(
        .video_source_valid,.video_source_slot,.video_source_id,.source_pin_valid(snap_source_valid),.source_pin_slot(snap_source_slot),
        .cold_reset_n,.video_clk,.core_clk,.video_vs,.video_de,.video_rgb,
        .job_valid(cap_state==CAP_START),.job_ready(snap_ready),.job_base(capture_base),.job_config_id(cap_config),.job_handle(cap_handle),
        .cancel_valid(1'b0),.cancel_handle(64'd0),.done_valid(snap_done),.done_ready(cap_state==CAP_WAIT),
        .done_good(snap_good),.done_reason(snap_reason),.done_handle(snap_handle),.done_frame_id(snap_video_frame),.done_config_id(snap_config),
        .quarantined(snap_q),.line_req_valid(snap_req),.line_req_ready(snap_req_ready),.line_addr(snap_addr),.line_wdata(snap_data),
        .line_rsp_valid(snap_memory_rsp),.line_rsp_ready(snap_rsp_ready),.line_error,.line_drained,.dropped_frames(),.captured_pairs(snap_pairs));
    wire c_ready,c_done,c_in_ready,c_q,c_stop;
    wire [95:0] c_scope;wire [1:0] c_outcome;wire [31:0] c_reason;
    wire [20:0] c_inputs,c_classes;wire [21:0] c_outputs;
    wire r_ready,r_config_valid,r_config_error,r_valid,r_done,r_q;
    wire [73:0] r_fp;wire [63:0] r_id,r_done_id;wire [1:0] r_outcome;
    logic r_closed,c_closed,r_good,c_good,aborting;
    wire algorithm_phase=state==CANNY_START||state==READER_START||state==READER_CONFIG||state==PROCESS;
    wire [3:0] canny_state;
    logic [7:0] last_capture_reason;
    logic [19:0] input_progress;
    logic [32:0] heartbeat;
    // 100 MHz core clock -> one global millisecond tick. Each phase count
    // has <1 ms quantization. Total is interval between successful display ACKs
    // (first result includes startup); capture is the admitted snapshot duration.
    // Capture and algorithm overlap, so C+P+H no longer equals total.
    // Keep last SUCCESSFULLY RETIRED job measurements; do not publish failures.
    logic [16:0] millisecond_divider;
    wire millisecond_tick=millisecond_divider==17'd99999;
    logic [15:0] capture_ms,preprocess_ms,hysteresis_ms,total_ms;
    function automatic [15:0] sat_ms(input [15:0] value);
        sat_ms=(value==16'hffff) ? value : value+16'd1;
    endfunction
    always_ff @(posedge core_clk)begin
        if(rst)begin
            millisecond_divider<=0;capture_ms<=0;preprocess_ms<=0;
            hysteresis_ms<=0;total_ms<=0;debug_perf<=0;
        end else begin
            millisecond_divider<=millisecond_tick?17'd0:millisecond_divider+17'd1;
            if(take_preprocessed)begin
                capture_ms<=pre_capture_ms;preprocess_ms<=pre_elapsed_ms;hysteresis_ms<=0;
            end
            if(millisecond_tick&&state!=FAULT&&(enable||state!=IDLE))begin
                total_ms<=sat_ms(total_ms);
                if(algorithm_phase&&canny_state==8)hysteresis_ms<=sat_ms(hysteresis_ms);
            end
            if(state==WAIT_DISPLAY&&retired_valid&&retired_frame==handle)begin
                debug_perf<={millisecond_tick?sat_ms(total_ms):total_ms,
                             hysteresis_ms,preprocess_ms,capture_ms};
                total_ms<=0;
            end else if(state==IDLE&&!enable)total_ms<=0;
        end
    end
    // Observability only. No reset, enable, memory ownership or video gating changes.
    assign debug_status={handle[3:0],8'd0,input_progress,heartbeat[32:25],
        last_capture_reason,canny_state,state,failed_jobs[15:0],completed_jobs[15:0]};
    always_ff @(posedge core_clk)begin
        if(rst)begin heartbeat<=0;last_capture_reason<=0;input_progress<=0;end
        else begin
            heartbeat<=heartbeat+1'b1;
            if(cap_state==CAP_WAIT&&snap_done)last_capture_reason<=snap_reason;
            if(pre_state==PRE_START&&pre_ready)input_progress<=0;
            else if(r_valid&&pre_in_ready&&!pre_aborting)input_progress<=input_progress+1'b1;
        end
    end

    wire [1:0] req_valid,req_ready,req_write,rsp_valid,rsp_ready;
    wire [31:0] req_addr[0:1];wire [511:0] req_data[0:1],rsp_data;
    wire rsp_error,rsp_drained,arb_q;
    wire alg_req,alg_ready,alg_write,alg_rsp_ready;
    wire [31:0] alg_addr;wire [511:0] alg_data;
    rgb_frame_reader #(.WIDTH(W),.HEIGHT(H),.GRAY_ONLY(GRAY_SNAPSHOT)) source_reader(
        .clk(core_clk),.rst,.job_valid(pre_state==PRE_READER_START),.job_ready(r_ready),.job_base(source_base),.job_handle(pre_handle),
        .job_rsp_valid(r_config_valid),.job_rsp_ready(pre_state==PRE_READER_CONFIG),.job_rsp_error(r_config_error),
        .out_valid(r_valid),.out_ready(pre_in_ready||pre_aborting),.out_fp(r_fp),.out_id(r_id),
        .cancel_valid(pre_aborting),.cancel_id(pre_handle),.done_valid(r_done),.done_ready(pre_phase&&!r_closed),.done_id(r_done_id),
        .outcome(r_outcome),.reason(),.prepared_pairs(),.output_pairs(),.read_lines(),.discarded_lines(),.source_stop(),.quarantined(r_q),
        .line_req_valid(req_valid[0]),.line_req_ready(req_ready[0]),.line_write(req_write[0]),.line_addr(req_addr[0]),.line_wdata(req_data[0]),
        .line_rsp_valid(rsp_valid[0]),.line_rsp_ready(rsp_ready[0]),.line_rdata(rsp_data),.line_error(rsp_error),.line_drained(rsp_drained));
    wire trace_req,trace_req_ready,trace_write,trace_rsp,trace_rsp_ready;
    wire [31:0] trace_addr;wire [511:0] trace_data;
    canny_full_top #(.WIDTH(W),.HEIGHT(H),.STAGE(1)) preprocess_canny(
        .debug_state(),.clk(core_clk),.rst,.cj_valid(pre_state==PRE_START),.cj_ready(pre_ready),.cj(pre_job),
        .class_base(pre_class_base),.queue_base(32'h06600000),.result_base(32'h06000000),
        .in_valid(r_valid&&!pre_aborting),.in_ready(pre_in_ready),.in_fp(r_fp),
        .grad_valid(),.grad_ready(1'b1),.grad_payload(),.cancel_valid(pre_aborting),.cancel_scope(pre_scope),.source_stop(pre_stop),
        .done_valid(pre_done),.done_ready(pre_phase&&!pre_closed),.done_scope(pre_done_scope),.outcome(pre_outcome),.reason(),
        .input_pairs(pre_inputs),.class_pairs(pre_classes),.output_pixels(pre_outputs),.edge_pixels(),.r2_status_snapshot(),.discarded_pixels(),
        .line_req_valid(req_valid[1]),.line_req_ready(req_ready[1]),.line_write(req_write[1]),.line_addr(req_addr[1]),.line_wdata(req_data[1]),
        .line_rsp_valid(rsp_valid[1]),.line_rsp_ready(rsp_ready[1]),.line_rdata(rsp_data),.line_error(rsp_error),.line_drained(rsp_drained),.quarantined(pre_q));
    canny_full_top #(.WIDTH(W),.HEIGHT(H),.STAGE(2)) complete_canny(
        .debug_state(canny_state),.clk(core_clk),.rst,.cj_valid(state==CANNY_START),.cj_ready(c_ready),.cj(job),
        .class_base(trace_class_base),.queue_base(32'h06600000),.result_base,
        .in_valid(1'b0),.in_ready(c_in_ready),.in_fp(74'd0),
        .grad_valid(),.grad_ready(1'b1),.grad_payload(),.cancel_valid(aborting),.cancel_scope(scope),.source_stop(c_stop),
        .done_valid(c_done),.done_ready(algorithm_phase&&!c_closed),.done_scope(c_scope),.outcome(c_outcome),.reason(c_reason),
        .input_pairs(c_inputs),.class_pairs(c_classes),.output_pixels(c_outputs),.edge_pixels(),.r2_status_snapshot(),.discarded_pixels(),
        .line_req_valid(trace_req),.line_req_ready(trace_req_ready),.line_write(trace_write),.line_addr(trace_addr),.line_wdata(trace_data),
        .line_rsp_valid(trace_rsp),.line_rsp_ready(trace_rsp_ready),.line_rdata,.line_error,.line_drained,.quarantined(c_q));
    wire pre_mem_req,pre_mem_ready,pre_mem_write,pre_mem_rsp,pre_mem_rsp_ready;
    wire [31:0] pre_mem_addr;wire [511:0] pre_mem_data;
    line_rpc_arbiter2 preprocessing_memory(.clk(core_clk),.rst,.req_valid,.req_ready,.req_write,.req_addr,.req_data,
        .rsp_valid,.rsp_ready,.rsp_data,.rsp_error,.rsp_drained,
        .line_req_valid(pre_mem_req),.line_req_ready(pre_mem_ready),.line_write(pre_mem_write),.line_addr(pre_mem_addr),.line_wdata(pre_mem_data),
        .line_rsp_valid(pre_mem_rsp),.line_rsp_ready(pre_mem_rsp_ready),.line_rdata,.line_error,.line_drained,.quarantined(pre_arb_q));
    wire [1:0] stage_req_ready,stage_rsp_valid;
    wire [31:0] stage_addr[0:1];wire [511:0] stage_data[0:1];
    assign stage_addr[0]=pre_mem_addr;assign stage_addr[1]=trace_addr;
    assign stage_data[0]=pre_mem_data;assign stage_data[1]=trace_data;
    assign pre_mem_ready=stage_req_ready[0];assign trace_req_ready=stage_req_ready[1];
    assign pre_mem_rsp=stage_rsp_valid[0];assign trace_rsp=stage_rsp_valid[1];
    line_rpc_arbiter2 algorithm_memory(.clk(core_clk),.rst,
        .req_valid({trace_req,pre_mem_req}),.req_ready(stage_req_ready),.req_write({trace_write,pre_mem_write}),
        .req_addr(stage_addr),.req_data(stage_data),.rsp_valid(stage_rsp_valid),.rsp_ready({trace_rsp_ready,pre_mem_rsp_ready}),
        .rsp_data(),.rsp_error(),.rsp_drained(),
        .line_req_valid(alg_req),.line_req_ready(alg_ready),.line_write(alg_write),.line_addr(alg_addr),.line_wdata(alg_data),
        .line_rsp_valid(alg_memory_rsp),.line_rsp_ready(alg_rsp_ready),.line_rdata,.line_error,.line_drained,.quarantined(arb_q));
    wire [1:0] overlap_valid={alg_req,snap_req};
    wire [1:0] overlap_ready,overlap_response;
    wire [31:0] overlap_addr[0:1];
    wire [511:0] overlap_data[0:1];
    assign overlap_addr[0]=snap_addr;assign overlap_addr[1]=alg_addr;
    assign overlap_data[0]=snap_data;assign overlap_data[1]=alg_data;
    assign snap_req_ready=overlap_ready[0];assign alg_ready=overlap_ready[1];
    assign snap_memory_rsp=overlap_response[0];assign alg_memory_rsp=overlap_response[1];
    // This arbiter keeps ownership through the consumed DDR response. Capture
    // and processing may overlap, but never borrow each other's transactions.
    line_rpc_arbiter2 overlap_memory(.clk(core_clk),.rst,
        .req_valid(overlap_valid),.req_ready(overlap_ready),.req_write({alg_write,1'b1}),
        .req_addr(overlap_addr),.req_data(overlap_data),
        .rsp_valid(overlap_response),.rsp_ready({alg_rsp_ready,snap_rsp_ready}),
        .rsp_data(),.rsp_error(),.rsp_drained(),
        .line_req_valid,.line_req_ready,.line_write,.line_addr,.line_wdata,
        .line_rsp_valid,.line_rsp_ready,.line_rdata,.line_error,.line_drained,.quarantined(overlap_q));
    assign failed_jobs=cap_failures+pre_failures+algorithm_failures;
    // Capture's descriptor is immutable from SNAP start through its transfer
    // to the processing FSM. Two banks suffice: after transfer, capture may
    // fill the opposite bank, then must wait until its READY descriptor is taken.
    // Edge-only display never reads either source bank. PRE does not accept
    // the next source until its previous reader and class writer have drained.
    always_ff @(posedge core_clk)begin
        if(rst)begin
            cap_state<=CAP_IDLE;cap_bank<=0;cap_handle<=0;cap_next_handle<=1;
            cap_threshold<=96;cap_filter<=1;cap_config<=0;cap_frame<=0;cap_source_slot<=0;
            cap_failures<=0;cap_ms<=0;config_request<=0;
        end else if(snap_q||r_q||c_q||arb_q||overlap_q||pre_q||pre_arb_q||pre_state==PRE_FAULT)cap_state<=CAP_FAULT;
        else begin
            if(capturing&&millisecond_tick)cap_ms<=sat_ms(cap_ms);
            case(cap_state)
                CAP_IDLE:if(enable)begin
                    if(cap_next_handle==64'hffffffffffffffff)cap_state<=CAP_FAULT;
                    else begin
                        config_request<=!config_request;cap_state<=CAP_CONFIG;
                    end
                end
                CAP_CONFIG:if(config_ack_sync[1]==config_request)begin
                    cap_threshold<=config_threshold_hold;cap_filter<=config_filter_hold;
                    cap_config<=config_id_hold;cap_handle<=cap_next_handle;
                    cap_ms<=0;cap_state<=CAP_START;
                end
                CAP_START:if(snap_ready)cap_state<=CAP_WAIT;
                CAP_WAIT:if(snap_done)begin
                    if(snap_handle!=cap_handle||snap_config!=cap_config)cap_state<=CAP_FAULT;
                    else begin
                        cap_next_handle<=cap_next_handle+1'b1;
                        if(snap_good&&snap_pairs==P)begin cap_frame<=snap_video_frame;cap_source_slot<=snap_source_slot;cap_state<=CAP_READY;end
                        else begin cap_failures<=cap_failures+1'b1;cap_state<=CAP_IDLE;end
                    end
                end
                CAP_READY:if(take_capture)begin cap_state<=CAP_IDLE;cap_bank<=!cap_bank;end
                CAP_FAULT:begin end
                default:cap_state<=CAP_FAULT;
            endcase
        end
    end
    // Two class banks. PRE_READY is immutable until trace admits it. The
    // opposite bank may then be filled while trace reads/mutates its own bank.
    // Source bank is released only after reader AND preprocessing writer drain.
    always_ff @(posedge core_clk)begin
        if(rst)begin
            pre_state<=PRE_IDLE;pre_bank<=0;source_bank<=0;
            pre_source_slot<=0;pre_handle<=0;pre_sensor_frame<=0;pre_threshold<=96;pre_filter<=1;pre_config<=0;
            pre_capture_ms<=0;pre_elapsed_ms<=0;pre_cycles<=0;
            r_closed<=0;r_good<=0;pre_closed<=0;pre_good<=0;pre_aborting<=0;pre_failures<=0;
        end else if(snap_q||r_q||c_q||arb_q||overlap_q||pre_q||pre_arb_q||cap_state==CAP_FAULT)pre_state<=PRE_FAULT;
        else begin
            if(pre_phase)begin
                pre_cycles<=pre_cycles+1'b1;
                if(millisecond_tick)pre_elapsed_ms<=sat_ms(pre_elapsed_ms);
                if(r_done&&!r_closed)begin
                    r_closed<=1;r_good<=r_outcome==0&&r_done_id==pre_handle;
                    if(r_outcome!=0||r_done_id!=pre_handle)pre_aborting<=1;
                end
                if(pre_done&&!pre_closed)begin
                    pre_closed<=1;pre_good<=pre_outcome==0&&pre_done_scope==pre_scope&&pre_inputs==P&&pre_classes==P;
                    if(pre_outcome!=0||pre_done_scope!=pre_scope||pre_inputs!=P||pre_classes!=P)pre_aborting<=1;
                end
            end
            case(pre_state)
                PRE_IDLE:if(take_capture)begin
                    source_bank<=cap_bank;pre_handle<=cap_handle;pre_sensor_frame<=cap_frame;pre_source_slot<=cap_source_slot;
                    pre_threshold<=cap_threshold;pre_filter<=cap_filter;pre_config<=cap_config;
                    pre_capture_ms<=cap_ms;pre_elapsed_ms<=0;pre_cycles<=0;
                    r_closed<=0;r_good<=0;pre_closed<=0;pre_good<=0;pre_aborting<=0;
                    pre_state<=PRE_START;
                end
                PRE_START:if(pre_ready)pre_state<=PRE_READER_START;
                PRE_READER_START:if(r_ready)pre_state<=PRE_READER_CONFIG;
                PRE_READER_CONFIG:if(r_config_valid)begin
                    if(r_config_error)begin r_closed<=1;r_good<=0;pre_aborting<=1;end
                    pre_state<=PRE_RUN;
                end
                PRE_RUN:if(r_closed&&pre_closed)begin
                    if(r_good&&pre_good&&!pre_aborting)pre_state<=PRE_READY;
                    else begin pre_failures<=pre_failures+1'b1;pre_state<=PRE_IDLE;end
                end
                PRE_READY:if(take_preprocessed)begin pre_bank<=!pre_bank;pre_state<=PRE_IDLE;end
                PRE_FAULT:begin end
                default:pre_state<=PRE_FAULT;
            endcase
        end
    end
    // Bundled-data publication borrows the completed job descriptor/result.
    // The toggle is emitted only in PUBLISH. WAIT_DISPLAY freezes every
    // payload source until the reader has latched it at a video boundary AND
    // acknowledged the full handle after draining its previous AXI reads.
    // Only after that ACK may a new job overwrite these sources. Reader owns
    // its independent latched display metadata by then. Payload outside this
    // handshake is unspecified; no receiver samples it without a new toggle.
    assign publish_config_id=config_id;
    assign publish_sensor_frame=sensor_frame;
    assign publish_recognition=1'b0;
    assign publish_target_mask=4'd0;
    assign publish_target_class=8'd0;
    assign publish_target_box=176'd0;
    assign publish_target_center2=96'd0;
    assign publish_unknown_count=22'd0;
    assign publish_unknown_reasons=8'd0;
    assign publish_target_overflow=1'b0;
    assign publish_processing_cycles=processing_cycles;
    assign publish_slot=slot;
    assign publish_frame=handle;
    assign publish_threshold=threshold;
    assign publish_filter=filter;
    assign quarantined=state==FAULT||cap_state==CAP_FAULT||snap_q||r_q||c_q||arb_q||overlap_q||pre_q||pre_arb_q||pre_state==PRE_FAULT;
    always_ff @(posedge core_clk)begin
        if(rst)begin
            state<=IDLE;slot<=0;trace_bank<=0;handle<=0;threshold<=96;filter<=1;config_id<=0;
            publish_toggle<=0;
            sensor_frame<=0;processing_cycles<=0;trace_source_slot<=0;result_source_valid<=0;result_source_slot[0]<=0;result_source_slot[1]<=0;

            c_closed<=0;c_good<=0;aborting<=0;completed_jobs<=0;algorithm_failures<=0;
        end else if(snap_q||r_q||c_q||arb_q||overlap_q||pre_q||pre_arb_q||pre_state==PRE_FAULT||cap_state==CAP_FAULT)state<=FAULT;
        else begin
            if(algorithm_phase)processing_cycles<=processing_cycles+1;
            if(algorithm_phase)begin
                if(c_done&&!c_closed)begin
                    c_closed<=1;c_good<=c_outcome==0&&c_scope==scope&&c_inputs==P&&c_classes==P&&c_outputs==N;
                    if(c_outcome!=0||c_scope!=scope||c_inputs!=P||c_classes!=P||c_outputs!=N)aborting<=1;
                end
            end
            case(state)
                IDLE:if(take_preprocessed)begin
                    trace_bank<=pre_bank;handle<=pre_handle;sensor_frame<=pre_sensor_frame;trace_source_slot<=pre_source_slot;
                    threshold<=pre_threshold;filter<=pre_filter;config_id<=pre_config;
                    processing_cycles<=pre_cycles;c_closed<=0;c_good<=0;aborting<=0;
                    state<=CANNY_START;
                end
                CANNY_START:if(c_ready)state<=PROCESS;
                PROCESS:if(c_closed)begin
                    if(c_good&&!aborting)begin
                        state<=PUBLISH;
                    end else begin algorithm_failures<=algorithm_failures+1;state<=IDLE;end
                end
                PUBLISH:begin
                    // Engine holds output fields until a new job, after this mailbox retires.

                    result_source_valid[slot]<=1;result_source_slot[slot]<=trace_source_slot;
                    publish_toggle<=!publish_toggle;completed_jobs<=completed_jobs+1;state<=WAIT_DISPLAY;
                end
                WAIT_DISPLAY:begin
                    if(retired_valid&&retired_frame==handle)begin slot<=!slot;state<=IDLE;end
                    else if(HISTORY_SOURCE&&discarded_valid&&discarded_frame==handle)state<=IDLE;
                end
                FAULT:begin end // Never reclaim an uncertain DDR transaction with a local reset.
                default:state<=FAULT;
            endcase
        end
    end
// RAW source ownership spans the complete capture/preprocess/trace/result
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
endmodule
