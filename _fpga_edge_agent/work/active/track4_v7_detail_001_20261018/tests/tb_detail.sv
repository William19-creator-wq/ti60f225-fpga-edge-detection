`timescale 1ns/1ps
module tb_detail;
    reg clk=0;always #10 clk=~clk;
    reg rst_n=0,vs=0,de=0;reg [15:0] camera=0;
    wire [15:0] injected;wire odd;
    rawcard_overlay rawcard(clk,rst_n,vs,de,camera,injected,odd);
    wire rv,rh,rd,valid;wire [47:0] rgb;
    debayer_top_2to1 #(.Y_PHASE_XOR(1'b1),.RB_SWAP(1'b1)) dut(
        .in_pclk(clk),.in_rstn(rst_n),.raw_vs_i(vs),.raw_hs_i(1'b0),.raw_de_i(de),.raw_valid_i(de),.raw_datax4_i(injected),
        .r_gain(16'h0100),.g_gain(16'h0100),.b_gain(16'h0100),.rgb_vs_o(rv),.rgb_hs_o(rh),.rgb_de_o(rd),.rgb_valid_o(valid),.rgb_datax2_o(rgb),.rgb_rout(),.rgb_gout(),.rgb_bout());
    reg drst=0,dvs=0,dde=0;reg [23:0] camera_rgb=0;
    wire [23:0] direct_rgb;
    colorcard_overlay directcard(.clk(clk),.rst_n(drst),.vs(dvs),.de(dde),
        .camera_r(camera_rgb[23:16]),.camera_g(camera_rgb[15:8]),.camera_b(camera_rgb[7:0]),
        .out_r(direct_rgb[23:16]),.out_g(direct_rgb[15:8]),.out_b(direct_rgb[7:0]));
    integer row=0,col=0,i,j,s,sy,sx;
    integer qy[0:7],qx[0:7];reg qv[0:7];
    integer raw_checks=0,direct_checks=0,rgb_checks=0;
    reg raw_done=0,direct_done=0;
    reg [15:0] expected_raw;reg [23:0] expected_rgb;
    // Independent arithmetic oracle: no variable bit selects or RTL helper instantiation.
    function automatic [7:0] pattern(input integer y,x);
        integer width,bright;
        begin
            width=2**(x/320);
            if(y<64)bright=(x/width)%2;
            else if(y<128)bright=(y/width)%2;
            else bright=((x/width)+(y/width))%2;
            pattern=bright?224:32;
        end
    endfunction
    function automatic [7:0] raw_reference(input integer y,x);
        if(y>=224 && y<416)raw_reference=pattern(y-224,x);
        else raw_reference=(y*83+x*37+x*y*3)%192+32;
    endfunction
    function automatic [23:0] bilinear(input integer y,x);
        integer c,h,v,cross_mean,diag,r,g,b;
        begin
            c=raw_reference(y,x);
            h=(raw_reference(y,x-1)+int'(raw_reference(y,x+1)))/2;
            v=(raw_reference(y-1,x)+int'(raw_reference(y+1,x)))/2;
            cross_mean=(int'(raw_reference(y,x-1))+raw_reference(y,x+1)+raw_reference(y-1,x)+raw_reference(y+1,x))/4;
            diag=(int'(raw_reference(y-1,x-1))+raw_reference(y-1,x+1)+raw_reference(y+1,x-1)+raw_reference(y+1,x+1))/4;
            if(y%2==0 && x%2==0)begin r=diag;g=cross_mean;b=c;end
            else if(y%2==1 && x%2==1)begin r=c;g=cross_mean;b=diag;end
            else if(y%2==0)begin r=v;g=c;b=h;end
            else begin r=h;g=c;b=v;end
            bilinear={r[7:0],g[7:0],b[7:0]};
        end
    endfunction
    always @(posedge clk)begin
        for(i=7;i>0;i=i-1)begin qy[i]=qy[i-1];qx[i]=qx[i-1];qv[i]=qv[i-1];end
        qy[0]=row;qx[0]=col;qv[0]=de&&rst_n;
        if(!rst_n)for(i=0;i<8;i=i+1)qv[i]=0;
        #1;
        if(qv[5])begin
            sy=qy[5]-1;sx=2*qx[5]-2;
            if(sy>=225 && sy<415 && sx>=4 && sx<1916)begin
                if(rd!==1 || valid!==1)$fatal(1,"Lost valid");
                for(s=0;s<2;s=s+1)begin
                    if(rgb[s*24+:24]!==bilinear(sy,sx+s))$fatal(1,"RGB mismatch y=%0d x=%0d got=%h exp=%h",sy,sx+s,rgb[s*24+:24],bilinear(sy,sx+s));
                    rgb_checks=rgb_checks+1;
                end
            end
        end
    end
    initial begin
        repeat(5)@(negedge clk);rst_n=1;
        @(negedge clk);vs=1;repeat(5)@(negedge clk);vs=0;repeat(8)@(negedge clk);
        for(row=0;row<430;row=row+1)begin
            for(col=0;col<960;col=col+1)begin
                @(negedge clk);de=1;camera={8'(row+col),8'(row*3+col)};
                expected_raw=(row>=224 && row<416)?{pattern(row-224,col*2+1),pattern(row-224,col*2)}:camera;
                #1;if(injected!==expected_raw || odd!==(row%2))$fatal(1,"RAW injection/bypass/row error %0d %0d",row,col);
                raw_checks=raw_checks+1;
            end
            repeat(140)begin @(negedge clk);de=0;camera=16'had53;#1;if(injected!==camera)$fatal(1,"RAW blank bypass");end
        end
        @(negedge clk);rst_n=0;de=1;#1;if(injected!==camera)$fatal(1,"RAW reset bypass");
        de=0;raw_done=1;
    end
    initial begin:direct_test
        integer y,x;
        repeat(5)@(negedge clk);drst=1;
        @(negedge clk);dvs=1;repeat(5)@(negedge clk);dvs=0;repeat(8)@(negedge clk);
        for(y=0;y<430;y=y+1)begin
            for(x=0;x<1920;x=x+1)begin
                @(negedge clk);dde=1;camera_rgb={8'(y+x),8'(y*3+x),8'(x*7+y)};
                expected_rgb=(y<192)?{3{pattern(y,x)}}:camera_rgb;
                #1;if(direct_rgb!==expected_rgb)$fatal(1,"Direct pattern/bypass error %0d %0d got=%h exp=%h",y,x,direct_rgb,expected_rgb);
                direct_checks=direct_checks+1;
            end
            repeat(12)begin @(negedge clk);dde=0;camera_rgb=24'hab1234;#1;if(direct_rgb!==camera_rgb)$fatal(1,"Direct blank bypass");end
        end
        @(negedge clk);drst=0;dde=1;#1;if(direct_rgb!==camera_rgb)$fatal(1,"Direct reset bypass");
        dde=0;direct_done=1;
    end
    initial begin
        wait(raw_done&&direct_done);
        if(rgb_checks!=363280)$fatal(1,"Missing RGB comparison");
        $display("DETAIL_PASS raw_words=%0d direct_pixels=%0d bilinear_pixels=%0d",raw_checks,direct_checks,rgb_checks);$finish;
    end
    initial begin #30000000;$fatal(1,"Timeout");end
endmodule
