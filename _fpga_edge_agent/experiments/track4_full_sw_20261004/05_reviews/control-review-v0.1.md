# CONTROL v0.1实际读稿审查

2026-10-04；TRACK4-CONTROL-001；DESIGN_REVIEW_NOT_FUNCTIONAL_TESTS。结论为 **LOCAL_DESIGN / NOT_APPROVED / NOT_READY**。本轮只保存本评审，不修改主稿、相邻基线、原资料、正式状态或数据库。

## 1. 实际阅读与版本绑定

实际全文读回[CONTROL主稿](../../../planning/design-TRACK4-CONTROL-001.md)B/C整体、D接口与有界记录、E操作及同沿规则、F/G/H契约与追踪、A/I阻塞与门槛；最后再次从磁盘核对D2同沿替代判定及SHA。前轮FM、PLATFORM、CAMERA、DISPLAY、Canny和识别的只读合同分析是输入，不能代替这些父模块吸收新接口后的联合审查。

本次最终绑定主稿SHA256：`A0CE9329AA2D0F8914150A9DE350F473011F506744F79E1ADAE8207E796B50A6`。本文不自包含自身hash；主稿以后变更须重新绑定。

## 2. 已发现并确认落盘的修正

| 发现 | 实际主稿中的修正与边界 |
|---|---|
| WAIT_FIRST旧FREEZE可能阻止RESUME进入 | IF05、D2、OP06明确T、独立已接受R605及本地未提出意图；R ready不等旧T完成，T/R各自预留done938。旧T生成并交付ABORTED终态后R转新T；不覆盖held终态。最终FM/DP阶段谓词仍CT-B03。 |
| UI观察反压可能卡APPLIED及租约回收 | OP08分离可更新live和不可变held读响应；UI慢读不得反压APPLIED业务ACK、RETIRE、fence及返租约。旧receipt/done继续结账。 |
| 静态非法D持续自动重提 | OP05保存当前D版本拒绝状态；静态字段/profile失败等待新D或明确资格变化；VERSION先取得新C再重建。 |
| 替代来源不在原回复位宽中 | IF02改reply274；SOURCE_UI134进入P/C。D保留已锁入P状态，P结账后不把旧D重新当未提出。 |
| 同沿P锁旧D、新UI写新D时误报替代 | D2明确使用旧已锁标志或本沿P锁存的合并判定；该沿superseded_before_proposal=0且superseded_UI133全0。 |
| BUSY完成缓存导致永久BUSY或同seq换op | D1明确BUSY不进最后完成缓存，重试重新检查容量；proposal_seq跨op唯一，同seq改op拒绝。 |
| 完整SET_CONFIG没有实际入口 | D1明确结构化入口及其来源/回复容量仍CT-B02；UI133不承载CFG212，T10是待冻结入口的文字场景。 |

本次限定复读未发现上述修正之间新的直接文字冲突。D/P/C、T/R及本地最新意图均有有限记录边界；普通更新不为每个版本等待APPLIED，已提出P及已接受T/R保持原身份。实际job采用保存在既有有界任务/结果上下文，旧APPLIED不回写D/C。此结论是设计审阅，不是功能或实现证明。

## 3. 字段算术

| 候选类型 | 按主稿字段相加 |
|---|---|
| UI133 | 32+32+64+3+2=133 |
| reply274 | 133+2+5+1+133=274 |
| SOURCE_UI134 | 1+133=134 |
| CFG212 | 2+1+11+11+11+112+64=212 |
| COMMITTED570 | 64+32+64+64+212+134=570 |
| PROPOSE605 | 32+32+64+64+64+3+212+134=605 |
| receipt1182 | 605+2+5+570=1182 |
| done938 | 605+2+5+2+1+195+64+64=938 |

上述均为设计算术，不是生产packed端口或资源综合结果。无效来源及无origin按主稿规范零值处理；valid与完整身份不能由generation是否为0推断。FJ110、Canny job917、OFFER1963不被本稿暗中扩展，新增父元数据关联仍待CT-B02联合吸收。

## 4. 剩余阻塞与未运行项

CT-B01…08全部保留，尤其CT-B02的FM完整配置、来源关联、结构化入口及观察读口，CT-B03的FM/DP ABORT与RESUME两阶段及真实done谓词。RC profile实体、暖会话关闭/保持域、AON与core CDC/STA、四键与LED真实引脚、电气、全FF预算、真实DDR/PHY及整机质量/吞吐仍未闭合。待吸收的新端口不得伪装成当前FM/PL/DP基线已经提供的保证。

CT-T01…24全部 **NOT_RUN**。本轮未生成业务源码、功能脚本、可执行测试或TB，未执行仿真、构建、综合、PNR/STA、下载或联网；未生成pin、bit/hex。根v0.2无当前正确性阻塞门槛尚不满足，不能标READY或取得实现批准；完整十一项交付目标保持。
