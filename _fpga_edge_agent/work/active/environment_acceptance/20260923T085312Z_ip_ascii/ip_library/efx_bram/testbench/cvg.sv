//string to number
function int family_to_int(string family);
	if (family == "TITANIUM")  return 0;
	if (family == "TRION")  return 1;
	return -1;
endfunction

function int mtype_to_int(string mtype);
	if (mtype == "SP_RAM")  return 0;
	if (mtype == "SDP_RAM")  return 1;
	if (mtype == "TDP_RAM")  return 2;
	if (mtype == "SP_ROM")  return 3;
	if (mtype == "DP_ROM")  return 4;
	return -1;
endfunction

function int mmode_to_int(string mmode);
	if (mmode == "SPEED")  return 0;
	if (mmode == "AREA")  return 1;
	return -1;
endfunction

function int wmode_to_int(string wmode);
	if (wmode == "READ_FIRST")  return 0;
	if (wmode == "WRITE_FIRST")  return 1;
	if (wmode == "READ_UNKNOWN")  return 2;
	if (wmode == "NO_CHANGE")  return 3;
	return -1;
endfunction

function int wmode_a_to_int(string wmode_a);
	if (wmode_a == "READ_FIRST")  return 0;
	if (wmode_a == "WRITE_FIRST")  return 1;
	if (wmode_a == "READ_UNKNOWN")  return 2;
	if (wmode_a == "NO_CHANGE")  return 3;
	return -1;
endfunction

function int wmode_b_to_int(string wmode_b);
	if (wmode_b == "READ_FIRST")  return 0;
	if (wmode_b == "WRITE_FIRST")  return 1;
	if (wmode_b == "READ_UNKNOWN")  return 2;
	if (wmode_b == "NO_CHANGE")  return 3;
	return -1;
endfunction

int family_num;
int mtype_num;
int mmode_num;
int wmode_num;
int wmode_a_num;
int wmode_b_num;

initial begin
	family_num = family_to_int(FAMILY);
	mtype_num = mtype_to_int(MEMORY_TYPE);
	mmode_num = mmode_to_int(MEMORY_MODE);
	wmode_num = wmode_to_int(WRITE_MODE);
	wmode_a_num = wmode_a_to_int(WRITE_MODE_A);
	wmode_b_num = wmode_b_to_int(WRITE_MODE_B);
end

//define previous logic
logic re_prev, we_prev, bram_rst_prev, we_a_prev, we_b_prev, clke_a_prev, clke_b_prev, clke_prev, bram_rst_a_prev, bram_rst_b_prev, wclke_prev, addren_prev, waddren_prev, raddren_prev, addren_a_prev, addren_b_prev;
logic [9:0]state_a_prev, state_b_prev, state_prev;

always @(posedge clk) begin
	if (MEMORY_TYPE == "SP_RAM" ) begin
		re_prev <= re;
		we_prev <= we;
		bram_rst_prev <= bram_rst;
		state_prev <= state;
		wclke_prev <= wclke;
		addren_prev <= addren;
		cvg_port_spram_inst.sample();

	end

	if (MEMORY_TYPE == "SDP_RAM" && CLK_MODE == 1) begin
		wclke_prev <= wclke;
		re_prev <= re;
		we_prev <= we;
		bram_rst_prev <= bram_rst;
		waddren_prev <= waddren;
		raddren_prev <= raddren;
		state_prev <= state;
		cvg_port_sdp_inst.sample();
	end

	if (MEMORY_TYPE == "TDP_RAM" && CLK_MODE == 1) begin
		we_a_prev <= we_a;
		we_b_prev <= we_b;
		clke_a_prev <= clke_a;
		clke_b_prev <= clke_b;
		addren_a_prev <= addren_a;
		addren_b_prev <= addren_b;
		bram_rst_a_prev <= bram_rst_a;
		bram_rst_b_prev <= bram_rst_b;
		state_a_prev <= state_a;
		state_b_prev <= state_b;
		cvg_port_tdp_inst.sample();
	end

	if (MEMORY_TYPE == "SP_ROM" ) begin
		re_prev <= re;
		bram_rst_prev <= bram_rst;
		state_prev <= state;
		addren_prev <= addren;
		cvg_port_sprom_inst.sample();
	end

	if (MEMORY_TYPE == "DP_ROM" && CLK_MODE == 1) begin
		clke_prev <= clke;
		addren_a_prev <= addren_a;
		addren_b_prev <= addren_b;
		bram_rst_a_prev <= bram_rst_a;
		bram_rst_b_prev <= bram_rst_b;
		state_a_prev <= state_a;
		state_b_prev <= state_b;
		cvg_port_dprom_inst.sample();
	end

end

always @(posedge clk_a) begin
	if (MEMORY_TYPE == "TDP_RAM" && CLK_MODE == 2) begin
		we_a_prev <= we_a;
		clke_a_prev <= clke_a;
		addren_a_prev <= addren_a;
		bram_rst_a_prev <= bram_rst_a;
		state_a_prev <= state_a;
		cvg_port_tdp_inst.sample();
	end
	
	if (MEMORY_TYPE == "DP_ROM" && CLK_MODE == 2) begin
		clke_a_prev <= clke_a;
		addren_a_prev <= addren_a;
		bram_rst_a_prev <= bram_rst_a;
		state_a_prev <= state_a;
		cvg_port_dprom_inst.sample();
	end
end

always @(posedge clk_b) begin
	if (MEMORY_TYPE == "TDP_RAM" && CLK_MODE == 2) begin
		we_b_prev <= we_b;
		clke_b_prev <= clke_b;
		addren_b_prev <= addren_b;
		bram_rst_b_prev <= bram_rst_b;
		state_b_prev <= state_b;
		cvg_port_tdp_inst.sample();
	end

	if (MEMORY_TYPE == "DP_ROM" && CLK_MODE == 2) begin
		clke_b_prev <= clke_b;
		addren_b_prev <= addren_b;
		bram_rst_b_prev <= bram_rst_b;
		state_b_prev <= state_b;
		cvg_port_dprom_inst.sample();
	end
end

