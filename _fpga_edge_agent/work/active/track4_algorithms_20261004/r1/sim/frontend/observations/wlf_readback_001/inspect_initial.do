onerror {quit -code 1}
echo DATASETS
dataset list
echo SCOPE
find signals /*
echo ONE
examine -time {84 ns} -radix unsigned /tb_window3x3_pair/check/g_window/dut/rd_en /tb_window3x3_pair/check/g_window/dut/recent_wr_en /tb_window3x3_pair/check/g_window/dut/pending_q
quit -code 0
