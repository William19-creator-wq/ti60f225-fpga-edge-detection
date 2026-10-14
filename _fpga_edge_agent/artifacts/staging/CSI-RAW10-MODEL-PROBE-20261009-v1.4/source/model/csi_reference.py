"""CPREQ02/03/05：独立RAW10数值/数量及原端口观察；不宣称生产closure。"""
import argparse,collections,json,pathlib,struct
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def group(index,width,height):
    per_frame=width*height//4;frame=index//per_frame;y=(index%per_frame)//(width//4);gx=index%(width//4)
    result=0
    for j in range(4):
        x=gx*4+j;pixel=(37*x+53*y+7*(x^y)+101*frame)%1024;result|=pixel<<(10*j)
    return result,frame,y,gx
def audit(root):
    m=read(root/'protocol-metrics.json');assert m['finished'];n=m['width']*m['height']*m['frames']//4
    source=(root/'tx-source.bin').read_bytes();actual=(root/'rx-observed.bin').read_bytes();unknown=(root/'rx-unknown.bin').read_bytes()
    assert len(source)==8*n and len(actual)==16*n and len(unknown)==n
    stats={k:collections.Counter() for k in ('upper24','ppc','dt','vc','wc','short','hs','vs')};unknowns=collections.Counter()
    raw_dt_bad=raw_wc_bad=raw_hs_low=0
    for i in range(n):
        golden,frame,y,gx=group(i,m['width'],m['height']);transmitted=struct.unpack_from('<Q',source,8*i)[0]
        assert transmitted&((1<<40)-1)==golden,(i,'source_pattern')
        assert transmitted>>40==0xa5c300^(y*17+frame)
        data,ppc,dt,vc,flags,wc,short=struct.unpack_from('<QBBBBHH',actual,16*i)
        assert data&((1<<40)-1)==golden,(i,hex(data),hex(golden))
        values=(data>>40,ppc,dt,vc,wc,short,flags&1,(flags>>1)&1)
        for bit,(key,v) in enumerate(zip(stats,values)):
            if unknown[i]&(1<<bit):unknowns[key]+=1
            else:stats[key][v]+=1
        if not unknown[i]&4 and dt!=0x2b:raw_dt_bad+=1
        if not unknown[i]&16 and wc!=m['width']*5//4:raw_wc_bad+=1
        if not unknown[i]&64 and flags&1==0:raw_hs_low+=1
    assert m['input_records']==m['output_records']==n
    edges=(root/'port-edges.csv').read_text(encoding='ascii').splitlines();domains=collections.Counter(e.split(',')[0] for e in edges)
    result=dict(status='PASS',metrics=m,raw10_pixels_compared=n*4,groups_compared=n,
                observed_fields={k:{str(v):c for v,c in counts.items()} for k,counts in stats.items()},
                unknown_field_counts=dict(unknowns),raw_dt_not_raw10_valid_records=raw_dt_bad,
                raw_wc_not_line_payload_valid_records=raw_wc_bad,hs_low_valid_records=raw_hs_low,
                edge_domain_counts=dict(domains),lane_trace_bytes=(root/'tx-lanes.bin').stat().st_size,
                optional_pixel_sideband_tested=False,crc_error_attribution_tested=False,reception_closure_proven=False,
                active_c2_equivalence_proven=False,actual_sensor_verified=False,hardware_verified=False,full_project_goal_complete=False)
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['audit']);p.add_argument('directory',type=pathlib.Path);a=p.parse_args();audit(a.directory)
