# R1 v1.1 实现独立读回记录

批准：`AP-ALGORITHM-R1-20261004-v1.1`；基线：`ALGO-BL-20261004-v1.1`。本记录只评审已批准的独立灰度／中值／Sobel 软件实验，不扩张后续 Canny、识别、DDR 或生产输入输出的实现授权。日期为 2026-10-05；正式数据库及硬件状态未改变。

## 阅读次序与范围

先从获批修订卡读回整体范围，再沿完整 R1 的 D/E/G/H 与继承 FE 合同，检查已保存的六个核心和六个外壳 RTL。局部先看二维独立参考，再看黄金打包与 TB 的实际交接，最后看构建工程、约束与运行证据。

Root 已完整读回两个独立参考文件、三份 R1 TB、当前 `run_r1_sim.ps1`、`run_r1_build.ps1`、三份工程文件及核心／外壳实现；随后已分两段完整读回前端共同 driver 的最终新增 all_empty 断言版。独立检查了下降沿驱动／上升沿旧状态 fire、原输出前缀计数、配置快照、状态背压、取消同沿旧输出、reset 重开黄金、无 reset 后续 job、九个实际阶段事件、RAM地址与碰撞以及无停顿延迟检查的条件。静态读回结论与实际仿真、物理检查、人工理解验收分别登记。

## 数值与记录的交接检查

| 交接 | 独立参考实际表达 | 实现／TB 的对应检查 | 当前结论 |
|---|---|---|---|
| RGB→Y | `(77R+150G+29B+128)//256`，完整输入先验证 | 两 lane 的低／高 24 bit 与 Y 低／高字节一致；RTL 用定宽移位相加 | 公式和位序一致；完整 suite 另记 |
| Y→中值→第二邻域 | 普通排序取第 5 项；两次分别在有限图中夹紧坐标 | 九级比较网络与中心旁路同延迟；第二窗口读取已过滤的有限图 | 参考未复制比较网络／RAM／状态机 |
| Sobel→edge | signed GX/GY 在 ±1020，L1 联合上界 1530，严格 `L1>T` | 11 bit 有符号差、10 bit 绝对值、11 bit 总和；元数据和输出同握手 | 宽度、符号、阈值一致 |
| FO→CRC记录 | M16、edge2、x11、y11、三个 ID 各32、标记3、高填充21 | TB 读独立 40 hex 黄金，逐一真实 FO fire 比较，不只比较末尾摘要 | R1 shell 002 实测通过 |
| FS→CRC记录 | code3、in21、out21、三个 ID 各32、高填充19 | 原始 status 被接受并保存；FEED 中提前错误不等待完整 N | 八个 typed 场景实测通过 |
| 160 bit→CRC | 非反射 0x04C11DB7，MSB 先行；另有 byte 多项式除法自检 | 捕获沿不移位；随后真实 160 沿更新；最终 snapshot 使用最后新值 | 每条实际完成记录均检查 |

外壳 CRC 对 FS 的诊断坐标不作摘要，保持原 FE 诊断接口。LED0 的完整 OK 标志不是图像黄金或硬件成功的替代判据。

## 首轮真实外壳结果及审计修订

`sim/r1/runs/r1_shell_002/run-result.json` 为实际 COMPLETE，七个正常工具仿真均退出 0，三个故意 fatal 探针均退出 3 且没有成功 JSON。统一 vlog：Errors 0 / Warnings 0。8×5 首次展开保留 vopt-10587（+acc 减少优化）的工具告警，不隐去。

| 场景 | 实际完成 | 交付数值／记录比较 | CRC 完成比较 | 数值／协议错误 |
|---|---:|---:|---:|---:|
| top 4×3 | 69 job，64 种配置，处理中 reset 1 次 | FO 415；records 484 | 483 | 0／0 |
| top 8×5 | 69 job，64 种配置，处理中 reset 1 次 | FO 1381；records 1450 | 1449 | 0／0 |
| 四个 258×258 图样，各自 | 33282 pairs；边界 pairs 1290；保持 7397 沿 | 所有 33282 pairs | 不适用 | 0／0 |
| J/K typed 场景 | 8；CRC忙时 reset 1；耗尽边界 2 | records 47；FO 反压4770沿／FS1260沿 | 46 | 0／0 |

记录数比 CRC 完成数多 1 是真实处理中 reset 撤销了一条已捕获记录；不能将这条记录标作已完成 CRC。

