
module tdp_test_pattern #(
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
    output reg                    addren = 0,
    output reg                    bram_rst = 0,
    output integer                state_out

);

localparam TEST_RESET = 21;
localparam TEST_INIT = 0;
localparam TEST_INIT_VAL = 1;
localparam TEST_NORMAL_SCAN = 2;
localparam TEST_DIFF_VALUE_ADDR = 3;
localparam TEST_CLKEN_DISABLE = 4;
localparam TEST_CLKEN_DISABLE_RAND = 5;
localparam TEST_WEN_DISABLE = 6;
localparam TEST_WEN_DISABLE_RAND = 7;
localparam TEST_ADDREN_DISABLE = 8;
localparam TEST_ADDREN_DISABLE_RAND = 9;
localparam TEST_BYTEEN_DISABLE = 10;
localparam TEST_BYTEEN_DISABLE_RAND = 11;
localparam TEST_SAME_VALUE_ADDR = 12;
localparam TEST_REN_DISABLE = 13;
localparam TEST_REN_DISABLE_RAND = 14;
localparam TEST_RST = 15;
localparam TEST_SAMEADDR_RANDOM = 16;
localparam TEST_RANDOM1 = 17;
localparam TEST_RANDOM2 = 18;
localparam TEST_RANDOM3 = 19;
localparam TEST_END = 20;
localparam TEST_READOUT = 999;
localparam TEST_RST_B4_WRITE = 22;
localparam TEST_RST_B4_READ = 23;
localparam TEST_RST_DURING_WRITE = 24;
localparam TEST_RST_DURING_READ = 25;
localparam TEST_RST_AFTER_WRITE = 26;
localparam TEST_RST_AFTER_READ = 27;

