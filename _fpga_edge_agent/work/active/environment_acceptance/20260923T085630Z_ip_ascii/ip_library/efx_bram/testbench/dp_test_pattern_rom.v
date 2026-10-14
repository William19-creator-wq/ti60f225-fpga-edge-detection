
module dp_test_pattern_rom #(
    parameter SEED_INIT = 999,
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 16,
    parameter BYTEEN_WIDTH = 8,

    parameter SCAN_MODE = 0 //1 == incr, 0 == decr
) (
    /**
     * @brieft assume high/posedge is active for all signals except rstn 
     */
    input                         clk,
    input                         rstn,
    output reg                    sim_end = 0,

    output reg [ADDR_WIDTH-1:0 ]  addr = {ADDR_WIDTH{1'b0}},
    output reg [DATA_WIDTH-1:0 ]  wdata = {DATA_WIDTH{1'b0}},
    output reg                    clke = 0,
    output reg                    we = 0,
    output reg [BYTEEN_WIDTH-1:0] byteen = {BYTEEN_WIDTH{1'b0}},
    output reg                    addren = 1,
    output reg                    bram_rst = 0,
    output integer                state_out

);

localparam TEST_RESET = 11;
localparam TEST_INIT = 0;
localparam TEST_INIT_VAL = 1;
localparam TEST_ADDREN_DISABLE = 2;
localparam TEST_ADDREN_DISABLE_RAND = 3;
localparam TEST_SAME_VALUE_ADDR = 4;
localparam TEST_RST = 5;
localparam TEST_SAMEADDR_RANDOM = 6;
localparam TEST_RANDOM1 = 7;
localparam TEST_RANDOM2 = 8;
localparam TEST_RANDOM3 = 9;
localparam TEST_END = 10;
localparam TEST_READOUT = 999;
localparam TEST_RST_B4_READ = 12;
localparam TEST_RST_DURING_READ = 13;
localparam TEST_RST_AFTER_READ = 14;

integer state = TEST_INIT;
integer next_state = TEST_INIT;
integer dummy = 0;
integer read_cnt = 0;
integer write_cnt = 0;
integer rst_cnt = 0;
integer read_out = 0;

always @(*) begin
	assign state_out = state;
end

function [DATA_WIDTH-1:0] get_rand_wr_data(input integer dummy);
    reg [DATA_WIDTH-1:0] temp;
    integer i;
    begin
        temp = {DATA_WIDTH{1'b0}};
        for(i=0 ; i<$rtoi($ceil(DATA_WIDTH/32.0)) ; i=i+1) begin
            temp = temp << 32 | $random();
        end

        get_rand_wr_data = temp;
    end
endfunction

function [ADDR_WIDTH-1:0] get_rand_addr(input integer dummy);
    reg [ADDR_WIDTH-1:0] temp;
    integer i;
    begin
        temp = {ADDR_WIDTH{1'b0}};
        for(i=0 ; i<$rtoi($ceil(ADDR_WIDTH/32.0)) ; i=i+1) begin
            temp = temp << 32 | $random();
        end

        get_rand_addr = temp;
    end
endfunction

function get_rand_en(input integer dummy);
    integer random;
    integer temp;
    integer i;
    begin
        temp = 0;
        random = $random();
        for(i=0 ; i<32 ; i=i+1) begin
            temp = temp + random[0];
            random = random >> 1;
        end
        get_rand_en = temp[0];
    end
endfunction

function [BYTEEN_WIDTH-1:0] get_rand_byteen(input integer dummy);
    reg [BYTEEN_WIDTH-1:0] temp;
    integer i;
    begin
        temp = {BYTEEN_WIDTH{1'b0}};
        for(i=0 ; i<BYTEEN_WIDTH ; i=i+1) begin
            temp = temp << 1;
            temp[0] = get_rand_en(dummy);
        end

        get_rand_byteen = temp;
    end
endfunction
always @(posedge clk) begin
    if (~rstn) begin
	state <= TEST_RESET;
    end else begin
	case (state)
	TEST_RESET: begin
            state <= TEST_INIT;
            next_state <= TEST_INIT;
            dummy <= 0;
            read_cnt <= 0;
            write_cnt <= 0;
            clke <= 1;
            addr <= {ADDR_WIDTH{1'b0}};
            addren <= 1;
            bram_rst <= 1;
            sim_end <= 0;
    	end
        
        TEST_INIT: begin
            clke        <= 0;
            addren      <= 0;
            bram_rst    <= 0;
            addr        <= {ADDR_WIDTH{1'b0}};
            state       <= state + 1;
            read_cnt    <= 0;
            write_cnt   <= 0;
        end

        TEST_INIT_VAL: begin
            state      <= TEST_READOUT;
            next_state <= state + 1;
        end

        TEST_ADDREN_DISABLE,
        TEST_ADDREN_DISABLE_RAND,
        TEST_SAME_VALUE_ADDR: begin
            if (read_cnt == (1<<ADDR_WIDTH)) begin
                `ifdef FULL
                	state       <= state + 1;
		`else
			if (read_out > 2) begin
			    state	    <= TEST_END;
			end else begin
			    state       <= $urandom_range(9, 2);
			    read_out <= read_out +1;
			end
		`endif
                read_cnt    <= 0;
                addr        <= 0;
                clke        <= 0;
                addren      <= 0;

            end else begin
                read_cnt    <= read_cnt + 1;
                addr        <= SCAN_MODE ? 
                                !(state == TEST_SAME_VALUE_ADDR ) ? 
                                ~read_cnt[0 +: ADDR_WIDTH] : 
                                read_cnt[0 +: ADDR_WIDTH] : 
                                read_cnt[0 +: ADDR_WIDTH];
                clke        <= 1;    
                addren      <= state == TEST_ADDREN_DISABLE ? 0 : 
                            state == TEST_ADDREN_DISABLE_RAND ? get_rand_en(dummy) : 
                            1;
            end
        end


        TEST_RST: begin
                bram_rst    <= 1;
		clke        <= 1;
                addr        <= read_cnt[0 +: ADDR_WIDTH];
                addren      <= 1;                
                read_cnt    <= read_cnt + 1;

                if (read_cnt == (1<<ADDR_WIDTH)) begin
                `ifdef FULL
                	state       <= state + 1;
		`else
			if (read_out > 2) begin
			    state	    <= TEST_END;
			end else begin
			    state       <= $urandom_range(9, 2);
			    read_out <= read_out +1;
			end
		`endif
                bram_rst    <= 0;
                clke        <= 0;
                read_cnt    <= 0;
            end
        end

        TEST_SAMEADDR_RANDOM,
        TEST_RANDOM1, TEST_RANDOM2: begin
            if (read_cnt == (1 << ADDR_WIDTH)) begin
                `ifdef FULL
                	state       <= state + 1;
		`elsif LESS
			state       <= state + 1;
		`else
			if (read_out > 2) begin
			    state	    <= TEST_END;
			end else begin
			    state       <= $urandom_range(9, 2);
			    read_out <= read_out +1;
			end
		`endif
                read_cnt    <= 0;
                addr        <= 0;
                clke        <= 0;
                addren      <= 0;
            end else begin
                read_cnt    <= read_cnt + 1;

                addr        <= state == TEST_SAMEADDR_RANDOM ? read_cnt[0 +: ADDR_WIDTH] : get_rand_addr(dummy);
                clke        <= get_rand_en(dummy);
                addren      <= get_rand_en(dummy);
                bram_rst    <= get_rand_en(dummy);
            end
        end

	TEST_RANDOM3: begin
	    if (read_cnt > 30) begin
                `ifdef FULL
                	state       <= state + 1;
		`elsif LESS
			state       <= state + 1;
		`else
			if (read_out > 2) begin
			    state	    <= TEST_END;
			end else begin
			    state       <= $urandom_range(9, 2);
			    read_out <= read_out +1;
			end
		`endif
                read_cnt    <= 0;
                addr        <= 0;
                clke        <= 0;
                addren      <= 0;
            end else begin
                read_cnt    <= read_cnt + 1;

                addr        <= (read_cnt == 0 || read_cnt == 10 || read_cnt == 20)? get_rand_addr(dummy) : addr;
                clke        <= get_rand_en(dummy);
                addren      <= get_rand_en(dummy);
                bram_rst    <= get_rand_en(dummy);
            end
        end

	TEST_RST_B4_READ: begin
	    if (rst_cnt > 3) begin
            	if (read_cnt == (1<<ADDR_WIDTH)) begin
                    state       <= state + 1;
                    addren      <= 0;
                    addr        <= 0;
                    read_cnt    <= 0;
		    rst_cnt	<= 0;
		    clke    <= 0;
            	end else begin
		    bram_rst    <= 0;
                    addren      <= 1;
                    addr        <= read_cnt[0 +: ADDR_WIDTH];
                    read_cnt    <= read_cnt + 1;
            	end	
	    end else if (rst_cnt > 0)begin
		bram_rst    <= 1;
                addr        <= get_rand_addr(dummy);
                addren      <= 1;
                read_cnt    <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end else begin
		clke    <= 1;
		bram_rst    <= 1;
                addren      <= 0;
                addr        <= 0;
                read_cnt    <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end
	end

	TEST_RST_DURING_READ: begin
	    if (rst_cnt > 3) begin
            	if (read_cnt == (1<<ADDR_WIDTH)) begin
                    state       <= state + 1;
		    clke    <= 0;
		    bram_rst    <= 0;
                    addren      <= 0;
                    addr        <= 0;
                    read_cnt    <= 0;
		    rst_cnt	<= 0;
            	end else begin
		    bram_rst    <= 0;
                    addren      <= 1;
                    addr        <= read_cnt[0 +: ADDR_WIDTH];
                    read_cnt    <= read_cnt + 1;
            	end	
	    end else if (rst_cnt > 0)begin
		#2;
		bram_rst    <= 1;
                addr        <= get_rand_addr(dummy);
                addren      <= 1;
                read_cnt    <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end else begin
		clke    <= 1;
		bram_rst    <= 0;
                addren      <= 1;
                addr        <= 0;
                read_cnt    <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end
	end

	TEST_RST_AFTER_READ: begin
	    if (rst_cnt > 3) begin
		state       <= TEST_READOUT;
		next_state  <= TEST_END;
		rst_cnt	    <= 0;
	    end else if (rst_cnt > 2)begin
		bram_rst    <= 0;
                addren      <= 0;
                addr        <= 0;
                read_cnt    <= 0;
		clke    <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end else if (rst_cnt > 0)begin
		bram_rst    <= 1;
		clke    <= 0;
                addren      <= 0;
                addr        <= 0;
                read_cnt    <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end else begin
            	clke    <= 1;

            	if (read_cnt == (1<<ADDR_WIDTH)) begin
		    bram_rst    <= 0;
                    addren      <= 0;
                    addr        <= 0;
                    read_cnt    <= 0;
		    rst_cnt	    <= rst_cnt + 1;
            	end else begin
		    bram_rst    <= 0;
                    addren      <= 1;
                    addr        <= read_cnt[0 +: ADDR_WIDTH];
                    read_cnt    <= read_cnt + 1;
            	end
	    end
	end
	
        TEST_END: begin
            clke            <= 0;
            addren          <= 0;
            addr            <= {ADDR_WIDTH{1'b1}};
            state           <= state;

            if (read_cnt > 5) begin
                sim_end <= 1;
            end else begin
                read_cnt    <= read_cnt + 1;
            end
        end

        TEST_READOUT: begin

            if (read_cnt == (1<<ADDR_WIDTH)) begin
                `ifdef FULL
                	state       <= state + 1;
		`elsif LESS
			state       <= TEST_RANDOM1;
		`elsif RESET
		    if (read_out > 0) begin
			state	    <= next_state;
		    end else begin
			state	    <= TEST_RST_B4_READ;
			read_out <= read_out +1;
		    end
		`else
			state       <= $urandom_range(9, 2);
			read_out <= read_out +1;
		`endif
                addren      <= 0;
                addr        <= 0;
                read_cnt    <= 0;
		clke    <= 0;
            end else begin
		clke    <= 1;
                addren      <= 1;
                addr        <= read_cnt[0 +: ADDR_WIDTH];
                read_cnt    <= read_cnt + 1;
            end
        end

        endcase
    end
    
    
end

initial begin
	$display("================");
    $display("Testbench begin!");
    $display("================");
end

always @(state) begin
	$display("\nSTATE : %d \n", state);
end

endmodule
