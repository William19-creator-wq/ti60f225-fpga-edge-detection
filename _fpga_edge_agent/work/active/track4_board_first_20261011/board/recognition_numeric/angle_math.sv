// AN06：单个18×30结果寄存器；core须在start之前预约目的，不能对返回施加背压。
module angle_product(input logic clk,rst,start,input logic [17:0] a,input logic [29:0] b,
    output logic [47:0] product,output logic valid);
    always_ff @(posedge clk)begin
        if(rst)valid<=0;
        else begin valid<=start;if(start)product<=a*b;end
    end
endmodule

module angle_cross(input logic [47:0] m_c,m_s,output logic signed [48:0] cross_value,output logic positive);
    always_comb begin cross_value=$signed({1'b0,m_c})-$signed({1'b0,m_s});positive=cross_value>0;end
endmodule

// AN03：负数先扩s31取绝对值，再用完整余数RNE；不能用算术右移代替舍入。
module project_round(input logic signed [29:0] p,output logic signed [12:0] q);
    logic signed [30:0] extended;logic [30:0] magnitude;logic [11:0] whole;
    logic [18:0] remainder;logic [12:0] rounded;
    always_comb begin
        extended=$signed({p[29],p});magnitude=p[29]?-$signed(extended):extended;
        whole=magnitude[30:19];remainder=magnitude[18:0];
        rounded={1'b0,whole}+((remainder>19'd262144 || (remainder==19'd262144 && whole[0]))?13'd1:13'd0);
        q=p[29]?-$signed(rounded):$signed(rounded);
    end
endmodule
