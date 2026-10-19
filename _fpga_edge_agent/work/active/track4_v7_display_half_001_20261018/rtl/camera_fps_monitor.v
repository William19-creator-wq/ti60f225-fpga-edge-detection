// 旁路测量：相邻VS上升沿的周期，而非假设VS上升沿必定是帧起点。
// CSI域每个 de && hs 周期接收4像素；HS有效区内允许DE气泡。
// 不输出ready/复位到视频链路。所有计数和LA均位于clk域。
module camera_fps_monitor #(
    parameter [31:0] STALE_CYCLES = 32'd100000000,
    parameter [31:0] EXPECTED_WORDS = 32'd518400,
    parameter [15:0] EXPECTED_LINES = 16'd1080,
    parameter [15:0] EXPECTED_LINE_WORDS = 16'd480
) (
    input wire clk, rst_n, vs, hs, de,
    output wire [15:0] telemetry_word,
    output wire packet_start, measurement_ready
);
    reg vs_d, hs_d, armed, ready;
    reg [31:0] period_count, frame_words, sequence_count;
    reg [15:0] line_words, lines, min_words, max_words;
    reg overflow, boundary_error;
    reg [31:0] last_period, last_words;
    reg [15:0] last_lines, last_min, last_max;
    reg last_overflow, last_boundary_error;
    wire frame_edge = vs && !vs_d;
    wire accept_word = de && hs;
    wire line_end = hs_d && !hs && (line_words != 0);
    // HS下降沿恰与VS边沿重合时，先将末行计入刚结束的区间。
    wire [15:0] completed_lines = line_end ? (lines == 16'hffff ? lines : lines + 16'd1) : lines;
    wire [15:0] completed_min = line_end && line_words < min_words ? line_words : min_words;
    wire [15:0] completed_max = line_end && line_words > max_words ? line_words : max_words;
    wire [31:0] measured_period = period_count == 32'hffffffff ? period_count : period_count + 32'd1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vs_d<=0; hs_d<=0; armed<=0; ready<=0;
            period_count<=0; frame_words<=0; sequence_count<=0;
            line_words<=0; lines<=0; min_words<=16'hffff; max_words<=0;
            overflow<=0; boundary_error<=0;
            last_period<=0; last_words<=0; last_lines<=0; last_min<=0; last_max<=0;
            last_overflow<=0; last_boundary_error<=0;
        end else begin
            vs_d<=vs; hs_d<=hs;
            if (frame_edge) begin
                armed<=1;
                if (armed) begin
                    ready<=1; sequence_count<=sequence_count+32'd1;
                    last_period<=measured_period; last_words<=frame_words;
                    last_lines<=completed_lines;
                    last_min<=completed_lines==0 ? 16'd0 : completed_min;
                    last_max<=completed_max;
                    last_overflow<=overflow || period_count==32'hffffffff || (line_end && lines==16'hffff);
                    last_boundary_error<=boundary_error || (hs && hs_d && line_words!=0);
                end
                period_count<=0;
                frame_words<=accept_word ? 32'd1 : 32'd0;
                line_words<=accept_word ? 16'd1 : 16'd0;
                lines<=0; min_words<=16'hffff; max_words<=0; overflow<=0;
                // 跨边界半行不能冒充完整几何；在前后两个区间均标记。
                boundary_error<=hs && hs_d && line_words!=0;
            end else if (armed) begin
                if (period_count!=32'hffffffff) period_count<=period_count+32'd1;
                if (accept_word) begin
                    if (frame_words!=32'hffffffff) frame_words<=frame_words+32'd1;
                    if (line_words!=16'hffff) line_words<=line_words+16'd1;
                    if (frame_words==32'hffffffff || line_words==16'hffff) overflow<=1;
                end
                if (line_end) begin
                    lines<=completed_lines; min_words<=completed_min; max_words<=completed_max;
                    line_words<=0;
                    if (lines==16'hffff) overflow<=1;
                end
            end
        end
    end
    // flags: bit0完整周期已锁存；1超过2秒无VS；2溢出；3几何不符；4边界切断有效行。
    wire geometry_bad = last_words!=EXPECTED_WORDS || last_lines!=EXPECTED_LINES ||
                        last_min!=EXPECTED_LINE_WORDS || last_max!=EXPECTED_LINE_WORDS;
    wire [15:0] flags = {11'd0,last_boundary_error,geometry_bad && ready,last_overflow,
                        armed && period_count>=STALE_CYCLES,ready};
    wire [223:0] live_payload = {period_count[31:16],period_count[15:0],flags,last_max,last_min,last_lines,
        last_words[31:16],last_words[15:0],last_period[31:16],last_period[15:0],
        sequence_count[31:16],sequence_count[15:0],16'h0001,16'ha55a};
    reg [15:0] checksum;
    integer k;
    always @* begin
        checksum=0;
        for (k=0;k<14;k=k+1) checksum=checksum ^ live_payload[k*16 +: 16];
    end
    reg [255:0] packet;
    reg [3:0] word_index;
    // 一次锁存整个报文，禁止在两半32位数之间更新数据。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin packet<=0; word_index<=0; end
        else begin
            word_index<=word_index+4'd1;
            if (word_index==4'd15) packet<={16'h5aa5,checksum,live_payload};
        end
    end
    assign telemetry_word=packet[word_index*16 +: 16];
    assign packet_start=word_index==0;
    assign measurement_ready=packet[176]; // word11 bit0，与报文同一快照
endmodule
