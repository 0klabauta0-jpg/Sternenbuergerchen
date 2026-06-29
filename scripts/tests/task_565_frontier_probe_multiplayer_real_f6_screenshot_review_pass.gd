extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TASK_562_TEST_PATH: String = "res://scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd"
const FIRETEAM_SELECTED_CARDS_ROW_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_565 Frontier Probe Multiplayer Real F6 Screenshot Review Pass ===")
	_test_docs_and_wiring()
	await _test_selected_fireteam_status_matches_visible_cards()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_565: FAILED")
		quit(1)
		return
	print("TASK_565: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_565 task file exists")
	_assert(task_text.contains("Frontier Probe Multiplayer Real F6 Screenshot Review Pass"), "TASK_565 task file names the task")
	_assert(status_text.contains("TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass"), "Implementation status tracks TASK_565")
	_assert(roadmap_text.contains("TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass (implementiert)"), "Roadmap marks TASK_565 implemented")
	_assert(roadmap_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass"), "Roadmap names TASK_566 follow-up")
	_assert(contract_text.contains("Frontier-Probe-Multiplayer-Real-F6-Screenshot-Review"), "Mission feedback contract documents TASK_565")
	_assert(report_text.contains("TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass"), "Review workbench tracks TASK_565")
	_assert(report_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass"), "Review workbench names TASK_566 follow-up")
	_assert(controller_text.contains("_filter_ground_fireteam_card_units(_get_fireteam_units(selected_cards_fireteam_id"), "Controller status uses the same fireteam-unit fallback as visible cards")
	_assert(FileAccess.file_exists(TASK_562_TEST_PATH), "TASK_562 real viewport capture remains available")


func _test_selected_fireteam_status_matches_visible_cards() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	if simulation_root != null and simulation_root.has_method("set_peer_team_assignments"):
		simulation_root.call("set_peer_team_assignments", {
			1: "team_alpha",
			2: "team_bravo",
		})
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission scene exposes Controller, CombatDriver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 2, "Mission scene exposes Alpha units for real F6 review")
	if friendly_units.size() < 2:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)

	var objective_status = simulation_root.call("get_objective_status") if simulation_root.has_method("get_objective_status") else null
	_assert(objective_status != null, "SimulationRoot exposes ObjectiveStatus")
	if objective_status == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	objective_status.owning_team_id = "team_alpha"
	objective_status.capturing_team_id = "team_alpha"
	objective_status.capture_progress = 1.0

	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures frontier probe scenario gates")
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	combat_driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	combat_driver.call("set_mission_cargo_touchdown_state", "departed")
	controller.call("select_tile_from_world_position_for_test", objective_status.position)
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(12)
	controller.call("_update_ui")
	await _wait_frames(4)

	var command_snapshot: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var selected_label_text: String = String(command_snapshot.get("selected_fireteam_status_label_text", "")).strip_edges()
	var selected_computed_text: String = String(command_snapshot.get("selected_status_text", "")).strip_edges()
	var selected_status_text: String = selected_label_text if not selected_label_text.is_empty() else selected_computed_text
	var cards_row := scene.get_node_or_null(FIRETEAM_SELECTED_CARDS_ROW_PATH) as HBoxContainer
	var visible_card_count: int = _count_visible_member_cards(cards_row)
	_assert(visible_card_count >= 2, "Selected Fireteam panel shows visible member cards")
	_assert(not selected_status_text.contains("keine Einheiten aktiv"), "Selected Fireteam status does not contradict visible cards")
	_assert(selected_status_text.contains("Karten") or selected_status_text.contains("Mitglied"), "Selected Fireteam status reports cards or members")
	_assert(selected_status_text.contains("Lead"), "Selected Fireteam status reports lead/drop context")

	scene.queue_free()
	await _wait_frames(2)


func _count_visible_member_cards(cards_row: HBoxContainer) -> int:
	if cards_row == null:
		return 0
	var count: int = 0
	for child in cards_row.get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		var source_context: String = ""
		if control.has_method("get_source_context"):
			source_context = String(control.call("get_source_context")).strip_edges()
		else:
			source_context = String(control.get_meta("source_context", "")).strip_edges()
		if source_context == "mission_selected_fireteam_member":
			count += 1
	return count


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", LARGE_MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", true)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _assign_fireteam_ids(units: Array, fireteam_id: String) -> void:
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit != null and unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", fireteam_id)


func _collect_team_units(root_node: Node, team_id: String) -> Array:
	var result: Array = []
	for node in _collect_nodes(root_node):
		if not node.has_method("get_team_id") or not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() == team_id:
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


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
