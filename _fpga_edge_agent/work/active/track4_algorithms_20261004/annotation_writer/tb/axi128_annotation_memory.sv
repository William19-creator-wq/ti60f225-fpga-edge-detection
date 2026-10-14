`timescale 1ns/1ps
// AW08：Source/EDGE明示公式夹具；ANN先毒化A5，仅实际AXI W可修改。
module axi128_annotation_memory #(parameter integer IMAGE_WIDTH=34,IMAGE_HEIGHT=20)(
    input logic clk,rst,random_stalls,hold_aw,hold_w,hold_ar,hold_b,hold_r,input integer fault_kind,
    input logic m_axi_awvalid,output logic m_axi_awready,input logic [31:0] m_axi_awaddr,
    input logic [3:0] m_axi_awid,input logic [7:0] m_axi_awlen,input logic [2:0] m_axi_awsize,input logic [1:0] m_axi_awburst,
    input logic m_axi_wvalid,output logic m_axi_wready,input logic [127:0] m_axi_wdata,input logic [15:0] m_axi_wstrb,input logic m_axi_wlast,
    output logic m_axi_bvalid=0,input logic m_axi_bready,output logic [3:0] m_axi_bid=0,output logic [1:0] m_axi_bresp=0,
    input logic m_axi_arvalid,output logic m_axi_arready,input logic [31:0] m_axi_araddr,
    input logic [3:0] m_axi_arid,input logic [7:0] m_axi_arlen,input logic [2:0] m_axi_arsize,input logic [1:0] m_axi_arburst,
    output logic m_axi_rvalid=0,input logic m_axi_rready,output logic [127:0] m_axi_rdata=0,
    output logic [3:0] m_axi_rid=0,output logic [1:0] m_axi_rresp=0,output logic m_axi_rlast=0,
    output logic writing=0,b_pending=0,reading=0
);
    localparam integer N=IMAGE_WIDTH*IMAGE_HEIGHT,S=((3*N+63)/64)*64,E=((N+511)/512)*64,A=((4224+(N+3)/4+63)/64)*64;
    localparam integer BYTES=6*S+3*E+3*A;
    byte unsigned memory_bytes[0:BYTES-1];
    function automatic integer map_byte(input logic [31:0] address);
        integer slot,offset;
        begin
            map_byte=-1;
            if(address<32'h03000000)begin
                slot=int'(address>>23);offset=int'(address&32'h007fffff);
                if(slot<6 && offset<S)map_byte=slot*S+offset;
            end else if(address<32'h04800000)begin
                slot=int'((address-32'h03000000)>>23);offset=int'((address-32'h03000000)&32'h007fffff);
                if(offset<E)map_byte=6*S+slot*E+offset;
                else if(offset>=1048576 && offset<1048576+A)map_byte=6*S+3*E+slot*A+offset-1048576;
            end
        end
    endfunction
    function automatic logic [7:0] source_byte(input integer slot,offset);
        integer pixel,x,y,ch,f;
        begin
            if(offset>=3*N)return 0;
            pixel=offset/3;x=pixel%IMAGE_WIDTH;y=pixel/IMAGE_WIDTH;ch=offset%3;f=slot+1;
            case(ch)
                0:return 8'(37*x+11*y+3*f);
                1:return 8'(13*x+47*y+7*f);
                2:return 8'(53*x+19*y+17*f);
            endcase
            return 0;
        end
    endfunction
    function automatic logic edge_pixel(input integer pixel);
        return (7*(pixel%IMAGE_WIDTH)+3*(pixel/IMAGE_WIDTH))%9<2;
    endfunction
    function automatic logic [7:0] edge_byte(input integer offset);
        logic [7:0] value;
        begin
            value=0;
            for(integer bit_index=0;bit_index<8;bit_index++)
                if(offset*8+bit_index<N)value[bit_index]=edge_pixel(offset*8+bit_index);
            return value;
        end
    endfunction
    integer write_address=0,read_address=0,w_index=0,r_index=0,r_count=0,b_delay=0,r_delay=0,w_fault=0,r_fault=0;
    logic [3:0] read_identity=0;bit b_wrong_sent=0,reset_held=0;
    logic [31:0] rng=32'h9852cb7d;
    always @(negedge clk)begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        m_axi_awready=!rst&&!writing&&!b_pending&&!hold_aw&&(!random_stalls||rng[2:0]!=0);
        m_axi_wready=!rst&&writing&&!hold_w&&(!random_stalls||rng[5:3]!=0);
        m_axi_arready=!rst&&!reading&&!hold_ar&&(!random_stalls||rng[8:6]!=0);
    end
    always @(posedge clk)begin
        if(rst)begin
            writing=0;b_pending=0;reading=0;b_wrong_sent=0;w_index=0;r_index=0;b_delay=0;r_delay=0;
            m_axi_bvalid<=0;m_axi_rvalid<=0;m_axi_bid<=0;m_axi_bresp<=0;m_axi_rid<=0;m_axi_rresp<=0;m_axi_rlast<=0;m_axi_rdata<=0;
            if(!reset_held)begin
                for(integer i=0;i<BYTES;i++)memory_bytes[i]=8'ha5;
                for(integer slot=0;slot<6;slot++)for(integer i=0;i<S;i++)memory_bytes[slot*S+i]=source_byte(slot,i);
                for(integer slot=0;slot<3;slot++)for(integer i=0;i<E;i++)memory_bytes[6*S+slot*E+i]=edge_byte(i);
            end
            reset_held=1;
        end else begin
            reset_held=0;
            if(m_axi_awvalid&&m_axi_awready)begin
                if(m_axi_awid!=0||m_axi_awlen!=3||m_axi_awsize!=4||m_axi_awburst!=1||m_axi_awaddr[5:0]!=0||m_axi_awaddr<32'h03100000||((m_axi_awaddr-32'h03000000)&32'h007fffff)<32'h00100000||map_byte(m_axi_awaddr)<0 || map_byte(m_axi_awaddr+32'd63)!=map_byte(m_axi_awaddr)+63)$fatal(1,"Duplex AW grant/format");
                write_address=map_byte(m_axi_awaddr);w_index=0;writing=1;b_wrong_sent=0;w_fault=fault_kind;
            end
            if(m_axi_wvalid&&m_axi_wready)begin
                if(!writing||m_axi_wstrb!=16'hffff||m_axi_wlast!==(w_index==3))$fatal(1,"Duplex W ownership/strobe/LAST");
                for(integer i=0;i<16;i++)memory_bytes[write_address+w_index*16+i]=m_axi_wdata[i*8+:8];
                if(w_index==3)begin writing=0;b_pending=1;b_delay=7;end else w_index++;
            end
            // hold仅推迟首次公开；已公开的B正文和valid保持到实际fire。
            if(m_axi_bvalid&&m_axi_bready)begin
                m_axi_bvalid<=0;
                if(m_axi_bid==0)begin
                    b_pending=0;
                end else begin b_wrong_sent=1;b_delay=17;end
            end else if(b_pending&&!m_axi_bvalid)begin
                if(b_delay>0)b_delay--;
                else if(!hold_b)begin
                    m_axi_bvalid<=1;m_axi_bid<=w_fault==2&&!b_wrong_sent?4'd7:4'd0;m_axi_bresp<=w_fault==1?2'd2:2'd0;
                end
            end
            if(m_axi_arvalid&&m_axi_arready)begin
                if((m_axi_arid!=0&&m_axi_arid!=2)||m_axi_arsize!=4||m_axi_arburst!=1||m_axi_araddr[3:0]!=0||m_axi_arlen>63||
                    map_byte(m_axi_araddr)<0 || map_byte(m_axi_araddr+32'((int'(m_axi_arlen)+1)*16-1))!=map_byte(m_axi_araddr)+(int'(m_axi_arlen)+1)*16-1||int'(m_axi_araddr[11:0])+(int'(m_axi_arlen)+1)*16>4096)$fatal(1,"Duplex AR grant/format/4KiB");
                if(m_axi_arid==0&&(m_axi_arlen!=3||m_axi_araddr[5:0]!=0))$fatal(1,"Algorithm AR not 64B");
                read_address=map_byte(m_axi_araddr);r_index=0;r_count=int'(m_axi_arlen)+1;reading=1;r_delay=3;r_fault=fault_kind;read_identity=m_axi_arid;
            end
            if(m_axi_rvalid&&m_axi_rready)begin
                m_axi_rvalid<=0;
                if(m_axi_rlast&&m_axi_rid==read_identity)reading=0;
                else begin r_index++;r_delay=random_stalls?int'(rng[11:10]):1;end
            end else if(reading&&!m_axi_rvalid)begin
                if(r_delay>0)r_delay--;
                else if(!hold_r)begin
                    m_axi_rvalid<=1;m_axi_rid<=r_fault==4&&r_index==1?(read_identity^4'd1):read_identity;
                    m_axi_rresp<=r_fault==3&&r_index==2?2'd2:2'd0;
                    m_axi_rlast<=r_fault==5?r_index==1:r_fault==6?r_index>=r_count:r_index==r_count-1;
                    for(integer i=0;i<16;i++)begin
                        if(read_address+r_index*16+i<BYTES)m_axi_rdata[i*8+:8]<=memory_bytes[read_address+r_index*16+i];
                        else m_axi_rdata[i*8+:8]<=0;
                    end
                end
            end
        end
    end
endmodule
