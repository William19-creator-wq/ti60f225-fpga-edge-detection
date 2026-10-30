from pathlib import Path
import json,hashlib,datetime,xml.etree.ElementTree as ET,shutil
p=Path(__file__).resolve().parent
report=p.parents[2]/'reports/TRACK4-DDR-FRAMEBUFFER-20261029'
f=report/'checkpoint.json';s=json.loads(f.read_text(encoding='utf-8'))
s.update(status='P1_CATALOG_MAP_PASS_IMPLEMENTATION_RUNNING',updated_at=datetime.datetime.now().astimezone().isoformat(),
 next_action='Finish official IP interface/PNR; inspect timing; complete capture/read ownership integration. No hardware pass.',
 stages={'P0':'PASS','P1':'CATALOG_GENERATED_INSTANTIATED_MAP_PASS','P2':'OWNER_COMPONENT_SIM_PASS_NOT_INTEGRATED','P3':'NOT_IMPLEMENTED','P4':'NOT_IMPLEMENTED','P5':'NOT_IMPLEMENTED'})
s['evidence']={'catalog':'catalog-generation-result.json','adapter':'verification/catalog_adapter/result.json','owner':'verification/frame_history/result.json','map':'catalog_build/map-result.json'}
s['running_session']=15523
s['mapped_resources']={'LUT4':41042,'FF':23607,'DSP48':140,'RAM10':228,'DPRAM10':4}
f.write_text(json.dumps(s,ensure_ascii=False,indent=2),encoding='utf-8')
files=[p/n.get('name') for n in ET.parse(p/'ti60f225_oob.xml').findall('.//{http://www.efinixinc.com/enf_proj}design_file')]
files += [p/'ti60f225_oob.xml',p/'ti60f225_oob.peri.xml',p/'ti60f225_oob.sdc']
files += list((p/'ip/frame_ddr3').glob('*.bin'))+list((p/'ip/frame_ddr3').glob('*.vh'))
snapshot=p/'catalog_build/source-snapshot';snapshot.mkdir(exist_ok=True)
manifest={}
for file in files:
 rel=file.relative_to(p);dest=snapshot/rel;dest.parent.mkdir(exist_ok=True,parents=True);shutil.copy2(file,dest)
 manifest[str(rel)]=hashlib.sha256(file.read_bytes()).hexdigest()
(p/'catalog_build/source-sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Recorded P1 map and component simulation evidence; hardware pending.')
