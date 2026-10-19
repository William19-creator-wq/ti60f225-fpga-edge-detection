"""Independent integer-array reference versus RTL with the vendor line RAM model."""
from pathlib import Path
import hashlib,json,os,subprocess,sys,time,shutil,datetime
import numpy as np
from status_reference import overlay
sys.stdout.reconfigure(encoding='utf-8',errors='replace')
w=Path(__file__).absolute().parent.parent
report=Path('D:/大三/FPGA_verilog/_fpga_edge_agent/reports/TRACK4-V7-ALGORITHM-CONTROL-001')
questa=Path('C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64')
model=Path('C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/efx_ram10.v')
sim=w/'sim_bridge';sim.mkdir(exist_ok=True)
def run(name,args):
    p=report/f'{name}.log';attempt=1
    while p.exists():p=report/f'{name}-{attempt:02d}.log';attempt+=1
    with p.open('wb') as f:
        result=subprocess.run([str(x) for x in args],cwd=sim,stdout=f,stderr=subprocess.STDOUT,
                              creationflags=subprocess.CREATE_NO_WINDOW,timeout=900)
    content=p.read_text(errors='replace')
    print(name, 'exit', result.returncode, str(p),flush=True)
    if result.returncode or '** Error' in content or '** Fatal' in content:print(content[-7000:]);raise SystemExit(1)
    return content
def dump(path,arr):
    pairs=arr.reshape(-1,2).astype(np.uint64)
    vals=pairs[:,0]|(pairs[:,1]<<24)
    path.write_text('\n'.join(f'{int(v):012x}' for v in vals)+'\n',encoding='ascii')
def gold(wid,hei,frames,fault=False,hud=False):
    y,x=np.indices((hei,wid),dtype=np.uint32);data=[];expected=[]
    for frame in range(frames):
        # Smooth ramps, hard boundaries, alternating single-pixel lines and impulse noise.
        r=((x*3+y*7+frame*41)%256).astype(np.uint32)
        g=((x//7*35+y*5+frame*17)%256).astype(np.uint32)
        b=((y//3*63+x*11+frame*71)%256).astype(np.uint32)
        mask=(x+y*17+frame*23)%193==0;r[mask]=255;g[mask]=0;b[mask]=255
        rgb=(r<<16)|(g<<8)|b
        gray=((77*r+150*g+29*b+128)>>8).astype(np.int32)
        padded=np.pad(gray,1,mode='edge')
        med=np.median(np.lib.stride_tricks.sliding_window_view(padded,(3,3)),axis=(-2,-1)).astype(np.int32) if wid==1920 or frame!=frames-1 else gray
        p=np.pad(med,1,mode='edge')
        gx=-p[:-2,:-2]+p[:-2,2:]-2*p[1:-1,:-2]+2*p[1:-1,2:]-p[2:,:-2]+p[2:,2:]
        gy=-p[:-2,:-2]-2*p[:-2,1:-1]-p[:-2,2:]+p[2:,:-2]+2*p[2:,1:-1]+p[2:,2:]
        edge=(np.abs(gx)+np.abs(gy))>(2047 if frame==frames-2 else 256)
        variants=[rgb,gray*0x010101,med*0x010101,edge.astype(np.uint32)*0xffffff,np.where(edge,0xff0000,rgb)]
        mode=3 if fault else (([1,2,6][frame]) if wid==1920 else (frame if frame<7 else 5))
        if mode==6:out=np.minimum(np.abs(gray-med)*8,255).astype(np.uint32)*0x010101
        elif mode<5:out=variants[mode].copy()
        else:out=np.select([x<wid//5,x<wid*2//5,x<wid*3//5,x<wid*4//5],[a for a in variants[:4]],default=variants[4])
        if fault and frame==0:out=rgb.copy()
        if hud:out=overlay(out,mode,2047 if frame==frames-2 else 256,not(fault and frame==0))
        data.append(rgb);expected.append(out)
    return np.stack(data),np.stack(expected)
if not (sim/'work').exists():run('sim-library',[questa/'vlib.exe','work'])
top=(w/'rtl/ti60f225_oob_top.v').read_text(encoding='utf-8')
serializer=top[top.index("reg rgb_vs_r = 'd0;"):top.index('//==============================================================================',top.index("reg rgb_vs_r = 'd0;"))]
assert '{hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata} <= rgb_datax2[23:0]' in serializer
extracted=sim/'actual_serializer.sv'
extracted.write_text('''module actual_serializer(input wire hdmi_tx_slow_clk,rgb_vs,rgb_hs,rgb_de,
input wire [47:0] rgb_datax2,output wire [23:0] actual_rgb,
output wire actual_vs,actual_hs,actual_de);
wire pos_vs;
'''+serializer+'''
assign actual_rgb={hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata};
assign actual_vs=hdmi_tx_vs;assign actual_hs=hdmi_tx_hs;assign actual_de=hdmi_tx_de;
endmodule
''',encoding='utf-8')
sources=[model]+sorted((w/'algorithm/frontend').glob('*.sv'))+[w/'rtl/v7_algorithm_status_pixel.sv',w/'rtl/v7_algorithm_video_pair.sv',extracted,w/'tests/tb_bridge.sv']
source_hashes={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
snapshot=report/('sim-inputs-'+datetime.datetime.now().strftime('%H%M%S'))
snapshot.mkdir()
for p in sources+[Path(__file__),w/'tests/status_reference.py']:shutil.copy2(p,snapshot/p.name)
run('sim-compile',[questa/'vlog.exe','-sv','-timescale','1ns/1ps','-work','work']+sources)
cases={'small':(40,12,100,9,0,0),'fault':(40,12,100,3,1,0),'reset':(40,12,100,3,0,0),'hud':(320,48,220,9,0,1),'hud_fault':(320,48,220,3,1,1),'full':(1920,1080,1100,3,0,1)}
for name in (sys.argv[1:] or ['small','fault','full']):
    wid,hei,ht,frames,fault,hud=cases[name];t=time.time()
    a,b=gold(wid,hei,frames,bool(fault),bool(hud));ip=sim/f'{name}-input.hex';gp=sim/f'{name}-gold.hex'
    dump(ip,a);dump(gp,b)
    text=run('sim-'+name,[questa/'vsim.exe','-c','-quiet','-voptargs=+acc','work.tb_bridge',
          f'-gHUD_TEST={hud}',f'-gW={wid}',f'-gH={hei}',f'-gHT={ht}',f'-gFRAMES={frames}',f'-gFAULT_TEST={fault}',f'-gRESET_TEST={int(name=="reset")}',
          '+INPUT='+ip.as_posix(),'+GOLD='+gp.as_posix(),'-do','onbreak {quit -code 1}; onerror {quit -code 1}; run -all; quit -code 0'])
    assert 'BRIDGE_PASS' in text
    result={'case':name,'W':wid,'H':hei,'frames':frames,'fault_injection':bool(fault),'hud':bool(hud),'seconds':time.time()-t,
            'result':'PASS','input_sha256':hashlib.sha256(ip.read_bytes()).hexdigest(),
            'gold_sha256':hashlib.sha256(gp.read_bytes()).hexdigest(),
            'sources':source_hashes,'snapshot':str(snapshot)}
    assert all(hashlib.sha256(Path(p).read_bytes()).hexdigest()==v for p,v in source_hashes.items()),'Source changed during simulation'
    dest=report/f'sim-{name}-result.json'
    if dest.exists():shutil.copy2(dest,snapshot/dest.name)
    dest.write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(text[-700:],flush=True)
