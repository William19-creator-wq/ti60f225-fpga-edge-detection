onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_scalar_probe_top/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log -r /tb_scalar_probe_top/dut/*
run -all
quit -code 1
