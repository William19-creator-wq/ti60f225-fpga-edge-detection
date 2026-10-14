# 源帧自动管理与实际采集

先读 [整体、接口及逐状态中文草图](control/design-v1.md)，再读 [管理器](rtl/frame_capture_manager.sv) 的事实寄存器、owner命令和 `capture_control`；最后读 [组合模块](rtl/frame_capture_owned_axi.sv) 的真实RAW/owner/写服务连接。

一次完整正常处理：

```
接收帧请求，锁定scope96和Bayer2
        ↓
真实ALLOC_SOURCE回执 → Source handle、Origin、slot
        ↓
实际RAW采集模块接受job → 向接收方交付grant
        ↓
RAW真实fire → CFA/RGB → 实际AW/W/B写入Source
        ↓
最后RAW的EOF fire → 自动SOURCE_EOF
        ↓
等待真实capture DONE与接收方RX no-future close
        ↓
自动SOURCE_END7/OK → 安全frame DONE
```

错误或取消时，管理器等待实际producer闭合和RX不再输入的证明，再以END6登记无效帧；UNKNOWN以END0隔离，不给安全DONE。配置在frame fire一次采样，之后改变输入不改本帧。grant交付前不接受RAW/RXclose，避免借用身份尚未交付就释放。

阅读验证代码时按 [实际TB](tb/tb_capture_owned.sv) → [数学AXI内存](tb/axi128_capture_owned_memory.sv) → [独立参考](model/capture_owned_reference.py) → `runs/*/source-manifest.json`、`suite-result.json`、`independent-audit.json`。

当前34×20、4×2、完整1920×1080三次仿真及独立审计均通过，合计23个实际完整帧、2081168比较像素。小尺寸另有接收错误、取消、重复身份拒绝、BRESP/UNKNOWN、缺失完成和4类明确的manager端口模型场景。端口模型用于反压/计数防御，不称为相机或像素验证。

当前组合Efinity MAP：6597 LUT、4280 FF、235 ADD、8 RAM10、0 DSP。详见 [完成核对](completion-review.md) 与 [实际资源记录](resource-result.json)。它只包含本采集管理用途的owner连接；正式父顶层须复用manager、采集执行模块与一个共享owner，并接结果/显示管理。资源不能简单当作全owner和整机预算。

运行脚本为 `scripts/run_capture_sim.ps1`、`scripts/run_capture_map.ps1`。RXclose是外部端点测试输入，真实CSI CRC/PHY尚未由此验证；DDR数学内存也不替代物理DDR模型。整体目标继续，剩余发布、冻结重算、回收、复杂识别及板级PNR/STA/bit需后续完成。
