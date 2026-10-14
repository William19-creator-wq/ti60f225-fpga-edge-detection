# R1 图样、监督器与 CRC 软件验证

执行日期：2026-10-05。范围依据 AP-ALGORITHM-R1-20261004-v1.1，继承完整 R1 v1 与 FE v1；三份测试台、`scripts/run_r1_sim.ps1` 与两份独立数学模型，12份已批 RTL、原厂 EFX_RAM10。未修改 RTL 或原厂模型。综合、布局布线、STA 与 bit 的报告由构建流程单独给出；本报告是算法外壳及组件仿真证据。

## 1. 整体交接和操作顺序

```text
正式指定批准 + 两份 R1 设计 + 22 baseline 原件 hash/bytes
     ↓ 新 RunId，冻结当前runner、两个数学源、vendor、12 RTL、3 TB
Python二维图/公式 → 全部 record160 / running CRC32 文件与 manifest
     ↓ 文件字域、精确hex、EOF行数、hash逐一核对
Questa vlog（原模型仅默认timescale，不改源码）
     ├─三个故障退出探针：finished=0 → 非零退出且无成功JSON
     ├─top W4/H3 与 W8/H5：真握手、真FE、每条record及每条CRC
     ├─source四图：完整258×258、快照/边界/held
     └─typed J/K/LED：原始FS错误与序列边界、busy reset
     ↓ 实际计数与预定必需计数一致，所有输入末尾重读无变化
完整 JSON + 工具日志 + .do + WLF；满足本流程才写 COMPLETE
```

可读回操作：进入现有 approved work，调用 `scripts/run_r1_sim.ps1 -RunId <新的安全名称>`。脚本拒绝已有目录；失败目录保留。工具使用现装 Python3.14.6、Questa2024.1；模拟时钟40ns。仅在本进程缺省 MGLS_LICENSE_FILE 时临时继承已存在的 User 配置，不输出或读取许可文件，finally恢复原Process变量，不改User/Machine。

## 2. 三份测试台的局部边界

`tb_r1_algorithm_top.sv` 只解码独立 Python 黄金，不在 SV 重算 CRC 或图像结果。正常FO/FS分别打包原始160 bit字段，逐条核对数值/坐标/marker/身份，逐 record 核 running CRC。Capture 沿要求 record_hold=原record、bit_index159、CRC不提前移位；随后恰好160个 shift clock，最后一位后的状态与文件一致。终端再检查最后 CRC、counts、status、good、LED。两个尺寸均先完成 k0…4，在 k5 第一个 CRC bit150真实忙时将 KEY 拉低至少四个时钟，再从 k0完整完成64种组合；旧record被reset取消，不冒充已完成CRC。

`tb_pattern_pair_source.sv` 在真实 job_start 后扰动外部cfg，已锁job_snapshot保持不变。四图每对48 bit RGB、坐标、SOF/EOL/EOF、source_last_fire全部比对，ready真实停顿，held完整payload保持。每一行检查x_even30/32/128/254/256，包含lane1的31、129、255以及x256；整图覆盖y31/32/128/129/255/256和奇数半幅129。

`tb_r1_observer_supervisor.sv` 只从typed FO/FS输入驱动 J/K/LED，不 force 实际FE status或done。八场景为normal、FEED提前原始错误、原OK错frame_id、原OK错输入计数、FEED前缀原OK、DRAIN取消、序列FFFFFFFE、序列FFFFFFFF。仅最后两值的边界初始化写 supervisor.job_sequence=FFFFFFFE；随后FFFFFFFF必须由真实监督器递进，ERROR/EXHAUSTED无重启、无wrap。status使用原始code/IDs/count，不能用自造OK替换。单独busy reset清旧record，全部typed记录与最后摘要CRC均核独立文件；FO/FS停顿实际计数。

## 3. 正常 / fatal 退出边界

真实 `.do` 配合 `-onfinish stop` 与 `+acc`：onbreak用catch读取本TB的finished，只有二进制1才能quit0，其他quit3；onerror退出2；run自然返回也退出3。TB仅在所有比较与必要count成功、JSON已经关闭后设置finished=1。Runner同时要求exit0、存在finished JSON、numeric_errors=protocol_errors=0及必需计数。三个测试台各有deliberate fatal探针，真实结果均exit3且无成功JSON，防止把工具进程退出0当作PASS。

`vlog -sv -timescale 1ns/1ps` 给无显式timeunit的原厂模块提供默认单位；EFX_RAM10文件本身不变。`log -r /*` 与 `-wlf` 保存实际信号。

## 4. 已保留的历史与真实计数

`r1_shell_001` 保留 FAILED：编译0errors/0warnings，但第一top启动exit12。原因是PowerShell数组内未逐项括号的字符串拼接把两个参数合为一个，之后只修runner参数边界。

`r1_shell_002` COMPLETE、14条工具命令、7正常cases、3非零fatal探针，冻结17 runtime inputs（vendor+12RTL+3TB+manifest）。其结果不能归因于后加冻结模型/runner的脚本版本。run-result SHA256：`923DF98AB9CE3DF2FEC4E4FFC2950CF1116D1D489E144B80B34E394EE1A00FA1`。

`r1_shell_003` 在002后新增运行前冻结runner/两模型，并在末尾核对，独立新目录COMPLETE，runtime inputs=20；数值/协议行为与002一致。之后正式批准/22baseline自动核对的审计修补另开004，不回写002/003。

