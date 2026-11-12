"""Selected bounded owner checks in a private project/profile; no game startup."""
from pathlib import Path
import hashlib, json, os, re, shutil, subprocess, sys, uuid

source=Path(__file__).resolve().parents[3]
case="base_checkpoint"
script="output/native_glut_maps/base_action_checkpoint_v2_20261112/check.gd"
run=source/"output/native_glut_maps/base_action_checkpoint_v2_20261112"/(case+"-"+uuid.uuid4().hex)
project=run/"project";project.mkdir(parents=True)
app="SB-Codex-Review2-Orbit-"+uuid.uuid4().hex
profile=Path(os.environ["APPDATA"])/"Godot/app_userdata/Sternenbuergerchen"
def fingerprint(path):
    return {str(p.relative_to(path)):[hashlib.sha256(p.read_bytes()).hexdigest(),p.stat().st_mtime_ns]
            for p in path.rglob("*") if p.is_file()} if path.exists() else {}
before=fingerprint(profile)
pending=[script,"scripts/tests/review2_isolated_user_guard.gd"]
hashes={}
while pending:
    relative=pending.pop()
    if relative in hashes:continue
    origin=source/relative
    code=origin.read_text(encoding="utf-8-sig") if origin.suffix in [".gd",".gdshader",".tscn",".tres"] else ""
    target=project/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(origin,target)
    hashes[relative]=hashlib.sha256(origin.read_bytes()).hexdigest()
    pending.extend(v for v in re.findall(r'"res://([^\"]+)"',code) if (source/v).is_file())
    pending.extend(re.findall(r'extends\s+"res://([^\"]+\.gd)"',code))
    pending.extend(re.findall(r'(?:preload|load)\(\s*"res://([^\"]+\.(?:gd|gdshader))"',code))
# The real system-map visual loads this shipped model via catalog at runtime.
asset="Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb"
target=project/asset;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source/asset,target)
hashes[asset]=hashlib.sha256((source/asset).read_bytes()).hexdigest()
texture="Assets/curated/kenney/space_station/models_all/Textures/colormap.png"
target=project/texture;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source/texture,target)
hashes[texture]=hashlib.sha256((source/texture).read_bytes()).hexdigest()
layout="art/polisa_r08_20261111/layout_compiled.json"
target=project/layout;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source/layout,target)
hashes[layout]=hashlib.sha256((source/layout).read_bytes()).hexdigest()
if "--binding-baseline" in sys.argv:
    relative="scripts/core/base_personnel_runtime.gd"
    baseline=source/"output/native_glut_maps/base_action_checkpoint_v2_20261112/base_checkpoint-823c02aab9eb40c1a641acdb9c40e49f/project"/relative
    shutil.copyfile(baseline,project/relative)
    (run/"baseline.json").write_text(json.dumps({"source":str(baseline),"sha256":hashlib.sha256(baseline.read_bytes()).hexdigest()}),encoding="utf-8")
for origin in (source/"data").rglob("*.json"):
    target=project/origin.relative_to(source);target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(origin,target)
(project/"project.godot").write_text('config_version=5\n[application]\nconfig/name='+json.dumps(app)+'\n[autoload]\nReview2Isolation="*res://scripts/tests/review2_isolated_user_guard.gd"\n',encoding="utf-8")
user=Path(os.environ["APPDATA"])/"Godot/app_userdata"/app
env=dict(os.environ,SB_REVIEW2_USER_DIR=str(user))
engine=shutil.which("godot_console.exe") or "C:/Users/bjoer/AppData/Local/Microsoft/WinGet/Links/godot_console.exe"
with (run/"output.log").open("w",encoding="utf-8") as out:
    imported=subprocess.run([engine,"--headless","--editor","--path",str(project),"--import","--quit"],env=env,stdout=out,stderr=subprocess.STDOUT,timeout=45)
    result=subprocess.run([engine,"--headless","--path",str(project),"--script","res://"+script],env=env,stdout=out,stderr=subprocess.STDOUT,timeout=30) if imported.returncode==0 else imported
log=(run/"output.log").read_text(encoding="utf-8",errors="replace")
unchanged=before==fingerprint(profile)
stable=all(hashlib.sha256((source/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
success="BASE_ACTION_CHECKPOINT_V2 passed=30 failed=0" in log
clean=success and not re.search(r'^(?:ERROR:|SCRIPT ERROR:)|ObjectDB instances leaked|resources still in use',log,re.M)
isolated=(user/"review2_isolation_canary.json").is_file()
report={"case":case,"exit_code":result.returncode,"clean_log":clean,"real_profile_unchanged":unchanged,"source_unchanged":stable,"private_canary":isolated,"source_sha256":hashes}
(run/"report.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print(log[-4500:]);print(json.dumps({k:v for k,v in report.items() if k!="source_sha256"}));print(run)
sys.exit(0 if result.returncode==0 and clean and unchanged and stable and isolated else 1)
