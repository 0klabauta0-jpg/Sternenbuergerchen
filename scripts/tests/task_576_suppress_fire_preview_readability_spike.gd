extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TACTICAL_COMMAND_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_576_suppress_fire_preview_readability_spike.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TACTICAL_CLARITY_CONTRACT_PATH: String = "res://docs/dev/tactical_decision_clarity_contract.md"
const COMMAND_RULES_CONTRACT_PATH: String = "res://docs/dev/tactical_command_rules_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TASK_567_TEST_PATH: String = "res://scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd"
const TASK_575_TEST_PATH: String = "res://scripts/tests/task_575_fire_rule_evidence_polish_findings.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_576 Suppress Fire Preview Readability Spike ===")
	_test_docs_and_wiring()
	await _test_suppress_fire_preview_before_go()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_576: FAILED")
		quit(1)
		return
	print("TASK_576: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var tactical_clarity_text: String = _read_text(TACTICAL_CLARITY_CONTRACT_PATH)
	var command_rules_text: String = _read_text(COMMAND_RULES_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_576 task file exists")
	_assert(task_text.contains("Suppress Fire Preview Readability Spike"), "TASK_576 task file names the task")
	_assert(status_text.contains("TASK_576 - Suppress Fire Preview Readability Spike"), "Implementation status tracks TASK_576")
	_assert(roadmap_text.contains("TASK_576 - Suppress Fire Preview Readability Spike (implementiert)"), "Roadmap marks TASK_576 implemented")
	_assert(roadmap_text.contains("TASK_577 - Suppress Fire Visual Evidence Pass"), "Roadmap names TASK_577 follow-up")
	_assert(report_text.contains("TASK_576 - Suppress Fire Preview Readability Spike"), "Review workbench tracks TASK_576")
	_assert(report_text.contains("TASK_577 - Suppress Fire Visual Evidence Pass"), "Review workbench names TASK_577 next task")
	_assert(contract_text.contains("Suppress-Fire-Preview-Readability"), "Mission feedback contract documents TASK_576")
	_assert(tactical_clarity_text.contains("read_only = true"), "Tactical clarity contract keeps preview read-only")
	_assert(command_rules_text.contains("fire_rule") and command_rules_text.contains("suppress"), "Tactical command rules still define suppress")
	_assert(controller_text.contains("get_suppress_fire_preview_readability_snapshot"), "Mission controller exposes TASK_576 snapshot")
	_assert(controller_text.contains("SUP AREA"), "Mission controller formats compact SUP AREA preview text")
	_assert(FileAccess.file_exists(TASK_567_TEST_PATH), "TASK_567 threat preview verifier remains available")
	_assert(FileAccess.file_exists(TASK_575_TEST_PATH), "TASK_575 fire-rule polish verifier remains available")


func _test_suppress_fire_preview_before_go() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var primary_view: Node = scene.get_node_or_null("Primary3DView")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and primary_view != null and simulation_root != null, "Mission fixture exposes TacticalController, Primary3DView and SimulationRoot")
	if controller == null or primary_view == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for SUP preview")
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
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "Move order can be planned before SUP preview")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)

	var queue_count_before: int = _get_simulation_command_queue_count(simulation_root)
	var snapshot: Dictionary = Dictionary(controller.call("get_suppress_fire_preview_readability_snapshot"))
	var queue_count_after: int = _get_simulation_command_queue_count(simulation_root)
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_576 suppress preview gate passes before GO")
	_assert(_check_passed(snapshot, "first_move_gate_still_passes"), "TASK_540 first-move gate remains green")
	_assert(_check_passed(snapshot, "threat_preview_gate_still_passes"), "TASK_567 threat preview gate remains green")
	_assert(_check_passed(snapshot, "suppress_rule_selected"), "SUP fire-rule is selected")
	_assert(_check_passed(snapshot, "suppress_preview_enabled"), "SUP preview is enabled for planned target")
	_assert(_check_passed(snapshot, "suppress_preview_text_visible"), "SUP AREA appears in selected order text")
	_assert(_check_passed(snapshot, "suppress_preview_has_area_context"), "SUP preview exposes area context")
	_assert(_check_passed(snapshot, "suppress_preview_remains_read_only"), "SUP preview remains read-only")
	_assert(queue_count_before == queue_count_after, "Reading SUP preview does not enqueue commands")
	_assert(String(snapshot.get("fire_rule", "")) == TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS, "Snapshot reports suppress fire-rule")
	_assert(bool(snapshot.get("enabled", false)), "Snapshot reports SUP preview enabled")
	_assert(String(snapshot.get("preview_text", "")).contains("SUP AREA"), "Snapshot preview text contains SUP AREA")
	_assert(float(snapshot.get("radius_world", 0.0)) > 0.0, "Snapshot reports SUP area radius")
	_assert(String(snapshot.get("selected_order_text", "")).contains("SUP AREA"), "Selected order text carries SUP preview")

	controller.call("set_fireteams_fire_rule", PackedStringArray(["blue"]), TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD)
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(4)
	var hold_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(not String(hold_feedback.get("selected_order_text", "")).contains("SUP AREA"), "Non-suppress fire-rule does not show stale SUP preview")

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
