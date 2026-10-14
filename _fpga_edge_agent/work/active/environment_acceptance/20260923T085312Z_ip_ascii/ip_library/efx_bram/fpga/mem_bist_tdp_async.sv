
module mem_bist_tdp_async #(
parameter OUTPUT_REG_A = 1'b0,
parameter OUTPUT_REG_B = 1'b0,
parameter BYTEEN_WIDTH_A = 'd2,
parameter BYTEEN_WIDTH_B = 'd2,
parameter ADDR_WIDTH_A = 'd3,
parameter DATA_WIDTH_A = 'd16,
parameter ADDR_WIDTH_B = 'd3,
parameter DATA_WIDTH_B = 'd16
)	(
    input  logic        clk_a,
    input  logic        clk_b,
    input  logic	reset_a,
    input  logic        reset_b,
    input  logic        start,

    // Memory interface
    output logic        we_a,
    output logic        we_b,
    output logic        addren_a,
    output logic        addren_b,

    output logic [ADDR_WIDTH_A-1:0]  addr_a,
    output logic [ADDR_WIDTH_B-1:0]  addr_b,
    output logic [DATA_WIDTH_A-1:0] wdata_a,
    output logic [DATA_WIDTH_B-1:0] wdata_b,
    input  logic [DATA_WIDTH_A-1:0] rdata_a,
    input  logic [DATA_WIDTH_B-1:0] rdata_b,

    output logic [BYTEEN_WIDTH_A-1:0]  byteen_a,
    output logic [BYTEEN_WIDTH_B-1:0]  byteen_b,
    output logic        clke_a,
    output logic        clke_b,

    // Status
    output logic        done,
    output logic        pass,
    output logic        fail
);

logic done_a;
logic done_b;
logic pass_a;
logic pass_b;
logic fail_a;
logic fail_b;

assign done = done_a & done_b;
assign pass = pass_a & pass_b;
assign fail = fail_a | fail_b;

