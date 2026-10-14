"""Publish measured acceptance status; never upgrades blocked items to success."""
from pathlib import Path
from datetime import datetime,timezone
import ast,csv,hashlib,json,re,sys
from urllib.parse import unquote
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'reports/audit/environment_acceptance'
sys.stdout.reconfigure(encoding='utf-8')
def save(path,obj):
    path.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

entries=[
('EF-01','Ti60 device/project and synthesis','CORE','PASS','20260923T084901Z_build_minimal_ascii/efinity_compile.log','ASCII alias required for this local layout'),
('EF-02','Interface PLL and pin generation','CORE','PASS','20260923T084901Z_build_minimal_ascii/efinity_compile.log','Reference VF LED configuration only'),
('EF-03','Placement and routing','CORE','PASS','20260923T084901Z_build_minimal_ascii/efinity_compile.log','Minimal design with two threads'),
('EF-04','Static timing report','CORE','PASS_LIMITED','20260923T084901Z_build_minimal_ascii/build_result.json','Internal clock setup 8.506ns hold 0.101ns; not board IO signoff'),
('EF-05','bit and hex generation and hashes','CORE','PASS','artifact_manifest.json','No hardware programming'),
('EF-06','Original debug insertion profile','OPTIONAL_DEBUG','FAIL','20260923T084809Z_build_compile_ascii/efinity_compile.log','Missing generated debug_top.v'),
('IP-01','FIFO 8.1 validate and generate','CORE','PASS','20260923T085741Z_ip_ascii/ip_generation_result.json','Generation only; simulation is a separate gate'),
('SIM-01','Plain LED HDL compilation','CORE','PASS','../environment_20260923/simulation_vlog.txt','Does not imply simulation license'),
('SIM-02','ModelSim simulation license checkout','CORE','BLOCKED','../environment_20260923/simulation_vsim.txt','Valid product license not configured'),
('SIM-03','Current vendor FIFO HDL compilation','CORE','FAIL','20260923T090001Z_fifo_compile/fifo_vlog.log','Old compiler syntax and protected model key errors'),
('SIM-04','Intentional syntax error detection','CORE','PASS','20260923T090001Z_fifo_compile/negative_syntax_compile.log','Expected nonzero code 2'),
('SIM-05','Behavior assertions and negative assertion','CORE','BLOCKED','../environment_20260923/simulation_probe.json','Needs working compatible simulator'),
('SIM-06','Waveform generation and viewing','CORE','BLOCKED','../environment_20260923/simulation_probe.json','No successful simulation yet'),
('SIM-07','Vendor primitive FIFO RAM simulation','CORE','BLOCKED','20260923T090001Z_fifo_compile/fifo_compile_result.json','Compatible simulator and valid license/models needed'),
('SIM-08','Mapped/post-route simulation','CORE','BLOCKED','20260923T090001Z_fifo_compile/fifo_compile_result.json','Simulator compatibility unresolved'),
('OBS-01','Event append and read','AGENT','PASS','20260923T084403Z_local/local_runtime_tests.json','Isolated test records'),
('OBS-02','Checkpoint read and hash','AGENT','PASS','20260923T084403Z_local/local_runtime_tests.json','Roundtrip only; not full runtime resume'),
('OBS-03','Artifact hash change detection','AGENT','PASS','20260923T084403Z_local/local_runtime_tests.json','Isolated altered file'),
('OBS-04','Alerts deduplication and report export','AGENT','PASS','20260923T084403Z_local/local_runtime_tests.json','MD CSV JSON HTML and missing DB/human gate alerts'),
('GATE-01','Reject illegal transition and missing observation','AGENT','FAIL','20260923T084403Z_local/local_runtime_tests.json','Event recorder accepts illegal transition; enforcement not implemented'),
('GATE-02','Approval pause/resume and side effect idempotency','AGENT','NOT_IMPLEMENTED','','Full execution layer not available; no successful test claimed'),
('DB-01','PostgreSQL connection schema migration and transaction','AGENT','BLOCKED','20260923T084403Z_local/local_runtime_tests.json','No URL/service/approved driver; no fallback used'),
('BOARD-01','Target DDR CSI and display IP configuration','TARGET_DEPENDENT','BLOCKED','','Actual hardware and modes undecided'),
('BOARD-02','Driver downloader and hardware observation','HUMAN_ONLY','BLOCKED','','No confirmed connected hardware; human programming mandatory'),
('GUI-01','Full GUI and waveform interaction','CORE','NOT_TESTED','','Command-line testing does not prove GUI interaction'),
('OPT-01','TinyML RISC-V C++ SDK','NOT_SELECTED','NOT_APPLICABLE','','Not selected for track 4 implementation'),
('OPT-02','Additional plugin MCP','NOT_REQUIRED','NOT_APPLICABLE','','No external plugin or MCP required for these probes'),
]
with (ROOT/'validation/ENVIRONMENT_ACCEPTANCE_MATRIX.csv').open('w',encoding='utf-8-sig',newline='') as handle:
    writer=csv.writer(handle);writer.writerow(['test_id','function','scope','status','evidence_relative_to_report','limitation']);writer.writerows(entries)
