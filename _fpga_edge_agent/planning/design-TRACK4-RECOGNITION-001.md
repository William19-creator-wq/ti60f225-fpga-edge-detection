# TRACK4-RECOGNITION-001：圆形／矩形识别与预生成标注设计 v0.1

按[PLAN_TEMPLATE.md](PLAN_TEMPLATE.md)建立；2026-10-04。**LOCAL_DESIGN / NOT_APPROVED / NOT_READY**。这是一份候选设计和中文操作草图，尚无业务源码、参考程序、可执行测试、仿真或综合结果；不把有限工作量与资源算术当成识别准确率证明。

## 通用计划字段

- Goal：补齐完整11功能中T4-A6，以及识别到T4-A5/MOD-11显示的交接；用完整Canny边缘与梯度产生圆／任意旋转矩形候选，原分辨率核验，再预生成同源标注。
- Current state：FRONTEND v1待批准；FM v0.1、Canny v0.4、DDR服务v0.1均为有阻塞的局部稿；识别尚未实现。原资料只读。
- Target state：冻结数值、候选覆盖、输出／错误、资源与相邻端口后达到READY；获批实现再验证独立集圆和矩形各P/R≥95%、同类bbox IoU≥0.5及完整1080p事务。
- Gap：候选覆盖、量化／拟合／核验阈值、复杂场景可辨识范围、局部寄存器／算术、父job与ANN bundle、AUX授权、真实DDR／DSP／时序尚未闭合。
- Assumptions：软件实验仍假定V4/I3 Ti60F225＋SC431HAI彩色、1920×1080与HDMI60Hz；没有把相机或识别处理fps设为60。
- Open questions：见RC-B01…08；由Agent继续性能／资源比较，先前尺寸／数量／遮挡／噪声两组参数不恢复为硬限制。
- Dependencies：v0.2；[整体布局](../experiments/track4_full_sw_20261004/02_system/overall-design-layout.md)、[交接](../experiments/track4_full_sw_20261004/03_interfaces/handoffs-and-composition.md)、[Canny v0.4](design-TRACK4-CANNY-001.md)、[父任务附件](../experiments/track4_full_sw_20261004/04_local-designs/canny-parent-writer-sketches-v0.4.md)、[DDR服务v0.1](design-TRACK4-DDR-SERVICE-001.md)、[FM v0.1](design-TRACK4-FRAME-MANAGER-001.md)及匹配2Gb模型。
- Milestones：整体行为→组合／所有权→候选数值与中文草图→开发比较／独立集冻结→READY批准→参考与RTL→事务／质量／整机实现验证。当前只到前三项候选。
- Detailed steps：B/C先读整机职责，D看交接，E按OP顺序读局部，F看数值和资源，G/H看验证与追踪，I看未达到门槛原因。
- State transitions：局部LOCAL_DESIGN；不写正式PROJECT_STATE、TASK_LEDGER或DB；无 IMPLEMENTING 状态。
- Artifacts and hashes：A列实际输入哈希；[地址候选](../experiments/track4_full_sw_20261004/01_baseline/recognition-candidate-address-arithmetic-v0.1.json)和[评审](../experiments/track4_full_sw_20261004/05_reviews/recognition-review-v0.1.md)分类保存；本稿哈希由文档审计登记。
- Validation：仅设计分析／保存读回／只读来源与算术检查；RC-T01…16全部NOT_RUN。
- Failure handling：错误／容量溢出不得伪装零目标；已承诺段按MOD-05排空或隔离，未完成ANN不发布。
- Human approval gates：未申请本稿实现批准；无当前正确性阻塞才达到READY，之后明确版本／范围／基线。原FRONTEND和模型获取请求仍待答，不重复申请。
- Rollback：仅回退本次设计文档差异；原HDK／工具／旧冻结设计／状态不变。
- Completion criteria：本稿闭合且获批后，实际数值／事务／完整1080p／独立质量／资源与时序验证才能交付识别；整体仍须全部11功能与bit/hex。本次止于比特流后硬件步骤之前。

## A. 状态、事实与阅读入口

关联A6/A5/A3/A4、MOD-09及MOD-10/11交接；不声称这些正式节点完成。来源区分如下：用户保留完整功能和质量目标；资料事实是Canny完整梯度格式与当前DDR候选契约；本稿四阶段、32桶、候选容量及ANN图均为设计提议；可支持复杂场景和性能是未知。原先“96–768、比例≤3、最多4、遮挡20%、完整入画、对比64、纹理±16、噪声0–8／0.5%”均只是比较轴。

| 实际输入 | SHA256／含义 |
|---|---|
| 根规范v0.2 | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 |
| Canny v0.4 | 224779F89206F4113CB0764617401E96ED53D7CF34DBD43FBB60A800A54C8729 |
| Canny父任务／writer附件v0.4 | DE6172CF4910F593BD76622E304C56808EE62813ABA52D99E3EDF167758467DC |
| DDR服务v0.1 | 543D560FE9F9F4DFEB00386A7B5DBEF91F41075DB41133EF701F94068ED6AE32 |
| FM v0.1 | D4CD59B9183E3456757D35AEC7B3ADF3E0C09727EAB9070D3AEDA355FE1FC2FA |
| 原Canny 12区地址JSON | 4F38ADEAECE05621B82A2E2667A0099021A272F7F13B5759C191533001426B63 |
| EFX_RAM10现有模型 | DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33；20×512／1×8192模式实际读查；原语宽度静态，共享池实际选择固定20×512 |

上述不是本稿实施基线；READY前还需纳入父端口、冻结配置／模型／工具等。没有伪造commit；没有批准指定本稿实现。下一项允许行动为继续只读设计闭合及比较方案，不能生成业务源码或可执行试验。

