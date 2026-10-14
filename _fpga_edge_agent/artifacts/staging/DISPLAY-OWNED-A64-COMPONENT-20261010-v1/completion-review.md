# 显示整合进度核对

本批新增/明确适配11份业务与验证文件，冻结34份输入，复用22份运行依赖。实际模拟源30份，MAP输入33份，工程内22份生产RTL/package；RAM10厂商模型仅用于模拟，不放入综合文件清单。

当前已终止的两次运行：

|运行|几何|完整帧/前缀帧|显示时隙|比较active区域像素|native pops|实际lookup|旧closed/RETIRE|
|---|---|---|---:|---:|---:|---:|---:|
|owned_scan_small_001|34×20|17/18|177334|12240|5804|353|7/7|
|owned_scan_min_001|4×2|17/18|114367|144|84|47|7/7|
|owned_scan_hd_001|1920×1080|17/18|22231390|37324800|17625624|18373|7/7|

表格来自两次实际scan-metrics.json/reference-result.json。上述像素数包含测试启动阶段的空白active时隙；审计逐时隙区分未启用帧的黑色/错误标志与有真实active bundle的数值，不能把每个时隙叫作实际算法生产像素。

两次vlib/vlog/vopt/scan_vsim/audit均exit0，fatal探针exit1且包含预期标记；每次相邻帧无reset，全部六mode、一次missed VS、两次取消、20周期oldclosed holding及真实冻结/恢复均通过独立对象/数字审计。真实owner OFFER绑定sequence，query按完整demand验证；没有TB影子lookup权限。所有输入与snapshot末尾hash均检查。

`owned_scan_hd_001`：scan_vsim实际在2026-10-10T15:33:45Z退出0，独立audit在15:41:09Z退出0，suite/reference均PASS；fatal探针exit1且有预期标记。仍是同一次运行，无重启。独立审计覆盖17完整帧及明确第18帧前缀，22231390时隙和37324800个active像素比较；实际18帧日志不能被说成18完整帧。六mode、missed VS、两种取消、冻结/恢复、7次oldclosed/RETIRE全部通过。

`owned_scan_map_001`：实际Efinity退出0，网表原语计数与rpt相同：47017 LUT4、25707 FF、773 ADD、19 RAM10、1 DSP。rpt层级估计owner12322 LUT、scan34694 LUT；估计有优化分组，最终以全网表47017为准。warn.log实际20条EFX-0200、5条EFX-0657，无零警告声明。两时钟10ns与13.468ns仅为MAP输入目标；未运行PNR/STA/Mapped动态/bit。

DA01..07：当前三种几何及实际MAP的组件证据成立。三次模拟vlib/vlog/vopt/scan_vsim/audit均exit0，fatal均exit1且有预期标记。全部模拟source30份current/snapshot、MAP33份current/snapshot、baseline34份原路径/副本已重新检查无漂移。兼容参数16保留，但本批生产端点统一64，本批不宣称另跑了A16兼容组合。Source/EDGE/ANN内存及manual生产关闭是fixture；真实owner/native/fence/renderer实际执行，不宣称真实相机/Canny/识别生产。

本批解除生产帧描述与显示校验的A16/A64不相容，并接入实际读权限；没有完成Result自动控制、相机CRC/不可暂停缓冲、整机共享存储、复杂识别或物理DDR。47k LUT的当前组合占用较多，必须在全父顶层统一资源检查后优化，不能把组件综合通过当作整机资源装得下。正式数据库/H0/Manifest及硬件状态没有改变。理解验收仍待用户实际回答。
