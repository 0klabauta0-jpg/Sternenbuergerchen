"""Prepare by default; --execute runs the frozen, bounded AP6/AP7/AP8 cases serially."""
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
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs/qa/ap678_bundle_20261112/manifest.json"
ERROR = re.compile(r"^(?:ERROR:|SCRIPT ERROR:|Parse Error:|Compile Error:)|ObjectDB instances leaked|resources still in use", re.M)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute", action="store_true", help="Actually run the later frozen integration block")
    parser.add_argument("--extended", action="store_true", help="Explicitly include older neighbor guards; not the default")
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    checks = manifest["checks"] + (manifest["extended_checks"] if args.extended else [])
    if not args.execute:
        print(json.dumps({"status": "prepared_not_run", "manifest": str(MANIFEST),
                          "cases": checks, "extended": args.extended, "pending": manifest["pending"]}, indent=2))
        return 0

    run = ROOT / "output/native_glut_maps/ap678_bundle_20261112" / uuid.uuid4().hex
    run.mkdir(parents=True)
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    report = {"status": "running", "head": head, "manifest_sha256": sha(MANIFEST),
              "runner_sha256": sha(Path(__file__)), "extended": args.extended, "cases": [], "pending": manifest["pending"],
              "full_ap7": False, "full_ap8": False, "native_acceptance": False}
    report_path = run / "report.json"

    def save() -> None:
        report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    save()
    engine = shutil.which("godot_console.exe")
    try:
        if not engine:
            raise RuntimeError("godot_console.exe unavailable")
        probe = subprocess.run([engine, "--version"], capture_output=True, text=True, timeout=10)
        report["engine_version"] = probe.stdout.strip()
        if probe.returncode or not probe.stdout.strip().startswith("4.6.2"):
            raise RuntimeError("Godot 4.6.2 probe failed")
    except (OSError, ValueError, subprocess.TimeoutExpired, RuntimeError) as exc:
        report.update(status="blocked", issue=str(exc))
        save()
        print(report_path)
        return 1

    frozen_sources: dict[str, str] = {}
    failed = False
    for index, case in enumerate(checks):
        destination = run / (str(index + 1).zfill(2) + "-" + case["name"])
        destination.mkdir()
        entry = {"name": case["name"], "status": "running", "command": [sys.executable] + case["argv"]}
        report["cases"].append(entry)
        # Archive fixed evidence paths before the existing specialist overwrites them.
        for relative in case.get("archive_before", []):
            original = ROOT / relative
            if original.is_file():
                archived = destination / "prior_evidence" / relative
                archived.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(original, archived)
        before = {str(p): [p.stat().st_mtime_ns, sha(p)] for p in ROOT.glob(case["report_glob"]) if p.is_file()}
        started = time.monotonic()
        try:
            if any(not (ROOT / p).is_file() or sha(ROOT / p) != digest for p, digest in frozen_sources.items()):
                raise RuntimeError("Source changed between cases; freeze again before any retry")
            with (destination / "runner.log").open("w", encoding="utf-8") as stream:
                child = subprocess.Popen(entry["command"], cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT,
                                         env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
                try:
                    exit_code = child.wait(timeout=case["timeout_seconds"])
                except subprocess.TimeoutExpired:
                    # Kill this runner's descendants too, so another case never overlaps it.
                    if os.name == "nt":
                        subprocess.run(["taskkill", "/PID", str(child.pid), "/T", "/F"], capture_output=True)
                    else:
                        child.kill()
                    child.wait(timeout=10)
                    raise RuntimeError("Case exceeded bundle timeout; stopped, no subsequent case")
            entry["exit_code"] = exit_code
            fresh = [p for p in ROOT.glob(case["report_glob"]) if p.is_file()
                     and before.get(str(p)) != [p.stat().st_mtime_ns, sha(p)]]
            if len(fresh) != 1:
                raise RuntimeError("Expected exactly one fresh child report, got " + str(len(fresh)))
            original = fresh[0]
            data = json.loads(original.read_text(encoding="utf-8"))
            shutil.copy2(original, destination / "child_report.json")
            entry.update(child_report=str(original), child_report_sha256=sha(original))
            if exit_code != 0 or any(data.get(field) is not True for field in case["true_fields"]):
                raise RuntimeError("Child exit or required source/profile/canary/pass guard failed")
            for code in data.get("exit_codes", {}).values():
                if code != 0:
                    raise RuntimeError("Child process exit failed")
            hashes = data.get("workspace_source_sha256", data.get("source_sha256", {}))
            if not hashes:
                raise RuntimeError("Child supplied no source provenance")
            for relative, digest in hashes.items():
                source = ROOT / relative
                if source.is_file():
                    if sha(source) != digest or (relative in frozen_sources and frozen_sources[relative] != digest):
                        raise RuntimeError("Source provenance changed: " + relative)
                    frozen_sources[relative] = digest
            refs = data.get("dependency_source_refs", {})
            if any(value != head for value in refs.values()):
                raise RuntimeError("Cross-branch dependency pin is not a current Parent integration pass")
            logs = [original.parent / name for name in case["logs"]]
            for log in logs:
                text = log.read_text(encoding="utf-8", errors="replace")
                normalized = "\n".join(line.lstrip() for line in re.sub(r"\x1b\[[0-9;]*m", "", text).splitlines())
                if ERROR.search(normalized):
                    raise RuntimeError("Engine error or leak in child log: " + str(log))
                shutil.copy2(log, destination / log.name)
            entry["status"] = "passed"
        except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as exc:
            entry.update(status="failed", issue=str(exc))
            failed = True
        entry["elapsed_seconds"] = round(time.monotonic() - started, 3)
        save()
        print(case["name"] + ": " + entry["status"], flush=True)
        if failed:
            break
    report["not_run"] = [case["name"] for case in checks[len(report["cases"]):]]
    report["source_sha256"] = frozen_sources
    report["status"] = "failed" if failed else ("partial_pending" if manifest["pending"] else "selected_checks_passed")
    save()
    print(report_path)
    return 1 if failed else (2 if manifest["pending"] else 0)


if __name__ == "__main__":
    raise SystemExit(main())
