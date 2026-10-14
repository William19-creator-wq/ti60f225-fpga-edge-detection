// Module: efx_pulse_sync
// Description:
//   Safely transfers a single-cycle pulse from a source clock domain to a
//   destination clock domain using a toggle-based synchronization scheme.
//
// ==========================================================================

module `IP_MODULE_NAME(efx_pulse_sync) #(
   parameter ACTIVE_LOW = 1, // 0 - Active high reset, 1 - Active low reset
   parameter OFF_ASSERTION = 0
) (
   input  src_clk,      // Source clock (e.g., tx_axis_clk)
   input  src_reset,    // Reset for source domain
   input  pulse_in,     // Single-cycle pulse in src_clk domain

   input  dst_clk,      // Destination clock (e.g., tx_clk)
   input  dst_reset,    // Reset for destination domain
   output pulse_out     // Single-cycle pulse in dst_clk domain
);

// Toggle generation in source clock domain
reg toggle_src;

// Synchronizer flops in destination clock domain
wire toggle_sync;
reg  toggle_sync_r;

generate
   if (ACTIVE_LOW == 1) begin
      always @ (posedge src_clk or negedge src_reset) begin
         if (!src_reset)
            toggle_src <= 1'b0;
         else if (pulse_in)
            toggle_src <= ~toggle_src;
         else
            toggle_src <= toggle_src;
      end

     `IP_MODULE_NAME(efx_asyncreg) #(
        .WIDTH         (1),
        .OFF_ASSERTION (OFF_ASSERTION)
     ) efx_asyncreg_toggle_src (
        .clk     (dst_clk),
        .reset_n (dst_reset),
        .d_i     (toggle_src),
        .d_o     (toggle_sync)
     );
      
      always @ (posedge dst_clk or negedge dst_reset) begin
         if (!dst_reset) begin
            toggle_sync_r <= 1'b0;
         end 
         else begin
            toggle_sync_r <= toggle_sync;  // Delay for edge detect
         end
      end
   end
   else begin // Active High Reset
      always @ (posedge src_clk or posedge src_reset) begin
         if (src_reset)
            toggle_src <= 1'b0;
         else if (pulse_in)
            toggle_src <= ~toggle_src;
         else
            toggle_src <= toggle_src;
      end

      `IP_MODULE_NAME(efx_asyncreg) #(
         .WIDTH         (1),
         .ACTIVE_HIGH   (0),
         .OFF_ASSERTION (OFF_ASSERTION)
      ) efx_asyncreg_toggle_src (
         .clk     (dst_clk),
         .reset_n (dst_reset),
         .d_i     (toggle_src),
         .d_o     (toggle_sync)
      );
      
      always @ (posedge dst_clk or posedge dst_reset) begin
         if (dst_reset) begin
            toggle_sync_r <= 1'b0;
         end 
         else begin
            toggle_sync_r <= toggle_sync;  // Delay for edge detect
         end
      end
   end
endgenerate

// Generate one-cycle pulse in destination domain
assign pulse_out = toggle_sync ^ toggle_sync_r;

endmodule

