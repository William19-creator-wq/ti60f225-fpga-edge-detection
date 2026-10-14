# FP08 component MAP target only; board IO/CDC/STA still unverified.
create_clock -name core_clk -period 10.000 [get_ports core_clk]
