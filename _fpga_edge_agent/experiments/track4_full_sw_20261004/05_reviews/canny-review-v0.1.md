# Canny v0.1只读设计审查

2026-10-04；[TRACK4-CANNY-001](../../../planning/design-TRACK4-CANNY-001.md)状态LOCAL_DESIGN/NOT_APPROVED。以下是实际设计/资料审查与落盘修订，不是代码评审、功能仿真或综合通过。

## 1. 三个独立审查方向

| 方向 | 已读范围与发现 |
|---|---|
| 数值/边界 | 规则链、v0.2、FRONTEND/00/02/03；推导5×5轴系数、仅最终舍入、梯度位宽、424整数方向、canonical平台和严格双阈值；落盘后发现Msrc/Mgrad/Mnms命名混用，已修正 |
| 精确连接/存储 | 规则链、v0.2、02/03、FRAME-MANAGER、DDR事实及本机RAM10模型；提出唯一claim、N容量单调队列、8KiB状态cache、committed_tail与append精确forward；避免把全帧visited或2bit图容量当实际访问开销 |
| 整条组合 | 规则链、FRONTEND/FM/00/02/03/07；发现不能复用Gaussian之前的梯度，分叉需各支消费记录，FE status及时消费，AW前整burst数据备齐，grad工作区需最后读租约；落盘后收紧RAM停顿和取消同沿措辞 |

三方未写原资料、未联网/下载、未生成代码/脚本/testbench，未运行仿真或构建。算法公式、资源和流量是设计推导。

## 2. 已落实的修订

- 输入Msrc8、原始Mgrad11、NMS输出Mnms明确区分；方向只看梯度零向量，阈值只比Mnms，NMS邻居从抑制前Mgrad读取。
- 5×5默认先纵向再水平，只最后+128/256舍入；值30/权重4反例期望0，提前按轴舍入会得1。
- 方向分界是424/1024整数契约，不用atan当黄金值；相等归轴向，平台顺序不随梯度反号改变。
- C4产生dir，C3只交付梯度/幅值；分叉两pending独立，每支一次，取消时两接口的交付前缀可以不同。
- FRONTEND合法小图不自动Canny合法；候选W偶数≥6/H≥5在组合启动前校验，拒绝事件/状态编码待完整接口冻结。
- 识别启用必须保存grad；识别最后读fence或bundle租约未归还时，grad地址不可复用。
- 停顿关闭新RE/WE并保持历史，不把上拍使能保持为1反复读写；取消同沿真实握手仍逐接口登记。
- 源读取/输出writer/DDR响应的推进相互独立；FE status及时保存；AW前备齐完整burst，取消不撤销已提出/接受的协议义务。
- seed扫描所有强边后执行队列/状态阶段fence；正常BFS只claim弱边，发现残留10视为错误；逻辑队列空后仍seal/fence再导出。
- tail、committed_tail、head分开；本地forward允许head超过committed_tail，银行在B成功前不可复用，旧read cache有效范围不因tail增长扩展。
- 连接复核补充新job缓存有效性隔离、descriptor按最早未提交范围保持连续前缀、银行B后仍需本地read/sideband捕获及prefix移交；小图物理state/queue区补齐64B/16B，padding不增加有效数量。
- 40块RAM只是已列共享FE/Canny窗口/cache/queue结构；64B状态线随机miss可放大流量，16B/64B、pin/归组、queue forward和精确快路径仍待同输入实际比较。

## 3. 尚未闭合的边界

CN-B01…08继续保留：新窗口逐拍/读写冲突、13bit历史端口、cache/queue完整状态及partial规则、MOD-05实际响应/可见性、job/status/取消编码、地址与租约、真实资源/时序/吞吐。帧管理FM-B01…08和匹配器件模型亦未关闭。

没有因这些审查将本稿升级READY。原FRONTEND v1及其28项输入保持不变；其既有待批准实现范围未扩大。用户尚未作理解验收，所有CN-T01…14仍未运行。

## 4. 读回与审计入口

最终文件及哈希、相对链接、稳定ID/A–L覆盖、24项原输入与28项FE输入一致性，以[当前文档检查](document-checks.json)为准。上一轮19份文档审计保存在[frame历史快照](document-checks-frame-v0.1.json)，不能用旧快照证明本轮改过的主计划/索引。

本页只登记设计层证据，不替代业务功能、综合/STA、真实DDR/PHY校准或整机完成验收。
