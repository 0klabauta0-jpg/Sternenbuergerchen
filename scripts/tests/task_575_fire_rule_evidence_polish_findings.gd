extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TACTICAL_COMMAND_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_575_fire_rule_evidence_polish_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TASK_572_TEST_PATH: String = "res://scripts/tests/task_572_fire_rule_f6_readability_smoke.gd"
const TASK_574_TEST_PATH: String = "res://scripts/tests/task_574_fire_rule_real_f6_screenshot_review_pass.gd"

const ACTIVE_STYLE_ID: String = "fire_rule_active_affordance_v1"
const INACTIVE_STYLE_ID: String = "fire_rule_inactive_affordance_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_575 Fire Rule Evidence Polish Findings ===")
	_test_docs_and_wiring()
	await _test_active_fire_rule_affordance_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_575: FAILED")
		quit(1)
		return
	print("TASK_575: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var task_574_text: String = _read_text(TASK_574_TEST_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_575 task file exists")
	_assert(task_text.contains("Fire Rule Evidence Polish Findings"), "TASK_575 task file names the task")
	_assert(status_text.contains("TASK_575 - Fire Rule Evidence Polish Findings"), "Implementation status tracks TASK_575")
	_assert(roadmap_text.contains("TASK_575 - Fire Rule Evidence Polish Findings (implementiert)"), "Roadmap marks TASK_575 implemented")
	_assert(roadmap_text.contains("TASK_576 - Suppress Fire Preview Readability Spike"), "Roadmap names TASK_576 follow-up")
	_assert(report_text.contains("TASK_575 - Fire Rule Evidence Polish Findings"), "Review workbench tracks TASK_575")
	_assert(report_text.contains("TASK_576 - Suppress Fire Preview Readability Spike"), "Review workbench names TASK_576 next task")
	_assert(contract_text.contains("Fire-Rule-Evidence-Polish-Findings"), "Mission feedback contract documents TASK_575")
	_assert(controller_text.contains(ACTIVE_STYLE_ID), "Mission controller exposes active Fire-Rule affordance style")
	_assert(controller_text.contains("active_rule_affordance_stronger"), "Mission controller exposes active affordance readability check")
	_assert(task_574_text.contains("active_rule_affordance_stronger"), "TASK_574 manifest carries active affordance evidence")
	_assert(FileAccess.file_exists(TASK_572_TEST_PATH), "TASK_572 F6 readability smoke remains available")


func _test_active_fire_rule_affordance_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 2, "Mission scene exposes Alpha units for Fire-Rule polish")
	if friendly_units.size() < 2:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 4), "blue")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_fireteams_fire_rule", PackedStringArray(["blue"]), TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD)
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)
	controller.call("_update_ui")
	await _wait_frames(4)

	var controls_snapshot: Dictionary = Dictionary(controller.call("get_fire_rule_controls_readability_snapshot"))
	var f6_snapshot: Dictionary = Dictionary(controller.call("get_fire_rule_f6_readability_snapshot"))
	_assert(String(f6_snapshot.get("gate", "")) == "pass", "Fire-Rule F6 gate remains green after polish")
	_assert(_check_passed(f6_snapshot, "active_rule_affordance_stronger"), "Active Fire-Rule affordance check passes")
	_assert(String(f6_snapshot.get("active_affordance_style_id", "")) == ACTIVE_STYLE_ID, "F6 snapshot exposes active affordance style ID")
	_assert(int(f6_snapshot.get("active_button_affordance_count", 0)) == 1, "Exactly one active Fire-Rule affordance is visible")
	_assert(float(f6_snapshot.get("active_button_visual_weight", 0.0)) >= 2.0, "Active Fire-Rule visual weight is stronger than inactive")
	_assert(not bool(f6_snapshot.get("ui_sets_gameplay_truth", true)), "F6 polish snapshot remains read-only")

	var buttons: Dictionary = Dictionary(controls_snapshot.get("buttons", {}))
	var hold_button: Dictionary = Dictionary(buttons.get(TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD, {}))
	_assert(bool(hold_button.get("active", false)), "Hold Fire button remains the active ROE")
	_assert(bool(hold_button.get("fire_rule_affordance_active", false)), "Hold Fire carries active affordance")
	_assert(String(hold_button.get("fire_rule_affordance_style_id", "")) == ACTIVE_STYLE_ID, "Hold Fire uses active affordance style")
	_assert(float(hold_button.get("fire_rule_affordance_visual_weight", 0.0)) >= 2.0, "Hold Fire carries active visual weight")

	for inactive_rule in [
		TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_RETURN,
		TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_FREE,
		TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS,
	]:
		var button_snapshot: Dictionary = Dictionary(buttons.get(inactive_rule, {}))
		_assert(not bool(button_snapshot.get("active", true)), "%s Fire-Rule button is not active" % inactive_rule)
		_assert(not bool(button_snapshot.get("fire_rule_affordance_active", true)), "%s Fire-Rule button has no active affordance" % inactive_rule)
		_assert(String(button_snapshot.get("fire_rule_affordance_style_id", "")) == INACTIVE_STYLE_ID, "%s Fire-Rule button uses inactive affordance style" % inactive_rule)

	scene.queue_free()
	await _wait_frames(2)


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


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


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
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
