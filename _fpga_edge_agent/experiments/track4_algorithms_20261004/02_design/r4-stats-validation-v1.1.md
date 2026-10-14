# R4 STATS：独立验证与逐沿组合检查 v1.1

2026-10-08，纯设计/NOT_RUN；不含可执行模型或TB。用于主卡ST-B03与最终范围核对。v0.1保留，v1补有限状态、完整算术/身份/错误资格和冻结后的证据检查。

## 1. 三层独立期望

stats_reference直接解码源START/POINT/END/ABORT，按主卡资格和首错规则判断，再把所有合法include点作为数学集合求和：LS直接求Gy²、−GyGx、Gx²、Gy(Gyx−Gxy)、−Gx(Gyx−Gxy)；TLS直接求中心坐标和及乘积。它不复制DUT四级寄存器、s57加法器或五槽结构。合法域的完整N数学分析表明实际溢出不可达；隔离helper边界与主行为证据分别报告，不能靠force宣称合法域达到了overflow。按原R3 INPUT_FIELDS作数值范围检查和NUM622打包，原ID从源完整复制。原fit_reference.encode_request默认destination=kind，不能直接用该默认重新分配本source的destination0；复制的fit_reference.evaluate只评估独立打包的原ID请求。

真实组合把观察到的完整STAT632成功体交给原FIT实例。原fit_reference逐字节复制，给它的是独立源集合推导的NUM请求，不能用DUT统计当黄金。分别比较STAT632、实际NUM622和实际NUM_RESP585；失败统计不能发NUM，少点合法统计必须发NUM，由原FIT返回LOCAL_COUNT。

协议审核从真实fire和reset重建三份独立账：①START/非法IDLE入口与STAT终态；②接受POINT、合法eligible分派、commit/discard/pending；③STAT→NUM/NUM结果/观察与CRC。NUM私有原scalar仍由原FIT拥有；原child不修改。CRC不能代替全部token/统计/响应的比较。

## 2. 明确测试族与固定种子

文字场景实际生成后须记录每case完整输入hash/数量/周期表；以下全部尚未生成、未运行。

- 固定尺寸6×5、8×7、16×9、1920×1080。
- 随机种子20261021（LS）、20261022（TLS）、20261023（协议/停顿）。每个kind11/12/17/18各256个合法小点集：从图内不重复坐标取点，再按(y,x)排序；点数0…128且不超过N。include覆盖全1、全0、交替与固定seed；梯度包含0、±1、±1020及域内随机，threshold固定轮换0/1/32768/65535，诊断只0。共1024正常统计case，真实FIT组合逐case比较。
- 逐项固定反例：平行LS；n0/1/2；TLS isotropic正方点；水平/竖直/斜线；部分include但完整E扫描；末点唯一贡献；三个点同坐标/倒序/重复ordinal/缺ordinal；x=W/y=H；G±1021及−1024；START/POINT/END/ABORT unused；width奇数/0/2047、height0/2047、version0、owner1、kind13；诊断threshold1；E>N；早END/错误声明/不同ID关闭。每反例单独case，不把随机“可能命中”当覆盖。
- 全1920×1080两场：LS全N坐标、Gx/Gy按行列奇偶±1020，全include；TLS全N坐标、合法梯度、全include。每场真实POINT数2073600，独立全体整数和及末点检查；同一统计场真实接原FIT，另外匹配已推导LS中心/全N TLS对称和。原始全POINT输入/输出事件保留，不用小场或CRC替代。
- 全尺寸稀疏场仍扫描N：include只取四角与三个内点，其余include0；kind11与12各一场，验证坐标域/计数/筛选交接。这里稀疏是样例，不限制生产E或n。
- reset：IDLE/CHECK/RUN四级各含点/DRAIN/PACK/HELD逐项；旧义务作废后新header；source/核/原FIT/observer共同reset。另单端reset仅协议反例，不判正常恢复。
- ABORT：零点、连续点每级、与提交同沿、首错后、END前最后点之后；同ID/pad0；不同ID ABORT随后原ID真正关闭；END后不得再造ABORT义务，测试caller正确接收/丢弃统计及已发布FIT事务的原取消合同。
- stall：token气泡0/1/3/8沿；stat_ready held0/1/8/257；真实FIT req/rsp相邻关闭；core独立输入连续一POINT/沿。观察器每个真实完整响应按585位计CRC。
- probe64个完整闭合job+reset后4个；源逐token与附稿LFSR/位置/profile逐项核对，STAT/NUM/CRC分别算；MAX−1两个job之后HALT，序号不能回绕。所有四kind正常数学路径必须实际观察到。
- 隔离数值helper：raw_seen u22最大−1/最大与增量1的完整u23资格、n=N−1/N加1、五typed字段最小/最大内外一单位。覆盖n优先及槽0…4错误选择，禁止在正常核用force篡改累加器冒当输入场景。PROTOCOL_STUCK只为恶意超过容器源保留，正常source故障进展在N+1内真实关闭；若不运行超长反例，明确报告该态动态未覆盖，完整进展论证不冒充状态覆盖。

## 3. 明确正常与异常运行期限

