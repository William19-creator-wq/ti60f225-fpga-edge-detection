// Round-robin AXI128 write ownership. Locked before exposing AW, released at B.
module frame_write_share(
 input wire clk,rst,
 input wire [1:0] c_awvalid,output wire [1:0] c_awready,input wire [1:0][31:0] c_awaddr,
 input wire [1:0][7:0] c_awlen,input wire [1:0][2:0] c_awsize,input wire [1:0][1:0] c_awburst,
 input wire [1:0] c_wvalid,output wire [1:0] c_wready,input wire [1:0][127:0] c_wdata,
 input wire [1:0][15:0] c_wstrb,input wire [1:0] c_wlast,
 output wire [1:0] c_bvalid,input wire [1:0] c_bready,output wire [1:0][1:0] c_bresp,
 output wire awvalid,input wire awready,output wire [31:0] awaddr,output wire [7:0] awlen,
 output wire [2:0] awsize,output wire [1:0] awburst,
 output wire wvalid,input wire wready,output wire [127:0] wdata,output wire [15:0] wstrb,output wire wlast,
 input wire bvalid,output wire bready,input wire [1:0] bresp
);
 reg owned,owner,prefer;
 assign awvalid=owned&&c_awvalid[owner];assign awaddr=c_awaddr[owner];assign awlen=c_awlen[owner];
 assign awsize=c_awsize[owner];assign awburst=c_awburst[owner];
 assign wvalid=owned&&c_wvalid[owner];assign wdata=c_wdata[owner];assign wstrb=c_wstrb[owner];assign wlast=c_wlast[owner];
 assign bready=owned&&c_bready[owner];assign c_bresp={2{bresp}};
 for(genvar i=0;i<2;i++)begin
   assign c_awready[i]=owned&&owner==i&&awready;
   assign c_wready[i]=owned&&owner==i&&wready;
   assign c_bvalid[i]=owned&&owner==i&&bvalid;
 end
 always @(posedge clk)begin
   if(rst)begin owned<=0;owner<=0;prefer<=0;end
   else if(!owned)begin
     if(c_awvalid[prefer])begin owner<=prefer;owned<=1;end
     else if(c_awvalid[!prefer])begin owner<=!prefer;owned<=1;end
   end else if(bvalid&&bready)begin owned<=0;prefer<=!owner;end
 end
endmodule
