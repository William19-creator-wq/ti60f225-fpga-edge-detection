"""AN02/03：独立π恒等式、幂/阶乘区间；角度线性扫描，投影直接大整数。"""
from fractions import Fraction as F
from functools import lru_cache
from math import factorial
import json
from pathlib import Path

def atan_interval(x,n):
    total=sum(((-1)**j)*x**(2*j+1)/(2*j+1) for j in range(n))
    other=total+((-1)**n)*x**(2*n+1)/(2*n+1)
    return min(total,other),max(total,other)
@lru_cache(None)
def reference_pi(n):
    a,b=atan_interval(F(1,2),n);c,d=atan_interval(F(1,3),n)
    return 4*(a+c),4*(b+d)
def trig_interval(x,n,sine):
    parity=int(sine)
    total=sum(((-1)**j)*x**(2*j+parity)/factorial(2*j+parity) for j in range(n))
    other=total+((-1)**n)*x**(2*n+parity)/factorial(2*n+parity)
    return min(total,other),max(total,other)
def independent_component(ratio,scale,sine):
    n=12
    while True:
        lo_pi,hi_pi=reference_pi(n);a,b=lo_pi*ratio,hi_pi*ratio
        lo=trig_interval(a if sine else b,n,sine)[0]*scale
        hi=trig_interval(b if sine else a,n,sine)[1]*scale
        r=(lo+F(1,2)).numerator//(lo+F(1,2)).denominator
        if F(r)-F(1,2)<lo<=hi<F(r)+F(1,2):return r
        n*=2
@lru_cache(None)
def constants():
    boundary=[tuple(independent_component(F(2*k+1,1024),1<<30,s) for s in (False,True)) for k in range(128)]
    coeff=[tuple(independent_component(F(k,512),32768,s) for s in (False,True)) for k in range(129)]
    return boundary,coeff
def audit_constants(rtl,certificate):
    rtl=Path(rtl);proof=json.loads(Path(certificate).read_text());boundary,coeff=constants()
    if len(proof['proof'])!=514:raise ValueError('certificate count')
    for row in proof['proof']:
        table=boundary if row['table']=='boundary' else coeff
        value=table[row['k']][int(row['sine'])]
        lo=F(*(int(t,16) for t in row['lower']));hi=F(*(int(t,16) for t in row['upper']))
        if row['value']!=value or not F(value)-F(1,2)<lo<=hi<F(value)+F(1,2):raise ValueError('separation certificate')
    expected_b=[0]*512;expected_c=[0]*512
    for k,(c,s) in enumerate(boundary):
        number=c|(s<<30)
        for word in range(3):expected_b[3*k+word]=(number>>(20*word))&0xfffff
    for k,(c,s) in enumerate(coeff):expected_c[2*k]=c;expected_c[2*k+1]=s
    for name,expected in (('angle_boundary.mem',expected_b),('projection_coeff.mem',expected_c)):
        raw=(rtl/name).read_bytes();words=[int(line,16) for line in raw.splitlines()]
        if words!=expected or len(words)!=512 or raw!=(''.join(f'{v:05X}\n' for v in words)).encode('ascii'):raise ValueError('ROM exact contents')
    if coeff[0]!=(32768,0) or coeff[128][0]!=coeff[128][1]:raise ValueError('axis/diagonal')
    return dict(status='PASS',components=514,rom_words=1024,method='independent atan(1/2)+atan(1/3), direct powers/factorials')
def field(raw,lo,bits,signed=False):
    v=(raw>>lo)&((1<<bits)-1);return v-(1<<bits) if signed and v>>(bits-1) else v
def identity(sequence,kind):return 1|(1<<64)|(sequence<<104)|(kind<<168)
def request(kind,payload=0,sequence=0,width=1920,height=1080,version=1,owner=0,flags=0,target=0):
    own=identity(sequence,kind)|(owner<<96)
    return own|width<<176|height<<187|version<<198|kind<<206|flags<<211|target<<213|payload<<222
def response(req,outcome=0,reason=0,value=0):
    return field(req,0,176)|field(req,206,5)<<176|field(req,213,9)<<181|outcome<<190|reason<<192|value<<200
def rounded_ratio(p,d):
    q,r=divmod(abs(p),d)
    if 2*r>d or (2*r==d and q&1):q+=1
    return -q if p<0 else q
def coefficients(theta):
    _,table=constants()
    if theta<=128:return table[theta]
    if theta<=256:c,s=table[256-theta];return s,c
    if theta<=384:c,s=table[theta-256];return -s,c
    c,s=table[512-theta];return -c,s
def vector_angle(x,y):
    boundaries,_=constants();half=int(y<0 or (y==0 and x<0))
    if half:x,y=-x,-y
    m,M=sorted((abs(x),y));q=0
    for c,s in boundaries:
        if m*c>M*s:q+=1
        else:break
    theta=q if x>=0 and abs(x)>=y else (256-q if x>=0 else (256+q if abs(x)<y else 512-q))
    full=(theta+512*half)%1024
    return theta,half,full,full>>4
def evaluate(req):
    w,h,k,p=field(req,176,11),field(req,187,11),field(req,206,5),field(req,222,400)
    if not 6<=w<=1920 or w&1 or not 5<=h<=1080:return response(req,2,3)
    used={8:22,9:38,10:31,16:9}
    if field(req,198,8)!=1 or field(req,96,8)!=0 or k not in used:return response(req,2,12)
    if field(req,211,11) or p>>used[k]:return response(req,2,2)
    if k in (8,9):
        bits=11 if k==8 else 19;x,y=field(p,0,bits,True),field(p,bits,bits,True)
        limit=1020 if k==8 else 262143
        if abs(x)>limit or abs(y)>limit:return response(req,2,3)
        if x==y==0:return response(req,2,1) if k==8 else response(req,1,4)
        theta,half,full,sector=vector_angle(x,y)
        value=theta%512 if k==8 else theta|(half<<10)|(full<<11)|(sector<<21)
    elif k==16:
        c,s=coefficients(p);value=(c&0x1ffff)|((s&0x1ffff)<<17)
    else:
        x,y,theta=field(p,0,11),field(p,11,11),field(p,22,9)
        if x>=w or y>=h:return response(req,2,3)
        c,s=coefficients(theta);q=rounded_ratio((2*x-w+1)*c+(2*y-h+1)*s,1<<19)
        if not -138<=q<=138:raise ValueError('projection bound')
        value=(q&511)|((q+138)<<9)
    return response(req,value=value)
