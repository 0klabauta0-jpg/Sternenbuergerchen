"""Sequential real Godot viewport captures; never paint a substitute image."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
CASES = [(view, "1920x1080") for view in (
    "main_menu", "mission", "homebase", "fob", "characters", "teameditor",
    "lobby", "settings", "debrief", "editor", "escape",
)] + [(view, "1280x720") for view in (
    "mission", "settings", "homebase", "fob", "debrief", "lobby",
)]


def main():
	# Optional view filter lets a changed screen be recaptured without repeating
	# unrelated successful captures. The default reproduces the complete set.
    parser = argparse.ArgumentParser()
    parser.add_argument("--views", nargs="+")
    selected = parser.parse_args().views
    logs = QA / "capture_logs"
    logs.mkdir(exist_ok=True)
    result_path = QA / "capture_results.json"
    results = json.loads(result_path.read_text()) if result_path.exists() else []
    for view, size in CASES:
        if selected and view not in selected:
            continue
        command = [
            "godot_console", "--path", str(ROOT), "--rendering-method", "gl_compatibility",
            "--audio-driver", "Dummy", "--script", "res://scripts/tests/ui_native_capture.gd", "--",
            "--view=" + view, "--size=" + size, "--logical-size=" + size,
            "--output=res://docs/qa/ui_native_r2_20261101/captures",
            "--fixture-scope=ui_native_r2_capture",
        ]
        start = time.monotonic()
        process = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        log = process.stdout.decode("utf-8", errors="replace")
        (logs / (view + "_" + size + ".log")).write_bytes(process.stdout)
        matches = re.findall(r"^CAPTURE: (.+)$", log, re.MULTILINE)
        evidence = json.loads(matches[-1]) if matches else {}
        errors = re.findall(r"(?im)^(?:SCRIPT ERROR:|ERROR:|.*ObjectDB instances leaked|.*Resources still in use)", log)
        passed = process.returncode == 0 and bool(evidence) and not errors and evidence.get("save_error") == 0
        passed = passed and evidence.get("source_capture") is True and evidence.get("synthetic_image_fallback") is False
        passed = passed and evidence.get("scaled_capture") is False and evidence.get("logical_size") == [int(part) for part in size.split("x")]
        record = {"view": view, "size": size, "passed": passed, "exit_code": process.returncode,
                  "error_count": len(errors), "duration_seconds": round(time.monotonic() - start, 3), "evidence": evidence}
        if passed:
            png = QA / "captures" / (view + "_" + size + ".png")
            record["image_sha256"] = hashlib.sha256(png.read_bytes()).hexdigest()
        results = [old for old in results if (old["view"], old["size"]) != (view, size)] + [record]
        print(f"{view} {size}: {'PASS' if passed else 'FAIL'}", flush=True)
        (QA / "capture_results.json").write_bytes((json.dumps(results, indent=2) + "\n").encode())
        if not passed:
            raise SystemExit(1)


if __name__ == "__main__":
    main()
