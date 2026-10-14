# TRACK4-LINE-POINT-MATH-001 v1：粗线/细线逐点精确数值回调

2026-10-11，READY_FOR_PARENT_REVIEW / NOT_IMPLEMENTED。仅首 RP 单文件设计，完整矩形后端仍未READY。按 PLAN_TEMPLATE 合并短卡；用户持续自主推进、本地审计、免长草图/独立测试授权沿父任务，不冒称本版用户已批准。父保存读回/呈现并限定实施前不生成源码；本轮不改main/058/原资料，不做TB、仿真、EDA或硬件操作。

## A/B/C. 范围、来源和整体行为

- Goal / Current / Gap：现有完整scalar op0…7可复用；尚无矩形 COARSE offset与TLS_POINT数值回调。首块只把一个合法POINT和一条粗/细线变成完整offset、切向、精确RNE残差与gradient相容性；不筛run、不选矩形、不做DDR/ANGLE/STATS。
- Target / planned file：新独立 `work/active/track4_board_first_20261011/candidates/line_point_math_v1/board/rtl/board_line_point_math.sv`，仅这一文件；before来源与依赖登记由父限定后执行。没有业务基线源码，不能伪造修改前commit。
- Assumptions：WIDTH默认1920，HEIGHT默认1080；core同一正沿、共同同步高rst、单预约、父取得唯一scalar实际owner且前任及私有bridge真的quiet。输入来自当前POINT V2和实际粗/细线域，不裁场景、不加入96–768、长宽比等限制。
- Boundary：本卡细化[矩形卡E1](design-TRACK4-RECTANGLE-REFINE-001.md)，父已全文读回其SHA `25242C5722176970259AF3E87FA9069590576E1BE1C792E4845AA0DBB8521EC9`。LINE min16/原默认3、censor、CELL/EXT、TLS六遍、PAIR、RG/RV/RECT/ANN及整机资源都不属于首块，不以整包未READY阻止这个独立已定义数学回调，也不顺手生成这些后端。
- Actual sources：scalar_protocol_pkg SHA `40D7FC511C4E481B0B194A2B31D53C18627EC7D420A5B54E17C438E5832D3028`；当前scalar_core_words `6266734BEDD5CD1439355CC2153AE4B3FB0630079CADF9097433D9A0F89E4037`；原PM `83172157F710AB694F11782E73E0C75914B0B906415F9B8B507E120A3579CB21`；实际fit_core `875083D9835283FCABA45372A08BE2CF2B8056AA99F310F24DA15135565242F6`。均已读回相关接口、资格/数值路径；NUMERIC E5仍以SHA `17C4A290414970260BBADC7B5286F6C6F5608E3B03E0FF38E08E3E5E1491F39A`为数学来源。
- Modules / Flow：只有MOD-RP。`接受command → CHECK → typed槽/NUM微步 →完整385资格→真实close → MODE结果→normal精确门→held response→真实quiet`。单同步16bitRAM、两128bitoperand；没有第二NUM或385/512 FF返回快照。

LP-REQ01 COARSE精确nearest半像素offset及完整s21输出；LP-REQ02 TLS精确RNE残差/至多一次纠正及复核；LP-REQ03 两模式切向与完整gradient门；LP-REQ04 192/385全资格、单预约/ID/真实关闭、默认兼容与借用生命周期。

## D. 精确接口与默认参数

参数：WIDTH=1920、HEIGHT=1080、`SHARED_RETURN_WORDS=0`、`BORROW_COMMAND=0`。默认SHARED=0只用原全RSP正文选择；开1使用父16bit返回侧带，算术和资格相同。默认BORROW=0于command真fire快照下列全部340bit（ID176+mode2+point64+nx32+ny32+rho18+tol16）；开1直接借稳定正文，不按command_valid撤销或置零。两generate分支建立同一个held视图，结果echo只能引用该held视图，不能混用原输入。

