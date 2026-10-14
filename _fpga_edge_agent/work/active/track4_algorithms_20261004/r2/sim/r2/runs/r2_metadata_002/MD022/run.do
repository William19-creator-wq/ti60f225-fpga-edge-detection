onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_canny_stream_top/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_canny_stream_top/clk /tb_canny_stream_top/rst /tb_canny_stream_top/cancel /tb_canny_stream_top/in_valid /tb_canny_stream_top/in_ready /tb_canny_stream_top/class_valid /tb_canny_stream_top/class_ready /tb_canny_stream_top/grad_valid /tb_canny_stream_top/grad_ready /tb_canny_stream_top/status_valid /tb_canny_stream_top/status_ready /tb_canny_stream_top/status_payload /tb_canny_stream_top/dut/g_metadata /tb_canny_stream_top/dut/s_input_q /tb_canny_stream_top/dut/s_input_row /tb_canny_stream_top/dut/event_fire /tb_canny_stream_top/dut/data_flush /tb_canny_stream_top/dut/sobel_window/rd_addr /tb_canny_stream_top/dut/sobel_window/rd_en
run -all
quit -code 1
