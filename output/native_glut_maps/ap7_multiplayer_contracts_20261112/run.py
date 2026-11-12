"""Only AP7 contracts plus one existing Snapshot neighbour; private guarded profile."""
from pathlib import Path
import hashlib, importlib.util, json, os, re, shutil, subprocess, sys, uuid
sys.dont_write_bytecode=True
source=Path(__file__).resolve().parents[3]; qa=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('guards_readonly',source/'scripts/tests/run_hex_tactical_check.py')
guards=importlib.util.module_from_spec(spec);spec.loader.exec_module(guards)
app='SB-Codex-Review2-'+uuid.uuid4().hex
project=source/'.godot/ap7_contract_checks'/uuid.uuid4().hex;project.mkdir(parents=True)
user=Path(os.environ['APPDATA'])/'Godot/app_userdata'/app
real=Path(os.environ['APPDATA'])/'Godot/app_userdata/Sternenbuergerchen'
before=guards.fingerprint(real)
fixture=qa.relative_to(source).as_posix()+'/check.gd'
neighbour='scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd'
pending=[fixture,neighbour,'scripts/tests/review2_isolated_user_guard.gd']; paths=set()
while pending:
    relative=pending.pop()
    if relative in paths:continue
    origin=source/relative
    if not origin.is_file():continue
    paths.add(relative)
    if origin.suffix in ['.gd','.gdshader','.tscn','.tres']:
        text=origin.read_text(encoding='utf-8-sig')
        pending.extend(v for v in re.findall(r'"res://([^\"]+)"',text) if (source/v).is_file())
paths.update(['addons/limboai/bin/limboai.gdextension','addons/limboai/bin/liblimboai.windows.editor.x86_64.dll'])
hashes={}
for relative in sorted(paths):
    origin=source/relative
    if not origin.is_file():continue
    target=project/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(origin,target)
    hashes[relative]=hashlib.sha256(origin.read_bytes()).hexdigest()
(project/'project.godot').write_text('config_version=5\n[application]\nconfig/name='+json.dumps(app)+'\n[autoload]\nIsolation="*res://scripts/tests/review2_isolated_user_guard.gd"\n',encoding='utf-8')
(project/'.godot').mkdir(exist_ok=True);(project/'.godot/extension_list.cfg').write_text('res://addons/limboai/bin/limboai.gdextension\n',encoding='utf-8')
engine=shutil.which('godot_console.exe');env=dict(os.environ,SB_REVIEW2_USER_DIR=str(user))
cases=[('import.log',['--headless','--editor','--path',str(project),'--import','--quit']),('snapshot_compile.log',['--headless','--path',str(project),'--script','res://scripts/multiplayer/multiplayer_snapshot_contract.gd','--check-only']),('command_compile.log',['--headless','--path',str(project),'--script','res://scripts/multiplayer/multiplayer_command_contract.gd','--check-only']),('check.log',['--headless','--path',str(project),'--script','res://'+fixture]),('neighbour.log',['--headless','--path',str(project),'--script','res://'+neighbour])]
exits={}
for name,args in cases:
    try:r=subprocess.run([engine]+args,env=env,capture_output=True,text=True,timeout=40);output=r.stdout+r.stderr;exits[name]=r.returncode
    except subprocess.TimeoutExpired:output='ERROR: bounded timeout';exits[name]=124
    (qa/name).write_text(output,encoding='utf-8')
    print(name,exits[name]);print(output[-2200:] if name in ['check.log','neighbour.log'] or exits[name] else '')
    if exits[name]:break
stable=all(hashlib.sha256((source/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
profile=before==guards.fingerprint(real);canary=(user/'review2_isolation_canary.json').is_file()
clean=all(not guards.ERROR.search((qa/name).read_text()) for name in exits)
passed=len(exits)==len(cases) and all(v==0 for v in exits.values()) and clean and stable and profile and canary
report={'passed':bool(passed),'exit_codes':exits,'source_unchanged':stable,'real_profile_unchanged':profile,'private_canary':canary,'full_ap7':False,'private_project':str(project),'private_user':str(user),'source_sha256':hashes}
(qa/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print({k:v for k,v in report.items() if k not in ['source_sha256','private_project','private_user']})
raise SystemExit(0 if passed else 1)