| 阻塞 | 影响与需要的证据／处理 |
|---|---|
| RC-B01 | 圆粗中心格／法线误差可漏多圆、同心或图外中心，影响RC-02/03；比较多种子、分组、网格／扩域，冻结候选覆盖政策 |
| RC-B02 | θ、DDA边界、TLS／LS／半径峰／核验／去重阈值和记录字段尚未全部冻结，影响RC-02…05／IF-RC03…06；补整数逐步数值与局部状态 |
| RC-B03 | SEGMENT分段／投影排序、三边端点估计和真实负样本可辨识性未闭合，影响RC-03/04；独立比较保留反例，确定支持范围 |
| RC-B04 | MOD-04/05/11尚未吸收AUX_TEMP与ANN owner、四phase、job和bundle完整端口，影响所有权／发布；修订相邻稿并逐连接检查 |
| RC-B05 | 匹配2Gb参数／受保护PHY真实仿真／可见写与恢复未验证，影响所有DDR交接；保留既有模型申请，真实预检获批后执行 |
| RC-B06 | 58块识别预算仅容器，未含所有算术、标签、pipeline和元数据；DSP/XLR、跨PLL和整机PNR/STA未测，影响RC-06/08 |
| RC-B07 | 独立集分布／支持域未冻结且识别尚未运行；无法证明两类95%，影响RC-04/08；先开发比较，再独立锁定种子／标签／评分 |
| RC-B08 | 采集／显示最坏QoS、六源槽排空和识别期限未证；不能把HDMI60Hz当处理速率；整机调度／服务fence／slot回收需实际证明 |

## B. 整体可观察行为

识别启动在Canny最终EDGE和GRAD可见之后，保持同一源帧／配置／父任务身份及工作区租约。识别读原RGB、完整边缘及梯度；暂存点／候选；输出几何清单和完整2bit标注图。成功仅在全部输出写完成、MC引用与工作区正确归还后提出。帧管理将原源／EDGE／ANN原子组成显示bundle，显示域按真实VSYNC切换；旧bundle的ANN在RETIRE_DRAINED前不可写。

| REQ | 要求与观察 |
|---|---|
| RC-01 | 输入必须同一父任务、源／配置／epoch；EDGE点与grad32按同坐标匹配，非法descriptor／身份拒绝 |
| RC-02 | 圆候选不以连通或轮廓封闭为前提；完整梯度法线粗筛、原分辨率拟合、多个半径峰，粗筛漏检仍算FN |
| RC-03 | 矩形允许任意旋转；并行边／正交边与可见端点提出三边／四边候选，整条短边缺失进入测试；支持域待证 |
| RC-04 | 开发参数由整体质量／吞吐／资源比较选择；独立集圆／矩形各Precision和Recall≥95%，同类一对一IoU≥0.5 |
| RC-05 | 成功零目标与失败不同；内部候选／输出／计数溢出必须明确失败，不默默截断、饱和计票或丢弃失败帧 |
| RC-06 | 有限内存／有限循环，无同phase写后未fence读依赖；反压保留承诺、取消排空、不覆盖仍在显示的ANN |
| RC-07 | 标注预生成并完整写入同源ANN，显示每像素只取2bit图码，保持识别模式的原RGB／边缘／类别及文字对齐 |
| RC-08 | 报告计算延迟／fps、DDR交易和真实RAM/DSP/XLR/STA，HDMI60Hz单独；不得以设计预算宣称已达性能 |

正常走查：一幅包含旋转矩形和两个不同半径同心圆的源，经完整Canny→四阶段识别→核验与去重→ANN写fence→bundle换入。预期同心圆可各自输出，矩形输出旋转顶点，标签与该源一致；这是验证期望，候选算法尚未证明能得到它。

边界走查：三条边的U形图形可与缺失短边的矩形呈现相同像素；不能凭三边规则普适推断语义。测试保留明确类别／歧义标签政策，经支持域评审后评价，不擅自删歧义或负样本。输入合法但E=0时，输出count=0、全零ANN图；MC错误或候选容量不足是失败，不能给空清单成功。

## C. 职责与整机交接

普通文本数据路径：

源RGB＋最终EDGE＋grad32 → IF-RC01 接纳同源job
→ phase0 点提取 → POINTS
→ phase1 32角桶散写SORTED＋圆候选CIRC
→ phase2 SORTED／halo → 直线／线段／边对 → RECT
→ phase3 CIRC／RECT＋原图核验 → final清单 → ANN行生成
→ 全部终结／phase3 fence → IF-RC07 帧管理发布
→ IF-RC08 显示按N像素读连续2bit图。

| 逻辑职责 | 拥有的数据／依赖／理由 |
|---|---|
| MOD-09/R0调度与身份 | 独占job、四phase、MC tag／holding／错误及lease；依赖MOD-04/05，统一结束避免局部提前发布 |
| MOD-09/R1点与角桶 | POINTS、32桶目录／散写缓存；只选EDGE=1，完整Gx/Gy；不是按dir2限制方向 |
| MOD-09/R2几何候选 | 分时21bit累加器、圆拟合／半径峰、线／段／平行带／RECT；有限表／退出 |
| MOD-09/R3核验与合并 | 原分辨率支持／残差／法线／角覆盖、类别清单和去重；保留失败计数 |
| MOD-10/R4标注生成 | final清单、双行2bit掩码／跨行carry；自写，不在每显示像素遍历对象 |
| MOD-04／05／11 | 分别拥有slot／job／bundle、授权／物理承诺／fence、VSYNC／active／retiring；本稿不改变其所有权 |

自写候选算法，现有参考只提供输入格式／RAM原语／保护DDR。未发现可直接验收本需求的识别实现；没有据文件名推定质量或复用许可。几何累加器仅允许圆阶段和矩形阶段复用；同时存活的段表／终表／流缓冲不假定重叠。

## D. 接口、存储与组合检查

### D1. 八项交接

所有core侧ready／valid在core_clk上升沿以valid&&ready接受；停顿时payload与伴随身份保持。当前假定core100MHz，真实时钟／复位见RC-B06。接口是设计文档，不是已生成端口；未完成的父job／bundle布局明确阻塞。

