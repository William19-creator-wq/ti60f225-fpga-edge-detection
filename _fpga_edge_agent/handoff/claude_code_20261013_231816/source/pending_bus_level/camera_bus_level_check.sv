// TRACK4-CAM-BUS-LEVEL-001 v1 / R1-R6 / IF1-IF4。
// 给普通万用表留下稳定测量窗口；检查的是主板电平，不授予相机通信资格。
module camera_bus_level_check #(
    parameter integer unsigned MEASURE_CYCLES = 32'd3030000000,
    parameter integer unsigned SETTLE_CYCLES  = 32'd505000,
    parameter integer unsigned GUARD_CYCLES   = 32'd101000
)(
    input  logic clk,
    input  logic arst_n,
    input  logic scl_i,
    input  logic sda_i,
    output wire  cam_rst_p,
    output wire  scl_drive_low,
    output wire  sda_drive_low,
    output logic [3:0] phase_leds,
    output wire  finished,
    output wire  sda_error,
    output wire  scl_error
);
    typedef enum logic [2:0] {
        IDLE, SCL_LOW, BOTH_LOW, SDA_RELEASE,
        RELEASE_GUARD, RELEASE_CHECK, FINISH
    } state_t;
    state_t state;
    logic [31:0] phase_count;
    logic raw_scl_low, raw_sda_low;
    logic finished_reg, sda_error_reg, scl_error_reg;
    (* ASYNC_REG = "TRUE" *) logic [1:0] reset_release;
    (* ASYNC_REG = "TRUE" *) logic scl_meta, scl_sync;
    (* ASYNC_REG = "TRUE" *) logic sda_meta, sda_sync;
    wire logic_rst = !reset_release[1];
    wire pins_enabled = arst_n && !logic_rst;
    wire settled = (phase_count >= SETTLE_CYCLES - 32'd1);
    wire measure_due = (phase_count >= MEASURE_CYCLES - 32'd1);
    wire guard_due = (phase_count >= GUARD_CYCLES - 32'd1);

    // IF1/R5：SW0或LOCK条件撤销时，异步撤销驱动资格；只同步释放。
    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            reset_release <= 2'b00;
        else
            reset_release <= {reset_release[0], 1'b1};
    end
    always_ff @(posedge clk) begin
        if (logic_rst) begin
            scl_meta <= 1'b1;
            scl_sync <= 1'b1;
            sda_meta <= 1'b1;
            sda_sync <= 1'b1;
        end else begin
            scl_meta <= scl_i;
            scl_sync <= scl_meta;
            sda_meta <= sda_i;
            sda_sync <= sda_meta;
        end
    end

    // IF2：开漏OUT由顶层固定0。资格来自寄存器，避免多位阶段译码毛刺。
    assign scl_drive_low = pins_enabled && raw_scl_low;
    assign sda_drive_low = pins_enabled && raw_sda_low;
    assign cam_rst_p = !pins_enabled;
    assign finished = pins_enabled && finished_reg;
    assign sda_error = pins_enabled && sda_error_reg;
    assign scl_error = pins_enabled && scl_error_reg;

    always_comb begin
        phase_leds = 4'b0000;
        if (pins_enabled) begin
            case (state)
                IDLE:        phase_leds = 4'b0001;
                SCL_LOW:     phase_leds = 4'b0010;
                BOTH_LOW:    phase_leds = 4'b0100;
                SDA_RELEASE: phase_leds = 4'b1000;
                default:     phase_leds = 4'b0000;
            endcase
        end
    end

    // R3：所有退出先释放SDA，保留原SCL资格；至少1ms后再释放SCL。
    task automatic begin_release;
        begin
            raw_sda_low <= 1'b0;
            phase_count <= 32'd0;
            state <= RELEASE_GUARD;
        end
    endtask

    always_ff @(posedge clk) begin
        if (logic_rst) begin
            state <= IDLE;
            phase_count <= 32'd0;
            raw_scl_low <= 1'b0;
            raw_sda_low <= 1'b0;
            finished_reg <= 1'b0;
            sda_error_reg <= 1'b0;
            scl_error_reg <= 1'b0;
        end else begin
            // R6：有限阶段计数；FINISH不再推进，禁止32位回绕重启。
            if ((state != FINISH) && (phase_count != 32'hffffffff))
                phase_count <= phase_count + 32'd1;

            case (state)
                IDLE: begin
                    if (settled && (!scl_sync || !sda_sync)) begin
                        if (!scl_sync) scl_error_reg <= 1'b1;
                        if (!sda_sync) sda_error_reg <= 1'b1;
                        begin_release();
                    end else if (measure_due) begin
                        raw_scl_low <= 1'b1;
                        phase_count <= 32'd0;
                        state <= SCL_LOW;
                    end
                end

                SCL_LOW: begin
                    // 只有实际回读SCL低才允许下一阶段拉SDA，不能只看OE。
                    if (settled && (scl_sync || !sda_sync)) begin
                        if (scl_sync) scl_error_reg <= 1'b1;
                        if (!sda_sync) sda_error_reg <= 1'b1;
                        begin_release();
                    end else if (measure_due) begin
                        raw_sda_low <= 1'b1;
                        phase_count <= 32'd0;
                        state <= BOTH_LOW;
                    end
                end

                BOTH_LOW: begin
                    if (settled && scl_sync) begin
                        scl_error_reg <= 1'b1;
                        if (sda_sync) sda_error_reg <= 1'b1;
                        begin_release();
                    end else begin
                        // 拉SDA失败也留下完整窗口，便于实测；SCL必须保持低。
                        if (settled && sda_sync) sda_error_reg <= 1'b1;
                        if (measure_due) begin
                            raw_sda_low <= 1'b0;
                            phase_count <= 32'd0;
                            state <= SDA_RELEASE;
                        end
                    end
                end

                SDA_RELEASE: begin
                    if (settled && scl_sync) begin
                        scl_error_reg <= 1'b1;
                        if (!sda_sync) sda_error_reg <= 1'b1;
                        begin_release();
                    end else begin
                        if (settled && !sda_sync) sda_error_reg <= 1'b1;
                        if (measure_due) begin_release();
                    end
                end

                RELEASE_GUARD: begin
                    if (guard_due) begin
                        raw_scl_low <= 1'b0;
                        phase_count <= 32'd0;
                        state <= RELEASE_CHECK;
                    end
                end

                RELEASE_CHECK: begin
                    if (guard_due) begin
                        if (!scl_sync) scl_error_reg <= 1'b1;
                        if (!sda_sync) sda_error_reg <= 1'b1;
                        finished_reg <= 1'b1;
                        state <= FINISH;
                    end
                end

                FINISH: begin
                    // R4/R6：测量结束含失败；错误位保持，不能解释为ACK或ID。
                end

                default: begin
                    sda_error_reg <= 1'b1;
                    scl_error_reg <= 1'b1;
                    begin_release();
                end
            endcase
        end
    end
endmodule
