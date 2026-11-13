"""One isolated two-peer loopback ENet regression; no gameplay main scene."""
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
ENTRY = "scripts/tests/hex_enet_regression_verifier.gd"
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def fingerprint(directory):
    if not directory.exists():
        return {}
    return {str(p.relative_to(directory)): [hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mtime_ns]
            for p in directory.rglob("*") if p.is_file()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--case", choices=["enet", "movement_save"], default="enet")
    args = parser.parse_args()
    entry = ENTRY if args.case == "enet" else "scripts/tests/hex_movement_save_state_verifier.gd"
    if not args.execute:
        print(json.dumps({"status": "prepared_not_run", "entry": entry, "case": args.case}))
        return 0
    engine = shutil.which("godot_console.exe")
    if not engine:
        raise RuntimeError("godot_console.exe missing")
    version = subprocess.check_output([engine, "--version"], text=True).strip()
    if not version.startswith("4.6.2"):
        raise RuntimeError("Godot 4.6.2 required")
    run_id = uuid.uuid4().hex
    qa = ROOT / "docs/qa/hex_enet_regression_20261113" / run_id
    project = ROOT / ".godot/hex_enet_regression" / run_id / "project"
    qa.mkdir(parents=True)
    project.mkdir(parents=True)
    app = "SB-Codex-Review2-" + run_id
    user = Path(os.environ["APPDATA"]) / "Godot/app_userdata" / app
    real_user = Path(os.environ["APPDATA"]) / "Godot/app_userdata/Sternenbuergerchen"
    before = fingerprint(real_user)
    pending = [entry, "scripts/tests/review2_isolated_user_guard.gd"]
    paths = set()
    while pending:
        relative = pending.pop()
        if relative in paths:
            continue
        paths.add(relative)
        content = (ROOT / relative).read_text(encoding="utf-8-sig")
        pending.extend(re.findall(r'(?:preload|load)\(\s*"res://([^\"]+\.gd)"', content))
    if "scripts/meta/homebase_screen.gd" in paths:
        raise RuntimeError("unexpected HomebaseScreen closure")
    paths.update(["data/terrain_tile_catalog.json", "addons/limboai/bin/limboai.gdextension", "addons/limboai/bin/liblimboai.windows.editor.x86_64.dll"])
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
    output = ANSI.sub("", (qa / "output.log").read_text(encoding="utf-8", errors="replace"))
    source_guard = all(hashlib.sha256((ROOT / p).read_bytes()).hexdigest() == h for p, h in hashes.items())
    profile_guard = before == fingerprint(real_user)
    canary = (user / "review2_isolation_canary.json").is_file()
    errors = re.search(r"^(?:ERROR:|SCRIPT ERROR:|Parse Error:|Compile Error:)|ObjectDB instances leaked|resources still in use", output, re.M)
    marker_ok = "HEX_ENET_REGRESSION_PASS" in output if args.case == "enet" else bool(re.search(r"HEX_MOVEMENT_SAVE_STATE passed=\d+ failed=0", output))
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