| IF | 提供→使用；参数、前提、保证 |
|---|---|
| IF-RC01 | MOD-04/Canny→R0；job valid/ready、J486身份、W/H、识别cfg快照、scope H68、九grant H69及SRC/EDGE/GRAD/META/POINTS/SORTED/CIRC/RECT/ANN的base/L/A uint32；继承同父PROCESS scope与workspace lease，先验证再接纳；总packed job与cfg字段RC-B04/02 |
| IF-RC02 | R0↔MOD-05 client5；沿用DDR v0.1 req266、permit／prepare、W/R128与301bitterminal、release ACK、producer_close／seal／fence；R与W各两个128bit holding槽（两槽×128bit，不是128拍），实际请求／终态逐项记账，不另造可重开的phase |
| IF-RC03 | R1→R2；point64、logical count E uint21、θ512／桶32目录；严格row-major POINTS和各桶count，padding不作为点；计数／地址只在真实接受推进 |
| IF-RC04 | R2→R3；CIRC cap1024×32B、RECT cap1024×64B，候选有效数uint11，标志／几何／来源；phase3才读前阶段完整候选，字段布局未冻结阻塞 |
| IF-RC05 | R3→R4；final cap64×64B，count uint7，几何Q4／bbox／类别／score／flags；工作清单不可在绘制期间改变，类别阈值／去重规则待冻结 |
| IF-RC06 | R4→MOD-05 ANN写；header128B＋list4096B＋连续map，全部小图尾bit／byte补零，未用list条目零；写数据不等于结果可发布 |
| IF-RC07 | R0→MOD-04；不可变job身份／完成kind／err／E及候选／final数量／ANN descriptor／租约返还证据；最后W和R terminal＋release／fence／holding清空后成功；独立binding_return valid/ready与return_ack valid/ready必须先于完整status，payload回显经核验绑定的J／grant／lease，坏job不能指定释放对象；完整status packed layout RC-B04 |
| IF-RC08 | MOD-04→MOD-11；active bundle增加ANN descriptor、类别格式／count／generation，显示RO grant；读取header/list只用于换页与观察，扫描直接map；RETIRING旧读排空后返还 |

### D2. 明确输入和工作存储

令N=W×H，主实例1920×1080。EDGE低地址低bit顺序，L=ceil(N/8)、A=16ceil(N/128)。GRAD **32bit**，i=yW+x，地址base+4i；[10:0] Gx signed11、[21:11] Gy signed11、[23:22] dir2、[31:24]=0，Gx/Gy∈[-1020,1020]。即使NMS抑制，其原梯度仍存在；只对最终EDGE=1点使用。

POINT64提议：x[10:0]、y[21:11]、Gx[32:22]、Gy[43:33]、dir[45:44]、θ[54:46]、[63:55]=0，角θ在[0,511]表示π周期法线；非dir2代替。保留位不为零或EDGE=1且Gx=Gy=0定义为输入语义错误，终结失败，不产生法向除零。依据实际Canny CN-04/05：Mgrad>0才可NMS保留、Mnms=0为NONE、严格双阈值即使阈值0也不保留零幅值；合法最终EDGE点必有非零G。不能把坏输入点跳票后成功，也不把dir00当非零梯度证据。θ变换的整数边界／舍入RC-B02，不能假定atan实数自动可综合。

POINTS容量8N；若E奇数，末8B补到16B，不当第二点。参数检查沿实际Canny候选：W为偶数6…1920、H为5…1080；小图仅用于局部事务测试，生产1920×1080。粗格Wc=ceil(W/16)、Hc=ceil(H/16)，实际有效格Wc×Hc≤8160，主实例120×68；未用物理cell不当图内坐标。SORTED每桶独立16B起址；P_b=16ceil(count_b/2)，prefix按P_b累加，logical count与physical extent分开；每桶末half零。Σcount=E且ΣP_b≤8(E+32)，上界8(N+32)=16,589,056B。不能按紧凑8N让两个桶尾／首共享beat并互相零覆盖，也不能在本phase回读SORTED补half。32桶每桶16θ，halo读取按真实count跳padding。

META提议128B阶段头＋32×16B目录=640B，单目录项count/byte_offset/physical_extent/cursor各uint32。CIRC/RECT候选容量及final64只是**内部资源比较配置**；不把64改写成用户目标数限制。出现容量失败须保留于性能与质量统计。CIRC32B、RECT64B、final64B容器和Q4坐标是提议，详细字段与拟合范围未冻结不允许实施。

ANN每结果槽独占：相对0头128B；相对128清单64×64=4096B；相对4224图ceil(N/4)=518400B；主实例总L=A=522624B，页分配524288B。2bit编码00无标注、01圆、10矩形、11文字或不同类叠加；背景不清除已画位，不同非零码冲突取11，11保持。文字字形／颜色由MOD-10/11进一步冻结；不是承诺中文汉字ROM已存在。

[独立地址算术](../experiments/track4_full_sw_20261004/01_baseline/recognition-candidate-address-arithmetic-v0.1.json)追加于原12区之后，不改旧图：AUX_TEMP [0x034AC000,0x0546A000)，33,284,096B；ANN0/1/2合计1,572,864B；新增总34,856,960B，原图像页55,226,368B加新增为90,083,328B，另低4KiB保留，高水位0x055EA000，假定256MiB剩178,348,032B。TEMP页gap存在；TEMP跨度仅描述地址分配，不授整span RW。五TEMP子区分别按精确L/A建立grant，META尾3456B、SORTED尾3840B不授；各ANN尾1664B也不授。数学非重叠不证明2Gb物理地址映射。

### D3. 四phase与所有权（相邻稿必须修订）

