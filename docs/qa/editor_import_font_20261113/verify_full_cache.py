"""Load both suspect fonts and the real menu from the fresh private import."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
from probe_process import run, fingerprint, errors

parser = argparse.ArgumentParser()
parser.add_argument("run", type=Path)
args = parser.parse_args()
folder = args.run.resolve()
project = folder / "project"
assert folder.parent.name == "local_runs" and folder.name.startswith("full_")
name = re.search(r'config/name="([^"]+)"', (project / "project.godot").read_text()).group(1)
assert name.startswith("SB-Codex-Import-")
profile = folder / "private_profile"
expected = profile / "Godot/app_userdata" / name
env = dict(os.environ, APPDATA=str(profile), LOCALAPPDATA=str(profile), SB_IMPORT_USER=str(expected))
real_user = Path(os.environ["APPDATA"]) / "Godot/app_userdata/Sternenbuergerchen"
before = fingerprint(real_user)
script = r'''extends SceneTree
func _initialize():
    if OS.get_user_data_dir().replace("\\", "/") != OS.get_environment("SB_IMPORT_USER").replace("\\", "/"):
        push_error("IMPORT_PROFILE_GUARD_FAILED")
        quit(2)
        return
    call_deferred("_run")

func _run():
    for ext in ["ttf", "otf"]:
        var font = load("res://Assets/kenney_input-prompts_1.4.1/Nintendo Gamecube/Fonts/kenney_input_nintendo_gamecube." + ext) as FontFile
        if font == null or font.get_data().is_empty() or font.get_string_size("ABC").x <= 0:
            push_error("IMPORT_FONT_LOAD_FAILED")
            quit(3)
            return
    var menu = load("res://scenes/ui/main_menu.tscn") as PackedScene
    if menu == null:
        push_error("IMPORT_MENU_LOAD_FAILED")
        quit(4)
        return
    var instance = menu.instantiate()
    root.add_child(instance)
    await process_frame
    await process_frame
    instance.queue_free()
    await process_frame
    await process_frame
    print("FRESH_IMPORT_RUNTIME_PASS fonts=2 menu=1 profile=", OS.get_user_data_dir())
    quit(0)
'''
(project / "verify_fresh_cache.gd").write_text(script, encoding="utf-8")
with (folder / "runtime.log").open("wb") as log:
    code = run([shutil.which("godot_console.exe"), "--headless", "--path", str(project), "--script", "res://verify_fresh_cache.gd"], env=env, log=log, timeout=90)
text = (folder / "runtime.log").read_text(encoding="utf-8", errors="replace")
result = dict(exit=code, errors=errors(text), expected_user=str(expected),
              real_profile_unchanged=before == fingerprint(real_user),
              marker="FRESH_IMPORT_RUNTIME_PASS fonts=2 menu=1" in text)
result["passed"] = code == 0 and not result["errors"] and result["marker"] and result["real_profile_unchanged"]
(folder / "runtime.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
print(json.dumps(result))
raise SystemExit(0 if result["passed"] else 1)
