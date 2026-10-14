# TRACK4-RAW-SOURCE-JOIN-001 v1：RAW10彩色流到连续RGB源帧的关闭组合

2026-10-09。持续自主授权下先保存/readback READY，再生成独立work/raw_source_join。正式DB/HDK/硬件/已登记源保持；不是整机源COMPLETE发布。

Goal：真实RAW10行RAM/reflect101/插值→RGB48→双bank源writer→真实line回执，完成一个同步采集软件流。Current：RAW彩色四1080p相位和4RAM MAP已归档；RGB writer全字节仿真已通过，v1.1正在排除动态组拍存储综合歧义。Target：正常四相位完整源字节与元数据一致、取消和错误按子模块真实终态关闭，96位scope完整保留。Gap：父组合RTL/独立组合参考/测试/实际MAP。Assumptions：相同处理clk；外层供应64B完整grant、唯一64bit局部handle及96bit完整scope，接收端RAW可反压。真实CSI不可反压/CDC/FIFO、迟到CRC/RX closure、DDR phase fence、FM发布由后续外层承担，不把此接口冒充CSI。

Milestones：整体/接口/中文局部→冻结两子包→RTL→小图4phase×模式→元数据/双终态/公开RGB关闭→1080p→MAP/归档。Failure：保留错误run，未知drain隔离；不得将父级局部done映射成可显示帧。Human gates：无硬件操作。Rollback：新work和只读冻结输入。Completion：RJ-T01..04通过；RJ-T05整机随后。Open questions：无新待批边界，继续用户自主授权。

## A—D 整体、接口与组合

raw_source_join锁job_base32/job_handle64/job_scope96/phase2。外部输入RAW20、x_even11/y11/markers3/bad/handle64；取消handle64。输出done保持scope96/id64/outcome2/reason8/failed_stage2，保存accepted_raw22/accepted_rgb22/logical_bytes32/physical_bytes32/written_lines22/discarded_rgb22，source_stop及quarantined。line RPC同writer512bit原样接出，不改请求握手或drain语义。

先配置writer（公开job_valid保持到ready、消费其job_rsp），合法后启动RAW job，再开放RAW输入。锁定字段不随后续job提案变化。非法grant先消费拒绝回执并给父局部ERROR(stage3/reason32)，不启动RAW。RAW和writer分别完成并实际消费；父只在两侧安全关闭后done。某侧先成功不等同另一侧完成。

正常RGB用RAW的真实out_valid/ready接writer in_valid/ready，坐标、markers、handle原样。若writer安全ERROR/CANCEL done先消费，父打开明确discard出口接收RAW已经公开的held RGB，广播matching cancel并继续等RAW done；不能让RAW等一个已关闭writer的ready。discard是单独计数，不充作写回RGB。若RAW先ERROR，则取消writer并等旧公共RPC真实回执。ERROR优先父cancel，失败stage区分writer1/RAW2/父3。非matching cancel忽略，held done不能改内容。

unknown drain立即父QUARANTINE；保留scope/grant/handle及writer公共owner，停止新RAW；没有安全done/job_ready。rst仅外部证明安全的共同复位，绝不在子模块持有公共借用时私自复位。没有重复写回、缩减scope或复用未归还源。

## E 中文语句组织草图

先enum IDLE/CFG_WRITER/WAIT_WRITER/ARM_RAW/RUN/DRAIN/DONE/QUARANTINE；声明锁定base/handle/scope/phase、writer_started/closed、raw_started/closed、stopping、最终计数。IDLE真实job_fire锁字段，所有记录清零；初始化两closed=1，哪个子job真实fire才置该closed=0。

CFG_WRITER保持writer job_valid；WAIT_WRITER实际rsp_fire好则ARM_RAW，拒绝则错误DRAIN且writer_closed=1。ARM_RAW保持raw job_valid直到fire，再RUN；取消已开始的job通过原RAW当前job_id匹配路径关闭，不撤回正在保持的job提案。输入ready/valid只在RUN且!stopping/!matching_cancel开放。

RAW out_ready通常取writer in_ready；仅writer_closed且stopping时转为discard ready。旧out_fire同时计RAW子输出及父discard，父保存writer accepted真实数不会混入discard。两个done_ready各在started且!closed时拉高；在done_fire保存真实指标、closed=1、错误转stopping并DRAIN。真writer error优先普通cancel，RAW的受控CANCEL不得把已有writer ERROR覆盖。

DRAIN下一沿读旧closed条件，两侧已闭合且!quarantine才DONE；成功另核P/P/L/A/A64lines且discard=0。DONE保持全体输出直到消费，再IDLE。Q无后继安全终态。相同scope的后续job提案、同沿cancel/error、子done不同先后均按上述旧状态记录。

## F—H 独立验证、追踪和边界

RJ-T01：复用冻结的二维RAW/CFA参考只生成参考图，在组合参考里把小端canonicalBGR重排为连续RGB再补A64零；不调用writer算法/FSM。四phase×10模式、34×19/4×2/6×5/跨RAM地址/完整1080p，逐请求及最终所有源字节一致。
RJ-T02：held请求/回执、held父done、提案scope/phase/handle变化、错误cancel ID、两子done不同先后；正常实际计数P/P/L/A，最后write及全排空。
RJ-T03：四类RAW输入错误；取消部分RAW/公开RGB停顿/REQUEST/WAIT/held done；writer错误后确实discard旧RGB并关闭RAW；RAW错误后writer部分bank/公共请求安全关闭；unknown不发布done；外部安全共同复位后一完整新帧。
RJ-T04：Efinity Ti60F225/I3实际组合RAM（预计8，不以预计代替报告）及FF/LUT/DSP检查，100MHz组件目标不冒充生产时序。
RJ-T05：真实CSI、CDC/FIFO期限、源grant/FM/RXclosure/phasefence、DDR、显示/识别与整机PNR/STA另闭合。

追踪：RJ01完整scope→锁字段/终态→T02；RJ02真实RGB源→原RAW/writer及中间接口→T01；RJ03关闭/无假COMPLETE→closed/discard/Q→T03/05。先读此整体，再读两子包内部草图，最后父局部实现和TB；中文理解验收仍待用户阅读反馈，代码前已保存/readback。
