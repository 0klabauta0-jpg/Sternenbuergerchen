extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_707_mission_door_computer_cargo_smoke.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const SOURCE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TEST_SCENARIO_PATH: String = "res://tmp/task_707_mission_door_computer_cargo_smoke_scenario.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/mission_door_computer_cargo_smoke.json"
const DOOR_INTERACTION_ID: String = "station_door_computer_cargo_smoke"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_707 Mission Door/Computer/Cargo Smoke ===")
	_test_docs()
	await _test_door_computer_cargo_flow()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_707: FAILED")
		quit(1)
		return
	print("TASK_707: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_707 task file exists")
	_assert(task_text.contains("Mission Door/Computer/Cargo Smoke"), "Task documents Door/Computer/Cargo smoke")
	_assert(contract_text.contains("Door/Computer/Cargo Smoke"), "Interaction contract documents TASK_707")
	_assert(status_text.contains("TASK_707 - Mission Door/Computer/Cargo Smoke"), "Implementation status tracks TASK_707")
	_assert(roadmap_text.contains("TASK_707 - Mission Door/Computer/Cargo Smoke (implementiert)"), "Roadmap marks TASK_707 implemented")
	_assert(report_text.contains("TASK_707 - Mission Door/Computer/Cargo Smoke"), "Report references TASK_707")
	_assert(report_text.contains('data-export-key="playtest.door_computer_cargo_smoke"'), "Report exports TASK_707 playtest check")


func _test_door_computer_cargo_flow() -> void:
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

	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", TEST_SCENARIO_PATH)), "Combat driver configures TASK_707 scenario")
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	_assert(not fireteam_id.is_empty(), "Verifier selects a fireteam")

	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	var station_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, station_position)
	await _wait_frames(2)

	var station_before_door: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(station_before_door.get("next_step_id", "")) == "occupy_station_computer", "After AA complete next gate remains station computer before Door")
	_assert(String(station_before_door.get("next_interaction_id", "")) == "station_computer", "Door smoke does not replace computer objective gate")

	combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": DOOR_INTERACTION_ID,
		"state": "operating",
		"complete": true,
		"hold_seconds": 2.0,
		"duration_seconds": 2.0,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": "open_station_door",
		"required_state": "door_open",
		"interaction_type": "door",
		"command_type": "breach",
	})
	await _wait_frames(4)
	controller.call("_sync_primary_3d_mission_status_visuals")
	await _wait_frames(4)
	var primary_view: Node = controller.call("_get_primary_3d_view")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Primary 3D view exposes render snapshot")
	var door_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	var door_entries: Array = Array(door_snapshot.get("mission_interaction_object_reaction_entries", []))
	_assert(_entry_field_equals(door_entries, DOOR_INTERACTION_ID, "runtime_visual_state", "open"), "Door opens before computer step")
	_assert(_entry_field_equals(door_entries, DOOR_INTERACTION_ID, "door_layout_tone", "success"), "Door open exports success layout tone")
	_assert(_entry_field_contains(door_entries, DOOR_INTERACTION_ID, "door_layout_readout", "path clear"), "Door open readout is visible in render snapshot")
	_assert(not _entry_bool(door_entries, DOOR_INTERACTION_ID, "door_visual_sets_gameplay_truth"), "Door smoke visual remains non-authoritative")

	var station_after_door: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(station_after_door.get("next_step_id", "")) == "occupy_station_computer", "Door open does not complete or skip station computer gate")

	combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": "station_computer",
		"state": "operating",
		"complete": true,
		"hold_seconds": 18.0,
		"duration_seconds": 18.0,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": "occupy_station_computer",
		"required_state": "computer_controlled",
		"interaction_type": "computer",
		"command_type": "take",
	})
	var cargo_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "spawn_alpha", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, cargo_position)
	await _wait_frames(2)
	var cargo_snapshot: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(cargo_snapshot.get("next_step_id", "")) == "cargo_touchdown_extract", "Computer control advances to cargo gate")
	_assert(String(cargo_snapshot.get("next_interaction_id", "")) == "cargo_landing_hold", "Cargo gate maps to cargo hold interaction")
	_assert(String(cargo_snapshot.get("next_line", "")).contains("NEXT CARGO"), "Cargo next line is visible")

	combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": "cargo_landing_hold",
		"state": "holding",
		"complete": true,
		"hold_seconds": 12.0,
		"duration_seconds": 12.0,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": "cargo_touchdown_extract",
		"required_state": "cargo_departed",
		"interaction_type": "hold_zone",
		"command_type": "defend",
	})
	await _wait_frames(2)
	var complete_snapshot: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(bool(complete_snapshot.get("all_gates_complete", false)), "Cargo departed completes all objective gates")
	_assert(String(complete_snapshot.get("next_line", "")) == "OBJECTIVES complete", "Complete line remains stable")
	_assert(_snapshot_is_read_only(complete_snapshot), "Complete objective snapshot remains read-only")

	_write_manifest({
		"schema": "sternenbuergerchen.mission_door_computer_cargo_smoke_manifest.v1",
		"task_id": "TASK_707",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"door_interaction_id": DOOR_INTERACTION_ID,
		"door_runtime_visual_state": _entry_string(door_entries, DOOR_INTERACTION_ID, "runtime_visual_state"),
		"door_layout_tone": _entry_string(door_entries, DOOR_INTERACTION_ID, "door_layout_tone"),
		"door_layout_readout": _entry_string(door_entries, DOOR_INTERACTION_ID, "door_layout_readout"),
		"station_before_door_next_step": String(station_before_door.get("next_step_id", "")),
		"station_after_door_next_step": String(station_after_door.get("next_step_id", "")),
		"cargo_next_line": String(cargo_snapshot.get("next_line", "")),
		"complete_next_line": String(complete_snapshot.get("next_line", "")),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	})
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_707 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_707", "Manifest records TASK_707")
	_assert(String(parsed.get("door_layout_tone", "")) == "success", "Manifest records Door success tone")
	_assert(String(parsed.get("complete_next_line", "")) == "OBJECTIVES complete", "Manifest records objective completion")

	scene.queue_free()
	await _wait_frames(2)


