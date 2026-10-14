# RS01..06：单video域组件目标；生产引脚/物理CDC/总STA由最终top闭合。
create_clock -name video_clock -period 13.468 [get_ports {video_clk}]
