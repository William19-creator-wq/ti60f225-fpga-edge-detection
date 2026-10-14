# DDR整段缓冲RAM映射来源 v1

2026-10-04；TRACK4-DDR-SERVICE-001。只读模型核查与设计预算，未执行RTL、综合、仿真、布局布线或器件验证。

实际文件：`C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/efx_ram10.v`。
SHA256：`DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33`；已由[FE输入清单](frontend-baseline-v1.json)绑定，此页不修改该清单。

模型第17行说明512×20模式；第101–118行给READ_WIDTH/WRITE_WIDTH=20对应9bit地址；第120–128行给双写使能与512×20容量。第311–325行按WRITE_WIDTH/2分低半/高半，因此20bit模式每个使能控制10bit，不能当8bit字节WSTRB。第334–417行表明正沿读、OUTPUT_REG=0仍在该沿后更新、下一同步沿捕获，RE0保持；同址语义不用于本候选。

设计提议：R池和W池分开，每池7块20×512同步条带，前6块分别保存data[19:0]…data[119:100]，末块低8bit保存data[127:120]、高12bit固定0，统一WE=11。地址{slot3,beat6}覆盖8个64拍槽；每池载荷8×64×16=8192B，物理位数7×512×20=71680bit。两池14块；不得按总8192bit/段误推为一块可提供128bit整拍端口。

R池物理R写口与逻辑R读口独立；W池逻辑W写口与物理W读口独立。同池只读已封存槽/写收集槽，槽状态和pending预留防同址及越界。20bit容器不改变外部128bit低地址/低byte lane契约。

[DDR服务设计](../../../planning/design-TRACK4-DDR-SERVICE-001.md)给完整端口/FSM和生命周期；14RAM为候选模式映射，并非综合推断或Ti60F225实际放置结果。加Canny既有44块得数据池相关小计58/256=22.65625%。DDR稿另提议scope身份1块、phase冷记录2块20×512：scope地址={slot4,word5}，phase bank=slot[4]、地址={slot[3:0],word5}，分别按640bit容器存623bit身份及scope handle68/阶段快照，不能把完整623bit scope加token重复塞入phase容器。metadata3块后服务共17块，Canny44+服务17=61/256=23.828125%，才是当前已列RAM小计；平台/相机/显示/识别、热元数据FF与实际综合/时序另计。
