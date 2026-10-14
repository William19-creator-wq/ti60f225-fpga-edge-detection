# Canny v0.3：状态cache、queue端口与内存组合只读审查

2026-10-04；[主稿v0.3](../../../planning/design-TRACK4-CANNY-001.md)、[存储草图](../04_local-designs/canny-memory-sketches-v0.3.md)为LOCAL_DESIGN/NOT_APPROVED。[窗口v0.2](../04_local-designs/canny-window-sketches-v0.2.md)继续有效。本页记录实际设计分析与文档修订，业务实现/验证全部未运行。

## 1. 整体到局部及三方向复审

精确八邻域闭包与数值链不变；C0阶段、唯一状态cache、queue指针/银行及MOD-05边界先分清，再细化RAM/FSM和逐沿交接。三个子任务只读核对实际附件，未代写业务代码。

| 复审方向 | 发现、选择及并入修订 |
|---|---|
| cache布局/状态 | 8块512×16与set/word映射一致；补干净miss跳WB、WB保存替换/FLUSH用途、失败drained退出而不永等success；hit/完整安装显式pin，同线不重复列表；cancel同末字禁止valid发布，claim同cancel仍成对WE；地址先扩宽再移位，WB捕获与下一读可同沿 |
| queue端口/容量 | 两append半bank共享1R1W；prefix占256槽，新增容量256−p，避免259槽/65拍；选择逐segment承诺，取消不再提出后段、descriptor失败c不推进；返回槽计未capture预留；prefetch至多3段，段内索引/offset与8/9/10bit进度分清；私有pop共同abort，作废范围不授权新读 |
| 内存/阶段组合 | 早ACCESS拒绝可能使已提出W永等ready；补已req_fire才completion、W在req_fire后、失败且物理drained的共同terminal、逻辑拍暂停/终结和独立completion_ready；actual_beats只计逻辑交付不代替物理排空。tag借用仅到该segment结清，不等整bank/cache而阻后段；正常fence在最后请求实际交付后建立，后台和已grant capture独立推进 |

窄服务候选为32bit字节地址、1…64个16B完整拍、16bit虚拟tag，16B对齐且不跨4KiB；物理ID4另经事务表。物理R反压、W气泡和B后可见性未知，预留整请求接收/可能整burst发送缓冲另计，不能把逻辑接口当真实保护controller保证。

## 2. 条件推导、资源和未完成

cache命中claim e0…e6、下一操作最早e7；WB32次读至e31/捕获末字e32、最早e33请求；FILL32字安装后下一沿读。它们是设计条件推导，没有运行波形。串行候选需继续比较同字最新值旁路、邻居归组及扫描；未声称性能最优。

共享FE/Canny候选40 RAM10不变，cache元数据1632bit、linebuf512bit及其他记录、queue carry/W/R/pop寄存器分别列出；MOD-05及平台/显示/识别另计，尚未综合/PNR。CN-B03/04得到具体候选，完整父端口与基线仍待统一；CN-B05…08的真实服务/器件PHY、地址/租约、性能/质量继续阻塞READY。

T19…22新增cache映射/最新字/安装取消、prefix/共享口/回收、分段API/早失败/fence、原子claim/后台/错误隔离。T01…22均NOT_RUN；数学参考、行为内存、真实2Gb芯片/PHY和整机实现分别验收。

## 3. 用户路径核对及当前审计

VF长目录11672文件含24份展开ddr3.v，SHA256均AF83D644D4471A88E9D732AED012BF486FEE75BE79031660452F576FD56F20EA；两个SC1336 ZIP各含一份。Demo展开5254文件，IMX219 ZIP含一份。共27模型均默认4Gb/x16，第122/123行的2Gb分支引用缺失2048Mb_ddr3_parameters.vh；找到模型不等于已拥有V4匹配2Gb仿真依赖。只读ZIP目录/文本，没有下载、解压写回或执行。

本机RAM模型完整SHA256为DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33，与FE清单一致。[当前文档检查](document-checks.json)记录本轮文件/链接/ID/追踪及基线；[前轮23文档快照](document-checks-canny-v0.2.json)仅作历史。FE v1/28输入、FM v0.1、窗口v0.2不改。

没有新的业务实现或模型获取批准；原两项申请保持待答，不重复提问。未生成RTL/参考/脚本/TB，未运行仿真、综合、PNR/STA或bit/hex，未改正式数据库/节点状态；理解和硬件观察仍未检验。
