"""VI-T01…05：独立完整图黄金，审计真实采集/呈现输出，并从实际RGB导出画面。"""
import argparse,hashlib,json
from pathlib import Path
from video_io_reference import *
def digest(path):
    with Path(path).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def generate(run):
    root=Path(run)/'vectors';root.mkdir(parents=True,exist_ok=False);frame=gray_frame()
    (root/'gray.bin').write_bytes(frame)
    for mode in range(4):(root/f'mode{mode}.rgb').write_bytes(image_bytes(mode,frame))
    (root/'manifest.json').write_text(json.dumps(dict(width=W,height=H,pairs=W*H//2,modes=4,
        files={p.name:digest(p) for p in root.iterdir() if p.is_file()}),indent=2))
    print('Generated complete 1080p gray and four complete RGB reference frames')
def audit_camera(run):
    run=Path(run);actual=run/'capture-gray.bin';expected=run/'vectors/gray.bin'
    if actual.read_bytes()!=expected.read_bytes():raise ValueError('actual camera preview differs')
    r=json.loads((run/'camera-result.json').read_text())
    if not r.get('finished') or r.get('status')!='PASS' or r.get('pairs')!=1036800:raise ValueError('camera incomplete')
    print(json.dumps(dict(status='PASS',pixels=W*H,sha256=digest(actual))))
def audit_presenter(run):
    run=Path(run);result=json.loads((run/'presenter-result.json').read_text());artifacts=[]
    if not result.get('finished') or result.get('status')!='PASS' or result.get('modes')!=4:raise ValueError('presenter incomplete')
    for mode in range(4):
        actual=run/f'actual-mode{mode}.rgb';expected=run/f'vectors/mode{mode}.rgb'
        data=actual.read_bytes()
        if data!=expected.read_bytes():raise ValueError(f'mode{mode} complete image differs')
        picture=run/f'actual-mode{mode}.png';write_png(picture,data)
        artifacts.append(dict(mode=mode,rgb_sha256=digest(actual),png=str(picture),png_sha256=digest(picture)))
    (run/'pictures.json').write_text(json.dumps(dict(status='PASS',source='actual RTL RGB output',width=W,height=H,artifacts=artifacts),indent=2))
    print(json.dumps(dict(status='PASS',pixels_checked=4*W*H,actual_pngs=4)))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=('generate','audit-camera','audit-presenter'));p.add_argument('run');a=p.parse_args()
    {'generate':generate,'audit-camera':audit_camera,'audit-presenter':audit_presenter}[a.action](a.run)