| IF01 command / response | 定义 |
|---|---|
| command_valid/ready，command_id176 | ID低96为scope，owner字节[103:96]必须0，完整ID回显；高72是父身份，保持原样。 |
| command_mode2 | 0 COARSE、1 TLS_POINT，2/3已知FORMAT错误。 |
| command_point64 | gx s11/gy s11/dir2/zero8/x11/y11/theta9/zero1，与原PM域一致；x<W/y<H、G在±1020、absGx+absGy≤1530、G非零。RP不检查rowmajor/ordinal，这是父扫描器职责。 |
| command_nx/ny s32 | 粗模式必须是s17系数的完整sign-extension，且各在±32768，来源ANGLE16的C/S Q15；细模式各在±2^30，来源FIT12 Q30。不得先裁成合法范围。 |
| command_rho s18 | 粗为R0 Q4，细为rho Q4，整个二补码s18域；不限制画面内。 |
| command_tolerance u16 | 0…65535的normal_sin门，锁定算法配置，不在RP替换默认阈值。 |
| response_valid/ready，response_id176/mode2 | 单held回应，ID/mode及全部值在背压期间不变；没有未接受command的回执。 |
| offset s21 / offset_valid / offset_index6 | COARSE完整δ；只有−24≤δ≤24才valid，index=δ+24∈0…48。域外合法数学结果保完整offset，valid0/index0，不是错误/截断。TLS这三字段为0。 |
| tangent s18 / distance u21 / normal_ok | 两模式tQ4；distance仅TLS精确q，COARSE distance0；normal是真实完整cross门，等号通过。 |
| error/drained、quiet、sticky fault | 合法结果error0；已知故障真实关闭后error1/drained1，所有数值0；UNKNOWN error1/drained0并隔离。没有本地候选LOCAL_REJECT，normal0/offset_invalid是合法结果。 |

默认snapshot调用者可在接受后撤销原command，但物理owner仍保持到RP真实quiet。BORROW=1父保持全部command字段至response消费且RP quiet；UNKNOWN保持到共同冷复位。无本地暖cancel/timeout口；父stop只能停新请求并等已接受回调关闭，共同rst由RP/父/scalar同时执行。

IF02 NUM沿原REQ622/RSP585/ID176。op0 MUL、1 ADD、2 SUB、3 DIV_RNE、4 SQRT_RNE、5 COMPARE、6 DIV_FLOOR、7 SQRT_FLOOR。普通op请求target192，op4 target97，op7 target96，op5 target2；根的B全192位0，其余padding16全0。A/B从完整128bitcanonical槽按AS/BS sign/zero extend到192，禁止先截typed低字段。每个微步的AS/BS由表中s/u决定；比较返回只允许0等/1小/2大，3为INTERNAL。

NUM_ID=`{8'hC4,closed_sequence64,8'd0,held_command_id[95:0]}`。父已核当前实际C1/C2/C3/D1，C4不冲突；D2/C5/C6只是未实施规划，仍在集成前核全源。N从真实请求接受保持到真实回复消费后的childquiet，不在command/job重置、不另存pending N。req正文、opcode/target、operand及MODE微步均保持至该close沿，支持当前BORROW_HEADER/PAYLOAD。RP quiet仅本地IDLE&&childquiet，不由exhausted的ready0代替。

## E. 槽宽、微步与数学

记C=COARSE、T=TLS，n=(a,b)、g=(gx,gy)、X2=2x−(W−1)、Y2=2y−(H−1)。X2/Y2先s13形成，验证实际s12域后仍完整扩展到128供运算。scale C=32768、T=1073741824。表内每行都是真实scalar调用，目的值按所列s/u位宽核完385位后8×16写入；不在未close时推进下一行。局部固定输入/0/1/2/4/8/16/64、scale、65535²=4294836225均是typed常量，不生成额外程序/常量文件。

| 槽 | 当期类型与生命周期 |
|---|---|
| S0 | K=C u33/T u65；K建立后保持到最后normal比较，唯一持久数学槽。 |
| S1 | f=C s34/T s50；保持到distance完成及粗模式sign恢复；之后不用。 |
| S2 | f²=C u68/T u100，复核结束后可改cross²=C u58/T u88。 |
| S3 | C的D=64K u39，或T的M=RNEsqrtK u33；保持至本mode全部残差复核。 |
| S4 | C的floor商u68→k u21→q u21→offset s21；T的q0/q u21；distance输出私有保存后复用tangent s18。 |
| S5/S6/S7/S8 | odd u22/odd²u44/threshold C u83或T u109/compare u2；每次半点检查都重建S5，不读上轮odd。 |
| S9 | 4f²=C u70/T u102，残差复核后改normal左式=C u90/T u120。 |
| S10/S11 | normal平方 C u34/T u64；坐标乘 C s28/T s43；absf T u50；切向乘 C s30/T s45；gradient乘 C s28/T s43；最后G²u22。按当前PC准确解释，旧值不用。 |
| S12 | 坐标和 C s29/T s44；切向差 C s31/T s46；gradient cross C s29/T s44；最后G²和u23。 |
| S13 | 坐标和×16 C s33/T s48；切向×8 C s34/T s49；最后tol²u32。 |
| S14 | rho×scale C s33/T s48；最后tol²G² u55→normal右式C u88/T u120。 |
| S15 | 未使用，禁止读取；保留16slot固定RAM地址形式。 |

