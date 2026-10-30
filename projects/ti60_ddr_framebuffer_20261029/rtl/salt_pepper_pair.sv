// Reproducible demonstration input, BEFORE grayscale and median filtering.
// Two RGB888 pixels per cycle; all video signals and clean reference delay 1 clk.
// Seed and rate latch on rising VS. Blanking never consumes random numbers.
// Rates 655/65536, 1966/65536, 3277/65536 approximate 1%, 3%, 5%.
// Both salt and pepper replace all RGB channels so artificial noise is neutral.
module salt_pepper_pair (
    input wire clk, rst,
    input wire in_vs, in_hs, in_de,
    input wire [47:0] in_rgb,
    input wire [1:0] cfg_level,
    input wire [31:0] cfg_seed,
    output reg out_vs, out_hs, out_de,
    output reg [47:0] clean_rgb, noisy_rgb,
    output reg [1:0] injected,
    output reg [1:0] active_level
);
    reg previous_vs;
    reg [31:0] random_state;
    wire frame_start = in_vs && !previous_vs;

    function automatic [31:0] next_random(input [31:0] value);
        reg [31:0] t;
        begin
            t = value ^ (value << 13);
            t = t ^ (t >> 17);
            next_random = t ^ (t << 5);
        end
    endfunction
    function automatic [15:0] cutoff(input [1:0] level);
        case (level)
            1: cutoff = 16'd655;
            2: cutoff = 16'd1966;
            3: cutoff = 16'd3277;
            default: cutoff = 16'd0;
        endcase
    endfunction
    wire [31:0] sample0 = next_random(random_state);
    wire [31:0] sample1 = next_random(sample0);
    wire hit0 = sample0[15:0] < cutoff(active_level);
    wire hit1 = sample1[15:0] < cutoff(active_level);
    always @(posedge clk) begin
        if (rst) begin
            previous_vs <= 0;
            random_state <= 32'h43106025;
            active_level <= 0;
            out_vs <= 0; out_hs <= 0; out_de <= 0;
            clean_rgb <= 0; noisy_rgb <= 0; injected <= 0;
        end else begin
            previous_vs <= in_vs;
            out_vs <= in_vs; out_hs <= in_hs; out_de <= in_de;
            clean_rgb <= in_rgb;
            noisy_rgb <= in_rgb;
            injected <= 0;
            if (frame_start) begin
                // Xorshift's zero state is absorbing; substitute a documented seed.
                random_state <= cfg_seed == 0 ? 32'h43106025 : cfg_seed;
                active_level <= cfg_level;
            end else if (in_de) begin
                random_state <= sample1;
                injected <= {hit1,hit0};
                if (hit0) noisy_rgb[23:0] <= {24{sample0[16]}};
                if (hit1) noisy_rgb[47:24] <= {24{sample1[16]}};
            end
        end
    end
    // synthesis translate_off
    always @(posedge clk) if (!rst && frame_start && in_de)
        $fatal(1,"VS frame boundary must occur in blanking");
    // synthesis translate_on
endmodule
