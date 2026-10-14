onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_window3x3_pair/check/done} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_window3x3_pair/check/clk /tb_window3x3_pair/check/rst /tb_window3x3_pair/check/in_valid /tb_window3x3_pair/check/in_ready /tb_window3x3_pair/check/out_valid /tb_window3x3_pair/check/out_ready /tb_window3x3_pair/check/actual_value /tb_window3x3_pair/check/phase_present /tb_window3x3_pair/check/input_index /tb_window3x3_pair/check/output_index
log /tb_window3x3_pair/check/g_window/dut/rd_en /tb_window3x3_pair/check/g_window/dut/rd_addr /tb_window3x3_pair/check/g_window/dut/recent_wr_en /tb_window3x3_pair/check/g_window/dut/older_wr_en /tb_window3x3_pair/check/g_window/dut/pending_q /tb_window3x3_pair/check/g_window/dut/replay_phase
run -all
quit -code 1