同槽重写不需要额外wide类型寄存器：mode/PC决定源/目的typed域，valid16每command清0，只有完整8word写完才置有效。所有分支明确先写后读，新command不依旧RAM；没有RAM正文全复位。S4对外小值暂存约68bit只在资格且close后更新，公开response在全部微步结束才有效。

### E1. 共同K/f：11次调用

| 步 | op、A/B及AS/BS | 目的/资格及后继 |
|---|---|---|
| K1 | MUL a(s32/粗canonical17),a(s) | S10 C u34/T u64 |
| K2 | MUL b(s),b(s) | S11 C u34/T u64 |
| K3 | ADD S10(u),S11(u) | S0 C u33/T u65 |
| K4 | COMPARE S0(u),Kmin(u) | S8 u2；Kmin C=2^28/T=2^58，cmp1为坏normal INTERNAL，0/2继续。 |
| F1 | MUL a(s),x(u11) | S10 C s28/T s43 |
| F2 | MUL b(s),y(u11) | S11 C s28/T s43 |
| F3 | ADD S10(s),S11(s) | S12 C s29/T s44 |
| F4 | MUL S12(s),16(u) | S13 C s33/T s48 |
| F5 | MUL rho(s18),scale(u) | S14 C s33/T s48，是真实常量移位的等价乘法，非窄化。 |
| F6 | SUB S13(s),S14(s) | S1 C s34/T s50 |
| F7 | MUL S1(s),S1(s) | S2 C u68/T u100 |

源先CHECK：非法尺寸/POINT/owner/mode为FORMAT/COORD；系数非canonical/range或K不足为INTERNAL，不能把坏normal当合法distance0。粗合法域 `|f|≤32768·[16(W−1+H−1)+131072]<2^33`、D≥2^34，因此floor-root k<2^16；δ完整s21足够。细f守s50、M≥2^29，q0<2^20，完整u21足够，不缩到支持阈值位宽。

### E2. COARSE精确δ：floor根 + 半整数tie-even

| 步 | 调用 | 目的/资格 |
|---|---|---|
| C1 | MUL K(u),64(u) | S3 u39=D |
| C2 | DIV_FLOOR S2(u),S3(u) | S4 u68，分母非0由K守卫建立。 |
| C3 | SQRT_FLOOR S4(u),0(u192) | S4 u21=k。floor(sqrt(floor(f²/D)))=floor(|f|/sqrtD)，不替近似。 |
| C4 | MUL S2(u),4(u) | S9 u70=4f² |
| C5/C6 | MUL S4(u),2(u)；ADD所得S5(u),1(u) | S5 u22=2k+1 |
| C7/C8/C9 | MUL S5,S5；MUL所得S6,S3；COMPARE S9,S7 | S6 u44；S7 u83；S8 u2 |
| C10 | ADD k(u),inc(u1) | S4 u21=q；inc=cmp2或(cmp0且k奇)。此加法即使inc0也是真实调用。 |

随后执行E4的lower/upper完整资格（D=S3），再 `MUL q(u),sign_f(s)` → S4 s21，其中sign_f=−1仅f<0，否则+1；f=0选择+1也给δ0。再两次COMPARE δ(s21),−24(s) 与δ(s21),+24(s)，接受域为lower cmp≠1且upper cmp≠2；合法域之外保完整δ而index0，合法时由扩展s22的δ+24检查0…48后收6。没有priority/clamp/wrap或域外提前跳normal。

### E3. TLS精确q：q0、至多±1纠正

| 步 | 调用 | 目的/资格 |
|---|---|---|
| T1 | SQRT_RNE K(u),0(u192) | S3 u33=M；真实RNE根，不以lookup或近似替换。 |
| T2 | MUL f(s50),sign_f(s) | S10 u50=absf；sign与C相同。 |
| T3 | DIV_RNE S10(u),S3(u) | S4 u21=q0，完整RNE；M非0。 |
| T4 | MUL S2(u),4(u) | S9 u102=4f² |
| T5a | q0>0才按E4 lower五步构造/比较，但此处用于纠正 | 4f²<lower，或相等且q0奇，标adjust=−1并跳T5b；q0=0跳lower。 |
| T5b | 未标−1时按E4 upper五步构造/比较 | 4f²>upper，或相等且q0奇，标adjust=+1，否则0。 |
| T6 | adjust=−1用SUB q0(u),1(u)；其它用ADD q0(u),inc(u1) | S4 u21=q，inc只为0/1；q0>0才可减。选择决定于已close比较，request期间不改变。 |

