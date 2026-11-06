"""Summarize immutable R3 originals after profiling; never run during a profile."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "output/reference_polish_r3_20261106"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    runs = []
    for path in sorted(BASE.glob("*/*/report.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        runs.append({"path": path.relative_to(ROOT).as_posix(), "sha256": sha(path),
                     "summary": data["summary"], "checks": [
                         {key: case.get(key) for key in ["name", "passed", "exit_code", "error_count", "timed_out", "isolation_verified", "source_inputs_stable"]}
                         for case in data["checks"]]})
    profiles = []
    for path in sorted(BASE.glob("*/*/*_performance.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        summary = data["summary"]
        frames = data["frames"]
        unique_ui = {row["ui_refresh"].get("invocation_count"): row["ui_refresh"] for row in frames if row.get("ui_refresh")}
        draw_calls = sorted(row["draw_calls"] for row in frames)
        profiles.append({
            "path": path.relative_to(ROOT).as_posix(), "sha256": sha(path),
            "duration_usec": summary["duration_usec"], "frames": summary["frames"],
            "frametime_usec": summary["frametime_usec"], "hitch_counts": summary["hitch_counts"],
            "simulation_seconds_per_wall_second": summary["simulation_seconds_per_wall_second"],
            "simulation_ticks": summary["simulation_ticks"], "camera_before": data["camera_before"], "camera_after": data["camera_after"],
            "display_samples": data["display_samples"], "unique_ui_samples": len(unique_ui),
            "ui_max_usec": max((x.get("total_usec", 0) for x in unique_ui.values()), default=0),
            "draw_calls_p50_p95_max": [draw_calls[len(draw_calls)//2], draw_calls[min(len(draw_calls)-1, int(len(draw_calls)*0.95))], draw_calls[-1]],
            "scope": data["scope"],
        })
    target = BASE / "analysis.json"
    target.write_text(json.dumps({"schema": "sternenbuergerchen.reference_polish_r3.analysis.v1",
        "base": "173a1e3c33b733a78a396a93db9cedf631d84998", "runs": runs, "profiles": profiles,
        "limits": "Native measured route only; nested scopes are not additive. Product camera/density and fixed camera34 are separate. No EXE, WAN or whole-game acceptance."},
        ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({"runs": len(runs), "profiles": len(profiles), "path": str(target)}))


if __name__ == "__main__":
    main()
