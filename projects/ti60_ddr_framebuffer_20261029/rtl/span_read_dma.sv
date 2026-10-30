// One outstanding read burst; cancellation drains accepted work before idle.
// FIFO space reserves the entire burst. No new address is issued after cancel.
module span_read_dma #(parameter integer BEATS=240)(
 input logic clk,rst,start,cancel,input logic[31:0]base_address,
 input logic[10:0]fifo_free,
 output logic busy,done,fault,
 output logic[31:0]araddr,output logic[7:0]arlen,
 output wire[2:0]arsize,output wire[1:0]arburst,
 output wire arvalid,input logic arready,
 input logic[127:0]rdata,input logic[1:0]rresp,input logic rlast,rvalid,
 output wire rready,output wire[127:0]pixel_data,output wire pixel_valid,input logic pixel_ready
);
 localparam IDLE=0,WAIT_SPACE=1,ADDRESS=2,DATA=3;
 logic[1:0]state;logic cancelled;
 logic[17:0]remaining;logic[8:0]left,burst;
 wire[8:0]boundary=9'd256-{1'b0,araddr[11:4]};
 wire[8:0]length0=remaining>128?9'd128:remaining[8:0];
 wire[8:0]length1=length0>boundary?boundary:length0;
 assign arsize=4;assign arburst=1;assign arvalid=state==ADDRESS;
 assign rready=state==DATA&&(cancelled||cancel||pixel_ready);
 assign pixel_valid=state==DATA&&rvalid&&!cancelled&&!cancel;
 assign pixel_data=rdata;
 always_ff @(posedge clk)begin
   done<=0;
   if(rst)begin state<=IDLE;busy<=0;fault<=0;cancelled<=0;remaining<=0;left<=0;burst<=0;araddr<=0;arlen<=0;end
   else begin
     if(cancel&&busy)cancelled<=1;
     case(state)
       IDLE:if(start&&!cancel)begin
         busy<=1;cancelled<=0;remaining<=BEATS;araddr<=base_address;state<=WAIT_SPACE;
       end
       WAIT_SPACE:begin
         if(cancelled||cancel||remaining==0)begin busy<=0;done<=1;state<=IDLE;end
         else if(fifo_free>=length1)begin burst<=length1;left<=length1;arlen<=length1-1;state<=ADDRESS;end
       end
       ADDRESS:if(arready)state<=DATA;
       DATA:if(rvalid&&rready)begin
         if(rresp!=0||rlast!=(left==1))begin fault<=1;cancelled<=1;end
         left<=left-1;
         if(rlast)begin remaining<=remaining-burst;araddr<=araddr+({23'd0,burst}<<4);state<=WAIT_SPACE;end
       end
     endcase
   end
 end
endmodule