always @(posedge wclk) begin
	if (MEMORY_TYPE == "SDP_RAM" && CLK_MODE == 2) begin
		wclke_prev <= wclke;
		we_prev <= we;
		bram_rst_prev <= bram_rst;
		waddren_prev <= waddren;
		state_prev <= state;
		cvg_port_sdp_inst.sample();
	end
end

always @(posedge rclk) begin
	if (MEMORY_TYPE == "SDP_RAM" && CLK_MODE == 2) begin
		re_prev <= re;
		bram_rst_prev <= bram_rst;
		raddren_prev <= raddren;
		state_prev <= state;
		cvg_port_sdp_inst.sample();
	end
end

//spram parameter
covergroup cvg_spram;
	cp_family: coverpoint family_num {
		bins titanium = {0};
		bins trion = {1};
	}

	cp_memory_mode: coverpoint mmode_num {
		bins speed = {0};
		bins area = {1};
	}

	cp_write_mode: coverpoint wmode_num {
		bins readfirst = {0};
		bins writefirst = {1};
		bins readunknown = {2};
	}

	cp_datawidth_a: coverpoint DATA_WIDTH_A {
		bins verylow = {[1:128]};
		bins low = {[129:384]};
		bins middle = {[385:640]};
		bins high = {[641:896]};
		bins veryhigh = {[897:1024]};
	}

	cp_addr_width_a: coverpoint ADDR_WIDTH_A {
		bins width[] = {[1:14]};
	}

	cp_byten: coverpoint BYTEEN_ENABLE {
		bins byten[] = {0,1};
	}

	cp_addren: coverpoint ADDREN_ENABLE {
		bins addren[] = {0,1}; 
	}

	cp_wclke: coverpoint WCLKE_ENABLE {
		bins wclke[] = {0,1}; 
	}

	cp_we: coverpoint WE_ENABLE {
		bins we[] = {0,1}; 
	}

	cp_re: coverpoint RE_ENABLE {
		bins re[] = {0,1};
	}

	cp_reset: coverpoint RESET_ENABLE {
		bins reset[] = {0,1};
	}

	cp_output: coverpoint OUTPUT_REG {
		bins outputreg[] = {0,1};
	}

	cp_family_mmode: cross cp_family, cp_memory_mode;
	cp_byte_address_we_wclke: cross cp_we, cp_addren, cp_byten,cp_wclke  iff (family_num == 0);
	cp_address_re: cross cp_re, cp_addren iff (family_num == 0);
	cp_we_re: cross cp_we, cp_re, cp_reset;
	cp_outputreg_family: cross cp_family, cp_output iff (RE_ENABLE == 1 && WE_ENABLE == 1);
	
endgroup

//spram_port
covergroup cvg_port_spram;
	port_wclke: coverpoint wclke {
		bins wclke[] = {0,1};
	}

	port_wclke_prev: coverpoint wclke_prev {
		bins wclke_prev[] = {0,1};
	}
	
	port_we: coverpoint we {
		bins we[] = {0,1}; 
	}
	
	port_re: coverpoint re {
		bins re[] = {0,1}; 
	}

	port_we_prev: coverpoint we_prev {
		bins we_prev[] = {0,1}; 
	}
	
	port_re_prev: coverpoint re_prev {
		bins re_prev[] = {0,1}; 
	}

	port_rst: coverpoint bram_rst {
		bins rst[] = {0,1};
	}

	port_rst_prev: coverpoint bram_rst_prev {
		bins rst_prev[] = {0,1};
	}

	port_addren: coverpoint addren {
		bins addren[] = {0,1};
	}

	port_addren_prev: coverpoint addren_prev {
		bins addren_prev[] = {0,1};
	}

	port_state: coverpoint state {
		bins state[] = {20,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,999,21,22,23,24,25,26};
	}

	port_state_prev: coverpoint state_prev {
		bins state_prev[] = {20,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,999,21,22,23,24,25,26};
	}


	spram_we_wclke_addren: cross port_we, port_we_prev, port_wclke, port_wclke_prev, port_addren, port_addren_prev iff (WE_ENABLE == 1 && WCLKE_ENABLE == 1 && ADDREN_ENABLE == 1 && OUTPUT_REG == 1);
	spram_re_addren: cross port_re, port_re_prev, port_addren, port_addren_prev iff (RE_ENABLE == 1 && ADDREN_ENABLE == 1 && family_num == 0);
	spram_we_re: cross port_we, port_re, port_we_prev, port_re_prev iff (WE_ENABLE == 1 && RE_ENABLE == 1 && OUTPUT_REG == 1);
	spram_we_re_rst: cross port_we, port_re, port_we_prev, port_re_prev, port_rst, port_rst_prev iff (WE_ENABLE == 1 && RE_ENABLE == 1 && RESET_ENABLE == 1 && family_num == 0 && OUTPUT_REG == 0);
	spram_we_re_rst_output_reg: cross port_we, port_re, port_we_prev, port_re_prev, port_rst, port_rst_prev iff (WE_ENABLE == 1 && RE_ENABLE == 1 && RESET_ENABLE == 1 && family_num == 0 && OUTPUT_REG == 1);
	spram_we_re_addren: cross port_we, port_re, port_addren, port_we_prev, port_re_prev, port_addren_prev iff (WE_ENABLE == 1 && RE_ENABLE == 1 && ADDREN_ENABLE == 1 && family_num == 0);
	spram_state: cross port_state, port_state_prev;

endgroup

cvg_port_spram cvg_port_spram_inst = new();