依据原NUMERIC守卫，sqrtK及M≥2^29且根误差≤0.5，未舍入距离差≤2^-10 Q4，因此q0与精确RNE q至多差1；这只是限定纠正次数的证明，不能免掉后续完整检查。一次纠正后执行E4两边复核（D=K），不无界迭代，不直接采用q0。通过后distance=q u21；不先收16bit。若复核不满足为INTERNAL/error，不返回近似成功。

### E4. 公共半点构造与最终复核（每侧五调用）

q始终当前S4无符号21，F4保持S9，D在C为S3、T为S0。每次调用从q重算odd，不借旧S5。

| 子步 | lower（仅q>0） | upper（总执行） | 类型 |
|---|---|---|---|
| B1 | MUL q,2 | MUL q,2 | S5 u22 |
| B2 | SUB S5,1 | ADD S5,1 | S5 u22；lower q0时完全跳过。 |
| B3 | MUL S5,S5 | 同左 | S6 u44 |
| B4 | MUL S6,D | 同左 | S7 C u83/T u109 |
| B5 | COMPARE F4,S7 | 同左 | S8 u2 |

最终lower通过 iff F4>lower或(F4=lower且q偶)；upper通过 iff F4<upper或(F4=upper且q偶)。q0 lower自然通过，upper照常检查；任何cmp3/高位/半点不合格为已知INTERNAL。粗路径的round与細路径的±1纠正都按这一同一nearest-even规则证明最终值，没有不同tie政策。

### E5. 切向：五调用，结束后再做normal

1. MUL b(s),X2(s13)→S10 C s30/T s45。
2. MUL a(s),Y2(s13)→S11 C s30/T s45。
3. SUB S10(s),S11(s)→S12 C s31/T s46。
4. MUL S12(s),8(u)→S13 C s34/T s49。
5. DIV_RNE S13(s),scale(u)→S4 s18。

这五步均为真实scalar调用，不额外实现宽local shift路径。RNE切向不以distance或coarse theta重建；保存tangent后S4不再读。

### E6. normal：12调用，完整交叉乘

| 顺序 | 调用 | 目的资格 |
|---|---|---|
| N1/N2/N3 | MUL a(s),gy(s)；MUL b(s),gx(s)；SUB前者(s),后者(s) | S10/S11 C s28/T s43；S12 cross C s29/T s44 |
| N4/N5 | MUL cross(s),cross(s)；MUL所得(u),4294836225(u32) | S2 C u58/T u88；S9 left C u90/T u120 |
| N6/N7/N8 | MUL gx(s),gx(s)；MUL gy(s),gy(s)；ADD两平方(u) | S10 u22/S11 u22/S12 G²u23 |
| N9/N10/N11 | MUL tol(u16),tol(u16)；MUL所得(u),G²(u)；MUL所得(u),K(u) | S13 u32/S14 u55/S14 right C u88/T u120 |
| N12 | COMPARE left(u),right(u) | S8 u2；normal_ok=(cmp≠2)，等号通过。 |

normal数学为cross²·65535²≤tol²·K·G²，使用真正norm K，不假定Q15/Q30范数恰单位长；gradient非零已CHECK。tol0/cross0为合法等号；不换dot/cos门。COARSE即使offset不属于49bin仍计算真实normal与tangent，父可用offset_valid做成员政策。

## F. 逐沿、错误、MAX与结构预算

每个scalar微步：PLAN核需要的slot_valid并固定op/AS/BS/destination/stored_bits → A/B各8次READ/CAPTURE同步字加载，低到高shift组装完整128 → 全192REQ held → NUM_WAIT核完整ID、kind、target、outcome/reason → NUM_SCAN index0…24 → 全部通过才REG_WRITE word0…7 → word7建立slot_valid → NUM_CONSUME实际fire → NUM_CLOSE等childquiet → N递增/锁耗尽 → 下微步。opcode、body、operand和所借command在CONSUME后仍保到真实CLOSE，不能ready一下就覆写。

