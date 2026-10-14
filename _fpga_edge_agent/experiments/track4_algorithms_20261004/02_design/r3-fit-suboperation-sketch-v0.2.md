# 七项拟合/距离：子运算与寄存器复用中文草图 v0.2

2026-10-06，纯设计，NOT_IMPLEMENTED/NOT_RUN；关联FIT主卡v0.3。先阅读原字节保留的[完整顺序表v0.1快照](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/02_design/r3-fit-suboperation-sketch-v0.1-snapshot.md)，SHA D818BDFD2F05FADBBD1CE1683F7D79B5F918F3CC9A8093EDCDF2E8BE0CF6FA10；本页明确替换其中的有限边搜索和K/M重复求根，其余LS/TLS/交点/法线距离数值与slot顺序沿原表。

本页不是程序或ROM执行表，不生成业务实现。变化发生在未批准的FIT草稿内，不改已交付scalar、ANGLE待批设计或其34项基线。

## 1. 有限边：等价floor路线取代19轮二分

保留原F01…11及三分支形成N78/D39的全部全宽步骤；w7N/w8D不变，D>0，w9为4N u80。原w10/11由lo/hi改为t=floor(N/D) u37、k=floor(sqrt(t)) u19，w12为最终q u19，其余临时产品w6/w13/w15不变。每沿一工作槽写、旧缓存真实消费后下一状态使用，沿原共同规则。

证明：对任意非负N/D与整数k，k²≤N/D等价k²≤floor(N/D)，所以两者平方根向下取整相同。真实Q4几何给N/D<2^37，t可收u37，k<2^19。使用已验证scalar kind6/7，不新增近似根、容器截断或额外算术IP。

| 新步 | 中文操作/私有primitive | 容器/目的与守卫 |
|---|---|---|
| F12 | 局部wide SHIFT原N×4 | u80→w9，保持至最终资格 |
| F13 | DIV_FLOOR_U N(u78),D(u39) | target37→w10 u37；非负且D正，由实际几何界确保37位，不默截商 |
| F14 | SQRT_FLOOR t(u37)，B0/flags0 | target19→w11 u19=k；原scalar已核整数floor根平方上下界 |
| F15 | 局部odd=2k+1 | 先u20→w6，不在u19内先加 |
| F16 | MUL odd(u20),odd(u20) | target40→w13 u40 |
| F17 | MUL w13(u40),D(u39) | target79→w13 u79；平方已消费才覆盖 |
| F18 | COMPARE F4(u80),w13(u79) | target2→w15，0等/1小/2大，code3内部错 |
| F19 | 局部RNE：小取k，大取k+1，等取偶数 | 加一先u20，查u19→w12；不把floor根当最终RNE |
| F20 | 最终上界2q+1：重复两MUL/COMPARE | q偶允许等、q奇严格小，失败INTERNAL |
| F21 | q>0最终下界2q−1：重复两MUL/COMPARE | q偶允许等、q奇严格大；q0不形成负odd |
| F22 | PACK原N78/D39/q19 | 136有效+249zero；不约分或换原N/D表示 |

相同后置两边资格下：旧二分最多19×3+6=63个private调用；新路线2+3+6=11个，若q0跳低界则更少。这个比较仅针对取根/舍入尾段，不是整核沿数或实测fps。DIV_FLOOR/ROOT_FLOOR自身仍有原192/96位步骤和平方核验，必须在未来仿真记录真实时间。

两个合法量化边案例：P=(0,0)，A=(0,-1)、B=(1,1)均Q4，p=(0,1)、d=(1,2)，z2/K5在内部，N1/D5，t0/k0、中点4<5→q0；将B改(1,0)，d=(1,1)、z1/K2，N1/D2，t0/k0、中点4>2→q1。它们证明不能用RNE_sqrt(floor(N/D))直接替代完整分数；本稿用floor根加精确中点，手算不是运行证据。

