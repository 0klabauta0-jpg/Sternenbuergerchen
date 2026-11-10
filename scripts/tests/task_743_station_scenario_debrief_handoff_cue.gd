extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_743_station_scenario_debrief_handoff_cue.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_scenario_debrief_handoff_cue.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_743 Station Scenario Debrief Handoff Cue ===")
	_test_docs_contract_and_report()
	await _test_station_scenario_debrief_handoff_cue()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_743: FAILED")
		quit(1)
		return
	print("TASK_743: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var feedback_source_text: String = _read_text("res://scripts/mission/diagnostics/mission_command_feedback_diagnostics.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_743 task file exists")
	_assert(task_text.contains("Station Scenario Debrief Handoff Cue"), "Task documents Station Scenario Debrief Handoff Cue")
	_assert(contract_text.contains("Station Scenario Debrief Handoff Cue"), "Interaction contract documents TASK_743")
	_assert(status_text.contains("TASK_743 - Station Scenario Debrief Handoff Cue"), "Implementation status tracks TASK_743")
	_assert(roadmap_text.contains("TASK_743 - Station Scenario Debrief Handoff Cue"), "Roadmap tracks TASK_743")
	_assert(report_text.contains("TASK_743 - Station Scenario Debrief Handoff Cue"), "Current handbook references TASK_743")
	_assert(report_text.contains("station_scenario_debrief_handoff_cue"), "Current handbook exports TASK_743 fields")
	_assert(controller_text.contains("get_station_scenario_debrief_handoff_cue_snapshot"), "Controller exposes TASK_743 snapshot")
	_assert(feedback_source_text.contains("station_scenario_debrief_handoff_line"), "Command feedback exports station handoff line")


func _test_station_scenario_debrief_handoff_cue() -> void:
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

	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures station scenario")
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	_assert(not fireteam_id.is_empty(), "Verifier selects a fireteam")
	_complete_station_route(combat_driver, fireteam_id)
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(4)

	var snapshot: Dictionary = Dictionary(controller.call("get_station_scenario_debrief_handoff_cue_snapshot")).duplicate(true)
	var handoff: Dictionary = Dictionary(snapshot.get("handoff", {}))
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var chain: PackedStringArray = PackedStringArray(Array(handoff.get("handoff_chain", [])))
	var handoff_line: String = String(handoff.get("handoff_line", ""))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_scenario_debrief_handoff_cue.v1", "TASK_743 snapshot schema is stable")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_743 final gate passes")
	_assert(bool(handoff.get("handoff_ready", false)), "Station handoff is ready after route completion")
	_assert(String(handoff.get("cue_line", "")) == "CUE DONE: Cargo weg | Debrief", "Station handoff keeps final Cargo/Debrief cue")
	_assert(handoff_line == "HANDOFF Debrief bereit | danach Homebase", "Station handoff line is compact and explicit")
	_assert(String(snapshot.get("mission_control_status_text", "")).contains(handoff_line), "Mission Control includes station handoff line")
	_assert(String(command_feedback.get("station_scenario_debrief_handoff_line", "")) == handoff_line, "Command feedback exports station handoff line")
	_assert(bool(command_feedback.get("station_scenario_debrief_handoff_ready", false)), "Command feedback exports station handoff ready flag")
	_assert(chain.has("station_route_complete") and chain.has("debrief_review") and chain.has("return_homebase"), "Handoff chain includes station route, Debrief and Homebase")
	_assert(String(handoff.get("display_route_line", "")).contains("AA > DOOR > COM > CARGO"), "Handoff keeps neutral station route visible")
	_assert(bool(handoff.get("handoff_line_within_limit", false)), "Handoff line stays compact")
	_assert(_snapshot_is_read_only(handoff), "Station handoff stays read-only")
	_assert(not bool(handoff.get("creates_navigation", true)), "Station handoff does not create navigation")
	_assert(not bool(handoff.get("creates_command", true)), "Station handoff does not create commands")
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_743 manifest is written")

	scene.queue_free()
	await _wait_frames(2)


func _complete_station_route(combat_driver: Node, fireteam_id: String) -> void:
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	combat_driver.call("update_mission_interaction_runtime_progress", _progress_payload("station_door", "operating", true, 2.0, fireteam_id, "open_station_door", "door_open", "door", "breach"))
	combat_driver.call("update_mission_interaction_runtime_progress", _progress_payload("station_computer", "operating", true, 18.0, fireteam_id, "occupy_station_computer", "computer_controlled", "computer", "take"))
	combat_driver.call("update_mission_interaction_runtime_progress", _progress_payload("cargo_landing_hold", "holding", true, 12.0, fireteam_id, "cargo_touchdown_extract", "cargo_departed", "hold_zone", "defend"))
	combat_driver.call("set_mission_cargo_touchdown_state", "departed")


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


func _write_manifest(snapshot: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var handoff: Dictionary = Dictionary(snapshot.get("handoff", {}))
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_743 manifest for writing")
		return
	file.store_string(JSON.stringify({
		"schema": "sternenbuergerchen.station_scenario_debrief_handoff_cue_manifest.v1",
		"task_id": "TASK_743",
		"snapshot_schema": String(snapshot.get("schema", "")),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"handoff_ready": bool(handoff.get("handoff_ready", false)),
		"handoff_line": String(handoff.get("handoff_line", "")),
		"cue_line": String(handoff.get("cue_line", "")),
		"route_line": String(handoff.get("route_line", "")),
		"display_route_line": String(handoff.get("display_route_line", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": String(snapshot.get("recommended_next_task", "")),
	}, "\t"))
	file.close()


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


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