core最坏无停顿一个START/CHECK、E POINT、一个END、排尾/pack；每输入token间最多8个bubble，held最多257，取per-case cycle_limit=9×(E+2)+512，STAT在真关闭后6沿内形成，正常连续点单独检查接受间隔1。wall上限每小case300秒、完整1080p case3600秒、整套10800秒；这些是测试监测，不让RTL用timeout伪造END或清pending。

真实FIT组合在上述统计预算外再加16384个原FIT形成沿、1024个测试/握手余量，held257另计。probe一个job至观察完成上限9×(543+2)+16384+585+1024=22898沿；64+4正常观察总限取2000000沿，具体fault切点和reset段写manifest。永久无END/消费者永久不ready属于违反正常进展假设，独立有限监测须退出失败，不生成成功文件；expected-fatal同正常PASS分开。

编译目标按22文件明确顺序，pkg先于模块；vlog错误0，vopt的调试acc提示不冒当数学验证。normal结束须finished=true、完整case数/POINT数及三账全关；intentional fatal至少一个退出非0且不得生成success记录。Source/工具/场景/快照始末hash一致。修改后只重跑受影响且必需的当前完整scope，不重跑未变更旧R1/R2/FIT全部独立套件。

## 4. 正常组合逐沿走查

源START fire锁mode/ID/E→CHECK→RUN；POINT fire在t0锁S0，t1产品/t2 d/t3 ad-bd/t4提交。最后点te−1、END te，te+3最终统计提交，te+4离DRAIN，te+5形成STAT valid；此前不读取尚未提交的末点。

stat_fire=f：适配者锁NUM622，f+1最早NUM req_fire。原FIT为1个真实事务，rsp_fire=r时缓存585；r+1可检查真实quiet与stats quiet，若均为1则r+2最早observer_fire；后续585沿（第一沿r+3）移位，最后沿用新CRC。quiet尚未为1就留FIT_QUIET并继续实际检查，测试期限失效则FAIL，不以“过几沿”伪判断关闭；不得额外隐藏无界条件。

STAT失败：不发NUM；f沿按原metadata形成585错误，确认两核quiet后发表，observer消费后移位。STAT身份/矩阵破坏时，预期source上下文保留，响应为FRAME_FAIL/INTERNAL；不能把错误的STAT ID借给新caller。STAT成功n0：仍真实发NUM，原FIT检查LOCAL_COUNT；不能在适配层擅改为统计失败。diagnostic仍发17/18，不从11/12求几何后丢字段。

输入header非法：CHECK记录首错但源已有可能发布POINT，RUN仍接纳/丢弃其旧义务；源收到fault后兑现held POINT，发同ID ABORT；原首错而不是伪cancel返回。不同ID END不会关闭原ID；有限源必须再以原ID结束，否则明确不完整。

## 5. 发布证据与范围

真实同源联合Stats+FIT工程：原六RTL复制字节一致，22业务文件源hash绑定；25MHz/XLR≤56000/RAM0/DSP≤32。Map/Interface/Pnr/独立routed STA逐阶段新attempt、精确PID/创建时刻/argv及退出。保留原VDB/place/trace/interface/SDC，工具格式重排XML须逐节点/属性/文本/顺序相等，不把代码/参数变化当格式。

必检查实际Q→D：token槽→stats header/S0、S0→产品、产品→d、d→ad/bd、末级→五累加、统计槽→STAT结果、STAT→NUM槽、NUM槽→原FIT上下文、原FIT真实算术/返回、FIT/旁路→response_word、response_word→CRC。包括所有误差、cancel/复位和源字段保持的逻辑端点，按真实mapped名字查询，空集合/空报告失败；不能用CE/CLK/SR代实际数据D。级间reset Q1→D2及Q2同步释放另核，内部未约束/无clock/多clock0。

引脚复用获准FIT seed配置：J2 core25m、P13 KEY reset、N14/P14 LED，实际PT/pinout与电压/GCLK/4mA读回。这里只是联合数学probe，不证明生产相机/DDR/HDMI引脚。必要检查及源码/路由hash绑定通过才bit/hex、staging登记并停止硬件步骤。

## 6. 文件反向职责

六原RTL只复用原FIT/reset；新stats_pkg定义本独立token/STAT语义；stats_core执行检查/流水线/五项汇总；stats_probe_top拥有来源/注册交接/共享响应观察与CRC。三个model分别独立统计、输入/账/probe重建、原FIT大整数期望。四TB分别资格helper、统计行为、真实FIT组合、真实probe。三个runner/Tcl与三工程负责可复现、失败退出、同源和物理证据。

上述单位均对应主卡ST01…09与T01…12。无新模块负责候选选择、DDR物理返回、生产摄像显示或完整识别质量；没有把这次完成定义成全十一项完成。

## 7. v1.1：尾域实例的真实初始条件

主probe FIRST_SEQUENCE=0；尾域单独实例FIRST_SEQUENCE=2^64−2、同seed0x43106025，共同reset后仅两次START真实fire，分别seq MAX−1/kind17故障和MAX/kind18主动中止，关闭/观察完后必须HALT，后续257沿无START。当前身份从该START真正锁定，不能用force改在途计数或消息。把该实例作为单独reset/账/CRC段，不混进64+4统计；所有原默认硬件条件仍固定0。
