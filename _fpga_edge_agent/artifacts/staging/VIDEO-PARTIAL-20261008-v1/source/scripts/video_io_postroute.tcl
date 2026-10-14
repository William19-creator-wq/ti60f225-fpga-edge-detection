puts "VIDEO_POSTROUTE_BEGIN"
set sr1 [get_pins {reset_adapter/reset_release_stage1~FF|SR}]
set sr2 [get_pins {reset_adapter/reset_release_stage2~FF|SR}]
set q1 [get_pins {reset_adapter/reset_release_stage1~FF|Q}]
set d2 [get_pins {reset_adapter/reset_release_stage2~FF|D}]
set q2 [get_pins {reset_adapter/reset_release_stage2~FF|Q}]
foreach item [list $sr1 $sr2 $q1 $d2 $q2] {if {[llength $item] != 1} {error "Reset endpoint must resolve exactly once"}}
puts "ASYNC_SR1_NET=[get_nets $sr1]";puts "ASYNC_SR2_NET=[get_nets $sr2]"
if {[llength [all_clocks]] != 1} {error "Exactly one core clock required"}
report_clocks -file video_clocks.rpt
check_timing -override_defaults {no_clock unconstrained_internal_endpoints multiple_clock} -verbose -file video_internal_coverage.rpt
check_timing -verbose -file video_full_coverage.rpt
report_timing -setup -from $q1 -to $d2 -npaths 1 -file video_q1_d2_setup.rpt
report_timing -hold -from $q1 -to $d2 -npaths 1 -file video_q1_d2_hold.rpt
set core_ff [all_registers]
report_timing -setup -from $q2 -to $core_ff -npaths 16 -file video_q2_core_setup.rpt
report_timing -hold -from $q2 -to $core_ff -npaths 16 -file video_q2_core_hold.rpt
proc endpoint_union {patterns} {set pins [list];foreach pattern $patterns {set pins [concat $pins [get_pins -regexp $pattern]]};return $pins}
set transitions [list \
 [list timing_to_capture [list {^timing/.*count.*~FF\|Q$}] [list {^capture/.*~FF\|D$}]] \
 [list timing_to_presenter [list {^timing/.*count.*~FF\|Q$}] [list {^presenter/.*~FF\|D$} {^out_rgb_pair.*~FF\|D$}]] \
 [list mode_to_rgb [list {^frame_count.*~FF\|Q$} {^presenter/frame_mode.*~FF\|Q$}] [list {^presenter/out_rgb_pair.*~FF\|D$} {^out_rgb_pair.*~FF\|D$}]] \
 [list capture_to_checksum [list {^gray_pair.*~FF\|Q$} {^raw_pair_out.*~FF\|Q$} {^frame_id.*~FF\|Q$} {^capture/.*~FF\|Q$}] [list {^data_checksum.*~FF\|D$}]] \
 [list rgb_to_checksum [list {^presenter/out_rgb_pair.*~FF\|Q$} {^out_rgb_pair.*~FF\|Q$}] [list {^data_checksum.*~FF\|D$}]]]
foreach transition $transitions {
    set name [lindex $transition 0];set starts [endpoint_union [lindex $transition 1]];set ends [endpoint_union [lindex $transition 2]]
    puts "DATA_${name}_SOURCE_COUNT=[llength $starts]";puts "DATA_${name}_DEST_COUNT=[llength $ends]"
    if {[llength $starts] == 0 || [llength $ends] == 0} {error "Data endpoint collection empty"}
    report_timing -setup -from $starts -to $ends -npaths 8 -nworst 1 -file video_${name}_setup.rpt
    report_timing -hold -from $starts -to $ends -npaths 8 -nworst 1 -file video_${name}_hold.rpt
}
puts "VIDEO_POSTROUTE_END"
exit
