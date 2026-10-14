// -----------------------------------------------------------------------------
// Debounced, active-low board key for selecting the image-processing mode.
//
// i_key_n is asynchronous to clk, so it first passes through a two-flop
// synchronizer.  A stable transition must remain unchanged for
// DEBOUNCE_CYCLES clocks.  One falling (pressed) edge advances the requested
// mode 0 -> 1 -> 2 -> 0; holding a key therefore cannot retrigger it.
// o_mode is intentionally changed only at an active-high VS rising edge while
// DE is low.  This makes the selected mode constant for a complete frame and
// avoids a half-frame image change.
// -----------------------------------------------------------------------------

module key_mode_select #(
    parameter integer DEBOUNCE_CYCLES = 2_970_000
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       i_key_n,
    input  wire       i_vs,
    input  wire       i_de,
    output reg  [1:0] o_mode
);

    function integer ceil_log2;
        input integer value;
        integer v;
        begin
            if (value <= 1) begin
                ceil_log2 = 1;
            end else begin
                v = value - 1;
                ceil_log2 = 0;
                while (v > 0) begin
                    ceil_log2 = ceil_log2 + 1;
                    v = v >> 1;
                end
            end
        end
    endfunction

    // Clamp an accidental zero parameter to one clock so the comparison and
    // vector width remain legal for all elaborations.
    localparam integer DB_LIMIT = (DEBOUNCE_CYCLES < 1) ? 1 : DEBOUNCE_CYCLES;
    localparam integer DB_WIDTH = ceil_log2(DB_LIMIT);

    reg key_meta;
    reg key_sync;
    reg key_stable;
    reg key_stable_d;
    reg [DB_WIDTH-1:0] db_count;
    reg [1:0] requested_mode;
    reg       vs_d;

    // Two-flop synchronizer.  The key is pulled high on the board and is low
    // while pressed.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_meta <= 1'b1;
            key_sync <= 1'b1;
        end else begin
            key_meta <= i_key_n;
            key_sync <= key_meta;
        end
    end

    // Digital debounce: only accept a new level after DB_LIMIT consecutive
    // clocks at that level.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_stable <= 1'b1;
            db_count   <= {DB_WIDTH{1'b0}};
        end else if (key_sync == key_stable) begin
            db_count <= {DB_WIDTH{1'b0}};
        end else if (db_count == DB_LIMIT - 1) begin
            key_stable <= key_sync;
            db_count   <= {DB_WIDTH{1'b0}};
        end else begin
            db_count <= db_count + 1'b1;
        end
    end

    // Falling edge of the debounced active-low key advances the request once.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_stable_d <= 1'b1;
            requested_mode <= 2'b00;
        end else begin
            key_stable_d <= key_stable;
            if (key_stable_d && !key_stable) begin
                if (requested_mode == 2'd2)
                    requested_mode <= 2'd0;
                else
                    requested_mode <= requested_mode + 1'b1;
            end
        end
    end

    // Frame-safe mode commit.  A press coincident with this edge is sampled
    // from the old requested_mode and consequently takes effect next frame.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vs_d    <= 1'b0;
            o_mode  <= 2'b00;
        end else begin
            vs_d <= i_vs;
            if (i_vs && !vs_d && !i_de)
                o_mode <= requested_mode;
        end
    end

endmodule
