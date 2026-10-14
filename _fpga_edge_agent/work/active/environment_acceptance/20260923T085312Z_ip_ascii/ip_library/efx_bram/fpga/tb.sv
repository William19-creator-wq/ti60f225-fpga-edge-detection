module tb;

reg clk1,clk2;

initial begin
    clk1 = 0;
    forever #5 clk1 = ~clk1;   // 10 ns period → 100 MHz
end

initial begin
    clk2 = 0;
    forever #5 clk2 = ~clk2;   // 10 ns period → 100 MHz
end

reg reset_n;
reg start_n;
reg lock;
reg pass;
reg fail;

initial begin
	lock = 0;
	reset_n = 1;
	start_n = 1;
	#100;
	lock = 1;
	#100;
	start_n = 0;
	#10;
	start_n = 1;
end

initial begin
        fork : TEST_DONE
                begin
                        wait(pass);
			$display("[INFO]: PASS occurred");
                end
		begin
			wait(fail);
			$display("[Error]: FAIL occurred");
			#100;
			$finish;
		end
                begin
                        #100000000;
                        $display("[Error]: TIMEOUT occurred");
			$finish;
                end
        join_any
	disable TEST_DONE;
        #100;
        $display("[INFO]: TEST completed successfully: %0t", $time);	
        $finish;
end

bram_ed dut (
	.pll_inst1_CLKOUT1(clk1),
	.pll_inst1_CLKOUT2(clk2),
	.i_reset_n(reset_n),
	.i_start_n(start_n),

	.user_led0_blue(),
	.user_led0_green(),
	.user_led0_red(),

	.user_led1_blue(),
	.user_led1_green(pass),
	.user_led1_red(fail),

	.pll_inst1_RSTN(),
	.pll_inst1_LOCKED(lock)
);

endmodule

