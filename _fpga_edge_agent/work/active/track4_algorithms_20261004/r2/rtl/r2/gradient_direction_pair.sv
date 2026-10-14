// SI-REQ02 / E3 / U-D：signed11逐lane检查，四级移位加法方向流水。
module gradient_direction_pair (
    input wire clk, rst, frame_start, data_flush,
    input wire in_valid, output wire in_ready,
    input wire [65:0] in_pair,
    input wire [10:0] in_x_even, in_y,
    input wire in_sof, in_eol, in_eof,
    input wire [95:0] job_ids,
    output wire out_valid, input wire out_ready,
    output wire [69:0] out_pair,
    output wire [10:0] out_x_even, out_y,
    output wire out_sof, out_eol, out_eof,
    output logic err_valid, input wire err_ready,
    output logic [119:0] err_payload,
    output wire empty
);
    logic [3:0] valid_pipe;
    logic [65:0] gradient_pipe [0:3];
    logic [24:0] coordinate_pipe [0:3];
    logic [9:0] absolute_x_s1 [0:1], absolute_y_s1 [0:1];
    logic [19:0] x384_s2 [0:1], x40_s2 [0:1], x1024_s2 [0:1];
    logic [19:0] y384_s2 [0:1], y40_s2 [0:1], y1024_s2 [0:1];
    logic [19:0] x424_s3 [0:1], y424_s3 [0:1];
    logic [19:0] x1024_s3 [0:1], y1024_s3 [0:1];
    logic [3:0] direction_s4;
    logic signed [11:0] input_x [0:1], input_y [0:1];
    logic [11:0] input_abs_x [0:1], input_abs_y [0:1];
    logic [1:0] lane_bad;
    logic bad_lane;
    logic [11:0] bad_x;
    wire advance = !valid_pipe[3] || out_ready;
    wire input_fire = in_valid && in_ready;

    always_comb begin : validate_input
        for (integer lane=0; lane<2; lane=lane+1) begin
            input_x[lane] = $signed({in_pair[lane*33+10], in_pair[lane*33 +: 11]});
            input_y[lane] = $signed({in_pair[lane*33+21], in_pair[lane*33+11 +: 11]});
            // 先扩到12位，可准确表示 abs(-1024)，再判断合法范围。
            input_abs_x[lane] = input_x[lane] < 0 ? -input_x[lane] : input_x[lane];
            input_abs_y[lane] = input_y[lane] < 0 ? -input_y[lane] : input_y[lane];
            lane_bad[lane] = input_abs_x[lane] > 12'd1020
                || input_abs_y[lane] > 12'd1020
                || in_pair[lane*33+22 +: 11] > 11'd1530
                || (input_abs_x[lane]+input_abs_y[lane])
                    != {1'b0,in_pair[lane*33+22 +: 11]};
        end
        bad_lane = !lane_bad[0]; // 两lane同时坏时选择lane0。
        bad_x = {1'b0,in_x_even} + {11'b0,bad_lane};
    end
    assign in_ready = !rst && advance && !err_valid;
    assign out_valid = !rst && valid_pipe[3];
    assign out_pair = {direction_s4, gradient_pipe[3]};
    assign {out_eof,out_eol,out_sof,out_y,out_x_even} = coordinate_pipe[3];
    assign empty = !(|valid_pipe) && !err_valid;

    // 错误槽独立于数据流水：flush/start不能删掉尚未交付的错误。
    always_ff @(posedge clk) begin : error_slot
        if (rst) begin
            err_valid <= 1'b0;
            err_payload <= 120'b0;
        end else begin
            if (err_valid && err_ready) err_valid <= 1'b0;
            if (input_fire && (|lane_bad)) begin
                err_valid <= 1'b1;
                if (bad_x <= 12'd2047)
                    err_payload <= {job_ids,1'b1,bad_lane,in_y,bad_x[10:0]};
                else
                    err_payload <= {job_ids,24'b0};
            end
        end
    end

    always_ff @(posedge clk) begin : direction_pipeline
        if (rst || data_flush || frame_start) begin
            valid_pipe <= 4'b0;
        end else if (advance) begin
            valid_pipe <= {valid_pipe[2:0],input_fire && !(|lane_bad)};
            gradient_pipe[0] <= in_pair;
            coordinate_pipe[0] <= {in_eof,in_eol,in_sof,in_y,in_x_even};
            for (integer stage=1; stage<4; stage=stage+1) begin
                gradient_pipe[stage] <= gradient_pipe[stage-1];
                coordinate_pipe[stage] <= coordinate_pipe[stage-1];
            end
            for (integer lane=0; lane<2; lane=lane+1) begin
                absolute_x_s1[lane] <= input_abs_x[lane][9:0];
                absolute_y_s1[lane] <= input_abs_y[lane][9:0];
                // D2：先零扩20位，再移位。424 = 384 + 40。
                x384_s2[lane] <= ({10'b0,absolute_x_s1[lane]} << 8)
                    + ({10'b0,absolute_x_s1[lane]} << 7);
                x40_s2[lane] <= ({10'b0,absolute_x_s1[lane]} << 5)
                    + ({10'b0,absolute_x_s1[lane]} << 3);
                x1024_s2[lane] <= {absolute_x_s1[lane],10'b0};
                y384_s2[lane] <= ({10'b0,absolute_y_s1[lane]} << 8)
                    + ({10'b0,absolute_y_s1[lane]} << 7);
                y40_s2[lane] <= ({10'b0,absolute_y_s1[lane]} << 5)
                    + ({10'b0,absolute_y_s1[lane]} << 3);
                y1024_s2[lane] <= {absolute_y_s1[lane],10'b0};
                // D3：合并乘积，与同一组梯度/坐标同行。
                x424_s3[lane] <= x384_s2[lane]+x40_s2[lane];
                y424_s3[lane] <= y384_s2[lane]+y40_s2[lane];
                x1024_s3[lane] <= x1024_s2[lane];
                y1024_s3[lane] <= y1024_s2[lane];
                // D4：等号优先H，再V；零幅值也属于H。
                if (gradient_pipe[2][lane*33+22 +: 11] == 0
                    || y1024_s3[lane] <= x424_s3[lane])
                    direction_s4[lane*2 +: 2] <= 2'b00;
                else if (x1024_s3[lane] <= y424_s3[lane])
                    direction_s4[lane*2 +: 2] <= 2'b10;
                else if (gradient_pipe[2][lane*33+10] == gradient_pipe[2][lane*33+21])
                    direction_s4[lane*2 +: 2] <= 2'b01;
                else direction_s4[lane*2 +: 2] <= 2'b11;
            end
        end
    end
endmodule
