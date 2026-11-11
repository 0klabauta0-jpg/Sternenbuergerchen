"""Selected bounded owner checks in a private project/profile; no game startup."""
from pathlib import Path
import hashlib, json, os, re, shutil, subprocess, sys, uuid

source=Path(__file__).resolve().parents[2]
case=sys.argv[1]
fixtures={"prepared":"docs/qa/orbit_owner_integration_20261111/prepared_owner_check.gd",
          "root":"scripts/tests/space_combat_area_real_travel_verifier.gd",
          "birth":"scripts/tests/polisa_birth_flight_identity_check.gd",
          "surface":"scripts/tests/space_surface_approach_preview_verifier.gd",
          "authority":"scripts/tests/space_combat_authority_tick_verifier.gd",
          "reactivation":"scripts/tests/space_surface_real_reactivation_verifier.gd",
          "move":"scripts/tests/space_singleplayer_move_verifier.gd",
          "departure":"scripts/tests/space_atomic_departure_verifier.gd",
          "surface_group":"scripts/tests/space_surface_group_fixture_verifier.gd",
          "approach_cancel":"scripts/tests/space_local_approach_cancel_verifier.gd",
          "first_entry":"scripts/tests/space_combat_area_real_first_entry_verifier.gd"}
script=fixtures[case]
run=source/"output/native_glut_maps/orbit_owner_integration_20261111"/(case+"-"+uuid.uuid4().hex)
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
    code=origin.read_text(encoding="utf-8-sig")
    target=project/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(origin,target)
    hashes[relative]=hashlib.sha256(origin.read_bytes()).hexdigest()
    pending.extend(re.findall(r'(?:preload|load)\(\s*"res://([^\"]+\.gd)"',code))
for origin in (source/"data").rglob("*.json"):
    target=project/origin.relative_to(source);target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(origin,target)
(project/"project.godot").write_text('config_version=5\n[application]\nconfig/name='+json.dumps(app)+'\n[autoload]\nReview2Isolation="*res://scripts/tests/review2_isolated_user_guard.gd"\n',encoding="utf-8")
user=Path(os.environ["APPDATA"])/"Godot/app_userdata"/app
env=dict(os.environ,SB_REVIEW2_USER_DIR=str(user))
engine=shutil.which("godot_console.exe")
with (run/"output.log").open("w",encoding="utf-8") as out:
    imported=subprocess.run([engine,"--headless","--editor","--path",str(project),"--import","--quit"],env=env,stdout=out,stderr=subprocess.STDOUT,timeout=45)
    result=subprocess.run([engine,"--headless","--path",str(project),"--script","res://"+script],env=env,stdout=out,stderr=subprocess.STDOUT,timeout=30) if imported.returncode==0 else imported
log=(run/"output.log").read_text(encoding="utf-8",errors="replace")
unchanged=before==fingerprint(profile)
stable=all(hashlib.sha256((source/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
clean=not re.search(r'^(?:ERROR:|SCRIPT ERROR:)|ObjectDB instances leaked|resources still in use',log,re.M)
isolated=(user/"review2_isolation_canary.json").is_file()
report={"case":case,"exit_code":result.returncode,"clean_log":clean,"real_profile_unchanged":unchanged,"source_unchanged":stable,"private_canary":isolated,"source_sha256":hashes}
(run/"report.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print(log[-4500:]);print(json.dumps({k:v for k,v in report.items() if k!="source_sha256"}));print(run)
sys.exit(0 if result.returncode==0 and clean and unchanged and stable and isolated else 1)
