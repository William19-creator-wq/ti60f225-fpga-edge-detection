onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_r2_hd_chain/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_r2_hd_chain/rst /tb_r2_hd_chain/job_start /tb_r2_hd_chain/cj /tb_r2_hd_chain/source_stop /tb_r2_hd_chain/terminal_done /tb_r2_hd_chain/last_crc /tb_r2_hd_chain/last_cs /tb_r2_hd_chain/dut/controller/state /tb_r2_hd_chain/source/q /tb_r2_hd_chain/source/row /tb_r2_hd_chain/observer/busy /tb_r2_hd_chain/observer/chunk_index
run -all
quit -code 1
