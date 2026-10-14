create_clock -name video_wr_clk -period 14.286 [get_ports wr_clk]
create_clock -name core_rd_clk -period 10.000 [get_ports rd_clk]
# Component MAP targets only. Production Gray source-to-first-sync delay/skew and CDC/PNR/STA remain open.
