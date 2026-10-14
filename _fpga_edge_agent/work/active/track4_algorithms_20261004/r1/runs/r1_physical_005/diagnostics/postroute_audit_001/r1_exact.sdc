# R1-REQ04 / OP04：真实25MHz单时钟。无multicycle、无整个reset/core域例外。
create_clock -name core_25m -period 40.000 [get_ports {clk_25m}]

# 本机STA隔离查询实际读回这两个post-map精确名，each SR网络均为key1_n。
# 保留exactly-one检查；不把regexp零匹配当正确例外，不切任何同步路径。
set r1_async_sr1 [get_pins {reset_adapter/reset_release_stage1~FF|SR}]
set r1_async_sr2 [get_pins {reset_adapter/reset_release_stage2~FF|SR}]
if {[llength $r1_async_sr1] != 1} {error "R1 reset stage1 async SR endpoint must resolve exactly once"}
if {[llength $r1_async_sr2] != 1} {error "R1 reset stage2 async SR endpoint must resolve exactly once"}
set_false_path -from [get_ports {key1_n}] -to $r1_async_sr1
set_false_path -from [get_ports {key1_n}] -to $r1_async_sr2

# LED无板外同步采样clock：仅这两个静态异步输出端例外。
set_false_path -to [get_ports {led0}]
set_false_path -to [get_ports {led1}]
