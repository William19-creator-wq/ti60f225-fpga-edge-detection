`timescale 1ns/1ps
// AB-T01：独立bytearray AXI端点，按真实16B拍写；故障是公开响应，不force桥内部。
module axi128_byte_memory #(parameter integer BYTES=16384)(
    input logic clk,rst,random_stalls,hold_aw,hold_w,hold_ar,hold_b,hold_r,
    input integer fault_kind,
    input logic m_axi_awvalid,output logic m_axi_awready,input logic [31:0] m_axi_awaddr,
    input logic [3:0] m_axi_awid,input logic [7:0] m_axi_awlen,input logic [2:0] m_axi_awsize,input logic [1:0] m_axi_awburst,
    input logic m_axi_wvalid,output logic m_axi_wready,input logic [127:0] m_axi_wdata,input logic [15:0] m_axi_wstrb,input logic m_axi_wlast,
    output logic m_axi_bvalid,input logic m_axi_bready,output logic [3:0] m_axi_bid,output logic [1:0] m_axi_bresp,
    input logic m_axi_arvalid,output logic m_axi_arready,input logic [31:0] m_axi_araddr,
    input logic [3:0] m_axi_arid,input logic [7:0] m_axi_arlen,input logic [2:0] m_axi_arsize,input logic [1:0] m_axi_arburst,
    output logic m_axi_rvalid,input logic m_axi_rready,output logic [127:0] m_axi_rdata,
    output logic [3:0] m_axi_rid,output logic [1:0] m_axi_rresp,output logic m_axi_rlast
);
    byte unsigned memory_bytes[0:BYTES-1];
    logic writing=0,b_pending=0,reading=0,b_wrong_sent=0;
    integer write_address,read_address,w_index,r_index,b_delay,r_delay;
    logic [31:0] rng=32'h9852cb7d;
    always @(negedge clk)begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        m_axi_awready=!rst && !writing && !b_pending && !reading && !hold_aw && (!random_stalls || rng[2:0]!=0);
        m_axi_wready=!rst && writing && !hold_w && (!random_stalls || rng[5:3]!=0);
        m_axi_arready=!rst && !writing && !b_pending && !reading && !hold_ar && (!random_stalls || rng[8:6]!=0);
        m_axi_bvalid=!rst && b_pending && b_delay==0 && !hold_b;
        m_axi_bid=fault_kind==2 && !b_wrong_sent ? 1 : 0;m_axi_bresp=fault_kind==1 ? 2 : 0;
        m_axi_rvalid=!rst && reading && r_delay==0 && !hold_r;
        m_axi_rid=((fault_kind==4 && r_index==1) || (fault_kind==7 && r_index==3)) ? 1 : 0;
        m_axi_rresp=fault_kind==3 && r_index==2 ? 2 : 0;
        m_axi_rlast=fault_kind==5 ? r_index==1 : (fault_kind==6 || fault_kind==7 ? r_index>=4 : r_index==3);
        if(fault_kind==7 && r_index==3)m_axi_rlast=1;
        m_axi_rdata=0;
        for(integer b=0;b<16;b++)if(reading && read_address+r_index*16+b<BYTES)m_axi_rdata[b*8+:8]=memory_bytes[read_address+r_index*16+b];
    end
    always @(posedge clk)begin
        if(rst)begin
            writing=0;b_pending=0;reading=0;b_wrong_sent=0;w_index=0;r_index=0;b_delay=0;r_delay=0;
            for(integer b=0;b<BYTES;b++)memory_bytes[b]=8'((b*37)^(b>>3));
        end else begin
            if(m_axi_awvalid && m_axi_awready)begin
                if(m_axi_awid!=0 || m_axi_awlen!=3 || m_axi_awsize!=4 || m_axi_awburst!=1 || m_axi_awaddr[5:0]!=0 || m_axi_awaddr+64>BYTES)$fatal(1,"AXI slave AW public format");
                write_address=m_axi_awaddr;w_index=0;writing=1;b_wrong_sent=0;
            end
            if(m_axi_wvalid && m_axi_wready)begin
                if(!writing || m_axi_wstrb!=16'hffff || m_axi_wlast!=(w_index==3))$fatal(1,"AXI slave W framing/strobe");
                for(integer b=0;b<16;b++)memory_bytes[write_address+w_index*16+b]=m_axi_wdata[b*8+:8];
                if(w_index==3)begin writing=0;b_pending=1;b_delay=7;end else w_index++;
            end else if(b_pending && b_delay>0)b_delay--;
            if(m_axi_bvalid && m_axi_bready)begin
                if(fault_kind==2 && !b_wrong_sent)begin b_wrong_sent=1;b_delay=4;end else b_pending=0;
            end
            if(m_axi_arvalid && m_axi_arready)begin
                if(m_axi_arid!=0 || m_axi_arlen!=3 || m_axi_arsize!=4 || m_axi_arburst!=1 || m_axi_araddr[5:0]!=0 || m_axi_araddr+64>BYTES)$fatal(1,"AXI slave AR public format");
                read_address=m_axi_araddr;r_index=0;reading=1;r_delay=3;
            end else if(reading && r_delay>0)r_delay--;
            if(m_axi_rvalid && m_axi_rready)begin
                if(m_axi_rlast && m_axi_rid==0)reading=0;
                else begin r_index++;r_delay=random_stalls ? integer'(rng[11:10]) : 1;end
            end
        end
    end
endmodule
