onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_i2c_register_master/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
run -all
quit -code 1
