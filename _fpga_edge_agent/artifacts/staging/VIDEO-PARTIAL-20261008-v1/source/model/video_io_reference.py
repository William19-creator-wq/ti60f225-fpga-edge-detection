"""VP01…04：二维原始图、固定视频区间及直接像素函数；无RTL状态机镜像。"""
import struct,zlib
from pathlib import Path
W,H=1920,1080
BARS=(0xffffff,0xffff00,0x00ffff,0x00ff00,0xff00ff,0xff0000,0x0000ff,0)

def raw_pixel(x,y):return (3*x+5*y+256*((x//120+y//90)&1))&1023
def gray_pixel(x,y):return raw_pixel(x,y)>>2
def gray_frame():return bytes(gray_pixel(x,y) for y in range(H) for x in range(W))
def rgb_pixel(x,y):return ((x&255)<<16)|((y&255)<<8)|((x^y)&255)
def edge_pixel(x,y,frame):
    here=frame[y*W+x]
    return abs(here-frame[y*W+min(x+1,W-1)])>=64 or abs(here-frame[min(y+1,H-1)*W+x])>=64
def source_coordinates(mode,x,y):return ((x%960)*2,(x%960)*2+2,y) if mode==2 else (x,x+1,y)
def render_pixel(mode,x,y,frame):
    sx=(x%960)*2 if mode==2 else x
    if mode==0:return BARS[x//240]
    if mode==1 or (mode==2 and x<960):return frame[y*W+sx]*0x010101
    if mode==2:return 0xffffff if edge_pixel(sx,y,frame) else 0
    return 0xff0000 if edge_pixel(sx,y,frame) else rgb_pixel(sx,y)
def image_bytes(mode,frame):
    data=bytearray()
    for y in range(H):
        for x in range(W):
            # 分屏第二像素源步长2，按显示像素独立映射。
            c=render_pixel(mode,x,y,frame);data.extend(((c>>16)&255,(c>>8)&255,c&255))
    return bytes(data)
def write_png(path,rgb):
    if len(rgb)!=W*H*3:raise ValueError('RGB image size')
    def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    scanlines=b''.join(b'\0'+rgb[y*W*3:(y+1)*W*3] for y in range(H))
    image=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',W,H,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(scanlines,6))+chunk(b'IEND',b'')
    Path(path).write_bytes(image)
