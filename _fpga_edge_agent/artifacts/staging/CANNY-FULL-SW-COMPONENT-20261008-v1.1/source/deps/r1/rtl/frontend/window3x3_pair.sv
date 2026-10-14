// FE-01/03/04/06；OP-03…05。独立的有限图replicate窗口，不存整帧。
module window3x3_pair #(parameter integer W = 1920, parameter integer H = 1080) (
    input wire clk, input wire rst, input wire frame_start, input wire flush,
    input wire in_valid, output wire in_ready, input wire [15:0] in_y_pair,
    input wire [10:0] in_x_even, input wire [10:0] in_y,
    input wire in_sof, input wire in_eol, input wire in_eof,
    output wire out_valid, input wire out_ready, output reg [143:0] out_window_pair,
    output reg [10:0] out_x_even, output reg [10:0] out_y,
    output reg out_sof, output reg out_eol, output reg out_eof, output wire empty
);
    localparam [9:0] LAST_Q = W/2 - 1;
    localparam [10:0] LAST_ROW = H - 1;
    localparam [2:0] IDLE=0, REAL=1, REPLAY=2, TAIL=3, WAIT_EOF=4;
    localparam [1:0] NO_PENDING=0, REAL_PENDING=1, REPLAY_PENDING=2, TAIL_PENDING=3;
    reg [2:0] replay_phase;
    reg [1:0] read_pending;
    reg [9:0] pending_q, replay_q;
    reg [10:0] pending_row;
    reg [15:0] pending_pair;
    reg output_present;
    reg horizontal_valid;
    reg [23:0] left_column, center_column0, center_column1;
    reg [9:0] horizontal_q;
    reg [10:0] horizontal_row;
    wire advance = !output_present || out_ready;
    // flush是采样沿的撤销事件；不能经ready反向取消已经成立的错误握手。
    assign in_ready = !rst && replay_phase == REAL && advance;
    assign out_valid = !rst && output_present;
    assign empty = replay_phase == IDLE && read_pending == NO_PENDING &&
                   !horizontal_valid && !output_present;
    wire controls_active = !rst && !flush && !frame_start && advance;
    wire real_issue = controls_active && replay_phase == REAL && in_valid;
    wire replay_issue = controls_active && replay_phase == REPLAY;
    wire rd_en = real_issue || replay_issue;
    wire [9:0] rd_addr = real_issue ? in_x_even[10:1] : replay_q;
    wire recent_wr_en = controls_active && read_pending == REAL_PENDING;
    wire older_wr_en = recent_wr_en && pending_row != 0;
    wire [15:0] recent_read, older_read;
    line_store_pair #(.W(W)) recent (
        .clk(clk), .rd_en(rd_en), .rd_addr(rd_addr), .rd_pair(recent_read),
        .wr_en(recent_wr_en), .wr_addr(pending_q), .wr_pair(pending_pair)
    );
    line_store_pair #(.W(W)) older (
        .clk(clk), .rd_en(rd_en), .rd_addr(rd_addr), .rd_pair(older_read),
        .wr_en(older_wr_en), .wr_addr(pending_q), .wr_pair(recent_read)
    );
    reg vertical_valid;
    reg [23:0] new_column0, new_column1;
    reg [10:0] new_row;
    // 每列低8位为top；之后才转成每lane低a高i的行优先窗口。
    always @* begin
        vertical_valid = 1'b0;
        new_column0 = 24'b0; new_column1 = 24'b0; new_row = 11'b0;
        if (read_pending == REAL_PENDING && pending_row != 0) begin
            vertical_valid = 1'b1;
            new_row = pending_row - 11'd1;
            if (pending_row == 1) begin
                new_column0 = {pending_pair[7:0], recent_read[7:0], recent_read[7:0]};
                new_column1 = {pending_pair[15:8], recent_read[15:8], recent_read[15:8]};
            end else begin
                new_column0 = {pending_pair[7:0], recent_read[7:0], older_read[7:0]};
                new_column1 = {pending_pair[15:8], recent_read[15:8], older_read[15:8]};
            end
        end else if (read_pending == REPLAY_PENDING) begin
            vertical_valid = 1'b1; new_row = LAST_ROW;
            new_column0 = {recent_read[7:0], recent_read[7:0], older_read[7:0]};
            new_column1 = {recent_read[15:8], recent_read[15:8], older_read[15:8]};
        end
    end
    function [71:0] row_major_window;
        input [23:0] l, c, r;
        begin
            row_major_window = {r[23:16], c[23:16], l[23:16],
                                r[15:8], c[15:8], l[15:8],
                                r[7:0], c[7:0], l[7:0]};
        end
    endfunction
    always @(posedge clk) begin
        if (rst || flush || frame_start) begin
            replay_phase <= frame_start && !rst && !flush ? REAL : IDLE;
            read_pending <= NO_PENDING;
            pending_q <= 0; pending_row <= 0; pending_pair <= 0; replay_q <= 0;
            horizontal_valid <= 0; horizontal_q <= 0; horizontal_row <= 0;
            left_column <= 0; center_column0 <= 0; center_column1 <= 0;
            output_present <= 0; out_window_pair <= 0;
            out_x_even <= 0; out_y <= 0; out_sof <= 0; out_eol <= 0; out_eof <= 0;
        end else if (advance) begin
            output_present <= 0;
            read_pending <= NO_PENDING;
            // 先消费old pending/old RAM，后发下一读；不能因输入气泡重吃旧读回。
            if (vertical_valid) begin
                if (horizontal_valid) begin
                    output_present <= 1;
                    out_window_pair[71:0] <= row_major_window(left_column, center_column0, center_column1);
                    out_window_pair[143:72] <= row_major_window(center_column0, center_column1,
                                                               pending_q == 0 ? center_column1 : new_column0);
                    out_x_even <= {horizontal_q, 1'b0}; out_y <= horizontal_row;
                    out_sof <= horizontal_q == 0 && horizontal_row == 0;
                    out_eol <= horizontal_q == LAST_Q;
                    out_eof <= horizontal_q == LAST_Q && horizontal_row == LAST_ROW;
                end
                left_column <= pending_q == 0 ? new_column0 : center_column1;
                center_column0 <= new_column0; center_column1 <= new_column1;
                horizontal_q <= pending_q; horizontal_row <= new_row; horizontal_valid <= 1;
            end else if (read_pending == TAIL_PENDING) begin
                output_present <= 1;
                out_window_pair[71:0] <= row_major_window(left_column, center_column0, center_column1);
                out_window_pair[143:72] <= row_major_window(center_column0, center_column1, center_column1);
                out_x_even <= {horizontal_q, 1'b0}; out_y <= horizontal_row;
                out_sof <= horizontal_q == 0 && horizontal_row == 0;
                out_eol <= horizontal_q == LAST_Q;
                out_eof <= horizontal_q == LAST_Q && horizontal_row == LAST_ROW;
                horizontal_valid <= 0;
            end
            case (replay_phase)
                REAL: if (real_issue) begin
                    read_pending <= REAL_PENDING; pending_q <= in_x_even[10:1];
                    pending_row <= in_y; pending_pair <= in_y_pair;
                    if (in_eof) begin replay_phase <= REPLAY; replay_q <= 0; end
                end
                REPLAY: begin
                    read_pending <= REPLAY_PENDING; pending_q <= replay_q; pending_row <= LAST_ROW;
                    if (replay_q == LAST_Q) replay_phase <= TAIL;
                    else replay_q <= replay_q + 10'd1;
                end
                TAIL: begin read_pending <= TAIL_PENDING; replay_phase <= WAIT_EOF; end
                WAIT_EOF: if (output_present && out_ready && out_eof &&
                              read_pending == NO_PENDING && !horizontal_valid)
                    replay_phase <= IDLE;
                default: begin end
            endcase
        end
    end
    // synthesis translate_off
    initial if (W < 4 || W > 1920 || W % 2 != 0 || H < 3 || H > 1080)
        $fatal(1, "window3x3_pair: illegal dimensions");
    always @(posedge clk) begin
        if (!rst && !flush && !frame_start && advance) begin
            if (read_pending == TAIL_PENDING && !horizontal_valid)
                $fatal(1, "TAIL has no last horizontal group");
            if (vertical_valid && pending_q != 0 &&
                (!horizontal_valid || horizontal_row != new_row || horizontal_q + 1 != pending_q))
                $fatal(1, "window horizontal sequence mismatch");
            if (real_issue && (in_x_even[0] || in_x_even >= W || in_y >= H))
                $fatal(1, "window input out of range");
        end
    end
    // synthesis translate_on
endmodule
