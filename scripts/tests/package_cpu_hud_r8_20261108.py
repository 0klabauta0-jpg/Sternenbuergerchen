"""Package finished R8 runs without modifying prior evidence or starting engines."""
from __future__ import annotations

import json
from pathlib import Path
import shutil

import package_runtime_hitches_r4_20261107 as shared
import package_cpu_hud_r7_20261108 as previous_package
from run_cpu_hud_r7_20261108 import EXTRA_INPUTS as R7_INPUTS
from run_cpu_hud_r6_20261108 import EXTRA_INPUTS as R6_INPUTS
from run_cpu_hud_r8_20261108 import EXTRA_INPUTS
from run_cpu_hud_r5_20261108 import EXTRA_INPUTS as PREVIOUS_INPUTS

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "output/cpu_hud_r8_20261108"
QA = ROOT / "docs/qa/cpu_hud_r8_20261108"


def preservation() -> dict:
    result = previous_package.preservation()
    extra = shared.load_json(OUT / "preserved_start.json")
    issues = []
    for entry in extra:
        actual = shared.pin_file(shared.confined_file(entry["path"]))
        if actual != {key: entry[key] for key in ("size", "sha256", "mtime_ns")}:
            issues.append({"path": entry["path"], "expected": entry, "actual": actual})
    result["additional_start_count"] = len(extra)
    result["additional_issues"] = issues
    result["passed"] = result["passed"] and not issues
    return result


def only_run(label: str) -> Path:
    runs = list((shared.RAW / label).glob("*/report.json"))
    if len(runs) != 1:
        raise ValueError("Expected exactly one selected run: " + label)
    return runs[0].parent


def main() -> int:
    shared.QA = QA
    generated = [QA / name for name in ("raw_evidence.zip", "manifest.json", "source_binding.json", "preservation_report.json")]
    for path in generated:
        if path.exists():
            raise FileExistsError("Preserve existing output: " + str(path))
    proof = preservation()
    if not proof["passed"]:
        raise RuntimeError("Preservation failed; no automatic restoration")
    required = {"cpu_hud_r8_final_regression_v2": 93, "cpu_hud_r8_native_before_retry": 1,
                "cpu_hud_r8_native_after_a": 1, "cpu_hud_r8_native_after_b": 1}
    results = {}
    for label, count in required.items():
        report = shared.load_json(only_run(label) / "report.json")
        if report["summary"] != {"selected": count, "passed": count, "failed": 0}:
            raise RuntimeError("Required final run is not green: " + label)
        results[label] = report["summary"]
    selected = sorted({item for item in (*PREVIOUS_INPUTS, *R6_INPUTS, *R7_INPUTS, *EXTRA_INPUTS) if item.endswith((".gd", ".py"))})
    for case in shared.load_json(ROOT / "scripts/tests/cpu_hud_r8_20261108_regression_manifest.json")["checks"]:
        selected.append(case["script"].removeprefix("res://"))
    selected.append(Path(__file__).resolve().relative_to(ROOT).as_posix())
    selected.append("scripts/tests/runtime_hitches_r4_20261107_gpu_capture.gd")
    binding = shared.source_binding(selected)
    manifest_path = "scripts/tests/cpu_hud_r8_20261108_regression_manifest.json"
    binding["files"][manifest_path] = shared.pin_file(ROOT / manifest_path)
    previous_manifest = "scripts/tests/cpu_hud_r5_20261108_regression_manifest.json"
    binding["files"][previous_manifest] = shared.pin_file(ROOT / previous_manifest)
    binding["files"]["scripts/tests/cpu_hud_r6_20261108_regression_manifest.json"] = shared.pin_file(ROOT / "scripts/tests/cpu_hud_r6_20261108_regression_manifest.json")
    for name, expected in shared.load_json(OUT / "dependency_binding.json").items():
        actual = shared.pin_file(ROOT / name)
        if actual["sha256"] != expected["sha256"]:
            raise RuntimeError("Inherited test dependency changed: " + name)
        binding["files"][name] = actual
    binding["files"]["scripts/tests/cpu_hud_r7_20261108_regression_manifest.json"] = shared.pin_file(ROOT / "scripts/tests/cpu_hud_r7_20261108_regression_manifest.json")
    binding["count"] = len(binding["files"])
    prior = shared.load_json(shared.R3)["files"]
    binding["added_after_r3"] = sorted(set(binding["files"]) - set(prior))
    QA.mkdir(parents=True, exist_ok=True)
    binding_pin = shared.write_json_new(QA / "source_binding.json", binding)
    paths = set()
    for directory in list(shared.RAW.glob("cpu_hud_r8_*")) + [OUT]:
        for path in directory.rglob("*"):
            if path.is_file() and path.suffix.lower() in {".json", ".log", ".txt", ".raw", ".md"}:
                paths.add(path)
    raw = shared.write_raw_archive(QA / "raw_evidence.zip", sorted(paths))
    captures = []
    run = only_run("cpu_hud_r8_native_after_b")
    images = [(run / "after_b_captures" / name, name) for name in ("02_homebase.png", "06_go_movement.png")]
    images.append((only_run("cpu_hud_r8_native_before_retry") / "before_retry_captures/06_go_movement.png", "before_go_movement.png"))
    for source, name in images:
        expected = shared.pin_file(source)
        target = QA / "captures" / name
        target.parent.mkdir(exist_ok=True)
        with source.open("rb") as reader, target.open("xb") as writer:
            shutil.copyfileobj(reader, writer, shared.BLOCK_BYTES)
        actual = shared.pin_file(target)
        if any(actual[key] != expected[key] for key in ("size", "sha256")):
            raise RuntimeError("Capture copy differs")
        captures.append({"path": target.relative_to(QA).as_posix(), "original": source.relative_to(ROOT).as_posix(), **actual})
    for relative, expected in binding["files"].items():
        if shared.pin_file(ROOT / relative) != expected:
            raise RuntimeError("Source changed while packaging: " + relative)
    proof = preservation()
    if not proof["passed"]:
        raise RuntimeError("Post-package preservation failed")
    protection_pin = shared.write_json_new(QA / "preservation_report.json", proof)
    shared.write_json_new(QA / "manifest.json", {
        "schema": "sternenbuergerchen.cpu_hud_r8.qa.v1", "passed": True,
        "passed_scope": "Original bytes/readback, source binding, required run guards and preservation; no isolated FPS acceptance.",
        "required_runs": results, "files": raw, "captures": captures,
        "source_binding": binding_pin, "preservation": protection_pin,
        "archive": {"path": "raw_evidence.zip", **shared.pin_file(QA / "raw_evidence.zip"), "streamed_readback_verified": True},
        "historical_failed_attempts_preserved": True,
    })
    print(json.dumps({"status": "R8_PACKAGE_PASS", "raw_files": len(raw), "bound_sources": binding["count"], "captures": len(captures)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
