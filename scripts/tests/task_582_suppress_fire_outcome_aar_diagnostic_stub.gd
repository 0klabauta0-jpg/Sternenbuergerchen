extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const TACTICAL_COMMAND_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_582_suppress_fire_outcome_aar_diagnostic_stub.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const COMBAT_RESOLVER_PATH: String = "res://scripts/tactical/combat_fire_decision_resolver.gd"
const COMBAT_DRIVER_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TASK_570_TEST_PATH: String = "res://scripts/tests/task_570_hold_fire_discipline_mission_bridge.gd"
const TASK_580_TEST_PATH: String = "res://scripts/tests/task_580_suppress_fire_visual_tuning_findings.gd"

var _passed: int = 0
var _failed: int = 0


class FakeUnit:
	extends Node2D

	var unit_id: String = "alpha_sup"
	var team_id: String = "team_alpha"
	var fireteam_id: String = "blue"
	var active_weapon_id: String = "rifle"
	var _current_unit_command = null

	func get_unit_id() -> String:
		return unit_id

	func get_team_id() -> String:
		return team_id

	func get_fireteam_id() -> String:
		return fireteam_id

	func get_vital_state() -> String:
		return "fit"

	func get_active_weapon_id() -> String:
		return active_weapon_id

	func get_current_unit_command():
		return _current_unit_command

	func get_fire_status() -> String:
		if _current_unit_command != null and _current_unit_command.has_method("get"):
			return String(_current_unit_command.get("fire_status"))
		return "fire_at_will"

	func assign_unit_command(command) -> bool:
		_current_unit_command = command
		return true


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_582 Suppress Fire Outcome AAR Diagnostic Stub ===")
	_test_docs_and_wiring()
	_test_resolver_suppress_outcome_diagnostic()
	await _test_integrated_suppress_aar_diagnostic_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_582: FAILED")
		quit(1)
		return
	print("TASK_582: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var resolver_text: String = _read_text(COMBAT_RESOLVER_PATH)
	var driver_text: String = _read_text(COMBAT_DRIVER_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_582 task file exists")
	_assert(task_text.contains("Suppress Fire Outcome AAR Diagnostic Stub"), "TASK_582 task file names the task")
	_assert(status_text.contains("TASK_582 - Suppress Fire Outcome AAR Diagnostic Stub"), "Implementation status tracks TASK_582")
	_assert(roadmap_text.contains("TASK_582 - Suppress Fire Outcome AAR Diagnostic Stub (implementiert)"), "Roadmap marks TASK_582 implemented")
	_assert(roadmap_text.contains("TASK_583 - Suppress Fire AAR Report Panel Readability"), "Roadmap names TASK_583 follow-up")
	_assert(report_text.contains("TASK_582 - Suppress Fire Outcome AAR Diagnostic Stub"), "Review workbench tracks TASK_582")
	_assert(report_text.contains("TASK_583 - Suppress Fire AAR Report Panel Readability"), "Review workbench names TASK_583 follow-up")
	_assert(contract_text.contains("Suppress-Fire-Outcome-AAR-Diagnostic-Stub"), "Mission feedback contract documents TASK_582")
	_assert(resolver_text.contains("build_fire_rule_outcome_diagnostic"), "Combat resolver exposes fire-rule outcome diagnostic")
	_assert(driver_text.contains("get_suppress_fire_outcome_aar_diagnostic_snapshot"), "Combat driver exposes TASK_582 AAR diagnostic snapshot")
	_assert(controller_text.contains("get_suppress_fire_outcome_aar_diagnostic_snapshot"), "Mission controller exposes TASK_582 snapshot")
	_assert(FileAccess.file_exists(TASK_570_TEST_PATH), "TASK_570 fire-rule verifier remains available")
	_assert(FileAccess.file_exists(TASK_580_TEST_PATH), "TASK_580 visual tuning verifier remains available")


func _test_resolver_suppress_outcome_diagnostic() -> void:
	var unit := FakeUnit.new()
	root.add_child(unit)
	var command = UNIT_COMMAND_SCRIPT.new()
	command.command_type = UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION
	command.priority = 20
	command.unit_id = unit.unit_id
	command.team_id = unit.team_id
	command.target_position = Vector2.ZERO
	command.source_command_type = "defend"
	command.fire_rule = TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS
	command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
	unit.assign_unit_command(command)
	var diagnostic: Dictionary = Dictionary(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call(
		"build_fire_rule_outcome_diagnostic",
		unit,
		{"can_attack": true}
	))
	_assert(String(diagnostic.get("schema", "")) == "sternenbuergerchen.fire_rule_outcome.v1", "Resolver returns stable fire-rule outcome schema")
	_assert(bool(diagnostic.get("read_only", false)), "Resolver outcome diagnostic is read-only")
	_assert(not bool(diagnostic.get("ui_sets_gameplay_truth", true)), "Resolver outcome diagnostic does not set gameplay truth")
	_assert(String(diagnostic.get("fire_rule", "")) == TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS, "Resolver reports suppress fire-rule")
	_assert(String(diagnostic.get("outcome_label", "")) == "suppress_pressure_intent", "Resolver labels suppress as pressure intent")
	_assert(bool(diagnostic.get("suppress_intent_active", false)), "Resolver marks suppress intent active")
	_assert(bool(diagnostic.get("suppress_pressure_intent_visible", false)), "Resolver marks pressure intent visible")
	_assert(not bool(diagnostic.get("suppress_effect_applied", true)), "Resolver does not apply suppression effect")
	_assert(not bool(diagnostic.get("suppression_effect_payload_enqueued", true)), "Resolver does not enqueue suppression effect payload")
	_assert(not bool(diagnostic.get("ammo_consumed", true)), "Resolver does not consume ammo")
	_assert(not bool(diagnostic.get("suppress_damage_modifier_applied", true)), "Resolver does not modify damage")
	unit.queue_free()


func _test_integrated_suppress_aar_diagnostic_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var primary_view: Node = scene.get_node_or_null("Primary3DView")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and primary_view != null and combat_driver != null and simulation_root != null, "Mission fixture exposes TacticalController, Primary3DView, CombatLoopDriver and SimulationRoot")
	if controller == null or primary_view == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for SUP outcome")
	if friendly_units.size() < 3:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_fireteams_fire_rule", PackedStringArray(["blue"]), TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS)
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(8)

	var move_target := Vector2(544.0, 288.0)
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "Move order can be planned before SUP outcome")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)
	_assert(String(Dictionary(controller.call("get_suppress_fire_preview_readability_snapshot")).get("gate", "")) == "pass", "SUP preview gate is green before outcome smoke")
	_assign_suppress_fire_commands(controller, "blue", move_target)
	await _wait_frames(2)

	var contact_setup: Dictionary = _position_first_enemy_near_fireteam(controller, "blue")
	_assert(not contact_setup.is_empty(), "Enemy can be positioned for SUP outcome")
	_force_detection_complete(controller, combat_driver, "blue", contact_setup)
	_update_contact_tracking(combat_driver)
	_force_first_engagement_decision(controller, combat_driver, simulation_root, "blue", contact_setup)
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(8)

	var queue_count_before: int = _get_simulation_command_queue_count(simulation_root)
	var snapshot: Dictionary = Dictionary(controller.call("get_suppress_fire_outcome_aar_diagnostic_snapshot"))
	var queue_count_after: int = _get_simulation_command_queue_count(simulation_root)
	var second_snapshot: Dictionary = Dictionary(controller.call("get_suppress_fire_outcome_aar_diagnostic_snapshot"))
	var second_queue_count_after: int = _get_simulation_command_queue_count(simulation_root)
	var aar_diagnostic: Dictionary = Dictionary(snapshot.get("aar_diagnostic", {}))
	var last_outcome: Dictionary = Dictionary(snapshot.get("last_suppress_fire_outcome", {}))
	var count_by_fireteam: Dictionary = Dictionary(snapshot.get("suppress_fire_outcome_by_fireteam", {}))
	var intent_snapshot: Dictionary = Dictionary(snapshot.get("intent_snapshot", {}))
	var diagnostics: Dictionary = Dictionary(intent_snapshot.get("contact_decision_diagnostics", {}))
	_assert(queue_count_before == queue_count_after and queue_count_after == second_queue_count_after, "Reading SUP AAR snapshots does not enqueue commands")
	_assert(int(snapshot.get("suppress_fire_outcome_count", 0)) == int(second_snapshot.get("suppress_fire_outcome_count", -1)), "Reading SUP AAR snapshot does not increase outcome count")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_582 SUP AAR diagnostic gate passes")
	_assert(_check_passed(snapshot, "aar_diagnostic_available"), "SUP AAR diagnostic schema is available")
	_assert(_check_passed(snapshot, "suppress_outcome_counted"), "SUP fired outcome is counted")
	_assert(_check_passed(snapshot, "fireteam_bucket_visible"), "SUP fired outcome is grouped by fireteam")
	_assert(_check_passed(snapshot, "intent_outcome_still_green"), "TASK_581 intent/outcome snapshot remains green")
	_assert(_check_passed(snapshot, "no_suppression_effect_payload"), "No suppression effect payload is enqueued")
	_assert(_check_passed(snapshot, "no_ammo_consumption"), "No ammo consumption is reported")
	_assert(_check_passed(snapshot, "no_suppress_damage_modifier"), "No SUP damage modifier is reported")
	_assert(_check_passed(snapshot, "read_only"), "SUP AAR diagnostic snapshot remains read-only")
	_assert(String(aar_diagnostic.get("schema", "")) == "sternenbuergerchen.suppress_fire_outcome_aar_diagnostic.v1", "AAR diagnostic reports stable schema")
	_assert(int(aar_diagnostic.get("suppress_fire_outcome_count", 0)) >= 1, "AAR diagnostic count is at least one")
	_assert(int(count_by_fireteam.get("blue", 0)) >= 1, "AAR diagnostic includes blue fireteam bucket")
	_assert(String(last_outcome.get("outcome_label", "")).strip_edges() == "suppress_pressure_intent", "AAR diagnostic reports suppress pressure intent")
	_assert(String(last_outcome.get("status", "")).strip_edges() == "fired", "AAR diagnostic only counts fired outcomes")
	_assert(String(diagnostics.get("attacker_fire_rule", "")) == TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS, "Diagnostics report suppress as attacker fire-rule")
	_assert(not bool(last_outcome.get("suppression_effect_payload_enqueued", true)), "AAR diagnostic keeps suppression effect payload false")
	_assert(not bool(last_outcome.get("ammo_consumed", true)), "AAR diagnostic keeps ammo consumption false")
	_assert(not bool(last_outcome.get("suppress_damage_modifier_applied", true)), "AAR diagnostic keeps damage modifier false")

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


