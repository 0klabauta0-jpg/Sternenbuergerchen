"""Run Godot checks with a fresh project name/user directory and roster guard.

The source project configuration and real user data are never redirected in place.
Resource directories/import cache are shared; output/tmp and user:// are private.
"""
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
from datetime import datetime, timezone


RESOURCE_DIRS = ("addons", "Assets", "art", "data", "docs", "maps", "scenes", "scripts", "shaders", "tests")
ERROR = re.compile(r"^\s*(?:ERROR:|SCRIPT ERROR:|Parse Error:|Compile Error:)|ObjectDB instances leaked|resources still in use at exit", re.MULTILINE)
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def roster_state(path: Path) -> dict:
    raw = path.read_bytes()
    info = path.stat()
    return {"sha256": hashlib.sha256(raw).hexdigest(), "length": len(raw), "mtime_ns": info.st_mtime_ns}


def check_roster(baseline: dict) -> dict:
    actual = roster_state(Path(baseline["roster_path"]))
    if actual != baseline["state"]:
        raise RuntimeError("Protected roster differs from the recorded baseline; refusing tests. No automatic restoration.")
    return actual


def create_overlay(source: Path, run_id: str) -> tuple[Path, str]:
    container = source / ".godot" / "review2_isolation" / run_id
    project = container / "project"
    project.mkdir(parents=True, exist_ok=False)
    app_name = "SB-Codex-Review2-" + run_id
    config = (source / "project.godot").read_text(encoding="utf-8-sig")
    section = re.search(r"(?ms)^\[application\]\s*\n(.*?)(?=^\[|\Z)", config)
    if section is None:
        raise ValueError("Missing application section")
    body = section.group(1)
    if re.search(r"(?m)^config/(?:name|use_custom_user_dir|custom_user_dir_name|project_settings_override)\.", body):
        raise ValueError("Feature-specific data path settings require explicit isolation support")
    body = re.sub(r"(?m)^config/(?:name|use_custom_user_dir|custom_user_dir_name|project_settings_override|disable_project_settings_override)=.*\n?", "", body)
    # Godot also disables CLI --script when disable_project_settings_override is
    # true. Keep CLI tests enabled; the overlay has no override.cfg/project.binary
    # and its explicit external override path is empty.
    isolated = ('config/name=' + json.dumps(app_name) + '\nconfig/use_custom_user_dir=false\n'
                'config/disable_project_settings_override=false\nconfig/project_settings_override=""\n')
    config = config[:section.start(1)] + isolated + body + config[section.end(1):]
    config = config.replace("[autoload]\n", '[autoload]\nReview2Isolation="*res://scripts/tests/review2_isolated_user_guard.gd"\n', 1)
    if 'Review2Isolation="*res://' not in config:
        raise ValueError("Missing autoload section for the fail-closed guard")
    (project / "project.godot").write_text(config, encoding="utf-8", newline="\n")
    links = [{"source": str(source / name), "destination": str(project / name)}
             for name in RESOURCE_DIRS if (source / name).is_dir()]
    links.append({"source": str(source / ".godot"), "destination": str(project / ".godot")})
    spec = container / "links.json"
    spec.write_text(json.dumps(links), encoding="utf-8")
    if os.name == "nt":
        setup = container / "create_links.ps1"
        setup.write_text('$ErrorActionPreference="Stop"\n'
                         '$links=Get-Content -LiteralPath $env:SB_REVIEW2_LINK_SPEC -Raw | ConvertFrom-Json\n'
                         'foreach($link in $links){New-Item -ItemType Junction -Path $link.destination -Target $link.source | Out-Null}\n', encoding="utf-8")
        env = dict(os.environ, SB_REVIEW2_LINK_SPEC=str(spec))
        subprocess.run(["powershell.exe", "-NoProfile", "-NonInteractive", "-File", str(setup)], env=env, check=True, capture_output=True)
    else:
        for link in links:
            Path(link["destination"]).symlink_to(link["source"], target_is_directory=True)
    for pattern in ("*.svg", "*.tres", "*.res", "*.gdextension"):
        for resource in source.glob(pattern):
            shutil.copy2(resource, project / resource.name)
            # Root resources need their import remap as well as the shared cache.
            # Without it Godot cannot load e.g. icon.svg in an otherwise valid
            # isolated project. Copy only metadata adjacent to copied resources.
            remap = resource.with_name(resource.name + ".import")
            if remap.is_file():
                shutil.copy2(remap, project / remap.name)
    (project / "output").mkdir()
    (project / "tmp").mkdir()
    return project, app_name


