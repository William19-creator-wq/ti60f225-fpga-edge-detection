# FT-T10：实际数据D路径；不把CE/CLK/SR计作算术证据。空集合或空报告必须失败。
puts "FIT_POSTROUTE_BEGIN"
set sr1 [get_pins {reset_adapter/reset_release_stage1~FF|SR}]
set sr2 [get_pins {reset_adapter/reset_release_stage2~FF|SR}]
set q1 [get_pins {reset_adapter/reset_release_stage1~FF|Q}]
set d2 [get_pins {reset_adapter/reset_release_stage2~FF|D}]
set q2 [get_pins {reset_adapter/reset_release_stage2~FF|Q}]
foreach item [list $sr1 $sr2 $q1 $d2 $q2] {
    if {[llength $item] != 1} {error "Reset endpoint must resolve exactly once"}
}
puts "ASYNC_SR1_NET=[get_nets $sr1]"
puts "ASYNC_SR2_NET=[get_nets $sr2]"
if {[llength [all_clocks]] != 1} {error "Exactly one core clock required"}
report_clocks -file fit_clocks.rpt
check_timing -override_defaults {no_clock unconstrained_internal_endpoints multiple_clock} -verbose -file fit_internal_coverage.rpt
check_timing -verbose -file fit_full_coverage.rpt
report_timing -setup -from $q1 -to $d2 -npaths 1 -file fit_q1_d2_setup.rpt
report_timing -hold -from $q1 -to $d2 -npaths 1 -file fit_q1_d2_hold.rpt
set core_ff [get_cells -regexp {^arithmetic/.*~FF$}]
if {[llength $core_ff] == 0} {error "Core register collection empty"}
report_timing -setup -from $q2 -to $core_ff -npaths 16 -file fit_q2_core_setup.rpt
report_timing -hold -from $q2 -to $core_ff -npaths 16 -file fit_q2_core_hold.rpt
# 单独解析每种实际寄存器名字，再合并；工具的端点正则不接受组内OR。
proc endpoint_union {patterns} {
    set pins [list]
    foreach pattern $patterns {set pins [concat $pins [get_pins -regexp $pattern]]}
    return $pins
}
set transitions [list \
 [list source_to_request [list {^source_lfsr\[[0-9]+\]~FF\|Q$}] [list {^request_slot\[[0-9]+\]~FF\|D$}]] \
 [list request_to_capture [list {^request_slot\[[0-9]+\]~FF\|Q$}] [list {^arithmetic/held_request\[[0-9]+\]~FF\|D$}]] \
 [list capture_to_command [list {^arithmetic/held_request.*~FF\|Q$} {^arithmetic/work_slot.*~FF\|Q$}] [list {^arithmetic/published_command.*~FF\|D$}]] \
 [list command_to_bridge [list {^arithmetic/published_command.*~FF\|Q$}] [list {^arithmetic/child_req_body.*~FF\|D$}]] \
 [list bridge_to_child [list {^arithmetic/child_req_body.*~FF\|Q$}] [list {^arithmetic/private_arithmetic/held_request.*~FF\|D$}]] \
 [list child_operand_to_product [list {^arithmetic/private_arithmetic/work_[ab].*~FF\|Q$}] [list {^arithmetic/private_arithmetic/column_sum.*~FF\|D$}]] \
 [list child_full_to_bridge [list {^arithmetic/private_arithmetic/full.*~FF\|Q$} {^arithmetic/child_rsp_body\[[2-5][0-9][0-9]\]~FF\|Q$}] [list {^arithmetic/bridge_result.*~FF\|D$}]] \
 [list bridge_to_slot [list {^arithmetic/bridge_result.*~FF\|Q$}] [list {^arithmetic/work_slot.*~FF\|D$}]] \
 [list cache_to_slot [list {^.*arithmetic/cache_[km]\[.*~FF\|Q$}] [list {^arithmetic/work_slot.*~FF\|D$}]] \
 [list slot_to_response [list {^arithmetic/work_slot.*~FF\|Q$}] [list {^rsp_body.*~FF\|D$}]] \
 [list response_to_observer [list {^rsp_body.*~FF\|Q$}] [list {^response_shift.*~FF\|D$}]] \
 [list observer_to_crc [list {^response_shift.*~FF\|Q$}] [list {^rolling_crc.*~FF\|D$}]]]
foreach transition $transitions {
    set name [lindex $transition 0]
    set starts [endpoint_union [lindex $transition 1]]
    set ends [endpoint_union [lindex $transition 2]]
    puts "DATA_${name}_SOURCE_COUNT=[llength $starts]"
    puts "DATA_${name}_DEST_COUNT=[llength $ends]"
    if {[llength $starts] == 0 || [llength $ends] == 0} {error "Data endpoint collection empty"}
    report_timing -setup -from $starts -to $ends -npaths 8 -nworst 1 -file fit_${name}_setup.rpt
    report_timing -hold -from $starts -to $ends -npaths 8 -nworst 1 -file fit_${name}_hold.rpt
}
puts "FIT_POSTROUTE_END"
exit
