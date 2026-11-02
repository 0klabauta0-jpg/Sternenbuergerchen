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
CASES = [(view, "standard", size) for size in ("1920x1080", "1280x720")
         for view in ("fob", "homebase", "debrief", "mission")]
CASES += [("debrief", "empty", "1920x1080"), ("debrief", "rich", "1920x1080"),
          ("fob", "populated", "1920x1080"), ("homebase", "teams", "1920x1080"), ("debrief", "partial", "1920x1080")]


def main():
	# Optional view filter lets a changed screen be recaptured without repeating
	# unrelated successful captures. The default reproduces the complete set.
    parser = argparse.ArgumentParser()
    parser.add_argument("--views", nargs="+")
    parser.add_argument("--variants", nargs="+")
    args = parser.parse_args()
    selected = args.views
    logs = QA / "capture_logs"
    logs.mkdir(exist_ok=True)
    result_path = QA / "capture_results.json"
    results = json.loads(result_path.read_text()) if result_path.exists() else []
    for view, variant, size in CASES:
        if selected and view not in selected:
            continue
        if args.variants and variant not in args.variants:
            continue
        command = [
            "godot_console", "--path", str(ROOT), "--rendering-method", "gl_compatibility",
            "--audio-driver", "Dummy", "--script", "res://scripts/tests/ui_native_capture.gd", "--",
            "--view=" + view, "--variant=" + variant, "--size=" + size, "--logical-size=" + size,
            "--output=res://docs/qa/ui_native_r3_20261102/captures",
            "--fixture-scope=ui_native_r3_capture",
        ]
        start = time.monotonic()
        process = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        log = process.stdout.decode("utf-8", errors="replace")
        (logs / (view + "_" + variant + "_" + size + ".log")).write_bytes(process.stdout)
        matches = re.findall(r"^CAPTURE: (.+)$", log, re.MULTILINE)
        evidence = json.loads(matches[-1]) if matches else {}
        errors = re.findall(r"(?im)^(?:SCRIPT ERROR:|ERROR:|.*ObjectDB instances leaked|.*Resources still in use)", log)
        passed = process.returncode == 0 and bool(evidence) and not errors and evidence.get("save_error") == 0
        passed = passed and evidence.get("source_capture") is True and evidence.get("synthetic_image_fallback") is False
        passed = passed and evidence.get("scaled_capture") is False and evidence.get("logical_size") == [int(part) for part in size.split("x")]
        if view == "debrief" and evidence:
            metrics = evidence.get("ui_metrics", {})
            row = metrics.get("return_row", {}).get("rect", [])
            slot = metrics.get("return_slot", {}).get("rect", [])
            card = metrics.get("return_card", {}).get("rect", [])
            footer_valid = len(row) == len(slot) == len(card) == 4
            if footer_valid:
                footer_valid = all(abs(a - b) <= 1 for a, b in zip(row, slot))
                footer_valid = footer_valid and row[0] >= card[0] and row[1] >= card[1] and row[0] + row[2] <= card[0] + card[2] + 1 and row[1] + row[3] <= card[1] + card[3] + 1
            passed = passed and footer_valid
        record = {"view": view, "variant": variant, "file": view + ("_" + variant if variant != "standard" else "") + "_" + size, "size": size, "passed": passed, "exit_code": process.returncode,
                  "error_count": len(errors), "duration_seconds": round(time.monotonic() - start, 3), "evidence": evidence}
        if passed:
            png = QA / "captures" / (record["file"] + ".png")
            record["image_sha256"] = hashlib.sha256(png.read_bytes()).hexdigest()
        results = [old for old in results if (old["view"], old["variant"], old["size"]) != (view, variant, size)] + [record]
        print(f"{view} {variant} {size}: {'PASS' if passed else 'FAIL'}", flush=True)
        (QA / "capture_results.json").write_bytes((json.dumps(results, indent=2) + "\n").encode())
        if not passed:
            raise SystemExit(1)


if __name__ == "__main__":
    main()
