"""Run only the selected mission regression gates, sequentially in new evidence."""
import argparse
import subprocess
import sys
from pathlib import Path

from _qa_common import QA, ROOT, isolated_profile, new_run_dir, write_json

NAMESPACE = "SternenBuergerchen_Mission_A5_Edge_Contracts"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot_console")
    parser.add_argument("--filter", help="Run only matching names from this round's selected mission gates.")
    parser.add_argument("--skip-import", action="store_true", help="Only after a successful import of the same unchanged checkout.")
    args = parser.parse_args()
    runner = Path.home() / ".codex/skills/godot-game-verification/scripts/run_checks.py"
    assert runner.is_file(), runner
    run = new_run_dir("headless")
    command = [sys.executable, str(runner), "--project", str(ROOT), "--manifest", str(QA / "checks_final.json"), "--godot", args.godot, "--output", str(run / "checks")]
    if args.filter:
        command.extend(["--filter", args.filter])
    if args.skip_import:
        command.append("--skip-import")
    profile = {}
    try:
        with isolated_profile(NAMESPACE) as profile:
            process = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=900)
    except subprocess.TimeoutExpired as exc:
        (run / "runner.log").write_bytes(exc.stdout or b"")
        write_json(run / "profile_isolation.json", {**profile, "command": command, "timed_out": True, "exit_code": None})
        raise
    (run / "runner.log").write_bytes(process.stdout)
    write_json(run / "profile_isolation.json", {**profile, "command": command, "exit_code": process.returncode})
    print(process.stdout.decode("utf-8", errors="replace"))
    print(f"Evidence: {run}", flush=True)
    raise SystemExit(process.returncode)


if __name__ == "__main__":
    main()
