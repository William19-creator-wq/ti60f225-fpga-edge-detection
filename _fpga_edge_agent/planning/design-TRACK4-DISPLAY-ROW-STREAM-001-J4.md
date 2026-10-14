# 行消费验证 v1.4：单字节可见标志的明确表示

- Current state / Goal：`_003` 两次真实仿真exit0，独立参考拒绝native记录：第1行release记录shown=P，二进制14字节记录的visible字节却全0（完整54bit/地址已匹配）。不能忽略此矛盾或把0当正确图像。
- Scope / 中文草图：TB写native记录时把1bit pixel_valid显式扩成8bit再送%c，使14字节定义的第二字节确实为uint8的0/1；协议、数据、时序、计数、输出/独立判定不变。参考报错附frame/bank/row及实际counts，便于继续定位；若仍不一致继续调查，不放宽。
- Dependencies / State / Steps：baseline-v1.4在23项加本卡为24项；保存读回呈现READY后，按持续自主软件/本地审计授权改这一记录表达和runner基线；新的 `_004` 完整小/最小运行再严格独立比较。原 `_001..003` 源/原日志/二进制均保留，无生产RTL或冻结依赖变更。
- Validation / Trace / Gates：STV1/RS03真实pop与pixel标志→TB native序列化14字节→Python bool字节与release shown/真正像素位置逐项比较，及全RGB/控制。当前前置其余内容沿v1/J1–J3，不存在新的生产边界；无网络/安装/硬件/正式DB操作，不等待逐版用户批准。