//done a then goes to b// simple sequential testing only //

    logic donea_toggle_r_sync1, donea_toggle_r_sync2;

    // Sync request into read clock domain
    always_ff @(posedge clk_b or posedge reset_b) begin
        if (reset_b) begin
            donea_toggle_r_sync1 <= 0;
            donea_toggle_r_sync2 <= 0;
        end else begin
            donea_toggle_r_sync1 <= done_a;
            donea_toggle_r_sync2 <= donea_toggle_r_sync1;
        end
    end

    wire donea_pulse_r = donea_toggle_r_sync1 ^ donea_toggle_r_sync2;

    //------------------------------------------------------------
    // Walking‑1 pattern a
    //------------------------------------------------------------
    function automatic logic [DATA_WIDTH_A-1:0] walking_one_a (input int idx);
        logic [DATA_WIDTH_A:0] tmp;
        begin
            tmp = '0;
            tmp[idx] = 1'b1;
            return tmp;
        end
    endfunction

    //------------------------------------------------------------
    // Walking‑1 pattern b
    //------------------------------------------------------------
    function automatic logic [DATA_WIDTH_B-1:0] walking_one_b (input int idx);
        logic [DATA_WIDTH_B:0] tmp;
        begin
            tmp = '0;
            tmp[idx] = 1'b1;
            return tmp;
        end
    endfunction

    //------------------------------------------------------------
    // CDC handshake (toggle based)
    //------------------------------------------------------------
    logic reqa_toggle_w, reqa_toggle_r_sync1, reqa_toggle_r_sync2;
    logic acka_toggle_r, acka_toggle_w_sync1, acka_toggle_w_sync2;

    // Sync request into read clock domain
    always_ff @(posedge clk_a or posedge reset_a) begin
        if (reset_a) begin
            reqa_toggle_r_sync1 <= 0;
            reqa_toggle_r_sync2 <= 0;
        end else begin
            reqa_toggle_r_sync1 <= reqa_toggle_w;
            reqa_toggle_r_sync2 <= reqa_toggle_r_sync1;
        end
    end

    // Sync acknowledge into write clock domain
    always_ff @(posedge clk_a or posedge reset_a) begin
        if (reset_a) begin
            acka_toggle_w_sync1 <= 0;
            acka_toggle_w_sync2 <= 0;
        end else begin
            acka_toggle_w_sync1 <= acka_toggle_r;
            acka_toggle_w_sync2 <= acka_toggle_w_sync1;
        end
    end


    wire reqa_pulse_r = reqa_toggle_r_sync1 ^ reqa_toggle_r_sync2;
    wire acka_pulse_w = acka_toggle_w_sync1 ^ acka_toggle_w_sync2;


    logic reqa_pulse_r_reg;
    logic reqa_pulse_r_reg2;
    logic reqa_pulse_r_reg3;

    always_ff @(posedge clk_a or posedge reset_a) begin
	    if(reset_a) begin
		reqa_pulse_r_reg  <= 1'b0;
		reqa_pulse_r_reg2 <= 1'b0;
		reqa_pulse_r_reg3 <= 1'b0;
	    end else begin
		reqa_pulse_r_reg  <= reqa_pulse_r;    
		reqa_pulse_r_reg2 <= reqa_pulse_r_reg; 
		reqa_pulse_r_reg3 <= reqa_pulse_r_reg2;
	    end
    end

    //------------------------------------------------------------
    // CDC handshake (toggle based)
    //------------------------------------------------------------
    logic reqb_toggle_w, reqb_toggle_r_sync1, reqb_toggle_r_sync2;
    logic ackb_toggle_r, ackb_toggle_w_sync1, ackb_toggle_w_sync2;

    // Sync request into read clock domain
    always_ff @(posedge clk_b or posedge reset_b) begin
        if (reset_b) begin
            reqb_toggle_r_sync1 <= 0;
            reqb_toggle_r_sync2 <= 0;
        end else begin
            reqb_toggle_r_sync1 <= reqb_toggle_w;
            reqb_toggle_r_sync2 <= reqb_toggle_r_sync1;
        end
    end

    // Sync acknowledge into write clock domain
    always_ff @(posedge clk_b or posedge reset_b) begin
        if (reset_b) begin
            ackb_toggle_w_sync1 <= 0;
            ackb_toggle_w_sync2 <= 0;
        end else begin
            ackb_toggle_w_sync1 <= ackb_toggle_r;
            ackb_toggle_w_sync2 <= ackb_toggle_w_sync1;
        end
    end


    wire reqb_pulse_r = reqb_toggle_r_sync1 ^ reqb_toggle_r_sync2;
    wire ackb_pulse_w = ackb_toggle_w_sync1 ^ ackb_toggle_w_sync2;


    logic reqb_pulse_r_reg;
    logic reqb_pulse_r_reg2;
    logic reqb_pulse_r_reg3;

    always_ff @(posedge clk_b or posedge reset_b) begin
	    if(reset_b) begin
		reqb_pulse_r_reg  <= 1'b0;
		reqb_pulse_r_reg2 <= 1'b0;
		reqb_pulse_r_reg3 <= 1'b0;
	    end else begin
		reqb_pulse_r_reg  <= reqb_pulse_r;    
		reqb_pulse_r_reg2 <= reqb_pulse_r_reg; 
		reqb_pulse_r_reg3 <= reqb_pulse_r_reg2;
	    end
    end


    //------------------------------------------------------------
    // Write Domain
    //------------------------------------------------------------
    typedef enum logic [1:0] {W_IDLE, W_WRITE, W_WAIT_ACK} wstate_t;
    wstate_t wstate_a;
    wstate_t wstate_b;

    logic [13:0]  addr_w_a;
    logic [9:0]  bit_idx_w_a;
    logic [DATA_WIDTH_A-1:0] pattern_w_a;

    wire last_addr_w_a = (addr_w_a == {ADDR_WIDTH_A{1'b1}});
    wire last_bit_w_a  = (bit_idx_w_a == (DATA_WIDTH_A-1));

    always_ff @(posedge clk_a or posedge reset_a) begin
        if (reset_a) begin
            wstate_a       <= W_IDLE;
            we_a           <= 0;
            addren_a       <= 0;
            addr_a         <= '0;
            wdata_a        <= '0;
            byteen_a       <= {BYTEEN_WIDTH_A{1'b1}};
            clke_a         <= 1'b1;
            addr_w_a       <= '0;
            bit_idx_w_a    <= '0;
            pattern_w_a    <= '0;
            reqa_toggle_w  <= 0;
            done_a         <= 0;
            pass_a         <= 0;
        end else begin
            case (wstate_a)

                W_IDLE: begin
                    we_a     <= 0;
                    addren_a <= 0;

                    if (start) begin
                        addr_w_a    <= 0;
                        bit_idx_w_a <= 0;
                        pattern_w_a <= walking_one_a(0);
                        wstate_a    <= W_WRITE;
                    end
                end

                W_WRITE: begin
                    we_a      	  <= 1'b1;
                    addren_a  	  <= 1'b1;
                    addr_a    	  <= addr_w_a;
                    wdata_a   	  <= pattern_w_a;
                    reqa_toggle_w <= ~reqa_toggle_w; // request read/compare
                    wstate_a 	  <= W_WAIT_ACK;
                end

                W_WAIT_ACK: begin
                    we_a     <= 0;
                    addren_a <= 0;

                    if (acka_pulse_w) begin
                        if (!last_addr_w_a) begin
                            addr_w_a <= addr_w_a + 1'b1;
                            wstate_a <= W_WRITE;
                        end else begin
                            addr_w_a <= 0;

                            if (!last_bit_w_a) begin
                                bit_idx_w_a <= bit_idx_w_a + 1'b1;
                                pattern_w_a <= walking_one_a(bit_idx_w_a + 1);
                                wstate_a <= W_WRITE;
                            end else begin
                                done_a <= 1'b1;
                                pass_a <= ~fail_a;
                                wstate_a <= W_IDLE;
                            end
                        end
                    end
                end

            endcase
        end
    end

    logic [13:0]  addr_w_b;
    logic [9:0]  bit_idx_w_b;
    logic [DATA_WIDTH_B-1:0] pattern_w_b;

    wire last_addr_w_b = (addr_w_b == {ADDR_WIDTH_B{1'b1}});
    wire last_bit_w_b  = (bit_idx_w_b == (DATA_WIDTH_B-1));

    always_ff @(posedge clk_b or posedge reset_b) begin
        if (reset_b) begin
            wstate_b       <= W_IDLE;
            we_b           <= 0;
            addren_b       <= 0;
            addr_b         <= '0;
            wdata_b        <= '0;
            byteen_b       <= {BYTEEN_WIDTH_A{1'b1}};
            clke_b         <= 1'b1;
            addr_w_b       <= '0;
            bit_idx_w_b    <= '0;
            pattern_w_b    <= '0;
            reqb_toggle_w  <= 0;
            done_b         <= 0;
            pass_b         <= 0;
        end else begin
            case (wstate_b)

                W_IDLE: begin
                    we_b     <= 0;
                    addren_b <= 0;

                    if (donea_pulse_r) begin
                        addr_w_b    <= 0;
                        bit_idx_w_b <= 0;
                        pattern_w_b <= walking_one_b(0);
                        wstate_b    <= W_WRITE;
                    end
                end

                W_WRITE: begin
                    we_b      	  <= 1'b1;
                    addren_b  	  <= 1'b1;
                    addr_b    	  <= addr_w_b;
                    wdata_b   	  <= pattern_w_b;
                    reqb_toggle_w <= ~reqb_toggle_w; // request read/compare
                    wstate_b 	  <= W_WAIT_ACK;
                end

                W_WAIT_ACK: begin
                    we_b     <= 0;
                    addren_b <= 0;

                    if (ackb_pulse_w) begin
                        if (!last_addr_w_b) begin
                            addr_w_b <= addr_w_b + 1'b1;
                            wstate_b <= W_WRITE;
                        end else begin
                            addr_w_b <= 0;

                            if (!last_bit_w_b) begin
                                bit_idx_w_b <= bit_idx_w_b + 1'b1;
                                pattern_w_b <= walking_one_b(bit_idx_w_b + 1);
                                wstate_b <= W_WRITE;
                            end else begin
                                done_b <= 1'b1;
                                pass_b <= ~fail_b;
                                wstate_b <= W_IDLE;
                            end
                        end
                    end
                end

            endcase
        end
    end

    //------------------------------------------------------------
    // Read Domain
    //------------------------------------------------------------
    always_ff @(posedge clk_a or posedge reset_a) begin
        if (reset_a) begin
            acka_toggle_r  <= 0;
            fail_a	   <= 0;
        end else begin
	    if ((reqa_pulse_r_reg2 && OUTPUT_REG_A==1'b0)||(reqa_pulse_r_reg3 && OUTPUT_REG_A==1'b1)) begin
		if(rdata_a !== pattern_w_a) begin
			fail_a <= 1'b1;
		end
                acka_toggle_r <= ~acka_toggle_r;
	    end	    

        end
    end

    always_ff @(posedge clk_b or posedge reset_b) begin
        if (reset_b) begin
            ackb_toggle_r  <= 0;
            fail_b	   <= 0;
        end else begin
	    if ((reqb_pulse_r_reg2 && OUTPUT_REG_B==1'b0)||(reqb_pulse_r_reg3 && OUTPUT_REG_B==1'b1)) begin
		if(rdata_b !== pattern_w_b) begin
			fail_b <= 1'b1;
		end
                ackb_toggle_r <= ~ackb_toggle_r;
	    end	    

        end
    end    

endmodule
