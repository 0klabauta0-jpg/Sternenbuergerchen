extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_549_combat_hud_f6_visual_audit.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_548_TEST_PATH: String = "res://scripts/tests/task_548_combat_hud_visual_detail_tooltip_pass.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_549 Combat HUD F6 Visual Audit ===")
	_test_docs_and_wiring()
	await _test_combat_hud_f6_visual_audit()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_549: FAILED")
		quit(1)
		return
	print("TASK_549: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_549 task file exists")
	_assert(_read_text(TASK_PATH).contains("Combat HUD F6 Visual Audit"), "TASK_549 task file names the task")
	_assert(_read_text(STATUS_PATH).contains("TASK_549 - Combat HUD F6 Visual Audit"), "Implementation status tracks TASK_549")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_549 - Combat HUD F6 Visual Audit (implementiert)"), "Roadmap marks TASK_549 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_549 - Combat HUD F6 Visual Audit"), "Review workbench tracks TASK_549")
	_assert(_read_text(CONTRACT_PATH).contains("get_combat_hud_f6_visual_audit_snapshot"), "Mission feedback contract documents TASK_549 snapshot")
	_assert(_read_text(CONTROLLER_PATH).contains("get_combat_hud_f6_visual_audit_snapshot"), "TacticalController exposes combat HUD F6 visual audit snapshot")
	_assert(FileAccess.file_exists(TASK_548_TEST_PATH), "TASK_548 tooltip smoke remains available")


func _test_combat_hud_f6_visual_audit() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission scene exposes TacticalController, CombatLoopDriver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 4, "Mission scene exposes at least four friendly units for visual audit")
	if friendly_units.size() < 4:
		scene.queue_free()
		await _wait_frames(2)
		return

	_assign_fireteam_ids(friendly_units.slice(0, 2), "blue")
	_assign_fireteam_ids(friendly_units.slice(2, 4), "gold")
	var blue_unit_ids: Array = _collect_unit_ids(friendly_units.slice(0, 2))
	var gold_unit_ids: Array = _collect_unit_ids(friendly_units.slice(2, 4))
	_apply_two_dropship_planning_state(controller, blue_unit_ids, gold_unit_ids)
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(6)

	var contact_setup: Dictionary = _position_first_enemy_near_fireteam(controller, "blue")
	_assert(not contact_setup.is_empty(), "Visual audit smoke can position an enemy near BLUE")
	if contact_setup.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	_prepare_fireteam_for_first_engagement(controller, "blue", Vector2(contact_setup.get("enemy_position", Vector2.ZERO)))
	_update_contact_tracking(combat_driver)
	_force_first_engagement_decision(controller, combat_driver, simulation_root, "blue", contact_setup)
	controller.call("refresh_contact_overlay")
	controller.call("refresh_fireteam_security_state")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(8)
	controller.call("_update_ui")

	var audit: Dictionary = Dictionary(controller.call("get_combat_hud_f6_visual_audit_snapshot"))
	_assert(not bool(audit.get("ui_sets_gameplay_truth", true)), "Combat HUD F6 audit is read-only")
	_assert(String(audit.get("audit_id", "")) == "combat_hud_f6_visual_audit_v1", "Combat HUD F6 audit uses stable audit id")
	_assert(String(audit.get("automated_visual_gate", "")) == "pass", "Combat HUD F6 automated visual gate passes")
	_assert(int(audit.get("failed_count", -1)) == 0, "Combat HUD F6 audit has no critical failures")
	_assert(bool(audit.get("manual_screenshot_required", false)), "Combat HUD F6 audit still marks manual screenshot as required")
	_assert(not bool(audit.get("manual_screenshot_done", true)), "Combat HUD F6 audit does not pretend a manual screenshot happened")
	_assert(_check_passed(audit, "task_548_tooltip_gate_passes"), "TASK_548 tooltip gate remains green")
	_assert(_check_passed(audit, "hud_controls_present"), "HUD panels and labels exist")
	_assert(_check_passed(audit, "labels_visible_and_hoverable"), "Combat HUD labels are visible and hoverable")
	_assert(_check_passed(audit, "labels_inside_panels"), "Combat HUD labels stay inside their panels")
	_assert(_check_passed(audit, "panels_inside_fullhd_bounds"), "Combat HUD panels stay inside FullHD bounds")
	_assert(_check_passed(audit, "selected_and_mission_panels_do_not_overlap"), "Selected Fireteam and Mission Control panels do not overlap")
	_assert(_check_passed(audit, "tooltip_payload_matches_both_labels"), "Both labels expose the same tooltip payload")
	_assert(_check_passed(audit, "tooltip_lines_short_and_scannable"), "Tooltip lines stay short and scannable")
	_assert(_check_passed(audit, "tooltip_preview_fits_fullhd"), "Estimated tooltip preview fits FullHD")
	_assert(int(audit.get("tooltip_line_count", 0)) <= 4, "Tooltip line count stays compact")
	_assert(int(audit.get("max_tooltip_line_length", 999)) <= 112, "Tooltip line length stays under budget")
	_assert(not String(audit.get("compact_line", "")).strip_edges().is_empty(), "Audit preserves compact combat line")

	scene.queue_free()
	await _wait_frames(2)


