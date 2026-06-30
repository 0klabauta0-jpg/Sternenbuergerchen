extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_INTERACTION_OBJECT_REACTION_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_object_reaction.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_696_door_runtime_visual_animation_asset_swap.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SOURCE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TEST_SCENARIO_PATH: String = "res://tmp/task_696_door_runtime_visual_animation_asset_swap_scenario.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/door_runtime_visual_animation_asset_swap.json"
const DOOR_INTERACTION_ID: String = "station_door_visual_swap_probe"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_696 Door Runtime Visual Animation/Asset Swap ===")
	_test_docs()
	_test_reaction_contract_fields()
	await _test_render_snapshot_exports_door_visual_swap()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_696: FAILED")
		quit(1)
		return
	print("TASK_696: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_696 task file exists")
	_assert(task_text.contains("Door Runtime Visual Animation/Asset Swap"), "Task documents door visual animation asset swap")
	_assert(contract_text.contains("Door Runtime Visual Animation/Asset Swap"), "Interaction contract documents door visual animation asset swap")
	_assert(status_text.contains("TASK_696 - Door Runtime Visual Animation/Asset Swap"), "Implementation status tracks TASK_696")
	_assert(roadmap_text.contains("TASK_696 - Door Runtime Visual Animation/Asset Swap (implementiert)"), "Roadmap marks TASK_696 implemented")
	_assert(handbook_text.contains("TASK_696 - Door Runtime Visual Animation/Asset Swap"), "Current handbook references TASK_696")
	_assert(handbook_text.contains('data-export-key="mission_interaction_door_runtime_visual_animation_asset_swap.manifest_path"'), "Current handbook exports TASK_696 manifest path")


func _test_reaction_contract_fields() -> void:
	var snapshot: Dictionary = Dictionary(MISSION_INTERACTION_OBJECT_REACTION_SCRIPT.call("build_snapshot", {
		"schema": "test.visual_state",
		"entries": [
			_visual_entry("door_closed", "door", "usable", 0.0),
			_visual_entry("door_operating", "door", "in_progress", 0.5),
			_visual_entry("door_open", "door", "complete", 1.0),
		],
	}))
	_assert(bool(snapshot.get("read_only", false)), "Door visual snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Door visual snapshot does not set gameplay truth")
	var entries: Array = Array(snapshot.get("entries", []))
	_assert(_entry_field_equals(entries, "door_closed", "runtime_visual_state", "closed"), "Closed door stays closed")
	_assert(_entry_field_equals(entries, "door_closed", "door_asset_swap_state", "door_closed_asset"), "Closed door exports closed asset swap state")
	_assert(_entry_field_equals(entries, "door_closed", "door_animation_phase", "closed_idle"), "Closed door exports closed animation phase")
	_assert(absf(_entry_float(entries, "door_closed", "door_leaf_gap_fraction") - 0.0) < 0.001, "Closed door leaf gap is zero")
	_assert(_entry_field_equals(entries, "door_operating", "runtime_visual_state", "half"), "Operating door resolves half visual state")
	_assert(_entry_field_equals(entries, "door_operating", "door_asset_swap_state", "door_half_open_asset"), "Operating door exports half asset swap state")
	_assert(_entry_field_contains(entries, "door_operating", "door_animation_phase", "opening_"), "Operating door exports opening animation phase")
	_assert(_entry_float(entries, "door_operating", "door_leaf_gap_fraction") > 0.34, "Operating door leaf gap is visible")
	_assert(_entry_field_equals(entries, "door_open", "runtime_visual_state", "open"), "Open door resolves open state")
	_assert(_entry_field_equals(entries, "door_open", "door_asset_swap_state", "door_open_asset"), "Open door exports open asset swap state")
	_assert(_entry_field_equals(entries, "door_open", "door_animation_phase", "open"), "Open door exports open phase")
	_assert(_entry_bool(entries, "door_open", "door_threshold_visible"), "Open door threshold is visible")
	_assert(_entry_field_equals(entries, "door_open", "door_runtime_collision_source", "MissionInteractionDoorRuntimeCollisionLOS"), "Door visual names collision source")
	_assert(not _entry_bool(entries, "door_open", "door_visual_sets_gameplay_truth"), "Door visual does not claim gameplay truth")


