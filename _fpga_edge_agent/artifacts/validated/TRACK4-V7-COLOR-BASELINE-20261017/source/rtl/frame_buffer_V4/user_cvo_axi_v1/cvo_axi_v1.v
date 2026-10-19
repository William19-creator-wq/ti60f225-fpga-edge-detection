
	module cvo_axi #(
	parameter SYMBOL_WIDTH      = 8,            // Bits per color component
    parameter SYMBOL_NUM   		= 2,            // Parallel pixels: 1, 2, 4, 8
    parameter PIXEL_NUM     	= 0,            // 0:RGB, 1:YUV444, 2:YUV422
    parameter HSYNC_POL         = 1,            // H sync polarity (0=active low, 1=active high)
    parameter VSYNC_POL         = 1,            // V sync polarity (0=active low, 1=active high)
    parameter FIFO_DEPTH        = 512,          // FIFO buffer depth
    parameter FIFO_ALMOST_FULL  = 500,          // FIFO almost full threshold
	parameter MAX_H_VALID       = 1920,
    parameter MAX_V_VALID       = 1080,
    // Derived parameters
    parameter DATA_WIDTH        = SYMBOL_WIDTH * PIXEL_NUM * SYMBOL_NUM
			
			
	)(
	input		wire									o_clk,
	input		wire									rst_n,
	
	output		reg										fifo_rd_period = 'd0,     
	output		reg										fifo_rd_underflow = 'd0,

	 //------------------------------------------------------------------------
    // AXI Stream Input (Standard Video Interface)
    //------------------------------------------------------------------------
	input  wire 										s_axi_clk,
    input  wire [DATA_WIDTH-1:0]            			s_axis_tdata,   // Pixel data
    input  wire                             			s_axis_tvalid,  // Data valid
    output wire                             			s_axis_tready,  // Ready to accept
    input  wire                             			s_axis_tlast,   // End of line (EOL)
    input  wire                             			s_axis_tuser,   // Start of frame (SOF)
	
	input		wire 	[12:0]							H_FRONT_PORCH 	,
	input		wire 	[12:0]							H_SYNC 			,
	input		wire 	[12:0]							H_VALID 		,
	input		wire 	[12:0]							H_BACK_PORCH 	,
	input		wire 	[12:0]							V_FRONT_PORCH 	,
	input		wire 	[12:0]							V_SYNC 			,
	input		wire 	[12:0]							V_VALID 		,
	input		wire 	[12:0]							V_BACK_PORCH 	,
	
	
	output		 	[DATA_WIDTH-1:0] 					vout ,
	output		reg										o_hs = 'd0,
	output		reg										o_vs = 'd0,
	output		reg										o_de = 'd0
	
	);
//==========================================================
//
//==========================================================
	
	localparam S_H_SYNC 		= 2'd0;
	localparam S_H_BACK_PORCH 	= 2'd1;
	localparam S_H_VALID 		= 2'd2;
	localparam S_H_FRONT_PORCH 	= 2'd3;
	localparam S_V_SYNC 		= 2'd0;
	localparam S_V_BACK_PORCH 	= 2'd1;
	localparam S_V_VALID 		= 2'd2;
	localparam S_V_FRONT_PORCH 	= 2'd3;
	localparam FIFO_ADDR_WIDTH   = $clog2(FIFO_DEPTH) ;
	
	wire									fifo_wr_rst ;
	wire	[FIFO_ADDR_WIDTH:0] 					wrusedw;
	//wire 
	wire	[DATA_WIDTH-1:0] fifo_rd_data;
	wire										fifo_rd_en;
	wire									fifo_rd_empty;
	reg	[1:0] 						h_state = S_H_FRONT_PORCH;
	reg	[1:0] 						v_state = S_V_FRONT_PORCH;
	reg	[12:0] 						h_cnt = 0;
	reg	[12:0] 						v_cnt = 0;
	reg										frame_start_d0 = 1'b0;
	reg										frame_start_d1 = 1'b0;
	// wire									pos_frame_start;
	reg										frame_ena			 = 1'b0;
	reg										h_front_porch_flag 	= 1'b0;
	reg										h_sync_flag				= 1'b0;
	reg										h_valid_flag			= 1'b0;
	reg										h_back_porch_flag = 1'b0;
	    									
	reg										v_front_porch_flag 	= 1'b0;
	reg										v_sync_flag				= 1'b0;
	reg										v_valid_flag			= 1'b0;
	reg										v_back_porch_flag = 1'b0;
	wire									fifo_rst					;
	wire									pos_fifo_rd_period;
	reg [3:0] 								sync_frame_start;
	reg										fifo_rd_period_d0 = 1'b0;
	reg [15:0] axi_v_cnt = 'd0;
	reg   		axi_en = 'd0;
	reg										fifo_wr_almost_full = 'd0;
