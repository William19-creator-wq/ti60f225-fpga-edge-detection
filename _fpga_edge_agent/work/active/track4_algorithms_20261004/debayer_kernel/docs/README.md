# RAW10四相位双像素转色核：实际代码入口

2026-10-08，RAW10-DEBAYER v1；四份文件已生成，debayer_kernel_004编译/仿真/独立审核通过。它接两个3×3 RAW10窗口，不是裸RAW pair直接输入；行RAM/reflect101窗口与真实相机接收仍待整合。

顺序：[整体/接口/中文操作草图](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-RAW10-DEBAYER-KERNEL-001.md) → rtl/raw10_debayer_pair.sv（切窗口/判断颜色/扩宽求和/单次量化/输出槽）→ model/debayer_reference.py（显式四色表/邻居和整数divmod）→ tb/tb_debayer_pair.sv（真实事件账/停顿/复位）→ scripts/run_debayer_sim.ps1。

phase0RGGB/1GRBG/2GBRG/3BGGR，原图奇偶决定center颜色。RAW和保留13bit，RGB=min(255,floor((S+2d)/(4d)))，d1/2/4只常数移位；不先截RAW或先平均。RGB48低lane={R0,G0,B0}，高lane={R1,G1,B1}，coords/markers/job_id同沿注册。输出槽满且下游停顿，全部内容保持；同时交付与替换读旧输出。

实际25,152个双像素窗口：四phase/行奇偶/所有0…1023常量、九点脉冲/边界和16,384随机；25,102交付、50共同reset作废，accepted=delivered+reset_aborted逐笔闭合。包含50个held输出复位恢复，RGB/坐标/标志/64bit ID逐项正确，真fatal退出非零。物理资源/时序未执行，真实传感器Bayer相位未由这些合成数据证明。

早期尝试保留：_001/_002为新runner复用时路径不符；_003为数值字面量后紧接问号的词法编译错误，_004已修复并完整通过，未删除失败记录。

Questa先看in_valid/ready和phase/window/x/y，然后out_valid/ready/rgb/markers/job_id；比较要按真实握手，不把气泡作为0像素。正常软件重跑选新RunId。改变phase/补边/量化须先改对应草图再验证。

DK01/02→颜色及quantize→T01；DK03→elastic slot/sideband→T02；DK04→valid reset及事件R→T03。T04实际行窗口、生产CSI/CDC/DDR写入、综合布线和整机组合仍NOT_RUN。理解验收待反馈。