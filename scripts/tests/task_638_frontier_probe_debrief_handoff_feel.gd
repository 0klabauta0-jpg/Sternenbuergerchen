extends SceneTree

const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_638_frontier_probe_debrief_handoff_feel.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_debrief_handoff_feel.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_638 Frontier Probe Debrief Handoff Feel ===")
	_test_docs_and_reports()
	await _test_debrief_handoff_feel_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_638: FAILED")
		quit(1)
		return
	print("TASK_638: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_638 task file exists")
	_assert(task_text.contains("Frontier Probe Debrief Handoff Feel"), "TASK_638 task names debrief handoff feel")
	_assert(status_text.contains("TASK_638 - Frontier Probe Debrief Handoff Feel"), "Implementation status tracks TASK_638")
	_assert(roadmap_text.contains("TASK_638 - Frontier Probe Debrief Handoff Feel (implementiert)"), "Roadmap marks TASK_638 implemented")
	_assert(contract_text.contains("Frontier-Probe-Debrief-Handoff-Feel"), "Mission feedback contract documents TASK_638")
	_assert(controller_text.contains("get_frontier_probe_debrief_handoff_feel_snapshot"), "Controller exposes TASK_638 snapshot")
	_assert(report_text.contains("TASK_638 Frontier Probe Debrief Handoff Feel"), "Rolling report tracks TASK_638")
	_assert(report_text.contains('latest_completed_task: "TASK_644 - Frontier Probe Homebase Real Window Review"'), "Rolling report advances latest completed beyond TASK_638")
	_assert(handbook_text.contains("TASK_638 - Frontier Probe Debrief Handoff Feel"), "Status handbook tracks TASK_638")
	_assert(handbook_text.contains('current_task: "TASK_644 - Frontier Probe Homebase Real Window Review"'), "Status handbook current task advances beyond TASK_638")
	for key in [
		"frontier_probe_debrief_handoff_feel.task_id",
		"frontier_probe_debrief_handoff_feel.manifest_path",
		"frontier_probe_debrief_handoff_feel.handoff_line",
		"frontier_probe_debrief_handoff_feel.handoff_ready",
		"frontier_probe_debrief_handoff_feel.handoff_chain",
		"frontier_probe_debrief_handoff_feel.mission_control_contains_handoff",
		"frontier_probe_debrief_handoff_feel.read_only",
		"frontier_probe_debrief_handoff_feel.recommended_next_task",
		"frontier_probe_debrief_handoff_feel.notes",
	]:
		_assert(report_text.contains(key), "Rolling report exports %s" % key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_debrief_handoff_feel"'), "Rolling report exports TASK_638 free note")
	_assert(handbook_text.contains('data-export-key="status.task_638_done"'), "Status handbook exports TASK_638 checkbox")


func _test_debrief_handoff_feel_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission scene exposes controller, combat driver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_prepare_frontier_probe_scene(scene, controller, combat_driver, simulation_root)
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	combat_driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	combat_driver.call("set_mission_scenario_runtime_step_state", "cargo_touchdown_extract", "cargo_departed")
	combat_driver.call("set_mission_cargo_touchdown_state", "departed")
	var snapshot: Dictionary = await _capture_handoff_snapshot(controller)
	var handoff: Dictionary = Dictionary(snapshot.get("handoff", {}))
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_debrief_handoff_feel.v1", "TASK_638 snapshot schema is stable")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_638 final gate passes")
	_assert(bool(handoff.get("handoff_ready", false)), "Frontier Probe handoff is ready after route completion")
	_assert(String(handoff.get("source_next_interaction_id", "")) == "open_debrief", "TASK_638 source points to TASK_637 open_debrief")
	_assert(String(handoff.get("handoff_line", "")) == "HANDOFF Debrief bereit | danach Homebase", "Handoff line is compact and explicit")
	_assert(String(snapshot.get("mission_control_status_text", "")).contains(String(handoff.get("handoff_line", ""))), "Mission Control includes HANDOFF line")
	_assert(String(command_feedback.get("frontier_probe_debrief_handoff_line", "")).contains("HANDOFF Debrief bereit"), "Command feedback exports HANDOFF line")
	_assert(_handoff_chain_complete(PackedStringArray(Array(handoff.get("handoff_chain", [])))), "Handoff chain includes mission, debrief and homebase")
	_assert(bool(handoff.get("handoff_line_within_limit", false)), "HANDOFF line stays compact")
	_assert(bool(snapshot.get("read_only", false)), "TASK_638 snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_638 snapshot does not set gameplay truth")
	_assert(not bool(handoff.get("creates_navigation", true)), "TASK_638 does not create navigation")
	_assert(not bool(handoff.get("creates_command", true)), "TASK_638 does not create commands")
	var manifest: Dictionary = _build_manifest(snapshot)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_638 manifest is written")
	_assert(String(manifest.get("handoff_chain", "")) == "mission_complete -> debrief_review -> return_homebase", "Manifest records full handoff chain")

	scene.queue_free()
	await _wait_frames(2)


