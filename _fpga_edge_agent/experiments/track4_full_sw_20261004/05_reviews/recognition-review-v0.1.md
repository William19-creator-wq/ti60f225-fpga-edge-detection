# TRACK4-RECOGNITION-001 v0.1：实际读稿审查

2026-10-04；DOC-20261004-RECOGNITION-V01。范围为[主设计A–L](../../../planning/design-TRACK4-RECOGNITION-001.md)与[追加地址候选](../01_baseline/recognition-candidate-address-arithmetic-v0.1.json)，当前LOCAL_DESIGN / NOT_APPROVED，有RC-B01…08。三方向受同一v0.2门槛约束，只读调查／数学／中文设计；未代写业务源码／脚本／测试。

## 1. 整体先于局部

先整体输入与输出／失败（B），职责和数据控制路径（C），8项接口／四phase／工作TEMP与结果ANN（D），再8项中文草图／10不变量（E），最后位宽／存储／工作量（F）、16文字场景／双向追踪（G/H）、门槛与实际未运行项（I–L）。完整grad32直接用于法线，dir2仅为Canny邻域方向；不恢复用户撤回的固定尺寸／最多4／噪声／遮挡边界。

## 2. 三方向实际读回与实质修正

| 方向 | 实际查读与发现 | 已在主稿处理 |
|---|---|---|
| 圆／存储原语 | Canny grad32、EFX_RAM10静态宽深和LS保守位宽；薄DDA187与supercover254不是同一工作量 | Gx/Gy完整使用、21bit条件去重／22bit加法、图外/同格多中心/同心多半径仍阻塞；LS宽乘除与退化检查不默默缩窄 |
| 矩形／配对／量化 | 512θ／16batch、rho2半像素、32桶halo全读、θ首尾rho符号、线／段／pair有限容器 | 三桶加载≤3E与h2每point≤5票分开；理想角界不冒充整数判角已证；coarse125/64bit与TLS217bit/四边868bit分开，NMS carry/分段仍阻塞 |
| 身份／AUX／ANN／事务 | 原12区、FM WORKING、Canny严格零幅值、DDR两槽×128bit、phase与返还ACK | 9 PROCESS/25grant候选峰、五TEMP精确A/pagegap不授、RESULT ANN生命周期、独立binding_return/ACK先于完整status快照、保持client旧W来源/借用/pending |

全部三方向已实际打开保存稿后反馈，不是只审查聊天摘要。以下问题在复读中具体纠正：

1. **共享RAM静态模式**：原候选圆末块1×8192、矩形17条20×512不能运行时复用。改全部固定20×512，圆末块16个高bit／word、其余4bit零，串行high-word RMW；17块预算保留，模式切换须借用全空。
2. **P0缓冲所有权**：四条20×512形成512×64池，分四个128word区，EDGE/GRAD/POINTS源独立；128bit R拍holding分两word写，POINTS满时flush而不覆盖旧GRAD。单共享口需串行仲裁，具体FSM仍阻塞。
3. **scatter半拍**：32桶各16B起址且physical_extent单独计算，上界8(N+32)；满16或EOF才seal，临时奇数不提前零补再追加。META cursor两word原子锁与latest staging。
4. **零梯度**：一次分析曾建议保存θ0并跳法向；随后实际读Canny CN-04/05确认Mnms0为NONE、严格>0政策。最终恢复EDGE1/G0非法输入失败，杜绝坏输入跳票成功；保存稿／测试行一致。
5. **status未来证据**：先冻结local_result，实际采到全部所含lease/fence证据后才冻结完整status；返还通道独立，不等status消费才ACK。
6. **单位／小图／枚举**：rho2 pitch16=8像素、Q15 coeff signed17可容+32768；W6/H5/N30符合Canny，ANN连续跨行末4bit/8B补零；结果状态为WORKING，holding为两槽×128bit。
7. **宽统计与吞吐**：原图核验附加遍数、DSP/LS/标签／内部公平／六槽期限都留阻塞。没有从候选容量、3.878s理想票更新或119块小计推导已达fps／质量。

## 3. 算术与资源的证据边界

[原12区](../01_baseline/canny-candidate-address-arithmetic-v0.4.json)未改。META640／POINTS16588800／SORTED16589056／CIRC32768／RECT65536按4KiB分配；三ANN各522624B物理、524288B页分配。新增34856960B，原图像页加新增90083328B，低4KiB另外计，高水位0x055EA000=90087424B，假定256MiB剩178348032B。页gap不授grant，不属于有效对象。

已列识别58+Canny44+DDR17=119/256=46.484375%。固定20bit累加器17、峰8、段14、pair4、final4、row2、流池4、scatter4、目录1均写出物理组织；缺完整算术／DSP／标签／metadata和平台等。实际综合／PNR／STA未运行，不能据此说全机利用率已优化完成。

## 4. 当前门槛与验证状态

| 项目 | 状态／含义 |
|---|---|
| 文件／章节／ID／链接／算术／冻结输入 | 当前[文档检查](document-checks.json)记录实际读回；历史DDR30份审计另存 |
| RC-T01…16 | 全部NOT_RUN，仅文字验证计划 |
| 业务源码／参考程序／测试／TB | 未生成 |
| 真实DDR／PHY／校准、RTL仿真、综合／PNR／STA／bit | 全部NOT_RUN |
| 独立圆／矩形95%质量与处理fps | 未验证，supported domain尚未冻结 |
| READY／批准／正式状态／DB | 未READY／未批准／未修改／未配置状态不变 |
| 实物与理解验收 | 未执行；Agent解释不代表用户已理解 |

继续允许的工作为补齐RC-B01…08及相邻局部设计；当前稿不构成实现授权。没有新建批准请求，既有FRONTEND/模型获取仍待答；完整11项与bit/hex目标仍未达成。

