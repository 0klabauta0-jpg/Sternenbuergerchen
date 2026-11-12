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
          "first_entry":"scripts/tests/space_combat_area_real_first_entry_verifier.gd",
          "warp_entry_owner":"scripts/tests/space_warp_entry_owner_verifier.gd",
          "warp_cycle":"scripts/tests/space_warp_product_cycle_verifier.gd",
          "home_launch":"scripts/tests/space_home_launch_wing_verifier.gd",
          "regular_polisa_pilot":"scripts/tests/polisa_regular_visit_pilot_guard_verifier.gd",
          "v3_reader":"scripts/tests/space_v3_product_reader_verifier.gd",
          "polisa_mask":"scripts/tests/space_polisa_static_mask_verifier.gd",
          "polisa_dock_owner":"scripts/tests/space_polisa_fleet_dock_verifier.gd",
          "polisa_gate":"scripts/tests/space_polisa_gate_preview_verifier.gd",
          "polisa_atomic":"scripts/tests/space_polisa_atomic_dock_verifier.gd",
          "polisa_birth":"scripts/tests/polisa_local_pickup_backend_check.gd",
          "polisa_birth_reentrant":"scripts/tests/polisa_local_pickup_backend_check.gd"}
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
if case == "regular_polisa_pilot":
    # External URI shared by the shipped station GLBs in the controller closure.
    pending.append("Assets/curated/kenney/space_station/models_all/Textures/colormap.png")
hashes={}
while pending:
    relative=pending.pop()
    if relative in hashes:continue
    origin=source/relative
    code=origin.read_text(encoding="utf-8-sig") if origin.suffix in {".gd", ".gdshader", ".gdshaderinc", ".tscn", ".tres"} else ""
    target=project/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(origin,target)
    hashes[relative]=hashlib.sha256(origin.read_bytes()).hexdigest()
    pending.extend(v for v in re.findall(r'"res://([^\"]+)"',code) if (source/v).is_file())
    pending.extend(re.findall(r'(?:preload|load)\(\s*"res://([^\"]+\.(?:gd|gdshader))"',code))
    pending.extend(re.findall(r'extends\s+"res://([^\"]+\.gd)"',code))
for origin in (source/"data").rglob("*.json"):
    target=project/origin.relative_to(source);target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(origin,target)
project_settings='config_version=5\n[application]\nconfig/name='+json.dumps(app)+'\n[autoload]\nReview2Isolation="*res://scripts/tests/review2_isolated_user_guard.gd"\n'
if case == "v3_reader":
    # Only this newly created private project permits the fixture's catalog writes.
    project_settings+='[space_reader_probe]\nisolated=true\n'
(project/"project.godot").write_text(project_settings,encoding="utf-8")
user=Path(os.environ["APPDATA"])/"Godot/app_userdata"/app
env=dict(os.environ,SB_REVIEW2_USER_DIR=str(user))
if case == "polisa_birth": env["SB_TEST_LOCAL_BIRTH"] = "1"
if case == "polisa_birth_reentrant": env["SB_TEST_LOCAL_BIRTH"] = "2"
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
