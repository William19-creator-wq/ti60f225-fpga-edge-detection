"""FT01…08：独立大整数定义。距离由有理中点搜索，不沿用RTL的q0、floor或缓存。"""
from math import isqrt

KINDS = (11, 12, 13, 14, 15, 17, 18)
INPUT_FIELDS = {
    11: ((21,0),(43,0),(44,1),(43,0),(56,1),(56,1),(16,0)),
    12: ((21,0),(33,1),(33,1),(43,0),(43,0),(44,1),(16,0)),
    13: ((32,1),(32,1),(18,1),(32,1),(32,1),(18,1)),
    14: ((32,1),(32,1),(18,1),(11,0),(11,0)),
    15: ((18,1),(18,1),(18,1),(18,1),(11,0),(11,0)),
    17: ((21,0),(43,0),(44,1),(43,0),(56,1),(56,1)),
    18: ((21,0),(33,1),(33,1),(43,0),(43,0),(44,1)),
}

def field(number, low, bits, signed=False):
    raw=(number>>low)&((1<<bits)-1)
    return raw-(1<<bits) if signed and raw>>(bits-1) else raw

def packed(values, fields):
    result=0; low=0
    if len(values)!=len(fields): raise ValueError("field count")
    for value,(bits,signed) in zip(values,fields):
        minimum=-(1<<(bits-1)) if signed else 0
        maximum=(1<<(bits-1))-1 if signed else (1<<bits)-1
        if not isinstance(value,int) or not minimum<=value<=maximum:
            raise ValueError(f"{value} outside {'s' if signed else 'u'}{bits}")
        result|=(value&((1<<bits)-1))<<low; low+=bits
    return result

def encode_request(kind, values=(), *, sequence=0,width=1920,height=1080,version=1,owner=0,
                   flags=0,target=0,padding=0):
    if kind not in KINDS: raise ValueError("encode supported kinds explicitly")
    payload=packed(values,INPUT_FIELDS[kind])
    payload|=padding<<sum(bits for bits,_ in INPUT_FIELDS[kind])
    context=packed((1,0,1,owner,sequence,kind),((32,0),(32,0),(32,0),(8,0),(64,0),(8,0)))
    return (context | width<<176 | height<<187 | version<<198 | kind<<206 |
            flags<<211 | target<<213 | payload<<222)

def response(request,outcome,reason,value=0):
    return (field(request,0,176) | field(request,206,5)<<176 | field(request,213,9)<<181 |
            outcome<<190 | reason<<192 | value<<200)

class Reject(Exception):
    def __init__(self,outcome,reason): self.outcome,self.reason=outcome,reason

def fail(outcome,reason): raise Reject(outcome,reason)

def rne_div(numerator,denominator):
    if denominator<=0: raise ValueError("positive denominator required")
    quotient,remainder=divmod(abs(numerator),denominator)
    if 2*remainder>denominator or (2*remainder==denominator and quotient&1): quotient+=1
    return -quotient if numerator<0 else quotient

def rne_root(value):
    root=isqrt(value)
    cmp=4*value-(2*root+1)**2
    return root+int(cmp>0 or (cmp==0 and root&1))

def rational_distance(numerator,denominator,bits):
    """独立单调中点二分。输出的两边资格仍再次检查。"""
    if numerator<0 or denominator<=0: raise ValueError("rational domain")
    left,right=0,(1<<bits)-1
    while left<right:
        middle=(left+right)//2
        cmp=4*numerator-(2*middle+1)**2*denominator
        if cmp<0 or (cmp==0 and middle%2==0): right=middle
        else: left=middle+1
    q=left
    upper=4*numerator-(2*q+1)**2*denominator
    lower=4*numerator-(2*q-1)**2*denominator if q else 1
    if upper>0 or (upper==0 and q&1) or lower<0 or (lower==0 and q&1):
        fail(2,13)
    return q

def normal(nx,ny):
    if not -(1<<30)<=nx<=(1<<30) or not -(1<<30)<=ny<=(1<<30) or (nx==ny==0): fail(2,13)

def qualified_k(nx,ny):
    k=nx*nx+ny*ny
    if k<(1<<58): fail(2,13)
    return k

def geometry(value):
    if not -(1<<17)<=value<(1<<17): fail(1,6)
    return value

