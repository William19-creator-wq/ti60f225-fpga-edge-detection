onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_gaussian5x5_pair/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_gaussian5x5_pair/clk /tb_gaussian5x5_pair/rst /tb_gaussian5x5_pair/in_valid /tb_gaussian5x5_pair/in_ready /tb_gaussian5x5_pair/out_valid /tb_gaussian5x5_pair/out_ready
run -all
quit -code 1
