"""FAST: 实际物理报告审核与只增不覆盖的本地登记。草图见../sta-script-change-v1.md。"""
import argparse
import csv
import hashlib
import io
import json
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path

CONTROL = Path('D:/大三/FPGA_verilog/_fpga_edge_agent')
WORK = CONTROL / 'work/active/track4_algorithms_20261004'
PACKAGES = {
    'stats': ('r4_stats','stats_probe',22,56000,0,32,'TRACK4-ALGORITHM-R4-STATS-001','ALGORITHM-R4-STATS'),
    'angle': ('r3_angle','angle_probe',20,24000,2,8,'TRACK4-ALGORITHM-R3-ANGLE-001','ALGORITHM-R3-ANGLE'),
}

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest().upper()

def read_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))

def write_json(path, value):
    path = Path(path)
    if path.exists():
        raise FileExistsError(f'preserve existing record: {path}')
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

def utc():
    return datetime.now(timezone.utc).isoformat()

def require(condition, message):
    if not condition:
        raise AssertionError(message)

def stage_pass(root, stage):
    result = read_json(root / f'{stage}.result.json')
    require(result['exit_code'] == 0 and result['timed_out'] is False, f'{stage} not passed')

def verify_ram(mapfile, source):
    text = mapfile.read_text(encoding='utf-8', errors='replace')
    result = {}
    for name, filename in (('boundary','angle_boundary.mem'),('coefficient','projection_coeff.mem')):
        match = re.search(r'EFX_RAM10\s+\\arithmetic/constants/'+name+r'\s+(.+?);', text, re.S)
        require(match is not None, f'mapped ROM {name} missing')
        fields = dict((int(i,16),int(v,16)) for i,v in re.findall(r'INIT_([0-9A-F]+)=256\x27h([0-9a-fA-F]+)', match[1]))
        require(set(fields) == set(range(40)), f'ROM {name} not 40x256 init bits')
        packed = sum(v << (256*i) for i,v in fields.items())
        words = [int(line,16) for line in (source / filename).read_text().splitlines()]
        require(len(words) == 512, 'ROM source not 512 words')
        actual = [(packed >> (20*i)) & ((1 << 20)-1) for i in range(512)]
        require(actual == words, f'mapped INIT differs from .mem: {name}')
        result[name] = {'words':512, 'source_sha256':sha(source / filename), 'mapped_init_exact':True}
    return result

