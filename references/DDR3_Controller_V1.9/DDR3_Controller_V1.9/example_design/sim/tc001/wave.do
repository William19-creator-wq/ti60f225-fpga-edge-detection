onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb_top/core_clk
add wave -noupdate /tb_top/sdram_clk
add wave -noupdate /tb_top/rx_cal_clk
add wave -noupdate /tb_top/tx_cal_clk
add wave -noupdate /tb_top/tx_cal_clk_90
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb_top/ddr3_ck_p_fpga
add wave -noupdate /tb_top/ddr3_ck_n_fpga
add wave -noupdate /tb_top/ddr3_reset_n
add wave -noupdate /tb_top/ddr3_cke_fpga
add wave -noupdate /tb_top/ddr3_cs_n_fpga
add wave -noupdate /tb_top/ddr3_ras_n_fpga
add wave -noupdate /tb_top/ddr3_cas_n_fpga
add wave -noupdate /tb_top/ddr3_we_n_fpga
add wave -noupdate /tb_top/ddr3_ba_fpga
add wave -noupdate /tb_top/ddr3_addr_fpga
add wave -noupdate /tb_top/ddr3_dqs_p_fpga
add wave -noupdate /tb_top/ddr3_dqs_n_fpga
add wave -noupdate /tb_top/ddr3_dq_fpga
add wave -noupdate /tb_top/ddr3_dm_fpga
add wave -noupdate /tb_top/ddr3_odt_fpga
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb_top/pll_shift
add wave -noupdate /tb_top/pll_shift_sel
add wave -noupdate /tb_top/pll_shift_ena
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb_top/u_ip_top/cal_done
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb_top/u_ip_top/opwr_percentum
add wave -noupdate /tb_top/u_ip_top/opwr_permillage
add wave -noupdate /tb_top/u_ip_top/oprd_percentum
add wave -noupdate /tb_top/u_ip_top/oprd_permillage
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb_top/u_ip_top/error
add wave -noupdate /tb_top/u_ip_top/err_cnt
add wave -noupdate /tb_top/u_ip_top/err_addr
add wave -noupdate /tb_top/u_ip_top/err_position
add wave -noupdate /tb_top/u_ip_top/ref_data
add wave -noupdate /tb_top/u_ip_top/err_data
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {215270572955 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 206
configure wave -valuecolwidth 228
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits fs
update
WaveRestoreZoom {730800427259 fs} {868484188040 fs}
