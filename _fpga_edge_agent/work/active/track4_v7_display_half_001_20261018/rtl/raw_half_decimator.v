// 2:1 nearest-neighbour decimator for the SC431 RAW10 byte stream.
// Input byte layout is {P1,P0,P3,P2}; each input word contains four source
// pixels. Keep P0 and P2 from every input word and discard odd source lines,
// so the 1920x1080 sensor stream becomes 960x540 while the sensor/link stay
// unchanged.
module raw_half_decimator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i_vs,
    input  wire        i_hs,
    input  wire        i_de,
    input  wire [31:0] i_data,
    output wire        o_vs,
    output wire        o_hs,
    output wire        o_de,
    output wire [15:0] o_data
);
    reg vs_d;
    reg line_active_d;
    reg [10:0] line_number;
    wire line_active = i_hs | i_de;
    wire frame_start = i_vs & ~vs_d;
    wire line_end    = ~line_active & line_active_d;
    wire word_fire   = i_de & i_hs;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vs_d          <= 1'b0;
            line_active_d <= 1'b0;
            line_number   <= 11'd0;
        end else begin
            vs_d          <= i_vs;
            line_active_d <= line_active;
            if (frame_start)
                line_number <= 11'd0;
            else if (line_end && line_number != 11'h7ff)
                line_number <= line_number + 11'd1;

        end
    end

    assign o_vs   = i_vs;
    assign o_hs   = i_hs & ~line_number[0];
    assign o_de   = word_fire & ~line_number[0];
    assign o_data = {i_data[7:0], i_data[23:16]};
endmodule
