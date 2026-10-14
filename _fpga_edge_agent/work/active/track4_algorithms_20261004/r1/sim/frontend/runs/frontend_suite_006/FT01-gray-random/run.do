onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_rgb_to_y_pair/check/done} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_rgb_to_y_pair/check/clk /tb_rgb_to_y_pair/check/rst /tb_rgb_to_y_pair/check/in_valid /tb_rgb_to_y_pair/check/in_ready /tb_rgb_to_y_pair/check/out_valid /tb_rgb_to_y_pair/check/out_ready /tb_rgb_to_y_pair/check/actual_value /tb_rgb_to_y_pair/check/phase_present /tb_rgb_to_y_pair/check/input_index /tb_rgb_to_y_pair/check/output_index
run -all
quit -code 1
