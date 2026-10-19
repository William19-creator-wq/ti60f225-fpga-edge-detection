from pathlib import Path
w=Path(__file__).resolve().parents[1]
p=w/'tests/tb_bridge.sv';s=p.read_text(encoding='utf-8')
s=s.replace('RESET_TEST=0;','RESET_TEST=0,HUD_TEST=0;')
s=s.replace('.HTOTAL(HT))','.HTOTAL(HT),.HUD_ENABLE(HUD_TEST))')
s=s.replace('mode=FAULT_TEST?3:(W==1920?5:(frame<6?frame:5));',
    'mode=FAULT_TEST?3:(W==1920?(frame==2?6:frame+1):(frame<7?frame:5));')
s=s.replace('median_enable=frame!=FRAMES-1;','median_enable=W==1920?1:frame!=FRAMES-1;')
p.write_text(s,encoding='utf-8')
p=w/'tests/run_sim.py';s=p.read_text(encoding='utf-8')
s=s.replace('import numpy as np','import numpy as np\nfrom status_reference import overlay')
s=s.replace('def gold(wid,hei,frames,fault=False):','def gold(wid,hei,frames,fault=False,hud=False):')
s=s.replace('if frame!=frames-1 else gray','if wid==1920 or frame!=frames-1 else gray')
s=s.replace('mode=3 if fault else (5 if wid==1920 or frame>=6 else frame)',
    'mode=3 if fault else (([1,2,6][frame]) if wid==1920 else (frame if frame<7 else 5))')
start=s.index('        out=variants[mode].copy()')
end=s.index('        data.append',start)
s=s[:start]+'''        if mode==6:out=np.minimum(np.abs(gray-med)*8,255).astype(np.uint32)*0x010101
        elif mode<5:out=variants[mode].copy()
        else:out=np.select([x<wid//5,x<wid*2//5,x<wid*3//5,x<wid*4//5],[a for a in variants[:4]],default=variants[4])
        if fault and frame==0:out=rgb.copy()
        if hud:out=overlay(out,mode,2047 if frame==frames-2 else 256,not(fault and frame==0))
'''+s[end:]
s=s.replace("[w/'rtl/v7_algorithm_video_pair.sv',extracted,w/'tests/tb_bridge.sv']", "[w/'rtl/v7_algorithm_status_pixel.sv',w/'rtl/v7_algorithm_video_pair.sv',extracted,w/'tests/tb_bridge.sv']")
s=s.replace("for p in sources+[Path(__file__)]:", "for p in sources+[Path(__file__),w/'tests/status_reference.py']:")
start=s.index('cases={');end=s.index('for name in ',start)
s=s[:start]+"cases={'small':(40,12,100,9,0,0),'fault':(40,12,100,3,1,0),'reset':(40,12,100,3,0,0),'hud':(320,48,220,9,0,1),'hud_fault':(320,48,220,3,1,1),'full':(1920,1080,1100,3,0,1)}\n"+s[end:]
s=s.replace('wid,hei,ht,frames,fault=cases[name]','wid,hei,ht,frames,fault,hud=cases[name]')
s=s.replace('gold(wid,hei,frames,bool(fault))','gold(wid,hei,frames,bool(fault),bool(hud))')
s=s.replace("f'-gW={wid}'","f'-gHUD_TEST={hud}',f'-gW={wid}'")
s=s.replace("'fault_injection':bool(fault)","'fault_injection':bool(fault),'hud':bool(hud)")
p.write_text(s,encoding='utf-8')
print('Extended bridge tests: seven modes, diff, HUD, full resolution; controls isolated.')
