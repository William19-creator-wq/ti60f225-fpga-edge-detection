// Read-only telemetry in video_clk. Rates are tenths of frames/second, using
// measured intervals. C is CSI VS, D is output VS, U is published-result change,
// P measures intervals between successful job completions, including capture,
// scheduling and display waits; it is independent of result display/freeze.
// completion_toggle_async is completed_jobs[0] in core_clk, toggled only after
// all writes drain. Producer and monitor share cold reset. Events must be at
// least four video clocks apart (full-frame jobs satisfy this by construction).
// First event arms a period; two events are needed for a valid rate. Rates are
// interval estimates, not cumulative averages. processing_ms remains latency.
// A shared 64/32 serial divider avoids combinational division in the video path.
module video_completion_performance #(parameter integer VIDEO_HZ=74250000,CORE_HZ=100000000)(
 input wire clk,rst,capture_vs_async,display_vs,result_valid,completion_toggle_async,
 input wire [63:0] result_id,processing_cycles,
 output reg [15:0] capture_fps_x10,display_fps_x10,update_fps_x10,process_fps_x10,
 output reg [31:0] processing_ms
);
 (* ASYNC_REG="TRUE" *) reg [1:0] capture_sync;
 (* ASYNC_REG="TRUE" *) reg [1:0] completion_sync;
 reg [2:0] completion_startup;
 reg completion_previous;
 reg capture_previous,display_previous,result_seen;
 reg [63:0] result_previous;
 wire [3:0] pulse={completion_startup[2]&&(completion_sync[1]^completion_previous),result_valid&&(!result_seen||result_previous!=result_id),display_vs&&!display_previous,capture_sync[1]&&!capture_previous};
 reg [31:0] age[0:3],period[0:3];reg [3:0] armed,period_valid;
 always @(posedge clk)begin
  if(rst)begin
   completion_sync<=0;completion_startup<=0;completion_previous<=0;capture_sync<=0;capture_previous<=0;display_previous<=0;result_seen<=0;result_previous<=0;armed<=0;period_valid<=0;
   for(integer k=0;k<4;k=k+1)begin age[k]<=0;period[k]<=0;end
  end else begin
   completion_sync<={completion_sync[0],completion_toggle_async};
   completion_startup<={completion_startup[1:0],1'b1};
   completion_previous<=completion_sync[1];
   capture_sync<={capture_sync[0],capture_vs_async};capture_previous<=capture_sync[1];display_previous<=display_vs;
   if(result_valid)begin result_seen<=1;result_previous<=result_id;end
   for(integer k=0;k<4;k=k+1)begin
    if(pulse[k])begin
     armed[k]<=1;age[k]<=0;
     if(armed[k])begin period_valid[k]<=1;period[k]<=age[k]==32'hffffffff ? age[k]:age[k]+1'b1;end
    end else if(age[k]!=32'hffffffff)age[k]<=age[k]+1'b1;
   end
  end
 end
 reg [2:0] channel;
 reg busy,valid_job;reg [6:0] remaining;
 // Consumed dividend bits hold quotient bits; after 64 steps all bits
 // are quotient. No change to operands, saturation, or update schedule.
 reg [63:0] dividend;
 reg [31:0] divisor;
 reg [32:0] remainder;
 wire [32:0] trial={remainder[31:0],dividend[63]};
 wire subtract=trial>={1'b0,divisor};
 wire [63:0] next_quotient={dividend[62:0],subtract};
 wire [31:0] limited_q=|next_quotient[63:32]?32'hffffffff:next_quotient[31:0];
 wire [15:0] limited_rate=|limited_q[31:16]?16'hffff:limited_q[15:0];
 always @(posedge clk)begin
  if(rst)begin
   channel<=0;busy<=0;valid_job<=0;remaining<=0;dividend<=0;divisor<=1;remainder<=0;
   capture_fps_x10<=0;display_fps_x10<=0;update_fps_x10<=0;process_fps_x10<=0;processing_ms<=0;
  end else if(!busy)begin
   busy<=1;remaining<=64;remainder<=0;
   if(channel<4)begin
    dividend<=64'(VIDEO_HZ)*10;divisor<=period[channel]==0?1:period[channel];
    // Two missing expected intervals, at least two seconds, means stale.
    valid_job<=period_valid[channel]&&{1'b0,age[channel]}<({1'b0,period[channel]}*2>33'(VIDEO_HZ)*2?{1'b0,period[channel]}*2:33'(VIDEO_HZ)*2);
   end else begin
    dividend<=processing_cycles;divisor<=CORE_HZ/1000;valid_job<=result_valid;
   end
  end else begin
   dividend<=next_quotient;
   remainder<=subtract?trial-{1'b0,divisor}:trial;remaining<=remaining-1'b1;
   if(remaining==1)begin
    busy<=0;channel<=channel==4?0:channel+1'b1;
    case(channel)
     0:capture_fps_x10<=valid_job?limited_rate:0;
     1:display_fps_x10<=valid_job?limited_rate:0;
     2:update_fps_x10<=valid_job?limited_rate:0;
     3:process_fps_x10<=valid_job?limited_rate:0;
     4:processing_ms<=valid_job?limited_q:0;
    endcase
   end
  end
 end
 // synthesis translate_off
 initial if(VIDEO_HZ<1||CORE_HZ<1000||VIDEO_HZ>400000000||CORE_HZ>400000000)$fatal(1,"Unsupported telemetry clocks");
 // synthesis translate_on
endmodule

