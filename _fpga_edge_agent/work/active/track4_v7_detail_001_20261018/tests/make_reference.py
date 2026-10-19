"""Independent bilinear reference; a mathematical illustration, not a hardware capture."""
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[4]/'reports/TRACK4-V7-DETAIL-001'
y,x=np.mgrid[-1:193,-1:1921]
width=2**np.clip(x//320,0,5)
bright=np.where(y<64,(x//width)%2,np.where(y<128,(y//width)%2,(x//width+y//width)%2))
a=np.where(bright,224,32).astype(np.int32)
c=a[1:-1,1:-1];h=(a[1:-1,:-2]+a[1:-1,2:])//2;v=(a[:-2,1:-1]+a[2:,1:-1])//2
cross=(a[1:-1,:-2]+a[1:-1,2:]+a[:-2,1:-1]+a[2:,1:-1])//4
diag=(a[:-2,:-2]+a[:-2,2:]+a[2:,:-2]+a[2:,2:])//4
yy,xx=np.mgrid[:192,:1920];ee=(yy%2==0)&(xx%2==0);oo=(yy%2==1)&(xx%2==1)
red=np.where(ee,diag,np.where(oo,c,np.where(yy%2==0,v,h)))
green=np.where(ee|oo,cross,c)
blue=np.where(ee,c,np.where(oo,diag,np.where(yy%2==0,h,v)))
direct=np.stack([c,c,c],axis=-1).astype(np.uint8)
raw=np.stack([red,green,blue],axis=-1).astype(np.uint8)
# Outer edge padding is deliberately not modeled; gray out a one-pixel perimeter.
raw[[0,-1],:]=128;raw[:,[0,-1]]=128
Image.fromarray(direct).save(R/'direct_pattern_1920x192.png')
Image.fromarray(raw).save(R/'bilinear_reference_1920x192.png')
im=Image.new('RGB',(1920,560),'#f5f5f2');d=ImageDraw.Draw(im)
font=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',24)
d.text((15,8),'A：直接 RGB 图案（1、2、4、8、16、32 像素宽；每列 320 像素）',font=font,fill='#111111')
im.paste(Image.fromarray(direct),(0,48))
d.text((15,250),'B：同一灰度场景经过 BGGR 双线性插值的数学参考（不是实机截图）',font=font,fill='#111111')
im.paste(Image.fromarray(raw),(0,292))
d.text((15,493),'每块从上到下：竖条纹 / 横条纹 / 棋盘格。1、2 像素细纹的伪色和模糊属于参考结果。',font=font,fill='#111111')
d.text((15,528),'请按原始尺寸查看细纹；缩略图不能用于判断单像素是否清楚。',font=font,fill='#111111')
im.save(R/'detail_reference.png')
print(R/'detail_reference.png')
