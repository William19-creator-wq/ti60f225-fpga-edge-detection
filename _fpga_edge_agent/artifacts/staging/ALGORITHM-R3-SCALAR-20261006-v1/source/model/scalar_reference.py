"""S02/S03/S04：数学oracle用Python大整数，不重写RTL列乘/restoring状态机。"""
from math import isqrt

MASK192 = (1 << 192) - 1
MASK385 = (1 << 385) - 1
MAX_TARGET = (385, 194, 194, 193, 97, 2, 192, 96)


def field(body, low, bits):
    return (body >> low) & ((1 << bits) - 1)


def encode_request(kind, a=0, b=0, *, a_signed=0, b_signed=0, target=None,
                   sequence=0, width=1920, height=1080, version=1, owner=0, padding=0):
    """检查表示域，算法非法域仍编码，供FRAME_FAIL测试。"""
    target = MAX_TARGET[kind] if target is None and 0 <= kind < 8 else (target or 0)
    parts = [(1,0,32), (0,32,32), (1,64,32), (owner,96,8), (sequence,104,64),
             (kind,168,8), (width,176,11), (height,187,11), (version,198,8),
             (kind,206,5), (a_signed,211,1), (b_signed,212,1), (target,213,9)]
    body = 0
    for value, low, bits in parts:
        if not isinstance(value, int) or not 0 <= value < (1 << bits):
            raise ValueError(f"field at {low} outside representation")
        body |= value << low
    if not 0 <= padding < (1 << 16):
        raise ValueError("padding representation")
    body |= (a & MASK192) << 222
    body |= (b & MASK192) << 414
    body |= padding << 606
    return body


def signed192(raw, signed):
    return raw - (1 << 192) if signed and raw >> 191 else raw


def response(request, outcome, reason, value=0):
    return (field(request,0,176) | (field(request,206,5) << 176)
            | (field(request,213,9) << 181) | (outcome << 190)
            | (reason << 192) | ((value & MASK385) << 200))


def evaluate(request):
    if not isinstance(request, int) or not 0 <= request < (1 << 622):
        raise ValueError("request outside 622 bits")
    width, height = field(request,176,11), field(request,187,11)
    kind = field(request,206,5)
    sa, sb, bits = field(request,211,1), field(request,212,1), field(request,213,9)
    a_raw, b_raw = field(request,222,192), field(request,414,192)
    a, b = signed192(a_raw, sa), signed192(b_raw, sb)
    # 返回顺序是输入合同；数学oracle本身没有时钟、取消或状态机。
    if not 6 <= width <= 1920 or width % 2 or not 5 <= height <= 1080:
        return response(request,2,3)
    if field(request,198,8) != 1 or field(request,96,8) != 0 or kind >= 8:
        return response(request,2,12)
    if (not 1 <= bits <= MAX_TARGET[kind] or (kind == 5 and bits != 2)
            or (kind in (4,6,7) and (sa or sb))):
        return response(request,2,2)
    if (kind in (4,7) and field(request,414,208)) or (kind not in (4,7) and field(request,606,16)):
        return response(request,2,2)
    if kind in (3,6) and b == 0:
        return response(request,2,11)
    if kind == 3 and b < 0:
        return response(request,2,2)
    signed_result = kind == 2 or (kind in (0,1) and (sa or sb)) or (kind == 3 and sa)
    if kind == 0:
        value = a * b
    elif kind == 1:
        value = a + b
    elif kind == 2:
        value = a - b
    elif kind in (3,6):
        value, remainder = divmod(abs(a), b)
        if kind == 3 and (2*remainder > b or (2*remainder == b and value % 2)):
            value += 1
        if a < 0:
            value = -value
    elif kind in (4,7):
        value = isqrt(a_raw)
        if kind == 4:
            boundary = (2*value+1)**2
            if 4*a_raw > boundary or (4*a_raw == boundary and value % 2):
                value += 1
    else:
        value = 1 if a < b else 2 if a > b else 0
    minimum = -(1 << (bits-1)) if signed_result else 0
    maximum = (1 << (bits-1))-1 if signed_result else (1 << bits)-1
    if not minimum <= value <= maximum:
        return response(request,2,8)
    return response(request,0,0,value)


def crc_bits(crc, body, count=585):
    for index in range(count-1, -1, -1):
        feedback = (crc >> 31) ^ ((body >> index) & 1)
        crc = (crc << 1) & 0xffffffff
        if feedback:
            crc ^= 0x04c11db7
    return crc
