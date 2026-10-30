"""Package a successful build with matching sources; never imply board acceptance."""
from pathlib import Path
import argparse, hashlib, json, shutil, zipfile

parser = argparse.ArgumentParser()
parser.add_argument('build', help='Existing build directory under this project')
parser.add_argument('--output-name', help='Fresh immediate-child delivery directory name')
args = parser.parse_args()
root = Path(__file__).resolve().parent
build = (root / args.build).resolve()
if build.parent != root:
    raise SystemExit('Build must be an immediate project child')
for flow in ('map', 'interface', 'pnr', 'pgm'):
    result = json.loads((build / f'{flow}-result.json').read_text(encoding='utf-8-sig'))
    if result.get('exit') != 0:
        raise SystemExit(f'{flow} has not passed')
expected = json.loads((build / 'source-sha256.json').read_text(encoding='utf-8-sig'))
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
changed = [name for name, digest in expected.items() if not (root/name).is_file() or sha(root/name) != digest]
if changed:
    raise SystemExit('Sources differ from build: ' + ', '.join(changed))
bit = build / 'outflow/ti60f225_oob.bit'
if not bit.is_file() or not bit.stat().st_size:
    raise SystemExit('No generated bitstream')
dest = root / (args.output_name or ('delivery_' + build.name))
if dest.resolve().parent != root:
    raise SystemExit('Output must be an immediate project child')
dest.mkdir(exist_ok=False)
suffixes = {'.v', '.sv', '.vh', '.svh', '.vhd', '.vhdl', '.mem', '.hex', '.bin', '.json', '.xml', '.sdc', '.tcl', '.py', '.md'}
files = {root/name for name in expected}
for folder in ('rtl', 'algorithm', 'canny', 'canny_board', 'ip', 'verification'):
    files.update(f for f in (root/folder).rglob('*') if f.is_file() and f.suffix.lower() in suffixes and 'work' not in f.relative_to(root/folder).parts)
files.update(f for f in root.iterdir() if f.is_file() and f.suffix.lower() in suffixes)
source_hashes = {f.relative_to(root).as_posix(): sha(f) for f in sorted(files)}
source_zip = dest / 'Ti60F225_DDR_Framebuffer_source.zip'
with zipfile.ZipFile(source_zip, 'w', zipfile.ZIP_DEFLATED) as archive:
    for f in sorted(files):
        archive.write(f, f.relative_to(root).as_posix())
    archive.writestr('SOURCE_SHA256.json', json.dumps(source_hashes, indent=2))
with zipfile.ZipFile(source_zip) as archive:
    bad = archive.testzip()
    if bad:
        raise SystemExit('ZIP integrity failed: ' + bad)
bit_copy = dest / 'Ti60F225_DDR_Framebuffer.bit'
shutil.copy2(bit, bit_copy)
evidence = dest / 'build-evidence'
evidence.mkdir()
for f in build.glob('*-result.json'):
    shutil.copy2(f, evidence/f.name)
shutil.copy2(build/'source-sha256.json', evidence/'source-sha256.json')
for f in (build/'outflow').iterdir():
    if f.suffix in {'.rpt', '.csv'}:
        shutil.copy2(f, evidence/f.name)
manifest = {
    'build': build.name, 'source_files': len(source_hashes),
    'source_archive': {'name': source_zip.name, 'sha256': sha(source_zip)},
    'bitstream': {'name': bit_copy.name, 'sha256': sha(bit_copy)},
    'build_flows_passed': True,
    'timing_review': 'Inspect included setup/hold reports; flow completion alone is insufficient',
    'hardware_programmed': False, 'hardware_passed': False,
    'limitations': 'Candidate packaging is not evidence of board functionality or performance.'
}
(dest/'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(str(dest))
