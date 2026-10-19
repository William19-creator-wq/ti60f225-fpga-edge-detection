`timescale 1ns/1ps
module tb_spatial;
    reg clk=0;always #10 clk=~clk;
    reg rst_n=0,vs=0,de=0;reg [15:0] raw=0;
    wire rv,rh,rd,valid;wire [47:0] rgb;
    debayer_top_2to1 #(.Y_PHASE_XOR(1'b1),.RB_SWAP(1'b1)) dut(
        .in_pclk(clk),.in_rstn(rst_n),.raw_vs_i(vs),.raw_hs_i(1'b0),.raw_de_i(de),.raw_valid_i(de),.raw_datax4_i(raw),
        .r_gain(16'h0100),.g_gain(16'h0100),.b_gain(16'h0100),.rgb_vs_o(rv),.rgb_hs_o(rh),.rgb_de_o(rd),.rgb_valid_o(valid),.rgb_datax2_o(rgb));
    integer row,col,i,pattern,fd,cycles=0;
    integer qy[0:7],qx[0:7];reg qv[0:7];
    function automatic [7:0] sample(input integer y,x,p);
        integer z;
        begin
            case(p)
                0:z=(x*37+y*83+(x*y*3))%192+32;
                1:z=((x/4)%2)?208:48;
                2:z=((y/4)%2)?208:48;
                3:z=(((x/8)+(y/8))%2)?208:48;
                default:z=((x/2)%2)?208:48;
            endcase
            sample=z;
        end
    endfunction
    always @(posedge clk) begin
        for(i=7;i>0;i=i-1)begin qy[i]=qy[i-1];qx[i]=qx[i-1];qv[i]=qv[i-1];end
        qy[0]=row;qx[0]=col;qv[0]=de&&rst_n;
        if(!rst_n)for(i=0;i<8;i=i+1)qv[i]=0;
        #1;
        if(qv[5])$fwrite(fd,"%0d,%0d,%0d,%0d,%0d,%06h,%06h\n",pattern,qy[5],qx[5],rd,valid,rgb[23:0],rgb[47:24]);
    end
    task blank(input integer n);
        repeat(n)begin @(negedge clk);de=0;raw=16'hdead;end
    endtask
    initial begin
        fd=$fopen("spatial.csv","w");
        $fwrite(fd,"pattern,input_row,input_pair,de,valid,slot0,slot1\n");
        for(pattern=0;pattern<5;pattern=pattern+1)begin
            rst_n=0;blank(5);rst_n=1;blank(4);
            @(negedge clk);vs=1;blank(4);@(negedge clk);vs=0;blank(8);
            for(row=0;row<24;row=row+1)begin
                for(col=0;col<960;col=col+1)begin
                    @(negedge clk);de=1;raw={sample(row,col*2+1,pattern),sample(row,col*2,pattern)};
                end
                blank(140);
            end
            blank(20);
        end
        $fclose(fd);$display("SPATIAL_CAPTURE_DONE patterns=5 rows=24 pairs=960");$finish;
    end
endmodule
