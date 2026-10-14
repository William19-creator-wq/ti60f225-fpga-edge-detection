// R1-REQ03 / R1-OP01：规则图样按真实FP握手推进，不存整帧。
module pattern_pair_source #(parameter integer W=1920, parameter integer H=1080) (
    input wire clk, rst, job_start, job_stop,
    input wire [31:0] job_epoch, job_frame_id, job_config_id,
    input wire job_median_enable, input wire [1:0] job_output_kind,
    input wire [10:0] job_threshold, input wire [1:0] job_pattern,
    output wire in_valid, input wire in_ready, output wire [47:0] in_rgb,
    output wire [10:0] in_x_even, in_y,
    output wire in_sof, in_eol, in_eof, output wire source_last_fire
);
    localparam [9:0] LAST_Q=W/2-1;
    localparam [10:0] LAST_ROW=H-1;
    reg active;
    reg [111:0] job_snapshot;
    reg [9:0] accepted_q;
    reg [10:0] accepted_row;
    wire [1:0] pattern=job_snapshot[111:110];
    wire [10:0] x0={accepted_q,1'b0};
    function [23:0] rgb_at;
        input [10:0] x, y; input [1:0] p;
        reg [7:0] value;
        begin
            case(p)
                0: rgb_at={x[7:0],y[7:0],(x[7:0]^y[7:0])};
                1: rgb_at=x<W/2 ? 24'h000000 : 24'hffffff;
                2: rgb_at=y<H/2 ? 24'h000000 : 24'hffffff;
                default: begin value=(x[5]^y[5]) ? 8'd239 : 8'd16; rgb_at={value,value,value}; end
            endcase
        end
    endfunction
    // 真实FS终结事件允许撤销尚未交付候选；不是伪造源EOF/FP交付。
    assign in_valid=!rst && active && !job_stop;
    assign in_rgb={rgb_at(x0+11'd1,accepted_row,pattern),rgb_at(x0,accepted_row,pattern)};
    assign in_x_even=x0; assign in_y=accepted_row;
    assign in_sof=accepted_q==0 && accepted_row==0;
    assign in_eol=accepted_q==LAST_Q;
    assign in_eof=accepted_q==LAST_Q && accepted_row==LAST_ROW;
    assign source_last_fire=in_valid && in_ready && in_eof;
    always @(posedge clk) begin
        if(rst) begin active<=0; job_snapshot<=0; accepted_q<=0; accepted_row<=0; end
        else if(job_start) begin
            job_snapshot<={job_pattern,job_threshold,job_output_kind,job_median_enable,
                            job_config_id,job_frame_id,job_epoch};
            accepted_q<=0; accepted_row<=0; active<=1;
        end else if(job_stop) active<=0;
        else if(in_valid && in_ready) begin
            if(accepted_q==LAST_Q) begin
                if(accepted_row==LAST_ROW) active<=0;
                else begin accepted_q<=0; accepted_row<=accepted_row+11'd1; end
            end else accepted_q<=accepted_q+10'd1;
        end
    end
endmodule
