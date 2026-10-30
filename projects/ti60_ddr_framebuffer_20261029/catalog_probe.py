"""Inspect the installed Catalog through Efinity's own IP Manager API."""
import os
import sys
import json
from pathlib import Path

root = Path(__file__).resolve().parent
tool = Path(os.environ['EFINITY_HOME'])
dll_handle = os.add_dll_directory(str(tool / 'bin'))
sys.path.insert(0, str(tool / 'ipm/bin'))
from common.logger import Logger
Logger.setup_logger(str(root), None, 'catalog-generation.log')
from gui import api_wrapper as api
from efx_ipmgr.production_api.type.vlnv_type import VLNV
from efx_ipmgr.api_v2 import IPManagerBackend

vlnv = VLNV('efinixinc.com', 'memory_controller', 'efx_ddr3_soft_controller', '5.16')
backend = IPManagerBackend.singleton()
backend.update_ip_sources(api.get_option(), vlnv, True, device='Ti60F225', family='Titanium')
params = api.get_ip_params(vlnv, 'Ti60F225', 'Titanium')
filesets = api.get_ip_filesets(vlnv)
result = {'parameters': [p.to_dict() for p in params],
          'filesets': [f.to_dict() for f in filesets]}
(root / 'catalog-parameters.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
for p in params:
    if p.resolve == 'user':
        print(p.name, p.value, p.constraint, flush=True)
for f in filesets:
    print('FILESET', f.display_name, f.is_optional, flush=True)
if '--generate' in sys.argv:
    changes = {'row':'14', 'col':'10', 'bank':'3', 'freq':'400',
               'data_width':'1', 'DDR3_MODE':'2', 'DDR3_DATA_RATE':'2',
               'cas_latency':'6', 'dynamic_odt':'2'}
    selected = [p._replace(value=changes[p.name]) if p.name in changes else p for p in params]
    targets = [f.fileset_template for f in filesets
               if not f.is_optional or f.display_name in ('Testbench', 'Testbench/modelsim')]
    code = api.generate_ip(vlnv, selected, targets, root, 'frame_ddr3',
                          user_ip_path=root, device_name='Ti60F225', family_name='Titanium',
                          project_name='ti60f225_oob',
                          peri_xml_file_path=str(root/'ti60f225_oob.peri.xml'),
                          project_xml_path=str(root/'ti60f225_oob.xml'))
    (root/'catalog-generation-result.json').write_text(json.dumps({'result':code.name,
        'parameters':changes,'integrated':False,'hardware_passed':False},indent=2),encoding='utf-8')
    print('GENERATION_RESULT', code.name, flush=True)
    if not code.is_pass(): raise SystemExit(1)