//sdpram parameter
covergroup cvg_sdp;
	cp_family: coverpoint family_num {
		bins titanium = {0};
		bins trion = {1};
	}

	cp_memory_mode: coverpoint mmode_num {
		bins speed = {0};
		bins area = {1};
	}

	cp_write_mode: coverpoint wmode_num {
		bins readfirst = {0};
		bins writefirst = {1};
		bins readunknown = {2};
		bins invalid = {3};
	}

	cp_speed_width_ratio: coverpoint WIDTH_RATIO iff (mmode_num == 0) {
		bins widthratio[] = {[0:8]};
	}

	cp_area_width_ratio: coverpoint WIDTH_RATIO iff (mmode_num == 1) {
		bins only4 = {4};
		bins invalidratio = {0,1,2,3,5,6,7,8};
	}

	cp_ratio4_datawidth_a: coverpoint DATA_WIDTH_A iff (WIDTH_RATIO == 4) {
		bins verylow = {[1:128]};
		bins low = {[129:384]};
		bins middle = {[385:640]};
		bins high = {[641:896]};
		bins veryhigh = {[897:1024]};
	}

	cp_data_width_a: coverpoint DATA_WIDTH_A {
		bins width1 = {1}; //if WIDTH_RATIO = 5,6,7,8
		bins width2 = {2}; //if WIDTH_RATIO = 3,5,6,7,8
		bins width4 = {4}; //if WIDTH_RATIO = 2,3,5,6,7,8
		bins width8 = {8}; //if WIDTH_RATIO = 1,2,3,5,6,7,8
		bins width16 = {16};
		bins width32 = {32};
		bins width64 = {64};
		bins width128 = {128};
		bins width256 = {256};
		bins width512 = {512};
		bins width1024 = {1024};
	}

	cp_ratio4_datawidth_b: coverpoint DATA_WIDTH_B iff (WIDTH_RATIO == 4) {
		bins verylow = {[1:128]};
		bins low = {[129:384]};
		bins middle = {[385:640]};
		bins high = {[641:896]};
		bins veryhigh = {[897:1024]};
	}

	cp_data_width_b: coverpoint DATA_WIDTH_B {
		bins width1 = {1}; // if WIDTH_RATIO = 0,1,2,3 
		bins width2 = {2}; // if WIDTH_RATIO = 0,1,2,3,5
		bins width4 = {4}; // if WIDTH_RATIO = 0,1,2,3,5,6
		bins width8 = {8}; // if WIDTH_RATIO = 0,1,2,3,5,6,7
		bins width16 = {16};
		bins width32 = {32};
		bins width64 = {64};
		bins width128 = {128}; // if WIDTH_RATIO = 1,2,3,5,6,7,8
		bins width256 = {256}; // if WIDTH_RATIO = 2,3,5,6,7,8
		bins width512 = {512}; // if WIDTH_RATIO = 3,5,6,7,8
		bins width2048 = {2048}; // if WIDTH_RATIO = 5,6,7,8
		bins width4096 = {4096}; // if WIDTH_RATIO = 6,7,8
		bins width8192 = {8192}; // if WIDTH_RATIO = 7,8
		bins width16384 = {16384}; // if WIDTH_RATIO = 8
	}
	
	cp_addr_width_a: coverpoint ADDR_WIDTH_A {
		bins width[] = {[1:14]};
	}

	cp_addr_width_b: coverpoint ADDR_WIDTH_B {
		bins width[] = {[1:14]};
	}

	cp_byten: coverpoint BYTEEN_ENABLE {
		bins byten[] = {0,1};
	}

	cp_waddren: coverpoint WADDREN_ENABLE {
		bins waddren[] = {0,1}; 
	}

	cp_raddren: coverpoint RADDREN_ENABLE {
		bins raddren[] = {0,1}; 
	}

	cp_clkmode: coverpoint CLK_MODE {
		bins clkmode[] = {1,2};
	}

	cp_wclke: coverpoint WCLKE_ENABLE {
		bins wclke[] = {0,1}; 
	}

	cp_we: coverpoint WE_ENABLE {
		bins we[] = {0,1}; 
	}

	cp_re: coverpoint RE_ENABLE {
		bins re[] = {0,1};
	}

	cp_reset: coverpoint RESET_ENABLE {
		bins reset[] = {0,1};
	}

	cp_output: coverpoint OUTPUT_REG {
		bins outputreg[] = {0,1};
	}

	cp_family_mmode: cross cp_family, cp_memory_mode;
	cp_byte_address_we: cross cp_we, cp_byten, cp_waddren iff (family_num == 0);
	cp_address_re: cross cp_re, cp_raddren iff (family_num == 0);
	cp_we_re: cross cp_we, cp_re;
	cp_clkmode_runknown: cross cp_write_mode, cp_clkmode iff (wmode_num == 2);
	cp_outputreg_family: cross cp_family, cp_output iff (RE_ENABLE == 1 && WE_ENABLE == 1);
	
endgroup

//sdp port
covergroup cvg_port_sdp;
	port_wclke: coverpoint wclke {
		bins wclke[] = {0,1};
	}
	
	port_wclke_prev: coverpoint wclke_prev {
		bins wclke_prev[] = {0,1};
	}

	port_we: coverpoint we {
		bins we[] = {0,1}; 
	}
	
	port_re: coverpoint re {
		bins re[] = {0,1}; 
	}

	port_we_prev: coverpoint we_prev {
		bins we_prev[] = {0,1}; 
	}
	
	port_re_prev: coverpoint re_prev {
		bins re_prev[] = {0,1}; 
	}

	port_rst: coverpoint bram_rst {
		bins rst[] = {0,1};
	}

	port_rst_prev: coverpoint bram_rst_prev {
		bins rst_prev[] = {0,1};
	}

	port_waddren: coverpoint waddren {
		bins waddren[] = {0,1};
	}

	port_raddren: coverpoint raddren {
		bins raddren[] = {0,1};
	}

	port_waddren_prev: coverpoint waddren_prev {
		bins waddren_prev[] = {0,1};
	}

	port_raddren_prev: coverpoint raddren_prev {
		bins raddren_prev[] = {0,1};
	}

	port_wclk: coverpoint wclk {
		bins wclk[] = {0,1}; 
	}

	port_rclk: coverpoint rclk {
		bins rclk[] = {0,1}; 
	}

	port_state: coverpoint state {
		bins state[] = {20,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,999,21,22,23,24,25,26};
	}

	port_state_prev: coverpoint state_prev {
		bins state_prev[] = {20,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,999,21,22,23,24,25,26};
	}

	sdp_we_wclke_waddren: cross port_we, port_wclke, port_waddren, port_we_prev, port_wclke_prev, port_waddren_prev iff (WE_ENABLE == 1 && WCLKE_ENABLE == 1 && WADDREN_ENABLE ==1);
	sdp_re_raddren: cross port_re, port_re_prev, port_raddren, port_raddren_prev iff (RE_ENABLE == 1 && RADDREN_ENABLE ==1);
	sdp_we_re: cross port_we, port_re, port_we_prev, port_re_prev iff (WE_ENABLE == 1 && RE_ENABLE == 1 && OUTPUT_REG == 1);
	sdp_we_re_addren: cross port_we, port_re, port_waddren, port_raddren iff (WE_ENABLE == 1 && RE_ENABLE == 1 && WADDREN_ENABLE == 1 && RADDREN_ENABLE == 1 && family_num == 0);
	sdp_we_re_rst_prev: cross port_we, port_re, port_we_prev, port_re_prev, port_rst, port_rst_prev iff (WE_ENABLE == 1 && RE_ENABLE == 1 && RESET_ENABLE == 1 && family_num == 0 && OUTPUT_REG == 0);	
	sdp_we_re_rst_outputreg: cross port_we, port_re, port_we_prev, port_re_prev, port_rst, port_rst_prev iff (WE_ENABLE == 1 && RE_ENABLE == 1 && RESET_ENABLE == 1 && family_num == 0 && OUTPUT_REG == 1);
	sdp_clk: cross port_wclk, port_rclk iff (CLK_MODE == 2);
	sdp_state: cross port_state, port_state_prev;

