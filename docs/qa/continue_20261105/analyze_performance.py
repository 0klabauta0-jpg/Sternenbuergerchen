"""Reproduce the small derived performance summary; no engine or image editing."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import math
from pathlib import Path
import zipfile


BASE = Path(__file__).resolve().parent


def load_raw(relative: str) -> dict:
    manifest = json.loads((BASE / "manifest.json").read_text(encoding="utf-8"))
    entry = next(item for item in manifest["archive_only"] if item["path"] == relative)
    local = BASE / relative
    archive = BASE / "continue_20261105.zip"
    if local.is_file():
        data = local.read_bytes()
    elif archive.is_file():
        with zipfile.ZipFile(archive) as packed:
            data = packed.read("continue_20261105/" + relative)
    else:
        data = (BASE.parents[2] / entry["original_path"]).read_bytes()
    if len(data) != entry["bytes"] or hashlib.sha256(data).hexdigest() != entry["sha256"]:
        raise ValueError(f"Raw source mismatch: {relative}")
    return json.load(io.TextIOWrapper(io.BytesIO(data), encoding="utf-8-sig"))


def percentile(values: list[int], fraction: float) -> int:
    ordered = sorted(values)
    return ordered[max(0, math.ceil(len(ordered) * fraction) - 1)]


def selected_window(data: dict, cutoff: int = 38_000_000) -> dict:
    frames = [frame for frame in data["frames"] if 0 <= frame["elapsed_usec"] <= cutoff]
    times = [frame["frame_usec"] for frame in frames]
    physics = [tick for tick in data["physics_ticks"] if 0 <= tick["elapsed_usec"] <= cutoff]
    tick_delta = physics[-1]["simulation"]["tick"] - physics[0]["simulation"]["tick"]
    duration = frames[-1]["elapsed_usec"]
    return {
        "cutoff_usec": cutoff,
        "frame_selection": "0 <= frame.elapsed_usec <= 38000000; frame end timestamps",
        "percentile_method": "nearest rank, ceil(N*p)-1 after sorting",
        "frames": len(frames),
        "first_frame_end_usec": frames[0]["elapsed_usec"],
        "last_frame_end_usec": duration,
        "mean_frame_usec": sum(times) / len(times),
        "p50_usec": percentile(times, 0.50),
        "p95_usec": percentile(times, 0.95),
        "p99_usec": percentile(times, 0.99),
        "max_usec": max(times),
        "over_100ms": sum(value > 100_000 for value in times),
        "over_250ms": sum(value > 250_000 for value in times),
        "physics_tick_delta": tick_delta,
        "simulation_seconds_per_effective_wall_second": tick_delta / 60 / (duration / 1_000_000),
        "registered_units": sorted({frame["unit_count"] for frame in frames}),
        "navigation_pending_max": max(frame["nav_pending"] for frame in frames),
    }


def summarize(data: dict) -> dict:
    summary = data["summary"]
    actions = [{"elapsed_usec": action["elapsed_usec"],
                "move_usec": action["move_usec"], "go_usec": action["go_usec"],
                "pair_usec": action["move_usec"] + action["go_usec"],
                "move_accepted": action["move_accepted"], "go_accepted": action["go_accepted"]}
               for action in data["actions"]]
    return {"reported_summary": {key: summary[key] for key in
            ["duration_usec", "frames", "frametime_usec", "hitch_counts",
             "simulation_seconds_per_wall_second", "simulation_ticks"]},
            "scope": data["scope"], "first_38_seconds": selected_window(data),
            "actions": actions,
            "pair_usec_range": [min(item["pair_usec"] for item in actions),
                                max(item["pair_usec"] for item in actions)]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Write only this package's analysis.json.")
    args = parser.parse_args()
    result = {"schema": "sternenbuergerchen.continue_performance_analysis.v1",
              "kind": "derived analysis, not original evidence",
              "comparison_boundary": "Compare the first 0-38s window separately. Full90 versus full38 percentiles are not a causal before/after comparison. One native run per condition; no general FPS/release/WAN acceptance.",
              "runs": {}}
    for key, relative in [
        ("baseline_38", "raw/command_baseline/baseline_performance.json"),
        ("intermediate_38", "raw/command_batched/batched_performance.json"),
        ("final_90", "raw/final_native_motion/final_performance.json"),
    ]:
        result["runs"][key] = summarize(load_raw(relative))
    if args.write:
        (BASE / "analysis.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                                            encoding="utf-8", newline="\n")
    else:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
