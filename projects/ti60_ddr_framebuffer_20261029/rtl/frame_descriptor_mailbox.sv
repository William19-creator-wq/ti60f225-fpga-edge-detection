// One stable bundled-data transfer. Both sides reset together with the pipeline.
// src_data is latched until destination consumption is acknowledged; no bitwise
// synchronization of a changing descriptor is permitted.
module frame_descriptor_mailbox #(parameter integer WIDTH=160)(
 input logic src_clk,src_rst,src_valid,
 output wire src_ready,input logic [WIDTH-1:0] src_data,
 input logic dst_clk,dst_rst,
 output logic dst_valid,input logic dst_ready,output logic [WIDTH-1:0] dst_data
);
 logic request,acknowledge;
 wire [WIDTH-1:0] held;
 wire receive;
 frame_mailbox_register #(.WIDTH(WIDTH)) source_storage(
   .clk(src_clk),.rst(src_rst),.enable(src_valid&&src_ready),.d(src_data),.q(held));
 frame_mailbox_register #(.WIDTH(WIDTH)) destination_storage(
   .clk(dst_clk),.rst(dst_rst),.enable(receive),.d(held),.q(dst_data));
 (* async_reg="true" *) logic [1:0] ack_sync,req_sync;
 logic seen;
 assign receive=!dst_valid&&req_sync[1]!=seen;
 assign src_ready=request==ack_sync[1];
 always_ff @(posedge src_clk)begin
   if(src_rst)begin request<=0;ack_sync<=0;end
   else begin
     ack_sync<={ack_sync[0],acknowledge};
     if(src_valid&&src_ready)begin request<=!request;end
   end
 end
 always_ff @(posedge dst_clk)begin
   if(dst_rst)begin req_sync<=0;seen<=0;acknowledge<=0;dst_valid<=0;end
   else begin
     req_sync<={req_sync[0],request};
     if(!dst_valid&&req_sync[1]!=seen)begin
       dst_valid<=1;seen<=req_sync[1];
     end
     if(dst_valid&&dst_ready)begin dst_valid<=0;acknowledge<=seen;end
   end
 end
endmodule

// Native DSP output registers retain one 32-bit word with the same clock/CE
// and synchronous reset as a fabric register. This consumes spare DSPs to
// reduce XLR pressure; it introduces no arithmetic pipeline stage.
module frame_mailbox_register #(parameter integer WIDTH=64)(
 input wire clk,rst,enable,input wire [WIDTH-1:0] d,output wire [WIDTH-1:0] q
);
 generate if(!(WIDTH==64||WIDTH==92||WIDTH==129))begin:narrow_register
   reg [WIDTH-1:0] value;
   always @(posedge clk)if(rst)value<=0;else if(enable)value<=d;
   assign q=value;
 end else begin:wide
   localparam integer WORDS=(WIDTH+31)/32;
   wire [WORDS*32-1:0] padded={{(WORDS*32-WIDTH){1'b0}},d};
   wire [WORDS*32-1:0] result;
   for(genvar i=0;i<WORDS;i++)begin:word_register
     wire [31:0] data_word=padded[i*32+:32];wire [47:0] value;
     EFX_DSP48 #(.SIGNED(0),.O_REG(1),.RST_SYNC(1),.N_SEL("C")) storage(
       .A({4'd0,data_word[31:17]}),.B(18'h20000),.C({1'b0,data_word[16:0]}),.CASCIN(48'd0),
       .OP(2'b00),.SHIFT_ENA(1'b0),.CLK(clk),.CE(enable),.RST(rst),.O(value),.CASCOUT(),.OVFL());
     assign result[i*32+:32]=value[31:0];
   end
   assign q=result[WIDTH-1:0];
 end endgenerate
endmodule