002 原报告只冻结 17 项（原厂 RAM、12 RTL、3 TB、参考 manifest）。后续 runner 增加了两个模型和自身的开始／结束 SHA 核对，必须在新 run 中执行；002 不回写成 20 项版运行证据。当前最终采用 **r1_shell_005**：Root 已实际读取原始 JSON、22份治理输入和必要计数，并独立重核20项运行输入 SHA 全部一致。状态 COMPLETE、governance_unchanged=true、22项冻结输入0失配、七正常运行／三故意 fatal；结果 SHA `559E01DA657A2C437BA43BA9EB624F423919A9893DC1F8BE81A50C09782653D4`。表中数值计数与005一致。最终选用的 release gate 另行列清。

Root 已读回每个实际正常结果及三个 fatal 的退出码，也实际查看 fatal 日志和 `top-W4-H3` TB 的捕获／首 bit／末 bit／reset 路径。批准合同允许的末两 job 序号初始化只出现在 J/K 组件测试，未强制真实 FE 的 status、done 或状态。

## 物理检查与补强项

三份工程配置已实际保存：Ti60F225 / I3 / SV2009，生产 1920×1080 参数；J2 的 25MHz GCLK、P13 KEY、N14／P14 LED。KEY 电气沿用板外上拉，工程不额外启用内部上拉。全部原厂参考和 RAM 模型保持只读。

SDC 明确 40 ns 主时钟；KEY 仅到两个已映射异步 SR 端点的例外必须各命中一次。一级 Q→二级 D、二级 Q→core 和 RAM 仍需实际计时。LED 异步静态输出例外不能扩张到内部路径。Root 已完整读回工程与约束，物理报告尚待最终审阅。

`r1_physical_001` Map 实际退出 0，报告中的 LUT4 为 **1886**，FF2305、ADD575、SRL8 78，8 RAM10、0 DSP；这不是最终 XLR 合并计数。早期消息把“LUT4=1886”连写成“LUT41886”，已核实不应解读为 41886 个 LUT。Interface 首次失败的原始日志保留，配置修复与新 run 另记；尚未通过布局布线／STA。

FE 状态代码静态路径：正常进入 STATUS 前检查 all_empty；取消和坏输入的同一个沿清除所有内部有效性／窗口 pending／horizontal／phase，下一沿 STATUS 保持。共同 TB 已补充 STATUS 下 all_empty 的直接运行断言，`protocol_probe_001` 使用独立目录关联原黄金 hash 检查，完整新 suite 将同时使用这份 TB。补验不覆盖或冒充原全量 suite。

005 的真实失败已经排除延迟假说：窗口单核没有 FS，FT05 场景元数据却默认 expected_status=0，runner 因 TB 真实 observed_status=-1 不相等而报失败；这不是 RAM、数值或停顿时长错误。仅将该参考场景的状态改为 NA，数学、RTL、原厂模型不变。新模型 SHA `4D81E977D1A8633B20497A1BA5A6E664D63E5730652380684B68BBB65D955D7A` 与最终 shell005、physical003 的快照一致。旧失败不回写为 PASS。

physical003 的 Interface 已实际退出0。Root 阅读了 PT 工程报告与 timing 表，并定向核 pinout 四行：J2 clk_25m.P / 1A / 1.8V，P13 key1_n / BR / 3.3V，N14 led0、P14 led1 / BR / 3.3V；时钟走 GPIOL_P_08.ALT 的 GCLK。KEY pull none、LED drive4；PLL／OSC／JTAG／LVDS／MIPI均无配置实例。后三次物理运行只补空registry，没有新增业务 IP。首个 PnR 已到 routing，但实际 get_pins 名称未匹配 SR，SDC exactly-one 校核报错、工具 exit1，不能采用其无正确例外覆盖的 STA 数字；修正约束后必须新 run。PnR 生成的 lbf 为中间格式，未调用 pgm，也未产生 bit／hex。

## 已有波形的独立读回

Root 实际阅读 `sim/frontend/observations/wlf_readback_001/readback.md`、三份 CSV 与三个原始查询日志，并重新计算三份源 WLF 的 SHA；均与记录的 before/after 相同，三个 `vsim -c -view` 查询均实际退出0。观察只读取已有波形，没有重跑 case，也没有修改完整006的冻结输入。

FT05 的84ns气泡允许提交上一 REAL 的延迟写，94ns没有重复写；114ns跨行读q0／写q3；144/154ns背压时两bank读写均停。214ns首 REPLAY 仍提交末次 REAL 的 pending 写q3，224ns消费 REPLAY pending 后不再写；因此不能把“REPLAY阶段绝不写”当作实现不变量。旧005的该案依旧是汇总状态元数据失败，波形读回不将旧run改判。

