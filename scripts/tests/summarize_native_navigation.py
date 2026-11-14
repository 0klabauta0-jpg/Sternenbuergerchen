"""Recompute the accepted B/C comparison without mixing the preliminary A run."""
import hashlib
import json
import math
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / "docs/qa/native_navigation_20261114"

def stats(values):
    ordered = sorted(values)
    return {"count": len(values), "median_ms": statistics.median(values) / 1000,
            "mean_ms": statistics.mean(values) / 1000,
            "p95_ms": ordered[math.ceil(len(values) * .95) - 1] / 1000,
            "max_ms": max(values) / 1000, "sum_ms": sum(values) / 1000}

groups = {}
source_matches = {}
for run in ["bench_b", "bench_c"]:
    data = json.loads((QA / run / "result.json").read_text())
    assert data["passed"] and not data["failures"]
    manifest = json.loads((QA / run / "source_manifest.json").read_text())
    for path, digest in manifest["source_sha256"].items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
        source_matches[path] = digest
    for row in data["pairs"]:
        assert row["ordered_path_and_status_equal"] and row["score_equal"] and row["native_used"]
        key = "/".join(row[k] for k in ["fixture", "algorithm", "mode"])
        groups.setdefault(key, []).append(row)

summary = {}
for key, rows in groups.items():
    gd = stats([r["gdscript_usec"] for r in rows])
    cpp = stats([r["native_usec"] for r in rows])
    summary[key] = {"gdscript": gd, "native": cpp,
                    "median_speedup": gd["median_ms"] / cpp["median_ms"],
                    "successful_nonempty_routes": sum(r["path_length"] > 0 for r in rows),
                    "small_sample_warning": len(rows) < 20}
result = {"accepted_runs": ["bench_b", "bench_c"], "excluded_run": "bench_a: concurrent own Git discovery consumed CPU; retained as preliminary evidence",
          "all_source_hashes_match": source_matches, "summaries": summary,
          "scope": "Navigation-only. Static option snapshots amortized for warm calls; preparation is separately measured. No FPS claim."}
(QA / "comparison.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
for key, row in summary.items():
    print(f'{key}: {row["gdscript"]["median_ms"]:.3f} -> {row["native"]["median_ms"]:.3f} ms; x{row["median_speedup"]:.2f}; n={row["gdscript"]["count"]}; routes={row["successful_nonempty_routes"]}')
