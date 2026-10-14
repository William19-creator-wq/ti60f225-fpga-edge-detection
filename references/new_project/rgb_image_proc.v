// -----------------------------------------------------------------------------
// RGB image processing pipeline for the Ti60F225 video path
//
// The input stream is one RGB pixel per `clk` cycle.  `i_de` is the data-enable
// (pixel-valid) signal; `i_hs` and `i_vs` are the corresponding line/frame
// control signals.  The three registered stages carry all of these control
// signals along with the pixel data.  An input stable before edge N appears at
// the output after edge N+2 (the third register position); the pipeline is
// nevertheless full-rate once primed.
//
// i_mode:
//   2'b00 - original RGB
//   2'b01 - gray:      {Y,Y,Y}
//   2'b10 - threshold: {8'hff,8'hff,8'hff} or black
//   2'b11 - original RGB (safe default)
//
// Y = (77*R + 150*G + 29*B + 128) >> 8
// The coefficients are fixed-point approximations of 0.299, 0.587 and 0.114.
// They are written as shifts/adds so the intended FPGA implementation is
// visible and does not require a floating-point operator.
// -----------------------------------------------------------------------------

module rgb_image_proc #(
    parameter [7:0] THRESHOLD = 8'd128
)(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       i_de,
    input  wire       i_hs,
    input  wire       i_vs,
    input  wire [7:0] i_r,
    input  wire [7:0] i_g,
    input  wire [7:0] i_b,   
    input  wire [1:0] i_mode,

    output reg        o_de,
    output reg        o_hs,
    output reg        o_vs,
    output reg  [7:0] o_r,
    output reg  [7:0] o_g,
    output reg  [7:0] o_b
);

    // ------------------------------ stage 1 -------------------------------
    // Capture the original pixel and form the three fixed-point products.
    // Every operand is explicitly extended to 16 bits before shifting.
    reg [15:0] s1_r_term;
    reg [15:0] s1_g_term;
    reg [15:0] s1_b_term;
    reg  [7:0] s1_r;
    reg  [7:0] s1_g;
    reg  [7:0] s1_b;
    reg        s1_de;
    reg        s1_hs;
    reg        s1_vs;
    reg  [1:0] s1_mode;

    // ------------------------------ stage 2 -------------------------------
    // Add the products and round before the >>8 fixed-point normalization.
    reg [16:0] s2_y_sum;
    reg  [7:0] s2_r;
    reg  [7:0] s2_g;
    reg  [7:0] s2_b;
    reg        s2_de;
    reg        s2_hs;
    reg        s2_vs;
    reg  [1:0] s2_mode;

    wire [7:0] s2_y = s2_y_sum[15:8];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_r_term <= 16'd0;
            s1_g_term <= 16'd0;
            s1_b_term <= 16'd0;
            s1_r      <= 8'd0;
            s1_g      <= 8'd0;
            s1_b      <= 8'd0;
            s1_de     <= 1'b0;
            s1_hs     <= 1'b0;
            s1_vs     <= 1'b0;
            s1_mode   <= 2'b00;

            s2_y_sum  <= 17'd0;
            s2_r      <= 8'd0;
            s2_g      <= 8'd0;
            s2_b      <= 8'd0;
            s2_de     <= 1'b0;
            s2_hs     <= 1'b0;
            s2_vs     <= 1'b0;
            s2_mode   <= 2'b00;

            o_de      <= 1'b0;
            o_hs      <= 1'b0;
            o_vs      <= 1'b0;
            o_r       <= 8'd0;
            o_g       <= 8'd0;
            o_b       <= 8'd0;
        end else begin
            // S1: 77 = 64 + 8 + 4 + 1
            s1_r_term <= ({8'd0, i_r} << 6) +
                         ({8'd0, i_r} << 3) +
                         ({8'd0, i_r} << 2) +
                         ({8'd0, i_r});
            // S1: 150 = 128 + 16 + 4 + 2
            s1_g_term <= ({8'd0, i_g} << 7) +
                         ({8'd0, i_g} << 4) +
                         ({8'd0, i_g} << 2) +
                         ({8'd0, i_g} << 1);
            // S1: 29 = 32 - 2 - 1
            s1_b_term <= ({8'd0, i_b} << 5) -
                         ({8'd0, i_b} << 1) -
                         ({8'd0, i_b});
            s1_r    <= i_r;
            s1_g    <= i_g;
            s1_b    <= i_b;
            s1_de   <= i_de;
            s1_hs   <= i_hs;
            s1_vs   <= i_vs;
            s1_mode <= i_mode;

            // S2: maximum sum is 255*256 + 128 = 65408, safely below 2^16.
            s2_y_sum <= {1'b0, s1_r_term} +
                        {1'b0, s1_g_term} +
                        {1'b0, s1_b_term} + 17'd128;
            s2_r      <= s1_r;
            s2_g      <= s1_g;
            s2_b      <= s1_b;
            s2_de     <= s1_de;
            s2_hs     <= s1_hs;
            s2_vs     <= s1_vs;
            s2_mode   <= s1_mode;

            // S3: mode selection.  RGB is explicitly blanked outside DE.
            o_de <= s2_de;
            o_hs <= s2_hs;
            o_vs <= s2_vs;
            if (s2_de) begin
                case (s2_mode)
                    2'b01: begin
                        o_r <= s2_y;
                        o_g <= s2_y;
                        o_b <= s2_y;
                    end
                    2'b10: begin
                        if (s2_y >= THRESHOLD) begin
                            o_r <= 8'hff;
                            o_g <= 8'hff;
                            o_b <= 8'hff;
                        end else begin
                            o_r <= 8'h00;
                            o_g <= 8'h00;
                            o_b <= 8'h00;
                        end
                    end
                    default: begin
                        o_r <= s2_r;
                        o_g <= s2_g;
                        o_b <= s2_b;
                    end
                endcase
            end else begin
                o_r <= 8'h00;
                o_g <= 8'h00;
                o_b <= 8'h00;
            end
        end
    end

endmodule