FT10 的窗口B尾部取消／复位实际在484ns出现phase272，486ns二者all_empty=1：取消提供status、复位不提供旧job status；1044ns恢复job均all_empty=1且正常status有效。这与TB真实交付计数和44项专项检查相互对应。用户理解读回、实体下载和硬件观察仍未验收。

physical004 的两个精确SR端点已匹配，但在SDC加载阶段调用额外 `check_timing` 报告命令触发现装工具异常，PNR真实退出1。报告命令移到布线后的独立STA查询，保持40ns时钟／复位例外边界，用新physical005验证；004失败及日志保留，不能用中间时序数字替代最终验收。

## physical005 的实际物理读回

Root 实际读取005的Map／Interface／Pnr退出结果、完整主STA报告、完整PT／PT timing、packed资源和route／hold fixing／CDC／warn／err报告，以及本run隔离postroute audit的Tcl、参数、日志、退出结果和完整两个coverage／clock报告。另读Q1→D2完整setup／hold及Q2→core／RAM各摘要与首路径，全部58条所列专门路径slack已实际提取为正；不冒称阅读全文的四份长报告。

正式005三个工具阶段均退出0、未超时；主40ns setup裕量35.381ns、hold裕量0.063ns。内部check_timing的no_clock、unconstrained_internal_endpoints、multiple_clock均0；2391个all_registers、1个clock、1129个core FF与8个RAM查询真实存在。完整coverage明确没有“无delay且无例外”的输入／输出；带例外只有KEY一个和LED两个。精确SR各1且网络均KEY，Q1→D2有setup39.527ns／hold0.124ns；Q2→core最小35.642ns／0.403ns，Q2→RAM最小35.916ns／0.803ns，未被整个reset域false_path切掉。主最差hold路径是窗口B pending_pair→recent RAM WDATA，处于有效同域约束。

packed资源3411／60800 XLR、8／256 RAM10、0／160 DSP、1／32 GBUF，满足本R1的≤8000XLR／8RAM／0DSP预算；综合LUT4=1886、FF2305、ADD575、SRL8=78与packed XLR分别列清。Root 定向核四pinout行，并读PT完整四GPIO表：J2 1.8V GCLK、P13／N14／P14 3.3V，KEY pull none、LED drive4，无PLL／OSC／JTAG／LVDS／MIPI实例。综合告警只列EFX-0200去除局部临时／冗余信号与EFX-0657将小／固定访问数组映射逻辑；原始日志保留，非0告警不改称“零告警”。CDC报告无synchronizer warning，不将其扩张为新生产CDC验收。

Root 独立核17份snapshot／active SHA一致；隔离audit所用原005的vdb、place、interface、SDC及全部实际route／trace相关文件SHA相同。真实trace为 `r1_algorithm.troutingtraces`（458582B，SHA99757F036FA5C00A0C775E55B9CDEF650A9F454F64CE2ADB715DEC1E8B663093），工具实际reload trace。参数中的`.route`文件不存在，不用空hash相等作为证明。原厂write_sdc导出的四条例外缺换行，只作工具展示，不作为可重新加载约束；有效交付输入是已解析成功的冻结 `project/r1_algorithm.sdc`，SHA0F06ED5E8B4023837268E237E6C743DA964712EA3580E1C262C6B8711DE5E1D5。

## 数值反例的补验读回

Root 实读 `border_discriminator_002/supplemental-result.json`、独立生成器和 `readback/corner-readback.json`，重核17份实际输入SHA零变化。T=41的两个4×3整核案均accepted／delivered／compared=6、status0、数值／协议错误0；四角的真实WLF样本是m0 L1=44／edge1，m1 L1=40／edge0。该阈值使双补边差异在真实输出可见，补强原T=4全部edge1的场景；它不替代123案完整suite。001手工审计路径失败另保留，002才作为补验成功证据。

## 全量功能与放行读回

Root 已实际读取最终 `frontend_suite_006/suite-result.json`：PASS、123／123、full_manifest=true、runtime_input_hashes_unchanged=true，126次子工具调用均退出0；FT-01…11各类完整，数值／协议错误均0。四个1920×1080 job各接受／交付／比较1036800组，合8294400像素，终态0／finished=true；均cycles1038747。实际manifest核306文件／8322536行hex，参考生成未读取RTL。FE18项和R1 shell20项当前SHA已独立重核零失配；22份批准基线SHA／大小亦零失配，正式PROJECT_STATE／TASK_LEDGER原hash不变。

