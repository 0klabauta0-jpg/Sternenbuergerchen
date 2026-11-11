from pathlib import Path
import os, re, shutil, subprocess, uuid

root = Path.cwd()
folder = root / 'output/native_glut_maps/profile_readout_20261111'
project = folder / 'project'
project.mkdir(parents=True, exist_ok=True)
shutil.copyfile(folder / 'verifier.gd', project / 'verifier.gd')
pending = ['scripts/meta/character_sheet_formatter.gd', 'scripts/meta/skirmish_start_configuration.gd', 'scripts/meta/meta_unit_profile.gd']
visited = set()
while pending:
    relative = pending.pop()
    if relative in visited:
        continue
    visited.add(relative)
    source = root / relative
    destination = project / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
    pending += re.findall(r'(?:preload|load)\(\s*"res://([^\"]+\.gd)"', source.read_text(encoding='utf-8-sig'))
(project / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="ProfileReadoutPrivate-' + uuid.uuid4().hex + '"\n', encoding='utf-8')
engine = shutil.which('godot_console.exe')
environment = os.environ.copy()
environment['APPDATA'] = str(folder / 'profiles')
(folder / 'profiles').mkdir(exist_ok=True)
for args in [['--editor', '--import', '--quit'], ['--script', 'res://verifier.gd']]:
    result = subprocess.run([engine, '--headless', '--path', str(project)] + args, capture_output=True, text=True, timeout=30, env=environment)
    print(result.stdout)
    print(result.stderr)
    print('EXIT', result.returncode)
    if result.returncode or 'SCRIPT ERROR:' in result.stdout + result.stderr or 'ERROR:' in result.stdout + result.stderr:
        raise SystemExit(1)
    if '--script' in args and 'failures=0' not in result.stdout:
        raise SystemExit(1)
