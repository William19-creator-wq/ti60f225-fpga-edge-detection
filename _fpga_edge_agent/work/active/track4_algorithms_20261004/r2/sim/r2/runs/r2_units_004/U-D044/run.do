onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_gradient_direction_pair/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_gradient_direction_pair/clk /tb_gradient_direction_pair/rst /tb_gradient_direction_pair/in_valid /tb_gradient_direction_pair/in_ready /tb_gradient_direction_pair/out_valid /tb_gradient_direction_pair/out_ready
run -all
quit -code 1
