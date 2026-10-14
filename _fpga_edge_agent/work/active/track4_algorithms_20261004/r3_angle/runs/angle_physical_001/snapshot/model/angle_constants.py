"""AN-T01：Machin公式与递推Taylor的精确区间；只在half-cell分离后生成ROM。"""
from fractions import Fraction as F
from functools import lru_cache
import argparse,json,hashlib
from pathlib import Path

def atan_bounds(x,n):
    term=x;total=F(0)
    for j in range(n):total+=(-1 if j&1 else 1)*term/(2*j+1);term*=x*x
    adjacent=total+(-1 if n&1 else 1)*term/(2*n+1)
    return min(total,adjacent),max(total,adjacent)
@lru_cache(None)
def pi_bounds(n):
    a,b=atan_bounds(F(1,5),n);c,d=atan_bounds(F(1,239),n)
    lo,hi=16*a-4*d,16*b-4*c
    if not 3<lo<=hi<4:raise ValueError('pi enclosure')
    return lo,hi
def series_bounds(x,n,sine):
    term=x if sine else F(1);total=F(0)
    for j in range(n):
        total+=term
        term=-term*x*x/((2*j+2)*(2*j+3) if sine else (2*j+1)*(2*j+2))
    adjacent=total+term
    return min(total,adjacent),max(total,adjacent)
def component(ratio,scale,sine):
    n=8
    while True:
        lo_pi,hi_pi=pi_bounds(n);lo_x,hi_x=lo_pi*ratio,hi_pi*ratio
        if not 0<=lo_x<=hi_x<=1:raise ValueError('Taylor monotonic domain')
        if sine:lo=series_bounds(lo_x,n,True)[0]*scale;hi=series_bounds(hi_x,n,True)[1]*scale
        else:lo=series_bounds(hi_x,n,False)[0]*scale;hi=series_bounds(lo_x,n,False)[1]*scale
        nearest=(lo+F(1,2)).numerator//(lo+F(1,2)).denominator
        if F(2*nearest-1,2)<lo<=hi<F(2*nearest+1,2):
            return nearest,dict(n=n,value=nearest,lower=[format(lo.numerator,'x'),format(lo.denominator,'x')],
                                upper=[format(hi.numerator,'x'),format(hi.denominator,'x')])
        n*=2
def generate(root,certificate):
    root=Path(root);root.mkdir(parents=True,exist_ok=True);boundary=[];coefficients=[];proof=[]
    for k in range(128):
        pair=[]
        for sine in (False,True):
            value,record=component(F(2*k+1,1024),1<<30,sine);pair.append(value)
            record.update(table='boundary',k=k,sine=sine);proof.append(record)
        boundary.append(tuple(pair))
    for k in range(129):
        pair=[]
        for sine in (False,True):
            value,record=component(F(k,512),32768,sine);pair.append(value)
            record.update(table='projection',k=k,sine=sine);proof.append(record)
        coefficients.append(tuple(pair))
    bwords=[0]*512;cwords=[0]*512
    for k,(c,s) in enumerate(boundary):
        if not 0<s<c<1<<30:raise ValueError('boundary width')
        if k and not (s>boundary[k-1][1] and c<boundary[k-1][0]):raise ValueError('nonmonotonic boundary')
        packed=c|(s<<30)
        for word in range(3):bwords[3*k+word]=(packed>>(20*word))&0xfffff
    for k,(c,s) in enumerate(coefficients):
        if not 0<=s<=c<=32768:raise ValueError('coefficient width')
        cwords[2*k]=c;cwords[2*k+1]=s
    for name,words in (('angle_boundary.mem',bwords),('projection_coeff.mem',cwords)):
        path=root/name
        if path.exists():raise FileExistsError('preserve old generated ROM; use a deliberate revision')
        path.write_bytes((''.join(f'{word:05X}\n' for word in words)).encode('ascii'))
    Path(certificate).parent.mkdir(parents=True,exist_ok=True)
    Path(certificate).write_text(json.dumps(dict(method='Machin/recurrence/Fraction',components=514,proof=proof,
        rom_sha256={name:hashlib.sha256((root/name).read_bytes()).hexdigest() for name in ('angle_boundary.mem','projection_coeff.mem')}),indent=2),encoding='utf-8')
    print(json.dumps(dict(status='GENERATED_NOT_YET_INDEPENDENTLY_AUDITED',components=len(proof),max_terms=max(p['n'] for p in proof))))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('rtl');p.add_argument('certificate');a=p.parse_args();generate(a.rtl,a.certificate)