func _assign_suppress_fire_commands(controller: Node, fireteam_id: String, target_position: Vector2) -> void:
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var command = UNIT_COMMAND_SCRIPT.new()
		command.command_type = UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION
		command.priority = 30
		command.unit_id = _get_unit_id(unit)
		command.team_id = String(unit.call("get_team_id")) if unit.has_method("get_team_id") else "team_alpha"
		command.target_position = target_position
		command.source_command_type = "defend"
		command.fire_rule = TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS
		command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
		if unit.has_method("assign_unit_command"):
			unit.call("assign_unit_command", command)
		if unit.has_method("set_runtime_status"):
			unit.call(
				"set_runtime_status",
				"holding",
				"hold_position",
				30,
				"fire_at_will",
				"defend",
				1.0,
				0.0,
				0.0,
				1,
				target_position,
				"engage",
				"aimed",
				"task582_suppress_aar",
				1.0,
				75.0
			)


func _position_first_enemy_near_fireteam(controller: Node, fireteam_id: String) -> Dictionary:
	var friendly_units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false))
	if enemy_units.is_empty():
		enemy_units = Array(controller.call("_get_all_enemy_units", true))
	if friendly_units.is_empty() or enemy_units.is_empty():
		return {}
	var friendly := friendly_units[0] as Node2D
	var enemy := enemy_units[0] as Node2D
	if friendly == null or enemy == null:
		return {}
	enemy.global_position = friendly.global_position + Vector2(54.0, 0.0)
	if enemy is CanvasItem:
		(enemy as CanvasItem).visible = true
	return {
		"fireteam_id": fireteam_id,
		"friendly_unit_id": _get_unit_id(friendly),
		"enemy_unit_id": _get_unit_id(enemy),
		"friendly_position": friendly.global_position,
		"enemy_position": enemy.global_position,
	}


