

module vid_rx_align_v1 #(
	parameter I_VID_WIDTH = 16,
    parameter SIM_EN = 1'b1,
	parameter AXI_DDR_WIDTH = 256
	 
)(
input		wire										clk		,    
input		wire										rst_n	,
input		wire										i_vs	, //active hgih
input       wire                                        i_hs    ,
input		wire										i_de	, //active high
input		wire	[I_VID_WIDTH-1:0] 					vin     ,

output		wire										fifo_wr_en,
output		wire		[AXI_DDR_WIDTH-1:0]				fifo_wr_data ,
output		wire										frame_start,
output		wire										fifo_rst_p,
output		wire				[23:0]					frame_pix_num,
output      wire									    frame_stable,
output      wire    [31:0]                              ddr_frame_len		


);
  
  
  wire                                                  fi_pixel_start;
  wire                                                  fi_pixel_end  ;

  //before every frame,reset the fifo firs
  					


wire                    fi_valid;
wire [I_VID_WIDTH-1:0]  fi_data;
// wire [63:0]             ser2par_data;
// wire                    ser2par_valid;
wire                    ser2par_sop;
wire                    ser2par_eop;
frame_info_det #(
    .I_VID_WIDTH(I_VID_WIDTH),
    .SIM_EN(SIM_EN),
    .AXI_DDR_WIDTH(AXI_DDR_WIDTH)
)u_frame_info_det(
/*i*/.clk			    (clk		    ),    
/*i*/.rst_n			    (rst_n	        ),
/*i*/.i_vs			    (i_vs	        ), //active hgih
/*i*/.i_hs              (i_hs           ),
/*i*/.i_de			    (i_de	        ), //active high
/*i*/.i_data            (vin            ),
                    
/*o*/.frame_pix_num_o	(frame_pix_num  ),
/*o*/.frame_stable      (frame_stable	),
/*O*/.frame_start       (frame_start    ),
/*O*/.ddr_frame_len     (ddr_frame_len  ),
/*O*/.o_pixel_start     (fi_pixel_start ),
/*O*/.o_pixel_end       (fi_pixel_end   ),
/*O*/.fifo_rst_p        (fifo_rst_p     ),
/*O*/.o_valid           (fi_valid       ),
/*O*/.o_data            (fi_data        )
);             



ser2par_v1 # (
    .I_VID_WIDTH(I_VID_WIDTH),
    .O_VID_WIDTH(AXI_DDR_WIDTH)
)ser2par_24_128_inst (
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .i_valid        (fi_valid       ),//frame_stable &
    .i_data         (fi_data        ),
    .i_frame_start  (fi_pixel_start ),
    .i_frame_end    (fi_pixel_end   ),
    .frame_stable   (frame_stable   ),
    .frame_pix_num  (frame_pix_num  ),
    
    .o_valid        (fifo_wr_en     ),//(ser2par_valid  ),
    .o_data         (fifo_wr_data   ),//(ser2par_data   ),
    .o_frame_start  (ser2par_sop    ),
    .o_frame_end    (ser2par_eop    )
);
  

    // ser2par # (
    //     .I_VID_WIDTH(64),
    //     .I_MUX(AXI_DDR_WIDTH/64),
    //     .O_VID_WIDTH(AXI_DDR_WIDTH)
    // )
    // ser2par_inst (
    //     .clk        (clk            ),
    //     .rst_n      (rst_n          ),
    //     .i_valid    (ser2par_valid  ),
    //     .i_data     (ser2par_data   ),
    //     .i_start    (ser2par_sop    ),
    //     .i_end      (ser2par_eop    ),
    //     .o_valid    (fifo_wr_en     ),
    //     .o_data     (fifo_wr_data   )
    // );

  
  



endmodule
