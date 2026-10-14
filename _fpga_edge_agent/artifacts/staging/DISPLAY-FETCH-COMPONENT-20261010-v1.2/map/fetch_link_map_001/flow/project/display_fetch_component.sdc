# FC01..07 component target; board pins/physical CDC/STA are final integration work.
create_clock -name core_clock -period 10.000 [get_ports {core_clk}]
create_clock -name video_clock -period 13.468 [get_ports {video_clk}]
