`timescale 1ns/1ps
module tb_rawcard;
    reg clk=0;always #6.734 clk=~clk;
    reg rst_n=0,vs=0,de=0;
    reg [15:0] camera=0;wire [15:0] raw;wire row_odd;
    wire rv,rh,rd,valid;wire [47:0] rgb;
    rawcard_overlay injector(clk,rst_n,vs,de,camera,raw,row_odd);
    debayer_top_2to1 dut(.in_pclk(clk),.in_rstn(rst_n),.raw_vs_i(vs),.raw_hs_i(1'b0),.raw_de_i(de),.raw_valid_i(de),.raw_datax4_i(raw),
        .r_gain(16'h0100),.g_gain(16'h0100),.b_gain(16'h0100),.rgb_vs_o(rv),.rgb_hs_o(rh),.rgb_de_o(rd),.rgb_valid_o(valid),.rgb_datax2_o(rgb));
    integer frame,row,col,i,slot,cy,cx,raw_checks=0,rgb_checks=0;
    integer qy[0:5],qx[0:5];bit qv[0:5];
    reg [23:0] palette[0:7];reg [23:0] target;reg [7:0] gray;reg [15:0] expected_raw;
    function automatic [23:0] color_at(input integer y,x);
        reg [7:0] g;
        begin
            if(y<320) color_at=palette[x/120];
            else begin g=(x/60)*17;color_at={g,g,g};end
        end
    endfunction
    always @(posedge clk) begin
        for(i=5;i>0;i=i-1) begin qv[i]=qv[i-1];qy[i]=qy[i-1];qx[i]=qx[i-1];end
        qv[0]=rst_n && de;qy[0]=row;qx[0]=col;
        if(!rst_n) for(i=0;i<6;i=i+1) qv[i]=0;
        #1;
        if(qv[5] && qy[5]>=227 && qy[5]<=413 && qy[5]!=319 && qy[5]!=320 && qy[5]!=321 && qy[5]!=322 && qx[5]%60>=3 && qx[5]%60<=56) begin
            cy=qy[5]-1;cx=qx[5];
            if(!valid || !rd) $fatal(1,"valid lost");
            target=color_at(cy,cx);
            // 打包是BGR；现有HDMI旁路交换R/B，因此该24位字恰为最终RGB。
            for(slot=0;slot<2;slot=slot+1) begin
                if(((rgb>>(slot*24))&48'hffffff)!=={24'd0,target})
                    $fatal(1,"Pipeline mismatch y=%0d x=%0d slot=%0d got=%h expected=%h",cy,cx,slot,(rgb>>(slot*24))&48'hffffff,target);
                rgb_checks=rgb_checks+1;
            end
        end
    end
    task blank(input integer n);
        repeat(n) begin @(negedge clk);de=0;camera=$random;#1;if(raw!==camera)$fatal(1,"blanking mismatch");end
    endtask
    initial begin
        palette[0]=24'hc0c0c0;palette[1]=24'hc0c020;palette[2]=24'h20c0c0;palette[3]=24'h20c020;
        palette[4]=24'hc020c0;palette[5]=24'hc02020;palette[6]=24'h2020c0;palette[7]=24'h202020;
        repeat(5) @(negedge clk);rst_n=1;blank(10);
        for(frame=0;frame<2;frame=frame+1) begin
            @(negedge clk);vs=1;blank(4);@(negedge clk);vs=0;blank(12);
            for(row=0;row<430;row=row+1) begin
                for(col=0;col<960;col=col+1) begin
                    @(negedge clk);de=1;camera=$random;#1;
                    if(row_odd !== (row%2 != 0)) $fatal(1,"Row tag mismatch y=%0d tag=%b",row,row_odd);
                    expected_raw=camera;
                    if(row>=224 && row<416) begin
                        target=color_at(row,col);
                        expected_raw=(row%2)?{target[15:8],target[23:16]}:{target[7:0],target[15:8]};
                    end
                    if(raw!==expected_raw)$fatal(1,"RAW mismatch y=%0d x=%0d",row,col);
                    raw_checks=raw_checks+1;
                end
                blank(16);
            end
            blank(20);
        end
        @(negedge clk);rst_n=0;#1;if(raw!==camera)$fatal(1,"reset bypass mismatch");
        $display("RAWTAG_PASS raw_words=%0d rgb_pixels=%0d frames=2",raw_checks,rgb_checks);$finish;
    end
endmodule
