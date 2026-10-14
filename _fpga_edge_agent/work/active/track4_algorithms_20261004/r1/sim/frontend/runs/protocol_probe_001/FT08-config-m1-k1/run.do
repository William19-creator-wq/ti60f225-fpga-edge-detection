onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_frontend_frame_pair/check/done} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_frontend_frame_pair/check/clk /tb_frontend_frame_pair/check/frontend_all_empty /tb_frontend_frame_pair/check/status_valid /tb_frontend_frame_pair/check/status_ready /tb_frontend_frame_pair/check/phase_present
run -all
quit -code 1
