read_sdc ../track4_board.sdc
puts "=== CHECK_TIMING VERBOSE"
catch {check_timing -verbose} e; puts $e
foreach p {tmds_tx_data0_TX_DATA[*] tmds_tx_clk_TX_DATA[*]} {
  puts "=== TO $p"
  if {[catch {report_timing -to [get_ports $p]} e]} {puts "ERR: $e"}
}
foreach p {cam_d0_HS_IN[*] cam_d2_HS_IN[*]} {
  puts "=== FROM $p"
  if {[catch {report_timing -from [get_ports $p]} e]} {puts "ERR: $e"}
}
