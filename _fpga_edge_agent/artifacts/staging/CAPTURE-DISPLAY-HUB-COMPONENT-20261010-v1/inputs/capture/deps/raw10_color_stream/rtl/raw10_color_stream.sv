// RC01…03：锁定phase/handle、真实RAW/窗口/RGB计数，公开RGB到消费才关闭。
module raw10_color_stream #(
    parameter integer unsigned WIDTH=1920,HEIGHT=1080
)(
    input logic clk,rst,
    input logic job_valid,output wire job_ready,input logic [63:0] job_id,input logic [1:0] phase,
    input logic in_valid,output wire in_ready,input logic [19:0] raw_pair,
    input logic [10:0] in_x_even,in_y,input logic [2:0] in_markers,input logic in_bad,input logic [63:0] in_id,
    output wire out_valid,input logic out_ready,output wire [47:0] rgb_pair,
    output wire [10:0] out_x_even,out_y,output wire [2:0] out_markers,output wire [63:0] out_id,
    input logic cancel_valid,input logic [63:0] cancel_id,output wire source_stop,
    output wire done_valid,input logic done_ready,output wire [63:0] done_id,
    output logic [1:0] outcome,output logic [7:0] reason,
    output logic [21:0] accepted_pairs,window_pairs,output_pairs,discarded_reads
);
    localparam integer unsigned P=WIDTH*HEIGHT/2;
    typedef enum logic [2:0] {IDLE,ARM,RUN,DRAIN,ABORT,DONE} state_t;
    state_t state;
    logic [63:0] active_id;
    logic [1:0] active_phase;
    logic [9:0] expected_q;
    logic [10:0] expected_y;
    logic output_eof_seen;
    logic [7:0] input_error;
    logic window_ready,window_valid,kernel_ready,window_empty,discarded_read_pulse;
    logic [179:0] window_payload;
    logic [10:0] window_x,window_y;
    logic window_sof,window_eol,window_eof;
    wire matching_cancel=cancel_valid && cancel_id==((state==IDLE)?job_id:active_id);
    wire input_fire=in_valid && in_ready;
    wire window_fire=window_valid && kernel_ready && (state==RUN || state==DRAIN);
    wire output_fire=out_valid && out_ready;
    assign job_ready=!rst && state==IDLE && window_empty && !out_valid;
    assign in_ready=!rst && state==RUN && window_ready && !matching_cancel;
    assign source_stop=!rst && (state==DRAIN || state==ABORT || state==DONE || (state==RUN && matching_cancel));
    assign done_valid=!rst && state==DONE;
    assign done_id=active_id;
    always_comb begin
        input_error=0;
        if(in_bad)input_error=1;
        else if(in_id!=active_id)input_error=2;
        else if(in_x_even!={expected_q,1'b0} || in_y!=expected_y)input_error=3;
        else if(in_markers!={expected_q==WIDTH/2-1 && expected_y==HEIGHT-1,expected_q==WIDTH/2-1,expected_q==0 && expected_y==0})input_error=4;
    end
    raw10_window_pair #(.W(WIDTH),.H(HEIGHT)) window(
        .clk(clk),.rst(rst),.frame_start(state==ARM),.flush(state==ABORT),
        .in_valid(input_fire && input_error==0),.in_ready(window_ready),.in_raw_pair(raw_pair),
        .in_x_even(in_x_even),.in_y(in_y),.in_sof(in_markers[0]),.in_eol(in_markers[1]),.in_eof(in_markers[2]),
        .out_valid(window_valid),.out_ready(kernel_ready && (state==RUN || state==DRAIN)),.out_window_pair(window_payload),
        .out_x_even(window_x),.out_y(window_y),.out_sof(window_sof),.out_eol(window_eol),.out_eof(window_eof),
        .empty(window_empty),.discarded_read_pulse(discarded_read_pulse));
    // ABORT不复位已公开RGB；ARM仅在旧window/核双方已经空后到达。
    raw10_debayer_pair debayer(.clk(clk),.rst(rst || state==ARM),
        .in_valid(window_valid && (state==RUN || state==DRAIN)),.in_ready(kernel_ready),
        .in_window_pair(window_payload),.in_x_even(window_x),.in_y(window_y),.in_phase(active_phase),
        .in_markers({window_eof,window_eol,window_sof}),.in_job_id(active_id),
        .out_valid(out_valid),.out_ready(out_ready),.out_rgb_pair(rgb_pair),.out_x_even(out_x_even),.out_y(out_y),.out_markers(out_markers),.out_job_id(out_id));
    initial if(WIDTH<4 || WIDTH>1920 || WIDTH%2!=0 || HEIGHT<2 || HEIGHT>1080)$fatal(1,"raw10 stream geometry");
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;active_id<=0;active_phase<=0;expected_q<=0;expected_y<=0;output_eof_seen<=0;
            outcome<=0;reason<=0;accepted_pairs<=0;window_pairs<=0;output_pairs<=0;discarded_reads<=0;
        end else begin
            if(window_fire)window_pairs<=window_pairs+22'd1;
            if(output_fire)begin output_pairs<=output_pairs+22'd1;if(out_markers[2])output_eof_seen<=1;end
            if(discarded_read_pulse)discarded_reads<=discarded_reads+22'd1;
            case(state)
                IDLE:if(job_valid && job_ready)begin
                    active_id<=job_id;active_phase<=phase;expected_q<=0;expected_y<=0;output_eof_seen<=0;
                    accepted_pairs<=0;window_pairs<=0;output_pairs<=0;discarded_reads<=0;reason<=0;outcome<=0;
                    if(matching_cancel)begin outcome<=2;state<=DONE;end else state<=ARM;
                end
                ARM:if(matching_cancel)begin outcome<=2;state<=ABORT;end else state<=RUN;
                RUN:begin
                    if(matching_cancel)begin outcome<=2;state<=ABORT;end
                    else if(input_fire)begin
                        accepted_pairs<=accepted_pairs+22'd1;
                        if(input_error!=0)begin outcome<=1;reason<=input_error;state<=ABORT;end
                        else if(expected_q==WIDTH/2-1)begin
                            expected_q<=0;
                            if(expected_y==HEIGHT-1)state<=DRAIN;else expected_y<=expected_y+11'd1;
                        end else expected_q<=expected_q+10'd1;
                    end
                end
                DRAIN:begin
                    if(matching_cancel)begin outcome<=2;state<=ABORT;end
                    else if(window_empty && !out_valid)begin
                        if(accepted_pairs==22'(P) && window_pairs==22'(P) && output_pairs==22'(P) && output_eof_seen)begin outcome<=0;reason<=0;end
                        else begin outcome<=1;reason<=5;end
                        state<=DONE;
                    end
                end
                ABORT:if(window_empty && !out_valid)state<=DONE;
                DONE:if(done_ready)state<=IDLE;
                default:begin outcome<=1;reason<=5;state<=ABORT;end
            endcase
        end
    end
endmodule