`r1_shell_004` 为正式governance核对版：实际exit0、COMPLETE，14工具命令、7正常cases、3fatal探针；inputs=20，在生成前记录当前runner/两模型以及实际RTL/TB/vendor，末尾逐项hash不变。独立governance记录两R1设计、当前正式批准、真实approval note、22份原输入；运行前后22/0 mismatch，governance_unchanged=true。run-result SHA256为 `6E4BA29071219177EE379B3B976D40B16A2EA447DFCEE23397F92372DBB855FD`。

**最终采用 `r1_shell_005`**：004结束后仅修FE FT05 scenario的status=NA（window单元无F0状态），数学、RTL、R1 TB/runner不变；005新目录按当前FE源hash `4D81E977D1A8633B20497A1BA5A6E664D63E5730652380684B68BBB65D955D7A` 完整重跑。实际exit0、COMPLETE，20 runtime inputs、22/0 baseline、governance_unchanged=true、14工具命令/7正常cases/3fatal探针。run-result SHA256 `559E01DA657A2C437BA43BA9EB624F423919A9893DC1F8BE81A50C09782653D4`。vlog0errors/0warnings；七正常vsim exit0、三个fatal exit3，所有正常numeric/protocol errors0。下表计数和正常结果hash与002/004一致，但当前批准/源冻结链以005为准；旧run保持原输入版本不回写。

当前正式Approval Manifest SHA256 `7AC43241B211A52087DD74A5306778D307DB57C732D78F104382BB42A5C8F76D`；真实approval note `1869F2A244949C6366E02A21F0400235F6E9C776B3FA4D7EC659F9C4A39C27EB`；22 baseline `DA97EA25F9DD8193913967965A2E0874CAD1E7A307F11337272BF910AA1D3DE4`。baseline内旧NOT_APPROVED是冻结的批准前证据，执行授权来自当前正式scoped approval，脚本没有混用二者。

| 最终实际冻结源 | SHA256 |
|---|---|
| run_r1_sim.ps1 | 50BCA42FF6EBEE125EBF60C7722A9C04FAE5B03C3F1FC862CC0FD90A108330C6 |
| tb_r1_algorithm_top.sv | B11312A27D4B3FBE73575E5C14DE9FF374311E5FFFF1A9BA859274B3CDE2BE35 |
| tb_pattern_pair_source.sv | 51EE5B7B21E3449E6DE0F4C5D1B6B73A26FE55B53B230F8211304BD5E5785F20 |
| tb_r1_observer_supervisor.sv | 3EFE9FA95BE944A3F7579E2CD27E0A53E57598567230FBD9D017B45D7D1E64D2 |

全部12份RTL、vendor、两模型、manifest hash见005的20项inputs；各正常JSON自己的hash见cases，各完整工具日志hash/退出码见commands。WLF与.do同目录留存，不复写旧run。

| 正常case | 完成/交付与CRC证据 | 周期 |
|---|---|---:|
| top-W4-H3 | 69 completed jobs、64 unique；415 FO、484 records、483完整CRC、reset1 | 79,883 |
| top-W8-H5 | 69 completed jobs、64 unique；1,381 FO、1,450 records、1,449完整CRC、reset1 | 235,689 |
| source-pattern0…3，每项 | 33,282 compared pairs、1,290 boundary pairs、7,397 held cycles | 40,684 |
| observer-supervisor | 8场景、47 records、46完整CRC；FO stall4,770、FS stall1,260、busy reset1、exhausted2 | 7,495 |

所有正常项 numeric_errors=0、protocol_errors=0。top/typed各多出的一个 captured record 在CRC忙时被reset取消，故records比完整CRC多1；这是实际重置边界，不是缺少黄金核对。正常WLF均非空：top4x3 3,784,704B、top8x5 11,214,848B、typed352,256B、四source1,441,792…2,105,344B。

## 5. 人工波形观察草图

用Questa打开相应run的WLF，先定位 `/tb_r1_algorithm_top/dut` 的 rst/job_start/job_frame_id/source_last_fire，再看 out_valid/out_ready 与 status_valid/status_ready。正常一条record交付沿后，`observer/record_hold`稳定、`record_bit_index`从159降至0，capture沿CRC不移位，160shift完成再允许下一次ready。FS最后移位后，观察last_crc/last_good/last counts、terminal_crc_done注册脉冲与下一job_start；中途reset时，旧busy、pending与last_result_valid清零，frame_id回0，旧RAM内容不能影响新的完整k0结果。

source WLF先看job_snapshot再看ready拉低期间 `{last,eof,eol,sof,y,x,rgb}` 保持；查看x30→32、x128→130、x254→256，lane1分别覆盖31/129/255。typed WLF先查看原FS字段，再查看good资格、160移位后的terminal_good；原OK错身份/计数也必须last_good=0并留ERROR。最终两job检查实际job_sequence从FFFFFFFE到FFFFFFFF后留EXHAUSTED，无00000000新启动。

## 6. 双向追踪

R1 v1 图样/监督/CRC/复位/LED合同 → 三份R1测试台及独立record/CRC文件 → 表中必要计数；每个测试台文件头和局部说明反向指回这些交接。FE F1/G数值合同 → 独立二维参考 → R1完整图像record，不以LED当数值oracle。R1 v1.1与22 baseline → runner批准核对和冻结SHA → 当前正式运行报告。参考完整证据另见 `reference-implementation.md`。
