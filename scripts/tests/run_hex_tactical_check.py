"""One bounded, isolated Hex contract case; never loads the game's main scene."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import uuid


CASES = {
    "ground": ("hex_ground_state_verifier.gd", "HEX_GROUND_STATE_PASS"),
    "visibility": ("hex_visibility_verifier.gd", "HEX_VISIBILITY_PASS"),
    "detection": ("hex_detection_verifier.gd", "HEX_DETECTION_PASS"),
    "owner": ("hex_ground_owner_verifier.gd", "HEX_GROUND_OWNER_PASS"),
    "consumers": ("hex_sight_consumers_verifier.gd", "HEX_SIGHT_CONSUMERS_PASS"),
    "facing": ("hex_facing_state_verifier.gd", "HEX_FACING_STATE_PASS"),
    "security": ("hex_security_consumers_verifier.gd", "HEX_SECURITY_CONSUMERS_PASS"),
    "reservation": ("hex_reservation_verifier.gd", "HEX_RESERVATION_PASS"),
    "reservation_owner": ("hex_reservation_owner_verifier.gd", "HEX_RESERVATION_OWNER_PASS"),
    "topology": ("hex_neighbor_cache_verifier.gd", "HEX_NEIGHBOR_CACHE_PASS"),
    "corridors": ("output/native_glut_maps/hex_corridor_cache_20261111/verifier.gd", "HEX_CORRIDOR_CACHE_PASS"),
    "corridor_integration": ("hex_corridor_integration_verifier.gd", "HEX_CORRIDOR_INTEGRATION_PASS"),
    "projection": ("hex_motion_projection_verifier.gd", "HEX_MOTION_PROJECTION_PASS"),
    "movement_stop": ("hex_movement_stop_verifier.gd", "HEX_MOVEMENT_STOP_PASS"),
    "locations": ("hex_location_runtime_verifier.gd", "HEX_LOCATION_RUNTIME_PASS"),
    "movement": ("hex_movement_verifier.gd", "HEX_MOVEMENT_PASS"),
    "movement_consumers": ("hex_movement_consumers_verifier.gd", "HEX_MOVEMENT_CONSUMERS_PASS"),
    "execution_members": ("hex_execution_members_verifier.gd", "HEX_EXECUTION_MEMBERS_PASS"),
    "execution_controller": ("hex_execution_controller_verifier.gd", "HEX_EXECUTION_CONTROLLER_PASS"),
    "moving_shot": ("hex_moving_shot_verifier.gd", "HEX_MOVING_SHOT_PASS"),
    "door_guard": ("hex_door_guard_verifier.gd", "HEX_DOOR_GUARD_PASS"),
    "backoff": ("hex_backoff_execution_verifier.gd", "HEX_BACKOFF_EXECUTION_PASS"),
    "lifecycle": ("hex_ground_lifecycle_verifier.gd", "HEX_GROUND_LIFECYCLE_PASS"),
    "admission_slots": ("hex_admission_slots_verifier.gd", "HEX_ADMISSION_SLOTS_PASS"),
    "deployment_phase": ("hex_deployment_phase_verifier.gd", "HEX_DEPLOYMENT_PHASE_PASS"),
    "deployment_controller": ("hex_deployment_controller_verifier.gd", "HEX_DEPLOYMENT_CONTROLLER_PASS"),
    "ship_footprint": ("hex_ground_ship_footprint_verifier.gd", "HEX_GROUND_SHIP_FOOTPRINT_PASS"),
    "ship_producer": ("hex_ground_ship_producer_verifier.gd", "HEX_GROUND_SHIP_PRODUCER_PASS"),
    "base_personnel": ("hex_base_personnel_owner_verifier.gd", "HEX_BASE_PERSONNEL_OWNER_PASS"),
    "base_boarding": ("hex_base_boarding_verifier.gd", "HEX_BASE_BOARDING_PASS"),
    "base_unboard_transaction": ("hex_base_unboard_transaction_verifier.gd", "HEX_BASE_UNBOARD_TRANSACTION_PASS"),
    "mission_setup": ("hex_mission_setup_verifier.gd", "HEX_MISSION_SETUP_PASS"),
    "mission_wave": ("hex_mission_wave_verifier.gd", "HEX_MISSION_WAVE_PASS"),
    "respawn": ("hex_respawn_verifier.gd", "HEX_RESPAWN_PASS"),
    "polisa_visit": ("polisa_real_visit_board_retire_probe.gd", "POLISA_REAL_VISIT_BOARD_RETIRE passed="),
    "medical_consumer": ("output/native_glut_maps/medical_completed_consumer_guard_20261112/check.gd", "MEDICAL_COMPLETED_CONSUMER_GUARD passed=4 failed=0"),
    "actor_prepared": ("output/native_glut_maps/actor_prepared_respawn_20261112/check.gd", "ACTOR_PREPARED_RESPAWN passed=24 failed=0"),
}
ANSI = re.compile(r"\x1b\[[0-9;]*m")
ERROR = re.compile(r"^(?:ERROR:|SCRIPT ERROR:)|ObjectDB instances leaked|resources still in use", re.M)


def fingerprint(directory: Path) -> dict:
    if not directory.exists():
        return {}
    return {str(p.relative_to(directory)): [hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mtime_ns]
            for p in directory.rglob("*") if p.is_file()}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", required=True, choices=CASES)
    parser.add_argument("--flow-ref", help="Explicit private cross-branch Flow dependency for polisa_visit; default: workspace")
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[2]
    script, marker = CASES[args.case]
    script_path = script if "/" in script else "scripts/tests/" + script
    dependency_refs = {}
    workspace_hashes = {}
    resolved_head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source).decode().strip()
    parent_ref = args.flow_ref or resolved_head
    def read_source(relative):
        origin = source / relative
        if args.case == "polisa_visit" and args.flow_ref and relative == "scripts/meta/meta_layer_flow.gd":
            if origin.is_file():
                workspace_hashes[relative] = hashlib.sha256(origin.read_bytes()).hexdigest()
            dependency_refs[relative] = parent_ref
            return subprocess.check_output(["git", "show", parent_ref + ":" + relative], cwd=source)
        if origin.is_file():
            data = origin.read_bytes()
            workspace_hashes[relative] = hashlib.sha256(data).hexdigest()
            return data
        if args.case in {"polisa_visit", "medical_consumer", "execution_controller"}:
            for ref in [resolved_head] + ([parent_ref] if args.case == "polisa_visit" else []):
                result = subprocess.run(["git", "show", ref + ":" + relative], cwd=source,
                                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if result.returncode == 0:
                    dependency_refs[relative] = ref
                    return result.stdout
        raise FileNotFoundError(relative)
    run = source / ".godot/hex_tactical_checks" / (args.case + "-" + uuid.uuid4().hex)
    project = run / "project"
    project.mkdir(parents=True)
    app_name = "SB-Codex-Review2-" + uuid.uuid4().hex
    user_root = Path(os.environ["APPDATA"]) / "Godot/app_userdata" / app_name
    if user_root.exists():
        raise RuntimeError("Private profile must be fresh")
    real_user = Path(os.environ["APPDATA"]) / "Godot/app_userdata/Sternenbuergerchen"
    before = fingerprint(real_user)
    paths = [
        script_path,
        "scripts/tests/review2_isolated_user_guard.gd",
        "scripts/terrain/hex_grid.gd",
        "scripts/terrain/terrain_tile_data.gd",
        "scripts/terrain/terrain_registry.gd",
        "scripts/terrain/hex_corridor_topology_cache.gd",
        "scripts/terrain/terrain_truth_audit.gd",
        "scripts/core/los_system.gd",
        "scripts/core/hex_ground_runtime.gd",
        "scripts/tactical/bottleneck_reservation_resolver.gd",
        "scripts/core/hex_visibility_query.gd",
        "scripts/core/hex_detection_state.gd",
        "scripts/mission/combat_visibility_cache.gd",
    ]
    if args.case == "reservation":
        paths.append("scripts/tactical/bottleneck_reservation_resolver.gd")
    if args.case in {"owner", "consumers", "facing", "security", "locations", "movement", "movement_consumers", "execution_members", "moving_shot", "door_guard", "backoff", "lifecycle", "admission_slots", "deployment_phase", "deployment_controller", "ship_footprint", "ship_producer", "base_personnel", "base_boarding", "base_unboard_transaction", "mission_setup", "mission_wave", "respawn", "actor_prepared", "polisa_visit", "medical_consumer", "execution_controller"}:
        # Only the real owner's bounded preload closure; no game autoloads/scenes.
        pending = ["scripts/core/simulation_root.gd", "scripts/terrain/terrain_map_data.gd"]
        if args.case == "actor_prepared":
            pending.append(script_path)
        if args.case in {"polisa_visit", "medical_consumer", "execution_controller"}:
            pending.extend([script_path, "scripts/meta/meta_layer_flow.gd",
                            "scripts/tests/mission_tactical_sandbox_controller.gd"])
        if args.case in {"movement", "movement_consumers"}:
            pending.append("scripts/registries/unit_registry.gd")
        if args.case == "execution_members":
            pending.extend(["scripts/tests/hex_ground_lifecycle_verifier.gd",
                            "scripts/tests/hex_movement_verifier.gd",
                            "scripts/registries/unit_registry.gd",
                            "scripts/tactical/fireteam_movement_controller.gd"])
        if args.case == "moving_shot":
            pending.extend(["scripts/tests/hex_movement_verifier.gd","scripts/registries/unit_registry.gd","scripts/npc/test_unit.gd"])
        if args.case == "door_guard":
            pending.extend(["scripts/tests/hex_movement_verifier.gd","scripts/registries/unit_registry.gd","scripts/tests/mission_combat_loop_driver.gd"])
        if args.case == "backoff":
            pending.extend(["scripts/tests/hex_movement_verifier.gd","scripts/registries/unit_registry.gd"])
        if args.case in {"lifecycle", "admission_slots", "deployment_phase", "deployment_controller", "ship_footprint", "ship_producer", "base_personnel", "base_boarding", "base_unboard_transaction", "mission_setup", "mission_wave", "respawn", "polisa_visit", "medical_consumer", "execution_controller"}:
            pending.extend(["scripts/tests/hex_movement_verifier.gd","scripts/registries/unit_registry.gd"])
        if args.case in {"admission_slots", "deployment_phase", "deployment_controller", "ship_footprint", "ship_producer", "base_personnel", "base_boarding", "base_unboard_transaction", "mission_setup", "mission_wave", "respawn", "polisa_visit", "medical_consumer", "execution_controller"}:
            pending.append("scripts/tests/hex_ground_lifecycle_verifier.gd")
        if args.case in {"base_personnel", "base_boarding", "base_unboard_transaction", "mission_setup", "mission_wave", "respawn", "polisa_visit", "medical_consumer", "execution_controller"}:
            pending.extend([script_path,"scripts/tests/hex_base_personnel_owner_verifier.gd","scripts/core/base_personnel_runtime.gd"])
        if args.case == "ship_footprint":
            pending.extend(["scripts/mission/polisa_ground_body_profile.gd","scripts/mission/polisa_station_craft_runtime.gd"])
            if (source / "scripts/mission/hex_ground_ship_footprint.gd").exists():
                pending.append("scripts/mission/hex_ground_ship_footprint.gd")
            paths.append("data/frontier_ship_visual_catalog.json")
        if args.case in {"deployment_phase", "deployment_controller", "ship_producer"}:
            pending.append("scripts/tests/hex_admission_slots_verifier.gd")
            if (source / "scripts/mission/hex_ground_deployment_adapter.gd").exists():
                pending.append("scripts/mission/hex_ground_deployment_adapter.gd")
        if args.case in {"deployment_controller", "ship_producer"}:
            pending.extend(["scripts/tests/hex_deployment_phase_verifier.gd","scripts/tests/mission_tactical_sandbox_controller.gd"])
        if args.case in {"mission_setup", "mission_wave", "respawn", "polisa_visit", "medical_consumer", "execution_controller"}:
            pending.extend([script_path,"scripts/tests/mission_test_setup.gd","scripts/registries/ftl_registry.gd"])
        if args.case == "base_unboard_transaction":
            pending.extend([script_path,"scripts/tests/hex_base_boarding_verifier.gd","scripts/meta/homebase_screen.gd"])
        if args.case == "ship_producer":
            pending.extend([script_path,"scripts/tests/hex_deployment_controller_verifier.gd"])
            paths.append("data/frontier_ship_visual_catalog.json")
        if args.case == "movement_consumers":
            pending.extend(["scripts/tests/hex_movement_verifier.gd",
                            "scripts/terrain/terrain_map_3d_view.gd",
                            "scripts/tactical/fireteam_movement_controller.gd"])
            paths.append("shaders/terrain/hex_grid_coverage.gdshader")
        if args.case == "security":
            pending.extend(["scripts/core/hex_sight_runtime_adapter.gd",
                            "scripts/tactical/fireteam_security_controller.gd",
                            "scripts/tactical/overwatch_controller.gd",
                            "scripts/tactical/flank_vulnerability_resolver.gd"])
        if args.case == "consumers":
            pending.extend(["scripts/tests/mission_combat_loop_driver.gd",
                            "scripts/tactical/combat_fire_decision_resolver.gd",
                            "scripts/core/fog_of_war_system.gd"])
            if (source / "scripts/core/hex_sight_runtime_adapter.gd").exists():
                pending.append("scripts/core/hex_sight_runtime_adapter.gd")
        visited = set()
        while pending:
            relative = pending.pop()
            if relative in visited:
                continue
            visited.add(relative)
            paths.append(relative)
            if args.case in {"deployment_controller", "ship_producer", "base_unboard_transaction", "mission_setup", "mission_wave", "respawn", "polisa_visit", "medical_consumer", "execution_controller"} and Path(relative).suffix not in {".gd", ".tscn", ".tres", ".gdshader"}:
                continue
            code = read_source(relative).decode("utf-8-sig")
            pending.extend(re.findall(r'(?:preload|load)\(\s*"res://([^\"]+\.gd)"', code))
            if args.case in {"deployment_controller", "ship_producer", "base_unboard_transaction", "mission_setup", "mission_wave", "respawn", "polisa_visit", "medical_consumer", "execution_controller"}:
                pending.extend(re.findall(r'preload\(\s*"res://([^\"]+)"', code))
                pending.extend(re.findall(r'path="res://([^\"]+)"', code))
                pending.extend(re.findall(r'extends\s+"res://([^\"]+)"', code))
            if args.case == "movement_consumers":
                paths.extend(re.findall(r'preload\(\s*"res://([^\"]+)"', code))
        paths.append("data/terrain_tile_catalog.json")
        if args.case in {"consumers", "door_guard", "deployment_controller", "ship_producer", "base_unboard_transaction", "mission_setup", "mission_wave", "respawn", "polisa_visit", "medical_consumer", "execution_controller"}:
            paths.extend(["addons/limboai/bin/limboai.gdextension",
                          "addons/limboai/bin/liblimboai.windows.editor.x86_64.dll"])
    paths = list(dict.fromkeys(paths))
    hashes = {}
    for relative in paths:
        origin = source / relative
        if not origin.is_file() and args.case not in {"polisa_visit", "medical_consumer", "execution_controller"}:
            continue  # Missing implementation is a clean assertion in the RED verifier.
        target = project / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        data = read_source(relative)
        target.write_bytes(data)
        hashes[relative] = hashlib.sha256(data).hexdigest()
        assert hashlib.sha256(target.read_bytes()).hexdigest() == hashes[relative]
    config = ('config_version=5\n[application]\nconfig/name=' + json.dumps(app_name)
              + '\n[autoload]\nReview2Isolation="*res://scripts/tests/review2_isolated_user_guard.gd"\n')
    (project / "project.godot").write_text(config, encoding="utf-8")
    if args.case in {"consumers", "door_guard", "deployment_controller", "ship_producer", "base_unboard_transaction", "mission_setup", "mission_wave", "respawn", "polisa_visit", "medical_consumer", "execution_controller"}:
        (project / ".godot").mkdir(exist_ok=True)
        (project / ".godot/extension_list.cfg").write_text(
            'res://addons/limboai/bin/limboai.gdextension\n', encoding="utf-8")
    engine = shutil.which("godot_console.exe")
    if engine is None:
        raise RuntimeError("godot_console.exe is unavailable")
    argv = [engine, "--headless", "--path", str(project), "--script", "res://" + script_path]
    prepare_argv = [engine, "--headless", "--editor", "--path", str(project), "--import", "--quit"]
    env = dict(os.environ, SB_REVIEW2_USER_DIR=str(user_root))
    with (run / "output.log").open("w", encoding="utf-8") as stream:
        try:
            prepared = subprocess.run(prepare_argv, env=env, stdout=stream,
                                      stderr=subprocess.STDOUT, timeout=30)
            result = subprocess.run(argv, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=30) \
                if prepared.returncode == 0 else prepared
        except subprocess.TimeoutExpired:
            stream.write("\nERROR: bounded contract process timed out\n")
            result = subprocess.CompletedProcess(argv, 124)
    output = ANSI.sub("", (run / "output.log").read_text(encoding="utf-8", errors="replace"))
    after = fingerprint(real_user)
    unchanged = before == after
    profile_changes = [name for name in sorted(before.keys() | after.keys())
                       if before.get(name) != after.get(name)]
    copied_unchanged = all((source / p).is_file() and hashlib.sha256((source / p).read_bytes()).hexdigest() == value
                           for p, value in workspace_hashes.items())
    isolated = (user_root / "review2_isolation_canary.json").is_file()
    passed = result.returncode == 0 and marker in output and not ERROR.search(output) \
        and unchanged and copied_unchanged and isolated
    report = {"case": args.case, "passed": passed, "exit_code": result.returncode,
              "source_sha256": hashes, "sources_unchanged": copied_unchanged,
              "workspace_source_sha256": workspace_hashes, "dependency_source_refs": dependency_refs,
              "real_profile_unchanged": unchanged, "isolated": isolated,
              "real_profile_changes": profile_changes,
              "argv": argv, "prepare_argv": prepare_argv, "log": str(run / "output.log")}
    (run / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(output.rstrip())
    print("REPORT=" + str(run / "report.json"))
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
