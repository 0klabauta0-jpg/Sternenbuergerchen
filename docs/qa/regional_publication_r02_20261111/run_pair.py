"""Run only after coordinating an exclusive CPU/GPU measurement window."""
from pathlib import Path
import argparse,hashlib,json,os,shutil,subprocess,zipfile
parser=argparse.ArgumentParser();parser.add_argument('--godot',default=shutil.which('godot_console.exe'));args=parser.parse_args()
if not args.godot:parser.error('--godot executable is required')
folder=Path(__file__).resolve().parent;root=folder.parents[2]
out=root/'output/native_glut_maps/regional_publication_r02';out.mkdir(parents=True,exist_ok=True)
manifest=json.loads((folder/'paired_sources.json').read_text(encoding='utf-8'))
with zipfile.ZipFile(folder/'paired_sources.zip') as archive:
 for item in manifest['files']:
  data=archive.read(item['name']);assert hashlib.sha256(data).hexdigest()==item['sha256']
  (out/item['name']).write_bytes(data)
env=os.environ.copy();env['APPDATA']=str(out/'isolated_pair_profile')
result=subprocess.run([args.godot,'--headless','--path',str(root),'--script','res://docs/qa/regional_publication_r02_20261111/compare_publication.gd'],env=env,capture_output=True,text=True,timeout=120)
(folder/'paired_cpu.log').write_text(result.stdout+result.stderr,encoding='utf-8')
if (out/'paired_cpu.json').exists():shutil.copy2(out/'paired_cpu.json',folder/'paired_cpu.json')
print('Paired CPU exit',result.returncode)
raise SystemExit(result.returncode)
