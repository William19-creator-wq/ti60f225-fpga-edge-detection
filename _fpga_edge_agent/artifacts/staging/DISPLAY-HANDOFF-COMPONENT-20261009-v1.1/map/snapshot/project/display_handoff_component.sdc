# DH08: component MAP targets; full production CDC and board pins remain integration work.
create_clock -name core_clock -period 10.000 [get_ports {core_clk}]
create_clock -name video_clock -period 13.468 [get_ports {video_clk}]
