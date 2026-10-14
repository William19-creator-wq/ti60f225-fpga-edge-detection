
// synopsys translate_off
`timescale 1 ns / 1 ps													
// synopsys translate_on

module `IP_MODULE_NAME(efx_resetsync) #(
    parameter ASYNC_STAGE = 2,
    parameter ACTIVE_LOW = 1
) (
    input  wire             clk,
    input  wire             reset,
    output wire             d_o
);


generate
   if (ACTIVE_LOW == 1) begin: active_low
      `IP_MODULE_NAME(efx_asyncreg) #(
         .WIDTH      (1),
         .ACTIVE_LOW (1),
         .RST_VALUE  (0)
      ) efx_resetsync_active_low (
         .clk     (clk),
         .reset_n (reset),
         .d_i     (1'b1),
         .d_o     (d_o)
      );
   end
   else begin: active_high
      `IP_MODULE_NAME(efx_asyncreg) #(
         .WIDTH      (1),
         .ACTIVE_LOW (0),
         .RST_VALUE  (1)
      ) efx_resetsync_active_high (
         .clk     (clk),
         .reset_n (reset),
         .d_i     (1'b0),
         .d_o     (d_o)
      );
   end
endgenerate

endmodule
