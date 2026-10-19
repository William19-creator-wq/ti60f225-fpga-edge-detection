`timescale  1ns /1ps
module color_bar_tb;

parameter	MAX_HRES		= 12'd1200;
parameter	MAX_VRES		= 12'd1920;
parameter	HSP				= 8'd8;
parameter	HBP				= 8'd46;
parameter	HFP				= 8'd46;
parameter	VSP				= 8'd8;
parameter	VBP				= 8'd32;
parameter	VFP				= 8'd177;

reg clk = 1'b0;
reg rst_n = 1'b0;
always #10 clk = ~clk;

initial
begin
        #0
            rst_n = 0;
        # 100

            rst_n = 1;
end 


color_bar_rgb #(
			.HS_POLORY 		(1'b0	),
			.VS_POLORY 		(1'b0	),
			.H_FRONT_PORCH 	(HFP/2	),
			.H_SYNC 		(HSP/2	),
			.H_VALID 		(MAX_HRES/2	),
			.H_BACK_PORCH 	(HBP/2	),
			.V_FRONT_PORCH 	(VFP		),
			.V_SYNC 		(VSP		),
			.V_VALID 		(MAX_VRES	),
			.V_BACK_PORCH 	(VBP		),
			.TEST_MODE 		(2'b01		)
	)u_color_bar_rgb(
	/*i*/.clk	(clk),
	/*i*/.rst_n	(rst_n ),
	/*o*/.hs	(hs),
	/*o*/.vs	(vs),
	/*o*/.de	(de),
	/*O*/.h_cnt (h_cnt),
	/*O*/.v_cnt (v_cnt),
	/*o*/.rgb_r	(r_data),    //像素数据、红色分量
	/*o*/.rgb_g	(g_data),    //像素数据、绿色分量
	/*o*/.rgb_b (b_data)    //像素数据、蓝色分量
	
	);


endmodule