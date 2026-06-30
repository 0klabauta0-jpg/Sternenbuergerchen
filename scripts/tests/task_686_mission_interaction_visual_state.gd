extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_686_mission_interaction_visual_state.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/mission_interaction_visual_state.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_686 Mission Interaction Visual State ===")
	_test_docs()
	await _test_visual_state_sequence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_686: FAILED")
		quit(1)
		return
	print("TASK_686: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_686 task file exists")
	_assert(task_text.contains("Mission Interaction Visual State"), "Task documents visual state")
	_assert(contract_text.contains("Visual State Snapshot"), "Interaction contract documents visual state")
	_assert(contract_text.contains("get_mission_interaction_visual_state_snapshot"), "Interaction contract names visual state snapshot")
	_assert(status_text.contains("TASK_686 - Mission Interaction Visual State"), "Implementation status tracks TASK_686")
	_assert(roadmap_text.contains("TASK_686 - Mission Interaction Visual State (implementiert)"), "Roadmap marks TASK_686 implemented")
	_assert(handbook_text.contains("TASK_686 - Mission Interaction Visual State"), "Current handbook references TASK_686")
	_assert(handbook_text.contains('data-export-key="mission_interaction_visual_state.snapshot"'), "Current handbook exports TASK_686 status")


func _test_visual_state_sequence() -> void:
	_ensure_output_dir()
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var mission_setup: Node = scene.get_node_or_null("MissionSetup")
	_assert(controller != null and combat_driver != null and mission_setup != null, "Mission scene exposes controller, combat driver and setup")
	if controller == null or combat_driver == null or mission_setup == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	_assert(not fireteam_id.is_empty(), "Verifier selects a fireteam")

	var aa_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "factory_danger_zone", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, aa_position)
	await _wait_frames(2)
	var aa_visual: Dictionary = Dictionary(controller.call("get_mission_interaction_visual_state_snapshot"))
	_assert(_snapshot_is_read_only(aa_visual), "Visual state snapshot is read-only")
	_assert(String(aa_visual.get("schema", "")) == "sternenbuergerchen.mission_interaction_visual_state.v1", "Visual state schema is stable")
	_assert(int(aa_visual.get("visual_state_count", 0)) >= 3, "Visual state exposes AA, COM and CARGO entries")
	_assert(_entries_contain_label(Array(aa_visual.get("entries", [])), "aa_shutdown_zone", "NEXT AA"), "Start state labels NEXT AA")

	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	var station_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, station_position)
	combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": "station_computer",
		"state": "operating",
		"complete": false,
		"progress": 0.5,
		"hold_seconds": 9.0,
		"duration_seconds": 18.0,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": "occupy_station_computer",
		"required_state": "computer_controlled",
		"interaction_type": "computer",
		"command_type": "take",
	})
	await _wait_frames(2)
	var computer_visual: Dictionary = Dictionary(controller.call("get_mission_interaction_visual_state_snapshot"))
	_assert(_entries_contain_label(Array(computer_visual.get("entries", [])), "station_computer", "NEXT COM"), "Computer state labels NEXT COM")
	_assert(_entries_contain_label(Array(computer_visual.get("entries", [])), "station_computer", "9/18s"), "Computer state labels in-progress hold time")
	_assert(String(computer_visual.get("summary", "")).contains("COM"), "Visual summary points at computer")

	controller.call("_sync_primary_3d_mission_status_visuals")
	await _wait_frames(2)
	var primary_view: Node = controller.call("_get_primary_3d_view")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Primary 3D view exposes render snapshot")
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	_assert(int(render_snapshot.get("mission_interaction_visual_state_count", 0)) >= 3, "3D render snapshot counts interaction visual states")
	_assert(String(render_snapshot.get("mission_interaction_visual_state_style_id", "")) == "task_686_mission_interaction_visual_state", "3D render snapshot exposes visual style id")
	_assert(_entries_contain_label(Array(render_snapshot.get("mission_interaction_visual_state_entries", [])), "station_computer", "NEXT COM"), "3D render snapshot includes NEXT COM label")

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
	var cargo_visual: Dictionary = Dictionary(controller.call("get_mission_interaction_visual_state_snapshot"))
	_assert(_entries_contain_label(Array(cargo_visual.get("entries", [])), "station_computer", "COM OK"), "Computer complete labels COM OK")
	_assert(_entries_contain_label(Array(cargo_visual.get("entries", [])), "cargo_landing_hold", "NEXT CARGO"), "Cargo state labels NEXT CARGO after computer")
	_assert(int(Dictionary(controller.call("get_command_feedback_snapshot")).get("mission_interaction_visual_state_count", 0)) >= 3, "Command feedback exports visual state count")

	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.mission_interaction_visual_state_manifest.v1",
		"task_id": "TASK_686",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"aa_summary": String(aa_visual.get("summary", "")),
		"computer_summary": String(computer_visual.get("summary", "")),
		"cargo_summary": String(cargo_visual.get("summary", "")),
		"render_visual_state_count": int(render_snapshot.get("mission_interaction_visual_state_count", 0)),
		"render_style_id": String(render_snapshot.get("mission_interaction_visual_state_style_id", "")),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	}
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Visual state manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_686", "Manifest records TASK_686")
	_assert(int(parsed.get("render_visual_state_count", 0)) >= 3, "Manifest records render visual state count")

	scene.queue_free()
	await _wait_frames(2)


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _entries_contain_label(entries: Array, interaction_id: String, expected: String) -> bool:
	var normalized_interaction_id: String = interaction_id.strip_edges()
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("interaction_id", "")).strip_edges() != normalized_interaction_id:
			continue
		var haystack: String = "%s\n%s" % [String(entry.get("short_label", "")), String(entry.get("label", ""))]
		if haystack.contains(expected):
			return true
	return false


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
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


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
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