endgroup

cvg_port_sdp cvg_port_sdp_inst = new();

//tdp parameter
covergroup cvg_tdp;
	cp_family: coverpoint family_num {
		bins titanium = {0};
		bins trion = {1};
	}

	cp_memory_mode: coverpoint mmode_num {
		bins speed = {0};
		bins area = {1};
	}

	cp_write_modea: coverpoint wmode_a_num{
		bins readfirst = {0};
		bins writefirst = {1};
		bins nochange = {3};
	}

	cp_write_modeb: coverpoint wmode_b_num{
		bins readfirst = {0};
		bins writefirst = {1};
		bins nochange = {3};
	}

	cp_speed_width_ratio: coverpoint WIDTH_RATIO iff (mmode_num == 0) {
		bins widthratio[] = {[0:8]};
	}

	cp_area_width_ratio: coverpoint WIDTH_RATIO iff (mmode_num == 1) {
		bins only_4 = {4};
	}

	cp_ratio4_datawidth_a: coverpoint DATA_WIDTH_A iff (WIDTH_RATIO == 4) {
		bins verylow = {[1:128]};
		bins low = {[129:384]};
		bins middle = {[385:640]};
		bins high = {[641:896]};
		bins veryhigh = {[897:1024]};
	}

	cp_data_width_a: coverpoint DATA_WIDTH_A {
		bins width1 = {1}; //if WIDTH_RATIO = 5,6,7,8
		bins width2 = {2}; //if WIDTH_RATIO = 3,5,6,7,8
		bins width4 = {4}; //if WIDTH_RATIO = 2,3,5,6,7,8
		bins width8 = {8}; //if WIDTH_RATIO = 1,2,3,5,6,7,8
		bins width16 = {16};
		bins width32 = {32};
		bins width64 = {64};
		bins width128 = {128};
		bins width256 = {256};
		bins width512 = {512};
		bins width1024 = {1024};
	}

	cp_ratio4_datawidth_b: coverpoint DATA_WIDTH_B iff (WIDTH_RATIO == 4) {
		bins verylow = {[1:128]};
		bins low = {[129:384]};
		bins middle = {[385:640]};
		bins high = {[641:896]};
		bins veryhigh = {[897:1024]};
	}

	cp_data_width_b: coverpoint DATA_WIDTH_B {
		bins width1 = {1}; // if WIDTH_RATIO = 0,1,2,3 
		bins width2 = {2}; // if WIDTH_RATIO = 0,1,2,3,5
		bins width4 = {4}; // if WIDTH_RATIO = 0,1,2,3,5,6
		bins width8 = {8}; // if WIDTH_RATIO = 0,1,2,3,5,6,7
		bins width16 = {16};
		bins width32 = {32};
		bins width64 = {64};
		bins width128 = {128}; // if WIDTH_RATIO = 1,2,3,5,6,7,8
		bins width256 = {256}; // if WIDTH_RATIO = 2,3,5,6,7,8
		bins width512 = {512}; // if WIDTH_RATIO = 3,5,6,7,8
		bins width2048 = {2048}; // if WIDTH_RATIO = 5,6,7,8
		bins width4096 = {4096}; // if WIDTH_RATIO = 6,7,8
		bins width8192 = {8192}; // if WIDTH_RATIO = 7,8
		bins width16384 = {16384}; // if WIDTH_RATIO = 8
	}
	
	cp_addr_width_a: coverpoint ADDR_WIDTH_A {
		bins width[] = {[1:14]};
	}

	cp_addr_width_b: coverpoint ADDR_WIDTH_B {
		bins width[] = {[1:14]};
	}

	cp_bytena: coverpoint BYTEENA_ENABLE {
		bins bytena[] = {0,1};
	}

	cp_bytenb: coverpoint BYTEENB_ENABLE {
		bins bytenb[] = {0,1};
	}

	cp_addrena: coverpoint ADDREN_A_ENABLE {
		bins addrena[] = {0,1}; 
	}

	cp_addrenb: coverpoint ADDREN_B_ENABLE {
		bins addrenb[] = {0,1}; 
	}

	cp_clkmode: coverpoint CLK_MODE {
		bins clkmode[] = {1,2};
	}

	cp_clkea: coverpoint CLKEA_ENABLE {
		bins clkea[] = {0,1}; 
	}

	cp_clkeb: coverpoint CLKEB_ENABLE {
		bins clkeb[] = {0,1}; 
	}

	cp_wea: coverpoint WEA_ENABLE {
		bins wea[] = {0,1}; 
	}

	cp_web: coverpoint WEB_ENABLE {
		bins web[] = {0,1}; 
	}

	cp_reseta: coverpoint RESET_A_ENABLE {
		bins reseta[] = {0,1};
	}

	cp_resetb: coverpoint RESET_B_ENABLE {
		bins resetb[] = {0,1};
	}

	cp_outputa: coverpoint OUTPUT_REG_A {
		bins outputrega[] = {0,1};
	}

	cp_outputb: coverpoint OUTPUT_REG_B {
		bins outputregb[] = {0,1};
	}

	cp_family_mmode: cross cp_family, cp_memory_mode;
	cp_writemode_ab: cross cp_write_modea, cp_write_modeb;
	cp_byte_address_we: cross cp_wea, cp_web, cp_addrena, cp_addrenb, cp_bytena, cp_bytenb iff (family_num == 0);
	cp_clke_we: cross cp_clkea, cp_clkeb, cp_wea, cp_web iff (CLK_MODE == 2);
	cp_we_reset_outputreg: cross cp_wea, cp_web, cp_reseta, cp_resetb, cp_outputa, cp_outputb iff (family_num == 0);
	cp_outputreg_family: cross cp_family, cp_outputa, cp_outputb iff (WEA_ENABLE == 1 && WEB_ENABLE ==1);
	
