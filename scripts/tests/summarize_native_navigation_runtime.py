"""Verify runtime integration evidence and aggregate paired command ticks."""
import hashlib
import json
import math
import statistics
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / "docs/qa/native_navigation_runtime_20261114"


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def stats(values):
    ordered = sorted(values)
    return {"count": len(values), "median_ms": statistics.median(values) / 1000,
            "mean_ms": statistics.mean(values) / 1000,
            "p95_ms": ordered[math.ceil(len(values) * .95) - 1] / 1000,
            "max_ms": max(values) / 1000, "sum_ms": sum(values) / 1000}


def main():
    hashes, document_updates = {}, {}
    for run in ["native_suite_project_v2", "fallback_suite_project", "benchmark_a", "benchmark_b"]:
        manifest = read(QA / run / "source_manifest.json")
        for rel, digest in manifest["source_sha256"].items():
            actual = hashlib.sha256((ROOT / rel).read_bytes()).hexdigest()
            if actual != digest and rel == "docs/IMPLEMENTATION_STATUS.md":
                # Status-only prepend after the tests; the historical task476
                # references and every executable/tested byte remain unchanged.
                prior = subprocess.check_output(["git", "show", manifest["source_head"] + ":" + rel], cwd=ROOT)
                assert hashlib.sha256(prior).hexdigest() == digest
                assert (ROOT / rel).read_bytes().endswith(prior.split(b"\n\n", 1)[1])
                document_updates[rel] = {"tested_sha256": digest, "current_sha256": actual, "change": "completion status prepended after checks"}
            else:
                assert actual == digest, (run, rel)
                hashes[rel] = digest
    reports = []
    for group, count in [("native_checks", 8), ("fallback_checks", 2)]:
        files = list((QA / group).glob("*/metadata/report.json"))
        assert len(files) == 1, group
        report = read(files[0])
        assert len(report["checks"]) == count
        assert all(c["passed"] and not c["error_count"] and c["marker_found"] for c in report["checks"])
        reports.append(files[0].relative_to(ROOT).as_posix())
    for name, count in [("runtime_native", 172), ("mission_load_native", 24), ("native_parity", 1381),
                        ("runtime_fallback", 168), ("load_fallback", 23), ("hex_movement", 25)]:
        data = read(QA / (name + ".json"))
        assert data["passed"] == count and data["failed"] == 0, name
    groups, preparation, series = {}, {}, []
    for run in ["benchmark_a", "benchmark_b"]:
        data = read(QA / run / "result.json")
        assert data["passed"] and not data["failures"] and data["pair_count"] == 16
        for row in data["rows"]:
            assert all(row[key] for key in ["full_runtime_result_equal", "native_used_without_result_cache",
                       "preloaded_snapshots_reused", "terrain_unchanged", "nonempty_route"])
            groups.setdefault(row["fixture"], []).append(row)
        for row in data["preparation"]:
            preparation.setdefault(row["fixture"] + "/" + row["backend"], []).append(row["usec"])
        for fixture in ["hex24", "gm01"]:
            rows = [r for r in data["rows"] if r["fixture"] == fixture]
            prep = {p["backend"]: p["usec"] for p in data["preparation"] if p["fixture"] == fixture}
            series.append({"run": run, "fixture": fixture,
                           "gdscript_load_plus_eight_ticks_ms": (prep["gdscript"] + sum(r["gdscript_tick_usec"] for r in rows)) / 1000,
                           "native_load_plus_eight_ticks_ms": (prep["native"] + sum(r["native_tick_usec"] for r in rows)) / 1000})
    summaries = {}
    for name, rows in groups.items():
        gd = stats([r["gdscript_tick_usec"] for r in rows])
        native = stats([r["native_tick_usec"] for r in rows])
        summaries[name] = {"gdscript": gd, "native": native,
                           "median_speedup": gd["median_ms"] / native["median_ms"], "small_sample_warning": True}
    build = read(ROOT / "docs/qa/native_navigation_dynamic_costs_20261114/build_manifest.json")
    for rel, digest in build["files_sha256"].items():
        assert hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() == digest, rel
    result = {"accepted_reports": reports, "verified_source_asset_dll_sha256": hashes,
              "documentation_after_tests": document_updates,
              "native_build": "C++ sources/DLL unchanged from docs/qa/native_navigation_dynamic_costs_20261114/build_manifest.json",
              "all_command_pairs_equal": sum(map(len, groups.values())), "command_ticks": summaries,
              "loading_preparation": {k: stats(v) for k, v in preparation.items()}, "load_plus_commands": series,
              "scope": "Two fresh-process runs; eight command ticks per map/run; preparation includes each owner's graph and native snapshots. Tick includes scoring/world-path conversion/first motion. Simple units and headless mode; no complete visual playthrough or FPS claim."}
    (QA / "comparison.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    for name, value in summaries.items():
        print(f'{name}: {value["gdscript"]["median_ms"]:.4f} -> {value["native"]["median_ms"]:.4f} ms; x{value["median_speedup"]:.2f}; n={value["native"]["count"]}')
    print("32 exact command pairs; 8 native + 2 DLL-free gates; executable source hashes match")


if __name__ == "__main__":
    main()
