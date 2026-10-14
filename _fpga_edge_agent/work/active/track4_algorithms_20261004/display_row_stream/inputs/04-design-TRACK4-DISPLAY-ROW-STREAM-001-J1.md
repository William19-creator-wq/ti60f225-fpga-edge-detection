# 行消费 v1.1：请求承诺与连续吞吐的结构修订

- Goal / Current state：v1消费者刚生成、尚未编译/仿真。代码复核发现组合 want_request 受首DE/cancel热输入影响，在两个上升沿之间可能撤掉已提出请求。RS05要求真正兑现promise，不能只靠采样到stall以后再保持。
- Target state / Gap：native request_valid完全由pending_request寄存器给；reserve真fire后创建RE0承诺，每次真实RE fire才决定下一承诺。PRIME接受0/1后保持地址2的未接受promise（P2除外），两个真实credit满时由native ready0压住；首DE pop0与RE2同沿，之后保持每DE一对吞吐。没有第三response槽、没有额外像素RAM。
- Assumptions / Open questions / Dependencies：native count+pending最多2、允许同沿pop+RE，新结构直接利用已核源码。原16依赖、20输入原样保留，加本卡为第21项；无新接口或当前未定项。
- Milestones / Detailed steps / State transitions：保存读回呈现READY→baseline-v1.1冻结21项→只改消费者request生成/RS05说明及对应TB期望→实际同帧/取消/hold测试→MAP。持续用户自主软件授权，无逐版批准等待；本地审计与硬件闸门不改。
- Artifacts and hashes / Validation：原消费者初版按变更前完整SHA快照保存 inputs/rtl-before-J1.sv（计版本证据，不多计业务源码）；当前前置设计v1冻结保留。7自写文件不增。测试PRIME取消可能真实读取0/1/2共3项，期望来自实际promise/fire；P2只能读0/1，未接受promise不计issued。全54bit/完整GEN/credit/尾部/真正归还仍严格。
- Failure handling / Human approval gates / Rollback / Completion criteria：日志/旧版保留；原资料与已登记组件只读，不安装/联网/硬件；软件草图→新码→必要仿真/MAP，整goal不缩减。

## 整体、交接与中文逐沿草图

正常：reserve接受E0后req0 valid；E1接受0后req1 valid；E2接受1后req2 valid（P>2），native count1+pending1满两个credit、ready0，req2保持；真正首DE E3或更晚，pop0与req2 fire一起发生。此沿后req3 valid，下一DE pop1/request3，pending的同步RAM数据持续补队列。最後两pair时issued已经P，pending0，不能发越界地址P。

取消：准备时req2已经valid却未被接受，discard使本行不显示并开始DRAIN pop0，native释放credit让req2真正接受；随后依实际回应把1/2都pop，issued==popped、pending0、tail0才DISCARDED。不能为了“只准备两项”把第三个已承诺valid撤掉，也不能把尚未接受req2算成第三credit。reserve与discard同沿直接DRAIN且不创建RE0，属于尚无承诺的独立事件。

always_ff里：reserve好包且不discard→pending1；真实request_fire→issued+1并按**提交后的地址**是否<P及当前PRIME的下一个地址<3或本沿真实pixel pop来创建下一promise；其它边沿pending保持。出现取消/错误仅停止创建下一promise，已有pending不能清；Q中若原promise被真实接受也只清该promise，不继续生成。GEN/地址来自borrowed稳定ticket及只在fire推进的issued，完整holding成立。

RS01/02/03接口不变；RS05 pending_request→真RE/两credit→连续DE与取消STV1/2/3；RS06尾部/release/Q不变。另按原RS04修正“PRIME先看到错response”的error3分类，属于已规定行为的实现对齐，不放宽验收。内部两个error寄存器照v1，下一reserve不能清旧正在显示失败行的display_error。所有当前生成门槛有实据；保存读回呈现后自行实施，结果随后记录。