def review(kind, run_name):
    folder, circuit, count, max_xlr, exact_ram, max_dsp, _, _ = PACKAGES[kind]
    root = WORK / folder / 'runs' / run_name
    for stage in ('Map','Interface','Pnr','Sta'):
        stage_pass(root, stage)
    snapshot_path = root / 'snapshot-manifest.json'
    snapshot = read_json(snapshot_path)
    require(len(snapshot['files']) == count, 'source count differs')
    for file in snapshot['files']:
        require(sha(file['path']) == file['sha256'] and sha(file['snapshot']) == file['sha256'], 'source snapshot drift')
    simulation = WORK / folder / 'runs' / snapshot['simulation_run']
    suite = read_json(simulation / 'suite-result.json')
    require(suite['status'] == 'PASS' and suite['finished'] is True and suite['suite'] == 'All','simulation missing')
    flow, sta = root / 'flow/outflow', root / 'sta/outflow'
    script = (root / 'snapshot/scripts/postroute.tcl').read_text(encoding='utf-8')
    groups = re.findall(r'\[list ([a-z][a-z0-9_]+) \[list',script)
    require(len(groups) == (18 if kind == 'stats' else 19), 'unexpected transition coverage')
    groups += ['q1_d2','q2_core']
    if kind == 'angle':
        groups += ['all_registers']
    path_review = []
    evidence = []
    for group in groups:
        for analysis in ('setup','hold'):
            path = sta / f'{kind}_{group}_{analysis}.rpt'
            text = path.read_text(encoding='utf-8')
            slacks = [float(s) for s in re.findall(r'Slack\s*:\s*([-+\d.]+)\s*ns',text)]
            endpoints = re.findall(r'Path End\s*:\s*(\S+)',text)
            require(slacks and endpoints and min(slacks) >= 0, f'empty/failing real paths: {path.name}')
            if group == 'cross_to_search_enable':
                require(all('|CE' in e for e in endpoints),'cross control must end at CE')
            elif group not in ('q2_core','all_registers'):
                require(all(any(p in e for p in ('|D','|A[','|B[','|C[','|CASCIN[','|RADDR[')) for e in endpoints),
                        f'nondata endpoint {group}')
            path_review.append({'report':path.name,'paths':len(slacks),'min_slack_ns':min(slacks),
                                'endpoint_role':'control_enable' if group == 'cross_to_search_enable' else 'data_or_reset',
                                'endpoints':endpoints})
            evidence.append(path)
    coverage = sta / f'{kind}_internal_coverage.rpt'
    coverage_text = coverage.read_text(encoding='utf-8')
    for name in ('no_clock','unconstrained_internal_endpoints','multiple_clock'):
        require(re.search(r'checking '+name+r' \(0\)',coverage_text), f'internal timing issue: {name}')
    timing = flow / f'{circuit}.timing.rpt'
    text = timing.read_text(encoding='utf-8')
    require('Timing Model: I3' in text and re.search(r'core_25m\s+40\.000\s+25\.000',text), 'clock/model differs')
    sections = re.search(r'Setup \(Max\) Clock Relationship(.+?)Hold \(Min\) Clock Relationship(.+?)NOTE:',text,re.S)
    require(sections is not None,'timing summary missing')
    values = []
    for section in sections.groups():
        match = re.search(r'core_25m\s+core_25m\s+[\d.]+\s+([-+\d.]+)',section)
        require(match is not None,'clock relationship missing')
        values.append(float(match[1]))
    require(min(values) >= 0,'global setup or hold failed')
    resource = flow / f'{circuit}.place.rpt'
    resource_text = resource.read_text()
    xlr, ram, dsp = (int(re.search(label+r':\s*(\d+)\s*/',resource_text)[1]) for label in ('XLRs','Memory Blocks','DSP Blocks'))
    require(xlr <= max_xlr and ram == exact_ram and dsp <= max_dsp, 'resource budget exceeded')
    pinout = flow / f'{circuit}.pinout.csv'
    pintext = pinout.read_text(encoding='utf-8')
    rows = csv.DictReader(io.StringIO(pintext[pintext.index('Pin Number,'):]))
    actual = {r['Pin Number']:r for r in rows if r['Signal Name']}
    expected = {'J2':('clk_25m.P','1A','1.8 V'),'P13':('key1_n','BR','3.3 V'),
                'N14':('led0','BR','3.3 V'),'P14':('led1','BR','3.3 V')}
    require(set(actual) == set(expected), 'unexpected active pins')
    for pin,(signal,bank,voltage) in expected.items():
        r = actual[pin]
        require((r['Signal Name'],r['Bank'],r['I/O Bank Voltage']) == (signal,bank,voltage),f'pin differs: {pin}')
    require('GCLK' in actual['J2']['Function'],'clock pin lacks GCLK')
    pt = flow / f'{circuit}.pt.rpt'
    pttext = pt.read_text()
    for led in ('led0','led1'):
        require(re.search(r'\|\s*'+led+r'\s*\|\s*'+led+r'\s*\|[^\n]*\|\s*4\s*\|',pttext),f'{led} drive not4mA')
    ram_proof = verify_ram(flow / f'{circuit}.map.v',root / 'snapshot/rtl') if kind == 'angle' else {}
    proof = {'status':'PASS','path_reports':path_review,'ram_initialization':ram_proof,
             'pin_review':'PASS','global_setup_ns':values[0],'global_hold_ns':values[1],
             'xlr':xlr,'ram':ram,'dsp':dsp,'tooling_only_revision':True,
             'warning_review':('RAM INITs match all1024 words; coefficient_index10->9 narrowing is within1..128 after CHECK/PREP branch' if kind == 'angle' else 'optional FF aliases may not resolve; actual mapped DSP and data path reports are nonempty'),
             'hardware_status':'NOT_RUN','production_clock_verified':False}
    reviewfile = root / 'physical-review.json'
    write_json(reviewfile,proof)
    evidence += [coverage,timing,resource,pinout,pt,flow / f'{circuit}.warn.log',
                 flow / f'{circuit}.troutingtraces',root / 'snapshot/scripts/postroute.tcl',reviewfile]
    if kind == 'angle':
        evidence += [flow / f'{circuit}.map.v',root / 'snapshot/rtl/angle_boundary.mem',root / 'snapshot/rtl/projection_coeff.mem']
    gate = {'status':'PASS','setup_pass':True,'hold_pass':True,'worst_setup_ns':values[0],'worst_hold_ns':values[1],
            'internal_unconstrained':0,'no_clock':0,'multiple_clock':0,'pin_review':'PASS','data_path_review':'PASS',
            'xlr':xlr,'ram':ram,'dsp':dsp,'device':'Ti60F225','timing_model':'I3','clock_mhz':25,
            'snapshot_sha256':sha(snapshot_path),'routed_lbf_sha256':sha(root / f'flow/work_pnr/{circuit}.lbf'),
            'evidence':[{'path':str(p),'sha256':sha(p)} for p in evidence],
            'hardware_status':'NOT_RUN','full_project_goal_complete':False}
    write_json(root / 'release-gate.json',gate)
    print(json.dumps({'kind':kind,'run':run_name,'status':'PASS','reports':len(path_review),'xlr':xlr,'ram':ram,'dsp':dsp}))

