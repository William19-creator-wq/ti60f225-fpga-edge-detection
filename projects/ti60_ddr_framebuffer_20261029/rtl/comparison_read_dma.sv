// Stream A row0, B row0, A row1, B row1 ... into a shared display FIFO.
// RGB32 thumbnails occupy 960*540*4 bytes each, stride 3840 bytes per row.
module comparison_read_dma(
 input logic clk,rst,start,cancel,front_bank,input logic [10:0] fifo_free,
 output logic busy,done,output wire fault,
 output wire [31:0] araddr,output wire [7:0] arlen,output wire [2:0] arsize,
 output wire [1:0] arburst,output wire arvalid,input logic arready,
 input logic [127:0] rdata,input logic [1:0] rresp,input logic rlast,rvalid,
 output wire rready,output wire [127:0] pixel_data,output wire pixel_valid,input logic pixel_ready
);
 logic bank,side,span_start,aborted;logic [9:0] row;
 logic [1:0] state;
 wire span_busy,span_done;
 wire [31:0] row_offset=({22'd0,row}<<12)-({22'd0,row}<<8);
 wire [31:0] base=32'h02000000+(bank?32'h00400000:0)+(side?32'h00200000:0)+row_offset;
 span_read_dma #(.BEATS(240)) span(
   .clk(clk),.rst(rst),.start(span_start),.cancel(cancel||aborted),.base_address(base),.fifo_free(fifo_free),
   .busy(span_busy),.done(span_done),.fault(fault),.araddr(araddr),.arlen(arlen),.arsize(arsize),.arburst(arburst),
   .arvalid(arvalid),.arready(arready),.rdata(rdata),.rresp(rresp),.rlast(rlast),.rvalid(rvalid),.rready(rready),
   .pixel_data(pixel_data),.pixel_valid(pixel_valid),.pixel_ready(pixel_ready));
 always_ff @(posedge clk)begin
   span_start<=0;done<=0;
   if(rst)begin state<=0;bank<=0;side<=0;row<=0;busy<=0;aborted<=0;end
   else begin
     if(cancel&&busy)aborted<=1;
     case(state)
       0:if(start&&!cancel)begin bank<=front_bank;side<=0;row<=0;busy<=1;aborted<=0;state<=1;end
       1:if(cancel||aborted)begin busy<=0;done<=1;state<=0;end
         else begin span_start<=1;state<=2;end
       2:begin
         if(span_done||((cancel||aborted)&&!span_busy&&!span_start))begin
           if(cancel||aborted||(side&&row==539))begin busy<=0;done<=1;state<=0;end
           else begin side<=!side;if(side)row<=row+1;state<=1;end
         end
       end
     endcase
   end
 end
endmodule