integer state = TEST_RESET;
integer next_state = TEST_RESET;
integer dummy = 0;
integer read_cnt = 0;
integer write_cnt = 0;
integer read_out = 0;
integer init_cnt = 0;
integer rpt_cnt, rpt_cntr;
integer rst_cnt = 0;


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
    	    read_out <= 0;
            clke <= 1;
            we <= 0;
            addr <= {ADDR_WIDTH{1'b0}};
            byteen <= ~{BYTEEN_WIDTH{1'b1}};
            wdata <= {DATA_WIDTH{1'b0}};
            addren <= 1;
            bram_rst <= 1;
            sim_end <= 0;
	    rpt_cnt <= $urandom_range(1, 10);
	    rpt_cntr <= 0;
	end
        TEST_INIT: begin
            clke        <= 0;
            we          <= 0;
            byteen      <= ~{BYTEEN_WIDTH{1'b1}};
            addren      <= 0;
            bram_rst   <= 0;
            addr          <= {ADDR_WIDTH{1'b0}};
            wdata         <= 0;
	    if (rpt_cntr != rpt_cnt) begin
		state <= TEST_INIT;
		rpt_cntr <= rpt_cntr +1;
	    end else if (rpt_cntr == rpt_cnt) begin 
	    	if (init_cnt > 0) begin
			state   <= $urandom_range(20, 2);
	    	end else begin
			state       <= state + 1;
			init_cnt <= init_cnt +1;
	    	end
	    end
            read_cnt    <= 0;
            write_cnt   <= 0;
        end

        TEST_INIT_VAL: begin
            state      <= TEST_READOUT;
            next_state <= state + 1;
        end

        TEST_NORMAL_SCAN,
        TEST_CLKEN_DISABLE,
        TEST_CLKEN_DISABLE_RAND,
        TEST_WEN_DISABLE,
        TEST_WEN_DISABLE_RAND,
        TEST_ADDREN_DISABLE,
        TEST_ADDREN_DISABLE_RAND,
        TEST_BYTEEN_DISABLE,
        TEST_BYTEEN_DISABLE_RAND,
        TEST_SAME_VALUE_ADDR: begin
            if (write_cnt == (1<<ADDR_WIDTH)) begin
		`ifdef PR1TW
		state	    <= TEST_END;
		`else
                state       <= TEST_READOUT;
		`endif
                next_state  <= state + 1;
                write_cnt   <= 0;

                addr        <= 0;
                wdata       <= {DATA_WIDTH{1'b0}};
                clke        <= 0;
                we          <= 0;
                addren      <= 0;
                byteen      <= ~{BYTEEN_WIDTH{1'b1}};
            end else begin
                write_cnt   <= write_cnt + 1;

                wdata       <= state == TEST_SAME_VALUE_ADDR ? write_cnt[DATA_WIDTH-1:0] : get_rand_wr_data(dummy);
                addr        <= SCAN_MODE ? 
                                !(state == TEST_SAME_VALUE_ADDR) ? 
                                ~write_cnt[0 +: ADDR_WIDTH] : 
                                write_cnt[0 +: ADDR_WIDTH] : 
                                write_cnt[0 +: ADDR_WIDTH];
                clke       <= state == TEST_CLKEN_DISABLE ? 0 : 
                            state == TEST_CLKEN_DISABLE_RAND ? get_rand_en(dummy) : 
                            1;    
                we          <= state == TEST_WEN_DISABLE ? 0 :
                            state == TEST_WEN_DISABLE_RAND ? get_rand_en(dummy) : 
                            1;
                addren      <= state == TEST_ADDREN_DISABLE ? 0 : 
                            state == TEST_ADDREN_DISABLE_RAND ? get_rand_en(dummy) : 
                            1;
                byteen      <= state == TEST_BYTEEN_DISABLE ? ~{BYTEEN_WIDTH{1'b1}} : 
                            state == TEST_BYTEEN_DISABLE_RAND ? get_rand_byteen(dummy) : 
                            {BYTEEN_WIDTH{1'b1}};
                $display("%t ps - write data %h to address: %d ", $time(), wdata, addr);
            end
        end

	TEST_DIFF_VALUE_ADDR: begin
            if (write_cnt == ((1<<ADDR_WIDTH)+1)) begin
                state       <= TEST_READOUT;
                next_state  <= state + 1;
                write_cnt   <= 0;

                addr        <= 0;
                wdata       <= {DATA_WIDTH{1'b0}};
                clke        <= 0;
                we          <= 0;
                addren      <= 0;
                byteen      <= ~{BYTEEN_WIDTH{1'b1}};
            end else begin
		write_cnt   <= write_cnt + 1;

                wdata       <= get_rand_wr_data(dummy);
                addr        <= write_cnt == (1<<ADDR_WIDTH) ? 0 : write_cnt[0 +: ADDR_WIDTH];
                clke       <= 1;    
                we          <= 1;
                addren      <= 1;
                byteen      <= {BYTEEN_WIDTH{1'b1}};
                $display("%t ps - write data %h to address: %d ", $time(), wdata, addr);
            end
        end
	
        TEST_REN_DISABLE, 
        TEST_REN_DISABLE_RAND: begin
            clke    <= state == TEST_REN_DISABLE ? 0 : 
                            get_rand_en(dummy);
            we      <= 0;
            byteen  <= ~{BYTEEN_WIDTH{1'b1}};
            wdata     <= 0;

            if (read_cnt == (1<<ADDR_WIDTH)) begin
		`ifdef FULL
			state	    <= state + 1;
		`else
                	state       <= $urandom_range(21, 2);
		`endif
                read_cnt    <= 0;
                write_cnt   <= 0;

                addr        <= 0;
                wdata       <= {DATA_WIDTH{1'b0}};
                clke        <= 0;
                we          <= 0;
                addren      <= 0;
                byteen      <= ~{BYTEEN_WIDTH{1'b1}};
            end else begin
                addren      <= 1;
                addr        <= read_cnt[0 +: ADDR_WIDTH];
                read_cnt    <= read_cnt + 1;
            end
        end

        TEST_RST: begin
            if (write_cnt < 10) begin
                bram_rst    <= 1;
                clke        <= 1;
                write_cnt   <= write_cnt + 1;
            end else begin   
                `ifdef FULL
			state	    <= state + 1;
		`else
                	state       <= $urandom_range(21, 2);
		`endif
                bram_rst    <= 0;
                clke        <= 0;
                write_cnt   <= 0;
            end
        end

        TEST_SAMEADDR_RANDOM,
        TEST_RANDOM1: begin
            if (write_cnt == (1 << ADDR_WIDTH)) begin
                state       <= TEST_READOUT;
                next_state  <= state + 1;
                write_cnt   <= 0;

                addr        <= 0;
                wdata       <= {DATA_WIDTH{1'b0}};
                clke        <= 0;
                we          <= 0;
                addren      <= 0;
                byteen      <= ~{BYTEEN_WIDTH{1'b1}};
            end else begin
                write_cnt   <= write_cnt + 1;

                addr        <= state == TEST_SAMEADDR_RANDOM ? write_cnt[0 +: ADDR_WIDTH] : get_rand_addr(dummy);
                wdata       <= get_rand_wr_data(dummy);
                clke        <= get_rand_en(dummy);
                we          <= get_rand_en(dummy);
                addren      <= get_rand_en(dummy);
                byteen      <= get_rand_byteen(dummy);
                bram_rst    <= get_rand_en(dummy);
                $display("%t ps - write data %h to address: %d ", $time(), wdata, addr);
            end
        end
	
	TEST_RANDOM2: begin
            if (write_cnt > 30) begin
                state       <= TEST_READOUT;
                next_state  <= state + 1;
                write_cnt   <= 0;

                addr        <= 0;
                wdata       <= {DATA_WIDTH{1'b0}};
                clke        <= 0;
                we          <= 0;
                addren      <= 0;
                byteen      <= ~{BYTEEN_WIDTH{1'b1}};
            end else begin
                write_cnt   <= write_cnt + 1;

                addr        <= (write_cnt == 0 || write_cnt == 10 || write_cnt == 20)? get_rand_addr(dummy) : addr;
                wdata       <= get_rand_wr_data(dummy);
                clke        <= get_rand_en(dummy);
                we          <= 1;
                addren      <= get_rand_en(dummy);
                byteen      <= get_rand_byteen(dummy);
                bram_rst    <= get_rand_en(dummy);
                $display("%t ps - write data %h to address: %d ", $time(), wdata, addr);
            end
        end

	TEST_RANDOM3: begin
            if (read_cnt > 30) begin
                state       <= TEST_READOUT;
                next_state  <= state + 1;
                read_cnt   <= 0;

                addr        <= 0;
                wdata       <= {DATA_WIDTH{1'b0}};
                clke        <= 0;
                we          <= 0;
                addren      <= 0;
                byteen      <= ~{BYTEEN_WIDTH{1'b1}};
            end else begin
                read_cnt   <= read_cnt + 1;

                addr        <= (read_cnt == 0 || read_cnt == 10 || read_cnt == 20)? get_rand_addr(dummy) : addr;
                wdata      <= {DATA_WIDTH{1'b0}};
                clke        <= get_rand_en(dummy);
                we          <= 0;
                addren      <= get_rand_en(dummy);
                byteen      <= get_rand_byteen(dummy);
                bram_rst    <= get_rand_en(dummy);
                $display("%t ps - read data from address: %d ", $time(), addr);
            end
        end

	TEST_RST_B4_WRITE: begin
	    if (rst_cnt > 3) begin
	    	if (write_cnt == (1<<ADDR_WIDTH)) begin
			state       <= TEST_READOUT;
			next_state  <= state + 1;
			bram_rst    <= 0;
                	clke        <= 0;
			we          <= 0;
			addren      <= 0;
			addr        <= 0;
			write_cnt   <= 0;
			wdata       <= {DATA_WIDTH{1'b0}};
			byteen      <= ~{BYTEEN_WIDTH{1'b1}};
			rst_cnt	    <= 0;	
	    	end else begin
			bram_rst    <= 0;
                	clke        <= 1;
			we          <= 1;
			addren      <= 1;
			addr        <= write_cnt[0 +: ADDR_WIDTH];
			write_cnt   <= write_cnt + 1;
			wdata       <= get_rand_wr_data(dummy);
			byteen      <= {BYTEEN_WIDTH{1'b1}};
			rst_cnt	    <= rst_cnt + 1;
		end
	    end else if (rst_cnt > 2)begin
		if (read_cnt == (1<<ADDR_WIDTH)) begin
			bram_rst    <= 0;
                	clke        <= 0;
			we          <= 0;
			addren      <= 0;
			addr        <= 0;
			read_cnt   <= 0;
			rst_cnt	    <= rst_cnt + 1;	
	    	end else begin
			bram_rst    <= 0;
                	clke        <= 1;
			we          <= 0;
			addren      <= 1;
			addr        <= read_cnt[0 +: ADDR_WIDTH];
			read_cnt    <= read_cnt + 1;
		end
	    end else if (rst_cnt > 0)begin
		bram_rst    <= 1;
                clke        <= 1;
		we          <= 1;
		addren      <= 1;
		addr        <= get_rand_addr(dummy);
		write_cnt   <= 0;
		wdata       <= get_rand_wr_data(dummy);
		byteen      <= get_rand_byteen(dummy);
		rst_cnt	    <= rst_cnt + 1;
	    end else begin
		bram_rst    <= 1;
                clke        <= 0;
		we          <= 0;
		addren      <= 0;
		addr        <= 0;
		write_cnt   <= 0;
		wdata       <= {DATA_WIDTH{1'b0}};
		byteen      <= ~{BYTEEN_WIDTH{1'b1}};
		rst_cnt	    <= rst_cnt + 1;
	    end	
	end

	TEST_RST_B4_READ: begin
	    if (rst_cnt > 3) begin
	    	if (read_cnt == (1<<ADDR_WIDTH)) begin
			state       <= state + 1;
			next_state  <= state + 1;
			bram_rst    <= 0;
                	clke        <= 0;
			we          <= 0;
			addren      <= 0;
			addr        <= 0;
			read_cnt   <= 0;
			rst_cnt	    <= 0;	
	    	end else begin
			bram_rst    <= 0;
                	clke        <= 1;
			we          <= 0;
			addren      <= 1;
			addr        <= read_cnt[0 +: ADDR_WIDTH];
			read_cnt    <= read_cnt + 1;
			rst_cnt	    <= rst_cnt + 1;
		end
	    end else if (rst_cnt > 0)begin
		bram_rst    <= 1;
                clke        <= 1;
		we          <= 0;
		addren      <= 1;
		addr        <= get_rand_addr(dummy);
		read_cnt   <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end else begin
		bram_rst    <= 1;
                clke        <= 0;
		we          <= 0;
		addren      <= 0;
		addr        <= 0;
		read_cnt   <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end	
	end

	TEST_RST_DURING_WRITE: begin
	    if (rst_cnt > 3) begin
	    	if (write_cnt == (1<<ADDR_WIDTH)) begin
			state       <= TEST_READOUT;
			next_state  <= state + 1;
			bram_rst    <= 0;
                	clke        <= 0;
			we          <= 0;
			addren      <= 0;
			addr        <= 0;
			write_cnt   <= 0;
			wdata       <= {DATA_WIDTH{1'b0}};
			byteen      <= ~{BYTEEN_WIDTH{1'b1}};
			rst_cnt	    <= 0;	
	    	end else begin
			bram_rst    <= 0;
                	clke        <= 1;
			we          <= 1;
			addren      <= 1;
			addr        <= write_cnt[0 +: ADDR_WIDTH];
			write_cnt   <= write_cnt + 1;
			wdata       <= get_rand_wr_data(dummy);
			byteen      <= {BYTEEN_WIDTH{1'b1}};
			rst_cnt	    <= rst_cnt + 1;
		end
	    end else if (rst_cnt > 2)begin
		if (read_cnt == (1<<ADDR_WIDTH)) begin
			bram_rst    <= 0;
                	clke        <= 0;
			we          <= 0;
			addren      <= 0;
			addr        <= 0;
			read_cnt   <= 0;
			rst_cnt	    <= rst_cnt + 1;	
	    	end else begin
			bram_rst    <= 0;
                	clke        <= 1;
			we          <= 0;
			addren      <= 1;
			addr        <= read_cnt[0 +: ADDR_WIDTH];
			read_cnt    <= read_cnt + 1;
		end
	    end else if (rst_cnt > 0)begin
		#2;
		bram_rst    <= 1;
                clke        <= 1;
		we          <= 1;
		addren      <= 1;
		addr        <= get_rand_addr(dummy);
		write_cnt   <= 0;
		wdata       <= get_rand_wr_data(dummy);
		byteen      <= get_rand_byteen(dummy);
		rst_cnt	    <= rst_cnt + 1;
	    end else begin
		bram_rst    <= 0;
                clke        <= 1;
		we          <= 1;
		addren      <= 1;
		addr        <= write_cnt;
		write_cnt   <= 0;
		wdata       <= get_rand_wr_data(dummy);
		byteen      <= {BYTEEN_WIDTH{1'b1}};
		rst_cnt	    <= rst_cnt + 1;
	    end	
	end

	TEST_RST_DURING_READ: begin
	    if (rst_cnt > 3) begin
	    	if (read_cnt == (1<<ADDR_WIDTH)) begin
			state       <= state + 1;
			next_state  <= state + 1;
			bram_rst    <= 0;
                	clke        <= 0;
			we          <= 0;
			addren      <= 0;
			addr        <= 0;
			read_cnt   <= 0;
			rst_cnt	    <= 0;	
	    	end else begin
			bram_rst    <= 0;
                	clke        <= 1;
			we          <= 0;
			addren      <= 1;
			addr        <= read_cnt[0 +: ADDR_WIDTH];
			read_cnt    <= read_cnt + 1;
			rst_cnt	    <= rst_cnt + 1;
		end
	    end else if (rst_cnt > 0)begin
		#2;
		bram_rst    <= 1;
                clke        <= 1;
		we          <= 0;
		addren      <= 1;
		addr        <= get_rand_addr(dummy);
		read_cnt   <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end else begin
		bram_rst    <= 0;
                clke        <= 1;
		we          <= 0;
		addren      <= 1;
		addr        <= 0;
		read_cnt   <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end	
	end
	

	TEST_RST_AFTER_WRITE: begin
	    if (rst_cnt > 3) begin
		state       <= TEST_READOUT;
		next_state  <= state + 1;
	    	bram_rst    <= 0;
                clke        <= 0;
		we          <= 0;
		addren      <= 0;
		addr        <= 0;
		write_cnt   <= 0;
		wdata       <= {DATA_WIDTH{1'b0}};
		byteen      <= ~{BYTEEN_WIDTH{1'b1}};
		rst_cnt	    <= 0;
	    end else if (rst_cnt > 2)begin
		bram_rst    <= 0;
                clke        <= 0;
		we          <= 0;
		addren      <= 0;
		addr        <= 0;
		write_cnt   <= 0;
		wdata       <= {DATA_WIDTH{1'b0}};
		byteen      <= ~{BYTEEN_WIDTH{1'b1}};
		rst_cnt	    <= rst_cnt + 1;
	    end else if (rst_cnt > 0)begin
		bram_rst    <= 1;
                clke        <= 0;
		we          <= 0;
		addren      <= 0;
		addr        <= 0;
		write_cnt   <= 0;
		wdata       <= {DATA_WIDTH{1'b0}};
		byteen      <= ~{BYTEEN_WIDTH{1'b1}};
		rst_cnt	    <= rst_cnt + 1;
	    end else begin
		if (write_cnt == (1<<ADDR_WIDTH)) begin
			bram_rst    <= 1;
                	clke        <= 0;
			we          <= 0;
			addren      <= 0;
			addr        <= 0;
			write_cnt   <= 0;
			wdata       <= {DATA_WIDTH{1'b0}};
			byteen      <= ~{BYTEEN_WIDTH{1'b1}};
			rst_cnt	    <= rst_cnt + 1;	
	    	end else begin
			bram_rst    <= 0;
                	clke        <= 1;
			we          <= 1;
			addren      <= 1;
			addr        <= write_cnt[0 +: ADDR_WIDTH];
			write_cnt   <= write_cnt + 1;
			wdata       <= get_rand_wr_data(dummy);
			byteen      <= {BYTEEN_WIDTH{1'b1}};
		end
	    end	
	end

	TEST_RST_AFTER_READ: begin
	    if (rst_cnt > 3) begin
		state       <= TEST_READOUT;
		next_state  <= TEST_END;
	    	bram_rst    <= 0;
                clke        <= 0;
		we          <= 0;
		addren      <= 0;
		addr        <= 0;
		read_cnt    <= 0;
		rst_cnt	    <= 0;
	    end else if (rst_cnt > 2)begin
		bram_rst    <= 0;
                clke        <= 0;
		we          <= 0;
		addren      <= 0;
		addr        <= 0;
		read_cnt    <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end else if (rst_cnt > 0)begin
		bram_rst    <= 1;
                clke        <= 0;
		we          <= 0;
		addren      <= 0;
		addr        <= 0;
		read_cnt    <= 0;
		rst_cnt	    <= rst_cnt + 1;
	    end else begin
		if (read_cnt == (1<<ADDR_WIDTH)) begin
			bram_rst    <= 1;
                	clke        <= 0;
			we          <= 0;
			addren      <= 0;
			addr        <= 0;
			read_cnt   <= 0;
			rst_cnt	    <= rst_cnt + 1;	
	    	end else begin
			bram_rst    <= 0;
                	clke        <= 1;
			we          <= 0;
			addren      <= 1;
			addr        <= read_cnt[0 +: ADDR_WIDTH];
			read_cnt    <= read_cnt + 1;
		end
	    end	
	end

        TEST_END: begin
            clke            <= 0;
            we            <= 0;
            byteen          <= ~{BYTEEN_WIDTH{1'b1}};
            addren          <= 0;
            addr            <= {ADDR_WIDTH{1'b1}};
            wdata           <= 0;
            state           <= state;

            if (write_cnt > 5) begin
                sim_end <= 1;
            end else begin
                write_cnt    <= write_cnt + 1;
            end
        end

        TEST_READOUT: begin
            clke    <= 1;
            we    <= 0;
            byteen  <= ~{BYTEEN_WIDTH{1'b1}};
            wdata   <= 0;

            if (read_cnt == (1<<ADDR_WIDTH)) begin
		`ifdef PW1TR
			if (read_out > 0) begin
				state	    <= TEST_END;
			end else begin
				state	    <= next_state;
				read_out <= read_out +1;
			end
		`elsif PR1TW
			state       <= TEST_NORMAL_SCAN;
		`elsif FULL
			 state       <= next_state;
		`elsif LESS
			if (read_out > 0) begin
				state	    <= TEST_END;
			end else begin
				state	    <= next_state;
				read_out <= read_out +1;
			end
		`elsif RESET
			if (read_out > 0) begin
				state	    <= next_state;
			end else begin
				state	    <= TEST_RST_B4_WRITE;
				read_out <= read_out +1;
			end
		`elsif MIX_RESET
			if (read_out > 4) begin
				state	    <= TEST_END;
			end else begin
				state	    <= $urandom_range(19, 16);
				read_out <= read_out +1;
			end
		`else
                	if (read_out > 2) begin
				state	    <= TEST_END;
			end else begin
				state	    <= $urandom_range(19, 2);
				read_out <= read_out +1;
			end
		`endif
                //state       <= next_state;
		clke    <= 0;
                addren      <= 0;
                addr        <= 0;
                read_cnt    <= 0;
		
            end else begin
                addren      <= 1;
                addr        <= read_cnt[0 +: ADDR_WIDTH];
                read_cnt    <= read_cnt + 1;
            end
        end

        endcase
    end
    
    
end

initial begin
	$display("==============");
    $display("Testbench begin!");
    $display("==============");
end

always @(state) begin
	$display("\nSTATE : %d \n", state);
end

endmodule
