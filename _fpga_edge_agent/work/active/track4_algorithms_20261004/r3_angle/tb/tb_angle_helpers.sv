`timescale 1ns/1ps
module tb_angle_helpers;
    logic clk=0,rst=1,start=0;always #5 clk=~clk;
    logic [17:0] a=0;logic [29:0] b=0;wire [47:0] product;wire valid;
    angle_product mul(.*);
    logic [47:0] m_c=0,m_s=0;wire signed [48:0] cross_value;wire positive;
    angle_cross crossing(.*);
    logic signed [29:0] p=0;wire signed [12:0] q;
    project_round rounding(.*);
    logic finished=0;integer checks=0,seed=20261011;
    task automatic multiply_check(input logic [17:0] av,input logic [29:0] bv);
        logic [63:0] golden;
        begin
            golden={46'd0,av}*{34'd0,bv};@(negedge clk);a=av;b=bv;start=1;
            @(posedge clk);#1;if(!valid || product!==golden[47:0])$fatal(1,"product helper%0d",checks);checks++;
        end
    endtask
    task automatic rounding_check(input logic signed [29:0] pv,input logic signed [12:0] expected);
        begin p=pv;#1;if(q!==expected)$fatal(1,"RNE helper P%0d actual%0d expected%0d",p,q,expected);checks++;end
    endtask
    initial begin
        repeat(2)@(posedge clk);@(negedge clk);rst=0;
        multiply_check(0,0);multiply_check(262143,1073741823);multiply_check(1,1073741823);multiply_check(262143,1);
        for(integer i=0;i<18;i++)multiply_check(18'd1<<i,30'd1<<(i%30));
        for(integer i=0;i<256;i++)multiply_check($urandom(seed),$urandom(seed));
        @(negedge clk);start=0;@(posedge clk);#1;if(valid)$fatal(1,"bubble became product");checks++;
        @(negedge clk);rst=1;start=1;@(posedge clk);#1;if(valid)$fatal(1,"reset accepted product");checks++;
        @(negedge clk);rst=0;start=0;
        m_c=48'hffffffffffff;m_s=0;#1;if(!positive || cross_value!=49'sh0ffffffffffff)$fatal(1,"positive cross");checks++;
        m_c=0;m_s=48'hffffffffffff;#1;if(positive || cross_value!=-49'sh0ffffffffffff)$fatal(1,"negative cross");checks++;
        m_c=17;m_s=17;#1;if(positive || cross_value!=0)$fatal(1,"zero cross");checks++;
        rounding_check(30'sd262144,0);rounding_check(-30'sd262144,0);
        rounding_check(30'sd786432,2);rounding_check(-30'sd786432,-2);
        rounding_check(30'sd1310720,2);rounding_check(-30'sd1310720,-2);
        rounding_check(30'sh20000000,-1024);rounding_check(30'sh1fffffff,1024);
        $display("PASS ANGLE helpers checks%0d",checks);finished=1;#1;$finish;
    end
endmodule
