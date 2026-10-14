onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_canny_fork_pair/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log /tb_canny_fork_pair/clk /tb_canny_fork_pair/rst /tb_canny_fork_pair/in_valid /tb_canny_fork_pair/in_ready /tb_canny_fork_pair/n_valid /tb_canny_fork_pair/n_ready /tb_canny_fork_pair/grad_valid /tb_canny_fork_pair/grad_ready
run -all
quit -code 1
