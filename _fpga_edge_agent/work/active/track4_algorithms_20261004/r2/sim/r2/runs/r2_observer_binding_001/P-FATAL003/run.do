onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_r2_observer_supervisor/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
run -all
quit -code 1
