"""Summarize raw frame receipts without equating nested scopes to total FPS."""
import json
import math
import statistics
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def stats(values):
    ordered = sorted(float(value) for value in values if value is not None)
    if not ordered:
        return {"count": 0}
    return {
        "count": len(ordered),
        "mean": statistics.mean(ordered),
        "median": statistics.median(ordered),
        "p95": ordered[math.ceil((len(ordered) - 1) * 0.95)],
        "p99": ordered[math.ceil((len(ordered) - 1) * 0.99)],
        "max": ordered[-1],
    }


def summarize(path):
    if path.exists():
        text = path.read_text(encoding="utf-8-sig")
    else:
        with zipfile.ZipFile(ROOT / "raw_frames.zip") as archive:
            text = archive.read(path.name).decode("utf-8-sig")
    data = json.loads(text)
    rows = data["rows"]
    ids = [row["process_frame"] for row in rows]
    assert data["frame_binding_errors"] == 0
    assert len(ids) == len(set(ids)) and ids == sorted(ids)
    for row in rows:
        frame = row["process_frame"]
        assert row["cpu_frame_binding_ok"]
        for receipt in [row["sim"], row["meta"], row["view"]["process"], row["base_sim"]]:
            if receipt:
                assert receipt["process_frame"] == frame
        sim = row["sim"]
        if sim["sample_count"]:
            assert sim["last_tick"] - sim["first_tick"] + 1 == sim["sample_count"]
        else:
            assert sim["sum_usec"] == 0 and not sim["has_sample"]
    result = {
        "engine": data["engine"], "adapter": data["adapter"],
        "window": data["window"], "terrain_viewport": data["terrain_viewport"],
        "renderer": data["renderer"], "scale": data["scale"],
        "map_sha256": data["map_sha256"], "shots": data["shots"],
        "first_move_ms": data["first_move_ms"], "go_dispatch_ms": data["go_dispatch_ms"],
        "frames": len(rows), "binding_errors": data["frame_binding_errors"],
        "post_draw_callback_frame_offset": stats(row["post_draw_callback_process_frame"] - row["process_frame"] for row in rows),
        "phases": {},
    }
    for phase in sorted({row["phase"] for row in rows}):
        selected = [row for row in rows if row["phase"] == phase]
        quarter = [row for row in selected if "tutorial_usec" in row["meta"]["scopes_sum_usec"]]
        projections = [row["meta"]["tutorial"] for row in quarter]
        result["phases"][phase] = {
            "frames": len(selected),
            "wall_pre_draw_interval_ms": stats(row["wall_ms"] for row in selected),
            "physics_ticks_per_frame": stats(row["sim"]["sample_count"] for row in selected),
            "physics_cpu_sum_ms": stats(row["sim"]["sum_usec"] / 1000 for row in selected),
            "base_physics_cpu_sum_ms": stats(row["base_sim"].get("sum_usec", 0) / 1000 for row in selected),
            "view_process_ms": stats(row["view"]["process"]["sum_usec"] / 1000 for row in selected),
            "view_fow_external_ms": stats(row["view"]["fow_calls"]["sum_usec"] / 1000 for row in selected),
            "view_regional_publish_ms_active": stats(row["view"]["regional_publish"]["sum_usec"] / 1000 for row in selected if row["view"]["regional_publish"]["sample_count"]),
            "meta_quarter_ms": stats(row["meta"]["sum_usec"] / 1000 for row in quarter),
            "meta_observe_campaign_ms": stats(row["meta"]["scopes_sum_usec"].get("observe_campaign_usec", 0) / 1000 for row in quarter),
            "tutorial_refresh_ms": stats(row["meta"]["scopes_sum_usec"]["tutorial_usec"] / 1000 for row in quarter),
            "tutorial_projection_count": stats(receipt["sample_count"] for receipt in projections),
            "tutorial_projection_ms": stats(receipt["sum_usec"] / 1000 for receipt in projections),
            "tutorial_redundant_guard_projection_ms": stats(receipt["scopes_sum_usec"]["guard_snapshot_usec"] / 1000 for receipt in projections if "guard_snapshot_usec" in receipt["scopes_sum_usec"]),
            "latest_available_gpu_ms": stats(row["render_gpu_ms"] for row in selected),
            "test_poll_ms_active": stats(row["test_polls"]["sum_usec"] / 1000 for row in selected if row["test_polls"]["sample_count"]),
            "sampler_pre_draw_ms": stats(row["sampler_pre_draw_usec"] / 1000 for row in selected),
            "largest_frames": [{
                "process_frame": row["process_frame"], "wall_ms": row["wall_ms"],
                "physics_ticks": row["sim"]["sample_count"],
                "physics_sum_ms": row["sim"]["sum_usec"] / 1000,
                "view_ms": row["view"]["process"]["sum_usec"] / 1000,
                "publish_ms": row["view"]["regional_publish"]["sum_usec"] / 1000,
                "meta_ms": row["meta"]["sum_usec"] / 1000,
            } for row in sorted(selected, key=lambda item: item["wall_ms"] or 0, reverse=True)[:5]],
        }
    return result


if __name__ == "__main__":
    summary = {label: summarize(ROOT / f"{label}.json") for label in ["before", "after"]}
    for field in ["engine", "window", "terrain_viewport", "renderer", "scale", "map_sha256", "shots"]:
        assert summary["before"][field] == summary["after"][field], field
    (ROOT / "comparison.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    for label, report in summary.items():
        for phase in ["go_to_contact", "combat"]:
            phase_report = report["phases"][phase]
            print(label, phase, json.dumps({key: phase_report[key] for key in [
                "frames", "wall_pre_draw_interval_ms", "meta_quarter_ms",
                "tutorial_refresh_ms", "tutorial_projection_count"]}))
