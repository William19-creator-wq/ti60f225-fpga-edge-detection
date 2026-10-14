

module frame_info_det #(
	parameter I_VID_WIDTH = 16,
	parameter SIM_EN = 1'b1,
	parameter AXI_DDR_WIDTH = 256

)(
input		wire									clk	,    
input		wire									rst_n,
input		wire									i_vs, //active hgih
input     	wire 									i_hs,
input		wire									i_de, //active high
input      	wire [I_VID_WIDTH-1:0]					i_data,

output reg			[23:0]							frame_pix_num_o,
output reg											frame_stable,
output wire											frame_start,
output reg  [31:0] 									ddr_frame_len,
output reg   										o_pixel_start = 'd0,
output reg   										o_pixel_end = 'd0,
output wire   										fifo_rst_p,
output reg  										o_valid,
output reg  			[I_VID_WIDTH-1:0] 			o_data
);
localparam  VID_DATA_BYTE = I_VID_WIDTH/8;
localparam  AXI_DATA_BYTE = AXI_DDR_WIDTH/8;
  
  reg												vs_r0 = 1'b0;
  wire 												neg_vs;
  wire												pos_vs;
  reg						[1:0]					frame_num = 'd0;  
  reg						[23:0]				frame_pix_num = 'd0; 
  reg						[23:0] 				frame_len_d0 = 'd0;
  reg						[23:0] 				frame_len_d1 = 'd0; 
  reg						[23:0] 				frame_len_d2 = 'd0; 
  reg [31:0] 									total_frame_bytes = 'd0;
  reg  											negtive_sync = 'd0;
  always @( posedge clk )
  begin
		if( i_de ) begin
			if( i_vs )
				negtive_sync <= 1'b1;
			else
				negtive_sync = 1'b0;
		end
  end 

  always @( posedge clk )
  begin
  		vs_r0 	<= i_vs;  
		o_valid 	<= i_de; 
		o_data  <= i_data;
  end
  assign neg_vs = {vs_r0,i_vs} == 2'b10;   //video start
  assign pos_vs = {vs_r0,i_vs} == 2'b01;	 //video end
  
  wire w_frame_start = (~negtive_sync & neg_vs ) || (negtive_sync & pos_vs );
  wire w_frame_end   = (~negtive_sync & pos_vs ) || (negtive_sync & neg_vs ) ;

assign frame_start = w_frame_start;

  always @( posedge clk or negedge rst_n )
  begin
		if( ~rst_n )
			frame_pix_num <= 'd0;
		else if( w_frame_start ) 
			frame_pix_num <= 'd0;
		else if( i_de )
			frame_pix_num <= frame_pix_num + 1'b1;
  					
  end

  always @( posedge clk or negedge rst_n )
  begin
  		if( ~rst_n )
			frame_pix_num_o <= 'd0;
		else if( w_frame_end ) 
			frame_pix_num_o <= frame_pix_num;
  end
reg pixel_start_en = 'd0;
  always @( posedge clk or negedge rst_n )
  begin
		if( !rst_n )
			pixel_start_en <= 1'b0;
		else if( w_frame_start )
			pixel_start_en <= 1'b1;
		else if( i_de) 
			pixel_start_en <= 1'b0;
  end
wire pixel_start = pixel_start_en & i_de & frame_stable;
wire pixel_end = frame_pix_num == frame_pix_num_o-1 && frame_stable;
reg [2:0] fifo_rst_r = 'd0;
always @( posedge clk )
begin
	fifo_rst_r <=  {fifo_rst_r[1:0],w_frame_start};
end

assign fifo_rst_p = |fifo_rst_r;//pixel_start_en ;//pixel_start;
always @( posedge clk )
begin
	o_pixel_start <= pixel_start;
	o_pixel_end <= pixel_end;
end


reg frame_end_r0 = 'd0;
reg frame_end_r1 = 'd0;
  always @( posedge clk or negedge rst_n )
  begin
		if( !rst_n ) begin
			frame_end_r0 <= 'd0;
			frame_end_r1 <= 'd0;
		end else begin
			frame_end_r0 <= w_frame_end ;
			frame_end_r1 <= frame_end_r0;
		end
  end

  always @( posedge clk or negedge rst_n )
  begin
  		if( !rst_n ) begin
			frame_len_d0 <= 'd0; 
			frame_len_d1 <= 'd0; 
			frame_len_d2 <= 'd0; 
  		end else if( frame_end_r0 ) begin
			frame_len_d0 <= frame_end_r0;//frame_pix_num;
			frame_len_d1 <= frame_len_d0;
			frame_len_d2 <= frame_len_d1;
  		end
  end



  always @( posedge clk or negedge rst_n )
  begin
  		if( !rst_n ) begin
			frame_stable <= 1'b0;
		end else if( frame_end_r1 ) begin
			if( frame_len_d0 == frame_len_d1)// && frame_len_d0 == frame_len_d2 )
					frame_stable <= 1'b1;
			else
					frame_stable <= 1'b0;
		end
  end
  always @( posedge clk or negedge rst_n )
  begin
		if( !rst_n )
			total_frame_bytes = frame_pix_num * VID_DATA_BYTE;
		else if(w_frame_end)
			total_frame_bytes = frame_pix_num * VID_DATA_BYTE;
  end

  wire  [31:0] 									w_frame_len;
  generate
	if( AXI_DDR_WIDTH == 64 ) begin 
		assign w_frame_len = {3'd0,total_frame_bytes[31:3] + |total_frame_bytes[2:0]};
	end else if( AXI_DDR_WIDTH  == 128 ) begin
		assign w_frame_len = {4'd0,total_frame_bytes[31:4] + |total_frame_bytes[3:0]};
	end else if(AXI_DDR_WIDTH  == 256 ) begin 
		assign w_frame_len = {5'd0,{total_frame_bytes[31:5] + |total_frame_bytes[4:0]}};
	end else if(AXI_DDR_WIDTH  == 512 ) begin 
		assign w_frame_len = total_frame_bytes[31:6] + |total_frame_bytes[5:0];
	end 
  endgenerate


  always @( posedge clk )
			ddr_frame_len <= w_frame_len;//{6'd0,{total_frame_bytes[31:6] + |total_frame_bytes[5:0]}};
  

endmodule