| phase | 允许读的已完成数据 | 写出 | 封口前本地义务 |
|---|---|---|---|
| 0 | SRC（需要时）、EDGE、GRAD | POINTS＋META0 | 点尾half、目录／头及所有请求先产生，后request_generation_closed／seal |
| 1 | POINTS、META0 | SORTED、CIRC、META1 | 桶尾half／圆候选／目录全发；不读本phase刚写的SORTED/CIRC |
| 2 | SORTED、META1、原图及POINTS | RECT、META2 | 角batch→线／段／pair→候选均在本地闭合；不回读刚写RECT |
| 3 | CIRC、RECT、META2、SRC/EDGE/GRAD/POINTS | ANN完整头／清单／图 | final在片上，核验和绘制结束；全部尾padding／MC终结归还后fence |

四phase不可重复close/reopen，也不能拿同phase早返回的B自行假定全机可见。阶段头在本phase只写，下一phase读；取消后只结清已承诺MC段，不继续产生新业务，采用MOD-05保持域与隔离语义。各局部在pending关闭／读bankterminal/release前不能申请同client另一读并等待彼此。

需要父稿吸收：

1. DDR region5原来未grant；必须区分WORKSPACE-owned五TEMP子区与RESULT-owned ANN W，完整owner范围／generation。识别共九grant：SRC RO、EDGE RO、GRAD RO、META/POINTS/SORTED/CIRC/RECT按phase权限、ANN W；显示每bundle SRC/EDGE/ANN三RO。所有返还ACK后下一沿才复用。
2. Canny status消费不释放GRAD／workspace；识别最后真实读、pending/capture及local bank义务结束、fence和grant返还后才归还workspace。ANN结果租约保持至显示／pending／retiring全部归还。
3. 只有按顺序先返还旧Canny／reader再授予新识别，32grant峰估算才可为6 capture＋3×3显示＋9 PROCESS＋1diag=25；scope峰6＋3＋1＋1=11。这些只是组合候选，不证明32 phase records足够。
4. 旧整体02仍写“幅值16＋方向8”；本稿消费实际Canny grad32，不能给旧格式隐式兼容。00/02/03作为FRONTEND冻结输入不修改；整机统一版本须显式修订格式／预算／bundle。
5. MC服务17RAM与Canny44、识别58均为候选，不证明六槽SOF期限／HDMI水位。真slave可见读、端口、时钟、恢复及ROW14器件仍阻塞。

## E. 局部中文操作草图

### E1. 状态与不变量

R0候选顺序：IDLE→VALIDATE→P0_EXTRACT→P0_CLOSE/FENCE→P1_BUCKET_CIRCLE→P1_CLOSE/FENCE→P2_LINES_RECT→P2_CLOSE/FENCE→P3_VERIFY→P3_ANN→P3_CLOSE/FENCE→RETURN_LEASES→STATUS_HOLD。取消可进入CANCEL_DRAIN；未知排空进入QUARANTINE，不能用新epoch抹去承诺。每个循环由当前count和地址限定，不用固定帧超时冒充算法结束。

| INV | 始终保持／建立方式 |
|---|---|
| RC-INV01 | POINTS每条对应唯一最终EDGE点；只有对应读实际接受并核对后E增加 |
| RC-INV02 | E≤N、各桶count和为E；padding不增加数量，目录extent与offset相容 |
| RC-INV03 | 一个point对一个圆格／一个(θ,ρ)只贡献一次；否则21bit计数≤E证明失效 |
| RC-INV04 | 已握手或已提出的MC valid/payload保留至其义务终结；取消不撤回物理承诺 |
| RC-INV05 | phase monotonic且关闭不重开；没有同phase新写区读依赖 |
| RC-INV06 | 输入bank未全捕获／terminal／release就不借其同client READ资源等待新请求；仍在使用的EDGE/GRAD/point输出各有独立地址区 |
| RC-INV07 | 累加器读最新值后写；同址再票先消费前次提交／forward，不读不确定collision |
| RC-INV08 | 几何／候选／终表容量有检查，超限失败；不以输出前64条冒充完整成功 |
| RC-INV09 | ANN只在本job独占的WORKING结果槽生成；发布后到所有引用归还前不可修改 |
| RC-INV10 | final清单及status提出后保持；success需所有fence／租约／holding条件，零目标也写完整ANN |

### RC-OP01：接纳与绑定检查

输入：IF-RC01 job、旧IDLE状态、grant/descriptor、cfg。先检查W/H与N范围、乘法扩位、地址16B／页范围、各role owner／身份／generation及四phase未使用；组合非法先记录错误与需返还的有效绑定，不索取业务读。合法握手沿保存完整快照，下一ACTIVE沿才能接受取消；同沿取消不撤销已经接纳job。禁止边执行边读取可变控制阈值。

输出：固定job、已登记lease与P0入口，或固定失败记录。RC-B04仍需完整packed参数／父返还端口审查。

### RC-OP02：完整原分辨率点提取

输入：最终EDGE／grad32已完成范围，旧i/E和32桶计数全零。按row-major扫描。四条20×512并行形成512×64bit池（每word高16零），分四个互不覆盖的128word区：P0分别保留EDGE原始mask、GRAD原始字节、POINTS待写源，第四区作独立工作暂存；不是一个128区同时保存三种数据。每MC段≤64×16B=1024B，单区恰可全捕获；128bit R拍先锁到holding，再分两个64word写入，写完才接受下一拍。EDGE整段可覆盖8192像素，在对应多个GRAD批次处理结束前保留。GRAD段最多256像素，POINTS区容量128条，不足时先flush/归还并停点计算，不能覆盖未借用结束的数据。只有完整接收段并消费terminal/release后才申请另一READ。读口在EDGE mask、GRAD capture、POINTS writer间显式串行仲裁；在FF保留当前mask／梯度／pending读结果，非授权沿不RE，仲裁／metadata细状态仍RC-B04/06。EDGE=0忽略原grad；EDGE=1检查非零G和保留位，取完整signed G计算π周期θ，组64bit point，POINTS顺序两条组成16B拍。E与桶count仅在点真正交给本地输出holding时增加一次，DDR反压保留holding及索引。

