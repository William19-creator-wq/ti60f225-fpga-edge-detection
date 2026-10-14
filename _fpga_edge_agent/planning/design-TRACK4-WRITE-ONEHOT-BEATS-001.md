# TRACK4-WRITE-ONEHOT-BEATS-001 v1：独占写源的共享单热分拍树

2026-10-11，READY_FOR_REVIEW短卡，尚未编码/TB/EDA。依用户持续自主、本地审计与免额外长草图/独立测试授权，只读查实际资源后提出候选；ROOT读回呈现、限定实施后才生成业务源码。不冒称用户另按指定版号批准，不动main、058/059/060运行或冻结输入、原HDK、正式状态及硬件。保持完整1080p、六个有效写源、全部512/128有效payload、算法域/数量/精度与接口协议。

## 目标、实证与基线

WB01：只改变自写axi_write_pair_service中独占profile的128bit×24选1组合结构，争取降低实际资源/路由；没有资源通过或确定省500的结论。059实际cap61147/60800失败，由ROOT报告；本轮实际读hier的父write_service总LUT4=2639、自身2617，LUT+FF自身83.5，bridge仅22个LUT4。其它热点gradient_store为1615+63且26RAM，SEED3280+326.5且13RAM/14DSP，display自身2387+471.5，未找到能直接保证大收益且不扩大接口的单项。

| runs/board_compile_059/flow实际只读基线 | SHA256 |
|---|---|
| algorithm/services/axi_write_pair_service.sv | 3B92E773375E0BFFAE0E151535E7FCA6B8FE6F239CA61EFC5AC5F711DFE82776 |
| algorithm/rtl/video_memory_hub.sv | 2502E96AC44CFE62450AFC8E47F8C510DDD727C45101813032F1095F0156494C |
| algorithm/rtl/frame_actors_axi.sv | C5B13D0D7DD8B0E4BFC9BBA9F77E3CD6213CAE6E610CDD53ED9419610EC0024C |
| board/rtl/board_frame_system.sv | E59AD999E513E0B49065F3325F3A7B5AB50BB7B6D2C8BEA44233349803355C37 |
| outflow/track4_board.hier_util.rpt | DC5A5B4EE0642237350201F0084289C4B1C0520DE3F7CD4A36F191DAA5B3E2B4 |

历史证据：056原mask-OR自身LUT4=2259、057=2258；058独占encoded-case=2572、059=2617。不同run还有其它全工程改动与mapper归属波动，不能把差值当同基线测量；055未发现hier报告。恢复旧mask-OR仅提示约300–360规模，并非本候选已省500。既有EXCLUSIVE的硬拒绝/3bit锁源保留，不回退其协议。

## 范围、接口与具体局部

计划独立candidates/write_onehot_beats_v1四份自写文件。service/hub/actors尾部追加ONEHOT_EXCLUSIVE_BEATS默认0并逐级透传，候选board唯一actors实例显式1；主board尚不启用。只在EXCLUSIVE_PROFILE且此参数1时替换原exclusive_beat_tree，其余默认0、非独占profile、通用multi-hot OR分支原样。实际编码前before需取ROOT指定当时版本并记录完整hash；059是证据基线，不能用本表旧副本覆盖后续circle/FAST/ROOT_NARROW/FIXED_APPEND整合。

WB-IF01原端口不变：锁定data_source[2:0]码0为camera c_data[0]，码1…5为flat_wdata五个512bit源；bridge原write_beat_index[1:0]码0…3为各源四拍，beat128位次序低到高。24固定片段始终为camera[beat*128+:128]或flat_wdata[(source-1)*512+beat*128+:128]，均是常量生成位置，不新增动态512位数据选择或宽FF快照。

