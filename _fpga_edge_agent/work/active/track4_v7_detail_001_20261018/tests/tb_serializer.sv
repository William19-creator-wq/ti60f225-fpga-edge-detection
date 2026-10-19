`timescale 1ns/1ps
module tb_serializer;
    reg fast=1,pairclk=0;
    always #10 fast=~fast;
    always #20 pairclk=~pairclk;
    reg vs=0,hs=0,de=0;reg [47:0] pairdata=0;
    wire ov,oh,od;wire [23:0] pixel;
    serializer_from_top dut(.hdmi_tx_slow_clk(fast),.rgb_vs(vs),.rgb_hs(hs),.rgb_de(de),.rgb_datax2(pairdata),
        .out_vs(ov),.out_hs(oh),.out_de(od),.out_pixel(pixel));
    integer expected=0,count=0,y,x;
    // 每个位置不同的24位序号，要求输出0..5759完整且顺序相同。
    always @(posedge fast)begin
        #1;
        if(od)begin
            if(pixel!==expected[23:0])$fatal(1,"SERIALIZER mismatch count=%0d got=%0d expected=%0d",count,pixel,expected);
            count=count+1;expected=expected+1;
        end
    end
    task blank(input integer n);
        repeat(n)begin @(posedge pairclk);de<=0;pairdata<=48'hdeadbeabcdef;end
    endtask
    initial begin
        blank(3);@(posedge pairclk);vs<=1;blank(3);@(posedge pairclk);vs<=0;blank(5);
        for(y=0;y<3;y=y+1)begin
            for(x=0;x<960;x=x+1)begin
                @(posedge pairclk);de<=1;pairdata<={24'(y*1920+x*2+1),24'(y*1920+x*2)};
            end
            blank(140);
        end
        blank(5);#30;
        if(count!=5760)$fatal(1,"wrong output pixel count=%0d",count);
        $display("SERIALIZER_PASS distinct_pixels=%0d ideal_phase_aligned_2to1_clocks",count);$finish;
    end
endmodule