//==========================================================
//
//==========================================================

		always @( posedge s_axi_clk )
	begin
			sync_frame_start <= {sync_frame_start[2:0],fifo_rd_period_d0};
			if( sync_frame_start[3:2] == 2'b10)//negedge
				axi_en <= 1'b1;
			else if( s_axis_tready && s_axis_tvalid && s_axis_tlast && axi_v_cnt ==V_VALID-1 )
				axi_en <= 1'b0;
		
	end

	always @( posedge s_axi_clk or negedge rst_n )
	begin
		if( !rst_n )
			axi_v_cnt <= 'd0;
		else if( s_axis_tuser & s_axis_tready )
			axi_v_cnt <= 'd0;
		else if( s_axis_tready && s_axis_tvalid && s_axis_tlast ) 
			axi_v_cnt <= axi_v_cnt + 1'b1;
	end
	
	always @( posedge s_axi_clk or negedge rst_n )
	begin
			if( !rst_n )
					fifo_wr_almost_full <= 1'b1;
			else if( wrusedw >= FIFO_ALMOST_FULL ) begin
					fifo_wr_almost_full <= 1'b1;
			end else begin
					fifo_wr_almost_full <= 1'b0;
			end
	end
	assign s_axis_tready = (~fifo_wr_almost_full) && axi_en;



	assign fifo_wr_rst = ~rst_n || fifo_rst;////fifo_rst_p //pos_frame_start | 
	

   wire axi_data_valid = s_axis_tvalid & s_axis_tready;

DC_FIFO
# (
  	.FIFO_MODE  ( "Normal"        	), //"Normal"; //"ShowAhead"
    .DATA_WIDTH ( DATA_WIDTH        ),
    .FIFO_DEPTH ( FIFO_DEPTH        )//,

  ) u_rd_fifo(   
  //System Signal
  /*i*/.Reset   (fifo_wr_rst), //System Reset
  //Write Signal                             
  /*i*/.WrClk   (s_axi_clk ), //(I)Wirte Clock
  /*i*/.WrEn    (axi_data_valid), //(I)Write Enable
  /*o*/.WrDNum  (wrusedw), //(O)Write Data Number In Fifo
  /*o*/.WrFull  (), //(I)Write Full 
  /*i*/.WrData  (s_axis_tdata), //(I)Write Data
  //Read Signal                            
  /*i*/.RdClk   (o_clk), //(I)Read Clock
  /*i*/.RdEn    (fifo_rd_en), //(I)Read Enable
  /*o*/.RdDNum  (), //(O)Radd Data Number In Fifo
  /*o*/.RdEmpty (fifo_rd_empty), //(O)Read FifoEmpty
  /*o*/.RdData  (fifo_rd_data)  //(O)Read Data
);               

always @( posedge o_clk or negedge rst_n )
begin
		if( !rst_n )
				fifo_rd_underflow <= 1'b0;    
		else if( fifo_rd_empty & fifo_rd_en )
				fifo_rd_underflow <= 1'b1;
		else 
				fifo_rd_underflow <= 1'b0;
end


