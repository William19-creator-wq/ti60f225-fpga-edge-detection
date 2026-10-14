"""Validate review outputs using existing local tools; no downloads or DB calls."""
import csv
import hashlib
import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / 'reports/audit/environment_20260923'
EF = ROOT.parent / 'efinity-2026.1.132-windows-x64.tar/efinity-2026.1.132-windows-x64/efinity/2026.1'

def main():
    checks, errors = [], []
    docs = [ROOT / path for path in [
        'README.md','planning/CURRENT_PLAN.md','docs/WORKFLOW.md',
        'docs/workflows/TRACK4_WORKFLOW.md','docs/requirements/TRACK4_REQUIREMENTS.md',
        'docs/requirements/HARDWARE_AND_TOOLCHAIN_EVIDENCE.md',
        'reports/audit/environment_20260923/ENVIRONMENT_READINESS.md']]
    link_count = 0
    for doc in docs:
        data = doc.read_text(encoding='utf-8')
        targets = re.findall(r'\[[^\]\n]*\]\(([^\n)]*)\)', data)
        targets += re.findall(r'^\[[^\]]+\]:\s*(\S+)', data, re.M)
        for target in targets:
            target = unquote(target.strip('<>').split('#')[0])
            if not target or re.match(r'^https?://', target):
                continue
            link_count += 1
            if not (doc.parent / target).exists():
                errors.append(f'broken link {doc.name}: {target}')
    checks.append(dict(check='document_links', checked=link_count))
    for name in ['state/TASK_LEDGER.csv','docs/requirements/TRACK4_REQUIREMENTS.csv']:
        with (ROOT/name).open(encoding='utf-8',newline='') as handle:
            rows=list(csv.reader(handle))
        if any(len(row)!=len(rows[0]) for row in rows):
            errors.append(f'CSV column mismatch: {name}')
        checks.append(dict(check=name,rows=len(rows)-1,columns=len(rows[0])))
    json_paths = [ROOT/'state/PROJECT_STATE.json', *AUDIT.glob('*.json'), AUDIT/'pdf_evidence/reading_ledger.json']
    for path in json_paths:
        json.loads(path.read_text(encoding='utf-8-sig'))
    checks.append(dict(check='json_parse',files=len(json_paths)))
    source_manifest=json.loads((ROOT/'work/active/environment_probe_20260923/SOURCE_MANIFEST.json').read_text(encoding='utf-8'))
    for item in source_manifest:
        for key in ['source','copy']:
            if hashlib.sha256(Path(item[key]).read_bytes()).hexdigest()!=item['sha256']:
                errors.append(f'baseline hash mismatch: {item[key]}')
    checks.append(dict(check='original_and_copied_LED_hashes',files=len(source_manifest)*2))
    # Use PyYAML already bundled by Efinity, with a subprocess-only environment.
    env=os.environ.copy()
    env['PYTHONHOME']=str(EF/'python311')
    env['PYTHONDONTWRITEBYTECODE']='1'
    code="import pathlib,sys,yaml; paths=list(pathlib.Path(sys.argv[1]).glob('*.yaml')); [yaml.safe_load(p.read_text(encoding='utf-8')) for p in paths]; print('YAML_PARSE_PASS files='+str(len(paths)))"
    result=subprocess.run([str(EF/'python311/bin/python.exe'),'-B','-c',code,str(ROOT/'config')],
                          cwd=ROOT,env=env,capture_output=True,text=True,timeout=60)
    if result.returncode:
        errors.append('Existing Efinity PyYAML parser failed')
    checks.append(dict(check='config_yaml_parse',returncode=result.returncode,output=result.stdout.strip()))
    report=dict(at=datetime.now(timezone.utc).isoformat(),checks=checks,errors=errors,
                passed=not errors,scope='Local static review only; no FPGA build, hardware or database acceptance')
    (AUDIT/'review_validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,ensure_ascii=True,indent=2))
    return 1 if errors else 0

if __name__=='__main__':
    raise SystemExit(main())
