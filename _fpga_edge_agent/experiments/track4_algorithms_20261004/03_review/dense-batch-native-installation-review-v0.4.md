# DENSE 批次安装、partial 与上下文借用限定审阅 v0.4

2026-10-05。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。当前目标仍为原五基础/六高阶的完整软件实现验证。本轮有具体接口和释放顺序修正，没有生成本候选业务源码、参考、功能脚本、可执行测试/TB，未跑仿真、综合、PNR、STA或bit。

阅读顺序：[整体/职责 B–C](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001.md)→D1/D4管理→D5安装/借用→E0.1中文交接→F4字段和读事件→G/H验证与追踪。原[v0.3精确快照](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001-v0.3.md)保持原字节；[数字附件v0.4](dense-batch-native-numbers-v0.4.json)仅为文档算术，不是参考程序或测试结果。

## 本轮具体结果

1. busy新BEGIN的owned0/lease0仅表示此次没有新预留，不能清旧实例或将旧lease当新回执。新owned1必须匹配真实新预留、完整echo/pub/lease；partial保同一reserved CTX和实际query expected，不用组件valid0推断无责任。
2. 固定三步核查只用现有RC slot8 POINT/slot14 DENSE：POINT→DENSE→RELEASE。IKEY548/请求550/回复870逐字段定义；O独立接纳的高548保护实际原stage，历史lease严格增长/warm保留，串行复用原fullcheck/cache窗口，不重复pin或免费扣旧保存区。
3. POINT token/count来自真实完整descriptor，valid_count22先核≤2073600再装E21。部分失败的RELEASE仅按原IKEY及真实DATA关闭核验，未使用字段canonical零，不能要求full_valid或两份未核tuple。
4. CTX只读view以原client DN_WQ426完整DNKEY/post作独立来源，保持至真实group FACK及metadata/引用/运输GAP。DATA在END/307前实际封关，CONTROL仅保身份，不再授数据/prepare/物理访问；实际sole POOL/ENV关闭桥仍未冻。
5. 初审发现guard free先于末管理ACK会使仍live的lease/CTX失保护，已修为DATA关闭/RELEASE回复→旧group引用关闭→形成管理ACK且继续阻stage mutation→正确消费与全部旧metadata/GAP→双方最终撤guard/CTX/lease。不让回执产生等待自身消费，也不提前释放保护。
6. DDR正常关闭针对旧授权scope，不要求停止refresh或新增无来源drain针脚；仍缺匹配C2 Elitestek v1.1的B完成/后续读写排序合同。示例未接出BRESP，后续后端必须完整核BID/BRESP、RID/RRESP/LAST。异常无隔离证明时旧Q/债务保留，不以cal恢复、静默或一次读回自动回收。

## 有限字段与事件账

| 项目 | 当前所列数值 | 边界 |
|---|---:|---|
| 安装两端RQ/RSP保存 | 2×(550+870)=2840bit | 不alias管理CMD550；没有新增第三副本 |
| O/STORE具名控制 | 10+11=21bit | 不代完整异常/外部责任账 |
| 本轮增量 | 2861bit | 原v0.3所列8520→11381；加JL78为11459 |
| 每项独立CHECK读取 | 113+32+32+15=192 RE | 原RJ/pin/descriptor/CR ADMIN_READ；两项384/批 |
| 完整32批CHECK读取 | 12288 RE | holder/provider/动态grant/release/回调/仲裁/停顿另计；不是时钟上界 |
| 正常新口fire | 93376+192=93568 | 与JL2935296及typed32E分开 |

SC/CR原context2257、descriptor/pin1152、LOOKUP1358、assembly300/sequence43与原DN两端1466保留。JL部分13157及RAM186/194分支不变；全机资源、服务时间、STA和fit未证明。JSON的933明确改为v0.3历史比较，不能与当前11459混算。原五组E样本逐字段保持。原完整512θ/21bit/1080p及识别质量范围、FIRST INIT/32次DDR CLEAR保持。

## 实际读回与独立审阅

| 审阅者 | 实際保存后读取 | 结果 |
|---|---|---|
| root | 初稿主卡1–142/143–238/239–348；JSON1–563另完整重呈；最终卡149/161/182/189/309和JSON历史字段/四新增门 | 已读回本轮全部主卡及JSON，末次只改有限delta；不能代整包软件验证 |
| dense_semantics_compare | 初稿79–184/216–240/300–330；最终149/161/182/189/309 | 提出保护早释放和partial验证两问题，修后有限delta未见确定等待环 |
| dense_native_numeric | 初稿D5 143–161/F4 276–282、JSON全1–563；最终历史命名与新增门、数值身份 | schema/21控制/2861/11381/11459/12288/93568及五样本相符；九来源SHA相符 |
| dense_cost_compare | 初稿111–120/143–182/216–238/276–282；最终149/161/182/189/309 | DDR正常/异常scope和BRESP证据准确；最终保护寿命修订通过限定检查 |

root本轮另读requirements全文、SC31–139/190–234、CR94–145/190–244、DIR76–120、SM55–105、DDR资格1–133、Q0 1–28及资料请求全文25行；公开C2 ddr3_top1–192、axi4_bus_ctl1–100、top594–622/frame_buffer76–97；本地HTML fd169–190/overview169–186。受保护IP只读公开边界，没有读取保护正文。截断组合输出已单独重呈相应完整段；未将局部读段当整包全文。

最终主卡348行/64650B，SHA256 `BDCD4C3FB7F2D778240591104F90578D74B37359C079B246C3DA66FA0CBDA360`；数字附件567行/21186B，SHA256 `C5981CC783AE669CC19117ED7D59040C35EE7337169E07E6D3FE877FF2332CCA`。原v0.3快照304行/52761B，SHA256 `E47EDE2359FC21C2EE36AB91DB87DA311E355AF92B6016C08B4B1AF7867F0854`。初稿两项修订前身份为卡B6AE…/JSON A701…，不能把初审当最终全文审查。

## 未完成与下一步

DN-B01实际holder/fullcheck、原SC FENCING、partial责任迁移/回调/最终双侧门仍需组合定稿；DN-B02可信prepared/effects/许可/真实物理可见与关闭桥仍需匹配控制器合同；DN-B03全部唯一实例/保持槽/失败账/服务与CDC/STA预算未闭合。本卡未达到READY，不询问新批准、不冻结实现基线。

R1灰度/中值/Sobel既有123/123、综合/PNR/STA/bit交付仍只覆盖原R1；完整十一项未交付。R2 stream48份/Q0 44份原待答审批保留。当前44保护项及R1 22/R2 48/Q0 44输入bytes/hash复核相符；正式state/Manifest/任务账本、原HDK/来源卡与R1产物保持。PostgreSQL未配置，R1本地审计例外不扩用；仅记本地文档检查点，没有正式数据库、硬件、网络下载/安装或新EDA操作。

元数据首写误用PowerShell布尔字面量导致新增section缺失，已在交付前更正、解析及字段断言并由独立numeric复核；一次不存在DATABASE_NOTES路径读失败，随后读回真实database/README全文。两者均无业务/正式状态副作用。共享审计原无效第24行及历史null保持，不声称全文件无误；新增检查点须以真实换行追加并保持原字节。
