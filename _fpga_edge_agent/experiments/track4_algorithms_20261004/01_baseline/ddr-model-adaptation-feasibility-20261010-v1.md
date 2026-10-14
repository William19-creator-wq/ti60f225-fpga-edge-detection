# DDR3 2Gb/x16项目适配模型可行性补查 v1

2026-10-10，纯只读事实与后续设计入口，不是已生成模型或动态验证通过。软件自主授权继续，不重新提出批准问题；原HDK/安装只读，本次没有下载模型、提交注册资料或调用硬件。

## 已读的本地源码事实

本机 `C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/ipm/ip/efx_ddr3_soft_controller/testbench/ddr3.v` 为Micron bus functional v1.74，SHA `AF83D644D4471A88E9D732AED012BF486FEE75BE79031660452F576FD56F20EA`。97行定义默认den4096Mb、98行默认x16；120–127行依次选择1024/2048/4096/8192对应参数头。这里是存在2Gb分支但缺头，不是模型主体在算法上只能表示4Gb。模型主体后续容量/地址主要从BA_BITS/ROW_BITS/COL_BITS/DQ_BITS参数计算，不能仅靠文件默认宏判定内部全部容量。

本机4096头SHA `39BD3B893D9BEB65EA181DFE53A83ACC6291749A05FB46BBDF77C3ACD155A349`；8192头SHA `96DDE2B377F65527DF67A7E77EC7009A4682064F9103FFB15F1E5D4E0F46D187`。所读4096头x16为ADDR15/ROW15/COL10/DQ16/DQS2/DM2/BANK3；TRFC_MIN260000ps、TXPR/TXS270000ps，均带4Gb注释。2Gb控制器ROW14不能用地址访问半区替代模型密度匹配。

4096与8192参数头并非只差ROW：还存在速度分支集合、TRC和其它几何差异。因此未来适配必须把选定x16/速度profile有效的每个参数展开核对，不能只改3个数字后把其它参数称已匹配。MEM_BITS16是模型稀疏写突发记录容量，不是器件密度；模型自身注明不检查平均刷新周期，未来独立监视器仍应核刷新策略。型号/密度通过也不等于PHY已验证。

## 官网补查与权限范围

沿用户“你是否可以通过官网找”的既有授权再次只读查询Micron官方公开入口。[MT41J128M16JT-125:K官方目录](https://my.micron.com/products/memory/dram-components/ddr3-sdram/part-catalog/part-detail/mt41j128m16jt-125-k)的搜索索引仍列2Gb/x16/1.5V和Verilog1.74，但该页实际读取未返回可下载模型；数据手册和模型目录显示Get Access。原常见官方PDF路径一个不可访问、一个404；本轮未取得完整2Gb数据手册或2048参数头。没有使用搜索偶然返回的第三方仓库/镜像来伪称官方已取得，没有提交账户资料或接受协议。

## 可继续的工程路线

缺少厂商原始2048头不必成为所有软件工作的停点。可以另建“项目适配2Gb/x16模型”，保持既有Micron模型主体和版权说明，明确标为项目派生输入，不能冒称厂商原文件。生成前必须有完整选定profile参数的来源及中文草图：几何、速度和CL/CWL、ps/tCK单位、refresh/exit reset/self-refresh、DQS/DM/DQ及输入/输出时序、模型功能限制/未涵盖项、实际include和define选择；逐参数表无关键空项才实现，不以猜值解除缺口。

未来验证应分开模型自检、真实控制器初始化/校准、真正DQ/DQS读写和AXI独立字节账；边界跨bank/row、掩码、刷新、背压/取消/复位以及保留未决责任都须实际运行。不能force cal_done、绑理想RAM或禁用strict timing来制造通过。所有适配只在独立work，失败保存；正式PG/H0和硬件状态不改。当前未形成READY设计、未生成模型/头/TB/动态适配器，真实DDR动态仍未验证。

本轮其它正在完成的资源实验、摄像头接收CRC/尾部归属、生产帧控制与复杂识别可以继续；它们的组件软件证据不会自动升级成DDR或整机通过。
