// LT01/02：先同步，再证明连续样本；启动按住必须先合格释放。
module key_press_debouncer #(
    parameter integer unsigned DEBOUNCE_CYCLES = 500000
)(
    input logic clk, rst, raw_key_n,
    output logic press, stable_pressed,
    // Diagnostic readback after both CDC stages, including a key held at boot.
    output wire synchronized_n
);
    localparam integer COUNT_WIDTH = $clog2(DEBOUNCE_CYCLES) < 1 ? 1 : $clog2(DEBOUNCE_CYCLES);
    localparam logic [COUNT_WIDTH-1:0] LAST_COUNT = COUNT_WIDTH'(DEBOUNCE_CYCLES-1);
    (* ASYNC_REG = "TRUE" *) logic key_sync_first, key_sync_second;
    logic sample_valid_first, sample_valid_second;
    logic stable_level, armed;
    logic [COUNT_WIDTH-1:0] count;
    initial if (DEBOUNCE_CYCLES < 2) $fatal(1,"DEBOUNCE_CYCLES must be >=2");
    assign stable_pressed = armed && !stable_level;
    assign synchronized_n = key_sync_second;

    always_ff @(posedge clk) begin
        if (rst) begin
            key_sync_first <= 1; key_sync_second <= 1;
            sample_valid_first <= 0; sample_valid_second <= 0;
            stable_level <= 1; armed <= 0; count <= 0; press <= 0;
        end else begin
            key_sync_first <= raw_key_n; key_sync_second <= key_sync_first;
            sample_valid_first <= 1; sample_valid_second <= sample_valid_first;
            press <= 0;
            // 不用复位产生的高电平占位值证明已释放（特别是N=2）。
            if (!sample_valid_second) count <= 0;
            else if (!armed) begin
                if (!key_sync_second) count <= 0;
                else if (count == LAST_COUNT) begin
                    armed <= 1; stable_level <= 1; count <= 0;
                end else count <= count + 1'b1;
            end else if (key_sync_second == stable_level) count <= 0;
            else if (count == LAST_COUNT) begin
                stable_level <= key_sync_second; count <= 0;
                if (!key_sync_second) press <= 1;
            end else count <= count + 1'b1;
        end
    end
endmodule
