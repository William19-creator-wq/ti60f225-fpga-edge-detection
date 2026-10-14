"""DM01..05：已读取2Gb Rev.P/x16/sg125常量对照；M0不是初始化或PHY证明。"""
import hashlib
import json
import re
import sys
from pathlib import Path

EXPECTED = dict(ADDR_BITS=14, ROW_BITS=14, COL_BITS=10, BA_BITS=3,
                DQ_BITS=16, DQS_BITS=2, DM_BITS=2, BL_MIN=4, BL_MAX=8,
                CL_MIN=5, CL_MAX=14, CWL_MIN=5, CWL_MAX=10,
                TCK_MIN=1250, TCK_MAX=3300, CL_TIME=13750, TAA_MIN=13750,
                TRAS_MIN=35000, TRCD=13750, TRP=13750, TRC=48750, TRRD=7500, TFAW=40000,
                TRFC_MIN=160000, TRFC_MAX=70200000, TXPR=170000, TXS=170000, TXP=6000, TCKE=5000,
                TDS=10, TDH=45, TIS=170, TIH=120, TDQSQ=100, TDQSCK=225,
                TWR=15000, TWTR=7500, TRTP=7500, TMOD=15000, TDLLK=512,
                TDQSS=.27, TDSS=.18, TDSH=.18, TQSH=.4, TQSL=.4,
                MEM_BITS=15, AP=10, BC=12, strict_mrbits=1, strict_timing=1, STOP_ON_ERROR=1,
                capacity_bits=2147483648, clock_period_ps=2500, simulation_time_ps=20000,
                reset_released=False, finished=True)


def audit(root):
    root = Path(root)
    actual = json.loads((root/'profile.json').read_text(encoding='utf-8'))
    assert set(actual) == set(EXPECTED)
    for name, value in EXPECTED.items():
        assert abs(actual[name]-value) < 1e-9, (name, actual[name], value)
    assert actual['DQ_BITS'] * 2**(actual['BA_BITS']+actual['ROW_BITS']+actual['COL_BITS']) == actual['capacity_bits']
    log = (root/'profile_vsim.stdout.log').read_text(encoding='utf-8')
    assert not re.search(r'\b(ERROR|FATAL)\b', log, flags=re.I), 'Vendor diagnostics cannot be hidden by exit0'
    assert '/tmp' not in log
    files = sorted((root/'backend').glob('tb_ddr_profile.dram.*'))
    assert len(files) == 8 and {p.name.rsplit('.', 1)[1] for p in files} == set(map(str, range(8)))
    assert all(p.stat().st_size == 0 for p in files), 'M0 must not pretend to have written data'
    source = root/'source-snapshot'
    model = (source/'rtl/ddr3.sv').read_bytes()
    assert not re.search(rb'^\s*`define\s+(den1024Mb|x8)\s*$', model, flags=re.M)
    header = source/'deps/2048Mb_ddr3_parameters.vh'
    assert hashlib.sha256(header.read_bytes()).hexdigest().upper() == '1244175A23FB45222CD8509AED0B515463DF8176FBD5BF8FD87D6FEDE68C6850'
    return dict(status='PASS_M0_SELECTION_ELAB_ONLY', fields_checked=len(EXPECTED), profile=actual,
                backend_bank_files_opened=8, original_2048_header_unchanged=True,
                strict_checks_enabled=True, reset_released=False, memory_data_written=False,
                actual_ddr_controller_calibration_verified=False, actual_dq_dqs_readwrite_verified=False,
                physical_ddr_verified=False, full_project_goal_complete=False)


if __name__ == '__main__':
    root = Path(sys.argv[1])
    result = audit(root)
    (root/'reference-result.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=True))
