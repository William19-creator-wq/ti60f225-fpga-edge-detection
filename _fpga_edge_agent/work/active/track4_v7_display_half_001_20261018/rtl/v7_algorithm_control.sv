// KEY0仍由v7处理复位。这里只接KEY1加阈值、KEY2减阈值、KEY3模式。
// 配置在本域形成pending值，由video_pair在输入帧边界锁定。
module v7_algorithm_control #(
    parameter integer DEBOUNCE_CYCLES=1485000
)(
    input wire clk,rst,key_inc_n,key_dec_n,key_mode_n,
    output reg [2:0] mode,
    output wire [10:0] threshold
);
    wire mode_press;
    live_threshold_control #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES),
        .INITIAL_THRESHOLD(256),.STEP(32)) thresholds(
        .clk(clk),.rst(rst),.raw_inc_n(key_inc_n),.raw_dec_n(key_dec_n),
        .job_fire(1'b0),.pending_threshold(threshold),.active_threshold(),
        .inc_press(),.dec_press(),.inc_pressed(),.dec_pressed());
    key_press_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) mode_key(
        .clk(clk),.rst(rst),.raw_key_n(key_mode_n),.press(mode_press),.stable_pressed());
    always @(posedge clk)begin
        if(rst)mode<=3'd1;
        else if(mode_press)begin
            // 灰度与中值、差值相邻，便于固定镜头比较；ID保持与上一版兼容。
            case(mode)
                0:mode<=1;
                1:mode<=2;
                2:mode<=6;
                6:mode<=3;
                3:mode<=4;
                4:mode<=5;
                default:mode<=0;
            endcase
        end
    end
endmodule
