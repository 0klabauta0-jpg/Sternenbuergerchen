"""Capture the real normal-start route; no fixtures or timer/state patches."""
import argparse
import hashlib
import json
import subprocess

from _qa_common import ROOT, error_lines, isolated_profile, new_run_dir, res_path, write_json

NAMESPACE = "SternenBuergerchen_UI_Zielbild_Normal_QA"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sizes", nargs="+", choices=["1920x1080", "1280x720"], default=["1920x1080", "1280x720"])
    parser.add_argument("--godot", default="godot_console")
    parser.add_argument("--verbose-engine", action="store_true", help="Inspect shutdown warnings without relaxing acceptance.")
    args = parser.parse_args()
    run = new_run_dir("normal_start")
    records = []
    for size in args.sizes:
        folder = run / size
        folder.mkdir()
        result_path = folder / "startup.json"
        command = [args.godot, "--path", str(ROOT), "--rendering-method", "forward_plus", "--rendering-driver", "vulkan", "--audio-driver", "Dummy", "--script", "res://scripts/tests/ui_zielbild_normal_capture.gd", "--", "--ui-size=" + size, "--startup-timeout-seconds=150", "--evidence-output=" + res_path(result_path)]
        if args.verbose_engine:
            command.insert(1, "--verbose")
        profile = {}
        try:
            with isolated_profile(NAMESPACE) as profile:
                process = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
        except subprocess.TimeoutExpired as exc:
            (folder / "startup.log").write_bytes(exc.stdout or b"")
            write_json(folder / "process.json", {**profile, "command": command, "timed_out": True, "exit_code": None})
            raise
        (folder / "startup.log").write_bytes(process.stdout)
        errors = error_lines(process.stdout.decode("utf-8", errors="replace"))
        write_json(folder / "process.json", {**profile, "command": command, "logical_size": size, "driver": "vulkan", "exit_code": process.returncode, "error_count": len(errors), "error_lines": errors})
        assert process.returncode == 0 and not errors and result_path.exists(), f"Startup failed: {folder}"
        result = json.loads(result_path.read_text(encoding="utf-8"))
        assert result["failed"] == 0 and result["passed"] > 0
        dimensions = [int(part) for part in size.split("x")]
        for capture in result["captures"]:
            image_path = ROOT / capture["path"].removeprefix("res://")
            assert [capture["width"], capture["height"]] == dimensions
            assert hashlib.sha256(image_path.read_bytes()).hexdigest() == capture["sha256"]
        actual = next(item for item in result["captures"] if item["id"] == "06_go_movement")
        render = next(item for item in result["stages"] if item["id"] == "mission_started")["details"]["render"]
        assert render["frontier_art_enabled"] and render["grid_topology"] == "hex_axial_v1"
        assert render["authored_visual_layout_active"] and render["authored_visual_layout_id"] == "gm01_frontier_outpost_v1"
        assert render["authored_visual_owned_tile_count"] > 0
        facts = result["facts"]
        assert facts["isolated_user_data"] and facts["ui_test_user_data_dir"].replace("\\", "/").rstrip("/").endswith("/" + NAMESPACE)
        assert not any(facts[key] for key in ["synthetic_fixture", "time_acceleration", "forced_arrival", "forced_unloading", "private_simulation_state_writes", "profile_reset"])
        evidence = {**profile, "view": "mission", "variant": "zielbild", "fixture": False, "source_capture": True, "synthetic_image_fallback": False, "scaled_capture": False, "logical_size": dimensions, "image_size": dimensions, "renderer": result["renderer"], "profile": render, "image_sha256": actual["sha256"], "source_image": actual["path"].removeprefix("res://"), "source_report": result_path.relative_to(ROOT).as_posix(), "normal_start_checks": result["passed"], "normal_start_failures": 0, "exit_code": process.returncode, "error_count": len(errors), "scope": "Real menu -> Homebase -> saved GM01 -> timed transport -> LZ -> deployment -> Move/GO. Native captures require separate visual review; no campaign, combat, release or performance acceptance."}
        records.append(evidence)
        write_json(run / "capture_results.json", records)
        print(f"{size}: PASS normal start / {result['passed']} checks; {folder}", flush=True)
    print(f"Evidence: {run}", flush=True)


if __name__ == "__main__":
    main()
