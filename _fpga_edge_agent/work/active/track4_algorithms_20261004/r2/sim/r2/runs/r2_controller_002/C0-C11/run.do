onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_canny_stream_controller/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_canny_stream_controller/clk /tb_canny_stream_controller/rst /tb_canny_stream_controller/cancel /tb_canny_stream_controller/cj_valid /tb_canny_stream_controller/cj_ready /tb_canny_stream_controller/fj_valid /tb_canny_stream_controller/fj_ready /tb_canny_stream_controller/fs_valid /tb_canny_stream_controller/fs_ready /tb_canny_stream_controller/derr_valid /tb_canny_stream_controller/derr_ready /tb_canny_stream_controller/event_fire /tb_canny_stream_controller/data_flush /tb_canny_stream_controller/status_valid /tb_canny_stream_controller/status_ready /tb_canny_stream_controller/status_payload
run -all
quit -code 1
