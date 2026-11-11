from pathlib import Path
import re,shutil,subprocess,uuid
source=Path.cwd(); project=source/'.godot/hex_reservation_private/project'; project.mkdir(parents=True,exist_ok=True)
pending=['scripts/tests/hex_reservation_verifier.gd']; visited=set()
while pending:
 p=pending.pop()
 if p in visited: continue
 visited.add(p); text=(source/p).read_text(encoding='utf-8-sig'); target=project/p; target.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(source/p,target)
 pending+=re.findall(r'(?:preload|load)\(\s*"res://([^\"]+\.gd)"',text)
(project/'project.godot').write_text('config_version=5\n[application]\nconfig/name="HexReservationPrivate20261111-' + uuid.uuid4().hex + '"\n')
engine=shutil.which('godot_console.exe')
for args in [['--editor','--import','--quit'],['--script','res://scripts/tests/hex_reservation_verifier.gd']]:
 r=subprocess.run([engine,'--headless','--path',str(project)]+args,capture_output=True,text=True,timeout=30); print(r.stdout); print(r.stderr); print('EXIT',r.returncode)
 if r.returncode or 'SCRIPT ERROR:' in r.stdout+r.stderr or 'ERROR:' in r.stdout+r.stderr: raise SystemExit(1)
 if '--script' in args and 'HEX_RESERVATION_PASS' not in r.stdout: raise SystemExit(1)
