puts "ANGLE_POSTROUTE_BEGIN"
set sr1 [get_pins {reset_adapter/reset_release_stage1~FF|SR}]
set sr2 [get_pins {reset_adapter/reset_release_stage2~FF|SR}]
set q1 [get_pins {reset_adapter/reset_release_stage1~FF|Q}]
set d2 [get_pins {reset_adapter/reset_release_stage2~FF|D}]
set q2 [get_pins {reset_adapter/reset_release_stage2~FF|Q}]
foreach item [list $sr1 $sr2 $q1 $d2 $q2] {if {[llength $item] != 1} {error "Reset endpoints must resolve exactly once"}}
puts "ASYNC_SR1_NET=[get_nets $sr1]";puts "ASYNC_SR2_NET=[get_nets $sr2]"
if {[llength [all_clocks]] != 1} {error "Exactly one core clock required"}
report_clocks -file angle_clocks.rpt
check_timing -override_defaults {no_clock unconstrained_internal_endpoints multiple_clock} -verbose -file angle_internal_coverage.rpt
check_timing -verbose -file angle_full_coverage.rpt
report_timing -setup -from $q1 -to $d2 -npaths 1 -file angle_q1_d2_setup.rpt
report_timing -hold -from $q1 -to $d2 -npaths 1 -file angle_q1_d2_hold.rpt
set core_ff [get_cells -regexp {^arithmetic/.*~FF$}]
if {[llength $core_ff] == 0} {error "Core registers empty"}
report_timing -setup -from $q2 -to $core_ff -npaths 16 -file angle_q2_core_setup.rpt
report_timing -hold -from $q2 -to $core_ff -npaths 16 -file angle_q2_core_hold.rpt
proc endpoint_union {patterns} {
    set pins [list]
    foreach pattern $patterns {
        if {[string match {cell:*} $pattern]} {
            set pins [concat $pins [get_cells -regexp [string range $pattern 5 end]]]
        } else {set pins [concat $pins [get_pins -regexp $pattern]]}
    }
    return $pins
}
set transitions [list \
 [list source_to_request [list {^source_lfsr.*~FF\|Q$}] [list {^request_slot.*~FF\|D$}]] \
 [list request_to_capture [list {^request_slot.*~FF\|Q$}] [list {^arithmetic/held_request.*~FF\|D$}]] \
 [list capture_to_vector [list {^arithmetic/held_request.*~FF\|Q$}] [list {^arithmetic/canonical_.*~FF\|D$} {^arithmetic/centered_.*~FF\|D$}]] \
 [list vector_to_product [list {^arithmetic/minor_magnitude.*~FF\|Q$} {^arithmetic/major_magnitude.*~FF\|Q$} {^arithmetic/centered_.*~FF\|Q$}] [list {cell:^arithmetic/multiply/n5_pp_.*}]] \
 [list product_to_capture [list {cell:^arithmetic/multiply/n5_pp_.*}] [list {^arithmetic/first_product.*~FF\|D$} {^arithmetic/second_product.*~FF\|D$}]] \
 [list address_to_boundary [list {^arithmetic/rom_base.*~FF\|Q$}] [list {cell:^arithmetic/constants/boundary$}]] \
 [list address_to_coefficient [list {^arithmetic/rom_base.*~FF\|Q$}] [list {cell:^arithmetic/constants/coefficient$}]] \
 [list boundary_to_words [list {cell:^arithmetic/constants/boundary$}] [list {^arithmetic/constant_words.*~FF\|D$}]] \
 [list coefficient_to_words [list {cell:^arithmetic/constants/coefficient$}] [list {^arithmetic/constant_words.*~FF\|D$}]] \
 [list words_to_product [list {^arithmetic/constant_words.*~FF\|Q$} {^arithmetic/coefficient_[cs].*~FF\|Q$}] [list {cell:^arithmetic/multiply/n5_pp_.*}]] \
 [list words_to_coefficients [list {^arithmetic/constant_words.*~FF\|Q$}] [list {^arithmetic/coefficient_[cs].*~FF\|D$}]] \
 [list mid_to_search_data [list {^arithmetic/mid.*~FF\|Q$}] [list {^arithmetic/[lh][oi].*~FF\|D$}]] \
 [list cross_to_search_enable [list {^arithmetic/first_product.*~FF\|Q$} {^arithmetic/second_product.*~FF\|Q$}] [list {^arithmetic/[lh][oi].*~FF\|CE$}]] \
 [list products_to_sign [list {^arithmetic/first_product.*~FF\|Q$} {^arithmetic/second_product.*~FF\|Q$}] [list {^arithmetic/signed_product_[xy].*~FF\|D$}]] \
 [list signed_products_to_sum [list {^arithmetic/signed_product_[xy].*~FF\|Q$}] [list {^arithmetic/projection_sum.*~FF\|D$}]] \
 [list projection_to_round [list {^arithmetic/projection_sum.*~FF\|Q$}] [list {^arithmetic/rounded_q.*~FF\|D$}]] \
 [list value_to_response [list {^arithmetic/result_value.*~FF\|Q$}] [list {^rsp_body.*~FF\|D$} {^arithmetic/rsp_body.*~FF\|D$}]] \
 [list response_to_observer [list {^rsp_body.*~FF\|Q$} {^arithmetic/rsp_body.*~FF\|Q$}] [list {^response_shift.*~FF\|D$}]] \
 [list observer_to_crc [list {^response_shift.*~FF\|Q$}] [list {^rolling_crc.*~FF\|D$}]]]
foreach transition $transitions {
    set name [lindex $transition 0];set starts [endpoint_union [lindex $transition 1]];set ends [endpoint_union [lindex $transition 2]]
    puts "DATA_${name}_SOURCE_COUNT=[llength $starts]";puts "DATA_${name}_DEST_COUNT=[llength $ends]"
    if {[llength $starts] == 0 || [llength $ends] == 0} {error "Data endpoint collection empty"}
    report_timing -setup -from $starts -to $ends -npaths 8 -nworst 1 -file angle_${name}_setup.rpt
    report_timing -hold -from $starts -to $ends -npaths 8 -nworst 1 -file angle_${name}_hold.rpt
}
# 同一快照的两RAM须在资源报告、mapped网表和STA的实际地址/输出扇出另行读回。
report_timing -setup -npaths 64 -file angle_all_registers_setup.rpt
report_timing -hold -npaths 64 -file angle_all_registers_hold.rpt
puts "ANGLE_POSTROUTE_END"
exit
