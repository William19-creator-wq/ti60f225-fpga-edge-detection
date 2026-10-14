# Canny闭包内部组织：串行候选限定读回

2026-10-08；DESIGN_ANALYSIS_ONLY / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。上一目标轮完成STATS具体设计/54输入冻结属于设计进展，本轮不是等待运行中的EDA；实际进程核查owned_live_process_count=0。完整十一项仍未完成。

## 实际新增和新证据

新建[单操作串行提交草图](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-CLOSURE-SERIAL-001.md)，按整体→读者/接口→有限postimage→具体语句/旧沿→错误/取消→验证追踪写清一条替代路径。没有修改原R4C/BK、主机模型、业务RTL、已交付代码或正式状态。

原R4C D3实际规定324/449单信用，BK E2规定一次普通操作未结清不接下一op，且成功回复在物理效果和END之后。因此正常操作中的两次物理写之间没有另一个合法typed请求。这一事实支持“在最后两写均完成后才形成逻辑COMMIT”的条件分析；还不能从single-credit推定所有物理旁路都被关。

实际限定读取DIR的descriptor/read-pin/write-pin/初始化/COMMITTED段及CH的938/RETURN/PUB段。CH S_FINAL938的字段是台账/quiet/初态与提交token及计数，没有postimage字段；这排除了“必须把postimage送到CH才可封存”这一外部payload依赖。它仍含journal/native/permit/borrow quiet，不能把quiet常量置1或删除其它caller的共享journal。下一实际调查转为S内部诊断/旁路及quiet来源，而非新增CH postimage字段。

FPI与AXI是两层公开承诺。已将草图E3修正为：S只根据自己是否已公开FPI决定保持/停止后续发布，A独立处理AW/W/B物理边界；取消不能因为S看不到AW就擦掉旧FPI。候选没有采用改变原接口或窥探保护IP的方法。

## 数量与适用边界

原BK F的正常CLAIM journal为58WE+58RE+2stateWE；候选在独占及可见性条件成立时，只针对这份CLAIM研究移除116条数据事件和2条状态事件。116×2073600=240537600，2×2073600=4147200。这里是静态事件数，不是实际周期、RAM减少、速度或fps；授权/DDR/INIT/其它caller及全部控制容器仍保留。

保持full16B RMW、完整span授权和原初始化；没有引入未经验证的byte-mask、删QUEUE CLEAR、缩N或限制弱链长度。原精确八邻域与全N/P导出保持。失败允许真实部分写，但整私有build INVALID/不发布，未决效果及引用保留到合法关闭或隔离。

## 当前缺口与授权

SER-B01：所有可能mutable读者及共享A准入必须逐路径证明；SER-B02：匹配2Gb模型和真实IP写后读/异常关闭仍缺；SER-B03：CH payload已核无postimage，S内部诊断、其它journal caller和quiet映射仍OPEN；SER-B04：完整预算/文件/测试/共同基线待选择后冻结。故保持NOT_READY，不提出本候选实现批准。

本轮实际读了现有DDR后续核查与公开top/参数；已解出的库存记录仅4096/8192参数，模型den2048分支要求另一个2048头，不能用4Gb模型替代板载2Gb最终验证。没有启动Q1/Q2、重新运行Q0、改模型或联网；既有REQ-DDR3-MODEL-20261004仍待答。

STATS v1.1的54份冻结输入另逐项复核无漂移，新模块指定批准及本地审计请求仍待用户回复；未重复请求。ANGLE批准也不从自动续跑得到。规范§10.4要求“默认需要用户明确批准指定版本与范围”，纯设计记录沿已有控制面许可，新的业务实现/验证仍停在批准前。

正式PROJECT_STATE/TASK_LEDGER/Approval Manifest/DB/硬件节点不变，原staging不晋升；无业务源码/模型/功能脚本/TB、EDA、bit/hex、下载/安装/网络或硬件动作。具体源hash、读回hash及事件见同名JSON；只计算hash，不声称所有来源全文新读。