结束：N像素完整扫描、最后half补零、META0写出，所有段请求生成完再封口；不是只看EOF或末W握手。P0 fence确认后P1才能读POINTS。E=0仍写有效空目录，后续候选和ANN count0路径不漏终结。

### RC-OP03：32桶scatter与圆法线投票

输入：完整POINTS/META0。先完整读META0的640B并终结／release，在本phase只用片上完整目录；封尾时才写META1，不在本phase回读被覆盖的META。后续phase2也先完整读取上一阶段头／目录，末尾才写下一版本。先计算每桶16B physical前缀，不把logical count直接乘8代替。每桶16×64bit缓存，只在桶满16或POINTS逻辑EOF后封尾；暂时奇数occupancy不提前零补后继续追加。occupancy uint5可表示0…16，bucket/entry定位四条20bit RAM。满桶16条固定128B、8拍，选择SEALED且不再修改的桶作为W owner；EOF尾k条时nbeats=ceil(k/2)，奇数第二条零，k=0不发。桶所有W数据由已封口本地存储提供，不等待新point／DDA／LS才能交剩余W。满桶按完整16B拍送出，EOF尾half零；32桶独立offset／cursor，pending写不允许新点覆盖其源buffer。目录每个uint32用两20bit word（低20／高12＋高8零）、每entry八word；更新cursor锁entry，两word写完才解锁，latest staging避免同桶连续读旧cursor。容量不足暂停输入处理，MC后台及本地RE/capture/terminal/release仍前进。32桶/CIRC/META本地W选择的公平性与小状态需另证，不从7client RR推出；旧POINTS输入点处理完且借用结束后才改该区为LS读bank。

同遍可将point完整法线裁剪至粗中心网格。提议pitch16，120×68=8160有效cell、8192物理深度；一次遍历完整线段，半开cell唯一归属，不用正反ray重复原点。选薄线DDA时最多120＋68−1=187cell/point；若改supercover或法线容差走廊必须公开重算，不能保留187。Gx/Gy不是θ近似线。共享17块全部固定20×512，不能运行时改变原语宽度。圆低20bit在16块（bank=cell[12:9],addr=cell[8:0]），高bit在第17块按16个cell打包（addr=cell[12:4],bit=cell[3:0]，高4bit零）。同步RE所选low与high word→下一沿CAPTURE→扩22bit加1检查→WRITE low20并RMW high word保留其它15高位；提交后才访问下一cell，避免相邻cell共high word读旧值。私有累加器逐址清零；模式切换需RE/capture/WR/pending借用全空后再清规定地址，RAM不整阵复位。native1×8192是已有原语模式事实，但不是这个运行时复用池的配置。

该方案仅在图内粗中心提出候选：**图外中心、同格多个中心和正常噪声偏移目前RC-B01**。不将其变成“目标完整入画”要求。需要多种子／扩域或替代路线的证据后才可冻结。

### RC-OP04：圆原分辨率拟合与多半径峰

输入：on-chip中心票峰和已完成POINTS。按粗峰局部候选选择支撑法线，再做整数法线LS：a=Gy、b=−Gx、d=a·x+b·y；A=Σa²、B=Σab、C=Σb²、D=Σad、F=Σbd。Δ=AC−B²；cx=(DC−BF)/Δ、cy=(AF−BD)/Δ；分子先扩位再Q4缩放与有规则舍入，Δ=0／负或条件差拒绝退化拟合。梯度强度隐含权重可能偏向遮挡边，须开发比较。

中心周围原点集做半径／径向残差／法线／角覆盖核验；同心圆允许多个半径峰，不能每中心只留一个。角覆盖阈值尚未冻结，不暗设80%恢复撤回遮挡范围。圆候选生成在片上当前种子工作集，逐条写CIRC；本phase不读CIRC。峰数、半径domain／聚类／稳健迭代及精确小状态仍RC-B01/02；一次LS不能自动恢复合并粗峰。

### RC-OP05：角batch直线、线段与矩形配对

输入：P1完成SORTED，512θ、每batch16，循环32batch；读当前32桶之一与左右halo桶，按θ window筛选，边界按π周期wrap。每batch读取完整prev/current/next三个散桶，再按θ window过滤；来源桶每batch最多扫描一次，每个targetθ仅由所属batch更新，因此(point,targetθ)不重复。实际最多3E×8=49,766,400B加必要padding，不能按两个单θ halo低估。投影按目标θ重算；跨θ511↔0的NMS／峰合并须rho反号，276bin中心映射r→275−r且边界tie/±1待冻结，不直接用同rho index邻接。

提议像素中心：X2=2x−(W−1)、Y2=2y−(H−1)，各signed12，单位半像素；ρ2=X2cosθ＋Y2sinθ。Q15系数容器signed17、范围[-32768,32768]，cos0=+32768不能用signed16。各乘积signed29、投影和P signed30；r=floor((P+2208×32768)/2^19)，加偏置先扩signed31、检查rho范围后取uint9的r0…275。floor／正端点／theta系数生成数值仍需逐项核查。1080p绝对上界约2201.545，范围[-2208,2208)／pitch16为276有效ρbin，512 stride其它236不投票。一个ρ地址同时存16个count21，共336bit置于17条20×512 RAM（340bit）。同步读后串行更新一／多个相应θ字段；21bit计数溢出失败，保留padding零；不能假设原语21bit宽。投票halo窗口h∈{0,1,2}作为开发比较参数，h=2时每point最多5个targetθ票；它不是只用于峰合并的角门槛。≤3桶加载与每point≤5票为不同工作量。量化／window边界未冻结。

