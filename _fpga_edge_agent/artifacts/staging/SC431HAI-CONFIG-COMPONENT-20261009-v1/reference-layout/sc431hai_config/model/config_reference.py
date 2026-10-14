"""CT01/02/04/07：原始表与实际wire事件核对，独立于RTL状态机。"""
import argparse, hashlib, json, pathlib, re
UNIT=pathlib.Path(__file__).resolve().parents[1]
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def profile():
    data=read(UNIT/'data/sc431hai_profile.json');source=pathlib.Path(data['source'])
    assert hashlib.sha256(source.read_bytes()).hexdigest().upper()==data['source_sha256']
    actual=[]
    for line in source.read_text(encoding='utf-8-sig').splitlines():
        m=re.match(r"\s*ROM\[8'h([0-9a-fA-F]+)\]\s*=\s*\{16'h([0-9a-fA-F]+),\s*8'h([0-9a-fA-F]+),1'b([01])\}",line)
        if m:
            i,a,v,flag=(int(x,16) for x in m.groups());assert flag==0;actual.append(dict(index=i,address=a,value=v))
    assert len(actual)==164 and actual==data['writes']
    # 解码官方物理连续INIT位，核每个原表地址/数据，不依赖父的双RE次序。
    rom=(UNIT/'rtl/sc431hai_profile_rom.sv').read_text(encoding='utf-8')
    chunks=re.findall(r"\.INIT_([0-9A-F]+)\(256'h([0-9a-f]+)\)",rom)
    assert len(chunks)==40
    packed=sum(int(value,16)<<(int(index,16)*256) for index,value in chunks)
    for item in actual:
        i=item['index'];low=(packed>>(2*i*20))&0xfffff;high=(packed>>((2*i+1)*20))&0xfffff
        assert high<16 and (high<<20|low)==(item['address']<<8|item['value'])
    assert packed>>(328*20)==0
    return data
def generate(root):
    data=profile()
    (root/'profile.hex').write_text(''.join(f'{v["address"]:04x}{v["value"]:02x}\n' for v in data['writes']),encoding='ascii')
    (root/'verify.hex').write_text(''.join(f'{v["address"]:04x}{v["expected"]:02x}{v["mask"]:02x}\n' for v in data['verify']),encoding='ascii')
    (root/'profile-reference.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    print('164 original native ROM rows validated; independent wire expectations ready')
def wire(path):
    result={}
    for line in path.read_text(encoding='ascii').splitlines():
        fields=line.split(',');kind=fields[0];case=int(fields[1]);transaction=int(fields[2]);key=(case,transaction)
        result.setdefault(key,[]).append((kind,fields[3:]))
    return result
def check_transaction(events,reading,address,value,device=0x30):
    starts=[e[1][0] for e in events if e[0]=='S'];assert starts==(['0','1'] if reading else ['0'])
    acknowledgments=[e[1] for e in events if e[0]=='A'];assert len(acknowledgments)==4
    sent=[int(e[1],16) for e in acknowledgments]
    assert sent==[device<<1,address>>8,address&255,(device<<1|1) if reading else value]
    assert [int(e[2]) for e in acknowledgments]==[0]*4
    assert len([e for e in events if e[0]=='P'])==1
    if reading:
        payload=[e[1] for e in events if e[0]=='R'];assert len(payload)==1
        assert int(payload[0][0],16)==address and int(payload[0][1],16)==value
        assert [e[1][0] for e in events if e[0]=='M']==['1']
    else:
        writes=[e[1] for e in events if e[0]=='W'];assert len(writes)==1
        assert (int(writes[0][0],16),int(writes[0][1],16))==(address,value)
def audit_master(root):
    metrics=read(root/'master-metrics.json');assert metrics['finished'] and metrics['cases']>=276 and metrics['unknowns']==3
    events=wire(root/'master-wire.csv');rng=0x146ce572
    for i in range(128):
        rng=((rng<<1)&0xffffffff)|(((rng>>31)^(rng>>21)^(rng>>1)^rng)&1)
        address=(i*517)&65535;value=rng&255
        for case,reading in ((2*i,False),(2*i+1,True)):
            found=[ev for (c,_),ev in events.items() if c==case];assert len(found)==1
            check_transaction(found[0],reading,address,value)
    result=dict(status='PASS',random_wire_transactions=256,metrics=metrics,hardware_verified=False)
    (root/'master-reference-audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))
def audit_config(root):
    data=profile();metrics=read(root/'protocol-metrics.json');assert metrics['finished']
    events=wire(root/'config-wire.csv');rows=read(root/'config-results.json')
    normal=[r for r in rows if r['kind']=='config_ok'];assert normal
    for row in normal:
        case=row['case'];sequence=sorted((t,e) for (c,t),e in events.items() if c==case)
        assert len(sequence)==180
        expected=[(True,0x3107,0xcd),(True,0x3108,0x6b)]
        expected += [(False,v['address'],v['value']) for v in data['writes']]
        # TB允许无关位；masked expected是独立公开内容合同。
        expected += [(True,v['address'],v['expected']) for v in data['verify']]
        for index,((_,actual),(reading,address,value)) in enumerate(zip(sequence,expected)):
            if index>=166:
                read_payload=[e[1] for e in actual if e[0]=='R'][0];value=int(read_payload[1],16)
                public=data['verify'][index-166];assert value&public['mask']==public['expected']
            check_transaction(actual,reading,address,value,row['device'])
        assert row['writes']==164 and row['reads']==16 and row['mask']==16383 and row['id']==0xcd6b
        assert row['min_low_ns']>=4700 and row['min_high_ns']>=4000 and row['min_start_hold_ns']>=4000 and row['min_stop_setup_ns']>=4000 and row['min_bus_free_ns']>=4700
        assert row['first_start_after_power_ns']>=4000000
    result=dict(status='PASS',normal_configs=len(normal),wire_transactions_checked=180*len(normal),metrics=metrics,
                actual_sensor_verified=False,actual_csi_verified=False,production_pnr_verified=False,full_project_goal_complete=False)
    (root/'reference-audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['generate','master','config']);p.add_argument('directory',type=pathlib.Path);a=p.parse_args()
    {'generate':generate,'master':audit_master,'config':audit_config}[a.action](a.directory)
