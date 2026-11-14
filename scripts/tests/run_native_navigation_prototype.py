"""Run unchanged script sources in a fresh minimal Godot project; never import game assets."""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot_console.exe")
    parser.add_argument("--script", default="native_navigation_prototype_verifier.gd")
    parser.add_argument("--output-dir")
    parser.add_argument("--timeout", type=int, default=1800)
    parser.add_argument("--without-native", action="store_true")
    args = parser.parse_args()
    if Path(args.script).name != args.script or not args.script.endswith(".gd"):
        parser.error("script must be a basename in scripts/tests")
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    project = ROOT / "tmp" / "native_navigation" / run_id
    output = Path(args.output_dir).resolve() if args.output_dir else ROOT / "docs/qa/native_navigation_20261114" / run_id
    project.mkdir(parents=True, exist_ok=False)
    output.mkdir(parents=True, exist_ok=False)
    entry = "scripts/tests/" + args.script
    queue = [entry]
    # Fixture uses a constant map path; preserve bytes including source metadata.
    queue += ["maps/Ground_Mission01_32x32.json"]
    copied = {}
    while queue:
        relative = queue.pop()
        if relative in copied:
            continue
        source = (ROOT / relative).resolve()
        if not source.is_relative_to(ROOT) or not source.is_file():
            continue
        dest = project / relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, dest)
        copied[relative] = hashlib.sha256(source.read_bytes()).hexdigest()
        if source.suffix in [".gd", ".json"]:
            for dep in re.findall(r'res://([^"\s\x27]+)', source.read_text(encoding="utf-8-sig")):
                if Path(dep).suffix in [".gd", ".json", ".txt"] and (ROOT / dep).is_file():
                    queue.append(dep)
    if not args.without_native:
        for relative in [
            "native/navigation/navigation.gdextension",
            "native/navigation/bin/native_navigation.windows.template_release.x86_64.dll",
        ]:
            source = ROOT / relative
            dest = project / relative
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, dest)
            copied[relative] = hashlib.sha256(source.read_bytes()).hexdigest()
        (project / ".godot").mkdir(exist_ok=True)
        (project / ".godot/extension_list.cfg").write_text("res://native/navigation/navigation.gdextension\n")
    (project / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name="NativeNavigationProbe-' + run_id +
        '"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="NativeNavigationProbe/' + run_id +
        '"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding="utf-8")
    environment = {
        "source_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "engine": subprocess.check_output([args.godot, "--version"], text=True).strip(),
        "run_id": run_id, "source_sha256": copied, "minimal_project": str(project),
        "headless": True, "gpu_timing": "unavailable", "player_profile": "unique isolated project",
    }
    (output / "source_manifest.json").write_text(json.dumps(environment, indent=2), encoding="utf-8")
    commands = [
        [args.godot, "--headless", "--path", str(project), "--editor", "--import"],
        [args.godot, "--headless", "--path", str(project), "--script", "res://" + entry,
         "--", "--output=" + str(output / "result.json")],
    ]
    for name, command in zip(["import", "run"], commands):
        started = time.monotonic()
        print(name + ": " + str(output), flush=True)
        with (output / (name + ".log")).open("w", encoding="utf-8") as log:
            result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=args.timeout)
        text = (output / (name + ".log")).read_text(encoding="utf-8")
        print(text[-5000:], flush=True)
        (output / (name + "_process.json")).write_text(json.dumps({
            "command": command, "exit_code": result.returncode,
            "duration_seconds": time.monotonic() - started,
        }, indent=2))
        if result.returncode or any(token in text for token in [
            "SCRIPT ERROR:", "Parse Error:", "Failed to load script", "ERROR:", "ObjectDB instances leaked",
        ]):
            raise SystemExit(result.returncode or 1)
    print("Evidence: " + str(output), flush=True)

if __name__ == "__main__":
    main()
