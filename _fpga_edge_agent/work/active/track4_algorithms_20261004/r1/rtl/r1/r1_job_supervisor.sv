// R1-REQ03 / R1-OP01。真实FE终态先消费，终态CRC完成才允许新job。
module r1_job_supervisor #(parameter integer W=1920, parameter integer H=1080) (
    input wire clk,rst,
    output wire job_valid,input wire job_ready,
    output wire [31:0] job_epoch,job_frame_id,job_config_id,
    output wire job_median_enable,output wire [1:0] job_output_kind,job_pattern,
    output reg [10:0] job_threshold,output wire job_start,
    input wire source_last_fire,
    output wire accept_records,
    input wire status_valid,status_ready,input wire [2:0] status_code,
    input wire [31:0] status_epoch,status_frame_id,status_config_id,
    input wire [20:0] status_in_pairs,status_out_pairs,data_pairs,
    output wire terminal_accepted_good,
    input wire terminal_crc_done,terminal_good
);
    localparam [2:0] START=0,FEED=1,DRAIN=2,TERMINAL=3,ERROR=4,EXHAUSTED=5;
    localparam [20:0] N=(W/2)*H;
    reg [2:0] supervision_state;
    reg [31:0] job_sequence;
    reg source_eof_accepted;
    assign job_valid=!rst && supervision_state==START;
    assign job_epoch=32'd1;
    assign job_frame_id=job_sequence; assign job_config_id=job_sequence;
    assign job_median_enable=job_sequence[0];
    assign job_output_kind={1'b0,job_sequence[1]};
    assign job_pattern=job_sequence[3:2];
    always @* case(job_sequence[5:4])
        0: job_threshold=11'd0; 1: job_threshold=11'd64;
        2: job_threshold=11'd512; default: job_threshold=11'd1530;
    endcase
    assign job_start=job_valid && job_ready;
    assign accept_records=!rst && (supervision_state==FEED || supervision_state==DRAIN);
    assign terminal_accepted_good=status_code==0 &&
        status_epoch==job_epoch && status_frame_id==job_sequence && status_config_id==job_sequence &&
        supervision_state==DRAIN && source_eof_accepted &&
        status_in_pairs==N && status_out_pairs==N && data_pairs==N;
    always @(posedge clk) begin
        if(rst) begin supervision_state<=START;job_sequence<=0;source_eof_accepted<=0;end
        else case(supervision_state)
            START: if(job_start) begin supervision_state<=FEED;source_eof_accepted<=0;end
            FEED: begin
                if(source_last_fire) begin source_eof_accepted<=1;supervision_state<=DRAIN;end
                if(status_valid && status_ready) supervision_state<=TERMINAL;
            end
            DRAIN: if(status_valid && status_ready) supervision_state<=TERMINAL;
            TERMINAL: if(terminal_crc_done) begin
                if(!terminal_good) supervision_state<=ERROR;
                else if(job_sequence==32'hffffffff) supervision_state<=EXHAUSTED;
                else begin job_sequence<=job_sequence+32'd1;supervision_state<=START;end
            end
            default: begin end
        endcase
    end
endmodule
