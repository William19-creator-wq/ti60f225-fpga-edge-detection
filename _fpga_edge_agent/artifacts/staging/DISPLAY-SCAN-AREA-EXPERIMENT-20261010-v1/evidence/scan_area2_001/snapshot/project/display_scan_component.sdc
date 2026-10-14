create_clock -name core_clock -period 10.000 [get_ports core_clk]
create_clock -name video_clock -period 13.468 [get_ports video_clk]
set_clock_groups -asynchronous -group [get_clocks core_clock] -group [get_clocks video_clock]
