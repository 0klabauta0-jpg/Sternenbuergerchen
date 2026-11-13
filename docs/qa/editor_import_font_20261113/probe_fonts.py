"""Fresh, private font imports; never modifies the source asset pack/cache."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import time
import uuid
from probe_process import run, fingerprint, errors

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
ENGINE = shutil.which("godot_console.exe")
VERSION = subprocess.check_output([ENGINE, "--version"]).decode().strip()
REL = Path("Assets/kenney_input-prompts_1.4.1/Nintendo Gamecube/Fonts")
RUN = OUT / "local_runs" / uuid.uuid4().hex
RUN.mkdir(parents=True)
results = []
real_user = Path(os.environ["APPDATA"]) / "Godot/app_userdata/Sternenbuergerchen"
real_before = fingerprint(real_user)
for ext, metadata in [("ttf", True), ("otf", True), ("ttf", False)]:
    label = f"{ext}_{'original' if metadata else 'defaults'}"
    project = RUN / label
    dest = project / REL
    dest.mkdir(parents=True)
    name = f"kenney_input_nintendo_gamecube.{ext}"
    src = ROOT / REL / name
    before = hashlib.sha256(src.read_bytes()).hexdigest()
    metadata_before = hashlib.sha256(Path(str(src) + ".import").read_bytes()).hexdigest()
    shutil.copy2(src, dest / name)
    if metadata:
        shutil.copy2(str(src) + ".import", str(dest / name) + ".import")
    project_name = "SB-Codex-FontProbe-" + uuid.uuid4().hex
    (project / "project.godot").write_text(f'config_version=5\n[application]\nconfig/name="{project_name}"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding="utf-8")
    profile = project / "private_profile"
    profile.mkdir()
    env = dict(os.environ, APPDATA=str(profile), LOCALAPPDATA=str(profile))
    env["SB_FONT_PROBE_USER_DIR"] = str(profile / "Godot/app_userdata" / project_name)
    args = [ENGINE, "--headless", "--path", str(project), "--editor", "--import", "--verbose"]
    start = time.time()
    with (project / "import.log").open("wb") as log:
        code = run(args, env=env, log=log, timeout=120)
    imported = list((project / ".godot" / "imported").glob("*.fontdata"))
    # Force decoding and shaping, and assert private user:// at runtime.
    script = '''extends SceneTree
func _initialize():
    var profile = OS.get_user_data_dir()
    if profile.replace("\\\\", "/") != OS.get_environment("SB_FONT_PROBE_USER_DIR").replace("\\\\", "/"):
        push_error("PROFILE_GUARD_FAILED")
        quit(2)
        return
    var font = load("res://FONT_PATH") as FontFile
    if font == null or font.get_data().is_empty() or font.get_string_size("ABC", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x <= 0:
        push_error("FONT_DECODE_FAILED")
        quit(3)
        return
    print("FONT_PROBE_PASS user=", profile, " bytes=", font.get_data().size())
    quit(0)
'''.replace("FONT_PATH", (REL / name).as_posix())
    (project / "verify.gd").write_text(script, encoding="utf-8")
    with (project / "verify.log").open("wb") as log:
        verify_code = run([ENGINE, "--headless", "--path", str(project), "--script", "res://verify.gd"], env=env, log=log, timeout=60)
    verify_text = (project / "verify.log").read_text(encoding="utf-8", errors="replace")
    failures = errors((project / "import.log").read_text(encoding="utf-8", errors="replace") + verify_text)
    unchanged = before == hashlib.sha256(src.read_bytes()).hexdigest() and metadata_before == hashlib.sha256(Path(str(src) + ".import").read_bytes()).hexdigest()
    result = dict(case=label, engine_version=VERSION, import_args=args, import_timeout=120, verify_timeout=60, import_exit=code, verify_exit=verify_code, seconds=round(time.time()-start, 2), imported_files=[x.name for x in imported], source_sha256=before, source_unchanged=before == hashlib.sha256(src.read_bytes()).hexdigest(), passed=code == 0 and verify_code == 0 and bool(imported) and "FONT_PROBE_PASS" in verify_text, logs=str(project.relative_to(ROOT)))
    results.append(result)
    result.update(source_unchanged=unchanged, metadata_sha256=metadata_before,
                  real_profile_unchanged=real_before == fingerprint(real_user), errors=failures)
    result["passed"] = result["passed"] and unchanged and result["real_profile_unchanged"] and not failures
    print(json.dumps(result), flush=True)
(RUN / "summary.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
print("SUMMARY", RUN / "summary.json")
