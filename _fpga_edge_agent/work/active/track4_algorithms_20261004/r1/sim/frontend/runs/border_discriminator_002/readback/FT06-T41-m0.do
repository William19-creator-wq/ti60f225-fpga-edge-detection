onerror {quit -code 1}
echo CSV,time_ns,out_valid,out_ready,M_pair,edge_pair,L1_pair
set sample [examine -time {334 ns} -radix unsigned /tb_frontend_frame_pair/check/out_valid /tb_frontend_frame_pair/check/out_ready /tb_frontend_frame_pair/check/out_y_pair /tb_frontend_frame_pair/check/out_edge /tb_frontend_frame_pair/check/g_frontend/dut/unused_l1]
echo "CSV,334,[join $sample ,]"
set sample [examine -time {344 ns} -radix unsigned /tb_frontend_frame_pair/check/out_valid /tb_frontend_frame_pair/check/out_ready /tb_frontend_frame_pair/check/out_y_pair /tb_frontend_frame_pair/check/out_edge /tb_frontend_frame_pair/check/g_frontend/dut/unused_l1]
echo "CSV,344,[join $sample ,]"
set sample [examine -time {374 ns} -radix unsigned /tb_frontend_frame_pair/check/out_valid /tb_frontend_frame_pair/check/out_ready /tb_frontend_frame_pair/check/out_y_pair /tb_frontend_frame_pair/check/out_edge /tb_frontend_frame_pair/check/g_frontend/dut/unused_l1]
echo "CSV,374,[join $sample ,]"
set sample [examine -time {384 ns} -radix unsigned /tb_frontend_frame_pair/check/out_valid /tb_frontend_frame_pair/check/out_ready /tb_frontend_frame_pair/check/out_y_pair /tb_frontend_frame_pair/check/out_edge /tb_frontend_frame_pair/check/g_frontend/dut/unused_l1]
echo "CSV,384,[join $sample ,]"
quit -code 0
