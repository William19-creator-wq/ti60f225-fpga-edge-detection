create_clock -name core_clk -period 10.000 [get_ports clk]
# 内部组件综合目标；生产时钟/引脚和真实布线时序随后在board top验证。