endgroup

//tdp port
covergroup cvg_port_tdp;
	port_clka: coverpoint clk_a {
		bins clka[] = {0,1}; 
	}

	port_clkb: coverpoint clk_b {
		bins clkb[] = {0,1}; 
	}

	port_clkea: coverpoint clke_a {
		bins clkea[] = {0,1} ;
	}

	port_clkeb: coverpoint clke_b {
		bins clkeb[] = {0,1} ;
	}
	
	port_clke: coverpoint clke {
		bins clke[] = {0,1} ;
	}

	port_clkea_prev: coverpoint clke_a_prev {
		bins clkea_prev[] = {0,1} ;
	}

	port_clkeb_prev: coverpoint clke_b_prev {
		bins clkeb_prev[] = {0,1} ;
	}
	
	port_clke_prev: coverpoint clke_prev {
		bins clke_prev[] = {0,1} ;
	}

	port_wea: coverpoint we_a {
		bins wea[] = {0,1}; 
	}

	port_web: coverpoint we_b {
		bins web[] = {0,1}; 
	}

	port_wea_prev: coverpoint we_a_prev {
		bins wea_prev[] = {0,1}; 
	}

	port_web_prev: coverpoint we_b_prev {
		bins web_prev[] = {0,1}; 
	}

	port_addrena: coverpoint addren_a {
		bins addrena[] = {0,1}; 
	}

	port_addrenb: coverpoint addren_b {
		bins addrenb[] = {0,1}; 
	}
	
	port_addrena_prev: coverpoint addren_a_prev {
		bins addrena_prev[] = {0,1}; 
	}

	port_addrenb_prev: coverpoint addren_b_prev {
		bins addrenb_prev[] = {0,1}; 
	}

	port_rsta: coverpoint bram_rst_a {
		bins rsta[] = {0,1}; 
	}

	port_rstb: coverpoint bram_rst_b {
		bins rstb[] = {0,1}; 
	}

	port_rsta_prev: coverpoint bram_rst_a_prev {
		bins rsta_prev[] = {0,1}; 
	}

	port_rstb_prev: coverpoint bram_rst_b_prev {
		bins rstb_prev[] = {0,1}; 
	}

	port_state_a: coverpoint state_a {
		bins statea[] = {21,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,999,22,23,24,25,26,27};
	}

	port_state_b: coverpoint state_b {
		bins stateb[] = {21,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,999,22,23,24,25,26,27};
	}

	port_state_a_prev: coverpoint state_a_prev {
		bins statea_prev[] = {21,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,999,22,23,24,25,26,27};
	}

	port_state_b_prev: coverpoint state_b_prev {
		bins stateb_prev[] = {21,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,999,22,23,24,25,26,27};
	}

	tdp_clk: cross port_clka, port_clkb iff (CLK_MODE == 2);
	tdp_weab_clke: cross port_wea, port_web, port_wea_prev, port_web_prev, port_clke, port_clke_prev iff (CLK_MODE == 1 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && WEA_ENABLE == 1 && WEB_ENABLE == 1 && OUTPUT_REG_A == 1 && OUTPUT_REG_B == 1);
	tdp_weab_clkeab: cross port_wea, port_web, port_wea_prev, port_web_prev, port_clkea, port_clkeb, port_clkea_prev, port_clkeb_prev iff (CLK_MODE == 2 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && WEA_ENABLE == 1 && WEB_ENABLE == 1);
	tdp_weab_clke_rstab: cross port_wea, port_web, port_wea_prev, port_web_prev, port_clke, port_clke_prev, port_rsta, port_rstb, port_rsta_prev, port_rstb_prev iff (CLK_MODE == 1 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && WEA_ENABLE == 1 && WEB_ENABLE == 1 && RESET_A_ENABLE == 1 && RESET_B_ENABLE == 1 && family_num == 0);
	tdp_weab_clkeab_rstab: cross port_wea, port_web, port_wea_prev, port_web_prev, port_clkea, port_clkeb, port_clkea_prev, port_clkeb_prev, port_rsta, port_rstb, port_rsta_prev, port_rstb_prev iff (CLK_MODE == 2 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && WEA_ENABLE == 1 && WEB_ENABLE == 1 && RESET_A_ENABLE == 1 && RESET_B_ENABLE == 1 && family_num == 0);
	tdp_weab_clke_rstab_outputreg: cross port_wea, port_web, port_wea_prev, port_web_prev, port_clke, port_clke_prev, port_rsta, port_rstb, port_rsta_prev, port_rstb_prev iff (CLK_MODE == 1 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && WEA_ENABLE == 1 && WEB_ENABLE == 1 && RESET_A_ENABLE == 1 && RESET_B_ENABLE == 1 && family_num == 0 && OUTPUT_REG_A == 1 && OUTPUT_REG_B == 1);
	tdp_weab_clkeab_rstab_outputreg: cross port_wea, port_web, port_wea_prev, port_web_prev, port_clkea, port_clkeb, port_clkea_prev, port_clkeb_prev, port_rsta, port_rstb, port_rsta_prev, port_rstb_prev iff (CLK_MODE == 2 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && WEA_ENABLE == 1 && WEB_ENABLE == 1 && RESET_A_ENABLE == 1 && RESET_B_ENABLE == 1 && family_num == 0 && OUTPUT_REG_A == 1 && OUTPUT_REG_B == 1);
	tdp_weab_clke_addrenab: cross port_wea, port_web, port_wea_prev, port_web_prev, port_clke, port_clke_prev, port_addrena, port_addrenb, port_addrena_prev, port_addrenb_prev iff (CLK_MODE == 1 && family_num == 0 && WEA_ENABLE == 1 && WEB_ENABLE == 1 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && ADDREN_A_ENABLE == 1 && ADDREN_B_ENABLE == 1);
	tdp_weab_clkeab_addrenab: cross port_wea, port_web, port_wea_prev, port_web_prev, port_clkea, port_clkeb, port_clkea_prev, port_clkeb_prev, port_addrena, port_addrenb, port_addrena_prev, port_addrenb_prev iff (CLK_MODE == 2 && family_num == 0 && WEA_ENABLE == 1 && WEB_ENABLE == 1 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && ADDREN_A_ENABLE == 1 && ADDREN_B_ENABLE == 1);
	tdp_stateab: cross port_state_a, port_state_b, port_state_a_prev, port_state_b_prev;

