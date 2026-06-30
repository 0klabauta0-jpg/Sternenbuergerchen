extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_INTERACTION_OBJECT_REACTION_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_object_reaction.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_706_mission_door_layout_visual_polish.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const SOURCE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TEST_SCENARIO_PATH: String = "res://tmp/task_706_mission_door_layout_visual_polish_scenario.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/mission_door_layout_visual_polish.json"
const DOOR_INTERACTION_ID: String = "station_door_layout_polish_probe"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_706 Mission Door Layout/Visual Polish ===")
	_test_docs_and_report()
	_test_reaction_contract_fields()
	await _test_render_snapshot_exports_door_layout_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_706: FAILED")
		quit(1)
		return
	print("TASK_706: ALL PASSED")
	quit(0)


func _test_docs_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_706 task file exists")
	_assert(task_text.contains("Mission Door Layout/Visual Polish"), "Task documents Door layout visual polish")
	_assert(contract_text.contains("Mission Door Layout/Visual Polish"), "Interaction contract documents TASK_706")
	_assert(contract_text.contains("door_layout_readout"), "Contract documents Door layout readout")
	_assert(status_text.contains("TASK_706 - Mission Door Layout/Visual Polish"), "Implementation status tracks TASK_706")
	_assert(roadmap_text.contains("TASK_706 - Mission Door Layout/Visual Polish (implementiert)"), "Roadmap marks TASK_706 implemented")
	_assert(FileAccess.file_exists(REPORT_PATH), "Current state handbook refresh exists")
	_assert(report_text.contains("SternenBuergerchen Ist-Stand + Handbuch Refresh"), "Report title is present")
	_assert(report_text.contains('data-report-schema="sternenbuergerchen.html_workbench.v1"'), "Report uses HTML workbench schema")
	_assert(report_text.contains("JSON exportieren"), "Report exposes JSON export")
	_assert(report_text.contains('data-tab-target="handbook"'), "Report has handbook tab")
	_assert(report_text.contains('data-tab-target="friction"'), "Report has friction tab")
	_assert(report_text.contains('data-tab-target="playtest"'), "Report has playtest tab")
	_assert(report_text.contains("TASK_705 - Host/Client Door Real Click Manual Run Packet"), "Report names TASK_705")
	_assert(report_text.contains("TASK_706 - Mission Door Layout/Visual Polish"), "Report names TASK_706")
	_assert(report_text.contains("report_is_gameplay_truth: false"), "Report export marks itself as non-gameplay truth")
	_assert(report_text.contains('data-export-key="playtest.door_open_visible"'), "Report exports Door open playtest check")


func _test_reaction_contract_fields() -> void:
	var snapshot: Dictionary = Dictionary(MISSION_INTERACTION_OBJECT_REACTION_SCRIPT.call("build_snapshot", {
		"schema": "test.visual_state",
		"entries": [
			_visual_entry("door_closed", "usable", 0.0),
			_visual_entry("door_operating", "in_progress", 0.5),
			_visual_entry("door_open", "complete", 1.0),
		],
	}))
	_assert(bool(snapshot.get("read_only", false)), "Door layout snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Door layout snapshot does not set gameplay truth")
	var entries: Array = Array(snapshot.get("entries", []))
	_assert(_entry_field_equals(entries, "door_closed", "door_visual_polish_style_id", "task_706_door_closed_blocker_v1"), "Closed door exports blocker polish style")
	_assert(_entry_field_equals(entries, "door_closed", "door_layout_tone", "blocked"), "Closed door exports blocked tone")
	_assert(_entry_field_contains(entries, "door_closed", "door_layout_readout", "CLOSED"), "Closed door exports readable readout")
	_assert(_entry_float(entries, "door_closed", "door_layout_visual_weight") >= 0.99, "Closed door exports strong visual weight")
	_assert(_entry_field_equals(entries, "door_operating", "door_visual_polish_style_id", "task_706_door_opening_motion_v1"), "Opening door exports motion polish style")
	_assert(_entry_field_equals(entries, "door_operating", "door_layout_tone", "action"), "Opening door exports action tone")
	_assert(_entry_field_contains(entries, "door_operating", "door_layout_readout", "OPENING"), "Opening door exports readable readout")
	_assert(_entry_field_equals(entries, "door_open", "door_visual_polish_style_id", "task_706_door_open_clearance_v1"), "Open door exports clearance polish style")
	_assert(_entry_field_equals(entries, "door_open", "door_layout_tone", "success"), "Open door exports success tone")
	_assert(_entry_field_contains(entries, "door_open", "door_layout_readout", "OPEN"), "Open door exports readable readout")
	_assert(not _entry_bool(entries, "door_open", "door_visual_sets_gameplay_truth"), "Door visual polish remains non-authoritative")


