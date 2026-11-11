"""One private AP8 partial composition; never changes the shared Hex runner."""
from pathlib import Path
import hashlib, importlib.util, json, os, re, shutil, subprocess, sys, uuid
sys.dont_write_bytecode = True
source = Path(__file__).resolve().parents[3]
qa = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('hex_runner_readonly',source/'scripts/tests/run_hex_tactical_check.py')
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
app = 'SB-Codex-Review2-' + uuid.uuid4().hex
run = source/'.godot/hex_tactical_checks'/('ap8-partial-'+uuid.uuid4().hex)
project = run/'project'
project.mkdir(parents=True)
user = Path(os.environ['APPDATA'])/'Godot/app_userdata'/app
real_user = Path(os.environ['APPDATA'])/'Godot/app_userdata/Sternenbuergerchen'
before = helper.fingerprint(real_user)
pending = ['scripts/tests/hex_tactical_slice_verifier.gd','scripts/tests/review2_isolated_user_guard.gd']
paths = set()
while pending:
    relative = pending.pop()
    if relative in paths: continue
    paths.add(relative)
    text = (source/relative).read_text(encoding='utf-8-sig')
    pending.extend(re.findall(r'(?:preload|load)\(\s*"res://([^\"]+\.gd)"',text))
paths.update(['data/terrain_tile_catalog.json','addons/limboai/bin/limboai.gdextension','addons/limboai/bin/liblimboai.windows.editor.x86_64.dll'])
hashes = {}
for relative in sorted(paths):
    origin = source/relative
    if not origin.is_file(): continue
    target = project/relative
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(origin,target)
    hashes[relative] = hashlib.sha256(origin.read_bytes()).hexdigest()
(project/'project.godot').write_text('config_version=5\n[application]\nconfig/name='+json.dumps(app)+'\n[autoload]\nReview2Isolation="*res://scripts/tests/review2_isolated_user_guard.gd"\n',encoding='utf-8')
(project/'.godot').mkdir(exist_ok=True)
(project/'.godot/extension_list.cfg').write_text('res://addons/limboai/bin/limboai.gdextension\n',encoding='utf-8')
engine = shutil.which('godot_console.exe')
env = dict(os.environ,SB_REVIEW2_USER_DIR=str(user))
commands = [[engine,'--headless','--editor','--path',str(project),'--import','--quit'],[engine,'--headless','--path',str(project),'--script','res://scripts/tests/hex_tactical_slice_verifier.gd','--check-only'],[engine,'--headless','--path',str(project),'--script','res://scripts/tests/hex_tactical_slice_verifier.gd']]
exitcode = 0
with (qa/'output.log').open('w',encoding='utf-8') as stream:
    for argv in commands:
        try: result = subprocess.run(argv,env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=45)
        except subprocess.TimeoutExpired: exitcode = 124; stream.write('\nERROR: bounded timeout\n'); break
        exitcode = result.returncode
        if exitcode: break
output = helper.ANSI.sub('',(qa/'output.log').read_text(encoding='utf-8',errors='replace'))
source_guard = all(hashlib.sha256((source/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
profile_guard = before == helper.fingerprint(real_user)
canary = (user/'review2_isolation_canary.json').is_file()
partial = exitcode==0 and 'HEX_TACTICAL_SLICE_PARTIAL_READY' in output and not helper.ERROR.search(output) and source_guard and profile_guard and canary
(qa/'report.json').write_text(json.dumps({'partial_ready':bool(partial),'full_ap8':False,'exit_code':exitcode,'source_unchanged':source_guard,'real_profile_unchanged':profile_guard,'private_canary':canary,'private_project':str(project),'private_user':str(user),'source_sha256':hashes,'commands':commands},indent=2),encoding='utf-8')
print(output)
print('PARTIAL_READY='+str(bool(partial))+' FULL_AP8=false')
raise SystemExit(0 if partial else 1)
