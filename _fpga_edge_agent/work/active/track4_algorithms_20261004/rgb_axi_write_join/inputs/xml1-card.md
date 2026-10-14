# TRACK4-RGB-AXI-WRITE-JOIN-001 XML1：工程元素顺序修正

范围仅限新work的project/rgb_axi_write_join_component.xml，不改变RTL/TB/参考/五依赖/数值/接口/时序或源基线11。沿用用户持续自主软件与本地审计例外，不操作正式状态及硬件。

事实：join_small_001、join_min_001、join_bank_001、join_tail_001、join_hd_001均实际完成编译、预期fatal拒绝、功能及独立审计。HD实际1036800pairs、6220800RGB bytes、97200camera RPC及4096algorithm RPC通过。join_map_001已终止exit1；真实日志ProjectDatabaseParseFailed，未进入RTL综合，原失败目录保留。

定位：工程生成时移除旧design_file后把五个新节点append到top_vhdl_arch后；官方现有enf_proj.xsd及已成功write-pair项目规定top_module→design_file列表→top_vhdl_arch。新XML仍可被通用XML parser读取，但不满足Efinity工程顺序。

中文操作：读当前work XML，取唯一top_vhdl_arch节点，从design_info列表摘下，放在五个design_file之后；不改任何文件路径、器件Ti60F225/I3、100MHz约束、speed/retiming0/seq_opt0、bit关闭。读回整个XML，核对五份RTL路径/hash及上述配置，使用新join_map_002，从已通过当前9源snapshot关联并保存12源/工程快照。

检查与追踪：RJ-T5→工程XML顺序→本卡→新MAP结果/真实primitive与报告；五功能suite的9源hash保持不变，不为纯工程XML排序重复功能仿真。配置失败不能作为功能失败，也不能作综合通过。当前XML修正已形成可读设计，READY，随后执行并核实际结果；仍无PNR/STA/物理DDR/FPS或最终bit证据。
