// AXI128 to Efinity DDR3 Catalog merged-address interface.
// One read and one write burst may be outstanding. Reset only with DDR reset.
// Arbitration is held under backpressure; ownership ends at B/final R, not address.
module catalog_axi_adapter (
 input logic clk,rst,enable,
 input logic s_awvalid,output logic s_awready,input logic [31:0] s_awaddr,
 input logic [3:0] s_awid,input logic [7:0] s_awlen,input logic [2:0] s_awsize,
 input logic [1:0] s_awburst,
 input logic s_wvalid,output logic s_wready,input logic [127:0] s_wdata,
 input logic [15:0] s_wstrb,input logic s_wlast,
 output logic s_bvalid,input logic s_bready,output logic [3:0] s_bid,output logic [1:0] s_bresp,
 input logic s_arvalid,output logic s_arready,input logic [31:0] s_araddr,
 input logic [3:0] s_arid,input logic [7:0] s_arlen,input logic [2:0] s_arsize,
 input logic [1:0] s_arburst,
 output logic s_rvalid,input logic s_rready,output logic [127:0] s_rdata,
 output logic [3:0] s_rid,output logic [1:0] s_rresp,output logic s_rlast,
 output logic axi_avalid,input logic axi_aready,output logic axi_atype,
 output logic [7:0] axi_aid,output logic [31:0] axi_aaddr,output logic [7:0] axi_alen,
 output logic [2:0] axi_asize,output logic [1:0] axi_aburst,output logic [1:0] axi_alock,
 output logic axi_wvalid,input logic axi_wready,output logic [7:0] axi_wid,
 output logic [127:0] axi_wdata,output logic [15:0] axi_wstrb,output logic axi_wlast,
 input logic axi_bvalid,output logic axi_bready,input logic [7:0] axi_bid,input logic [1:0] axi_bresp,
 input logic axi_rvalid,output logic axi_rready,input logic [127:0] axi_rdata,
 input logic [7:0] axi_rid,input logic [1:0] axi_rresp,input logic axi_rlast,
 output logic fault
);
 logic write_busy,read_busy,address_pending,address_write,prefer_read;
 logic [3:0] write_id,read_id;
 logic [8:0] write_left,read_left;
 logic reject_write,reject_read;
 wire choose_read=!write_busy&&s_awvalid ? (prefer_read&&!read_busy&&s_arvalid) : (!read_busy&&s_arvalid);
 wire choose_write=!choose_read&&!write_busy&&s_awvalid;
 wire can_address=enable&&!fault&&!address_pending;
 assign s_awready=can_address&&choose_write;
 assign s_arready=can_address&&choose_read;
 assign axi_avalid=address_pending;
 assign axi_atype=address_write;
 assign axi_alock=0;
 assign axi_wid={4'd0,write_id};
 assign axi_wvalid=write_busy&&!reject_write&&(write_left!=0)&&s_wvalid;
 assign s_wready=write_busy&&(write_left!=0)&&(reject_write||axi_wready);
 assign axi_wdata=s_wdata;assign axi_wstrb=s_wstrb;assign axi_wlast=s_wlast;
 // Invalid bursts are consumed locally with DECERR and never reach DDR.
 assign s_bvalid=write_busy&&(reject_write?(write_left==0):axi_bvalid);
 assign axi_bready=write_busy&&!reject_write&&s_bready;
 assign s_bid=reject_write?write_id:axi_bid[3:0];assign s_bresp=reject_write?2'b11:axi_bresp;
 assign s_rvalid=read_busy&&(reject_read||axi_rvalid);assign axi_rready=read_busy&&!reject_read&&s_rready;
 assign s_rdata=reject_read?128'd0:axi_rdata;assign s_rid=reject_read?read_id:axi_rid[3:0];
 assign s_rresp=reject_read?2'b11:axi_rresp;assign s_rlast=reject_read?(read_left==1):axi_rlast;
 function automatic legal(input logic [31:0] a,input logic [7:0] len,input logic [2:0] size,input logic [1:0] burst);
   legal=(size==4)&&(burst==1)&&(a[3:0]==0)&&(len<128)&&({1'b0,a[11:0]}+(({5'd0,len}+13'd1)<<4)<=4096);
 endfunction
 always_ff @(posedge clk) begin
   if(rst)begin
     write_busy<=0;read_busy<=0;address_pending<=0;address_write<=0;prefer_read<=0;
     write_id<=0;read_id<=0;write_left<=0;read_left<=0;fault<=0;
     reject_write<=0;reject_read<=0;
     axi_aid<=0;axi_aaddr<=0;axi_alen<=0;axi_asize<=0;axi_aburst<=0;
   end else begin
     if(axi_avalid&&axi_aready)address_pending<=0;
     if(s_awvalid&&s_awready)begin
       write_busy<=1;write_id<=s_awid;write_left<={1'b0,s_awlen}+1;
       address_pending<=legal(s_awaddr,s_awlen,s_awsize,s_awburst);address_write<=1;prefer_read<=1;
       reject_write<=!legal(s_awaddr,s_awlen,s_awsize,s_awburst);
       axi_aid<={4'd0,s_awid};axi_aaddr<=s_awaddr;axi_alen<=s_awlen;axi_asize<=s_awsize;axi_aburst<=s_awburst;
       if(!legal(s_awaddr,s_awlen,s_awsize,s_awburst))fault<=1;
     end
     if(s_arvalid&&s_arready)begin
       read_busy<=1;read_id<=s_arid;read_left<={1'b0,s_arlen}+1;
       address_pending<=legal(s_araddr,s_arlen,s_arsize,s_arburst);address_write<=0;prefer_read<=0;
       reject_read<=!legal(s_araddr,s_arlen,s_arsize,s_arburst);
       axi_aid<={4'd0,s_arid};axi_aaddr<=s_araddr;axi_alen<=s_arlen;axi_asize<=s_arsize;axi_aburst<=s_arburst;
       if(!legal(s_araddr,s_arlen,s_arsize,s_arburst))fault<=1;
     end
     if(s_wvalid&&s_wready)begin
       write_left<=write_left-1;
       if(s_wlast!=(write_left==1))fault<=1;
     end
     if(s_bvalid&&s_bready)begin
       write_busy<=0;
       if(!reject_write&&(axi_bid!={4'd0,write_id}||axi_bresp!=0||
           (write_left!=0&&!(write_left==1&&s_wvalid&&s_wready))))fault<=1;
     end
     if(s_rvalid&&s_rready)begin
       read_left<=read_left-1;
       if(!reject_read&&(axi_rid!={4'd0,read_id}||axi_rresp!=0||axi_rlast!=(read_left==1)))fault<=1;
       if(s_rlast)read_busy<=0;
     end
   end
 end
endmodule
