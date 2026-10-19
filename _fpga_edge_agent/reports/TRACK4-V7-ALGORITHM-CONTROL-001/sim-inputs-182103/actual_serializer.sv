module actual_serializer(input wire hdmi_tx_slow_clk,rgb_vs,rgb_hs,rgb_de,
input wire [47:0] rgb_datax2,output wire [23:0] actual_rgb,
output wire actual_vs,actual_hs,actual_de);
wire pos_vs;
reg rgb_vs_r = 'd0;
always @( posedge hdmi_tx_slow_clk )
begin
  rgb_vs_r <= rgb_vs;
end
assign pos_vs = {rgb_vs_r,rgb_vs} == 2'b01;
reg vid_cnt = 'd0;
reg [7:0] hdmi_tx_rdata ;
reg [7:0] hdmi_tx_gdata ;
reg [7:0] hdmi_tx_bdata ;
reg hdmi_tx_vs;
reg hdmi_tx_hs;
reg hdmi_tx_de;
always @( posedge hdmi_tx_slow_clk )
begin
    if( pos_vs )
      vid_cnt <= 1'b1;
    else if( rgb_de )
      vid_cnt <= ~vid_cnt ;

    if( vid_cnt )
      {hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata} <= rgb_datax2[23:0];
    else 
      {hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata} <= rgb_datax2[47:24];

  hdmi_tx_vs <= rgb_vs;
  hdmi_tx_hs <= rgb_hs;
  hdmi_tx_de <= rgb_de;
end

assign actual_rgb={hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata};
assign actual_vs=hdmi_tx_vs;assign actual_hs=hdmi_tx_hs;assign actual_de=hdmi_tx_de;
endmodule