//=========================================================
//
//=========================================================
always @( posedge o_clk or negedge rst_n )
begin
	if( !rst_n )
		frame_ena <= 1'b0;
	else if( fifo_rd_empty & fifo_rd_en )
		frame_ena <= 1'b0;
	else// if( ~fifo_rd_empty )
		frame_ena <= 1'b1;
end
	
	always @( posedge o_clk or negedge rst_n)
	begin
			if( !rst_n )
					  h_front_porch_flag <= 1'b0;
			else if( !frame_ena)
						h_front_porch_flag <= 1'b0;
			else if( h_cnt == H_FRONT_PORCH -2 )
						h_front_porch_flag <= 1'b1;
			else
						h_front_porch_flag <= 1'b0;
	end
	
	always @( posedge o_clk or negedge rst_n )
	begin
			if( !rst_n )
						h_sync_flag <= 1'b0;
			else if( !frame_ena )
						h_sync_flag <= 1'b0;
			else if( h_cnt == H_SYNC -2 )
						h_sync_flag <= 1'b1;
			else
						h_sync_flag <= 1'b0;
	end
	
	always @( posedge o_clk or negedge rst_n )
	begin
			if( !rst_n )
						h_valid_flag <= 1'b0;
			else if( !frame_ena )
						h_valid_flag <= 1'b0;
			else if( h_cnt == H_VALID -2 )
						h_valid_flag <= 1'b1;
			else
						h_valid_flag <= 1'b0;
	end
	
	always @( posedge o_clk or negedge rst_n )
	begin
			if( !rst_n )
						h_back_porch_flag <= 1'b0;
			else if( !frame_ena )
						h_back_porch_flag <= 1'b0;
			else if( h_cnt == H_BACK_PORCH -2 )
						h_back_porch_flag <= 1'b1;
			else
						h_back_porch_flag <= 1'b0;
	end
	
	

	always @( posedge o_clk or negedge rst_n )
	begin
			if( ~rst_n ) begin
					h_cnt <= 'd0;
					h_state <= S_H_SYNC;
			end else if( frame_ena ) begin
					case(h_state )
					S_H_SYNC : begin
							if( h_sync_flag ) begin
									h_cnt <= 0;
									h_state <= S_H_BACK_PORCH;
							end else begin
									h_cnt <= h_cnt + 1'b1;
							end
					end
					S_H_BACK_PORCH : begin
							if( h_back_porch_flag ) begin
									h_cnt <= 0;
									h_state <= S_H_VALID;
							end else begin
									h_cnt <= h_cnt + 1'b1;
							end
					end
					
					
					S_H_VALID : begin
							if( h_valid_flag ) begin
									h_cnt <= 0;
									h_state <= S_H_FRONT_PORCH;
							end else begin
									h_cnt <= h_cnt + 1'b1;
							end
					end
					S_H_FRONT_PORCH : begin
									if( h_front_porch_flag ) begin
											h_cnt <= 0;
											h_state <= S_H_SYNC;
									end else begin
											h_cnt <= h_cnt + 1'b1;
									end
					end
					
					default: begin
							h_state <= S_H_SYNC;
							h_cnt <= 'd0;
					end
					endcase
			end else begin
					h_cnt <= 'd0;
					h_state <= S_H_SYNC;
			end
	end            
	
	always @( posedge o_clk or negedge rst_n )
	begin
			if( !rst_n )
					v_front_porch_flag <= 1'b0;
			else if(!frame_ena )
					v_front_porch_flag <= 1'b0;
			else if( v_cnt == V_FRONT_PORCH - 1  )
					v_front_porch_flag <= 1'b1;
			else
					v_front_porch_flag <= 1'b0;		
	end
	
	always @( posedge o_clk or negedge rst_n )
	begin
			if( !rst_n )
					v_sync_flag <= 1'b0;
			else if(!frame_ena )
					v_sync_flag <= 1'b0;
			else if( v_cnt == V_SYNC - 1  )
					v_sync_flag <= 1'b1;
			else
					v_sync_flag <= 1'b0;		
	end
	
	always @( posedge o_clk or negedge rst_n )
	begin
			if( !rst_n )
						v_valid_flag <=  1'b0;
			else if(!frame_ena )
						v_valid_flag <=  1'b0;			
			else if( v_cnt == V_VALID -1  )
						v_valid_flag <= 1'b1;
			else
						v_valid_flag <= 1'b0;
	end
	
	always @( posedge o_clk or negedge rst_n)
	begin
			if( !rst_n )
						v_back_porch_flag <= 1'b0;
			else if(!frame_ena )
						v_back_porch_flag <= 1'b0;	
			else if( v_cnt == V_BACK_PORCH -1  )
						v_back_porch_flag <= 1'b1;
			else
						v_back_porch_flag <= 1'b0;
	end
	
	always @( posedge o_clk or negedge rst_n )
	begin
			if( ~rst_n ) begin
					v_cnt <= 'd0;
					v_state <= S_V_SYNC;	
			end else if( frame_ena ) begin
						case(v_state )
						S_V_SYNC : begin
								if( h_front_porch_flag && h_state == S_H_FRONT_PORCH ) begin
										if( v_sync_flag ) begin
												v_cnt <= 0;
												v_state <= S_V_BACK_PORCH;
										end else begin
												v_cnt <= v_cnt + 1'b1;
										end
								end
						end
						S_V_BACK_PORCH : begin
								if( h_front_porch_flag && h_state == S_H_FRONT_PORCH ) begin
										if( v_back_porch_flag ) begin
												v_cnt <= 0;
												v_state <= S_V_VALID;
										end else begin
												v_cnt <= v_cnt + 1'b1;
										end
								end
						end
						
						
						S_V_VALID : begin
								if( h_front_porch_flag && h_state == S_H_FRONT_PORCH ) begin
										if( v_valid_flag ) begin
												v_cnt <= 0;
												v_state <= S_V_FRONT_PORCH;
										end else begin
												v_cnt <= v_cnt + 1'b1;
										end
								end
						end
						S_V_FRONT_PORCH : begin
								if( h_front_porch_flag && h_state == S_H_FRONT_PORCH ) begin   
										if(v_front_porch_flag ) begin
												v_cnt <= 0;
												v_state <= S_V_SYNC;
										end else begin
												v_cnt <= v_cnt + 1'b1;
										end
								end
						end
						default: begin
								v_state <= S_V_SYNC;
								v_cnt <= 'd0;
						end
						endcase
			end else begin
					v_cnt <= 'd0;
					v_state <= S_V_SYNC;	
			end
	end

	assign fifo_rd_en =  ( h_state == S_H_VALID && v_state == S_V_VALID);
	
	assign vout = fifo_rd_data;//
	
	always @( posedge o_clk )
	begin
			o_de <= (h_state == S_H_VALID && v_state == S_V_VALID );
	end
	always @( posedge o_clk or negedge rst_n)
	begin
			if( ~rst_n ) begin
					o_vs  <= 'd0;
					
			end else if( frame_ena ) begin
					o_vs <= VSYNC_POL ? (v_state == S_V_SYNC) : (v_state == ~S_V_SYNC);
			end else begin
					o_vs  <= 'd0;
			end
	end
	
	always @( posedge o_clk or negedge rst_n )
	begin
			if( ~rst_n ) begin
					o_hs  <= 'd0;
			end else if( frame_ena )begin
					o_hs <= HSYNC_POL? (h_state == S_H_SYNC) : (h_state == ~S_H_SYNC);
			end else begin
					o_hs  <= 'd0;
			end
	end         
	
	always @( posedge o_clk )
	begin
			fifo_rd_period <=  v_state == S_V_SYNC;
	end
	
	always @( posedge o_clk )
			fifo_rd_period_d0 <= fifo_rd_period;
	
	assign pos_fifo_rd_period = ~fifo_rd_period_d0 & fifo_rd_period;   
	assign fifo_rst = pos_fifo_rd_period;


	
	endmodule
	
	

