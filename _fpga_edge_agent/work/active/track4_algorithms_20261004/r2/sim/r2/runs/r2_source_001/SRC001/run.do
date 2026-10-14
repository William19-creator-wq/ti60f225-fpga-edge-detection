onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_r2_pattern_pair_source/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_r2_pattern_pair_source/clk /tb_r2_pattern_pair_source/rst /tb_r2_pattern_pair_source/in_valid /tb_r2_pattern_pair_source/in_ready /tb_r2_pattern_pair_source/out_valid /tb_r2_pattern_pair_source/out_ready
run -all
quit -code 1
