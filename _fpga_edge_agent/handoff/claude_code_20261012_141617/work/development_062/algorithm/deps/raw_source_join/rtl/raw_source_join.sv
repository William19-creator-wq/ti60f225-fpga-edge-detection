// RJ01..03：96位scope保留、两个真实子终态、writer安全关闭后的明确RGB discard。
module raw_source_join #(parameter integer WIDTH=1920,HEIGHT=1080)(
    input logic clk,rst,
    input logic job_valid,output wire job_ready,input logic [31:0] job_base,
    input logic [63:0] job_handle,input logic [95:0] job_scope,input logic [1:0] phase,
    input logic in_valid,output wire in_ready,input logic [19:0] raw_pair,
    input logic [10:0] in_x_even,in_y,input logic [2:0] in_markers,input logic in_bad,input logic [63:0] in_handle,
    input logic cancel_valid,input logic [63:0] cancel_id,
    output wire done_valid,input logic done_ready,output wire [63:0] done_id,output wire [95:0] done_scope,
    output logic [1:0] outcome,failed_stage,output logic [7:0] reason,
    output logic [21:0] accepted_raw,accepted_rgb,written_lines,discarded_rgb,
    output logic [31:0] logical_bytes,physical_bytes,
    output wire source_stop,quarantined,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained
);
    localparam integer P=WIDTH*HEIGHT/2,L=WIDTH*HEIGHT*3,A=((L+63)/64)*64;
    typedef enum logic [3:0] {IDLE,CFG_WRITER,WAIT_WRITER,ARM_RAW,RUN,DRAIN,DONE,QUARANTINE} state_t;
    state_t state;
    logic [31:0] base;logic [63:0] handle;logic [95:0] scope;logic [1:0] locked_phase;
    logic writer_started,writer_closed,raw_started,raw_closed,stopping;
    wire matching_cancel=cancel_valid && cancel_id==handle && state!=IDLE && state!=DONE && state!=QUARANTINE;
    wire child_cancel=stopping || matching_cancel;
    wire writer_job_ready,writer_rsp_valid,writer_rsp_error,writer_input_ready;
    wire writer_done_valid,writer_done_ready,writer_stop,writer_quarantine;
    wire [63:0] writer_done_id;wire [1:0] writer_outcome;wire [7:0] writer_reason;
    wire [21:0] writer_accepted,writer_lines;wire [31:0] writer_logical,writer_physical;
    wire raw_job_ready,raw_input_ready,raw_done_valid,raw_done_ready,raw_stop,raw_output_valid,raw_output_ready;
    wire [47:0] rgb_pair;wire [10:0] rgb_x,rgb_y;wire [2:0] rgb_markers;wire [63:0] rgb_id,raw_done_id;
    wire [1:0] raw_outcome;wire [7:0] raw_reason;
    wire [21:0] raw_accepted,raw_windows,raw_outputs,raw_discarded_reads;
    wire writer_done_fire=writer_done_valid && writer_done_ready;
    wire raw_done_fire=raw_done_valid && raw_done_ready;
    wire discard_enabled=writer_closed && stopping && raw_started && !raw_closed && state!=QUARANTINE;
    assign job_ready=!rst && state==IDLE;
    assign in_ready=!rst && state==RUN && !child_cancel && raw_input_ready;
    assign done_valid=!rst && state==DONE;
    assign done_id=handle;assign done_scope=scope;
    assign source_stop=child_cancel || raw_stop || state==DRAIN || state==DONE || state==QUARANTINE;
    assign quarantined=writer_quarantine || state==QUARANTINE;
    assign raw_output_ready=writer_closed ? discard_enabled : writer_input_ready;
    assign raw_done_ready=!rst && raw_started && !raw_closed && state!=QUARANTINE;
    assign writer_done_ready=!rst && writer_started && !writer_closed && state!=QUARANTINE;
    raw10_color_stream #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) color(
        .clk(clk),.rst(rst),.job_valid(state==ARM_RAW),.job_ready(raw_job_ready),.job_id(handle),.phase(locked_phase),
        .in_valid(in_valid && state==RUN && !child_cancel),.in_ready(raw_input_ready),.raw_pair(raw_pair),
        .in_x_even(in_x_even),.in_y(in_y),.in_markers(in_markers),.in_bad(in_bad),.in_id(in_handle),
        .out_valid(raw_output_valid),.out_ready(raw_output_ready),.rgb_pair(rgb_pair),
        .out_x_even(rgb_x),.out_y(rgb_y),.out_markers(rgb_markers),.out_id(rgb_id),
        .cancel_valid(child_cancel),.cancel_id(handle),.source_stop(raw_stop),
        .done_valid(raw_done_valid),.done_ready(raw_done_ready),.done_id(raw_done_id),.outcome(raw_outcome),.reason(raw_reason),
        .accepted_pairs(raw_accepted),.window_pairs(raw_windows),.output_pairs(raw_outputs),.discarded_reads(raw_discarded_reads));
    rgb_source_writer #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.DSP_PACKETS(1'b1)) writer(
        .clk(clk),.rst(rst),.job_valid(state==CFG_WRITER),.job_ready(writer_job_ready),.job_base(base),.job_handle(handle),
        .job_rsp_valid(writer_rsp_valid),.job_rsp_ready(state==WAIT_WRITER),.job_rsp_error(writer_rsp_error),
        .in_valid(raw_output_valid && writer_started && !writer_closed),.in_ready(writer_input_ready),.in_rgb(rgb_pair),
        .in_x_even(rgb_x),.in_y(rgb_y),.in_markers(rgb_markers),.in_bad(1'b0),.in_handle(rgb_id),
        .cancel_valid(child_cancel),.cancel_id(handle),.done_valid(writer_done_valid),.done_ready(writer_done_ready),.done_id(writer_done_id),
        .outcome(writer_outcome),.reason(writer_reason),.accepted_pairs(writer_accepted),.written_lines(writer_lines),
        .logical_bytes(writer_logical),.physical_bytes(writer_physical),.source_stop(writer_stop),.quarantined(writer_quarantine),
        .line_req_valid(line_req_valid),.line_req_ready(line_req_ready),.line_write(line_write),.line_addr(line_addr),.line_wdata(line_wdata),
        .line_rsp_valid(line_rsp_valid),.line_rsp_ready(line_rsp_ready),.line_rdata(line_rdata),.line_error(line_error),.line_drained(line_drained));
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;base<=0;handle<=0;scope<=0;locked_phase<=0;
            writer_started<=0;writer_closed<=1;raw_started<=0;raw_closed<=1;stopping<=0;
            outcome<=0;reason<=0;failed_stage<=0;accepted_raw<=0;accepted_rgb<=0;written_lines<=0;discarded_rgb<=0;logical_bytes<=0;physical_bytes<=0;
        end else begin
            if(raw_output_valid && raw_output_ready && discard_enabled)discarded_rgb<=discarded_rgb+22'd1;
            case(state)
                IDLE:if(job_valid && job_ready)begin
                    base<=job_base;handle<=job_handle;scope<=job_scope;locked_phase<=phase;
                    writer_started<=0;writer_closed<=1;raw_started<=0;raw_closed<=1;stopping<=0;
                    outcome<=0;reason<=0;failed_stage<=0;accepted_raw<=0;accepted_rgb<=0;written_lines<=0;discarded_rgb<=0;logical_bytes<=0;physical_bytes<=0;
                    if(cancel_valid && cancel_id==job_handle)begin stopping<=1;outcome<=2;reason<=128;state<=DRAIN;end
                    else state<=CFG_WRITER;
                end
                CFG_WRITER:if(writer_job_ready)begin writer_started<=1;writer_closed<=0;state<=WAIT_WRITER;end
                WAIT_WRITER:if(writer_rsp_valid)begin
                    if(writer_rsp_error)begin writer_closed<=1;stopping<=1;outcome<=1;reason<=32;failed_stage<=3;state<=DRAIN;end
                    else if(child_cancel)state<=DRAIN;
                    else state<=ARM_RAW;
                end
                ARM_RAW:if(raw_job_ready)begin raw_started<=1;raw_closed<=0;state<=child_cancel ? DRAIN : RUN;end
                RUN:if(child_cancel)state<=DRAIN;
                DRAIN:if(writer_closed && raw_closed && !writer_quarantine)begin
                    state<=DONE;
                    if(outcome==0 && (accepted_raw!=22'(P) || accepted_rgb!=22'(P) || logical_bytes!=32'(L) || physical_bytes!=32'(A) || written_lines!=22'(A/64) || discarded_rgb!=0))begin outcome<=1;reason<=33;failed_stage<=3;end
                end
                DONE:if(done_ready)state<=IDLE;
                default:begin end
            endcase
            if(matching_cancel)begin
                stopping<=1;
                if(state!=CFG_WRITER && state!=WAIT_WRITER && state!=ARM_RAW)state<=DRAIN;
                if(outcome==0 && !(state==WAIT_WRITER && writer_rsp_valid && writer_rsp_error))begin outcome<=2;reason<=128;failed_stage<=0;end
            end
            if(raw_done_fire)begin
                raw_closed<=1;accepted_raw<=raw_accepted;state<=DRAIN;
                if(raw_outcome==1)begin stopping<=1;outcome<=1;reason<=raw_reason;failed_stage<=2;end
                else if(raw_outcome==2 && outcome==0)begin stopping<=1;outcome<=2;reason<=128;failed_stage<=2;end
            end
            if(writer_done_fire)begin
                writer_closed<=1;accepted_rgb<=writer_accepted;written_lines<=writer_lines;
                logical_bytes<=writer_logical;physical_bytes<=writer_physical;state<=DRAIN;
                if(writer_outcome==1)begin stopping<=1;outcome<=1;reason<=writer_reason;failed_stage<=1;end
                else if(writer_outcome==2 && outcome==0)begin stopping<=1;outcome<=2;reason<=128;failed_stage<=1;end
            end
            if(writer_quarantine)begin state<=QUARANTINE;stopping<=1;outcome<=1;reason<=16;failed_stage<=1;end
        end
    end
    // synthesis translate_off
    always @(posedge clk)if(!rst)begin
        if(done_valid && (!writer_closed || !raw_closed || line_req_valid || quarantined))$fatal(1,"RAW source parent done before child closure");
        if(raw_done_fire && raw_done_id!=handle)$fatal(1,"RAW source child scope mismatch");
        if(writer_done_fire && writer_done_id!=handle)$fatal(1,"RGB source child scope mismatch");
        if(raw_output_valid && raw_output_ready && !discard_enabled && (!writer_started || writer_closed))$fatal(1,"RAW RGB acceptance lacks writer owner");
    end
    // synthesis translate_on
endmodule
