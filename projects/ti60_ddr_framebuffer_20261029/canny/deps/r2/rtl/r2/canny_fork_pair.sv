// SI-REQ05 / E3 / U-F：各分支拥有自己的pending；每份数据各交付一次。
module canny_fork_pair (
    input wire clk, rst, frame_start, data_flush, retain_grad,
    input wire in_valid, output wire in_ready,
    input wire [69:0] in_pair,
    input wire [10:0] in_x_even, in_y,
    input wire in_sof, in_eol, in_eof,
    output wire n_valid, input wire n_ready, output logic [31:0] n_pair,
    output wire [10:0] n_x_even, n_y, output wire n_sof, n_eol, n_eof,
    output wire grad_valid, input wire grad_ready, output logic [63:0] grad_pair,
    output wire [10:0] grad_x_even, grad_y,
    output wire grad_sof, grad_eol, grad_eof,
    output wire empty
);
    logic [69:0] held_pair;
    logic [24:0] held_coordinate;
    logic pending_n, pending_grad;
    wire old_released = (!pending_n || n_ready) && (!pending_grad || grad_ready);
    assign in_ready = !rst && old_released;
    assign n_valid = !rst && pending_n;
    assign grad_valid = !rst && pending_grad;
    assign empty = !pending_n && !pending_grad;
    assign {n_eof,n_eol,n_sof,n_y,n_x_even} = held_coordinate;
    assign {grad_eof,grad_eol,grad_sof,grad_y,grad_x_even} = held_coordinate;
    always_comb begin : format_branches
        for (integer lane=0; lane<2; lane=lane+1) begin
            n_pair[lane*16 +: 16] = {3'b0,held_pair[66+lane*2 +: 2],
                held_pair[lane*33+22 +: 11]};
            grad_pair[lane*32 +: 32] = {8'b0,held_pair[66+lane*2 +: 2],
                held_pair[lane*33+11 +: 11],held_pair[lane*33 +: 11]};
        end
    end
    always_ff @(posedge clk) begin : branch_obligations
        if (rst || frame_start || data_flush) begin
            pending_n <= 1'b0;
            pending_grad <= 1'b0;
        end else begin
            if (n_valid && n_ready) pending_n <= 1'b0;
            if (grad_valid && grad_ready) pending_grad <= 1'b0;
            // 接新组在clear之后赋值，保证同沿替换不会清掉新义务。
            if (in_valid && in_ready) begin
                held_pair <= in_pair;
                held_coordinate <= {in_eof,in_eol,in_sof,in_y,in_x_even};
                pending_n <= 1'b1;
                pending_grad <= retain_grad;
            end
        end
    end
endmodule
