"""Extract comparable normal-route timings without rewriting raw evidence."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from collections import Counter


def projection_facts(path: Path, duration_usec: int) -> dict:
    facts_path = path.with_name(path.name.removesuffix("_performance.json") + ".json")
    if not facts_path.is_file():
        return {"available": False}
    raw = facts_path.read_bytes()
    facts = json.loads(raw).get("facts", {})
    queue = facts.get("r4_periodic_hud_projection", {})
    start = int(queue.get("profile_start_usec", 0))
    after = queue.get("after_measurement", {})
    samples = [row for row in after.get("phase_samples", [])
               if start <= row["start_usec"] < start + duration_usec]
    by_frame = Counter(row["engine_frame"] for row in samples)
    phases = {}
    for key in ("primary_secondary", "craft", "world_status", "cards"):
        rows = [row for row in samples if row["key"] == key]
        costs = sorted(row["finish_usec"] - row["start_usec"] for row in rows)
        phases[key] = {"samples": len(rows), "max_cost_usec": max(costs, default=0),
                       "p95_cost_usec": costs[min(len(costs) - 1, int(len(costs) * .95))] if costs else 0,
                       "max_age_at_start_msec": max((row["age_at_start_msec"] for row in rows), default=0)}
    return {"available": bool(queue), "path": facts_path.as_posix(),
            "sha256": hashlib.sha256(raw).hexdigest(),
            "window_start_usec": start, "window_duration_usec": duration_usec,
            "samples_filtered_by_start_time": len(samples), "phases": phases,
            "max_jobs_in_one_engine_frame": max(by_frame.values(), default=0),
            "max_pending_keys_lifetime": after.get("max_pending_keys"),
            "lifetime_age_is_not_window_age": True,
            "command_receipts": facts.get("r4_command_debug", {}),
            "camera_audit": facts.get("r3_camera_profile", {}),
            "external_manager_work_not_in_controller_process": True}


def summarize(path: Path) -> dict:
    raw = path.read_bytes()
    data = json.loads(raw)
    summary = data["summary"]
    actions = [{key: action[key] for key in
                ("elapsed_usec", "move_accepted", "go_accepted", "move_usec", "go_usec")}
               for action in data["actions"]]
    for action in actions:
        action["paired_public_calls_usec"] = action["move_usec"] + action["go_usec"]
    largest = sorted(data["frames"], key=lambda row: row["frame_usec"], reverse=True)[:10]
    ticks = data.get("physics_ticks", [])
    tick_costs = sorted(row["simulation"]["total_tick_usec"] for row in ticks)
    backlog = {key: max((row.get(key, 0) for row in data["frames"]), default=0)
               for key in ("nav_pending", "command_queue", "effect_queue", "ticks_since_previous_frame")}
    return {
        "path": path.as_posix(), "sha256": hashlib.sha256(raw).hexdigest(),
        "duration_usec": summary["duration_usec"], "frames": summary["frames"],
        "frametime_usec": summary["frametime_usec"], "hitch_counts": summary["hitch_counts"],
        "simulation_ticks": summary["simulation_ticks"],
        "simulation_seconds_per_wall_second": summary["simulation_seconds_per_wall_second"],
        "backlog_frame_maxima": backlog,
        "physics_tick_samples": len(ticks),
        "physics_tick_cost_usec": {key: tick_costs[min(len(tick_costs)-1, int(len(tick_costs)*q))] if tick_costs else 0
                                   for key, q in (("p50", .5), ("p95", .95), ("p99", .99), ("max", 1.0))},
        "probe_usec": summary.get("probe_usec", {}),
        "camera_before": data["camera_before"], "camera_after": data["camera_after"],
        "display_samples": data["display_samples"], "scope": data["scope"],
        "actions": actions,
        "largest_frames": [{key: frame[key] for key in (
            "elapsed_usec", "frame_usec", "tick", "ticks_since_previous_frame",
            "controller_usec", "controller_scopes_usec", "simulation_usec",
            "terrain_usec", "fog_owner", "nav_pending", "unit_count")}
            for frame in largest],
        "nested_scopes_are_not_additive": True,
        "scope_monitors_may_be_previous_invocation": True,
        "gpu_frame_time_available": False,
        "projection_facts": projection_facts(path, summary["duration_usec"]),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("profiles", nargs="+", type=Path)
    args = parser.parse_args()
    result = {"schema": "sternenbuergerchen.r4_comparable_profile_summary.v1",
              "profiles": [summarize(path) for path in args.profiles]}
    # A receipt is immutable once written, including failed/intermediate runs.
    with args.output.open("x", encoding="utf-8", newline="\n") as stream:
        json.dump(result, stream, indent=2, ensure_ascii=False)
        stream.write("\n")
    for row in result["profiles"]:
        timing = row["frametime_usec"]
        print(row["path"], {key: timing[key] for key in ("p50", "p95", "p99", "max")},
              row["hitch_counts"], row["simulation_seconds_per_wall_second"])


if __name__ == "__main__":
    main()
