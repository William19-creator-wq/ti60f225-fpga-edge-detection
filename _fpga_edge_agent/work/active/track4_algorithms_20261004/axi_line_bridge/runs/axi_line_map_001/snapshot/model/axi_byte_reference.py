"""AB-T01：从请求日志独立重放完整64B字节写；不模拟AXI拍或桥FSM。"""
import argparse,hashlib,json,pathlib
def main():
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','audit']);p.add_argument('directory',type=pathlib.Path);a=p.parse_args()
    if a.action=='generate':print('AXI byte reference uses actual transaction input trace');return
    mem=bytearray((i*37^(i>>3))&255 for i in range(16384))
    for row in (a.directory/'transactions.txt').read_text().splitlines():
        if row=='X':mem=bytearray((i*37^(i>>3))&255 for i in range(16384))
        else:
            op,addr,payload=row.split();assert op=='W';addr=int(addr);data=int(payload,16).to_bytes(64,'little')
            assert addr%64==0 and addr+64<=len(mem);mem[addr:addr+64]=data
    actual=(a.directory/'actual-memory.bin').read_bytes();assert actual==mem
    metrics=json.loads((a.directory/'protocol-metrics.json').read_text());assert metrics['finished'] and metrics['normal_writes']==512 and metrics['normal_reads']==768 and metrics['unknown_fault_cases']==7
    result=dict(status='PASS',bytes_compared=len(mem),memory_sha256=hashlib.sha256(actual).hexdigest(),protocol=metrics,
                actual_ddr_verified=False,production_pnr_verified=False,full_project_goal_complete=False)
    (a.directory/'reference-audit.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
if __name__=='__main__':main()
