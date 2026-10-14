"""One-time control-plane bookkeeping. No database, install or hardware access."""
import csv
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / 'reports/audit/environment_20260923'

def main():
    current = json.loads((ROOT / 'state/PROJECT_STATE.json').read_text(encoding='utf-8'))
    if current.get('competition', {}).get('track') == 4:
        print('Track 4 bookkeeping already applied; preserving current progress.')
        return
    ledger = ROOT / 'state/TASK_LEDGER.csv'
    backup = AUDIT / 'TASK_LEDGER.before_track4.csv'
    if not backup.exists():
        backup.write_bytes(ledger.read_bytes())
    fields = ['task_id','node_id','title','status','owner','source_ref','build_ref',
              'artifact_ref','observation_ref','approval_ref','started_at','completed_at','notes']
    nodes = [
        ('H0_BASELINE','Confirm environment and physical baseline'),
        ('H1_DISPLAY_BASELINE','HDMI test pattern and display baseline'),
        ('H2_CAMERA_STREAM','Camera configuration capture and passthrough'),
        ('H3_GRAYSCALE','Fixed point grayscale pipeline'),
        ('H4_WINDOW_AND_SOBEL','Two line buffer 3x3 window and Sobel'),
        ('H5_THRESHOLD_DISPLAY','Threshold and grayscale edge comparison'),
        ('A1_MEDIAN_FILTER','Parallel 3x3 median filter'),
        ('A2_LIVE_THRESHOLD','Debounced live threshold control'),
        ('A3_DDR_FRAMEBUFFER','DDR frame buffer freeze and resume'),
        ('A4_CANNY','Full Canny pipeline including hysteresis'),
        ('A5_COLOR_OVERLAY','Aligned color edge overlay'),
        ('A6_SHAPE_RECOGNITION','Edge based shape recognition and labels'),
        ('R0_RELEASE','Integrated regression and release evidence'),
    ]
    # Do not reuse malformed legacy column positions as approvals or observations.
    with ledger.open('w', encoding='utf-8', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for node_id, title in nodes:
            writer.writerow(dict(task_id='TASK-'+node_id.split('_')[0], node_id=node_id,
                title=title, status='IN_PROGRESS' if node_id=='H0_BASELINE' else 'NOT_STARTED',
                owner='human_and_agent',source_ref='docs/workflows/TRACK4_WORKFLOW.md',
                notes='VF reference only; actual hardware undecided; simulation license blocked'
                      if node_id=='H0_BASELINE' else 'Planned; no hardware acceptance evidence'))
    path = ROOT / 'state/PROJECT_STATE.json'
    state = json.loads(path.read_text(encoding='utf-8'))
    state['competition'] = dict(track=4, scope='basic_and_six_advanced_planned',
                                requirements='docs/requirements/TRACK4_REQUIREMENTS.csv')
    state['environment_reference'] = dict(board='VF-Ti60F225',
        user_confirmed_reference_only=True, physical_hardware='UNDECIDED')
    state['environment_check'] = dict(at='2026-09-23',status='PARTIAL_BLOCKED',
        efinity_dependency_imports='PASS',efinity_cli_parser='PASS',
        efinity_full_build='NOT_RUN',modelsim_hdl_compile='PASS',
        modelsim_simulation='BLOCKED_INVALID_LICENSE_ENVIRONMENT',
        database_connected=False,report='reports/audit/environment_20260923/ENVIRONMENT_READINESS.md')
    state['database']['health'] = 'NOT_CONFIGURED'
    state['updated_at'] = datetime.now(timezone.utc).isoformat()
    path.write_text(json.dumps(state,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Updated track 4 ledger and state; hardware baseline remains unconfirmed.')

if __name__ == '__main__':
    main()