endgroup

cvg_port_tdp cvg_port_tdp_inst = new();

//sprom parameter
covergroup cvg_sprom;
	cp_family: coverpoint family_num {
		bins titanium = {0};
		bins trion = {1};
	}

	cp_memory_mode: coverpoint mmode_num {
		bins speed = {0};
		bins area = {1};
	}

	cp_datawidth_a: coverpoint DATA_WIDTH_A {
		bins verylow = {[1:128]};
		bins low = {[129:384]};
		bins middle = {[385:640]};
		bins high = {[641:896]};
		bins veryhigh = {[897:1024]};
	}

	cp_addr_width_a: coverpoint ADDR_WIDTH_A {
		bins width[] = {[1:14]};
	}

	cp_addren: coverpoint ADDREN_ENABLE {
		bins addren[] = {0,1}; 
	}

	cp_re: coverpoint RE_ENABLE {
		bins re[] = {0,1};
	}

	cp_reset: coverpoint RESET_ENABLE {
		bins reset[] = {0,1};
	}

	cp_output: coverpoint OUTPUT_REG {
		bins outputreg[] = {0,1};
	}

	cp_family_mmode: cross cp_family, cp_memory_mode;
	cp_address_re: cross cp_re, cp_addren iff (family_num == 0);
	cp_re_reset: cross cp_re, cp_reset iff (family_num == 0);
	cp_outputreg_family_sprom: cross cp_family, cp_output iff (RE_ENABLE == 1);
	
endgroup

//port sprom
covergroup cvg_port_sprom;
	
	port_re: coverpoint re {
		bins re[] = {0,1}; 
	}

	port_re_prev: coverpoint re_prev {
		bins re_prev[] = {0,1}; 
	}

	port_rst: coverpoint bram_rst {
		bins rst[] = {0,1};
	}

	port_rst_prev: coverpoint bram_rst_prev {
		bins rst_prev[] = {0,1};
	}

	port_addren: coverpoint addren {
		bins addren[] = {0,1};
	}

	port_addren_prev: coverpoint addren_prev {
		bins addren_prev[] = {0,1};
	}

	port_state: coverpoint state {
		bins state[] = {11,0,1,2,3,4,5,6,7,8,9,10,999,12,13,14};
	}

	port_state_prev: coverpoint state_prev {
		bins state_prev[] = {11,0,1,2,3,4,5,6,7,8,9,10,999,12,13,14};
	}
	
	sprom_re_rst: cross port_re, port_re_prev, bram_rst, bram_rst_prev iff (RE_ENABLE == 1 && RESET_ENABLE == 1 && family_num == 0 && OUTPUT_REG == 0);
	sprom_re_rst_outputreg: cross port_re, port_re_prev, bram_rst, bram_rst_prev iff (RE_ENABLE == 1 && RESET_ENABLE == 1 && family_num == 0 && OUTPUT_REG == 1);
	sprom_re_addren: cross port_re, port_re_prev, port_addren, port_addren_prev iff (RE_ENABLE == 1 && ADDREN_ENABLE == 1 && family_num == 0);
	sprom_state: cross port_state, port_state_prev;

endgroup

cvg_port_sprom cvg_port_sprom_inst = new();

