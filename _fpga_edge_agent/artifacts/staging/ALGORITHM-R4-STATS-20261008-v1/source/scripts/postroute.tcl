# ST-T12：各级真实Q→数据D；不存在的集合失败，复位同步级间不切时序。
puts "STATS_POSTROUTE_BEGIN"
set sr1 [get_pins {reset_adapter/reset_release_stage1~FF|SR}]
set sr2 [get_pins {reset_adapter/reset_release_stage2~FF|SR}]
set q1 [get_pins {reset_adapter/reset_release_stage1~FF|Q}]
set d2 [get_pins {reset_adapter/reset_release_stage2~FF|D}]
set q2 [get_pins {reset_adapter/reset_release_stage2~FF|Q}]
foreach item [list $sr1 $sr2 $q1 $d2 $q2] {if {[llength $item] != 1} {error "Reset endpoint must resolve exactly once"}}
puts "ASYNC_SR1_NET=[get_nets $sr1]"
puts "ASYNC_SR2_NET=[get_nets $sr2]"
if {[llength [all_clocks]] != 1} {error "Exactly one core clock required"}
report_clocks -file stats_clocks.rpt
check_timing -override_defaults {no_clock unconstrained_internal_endpoints multiple_clock} -verbose -file stats_internal_coverage.rpt
check_timing -verbose -file stats_full_coverage.rpt
report_timing -setup -from $q1 -to $d2 -npaths 1 -file stats_q1_d2_setup.rpt
report_timing -hold -from $q1 -to $d2 -npaths 1 -file stats_q1_d2_hold.rpt
set core_ff [concat [get_cells -regexp {^statistics/.*~FF$}] [get_cells -regexp {^fitting/.*~FF$}]]
if {[llength $core_ff] == 0} {error "Core registers empty"}
report_timing -setup -from $q2 -to $core_ff -npaths 16 -file stats_q2_core_setup.rpt
report_timing -hold -from $q2 -to $core_ff -npaths 16 -file stats_q2_core_hold.rpt
proc endpoint_union {patterns} {
    set pins [list]
    foreach pattern $patterns {if {[string match {cell:*} $pattern]} {set pins [concat $pins [get_cells -regexp [string range $pattern 5 end]]]} else {set pins [concat $pins [get_pins -regexp $pattern]]}}
    return $pins
}
set transitions [list \
 [list source_to_token [list {^source_lfsr.*~FF\|Q$} {^source_[xy].*~FF\|Q$}] [list {^token_slot.*~FF\|D$}]] \
 [list token_to_capture [list {^token_slot.*~FF\|Q$}] [list {^statistics/header.*~FF\|D$} {^statistics/s0_.*~FF\|D$}]] \
 [list s0_to_products [list {^statistics/s0_.*~FF\|Q$}] [list {^statistics/s1_.*~FF\|D$} {cell:^statistics/mult_199$} {cell:^statistics/mult_200$} {cell:^statistics/mult_201$} {cell:^statistics/mult_202$} {cell:^statistics/mult_203$}]] \
 [list products_to_d [list {^statistics/s1_.*~FF\|Q$} {cell:^statistics/mult_202$} {cell:^statistics/mult_203$}] [list {^statistics/s2_d.*~FF\|D$}]] \
 [list d_to_ad_bd [list {^statistics/s2_[abd].*~FF\|Q$}] [list {cell:^statistics/n3232_pp_.*} {cell:^statistics/n3270_pp_.*}]] \
 [list contribution_to_accumulator [list {^statistics/s3_.*~FF\|Q$} {cell:^statistics/n3232_pp_.*} {cell:^statistics/n3270_pp_.*}] [list {^statistics/accumulator.*~FF\|D$}]] \
 [list accumulator_to_stat [list {^statistics/accumulator.*~FF\|Q$}] [list {^stat_body.*~FF\|D$} {^statistics/stat_body.*~FF\|D$}]] \
 [list stat_to_request [list {^stat_body.*~FF\|Q$} {^statistics/stat_body.*~FF\|Q$}] [list {^request_slot.*~FF\|D$}]] \
 [list request_to_fit [list {^request_slot.*~FF\|Q$}] [list {^fitting/held_request.*~FF\|D$}]] \
 [list fit_capture_to_command [list {^fitting/held_request.*~FF\|Q$} {^fitting/work_slot.*~FF\|Q$}] [list {^fitting/published_command.*~FF\|D$}]] \
 [list command_to_bridge [list {^fitting/published_command.*~FF\|Q$}] [list {^fitting/child_req_body.*~FF\|D$}]] \
 [list bridge_to_child [list {^fitting/child_req_body.*~FF\|Q$}] [list {^fitting/private_arithmetic/held_request.*~FF\|D$}]] \
 [list child_operand_to_product [list {^fitting/private_arithmetic/work_[ab].*~FF\|Q$}] [list {^fitting/private_arithmetic/column_sum.*~FF\|D$}]] \
 [list child_return_to_bridge [list {^fitting/child_rsp_body.*~FF\|Q$} {^fitting/private_arithmetic/response_value.*~FF\|Q$}] [list {^fitting/bridge_result.*~FF\|D$}]] \
 [list bridge_to_slot [list {^fitting/bridge_result.*~FF\|Q$}] [list {^fitting/work_slot.*~FF\|D$}]] \
 [list fit_slot_to_response [list {^fitting/work_slot.*~FF\|Q$}] [list {^fit_rsp_body.*~FF\|D$} {^fitting/rsp_body.*~FF\|D$}]] \
 [list response_to_observer [list {^fit_rsp_body.*~FF\|Q$} {^fitting/rsp_body.*~FF\|Q$} {^stat_body.*~FF\|Q$}] [list {^response_word.*~FF\|D$}]] \
 [list observer_to_crc [list {^response_word.*~FF\|Q$}] [list {^rolling_crc.*~FF\|D$}]]]
foreach transition $transitions {
    set name [lindex $transition 0]
    set starts [endpoint_union [lindex $transition 1]]
    set ends [endpoint_union [lindex $transition 2]]
    puts "DATA_${name}_SOURCE_COUNT=[llength $starts]"
    puts "DATA_${name}_DEST_COUNT=[llength $ends]"
    if {[llength $starts] == 0 || [llength $ends] == 0} {error "Data endpoint collection empty"}
    report_timing -setup -from $starts -to $ends -npaths 8 -nworst 1 -file stats_${name}_setup.rpt
    report_timing -hold -from $starts -to $ends -npaths 8 -nworst 1 -file stats_${name}_hold.rpt
}
puts "STATS_POSTROUTE_END"
exit
