# TRACK4-CHECKPOINT-20261009-V4-001 v1：本批交付校验与观察图

2026-10-09；按PLAN_TEMPLATE简短基础设施变更卡。Goal：把两新单元（reader7、capture组合7）真实通过证据绑定到旧140文件检查点，提供可人工观察的实际软件像素图。Current：reader已登记EV019、组合小图/窄图/MAP通过、1080p仍运行。Target：仅全尺寸PASS且新包已登记后建立v4检查点；整目标仍ACTIVE。Gap：最终HD/登记前提；不会把运行中当通过。Assumptions：现有Python/Pillow/字体可读、原staging只读。Open question：无当前正确性未知，若Pillow不存在则保存验证结果并报告图片未生成，不安装。Dependencies：v2/v3原checkpoints、十份组件manifest、新两单元source/frozen baseline。Milestones：条件检查→hash/数字→数据图→v4→事件读回。State：READY读回后按用户“当你统计完后自行进行，无需我的批准”自主实施本脚本与本地审计；正式DB/state/hardware不改。Failure：任何HASH/PASS/长度/像素域不符立即失败，不改期望/覆盖旧产物。Rollback：仅新脚本和新命名v4/图片，旧资料及checkpoints保持。Completion：全部下列断言真实通过，标PROGRESS_FULL_GOAL_ACTIVE，不能标整机完成。

## 整体、局部草图与映射

`delivery_tools/capture_checkpoint.py`：输入是已存在的三个组合PASS run（small_010、narrow_001、hd_001）、reader PASS/MAP/已登记包、组合已登记包和旧checkpoint v2/v3。输出位于实验05_delivery，不覆盖已有文件。先核通过/finished、窄图held-FP witness和discard>0、HD几何1920×1080和2,073,600像素、两MAP结束exit0、两新包manifest及其全部files hash。按旧v3的8组件+两新组件逐项核所有登记文件hash；再核旧v2/v3的37+33工作文件及新14工作文件与各包source同名hash。不能把文件数称模块数，不重复计镜像/共享子模块/文档/数据/infra脚本。旧初始70项沿旧已登记证据，不虚构本轮重新逐文件核全部154。

图片直接来自通过HD的actual source.bin和result.bin：检查源3N、结果N；结果只0/255，sum(edge)=独立参考。RGB按实际R/G/B连续字节保存为完整1920×1080；结果L8原样保存；观察叠加在edge=255的像素取红255/0/0，其他原RGB保持。三份native PNG和缩小概览附source/result/PNG SHA与尺寸、ACTUAL_SOFTWARE_SIMULATION_NOT_HARDWARE标签。概览仅供阅读，不作像素精度证据、不宣称RTL叠加已集成。Pillow现有API属于数据图，不调用图像生成/网络/安装。

v4 JSON精确标注previous140+new14=154，已核work84、登记file总条数和zero drift、MAP46RAM等真实数字、2新包、物理/CSI/FM/识别/PNR/STA总bit仍未完成，既有用户授权、formal_state_changed=false。新事件EV022只追加两个既有JSONL，含checkpoint/报告/图hash；同ID已存在先失败。所有写入均在控制面，新名称若存在先失败。最终读回JSON并复核Manifest/图片hash；用户实际理解未验。

验证：CP01三个run及窄图触发/HD几何真实PASS；CP02源/登记全部摘要一致；CP03实际图/位图长度、像素域及edge数一致；CP04没有覆盖旧文件，事件append只一次，正式状态无修改。Python3.14整数任意宽，文件严格UTF-8/二进制读，paths限定本控制面。API/RTL数值合同不改变。

追踪：已完成数字→run审计→CP01；可恢复交付→artifact/source manifest+previouscheckpoint→CP02/04；人工像素观察→actual source/result→CP03。没有业务RTL变更，硬件动作不适用。

现有D:/py___ Python无Pillow；已用桌面只读依赖定位确认现有bundle Python路径，使用该现成runtime生成数据图，不安装。HD实际已PASS。登记/图片/检查点顺序继续执行。

CP首次执行在写入任何图片/报告/检查点前失败：reader的reference-audit不使用capture的metrics字段。按实际读取的独立schema适配：双方audit.status=PASS、suite.finished=true，结束证据各自来自已有protocol-metrics.finished。只改变登记校验的字段读取，不修改原测试/参考/源码/证据，不用缺字段默认通过。保存/readback后再执行。
