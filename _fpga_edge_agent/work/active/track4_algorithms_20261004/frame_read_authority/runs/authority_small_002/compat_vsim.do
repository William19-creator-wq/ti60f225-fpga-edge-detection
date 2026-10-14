onerror {quit -code 1}
onbreak {set rc 1; if {![catch {examine -radix binary /tb_frame_owner_authority_compat/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}
run -all
quit -code 1
