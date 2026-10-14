onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_sobel_pair/check/done} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_sobel_pair/check/clk /tb_sobel_pair/check/rst /tb_sobel_pair/check/in_valid /tb_sobel_pair/check/in_ready /tb_sobel_pair/check/out_valid /tb_sobel_pair/check/out_ready /tb_sobel_pair/check/actual_value /tb_sobel_pair/check/phase_present /tb_sobel_pair/check/input_index /tb_sobel_pair/check/output_index
run -all
quit -code 1
