"""Export a bounded, provenance-tracked handoff; no build or hardware operation."""
from pathlib import Path
from datetime import datetime, timezone, timedelta
import hashlib
import json
import re
import shutil
import zipfile

project = Path('D:/大三/FPGA_verilog')
control = project / '_fpga_edge_agent'
active = control / 'work/active/track4_board_first_20261011'
verified = control / 'work/active/track4_board_debug_031_20261011'
now = datetime.now(timezone.utc)
local = now.astimezone(timezone(timedelta(hours=8)))
status = json.loads((active / 'integration-status.json').read_text(encoding='utf-8-sig'))
run = status['current_run']
flow = active / 'runs' / run / 'flow'
terminal = active / 'runs' / run / 'compile.result.json'
terminal_body = json.loads(terminal.read_text(encoding='utf-8-sig')) if terminal.is_file() else None
actual_capacity = None
if terminal_body is not None:
    if terminal_body.get('exit_code') != 0:
        place = flow / 'outflow/track4_board.place.out'
        place_text = place.read_text(encoding='utf-8', errors='replace') if place.is_file() else ''
        capacity_match = re.search(r'Logic blocks\s*:\s*capacity=(\d+) usage=(\d+)', place_text)
        status['current_run_result'] = 'FAILED_PHYSICAL_CAPACITY' if capacity_match else 'FAILED_COMPILE'
        if capacity_match:
            actual_capacity = {'capacity': int(capacity_match[1]), 'usage': int(capacity_match[2])}
            status['latest_failed_packed_logic'] = actual_capacity['usage']
    else:
        status['current_run_result'] = 'COMPILE_EXIT_0_CHECK_FINAL_STA_BEFORE_HANDOFF'
folder = control / 'handoff' / ('claude_code_' + local.strftime('%Y%m%d_%H%M%S'))
folder.mkdir(parents=True, exist_ok=False)
provenance = {}

def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest().upper()

def copy(src, relative):
    if not src.is_file():
        return False
    dst = folder / relative
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    provenance[dst.relative_to(folder).as_posix()] = str(src)
    return True

def write(relative, content):
    dst = folder / relative
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(content, encoding='utf-8')

def json_write(relative, body):
    write(relative, json.dumps(body, ensure_ascii=False, indent=2) + '\n')

def source_tree(src, dest):
    for dirname in ('rtl', 'ip', 'algorithm', 'board'):
        for path in sorted((src / dirname).rglob('*')):
            if path.is_file():
                copy(path, Path(dest) / path.relative_to(src))
    for name in ('track4_board.xml', 'track4_board.sdc', 'track4_board.peri.xml', 'Panel_1080p_reg.mem'):
        if not copy(src / name, Path(dest) / name):
            raise RuntimeError('Missing required project file: ' + str(src / name))

source_tree(verified, 'work/verified_031')
source_tree(flow, 'work/development_' + run.removeprefix('board_compile_'))
for name in ('README.md', 'handoff.json', 'hardware-identity-confirmation.json', '实物首测说明_031.txt'):
    copy(verified / name, Path('work/verified_031') / name)
for name in ('track4_board.bit', 'track4_board.hex', 'track4_board.map.rpt', 'track4_board.place.rpt',
             'track4_board.route.rpt', 'track4_board.timing.rpt', 'track4_board.pinout.csv',
             'track4_board.pt.rpt', 'track4_board.res.csv', 'track4_board.pgm.out'):
    copy(verified / 'outflow' / name, Path('work/verified_031/outflow') / name)
expected = '77216940A9D01733EF93154C2C0A665F8C3FA0A9E4DE94C5D1FCB6F08FCB9951'
if sha(folder / 'work/verified_031/outflow/track4_board.bit') != expected:
    raise RuntimeError('Registered 031 bit hash mismatch')

