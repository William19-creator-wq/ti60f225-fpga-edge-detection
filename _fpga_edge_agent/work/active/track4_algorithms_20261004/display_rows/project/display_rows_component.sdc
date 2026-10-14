# DR01..07 component MAP targets; full board CDC/pins/STA remain integration work.
create_clock -name core_clock -period 10.000 [get_ports {core_clk}]
create_clock -name video_clock -period 13.468 [get_ports {video_clk}]
