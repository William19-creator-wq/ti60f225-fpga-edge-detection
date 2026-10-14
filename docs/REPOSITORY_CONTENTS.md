# 仓库内容与导出边界

本库是截至2026年10月14日的项目工程快照，保留原控制面目录布局以便对照已有设计、组件、整机工程和观察。

## Git中的内容

- 已有RTL/VHDL、C/C++、参考模型、TB、测试和构建脚本、Efinity工程与约束、IP输入及配置。
- 设计、中文操作草图、任务追踪、审批记录、来源与冻结清单。
- 小型仿真/综合/布局布线/时序日志和结果、观察JSON、电压记录、历史交接包的解压内容。
- 赛题、相机和V4说明等相关参考资料，群新增文本/源码/配置及解压后的DDR控制器资料。
- 新增的最新成果、问题、工程入口与相机调试汇总。

## Release中的内容

`fpga-bitstreams-20261014.zip`按SHA256保存45份不同FPGA bit及配套hex一次，`PATHS.csv`记录97条原逻辑路径到压缩包blob的对应关系。文件名相同不表示bit相同；历史失败或未验收bit仍保留为追溯材料。

`simulation-hex-samples-20261014.zip`另存268份不同历史仿真HEX输入/期望/输出数据，对应502条路径，索引为[simulation-hex-paths.csv](export/simulation-hex-paths.csv)。这些样本不能用于Programmer硬件下载。

恢复方法：查索引中的工程路径，找到archive_blob，解压它，核对SHA256，并恢复repository_path所给的文件名与目录。发布附件同时提供压缩包SHA256。

## 留在本机的内容

Efinity/Questa/驱动安装包、软件运行时、授权或登录配置不上传。波形、模拟库、缓存、大型生成向量/报告、生成网表/数据库和重复ZIP/RAR也不放进Git；它们仍保留在原工作区。原始完整HDK压缩包没有整体复制，项目工作副本中的实际依赖和已列参考保留。

[included-files.csv](export/included-files.csv)记录复制文件、来源、大小和SHA256；[excluded-files.csv](export/excluded-files.csv)记录遍历时排除的文件及原因；[export-summary.json](export/export-summary.json)列出整目录跳过规则；这些规则跳过的目录没有逐文件枚举。新增汇总文件由Git提交记录，既有源文件复制清单不覆盖这些新增文件。

导出后又补入26份既有源文件/项目配置，包括被缓存目录规则跳过但XML明确引用的必要源码。这些例外以included清单及export-summary的additional_required_inputs为准；excluded清单保留首次遍历记录。总计41357份既有文件，约945MiB，另有新增汇总与导出清单。

原artifact manifest仍描述本机完整历史产物，不能对删减后的Git副本直接运行“原全部blob均存在”的检查。请将原manifest、Git导出清单和Release索引分别阅读。

本次只复制和整理工程，没有修改原始HDK、RTL、IP、约束或正式数据库状态，也没有重新执行EDA或硬件操作。

GitHub普通Git拒绝超过100MiB的单文件；本库因此把比特流集中到Release，并保留大型生成文件于本机。[GitHub文件大小说明](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)
