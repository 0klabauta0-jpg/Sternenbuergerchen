extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TACTICAL_COMMAND_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_572_fire_rule_f6_readability_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TASK_571_TEST_PATH: String = "res://scripts/tests/task_571_fire_rule_controls_readability_polish.gd"
const TASK_557_TEST_PATH: String = "res://scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd"
const TASK_566_TEST_PATH: String = "res://scripts/tests/task_566_frontier_probe_multiplayer_f6_hover_panel_polish_pass.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_572 Fire Rule F6 Readability Smoke ===")
	_test_docs_and_wiring()
	await _test_fire_rule_f6_readability_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_572: FAILED")
		quit(1)
		return
	print("TASK_572: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_572 task file exists")
	_assert(task_text.contains("Fire Rule F6 Readability Smoke"), "TASK_572 task file names the smoke")
	_assert(status_text.contains("TASK_572 - Fire Rule F6 Readability Smoke"), "Implementation status tracks TASK_572")
	_assert(roadmap_text.contains("TASK_572 - Fire Rule F6 Readability Smoke"), "Roadmap tracks TASK_572")
	_assert(report_text.contains("TASK_572 - Fire Rule F6 Readability Smoke"), "HTML report tracks TASK_572")
	_assert(contract_text.contains("Fire-Rule-F6-Readability-Smoke"), "Mission command feedback contract documents TASK_572")
	_assert(controller_text.contains("get_fire_rule_f6_readability_snapshot"), "Mission controller exposes TASK_572 snapshot")
	_assert(FileAccess.file_exists(TASK_571_TEST_PATH), "TASK_571 fire-rule controls verifier remains available")
	_assert(FileAccess.file_exists(TASK_557_TEST_PATH), "TASK_557 F6 readability verifier remains available")
	_assert(FileAccess.file_exists(TASK_566_TEST_PATH), "TASK_566 hover/panel verifier remains available")


func _test_fire_rule_f6_readability_snapshot() -> void:
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
	_assert(friendly_units.size() >= 2, "Mission scene exposes Alpha units for Fire-Rule F6 smoke")
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

	var snapshot: Dictionary = Dictionary(controller.call("get_fire_rule_f6_readability_snapshot"))
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_572 Fire-Rule F6 readability snapshot passes")
	_assert(_check_passed(snapshot, "task571_controls_gate_passes"), "TASK_571 controls gate remains green")
	_assert(_check_passed(snapshot, "fire_rule_buttons_visible"), "Fire-Rule buttons are visible in FullHD")
	_assert(_check_passed(snapshot, "fire_rule_buttons_inside_command_panel"), "Fire-Rule buttons stay inside Command Matrix")
	_assert(_check_passed(snapshot, "fire_rule_buttons_inside_fullhd"), "Fire-Rule buttons stay inside FullHD")
	_assert(_check_passed(snapshot, "fire_rule_group_compact"), "Fire-Rule button group remains compact")
	_assert(_check_passed(snapshot, "fire_rule_controls_do_not_overlap_core_panels"), "Fire-Rule buttons do not overlap core panels")
	_assert(_check_passed(snapshot, "active_fire_rule_visible"), "Active Fire-Rule is visible")
	_assert(_check_passed(snapshot, "tooltips_and_help_explain_labels"), "Tooltips and help IDs explain short labels")
	_assert(_check_passed(snapshot, "bottom_hud_stays_world_readable"), "Bottom HUD leaves world readable")
	_assert(_check_passed(snapshot, "read_only"), "TASK_572 snapshot remains read-only")
	_assert(String(snapshot.get("selected_fire_rule_consensus", "")) == TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD, "Hold Fire consensus is visible")
	_assert(Array(snapshot.get("active_button_rules", [])).has(TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD), "Hold Fire button is active")
	_assert(int(snapshot.get("max_label_length", 99)) <= 3, "Fire-Rule labels stay short")
	_assert(float(snapshot.get("bottom_hud_occlusion_ratio", 1.0)) <= 0.30, "Bottom HUD occlusion ratio stays under budget")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Fire-Rule F6 snapshot does not set gameplay truth")

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
