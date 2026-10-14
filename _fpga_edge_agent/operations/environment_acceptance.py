"""Bounded local acceptance probes; never programs hardware or installs tools."""
from pathlib import Path
from datetime import datetime, timezone
import argparse, csv, hashlib, json, os, shutil, subprocess, sys, time
sys.stdout.reconfigure(encoding='utf-8')

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT.parent
EF = PROJECT/'efinity-2026.1.132-windows-x64.tar/efinity-2026.1.132-windows-x64/efinity/2026.1'
MODEL = Path(r'D:\modelism_\modelsim\Modelsim 10.1c\Modelsim 10.1c\win64')

def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def save(path, data):
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def environment(work, ef=EF):
    env=os.environ.copy()
    env.update(EFINITY_HOME=str(ef).replace('\\','/'), EFXPT_HOME=str(ef/'pt'),
        EFXPGM_HOME=str(ef/'pgm'), EFXDBG_HOME=str(ef/'debugger'), EFXIPM_HOME=str(ef/'ipm'),
        PYTHONHOME=str(ef/'python311'), PYTHONPATH=str(ef/'scripts'), PYTHONDONTWRITEBYTECODE='1',
        EFINITY_USER_DIR_INI=str(work/'user_dir.ini'),EFINITY_USER_DIR=str(work/'efinity_user'),PYTHONIOENCODING='utf-8')
    env['PATH']=os.pathsep.join(str(ef/p) for p in ['python311/bin','bin','pgm/bin','scripts'])+os.pathsep+env.get('PATH','')
    (work/'user_dir.ini').write_text('[General]\nEFINITY_USER_DIR='+str(work/'efinity_user').replace('\\','/')+'\n',encoding='utf-8')
    return env

def run_logged(name,args,work,out,env=None,timeout=600):
    start=time.monotonic()
    with (out/(name+'.log')).open('wb') as log:
        proc=subprocess.Popen([str(x) for x in args],cwd=work,env=env,stdout=log,stderr=subprocess.STDOUT)
        try:
            code=proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            subprocess.run(['taskkill','/PID',str(proc.pid),'/T','/F'],capture_output=True)
            code='TIMEOUT'
    record=dict(name=name,returncode=code,seconds=round(time.monotonic()-start,3),log=str(out/(name+'.log')))
    print(json.dumps(record),flush=True)
    save(out/(name+'.json'),record)
    return record