每batch提取多个line峰并原分辨率TLS／投影支撑分段；不同支撑区不能只global min/max合成一条边。SEGMENT cap1024、PARALLEL_PAIR cap512，分别明确完整表／计数；遍历segment对≤523776，三边pair×segment≤524288，四边pair对≤130816。合格RECT最多1024，超限失败。coarse容器提议：linepeak64=θ9/rho_bin9/count21/flags25；segment128可容peak_id10/θ9/fineρ2 signed13/tlo/thi各signed18 Q4/count21/occupied14/maxgap14/flags8，共125bit，其余3bit零；pair64容两个segment_id各10/θ9/粗分数及flags35。TLS n21＋Sx/Sy各signed33＋Sxx/Syy各uint43＋Sxy signed44共217bit，不能偷放128bit segment或final；phase3当前四边stats至少868bit另外核算。跨batch NMS边界／环首尾carry及其清零保留尚未闭合，不假设已存在于17块。三边矩形从两条平行长边、另一端垂直封口及两个可见远端的共同支持终点提出缺失短边；实际端点／误差／支撑分段与U形负样本RC-B03。

可对候选重新TLS和正交性／端点／残差核验，最终旋转坐标不能锁死512θ中心；phase2只写RECT，在P2 fence后读。ρ2用半像素，不能把pitch16写成16像素。理想最近θ量化基准误差≤0.17578125°，全图投影约≤3.378px，Q15系数附加≤0.023px，rho cell中心≤4px；整数θ判角自身误差还须单独界定，不能把基准当实际θ实现误差；halo角偏差并不自动享有最近角界。最终误差需拟合／核验实测。

### RC-OP06：原图核验、去重与有限终表

输入：P2完成CIRC/RECT、原RGB／EDGE／GRAD／POINTS。分批读候选，全原分辨率检查可见轮廓／梯度法线／颜色支持／几何残差与可辨识性；记录支撑／反例分数。清单排序／同类合并／同心处理必须保留不同真实几何；不能只按框重叠删掉同心圆或重叠目标。

final cap64当前仅资源选择，每对象64B逻辑、片上32×20bit=640bit容器，64条2048word，4RAM。每条装配／解包／保留位需要确定；输入原有候选溢出与终表不足都是明确失败。打分、门槛、去重顺序及出现第65对象时的完整政策尚待RC-B02/07，不能截断成成功。所有质量失败保存输入配置和原因。

### RC-OP07：逐行预生成2bit标注

输入：不可变final清单，ANN由本job独占的WORKING结果槽。两row bank各2bit×W，1080p是192个20bit word（每word10pixels）、1RAM／bank。先逐word清零当前row，再按对象bbox选择与该y相交的圆轮廓／旋转矩形边／标签，求交点／水平段，裁剪仅显示写坐标至[0,W)；几何输出允许表达图外位置，输出范围仍待最终域。x除10／余10选择word与2bit lane；RMW保持latest-word／pending转发，重复命中一word不能丢先前色位。

清空／绘制／送出为分离bank状态，图码冲突采用D2合并；每row只序列2W有效bit。map连续i=yW+x，不逐row补16B；输出assembler跨行carry，最后全N像素才补bit／byte到完整16B拍。小图W6,H5,N30，map L8/A16，末4bit和后8B为零；行bank内部剩余bit不插入DDR图。

写bank在对应数据已复制到MC holding／不再被引用后才复用；若尚作为输出源，要等真实接受与义务释放。最后有效数据／padding／header／未用list全零均产生请求后关闭phase3；全部fence之前不发布ANN。sqrt／旋转交点／字形／笔宽精确舍入与下游颜色仍RC-B02/06/04，不能借中文草图声称已综合。

### RC-OP08：终结、取消与发布

输入：各phase fence、last read/write、terminal与release ACK、holding/pending/cache／lease旧状态。正常先冻结local_result几何／数量，继续收集MC/fence及独立绑定返还ACK。TEMP/GRAD按父契约返还；ANN/SRC/EDGE归slot引用规则。只有完成记录将包含的实际证据全部采样后，才冻结完整status并提出valid；返还请求／ACK接口必须独立于status消费，不能由父等status后才释放造成互等。status提出后payload稳定；消费不是抹去显示ANN。

取消时停止新业务；已valid、permit、req、物理B/R与capture继续MOD-05义务；未承诺后段可丢。FAILED_DRAINED需要已排空证据；无法证明排空QUARANTINED，不复用槽、workspace／generation。逻辑reset保留服务及client5承诺域：完整旧ctx/permit/held req/W、assembler/carry、被旧段借用的point/scatter/final/row bank及RAM pending不由私有流rst清除；保持域继续真实req/W/R/terminal/release/fence/返还记账，合法终结或匹配旧scope安全恢复后才回收。不能清账后把旧响应接受到新job。QUARANTINED/drained0 status提出后不随后来排空改写；恢复以独立旧scope事件返还。完整父发布/返还端口未合入，保持RC-B04/05。

## F. 数值、语言、时间与资源

不采用C++实现，所以C++对象／RAII不适用；未来若选择须另写。候选软件参考沿FRONTEND用本机Python3.14.6标准库：几何解析真值／评分与位精确候选参考分开；无限精度整数需显式按已批准RTL宽度／舍入比较，不能成为硬件溢出掩盖。参考／RTL／事务三个契约都尚待闭合。

| 数值 | 候选表示／依据 |
|---|---|
| x/y与E | uint11坐标、E uint21≤2073600；乘法／前缀地址先至少uint64再检查32bit范围 |
| vote | uint21，扩22bit加法检查；一次point／cell或θρ条件才能保证≤E |
| LS d／A/C／B／D/F | d signed24、A/C uint43、B signed44、D/F signed56为保守容器；不以隐式乘法截断 |
| LS Δ／中心分子／Q4分子 | 分别signed89／signed101／signed105；阈值／舍入／条件数未冻结，宽乘除需串行共享或明确资源 |
| 坐标Q4 | 中心／矩形顶点signed18、半径uint17作为候选输出容器；不能暗推最终支持域为该范围 |
| 角与rho | θ uint9 π周期；coeff Q15、ρ2范围与bin由OP05；生成／舍入／负边界规则未冻结 |