copy(active / 'integration-status.json', 'context/integration-status.captured.json')
copy(active / 'full-goal-completion-audit.json', 'context/full-goal-completion-audit.captured.json')
copy(control / 'artifacts/staging/TRACK4-BOARD-FIRST-20261011-031/artifact-manifest.json',
     'context/registered-031-artifact-manifest.json')
copy(control / 'runtime/events/2026/10/session-FAST-BATCH-20261008.jsonl', 'context/runtime-events.captured.jsonl')
for name in ('inputs.json', 'compile.start.json', 'compile.result.json', 'result.json'):
    copy(active / 'runs' / run / name, Path('context') / run / name)
if terminal_body is not None:
    for name in ('track4_board.map.rpt', 'track4_board.place.rpt', 'track4_board.place.out',
                 'track4_board.res.csv', 'track4_board.err.log'):
        copy(flow / 'outflow' / name, Path('context') / run / 'outflow' / name)
for name in ('compile.result.json', 'result.json', 'inputs.json'):
    copy(active / 'runs/board_compile_061' / name, Path('context/board_compile_061') / name)
for name in ('track4_board.map.rpt', 'track4_board.place.rpt', 'track4_board.place.out',
             'track4_board.res.csv', 'track4_board.err.log'):
    copy(active / 'runs/board_compile_061/flow/outflow' / name,
         Path('context/board_compile_061/outflow') / name)
for name in ('build_board.ps1', 'register_board.ps1', 'register_when_ready.ps1'):
    copy(active / 'scripts' / name, Path('context/build_scripts_reference') / name)

rule_files = [
    'AGENTS.md', 'AI_Agent_代码可理解性规范_增补提案_v0.2.md',
    '_fpga_edge_agent/AGENTS.md', '_fpga_edge_agent/config/AGENTS.md',
    '_fpga_edge_agent/config/AGENT_PROMPT.md', '_fpga_edge_agent/config/PROJECT_CONFIG.yaml',
    '_fpga_edge_agent/config/APPROVAL_MANIFEST.yaml', '_fpga_edge_agent/database/README.md',
    '_fpga_edge_agent/state/PROJECT_STATE.json', '_fpga_edge_agent/state/TASK_LEDGER.csv',
    '_fpga_edge_agent/docs/WORKFLOW.md', '_fpga_edge_agent/docs/workflows/TRACK4_WORKFLOW.md',
    '_fpga_edge_agent/skills/fpga-hardware-node-gate/SKILL.md',
    '_fpga_edge_agent/planning/PLAN_TEMPLATE.md',
    '_fpga_edge_agent/docs/requirements/TRACK4_REQUIREMENTS.md',
    '_fpga_edge_agent/docs/requirements/TRACK4_REQUIREMENTS.csv',
    '_fpga_edge_agent/docs/requirements/HARDWARE_AND_TOOLCHAIN_EVIDENCE.md',
    '_fpga_edge_agent/docs/requirements/V4_CAMERA_SELECTION_20260927.md',
]
for relative in rule_files:
    copy(project / relative, Path('rules/project') / relative)
plans = [
    'design-TRACK4-FAST-BATCH-001.md', 'design-TRACK4-CIRCLE-FAST-INTEGRATION-001.md',
    'design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md', 'design-TRACK4-RECTANGLE-REFINE-001.md',
    'design-TRACK4-GEOMETRY-FAST-PM-001.md', 'design-TRACK4-ALGORITHM-R3-FIT-001.md',
    'design-TRACK4-ALGORITHM-R3-ANGLE-001.md', 'design-TRACK4-ALGORITHM-R4-STATS-001.md',
    'design-TRACK4-CANNY-FULL-SW-001.md', 'design-TRACK4-CANNY-FULL-SW-001-v1.1.md',
    'design-TRACK4-FRAME-ACTORS-001.md', 'design-TRACK4-FIT-DSP-DIRECT-001.md',
    'design-TRACK4-FIT-LOCAL-RESOURCE-001.md', 'design-TRACK4-CAPTURE-CANNY-AXI-001.md',
]
for name in plans:
    copy(control / 'planning' / name, Path('rules/project/_fpga_edge_agent/planning') / name)

