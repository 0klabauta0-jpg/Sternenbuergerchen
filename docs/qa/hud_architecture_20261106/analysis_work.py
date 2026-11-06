#!/usr/bin/env python3
"""Read-only analysis of the HUD architecture native profiles, using stdlib only.

Quick guide (this docstring is the deliberately small embedded README):
  python docs/qa/hud_architecture_20261106/analysis_work.py
      Prints provisional baseline/intermediate numbers; writes nothing.
  python docs/qa/hud_architecture_20261106/analysis_work.py --final PATH \
      --final-confirmed --output docs/qa/hud_architecture_20261106/analysis.json
      Use only after Root confirms the final marker and stable source receipt.
  python docs/qa/hud_architecture_20261106/analysis_work.py --self-check

The common prefix selects frame endpoints 0 <= elapsed_usec <= 38_000_000.
Frames crossing the boundary are excluded, never clipped or interpolated.
Quantiles use nearest rank, ceil(n*p/100)-1, as the capture harness does.
The actual covered endpoint and requested 38-second denominator are both shown.
Whole-profile statistics are separate; a 90-second mean is not compared to a
38-second mean. November 5 used a different physical display and is excluded.

HUD snapshots persist between calls. Deduplicate ui_refresh by invocation_count
across frame observations AND command action snapshots. Report the first ID as
left-boundary-uncertain and also supply totals excluding it. Missing IDs and
conflicting payloads remain explicit; observed totals are not an invented census.
Runtime-surface snapshots have no invocation ID: their distributions describe
observations, not independent calls. No runtime-surface work total is inferred.
All scopes are inclusive diagnostics. Never add a parent and its children, or
add ui_refresh.runtime_surfaces_usec a second time to ui_refresh.total_usec.

The utility does not run Godot, read/modify gameplay, change Git, create a ZIP,
or hash the source tree. Only --output writes, and it requires an accepted final.
"""

from __future__ import annotations

import argparse
import json
import math
from collections import defaultdict
from pathlib import Path
from typing import Any

WINDOW_USEC = 38_000_000
DEFAULT_RUNS = {
    "baseline": "output/hud_architecture_20261106/baseline_profile/20261106T132842Z-c93dc5aa/baseline_performance.json",
    "after_read_scope": "output/hud_architecture_20261106/after_read_scope/20261106T134304Z-74d18615/after_performance.json",
    "after_forward_projection": "output/hud_architecture_20261106/after_forward_projection/20261106T140743Z-49507f56/forward_performance.json",
}
DISPLAY_KEYS = (
    "cpu", "gpu", "display", "renderer", "rendering_driver", "window_size",
    "viewport_size", "root_size", "content_scale_size", "screen_size",
    "screen_refresh_rate", "window_mode", "vsync_mode", "time_scale",
    "physics_ticks_per_second", "max_physics_steps_per_frame",
)
UI_NESTING = {
    "total_usec": "Contains all HUD work below; do not add its children again.",
    "primary_labels_usec": "Contains primary_* label/tooltip/decision scopes.",
    "mission_panels_usec": "Contains panel_* presentation scopes.",
    "secondary_labels_usec": "Contains secondary_* scopes; not another pass.",
    "runtime_surfaces_usec": "Inside total_usec; separate runtime_surface snapshots may repeat it.",
}
SURFACE_NESTING = {
    "craft_controls_usec": "Parent of craft_summary/evacuation/button_styles/button_labels/hierarchy/layout.",
    "fireteam_cards_usec": "Parent of card/ad_hoc/fireteam-panel detail scopes where present.",
    "total_usec": "Parent of craft_controls/world_overlays/primary_status/fireteam_cards/visibility.",
}