def build(work,out,ef=EF,complete=False,minimal=False):
    hdk=next(PROJECT.glob('VF-Ti60F225_HDK*文件包'))/'VF-Ti60F225_HDK_V2.1_20251009/VF-Ti60F225_HDK_V2.1_20251009'
    source=hdk/'06-FPGA_HDL_Basic-2023.2/01_LED_8bit_Test'
    manifest=[]
    for item in source.rglob('*'):
        if not item.is_file(): continue
        relative=item.relative_to(source)
        if relative.parts[0] not in ('src','ip') and relative.as_posix() not in ('LED_8bit_Test.xml','LED_8bit_Test.peri.xml','VIP_System.sdc','debug_profile.wizard.json'):
            continue
        dest=work/relative
        dest.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(item,dest)
        manifest.append(dict(source=str(item),copy=str(dest.resolve()),sha256=digest(item)))
    save(out/'source_manifest.json',manifest)
    # Only resource scheduling differs from reference; RTL and pin assignments untouched.
    project=work/'LED_8bit_Test.xml'
    before=project.read_text(encoding='utf-8')
    after=before.replace('name="max_threads" value="-1"','name="max_threads" value="2"')
    if minimal:
        after=after.replace('name="auto_instantiation" value="on"','name="auto_instantiation" value="off"')
    project.write_text(after,encoding='utf-8')
    import difflib
    (out/'project.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='baseline.xml',tofile='work_copy.xml')),encoding='utf-8')
    save(out/'work_copy_changes.json',dict(change='max_threads -1 to 2',debug_insertion_disabled=minimal,reason='bound memory; minimal LED build excludes hardware debug core',hardware_profile='unconfirmed reference only'))
    env=environment(work,ef)
    stages=[]
    for stage in (['compile'] if complete else ['map','interface','pnr','pgm']):
        record=run_logged('efinity_'+stage,[ef/'python311/bin/python.exe','-B',ef/'scripts/efx_run.py','LED_8bit_Test.xml','--flow',stage],work,out,env)
        stages.append(record)
        if record['returncode']!=0: break
    artifacts=[dict(path=str(p.resolve()),size=p.stat().st_size,sha256=digest(p),hardware_programmed=False)
               for p in work.rglob('*') if p.is_file() and p.suffix in ('.bit','.hex')]
    passed=len(stages)==(1 if complete else 4) and all(x['returncode']==0 for x in stages) and bool(artifacts)
    save(out/'build_result.json',dict(stages=stages,artifacts=artifacts,hardware_programmed=False,passed=passed))
    save(out/'source_integrity_after.json',[dict(source=x['source'],unchanged=digest(x['source'])==x['sha256']) for x in manifest])
    return 0 if passed else 1

def license_probe(work,out):
    import winreg
    names=['LM_LICENSE_FILE','MGLS_LICENSE_FILE','SALT_LICENSE_SERVER']
    def summary(value):
        return dict(present=bool(value),kind='server' if value and '@' in value else ('path' if value else 'unset'),
                    target_exists=Path(value).exists() if value and '@' not in value and ';' not in value else None)
    facts={'environment':{name:summary(os.environ.get(name)) for name in names},'registry':[]}
    for hive,label in [(winreg.HKEY_CURRENT_USER,'USER'),(winreg.HKEY_LOCAL_MACHINE,'MACHINE')]:
        for key in [r'Software\FLEXlm License Manager',r'SOFTWARE\WOW6432Node\FLEXlm License Manager']:
            try:
                with winreg.OpenKey(hive,key) as handle:
                    for name in names:
                        try:
                            value,_=winreg.QueryValueEx(handle,name)
                            facts['registry'].append(dict(scope=label,name=name,**summary(value)))
                        except FileNotFoundError: pass
            except FileNotFoundError: pass
    # Known normal license locations only; no activation utilities or license content read.
    locations=[MODEL.parent/'license.dat',MODEL.parent/'licenses/eda/license.dat',Path(r'C:\flexlm\license.dat')]
    facts['default_file_presence']=[dict(location=str(p),present=p.is_file()) for p in locations]
    facts['scanned_candidates']=[]
    for base in [MODEL.parent,Path(r'C:\flexlm'),Path(r'C:\MentorGraphics\Licensing')]:
        if not base.is_dir(): continue
        for folder,dirs,files in os.walk(base):
            dirs[:]=[d for d in dirs if d.lower() not in ('crack','docs','examples','tcl','verilog_src','vhdl_src')]
            for name in files:
                if name.lower() in ('license.dat','mgc.licenses') or name.lower().endswith('.lic'):
                    facts['scanned_candidates'].append(str(Path(folder)/name))
    # Diagnostics print summaries only; keep any source values out of records.
    result=subprocess.run([str(MODEL/'lmutil.exe'),'lmdiag','-n'],cwd=work,capture_output=True,timeout=20)
    output=(result.stdout+result.stderr).decode('utf-8',errors='replace')
    facts['lmdiag']={'returncode':result.returncode,'missing_license_file':('Cannot find license file' in output),
        'no_such_file':('No such file' in output),'error_codes':[line.strip() for line in output.splitlines() if 'FlexNet Licensing error:' in line]}
    save(out/'license_diagnosis.json',facts)
    print(json.dumps(facts,ensure_ascii=True,indent=2))
    return 2  # Diagnosis alone never establishes simulation license checkout.

def ip_probe(work,out,ef=EF):
    baseline=ROOT/'work/active/environment_acceptance/20260923T084901Z_build_minimal_ascii'
    for name in ['LED_8bit_Test.xml','LED_8bit_Test.peri.xml']:
        shutil.copyfile(baseline/name,work/name)
    hashes=[]
    for name in ['efx_fifo_2','efx_bram','common']:
        source=ef/'ipm/ip'/name
        shutil.copytree(source,work/'ip_library'/name)
        hashes.extend(dict(path=str(p.resolve()),sha256=digest(p)) for p in source.rglob('*') if p.is_file())
    record=run_logged('ip_fifo_generation',[ef/'python311/bin/python.exe','-B',ROOT/'operations/ip_generation_smoke.py',work],work,out,environment(work,ef),timeout=240)
    if (work/'ip_generation_result.json').is_file():
        shutil.copyfile(work/'ip_generation_result.json',out/'ip_generation_result.json')
    save(out/'vendor_library_integrity.json',dict(files=len(hashes),all_unchanged=all(digest(x['path'])==x['sha256'] for x in hashes)))
    return 0 if record['returncode']==0 else 1

def fifo_compile(work,out):
    source=ROOT/'work/active/environment_acceptance/20260923T085741Z_ip_ascii/ip/smoke_fifo/Testbench'
    for p in source.iterdir():
        if p.is_file(): shutil.copyfile(p,work/p.name)
    records=[]
    for name,args in [('fifo_vlib',[MODEL/'vlib.exe','work']),
                      ('fifo_vlog',[MODEL/'vlog.exe','-sv','fifo_tb.sv','smoke_fifo.sv'])]:
        record=run_logged(name,args,work,out,timeout=60)
        records.append(record)
        if record['returncode']!=0: break
    (work/'intentional_syntax_error.v').write_text('module intentional_syntax_error( THIS_IS_INVALID ;\n',encoding='ascii')
    negative=run_logged('negative_syntax_compile',[MODEL/'vlog.exe','intentional_syntax_error.v'],work,out,timeout=30)
    save(out/'fifo_compile_result.json',dict(compilation=records,compile_passed=len(records)==2 and records[-1]['returncode']==0,
         intentional_error_detected=negative['returncode'] not in (0,'TIMEOUT'),simulation_passed=False))
    return 0 if records[-1]['returncode']==0 and negative['returncode'] not in (0,'TIMEOUT') else 1

def local_tests(work,out):
    sys.path.insert(0,str(ROOT/'runtime'))
    import agent_runtime as runtime
    import generate_reports as reports
    runtime.EVENT_ROOT=work/'runtime/events'
    runtime.CHECKPOINT_ROOT=work/'runtime/checkpoints'
    reports.ROOT=work
    reports.EVENT_ROOT=runtime.EVENT_ROOT
    reports.REPORT_ROOT=work/'reports'
    reports.ALERT_ROOT=work/'runtime/local_archive'
    (work/'state').mkdir(parents=True,exist_ok=True)
    shutil.copyfile(ROOT/'state/TASK_LEDGER.csv',work/'state/TASK_LEDGER.csv')
    shutil.copyfile(ROOT/'state/PROJECT_STATE.json',work/'state/PROJECT_STATE.json')
    results=[]
    def check(name,condition):
        results.append(dict(name=name,status='PASS' if condition else 'FAIL'))
    event=dict(event_id='SMOKE-E1',project_id='FPGA_EDGE_TI60',session_id='SMOKE',turn_id='T1',operation_id='OP1',
        artifact_id='A1',node_id='H0_BASELINE',event_type='SMOKE_ONLY',schema_version='1.0',occurred_at=runtime.utc_now(),
        state_before='ARTIFACT_READY',state_after='WAITING_HUMAN_PROGRAM',payload={'simulation':True})
    path=runtime.append_event(event)
    first=path.read_bytes()
    runtime.append_event({**event,'event_id':'SMOKE-E2','state_before':'WAITING_HUMAN_PROGRAM','state_after':'WAITING_HUMAN_OBSERVATION'})
    records=[json.loads(line) for line in path.read_text(encoding='utf-8').splitlines()]
    check('event_append_read',path.read_bytes().startswith(first) and len(records)==2 and records[1]['event_id']=='SMOKE-E2')
    checkpoint=runtime.write_checkpoint(dict(checkpoint_id='SMOKE-CP1',session_id='SMOKE',turn_id='T1',last_event_id='SMOKE-E2',state='WAITING_HUMAN_OBSERVATION'))
    restored=json.loads(checkpoint.read_text(encoding='utf-8'))
    recorded_hash=restored.pop('content_hash')
    check('checkpoint_roundtrip_and_hash',restored['last_event_id']=='SMOKE-E2' and hashlib.sha256(json.dumps(restored,ensure_ascii=False,sort_keys=True,indent=2).encode()).hexdigest()==recorded_hash)
    before=runtime.sha256_file(checkpoint)
    (work/'modified_artifact.txt').write_text(checkpoint.read_text(encoding='utf-8')+'\n',encoding='utf-8')
    check('artifact_hash_change_detection',runtime.sha256_file(work/'modified_artifact.txt')!=before)
    db=runtime.database_health()
    check('database_missing_config_detection',not db['configured'] and db['status']=='UNAVAILABLE')
    loaded=reports.load_events()
    alerts=reports.derive_alerts(loaded)
    check('human_wait_and_database_alert_generation',{'DATABASE_UNAVAILABLE','HUMAN_GATE_PENDING'} <= {x['alert_type'] for x in alerts})
    reports.append_alerts(alerts)
    alerts_path=reports.ALERT_ROOT/'alerts.jsonl'
    old=alerts_path.read_bytes()
    reports.append_alerts(alerts)
    check('alert_deduplication',alerts_path.read_bytes()==old)
    reports.write_reports(loaded)
    check('report_files_generated',bool(list((work/'reports').rglob('*.md'))) and bool(list((work/'reports').rglob('*.csv'))) and bool(list((work/'reports').rglob('*.html'))))
    # Guardrail negative probe: does the runtime really reject an illegal hardware transition?
    try:
        runtime.append_event({**event,'event_id':'SMOKE-ILLEGAL','state_before':'READY','state_after':'PASSED','payload':{'no_observation':True,'test_only':True}})
        check('illegal_state_and_missing_observation_rejected',False)
    except (ValueError,RuntimeError): check('illegal_state_and_missing_observation_rejected',True)
    save(out/'local_runtime_tests.json',dict(results=results,database_connection='NOT_ATTEMPTED_NO_URL',
        test_records_isolated=True,full_runtime_accepted=False))
    print(json.dumps(results,indent=2))
    return 0 if all(item['status']=='PASS' for item in results) else 1

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('mode',choices=['build','build_ascii','build_compile_ascii','build_minimal_ascii','ip_ascii','fifo_compile','license','local'])
    args=parser.parse_args()
    tag=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'_'+args.mode
    work=ROOT/'work/active/environment_acceptance'/tag
    out=ROOT/'reports/audit/environment_acceptance'/tag
    work.mkdir(parents=True,exist_ok=False);out.mkdir(parents=True,exist_ok=False)
    print('OUTPUT='+str(out),flush=True)
    if args.mode in ('build_ascii','build_compile_ascii','build_minimal_ascii','ip_ascii'):
        import ctypes
        drive=None
        for letter in 'RSTUVWXYZ':
            buffer=ctypes.create_unicode_buffer(4096)
            if not ctypes.windll.kernel32.QueryDosDeviceW(letter+':',buffer,4096):
                drive=letter+':'
                break
        if not drive: raise RuntimeError('No unused drive for temporary ASCII alias')
        subprocess.run(['subst',drive,str(PROJECT)],check=True,capture_output=True)
        try:
            alias=Path(drive+'/')
            # Mapping points to the existing project; only the owned work subtree is writable.
            if args.mode=='ip_ascii':
                status=ip_probe(alias/work.relative_to(PROJECT),out,alias/EF.relative_to(PROJECT))
            else:
                status=build(alias/work.relative_to(PROJECT),out,alias/EF.relative_to(PROJECT),complete=args.mode!='build_ascii',minimal=args.mode=='build_minimal_ascii')
        finally:
            subprocess.run(['subst',drive,'/D'],check=True,capture_output=True)
    else:
        status={'build':build,'license':license_probe,'local':local_tests,'fifo_compile':fifo_compile}[args.mode](work,out)
    raise SystemExit(status)
