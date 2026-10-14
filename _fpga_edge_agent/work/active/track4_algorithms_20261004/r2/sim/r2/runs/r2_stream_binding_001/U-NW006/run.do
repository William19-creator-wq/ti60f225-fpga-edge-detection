onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_nms_window_pair/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_nms_window_pair/clk /tb_nms_window_pair/rst /tb_nms_window_pair/in_valid /tb_nms_window_pair/in_ready /tb_nms_window_pair/out_valid /tb_nms_window_pair/out_ready
run -all
quit -code 1
