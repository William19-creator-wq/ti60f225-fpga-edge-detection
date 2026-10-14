// TRACK4-CAM-ID-001 v1，M1 / R1-R6 / IF1-IF4。
// 一次复位只执行四笔身份读取；本模块不写摄像头配置，也不授予视频采集资格。
module camera_id_probe (
    input  logic clk,
    input  logic arst_n,
    input  logic scl_i,
    input  logic sda_i,
    output wire  scl_drive_low,
    output wire  sda_drive_low,
    output logic started,
    output logic address30_ack,
    output logic id30_match,
    output logic address32_ack,
    output logic id32_match,
    output logic all_done,
    output logic bus_fault
);
    import sc431hai_profile_pkg::*;

    // IF1 / E1：实际 core_clk 为 100 MHz，计数按 101 MHz 上界计算。
    // 启动至少等 20 ms；全轮名义 250 ms，在 100 MHz 实钟下为 252.5 ms。
    localparam integer unsigned CLK_MAX_HZ = 101000000;
    localparam logic [20:0] POWER_WAIT_CYCLES = 21'd2020000;
    localparam logic [24:0] ROUND_LIMIT_CYCLES = 25'd25250000;

    typedef enum logic [2:0] {
        WAIT_POWER, PREPARE, ISSUE, WAIT_REPLY, NEXT, DONE, FAULT
    } state_t;

    state_t state;
    (* ASYNC_REG = "TRUE" *) logic [1:0] reset_release;
    wire probe_rst = !reset_release[1];

    logic [20:0] power_count;
    logic [24:0] round_count;
    logic [1:0] probe_index;
    logic [15:0] id30_value, id32_value;
    // bit 0 对应 3107（高字节），bit 1 对应 3108（低字节）。
    logic [1:0] id30_valid, id32_valid;

    logic [6:0] request_device;
    logic [15:0] request_register;
    logic [63:0] request_tag;
    wire request_valid, request_ready;
    wire response_valid, response_ready;
    wire [63:0] response_tag;
    wire [7:0] response_data, response_reason;
    wire [1:0] response_outcome;
    wire [3:0] response_phase, response_ack_mask;
    wire response_drained, master_quarantined;
    wire master_scl_drive_low, master_sda_drive_low;
    wire master_enable;

    wire terminal_state = (state == DONE) || (state == FAULT);
    wire deadline_due = started && !terminal_state &&
                        (round_count >= ROUND_LIMIT_CYCLES - 25'd1);
    wire response_taken = response_valid && response_ready;
    wire response_tag_matches = (response_tag == request_tag);

    // IF2 / R3：必须完成整笔读取和 STOP/释放，不能仅凭 ACK 或数据值授予身份。
    wire response_success = (response_outcome == 2'd0) &&
                            (response_reason == NONE) &&
                            response_drained &&
                            (response_ack_mask == 4'b1111) &&
                            !master_quarantined;
    wire response_nack = (response_outcome == 2'd1) &&
                         (response_reason == NACK) &&
                         response_drained && !master_quarantined;
    wire response_terminal = response_success || response_nack;

    // E5：只给最后一笔已安全终结的回复留一个 NEXT 提交拍；中间回复不延期。
    wire final_reply_at_limit = (state == WAIT_REPLY) &&
                               (probe_index == 2'd3) && response_taken &&
                               response_tag_matches && response_terminal;
    wire final_commit_at_limit = (state == NEXT) && (probe_index == 2'd3);

    // 外部复位异步置位，两级同步释放。M1/M2 使用同一个同步高有效复位。
    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            reset_release <= 2'b00;
        else
            reset_release <= {reset_release[0], 1'b1};
    end

    // E2 / E5：ISSUE 停顿期间正文保持；期限边界不再接受新请求。
    assign request_valid = !probe_rst && !bus_fault &&
                           (state == ISSUE) && !deadline_due;
    assign response_ready = !probe_rst && !bus_fault && (state == WAIT_REPLY);
    assign master_enable = !probe_rst && !bus_fault && (state != FAULT);

    // IF3 / R6：只输出“拉低资格”。顶层 OUT 固定 0，OE 接以下信号。
    // FAULT 同沿更新后立即屏蔽旧驱动；外设仍拉低时不声称整条总线已经释放。
    assign scl_drive_low = arst_n && master_enable && master_scl_drive_low;
    assign sda_drive_low = arst_n && master_enable && master_sda_drive_low;

    i2c_register_master #(
        .CLK_MAX_HZ (CLK_MAX_HZ),
        .SCL_HZ     (100000),
        .TIMEOUT_US (10000)
    ) u_i2c_master (
        .clk           (clk),
        .rst           (probe_rst),
        .enable        (master_enable),
        .req_valid     (request_valid),
        .req_ready     (request_ready),
        .req_read      (1'b1),
        .req_device    (request_device),
        .req_register  (request_register),
        .req_data      (8'h00),
        .req_tag       (request_tag),
        .cancel_valid  (1'b0),
        .cancel_tag    (64'd0),
        .rsp_valid     (response_valid),
        .rsp_ready     (response_ready),
        .rsp_tag       (response_tag),
        .rsp_data      (response_data),
        .rsp_reason    (response_reason),
        .rsp_outcome   (response_outcome),
        .rsp_phase     (response_phase),
        .rsp_ack_mask  (response_ack_mask),
        .rsp_drained   (response_drained),
        .quarantined   (master_quarantined),
        .scl_i         (scl_i),
        .sda_i         (sda_i),
        .scl_drive_low (master_scl_drive_low),
        .sda_drive_low (master_sda_drive_low)
    );

    always_ff @(posedge clk) begin
        if (probe_rst) begin
            state            <= WAIT_POWER;
            power_count      <= 21'd0;
            round_count      <= 25'd0;
            probe_index      <= 2'd0;
            request_device   <= 7'h30;
            request_register <= 16'h3107;
            request_tag      <= 64'd1;
            id30_value       <= 16'h0000;
            id32_value       <= 16'h0000;
            id30_valid       <= 2'b00;
            id32_valid       <= 2'b00;
            started          <= 1'b0;
            address30_ack    <= 1'b0;
            id30_match       <= 1'b0;
            address32_ack    <= 1'b0;
            id32_match       <= 1'b0;
            all_done         <= 1'b0;
            bus_fault        <= 1'b0;
        end else begin
            // 只在探测轮内累计，达到上界保持，避免计数回绕重新获得时间。
            if (started && !terminal_state && (round_count < ROUND_LIMIT_CYCLES))
                round_count <= round_count + 25'd1;

            // E3：只有匹配在途事务的握手能留下证据。
            // 故障回复的地址 ACK 仍可记录；只有完整成功的字节才获得有效位。
            if (response_taken && response_tag_matches) begin
                if (!probe_index[1]) begin
                    if (response_ack_mask[0])
                        address30_ack <= 1'b1;
                    if (response_success) begin
                        if (!probe_index[0]) begin
                            id30_value[15:8] <= response_data;
                            id30_valid[0]   <= 1'b1;
                        end else begin
                            id30_value[7:0] <= response_data;
                            id30_valid[1]  <= 1'b1;
                        end
                    end
                end else begin
                    if (response_ack_mask[0])
                        address32_ack <= 1'b1;
                    if (response_success) begin
                        if (!probe_index[0]) begin
                            id32_value[15:8] <= response_data;
                            id32_valid[0]   <= 1'b1;
                        end else begin
                            id32_value[7:0] <= response_data;
                            id32_valid[1]  <= 1'b1;
                        end
                    end
                end
            end

            // DONE/FAULT 为吸收终态，所有灯和证据保持到下一次逻辑复位。
            if (!terminal_state) begin
                if ((response_valid && (state != WAIT_REPLY)) ||
                    (deadline_due && !final_reply_at_limit && !final_commit_at_limit)) begin
                    bus_fault <= 1'b1;
                    all_done  <= 1'b0;
                    state     <= FAULT;
                end else begin
                    case (state)
                        WAIT_POWER: begin
                            if (power_count == POWER_WAIT_CYCLES - 21'd1) begin
                                power_count <= POWER_WAIT_CYCLES;
                                started     <= 1'b1;
                                probe_index <= 2'd0;
                                state       <= PREPARE;
                            end else begin
                                power_count <= power_count + 21'd1;
                            end
                        end

                        PREPARE: begin
                            // E2：地址为 7 位；tag 与索引一一对应且在 ISSUE/WAIT_REPLY 保持。
                            case (probe_index)
                                2'd0: begin
                                    request_device   <= 7'h30;
                                    request_register <= 16'h3107;
                                    request_tag      <= 64'd1;
                                end
                                2'd1: begin
                                    request_device   <= 7'h30;
                                    request_register <= 16'h3108;
                                    request_tag      <= 64'd2;
                                end
                                2'd2: begin
                                    request_device   <= 7'h32;
                                    request_register <= 16'h3107;
                                    request_tag      <= 64'd3;
                                end
                                2'd3: begin
                                    request_device   <= 7'h32;
                                    request_register <= 16'h3108;
                                    request_tag      <= 64'd4;
                                end
                            endcase
                            state <= ISSUE;
                        end

                        ISSUE: begin
                            if (request_valid && request_ready)
                                state <= WAIT_REPLY;
                        end

                        WAIT_REPLY: begin
                            if (response_taken) begin
                                if (response_tag_matches && response_terminal) begin
                                    state <= NEXT;
                                end else begin
                                    bus_fault <= 1'b1;
                                    state     <= FAULT;
                                end
                            end
                        end

                        NEXT: begin
                            // E4：前一拍提交字节/valid，本拍才比较，避免最后字节读到旧值。
                            if (!probe_index[1]) begin
                                if ((id30_valid == 2'b11) && (id30_value == SENSOR_ID))
                                    id30_match <= 1'b1;
                            end else begin
                                if ((id32_valid == 2'b11) && (id32_value == SENSOR_ID))
                                    id32_match <= 1'b1;
                            end

                            if (probe_index == 2'd3) begin
                                all_done <= 1'b1;
                                state    <= DONE;
                            end else begin
                                probe_index <= probe_index + 2'd1;
                                state       <= PREPARE;
                            end
                        end

                        default: begin
                            bus_fault <= 1'b1;
                            all_done  <= 1'b0;
                            state     <= FAULT;
                        end
                    endcase
                end
            end
        end
    end
endmodule