func _test_render_snapshot_exports_door_visual_swap() -> void:
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
		"complete": false,
		"hold_seconds": 1.0,
		"duration_seconds": 2.0,
		"progress": 0.5,
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
	var half_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	var half_entries: Array = Array(half_snapshot.get("mission_interaction_object_reaction_entries", []))
	_assert(_entry_field_equals(half_entries, DOOR_INTERACTION_ID, "runtime_visual_state", "half"), "Render snapshot exports half door state")
	_assert(_entry_field_equals(half_entries, DOOR_INTERACTION_ID, "door_asset_swap_state", "door_half_open_asset"), "Render snapshot exports half asset swap")
	_assert(_entry_field_contains(half_entries, DOOR_INTERACTION_ID, "door_animation_phase", "opening_"), "Render snapshot exports opening phase")
	_assert(_entry_float(half_entries, DOOR_INTERACTION_ID, "door_leaf_gap_fraction") > 0.34, "Render snapshot exports visible leaf gap")
	_assert(not _entry_bool(half_entries, DOOR_INTERACTION_ID, "door_threshold_visible"), "Half door threshold is not open yet")

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
	var open_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	var open_entries: Array = Array(open_snapshot.get("mission_interaction_object_reaction_entries", []))
	_assert(_entry_field_equals(open_entries, DOOR_INTERACTION_ID, "runtime_visual_state", "open"), "Render snapshot exports open door state")
	_assert(_entry_field_equals(open_entries, DOOR_INTERACTION_ID, "visual_asset_type_id", "station_set_door_single"), "Render snapshot swaps to open door asset type")
	_assert(_entry_field_equals(open_entries, DOOR_INTERACTION_ID, "door_animation_phase", "open"), "Render snapshot exports open phase")
	_assert(_entry_bool(open_entries, DOOR_INTERACTION_ID, "door_threshold_visible"), "Open render snapshot exports threshold")
	_assert(not _entry_bool(open_entries, DOOR_INTERACTION_ID, "door_visual_sets_gameplay_truth"), "Render snapshot visual does not claim gameplay truth")

	_write_manifest({
		"schema": "sternenbuergerchen.door_runtime_visual_animation_asset_swap_manifest.v1",
		"task_id": "TASK_696",
		"door_interaction_id": DOOR_INTERACTION_ID,
		"half_runtime_visual_state": _entry_string(half_entries, DOOR_INTERACTION_ID, "runtime_visual_state"),
		"half_door_animation_phase": _entry_string(half_entries, DOOR_INTERACTION_ID, "door_animation_phase"),
		"open_runtime_visual_state": _entry_string(open_entries, DOOR_INTERACTION_ID, "runtime_visual_state"),
		"open_visual_asset_type_id": _entry_string(open_entries, DOOR_INTERACTION_ID, "visual_asset_type_id"),
		"open_door_threshold_visible": _entry_bool(open_entries, DOOR_INTERACTION_ID, "door_threshold_visible"),
		"render_object_reaction_visual_count": int(open_snapshot.get("mission_interaction_object_reaction_visual_count", 0)),
		"ui_sets_gameplay_truth": false,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	})
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_696 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_696", "Manifest records TASK_696")
	_assert(String(parsed.get("open_runtime_visual_state", "")) == "open", "Manifest records open door state")

	scene.queue_free()
	await _wait_frames(2)


func _visual_entry(interaction_id: String, interaction_type: String, status: String, progress: float) -> Dictionary:
	return {
		"interaction_id": interaction_id,
		"interaction_type": interaction_type,
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
			"display_name": "Station Door Visual Swap Probe",
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
		_assert(false, "Can open TASK_696 temp scenario for writing")
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()
	_assert(FileAccess.file_exists(TEST_SCENARIO_PATH), "TASK_696 temp scenario is written")


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


func _entry_string(entries: Array, interaction_id: String, field_name: String) -> String:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("interaction_id", "")).strip_edges() == interaction_id:
			return String(entry.get(field_name, "")).strip_edges()
	return ""


func _entry_float(entries: Array, interaction_id: String, field_name: String) -> float:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("interaction_id", "")).strip_edges() == interaction_id:
			return float(entry.get(field_name, 0.0))
	return 0.0


func _entry_bool(entries: Array, interaction_id: String, field_name: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("interaction_id", "")).strip_edges() == interaction_id:
			return bool(entry.get(field_name, false))
	return false


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_696 manifest for writing")
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
	for _index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
