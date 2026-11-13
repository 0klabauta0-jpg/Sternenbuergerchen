"""One isolated main/save UI capability regression; no game startup."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import uuid

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
ENTRY = "scripts/tests/main_hex_save_ui_20261113.gd"

class Guards:
    ANSI = re.compile(r"\x1b\[[0-9;]*m")
    @staticmethod
    def fingerprint(path):
        return {str(p.relative_to(path)): [hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mtime_ns]
                for p in path.rglob("*") if p.is_file()} if path.exists() else {}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    entry = ENTRY
    args.case = "save_ui"
    if not args.execute:
        print(json.dumps({"status": "prepared_not_run", "entry": entry, "case": args.case}))
        return 0
    engine = shutil.which("godot_console.exe")
    if not engine:
        raise RuntimeError("godot_console.exe missing")
    version = subprocess.check_output([engine, "--version"], text=True).strip()
    if not version.startswith("4.6.2"):
        raise RuntimeError("Godot 4.6.2 required")
    helper = Guards
    run_id = uuid.uuid4().hex
    qa = ROOT / "docs/qa/main_hex_review_20261113/save_ui" / run_id
    project = ROOT / ".godot/main_hex_save_ui" / run_id / "project"
    qa.mkdir(parents=True)
    project.mkdir(parents=True)
    app = "SB-Codex-Review2-" + run_id
    user = Path(os.environ["APPDATA"]) / "Godot/app_userdata" / app
    real_user = Path(os.environ["APPDATA"]) / "Godot/app_userdata/Sternenbuergerchen"
    before = helper.fingerprint(real_user)
    pending = [entry, "scripts/tests/review2_isolated_user_guard.gd"]
    paths = set()
    while pending:
        relative = pending.pop()
        if relative in paths:
            continue
        paths.add(relative)
        content = (ROOT / relative).read_text(encoding="utf-8-sig")
        pending.extend(re.findall(r'(?:preload|load)\(\s*"res://([^\"]+\.gd)"', content))
    paths.update(str(p.relative_to(ROOT)).replace("\\", "/") for p in (ROOT / "data").rglob("*.json"))
    paths.update(["addons/limboai/bin/limboai.gdextension", "addons/limboai/bin/liblimboai.windows.editor.x86_64.dll"])
    hashes = {}
    for relative in sorted(paths):
        origin = ROOT / relative
        target = project / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(origin, target)
        hashes[relative] = hashlib.sha256(origin.read_bytes()).hexdigest()
    (project / "project.godot").write_text('config_version=5\n[application]\nconfig/name=' + json.dumps(app) + '\n[autoload]\nReview2Isolation="*res://scripts/tests/review2_isolated_user_guard.gd"\n', encoding="utf-8")
    (project / ".godot").mkdir()
    (project / ".godot/extension_list.cfg").write_text("res://addons/limboai/bin/limboai.gdextension\n", encoding="utf-8")
    fixture = project / "scenes/tests/main_hex_ui_slot.tscn"
    fixture.parent.mkdir(parents=True, exist_ok=True)
    fixture.write_text('[gd_scene format=3]\n[node name="UIBookmark" type="Node"]\n', encoding="utf-8")
    commands = [[engine, "--headless", "--editor", "--path", str(project), "--import", "--quit"],
                [engine, "--headless", "--path", str(project), "--script", "res://" + entry, "--check-only"],
                [engine, "--headless", "--path", str(project), "--script", "res://" + entry]]
    exitcode = 0
    with (qa / "output.log").open("w", encoding="utf-8") as stream:
        for command in commands:
            stream.write("COMMAND " + json.dumps(command) + "\n")
            stream.flush()
            try:
                exitcode = subprocess.run(command, env=dict(os.environ, SB_REVIEW2_USER_DIR=str(user)), stdout=stream, stderr=subprocess.STDOUT, timeout=45).returncode
            except subprocess.TimeoutExpired:
                exitcode = 124
                stream.write("\nERROR: bounded timeout\n")
            if exitcode:
                break
    output = helper.ANSI.sub("", (qa / "output.log").read_text(encoding="utf-8", errors="replace"))
    source_guard = all(hashlib.sha256((ROOT / p).read_bytes()).hexdigest() == h for p, h in hashes.items())
    profile_guard = before == helper.fingerprint(real_user)
    canary = (user / "review2_isolation_canary.json").is_file()
    errors = re.search(r"^(?:ERROR:|SCRIPT ERROR:|Parse Error:|Compile Error:)|ObjectDB instances leaked|resources still in use", output, re.M)
    marker_ok = "MAIN_HEX_SAVE_UI_PASS" in output
    ok = exitcode == 0 and marker_ok and not errors and source_guard and profile_guard and canary
    report = {"status": "passed" if ok else "failed", "exit_code": exitcode, "engine": version,
              "case": args.case, "real_enet": args.case == "enet", "processes": 1, "peers": 2 if args.case == "enet" else 0, "transport": "127.0.0.1 UDP ENet" if args.case == "enet" else "offline_neighbor",
              "native_acceptance": False, "lan_internet_acceptance": False, "production_activation": False,
              "source_unchanged": source_guard, "real_profile_unchanged": profile_guard, "private_canary": canary,
              "source_sha256": hashes, "private_project": str(project), "private_user": str(user), "commands": commands}
    (qa / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(output)
    print("REPORT " + str(qa / "report.json"))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
