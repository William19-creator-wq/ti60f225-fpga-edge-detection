# DISPLAY-SCAN-CORE v1 的验证补充 J1（2026-10-10）

- Goal：补齐 FC02/03/06 的真实停钟、启动前禁用、同沿归还/接受与错误回执覆盖；把运输 link 单独纳入真实 Ti60F225/I3 综合。
- Current state：v1 三 RTL 不变。小/最小/HD/近最大四个独立参考均 PASS；core MAP 为 19 RAM、9452 FF、17066 LUT、439 ADD、1 DSP；原 XML top 没有实例化 link，不能把这次资源报告说成包含 link。
- Target state：现有实际 AXI/native 测试补三场景，另加 link-only 错包测试与专用 MAP XML；完整 SCAN 仍继续，不缩减整体五基础/六高阶。
- Gap / Assumptions：错回执由明确的测试父主动注入，不假装来自真实核心；真实核心路径继续用原来的 native RAM/AXI。当前不存在新的生产接口、行为、时钟或资源选择。
- Open questions / Dependencies：完整视频仲裁/owner 联合、物理 CDC/DDR/QoS、生产 PNR/STA/bit 仍未完成，不影响这次明确验证边界。v1 的 16 项冻结输入保持。
- Milestones / Detailed steps：草图保存读回呈现→冻结 J1 第17输入→修改 TB/参考/脚本并新增 tb_fetch_transport.sv、display_fetch_link_component.xml→小/最小/运输仿真与独立审计→link MAP→登记。
- State transitions：READY_FOR_REVIEW；采用用户“当你统计完后自行进行，无需我的批准”的持续软件授权，不冒充新增逐版人工批准。原本地审计例外有效，正式 DB/硬件状态不变。
- Artifacts and hashes：v1 TB 4424CA54665BD555F3DF48CDD548D3F3C705DC0C92A99D591822BDEE2380C271；参考 C0AF14F500FDC8204FC773EF877F3FD2C9FBCEB02ED392350412ECFB00E2B4A6；sim runner 443E1561F3BC2F05E009ACBBEB19098AF15223505606A06037C1FCB294939086；map runner C3FEA01B324796FC0FD89F82BAAF1571A9A76862D1E78C57A5A05397FA6F6CB0。原运行的完整源码快照及失败记录保留，不覆盖。
- Validation / Failure handling：保持 fatal 非零探针、实际 finished、每次独立 RunId、源码前后哈希、完整源快照。错误包隔离要保 transport_live，不能被消费后重新开门；失败保日志再修订。
- Human approval gates / Rollback：无需逐版软件批准；原资料只读、无联网/安装/硬件动作；只新增独立 work 文件，可回看 v1 快照。
- Completion criteria：补测试和两种组件 MAP 分别结论；不宣称完整生产扫描或硬件完成。

## 整体→连接→中文局部草图

JREQ1（FT3）：enable 在核心 CHECK 前已经 0，最终 status7、outcome1、granted0、所有计数0、drained1；无 lookup 消费/AR/native WR/GEN推进，恢复 enable 后下一正常请求可运行。

JREQ2（FT4）：实际 link 发需求，video 在请求已接受后的低相位停钟。core 继续实际 lookup/AXI/native WR/publish/收据进入返回 mailbox。连续200个核心边沿，transport_live=1、core_idle=0、video_busy=1，原请求 payload 不变、没有视频消费；视频恢复后615全文不变且一次消费，真实行读/归还照原路径完成。此证据只覆盖逻辑停钟，不声称 MTBF。

JREQ3（FT2）：先真实读完旧行并释放，core return_valid 到达后保持 ready0。两测试线程：一方发同银行新需求，另一方在 service_valid 出现后的下降沿把 return_ready 置1，下一 core 上升沿真实 return 和 claim 同时发生。旧 busy/GEN 决定新请求 BUSY，收据 echo 旧 GEN；旧行真正归还同时推进下一 GEN。再发正常请求必须使用新 GEN。事件记录两次实际 fire 的同一 cycle，独立参考由归还账本和 claim/return 时间验证，不读取核心寄存器。

JREQ4（FC06）：link-only 父只提供一次实际 claim 后的615回执，覆盖正确 NoStarted、bank 改变、demand 改变、granted且GEN0、outcome3、drained0；正确包额外暂停视频时钟并压住 ready。请求/响应全文在未接受时保持，逐域握手计数一进一出；前五类错误最终 video/core Q，transport_live 保留、ready 不再开启；正确包真实 ACK 回传后才能 idle。wrong bank/demand/granted-GEN0 的 core Q 依视频消费错误后同步产生，outcome3/d0 的 core Q 可在源发送沿先产生。测试父不是生产业务核，不赋予 bank/帧关闭权。

JREQ5（FT5）：专用 XML top=display_fetch_link，只加入两个 package、atomic_mailbox 和 link 的真实路径，沿同一 core/video 时钟 SDC，只跑 MAP。map runner 明确 -Link，前提是本轮真实 link+core 小测试 PASS且源哈希一致；不套用旧 XML top 资源，不把两组件独立资源相加当整体装载证明。

## 语言、接口相容与追踪

生产 RTL 三份和全部冻结依赖不改。新增 TB 的人为父遵守 claim 后 payload 借用至返回真实进入 mailbox；video 输入在下降沿驱动、上升沿实际 fire，观察时钟暂停期间用核心边沿后 #1，避免 NBA 竞态。对 scope 查询在真正 return 前为 live；同沿的旧值/新值分别说明。所有银行、479/543/615/387 身份仍全文，unsigned GEN 不回绕。Python 纯事件字典按固定宽度解包、任意精度整数，不依赖 RTL状态。新运行在开始就复制所有编译/脚本/参考源到 source-snapshot；旧运行的哈希核实补存快照有单独说明。XML 为组件无板级 pin，SDC 是时钟预算，不能当 STA 通过。

|要求|模块/接口/草图|实际拟改|测试/判定|
|---|---|---|---|
|JREQ1|core CHECK/NoStarted|tb_fetch_core scenario29；参考原拒绝分支|status7、无副作用、再正常|
|JREQ2|link两mailbox、video时钟|tb_fetch_core scenario30|200核心沿暂停、实际publish后再收到同包|
|JREQ3|GEN stamp/真实return|consume_row 同沿选项/scenario32；事件参考|旧GEN BUSY+真实return同cycle，下一请求新GEN|
|JREQ4|link echo/Q/ACK|tb_fetch_transport、参考运输分支、sim -Transport|6种包、正确停钟与holding，错误永久隔离|
|JREQ5|当前Ti60/I3合成|link XML、map -Link|工具 exit0/真实报告/源快照；无 PNR/STA/bit|

整体正常路径已用 v1 实际 native/AXI；边界沿前 busy 与沿后 GEN 已走查。现有 FT 卡之外增加明确测试证据，不改变任何已通过结果期望。十项设计门槛均由 v1 和本卡覆盖，无当前验证接口未定项；保存读回、呈现后实施，实际结果随后填写。
