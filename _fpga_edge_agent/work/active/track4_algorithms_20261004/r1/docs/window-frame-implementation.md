# 两行窗口与任务封装：实现读回

授权为 R1 v1.1 / ALGO-BL-v1.1；完整行为采用 FRONTEND v1 B–H 和 R1 v1，本说明只定位已生成代码，不改契约。

先看 `frontend_frame_pair.sv` 的 `job_state` 和五级模块连线，再看 `window3x3_pair.sv` 的 `replay_phase/read_pending`，最后看 `line_store_pair.sv` 两lane原语。输入、数值候选输出、最终任务status是三个实际握手。

1. `job_fire` 锁三ID/配置，合法kind才产生frame_start；首RGB在下一沿。ACTIVE的in_ready取F1真实容量并受独立cancel限制；错误payload不能进入F1，但坏事务真实握手仍计入accepted_pairs。
2. `flush` 来自真实input_error或有效cancel，采样沿清所有流水/窗口有效历史。不能把它组合连回ready，否则会消掉触发错误的握手。旧输出在取消/错误沿若已交付仍由output_fire计数。
3. 窗口每次advance先消费旧read_pending，再发真实读/replay/TAIL。旧recent读回写入older，当前真实pair写recent；新读q+1/跨行0与旧写q/末组地址不同。
4. 首真实行只建立recent；第二行上边复制recent，随后用older/recent/current。REPLAY底行读older/recent/recent，不新增真实输入；TAIL只用水平历史复制右边界。
5. `horizontal_q/horizontal_row` 属于旧待输出组，`pending_q/new_row` 属于新组。跨行q0先输出旧行末组，再建立新行首组；窗口每lane按低a高i行优先打包。SOF/EOL/EOF由实际旧中心坐标产生。
6. `output_present` 被阻塞时禁止读写和pending推进；输入气泡时仍可消费旧pending/写旧真实组。RAM不清零，valid及首两行规则隔离上个job残留。
7. 最后FO真实交付、所有算术empty及两窗口IDLE后的下一沿，F0核真实输入/输出N计数并形成不可变status。STATUS消费沿只回IDLE，再下一沿才可新job。

| REQ/草图 | 已生成文件/稳定符号 | 待执行测试 |
|---|---|---|
| FE-01/06/07，OP-01 | frontend_frame_pair.sv：job_state/input_expected_q/input_expected_row/input_fire/input_error/output_fire/all_empty | FT-06…11 |
| FE-01/03/04/06，OP-03…05 | window3x3_pair.sv：read_pending/replay_phase/horizontal_columns（left_column/center_column0/1）/row_major_window | FT-04…07/10/11 |
| FE-08、INV-06…08 | line_store_pair.sv：pixel_lane/ram；两行each实例真实EFX_RAM10 | FT-05/12 |

实际首个静态检查：`runs/window_precompile_001/` 中vlib/vlog退出0，实际原厂EFX_RAM10及line_store/window编译Errors0/Warnings0。未展开/运行TB，不能据此标FT通过。三算术、完整封装及外壳仍在并行整合；当前功能仿真/综合/布局布线/STA/bit未通过验收。
