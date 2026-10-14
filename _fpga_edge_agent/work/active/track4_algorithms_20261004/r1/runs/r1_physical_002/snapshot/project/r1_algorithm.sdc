# R1-REQ04 / OP04：真实25MHz单时钟。无multicycle、无整个reset/core域例外。
create_clock -name core_25m -period 40.000 [get_ports {clk_25m}]

# get_pins必须基于实际post-map名称。限定原两级及末尾SR，拒绝空/多匹配。
# EFX_FF.SR是RTL异步清零映射；最终报告还须核扇入只来自key1_n。
set r1_async_sr1 [get_pins -regexp {.*reset_adapter.*reset_release_stage1[^|]*\|SR$}]
set r1_async_sr2 [get_pins -regexp {.*reset_adapter.*reset_release_stage2[^|]*\|SR$}]
if {[llength $r1_async_sr1] != 1} {error "R1 reset stage1 async SR endpoint must resolve exactly once"}
if {[llength $r1_async_sr2] != 1} {error "R1 reset stage2 async SR endpoint must resolve exactly once"}
set_false_path -from [get_ports {key1_n}] -to $r1_async_sr1
set_false_path -from [get_ports {key1_n}] -to $r1_async_sr2

# LED无板外同步采样clock：仅这两个静态异步输出端例外。
set_false_path -to [get_ports {led0}]
set_false_path -to [get_ports {led1}]
