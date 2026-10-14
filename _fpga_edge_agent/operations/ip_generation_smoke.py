"""Run under the existing Efinity Python. Generate a FIFO in an isolated library copy."""
import os,sys,json
from pathlib import Path
sys.path.insert(0,str(Path(os.environ['EFXIPM_HOME'])/'bin'))
work=Path(sys.argv[1])
from common.logger import LoggerManager
(work/'ip_log_config.ini').write_text('[logging]\nfile=10\nconsole=20\n',encoding='ascii')
LoggerManager(log_path=work/'ip_logs',config_path=work/'ip_log_config.ini')
from ipm_api_service.design import IPMDesignAPI
from efx_ipmgr.define import Option
from gui.api_wrapper import ResultCode,generate_ip
library=work/'ip_library'
design=IPMDesignAPI('Ti60F225','Titanium',project_path=work,is_verbose=True)
# The shipped IP manager may rebuild cached graphs alongside IP definitions.
# Point its library option at copied definitions so the vendor tree remains untouched.
design._IPMDesignAPI__option=Option(ip_library_root=library,
    user_ip_library_root=work/'efinity_user/ipm/user_ip',
    xml_search_dir=tuple(library.rglob('ipm')),user_xml_search_dir=())
created=design.create_ip('smoke_fifo','efinixinc.com','memory','efx_fifo_top')
if created is None: raise RuntimeError('FIFO IP was not discovered')
design.config_ip('smoke_fifo',{'DATA_WIDTH':'8'})
valid,_,_=design.validate_ip('smoke_fifo')
if not valid: raise RuntimeError('FIFO parameter validation failed')
ip=design._IPMDesignAPI__ips['smoke_fifo']
result=generate_ip(vlnv=ip['vlnv'],params=ip['params'],filesets=ip['outputs'],out_path=work,
    gen_name='smoke_fifo',user_ip_path=work,device_name='Ti60F225',family_name='Titanium',should_log=True,
    project_name='LED_8bit_Test',peri_xml_file_path=str(work/'LED_8bit_Test.peri.xml'),project_xml_path=str(work/'LED_8bit_Test.xml'))
outputs=[p for p in (work/'ip').rglob('*') if p.suffix in ('.v','.sv')]
wrapper=work/'ip/smoke_fifo/smoke_fifo.sv'
summary=dict(created=str(created[0]),validated=valid,generation_result=str(result),
    verilog_files=[str(p.resolve()) for p in outputs],passed=result==ResultCode.SUCCESS and wrapper.is_file() and 'module smoke_fifo' in wrapper.read_text(encoding='utf-8'))
(work/'ip_generation_result.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True))
raise SystemExit(0 if summary['passed'] else 1)
