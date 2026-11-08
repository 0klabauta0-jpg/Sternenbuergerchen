"""Serial fullscreen playtest checks/captures using private overlays and protected roster."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import uuid

from run_review2_isolated import ANSI, ERROR, check_roster, create_overlay


def source_pins(root: Path, script: str) -> dict:
    paths = {script.removeprefix("res://"),
             "scripts/tests/mission_tactical_sandbox_controller.gd",
             "scripts/terrain/terrain_map_3d_view.gd",
             "scripts/terrain/weapon_fire_feedback_pulse.gd",
             "scripts/terrain/weapon_fire_feedback_layer.gd",
             "scripts/tactical/periodic_hud_projection_queue.gd",
             "data/npc_unit_visual_mapping.json",
             "scripts/tests/runtime_hitches_r4_20261107_strategic_source_oracle.json",
             "scripts/core/fog_of_war_system.gd",
             "scripts/core/los_system.gd",
             "scripts/terrain/terrain_registry.gd",
             "scripts/tactical/fireteam_movement_controller.gd",
             "scripts/tests/runtime_hitches_r4_20261107_native_capture.gd",
             "scripts/tests/reference_polish_r3_20261106_native_capture.gd",
               "scripts/terrain/frontier_gm01_layout.gd",
               "scripts/terrain/frontier_reference_dressing.gd",
             "scripts/core/simulation_root.gd",
             "scripts/ui/mission_a5_hud_layout.gd",
               "scripts/ui/native_ui_icons.gd",
             "scripts/ui/tactical_ui_theme.gd",
             "scripts/tests/mission_test_setup.gd",
             "scripts/meta/homebase_screen.gd",
             "scripts/meta/meta_ui_skin.gd",
             "scripts/ui/reference_panel_frame.gd",
             "scripts/tests/hud_architecture_20261106_native_capture.gd",
             "scripts/tests/playtest_20261105_motion_order_capture.gd",
             "scripts/tactical/mission_hud_read_model.gd",
             "scripts/meta/homebase_operations_presenter.gd",
             "scripts/tests/mission_combat_loop_driver.gd",
             "scripts/mission/mission_interaction_door_runtime_collision_los.gd",
             "scripts/mission/mission_interaction_object_reaction.gd",
             "scripts/tests/playtest_20261105_fullscreen_performance_capture.gd",
             "scripts/tests/ui_zielbild_normal_capture.gd",
             "scripts/tests/run_runtime_hitches_r4_20261107.py"}
    return {path: hashlib.sha256((root / path).read_bytes()).hexdigest() for path in sorted(paths)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest")
    parser.add_argument("--script")
    parser.add_argument("--marker", default="")
    parser.add_argument("--filter", default="")
    parser.add_argument("--label", required=True)
    parser.add_argument("--native", action="store_true")
    parser.add_argument("--namespace")
    parser.add_argument("--baseline-runtime-ref", help="Exact Git commit for private scripts/data only")
    parser.add_argument("--timeout", type=float, default=150)
    parser.add_argument("args", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.baseline_runtime_ref and not re.fullmatch(r"[0-9a-f]{40}", args.baseline_runtime_ref):
        parser.error("Baseline runtime ref must be an exact commit SHA")
    if not re.fullmatch(r"[A-Za-z0-9_-]+", args.label):
        parser.error("Unsafe label")
    root = Path(__file__).resolve().parents[2]
    evidence = root / "output/runtime_hitches_r4_20261107"
    baseline = json.loads((evidence / "roster_baseline.json").read_text(encoding="utf-8"))
    original = check_roster(baseline)
    project_hash = hashlib.sha256((root / "project.godot").read_bytes()).hexdigest()
    cases = json.loads((root / args.manifest).read_text(encoding="utf-8-sig"))["checks"] if args.manifest else [
        {"name": Path(args.script).stem, "script": args.script, "success_marker": args.marker,
         "timeout": args.timeout, "args": args.args[1:] if args.args[:1] == ["--"] else args.args}]
    cases = [case for case in cases if args.filter in case["name"]]
    if not cases:
        parser.error("No selected cases")
    for case in cases:
        path = Path(case["script"].removeprefix("res://"))
        if path.is_absolute() or ".." in path.parts or not (root / path).is_file():
            parser.error("Invalid script")
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", case["name"]):
            parser.error("Invalid check name")
    run = evidence / args.label / (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8])
    run.mkdir(parents=True, exist_ok=False)
    results = []
    for case in cases:
        check_roster(baseline)
        overlay, name = create_overlay(root, uuid.uuid4().hex)
        baseline_runtime = None
        if args.baseline_runtime_ref:
            # Remove only the two newly created junctions, never their targets.
            # All baseline writes then land in private physical directories.
            for directory in ("scripts", "data"):
                junction = overlay / directory
                if (not junction.is_junction() or junction.resolve() != (root / directory).resolve()
                        or junction.parent.resolve() != overlay.resolve()):
                    raise RuntimeError("Unexpected baseline overlay junction")
                os.rmdir(junction)
                junction.mkdir()
            archive_bytes = subprocess.check_output(
                ["git", "archive", args.baseline_runtime_ref, "scripts", "data"], cwd=root)
            with tarfile.open(fileobj=io.BytesIO(archive_bytes)) as archive:
                for member in archive.getmembers():
                    relative = Path(member.name)
                    if (relative.is_absolute() or ".." in relative.parts
                            or relative.parts[0] not in ("scripts", "data")
                            or not (member.isdir() or member.isfile())):
                        raise RuntimeError("Unsafe baseline archive member")
                archive.extractall(overlay, filter="data")
            baseline_runtime = {"ref": args.baseline_runtime_ref, "private_directories": ["scripts", "data"],
                                "git_archive_sha256": hashlib.sha256(archive_bytes).hexdigest(),
                                "source_junctions_detached_before_writes": True}
        # The menu gate reads an immutable source-capture record under output/.
        # Keep writable outputs private and copy only this pinned input record.
        catalog = json.loads((root / "data/background_image_catalog.json").read_text(encoding="utf-8"))
        provenance = []
        records = [entry for entry in catalog["backgrounds"] if "source_capture" in entry]
        environment = json.loads((root / "output/grafik_20261101/pass06_environment_before_manifest.json").read_text(encoding="utf-8"))
        records.append({"source_capture": "res://" + environment["capture_metadata"],
                        "source_capture_sha256": environment["capture_metadata_sha256"]})
        for entry in records:
            relative = Path(entry["source_capture"].removeprefix("res://"))
            if relative.is_absolute() or ".." in relative.parts or relative.parts[0] != "output":
                raise RuntimeError("Unexpected source-capture input path")
            source = root / relative
            digest = hashlib.sha256(source.read_bytes()).hexdigest()
            if digest != entry["source_capture_sha256"]:
                raise RuntimeError("Source-capture input differs from its catalog pin")
            destination = overlay / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
            provenance.append({"path": relative.as_posix(), "sha256": digest})
        user_dir = Path(os.environ["APPDATA"]) / "Godot/app_userdata" / name
        if args.namespace:
            # The existing normal-route driver checks the final directory name.
            # A unique parent provides fresh data while retaining its exact guard.
            custom = name + "/" + args.namespace
            config = overlay / "project.godot"
            source = config.read_text(encoding="utf-8")
            source = source.replace("config/use_custom_user_dir=false", "config/use_custom_user_dir=true\nconfig/custom_user_dir_name=" + json.dumps(custom))
            config.write_text(source, encoding="utf-8")
            user_dir = Path(os.environ["APPDATA"]) / custom
        if user_dir.exists():
            raise RuntimeError("Native test profile is not fresh")
        env = dict(os.environ, SB_REVIEW2_USER_DIR=str(user_dir))
        log = run / (case["name"] + ".log")
        argv = ["godot_console.exe", "--path", str(overlay)]
        argv += ["--fullscreen", "--rendering-method", "forward_plus", "--rendering-driver", "vulkan"] if args.native else ["--headless"]
        argv += ["--script", str(overlay / case["script"].removeprefix("res://"))]
        native_args = [str(value).replace("{RUN}", str(run).replace("\\", "/")) for value in case.get("args", [])]
        if native_args:
            argv += ["--", *native_args]
        inputs_before = source_pins(root, case["script"])
        timed_out = False
        code = -1
        with log.open("w", encoding="utf-8") as stream:
            try:
                code = subprocess.run(argv, env=env, stdout=stream, stderr=subprocess.STDOUT,
                                      timeout=float(case.get("timeout", args.timeout)), check=False).returncode
            except subprocess.TimeoutExpired:
                timed_out = True
        after = check_roster(baseline)
        inputs_after = source_pins(root, case["script"])
        raw = ANSI.sub("", log.read_text(encoding="utf-8", errors="replace"))
        errors = ERROR.findall(raw)
        marker = case.get("success_marker", "")
        isolated = "REVIEW2_ISOLATED_USER_DATA " in raw and (user_dir / "review2_isolation_canary.json").is_file()
        passed = code == 0 and not timed_out and not errors and isolated and bool(marker) and marker in raw and inputs_before == inputs_after
        results.append({"name": case["name"], "passed": passed, "exit_code": code,
                        "timed_out": timed_out, "error_count": len(errors), "isolation_verified": isolated,
                        "user_dir": str(user_dir), "project": str(overlay), "log": str(log), "argv": argv,
                        "immutable_input_records": provenance,
                        "roster_before": original, "roster_after": after,
                        "source_inputs_before": inputs_before, "source_inputs_after": inputs_after,
                        "source_inputs_stable": inputs_before == inputs_after})
        results[-1]["baseline_runtime"] = baseline_runtime
        print(case["name"], "PASS" if passed else "FAIL", "exit", code, "errors", len(errors), flush=True)
    if project_hash != hashlib.sha256((root / "project.godot").read_bytes()).hexdigest():
        raise RuntimeError("Source project settings changed")
    report = {"schema": "sternenbuergerchen.runtime_hitches_r4_20261107.v1", "checks": results,
              "source_project_sha256": project_hash, "protected_roster": check_roster(baseline),
              "summary": {"selected": len(results), "passed": sum(item["passed"] for item in results),
                          "failed": sum(not item["passed"] for item in results)}}
    (run / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(report["summary"], "report:", run / "report.json", flush=True)
    return 0 if all(item["passed"] for item in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