def run_case(source: Path, output: Path, case: dict, baseline: dict, godot: str, timeout: float) -> dict:
    before = check_roster(baseline)
    run_id = uuid.uuid4().hex
    project, app_name = create_overlay(source, run_id)
    user_root = Path(os.environ["APPDATA"]) / "Godot" / "app_userdata" / app_name
    if user_root.exists():
        raise RuntimeError("Isolated user directory is not fresh")
    env = dict(os.environ, SB_REVIEW2_USER_DIR=str(user_root))
    log = output / (case["name"] + ".log")
    argv = [godot, "--headless", "--path", str(project), "--script", str(project / case["script"].removeprefix("res://"))]
    if case.get("args"):
        argv += ["--", *case["args"]]
    timed_out = False
    code = -1
    try:
        with log.open("w", encoding="utf-8") as stream:
            try:
                code = subprocess.run(argv, env=env, stdout=stream, stderr=subprocess.STDOUT,
                                      timeout=float(case.get("timeout", timeout)), check=False).returncode
            except subprocess.TimeoutExpired:
                timed_out = True
    finally:
        after = check_roster(baseline)
    text = ANSI.sub("", log.read_text(encoding="utf-8", errors="replace"))
    errors = ERROR.findall(text)
    marker = case.get("success_marker", "")
    isolated = "REVIEW2_ISOLATED_USER_DATA " in text and (user_root / "review2_isolation_canary.json").is_file()
    marker_found = not marker or marker in text
    passed = code == 0 and not timed_out and not errors and isolated and marker_found
    result = {"name": case["name"], "passed": passed, "exit_code": code, "timed_out": timed_out,
              "error_count": len(errors), "errors": errors[:20], "marker_found": marker_found,
              "isolation_verified": isolated, "user_dir": str(user_root), "project": str(project),
              "roster_before": before, "roster_after": after, "log": str(log), "argv": argv}
    print(case["name"] + ": " + ("PASS" if passed else "FAIL") + " (exit " + str(code) + ")", flush=True)
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", default=str(Path(__file__).resolve().parents[2]))
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument("--script")
    selection.add_argument("--manifest")
    parser.add_argument("--filter")
    parser.add_argument("--success-marker", default="")
    parser.add_argument("--timeout", type=float, default=120)
    parser.add_argument("--godot", default="godot_console.exe")
    parser.add_argument("--output", default="output/review2_fixes_20261102/runs")
    parser.add_argument("--baseline", default="output/review2_fixes_20261102/roster_baseline.json")
    parser.add_argument("args", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    source = Path(args.project).resolve()
    baseline_path = Path(args.baseline)
    if not baseline_path.is_absolute(): baseline_path = source / baseline_path
    baseline = json.loads(baseline_path.read_text(encoding="utf-8-sig"))
    check_roster(baseline)
    if args.manifest:
        manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8-sig"))
        if manifest.get("version") != 1: raise ValueError("Unsupported manifest version")
        cases = manifest["checks"]
    else:
        cases = [{"name": Path(args.script).stem, "script": args.script, "success_marker": args.success_marker,
                  "args": args.args[1:] if args.args[:1] == ["--"] else args.args}]
    if args.filter: cases = [case for case in cases if args.filter in case["name"]]
    if not cases: raise ValueError("No selected checks")
    for case in cases:
        path = Path(case["script"].removeprefix("res://"))
        if path.is_absolute() or ".." in path.parts or not (source / path).is_file():
            raise ValueError("Test script must be an existing project resource")
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", case["name"]):
            raise ValueError("Unsafe check name")
    output = Path(args.output)
    if not output.is_absolute(): output = source / output
    output /= datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    output.mkdir(parents=True, exist_ok=False)
    project_hash = hashlib.sha256((source / "project.godot").read_bytes()).hexdigest()
    results = []
    for case in cases:
        results.append(run_case(source, output, case, baseline, args.godot, args.timeout))
    if hashlib.sha256((source / "project.godot").read_bytes()).hexdigest() != project_hash:
        raise RuntimeError("Source project settings changed")
    final_roster = check_roster(baseline)
    report = {"schema": "sternenbuergerchen.review2_isolated_checks.v1", "checks": results,
              "summary": {"selected": len(results), "passed": sum(r["passed"] for r in results),
                          "failed": sum(not r["passed"] for r in results)},
              "source_project_sha256": project_hash, "protected_roster": final_roster,
              "all_user_dirs_unique": len({r["user_dir"] for r in results}) == len(results)}
    (output / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(str(report["summary"]) + "; report: " + str(output / "report.json"), flush=True)
    return 0 if all(r["passed"] for r in results) else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        print("ISOLATED_RUN_REFUSED: " + str(error), file=sys.stderr)
        sys.exit(2)
