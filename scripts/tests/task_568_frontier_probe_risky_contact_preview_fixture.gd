extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_568_frontier_probe_risky_contact_preview_fixture.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TACTICAL_CLARITY_CONTRACT_PATH: String = "res://docs/dev/tactical_decision_clarity_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TASK_506_TEST_PATH: String = "res://scripts/tests/task_506_tactical_decision_clarity_contract.gd"
const TASK_567_TEST_PATH: String = "res://scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd"

var _passed: int = 0
var _failed: int = 0
var _contact_fixture_tick: int = 120


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_568 Frontier Probe Risky Contact Preview Fixture ===")
	_test_docs_and_wiring()
	await _test_risky_and_suicidal_contact_preview_states()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_568: FAILED")
		quit(1)
		return
	print("TASK_568: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var tactical_contract_text: String = _read_text(TACTICAL_CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_568 task file exists")
	_assert(task_text.contains("Frontier Probe Risky Contact Preview Fixture"), "TASK_568 task file names the task")
	_assert(status_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture"), "Implementation status tracks TASK_568")
	_assert(roadmap_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture (implementiert)"), "Roadmap marks TASK_568 implemented")
	_assert(roadmap_text.contains("TASK_569 - Frontier Probe Threat Preview Visual Review"), "Roadmap names TASK_569 follow-up")
	_assert(report_text.contains("TASK_568 - Frontier Probe Risky Contact Preview Fixture"), "Review workbench tracks TASK_568")
	_assert(report_text.contains("TASK_569 - Frontier Probe Threat Preview Visual Review"), "Review workbench names TASK_569 follow-up")
	_assert(contract_text.contains("Frontier-Probe-Risky-Contact-Preview-Fixture"), "Mission command feedback contract documents TASK_568")
	_assert(tactical_contract_text.contains("risky") and tactical_contract_text.contains("suicidal"), "Tactical clarity contract still names risky/suicidal states")
	_assert(controller_text.contains("get_frontier_probe_first_move_threat_preview_readability_snapshot"), "TacticalController keeps TASK_567 snapshot used by TASK_568")
	_assert(FileAccess.file_exists(TASK_506_TEST_PATH), "TASK_506 tactical clarity verifier remains available")
	_assert(FileAccess.file_exists(TASK_567_TEST_PATH), "TASK_567 first-move threat preview verifier remains available")


func _test_risky_and_suicidal_contact_preview_states() -> void:
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
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission fixture exposes Controller, CombatDriver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	var enemy_units: Array = _collect_team_units(scene, "team_bravo")
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for risky preview")
	_assert(enemy_units.size() >= 3, "Mission fixture exposes at least three Bravo enemies for suicidal preview")
	if friendly_units.size() < 3 or enemy_units.size() < 3:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	await _wait_frames(4)

	var anchor: Vector2 = (friendly_units[0] as Node2D).global_position
	var risky_target: Vector2 = anchor + Vector2(112.0, 0.0)
	_prepare_contact_fixture(controller, combat_driver, enemy_units, "blue", risky_target, 1)
	_assert(bool(controller.call("issue_right_click_command_for_test", risky_target, "move", false)), "Risky move can be planned before GO")
	_refresh_preview(controller)
	await _wait_frames(6)
	var risky_snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_first_move_threat_preview_readability_snapshot"))
	_assert(_preview_is_contact_risk(risky_snapshot, "risky", 1), "One known contact makes first move RISKY")
	_assert(String(risky_snapshot.get("selected_order_text", "")).contains("RISKY"), "HUD order text names RISKY")
	_assert(int(risky_snapshot.get("line_of_fire_entry_count", 0)) >= 1, "Risky preview exposes at least one line-of-fire entry")
	_assert(int(risky_snapshot.get("render_preview_threat_line_count", 0)) == int(risky_snapshot.get("line_of_fire_entry_count", 0)), "Risky render threat-line count mirrors preview entries")
	_assert(not bool(risky_snapshot.get("ui_sets_gameplay_truth", true)), "Risky snapshot remains read-only")

	var suicidal_target: Vector2 = anchor + Vector2(144.0, 64.0)
	_prepare_contact_fixture(controller, combat_driver, enemy_units, "blue", suicidal_target, 3)
	_assert(bool(controller.call("issue_right_click_command_for_test", suicidal_target, "move", false)), "Suicidal move can be planned before GO")
	_refresh_preview(controller)
	await _wait_frames(6)
	var suicidal_snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_first_move_threat_preview_readability_snapshot"))
	_assert(_preview_is_contact_risk(suicidal_snapshot, "suicidal", 3), "Three known contacts make first move SUICIDAL")
	_assert(String(suicidal_snapshot.get("selected_order_text", "")).contains("SUICIDAL"), "HUD order text names SUICIDAL")
	_assert(int(suicidal_snapshot.get("line_of_fire_entry_count", 0)) >= 3, "Suicidal preview exposes at least three line-of-fire entries")
	_assert(int(suicidal_snapshot.get("render_preview_threat_line_count", 0)) == int(suicidal_snapshot.get("line_of_fire_entry_count", 0)), "Suicidal render threat-line count mirrors preview entries")
	_assert(not bool(suicidal_snapshot.get("ui_sets_gameplay_truth", true)), "Suicidal snapshot remains read-only")
	_assert(int(suicidal_snapshot.get("enemy_exposure_count", 0)) > int(risky_snapshot.get("enemy_exposure_count", 0)), "Suicidal fixture increases exposure over risky fixture")

	scene.queue_free()
	await _wait_frames(2)


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", LARGE_MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _prepare_contact_fixture(controller: Node, combat_driver: Node, enemy_units: Array, fireteam_id: String, target_position: Vector2, exposed_enemy_count: int) -> void:
	_reset_contact_state(combat_driver)
	_move_enemies_away(enemy_units)
	var offsets: Array[Vector2] = [
		Vector2(128.0, 0.0),
		Vector2(0.0, 128.0),
		Vector2(-128.0, 0.0),
		Vector2(0.0, -128.0),
	]
	var max_count: int = mini(exposed_enemy_count, enemy_units.size())
	for index in range(max_count):
		var enemy := enemy_units[index] as Node2D
		if enemy == null:
			continue
		enemy.visible = true
		enemy.global_position = target_position + offsets[index % offsets.size()]
		enemy.set_meta("overwatch_ready", false)
	_seed_contact_tracker(combat_driver, enemy_units, fireteam_id, max_count)
	controller.call("refresh_contact_overlay")
	controller.call("refresh_fireteam_security_state")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")


func _reset_contact_state(combat_driver: Node) -> void:
	var tracker = combat_driver.get("_contact_tracker")
	if tracker != null and tracker.has_method("reset_all"):
		tracker.call("reset_all")
	combat_driver.set("_detection_progress", {})
	_contact_fixture_tick += 10
	combat_driver.set("_current_tick", _contact_fixture_tick)


func _seed_contact_tracker(combat_driver: Node, enemy_units: Array, fireteam_id: String, contact_count: int) -> void:
	var tracker = combat_driver.get("_contact_tracker")
	if tracker == null or not tracker.has_method("update"):
		return
	var observations: Array = []
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	for index in range(mini(contact_count, enemy_units.size())):
		var enemy := enemy_units[index] as Node2D
		if enemy == null or not enemy.has_method("get_unit_id"):
			continue
		observations.append({
			"fireteam_id": normalized_fireteam_id,
			"unit_id": String(enemy.call("get_unit_id")).strip_edges(),
			"team_id": String(enemy.call("get_team_id")) if enemy.has_method("get_team_id") else "team_bravo",
			"enemy_type": "rifleman",
			"position": enemy.global_position,
			"last_known_position": enemy.global_position,
			"detection_complete": true,
		})
	tracker.call("update", _contact_fixture_tick, observations, [normalized_fireteam_id], {normalized_fireteam_id: 1.0})
	_contact_fixture_tick += 1
	combat_driver.set("_current_tick", _contact_fixture_tick)
	tracker.call("update", _contact_fixture_tick, observations, [normalized_fireteam_id], {normalized_fireteam_id: 1.0})


func _refresh_preview(controller: Node) -> void:
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")


func _preview_is_contact_risk(snapshot: Dictionary, expected_risk: String, minimum_exposures: int) -> bool:
	if String(snapshot.get("gate", "")) != "pass":
		return false
	if String(snapshot.get("risk_state", "")).strip_edges().to_lower() != expected_risk:
		return false
	if int(snapshot.get("enemy_exposure_count", 0)) < minimum_exposures:
		return false
	if int(snapshot.get("line_of_fire_entry_count", 0)) < minimum_exposures:
		return false
	return true


func _assign_fireteam_ids(units: Array, fireteam_id: String) -> void:
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit != null and unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", fireteam_id)


func _mark_units_deployed(controller: Node, units: Array) -> void:
	var deployed_ids: Dictionary = {}
	var deployed_positions: Dictionary = {}
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		deployed_ids[unit_id] = true
		if unit is Node2D:
			deployed_positions[unit_id] = (unit as Node2D).global_position
	controller.set("_deployed_unit_ids", deployed_ids)
	controller.set("_deployed_unit_positions", deployed_positions)


func _move_enemies_away(enemy_units: Array) -> void:
	for index in range(enemy_units.size()):
		var enemy := enemy_units[index] as Node2D
		if enemy == null:
			continue
		enemy.visible = false
		enemy.global_position = Vector2(12000.0 + 80.0 * float(index), 12000.0)


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


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(frame_count):
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
