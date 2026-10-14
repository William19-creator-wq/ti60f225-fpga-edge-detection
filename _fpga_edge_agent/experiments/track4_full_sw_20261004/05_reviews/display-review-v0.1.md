# DISPLAY v0.1实际读稿审查

2026-10-04；TRACK4-DISPLAY-001；DESIGN_REVIEW_NOT_FUNCTIONAL_TESTS。任务仍为五基础＋六高阶至bit/hex，本轮为显示局部设计；**LOCAL_DESIGN / NOT_APPROVED / NOT_READY**。本批设计以MASTER v0.11为输入，当前主计划v0.12为新增索引，其他局部输入未更改。

## 1. 实际阅读与绑定

先读[主稿](../../../planning/design-TRACK4-DISPLAY-001.md)B/C整体，D接口/视图/scan/控制/组合，E状态和八中文操作，再[附件](../04_local-designs/display-fetch-and-scan-sketches-v0.1.md)§1–8，最后F/G/H/I。root实际读回与独立代理有界复审分别记录，原源包只读、不解密。以下为最终落盘SHA，未自包含本文hash。

| 文档 | SHA256 |
|---|---|
| DISPLAY主稿v0.1 | 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717 |
| fetch/scan附件v0.1 | 7071D79E7EB3550580C027ACD830BDDB5825CD1A16813C246446926548C08EA3 |
| HDMI来源v1 | 08A9CDA7D565AAF60AB6006A89EBE3DA6A40E4DCB7C41DB59ECE44C8CA7E1C03 |
| VF/Demo补充来源v1 | 6E8823391907B5D9A42E7DB854E01648EC522952F3DD9E61699AC03CF9B10979 |

来源层核v6 timing/PLL/声明/旧underflow/末AR银行切换/PN，保护体未知不推内部时序。用户指定两根实际资料与IMX219 ZIP成员另查，root原字节流计算7成员hash、读回两公开TMDS源码，核4Gb默认与缺2048头；不是全PDF视觉穷尽审查。

## 2. 独立读审发现与已修正

| 发现 | 修正、相关接口/测试 |
|---|---|
| 最新future PLAN可能撤销当前scan后续行资格 | current_exec与future_plan独立；实际SELECTED固定路线，CLOSED独立结束；DP-IF03、T12/13/18、DF-T10 |
| safe省略SELECT却有未曝光FILL，无明确未选证据 | 有预取义务必须use_data0业务决定，槽满保存在既有future_plan并暂停后续预取；无义务safe不等不存在SELECT/CLOSED；不新增scope；DP D3/OP07、DF OP06/T10 |
| SRC存在与扫描mask混淆，mode3 mask010丢冻结源 | SRC身份/desc/grant始终存在，mask只定扫描集合，EDGE/ANN缺省规范0；IF01/D2/T05 |
| 主稿6pair与附件2pair例冲突 | 最终adapter n：packed n−8/−7、SRC n−6/−5、权重−4/部分−3/Y−2/render−1；q0 h88…96统一；OP04/DF-T08 |
| SRC192bit与168bit小计冲突 | 统一192容器/真实最多21B；原列取数1052bit，render386bit另计，完整元数据/adapter/邮箱FF仍待证 |
| bank归还与整scope encoder关闭混为一件 | row仅等RAM RE/pending/cache/54holding借用；独立render/encoder值仍持scan/scope引用，CLOSED/local_closed分别核；T11/19/21 |
| 同seq不同body与SNAP→COMMIT冲突 | 去重键(op,control_seq)，合法续阶段仍核SNAP事务/Origin/policy，同op异body拒绝；IF05/OP06/T16 |
| fence箭头先于段release易读成互等 | seal/fence请求与段release、本地关闭并行，证书/local合取才status；D4/OP08/T20/21 |
| 小图末拍及“六bank36”含混 | L有效/A真实授予对齐范围，不足完整16B拒绝；六分池41RAM/194，六合并36RAM/189是不同替代布局；T10/24 |

最终独立有界复审实际读主稿D3及附件§5/6/7，确认上述safe route、独立授权/关闭、6pair与1052/386候选一致，未发现新的直接冲突或互等。早期review发现已留在本表，不将“未发现”写成功能/实现证明；完整父接口吸收和外部证据继续BLOCKING。

## 3. 字段、时序与资源算术

主稿8要求/8交接/8操作/10不变量/24文字场景/8阻塞/A–L；附件8交接/8操作/15文字场景/5阻塞。以下为设计算术而非测试运行：

- render112；OFFER1963/receipt1969；DISPLAY_ID687；APPLIED1503/ACK1509。
- PLAN522；SELECTED1013/ACK1019；CLOSED921/ACK927，各有独立有限槽，旧image CLOSED业务ACK后才建下image。
- ROW336/OWNED342/RELEASE343/ACK349；控制header227、COMMIT422、ABORT291、CANCEL914、SNAP1353；terminal840/return687/ACK693。
- SRC18＋EDGE1＋ANN2＝21RAM，替旧FIFO9，已列162−9＋21＝174/256（67.96875%）；不是整机综合结果。
- 固定1100pair×1125行，74.25MHz pair/148.5MHz pixel/742.5MHz half-rate fast；每帧2073600有效pixel、1036800有效pair；line14.8148148µs、active12.9292929µs、blank1.8855219µs，首DE前41line约607.407407µs。
- mode5 6480B/row＝405拍；6998400B/frame×60＝419.904MB/s。最低展开1248core沿＝12.48µs，只是乐观下界，额外协议/竞争/ACK/归还不得忽略。

三结果上下文、1 current_exec、1 future_plan双route及至多1 closing held元数据均有预算说明，不创建第四scope。暖复位/旧借用保持、source freeze/provenance、相关clock及GRAY数值分别归契约。全部TEST仍NOT_RUN。

## 4. 未闭合项与生成门槛

DP-B01…08保留：现用codec或公开TMDS候选选定及复用条件/reset/真实数值；相关像素/fast相位、serializer和旧流水闭合；FM/DDR/PL/RC新端口联合吸收；真实2Gb器件/PHY校准；所有负载的行/首帧/旧CLOSED ACK期限；双clock RAM/全FF/XLR/STA；最终引脚/电气/合理SDC；全机控制与指定批准、原工作副本/构建/DB条件。

根v0.2 §10.3的无当前正确性阻塞不满足，不能标READY。既有FRONTEND与模型获取申请仍待答，不重复申请、不把用户总体目标当新版本批准。原正式H/A/R状态、数据库、Manifest和原包未改。理解验收无用户作答，待检验。

## 5. 检查与历史

root保存后实际读回；[当前文档检查](document-checks.json)绑定本批45份MD，链接/表格/编号/哈希为文档检查。前40份CAMERA审计原字节保留在[历史快照](document-checks-camera-v0.1.json)，SHA566BFB270C83FE2ECC696E364F996B974B6C5D03EF266B09D68C0EC664AC9482。

业务源码、参考模型、脚本/tests/TB未生成；功能仿真、受保护IP验证、2Gb PHY校准、综合、PNR/STA、pin生成和本次bit/hex全部NOT_RUN。下一项允许工作为控制/联合设计与只读来源，完整目标仍为最终软件工程及真实验证。

