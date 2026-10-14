create_clock -name core_25m -period 40 -waveform {0 20} {clk_25m}

set_false_path -from [get_ports {key1_n}] -to [get_pins {reset_adapter/reset_release_stage1~FF|SR}]set_false_path -from [get_ports {key1_n}] -to [get_pins {reset_adapter/reset_release_stage2~FF|SR}]set_false_path -to [get_ports {led0}]set_false_path -to [get_ports {led1}]