每目的完整385资格：unsigned要求所有bit≥stored_bits零；signed要求从stored_bits−1起全部与value384相同。25word补到400bit，index24只取真value384作低bit，高15按目的extension补；扫描包含最终片段而不是只看之前scan_bad。只有资格完成才允许完整8word slot保存；完整低128本身已经canonical，不截typed低位。COMPARE还核结果0/1/2。SHARED=1的NUM_SCAN/REG_WRITE游标同原PM，默认0局部选择；父侧带不得按valid/quiet抹held返回。所有步骤目的资格都在表中，没有“先收位再核”的例外。

输入格式/POINT坏、normal坏、资格/计数溢出、比较非法、半点复核坏：error1/sticky fault，清所有小输出；没有child接受时等待真实childquiet才drained1；本ID已接受请求则消费其合法或畸形的本ID回复并等quiet，停止余步后发布已知错误。原FRAME_FAIL正文必须全385零、reason属于FORMAT/COORD/OVERFLOW/DIV_ZERO/UNSUPPORTED/INTERNAL；未声明cancel出现CANCEL_DROP或其它矩阵不当成功。坏kind/target或本ID错误仍known-close；异ID不消费、不取消别人的预约，UNKNOWN回应drained0，回应消费后ISOLATED，quiet0至共同rst。永久不valid/不quiet就真实保持未完成，无时间推断drained。

MAX N可接受一次。其回复消费后的真实close设exhausted/sticky fault；若恰N12最后步，当前已接受command可成功交付（drained1/error0），后续ready0；若还需下一调用，在没有发新NUM的情况下当前command已知耗尽错误/drained1，不回绕、不伪造新请求回执。已有错误优先保error，MAX关闭不能改回成功。序号仅共同冷rst清0；fault作为sticky诊断，不因新command清除；known error关闭后若未耗尽可接受下一generic command，父可选择停整帧。所有数值/response在背压期间保持，response消费后才IDLE。

精确调用上界：C最多51（K/f11+C10+复核10+sign/domain3+tangent5+normal12）；T最多53（K/f11+T1…4共4+纠正lower/upper最多10+调整1+复核10+tangent5+normal12）。q0或q为0时可少lower五步。每调用包括真数值处理、25字资格、8字保存/关闭，51/53不是core沿/FPS。无早跳normal或粗域外删结果来减步骤。

资源仅估计：16×128/128×16同步工作RAM 1个RAM10；两operand256FF、sequence64、slot_valid16、小结果约70、control/游标/比较flags约500–700FF；BORROW=1约1kFF，默认snapshot再340FF。0新增DSP、0新NUM/ANGLE/STATS、0新ROM/DDR、无新CDC/引脚/SDC。实际LUT/FF/RAM/时序需后续父整机实测，不能凭此卡宣称装下或实时。RAM每次command清valid而不清正文，合法slot发布均完整8字后；同址读写不依赖READ_FIRST，READ/CAPTURE与REG_WRITE阶段排他。

## G/H/I/J/K/L. 走查、追踪和停止点

计划（全NOT_RUN，无TB/EDA）：粗f=0→δ0/index24；正/负半offset tie偶镜像；δ±24与±25保完整s21；q=0 lower跳而upper仍核；TLS q0偏±1纠正后再核两界、两个半点奇偶；tol0 cross0/非0；水平/垂直/斜线/最大rho与图外线；目的128以上非法高位、index24符号、COMPARE3；默认snapshot与borrow1保持；MAX恰最后/中间；OWN malformed与foreign ID隔离、request/response背压、共同rst。输入不测试LINE16/3、R0形成、六遍成员或矩形质量，这是其它模块职责。

正向追踪：LP01→E1/E2/E4/offset21→RP COARSE微步；LP02→E1/E3/E4→RP TLS微步；LP03→E5/E6→RP切向/normal；LP04→IF01/02/F→RP借用/资格/close。反向每一个slot和微步都有上述数值依赖，未添加拟合/成员/DDR操作。标准模板十项在此独立范围已有整体、职责、真实来源、完整接口、局部步骤/typed、RTL时间/复位/存储、场景、追踪、明确单文件及无局部数学TBD；实际保存读回/父呈现仍需本轮记录，整包不在READY范围。C++/独立参考本轮N/A，无跨语言证明冒称。

当前允许下一行动：父读回本v1精确表与51/53上界、确认单文件candidate授权；此前不实施。若修改模式/数学/类型/握手/MAX/参数/存储，先修此卡，不凭旧矩形卡扩大。回退只撤新candidate，原资料与当前工程不变；首次SOURCE生成/静态证据/哈希及实际集成由父登记。当前实际成果仅本设计保存/读回，源码、仿真、综合、PNR、STA、bit、硬件均未执行，用户理解验收待实际反馈。