def evaluate(request):
    if not isinstance(request,int) or not 0<=request<(1<<622): raise ValueError("request representation")
    width,height=field(request,176,11),field(request,187,11)
    kind=field(request,206,5); p=field(request,222,400)
    try:
        if not 6<=width<=1920 or width%2 or not 5<=height<=1080: fail(2,3)
        if field(request,198,8)!=1 or field(request,96,8)!=0 or kind not in KINDS: fail(2,12)
        if field(request,211,11): fail(2,2)
        fields=INPUT_FIELDS[kind]; used=sum(bits for bits,_ in fields)
        if p>>used: fail(2,2)
        args=[]; low=0
        for bits,signed in fields: args.append(field(p,low,bits,signed)); low+=bits
        if kind in (11,17,12,18):
            if args[0]>width*height: fail(2,7)
            if args[0]<(3 if kind in (11,17) else 2): fail(1,7)
        if kind in (11,17):
            n,a,b,c,d,f=args[:6]; trace=a+c; delta=a*c-b*b
            if delta<=0: fail(1,4)
            if trace<=0: fail(2,13)
            quality_num=4*delta*65535; quality_den=trace*trace
            if kind==11 and quality_num<args[6]*quality_den: fail(1,5)
            if kind==11:
                cx=geometry(rne_div(16*(d*c-b*f),delta))
                cy=geometry(rne_div(16*(a*f-b*d),delta))
            quality=rne_div(quality_num,quality_den)
            if not 0<=quality<=65535: fail(2,13)
            value=packed((cx,cy,n,quality),((18,1),(18,1),(21,0),(16,0))) if kind==11 else packed((n,quality),((21,0),(16,0)))
        elif kind in (12,18):
            n,sx,sy,sxx,syy,sxy=args[:6]
            cxx=n*sxx-sx*sx; cyy=n*syy-sy*sy; cxy=n*sxy-sx*sy
            if cxx<0 or cyy<0: fail(2,13)
            if cxx>=(1<<64) or cyy>=(1<<64): fail(2,8)
            if cxy*cxy>cxx*cyy: fail(2,13)
            if not -(1<<64)<=cxy<(1<<64): fail(2,8)
            trace=cxx+cyy
            if trace==0: fail(1,4)
            u,v=cxx-cyy,2*cxy; discr=u*u+v*v
            if discr==0: fail(1,4)
            rq=rne_root(discr<<32); anis_num=rq*65535; anis_den=trace<<16
            if kind==12 and anis_num<args[6]*anis_den: fail(1,5)
            anis=rne_div(anis_num,anis_den)
            if not 0<=anis<=65535: fail(2,13)
            if kind==18: value=packed((n,anis),((21,0),(16,0)))
            else:
                tx,ty=(rq+(u<<16),v<<16) if u>=0 else (v<<16,rq-(u<<16))
                length=rne_root(tx*tx+ty*ty)
                if length==0: fail(2,13)
                nx,ny=-rne_div(ty<<30,length),rne_div(tx<<30,length)
                normal(nx,ny)
                if ny<0 or (ny==0 and nx<0): nx,ny=-nx,-ny
                rho=geometry(rne_div((nx*sx+ny*sy+n*(nx*(width-1)+ny*(height-1)))<<3,n<<30))
                mu=geometry(rne_div((ny*sx-nx*sy)<<3,n<<30))
                k=qualified_k(nx,ny); m=rne_root(k)
                value=packed((nx,ny,ny,-nx,rho,mu,anis,k,m),((32,1),(32,1),(32,1),(32,1),(18,1),(18,1),(16,0),(65,0),(33,0)))
        elif kind==13:
            nx0,ny0,rho0,nx1,ny1,rho1=args
            normal(nx0,ny0); normal(nx1,ny1); qualified_k(nx0,ny0); qualified_k(nx1,ny1)
            den=nx0*ny1-ny0*nx1
            if den==0: fail(1,4)
            numx=(rho0*ny1-rho1*ny0)<<30; numy=(nx0*rho1-nx1*rho0)<<30
            if den<0: den,numx,numy=-den,-numx,-numy
            x=geometry(rne_div(numx,den)); y=geometry(rne_div(numy,den))
            value=packed((x,y),((18,1),(18,1)))
        elif kind==14:
            nx,ny,rho,x,y=args; normal(nx,ny)
            if x>=width or y>=height: fail(2,3)
            k=qualified_k(nx,ny); m=rne_root(k); f=16*(nx*x+ny*y)-(rho<<30)
            q=rational_distance(f*f,k,21)
            value=packed((q,k,m),((21,0),(65,0),(33,0)))
        else:
            ax,ay,bx,by,x,y=args
            if x>=width or y>=height: fail(2,3)
            px,py=16*x-ax,16*y-ay; dx,dy=bx-ax,by-ay; k=dx*dx+dy*dy
            if k==0: fail(1,4)
            z=px*dx+py*dy
            if z<=0: numerator,denominator=px*px+py*py,1
            elif z>=k: numerator,denominator=(16*x-bx)**2+(16*y-by)**2,1
            else: numerator,denominator=(px*dy-py*dx)**2,k
            q=rational_distance(numerator,denominator,19)
            value=packed((numerator,denominator,q),((78,0),(39,0),(19,0)))
        return response(request,0,0,value)
    except Reject as error:
        return response(request,error.outcome,error.reason)

def crc_bits(crc,body,count=585):
    for index in range(count-1,-1,-1):
        feedback=(crc>>31)^field(body,index,1)
        crc=(crc<<1)&0xffffffff
        if feedback: crc^=0x04c11db7
    return crc

def primitive_reference(request):
    """只审核原始私有算术返回，用直接整数运算；不复刻child状态机。"""
    kind=field(request,206,5); sa=field(request,211,1); sb=field(request,212,1)
    target=field(request,213,9)
    a=field(request,222,192,sa); b=field(request,414,192,sb)
    if kind==0: value=a*b
    elif kind==1: value=a+b
    elif kind==2: value=a-b
    elif kind==3:
        if b==0: return response(request,2,11)
        if b<0: return response(request,2,2)
        value=rne_div(a,b)
    elif kind==4: value=rne_root(a)
    elif kind==5: value=1 if a<b else 2 if a>b else 0
    elif kind==6:
        if b==0: return response(request,2,11)
        value=a//b
    elif kind==7: value=isqrt(a)
    else: raise AssertionError("private scheduler unsupported primitive")
    signed_result=kind==2 or (kind in (0,1) and (sa or sb)) or (kind==3 and sa)
    minimum=-(1<<(target-1)) if signed_result else 0
    maximum=(1<<(target-1))-1 if signed_result else (1<<target)-1
    if not minimum<=value<=maximum: return response(request,2,8)
    return response(request,0,0,value&((1<<385)-1))
