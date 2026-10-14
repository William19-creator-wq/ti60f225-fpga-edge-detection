// TRACK4-CAM-RST-STATIC-001 v1：静态 RST 电平下每秒一轮身份探测（REQ-1..6）。
// 替代 camera_reset_compare；camera_id_probe / i2c_register_master 原样复用。
// 只读 3107/3108，不写相机配置。时钟 core_clk 100 MHz，计数按 101 MHz 上界。
module camera_rst_static (
    input  logic clk,
    input  logic arst_n,        // 三个 PLL 锁定的与（w_arstn），低 = 复位
    input  logic key_n,         // KEY3 原始电平，低 = 按下
    input  logic scl_i,
    input  logic sda_i,
    output wire  cam_rst_p,     // J4-6 主板 RST 电平
    output wire  scl_drive_low,
    output wire  sda_drive_low,
    output wire  rst_level_led, // D1：亮 = RST 高
    output wire  ack30_seen,    // D2
    output wire  id30_seen,     // D3
    output wire  ack32_seen,    // D4
    output wire  id32_seen,     // D5
    output wire  heartbeat,     // D6：每完成一轮翻转一次
    output wire  fault_seen     // D7
);
    localparam logic [21:0] INIT_LOW_CYCLES = 22'd2020000;   // 20 ms
    localparam logic [25:0] WAKE_CYCLES     = 26'd50500000;  // 0.5 s
    localparam logic [26:0] ROUND_CYCLES    = 27'd101000000; // 1 s，从本轮开始计
    localparam logic [24:0] PROBE_LIMIT     = 25'd30300000;  // 0.3 s 防挂死

    typedef enum logic [1:0] { INIT_LOW, WAKE, PROBE, GAP } state_t;
    state_t state;

    // 异步置位、两级同步释放（与原 camera_reset_compare IF1 相同）。
    (* ASYNC_REG = "TRUE" *) logic [1:0] reset_release;
    wire rst = !reset_release[1];
    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) reset_release <= 2'b00;
        else         reset_release <= {reset_release[0], 1'b1};
    end

    // KEY3：两级同步 + 约 20 ms 连续稳定才出一次按下脉冲；上电按住须先松开。
    wire key_press;
    key_press_debouncer #(.DEBOUNCE_CYCLES(2020000)) u_key (
        .clk(clk), .rst(rst), .raw_key_n(key_n), .press(key_press), .stable_pressed());

    logic rst_level;        // 静态电平，上电为高；跨同步复位保持，只有 KEY3 改变
    logic level_valid;      // INIT_LOW 结束后才输出静态电平
    logic [26:0] count;     // 当前状态/本轮的计数
    logic probe_run;        // 1 = 探测器解除复位
    logic [4:0] seen;       // {fault, id32, ack32, id30, ack30}
    logic beat;
    wire  [6:0] probe_flags;
    wire  probe_scl_low, probe_sda_low;

    // 复位或 INIT_LOW 期间：复位时输出高（同原模块），INIT_LOW 输出低。
    assign cam_rst_p     = rst ? 1'b1 : (level_valid ? rst_level : 1'b0);
    // 只有 PROBE 中、探测器已解除复位时才允许拉低；切换/轮间同拍撤销。
    assign scl_drive_low = !rst && probe_run && probe_scl_low;
    assign sda_drive_low = !rst && probe_run && probe_sda_low;
    assign rst_level_led = cam_rst_p;
    assign {fault_seen, id32_seen, ack32_seen, id30_seen, ack30_seen} = rst ? 5'b0 : seen;
    assign heartbeat     = !rst && beat;

    camera_id_probe u_probe (
        .clk           (clk),
        .arst_n        (!rst && probe_run),
        .scl_i         (scl_i),
        .sda_i         (sda_i),
        .scl_drive_low (probe_scl_low),
        .sda_drive_low (probe_sda_low),
        .started       (probe_flags[0]),
        .address30_ack (probe_flags[1]),
        .id30_match    (probe_flags[2]),
        .address32_ack (probe_flags[3]),
        .id32_match    (probe_flags[4]),
        .all_done      (probe_flags[5]),
        .bus_fault     (probe_flags[6])
    );

    // rst_level 单独保存：只在上电配置时为 1，SW0 复位后保持用户上次选择。
    initial rst_level = 1'b1;
    always_ff @(posedge clk) begin
        if (!rst && level_valid && key_press) rst_level <= !rst_level;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= INIT_LOW; level_valid <= 1'b0; count <= 27'd0;
            probe_run <= 1'b0; seen <= 5'b0; beat <= 1'b0;
        end else if (level_valid && key_press) begin
            // REQ-3：切换电平，本轮作废，记忆清零，重新等 0.5 s。
            probe_run <= 1'b0; seen <= 5'b0; count <= 27'd0; state <= WAKE;
        end else begin
            case (state)
                INIT_LOW: begin
                    if (count == 27'(INIT_LOW_CYCLES) - 27'd1) begin
                        level_valid <= 1'b1; count <= 27'd0; state <= WAKE;
                    end else count <= count + 27'd1;
                end
                WAKE: begin
                    if (count == 27'(WAKE_CYCLES) - 27'd1) begin
                        probe_run <= 1'b1; count <= 27'd0; state <= PROBE;
                    end else count <= count + 27'd1;
                end
                PROBE: begin
                    // 探测器在 all_done/bus_fault 同沿提交 ack/id 标志，本沿采样。
                    if (probe_flags[5] || probe_flags[6] || count >= 27'(PROBE_LIMIT)) begin
                        seen <= seen | {probe_flags[6] || (count >= 27'(PROBE_LIMIT)),
                                        probe_flags[4], probe_flags[3], probe_flags[2], probe_flags[1]};
                        beat <= !beat; probe_run <= 1'b0; state <= GAP;
                    end
                    count <= count + 27'd1;
                end
                GAP: begin
                    if (count >= 27'(ROUND_CYCLES) - 27'd1) begin
                        probe_run <= 1'b1; count <= 27'd0; state <= PROBE;
                    end else count <= count + 27'd1;
                end
            endcase
        end
    end
endmodule