inputs = json.loads((active / 'runs' / run / 'inputs.json').read_text(encoding='utf-8-sig'))
checks = []
for entry in inputs:
    relative = entry['relative'].replace('\\', '/')
    dst = folder / ('work/development_' + run.removeprefix('board_compile_')) / relative
    if dst.is_file():
        checks.append({'relative': relative, 'matches_prebuild_hash': sha(dst) == entry['sha256'].upper()})
source_mismatches = [x for x in checks if not x['matches_prebuild_hash'] and
                     x['relative'].startswith(('rtl/', 'ip/', 'algorithm/', 'board/'))]
if source_mismatches:
    raise RuntimeError('Frozen source differs from run inputs: ' + json.dumps(source_mismatches))
json_write('context/development-input-copy-check.json', {
    'run': run, 'checks': checks, 'source_mismatches': source_mismatches,
    'note': 'Efinity may rewrite project XML during a build; any non-source hash difference is listed rather than inferred as a successful build.'
})

context = {
    'created_at_utc': now.isoformat(), 'created_at_asia_shanghai': local.isoformat(),
    'purpose': 'Human-reviewed handoff to Claude Code; no messages sent or Claude invocation performed',
    'original_workspace': str(project),
    'verified_project': 'work/verified_031/track4_board.xml',
    'verified_bit': 'work/verified_031/outflow/track4_board.bit', 'verified_bit_sha256': expected,
    'development_project': 'work/development_' + run.removeprefix('board_compile_') + '/track4_board.xml',
    'development_source_snapshot_from_run': run,
    'development_result_at_capture': status.get('current_run_result'),
    'development_actual_compile_result': terminal_body,
    'development_actual_physical_capacity': actual_capacity,
    'raw_status_file_may_lag_actual_terminal_result': terminal_body is not None,
    'latest_verified_run': 'board_compile_031',
    'board_confirmed_by_user': 'Ti60F225 DemoBoard V4', 'camera_confirmed_by_user': 'SC431HAI',
    'efinity_version': '2026.1.132', 'device': 'Ti60F225', 'timing_model': 'I3',
    'hardware_programming_reported': False, 'hardware_effects_verified': False,
    'scope': status.get('scope'), 'user_instruction': status.get('user_instruction'),
    'remaining_work': status.get('remaining_work'),
    'last_failed_packed_logic_from_status': status.get('latest_failed_packed_logic'), 'physical_xlr_capacity': 60800,
    'original_full_goal_complete': False,
    'originals_and_historical_runs_read_only': True,
    'extra_hardware_disallowed': True, 'existing_board_ddr3_allowed': True,
    'formal_database': 'Not configured; approved local audit exceptions retained; formal DB/state not changed',
    'software_installer_or_driver_included': False, 'credentials_or_environment_dump_included': False,
    'standalone_tests_or_new_design_sketches_requested_for_current_batch': False,
    'snapshot_not_live_state': True,
}
json_write('CONTEXT.json', context)
write('USER_SCOPE_AND_APPROVALS.txt', '''用户指示与既有授权摘要（聊天事实转述，不冒充新增数据库审批）

硬件：用户已明确回复“是，Ti60F225 V4 + SC431HAI”。板卡已到货。
存储：用户明确“允许使用板卡现有 DDR3”；同时“必须只用板卡现有资源”。
原目标：五项基础及六项高阶，1080p；完整复杂圆/旋转矩形/遮挡/缺边/重叠识别未完成。
用户拒绝160×120、单目标、每秒1帧的降级方案，不可把它恢复为验收目标。

用户近期明确说：
“当你统计完后自行进行，无需我的批准”
“不需要再中文草图，测试了……主要任务是把所有模块整合起来，整机综合与布局布线”
“只需要你整合所有模块，为什么需要这么长的时间？”
“我的实物板子到了……需要测试你目前认为可以交给我的部分可用代码”

因此当前批次以已有模块整合、资源/时序收敛、031人工上板指导为主；不自动扩展缺失算法。
当前用户指示优先于历史文档的重复审批/新增草图或独立测试流程；原文规则保留用于说明来源。
既有预检、R1、R2、FAST批次及本地审计例外，见规则文件审批清单与事件；不得伪造扩大范围的批准。
硬件操作仍由人完成；当前没有下载成功或画面的人工反馈，不标记实物PASSED。
额外工具/驱动/安装/网络/数据库操作不在本次交接授权中。不得解密或升级受保护IP。
正式PROJECT_STATE/TASK_LEDGER仍有旧H0信息，不能把这些旧字段当作最新硬件确认；也不擅自改写它们。
''')
write('START_HERE.txt', fr'''Claude Code 交接包 — {local.strftime('%Y-%m-%d %H:%M:%S')} Asia/Shanghai

建议阅读顺序：
1. 本文件；CONTEXT.json；USER_SCOPE_AND_APPROVALS.txt。
2. rules/project/AGENTS.md，然后按其指引阅读包内对应控制面规则、提示词、配置、状态、数据库说明。
3. context/integration-status.captured.json 与 full-goal-completion-audit.captured.json。
4. work/verified_031/README.md、实物首测说明_031.txt、handoff.json 和 outflow 报告。
5. 按实际问题查看开发工程和相关设计，不一次性读取全部源码/历史计划。

两份代码：
work/verified_031：已通过综合、布局布线、最终STA及bit/hex；124源码入口。
  XLR60531/60800，建立+0.381ns，保持+0.029ns。默认彩色加红色边缘叠加。
  六模式及按键见首测说明；几何候选仍是初版包围盒/方向判断，不是完整A6。
work/development_{run.removeprefix('board_compile_')}：从{run}冻结输入复制；新增识别代码参考。
  打包时结果为{status.get('current_run_result')}；这不等于通过布局布线或可下载。
  061综合通过但物理容量失败；最新状态记录72282 XLR/60800。
  本次开发run的实际结果/容量见CONTEXT.json和context/{run}；原status快照可能滞后，实际终结日志优先。
  新代码是否写出、综合是否通过、布局布线是否通过、实物是否通过必须分别判断。

当前最短路线：
A. 帮用户在匹配板卡上人工JTAG下载031，收集实际画面/LED/按键/下载控制台反馈。
B. 在既有授权范围内整合现有模块，围绕真实资源报告调整容量和时序。
C. 若要补写尚缺的完整矩形/最终标注算法，先让用户明确这一扩展范围。

在原电脑接手：
原工作区 D:\大三\FPGA_verilog。
031英文路径 C:\Users\34528\FPGAEdgeLinks\Work\active\track4_board_debug_031_20261011。
主开发英文路径 C:\Users\34528\FPGAEdgeLinks\Work\active\track4_board_first_20261011。
工具路径 C:\Users\34528\FPGAEdgeLinks\Efinity2026_1。
先核对正在运行的编译，保留运行日志，不重复启动同一run或并发修改同一份源码。
context/build_scripts_reference 仅为现有脚本副本，其中有原电脑硬编码路径；不能直接在另一电脑盲跑。

在另一电脑接手：
把本包解压到英文路径，以work中的工程为独立快照查看；工具/许可证/下载器须另行具备。
不复制整套原始HDK、全部历史run、Efinity安装目录、驱动、许可证、账号凭据或聊天隐藏状态。
受保护IP保持厂商文件原样。原始资料的引用需回到原项目获取，包内没有的资料不能假定已经提供。

本包是时间点快照。接手前读原工作区最新状态，若已有新run/新用户反馈，以真实新证据更新判断。
MANIFEST.json列每份文件来源及SHA256；manifest本身不包含自身hash。
''')
write('PROMPT_FOR_CLAUDE_CODE.txt', fr'''请接手我的 FPGA 项目。原工作区是 D:\大三\FPGA_verilog。
交接包目录是：{folder}
请先阅读这个交接包里的 START_HERE.txt、CONTEXT.json、USER_SCOPE_AND_APPROVALS.txt，
再按 rules/project/AGENTS.md 的指引读取项目规则。若在原电脑工作，同时核对原控制面的最新状态。

确认硬件为 Ti60F225 DemoBoard V4 + SC431HAI，只使用板卡现有资源，允许现有DDR3。
031 是最新通过整机综合、布局布线、最终时序并生成比特流的版；完整复杂识别尚未完成。
包内开发源码冻结自 {run}，打包时结果为 {status.get('current_run_result')}；不得当作已验证上板版。

当前优先帮我使用031做人工上板测试、解释画面和按键、根据我的真实反馈定位问题。
其次只继续现有模块的整合、资源压缩、整机综合/布局布线/时序及比特流。
当前批次不新增中文草图或独立测试，不自动补写尚缺的新算法，不重复索取已明确给出的软件授权。
原始HDK、资料、历史run和登记产物保持只读。硬件下载、Flash烧写、调试器操作由我执行。
不自动安装/联网/升级IP/改数据库，不把软件编译通过当成实物效果通过。

先做只读接手核对，简要告诉我：当前可上板文件、主要未完成项、正在运行的编译、最短下一步。
之后在上述已授权的软件范围内继续。若发现原工作区有另一个AI正在写同一源码，先协调修改所有权。
''')