WB-IF02解码与组合：先用精确case分别解码6bit source_onehot及4bit beat_onehot，非法码/X/Z时全0；24个共享choose仅为对应两位的AND，不依req_valid、active、quiet或enable临时清0。每两个固定片段组成一组128bit的masked pair OR，共12组；每四组pair做固定OR，共3组；最终OR三组得selected_beat。合法已知key恰一个choose；已接受、已知的二态payload逐位等于原24项case。非法key仍窄数据0，与原default一致。四态源中的X会传播；被选Z经AND/OR变为X，不能声称非法四态payload逐位等价。原完整selected_data/selected_known接受前检查保留，未知payload仍被拒绝；未选源X/Z被零mask消除，不扩大接受集合，不为保留非法Z增加宽mux。

WB-IF03所有权/时序：data_source仍取原locked_source，原request_fire锁来源/owner、原camera_credit公平规则、非法mask在accept前detected_fault=1且ready0、AW/W/B及通知路径不改。共同reset或response_fire&&effective_drained&&!quarantined才清来源；UNKNOWN、localQ、enable下降、W背压和held回复期间仍借原正文并保持拍号。不新增状态、寄存器、RAM/DSP、时钟、接受/发布周期；桥EXTERNAL_NARROW_WRITE仍1，bridge/protected IP本身不修改。

## 人可读局部次序、位宽与失败

原合法接受沿锁3bit源 → 同一锁源精确译成一热、同一2bit拍号译成一热 → 共用24个位选择固定128bit叶子 → 12/3/1固定OR层形成原W正文 → 原四拍真实W接受推进beat → 原B及drained通知消费才归还。所有每叶/每组/最终值均128bit，masked zero常量128位；索引仅常量genvar，不裁切payload、重排字节、合并写源或删功能。default0原case保留。

2026-10-12 ROOT实际恢复补充：059仅资源证据；本候选实施before取当前main/061冻结副本，service与hub仍为上表3B92/2502，actors为A05FFA1762A43B3872AAEE57FA5A11DFABEDE07F7D8CFF40F468A6E9FEA55FF5，system为2E8E6E5F6F2A1A717D5919C94A041594EAEB667D20076664452580065AD38094。必须保留完整circle/FAST、ROOT_NARROW、FIXED_APPEND整合。061实际综合57131 LUT/22875 FF/230 RAM/155 DSP，物理packing72282超过60800；本树不可能单独解决11482缺口，只做有界结构优化及一次真实测量，不声称整机容量通过。

未接受非法mask不生成回复；已接受异常沿用原bridge/localQ和真实B收尾，不因新树判断归属、宣布drain、改变held error/drained或提前释放借用。复位仍原core rst；没有CDC变化。C++不适用，此任务仅组合RTL选择。

## 预算、静态计划与停止点

名义LUT4结构：每输出bit的12个双masked-pair表达式各4输入，3个OR4及1个OR3，共16×128=2048 LUT4级，加共享精确解码/控制；相对059自身2617约500–570潜力，仅属门结构预算。实际工具可能重新切树、共享或复制选择，physical路由/LUT+FF归属也会变化，不能保证净省500、总容量或STA通过。FF/RAM/DSP结构增量为0，最坏选择数据路径为固定3个归并层加shared decode；时序需实际工具测量。

静态场景：6源×4拍逐切片、码6/7与拍号X/Z默认0；合法源中的X及未选源X；camera并发额度；非法zero/multi-hot mask preaccept；W/AW背压保持；真实B/drained回复；early/unexpected B、UNKNOWN held、enable下降、reset；default0及不完整profile完整旧路径。只场景文字与源码/diff读回，不生成TB或可执行测试。ROOT读回呈现后才限定候选四文件；随后父决定一次新run实际测量，记录真实packed/routing/STA，若不省资源或时序恶化则关参数/仅回退本候选，不退circle/FAST等其它局部。

双向追踪：WB01资源热点→059 hier与24case→新单热固定树；原完整payload/六源四拍→WB-IF01/02固定叶子和逐位等价；旧兼容与真实owner/失败→WB-IF03/default0/原完整状态机不改。每个新增位选择/归并仅服务组合优化，未新增行为。完成标准是独立源码与差异可读回，再由父实际资源/STA采纳；卡完成不是实现、整机通过或实物效果证明。