func _force_detection_complete(controller: Node, combat_driver: Node, fireteam_id: String, contact_setup: Dictionary) -> void:
	var enemy_id: String = String(contact_setup.get("enemy_unit_id", "")).strip_edges()
	var detection_progress: Dictionary = Dictionary(combat_driver.get("_detection_progress")).duplicate(true)
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node
		var friendly_id: String = _get_unit_id(unit)
		if friendly_id.is_empty() or enemy_id.is_empty():
			continue
		detection_progress["%s:%s" % [friendly_id, enemy_id]] = 0
		detection_progress["%s:%s" % [enemy_id, friendly_id]] = 0
	combat_driver.set("_detection_progress", detection_progress)


func _update_contact_tracking(combat_driver: Node) -> void:
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")
	if combat_driver.has_method("_advance_detection_timers"):
		combat_driver.call("_advance_detection_timers")
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")


func _force_first_engagement_decision(controller: Node, combat_driver: Node, simulation_root: Node, fireteam_id: String, contact_setup: Dictionary) -> void:
	_force_detection_complete(controller, combat_driver, fireteam_id, contact_setup)
	combat_driver.set("_current_tick", 120)
	combat_driver.set("_next_attack_tick", 0)
	if combat_driver.has_method("_try_enqueue_attacks"):
		combat_driver.call("_try_enqueue_attacks", simulation_root)


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


func _get_unit_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id")).strip_edges()
	return unit.name if unit != null else ""


func _get_simulation_command_queue_count(simulation_root: Node) -> int:
	if simulation_root == null:
		return 0
	var command_queue_variant: Variant = simulation_root.get("command_queue")
	if typeof(command_queue_variant) != TYPE_ARRAY:
		return 0
	return Array(command_queue_variant).size()


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _wait_frames(frame_count: int) -> void:
	for _i in range(frame_count):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _i in range(frame_count):
		await physics_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