core100MHz条件下圆薄DDA最坏387,763,200票，理想一更新/沿3.878s，三沿RMW约11.633s，另加清零／峰扫描／拟合／原图读；supercover保守254则526,694,400票、理想5.267s／三沿15.801s。半径枚举pitch4/step4基线约2,285,107,200票；只作比较，不承诺最优或fps。图纹理使E近N是保留最坏输入，不能假设自然边稀疏免除。

phase0一次EDGE+GRAD全读8,553,600B；POINTS最多16,588,800B。phase1读POINTS一次＋scatter最多16,589,056B，圆拟合额外扫描需另计；phase2每batch最多当前及邻桶，理想每point≤3次加载，但radius／line refinement等附加扫描尚未冻结。phase3按候选扫描原图可能昂贵，批量核验与每候选deadline仍RC-B02/08，不能用最低流量当整机总带宽。

| 片上候选存储 | RAM10数与物理组织 |
|---|---|
| 圆／矩形共享累加器 | 17；全部固定20×512，圆低20用16块＋第17块每word16个高bit（高4零）；矩形16×21条带17块，分时排空／重置 |
| LINE_PEAK 1024×64bit | 8；4条20bit×两depth512 bank |
| SEGMENT 1024×128bit | 14；7条20bit×两depth512 bank，字段是否够RC-B02/03 |
| PARALLEL_PAIR 512×64bit | 4；4条20bit×512，字段是否够RC-B02/03 |
| final64×640容器 | 4；2048×20bit序列word |
| 双row bank | 2；各20×512使用192word |
| 独立输入／输出池4区×128×64bit | 4；4条20×512分区，EDGE/GRAD/POINTS源不互盖、读口串行；不能与同时scatter共用 |
| 32scatter bucket×16×64bit | 4；4条20×512，地址bucket/entry |
| 32桶count/offset/extent/cursor目录 | 1；每项8×20=160bit，256word；每uint32两word，cursor原子锁／latest staging；头／live count另计 |
| 识别已列小计 | 58；未含完整乘除／CORDIC或查表／半径hist／标签ROM／额外holding、metadata及所有pipeline |
| 既有Canny44＋DDR服务17 | 61；保留已列范围 |
| 全部已列 | 119/256=46.484375%；**不是全机资源利用率或综合通过** |

真实EFX_RAM10同步1R1W／OUTPUT_REG0读在RE沿后更新，相邻逻辑下一沿CAPTURE；不假定RAM全清或同址读写值。final容器每条512bit占26个有效20bit word（末word高8bit零）及6个保留零word；bank=slot[5:4]、地址={slot[3:0],word5}。跨行carry128bit／MC holding／每桶尾half与pending保持需算FF，不藏入58块。优化比较可在明确互斥阶段复用表或增加parallel bank；四bank计票不能自动算4倍吞吐，热点／同址冲突必须处理。

RTL契约：SV2009目标工具语言；单core上升沿，cfg在job握手取旧寄存器快照，同沿cfg改只影响后job；气泡不当point，握手才推进数量；stall保持身份/payload；每个RMW不依赖原语collision，17块共享池原语宽度静态；phase关后不新开；逻辑复位保留MC承诺；最终配置／domain复位／CDC/STA未闭合。没有固定流水总延迟；条件工作量＋服务opportunity不等于时钟deadline。

## G. 实施顺序与文字验证计划

当前仅允许继续设计／评审。未来达到READY并指定批准后：独立几何真值和位精确参考→点／桶→几何候选→核验→ANN→父job/MC/显示组合→完整1080p与独立质量→整机综合／PNR／STA。计划职责为recognition_job、point_bucket、circle_candidate、rectangle_candidate、shape_verify、annotation_raster及对应reference/test；**都未创建**。试验本身若要可执行，同样先缩小设计并获批，不借研究脚本绕过。

| TEST | 输入／期望／观察；均NOT_RUN |
|---|---|
| RC-T01 | 同源合法／错generation／错descriptor／零梯度EDGE输入；非法绑定及EDGE1/G0明确失败，Canny CN-04/05严格零值政策相容，不产生除零或伪0°投票 |
| RC-T02 | N30、E0/1/奇数／N、32桶不均；POINTS逐点、θ目录、16B尾和Σcount=E，padding不计点 |
| RC-T03 | 相邻桶各奇数、桶full与W反压；scatter独立边界不覆盖，无同phaseDDR RMW |
| RC-T04 | 法线水平／垂直／过角点／格边／ray原点；一point-cell一次、187薄线或所选完整上界；22bit超限失败 |
| RC-T05 | 多圆同粗格／同心／图外中心／噪声偏法线／强梯度偏权；候选遗漏保留FN，LS退化／宽除法不输出伪圆 |
| RC-T06 | 矩形角近0/π／θwrap／halo重复／负rho边界；ρ2与实数几何误差独立比较、同θρ不重复 |
| RC-T07 | 三边／整短边缺失／分离共线段／U形负样本／重叠；原分辨率端点与标签可辨识政策，不以闭轮廓过滤 |
| RC-T08 | 线峰／段／pair／CIRC／RECT／final超容量及21bit溢出；明确失败，保存输入，成功列表不截断 |
| RC-T09 | 小图及1080p标注圆／斜矩形／水平边／文字同word冲突；2bit连续跨行，N30最后4bit／8B补零 |
| RC-T10 | 四phase关闭及fence延迟、最后half／dirty pending；后phase只读已可见，封口不阻塞未发尾段 |
| RC-T11 | 同client READ holding满、核验另读、writer阻塞；完整bank先终结／release，无资源互等 |
| RC-T12 | 每阶段cancel/reset、valid同沿、早failed terminal和未知排空；承诺保持、失败不发布、隔离不复用 |
| RC-T13 | ANN旧display／pending／两RETIRING，识别占workspace；25grants组合、slot/lease全部ACK后复用 |
| RC-T14 | 开发集轴尺寸／任意旋转／数量／遮挡／裁边／噪声／纹理／对比／负样本／重叠，比较pitch8/16/32、batch／并行存储与候选容量；不以撤回参数选易样例 |
| RC-T15 | 冻结独立集，解析GT框和类别；同类IoU≥0.5最大基数一对一匹配，重复FP、未配对GT FN、错类影响两类；每类P/R≥95%，失败不剔除，空分母政策先冻结 |
| RC-T16 | 全1080p实际DDR／核心时钟，读写计数／deadline／fps／跳帧＋HDMI60Hz，RAM/DSP/XLR及PNR/STA；匹配2Gb器件／PHY另验证，不用AXI行为模型替代 |

