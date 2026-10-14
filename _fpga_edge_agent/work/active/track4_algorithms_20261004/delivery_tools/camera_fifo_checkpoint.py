"""REQCP01..04：当前源/登记/运行实核，再新建不覆盖的v6进度。"""
import datetime,hashlib,json,pathlib
ROOT=pathlib.Path('D:/大三/FPGA_verilog/_fpga_edge_agent')
WORK=ROOT/'work/active/track4_algorithms_20261004'
OUT=ROOT/'experiments/track4_algorithms_20261004/05_delivery'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def fresh(path):
    assert path.resolve().is_relative_to(ROOT.resolve()) and not path.exists(),str(path)
    return path
def audit(unit,run):
    folder=WORK/unit/'runs'/run;suite=read(folder/'suite-result.json');assert suite['status']=='PASS' and suite['finished']
    reference=read(folder/'reference-audit.json');assert reference['status']=='PASS'
    for entry in read(folder/'source-manifest.json'):assert sha(pathlib.Path(entry['path']))==entry['sha256'].upper()
    return reference
def main():
    previous_path=OUT/'fast-batch-checkpoint-20261009-v5.json';previous=read(previous_path)
    earlier2=read(OUT/'fast-batch-checkpoint-20261008-v2.json');earlier3=read(OUT/'fast-batch-checkpoint-20261009-v3.json')
    old_sources=earlier2['new_files_checked']+earlier3['new_files_checked']+previous['new_files_checked'];assert len(old_sources)==84
    for entry in old_sources:assert sha(pathlib.Path(entry['path']))==entry['sha256'].upper()
    units=[('sc431hai_config','SC431HAI-CONFIG-COMPONENT-20261009-v1',13),('video_async_fifo','VIDEO-ASYNC-FIFO-COMPONENT-20261009-v1',7)]
    registered=[];new_sources=[];resources={}
    for name in [v['artifact'] for v in previous['registered_components']]+[v[1] for v in units]:
        folder=ROOT/'artifacts/staging'/name;path=folder/'artifact-manifest.json';manifest=read(path)
        prior=next((v for v in previous['registered_components'] if v['artifact']==name),None)
        if prior:assert sha(path)==prior['manifest_sha256'].upper()
        for entry in manifest['files']:assert sha(folder/entry['relative'])==entry['sha256'].upper()
        registered.append(dict(artifact=name,files_checked=len(manifest['files']),manifest_sha256=sha(path)))
    assert len(registered)==12 and sum(r['files_checked'] for r in registered)==5071
    for unit,artifact,count in units:
        folder=WORK/unit;own=[]
        for kind in ('rtl','model','tb','scripts','project','data'):
            for path in (folder/kind).glob('*'):
                if path.is_file() and path.suffix in ('.sv','.py','.ps1','.xml','.sdc','.json'):own.append(path)
        assert len(own)==count
        for path in sorted(own):
            relative=path.relative_to(folder).as_posix();assert sha(path)==sha(ROOT/'artifacts/staging'/artifact/'source'/relative)
            new_sources.append(dict(path=str(path),sha256=sha(path),artifact=artifact,relative=relative))
        manifest=read(ROOT/'artifacts/staging'/artifact/'artifact-manifest.json');resources[unit]=manifest['resources']
        for run in manifest['simulations']:audit(unit,run)
        assert read(folder/'runs'/manifest['component_map']/'Map.result.json')['exit_code']==0
    assert len(new_sources)==20
    assert resources['sc431hai_config']==dict(EFX_RAM10=1,EFX_FF=961,EFX_LUT4=1576,EFX_ADD=82,DSP=0)
    assert resources['video_async_fifo']==dict(EFX_RAM10=14,EFX_FF=387,EFX_LUT4=445,EFX_ADD=31,DSP=0)
    camera_fast=audit('sc431hai_config','camera_fast_001');camera_full=audit('sc431hai_config','camera_fullclock_001')
    fifo_manifest=read(ROOT/'artifacts/staging/VIDEO-ASYNC-FIFO-COMPONENT-20261009-v1/artifact-manifest.json')
    fifos=[audit('video_async_fifo',r) for r in fifo_manifest['simulations']]
    totals=dict(runs=len(fifos),cases=sum(a['metrics']['cases'] for a in fifos),records_compared=sum(a['records_compared'] for a in fifos),lost=sum(a['metrics']['lost'] for a in fifos))
    assert totals==dict(runs=9,cases=49,records_compared=659248,lost=104)
    hd=audit('video_async_fifo','fifo_hd_002');assert hd['metrics']['accepted']==hd['metrics']['delivered']==518400 and hd['metrics']['lost']==0
    assert camera_fast['metrics']['cases']==43 and camera_full['metrics']['cases']==2
    checkpoint=fresh(OUT/'fast-batch-checkpoint-20261009-v6.json');report=fresh(OUT/'CONTINUATION_20261009_CAMERA_FIFO.md')
    result=dict(previous)
    result.update(schema_version='1.4',at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),earlier_business_files=154,new_files=20,
                  total_business_and_validation_files=174,new_unit_counts=dict(sc431hai_config=13,video_async_fifo=7),new_files_checked=new_sources,
                  old_work_files_checked=84,current_work_files_checked=104,previous_checkpoint_sha256=sha(previous_path),registered_components=registered,
                  registered_files_checked=5071,registered_hash_drift=0,new_source_drift=0,live_tool_sessions=[],
                  camera_fast=camera_fast,camera_full_clock=camera_full,camera_resources=resources['sc431hai_config'],
                  fifo_totals=totals,fifo_hd=hd,fifo_resources=resources['video_async_fifo'],
                  remaining=['CSI version/packing/PPC/sideband/error attribution/actual receiver closure and adapter',
                             'frame-manager grants/phase/fence/freeze-resume/display QoS and coherent production integration',
                             'display prefetch/TMDS/same-frame overlay/annotation',
                             'circle/rotated rectangle/missing edge/occlusion/overlap/multiobject quality and shared arithmetic',
                             'total resource/worst processing time/one production top/pins/clocks/PNR/STA/full bit'],
                  full_project_goal_complete=False,status='PROGRESS_FULL_GOAL_ACTIVE',classification='progress')
    checkpoint.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');assert read(checkpoint)==result
    text=f'''# 2026-10-09：摄像头配置与双时钟运输继续交付

已按用户自主执行授权完成新20份业务/验证输入：SC431HAI配置13份、FIFO7份，累计174份。文件数不是模块数；共享镜像、官方依赖、文档、运行向量、日志和审计辅助不重复算业务代码。

摄像头配置：真实开漏数字事务，ID/CD6B、原表164次保序写、14项公开masked读回、STOP停流、T4启动等待与故障关闭。I2C主控276用例、快速配置43用例/5次完整配置/900笔事务独立核验；生产100MHz时钟/101MHz上界另完成配置+STOP，共2用例/180笔完整配置事务。生产参数实测最短低5070ns、高5080ns、START5050ns、STOP5080ns、空闲10150ns，平台资格到首START4045075ns。MAP为1 RAM10/961 FF/1576 LUT4/82 ADD/0DSP。不会把寄存器资格直接当采集ARM或真CSI成功。

视频FIFO：两真实独立时钟，native双时钟RAM、Gray同步、2条前取信用、held数据和独立粘滞损失。当前源9组运行49场景核对659248条，104次预设丢失一致；宽1…320、深16…4096含绕回/停钟/恢复/满/共同冷复位。完整1080p四像素组数量518400条在约70MHz写/100MHz读下全部交付、零丢失。MAP为14 RAM10/387 FF/445 LUT4/31 ADD/0DSP。首MAP原语READ_FIRST不合法，保留失败，设计J1修为READ_UNKNOWN，全部002源重新仿真后登记；旧320位运行源漂移被脚本拒绝，未混入新证据。

这两批是实际独立组件综合；未对它们执行板级PNR/STA或生成整机bit。FIFO物理Gray延迟/偏斜、真实电平/SID/reset、CSI位序/PPC/sideband/错误/closure仍需生产平台闭合。不能把独立组件的资源简单相加宣布整机装得下，STATS共享算术与最重HY处理时间优化仍在后续。

中文阅读次序：planning/design-TRACK4-SC431HAI-CONFIG-001.md → sc431hai_config/docs/README.md → profile/master/父状态/独立wire trace；planning/design-TRACK4-VIDEO-ASYNC-FIFO-001.md → video_async_fifo/docs/README.md → Gray/信用/RAM/双域复位 → 外部接受/交付参考 → 各runs/MAP → artifacts/staging冻结副本。

本次重核84份既有增量工作源及20份新源，共104份；初始70份沿其既有功能与登记证据，不伪称本次重新测试全部174份。12份组件Manifest共5071条文件逐一SHA核对，漂移0，当前11组仿真及2个MAP源一致。新包SC431HAI-CONFIG-COMPONENT-20261009-v1与VIDEO-ASYNC-FIFO-COMPONENT-20261009-v1均只在staging，不升级为硬件验收。

原先已通过的1080p RAW→RGB源写→真实AXI源读回→完整Canny结果证据保留于前v5，2073600像素/1078边缘等事实未被本批重复冒充。既有观察图仍可读：capture-canny-1080p-actual-panel-20261009-v2.png，红色叠加为软件观察，不称生产RTL显示已完成。

接下来继续CSI映射/真实closure、帧管理与冻结恢复、显示预取/TMDS/标注、完整复杂识别及算术共享，再做全工程资源/处理时间/单一生产top/引脚/时钟/PNR/STA/bit。新发现本机官方CSI ModelSim示例（soft_dphy及source_modelsim），尚未运行；不能把找到文件写成兼容已通过。板载2Gb/x16匹配DDR动态模型缺口仍只影响对应控制器/PHY动态证据，其他编码继续，不恢复排除DDR或降低1080p/识别要求。

本次未改原HDK、冻结包、正式数据库/状态，未下载、安装、联网或操作硬件；仍采用已准本地审计。整目标ACTIVE，生成最终bit之后停止硬件步骤。人工理解验收仍待实际作答。
'''
    report.write_text(text,encoding='utf-8');assert report.read_text(encoding='utf-8')==text
    event=dict(event_id='EV-FAST-BATCH-20261008-027',at_utc=result['at_utc'],status=result['status'],classification='progress',
               checkpoint=str(checkpoint),checkpoint_sha256=sha(checkpoint),business_files=174,new_files=20,registered_files_checked=5071,
               registered_hash_drift=0,full_project_goal_complete=False,hardware_actions=False,formal_state_changed=False)
    for p in (ROOT/'runtime/events/2026/10/session-FAST-BATCH-20261008.jsonl',ROOT/'experiments/track4_algorithms_20261004/03_review/side-effects.jsonl'):
        with p.open('a',encoding='utf-8') as f:f.write(json.dumps(event,ensure_ascii=False)+'\n')
    print(json.dumps(dict(status=result['status'],checkpoint_sha256=sha(checkpoint),business_files=174,work_sources_checked=104,registered_files_checked=5071,fifo_totals=totals)))
if __name__=='__main__':main()
