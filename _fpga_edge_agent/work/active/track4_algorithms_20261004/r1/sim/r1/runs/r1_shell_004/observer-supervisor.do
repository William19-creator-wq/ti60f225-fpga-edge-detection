onerror {quit -code 2}
onbreak {set rc 3; if {![catch {examine -radix binary /tb_r1_observer_supervisor/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
log -r /*
run -all
quit -code 3
