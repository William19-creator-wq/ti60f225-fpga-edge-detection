# 仅用于真实pin诊断；无批准例外，不可用于Bit/release gate。
create_clock -name core_25m -period 40.000 [get_ports {clk_25m}]