build=ROOT/'work/active/environment_acceptance/20260923T084901Z_build_minimal_ascii'
artifacts=[]
for suffix in ['bit','hex']:
    path=build/'outflow'/('LED_8bit_Test.'+suffix)
    artifacts.append(dict(artifact_id='ENV-LED-'+suffix.upper(),path=str(path),size=path.stat().st_size,
        sha256=hashlib.sha256(path.read_bytes()).hexdigest(),node_id='H0_BASELINE',
        purpose='ENVIRONMENT_SMOKE_ONLY',state='WAITING_HUMAN_PROGRAM',hardware_programmed=False,
        deployable_to_confirmed_hardware=False))
save(OUT/'artifact_manifest.json',dict(artifacts=artifacts,readiness='NOT_ACCEPTED',original_build_manifest_alias_paths='temporary alias; use these physical paths'))
state_path=ROOT/'state/PROJECT_STATE.json'
state=json.loads(state_path.read_text(encoding='utf-8'))
state['environment_check'].update(status='NOT_ACCEPTED',efinity_full_build='PASS_MINIMAL_LED_DEBUG_DISABLED',
    efinity_original_debug_profile='FAIL_MISSING_GENERATED_FILE',efinity_fifo_generation='PASS',
    modelsim_vendor_fifo_compile='FAIL_SYNTAX_AND_PROTECTED_KEY',
    modelsim_simulation='BLOCKED_LICENSE',runtime_illegal_transition_guard='FAIL',database_connected=False,
    report='reports/audit/environment_acceptance/ENVIRONMENT_ACCEPTANCE.md')
state['environment_check']['artifact_manifest']='reports/audit/environment_acceptance/artifact_manifest.json'
state['updated_at']=datetime.now(timezone.utc).isoformat()
save(state_path,state)
save(OUT/'test_authorization.json',dict(at=state['updated_at'],source='User instruction to search license resolution and run all necessary minimum software tests',
    authorized=['official_documentation_search','local_environment_diagnostics','isolated_work_copy','minimal_efinity_build','temporary_ascii_drive_alias','local_test_reports'],
    not_authorized=['new_tool_download_install','hardware_programming','database_provisioning','license_bypass']))

# Validate evidence links and Python parsing without executing tools again.
errors=[]
for entry in entries:
    if entry[4] and not (OUT/entry[4]).is_file(): errors.append('missing evidence '+entry[0])
for path in [ROOT/'operations/environment_acceptance.py',ROOT/'operations/ip_generation_smoke.py',Path(__file__)]:
    ast.parse(path.read_text(encoding='utf-8'))
for name in ['ENVIRONMENT_ACCEPTANCE.md']:
    path=OUT/name
    for target in re.findall(r'\[[^\]]+\]\(([^)]+)\)',path.read_text(encoding='utf-8')):
        if not (path.parent/unquote(target)).exists(): errors.append('broken link '+target)
save(OUT/'acceptance_index.json',dict(at=state['updated_at'],overall='NOT_ACCEPTED',tests=len(entries),
    test_counts={status:sum(item[3]==status for item in entries) for status in sorted({x[3] for x in entries})},
    evidence_integrity_errors=errors,downloads_performed=False,hardware_programmed=False))
print(json.dumps(dict(overall='NOT_ACCEPTED',tests=len(entries),evidence_errors=errors),ensure_ascii=False))
raise SystemExit(1 if errors else 0)
