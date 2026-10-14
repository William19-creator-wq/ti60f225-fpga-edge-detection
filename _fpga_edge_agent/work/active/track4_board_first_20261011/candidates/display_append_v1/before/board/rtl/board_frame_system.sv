// 上板整机：原图与结果独立归属；冻结变参重处理，完整结果才在扫描边界发布。
module board_frame_system #(parameter [1:0] BAYER_PHASE=2'd1)(
    input wire core_clk,rx_clk,video_clk,safe_reset_n,cal_done,
    input wire key_inc_n,key_dec_n,key_mode_n,
    input wire raw_vs,raw_hs,raw_de,input wire [39:0] raw_quad,
    output wire [47:0] rgb_pair,output wire rgb_vs,rgb_hs,rgb_de,
    output wire fault,output wire frozen,
    output wire  m_axi_awvalid,
    input wire  m_axi_awready,
    output wire [31:0] m_axi_awaddr,
    output wire [3:0] m_axi_awid,
    output wire [7:0] m_axi_awlen,
    output wire [2:0] m_axi_awsize,
    output wire [1:0] m_axi_awburst,
    output wire  m_axi_wvalid,
    input wire  m_axi_wready,
    output wire [127:0] m_axi_wdata,
    output wire [15:0] m_axi_wstrb,
    output wire  m_axi_wlast,
    input wire  m_axi_bvalid,
    output wire  m_axi_bready,
    input wire [3:0] m_axi_bid,
    input wire [1:0] m_axi_bresp,
    output wire  m_axi_arvalid,
    input wire  m_axi_arready,
    output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid,
    output wire [7:0] m_axi_arlen,
    output wire [2:0] m_axi_arsize,
    output wire [1:0] m_axi_arburst,
    input wire  m_axi_rvalid,
    output wire  m_axi_rready,
    input wire [127:0] m_axi_rdata,
    input wire [3:0] m_axi_rid,
    input wire [1:0] m_axi_rresp,
    input wire  m_axi_rlast
);
    (* ASYNC_REG="TRUE" *) reg [1:0] core_reset_pipe,cal_pipe;
    always @(posedge core_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin core_reset_pipe<=2'b11;cal_pipe<=0;end
        else begin core_reset_pipe<={core_reset_pipe[0],1'b0};cal_pipe<={cal_pipe[0],cal_done};end
    end
    wire rst=|core_reset_pipe;
    wire cal_ready=cal_pipe[1];
    localparam C_IDLE=0,C_JOB=1,C_RUN=2,C_TAIL=3,A_JOB=4,A_RUN=5;
    reg [2:0] control_state,display_mode;
    reg freeze;
    reg [24:0] mode_hold;reg long_seen;
    wire mode_press,mode_pressed;
    wire [10:0] pending_threshold,active_threshold;
    wire inc_pressed,dec_pressed;reg both_pressed_old;reg [1:0] phase_pending;
    wire [31:0] source_base,cap_base,result_base;
    reg [31:0] frame_seq,config_seq,job_frame;
    reg work_bank,display_bank,pending_bank,display_valid,pending_valid,job_sobel;
    reg work_source,control_fault;
    reg [10:0] job_threshold;
    reg job_recognition;
    reg [2:0] job_display_mode;
    reg saved_source[0:1];
    reg [31:0] saved_frame[0:1];
    reg [12:0] saved_signature[0:1];
    reg [2:0] saved_display_mode[0:1];
    wire [12:0] desired_signature={display_mode==5,display_mode==2,pending_threshold};
    wire [12:0] job_signature={job_recognition,job_sobel,job_threshold};
    wire [141:0] alg_cj={job_recognition,1'b1,job_threshold,(job_threshold>>1),11'd1080,11'd1920,config_seq,job_frame,32'd1};
    wire [194:0] alg_origin={64'd0,job_frame,32'd1,64'd1,3'd0};
    wire [95:0] cap_scope={config_seq,job_frame,32'd1};
    wire [63:0] cap_handle={32'd1,job_frame};
    function automatic [31:0] source_address(input slot);
        source_address=slot?32'h00800000:32'h00000000;
    endfunction
    assign cap_base=source_address(work_source);
    assign source_base=cap_base;
    assign result_base=work_bank?32'h01100000:32'h01000000;
    assign frozen=freeze;
    wire cap_job_ready,in_ready,cap_done_valid,cap_stop,cap_q;
    wire [1:0] cap_outcome;
    wire alg_job_ready,alg_done_valid,grad_valid,grad_ready,algorithm_q,memory_q;
    wire [1:0] alg_outcome;wire [184:0] grad_payload;
    wire cap_job_valid=control_state==C_JOB;
    wire alg_job_valid=control_state==A_JOB;
    wire job_fire=alg_job_valid&&alg_job_ready;
    live_threshold_control #(.DEBOUNCE_CYCLES(500000)) thresholds(
        .clk(core_clk),.rst,.raw_inc_n(key_inc_n),.raw_dec_n(key_dec_n),.job_fire,
        .pending_threshold,.active_threshold,.inc_pressed,.dec_pressed);
    // 双键消抖后仅触发一次；raw_source_join 在 job_fire 锁相位，帧内不会变化。
    always @(posedge core_clk)begin
        if(rst)begin both_pressed_old<=0;phase_pending<=BAYER_PHASE;end
        else begin
            both_pressed_old<=inc_pressed&&dec_pressed;
            if(inc_pressed&&dec_pressed&&!both_pressed_old)phase_pending<=phase_pending+2'd1;
        end
    end
    key_press_debouncer #(.DEBOUNCE_CYCLES(500000)) mode_key(
        .clk(core_clk),.rst,.raw_key_n(key_mode_n),.press(mode_press),.stable_pressed(mode_pressed));
    // 同沿冻结与显示计划到达时，先固定旧显示源，不能让旧pending抢先换原图。
    wire freeze_toggle=mode_pressed&&!long_seen&&mode_hold==25'd19999999;
    wire freeze_enter=freeze_toggle&&!freeze;
    wire freeze_exit=freeze_toggle&&freeze;
    wire freeze_requested=freeze||freeze_enter;
    always @(posedge core_clk)begin
        if(rst)begin freeze<=0;display_mode<=4;mode_hold<=0;long_seen<=0;end
        else begin
            if(mode_pressed)begin
                if(!long_seen)begin
                    if(mode_hold==25'd19999999)begin freeze<=!freeze;long_seen<=1;end
                    else mode_hold<=mode_hold+1'b1;
                end
            end else begin
                if(mode_hold!=0&&!long_seen)display_mode<=display_mode==5?3'd0:display_mode+1'b1;
                mode_hold<=0;long_seen<=0;
            end
        end
    end
    // CSI 不可反压：空闲时丢过整帧，只在新的(0,0)领取；采集失败不发布。
    reg raw_vs_d;reg [10:0] raw_x,raw_y;
    wire raw_valid=raw_de&&raw_hs;
    always @(posedge rx_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin raw_vs_d<=0;raw_x<=0;raw_y<=0;end
        else begin
            raw_vs_d<=raw_vs;
            if(raw_vs&&!raw_vs_d)begin raw_x<=0;raw_y<=0;end
            else if(raw_valid)begin
                if(raw_x==1916)begin raw_x<=0;raw_y<=raw_y==1079?11'd0:raw_y+1'b1;end
                else raw_x<=raw_x+11'd4;
            end
        end
    end
    wire rx_valid,rx_ready,rx_fault,rx_overflow;
    wire [63:0] rx_record;
    video_async_fifo #(.WIDTH(64),.DEPTH(2048)) camera_fifo(
        .cold_reset_n(safe_reset_n),.wr_clk(rx_clk),.rd_clk(core_clk),
        .wr_valid(raw_valid),.wr_data({2'd0,raw_y,raw_x,raw_quad}),.wr_overflow(rx_overflow),
        .rd_ready(rx_ready),.rd_valid(rx_valid),.rd_data(rx_record),.rd_fault(rx_fault));
    reg half;
    wire capture_active=control_state==C_RUN;
    wire capture_valid=capture_active&&rx_valid;
    wire [10:0] input_x=rx_record[50:40]+(half?11'd2:11'd0);
    wire [10:0] input_y=rx_record[61:51];
    wire [2:0] markers={input_x==1918&&input_y==1079,input_x==1918,input_x==0&&input_y==0};
    wire input_fire=capture_valid&&in_ready;
    // 冻结只发布同源结果，显示源就是冻结源；两原图槽无需第三槽或额外冻结快照。
    // 分配仅发生于无作业/pending/save的空闲沿，另一源槽已经没有读取者。
    wire free_source=display_valid?!saved_source[display_bank]:1'b0;
    wire idle_for_job=control_state==C_IDLE&&!pending_valid&&!save_shapes&&!display_begin&&!fault;
    // 首帧前冻结也允许完成一次采集；没有有效原图时不能提出重处理。
    wire capture_candidate=idle_for_job&&rx_valid&&rx_record[61:40]==0&&cal_ready&&
        (!freeze_requested||!display_valid);
    wire capture_start=capture_candidate&&frame_seq!=32'hffffffff&&config_seq!=32'hffffffff;
    assign rx_ready=capture_active?(in_ready&&half):((control_state==C_JOB||capture_start)?1'b0:1'b1);
    wire display_begin,display_fault;
    wire freeze_reference_source=saved_source[display_bank];
    wire publish_pending=pending_valid&&(!freeze_requested||!display_valid||
        saved_source[pending_bank]==freeze_reference_source);
    wire choose_bank=publish_pending?pending_bank:display_bank;
    wire has_frame=pending_valid||display_valid;
    wire [31:0] shown_source=source_address(saved_source[choose_bank]);
    wire [31:0] shown_result=choose_bank?32'h01100000:32'h01000000;
    // 只换样式可立即生效；算法签名改变时，旧结果仍按自己的模式呈现。
    wire [2:0] shown_mode=desired_signature==saved_signature[choose_bank]?display_mode:saved_display_mode[choose_bank];
    wire reprocess_candidate=idle_for_job&&cal_ready&&freeze_requested&&!freeze_exit&&display_valid&&
        desired_signature!=saved_signature[display_bank];
    wire [3:0] shape_valid,shape_circle;
    wire shape_finished;
    wire [3:0][10:0] shape_x0,shape_y0,shape_x1,shape_y1;
    reg [3:0] saved_valid[0:1],saved_circle[0:1];
    reg [3:0][10:0] saved_x0[0:1],saved_y0[0:1],saved_x1[0:1],saved_y1[0:1];
    reg save_shapes;
    board_shape_tracker shapes(.clk(core_clk),.rst,.start(job_fire),.finish(alg_done_valid&&control_state==A_RUN),
        .threshold(job_threshold),.grad_valid,.grad_ready,.grad_payload,
        .finished(shape_finished),
        .box_valid(shape_valid),.is_circle(shape_circle),.box_x0(shape_x0),.box_y0(shape_y0),.box_x1(shape_x1),.box_y1(shape_y1));
    always @(posedge core_clk)begin
        if(rst)begin
            control_state<=C_IDLE;frame_seq<=0;config_seq<=0;work_bank<=0;display_bank<=0;
            pending_bank<=0;display_valid<=0;pending_valid<=0;half<=0;job_sobel<=0;job_recognition<=0;job_threshold<=256;save_shapes<=0;
            work_source<=0;control_fault<=0;job_frame<=0;job_display_mode<=4;
            for(integer b=0;b<2;b=b+1)begin
                saved_valid[b]<=0;saved_circle[b]<=0;saved_x0[b]<=0;saved_y0[b]<=0;saved_x1[b]<=0;saved_y1[b]<=0;
                saved_source[b]<=0;saved_frame[b]<=0;saved_signature[b]<=0;saved_display_mode[b]<=4;
            end
        end else begin
            save_shapes<=0;
            // 不同原图的旧工作已经结清后才撤发布资格，不能中止在途AXI写。
            if(pending_valid&&freeze_requested&&display_valid&&
                saved_source[pending_bank]!=freeze_reference_source)pending_valid<=0;
            if(save_shapes)begin
                saved_valid[work_bank]<=shape_valid;saved_circle[work_bank]<=shape_circle;
                saved_x0[work_bank]<=shape_x0;saved_y0[work_bank]<=shape_y0;saved_x1[work_bank]<=shape_x1;saved_y1[work_bank]<=shape_y1;
                saved_source[work_bank]<=work_source;saved_frame[work_bank]<=job_frame;
                saved_signature[work_bank]<=job_signature;saved_display_mode[work_bank]<=job_display_mode;
                if(!freeze_requested||!display_valid||work_source==freeze_reference_source)begin
                    pending_valid<=1;pending_bank<=work_bank;
                end
            end
            if(display_begin)begin
                display_bank<=choose_bank;display_valid<=1;
                if(publish_pending)pending_valid<=0;
            end
            case(control_state)
                C_IDLE:if(reprocess_candidate)begin
                    if(config_seq==32'hffffffff)control_fault<=1;
                    else begin
                        work_bank<=!display_bank;work_source<=saved_source[display_bank];job_frame<=saved_frame[display_bank];
                        config_seq<=config_seq+32'd1;job_sobel<=display_mode==2;job_recognition<=display_mode==5;
                        job_threshold<=pending_threshold;job_display_mode<=display_mode;control_state<=A_JOB;
                    end
                end else if(capture_start)begin
                    work_bank<=display_valid?!display_bank:1'b0;work_source<=free_source;
                    frame_seq<=frame_seq+32'd1;job_frame<=frame_seq+32'd1;control_state<=C_JOB;
                end else if(capture_candidate&&(frame_seq==32'hffffffff||config_seq==32'hffffffff))begin
                    control_fault<=1;
                end
                C_JOB:if(cap_job_ready)begin control_state<=C_RUN;half<=0;end
                C_RUN:begin
                    if(input_fire)begin half<=!half;if(&markers[2:1])control_state<=C_TAIL;end
                    if(cap_done_valid)begin
                        if(cap_outcome==0&&config_seq!=32'hffffffff)begin
                            control_state<=A_JOB;config_seq<=config_seq+32'd1;
                            job_sobel<=display_mode==2;job_recognition<=display_mode==5;job_threshold<=pending_threshold;job_display_mode<=display_mode;
                        end
                        else begin control_state<=C_IDLE;control_fault<=1;end
                    end
                end
                C_TAIL:if(cap_done_valid)begin
                    if(cap_outcome==0&&config_seq!=32'hffffffff)begin
                        control_state<=A_JOB;config_seq<=config_seq+32'd1;
                        job_sobel<=display_mode==2;job_recognition<=display_mode==5;job_threshold<=pending_threshold;job_display_mode<=display_mode;
                    end
                    else begin control_state<=C_IDLE;control_fault<=1;end
                end
                A_JOB:if(alg_job_ready)control_state<=A_RUN;
                A_RUN:if(alg_done_valid&&shape_finished)begin
                    if(alg_outcome==0)save_shapes<=1;
                    else control_fault<=1;
                    control_state<=C_IDLE;
                end
                default:control_state<=C_IDLE;
            endcase
        end
    end
    wire span_req_valid,span_req_ready,display_data_valid,display_data_ready,display_done_valid,display_done_ready;
    wire [31:0] span_addr;wire [13:0] span_bytes;wire [127:0] display_data;wire [1:0] display_outcome;
    board_frame_display display(
        .core_clk,.video_clk,.safe_reset_n,.enable(cal_ready&&!memory_q),.has_frame,
        .source_base(shown_source),.result_base(shown_result),.mode(shown_mode),
        .box_valid(saved_valid[choose_bank]),.is_circle(saved_circle[choose_bank]),
        .box_x0(saved_x0[choose_bank]),.box_y0(saved_y0[choose_bank]),.box_x1(saved_x1[choose_bank]),.box_y1(saved_y1[choose_bank]),
        .frame_begin(display_begin),.span_req_valid,.span_req_ready,.span_addr,.span_bytes,
        .data_valid(display_data_valid),.data_ready(display_data_ready),.data(display_data),
        .done_valid(display_done_valid),.done_ready(display_done_ready),.outcome(display_outcome),
        .fault(display_fault),.rgb_pair,.rgb_vs,.rgb_hs,.rgb_de);
    assign fault=rx_fault||cap_q||algorithm_q||memory_q||display_fault||control_fault;
    // 各写端持有正文至真实回复；共享写端锁住接受沿owner/flat mask，消除重复RAM快照。
    frame_actors_axi #(.WIDTH(1920),.HEIGHT(1080),.RESULT_ITEM_BITS(1),.FLAT_WRITES(1'b1),.BORROW_WRITE_BODY(1'b1),.EXCLUSIVE_FLAT_WRITES(1'b1)) actors(
        .clk(core_clk),.rst,.axi_enable(cal_ready),
        .cap_job_valid,.cap_job_ready,.cap_base,.cap_handle,.cap_scope,.cap_bayer(phase_pending),
        .in_valid(capture_valid),.in_ready,.raw_pair(half?rx_record[39:20]:rx_record[19:0]),
        .in_x_even(input_x),.in_y(input_y),.in_markers(markers),.in_bad(rx_fault),.in_handle(cap_handle),
        .cap_cancel_valid(1'b0),.cap_cancel_id(cap_handle),.cap_done_valid,
        .cap_done_ready(control_state==C_RUN||control_state==C_TAIL),.cap_outcome,.cap_stop,.cap_quarantined(cap_q),
        .alg_sobel_mode(job_sobel),.alg_job_valid,.alg_job_ready,.alg_cj,.alg_origin,.alg_handle({32'd2,config_seq}),
        .source_base,.class_base(32'h02000000),.queue_base(32'h03000000),.result_base,
        .gradient_base(work_bank?32'h04800000:32'h04000000),
        .alg_cancel_valid(1'b0),.alg_cancel_scope(alg_cj[95:0]),.grad_valid,.grad_ready,.grad_payload,
        .alg_done_valid,.alg_done_ready(control_state==A_RUN&&shape_finished),.alg_outcome,.alg_quarantined(algorithm_q),
        .display_enable(cal_ready),.display_cancel(1'b0),.span_req_valid,.span_req_ready,.span_addr,.span_bytes,
        .display_data_valid,.display_data_ready,.display_data,.display_done_valid,.display_done_ready,.display_outcome,
        .memory_quarantined(memory_q),
        .m_axi_awvalid,.m_axi_awready,.m_axi_awaddr,.m_axi_awid,.m_axi_awlen,.m_axi_awsize,.m_axi_awburst,
        .m_axi_wvalid,.m_axi_wready,.m_axi_wdata,.m_axi_wstrb,.m_axi_wlast,.m_axi_bvalid,.m_axi_bready,.m_axi_bid,.m_axi_bresp,
        .m_axi_arvalid,.m_axi_arready,.m_axi_araddr,.m_axi_arid,.m_axi_arlen,.m_axi_arsize,.m_axi_arburst,
        .m_axi_rvalid,.m_axi_rready,.m_axi_rdata,.m_axi_rid,.m_axi_rresp,.m_axi_rlast);
endmodule
