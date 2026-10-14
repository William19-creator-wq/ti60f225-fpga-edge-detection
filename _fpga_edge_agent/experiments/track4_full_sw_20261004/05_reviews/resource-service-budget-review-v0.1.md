# 整机资源与服务预算实际审阅 v0.1

关联[预算主稿](../../../planning/design-TRACK4-RESOURCE-SERVICE-BUDGET-001.md)及[完整主计划](../../../planning/design-TRACK4-FULL-SW-001.md)；2026-10-04。只读/设计审阅，整机LOCAL_DESIGN、NOT_READY、NOT_APPROVED；业务代码、功能脚本、可执行测试/TB及本次仿真/综合/PNR/STA/pin/bit/hex均未生成或NOT_RUN。

## 1. 已实际读审的方向与版本

- DS/PL方向实际读A/D1–D3/E2–E4/F，读到修订后E8F0C58F104C923322866EE7F4FED88EBF5E4C41BE1D3F8725753CE26D3260BC；核439有效bit、31008/56054/62034、PL21272、225RAM、native word及历史/服务边界，无新增实质错误。
- FE/Canny/CAMERA/DISPLAY方向实际读D1/D3/D4/E3/F的初稿1DA205BD6DABFA72D383CF6E959F6D5AFB0D6CCB234BE999FF4D0594F17BBEB8。指出FS163+feed253应416而非409；C03984、Canny增量12962/含FE15940、三组执行候选57358。另明确Q512内344是冻结计数、168是诊断/标志；集中W包含CLASS/GRAD/EDGE、queue、SC。root修改后实际全文读回并逐项算术一致。
- FM/CONTROL/JOIN方向实际读四父稿及两中文附件，并核DS/PL/DP/RC相关字段，提交81737全宽FF直译例、有限canonical记录/控制/观察/reader候选及独立通道去重；明确不是FF最低值或已闭合布局。最终D5仅据该报告和root算术汇总，未声称该方向全文读过最终预算稿。
- 最终主稿SHA256：AF2C2ADFB66AEAA6A1E872AC067C28FFC8A673D836A88B750C4E7FA17BE44D11；35894字节/20381字符。root实际读回与预期全文严格相等。其后加入的D5候选表没有改前两方向审过的DS/PL/FE/服务字段；不同版本和阅读范围在此分别记录。

## 2. 数字与证据边界

RAM为44+17+105+21+13+21+4=225；FE8包含于Canny44，PL旧PIX9由DP21替代，PL/CAM两NORM192捕获是同一FIFO读端，只增6bit、只计一次。camera两源bank是2048B payload，四RAM物理5120B，不能扩大成四bank。

DS原列容器31008，RC局部29168合60176；DS完整候选56054或含明确诊断选择62034、PL21272、FE/Canny/CAM/DP57358不能无条件相加成全机真实FF。normal ACK共同身份借pinned record，错body回显仍需有限存储；P3不同DS shadow字段方案不取最低值，也不重复相加。最终状态、观察、热冷与完整路由还未统一；全部未知IP单列。

官方资料区分XLR62016/LE60800，旧place实际XLR44027/60800。FF与LUT/ADD/SRL packing及DSP12/24与物理DSP不混；旧2025-07-07 DDR22仅条件比较，不代替当前protected IP资源。source map/place原SHA实际核对，未重建原参考。

mode5每row6480B、405拍、1248core机会，100MHz理想12.48µs对14.8148µs只余2.3348µs；RR机会/理想带宽无固定期限。识别三项byte工作界合1907313868800B，1192.071168s只是除理想1.6GB/s的成本尺度，非实际帧时/实测worst或FPS。未恢复用户撤回的尺寸/比例/目标数/噪声硬界。

## 3. 仍需解决的事项与保存范围

RB-B01唯一容器/完整热冷/最终状态及观察、RB-B02匹配DDR/CSI/serializer合同与内部资源、RB-B03行期/采集/EOF回收的真实有限服务界、RB-B04联合版本和既有实施/模型/DB前置仍保留。未运行品质/综合属于批准后证据，不循环要求先生成未批准测试。既有FE与模型问题不重复发问。

本次保存预算主稿、本实际审阅、五入口/索引的v0.19更新；前61MD执行检查以8BC7140A…8DA7A953原字节存历史，当前文档审计另重绑。原HDK/资料、父稿、正式H0/ledger/Manifest及数据库不变，未联网/下载/安装或操作硬件。文档检查PASS仅表示链接/围栏/表/算术/哈希检查，不意味着软件实验完成。