func _apply_two_dropship_planning_state(controller: Node, blue_unit_ids: Array, gold_unit_ids: Array) -> void:
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_source"] = "homebase_direct"
	planning_state["mission_drop_craft_id"] = "dropship_alpha"
	planning_state["mission_drop_state"] = "waiting"
	planning_state["drop_ship_staged"] = true
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(384.0, 224.0)
	planning_state["deployed_unit_ids"] = blue_unit_ids + gold_unit_ids
	planning_state["deployed_unit_positions"] = {}
	planning_state["mission_drop_cards"] = [
		_build_waiting_mission_card("dropship_alpha", "Dropship Alpha", blue_unit_ids, "blue", "NW", Vector2(384.0, 224.0)),
		_build_waiting_mission_card("dropship_beta", "Dropship Beta", gold_unit_ids, "gold", "SE", Vector2(672.0, 352.0)),
	]
	controller.call("set_planning_state", planning_state)


func _build_waiting_mission_card(craft_id: String, display_name: String, unit_ids: Array, fireteam_id: String, approach_angle: String, lz_position: Vector2) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"state": "waiting",
		"progress": 100.0,
		"embarked_unit_ids": unit_ids.duplicate(),
		"boarded_fireteam_ids": [fireteam_id],
		"queued_fireteam_ids": [fireteam_id],
		"passenger_count": unit_ids.size(),
		"has_lz_position": true,
		"lz_position": lz_position,
		"approach_angle": approach_angle,
		"drop_ship_staged": true,
		"payload_source": "homebase_direct",
	}


func _assign_fireteam_ids(units: Array, fireteam_id: String) -> void:
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit != null and unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", fireteam_id)


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
	enemy.global_position = friendly.global_position + Vector2(58.0, 0.0)
	if enemy is CanvasItem:
		(enemy as CanvasItem).visible = true
	return {
		"fireteam_id": fireteam_id,
		"friendly_unit_id": _get_unit_id(friendly),
		"enemy_unit_id": _get_unit_id(enemy),
		"friendly_position": friendly.global_position,
		"enemy_position": enemy.global_position,
	}


func _prepare_fireteam_for_first_engagement(controller: Node, fireteam_id: String, enemy_position: Vector2) -> void:
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null:
			continue
		if unit.has_method("set"):
			unit.set("skill_accuracy", 1.0)
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
				enemy_position,
				"engage",
				"aimed",
				"task549_combat_hud_visual_audit",
				1.0,
				75.0
			)


func _force_first_engagement_decision(controller: Node, combat_driver: Node, simulation_root: Node, fireteam_id: String, contact_setup: Dictionary) -> void:
	var enemy_id: String = String(contact_setup.get("enemy_unit_id", "")).strip_edges()
	var detection_progress: Dictionary = Dictionary(combat_driver.get("_detection_progress")).duplicate(true)
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null:
			continue
		var friendly_id: String = _get_unit_id(unit)
		if friendly_id.is_empty() or enemy_id.is_empty():
			continue
		detection_progress["%s:%s" % [friendly_id, enemy_id]] = 0
		detection_progress["%s:%s" % [enemy_id, friendly_id]] = 0
	combat_driver.set("_detection_progress", detection_progress)
	combat_driver.set("_current_tick", 120)
	combat_driver.call("align_to_common_decision_step_for_test")
	if combat_driver.has_method("_try_enqueue_attacks"):
		combat_driver.call("_try_enqueue_attacks", simulation_root)


func _update_contact_tracking(combat_driver: Node) -> void:
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")
	if combat_driver.has_method("_advance_detection_timers"):
		combat_driver.call("_advance_detection_timers")
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")


func _collect_team_units(root_node: Node, team_id: String) -> Array:
	var result: Array = []
	for node in _collect_nodes(root_node):
		if not node.has_method("get_team_id") or not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() == team_id:
			result.append(node)
	return result


func _collect_unit_ids(units: Array) -> Array:
	var result: Array = []
	for unit_variant in units:
		var unit := unit_variant as Node
		var unit_id: String = _get_unit_id(unit)
		if not unit_id.is_empty():
			result.append(unit_id)
	return result


func _get_unit_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id")).strip_edges()
	return unit.name if unit != null else ""


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


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