def read_json(path: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    before = path.stat()
    with path.open(encoding="utf-8-sig") as handle:
        value = json.load(handle)
    after = path.stat()
    stable = (before.st_size, before.st_mtime_ns) == (after.st_size, after.st_mtime_ns)
    if not stable or not isinstance(value, dict):
        raise ValueError(f"Input changed while reading or is not an object: {path}")
    return value, {"path": str(path), "bytes": after.st_size, "mtime_ns": after.st_mtime_ns,
                   "stable_during_read": stable, "input_hash_not_computed": True}


def distribution(values: list[float | int]) -> dict[str, Any]:
    if not values:
        return {"count": 0}
    ordered = sorted(values)
    result = {"count": len(ordered), "min": ordered[0], "max": ordered[-1],
              "sum": sum(ordered), "mean": sum(ordered) / len(ordered)}
    result.update({f"p{p}": ordered[math.ceil(len(ordered) * p / 100) - 1]
                   for p in (50, 90, 95, 99)})
    return result


def bounds(values: list[float | int]) -> dict[str, Any]:
    return {"min": min(values), "max": max(values)} if values else {}


def scope_distributions(snapshots: list[dict[str, Any]], field: str) -> dict[str, Any]:
    keys = sorted({key for snapshot in snapshots for key in snapshot.get(field, {})})
    return {key: distribution([snapshot[field][key] for snapshot in snapshots
                               if key in snapshot.get(field, {})]) for key in keys}


def ui_analysis(data: dict[str, Any], frames: list[dict[str, Any]], cutoff: int) -> dict[str, Any]:
    observations: list[tuple[int, str, dict[str, Any]]] = [
        (int(frame["elapsed_usec"]), "frame", frame.get("ui_refresh", {})) for frame in frames]
    frame_ids = {int(snapshot.get("invocation_count", -1)) for _, _, snapshot in observations}
    action_boundary_exclusions = 0
    for index, action in enumerate(data.get("actions", [])):
        elapsed = int(action["elapsed_usec"])
        # Actions are far from the 38-s boundary in these fixtures. The stamp
        # is pre-call, so reject a possibly crossing pair rather than guess.
        if elapsed > cutoff:
            continue
        if elapsed + int(action["move_usec"]) + int(action["go_usec"]) > cutoff:
            action_boundary_exclusions += 1
            continue
        for kind in ("move_ui", "go_ui"):
            observations.append((elapsed, f"action_{index + 1}.{kind}", action.get(kind, {})))
    observations.sort(key=lambda item: (item[0], item[1]))
    by_id: dict[int, dict[str, Any]] = {}
    conflicts: list[dict[str, Any]] = []
    source_counts: dict[int, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    first_seen: dict[int, int] = {}
    for elapsed, source, snapshot in observations:
        invocation = int(snapshot.get("invocation_count", -1))
        if invocation < 0 or not snapshot.get("enabled", False):
            continue
        source_counts[invocation][source] += 1
        first_seen.setdefault(invocation, elapsed)
        if invocation in by_id and by_id[invocation] != snapshot:
            conflicts.append({"invocation_count": invocation, "observed_at_usec": elapsed,
                              "source": source})
        else:
            by_id.setdefault(invocation, snapshot)
    ids = sorted(by_id)
    initial_id = int(data["frames"][0].get("ui_refresh", {}).get("invocation_count", -1))
    attributable = [by_id[key] for key in ids if key != initial_id]
    snapshots = [by_id[key] for key in ids]
    with_surfaces = [snapshot for snapshot in snapshots
                     if int(snapshot.get("scopes_usec", {}).get("runtime_surfaces_usec", 0)) > 0]
    without_surfaces = [snapshot for snapshot in snapshots
                        if int(snapshot.get("scopes_usec", {}).get("runtime_surfaces_usec", 0)) == 0]
    peak_calls: dict[str, Any] = {}
    for key in sorted({key for snapshot in snapshots for key in snapshot.get("projection_build_calls", {})}):
        counts = [int(snapshot.get("projection_build_calls", {}).get(key, 0)) for snapshot in snapshots]
        peak = max(counts)
        peak_calls[key] = {"calls_per_observed_unique_pass": distribution(counts),
                           "peak_invocation_ids": [invocation for invocation in ids
                               if int(by_id[invocation].get("projection_build_calls", {}).get(key, 0)) == peak]}
    return {
        "policy": "Unique enabled invocation_count from frames plus Move/GO action snapshots; never sum repeated frame snapshots.",
        "observations": sum(sum(counts.values()) for counts in source_counts.values()),
        "unique_observed_count": len(ids), "invocation_id_min": min(ids) if ids else None,
        "invocation_id_max": max(ids) if ids else None,
        "missing_ids_between_observed_extremes": [key for key in range(min(ids), max(ids) + 1) if key not in by_id] if ids else [],
        "ids_recovered_only_from_actions": [key for key in ids if key not in frame_ids],
        "left_boundary_uncertain_id": initial_id,
        "left_boundary_note": "First persistent snapshot lacks its completion timestamp; inclusive and boundary-excluded totals are both exposed.",
        "total_usec_unique_observed_including_left_boundary": distribution([s["total_usec"] for s in snapshots]),
        "total_usec_unique_observed_excluding_left_boundary": distribution([s["total_usec"] for s in attributable]),
        "total_usec_unique_passes_including_runtime_surfaces": distribution([s["total_usec"] for s in with_surfaces]),
        "total_usec_unique_passes_without_runtime_surfaces": distribution([s["total_usec"] for s in without_surfaces]),
        "inclusive_scope_usec_per_unique_observed_pass": scope_distributions(snapshots, "scopes_usec"),
        "projection_scope_usec_per_unique_observed_pass": scope_distributions(snapshots, "projection_scopes_usec"),
        "projection_build_calls": peak_calls,
        "scope_nesting_do_not_add": UI_NESTING,
        "projection_diagnostic_bounds": {key: bounds([s["projection_pass"][key] for s in snapshots
            if isinstance(s.get("projection_pass", {}).get(key), (int, float))])
            for key in sorted({key for s in snapshots for key, value in s.get("projection_pass", {}).items()
                if isinstance(value, (int, float)) and not isinstance(value, bool)})},
        "snapshot_conflicts_for_same_invocation": conflicts,
        "actions_crossing_boundary_excluded": action_boundary_exclusions,
        "first_seen_elapsed_usec_by_id": {str(key): first_seen[key] for key in ids},
    }


def pairs_analysis(data: dict[str, Any], cutoff: int) -> dict[str, Any]:
    pairs = [{"index": index + 1, "elapsed_usec": action["elapsed_usec"], "target": action["target"],
              "move_usec": action["move_usec"], "go_usec": action["go_usec"],
              "pair_usec": action["move_usec"] + action["go_usec"],
              "move_accepted": action["move_accepted"], "go_accepted": action["go_accepted"]}
             for index, action in enumerate(data.get("actions", [])) if int(action["elapsed_usec"]) <= cutoff]
    return {"scope": "Synchronous handler costs, move_usec+go_usec; not input-to-arrival or complete frame latency.",
            "pairs": pairs, "pair_usec_distribution": distribution([p["pair_usec"] for p in pairs])}


def window_analysis(data: dict[str, Any], cutoff: int) -> dict[str, Any]:
    all_frames = data["frames"]
    frames = [row for row in all_frames if 0 <= int(row["elapsed_usec"]) <= cutoff]
    physics = [row for row in data.get("physics_ticks", []) if 0 <= int(row["elapsed_usec"]) <= cutoff]
    if not frames:
        raise ValueError("No frame observations in requested window")
    covered = int(frames[-1]["elapsed_usec"])
    tick_rate = float(data["display_samples"][0]["physics_ticks_per_second"])
    tick_delta = sum(int(row["ticks_since_previous_frame"]) for row in frames)
    frame_values = [int(row["frame_usec"]) for row in frames]
    ui = ui_analysis(data, frames, cutoff)
    surfaces = [row.get("runtime_surface", {}) for row in frames]
    # These snapshots have no call ID or completion timestamp. Their sums are
    # deliberately removed, because equal observations need not be new calls.
    surface_totals = distribution([s["total_usec"] for s in surfaces if "total_usec" in s])
    surface_totals.pop("sum", None)
    surface_scopes = scope_distributions(surfaces, "scopes_usec")
    for value in surface_scopes.values():
        value.pop("sum", None)
    peaks = []
    for row in sorted(frames, key=lambda row: row["frame_usec"], reverse=True)[:8]:
        peaks.append({key: row.get(key) for key in (
            "elapsed_usec", "frame_usec", "tick", "ticks_since_previous_frame", "controller_usec",
            "controller_scopes_usec", "hud_included_ui_refresh", "simulation_usec", "combat_usec",
            "terrain_usec", "nav_pending", "nav_new_queries", "command_queue")})
    return {
        "requested_endpoint_usec": cutoff, "policy": "0 <= frame endpoint <= requested endpoint; no interpolation",
        "frames": len(frames), "first_frame_endpoint_usec": frames[0]["elapsed_usec"],
        "last_frame_endpoint_usec": covered, "uncovered_tail_usec": cutoff - covered,
        "next_frame_endpoint_usec": next((r["elapsed_usec"] for r in all_frames if r["elapsed_usec"] > cutoff), None),
        "frametime_usec": distribution(frame_values),
        "hitch_counts": {f"over_{threshold}ms": sum(v > threshold * 1000 for v in frame_values)
                         for threshold in (33, 50, 100, 250)},
        "largest_frames": peaks,
        "simulation": {"physics_tick_rate": tick_rate, "frame_observed_tick_delta": tick_delta,
            "simulated_seconds": tick_delta / tick_rate,
            "sim_per_actual_covered_wall_second": tick_delta / tick_rate / (covered / 1_000_000),
            "observed_sim_per_requested_wall_second": tick_delta / tick_rate / (cutoff / 1_000_000),
            "formula": "sum(ticks_since_previous_frame)/physics_ticks_per_second/wall_seconds; boundary quantization remains explicit",
            "physics_observation_rows": len(physics)},
        "frame_backlog_bounds": {key: bounds([row[key] for row in frames if key in row])
            for key in ("command_queue", "effect_queue", "nav_pending", "nav_delayed", "ticks_since_previous_frame")},
        "physics_backlog_bounds": {key: bounds([row["simulation"][key] for row in physics
                if key in row.get("simulation", {})])
            for key in ("command_queue_after_tick", "effect_queue_after_tick", "command_count")},
        "physics_navigation_bounds": {key: bounds([row["simulation"]["navigation"][key] for row in physics
                if key in row.get("simulation", {}).get("navigation", {})])
            for key in ("pending_query_count", "delayed_this_tick", "new_path_queries_this_tick")},
        "unit_count_bounds": bounds([row["unit_count"] for row in frames]),
        "friendly_count_bounds": bounds([row["combat"]["friendly_unit_count"] for row in physics
            if "friendly_unit_count" in row.get("combat", {})]),
        "enemy_count_bounds": bounds([row["combat"]["active_enemy_unit_count"] for row in physics
            if "active_enemy_unit_count" in row.get("combat", {})]),
        "draw_calls_observed": distribution([row["draw_calls"] for row in frames if "draw_calls" in row]),
        "ui_refresh": ui,
        "runtime_surface": {"policy": "Persistent latest snapshots; observation-weighted distributions only, NOT independent invocation totals.",
            "total_usec_observations": surface_totals, "inclusive_scope_usec_observations": surface_scopes,
            "scope_nesting_do_not_add": SURFACE_NESTING,
            "exact_runtime_surfaces_within_unique_ui_passes": ui["inclusive_scope_usec_per_unique_observed_pass"].get("runtime_surfaces_usec", {})},
        "move_go": pairs_analysis(data, cutoff),
    }


def analyse_run(label: str, path: Path, is_final: bool) -> tuple[dict[str, Any], dict[str, Any]]:
    data, record = read_json(path)
    if int(data.get("summary", {}).get("duration_usec", 0)) < WINDOW_USEC:
        raise ValueError(f"Run is shorter than 38 seconds: {label}")
    runner, runner_record = read_json(path.with_name("report.json"))
    stem = path.name.removesuffix("_performance.json")
    route, route_record = read_json(path.with_name(stem + ".json"))
    checks = runner.get("checks", [])
    receipt_ok = bool(checks) and all(check.get("passed") is True and check.get("exit_code") == 0
        and check.get("error_count") == 0 and check.get("source_inputs_stable") is True
        and check.get("isolation_verified") is True and not check.get("timed_out") for check in checks)
    camera_stable = data.get("camera_before") == data.get("camera_after")
    route_ok = route.get("failed") == 0 and route.get("passed", 0) > 0
    if is_final and not (receipt_ok and route_ok and camera_stable):
        raise ValueError(f"Final rejected: {label}; receipt_ok={receipt_ok}, route_ok={route_ok}, camera_stable={camera_stable}")
    camera_audit = None
    camera_audit_record = None
    camera_audit_path = path.with_name(stem + "_camera_audit.json")
    if camera_audit_path.exists():
        camera_audit, camera_audit_record = read_json(camera_audit_path)
        if is_final and camera_audit.get("input_actions"):
            raise ValueError("Final camera audit records camera input actions")
    displays = data["display_samples"]
    result = {
        "label": label, "final": is_final, "input": record, "runner_receipt_input": runner_record,
        "route_receipt_input": route_record,
        "camera_audit_input": camera_audit_record, "camera_audit": camera_audit,
        "instrumentation_note": "Audited final extends the same motion harness with read-only camera-action observation and a 4-Hz camera-change reader; added observer overhead, no camera reset or handling." if is_final else "Baseline/intermediate motion-order capture instrumentation.",
        "receipt": {"passed": receipt_ok, "route_passed": route.get("passed"), "route_failed": route.get("failed"),
                    "camera_unchanged_within_run": camera_stable},
        "engine": data["engine"], "scope": data["scope"], "default_map": data["default_map"],
        "camera_before": data["camera_before"], "camera_after": data["camera_after"],
        "display_samples": displays,
        "display_unique_values": {key: sorted({json.dumps(d.get(key), sort_keys=True) for d in displays}) for key in DISPLAY_KEYS},
        "quality_limit": "JSON records renderer/display/camera/unit bounds, not a full AA/shadow/quality preset. Quality parity needs Root's source/capture review; unavailable GPU frame time stays unavailable.",
        "sources_sha256_as_recorded_by_capture": data.get("sources_sha256", {}),
        "common_0_38_seconds": window_analysis(data, WINDOW_USEC),
        "whole_profile_separate": {"not_an_equal_duration_comparison": True,
            "original_summary": {key: value for key, value in data["summary"].items() if key != "hitches_over_50ms"},
            "observed_frames": window_analysis(data, max(int(data["summary"]["duration_usec"]), int(data["frames"][-1]["elapsed_usec"])))}
    }
    return result, data


def compare_context(baseline: dict[str, Any], candidate: dict[str, Any]) -> dict[str, Any]:
    first, other = baseline["display_samples"][0], candidate["display_samples"][0]
    mismatches = {key: {"baseline": first.get(key), "candidate": other.get(key)}
                  for key in DISPLAY_KEYS if first.get(key) != other.get(key)}
    return {
        "same_display_context": not mismatches, "display_mismatches": mismatches,
        "same_engine": baseline["engine"] == candidate["engine"],
        "same_map": baseline["default_map"] == candidate["default_map"],
        "same_camera_before": baseline["camera_before"] == candidate["camera_before"],
        "both_cameras_stable_within_run": baseline["receipt"]["camera_unchanged_within_run"] and candidate["receipt"]["camera_unchanged_within_run"],
        "causal_limit": "Single normal-path runs, variable runtime positions and bounded read-only probes; matching context is not statistical causality or whole-game acceptance.",
    }


def self_check() -> None:
    assert distribution(list(range(1, 101)))["p95"] == 95
    assert distribution([7])["p99"] == 7
    sample = {"frames": [{"ui_refresh": {"invocation_count": 1}}], "actions": [
        {"elapsed_usec": 10, "move_usec": 2, "go_usec": 3,
         "move_ui": {"enabled": True, "invocation_count": 2, "total_usec": 20},
         "go_ui": {"enabled": True, "invocation_count": 3, "total_usec": 30}}]}
    frames = [{"elapsed_usec": n, "ui_refresh": {"enabled": True, "invocation_count": invocation, "total_usec": cost}}
              for n, invocation, cost in ((1, 1, 10), (2, 1, 10), (20, 3, 30))]
    actual = ui_analysis(sample, frames, 38_000_000)
    assert actual["unique_observed_count"] == 3
    assert actual["total_usec_unique_observed_including_left_boundary"]["sum"] == 60
    assert actual["total_usec_unique_observed_excluding_left_boundary"]["sum"] == 50
    assert actual["ids_recovered_only_from_actions"] == [2]
    print("ANALYSIS_WORK_SELF_CHECK_PASS")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[3])
    parser.add_argument("--final", type=Path, help="Explicit final performance JSON; failed camera attempts must not be supplied")
    parser.add_argument("--final-confirmed", action="store_true", help="Root has confirmed the final marker and source stability")
    parser.add_argument("--output", type=Path, help="Write analysis.json only after final acceptance")
    parser.add_argument("--self-check", action="store_true")
    args = parser.parse_args()
    if args.self_check:
        self_check()
        return
    if args.output and not (args.final and args.final_confirmed):
        parser.error("--output requires --final and Root's --final-confirmed")
    if args.final and not args.final_confirmed:
        parser.error("Do not analyse a final candidate before Root's confirmation")
    runs = dict(DEFAULT_RUNS)
    if args.final:
        runs["final"] = str(args.final)
    analysed = {}
    for label, relative in runs.items():
        path = Path(relative)
        path = path if path.is_absolute() else args.project_root / path
        result, _ = analyse_run(label, path, label == "final")
        analysed[label] = result
    report = {
        "schema": "sternenbuergerchen.hud_architecture_analysis.v1",
        "status": "root_confirmed_final_included" if args.final else "provisional_intermediates_only",
        "root_final_confirmation": args.final_confirmed,
        "november_5_not_comparable": "November 6 baseline uses physical 3440x1440 at 240.085 Hz; November 5 used 2560x1440 at 74.968 Hz. Do not mix those series.",
        "units": "Timing values are microseconds unless a field explicitly says seconds.",
        "runs": analysed,
        "context_comparisons_to_new_baseline": {label: compare_context(analysed["baseline"], run)
            for label, run in analysed.items() if label != "baseline"},
        "excluded_failed_attempt": "final_native_90/20261106T143538Z-795aeddc failed camera unchanged; kept separately and not accepted as final.",
    }
    if args.final:
        context = report["context_comparisons_to_new_baseline"]["final"]
        if not all(context[key] for key in ("same_display_context", "same_engine", "same_map", "same_camera_before", "both_cameras_stable_within_run")):
            raise ValueError("Final context differs from the new baseline; no causal comparison/output is accepted")
    for label, run in analysed.items():
        window = run["common_0_38_seconds"]
        frame = window["frametime_usec"]
        ui = window["ui_refresh"]["total_usec_unique_observed_including_left_boundary"]
        print(f"{label}: frames={window['frames']} p50/p95/p99/max_ms="
              f"{frame['p50']/1000:.3f}/{frame['p95']/1000:.3f}/{frame['p99']/1000:.3f}/{frame['max']/1000:.3f}; "
              f"unique_UI={ui['count']} UI_max_ms={ui['max']/1000:.3f}; "
              f"observed_sim/38s={window['simulation']['observed_sim_per_requested_wall_second']:.6f}")
    if args.output:
        output = args.output if args.output.is_absolute() else args.project_root / args.output
        if output.resolve().parent != Path(__file__).resolve().parent or output.name != "analysis.json":
            parser.error("Only this utility's sibling analysis.json is an authorized output")
        if output.exists():
            parser.error("Preserve existing analysis.json; do not silently overwrite an earlier result")
        output.write_text(json.dumps(report, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8")
        print(f"ANALYSIS_WRITTEN {output}")


if __name__ == "__main__":
    main()