func _capture_handoff_snapshot(controller: Node) -> Dictionary:
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(3)
	return Dictionary(controller.call("get_frontier_probe_debrief_handoff_feel_snapshot")).duplicate(true)


func _build_manifest(snapshot: Dictionary) -> Dictionary:
	var handoff: Dictionary = Dictionary(snapshot.get("handoff", {}))
	var chain: PackedStringArray = PackedStringArray(Array(handoff.get("handoff_chain", [])))
	return {
		"schema": "sternenbuergerchen.frontier_probe_debrief_handoff_feel_manifest.v1",
		"task_id": "TASK_638",
		"snapshot_schema": String(snapshot.get("schema", "")),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"handoff_ready": bool(handoff.get("handoff_ready", false)),
		"handoff_line": String(handoff.get("handoff_line", "")),
		"handoff_chain": " -> ".join(Array(chain)),
		"source_next_interaction_id": String(handoff.get("source_next_interaction_id", "")),
		"mission_control_contains_handoff": String(snapshot.get("mission_control_status_text", "")).contains(String(handoff.get("handoff_line", ""))),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"manual_review_required": true,
		"manual_review_done": false,
		"recommended_next_task": "TASK_639 - Frontier Probe Meta Debrief Route Smoke",
	}


func _prepare_frontier_probe_scene(scene: Node, controller: Node, combat_driver: Node, simulation_root: Node) -> void:
	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assign_fireteam_ids(friendly_units.slice(0, mini(2, friendly_units.size())), "blue")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var objective_status = simulation_root.call("get_objective_status") if simulation_root.has_method("get_objective_status") else null
	if objective_status != null:
		objective_status.owning_team_id = "team_alpha"
		objective_status.capturing_team_id = "team_alpha"
		objective_status.capture_progress = 1.0
		controller.call("select_tile_from_world_position_for_test", objective_status.position)
	if scene.has_node("MissionSetup"):
		var setup: Node = scene.get_node("MissionSetup")
		setup.set("map_file_path", LARGE_MAP_PATH)
		setup.set("scenario_file_path", SCENARIO_PATH)
		if setup.has_method("apply_runtime_selection_contract"):
			setup.call("apply_runtime_selection_contract")
	controller.call("set_planning_state", {"scenario_file_path": SCENARIO_PATH, "map_file_path": LARGE_MAP_PATH})
	controller.set("enemy_movement_enabled", false)
	combat_driver.set("enemy_movement_enabled", false)
	combat_driver.set("auto_enemy_fire_enabled", false)
	combat_driver.set("auto_friendly_fire_enabled", false)
	combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	combat_driver.call("set_mission_cargo_touchdown_state", "blocked")
	controller.call("_update_ui")


func _collect_team_units(root_node: Node, team_id: String) -> Array:
	var result: Array = []
	for node in _collect_nodes(root_node):
		if node is TestUnit and String(node.team_id) == team_id:
			result.append(node)
	return result


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _assign_fireteam_ids(units: Array, fireteam_id: String) -> void:
	for unit_variant in units:
		var unit: TestUnit = unit_variant
		unit.fireteam_id = fireteam_id


func _handoff_chain_complete(chain: PackedStringArray) -> bool:
	return chain.has("mission_complete") and chain.has("debrief_review") and chain.has("return_homebase")


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_638 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame
