"""One isolated actual Store/Continue case; --execute is required to run Godot."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[2]
ENTRY = "scripts/tests/hex_campaign_continue_verifier.gd"
NAV = "maps/base_interior_navigation.json"
ERROR = re.compile(r"^(?:ERROR:|SCRIPT ERROR:|Parse Error:|Compile Error:)|ObjectDB instances leaked|resources still in use", re.M)
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def fingerprint(path: Path) -> dict:
    return {str(p.relative_to(path)): [sha(p.read_bytes()), p.stat().st_mtime_ns]
            for p in path.rglob("*") if p.is_file()} if path.exists() else {}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    if not args.execute:
        print(json.dumps({"status": "prepared_not_run", "entry": ENTRY,
                          "positive": "exact private fine navigation + explicit test-only opt-in",
                          "negative": "exact original unflagged navigation + same saved Hex block"}))
        return 0
    engine = shutil.which("godot_console.exe")
    if not engine:
        raise RuntimeError("godot_console.exe unavailable")
    version = subprocess.check_output([engine, "--version"], text=True).strip()
    if not version.startswith("4.6.2"):
        raise RuntimeError("Godot 4.6.2 required")
    run = ROOT / ".godot/hex_campaign_continue" / uuid.uuid4().hex
    project = run / "project"
    project.mkdir(parents=True)
    app = "SB-Codex-Review2-" + uuid.uuid4().hex
    user = Path(os.environ["APPDATA"]) / "Godot/app_userdata" / app
    real = Path(os.environ["APPDATA"]) / "Godot/app_userdata/Sternenbuergerchen"
    before = fingerprint(real)
    pending = [ENTRY, "scripts/tests/review2_isolated_user_guard.gd",
               "maps/campaign_intro_base.json", NAV,
               "addons/limboai/bin/limboai.gdextension",
               "addons/limboai/bin/liblimboai.windows.editor.x86_64.dll"]
    pending += [str(p.relative_to(ROOT)).replace("\\", "/") for p in (ROOT / "data").rglob("*.json")]
    sources: dict[str, str] = {}
    text_types = {".gd", ".tscn", ".tres", ".gdshader"}
    while pending:
        relative = pending.pop()
        if relative in sources:
            continue
        original = ROOT / relative
        if not original.is_file():
            raise FileNotFoundError(relative)
        data = original.read_bytes()
        sources[relative] = sha(data)
        target = project / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        if original.suffix in text_types:
            code = data.decode("utf-8-sig")
            # All literal GD dependencies, and static non-GD preload/scene resources.
            refs = re.findall(r'["\']res://([^"\']+\.gd)["\']', code)
            refs += re.findall(r'preload\(\s*"res://([^\"]+)"', code)
            refs += re.findall(r'path="res://([^\"]+)"', code)
            pending.extend(refs)
    nav_original = (project / NAV).read_bytes()
    nav = json.loads(nav_original)
    if nav.get("tactical_grid_rules") or nav.get("grid_size") != {"x": 384, "y": 392} or nav.get("tile_size") != {"half_width": 16, "half_height": 8}:
        raise RuntimeError("Expected actual unflagged fine base navigation")
    nav["tactical_grid_rules"] = "hex_tactical_v1"
    nav_opt_in = json.dumps(nav, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    (project / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name=' + json.dumps(app) +
        '\n[autoload]\nReview2Isolation="*res://scripts/tests/review2_isolated_user_guard.gd"\n', encoding="utf-8")
    (project / ".godot").mkdir(exist_ok=True)
    (project / ".godot/extension_list.cfg").write_text("res://addons/limboai/bin/limboai.gdextension\n", encoding="utf-8")
    env = dict(os.environ, SB_REVIEW2_USER_DIR=str(user))
    commands = [
        ([engine, "--headless", "--editor", "--path", str(project), "--import", "--quit"], 60),
        ([engine, "--headless", "--path", str(project), "--script", "res://" + ENTRY, "--check-only"], 30),
        ([engine, "--headless", "--path", str(project), "--script", "res://" + ENTRY], 180),
        ([engine, "--headless", "--path", str(project), "--script", "res://" + ENTRY, "--", "--legacy-negative"], 45),
    ]
    report = {"head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
              "engine": version, "source_sha256": sources, "private_project": str(project),
              "private_user": str(user), "commands": [], "executed": True,
              "production_activation": False, "performance_acceptance": False,
              "private_navigation": {"source_sha256": sha(nav_original), "opt_in_sha256": sha(nav_opt_in),
                                     "changed_fields": ["tactical_grid_rules"], "grid_size": nav["grid_size"],
                                     "tile_size": nav["tile_size"]}}
    exit_code = 0
    log = run / "output.log"
    with log.open("w", encoding="utf-8") as stream:
        for index, (argv, timeout) in enumerate(commands):
            # Source files are never rewritten. Only the private project's explicit
            # positive input opts in; the last process gets the exact original bytes.
            (project / NAV).write_bytes(nav_original if index == 3 else nav_opt_in)
            try:
                result = subprocess.run(argv, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
                exit_code = result.returncode
            except subprocess.TimeoutExpired:
                exit_code = 124
                stream.write("\nERROR: bounded continue case timed out\n")
            report["commands"].append({"argv": argv, "exit_code": exit_code})
            if exit_code:
                break
    (project / NAV).write_bytes(nav_original)
    output = ANSI.sub("", log.read_text(encoding="utf-8", errors="replace"))
    report["source_unchanged"] = all((ROOT / p).is_file() and sha((ROOT / p).read_bytes()) == digest for p, digest in sources.items())
    report["real_profile_unchanged"] = before == fingerprint(real)
    report["private_canary"] = (user / "review2_isolation_canary.json").is_file()
    report["exit_code"] = exit_code
    report["passed"] = (exit_code == 0 and output.count("HEX_CAMPAIGN_CONTINUE_READY") == 2
                        and not ERROR.search(output) and report["source_unchanged"]
                        and report["real_profile_unchanged"] and report["private_canary"])
    (run / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(output[-16000:])
    print("REPORT=" + str(run / "report.json"))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
