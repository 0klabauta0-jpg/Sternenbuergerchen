"""Recompute dynamic-cost evidence; verify tested bytes and original workload."""
import hashlib
import json
import math
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / "docs/qa/native_navigation_dynamic_costs_20261114"
OLD = ROOT / "docs/qa/native_navigation_20261114/dynamic_options/result.json"


def stats(values):
    ordered = sorted(values)
    return {"count": len(values), "median_ms": statistics.median(values) / 1000,
            "mean_ms": statistics.mean(values) / 1000,
            "p95_ms": ordered[math.ceil(len(values) * .95) - 1] / 1000,
            "max_ms": max(values) / 1000, "sum_ms": sum(values) / 1000}


def summarize(rows):
    gd = stats([r["gdscript_usec"] for r in rows])
    native = stats([r["native_usec"] for r in rows])
    return {"gdscript": gd, "native": native,
            "median_speedup": gd["median_ms"] / native["median_ms"],
            "cumulative_speedup": gd["sum_ms"] / native["sum_ms"],
            "small_sample_warning": len(rows) < 20}


def main():
    old = json.loads(OLD.read_text())
    assert old["passed"] and not old["failures"]
    baseline = {(r["fixture"], r["sample"]): r for r in old["rows"]}
    hashes, groups, static_groups, series = {}, {}, {}, {}
    pair_count = 0
    for run in ["verify_first", "dynamic_a", "dynamic_b", "static_a", "static_b", "regression_hex"]:
        manifest = json.loads((QA / run / "source_manifest.json").read_text())
        for rel, digest in manifest["source_sha256"].items():
            assert hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() == digest, (run, rel)
            hashes[rel] = digest
        if run in ["verify_first", "regression_hex"]:
            continue
        data = json.loads((QA / run / "result.json").read_text())
        assert data["passed"] and not data["failures"]
        if run.startswith("static"):
            for row in data["pairs"]:
                assert row["ordered_path_and_status_equal"] and row["score_equal"] and row["native_used"]
                assert row["path_length"] > 0
                key = "/".join(row[k] for k in ["fixture", "algorithm", "mode"])
                static_groups.setdefault(key, []).append(row)
                pair_count += 1
            continue
        for row in data["rows"]:
            assert all(row[key] for key in ["ordered_path_status_score_equal", "native_used",
                       "one_terrain_snapshot", "one_hpa_snapshot", "new_query_context",
                       "both_result_cache_misses", "inputs_unchanged"])
            assert row["path_length"] > 0
            prior = baseline[(row["fixture"], row["sample"])]
            for key in ["from", "to", "options_variant_hex", "path_sha256", "status", "score"]:
                assert row[key] == prior[key], (run, row["fixture"], row["sample"], key)
            key = row["fixture"] + "/" + row["phase"]
            groups.setdefault(key, []).append(row)
            if row["phase"] == "successive_commands":
                subset = "first_cold_request" if row["cold_first_call"] else "following_requests"
                groups.setdefault(row["fixture"] + "/" + subset, []).append(row)
            pair_count += 1
        for key, value in data["summaries"].items():
            series.setdefault(key, []).append({
                "run": run,
                "gdscript_total_ms": value["gdscript"]["sum"] / 1000,
                "native_total_including_preparation_ms": value["native_total_including_preparation_usec"] / 1000,
                "native_preparation_excluded_from_queries_ms": value["native_preparation_usec_excluded_from_queries"] / 1000,
                "shared_graph_build_excluded_from_both_ms": value["graph_build_usec_excluded_from_both"] / 1000,
            })
    dynamic = {key: summarize(rows) for key, rows in groups.items()}
    for key, rows in groups.items():
        dynamic[key]["native_request_preparation"] = stats([r["native_debug"]["snapshot_prepare_usec"] for r in rows])
    result = {
        "accepted_runs": ["dynamic_a", "dynamic_b", "static_a", "static_b"],
        "all_source_hashes_match": hashes, "all_benchmark_pairs_exact": pair_count,
        "dynamic_workload_and_results_equal_original": True,
        "original_native_prototype": {"commit": "7a7cf80e3", "raw_file": OLD.relative_to(ROOT).as_posix(),
                                      "sha256": hashlib.sha256(OLD.read_bytes()).hexdigest(), "summaries": old["summaries"]},
        "dynamic": dynamic, "eight_query_series": series,
        "static": {key: summarize(rows) for key, rows in static_groups.items()},
        "scope": "Navigation only; paired GDS/native. Two repeated runs, eight original dynamic requests per phase/map. Cold first call and explicit preparation are included in series totals. Shared graph build is separately recorded. No FPS or significance claim.",
    }
    (QA / "comparison.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    for key, value in dynamic.items():
        print(f'{key}: {value["gdscript"]["median_ms"]:.4f} -> {value["native"]["median_ms"]:.4f} ms, n={value["native"]["count"]}')
    for key, value in result["static"].items():
        if key.startswith("gm01"):
            print(f'{key}: {value["gdscript"]["median_ms"]:.4f} -> {value["native"]["median_ms"]:.4f} ms')
    print("Exact benchmark pairs:", pair_count)


if __name__ == "__main__":
    main()
