// LT03/04：pending供父job_fire锁定；active只观察本单元同沿旧快照。
module live_threshold_control #(
    parameter integer unsigned DEBOUNCE_CYCLES = 500000,
    parameter integer unsigned INITIAL_THRESHOLD = 256,
    parameter integer unsigned STEP = 16
)(
    input logic clk, rst, raw_inc_n, raw_dec_n, job_fire,
    output logic [10:0] pending_threshold, active_threshold,
    output wire inc_press, dec_press, inc_pressed, dec_pressed
);
    localparam logic [10:0] INITIAL_VALUE = 11'(INITIAL_THRESHOLD);
    localparam logic [10:0] STEP_VALUE = 11'(STEP);
    wire [11:0] increased = {1'b0,pending_threshold} + {1'b0,STEP_VALUE};
    initial begin
        if (INITIAL_THRESHOLD > 2047 || STEP < 1 || STEP > 2047)
            $fatal(1,"Threshold parameter out of domain");
    end
    key_press_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) increment_key(
        .clk(clk),.rst(rst),.raw_key_n(raw_inc_n),.press(inc_press),.stable_pressed(inc_pressed));
    key_press_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) decrement_key(
        .clk(clk),.rst(rst),.raw_key_n(raw_dec_n),.press(dec_press),.stable_pressed(dec_pressed));
    always_ff @(posedge clk) begin
        if (rst) begin
            pending_threshold <= INITIAL_VALUE; active_threshold <= INITIAL_VALUE;
        end else begin
            case ({inc_press,dec_press})
                2'b10: pending_threshold <= increased > 12'd2047 ? 11'd2047 : increased[10:0];
                2'b01: pending_threshold <= pending_threshold < STEP_VALUE ? 11'd0 : pending_threshold - STEP_VALUE;
                default: begin end // 同沿双键抵消；按住无新事件。
            endcase
            if (job_fire) active_threshold <= pending_threshold;
        end
    end
endmodule