func _write_test_scenario() -> void:
	_ensure_output_dir()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_SCENARIO_PATH))
	var scenario: Dictionary = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	var interactions: Array = Array(vertical_slice.get("interaction_points", [])).duplicate(true)
	interactions.insert(1, {
		"interaction_id": DOOR_INTERACTION_ID,
		"display_name": "Station Door Smoke",
		"interaction_type": "door",
		"marker_id": "objective_point",
		"required_order": "breach",
		"duration_seconds": 2.0,
		"radius_world": 128.0,
		"required_team": "team_alpha",
		"step_id": "open_station_door",
		"gate_id": "open_station_door",
		"required_state": "door_open",
		"asset_hint": "station_set_door_single_closed"
	})
	vertical_slice["interaction_points"] = interactions
	scenario["vertical_slice"] = vertical_slice
	var file := FileAccess.open(TEST_SCENARIO_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_707 temp scenario for writing")
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()
	_assert(FileAccess.file_exists(TEST_SCENARIO_PATH), "TASK_707 temp scenario is written")


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


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


func _entry_field_equals(entries: Array, interaction_id: String, field_name: String, expected_value: String) -> bool:
	return _entry_string(entries, interaction_id, field_name) == expected_value


func _entry_field_contains(entries: Array, interaction_id: String, field_name: String, needle: String) -> bool:
	return _entry_string(entries, interaction_id, field_name).contains(needle)


func _entry_bool(entries: Array, interaction_id: String, field_name: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("interaction_id", "")).strip_edges() == interaction_id:
			return bool(entry.get(field_name, false))
	return false


func _entry_string(entries: Array, interaction_id: String, field_name: String) -> String:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("interaction_id", "")).strip_edges() == interaction_id:
			return String(entry.get(field_name, "")).strip_edges()
	return ""


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_707 manifest for writing")
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
