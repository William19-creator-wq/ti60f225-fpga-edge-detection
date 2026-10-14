"""R2 v1 独立二维整数参考；不模拟RTL流水、RAM地址或状态机。

阅读次序：参数验证→高斯二维25项→完整G8上的Sobel→方向→原幅值NMS。
只复用已批准R1的灰度/中值纯函数，不调用其测试生成CLI。
"""
from __future__ import annotations
import importlib.util
from pathlib import Path

_r1_path = Path(__file__).resolve().parents[2] / 'r1/model/frontend_reference.py'
_spec = importlib.util.spec_from_file_location('r1_pure_reference', _r1_path)
_r1 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_r1)
gray_image, median_image = _r1.gray_image, _r1.median_image


def integer(value, low, high, name):
    if type(value) is not int or not low <= value <= high:
        raise ValueError(f'{name}: integer [{low},{high}] required')
    return value


def dimensions(width, height):
    integer(width, 6, 1920, 'width')
    integer(height, 5, 1080, 'height')
    if width % 2:
        raise ValueError('width must be even')
    return width * height


def image_values(values, width, height, maximum=255):
    if isinstance(values, (str, bytes)) or len(values) != dimensions(width, height):
        raise ValueError('complete finite image required')
    snapshot = tuple(values)
    for v in snapshot:
        integer(v, 0, maximum, 'pixel')
    return snapshot


def window(values, width, height, x, y):
    return tuple(values[min(height-1,max(0,y+dy))*width+min(width-1,max(0,x+dx))]
                 for dy in (-1,0,1) for dx in (-1,0,1))


def gaussian_image(values, width, height):
    source = image_values(values, width, height)
    weights = (1,4,6,4,1)
    output = []
    # 与硬件分离：每中心直接取25个夹紧坐标，一次舍入。
    for y in range(height):
        rows = tuple(min(height-1,max(0,y+d))*width for d in (-2,-1,0,1,2))
        for x in range(width):
            columns = tuple(min(width-1,max(0,x+d)) for d in (-2,-1,0,1,2))
            total = sum(weights[dy]*weights[dx]*source[rows[dy]+columns[dx]]
                        for dy in range(5) for dx in range(5))
            if not 0 <= total <= 65280:
                raise AssertionError('Gaussian bound')
            output.append((total+128)//256)
    return tuple(output)


def gradient_direction(gx, gy, magnitude=None):
    integer(gx,-1020,1020,'gx')
    integer(gy,-1020,1020,'gy')
    x,y = abs(gx),abs(gy)
    m=x+y
    integer(m,0,1530,'magnitude')
    if magnitude is not None and integer(magnitude,0,1530,'magnitude') != m:
        raise ValueError('L1 does not equal abs(gx)+abs(gy)')
    if m == 0 or y*1024 <= x*424:
        return 0
    if x*1024 <= y*424:
        return 2
    return 1 if (gx<0)==(gy<0) else 3


def sobel_image(values, width, height):
    source = image_values(values,width,height)
    gx_values,gy_values,magnitudes,directions = [],[],[],[]
    for y in range(height):
        for x in range(width):
            a,b,c,d,e,f,g,h,i = window(source,width,height,x,y)
            gx=c+2*f+i-a-2*d-g
            gy=g+2*h+i-a-2*b-c
            m=abs(gx)+abs(gy)
            direction=gradient_direction(gx,gy,m)
            gx_values.append(gx); gy_values.append(gy)
            magnitudes.append(m); directions.append(direction)
    return {'gx':tuple(gx_values),'gy':tuple(gy_values),
            'm':tuple(magnitudes),'dir':tuple(directions)}


def classify_window(containers, x, y, width, height, tl, th):
    dimensions(width,height)
    integer(tl,0,2047,'TL'); integer(th,tl,2047,'TH')
    integer(x,0,width-1,'x'); integer(y,0,height-1,'y')
    if len(containers)!=9:
        raise ValueError('nine NMS containers required')
    samples=tuple(integer(v,0,8191,'M/dir container') for v in containers)
    center=samples[4]&2047
    direction=(samples[4]>>11)&3
    negative,positive=((3,5),(0,8),(1,7),(6,2))[direction]
    kept=(x not in (0,width-1) and y not in (0,height-1) and center>0
          and center>(samples[negative]&2047) and center>=(samples[positive]&2047))
    if not kept:
        return 0
    return 2 if center>th else (1 if center>tl else 0)


def nms_windows_image(magnitudes,directions,width,height):
    mags=image_values(magnitudes,width,height,1530)
    dirs=image_values(directions,width,height,3)
    plane=tuple(m | (d<<11) for m,d in zip(mags,dirs))
    return tuple(window(plane,width,height,x,y)
                 for y in range(height) for x in range(width))


def nms_class_image(magnitudes,directions,width,height,tl,th):
    mags=image_values(magnitudes,width,height,1530)
    dirs=image_values(directions,width,height,3)
    integer(tl,0,2047,'TL'); integer(th,tl,2047,'TH')
    plane=tuple(m | (d<<11) for m,d in zip(mags,dirs))
    return tuple(classify_window(window(plane,width,height,x,y),x,y,width,height,tl,th)
                 for y in range(height) for x in range(width))


def stream_image(rgb,width,height,median_enable,retain_grad,tl,th):
    dimensions(width,height)
    if type(median_enable) is not bool or type(retain_grad) is not bool:
        raise ValueError('median/retain must be bool')
    integer(tl,0,2047,'TL'); integer(th,tl,2047,'TH')
    gray=tuple(gray_image(rgb,width,height))
    msrc=tuple(median_image(gray,width,height,median_enable))
    gaussian=gaussian_image(msrc,width,height)
    gradients=sobel_image(gaussian,width,height)
    classes=nms_class_image(gradients['m'],gradients['dir'],width,height,tl,th)
    return {'gray':gray,'msrc':msrc,'g8':gaussian,**gradients,'class':classes}


def self_check():
    assert gaussian_image(tuple(16*y+x for y in range(5) for x in range(6)),6,5) == (
        *range(6,12),*range(17,23),*range(32,38),*range(47,53),*range(58,64))
    for value,expected in ((30,0),(31,0),(32,1),(33,1)):
        source=[0]*30; source[7]=value
        assert gaussian_image(source,6,5)[2*6+3]==expected
    assert gradient_direction(128,53)==0 and gradient_direction(128,54)==1
    assert gradient_direction(53,128)==2 and gradient_direction(-54,128)==3
    assert gradient_direction(0,0)==0
    p=[0]*9; p[4]=10; p[5]=10
    assert classify_window(p,2,2,8,6,9,10)==1
    p[3]=10; p[5]=0
    assert classify_window(p,2,2,8,6,0,9)==0
    return {'gaussian_ramp':30,'rounding_boundaries':4,'direction_boundaries':5,
            'nms_tie_profiles':2,'status':'PASS'}
