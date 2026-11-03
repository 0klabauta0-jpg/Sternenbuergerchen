"""Run the existing normal-start smoke sequentially at real UI resolutions."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sizes", nargs="+", default=["1920x1080", "1280x720"])
    args = parser.parse_args()
    project = ROOT / "project.godot"
    original = project.read_bytes()
    assert b"config/use_custom_user_dir" not in original
    isolated = original.replace(b"[application]\n", b'[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="SternenBuergerchen_UI_R4_Normalstart"\n', 1)
    assert isolated != original
    captures = QA / "captures"
    captures.mkdir(exist_ok=True)
    records_path = QA / "frontier_capture_results.json"
    records = json.loads(records_path.read_text(encoding="utf-8")) if records_path.exists() else []
    for size in args.sizes:
        folder = QA / "frontier" / (size + "_" + time.strftime("%Y%m%dT%H%M%SZ", time.gmtime()))
        folder.mkdir(parents=True)
        result_path = folder / "startup.json"
        relative = "res://" + result_path.relative_to(ROOT).as_posix()
        command = ["godot_console", "--path", str(ROOT), "--rendering-method", "forward_plus", "--rendering-driver", "vulkan", "--audio-driver", "Dummy", "--script", "res://scripts/tests/ui_native_r4_frontier_capture.gd", "--", "--ui-size=" + size, "--startup-timeout-seconds=150", "--evidence-output=" + relative]
        try:
            project.write_bytes(isolated)
            process = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
        finally:
            for attempt in range(20):
                try:
                    project.write_bytes(original)
                    break
                except OSError:
                    if attempt == 19:
                        raise
                    time.sleep(0.2)
        assert project.read_bytes() == original
        (folder / "startup.log").write_bytes(process.stdout)
        log = process.stdout.decode("utf-8", errors="replace")
        errors = re.findall(r"(?im)^(?:SCRIPT ERROR:|ERROR:|.*ObjectDB instances leaked|.*Resources still in use)", log)
        (folder / "process.json").write_bytes((json.dumps({"exit_code": process.returncode, "error_count": len(errors), "logical_size": size, "driver": "vulkan", "command": command, "isolated_user_data": True, "project_restored_byte_exact": True, "original_project_sha256": hashlib.sha256(original).hexdigest(), "test_project_sha256": hashlib.sha256(isolated).hexdigest()}, indent=2) + "\n").encode())
        assert process.returncode == 0 and not errors and result_path.exists(), f"{size}: startup exit/errors, see {folder}"
        result = json.loads(result_path.read_text(encoding="utf-8"))
        assert result["failed"] == 0 and result["passed"] > 0
        actual = next(item for item in result["captures"] if item["id"] == "06_go_movement")
        image_path = ROOT / actual["path"].replace("res://", "", 1)
        dimensions = [int(n) for n in size.split("x")]
        assert [actual["width"], actual["height"]] == dimensions
        assert hashlib.sha256(image_path.read_bytes()).hexdigest() == actual["sha256"]
        stage = next(item for item in result["stages"] if item["id"] == "mission_started")
        render = stage["details"]["render"]
        assert render["frontier_art_enabled"] and render["grid_topology"] == "square8"
        facts = result["facts"]
        assert facts["isolated_user_data"] and "SternenBuergerchen_UI_R4_Normalstart" in facts["ui_test_user_data_dir"]
        assert not facts["synthetic_fixture"] and not facts["time_acceleration"] and not facts["private_simulation_state_writes"]
        target = captures / ("mission_frontier_" + size)
        shutil.copyfile(image_path, target.with_suffix(".png"))
        evidence = {"view": "mission", "variant": "frontier", "fixture": False, "source_capture": True, "synthetic_image_fallback": False, "scaled_capture": False, "logical_size": dimensions, "image_size": dimensions, "renderer": result["renderer"], "profile": render, "image_sha256": actual["sha256"], "source_image": image_path.relative_to(ROOT).as_posix(), "source_report": result_path.relative_to(ROOT).as_posix(), "normal_start_checks": result["passed"], "normal_start_failures": 0, "scope": "Real menu -> Homebase -> saved GM01 -> timed transport -> LZ -> deployment -> Move/GO. No full campaign, combat, release or performance acceptance."}
        evidence["exit_code"] = process.returncode
        evidence["error_count"] = len(errors)
        evidence["isolated_user_data"] = True
        evidence["project_restored_byte_exact"] = True
        target.with_suffix(".json").write_bytes((json.dumps(evidence, indent=2) + "\n").encode())
        records = [old for old in records if old["logical_size"] != dimensions] + [evidence]
        print(f"{size}: PASS normal Frontier start / {result['passed']} checks", flush=True)
        (QA / "frontier_capture_results.json").write_bytes((json.dumps(records, indent=2) + "\n").encode())


if __name__ == "__main__":
    main()
