# TRACK4-FROZEN-REPROCESS-001 v1：冻结原图重新处理

2026-10-11；局部核查完成，独立候选准备实施、尚未编译。沿用 PLAN_TEMPLATE 的字段，合并为短变更记录；本次按用户已给自主实施例外推进。

## A. 范围、依据和授权

- Goal / Target：冻结后，阈值或 Sobel/Canny/识别选择改变，重新处理同一原图；完整结果在显示帧边界替换，恢复时继续采集。
- Current / Gap：当前 freeze 只挡采集和发布，没有重处理入口；source/result 共用一位 bank。
- Baseline：board_compile_052 的冻结输入；board_frame_system.sv SHA256 `C03E22655ABC292BE5B5A9629A243ED482CE6D4303212D0E2CF8C9F86AE00ED2`。
- Sources：T4-A3、原 UC-05；实际 frame_actors_axi、board_frame_display、frame_canny_rpc、board_sobel_rpc。
- Authority：引用用户“当你统计完后自行进行，无需我的批准”和后续“继续完成其他内容”；同时引用“不需要再中文草图、测试”的当前快速整合要求。采用既有自主实施与本地审计例外，不将本卡伪称为用户明确批准过的指定版号；不新增独立测试或长篇草图。
- Scope：只改独立候选的 board_frame_system.sv；原 HDK、052 冻结 flow、031 交付包、正式数据库、硬件状态不动。
- Open / Dependencies：局部地址和接口已查明；器件容量、最终布线、时序及实物效果仍须实际结果，不视为设计前置资料缺口。

## B/C/D. 行为、连接和所有权

- RGB 保留现有两源槽 `0x00000000/0x00800000`，每槽6,220,800B；不增加DDR区域。
- 两结果槽仍为 `0x01000000/0x01100000`；结果 bank 与原图 source slot 独立。每份结果保存 source1、source-frame32、配置签名13，签名为 recognition/sobel/threshold11。
- actors 已分别接收 cap_base、source_base、result_base，端口/数值/DDR块协议无需变化。display 仍只在自身 IDLE 接受 frame_begin 后锁地址；这是旧显示读取结清后更换指针的屏障。
- 冻结固定当前显示结果所属原图。旧采集/算法仍完成真实事务，不强行取消；另一原图的旧结果不获冻结发布资格。冻结原图的新完整结果可在 frame_begin 发布，否则新计算永远不可见。
- 采集选当前显示源的另一槽；只有控制器空闲、没有待发布结果、save_shapes或display_begin时分配。冻结只发布同源结果，冻结源始终等于显示源；没有可达分配沿同时pin两个不同源，故两独立RGB槽够用。三源候选已撤回，不保留无用途的额外选择逻辑或冻结身份快照。
- 重处理同样只在空闲和无待发布结果时开始，输出槽选当前显示结果的另一槽；不能原位改写正在显示的 EDGE。
- CJ.frame 与 origin.frame 使用 job_frame（原图身份）；frame_seq仅新采集递增，config_seq每次算法准备递增，alg_handle使用 `{2,config_seq}`。A_JOB/A_RUN及结果保存前保持全部作业字段。

## E/F. 局部事件和 RTL 契约

- 冻结入口锁已显示源和帧号；同沿显示边界不得先发布另一原图。初次没有有效画面时不虚构原图资格，允许一次首帧采集/已完成pending发布；有效冻结源确定后，丢弃其他源的待发布资格。
- 冻结期间比较期望签名与显示/已完成签名；busy期间按键变化合并为最新意图，在旧作业结清并发布后再启动下一次，不能改变在途作业。
- 0/1/3/4之间只改变呈现样式，无需重复相同 Canny；从2或5返回时仍按真实签名决定重新处理。签名不匹配时呈现旧结果的模式，新结果在frame_begin同时换模式。
- save_shapes 在原算法完成/形状完成后写结果对应元数据；仅随后 pending_valid 可发布。失败保留原显示并锁错误，避免冻结同一失败作业无限重试。
- unfreeze不撤已接受作业；解除冻结沿禁止新建重处理，其真实结束和待发布结果结清后恢复采集。复位清全部资格；数据 RAM/DDR不做额外全清。
- core_clk 上升沿；ready/valid沿条件沿用 actors；CDC、FIFO、外部引脚、时钟/复位极性不改变。旧显示读请求地址锁定到整次扫描结束。
- 身份计数耗尽不回绕，不接新作业并报告 fault。最多一项采集/算法工作及一项已完成待发布结果，不增加无界队列。

## G/H/I/J/K/L. 推进、检查、追踪和交付

- Milestones / Steps：候选单文件修改→静态所有权/身份/事件核查→采用主工程→新 run 整机综合/PNR/最终 STA→通过后登记 bit/hex，停止硬件步骤。
- Validation：按用户要求不新增独立测试/TB；必要综合、布线、最终 setup/hold 继续。正常冻结调阈值、同一源反复切结果槽、busy期间变参、旧采集完成、恢复和复位为静态走查边界，实物观察待用户。
- Trace：T4-A3/UC-05→源/结果独立所有权、重处理入口、CJ/origin身份→board_frame_system→新 run 输入哈希及工具结果；反向引用 source slot/job_frame/pending发布均为该缺口所需。
- State：已完成候选单文件实现，定向静态审查发现解除冻结同沿会多建作业，已补freeze_exit；同一次审查证明第三RGB槽不必要，已缩为两独立源槽。容量、布线、STA尚未运行本候选；不把静态审查称为仿真或硬件通过。
- Failure / Rollback：保留052基线和候选差异，失败只回退本候选；不能降低分辨率、放宽时序或伪造 DDR成功。
- Completion：同一原图新结果有完整软件编译证据后为软件待实物调试；完整复杂识别及硬件验收仍另列未完成。
