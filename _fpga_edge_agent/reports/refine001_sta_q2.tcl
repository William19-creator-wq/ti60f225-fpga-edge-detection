read_sdc ../track4_board.sdc
foreach p {tmds_tx_data0_TX_DATA[*] tmds_tx_data1_TX_DATA[*] tmds_tx_data2_TX_DATA[*] tmds_tx_clk_TX_DATA[*]} {
  puts "=== SETUP to $p"
  if {[catch {report_timing -to [get_ports $p] -max_paths 1} e]} {puts "ERR: $e"}
  puts "=== HOLD to $p"
  if {[catch {report_timing -to [get_ports $p] -max_paths 1 -delay_type min} e]} {puts "ERR: $e"}
}
foreach p {cam_d0_HS_IN[*] cam_d3_HS_IN[*] cam_d0_FIFO_EMPTY} {
  puts "=== SETUP from $p"
  if {[catch {report_timing -from [get_ports $p] -max_paths 1} e]} {puts "ERR: $e"}
  puts "=== HOLD from $p"
  if {[catch {report_timing -from [get_ports $p] -max_paths 1 -delay_type min} e]} {puts "ERR: $e"}
}
puts "=== CHECK_TIMING"
if {[catch {check_timing} e]} {puts "ERR: $e"}
