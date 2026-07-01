extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_716_station_route_run_readout_polish.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const SOURCE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TEST_SCENARIO_PATH: String = "res://tmp/task_716_station_route_run_readout_polish_scenario.json"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_run_readout_polish.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const DOOR_INTERACTION_ID: String = "station_route_run_readout_door"
const COMMAND_FEEDBACK_LABEL_PATH: NodePath = NodePath("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/CommandFeedbackLabel")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_716 Station Route Run Readout Polish ===")
	_test_docs()
	await _test_station_route_run_readout()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_716: FAILED")
		quit(1)
		return
	print("TASK_716: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_716 task file exists")
	_assert(task_text.contains("Station Route Run Readout Polish"), "Task documents Station Route Run Readout Polish")
	_assert(contract_text.contains("Station Route Run Readout Polish"), "Interaction contract documents TASK_716")
	_assert(status_text.contains("TASK_716 - Station Route Run Readout Polish"), "Implementation status tracks TASK_716")
	_assert(roadmap_text.contains("TASK_716 - Station Route Run Readout Polish (implementiert)"), "Roadmap marks TASK_716 implemented")
	_assert(report_text.contains("TASK_716 - Station Route Run Readout Polish"), "Current report references TASK_716")
	_assert(report_text.contains('data-export-key="station_route_run_readout_polish.route_line"'), "Current report exports TASK_716 route line")


func _test_station_route_run_readout() -> void:
	_ensure_output_dir()
	_write_test_scenario()
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var mission_setup: Node = scene.get_node_or_null("MissionSetup")
	_assert(controller != null and combat_driver != null and mission_setup != null, "Mission scene exposes controller, driver and setup")
	if controller == null or combat_driver == null or mission_setup == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", TEST_SCENARIO_PATH)), "Combat driver configures TASK_716 scenario")
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	_assert(not fireteam_id.is_empty(), "Verifier selects a fireteam")
	var station_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	var cargo_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "spawn_alpha", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, station_position)
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	await _wait_frames(2)

	var initial_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var initial_readout: Dictionary = Dictionary(initial_feedback.get("station_route_run_readout", {}))
	_assert(bool(initial_readout.get("active", false)), "Initial route readout is active")
	_assert(String(initial_readout.get("next_token", "")) == "COM", "Initial route points to computer after AA")
	_assert(_route_line_has_all_tokens(String(initial_readout.get("compact_line", ""))), "Initial route line names AA, Door, Computer and Cargo")

	combat_driver.call("update_mission_interaction_runtime_progress", _progress_payload(DOOR_INTERACTION_ID, "operating", true, 2.0, fireteam_id, "open_station_door", "door_open", "door", "breach"))
	await _wait_frames(3)
	controller.call("_update_ui")
	var door_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var door_readout: Dictionary = Dictionary(door_feedback.get("station_route_run_readout", {}))
	var door_line: String = String(door_readout.get("compact_line", ""))
	var label := scene.get_node_or_null(COMMAND_FEEDBACK_LABEL_PATH) as Label
	_assert(door_line.contains("DOOR OPEN"), "Door route line shows Door open")
	_assert(String(door_readout.get("next_token", "")) == "COM", "Door route line keeps computer as next step")
	_assert(bool(door_readout.get("read_only", false)) and not bool(door_readout.get("ui_sets_gameplay_truth", true)), "Route readout remains read-only")
	_assert(bool(door_readout.get("line_within_limit", false)), "Route line stays within char limit")
	_assert(label != null and label.text.contains(door_line), "Visible command feedback label contains route line")

	combat_driver.call("update_mission_interaction_runtime_progress", _progress_payload("station_computer", "operating", true, 18.0, fireteam_id, "occupy_station_computer", "computer_controlled", "computer", "take"))
	await _wait_frames(3)
	var computer_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var computer_readout: Dictionary = Dictionary(computer_feedback.get("station_route_run_readout", {}))
	var computer_line: String = String(computer_readout.get("compact_line", ""))
	_assert(computer_line.contains("COM CTRL"), "Computer route line shows controlled computer")
	_assert(String(computer_readout.get("next_token", "")) == "CARGO", "Computer route line points to cargo")

	_move_fireteam_units(scene, fireteam_id, cargo_position)
	combat_driver.call("update_mission_interaction_runtime_progress", _progress_payload("cargo_landing_hold", "holding", true, 12.0, fireteam_id, "cargo_touchdown_extract", "cargo_departed", "hold_zone", "defend"))
	await _wait_frames(3)
	var cargo_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var cargo_readout: Dictionary = Dictionary(cargo_feedback.get("station_route_run_readout", {}))
	var cargo_line: String = String(cargo_readout.get("compact_line", ""))
	_assert(cargo_line.contains("CARGO DEPARTED"), "Cargo route line shows departed cargo")
	_assert(String(cargo_readout.get("next_token", "")) == "DONE", "Cargo route line marks route done")
	_assert(bool(cargo_readout.get("all_gates_complete", false)), "Route readout exports all gates complete")

	_write_manifest({
		"schema": "sternenbuergerchen.station_route_run_readout_polish.v1",
		"task_id": "TASK_716",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"door_line": door_line,
		"computer_line": computer_line,
		"cargo_line": cargo_line,
		"final_next_token": String(cargo_readout.get("next_token", "")),
		"line_within_limit": bool(cargo_readout.get("line_within_limit", false)),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"recommended_next_task": "TASK_717 - Station Route Real Host/Client Click Findings",
	})
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_716 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_716", "Manifest records TASK_716")
	_assert(String(parsed.get("final_next_token", "")) == "DONE", "Manifest records final DONE token")
	_assert(bool(parsed.get("read_only", false)) and not bool(parsed.get("ui_sets_gameplay_truth", true)), "Manifest stays read-only")

	scene.queue_free()
	await _wait_frames(2)


