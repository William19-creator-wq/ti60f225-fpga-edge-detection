`resetall
`timescale 1ns/10ps

module sim();
   localparam N = 4;

   reg Oclk, Fclk, Sclk, resetn, locked;
   wire pll_resetn;
   wire [N-1:0] Oled, Fled, Sled, Sled_OE;
   reg [N-1:0] Oled_E, Fled_E, Sled_E, Sled_OE_E;
   integer 	 Ocycle, Fcycle, Scycle;
   
   
   pt_demo dut(.Oclk(Oclk),
			   .Fclk(Fclk),
			   .Sclk(Sclk),
			   .resetn(resetn),
			   .locked(locked),
			   .pll_resetn(pll_resetn),
			   .Oled(Oled),
			   .Fled(Fled),
			   .Sled(Sled),
			   .Sled_OE(Sled_OE));
   
   initial begin
	  //$monitor($time, "resetn: %b, locked: %b, Oclk:%b Fclk:%b, Sclk:%b, Oled: %d, Fled: %d, Sled: %d, Oled_E: %d, Fled_E: %d, Sled_E: %d", resetn, locked, Oclk, Fclk, Sclk, Oled, Fled, Sled, Oled_E, Fled_E, Sled_E);
	  Oclk = 0;
	  Fclk = 0;
	  Sclk = 0;
	  resetn = 0;
	  locked = 0;
	  Oled_E = 0;
	  Fled_E = 0;
	  Sled_E = 0;
	  Ocycle = 0;
	  Fcycle = 0;
	  Scycle = 0;

	  // Just control with explicit actions at time
	  #100 $display($time, "Release resetn");
	  resetn = 1;
	  #192 $display($time, "Reach lock");
	  locked = 1;
	  #2000 $display($time, "Assert resetn");
	  resetn = 0; 
	  locked = 0;
	  Fled_E = 0;
	  Sled_E = 0;
	  #100 $display($time, "Release resetn");
	  resetn = 1;
	  #192 $display($time, "Reach lock");
	  locked = 1;
	  #4000 $display($time, "TEST : PASS");
	  $finish;
   end

   // Create the clocks, run the oscillator faster to speed up simulation 
   always #100 Oclk = ~Oclk;
   always #4 Fclk = ~pll_resetn ? Fclk : ~Fclk;
   always #8 Sclk = ~pll_resetn ? Sclk : ~Sclk;

   // Check Oclk output
   always @(negedge Oclk) begin
	  if (Ocycle >= 0) begin
		 $display($time, "=== === === OCycle:%d === === ===", Ocycle);
		 $display("\tOled : %d", Oled);

		 Oled_E = Oled_E + 1;
	
		 if (Oled_E !== Oled) begin
			$display("\tMISMATCH: Expected %d got Oled : %d", Oled_E, Oled);
			$display("TEST : FAIL");
			$finish();
		 end
	  end

	  Ocycle = Ocycle + 1;
   end

   // Check Fclk output
   always @(negedge Fclk) begin
	  if (Fcycle >= 0) begin
		 $display($time, "=== === === FCycle:%d === === ===", Fcycle);
		 $display("locked : %b\tresetn: %b", locked, resetn);
		 $display("\tFled : %d", Fled);

		 Fled_E = locked ? Fled_E + 1 : Fled_E;
	
		 if (Fled_E !== Fled) begin
			$display("\tMISMATCH: Expected %d got Fled : %d", Fled_E, Fled);
			$display("TEST : FAIL");
			$finish();
		 end
	  end

	  Fcycle = Fcycle + 1;
   end

   // Check Sclk output
   always @(negedge Sclk) begin
	  if (Scycle >= 0) begin
		 $display($time, "=== === === SCycle:%d === === ===", Scycle);
		 $display("locked : %b\tresetn: %b", locked, resetn);
		 $display("\tSled : %d", Sled);

		 Sled_E = locked ? Sled_E + 1 : Sled_E;
		 Sled_OE_E = locked ? {N{1'b1}} : {N{1'b0}};
	
		 if (Sled_E !== Sled) begin
			$display("\tMISMATCH: Expected %d got Sled : %d", Sled_E, Sled);
			$display("TEST : FAIL");
			$finish();
		 end
		 if (Sled_OE_E !== Sled_OE) begin
			$display("\tMISMATCH: Expected %d got Sled OE : %d", Sled_OE_E, Sled_OE);
			$display("TEST : FAIL");
			$finish();
		 end
	  end

	  Scycle = Scycle + 1;
   end

endmodule