独立集种子／分布／GT／评分器在开发结束后锁定并哈希；不能边看最终集边调参。算法参考位精确与真值质量两个结果分开；小图通过不等于1080p。每次实际运行保存输入／cfg／job／工具／日志／波形／比较数量与正常结束证据。

## H. 双向追踪

| REQ | MOD／接口／草图／不变量 | 计划职责（未实现） | TEST |
|---|---|---|---|
| RC-01 | R0/R1、IF01/02/03、OP01/02、INV01/02/04 | recognition_job／point_bucket | T01/02/10/12 |
| RC-02 | R2/R3、IF03/04、OP03/04/06、INV03/07/08 | circle_candidate／shape_verify | T04/05/08/14/15 |
| RC-03 | R2/R3、IF03/04、OP05/06、INV03/07/08 | rectangle_candidate／shape_verify | T06/07/08/14/15 |
| RC-04 | R3、IF04/05、OP06、INV08 | shape_verify／独立评分 | T05/07/14/15 |
| RC-05 | R0/R3、IF04/05/07、OP06/08、INV08/10 | job错误／有界终表 | T01/08/12/15 |
| RC-06 | R0/R1、IF01/02/06/07、OP01/03/08、INV04/05/06/09 | MC记账／phase／lease | T03/10/11/12/13 |
| RC-07 | R4、IF05/06/08、OP07/08、INV09/10 | annotation_raster／显示map读 | T09/10/13 |
| RC-08 | R0/R2/R4、IF02/08、OP03…08、INV06/08 | 流量／周期计数／真实实现报告 | T14/16 |

IF表编号的IF01指IF-RC01，TEST表T01指RC-T01，避免误认为整体同号接口。反向上列六计划职责各有要求与必要性；后续真实文件／symbol／hash／测试结果才填入。本稿补充T4-A6、A5、DER所有权／性能，不能把其它十项划为已完成。

## I. 门槛自检与实际评审

| v0.2 §10.3 | 当前证据／结论 |
|---|---|
| 1整体行为／样例 | B，输入／输出／错误和可辨识反例明确 |
| 2职责／连接／来源 | C及A，原梯度/RAM来源已查，识别自写 |
| 3接口／相容 | D；父job／AUX／bundle仍RC-B04/05 |
| 4数据／状态／中文草图 | E八OP十INV，有具体pending／padding反例；算术细状态尚未闭合 |
| 5语言／映射／资源 | F有位宽／事件／物理容器；CORDIC／拟合／字形及全机资源未知 |
| 6局部／整体走查 | B/D/E；候选漏检和三边歧义保留 |
| 7实施／验证／追踪 | G/H八REQ十六文字场景，全部NOT_RUN |
| 8无正确性阻塞 | **不满足，RC-B01…08** |
| 9保存／读回／呈现 | 保存后实际读稿审查见05记录；用户实际理解待检验 |
| 10版本／范围／基线 | v0.1候选范围清楚，未冻结实施基线、未获批 |

所以不能标READY或声称可以立即按本稿编码。本稿分析推进允许继续，不替代原明确批准闸门。

## J. 变更记录

v0.1首次形成：完整grad32替代旧整体预算作为实际输入；依据Canny CN-04/05保留EDGE1/G0非法语义失败；共享17RAM统一静态20bit与高位打包；4流RAM划为四128word区／显式共享口；不要求连通封闭轮廓；32bucket独立16B尾避免scatter覆盖；四不可重开phase避免写读feedback；RESULT-owned ANN与WORKSPACE-owned TEMP分开；预生成2bit图降低显示按对象遍历压力；显式高宽LS及候选覆盖／歧义反例。都是批准前候选，不修改冻结FE/FM/Canny/DDR稿。

未来修改pitch／角window／候选容量／supported domain／位宽／fence或所有权，先修订设计、地址和追踪、重新评审；不能以内部优化名义改变识别范围或完整Canny。

## K. 实现与验证实录

本轮只读现有需求、设计／RAM源，进行容器与地址算术、独立分析及保存读稿。当前业务RTL、功能性脚本、reference、testbench、任何RC测试、真实DDR、综合、PNR/STA、bit/hex均NOT_RUN／未生成。设计审查不是软件功能仿真。没有修改正式状态／审批／数据库、没有下载模型或操作硬件。实际本稿与地址文件哈希、链接／基线复核在当前document-checks.json登记。

## L. 阅读与人工观察路线

先[实验入口](../experiments/track4_full_sw_20261004/README.md)00→01→02→03，再本稿B看输入到显示、C看职责、D看四phase与所有权、E按OP01…08跟一帧、F看数字来源／预算、G/H查测试及修改入口。第一次观察应看job／phase／MC实际接受与fence、E和bucket count、候选／失败、ANN写完成及真实VSYNC；波形尚未产生，不能登记人工观察已完成。

完整例子：EDGE合法非零梯度点→point64→桶tail独立补零→圆/矩形候选→原图核验→final工作表→row2bit→跨行carry→最后W／R release→phase3 fence→ANN发布→VSYNC active→旧ANN RETIRE_DRAINED。改变识别范围先改RC-04／B及G独立集，沿H找到OP/字段／容量／预算，再修订父接口与获批源码。源码尚未生成，文档—注释—代码一致性只能待实施复核；功能验收未运行，用户理解验收待检验。