func _test_render_snapshot_exports_door_layout_polish() -> void:
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

	combat_driver.call("configure_scenario_runtime_gates_from_file", TEST_SCENARIO_PATH)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	var door_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, door_position)
	await _wait_frames(2)

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
	var open_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	var open_entries: Array = Array(open_snapshot.get("mission_interaction_object_reaction_entries", []))
	_assert(_entry_field_equals(open_entries, DOOR_INTERACTION_ID, "runtime_visual_state", "open"), "Render snapshot exports open door state")
	_assert(_entry_field_equals(open_entries, DOOR_INTERACTION_ID, "door_visual_polish_style_id", "task_706_door_open_clearance_v1"), "Render snapshot exports Door polish style")
	_assert(_entry_field_equals(open_entries, DOOR_INTERACTION_ID, "door_layout_tone", "success"), "Render snapshot exports Door layout tone")
	_assert(_entry_field_contains(open_entries, DOOR_INTERACTION_ID, "door_layout_readout", "path clear"), "Render snapshot exports Door readout")
	_assert(_entry_float(open_entries, DOOR_INTERACTION_ID, "door_layout_visual_weight") >= 0.69, "Render snapshot exports Door visual weight")
	_assert(not _entry_bool(open_entries, DOOR_INTERACTION_ID, "door_visual_sets_gameplay_truth"), "Render snapshot visual polish does not set gameplay truth")
	_assert(int(open_snapshot.get("mission_interaction_object_reaction_visual_count", 0)) >= 7, "Door visual proxy contains extra polish accents")

	_write_manifest({
		"schema": "sternenbuergerchen.mission_door_layout_visual_polish_manifest.v1",
		"task_id": "TASK_706",
		"door_interaction_id": DOOR_INTERACTION_ID,
		"runtime_visual_state": _entry_string(open_entries, DOOR_INTERACTION_ID, "runtime_visual_state"),
		"door_visual_polish_style_id": _entry_string(open_entries, DOOR_INTERACTION_ID, "door_visual_polish_style_id"),
		"door_layout_readout": _entry_string(open_entries, DOOR_INTERACTION_ID, "door_layout_readout"),
		"door_layout_tone": _entry_string(open_entries, DOOR_INTERACTION_ID, "door_layout_tone"),
		"door_layout_visual_weight": _entry_float(open_entries, DOOR_INTERACTION_ID, "door_layout_visual_weight"),
		"render_object_reaction_visual_count": int(open_snapshot.get("mission_interaction_object_reaction_visual_count", 0)),
		"ui_sets_gameplay_truth": false,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	})
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_706 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_706", "Manifest records TASK_706")
	_assert(String(parsed.get("door_layout_tone", "")) == "success", "Manifest records Door success tone")

	scene.queue_free()
	await _wait_frames(2)


func _visual_entry(interaction_id: String, status: String, progress: float) -> Dictionary:
	return {
		"interaction_id": interaction_id,
		"interaction_type": "door",
		"token": "DOOR",
		"status": status,
		"progress": progress,
		"world_position": Vector2(64.0, 64.0),
		"is_next": true,
	}


func _write_test_scenario() -> void:
	_ensure_output_dir()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_SCENARIO_PATH))
	var scenario: Dictionary = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	vertical_slice["interaction_points"] = [
		{
			"interaction_id": DOOR_INTERACTION_ID,
			"display_name": "Station Door Layout Polish Probe",
			"interaction_type": "door",
			"marker_id": "objective_point",
			"required_order": "breach",
			"duration_seconds": 2.0,
			"radius_world": 128.0,
			"step_id": "open_station_door",
			"gate_id": "open_station_door",
			"required_state": "door_open",
			"required_team": "team_alpha",
			"asset_hint": "station_set_door_single_closed"
		}
	]
	scenario["vertical_slice"] = vertical_slice
	var file := FileAccess.open(TEST_SCENARIO_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_706 temp scenario for writing")
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()


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


func _entry_field_equals(entries: Array, interaction_id: String, field: String, expected: String) -> bool:
	return _entry_string(entries, interaction_id, field) == expected


func _entry_field_contains(entries: Array, interaction_id: String, field: String, expected_fragment: String) -> bool:
	return _entry_string(entries, interaction_id, field).contains(expected_fragment)


func _entry_float(entries: Array, interaction_id: String, field: String) -> float:
	for variant in entries:
		if typeof(variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(variant)
		if String(entry.get("interaction_id", "")) == interaction_id:
			return float(entry.get(field, 0.0))
	return 0.0


func _entry_bool(entries: Array, interaction_id: String, field: String) -> bool:
	for variant in entries:
		if typeof(variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(variant)
		if String(entry.get("interaction_id", "")) == interaction_id:
			return bool(entry.get(field, false))
	return false


func _entry_string(entries: Array, interaction_id: String, field: String) -> String:
	for variant in entries:
		if typeof(variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(variant)
		if String(entry.get("interaction_id", "")) == interaction_id:
			return String(entry.get(field, ""))
	return ""


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(data: Dictionary) -> void:
	_ensure_output_dir()
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_706 manifest for writing")
		return
	file.store_string(JSON.stringify(data, "\t"))
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
