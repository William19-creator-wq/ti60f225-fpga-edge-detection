# TRACK4-CANNY-MEMORY-JOIN-001 v1.1：FLUSH实际关闭探测

沿用v1整体/接口/验证范围和用户持续授权。组合旧状态走查发现：cache v1.1在已经提出的FLUSH中遭取消或安全存储错误时，会先终结旧FLUSH请求并返回错误，此时还可能保持configured。错误回复证明旧事务安全终结，不能直接推断cache配置已关闭。原cache包保持不改。

中文草图：FLUSH_WAIT消费回复、记录真正error后，进入FLUSH_DECIDE；下一拍cache已回IDLE。若cfg_ready=1，证明旧配置已关闭，可进入queue SEAL；若req_ready=1，证明仍有旧配置，重发op3/index0。此时cache fault/abort已粘住，第二个FLUSH只丢失败私有metadata并关闭，不提出新的外存请求。再经同一DECIDE实际确认。两个ready都0时等待原服务恢复/隔离，不能猜测关闭。只利用公开接口，不窥探内部configured来推进生产逻辑。

验证：原MJ-T05 FLUSH取消/安全写错加入“done前cache和queue都configured=0”观察，并检查第二次FLUSH不产生新RPC。held公开回复仍消费一次，各自错误优先和unknown隔离不变。配置失败时同样走DECIDE后只关闭实际成功的queue。范围不增加硬件/原资料修改。读回READY后按已有授权继续。
