// TRACK4-CAM-RST-COMPARE-001 v1 / M1 / R1-R5 / IF1-IF4。
// 只比较外部 RST 高电平下的身份读取；不写相机配置、不授予视频资格。
module camera_reset_compare (
    input  logic clk,
    input  logic arst_n,
    input  logic scl_i,
    input  logic sda_i,
    output wire  cam_rst_p,
    output wire  scl_drive_low,
    output wire  sda_drive_low,
    output wire  started,
    output wire  address30_ack,
    output wire  id30_match,
    output wire  address32_ack,
    output wire  id32_match,
    output wire  all_done,
    output wire  bus_fault
);
    // E1-E3：按 101 MHz 上界，实际 100 MHz 为 20.2 / 1.01 / 505 ms。
    localparam logic [20:0] LOW_HOLD_CYCLES = 21'd2020000;
    localparam logic [16:0] QUIET_CYCLES = 17'd101000;
    localparam logic [25:0] WATCHDOG_CYCLES = 26'd50500000;

    typedef enum logic [1:0] { LOW_HOLD, RUN_HIGH, QUIET, FINISH } state_t;
    state_t state;
    (* ASYNC_REG = "TRUE" *) logic [1:0] reset_release;
    wire supervisor_rst = !reset_release[1];
    logic rst_level;
    logic [20:0] low_count;
    logic [16:0] quiet_count;
    logic [25:0] watchdog_count;
    // bit 0..6 对应 D1..D7；进入 QUIET 后不再取探测器的实时值。
    logic [6:0] result_snapshot;
    wire [6:0] probe_flags;
    wire probe_scl_drive_low, probe_sda_drive_low;
    wire probe_arst_n = arst_n && !supervisor_rst && (state == RUN_HIGH);
    wire deadline_due = (watchdog_count >= WATCHDOG_CYCLES - 26'd1);
    wire stop_due = probe_flags[6] || probe_flags[5] || deadline_due;

    // IF1：异步置位、两级同步释放；外部复位不等待状态机才释放 I2C。
    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            reset_release <= 2'b00;
        else
            reset_release <= {reset_release[0], 1'b1};
    end

    // IF3/IF4：正常 RST 电平来自寄存器，避免多位状态组合译码毛刺。
    // 故障/期限/完成直接截止本机拉低资格，不能等待 M2 的同步复位。
    assign cam_rst_p = (!arst_n || supervisor_rst) ? 1'b1 : rst_level;
    assign scl_drive_low = probe_arst_n && !stop_due && probe_scl_drive_low;
    assign sda_drive_low = probe_arst_n && !stop_due && probe_sda_drive_low;
    assign {bus_fault, all_done, id32_match, address32_ack,
            id30_match, address30_ack, started} =
        (!arst_n || supervisor_rst) ? 7'b0 :
        ((state == RUN_HIGH) ? probe_flags : result_snapshot);

    // M2 原样复用：自身等至少 20 ms，再读两地址的 3107/3108。
    camera_id_probe u_camera_id_probe (
        .clk           (clk),
        .arst_n        (probe_arst_n),
        .scl_i         (scl_i),
        .sda_i         (sda_i),
        .scl_drive_low (probe_scl_drive_low),
        .sda_drive_low (probe_sda_drive_low),
        .started       (probe_flags[0]),
        .address30_ack (probe_flags[1]),
        .id30_match    (probe_flags[2]),
        .address32_ack (probe_flags[3]),
        .id32_match    (probe_flags[4]),
        .all_done      (probe_flags[5]),
        .bus_fault     (probe_flags[6])
    );

    always_ff @(posedge clk) begin
        if (supervisor_rst) begin
            state           <= LOW_HOLD;
            rst_level       <= 1'b1;
            low_count       <= 21'd0;
            quiet_count     <= 17'd0;
            watchdog_count  <= 26'd0;
            result_snapshot <= 7'b0;
        end else begin
            // R3：只计算 LOW_HOLD/RUN_HIGH；QUIET 的独立收尾不能被重启。
            if (((state == LOW_HOLD) || (state == RUN_HIGH)) &&
                (watchdog_count < WATCHDOG_CYCLES))
                watchdog_count <= watchdog_count + 26'd1;

            case (state)
                LOW_HOLD: begin
                    if (deadline_due) begin
                        result_snapshot <= 7'b1000000;
                        rst_level       <= 1'b1;
                        quiet_count     <= 17'd0;
                        state           <= QUIET;
                    end else if (rst_level) begin
                        // 首次变低边沿清零；随后才数完整的低电平周期。
                        rst_level <= 1'b0;
                        low_count <= 21'd0;
                    end else if (low_count == LOW_HOLD_CYCLES - 21'd1) begin
                        low_count <= LOW_HOLD_CYCLES;
                        rst_level <= 1'b1;
                        state     <= RUN_HIGH;
                    end else begin
                        low_count <= low_count + 21'd1;
                    end
                end

                RUN_HIGH: begin
                    // R2/R3：故障优先；同沿到期但安全完成，允许正常收尾。
                    if (probe_flags[6] || (deadline_due && !probe_flags[5])) begin
                        result_snapshot <= {2'b10, probe_flags[4:0]};
                        quiet_count     <= 17'd0;
                        state           <= QUIET;
                    end else if (probe_flags[5]) begin
                        // M2 的 ID 与 all_done 已于上一沿同时提交，本沿锁存。
                        result_snapshot <= {2'b01, probe_flags[4:0]};
                        quiet_count     <= 17'd0;
                        state           <= QUIET;
                    end
                end

                QUIET: begin
                    // IF2：M2 此时保持复位，LED 只用快照；不依赖清零后的标志。
                    if (quiet_count == QUIET_CYCLES - 17'd1) begin
                        quiet_count <= QUIET_CYCLES;
                        rst_level   <= 1'b0;
                        state       <= FINISH;
                    end else begin
                        quiet_count <= quiet_count + 17'd1;
                    end
                end

                FINISH: begin
                    // E4：吸收终态；只有全局复位/重新配置才开始下一轮。
                end

                default: begin
                    result_snapshot <= {2'b10, result_snapshot[4:0]};
                    quiet_count     <= 17'd0;
                    rst_level       <= 1'b1;
                    state           <= QUIET;
                end
            endcase
        end
    end
endmodule
