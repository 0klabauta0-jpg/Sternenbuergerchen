"""Audit isolated reports, original-Main failures and immutable source hashes."""
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent


def counts(case):
    found = []
    for line in Path(case["log"]).read_text(encoding="utf-8").splitlines():
        match = re.search(r"(\d+) passed,\s*(\d+) failed|RESULT\s+passed=(\d+)\s+failed=(\d+)", line)
        if match:
            found.append((int(match[1] or match[3]), int(match[2] or match[4])))
        match = re.search(r"ALL (\d+) TESTS PASSED|TASK_1157 PASS \((\d+) checks\)", line)
        if match:
            found.append((int(match[1] or match[2]), 0))
        if "{" in line:
            try:
                obj = json.loads(line[line.index("{"):])
            except json.JSONDecodeError:
                continue
            if isinstance(obj, dict) and "passed" in obj and "failed" in obj:
                found.append((int(obj["passed"]), int(obj["failed"])))
    if found:
        return dict(zip(("passed", "failed"), found[-1]))
    assert "canary" in case["name"], case["name"]
    return {"passed": 0, "failed": 0}


def failures(case):
    return [line.strip() for line in Path(case["log"]).read_text(encoding="utf-8").splitlines()
            if "ERROR:" in line or "SCRIPT ERROR:" in line]


def main():
    final_path, = (OUT / "verified_final_suite").glob("*/report.json")
    final = json.loads(final_path.read_text())
    manifest = json.loads((ROOT / "scripts/tests/review7_20261103_checks.json").read_text())
    assert final["summary"]["selected"] == len(manifest["checks"])
    assert [c["name"] for c in final["checks"]] == [c["name"] for c in manifest["checks"]]
    expected = {"task_839_release_firefight_world_label_declutter",
                "task_1122_connected_mission_world_camera_exposure_contact_cluster_readability",
                "bugfix_multiplayer_lobby_setup_and_asset_catalog_followup"}
    bad = [c for c in final["checks"] if not c["passed"]]
    assert {c["name"] for c in bad} == expected
    baseline_cases = {}
    for phase in ("original_main_adjacent", "original_main_task839"):
        for p in (OUT / phase).glob("*/report.json"):
            for c in json.loads(p.read_text())["checks"]:
                baseline_cases[c["name"]] = c
    for c in bad:
        original = baseline_cases[c["name"]]
        assert counts(c) == counts(original), c["name"]
        assert failures(c) == failures(original), c["name"]
        assert c["exit_code"] == original["exit_code"] == 1 and not c["timed_out"]
        assert not original["timed_out"] and original["isolation_verified"]
    native_path = sorted((OUT / "native_render").glob("*/report.json"))[-1]
    native = json.loads(native_path.read_text())
    native_case, = native["checks"]
    assert native_case["passed"] and native_case["gpu_buffer_readback_verified"]
    assert len(native_case["captures"]) == 3
    native_log_stat = Path(native_case["log"]).stat()
    native_started_ns = getattr(native_log_stat, "st_birthtime_ns", native_log_stat.st_ctime_ns)
    assert native_started_ns > final_path.stat().st_mtime_ns, "Native replay must start after the final matrix report"
    baseline = json.loads((OUT / "roster_baseline.json").read_text())
    fingerprint = json.loads((OUT / "final_source_snapshot.json").read_text())
    context = json.loads((OUT / "source_context.json").read_text())
    for path, sha in fingerprint.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == sha, path
    cases, history = [], []
    for p in sorted(OUT.glob("**/report.json")):
        obj = json.loads(p.read_text())
        history.append({"report": str(p.relative_to(ROOT)), **obj["summary"]})
        for c in obj["checks"]:
            assert c["isolation_verified"] and not c["timed_out"], (p, c["name"])
            assert c["roster_before"] == c["roster_after"] == baseline["state"], p
            cases.append(c)
    assert len({c["user_dir"] for c in cases}) == len(cases)
    real = Path(baseline["roster_path"])
    state = {"sha256": hashlib.sha256(real.read_bytes()).hexdigest(), "length": real.stat().st_size,
             "mtime_ns": real.stat().st_mtime_ns}
    assert state == baseline["state"]
    checks = [{"name": c["name"], "passed": c["passed"], "assertions": counts(c), "log": c["log"]} for c in final["checks"]]
    new = [c for c in checks if c["name"].startswith("review7_")]
    summary = {"schema": "sternenbuergerchen.review7_fixes.v1", "base_commit": "668423dcf5b76a7b7bb1010ae59337376911522e",
        "tested_product_commit": context["tested_product_commit"],
        "branch": subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT).decode().strip(),
        "confirmed_fixes": 7, "final_report": str(final_path.relative_to(ROOT)), "final_gates": final["summary"],
        "new_regressions": {"gates": len(new), "passed": sum(c["assertions"]["passed"] for c in new), "failed": sum(c["assertions"]["failed"] for c in new)},
        "green_assertions": sum(c["assertions"]["passed"] for c in checks if c["passed"]),
        "all_assertions": {k: sum(c["assertions"][k] for c in checks) for k in ("passed", "failed")},
        "baseline_failures": [{"name": c["name"], "assertions": counts(c), "original_main_log": baseline_cases[c["name"]]["log"], "same_error_lines": True} for c in bad],
        "native_render": {"report": str(native_path.relative_to(ROOT)), "assertions": counts(native_case),
            "gpu_buffer_readback_verified": True, "captures": [{"path": str((native_path.parent / name).relative_to(ROOT)),
                "sha256": hashlib.sha256((native_path.parent / name).read_bytes()).hexdigest()} for name in native_case["captures"]]},
        "source_fingerprints": fingerprint, "protected_roster": state, "isolated_check_runs": len(cases),
        "all_user_dirs_unique": True, "history": history, "checks": checks,
        "limits": ["Headless behavior plus targeted native FoW buffers and PNGs; no whole-game, animation-pixel, FPS, GPU-performance or release acceptance.",
                   "V1 editor-map payload transport remains outside scope (TASK228).",
                   "FoW terrain revisions are atomic request-time samples; continuous motion is coalesced into subsequent work.",
                   "Preliminary baseline/matrix startup and headless/native startup briefly overlapped. The final matrix and final native replay run serially within this task; no comparative performance evidence uses the overlaps."]}
    (OUT / "verification_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({k: summary[k] for k in ("final_gates", "new_regressions", "green_assertions", "all_assertions", "isolated_check_runs")}))


if __name__ == "__main__":
    main()
