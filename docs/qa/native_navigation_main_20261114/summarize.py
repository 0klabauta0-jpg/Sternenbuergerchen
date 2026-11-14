"""Validate accepted Main-integration evidence, rejecting superseded/empty gates."""
import hashlib
import json
import re
import statistics
from pathlib import Path

QA = Path(__file__).resolve().parent
ROOT = QA.parents[2]


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    accepted, hashes, superseded = [], {}, {}
    replacement = read(QA / "neighbors_a/project/source_manifest.json")["source_sha256"]
    replaced_tests = {"scripts/tests/task_476_fireteam_corridor_lane_cover_navigation.gd",
                      "scripts/tests/hex_base_personnel_owner_verifier.gd"}
    status_update = read(QA / "status_update.json") if (QA / "status_update.json").exists() else {}
    for name, folder in [("native_c", "project/"), ("neighbors_a", "project/"),
                         ("fallback_b", "project/"), ("checkpoint", ""),
                         ("benchmark_a", ""), ("benchmark_b", "")]:
        manifest = read(QA / name / (folder + "source_manifest.json"))
        assert read(QA / name / (folder + "import_process.json"))["exit_code"] == 0
        for rel, old_hash in manifest["source_sha256"].items():
            current = digest(ROOT / rel)
            if current != old_hash and rel in replaced_tests:
                assert replacement[rel] == current
                superseded[rel] = {"tested_before": old_hash, "accepted_retest": current}
            elif current != old_hash and rel == "docs/IMPLEMENTATION_STATUS.md":
                assert status_update.get("before_sha256") == old_hash and status_update.get("after_sha256") == current
            else:
                assert current == old_hash, (name, rel)
            hashes[rel] = current
    for run, names in [
        ("native_c", ["main_integration", "runtime", "mission_load", "native_parity", "door_revision",
                      "movement_fallback", "hex_movement", "command_lifecycle", "hex_authoritative", "hex_ship", "hex_movement_save"]),
        ("neighbors_a", ["corridor_lane_cover", "hex_base", "hex_boarding"]),
        ("fallback_b", ["main_integration", "runtime_fallback", "load_fallback"]),
    ]:
        files = list((QA / run / "checks").glob("*/metadata/report.json"))
        assert len(files) == 1
        checks = {c["name"]: c for c in read(files[0])["checks"]}
        for name in names:
            c = checks[name]
            assert c["passed"] and c["marker_found"] and c["error_count"] == 0
            log = files[0].parents[1] / "logs" / ("check-" + name + ".log")
            assert not re.search(r"\b0 passed, 0 failed\b", log.read_text(encoding="utf-8"))
            accepted.append({"run": run, "check": name, "report": files[0].relative_to(QA).as_posix()})
    checkpoint_log = (QA / "checkpoint/run.log").read_text(encoding="utf-8")
    assert "HEX_ROOT_CHECKPOINT_INTEGRATION passed=10 failed=0" in checkpoint_log
    assert read(QA / "checkpoint/run_process.json")["exit_code"] == 0
    assert not any(s in checkpoint_log for s in ["SCRIPT ERROR", "ERROR:", "instances leaked", "resources still in use"])
    accepted.append({"run": "checkpoint", "check": "hex_root_checkpoint", "assertions": 10})
    assert len(accepted) == 18
    for run, native, assertions in [("native_c", True, 668), ("fallback_b", False, 654)]:
        result = read(QA / run / "main.json")
        assert result["expect_native"] == native and result["passed"] == assertions and not result["failed"]
        assert len(result["runtime_pairs"]) == 4 and result["slice_pairs"] == 245
    groups, preparations, series = {}, {}, []
    for run in ["benchmark_a", "benchmark_b"]:
        data = read(QA / run / "result.json")
        assert data["passed"] and not data["failures"] and data["pair_count"] == 16
        for row in data["rows"]:
            assert all(row[k] for k in ["full_runtime_trace_equal", "scores_equal", "arrived", "native_used", "preloaded_snapshot_reused", "budget_bounded"])
            assert row["path_nodes"] > 1 and row["native_slices"] > 0
            groups.setdefault(row["fixture"], []).append(row)
        for fixture in ["ramps", "gm01"]:
            prep = {r["backend"]: r["usec"] for r in data["preparation"] if r["fixture"] == fixture}
            for backend, usec in prep.items(): preparations.setdefault(fixture + "/" + backend, []).append(usec / 1000)
            rows = [r for r in data["rows"] if r["fixture"] == fixture]
            series.append({"run": run, "fixture": fixture, **{backend + "_load_plus_eight_commands_ms": (usec + sum(r[backend + "_total_tick_usec"] for r in rows)) / 1000 for backend, usec in prep.items()}})
    timings = {}
    for fixture, rows in groups.items():
        timings[fixture] = {"command_pairs": len(rows), "small_sample_warning": True,
                           **{k + "_median_ms": statistics.median(r[k] for r in rows) / 1000 for k in ["gdscript_navigation_tick_usec", "native_navigation_tick_usec", "gdscript_total_tick_usec", "native_total_tick_usec"]}}
    build = read(QA / "build_manifest.json")
    for rel, h in build["files_sha256"].items(): assert digest(ROOT / rel) == h, rel
    result = {"accepted_gates": accepted, "gate_count": 18, "main_native_assertions": 668,
              "main_fallback_assertions": 654, "native_slice_pairs": 245, "benchmark_command_pairs": 32,
              "timings_per_complete_command": timings, "preparation_ms": preparations,
              "preparation_plus_eight_commands": series, "current_source_asset_dll_sha256": hashes,
              "superseded_fixture_tests": superseded, "documentation_after_tests": status_update,
              "rejected_runs": {"native_a/native_b": "Editor import crashed with 0xc0000005; no accepted checks",
                                "fallback_a": "Initial fixture typed-array and obsolete HPA assumptions; superseded",
                                "native_c/corridor_lane_cover,hex_boarding": "Missing Main interfaces in test doubles; superseded by neighbors_a",
                                "native_c/mission_restore": "Zero assertions: runner marker alone is insufficient; replaced by checkpoint/10 assertions"}}
    (QA / "comparison.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print("18 accepted nonempty gates; 245 native slice pairs; 32 exact command pairs; all current source/DLL hashes verified")
    print(json.dumps(timings))


if __name__ == "__main__":
    main()
