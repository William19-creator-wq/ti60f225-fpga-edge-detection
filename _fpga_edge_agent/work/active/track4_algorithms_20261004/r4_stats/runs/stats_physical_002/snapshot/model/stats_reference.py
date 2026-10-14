"""ST02/03：从原始点集合直接求整数和，不模拟RTL四级或五个累加寄存器。"""
from fit_reference import field, packed, INPUT_FIELDS, response, evaluate

ID_MASK=(1<<176)-1
KINDS=(11,12,17,18)

def identity(sequence=0):
    return 1 | 1<<64 | sequence<<104

def token(context,op,data=0):
    if not 0<=context<1<<176 or not 0<=data<1<<84: raise ValueError("token domain")
    return context | op<<176 | data<<178

def start(context,kind=11,width=1920,height=1080,count=0,threshold=0,version=1,padding=0):
    data=width | height<<11 | kind<<22 | version<<27 | threshold<<35 | count<<51 | padding<<72
    return token(context,0,data)

def point(context,ordinal,x,y,gx,gy,include=True,padding=0):
    data=ordinal | int(include)<<21 | x<<22 | y<<33 | (gx&2047)<<44 | (gy&2047)<<55 | padding<<66
    return token(context,1,data)

def close(context,count,*,abort=False,padding=0):
    return token(context,3,padding) if abort else token(context,2,count | padding<<22)

def header_reason(context,h):
    w,v,k=field(h,0,11),field(h,11,11),field(h,22,5)
    if not 6<=w<=1920 or w&1 or not 5<=v<=1080: return 3
    if field(h,27,8)!=1 or field(context,96,8)!=0 or k not in KINDS: return 12
    if h>>72 or (k in (17,18) and field(h,35,16)): return 2
    if field(h,51,21)>w*v: return 7
    return 0

def numeric(context,h,points,valid=True):
    w,v,k=field(h,0,11),field(h,11,11),field(h,22,5)
    payload=0
    if valid:
        # 每个列表元素来自真正接纳且include=1的原始点。
        if k in (11,17):
            normals=[(gy,-gx,gy*x-gx*y) for x,y,gx,gy in points]
            values=(len(points),sum(a*a for a,b,d in normals),sum(a*b for a,b,d in normals),
                    sum(b*b for a,b,d in normals),sum(a*d for a,b,d in normals),sum(b*d for a,b,d in normals))
        else:
            centered=[(2*x-(w-1),2*y-(v-1)) for x,y,gx,gy in points]
            values=(len(points),sum(x for x,y in centered),sum(y for x,y in centered),
                    sum(x*x for x,y in centered),sum(y*y for x,y in centered),sum(x*y for x,y in centered))
        if k in (11,12): values+= (field(h,35,16),)
        payload=packed(values,INPUT_FIELDS[k])
    return context | w<<176 | v<<187 | field(h,27,8)<<198 | k<<206 | payload<<222

def evaluate_tokens(tokens):
    """一段有限流；不同ID关闭并不结束旧流。没有真正关闭时拒绝生成黄金结果。"""
    it=iter(tokens); first=next(it); context=field(first,0,176)
    if field(first,176,2)!=0:
        return numeric(context,0,(),False) | 2<<622 | 2<<624
    h=field(first,178,84); w,v=field(h,0,11),field(h,11,11)
    expected=field(h,51,21); reason=header_reason(context,h); seen=0; previous=None; selected=[]
    for raw in it:
        own,op,p=field(raw,0,176),field(raw,176,2),field(raw,178,84)
        error=0; legal=own==context
        if not legal: error=13
        elif op==1:
            ordinal,x,y=field(p,0,21),field(p,22,11),field(p,33,11)
            gx,gy=field(p,44,11,True),field(p,55,11,True)
            if ordinal!=seen or seen>=expected: error=7
            elif x>=w or y>=v: error=3
            elif not -1020<=gx<=1020 or not -1020<=gy<=1020: error=13
            elif p>>66 or (previous is not None and (y,x)<=previous): error=2
            if not error:
                previous=(y,x)
                if not reason and field(p,21,1): selected.append((x,y,gx,gy))
        elif op==2:
            if p>>22: error=2
            elif field(p,0,22)!=seen or seen!=expected: error=7
        elif op==3:
            if p: error=2
        else: error=2
        if op==1:
            seen+=1
            if seen>=1<<22: raise ValueError("PROTOCOL_STUCK has no terminal result")
        reason=reason or error
        if legal and op in (2,3):
            outcome=2 if reason else (3 if op==3 else 0)
            return numeric(context,h,selected,outcome==0) | outcome<<622 | reason<<624
    raise ValueError("source did not close")

def fit_result(stat):
    req=field(stat,0,622); outcome,reason=field(stat,622,2),field(stat,624,8)
    return evaluate(req) if outcome==0 else response(req,outcome,reason)

def full_statistics(kind,sparse=False):
    """全N的独立集合闭式和；RTL输入仍逐个输出全部2073600个POINT。"""
    w,v=1920,1080; n=w*v
    if sparse:
        locations=((0,0),(1919,0),(960,540),(123,777),(777,999),(0,1079),(1919,1079))
        pts=[(x,y,1020 if y&1 else -1020,1020 if x&1 else -1020) for x,y in locations]
        return numeric(identity(100000+kind+int(sparse)*100),field(start(0,kind,count=n),178,84),pts)
    h=field(start(0,kind,count=n),178,84)
    if kind==11:
        a=n*1020**2
        values=(n,a,0,a,a*(w-1)//2,a*(v-1)//2,0)
    else: values=(n,0,0,n*(w*w-1)//3,n*(v*v-1)//3,0,0)
    return identity(100000+kind) | w<<176 | v<<187 | 1<<198 | kind<<206 | packed(values,INPUT_FIELDS[kind])<<222
