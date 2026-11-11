from pathlib import Path
import shutil,subprocess,uuid
root=Path.cwd(); folder=root/'output/native_glut_maps/hex_corridor_cache_20261111'; project=folder/'project'
project.mkdir(parents=True,exist_ok=True)
import re
pending=['scripts/terrain/hex_corridor_topology_cache.gd','scripts/terrain/terrain_registry.gd','scripts/terrain/terrain_tile_data.gd','scripts/terrain/hex_grid.gd']
shutil.copyfile(folder/'verifier.gd',project/'verifier.gd')
visited=set()
while pending:
 relative=pending.pop()
 if relative in visited: continue
 visited.add(relative)
 code=(root/relative).read_text(encoding='utf-8-sig')
 destination=project/relative;destination.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/relative,destination)
 pending+=re.findall(r'(?:preload|load)\(\s*"res://([^\"]+\.gd)"',code)
(project/'project.godot').write_text('config_version=5\n[application]\nconfig/name="HexCorridorCachePrivate-'+uuid.uuid4().hex+'"\n')
engine=shutil.which('godot_console.exe')
for args in [['--editor','--import','--quit'],['--script','res://verifier.gd']]:
 result=subprocess.run([engine,'--headless','--path',str(project)]+args,capture_output=True,text=True,timeout=30)
 print(result.stdout);print(result.stderr);print('EXIT',result.returncode)
 if result.returncode or 'SCRIPT ERROR:' in result.stdout+result.stderr or 'ERROR:' in result.stdout+result.stderr: raise SystemExit(1)
 if '--script' in args and 'HEX_CORRIDOR_CACHE_PASS' not in result.stdout: raise SystemExit(1)