files = []
for path in sorted(folder.rglob('*')):
    if path.is_file():
        relative = path.relative_to(folder).as_posix()
        files.append({'relative': relative, 'bytes': path.stat().st_size, 'sha256': sha(path),
                      'source': provenance.get(relative, 'Generated handoff context; no RTL modifications')})
json_write('MANIFEST.json', {'created_at_utc': now.isoformat(), 'source_run': run, 'files': files})
archive = folder.with_suffix('.zip')
with zipfile.ZipFile(archive, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for path in sorted(folder.rglob('*')):
        if path.is_file():
            z.write(path, Path(folder.name) / path.relative_to(folder))
with zipfile.ZipFile(archive, 'r') as z:
    if z.testzip() is not None:
        raise RuntimeError('Archive CRC verification failed')
archive_sha = sha(archive)
archive.with_suffix('.zip.sha256.txt').write_text(archive_sha + '  ' + archive.name + '\n', encoding='ascii')
event = {
    'event_id': 'EV-AI-HANDOFF-' + local.strftime('%Y%m%d-%H%M%S'), 'project_id': 'FPGA_EDGE_TI60',
    'session_id': 'FAST-BATCH-20261008', 'at_utc': now.isoformat(), 'operation_id': 'CLAUDE-CODE-HANDOFF-EXPORT',
    'archive': str(archive), 'archive_sha256': archive_sha, 'source_snapshot_run': run,
    'latest_verified_run': 'board_compile_031', 'files': len(files) + 1,
    'archive_crc_passed': True, 'verified_031_bit_hash_matched': True,
    'source_code_modified': False, 'build_started': False, 'claude_invoked': False,
    'hardware_programming_performed': False, 'formal_database_or_hardware_state_changed': False,
}
with (control / 'runtime/events/2026/10/session-FAST-BATCH-20261008.jsonl').open('a', encoding='utf-8') as f:
    f.write(json.dumps(event, ensure_ascii=False) + '\n')
print(json.dumps({'folder': str(folder), 'zip': str(archive), 'zip_bytes': archive.stat().st_size,
                  'sha256': archive_sha, 'files': len(files) + 1, 'snapshot_run': run,
                  'source_hash_checks': len(checks), 'source_mismatches': len(source_mismatches)}, ensure_ascii=False))
