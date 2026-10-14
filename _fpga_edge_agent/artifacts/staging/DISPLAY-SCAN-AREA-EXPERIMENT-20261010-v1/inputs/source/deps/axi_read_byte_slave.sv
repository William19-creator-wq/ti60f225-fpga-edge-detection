`timescale 1ns/1ps
// PF02/03：独立byte地址数学图；只在真实AR登记事务，R holding不依赖ready。
module axi_read_byte_slave #(parameter integer IMAGE_WIDTH=20,IMAGE_HEIGHT=8)(
    input logic clk,rst,input logic [2:0][2:0] source_for_result,input logic ideal,ar_pause,r_pause,
    input logic [2:0] fault_mode,
    input logic arvalid,output wire arready,input logic [31:0] araddr,input logic [3:0] arid,input logic [7:0] arlen,input logic [2:0] arsize,input logic [1:0] arburst,
    output logic rvalid,input logic rready,output logic [127:0] rdata,output logic [3:0] rid,output logic [1:0] rresp,output logic rlast,
    output logic [31:0] ar_count,r_count,output wire idle
);
    localparam integer N=IMAGE_WIDTH*IMAGE_HEIGHT,RGB_L=3*N,EDGE_L=(N+7)/8,ANN_L=(N+3)/4;
    logic busy;logic [31:0] address;logic [3:0] identity;logic [8:0] beats,index;
    logic [2:0] fault;logic extra_tail;logic [31:0] random_state=32'h189253a7;
    function automatic logic [7:0] memory_byte(input logic [31:0] a);
        integer slot,offset,pixel,x,y,ch,f,bit_index;logic [7:0] value;
        begin
            value=8'he5;
            if(a<32'h03000000)begin
                slot=int'(a>>23);offset=int'(a&32'h007fffff);
                if(slot<6 && offset<RGB_L)begin
                    pixel=offset/3;ch=offset%3;x=pixel%IMAGE_WIDTH;y=pixel/IMAGE_WIDTH;f=slot+1;
                    case(ch)0:value=8'((37*x+11*y+3*f)%256);1:value=8'((13*x+47*y+7*f)%256);2:value=8'((53*x+19*y+17*f)%256);endcase
                end
            end else if(a<32'h04800000)begin
                slot=int'((a-32'h03000000)>>23);offset=int'((a-32'h03000000)&32'h007fffff);f=int'(source_for_result[slot])+1;
                if(offset<EDGE_L)begin
                    value=0;for(bit_index=0;bit_index<8;bit_index++)begin
                        pixel=offset*8+bit_index;x=pixel%IMAGE_WIDTH;y=pixel/IMAGE_WIDTH;
                        if(pixel<N)value[bit_index]=((x+y+f)%3)==0;
                    end
                end else if(offset>=1048576+4224 && offset<1048576+4224+ANN_L)begin
                    value=0;for(bit_index=0;bit_index<4;bit_index++)begin
                        pixel=(offset-1048576-4224)*4+bit_index;x=pixel%IMAGE_WIDTH;y=pixel/IMAGE_WIDTH;
                        if(pixel<N)value[bit_index*2+:2]=2'((7*x+3*y+f)%4);
                    end
                end
            end
            return value;
        end
    endfunction
    function automatic logic [127:0] memory_beat(input logic [31:0] a);
        logic [127:0] value;for(integer byte_index=0;byte_index<16;byte_index++)value[byte_index*8+:8]=memory_byte(a+32'(byte_index));return value;
    endfunction
    assign arready=!rst && !busy && !rvalid && !ar_pause && (ideal || random_state[3:0]!=0);
    assign idle=!busy&&!rvalid;
    always_ff @(posedge clk)begin
        if(rst)begin busy<=0;rvalid<=0;rdata<=0;rid<=0;rresp<=0;rlast<=0;address<=0;identity<=0;beats<=0;index<=0;fault<=0;extra_tail<=0;ar_count<=0;r_count<=0;random_state<=32'h189253a7;end
        else begin
            random_state<={random_state[30:0],random_state[31]^random_state[21]^random_state[1]^random_state[0]};
            if(arvalid&&arready)begin
                if(araddr[3:0] || arsize!=4 || arburst!=1 || arlen>=64 || {1'b0,araddr[11:0]}+((13'(arlen)+1)<<4)>4096)$fatal(1,"Slave AR format/boundary");
                address<=araddr;identity<=arid;beats<={1'b0,arlen}+9'd1;index<=0;fault<=fault_mode;extra_tail<=0;busy<=1;ar_count<=ar_count+1;
            end
            if(rvalid&&rready)begin
                r_count<=r_count+1;rvalid<=0;
                if(index==beats-1)begin
                    if(fault==4 && !extra_tail)begin extra_tail<=1;index<=index+1;end
                    else busy<=0;
                end else if(extra_tail)busy<=0;
                else index<=index+1;
            end
            if(busy && (!rvalid||rready) && !r_pause && (ideal||random_state[2:0]!=0))begin
                // 已交付末拍时本沿不再重新提交旧index；下一帧由busy资格建立。
                if(!(rvalid&&rready))begin
                    rvalid<=1;rdata<=extra_tail ? 128'd0 : memory_beat(address+(32'(index)<<4));
                    rid<=fault==2 && index==0 ? identity^4'd1 : identity;
                    rresp<=fault==1 && index==0 ? 2'd2 : 2'd0;
                    rlast<=extra_tail || (fault==3 && index==0) || (index==beats-1 && fault!=4);
                end
            end
        end
    end
endmodule