func _progress_payload(interaction_id: String, state: String, complete: bool, seconds: float, fireteam_id: String, step_id: String, required_state: String, interaction_type: String, command_type: String) -> Dictionary:
	return {
		"interaction_id": interaction_id,
		"state": state,
		"complete": complete,
		"hold_seconds": seconds,
		"duration_seconds": seconds,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": step_id,
		"required_state": required_state,
		"interaction_type": interaction_type,
		"command_type": command_type,
	}


func _write_test_scenario() -> void:
	_ensure_output_dir()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_SCENARIO_PATH))
	var scenario: Dictionary = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	var interactions: Array = Array(vertical_slice.get("interaction_points", [])).duplicate(true)
	interactions.insert(1, {
		"interaction_id": DOOR_INTERACTION_ID,
		"display_name": "Station Route Run Door",
		"interaction_type": "door",
		"marker_id": "objective_point",
		"required_order": "breach",
		"duration_seconds": 2.0,
		"radius_world": 128.0,
		"required_team": "team_alpha",
		"step_id": "open_station_door",
		"gate_id": "open_station_door",
		"required_state": "door_open",
		"asset_hint": "station_set_door_single_closed",
	})
	vertical_slice["interaction_points"] = interactions
	scenario["vertical_slice"] = vertical_slice
	var file := FileAccess.open(TEST_SCENARIO_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_716 temp scenario for writing")
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()
	_assert(FileAccess.file_exists(TEST_SCENARIO_PATH), "TASK_716 temp scenario is written")


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
		mission_setup.set("scenario_file_path", TEST_SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _select_first_available_fireteam(controller: Node, mission_setup: Node) -> String:
	var available_ids: PackedStringArray = PackedStringArray(controller.call("_get_available_fireteam_ids"))
	var candidate_id: String = ""
	if not available_ids.is_empty():
		candidate_id = String(available_ids[0]).strip_edges().to_lower()
	else:
		var configured_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_fireteam_ids"))
		if not configured_ids.is_empty():
			candidate_id = String(configured_ids[0]).strip_edges().to_lower()
	if candidate_id.is_empty():
		candidate_id = "ft1"
	controller.call("_set_selected_fireteams", PackedStringArray([candidate_id]), false)
	var selected_ids: PackedStringArray = PackedStringArray(controller.call("get_selected_fireteam_ids"))
	return String(selected_ids[0]).strip_edges().to_lower() if not selected_ids.is_empty() else ""


func _move_fireteam_units(scene: Node, fireteam_id: String, center_position: Vector2) -> void:
	var offset_index: int = 0
	for child in scene.get_children():
		if not (child is Node2D):
			continue
		if not child.has_method("get_fireteam_id"):
			continue
		if String(child.call("get_fireteam_id")).strip_edges().to_lower() != fireteam_id:
			continue
		var offset: Vector2 = Vector2(float(offset_index % 2) * 10.0, float(int(offset_index / 2)) * 10.0)
		(child as Node2D).global_position = center_position + offset
		offset_index += 1


func _route_line_has_all_tokens(line: String) -> bool:
	return line.contains("AA ") and line.contains("DOOR ") and line.contains("COM ") and line.contains("CARGO ") and line.contains("NEXT ")


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_716 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
