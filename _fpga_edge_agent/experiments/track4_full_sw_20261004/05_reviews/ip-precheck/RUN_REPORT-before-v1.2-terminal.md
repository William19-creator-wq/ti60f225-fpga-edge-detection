# 已批准IP预检：实际运行记录

2026-10-04，Efinity2026.1.132、Questa2024.1，Ti60F225/I3。当前为**有限预检实测，整包未完成**。授权及原字节设计快照见[批准v1](approval-v1.md)、[输入修订批准v1.1](approval-v1.1.md)。原89输入、修订91输入均实际重hash匹配；所有运行在独立work，未使用旧outflow。

## 实际阶段与结果

| Case / 输入截面 | 已运行的结果 | 后续阶段状态及原因 |
|---|---|---|
| C0 attempt1 / 89输入 | Efinity `--flow map`退出1：两个原I²C头文件未在清单及副本中 | interface/PNR/STA NOT_RUN；首次日志完整保存 |
| C0 attempt2 / 获批91输入 | 补入两份原头文件后重新map，退出1：缺原`Panel_1080p_reg.mem`，top:783指定其初始化、true_dual_port_ram:52读入 | 未取得资源PASS；interface/PNR/STA NOT_RUN，输入闭包全面审计及修订正在完成 |
| C1 | 未执行 | C0 baseline尚未成功，SKIPPED_DEPENDENCY；不能预判ASYN0去桥省额 |
| C2.original / v6实际60引用、135输入文件 | Efinity map退出0，综合/映射PASS；Questa15厂商行为模型编译退出0，实际DUT编译退出2 | CSI保护区459行无可用解密key，vopt NOT_RUN；无TB、无vsim/run、无功能仿真 |
| C2.clock-corrected | 未执行 | CLOCK_UNRESOLVED：外部摄像DPHY byte时钟无法从core100/HS_BYTECLK70参数证明；按批准D停止该分支 |
| C3 | 未执行 | 依赖C2.clock-corrected，SKIPPED_DEPENDENCY |

C0缺输入是清单准备错误，不能解释成DDR保护IP不可综合；首次、第二次错误分别保留。C2的Efinity支持该实际源综合，但不证明Questa解密、DDR校准、摄像模式、吞吐或完整十一功能已通过。当前未执行布局布线/STA，不拿原厂历史报告补缺。

## C2.original实际综合预算

直接来源：[map报告](../../../../work/active/track4_ip_precheck_20261004/C2/outflow/ti60f225_oob.map.rpt)2783–2802及[层级CSV](../../../../work/active/track4_ip_precheck_20261004/C2/outflow/ti60f225_oob.res.csv)。报告生成时间17:34:48；日志实际完成时间见side-effects，Elapsed synthesis132s。整个参考不是新增算法工程。

| 整体资源 | 实测数量 |
|---|---:|
| EFX_RAM10 | 85 |
| EFX_DPRAM10 | 4 |
| EFX_FF | 10840 |
| EFX_LUT4 | 18363 |
| EFX_ADD | 1591 |
| EFX_SRL8 | 1164 |
| EFX_DSP48 | 4 |
| EFX_GBUFCE | 1 |

层级包含关系：DDR父39 RAM（FF2785/LUT3575）**已含**其异步桥17 RAM（FF204/LUT290）；CSI父11 RAM（FF1188/LUT2488）；frame_buffer父28 RAM；debug父2 RAM。父子不重复加。当前C1/C3未跑，ASYN0具体节约仍UNKNOWN。

CSI来源是XML实际引用的`rtl/csi_rx_controller.sv`5.15/HS_BYTE70/core100/FIFO1024/Discontinuous/PACK15；没有调用旁置5.16/HS50/2048设置或升级保护IP。当前参考不观察完整PPC/metadata/error输出，综合资源不作为新增生产NORM的完整上界。警告中有CSI冗余CRC数据删除、未驱动MIPI输出、DDR calibration内部未驱动网接地、10,240bit gamma memory因异步读映射逻辑，以及8条综合后端口未连接；均保留原日志，不静默修复或当成零开销。warn99–101还记录ser2par_v1静态除零返回x，复用视频路径前须调查实际参数/分支影响，不能由map PASS判功能正确。原参考RAW8截断/显示连接不等于完整RGB888生产方案。

## 仿真编译与时钟证据

[厂商模型编译日志](C2-questa-vendor-vlog.log)：15个真实行为模型，Errors0/Warnings0；[实际DUT编译日志](C2-questa-DUT-vlog.log)：59个`.v/.sv`，`.vh`仅include，未递归编译目录或加入TB。3条错误在CSI459保护区：No key to decrypt / protected syntax / protected scope；停止展开，未替换空maplib或删保护逻辑。

[独立clock/Questa范围审查](C2-clock-and-simulation-scope-review.md)给出实际peri/top/SDC路径。`<USER_PERIOD>`可按25MHz来源候选改40ns，但尚未修改/生成PT命中证据。外部CSI byte100只是旧SDC假设；70是生成参数，core100为另一时钟。C2修正分支的停止条件明确，不擅自把100改70或降低所需视频频率。

## 输入、命令、审计与范围

实际命令：C0/C2各在对应case运行`efx_run.bat ti60f225_oob.xml --flow map`；Questa按本地vmap/vlib、15原语vlog、XML顺序DUT vlog执行，精确输入见[C2编译输入](C2-questa-DUT-inputs.json)，没有调用compile/full/pgm。每次真实退出与时间在[追加副作用账本](side-effects.jsonl)，原始控制面事件同session-IP-PRECHECK-20261004。

C0 attempt1/2完整工具日志分别在`C0-attempt1-logs/`、`C0-attempt2-logs/`；两次console独立保留。C2源/保护RTL/IP设置135项阶段后检查：134项字节不变，仅case XML被官方工具改sw_version及格式/根运行元数据；全部子元素语义相同，见[C2阶段后检查](C2-postphase-input-check.json)、[XML元数据差异](C2-project-metadata-delta.json)。不是IP重生成。

[范围检查](scope-check-v1.json)实际发现work内bit/hex/bitbin/hexbin数量0；未编程、未联网/下载/安装、未改正式数据库或硬件状态。本地审计例外仅本次软件预检。正式PROJECT_STATE摘要`87BF105C9DA5C9304A3D7675520E1CA324D4CE51A055DA18FF3DA4B7665B2558`。

后续：先完成C0完整输入审计并按指定基线修订恢复；不扩大当前批准为算法实现。资源与失败证据反馈整包设计；完整生产后端、接口联合版本、资源/期限和独立功能仿真仍待闭合。

独立限定结果核对实际绑定本报告上一版SHA256 `DBD459496FC0F222DF278BEB8B2FE47F6279F6954EC8ADD8FCA8EBA9E6F76B25`/5377B、全部51行及资源/两个Questa日志/135输入，未发现新增反例；它同时指出上述静态除零警告，root已定位实际warn99–101后补入。本句追加后的文件不是该旧hash报告，不能冒称审阅者已读所有最终增补。
