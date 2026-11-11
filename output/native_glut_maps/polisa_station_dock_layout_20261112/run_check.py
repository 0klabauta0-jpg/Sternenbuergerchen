"""Only the six pure dock-layout checks, in a fresh guarded private project."""
from pathlib import Path
import hashlib, importlib.util, json, os, shutil, subprocess, sys, uuid
sys.dont_write_bytecode = True
source = Path(__file__).resolve().parents[3]
qa = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('hex_readonly_guards',source/'scripts/tests/run_hex_tactical_check.py')
guards = importlib.util.module_from_spec(spec); spec.loader.exec_module(guards)
app = 'SB-Codex-Review2-'+uuid.uuid4().hex
project = source/'.godot/polisa_dock_layout_checks'/uuid.uuid4().hex
project.mkdir(parents=True)
user = Path(os.environ['APPDATA'])/'Godot/app_userdata'/app
real = Path(os.environ['APPDATA'])/'Godot/app_userdata/Sternenbuergerchen'
before = guards.fingerprint(real)
paths = ['scripts/mission/polisa_station_dock_layout.gd','scripts/mission/orbit_approach_layout.gd','scripts/tests/review2_isolated_user_guard.gd',qa.relative_to(source).as_posix()+'/check.gd']
hashes = {}
for name in paths:
    target = project/name; target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(source/name,target)
    hashes[name] = hashlib.sha256((source/name).read_bytes()).hexdigest()
(project/'project.godot').write_text('config_version=5\n[application]\nconfig/name='+json.dumps(app)+'\n[autoload]\nIsolation="*res://scripts/tests/review2_isolated_user_guard.gd"\n',encoding='utf-8')
engine = shutil.which('godot_console.exe')
env = dict(os.environ,SB_REVIEW2_USER_DIR=str(user))
commands = [[engine,'--headless','--path',str(project),'--script','res://scripts/mission/polisa_station_dock_layout.gd','--check-only'],[engine,'--headless','--path',str(project),'--script','res://'+paths[-1]]]
exitcodes = []
for argv,name in zip(commands,['compile.log','check.log']):
    result = subprocess.run(argv,env=env,capture_output=True,text=True,timeout=20)
    exitcodes.append(result.returncode)
    (qa/name).write_text(result.stdout+result.stderr,encoding='utf-8')
    print(result.stdout+result.stderr)
unchanged = all(hashlib.sha256((source/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
profile = before == guards.fingerprint(real)
canary = (user/'review2_isolation_canary.json').is_file()
output = (qa/'check.log').read_text()
passed = exitcodes == [0,0] and 'checks=6 failures=0' in output and not guards.ERROR.search(output) and unchanged and profile and canary
report = {'passed':bool(passed),'source_unchanged':unchanged,'real_profile_unchanged':profile,'private_canary':canary,'commands':commands,'exit_codes':exitcodes,'private_project':str(project),'private_user':str(user),'source_sha256':hashes}
(qa/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('PASSED='+str(bool(passed)))
raise SystemExit(0 if passed else 1)