原19轮二分predicate保留在独立参考/等价比较计划中，RTL只选本路线；获批前不生成两个候选原型。真实最终half不可达证明仍有效，等号政策在隔离helper验证，近边界两侧与上述N1/2、N1/5主几何应实际覆盖。

## 2. K/M缓存：纯数值缓存，不缓存图像事务

K=nx²+ny²和M=RNE_sqrtK只取决于两整数Q30分量，和rho、像素x/y、W/H、frame/epoch/config、profile门无关。本核只接受numeric_version1。因此以完整nx32/ny32共64bit为key，精确匹配后复用同K65/M33，不改变结果或外部NUM_ID。

4个entry各key64/K65/M33/valid1=163bit，加循环替换index2，共654bit容器，另计到FIT资源预算，不能藏在原16槽或旧R3预算里。替换index可按mod4循环，它不是事务序号；private call_seq64仍不回绕。4是缓存数量，不是对象/边数量上限，未命中照正常完整计算。

局部规则：

1. 新kind14请求先完整CHECK格式/版本/normal分量/图内point。只有合法请求才查4个valid key；缓存命中不会绕过输入错误。
2. hit：按独立局部沿MOVE缓存K→w0、MOVE M→w1，再继续原D05点积/距离。两者在cache entry完整有效后借用；执行期间entry不被另一个父请求更新，单父事务保证。
3. miss：正常执行原D01…04的两平方/ADD/root并核K≥2^58/M资格；D04完整结果真实消费、字段守卫通过且无当前/sticky父abort时，原子写key/K/M/valid到next entry，index加一mod4。key用旧请求normal，K旧w0，M从旧bridge缓存，全是同次已发生数据。
4. kind12在原T60得出合法最终canonical normal/K/M时也可安装：key用旧w10/w11、K旧w12、M旧返回；若key已存在不重复分配。norm/rho/μ和K守卫此前均已过，安装不能用未规范的w7/w8。
5. 父取消同安装沿抑制新安装。已经有效的纯数值entry不因普通取消/换父job删除；其中没有父NUM_ID、点位置、geometry或结果目的，不能据entry valid返回旧父结果。cold reset清4个valid及替换index，不功能清数据。
6. lookup和安装都完整64bit相等，不量化key、不只比角bin、不把两normal相反视为同key。缓存错误/slot有效性及原函数结果由未来独立参考逐位核对；不宣称运行中ECC或任意位翻转容错。

命中会跳过kind14原D01…04四个private调用，仍执行完整f/精确舍入/最终资格。对一矩形四条细线的反复点检可避免重求根；实测命中率/沿数与全包资源未知，不能由654bit预算直接宣称性能通过。

## 3. 必要验证和版本影响

原LS17/诊断7 private调用计数已在v0.1修正，未执行。其余原表守卫继续审阅；本页新增未来场景：新floor法与原独立19-step/direct rational reference逐位相同，覆盖N0/D1、上述分数、最大合法几何、K1短边、最终q0/端点/内部、取消分别在两floor调用与中点/最终资格。

缓存要测：cold miss→hit、四key反复、第五key替换/重算、相反normal、不同job/W/H/rho/x/y仍正确、numeric_version非法仍拒绝、TLS规范normal安装后kind14命中、取消同安装抑制、取消后旧有效entry仍纯函数正确、joint reset使其无效、缓存和工作槽一写规则、source/probe观察到真实hit/miss数据路径。原参考每次重算K/M，不通过读取DUT缓存产生期望。

软件结果、真实child调用数、缓存命中/安装/替换、取消/复位账本分开记录；主DUT与isolated helper反例不混。新primitive均是已交付0–7接口内的6/7，仍要验证新父调度，不因原scalar PASS免去本组合检查。

这两项是未批准设计内的重要结构选择，写入FIT v0.3，保持NOT_READY/NOT_APPROVED。完整资源和形成沿、首错/状态矩阵、probe与文件/工具基线尚F-B02…04；READY之前不生成任何业务代码或功能性实验。完整目标仍1080p、全部十一项及原识别要求。
