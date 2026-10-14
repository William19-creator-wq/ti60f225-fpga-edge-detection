# 识别数值与记录候选 v0.1 实际评审

2026-10-04；关联 TRACK4-RECOGNITION-NUMERIC-001 与整机设计 v0.16。**LOCAL_DESIGN / NOT_READY / NOT_APPROVED**。这份记录是只读设计审查与文档读回证据；全部业务实现和运行验证均未执行。

## 1. 阅读对象与实际范围

数值稿：[design-TRACK4-RECOGNITION-NUMERIC-001.md](../../../planning/design-TRACK4-RECOGNITION-NUMERIC-001.md)。最终338行/24,212字符实际全文读回；root写后文本与预期一致，独立审查者读前/读后SHA一致：

`17C4A290414970260BBADC7B5286F6C6F5608E3B03E0FF38E08E3E5E1491F39A`

作者为/root/canny_queue_ports_detail；/root/canny_state_cache_detail审查θ/ρ边界、ROM表示与舍入；/root/canny_state_cache_detail/dp_join_check审查记录、LS/TLS、有限holding及取消。root实际读回完整稿并修订圆周环绕、径向宽度、精确直线残差与FORMAT取消，后一审查者再次全文核对上述最终字节。作者首次交付的60CE…版本与中间DC6A…版本不是本次最终基线。

父RC、CONTROL、CONTROL-JOIN、DATA-JOIN字节未修改。当前数值候选须由后续父设计显式吸收，不能把保存新稿当作完整RC已升级或已获批。

## 2. 已闭合的具体设计问题

| 问题与反例 | 最终候选规则与审查结论 |
|---|---|
| 128阈值有129种fold结果，7次不能覆盖所有叶 | θ二分最坏8次；cross严格大于0才越界，等号取低fold，未宣称全θ低编号tie。 |
| floor负数/零点及旧275−r会错格 | 277个对称RNE中心，r138自镜，mirror=276−r；stride512另235未用；±0.5→0、±1.5→±2。 |
| ROM的32768不能收signed16 | 两unsigned16 Q15系数各占一个20bit word，读取后扩signed17；129×2=258word。θ边界128×60=384word。 |
| 径向向量超Sobel域 | dx/dy先signed19、abs unsigned18，Q30乘积48bit/cross49bit；梯度路线仍10/40/41bit。 |
| 先把θu512压成POINT0，会把圆周另一侧错到sector0 | 保存未wrap θu10及原半平面，完整相加后mod1024。dx=-10000/dy=16→full512/sector32；反向dx=10000/dy=-16→raw1024/full0/sector0。 |
| Q30法线不是精确单位向量，直接以M作真实norm可能错inlier | f50/K65，K≥2^58；M=最近整数根，q0误差至多1，以4f²与奇数平方×K边界修正并复核ties-even。最近边用fi²Kj与fj²Ki比较；109/165bit比较在192bit域内。 |
| 已valid FORMAT取消时普通assembler可能停止接收 | body/key保持，旧ctx有独立本地消费后DISCARD资格，不等常规asm_ready、不发新MC；未消费FORMAT不借作物理W源，既有copy/pending及物理承诺仍实际关闭。 |
| 23个部分积列不等于完整乘积23word | 384bit输出24个16bit word，末carry检查后写第24word；混合加减先193再194bit，乘积385bit守卫。 |

上述为数学与合同审查结论，不是仿真测试通过。整数Q30 ROM是拟议逐位参考，未生成常数表；未把有限精度分类宣称为无限精度β的逐点等价。

23项静态字段/容器算术相等：POINT64、CIRC256、RECT512、FINAL三段96/192/224、PROFILE完整1024、NUM_REQ543、NUM_RESP540及列明FF/ROM等。53bit SSE最大8,905,772,396,160,000，小于2^53；前提是每遍支撑唯一且每inlier残差≤65535。7要求、8接口、7局部步骤、9不变量、16文字场景、6阻塞项、A—L与7追踪行均有内容；编号/宽度齐全不代替语义审查。

四边范数缓存4×(65+33)=392bit，已列数值FF容器小计**6191bit**。DATA旧预算178加两ROM为**180/256 RAM10（70.3125%）**。这些只是指定容器预算，未含全机FF/DSP、完整注册/所有权、字形及未定hist；没有综合利用率或100MHz时序结论。

## 3. 本地官方资料补充

[接口/复位/时钟来源证据](../01_baseline/vendor-interface-contract-evidence-v1.md)最终SHA：

`EF5E8909CB07A94929F08FAC0063AFCAA250CA8271006A27F5725B9BF02D0FD8`

root实际读八个本地HTML主体、复核十个源文件哈希；两PDF的指定页由子Agent读，root只复核文件身份/哈希。独立审查者全文读回此证据，未发现事实或端点混淆。证据明确25µs启动复位建议、LOCKED异步/窄脉冲、Titanium LVDS相关PLL/相位关系；CSI外部关闭、DDR B可见性/旧reset义务及10bit serializer关闭仍未由这些手册证明。

[用户指出VF与Demo目录的证据](../01_baseline/vf-demo-supplemental-evidence-v1.md)保留：DDR控制器/PHY/校准/模型已找到，具体未找到与V4 2Gb器件匹配的完整参数组合；SC431HAI来源在V4包。Demo tinyml参数虽为BANK3/ROW14/COL10/DQ16的2Gb地址几何，另有DRAM_WIDTH=8；不能据总DQ16宣称已完整匹配V4单x16器件。root实际重新读此参数全文，独立资料核查同样确认。原始资料只读，无解压落盘、网络、下载或构建。

## 4. 尚未闭合的目标与下一步

RN-B01种子/多圆/图外域完整覆盖；RN-B02支撑分段/三边/整短边缺失/U形辨识；RN-B03生产PROFILE实值、半径hist、稳健/颜色路线；RN-B04支撑去重与完整质量语义；RN-B05栅格、笔宽、字形；RN-B06全机资源/最坏服务及外部器件合同继续存在。数值稿并不达到READY_FOR_REVIEW。

RN-T01…16全部**NOT_RUN**；源码、常数生成器、参考程序、可执行测试与testbench均未生成。真实2Gb/PHY仿真、综合、引脚生成、布局布线、STA及bit/hex均NOT_RUN。每类精确率/召回率≥95%与同类IoU≥0.5的一对一独立评估目标保持，未恢复此前撤销的尺寸/数量/遮挡硬限。

允许下一步为闭合上述设计问题、相邻合同吸收与指定版本评审；已有FRONTEND及DDR模型获取审批仍PENDING，不重复创建。正式状态、Manifest、数据库与原始资料未改。整机十一功能软件目标仍未完成，目标保持ACTIVE；本轮分类PROGRESS，依据是新增明确数值合同、实际反例修正、本地来源证据和最终读回，而不是文件数量。