//dprom parameter
covergroup cvg_dprom;
	cp_family: coverpoint family_num {
		bins titanium = {0};
		bins trion = {1};
	}

	cp_memory_mode: coverpoint mmode_num {
		bins speed = {0};
		bins area = {1};
	}

	cp_speed_width_ratio: coverpoint WIDTH_RATIO iff (mmode_num == 0) {
		bins widthratio[] = {[0:8]};
	}

	cp_area_width_ratio: coverpoint WIDTH_RATIO iff (mmode_num == 1) {
		bins only_4 = {4};
	}

	cp_ratio4_datawidth_a: coverpoint DATA_WIDTH_A iff (WIDTH_RATIO == 4) {
		bins verylow = {[1:128]};
		bins low = {[129:384]};
		bins middle = {[385:640]};
		bins high = {[641:896]};
		bins veryhigh = {[897:1024]};
	}

	cp_data_width_a: coverpoint DATA_WIDTH_A {
		bins width1 = {1}; //if WIDTH_RATIO = 5,6,7,8
		bins width2 = {2}; //if WIDTH_RATIO = 3,5,6,7,8
		bins width4 = {4}; //if WIDTH_RATIO = 2,3,5,6,7,8
		bins width8 = {8}; //if WIDTH_RATIO = 1,2,3,5,6,7,8
		bins width16 = {16};
		bins width32 = {32};
		bins width64 = {64};
		bins width128 = {128};
		bins width256 = {256};
		bins width512 = {512};
		bins width1024 = {1024};
	}

	cp_ratio4_datawidth_b: coverpoint DATA_WIDTH_B iff (WIDTH_RATIO == 4) {
		bins verylow = {[1:128]};
		bins low = {[129:384]};
		bins middle = {[385:640]};
		bins high = {[641:896]};
		bins veryhigh = {[897:1024]};
	}

	cp_data_width_b: coverpoint DATA_WIDTH_B {
		bins width1 = {1}; // if WIDTH_RATIO = 0,1,2,3 
		bins width2 = {2}; // if WIDTH_RATIO = 0,1,2,3,5
		bins width4 = {4}; // if WIDTH_RATIO = 0,1,2,3,5,6
		bins width8 = {8}; // if WIDTH_RATIO = 0,1,2,3,5,6,7
		bins width16 = {16};
		bins width32 = {32};
		bins width64 = {64};
		bins width128 = {128}; // if WIDTH_RATIO = 1,2,3,5,6,7,8
		bins width256 = {256}; // if WIDTH_RATIO = 2,3,5,6,7,8
		bins width512 = {512}; // if WIDTH_RATIO = 3,5,6,7,8
		bins width2048 = {2048}; // if WIDTH_RATIO = 5,6,7,8
		bins width4096 = {4096}; // if WIDTH_RATIO = 6,7,8
		bins width8192 = {8192}; // if WIDTH_RATIO = 7,8
		bins width16384 = {16384}; // if WIDTH_RATIO = 8
	}
	
	cp_addr_width_a: coverpoint ADDR_WIDTH_A {
		bins width[] = {[1:14]};
	}

	cp_addr_width_b: coverpoint ADDR_WIDTH_B {
		bins width[] = {[1:14]};
	}

	cp_addrena: coverpoint ADDREN_A_ENABLE {
		bins addrena[] = {0,1}; 
	}

	cp_addrenb: coverpoint ADDREN_B_ENABLE {
		bins addrenb[] = {0,1}; 
	}

	cp_clkmode: coverpoint CLK_MODE {
		bins clkmode[] = {1,2};
	}

	cp_clkea: coverpoint CLKEA_ENABLE {
		bins clkea[] = {0,1}; 
	}

	cp_clkeb: coverpoint CLKEB_ENABLE {
		bins clkeb[] = {0,1}; 
	}

	cp_reseta: coverpoint RESET_A_ENABLE {
		bins reseta[] = {0,1};
	}

	cp_resetb: coverpoint RESET_B_ENABLE {
		bins resetb[] = {0,1};
	}

	cp_outputa: coverpoint OUTPUT_REG_A {
		bins outputrega[] = {0,1};
	}

	cp_outputb: coverpoint OUTPUT_REG_B {
		bins outputregb[] = {0,1};
	}

	cp_family_mmode: cross cp_family, cp_memory_mode;
	cp_clkeab: cross cp_clkea, cp_clkeb iff (CLK_MODE == 2);
	cp_resetab: cross cp_reseta, cp_resetb iff (family_num == 0);
	cp_outputregab: cross cp_outputa, cp_outputb;
	cp_addren: cross cp_addrena, cp_addrenb iff (family_num == 0);
	
endgroup

//port dprom
covergroup cvg_port_dprom;

	port_clka: coverpoint clk_a {
		bins clka[] = {0,1}; 
	}

	port_clkb: coverpoint clk_b {
		bins clkb[] = {0,1}; 
	}

	port_clkea: coverpoint clke_a {
		bins clkea[] = {0,1} ;
	}

	port_clkeb: coverpoint clke_b {
		bins clkeb[] = {0,1} ;
	}
	
	port_clke: coverpoint clke {
		bins clke[] = {0,1} ;
	}

	port_clkea_prev: coverpoint clke_a_prev {
		bins clkea_prev[] = {0,1} ;
	}

	port_clkeb_prev: coverpoint clke_b_prev {
		bins clkeb_prev[] = {0,1} ;
	}
	
	port_clke_prev: coverpoint clke_prev {
		bins clke_prev[] = {0,1} ;
	}

	port_addrena: coverpoint addren_a {
		bins addrena[] = {0,1}; 
	}

	port_addrenb: coverpoint addren_b {
		bins addrenb[] = {0,1}; 
	}
	
	port_addrena_prev: coverpoint addren_a_prev {
		bins addrena_prev[] = {0,1}; 
	}

	port_addrenb_prev: coverpoint addren_b_prev {
		bins addrenb_prev[] = {0,1}; 
	}

	port_rsta: coverpoint bram_rst_a {
		bins rsta[] = {0,1}; 
	}

	port_rstb: coverpoint bram_rst_b {
		bins rstb[] = {0,1}; 
	}

	port_rsta_prev: coverpoint bram_rst_a_prev {
		bins rsta_prev[] = {0,1}; 
	}

	port_rstb_prev: coverpoint bram_rst_b_prev {
		bins rstb_prev[] = {0,1}; 
	}

	port_state_a: coverpoint state_a {
		bins statea[] = {11,0,1,2,3,4,5,6,7,8,9,10,999,12,13,14};
	}

	port_state_b: coverpoint state_b {
		bins stateb[] = {11,0,1,2,3,4,5,6,7,8,9,10,999,12,13,14};
	}

	port_state_a_prev: coverpoint state_a_prev {
		bins statea_prev[] = {11,0,1,2,3,4,5,6,7,8,9,10,999,12,13,14};
	}

	port_state_b_prev: coverpoint state_b_prev {
		bins stateb_prev[] = {11,0,1,2,3,4,5,6,7,8,9,10,999,12,13,14};
	}

	dprom_clk: cross port_clka, port_clkb iff (CLK_MODE == 2);
	dprom_clke_addren: cross port_clke, port_clke_prev, port_addrena, port_addrenb, port_addrena_prev, port_addrenb_prev iff (CLK_MODE == 1 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && ADDREN_A_ENABLE == 1 && ADDREN_B_ENABLE == 1 && family_num == 0);
	dprom_clkeab_addren: cross port_clkea, port_clkeb, port_clkea_prev, port_clkeb_prev, port_addrena, port_addrenb, port_addrena_prev, port_addrenb_prev iff (CLK_MODE == 2 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && ADDREN_A_ENABLE == 1 && ADDREN_B_ENABLE == 1 && family_num == 0);
	dprom_clke_reset: cross port_clke, port_clke_prev, port_rsta, port_rstb, port_rsta_prev, port_rstb_prev iff (CLK_MODE == 1 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && RESET_A_ENABLE == 1 && RESET_B_ENABLE == 1 && family_num == 0);
	dprom_clkeab_reset: cross port_clkea, port_clkeb, port_clkea_prev, port_clkeb_prev, port_rsta, port_rstb, port_rsta_prev, port_rstb_prev iff (CLK_MODE == 2 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && RESET_A_ENABLE == 1 && RESET_B_ENABLE == 1 && family_num == 0);
	dprom_clke_reset_outputreg: cross port_clke, port_clke_prev, port_rsta, port_rstb, port_rsta_prev, port_rstb_prev iff (CLK_MODE == 1 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && RESET_A_ENABLE == 1 && RESET_B_ENABLE == 1 && family_num == 0 && OUTPUT_REG_A == 1 && OUTPUT_REG_B ==1);
	dprom_clkeab_reset_outputreg: cross port_clkea, port_clkeb, port_clkea_prev, port_clkeb_prev, port_rsta, port_rstb, port_rsta_prev, port_rstb_prev iff (CLK_MODE == 2 && CLKEA_ENABLE == 1 && CLKEB_ENABLE == 1 && RESET_A_ENABLE == 1 && RESET_B_ENABLE == 1 && family_num == 0 && OUTPUT_REG_A == 1 && OUTPUT_REG_B ==1);
	dprom_stateab: cross port_state_a, port_state_b, port_state_a_prev, port_state_b_prev;

