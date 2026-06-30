extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_INTERACTION_DOOR_MULTIPLAYER_AUTHORITY_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_door_multiplayer_authority.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_698_door_authority_ui_feedback.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SOURCE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TEST_SCENARIO_PATH: String = "res://tmp/task_698_door_authority_ui_feedback_scenario.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/door_authority_ui_feedback.json"
const DOOR_INTERACTION_ID: String = "station_door_authority_ui_probe"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_698 Door Authority UI Feedback ===")
	_test_docs()
	_test_readout_statuses()
	await _test_door_button_ui_feedback()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_698: FAILED")
		quit(1)
		return
	print("TASK_698: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_698 task file exists")
	_assert(task_text.contains("Door Authority UI Feedback"), "Task documents door authority UI feedback")
	_assert(contract_text.contains("Door Authority UI Feedback"), "Interaction contract documents door authority UI feedback")
	_assert(status_text.contains("TASK_698 - Door Authority UI Feedback"), "Implementation status tracks TASK_698")
	_assert(roadmap_text.contains("TASK_698 - Door Authority UI Feedback (implementiert)"), "Roadmap marks TASK_698 implemented")
	_assert(handbook_text.contains("TASK_698 - Door Authority UI Feedback"), "Current handbook references TASK_698")
	_assert(handbook_text.contains('data-export-key="mission_interaction_door_authority_ui_feedback.manifest_path"'), "Current handbook exports TASK_698 manifest path")


func _test_readout_statuses() -> void:
	var ready: Dictionary = _ui_feedback(_authority_snapshot({}), {"button_enabled": true, "has_usable_door": true, "display_token": "DOOR", "shortcut": "B"})
	_assert(String(ready.get("status", "")) == "ready", "Readout shows ready when door button is usable")
	_assert(String(ready.get("summary_line", "")).contains("bereit"), "Ready readout is readable")
	_assert(String(ready.get("tooltip_text", "")).contains("GO"), "Ready tooltip mentions GO requirement")
	_assert(bool(ready.get("read_only", false)), "Ready readout is read-only")
	_assert(not bool(ready.get("ui_sets_gameplay_truth", true)), "Ready readout does not set gameplay truth")

	var accepted: Dictionary = _ui_feedback(_authority_snapshot({"host_command_accepted": true}), {"button_enabled": true, "has_usable_door": true, "display_token": "DOOR", "shortcut": "B"})
	_assert(String(accepted.get("status", "")) == "accepted", "Readout shows accepted after host accept")
	_assert(String(accepted.get("summary_line", "")).contains("akzeptiert"), "Accepted readout is readable")

	var blocked: Dictionary = _ui_feedback(_authority_snapshot({"foreign_team_rejected": true, "foreign_team_reject_reason": "peer_team_mismatch"}), {"button_enabled": true, "has_usable_door": true, "display_token": "DOOR", "shortcut": "B"})
	_assert(String(blocked.get("status", "")) == "blocked", "Readout shows blocked for wrong-team reject")
	_assert(String(blocked.get("detail_line", "")).contains("peer_team_mismatch"), "Blocked readout names reject reason")

	var open: Dictionary = _ui_feedback(_authority_snapshot({"door_runtime_open_override": true}), {"button_enabled": true, "has_usable_door": true, "display_token": "DOOR", "shortcut": "B"})
	_assert(String(open.get("status", "")) == "open", "Readout shows open after runtime producer")
	_assert(String(open.get("detail_line", "")).contains("Walkability"), "Open readout names runtime producer effect")


func _test_door_button_ui_feedback() -> void:
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
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var door_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, door_position)
	controller.call("_update_ui")
	await _wait_frames(2)

	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var button_snapshot: Dictionary = Dictionary(Dictionary(command_feedback.get("command_buttons", {})).get("breach_door", {}))
	var ui_feedback: Dictionary = Dictionary(command_feedback.get("mission_interaction_door_authority_ui_feedback", {}))
	_assert(bool(button_snapshot.get("exists", false)), "Door breach button exists")
	_assert(not bool(button_snapshot.get("disabled", true)), "Door breach button is enabled near usable door")
	_assert(String(button_snapshot.get("tooltip_text", "")).contains("GO"), "Door breach tooltip explains GO requirement")
	_assert(String(button_snapshot.get("tooltip_text", "")).contains("SimulationRoot"), "Door breach tooltip names authority source")
	_assert(String(button_snapshot.get("door_authority_ui_status", "")) == "ready", "Door breach button records ready authority UI status")
	_assert(String(button_snapshot.get("door_authority_ui_summary_line", "")).contains("bereit"), "Door breach button exports readable authority line")
	_assert(bool(button_snapshot.get("door_authority_ui_read_only", false)), "Door breach button readout is read-only")
	_assert(String(ui_feedback.get("status", "")) == "ready", "Command feedback exports ready Door authority UI status")
	_assert(String(command_feedback.get("mission_interaction_door_authority_ui_line", "")).contains("bereit"), "Command feedback exports Door authority UI line")
	_assert(String(command_feedback.get("command_feedback_text", "")).contains("DOOR"), "Visible command feedback label contains Door authority line")

	_write_manifest({
		"schema": "sternenbuergerchen.door_authority_ui_feedback_manifest.v1",
		"task_id": "TASK_698",
		"door_interaction_id": DOOR_INTERACTION_ID,
		"button_enabled": not bool(button_snapshot.get("disabled", true)),
		"button_tooltip_mentions_go": String(button_snapshot.get("tooltip_text", "")).contains("GO"),
		"button_tooltip_mentions_authority": String(button_snapshot.get("tooltip_text", "")).contains("SimulationRoot"),
		"button_authority_ui_status": String(button_snapshot.get("door_authority_ui_status", "")),
		"command_feedback_line": String(command_feedback.get("mission_interaction_door_authority_ui_line", "")),
		"read_only": bool(ui_feedback.get("read_only", false)),
		"ui_sets_gameplay_truth": false,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	})
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_698 manifest is written")

	scene.queue_free()
	await _wait_frames(2)


func _authority_snapshot(overrides: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {
		"schema": "test.authority",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"hook_accepted": true,
		"requires_go": true,
		"gate": "review",
		"summary": "",
		"host_command_accepted": false,
		"foreign_team_rejected": false,
		"state_mutation_rejected": false,
		"door_runtime_open_override": false,
		"foreign_team_reject_reason": "",
		"state_mutation_reject_reason": "",
	}
	snapshot.merge(overrides, true)
	return snapshot


func _ui_feedback(authority_snapshot: Dictionary, button_context: Dictionary) -> Dictionary:
	return Dictionary(MISSION_INTERACTION_DOOR_MULTIPLAYER_AUTHORITY_SCRIPT.call("build_ui_feedback", authority_snapshot, button_context))


func _write_test_scenario() -> void:
	_ensure_output_dir()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_SCENARIO_PATH))
	var scenario: Dictionary = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	vertical_slice["interaction_points"] = [
		{
			"interaction_id": DOOR_INTERACTION_ID,
			"display_name": "Station Door Authority UI Probe",
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
		_assert(false, "Can open TASK_698 temp scenario for writing")
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()
	_assert(FileAccess.file_exists(TEST_SCENARIO_PATH), "TASK_698 temp scenario is written")


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


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_698 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


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
