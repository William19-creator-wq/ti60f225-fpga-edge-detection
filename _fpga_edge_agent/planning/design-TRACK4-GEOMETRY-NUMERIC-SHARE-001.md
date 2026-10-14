# TRACK4-GEOMETRY-NUMERIC-SHARE-001 v1.1：几何后端复用统计与拟合服务

2026-10-11。独立候选短契约；引用用户自主推进、本地审计和免新增独立测试授权。本卡不伪称得到指定版号批准，当前完整识别仍未实现。

- Goal / Gap：圆五遍、矩形六遍复用同一STATS/FIT；当前wrapper强制两遍且FIT只11/12，没有几何调用入口。避免再实例化算术核或复制622/585位快照。
- Baseline：board_recognition_stats.sv `F82C3E93CB3F191E91980EE70BDF8D28784F39E85DD9380FE9E8FC2620166128`；原TOKEN262、STAT632、NUM_REQ622/NUM_RSP585、NUM_ID176及R3数值规则不改。
- Scope：只在candidate修改上述wrapper，参数ENABLE_GEOMETRY默认0，未在主板开启。默认原两遍流程和接口有效语义保持；启用后同一FIT允许原七kind11/12/13/14/15/17/18，保留BORROW_PAYLOAD、WORD_SLOTS及唯一shared scalar。
- Ports：geometry_bind_valid/ready、geometry_release_valid/ready；geometry_token_valid/ready/body262；geometry_stat_valid/ready/body632；geometry_fit_req_valid/ready/body622；geometry_fit_rsp_valid/ready/body585；geometry_cancel_valid/id176；geometry_stats_quiet、geometry_fit_quiet、geometry_fault。
- Ownership：唯一geometry_owner位在真实bind握手置1，只能原wrapper IDLE/COMPLETE且无start、STATS/FIT/shared scalar均quiet时接纳。owned期间原start_ready为0，几何TOKEN/FIT端使用同一子核，原内部扫描/导出FSM不推进。geometry_release仅所有子核quiet、没有geometry_token_valid/fit_req_valid/cancel_valid时ready；真实release才清owner。失败/UNKNOWN不以empty代quiet或强清owner。
- Composition：STATS输入TOKEN和stat_ready按owner选；FIT输入req/body/rsp_ready/cancel按owner选；原STAT持有期间也必须满足原FIT quiet才释放。几何所有者保持TOKEN低176身份直到STAT真实消费及STATS quiet，FIT全部622正文持有到回复消费及FIT quiet，满足两个BORROW契约。NUM_ID.owner字段始终0，物理owner不写入数值身份。
- v1.1必要交接前提：geometry_stat_ready只允许调用者在geometry_fit_quiet且geometry_fit_req_valid为0时置1。这是借用STAT的关闭条件；父调度器必须生成满足此前提的ready，不能把它当作可任意消费的独立回复。内部仍以fit_quiet且无新FIT请求防护真实STATS释放；geometry_stat_valid保持原公开和背压语义，不在FIT忙时撤回。违反ready前提不属于合法事务，也不能用外侧valid/ready推称子核已消费。STAT释放与新FIT借用禁止同沿发生。
- Outputs：几何valid仅owned且!rst时公开；非ownerready为0；正文来自同一真实子核，不另建快照。fault只报告真实stats fault或外部FIT错误/隔离，LOCAL_REJECT仍是合法候选拒绝。原fault/output/count保持原流程。
- RTL：core正沿，valid&&ready为接受/交付。bind/原start互斥；release与新TOKEN/FIT请求互斥。所有权保留到borrow结果归还后的真实quiet，复位按原共同rst清owner；不上新CDC、时钟或引脚。
- Steps：candidate单文件→定向owner/borrow静态审查→供后端连接。完整board scalar owner及DDR阶段仍由父RPC后续接入，不能只开ENABLE_GEOMETRY就称闭合。
- Validation / Trace：圆A/C/E及矩形M0/M1/M2/诊断→同一STATS/FIT服务→wrapper端口/owner→父后端未来实际关闭证据。普通bind→START/POINT/END→STAT/FIT→关闭→release，以及同沿start/bind、release/请求、背压/错误为静态走查边界。不新增TB。
- Resources / Open：owner最多1FF加选择逻辑为结构估计；开启全FIT的真实逻辑/时序须后续整机实测。该局部端口/借用没有TBD；后端布局、调度、质量不借此称已通过。
- Rollback / Completion：只独立候选，054冻结输入保持。局部实现不等于完整识别；完整几何/注释/记录/最终工具结果仍须逐项完成，硬件仍由用户下载观察。
