# 已有WLF的实际只读观察

这是Questa 2024.1工具采样与Agent读回记录，供Root/用户按中文草图复核。用户理解验收由本人读回；硬件观察闸门保持原状态。采样未重跑DUT，也未修改当前006冻结源码、参考或原WLF。

先查现装`docs/cmd_help/q_cmd_help.txt`的examine（133行）与vsim（361行）：支持`vsim -view`打开已有仿真、`examine -time`读过去时刻。实际命令为`vsim -c -view <原WLF> -do <本目录query.do>`，三个查询均退出0。

本目录的`.do`是实际查询、`.log`是工具返回、`.csv`是从日志CSV行直接提取；`observation-sources.json`保存每个WLF读前/读后相同SHA256。初始探路亦保留`inspect_initial.do/.log`，实际数据集名为trace。

## FT05：气泡、跨行与背压期间RAM端口

来源：`frontend_suite_005/FT05-ram-transitions/trace.wlf`。这项旧run的数据和协议检查通过，汇总因无FS单元metadata填0失败；本次只观察其既有真实波形，修正metadata后的最终006另作全量验收。

采样时间选在随后上升沿前1ns。例如84ns的控制在85ns被RAM采样；读地址在rd_en=0时不作操作解释。RAM写地址取pending_q，phase 1=REAL、2=REPLAY、3=TAIL。

| 时间ns | in_ready/out_valid/out_ready | input/output index | rd_en/addr | recent/older write | pending_q | phase | 实际读回 |
|---|---|---|---|---|---|---|---|
| 84 | 1/0/1 | 3/0 | 0/0 | 1/0 | 2 | 1 | 输入气泡仍提交上一REAL延迟写；没有新读 |
| 94 | 1/0/1 | 3/0 | 0/0 | 0/0 | 2 | 1 | 第二个气泡无重复写，index不进 |
| 114 | 1/0/1 | 4/0 | 1/0 | 1/0 | 3 | 1 | 跨行读q0、写上一行q3，地址不同 |
| 144 | 0/1/0 | 7/0 | 0/0 | 0/0 | 2 | 1 | 首输出背压，读写均停，pending保持 |
| 154 | 0/1/0 | 7/0 | 0/0 | 0/0 | 2 | 1 | 第二个背压沿，同样保持index/pending |
| 164 | 1/1/1 | 7/0 | 1/3 | 1/1 | 2 | 1 | 放行后读q3、写q2，两bank写且无同地址碰撞 |
| 214 | 0/1/1 | 12/5 | 1/0 | 1/1 | 3 | 2 | 首REPLAY读q0，同时提交最后REAL延迟写q3 |
| 224 | 0/1/1 | 12/6 | 1/1 | 0/0 | 0 | 2 | 消费REPLAY pending，不写bank |
| 254 | 0/1/1 | 12/9 | 0/3 | 0/0 | 3 | 3 | TAIL不发读写，后续形成最终右边界 |

214ns说明判写使能必须看pending类型。将“REPLAY阶段绝不写RAM”当规则会误判最后一次合法REAL延迟写。

## FT10：窗口B底行TAIL取消与复位

来源为`protocol_probe_001/FT10-cancel-phase-window-b-tail/trace.wlf`及reset对应WLF。该专项44项通过后的波形保存了clk、phase_present、frontend_all_empty、status_valid/status_ready。

phase_present是实时观测bit集合：144=窗口B REPLAY(128)+Sobel valid(16)，272=窗口B TAIL(256)+Sobel valid(16)。它不是all_empty的反码；新job窗口处于REAL时即使尚无这些phase bit，all_empty仍为0。

| 时间ns | cancel: all_empty/status_valid/status_ready/phase | reset: 同列 | 实际读回 |
|---|---|---|---|
| 474 | 0/0/1/144 | 0/0/1/144 | 两者均实际处于B REPLAY与Sobel有效 |
| 484 | 0/0/1/272 | 0/0/0/272 | 两者都实际命中B TAIL，reset接收端同时屏蔽 |
| 486 | 1/1/1/0 | 1/0/0/0 | 下一采样沿后旧有效/历史均清；取消给出终止状态，reset旧job无终止 |
| 496 | 1/0/1/0 | 1/0/0/0 | 取消状态已消费，reset仍不虚构旧status |
| 506 | 0/0/1/0 | 0/0/0/0 | 两条路径的新job已启动，窗口进入REAL |
| 516 | 0/0/1/1 | 0/0/1/1 | 两者恢复的首输入已进入真实F1有效级 |
| 1044 | 1/1/1/0 | 1/1/1/0 | 两者完整恢复job均已排空、正常终止状态有效 |
| 1046 | 1/0/1/0 | 1/0/1/0 | 恢复状态消费完，内部保持全空 |

交付数量与终止码请结合各case JSON：cancel首次码1、旧12+恢复20=32组；reset只为恢复job形成码0、旧11+恢复20=31组，二者数值/协议错误0。上表的独立WLF采样集中验证实际phase与清空/status过程，数量来源保留为TB真实fire记录。

## 用户实际复查顺序

1. 先打开三个CSV读回上表，核对对应.log的`# CSV`原始返回。
2. 在Questa打开原WLF，按上表时间定位；FT05先把输入/输出握手、index、rd_en/addr、recent/older write、pending_q、replay_phase并排。
3. FT10把phase_present、frontend_all_empty、status_valid/status_ready并排，先看474→484命中phase，再看486清空，最后看恢复job终止。
4. 最后联合result.json复核真实交付/比较、恢复数量和错误为0，并由本人说明气泡为何可有旧写、首REPLAY为何仍可写、取消与reset为何少一组旧交付。

本记录已由Agent从现有WLF实际采样；Root可以独立读回这些查询文件。用户理解读回、硬件下载及实体观察另按控制面原有闸门执行。
