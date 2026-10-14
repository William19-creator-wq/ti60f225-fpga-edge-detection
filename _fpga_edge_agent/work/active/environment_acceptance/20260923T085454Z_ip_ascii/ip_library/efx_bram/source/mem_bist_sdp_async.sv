
module `IP_MODULE_NAME(mem_bist_sdp_async) #(
parameter OUT_REG = 1'b0,
parameter BYTEEN_WIDTH = 'd2,
parameter ADDR_WIDTH_A = 'd3,
parameter DATA_WIDTH_A = 'd16,
parameter ADDR_WIDTH_B = 'd3,
parameter DATA_WIDTH_B = 'd16
)	(
    input  logic        wclk,
    input  logic        rclk,
    input  logic        reset,
    input  logic        start,

    // Memory interface
    output logic        we,
    output logic        re,
    output logic        wadren,
    output logic        radren,

    output logic [ADDR_WIDTH_A-1:0]  waddr,
    output logic [ADDR_WIDTH_B-1:0]  raddr,
    output logic [DATA_WIDTH_A-1:0] wdata_a,
    input  logic [DATA_WIDTH_B-1:0] rdata_b,

    output logic [BYTEEN_WIDTH-1:0]  byteen,
    output logic        wclke,

    // Status
    output logic        done,
    output logic        pass,
    output logic        fail
);


    //------------------------------------------------------------
    // Walking‑1 pattern
    //------------------------------------------------------------
    function automatic logic [DATA_WIDTH_A-1:0] walking_one (input int idx);
        logic [DATA_WIDTH_A:0] tmp;
        begin
            tmp = '0;
            tmp[idx] = 1'b1;
            return tmp;
        end
    endfunction

    //------------------------------------------------------------
    // CDC handshake (toggle based)
    //------------------------------------------------------------
    logic req_toggle_w, req_toggle_r_sync1, req_toggle_r_sync2;
    logic ack_toggle_r, ack_toggle_w_sync1, ack_toggle_w_sync2;

    // Sync request into read clock domain
    always_ff @(posedge rclk or posedge reset) begin
        if (reset) begin
            req_toggle_r_sync1 <= 0;
            req_toggle_r_sync2 <= 0;
        end else begin
            req_toggle_r_sync1 <= req_toggle_w;
            req_toggle_r_sync2 <= req_toggle_r_sync1;
        end
    end

    // Sync acknowledge into write clock domain
    always_ff @(posedge wclk or posedge reset) begin
        if (reset) begin
            ack_toggle_w_sync1 <= 0;
            ack_toggle_w_sync2 <= 0;
        end else begin
            ack_toggle_w_sync1 <= ack_toggle_r;
            ack_toggle_w_sync2 <= ack_toggle_w_sync1;
        end
    end


    wire req_pulse_r = req_toggle_r_sync1 ^ req_toggle_r_sync2;
    wire ack_pulse_w = ack_toggle_w_sync1 ^ ack_toggle_w_sync2;


    logic req_pulse_r_reg;
    logic req_pulse_r_reg2;
    logic req_pulse_r_reg3;

    always_ff @(posedge rclk or posedge reset) begin
	    if(reset) begin
		req_pulse_r_reg  <= 1'b0;
		req_pulse_r_reg2 <= 1'b0;
		req_pulse_r_reg3 <= 1'b0;
	    end else begin
		req_pulse_r_reg  <= req_pulse_r;    
		req_pulse_r_reg2 <= req_pulse_r_reg; 
		req_pulse_r_reg3 <= req_pulse_r_reg2;
	    end
    end

    //------------------------------------------------------------
    // Write Domain
    //------------------------------------------------------------
    typedef enum logic [1:0] {W_IDLE, W_WRITE, W_WAIT_ACK} wstate_t;
    wstate_t wstate;

    logic [13:0]  addr_w;
    logic [9:0]  bit_idx_w;
    logic [DATA_WIDTH_A-1:0] pattern_w;

    wire last_addr_w = (addr_w == {ADDR_WIDTH_A{1'b1}});
    wire last_bit_w  = (bit_idx_w == (DATA_WIDTH_A-1));

    always_ff @(posedge wclk or posedge reset) begin
        if (reset) begin
            wstate       <= W_IDLE;
            we           <= 0;
            wadren       <= 0;
            waddr        <= '0;
            wdata_a      <= '0;
            byteen       <= 2'b11;
            wclke        <= 1'b1;
            addr_w       <= '0;
            bit_idx_w    <= '0;
            pattern_w    <= '0;
            req_toggle_w <= 0;
            done         <= 0;
            pass         <= 0;
        end else begin
            case (wstate)

                W_IDLE: begin
                    we   <= 0;
                    wadren <= 0;

                    if (start) begin
                        addr_w    <= 0;
                        bit_idx_w <= 0;
                        pattern_w <= walking_one(0);
                        wstate    <= W_WRITE;
                    end
                end

                W_WRITE: begin
                    we      <= 1'b1;
                    wadren  <= 1'b1;
                    waddr   <= addr_w;
                    wdata_a <= pattern_w;

                    req_toggle_w <= ~req_toggle_w; // request read/compare
                    wstate <= W_WAIT_ACK;
                end

                W_WAIT_ACK: begin
                    we     <= 0;
                    wadren <= 0;

                    if (ack_pulse_w) begin
                        if (!last_addr_w) begin
                            addr_w <= addr_w + 1'b1;
                            wstate <= W_WRITE;
                        end else begin
                            addr_w <= 0;

                            if (!last_bit_w) begin
                                bit_idx_w <= bit_idx_w + 1'b1;
                                pattern_w <= walking_one(bit_idx_w + 1);
                                wstate <= W_WRITE;
                            end else begin
                                done <= 1'b1;
                                pass <= ~fail;
                                wstate <= W_IDLE;
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
    always_ff @(posedge rclk or posedge reset) begin
        if (reset) begin
            re           <= 0;
            radren       <= 0;
            raddr        <= '0;
            ack_toggle_r <= 0;
            fail	 <= 0;
        end else begin
            re     <= 0;
            radren <= 0;

            if (req_pulse_r) begin
                re     <= 1'b1;
                radren <= 1'b1;
                raddr  <= addr_w; // safe: addr_w stable during WAIT_ACK
            end
	    else if (req_pulse_r_reg && OUT_REG==1'b1) begin
		re     <= 1'b1;
	    	radren <= 1'b1;
		raddr  <= addr_w;	
	    end

	    if ((req_pulse_r_reg2 && OUT_REG==1'b0)||(req_pulse_r_reg3 && OUT_REG==1'b1)) begin
		if(rdata_b !== pattern_w) begin
			fail <= 1'b1;
		end
                ack_toggle_r <= ~ack_toggle_r;		
	    end	    

        end
    end

endmodule