def register(kind, run_name, revision):
    folder,circuit,count,_,_,_,task,prefix = PACKAGES[kind]
    root = WORK / folder / 'runs' / run_name
    stage_pass(root,'Bit')
    gate = read_json(root / 'release-gate.json')
    require(gate['status'] == 'PASS','release gate missing')
    for proof in gate['evidence']:
        require(sha(proof['path']) == proof['sha256'],'proof drift')
    snapshot = read_json(root / 'snapshot-manifest.json')
    require(sha(root / 'snapshot-manifest.json') == gate['snapshot_sha256'],'snapshot manifest drift')
    require(sha(root / f'flow/work_pnr/{circuit}.lbf') == gate['routed_lbf_sha256'],'LBF drift')
    for entry in snapshot['files']:
        require(sha(entry['path']) == entry['sha256'] and sha(entry['snapshot']) == entry['sha256'],'source drift')
    artifact = prefix+'-20261008-'+revision
    destination = CONTROL / 'artifacts/staging' / artifact
    require(not destination.exists(), 'preserve registered artifacts')
    for suffix in ('bit','hex'):
        path = root / f'flow/outflow/{circuit}.{suffix}'
        require(path.is_file() and path.stat().st_size > 0,'bit/hex not available')
    destination.mkdir()
    def copy(source, relative):
        target = destination / relative
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source,target)
    for suffix in ('bit','hex'):
        copy(root / f'flow/outflow/{circuit}.{suffix}',f'bitstream/{circuit}.{suffix}')
    shutil.copytree(root / 'snapshot',destination / 'source')
    for path in root.iterdir():
        if path.is_file():
            copy(path,'evidence/physical/'+path.name)
    for sub in ('flow/outflow','sta/outflow'):
        for path in (root / sub).iterdir():
            if path.is_file() and path.suffix in ('.rpt','.csv','.log','.json','.sdc','.v'):
                copy(path,'evidence/physical/'+sub+'/'+path.name)
    sim = WORK / folder / 'runs' / snapshot['simulation_run']
    for path in sim.iterdir():
        if path.is_file() and (path.suffix in ('.json','.log','.do','.txt') or path.name.endswith('.bin')):
            copy(path,'evidence/simulation/'+path.name)
    shutil.copytree(WORK / folder / 'docs',destination / 'docs')
    copy(WORK / 'sta-script-change-v1.md','docs/sta-script-change-v1.md')
    copy(CONTROL / 'experiments/track4_algorithms_20261004/03_review/fast-batch-approval-20261008-v1.json','evidence/authorization.json')
    files = [{'relative':str(p.relative_to(destination)).replace('\\','/'),'bytes':p.stat().st_size,'sha256':sha(p)}
             for p in sorted(destination.rglob('*')) if p.is_file()]
    manifest = {'schema_version':'1.0','artifact_id':artifact,'task_id':task,'batch':'TRACK4-FAST-BATCH-001 v1',
                'baseline':'FAST-BL-20261008-v1','approved_by':'human_chat','audit_exception':'approved local audit',
                'created_at_utc':utc(),'status':'REGISTERED_SOFTWARE_ARTIFACT','hardware_status':'WAITING_HUMAN_PROGRAM_NOT_REQUESTED',
                'device':'Ti60F225','timing_model':'I3','clock_mhz':25,'simulation_run':snapshot['simulation_run'],
                'physical_run':run_name,'source_files':count,'xlr':gate['xlr'],'ram':gate['ram'],'dsp':gate['dsp'],
                'setup_ns':gate['worst_setup_ns'],'hold_ns':gate['worst_hold_ns'],
                'production_io_verified':False,'full_project_goal_complete':False,'file_count':len(files),'files':files}
    write_json(destination / 'artifact-manifest.json',manifest)
    event = {'event_id':'EV-FAST-BATCH-20261008-'+('005' if kind == 'angle' else '006'),'at_utc':utc(),'task_id':task,
             'status':'BIT_HEX_REGISTERED_STOP_HARDWARE_STEPS','artifact_id':artifact,
             'artifact_manifest_sha256':sha(destination / 'artifact-manifest.json'),'source_files':count,
             'xlr':gate['xlr'],'ram':gate['ram'],'dsp':gate['dsp'],'setup_ns':gate['worst_setup_ns'],'hold_ns':gate['worst_hold_ns'],
             'formal_state_unchanged':True,'hardware_actions':False}
    with (CONTROL / 'runtime/events/2026/10/session-FAST-BATCH-20261008.jsonl').open('a',encoding='utf-8') as stream:
        stream.write(json.dumps(event,ensure_ascii=False)+'\n')
    with (CONTROL / 'experiments/track4_algorithms_20261004/03_review/side-effects.jsonl').open('a',encoding='utf-8') as stream:
        stream.write(json.dumps(event,ensure_ascii=False)+'\n')
    print(json.dumps({'artifact':artifact,'file_count':len(files),'status':'REGISTERED'}))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action',choices=('review','register'))
    parser.add_argument('kind',choices=PACKAGES)
    parser.add_argument('run')
    parser.add_argument('--revision',default='v1')
    args = parser.parse_args()
    if args.action == 'review':
        review(args.kind,args.run)
    else:
        register(args.kind,args.run,args.revision)
