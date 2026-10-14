# TRACK4-CIRCLE-REFINE-001：独立候选 v1 变更记录

2026-10-11。本批依据用户持续自主推进、免新增中文长草图和独立测试、本地审计授权，以及 root 对已呈现短卡的限定 candidate 实施通知；不冒称用户按版号逐项审批。仅下列两份新 RTL 和本记录、本设计卡实施说明；正式数据库/状态、主 RTL/XML、HDK、硬件不改。

| 冻结输出 | SHA256 |
|---|---|
| board/rtl/board_circle_reduce.sv | 9785CCF94B22BC0898B32B80E36B20BD2FAAB262DEBF547FFAB7D71DEFC17D03 |
| board/rtl/board_circle_refine.sv | 9412A428E8841F017F0D435651CFA5040AC5D334D8BB841ABF8E95194BA601DE |
| planning/design-TRACK4-CIRCLE-REFINE-001.md（候选实施说明后） | 03549B326357F4E38C8C2EAC9B8B2BEFB66BF99921E5865320604AA27678D443 |

设计历史：root 先完整读回并呈现原 v1，SHA B1B3E73A73CA0E06C1A69BAD4D5AC88A5E74032E3B1ADEF6834113FA11BDF9EF；随后明确 CR 值域/局部拒绝/关闭说明，SHA AB183515BCA0DA293179B0E578B023F3653D98AB6CE5C68F68C5CD539A3B28AB，由 root 实际读回后继续实现。本记录不将旧 hash 冒称为修改后仍有效的设计。

CR 完整实现五 op：MEAN、POINT_METRIC、SCORE、QUALITY、FINAL_GATES。同一外部 scalar、128×16 工作 RAM、两份128-bit操作数，无新乘法核或385-bit返回快照；完整25字资格、全宽比较/RNE、C2/64关闭序号、borrow、已知错误真实关闭与UNKNOWN隔离。root 已全文定向源码读回 PASS；该结论不是编译、EDA、性能或硬件证明。

CF 完整实现全部selected seed、完整HIST与RAW/SMOOTH实际峰及相邻峰、A/B/C/D/E扫描、最终冻结几何/质量/径向sector/残差/极性、1024 CIRC精确去重和64B写回、META及真实lease释放。借同一POINT reply逐lane处理，无512FF帧副本；A/C只发FIT kind11，E的kind17 STATS诊断由CR等价计算。输出真实geometry lease、NUM的PM/CR/FIT owner请求、ANGLE owner请求。STAT/FIT结果借用直到其自身quiet，不提前换owner；失败STAT也必须完整ID匹配才消费，异ID隔离；STATS早故障不等待已经失效的token_ready。保留旧 PM v1接口，本目录文件冻结，不在这里混入radius-only变体。

实际只读依赖如下，均未修改：

| 输入 | SHA256 |
|---|---|
| candidate circle_histogram_v1/board/rtl/board_circle_histogram.sv | 3A8F9A320E3D6E8B1C7D8455BF24FD2B5B63E9B060C682262F664BD39CE59A50 |
| candidate geometry_point_math_v1/board/rtl/board_geometry_point_math.sv | 83172157F710AB694F11782E73E0C75914B0B906415F9B8B507E120A3579CB21 |
| candidate geometry_numeric_share_v1/board/rtl/board_recognition_stats.sv | B6B8CF63BB3215E707395C5394A4C2ADE8D9E6783C45342BED20D3A0587700C2 |
| board/recognition_numeric/stats_core.sv | 93FCA025A54F7FD8DA04AF6D3E56CF6D37CA3C0584DF745BB12A7B587BCE9A5C |
| board/recognition_numeric/fit_core.sv | 875083D9835283FCABA45372A08BE2CF2B8056AA99F310F24DA15135565242F6 |
| board/recognition_numeric/angle_core.sv | EA8B6F8E0E22112BD2D51B40A2E746A966500B3AF6A00C0835B4C66BC3863730 |
| board/recognition_numeric/scalar_protocol_pkg.sv | 40D7FC511C4E481B0B194A2B31D53C18627EC7D420A5B54E17C438E5832D3028 |

设计当时旧 RPC SHA 14E8BAC5A362AE37D6091516569AAFB841AE5B1613C46340D0EBD6D6CDAE2E88 属于056冻结只读来源，不能覆盖root更新。当前主057只读观察：RPC E692D5D88836034A6825B82D0778524CDC5A6F6531A662E66ACD0FEBBEF3161D；scalar_core_words 73F230DFB7B2D2F12A3220C8EE4FC4FF4B8C90E18AD916E3E05D24C084BA31F0。scalar协议没有改变；卡中数分钟初始化估算明确为旧056预算，不当作057优化后的实测值。root报告057综合通过但physical61201/60800超401，不能称新增候选装得下。

CF作者定向源码读回已完成：五遍分支和成员重放、Q4/全18位半径及扩宽和、实际STAT/FIT/ANGLE字段布局、末POINT padding、PACK八字及写回复、序号和MAX容量、已知失败/UNKNOWN与真实owner收尾。对两源码搜索 based literal 与 `?` 紧连模式无匹配；未添加可执行静态检查脚本。CF等待root完整读回，尚不记录其PASS。没有新TB、仿真、综合、布局布线、时序检查、比特流或硬件操作。

待接项目：父RPC的stage/DDR/PACK路由；SEED有效前缀与CF START；唯一scalar的PM/CR/FIT实际owner和16bit返回侧带；existing POINT angle_core的共享lease；geometry lease启用与LS_TLS_ONLY=1解耦；64B CIRC/META结果消费；另一个radius-only变体；整机容量/时序/速度与最终识别效果。矩形、最终分类/标签/annotation仍欠，不称完整A6或可下载整机完成。
