// KEY3 只选择五种全屏算法；视频桥接在帧边界锁存此配置。
module v7_fullscreen_mode_control #(
    parameter integer unsigned DEBOUNCE_CYCLES = 1485000
)(
    input wire clk, rst, key_mode_n,
    output wire [2:0] mode
);
    localparam [2:0] COLOR = 3'd0, GRAY = 3'd1, MEDIAN = 3'd2,
                     SOBEL = 3'd3, OVERLAY = 3'd4;
    reg [2:0] mode_state;
    wire mode_press;

    key_press_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) mode_key (
        .clk(clk), .rst(rst), .raw_key_n(key_mode_n),
        .press(mode_press), .stable_pressed()
    );

    // 非法内部状态立即对外回退彩色，不能选择原桥接中的五分区模式。
    assign mode = (mode_state <= OVERLAY) ? mode_state : COLOR;

    always @(posedge clk) begin
        if (rst) mode_state <= COLOR;
        else if (mode_state > OVERLAY) mode_state <= COLOR;
        else if (mode_press) begin
            case (mode_state)
                COLOR:   mode_state <= GRAY;
                GRAY:    mode_state <= MEDIAN;
                MEDIAN:  mode_state <= SOBEL;
                SOBEL:   mode_state <= OVERLAY;
                default: mode_state <= COLOR;
            endcase
        end
    end
endmodule
