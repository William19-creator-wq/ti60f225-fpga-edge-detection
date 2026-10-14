# SC-T07：组件预综合目标时钟；无生产引脚/CDC例外，不据此宣称布线时序通过。
create_clock -name cache_core -period 10.000 [get_ports {clk}]