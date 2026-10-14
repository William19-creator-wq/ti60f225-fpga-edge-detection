# Component-only clock; no physical board timing assertion
create_clock -name core_clk -period 10.000 [get_ports {clk}]
