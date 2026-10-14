onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_r2_observer_supervisor/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_r2_observer_supervisor/clk /tb_r2_observer_supervisor/rst /tb_r2_observer_supervisor/key1_n /tb_r2_observer_supervisor/cj_valid /tb_r2_observer_supervisor/cj_ready /tb_r2_observer_supervisor/class_valid /tb_r2_observer_supervisor/class_ready /tb_r2_observer_supervisor/grad_valid /tb_r2_observer_supervisor/grad_ready /tb_r2_observer_supervisor/status_valid /tb_r2_observer_supervisor/status_ready /tb_r2_observer_supervisor/status_payload /tb_r2_observer_supervisor/terminal_done /tb_r2_observer_supervisor/last_crc /tb_r2_observer_supervisor/last_cs /tb_r2_observer_supervisor/controller/k /tb_r2_observer_supervisor/controller/state /tb_r2_observer_supervisor/observer/busy /tb_r2_observer_supervisor/observer/chunk_index /tb_r2_observer_supervisor/observer/record_shift
run -all
quit -code 1
