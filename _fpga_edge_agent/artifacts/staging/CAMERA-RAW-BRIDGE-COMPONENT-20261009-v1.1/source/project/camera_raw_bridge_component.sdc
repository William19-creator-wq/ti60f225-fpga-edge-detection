create_clock -name core_clk -period 10.000 [get_ports core_clk]
create_clock -name pixel_clk -period 20.000 [get_ports pixel_clk]
# Component MAP. Production CDC max-delay/skew, PNR/STA and IO remain for integration.
