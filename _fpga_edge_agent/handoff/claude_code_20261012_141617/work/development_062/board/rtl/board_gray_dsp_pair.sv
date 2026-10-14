// RGB888两像素的77R/150G/29B完整16bit乘积。DSP无数据寄存器，调用者保持原流水/valid。
// DUAL高24位为11x10 lane1，低24位为8x8 lane0；所有输入和输出采用无符号右对齐。
module board_gray_dsp_pair(input wire clk,rst,input wire [47:0] in_rgb,output wire [95:0] terms);
    for(genvar c=0;c<3;c++)begin:g_coeff
        localparam [7:0] COEFF=c==0?8'd77:c==1?8'd150:8'd29;
        wire [47:0] products;
        EFX_DSP48 #(.MODE("DUAL"),.SIGNED(1'b0),.A_REG(1'b0),.B_REG(1'b0),.P_REG(1'b0),
            .W_REG(1'b0),.O_REG(1'b0),.C_REG(1'b0),.OP_REG(1'b0),.SHIFTER(1'b0),
            .P_EXT("ALIGN_RIGHT"),.M_SEL("P"),.N_SEL("CONST0"),.W_SEL("P")) multiply(
            .A({3'd0,in_rgb[24+(2-c)*8+:8],in_rgb[(2-c)*8+:8]}),.B({2'd0,COEFF,COEFF}),
            .C(18'd0),.CASCIN(48'd0),.OP(2'd0),.SHIFT_ENA(1'b0),.CLK(1'b0),.CE(1'b0),.RST(1'b0),
            .O(products),.CASCOUT(),.OVFL());
        assign terms[c*16+:16]=products[0+:16];
        assign terms[(3+c)*16+:16]=products[24+:16];
    end
endmodule
