`timescale 1ns/1ns
module tb_env;
 reg clk=0;
 reg locked=1;
 wire [7:0] led;
 integer failures=0;
 LED_8bit_Test dut(.pll_inst1_CLKOUT0(clk),.pll_inst1_LOCKED(locked),.led_data(led));
 always #5 clk=~clk;
 initial begin
  #1 locked=0;
  #2 if(led!==8'hff) begin $display("ENV_FAIL_RESET"); failures=failures+1; end
  repeat(3) @(negedge clk);
  locked=1;
  repeat(5) @(negedge clk);
  if(led!==8'h7f) begin $display("ENV_FAIL_FIRST_PATTERN"); failures=failures+1; end
  locked=0;
  #1 if(led!==8'hff) begin $display("ENV_FAIL_RE_RESET"); failures=failures+1; end
  if(failures==0) $display("ENV_SMOKE_PASS");
  else $display("ENV_SMOKE_FAIL");
  $finish;
 end
endmodule
