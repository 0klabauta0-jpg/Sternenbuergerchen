"""Real native fixture captures of FOB/Homebase/Debrief, in new evidence only."""
import argparse
import hashlib
import json
import re
import subprocess
import time

from _qa_common import ROOT, error_lines, isolated_profile, new_run_dir, res_path, write_json

NAMESPACE = "SternenBuergerchen_UI_Zielbild_Fixtures_QA"
CASES = [(view, variant, size)
         for size in ("1920x1080", "1280x720")
         for view, variants in (("fob", ("standard", "populated")), ("homebase", ("standard", "teams")), ("debrief", ("standard", "portraits")))
         for variant in variants]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--views", nargs="+", choices=["fob", "homebase", "debrief"])
    parser.add_argument("--variants", nargs="+", choices=["standard", "populated", "teams", "portraits"], default=["populated", "teams", "portraits"])
    parser.add_argument("--sizes", nargs="+", choices=["1920x1080", "1280x720"], default=["1920x1080", "1280x720"])
    parser.add_argument("--godot", default="godot_console")
    args = parser.parse_args()
    cases = [(view, variant, size) for view, variant, size in CASES if (not args.views or view in args.views) and variant in args.variants and size in args.sizes]
    if not cases:
        parser.error("No matching capture cases; populated is FOB, teams Homebase, portraits Debrief.")
    run = new_run_dir("fixtures")
    output = run / "captures"
    logs = run / "logs"
    output.mkdir()
    logs.mkdir()
    fixture_scope = "ui_zielbild_" + run.name
    records = []
    for view, variant, size in cases:
        basename = view + ("_" + variant if variant != "standard" else "") + "_" + size
        command = [args.godot, "--path", str(ROOT), "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy", "--script", "res://scripts/tests/ui_native_capture.gd", "--", "--view=" + view, "--variant=" + variant, "--size=" + size, "--logical-size=" + size, "--output=" + res_path(output), "--fixture-scope=" + fixture_scope]
        start = time.monotonic()
        profile = {}
        try:
            with isolated_profile(NAMESPACE) as profile:
                process = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        except subprocess.TimeoutExpired as exc:
            (logs / (basename + ".log")).write_bytes(exc.stdout or b"")
            write_json(logs / (basename + "_process.json"), {**profile, "command": command, "timed_out": True, "exit_code": None})
            raise
        log = process.stdout.decode("utf-8", errors="replace")
        (logs / (basename + ".log")).write_bytes(process.stdout)
        matches = re.findall(r"^CAPTURE: (.+)$", log, re.MULTILINE)
        evidence = json.loads(matches[-1]) if matches else {}
        errors = error_lines(log)
        dimensions = [int(part) for part in size.split("x")]
        png = output / (basename + ".png")
        passed = process.returncode == 0 and bool(evidence) and not errors and evidence.get("save_error") == 0
        passed = passed and evidence.get("source_capture") is True and evidence.get("synthetic_image_fallback") is False
        passed = passed and evidence.get("fixture_data") is True and evidence.get("scaled_capture") is False
        passed = passed and evidence.get("logical_size") == dimensions and evidence.get("image_size") == dimensions
        passed = passed and evidence.get("image") == res_path(png) and png.is_file()
        if passed:
            header = png.read_bytes()[:24]
            passed = header[:8] == b"\x89PNG\r\n\x1a\n" and [int.from_bytes(header[16:20], "big"), int.from_bytes(header[20:24], "big")] == dimensions
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
        record = {**profile, "view": view, "variant": variant, "file": basename, "size": size, "passed": passed, "exit_code": process.returncode, "error_count": len(errors), "error_lines": errors, "duration_seconds": round(time.monotonic() - start, 3), "fixture_scope": fixture_scope, "command": command, "evidence": evidence, "scope": "Real native controls with explicit fixture data; no normal mission, transport, campaign or visual-style acceptance."}
        if passed:
            record["image_sha256"] = hashlib.sha256(png.read_bytes()).hexdigest()
        records.append(record)
        write_json(run / "capture_results.json", records)
        print(f"{basename}: {'PASS' if passed else 'FAIL'}; {run}", flush=True)
        if not passed:
            raise SystemExit(1)
    print(f"Evidence: {run}", flush=True)


if __name__ == "__main__":
    main()