最终FE结果SHA72DA8D743B4B0BE4A3D50AC8A1E941A1D58C5FDA3F41BD7F8B634A95FDE039DB；FE manifest SHACCB3EA9ADFE953960F669BB2A4149AB285582765ED7201F2791EE3D822A9A38D。R1 shell005与physical005的源码及模型对应；Root已据实CreateNew保存并读回 `runs/r1_physical_005/release-gate.json`，SHAEB1AC16F3014146FF6B473B63C581EDA052B9EE3D41E94AA390C547FA55C9FF5，FT、四配置、R1-T02…05、资源／pin／setup／hold／内部coverage及项目三SHA齐全。

### 首次Bit空跑与必须修复的输出核验

005的首次Bit阶段实际pgm退出0，但没有hex／bit；Root递归核实际文件并读pgm原log确认“Flow skipped: Bitgen was not executed!”。现装 `efx_run_pgm.py` 实际112…214行说明：非USB模式从 `--work_dir` 默认取design.lbf，缺源且未显式source时跳过，仍返回0。新空work_pgm并没有已布线lbf；正确输入为同005的 `flow/work_pnr/r1_algorithm.lbf`，480729B、SHA22DE3B96DDAD6C2A3C6FDA82F418A83AE1F00E1A520E729161004F69DF134428。这是构建内部工作目录修复，17份冻结算法／模型／工程输入及批准边界不变，补同步操作草图及实际重试日志，首次结果不覆盖。

原厂每阶段会改写主flow/outflow/r1_algorithm.log；首次pgm已改写该文件，原physical-audit中其历史SHA仍对应隔离audit副本114DACE0D9F25B260B5F9985BA1EB6058E06984B426756DDE5A8D1537F5DCD54。Root重新核其他34份物理报告均一致，仅主合并log变化；Map／Interface／Pnr各自日志和STA报告仍保留。该历史条目不当当前主log hash使用。实际产物必须存在且非空、格式／来源／SHA登记后才能称Bit成功，pgm返回0不足以验收。

## 当前验收边界

Root已实际读取bitgen_retry_001的start/result、原厂pgm完整日志与bit-generation-proof：工具真实exit0、artifact_check_pass=true，source为已审阅同005的LBF，LPF亦与原审阅副本一致。Root重核两原输出实际非空及SHA，并CreateNew复制到artifacts/staging/ALGORITHM-R1-20261005-v1.1，逐件读回副本与原文件大小/SHA相同。bit 1,731,456B SHA F55F973B54355A70B65F914448F8A6E6E4431C672312DF954D3042B0DCFFB321；hex 1,731,516B SHA06907FBFCD7824AA387A3A84914F46603483FD6202E18B793A004420EDF560AD。staging manifest 7072B SHA41DE68F688D970D9D069467141A0863946D210ACCE72CA4758DC15CB060513C8，保存原输出/source/run/审批及证据。

两产物完整格式实读：均每行两ASCII十六进制字符加LF，分别577152/577172行、非法项0；没有推定二者相同或实体配置成功。17份当前及冻结输入、22份批准输入在登记时独立重核零变化。另一方向只读复核80项哈希/记录关系零不一致（不是80个唯一文件）；没有重跑任何工具。首次Bit四记录、no-artifact、release-gate、原物理审阅保持不变。

成功pgm完整主log另冻结tool-pgm.log（SHAEC8B68E15E4710B402767E315B4FD21D95D262EE67EEE5B55B60E508C285D0EB）。首次空跑主log原字节未另存副本，被原厂阶段更新覆盖；仅保留当时观察消息/hash、首次四记录与no-artifact记录，不称首次主log当前原始字节仍存在。历史PNR完整副本与SHA仍有效。

R1数值／协议／1080p回归、Map／PT／PnR／STA、真实bit/hex及staging均已实际通过，本批软件验收DONE_STOP_AFTER_BIT。[中文交付与操作入口](../05_delivery/r1-software-acceptance-v1.1.md)统一文件顺序与实际结果。未执行硬件步骤；正式状态、数据库及硬件节点不变。

后续算法／输入输出设计可以继续形成中文草图、接口与预算；其业务源码仍等待对应 READY_FOR_REVIEW 版本与范围获批。用户人工理解验收和实体硬件验收均未进行。
