"""组件登记：只有源绑定仿真/MAP通过才形成不可覆盖的本地快照。"""
import argparse,datetime,hashlib,json,pathlib,re,shutil

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def main():
    p=argparse.ArgumentParser();p.add_argument('unit');p.add_argument('artifact_id');p.add_argument('simulation');p.add_argument('map_run')
    p.add_argument('--extra-simulation',action='append');p.add_argument('--expected-ram',type=int,required=True);p.add_argument('--event',required=True)
    a=p.parse_args();root=pathlib.Path('D:/大三/FPGA_verilog/_fpga_edge_agent');work=root/'work/active/track4_algorithms_20261004';unit=work/a.unit
    simulation=unit/'runs'/a.simulation;mapping=unit/'runs'/a.map_run
    result=read(simulation/'suite-result.json');assert result['status']=='PASS' and result['finished']
    assert read(mapping/'Map.result.json')['exit_code']==0
    sources=read(mapping/'snapshot-manifest.json')['files']
    for entry in sources:
        assert sha(pathlib.Path(entry['path']))==entry['sha256'].upper()
        assert sha(pathlib.Path(entry['snapshot']))==entry['sha256'].upper()
    report=mapping/f'flow/outflow/{a.unit}_component.map.rpt';body=report.read_text(errors='replace')
    counts={};zero_evidence={}
    netlist_path=mapping/f'flow/outflow/{a.unit}_component.map.v'
    for name in ('EFX_RAM10','EFX_FF','EFX_LUT4','EFX_ADD'):
        found=re.findall(r'^'+name+r'\s*:\s*(\d+)',body,re.M)
        if not found and name in ('EFX_RAM10','EFX_ADD'):
            # ZR01：工具summary仅列非零资源；缺行只有实际网表无对应原语才能作0。
            netlist=netlist_path.read_text(errors='replace')
            pattern=r'\bEFX_(?:RAM\w*|DPRAM\w*)\b' if name=='EFX_RAM10' else r'\bEFX_ADD\b'
            assert not re.search(pattern,netlist,re.I),(name,'Missing count but primitive exists')
            counts[name]=0;zero_evidence[name]={'proof':'omitted_in_summary_and_no_primitive_in_actual_map_netlist','map_netlist_sha256':sha(netlist_path)}
        else:
            assert len(found)==1,(name,found);counts[name]=int(found[0])
    assert counts['EFX_RAM10']==a.expected_ram
    assert 'No DSP in design' in body
    counts['DSP']=0
    for name in ('EFX_SRL8',):
        found=re.findall(r'^'+name+r'\s*:\s*(\d+)',body,re.M)
        if found:assert len(found)==1;counts[name]=int(found[0])
    destination=root/'artifacts/staging'/a.artifact_id;assert not destination.exists(),'Preserve old registration'
    destination.mkdir(parents=True)
    for entry in sources:
        target=destination/'source'/entry['relative'];target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(entry['snapshot'],target)
    shutil.copy2(unit/'docs/README.md',destination/'README.md')
    baseline=unit/('baseline-v1.1.json' if (unit/'baseline-v1.1.json').exists() else 'baseline.json')
    shutil.copy2(baseline,destination/'baseline.json')
    for path in unit.glob('baseline*.json'):
        target=destination/'inputs'/path.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,target)
    for entry in read(baseline)['files']:
        path=pathlib.Path(entry['path']);assert sha(path)==entry['sha256'].upper()
        if path.suffix=='.md':shutil.copy2(path,destination/path.name)
        if path.suffix=='.py':
            relative=path.resolve().relative_to(work.resolve());target=destination/'reference-layout'/relative
            target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,target)
    simulation_names=[a.simulation]+(a.extra_simulation or [])
    for name in simulation_names:
        run=unit/'runs'/name;assert read(run/'suite-result.json')['status']=='PASS'
        for entry in read(run/'source-manifest.json'):
            path=pathlib.Path(entry['path']);assert sha(path)==entry['sha256'].upper()
            source_copy=destination/'source'/entry['relative']
            if not source_copy.exists():
                source_copy.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,source_copy)
            assert sha(source_copy)==entry['sha256'].upper()
            if path.suffix=='.py':
                target=destination/'reference-layout'/path.resolve().relative_to(work.resolve())
                target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,target)
        target=destination/'simulation'/name;target.mkdir(parents=True)
        for path in run.iterdir():
            if path.is_file() and path.suffix not in ('.wlf',):shutil.copy2(path,target/path.name)
    target=destination/'map';target.mkdir()
    for path in mapping.iterdir():
        if path.is_file():shutil.copy2(path,target/path.name)
    shutil.copytree(mapping/'flow/outflow',target/'outflow')
    files=[{'relative':path.relative_to(destination).as_posix(),'bytes':path.stat().st_size,'sha256':sha(path)} for path in sorted(destination.rglob('*')) if path.is_file()]
    manifest={'artifact_id':a.artifact_id,'status':'REGISTERED_SOFTWARE_COMPONENT_SYNTHESIS','source_files':len(sources),
        'simulations':simulation_names,'component_map':a.map_run,'resources':counts,'zero_resource_evidence':zero_evidence,'files':files,
        'pin_pnr_sta_bit_verified':False,'actual_ddr_verified':False,'hardware_actions':False,'formal_state_changed':False,'full_project_goal_complete':False}
    manifest_path=destination/'artifact-manifest.json';manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    for entry in files:assert sha(destination/entry['relative'])==entry['sha256']
    event={'event_id':a.event,'at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':manifest['status'],
        'artifact_id':a.artifact_id,'manifest_sha256':sha(manifest_path),'registered_files':len(files),'source_files':len(sources),'resources':counts,
        'hardware_actions':False,'formal_state_changed':False,'full_project_goal_complete':False}
    for path in (root/'runtime/events/2026/10/session-FAST-BATCH-20261008.jsonl',root/'experiments/track4_algorithms_20261004/03_review/side-effects.jsonl'):
        with path.open('a',encoding='utf-8') as f:f.write(json.dumps(event,ensure_ascii=False)+'\n')
    print(json.dumps(event,ensure_ascii=False))
if __name__=='__main__':main()
