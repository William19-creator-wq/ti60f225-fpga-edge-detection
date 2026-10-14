`timescale 1 ns / 1 ns

module lpddr4_tb;

 /////////////   
parameter   AXI_DATA_WIDTH    = 128               ; //AXI Data Width(Bit)
parameter   AXI_ADDR_WIDTH = 28;
  
parameter   DDR_WRITE_FIRST   = 1'h1              ; //1:Write First ; 0: Read First   
parameter   AXI_ID_WIDTH    =   8         ;
localparam   AXI0_WR_ID        = 8'haa           ; //AXI Write ID
localparam   AXI0_RD_ID        = 8'h55           ; //AXI Read ID	

localparam SYMBOL_WIDTH   = 8;
localparam SYMBOL_NUM     = 1;
localparam PAR_PIXEL_NUM  = 8;

localparam H_FRONT_PORCH  = 13'd128 	;//	
localparam H_SYNC 	 		  = 13'd88 	;//
localparam H_VALID 	 	  	= 13'd400  ;//
localparam H_BACK_PORCH  	= 13'd128   ;// 	
localparam V_FRONT_PORCH   	= 13'd4 	;//	
localparam V_SYNC 	 	    = 13'd5 	;//
localparam V_VALID 	 	  	= 13'd9  ;//
localparam V_BACK_PORCH  	= 13'd36 	;//	

localparam WR_FIFO_DEPTH  = 1024;
localparam RD_FIFO_DEPTH  = 1024;

wire  axi0_ARQOS;         
wire  axi0_AWQOS;         
wire  [5:0] axi0_AWID;    
wire  [AXI_ADDR_WIDTH-1:0] axi0_AWADDR; 
wire  [7:0] axi0_AWLEN;   
wire  [2:0] axi0_AWSIZE;  
wire  [1:0] axi0_AWBURST; 
wire  axi0_AWVALID;       
wire  [3:0] axi0_AWCACHE; 
wire  axi0_AWCOBUF;       
wire  axi0_AWLOCK;        
wire  axi0_AWAPCMD;       
wire  axi0_AWALLSTRB;     
wire  [5:0] axi0_ARID;   
wire  [AXI_ADDR_WIDTH-1:0] axi0_ARADDR; 
wire  [7:0] axi0_ARLEN;   
wire  [2:0] axi0_ARSIZE;  
wire  [1:0] axi0_ARBURST; 
wire  axi0_ARVALID;       
wire  axi0_ARLOCK;        
wire  axi0_ARAPCMD;       
wire  axi0_WLAST;         
wire  axi0_WVALID;        
wire  [AXI_DATA_WIDTH-1:0] axi0_WDATA; 
wire  [AXI_DATA_WIDTH/8-1:0] axi0_WSTRB;  
wire  axi0_BREADY;        
wire  axi0_RREADY;        
wire axi0_AWREADY;        
wire axi0_ARREADY;        
wire axi0_WREADY;         
wire [5:0] axi0_BID;      
wire [1:0] axi0_BRESP;    
wire axi0_BVALID;         
wire [5:0] axi0_RID;      
wire axi0_RLAST;          
wire axi0_RVALID;         
wire [AXI_DATA_WIDTH-1:0] axi0_RDATA;  
wire [1:0] axi0_RRESP;   

  //Ports
  reg  clk= 0;
  reg  rst_n = 0;

  wire  hs;
  wire  vs;
  wire  de;

wire [63:0] vid_vout;
wire [63:0] cvo_vout;
  
wire                    fb_m_axis_tuser ;
wire                    fb_m_axis_tvalid;
wire                    fb_m_axis_tready;
wire                    fb_m_axis_tlast ;
wire  [64-1:0] fb_m_axis_tdata ;
wire            fifo_rd_period;
reg rd_start = 'd0;
  always #10 clk = !clk;
  assign axi0_ACLK = clk;
  initial begin
    #0  rst_n = 0;
        rd_start = 0;
    # 100 rst_n = 1;

    #1000
      rd_start = 1;
    #100
      rd_start = 0;
  end



 // ÊµÀý»¯´ý²âÄ£¿é
    video_gen_top # (
    .SYMBOL_WIDTH(8),
    .SYMBOL_NUM(1),
    .PAR_PIXEL_NUM(8),
    .MAX_WIDTH(400),
    .MAX_HEIGTH(400),

    .H_FRONT_PORCH(H_FRONT_PORCH),
    .H_SYNC(H_SYNC),
    .H_VALID(H_VALID),
    .H_BACK_PORCH(H_BACK_PORCH),
    .V_FRONT_PORCH(V_FRONT_PORCH),
    .V_SYNC(V_SYNC),
    .V_VALID(V_VALID),
    .V_BACK_PORCH(V_BACK_PORCH),
    .VSYNC_POL(1),
    .HSYNC_POL(1)

  )
  video_src_gen_inst (
    .axi_clk(clk),
    .rst_n(rst_n),
    .mode(0),
    .src_width(H_VALID),
    .src_height(V_VALID),
    // .m_axis_tdata  (m0_axis_tdata),
    // .m_axis_tvalid (m0_axis_tvalid),
    // .m_axis_tready(~m0_axis_tready),
    // .m_axis_tuser(),
    // .m_axis_tlast  (m0_axis_tlast),
    .vout (vid_vout),
    .o_hs (hs  ),
    .o_vs (vs  ),
    .o_de (de  )
  );


frame_buffer #(
.I_VID_WIDTH (64),
.O_VID_WIDTH (64),
.START_ADDR     (32'h00120        ),
.FB_NUM			    (3),   
.MAX_VID_WIDTH  (1920),		
.MAX_VID_HIGHT	(1080)	,
.BURST_LEN  	(63),
.AXI_DATA_WIDTH ( AXI_DATA_WIDTH	),
.AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH	),
.WR_FIFO_DEPTH	( WR_FIFO_DEPTH		),    
.RD_FIFO_DEPTH 	( RD_FIFO_DEPTH 	),
.O_FRAME_WIDTH (50),
.O_FRAME_HEIGHT(9)
)checker0(
    .axi_clk(axi0_ACLK),
    .rst_n(rst_n),

/*i*/.i_clk			(clk   ),// (CLK_148P5M),//	(VI_CLK3_PLL		),    //(CLK_148P5M   ),//    
/*i*/.i_vs			(vs),//(rx_vsync 			),// (sync_vs2  ),//(e3_v							),  //(sw0_vs 			),//
/*i*/.i_de			(de),//(rx_de 				),// (sync_de2  ),//(e3_de						),    //(sw0_de 			),//
/*i*/.vin 			(vid_vout),//({y_422,c_422}),//
                  
/*i*/.o_clk			  (clk	 ),//(clk_o),//
/*i*/.fifo_rd_period (fifo_rd_period),//(fifo_rd_period  ),
/*o*/.m_axis_tuser  (fb_m_axis_tuser ),
/*o*/.m_axis_tvalid (fb_m_axis_tvalid),
/*i*/.m_axis_tready (fb_m_axis_tready),
/*o*/.m_axis_tlast  (fb_m_axis_tlast ),
/*o*/.m_axis_tdata  (fb_m_axis_tdata ),
  
    .awid(axi0_AWID),
    .awaddr(axi0_AWADDR),
    .awlen(axi0_AWLEN),
    .awsize(axi0_AWSIZE),
    .awburst(axi0_AWBURST),
    .awcache(axi0_AWCACHE),
    .awlock(axi0_AWLOCK),
    .awvalid(axi0_AWVALID),
    .awcobuf(axi0_AWCOBUF),
    .awapcmd(axi0_AWAPCMD),
    .awallstrb(axi0_AWALLSTRB),
    .awready(axi0_AWREADY),
    .awqos(axi0_AWQOS),
    .arid(axi0_ARID),
    .araddr(axi0_ARADDR),
    .arlen(axi0_ARLEN),
    .arsize(axi0_ARSIZE),
    .arburst(axi0_ARBURST),
    .arlock(axi0_ARLOCK),
    .arvalid(axi0_ARVALID),
    .arapcmd(axi0_ARAPCMD),
    .arready(axi0_ARREADY),
    .arqos(axi0_ARQOS),
    .wdata(axi0_WDATA),
    .wstrb(axi0_WSTRB),
    .wlast(axi0_WLAST),
    .wvalid(axi0_WVALID),
    .wready(axi0_WREADY),
    .rid(axi0_RID),
    .rdata(axi0_RDATA),
    .rlast(axi0_RLAST),
    .rvalid(axi0_RVALID),
    .rready(axi0_RREADY),
    .rresp(axi0_RRESP),
    .bid(axi0_BID),
    .bvalid(axi0_BVALID),
    .bready(axi0_BREADY)
);



  cvo_axi # (
    .SYMBOL_WIDTH(8),
    .SYMBOL_NUM(1),
    .PIXEL_NUM(8),
    .HSYNC_POL(1'b1),
    .VSYNC_POL(1'b1),
    .FIFO_DEPTH(512),
    .FIFO_ALMOST_FULL(500)
  )
  cvo_axi_inst (
    .rst_n(rst_n),
    .fifo_rd_period(fifo_rd_period),
    .fifo_rd_underflow(fifo_rd_underflow),
    .s_axi_clk(clk),
    .s_axis_tdata (fb_m_axis_tdata ),
    .s_axis_tvalid(fb_m_axis_tvalid),
    .s_axis_tready(fb_m_axis_tready),
    .s_axis_tlast (fb_m_axis_tlast ),
    .s_axis_tuser (fb_m_axis_tuser ),
    .H_FRONT_PORCH(H_FRONT_PORCH),
    .H_SYNC(H_SYNC),
    .H_VALID(H_VALID),
    .H_BACK_PORCH(H_BACK_PORCH),
    .V_FRONT_PORCH(V_FRONT_PORCH),
    .V_SYNC(V_SYNC),
    .V_VALID(V_VALID),
    .V_BACK_PORCH(V_BACK_PORCH),

    .o_clk(clk ),
    .vout(cvo_vout),
    .o_hs(o_hs),
    .o_vs(o_vs),
    .o_de(o_de)
  );



vid_check  u_vid_check(
	/*i*/.clk		(clk ),
	/*i*/.rst_n		(rst_n),
	/*i*/.i_hs		(o_hs),
	/*i*/.i_vs		(o_vs),
	/*i*/.i_de		(o_de),
	/*i*/.vin 		({cvo_vout }),
	/*o*/.check_fail()
	
	);

axi_ram #
(
    .DATA_WIDTH            (AXI_DATA_WIDTH       ),
    .ADDR_WIDTH            (20       ),
    .ID_WIDTH              (6            ),
    .PIPELINE_OUTPUT       (0            )
)                                        
u_axi_ram
(
    .clk                   (axi0_ACLK     ),
    .rst                   (!rst_n),
    .s_axi_awid            (0     ),
    .s_axi_awaddr          (axi0_AWADDR   ), 
    .s_axi_awlen           (axi0_AWLEN   ), 
    .s_axi_awsize          (axi0_AWSIZE   ), 
    .s_axi_awburst         (axi0_AWBURST  ), 
    .s_axi_awlock          (axi0_AWLOCK   ), 
    .s_axi_awcache         (axi0_AWCACHE  ), 
    .s_axi_awprot          (axi0_AWPROT   ), 
    .s_axi_awvalid         (axi0_AWVALID  ), 
    .s_axi_awready         (axi0_AWREADY  ), 
    .s_axi_wdata           (axi0_WDATA    ), 
    .s_axi_wstrb           (axi0_WSTRB    ), 
    .s_axi_wlast           (axi0_WLAST    ), 
    .s_axi_wvalid          (axi0_WVALID   ), 
    .s_axi_wready          (axi0_WREADY   ), 
    .s_axi_bid             (axi0_BID      ),
    .s_axi_bresp           (axi0_BRESP    ), 
    .s_axi_bvalid          (axi0_BVALID   ), 
    .s_axi_bready          (axi0_BREADY   ),
    .s_axi_arid            (0     ),
    .s_axi_araddr          (axi0_ARADDR   ), 
    .s_axi_arlen           (axi0_ARLEN    ), 
    .s_axi_arsize          (axi0_ARSIZE   ), 
    .s_axi_arburst         (axi0_ARBURST  ), 
    .s_axi_arlock          (axi0_ARLOCK   ), 
    .s_axi_arcache         (axi0_ARCACHE  ), 
    .s_axi_arprot          (axi0_ARPROT   ), 
    .s_axi_arvalid         (axi0_ARVALID  ), 
    .s_axi_arready         (axi0_ARREADY  ),
    .s_axi_rid             (axi0_RID      ),
    .s_axi_rdata           (axi0_RDATA    ), 
    .s_axi_rresp           (axi0_RRESP    ), 
    .s_axi_rlast           (axi0_RLAST    ), 
    .s_axi_rvalid          (axi0_RVALID   ), 
    .s_axi_rready          (axi0_RREADY   )
);






endmodule

