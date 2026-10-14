# SI-REQ07 / OBS-IF10：真实25MHz单时钟。无multicycle、无整个reset/core域例外。
create_clock -name core_25m -period 40.000 [get_ports {clk_25m}]

# 候选沿用同名reset_adapter；R2 map后必须独立查询/读回这两个post-map名，each SR网络均为key1_n。
# 保留exactly-one检查；不把regexp零匹配当正确例外，不切任何同步路径。
set r2_async_sr1 [get_pins {reset_adapter/reset_release_stage1~FF|SR}]
set r2_async_sr2 [get_pins {reset_adapter/reset_release_stage2~FF|SR}]
if {[llength $r2_async_sr1] != 1} {error "R2 reset stage1 async SR endpoint must resolve exactly once"}
if {[llength $r2_async_sr2] != 1} {error "R2 reset stage2 async SR endpoint must resolve exactly once"}
set_false_path -from [get_ports {key1_n}] -to $r2_async_sr1
set_false_path -from [get_ports {key1_n}] -to $r2_async_sr2

# LED无板外同步采样clock：仅这两个静态异步输出端例外。
set_false_path -to [get_ports {led0}]
set_false_path -to [get_ports {led1}]
