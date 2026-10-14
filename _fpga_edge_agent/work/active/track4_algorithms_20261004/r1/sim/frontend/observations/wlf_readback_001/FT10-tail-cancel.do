onerror {quit -code 1}
echo "CSV,time_ns,frontend_all_empty,status_valid,status_ready,phase_present"
set sample [examine -time {474 ns} -radix unsigned /tb_frontend_frame_pair/check/frontend_all_empty /tb_frontend_frame_pair/check/status_valid /tb_frontend_frame_pair/check/status_ready /tb_frontend_frame_pair/check/phase_present]
echo "CSV,474,[join $sample ,]"
set sample [examine -time {484 ns} -radix unsigned /tb_frontend_frame_pair/check/frontend_all_empty /tb_frontend_frame_pair/check/status_valid /tb_frontend_frame_pair/check/status_ready /tb_frontend_frame_pair/check/phase_present]
echo "CSV,484,[join $sample ,]"
set sample [examine -time {486 ns} -radix unsigned /tb_frontend_frame_pair/check/frontend_all_empty /tb_frontend_frame_pair/check/status_valid /tb_frontend_frame_pair/check/status_ready /tb_frontend_frame_pair/check/phase_present]
echo "CSV,486,[join $sample ,]"
set sample [examine -time {496 ns} -radix unsigned /tb_frontend_frame_pair/check/frontend_all_empty /tb_frontend_frame_pair/check/status_valid /tb_frontend_frame_pair/check/status_ready /tb_frontend_frame_pair/check/phase_present]
echo "CSV,496,[join $sample ,]"
set sample [examine -time {506 ns} -radix unsigned /tb_frontend_frame_pair/check/frontend_all_empty /tb_frontend_frame_pair/check/status_valid /tb_frontend_frame_pair/check/status_ready /tb_frontend_frame_pair/check/phase_present]
echo "CSV,506,[join $sample ,]"
set sample [examine -time {516 ns} -radix unsigned /tb_frontend_frame_pair/check/frontend_all_empty /tb_frontend_frame_pair/check/status_valid /tb_frontend_frame_pair/check/status_ready /tb_frontend_frame_pair/check/phase_present]
echo "CSV,516,[join $sample ,]"
set sample [examine -time {834 ns} -radix unsigned /tb_frontend_frame_pair/check/frontend_all_empty /tb_frontend_frame_pair/check/status_valid /tb_frontend_frame_pair/check/status_ready /tb_frontend_frame_pair/check/phase_present]
echo "CSV,834,[join $sample ,]"
set sample [examine -time {836 ns} -radix unsigned /tb_frontend_frame_pair/check/frontend_all_empty /tb_frontend_frame_pair/check/status_valid /tb_frontend_frame_pair/check/status_ready /tb_frontend_frame_pair/check/phase_present]
echo "CSV,836,[join $sample ,]"
set sample [examine -time {1044 ns} -radix unsigned /tb_frontend_frame_pair/check/frontend_all_empty /tb_frontend_frame_pair/check/status_valid /tb_frontend_frame_pair/check/status_ready /tb_frontend_frame_pair/check/phase_present]
echo "CSV,1044,[join $sample ,]"
set sample [examine -time {1046 ns} -radix unsigned /tb_frontend_frame_pair/check/frontend_all_empty /tb_frontend_frame_pair/check/status_valid /tb_frontend_frame_pair/check/status_ready /tb_frontend_frame_pair/check/phase_present]
echo "CSV,1046,[join $sample ,]"
quit -code 0
