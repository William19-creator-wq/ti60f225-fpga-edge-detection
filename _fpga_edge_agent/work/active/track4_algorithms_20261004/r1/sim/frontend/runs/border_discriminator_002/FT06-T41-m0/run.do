onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_frontend_frame_pair/check/done} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_frontend_frame_pair/check/clk /tb_frontend_frame_pair/check/out_valid /tb_frontend_frame_pair/check/out_ready /tb_frontend_frame_pair/check/out_y_pair /tb_frontend_frame_pair/check/out_edge /tb_frontend_frame_pair/check/g_frontend/dut/unused_l1
run -all
quit -code 1
