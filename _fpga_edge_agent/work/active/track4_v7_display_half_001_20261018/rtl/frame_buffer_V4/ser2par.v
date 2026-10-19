

module ser2par #(
	parameter I_VID_WIDTH = 64,
    parameter I_MUX  = 8,
	parameter O_VID_WIDTH = I_VID_WIDTH*I_MUX
	 
)(
input		wire										clk		,    
input		wire										rst_n	,
input       wire                                        i_valid,
input		wire	[I_VID_WIDTH-1:0] 					i_data,
input		wire										i_start	, //active hgih
input		wire										i_end	, //active high


output		wire										    o_valid,
output		wire	[O_VID_WIDTH-1:0]					o_data 


);
localparam IN_CNT_WIDTH = $clog2(I_MUX);
//==================================================================================

reg [O_VID_WIDTH-1:0] par_pix_data = 'd0;
reg [IN_CNT_WIDTH-1:0] r_in_cnt = 'd0;
reg [IN_CNT_WIDTH-1:0] w_in_cnt;
reg last_shift = 'd0;
// reg last_shift_r = 'd0;
reg start_cycle = 'd0;
always @( posedge clk or negedge rst_n )
begin 
    if( !rst_n ) begin
        par_pix_data <= 'd0;
    end else if( i_valid |last_shift)
        par_pix_data <= {par_pix_data[O_VID_WIDTH-I_VID_WIDTH-1:0],i_data};
end 

always @( posedge clk or negedge rst_n )
begin
    if( !rst_n )
        r_in_cnt <= 'd0;
    else 
        r_in_cnt <= w_in_cnt ;
end

always @(*)
begin
    if( i_start )
        w_in_cnt = 'd1;
    else if( r_in_cnt == I_MUX-1 & i_valid)
        w_in_cnt = 'd0;
    else if( i_valid | last_shift)
        w_in_cnt = r_in_cnt + 1'b1;
    else 
        w_in_cnt = r_in_cnt;
end


reg w_o_valid= 1'b0;
always @( posedge clk )
begin
    // last_shift_r <= last_shift;
    if( i_end && r_in_cnt != I_MUX-1 )
        last_shift <= 1'b1;
    else if(w_o_valid)//( r_in_cnt == I_MUX-1)
        last_shift <= 1'b0;
end

always@( posedge clk )
begin

  if( r_in_cnt == I_MUX-1 && ( i_valid |last_shift))
        w_o_valid <=  1'b1;
  else 
        w_o_valid <= 1'b0;
end
 
//  assign    w_o_valid =  r_in_cnt == I_MUX-1;//(~i_start) && (~|r_in_cnt) && (i_valid | last_shift);//last_shift_r);

 assign    o_data = par_pix_data;
 assign    o_valid = w_o_valid;

endmodule