endgroup

cvg_port_dprom cvg_port_dprom_inst = new();

//parameter inst
initial begin
	static int sampled_family = family_num;
	static int sampled_mtype = mtype_num;
	static int sampled_mmode = mmode_num;
	static int sampled_wmode = wmode_num;
	static int sampled_wmode_a = wmode_a_num;
	static int sampled_wmode_b = wmode_b_num;

	if (MEMORY_TYPE == "SP_RAM" ) begin
		cvg_spram cvg_spram_inst = new();
		#1 cvg_spram_inst.sample();

		//Illegal cases
		if (WRITE_MODE == "NO_CHANGE")
			$error("Invalid write mode for SPRAM!");

		if (MEMORY_MODE == "AREA" && WIDTH_RATIO != 4)
			$error("Invalid width ratio for SPRAM Area Mode!");

		if (FAMILY == "TRION" && (ADDREN_ENABLE == 1 || RESET_ENABLE == 1))
			$error("Invalid value for addren enable or reset enable on TRION device!");
	end

	if (MEMORY_TYPE == "SDP_RAM" ) begin
		cvg_sdp cvg_sdp_inst = new();
		#1 cvg_sdp_inst.sample();

		// Illegal cases:
		if (WRITE_MODE == "NO_CHANGE")
			$error("Invalid write mode for SDPRAM!");

		if (MEMORY_MODE == "AREA" && WIDTH_RATIO != 4)
			$error("Invalid width ratio for SDPRAM Area Mode!");

		//if (FAMILY == "TITANIUM" && WRITE_MODE == "WRITE_FIRST" && WIDTH_RATIO != 4)
		//	$error("Invalid mixed width mode for WRITE_FIRST on TITANIUM device!");

		if (FAMILY == "TRION" && (WADDREN_ENABLE == 1 || RADDREN_ENABLE == 1 || RESET_ENABLE == 1))
			$error("Invalid value for waddren enable or raddren enable or reset enable on TRION device!");

		if (CLK_MODE == 2 && (WRITE_MODE == "WRITE_FIRST" || WRITE_MODE == "READ_FIRST"))
			$error("Invalid clock mode for WRITE_FIRST or READ FIRST!");
	end

	if (MEMORY_TYPE == "TDP_RAM" ) begin
		cvg_tdp cvg_tdp_inst = new();
		#1 cvg_tdp_inst.sample();

		// Illegal cases:
		if (WRITE_MODE_A == "READ_UNKNOWN")
			$error("Invalid write mode for TDPRAM Port A!");

		if (WRITE_MODE_B == "READ_UNKNOWN")
			$error("Invalid write mode for TDPRAM Port B!");

		if (MEMORY_MODE == "AREA" && WIDTH_RATIO != 4)
			$error("Invalid width ratio for TDPRAM Area Mode!");

		if (CLK_MODE == 1 && (CLKEA_ENABLE != CLKEB_ENABLE))
			$error("Different clock enable when single code");

		if (FAMILY == "TRION" && (ADDREN_A_ENABLE == 1 || ADDREN_B_ENABLE == 1 || RESET_A_ENABLE ==1 || RESET_B_ENABLE == 1))
			$error("Invalid value for addren enable or reset enable on TRION device!");
	end

	if (MEMORY_TYPE == "SP_ROM" ) begin
		cvg_sprom cvg_sprom_inst = new();
		#1 cvg_sprom_inst.sample();

		// Illegal cases:
		if (WRITE_MODE == "READ_UNKNOWN" || WRITE_MODE == "WRITE_FIRST" || WRITE_MODE == "NO_CHANGE")
			$error("Invalid write mode for SPROM!");

		if (FAMILY == "TRION" && (ADDREN_ENABLE == 1 || RESET_ENABLE == 1))
			$error("Invalid value for addren enable or reset enable on TRION device!");
	end
	
	if (MEMORY_TYPE == "DP_ROM" ) begin
		cvg_dprom cvg_dprom_inst = new();
		#1 cvg_dprom_inst.sample();

		// Illegal cases:
		if (WRITE_MODE_A == "READ_UNKNOWN" || WRITE_MODE_A == "WRITE_FIRST" || WRITE_MODE_A == "NO_CHANGE")
			$error("Invalid write mode for DPROM Port A!");

		if (WRITE_MODE_B == "READ_UNKNOWN" || WRITE_MODE_B == "WRITE_FIRST" || WRITE_MODE_B == "NO_CHANGE")
			$error("Invalid write mode for DPROM Port B!");

		if (MEMORY_MODE == "AREA" && WIDTH_RATIO != 4)
			$error("Invalid width ratio for TDPRAM Area Mode!");

		if (CLK_MODE == 1 && (CLKEA_ENABLE != CLKEB_ENABLE))
			$error("Different clock enable when single code");

		if (FAMILY == "TRION" && (ADDREN_A_ENABLE == 1 || ADDREN_B_ENABLE == 1 || RESET_A_ENABLE ==1 || RESET_B_ENABLE == 1))
			$error("Invalid value for addren enable or reset enable on TRION device!");
	end
	
end
