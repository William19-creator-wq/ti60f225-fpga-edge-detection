# RECOGNITION-ALGORITHMS v0.1 实际读回与交叉审查

2026-10-04；范围是候选生成、稳定支撑、最终核验/去重/标注的设计。主稿仍为 **LOCAL_DESIGN / NOT_READY / NOT_APPROVED**。没有实现、可执行参考、功能脚本或TB；正文字形数据为设计常量，未生成生产ROM文件。

## 1. 对象与实际阅读

[主稿](../../../planning/design-TRACK4-RECOGNITION-ALGORITHMS-001.md)最终SHA256：`D8C45B02032DCA210265441118EA3AB7EF88DD2E549E15386082FCC6928057AB`。

root保存并从磁盘实际读回完整文本，比对最终预期一致。两个独立方向都在修正后实际全文读回该最终SHA：圆路线作者检查矩形/VC/PROFILE/资源；矩形路线作者检查圆seed/hist/拟合/池及联合几何。另有VC/栅格方向只读报告，root实际核对并整合。以上是文本/数学分析，不是运行测试。

输入RC `D9727727…3EE5`、NUMERIC `17C4A290…F39A`、DATA `B09B9FEA…9408`等保持原字节；改动条款只在新稿D/J显式覆盖，不自动升级父稿。完整来源hash见主稿A1和[当前文档检查](document-checks.json)。

## 2. 具体问题与修正

| 项目 | 原风险/反例 | 本稿处理 |
|---|---|---|
| Seed唯一数值入口 | 两点半径均值及角门方向未定义会改变key/rank和所选256 | 两G法线交点逐坐标RNE；量化中心两距离各RNE，均值再RNE；角为全宽sin下界、半径差与最终17bit域分别核。 |
| Histogram超域 | 图外center约(-8000,500)合法，右侧点距可超过8192px；先收17bit会回绕tile | 距离先全宽，0和>131071独立无票/观察计数，不将该输入帧从质量中删除。 |
| Sector循环资格 | “逐点通过sector门”依赖尚未形成的mask | 支撑只按径向/法向；完整mask形成后判整体coverage门。 |
| 矩形构造前置 | 两PAIR共用段、两组平行或交点远离真实run，强制正交新轴仍可能得到四角 | 四不同段/第三段不同、原方向正交及交点落原fine支撑区间加2px容差先检查。 |
| 端点与角 | centered tangent不能直接作absolute端点，量化Q30不恰为单位；各角独立RNE不保持精确正交 | 用完整向量交点恢复；输出称量化矩形，重新核非零、面积、CCW、不自交。 |
| Fit诊断断链 | CIRC/RECT没保存原LS n/TLS质量，FINE/PAIR已切VC | 同一最终geometry核验遍的inliers重算LS/四侧TLS诊断，不重拟合geometry；新fit_*语义及required侧明确。 |
| Membership与去重上界 | 相同geometry、不同present若改变谓词会留下多个支撑keeper | 全四边统一唯一侧分配；kind/present只影响整体验收/required质量，默认exact至多一次samegeometry完整支撑遍。 |
| 舍入满分误去重 | I=2073599、U=2073600的RNE UNORM为65535，但I<U | 门为65535I≥threshold·U；默认65535严格I=U，舍入只诊断/排序。 |
| 种子编号 | 圆ordinal0…255不能覆盖矩形PAIR0…511 | 圆seed13 high5零、矩形pair9 high4零分别保留。 |
| 工作公式 | 原phase2数值含Hough32E，公式漏该项 | 明确32E+14LE+6SE+VE，满值51027148800点检查。 |
| ANN范围/字形 | 圆Q5外界524539超signed20；字体和元数据不能占隐藏RAM | 外界signed21；draw80完整字段；98word字体使用projection spare，所有模式关闭后复用。 |

三边U负例与被同色覆盖整边的矩形可同RGB；推断flag不能使该负例退出FP。近拟合重复、代表选择遗漏、弱offset被筛除均可能影响质量，不能以文档完整宣称95%。

## 3. 静态算术与实际证据边界

19项字段/容器算术均相符：SEED128、峰64、SEGMENT128、FINE256、VC400、CELL32/EXT64、DRAW80、PROFILE三处50/50/64bit复用、263bit圆LS、3304/4883/14778bit FF小计及四内部消息位数。8要求/7IF/8OP/8INV/18文字场景/12节/7追踪行已定位。

- 最新已列RAM：180+26+4+15=225/256=87.890625%，剩31不代表可用全机余量；VC80排他使用已关闭的84池，FONT98word与draw1RAM分时复用。
- 14778bit为局部列明FF，不含全机/新FSM/完整metadata/row/统计执行保持；32个12×17乘只有本地DSP48位宽与推断依据。
- 圆最多86272遍POINTS，载荷1431148953600B；phase2最多51027148800点/408217190400B；P3核验/精确去重局部8493465600点/67947724800B。padding、scalar、覆盖统计等另计，不能当整机完整期限或实际fps。
- 四NMS行每行291个20bitword、hist每row336有效/340物理bit、VC40960word=80RAM、字体490原始bit/98word，均只静态核算。
- root实际读取三份本地DSP HTML主体、模型前190行及四文件hash，112组既有/来源/规则hash复核无漂移；全局文档数量及最终索引hash以保存后当前审计为准。

## 4. 仍未闭合及下一步

AG-B01保留：所有池模式、word序、RE/capture/commit/pending/borrow/holding、统计/coverage clipping与row内部执行须完整局部稿。AG-B02保留：完整FF/DSP/QoS、采集EOF/显示行期限及可接受识别延迟仍需联合预算。可继续这些设计，不以未获批测试结果循环阻止READY。

AG-B03为获批后的质量NOT_RUN：开发选择与最终独立分布冻结、负样本/重叠/失败帧、一对一最大基数匹配、每类P/R整数门都未运行。更广开发轴是比较点，不恢复用户撤回的旧硬边界。AG-B04沿父外部/执行前提，真实2Gb/PHY/CSI/cold/serializer/SDC、指定批准和正式DB等未消失。

十八场景执行数0；业务实现、功能脚本/TB、真实PHY、综合、引脚、PNR、STA、bit/hex均 **NOT_RUN**。原资料、正式状态、Manifest和数据库未改，无网络/下载/安装/设备动作；既有两项PENDING批准不重复创建。完整十一功能软件目标继续ACTIVE，本轮为设计实质进展，不是软件完成。
