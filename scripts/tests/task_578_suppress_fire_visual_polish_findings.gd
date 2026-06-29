extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TACTICAL_COMMAND_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_578_suppress_fire_visual_polish_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const TASK_577_TEST_PATH: String = "res://scripts/tests/task_577_suppress_fire_visual_evidence_pass.gd"
const TASK_576_TEST_PATH: String = "res://scripts/tests/task_576_suppress_fire_preview_readability_spike.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_578 Suppress Fire Visual Polish Findings ===")
	_test_docs_and_wiring()
	await _test_suppress_area_visual_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_578: FAILED")
		quit(1)
		return
	print("TASK_578: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var terrain_view_text: String = _read_text(TERRAIN_VIEW_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_578 task file exists")
	_assert(task_text.contains("Suppress Fire Visual Polish Findings"), "TASK_578 task file names the task")
	_assert(status_text.contains("TASK_578 - Suppress Fire Visual Polish Findings"), "Implementation status tracks TASK_578")
	_assert(roadmap_text.contains("TASK_578 - Suppress Fire Visual Polish Findings (implementiert)"), "Roadmap marks TASK_578 implemented")
	_assert(roadmap_text.contains("TASK_579 - Suppress Fire Manual F6 Review"), "Roadmap names TASK_579 follow-up")
	_assert(report_text.contains("TASK_578 - Suppress Fire Visual Polish Findings"), "Review workbench tracks TASK_578")
	_assert(report_text.contains("suppress_area_v2"), "Review workbench names current SUP area visual key")
	_assert(contract_text.contains("Suppress-Fire-Visual-Polish-Findings"), "Mission feedback contract documents TASK_578")
	_assert(controller_text.contains("_attach_suppress_fire_preview_to_waypoint_entries"), "Controller attaches SUP preview to waypoint entries")
	_assert(terrain_view_text.contains("waypoint_intent_preview_suppress_area_count"), "Primary3D exposes SUP area render count")
	_assert(FileAccess.file_exists(TASK_577_TEST_PATH), "TASK_577 visual evidence verifier remains available")
	_assert(FileAccess.file_exists(TASK_576_TEST_PATH), "TASK_576 suppress preview verifier remains available")


func _test_suppress_area_visual_snapshot() -> void:
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
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for SUP visual polish")
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
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "Move order can be planned for SUP area visual before GO")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(10)

	var queue_count_before: int = _get_simulation_command_queue_count(simulation_root)
	var suppress_snapshot: Dictionary = Dictionary(controller.call("get_suppress_fire_preview_readability_snapshot"))
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view.has_method("get_render_snapshot") else {}
	var queue_count_after: int = _get_simulation_command_queue_count(simulation_root)
	var suppress_area_entry: Dictionary = _find_first_suppress_area_entry(render_snapshot)
	_assert(queue_count_before == queue_count_after, "Reading SUP area visual does not enqueue commands")
	_assert(String(suppress_snapshot.get("gate", "")) == "pass", "TASK_576 SUP preview gate remains green")
	_assert(String(suppress_snapshot.get("preview_text", "")).contains("SUP AREA"), "SUP AREA text still appears")
	_assert(int(render_snapshot.get("waypoint_intent_preview_path_line_count", 0)) > 0, "Primary3D still reports path line")
	_assert(int(render_snapshot.get("waypoint_intent_preview_suppress_area_count", 0)) > 0, "Primary3D reports SUP area preview count")
	_assert(not suppress_area_entry.is_empty(), "Primary3D render entry exposes SUP area metadata")
	_assert(bool(suppress_area_entry.get("visible", false)), "SUP area entry is visible")
	_assert(String(suppress_area_entry.get("visual_key", "")) == "suppress_area_v2", "SUP area entry uses current stable visual key")
	_assert(float(suppress_area_entry.get("radius_world", 0.0)) > 0.0, "SUP area entry reports radius_world")
	_assert(float(suppress_area_entry.get("radius_3d", 0.0)) > 0.0, "SUP area entry reports radius_3d")
	_assert(String(suppress_area_entry.get("pressure_state", "")) == String(suppress_snapshot.get("pressure_state", "")), "SUP area pressure state mirrors preview snapshot")
	_assert(bool(suppress_area_entry.get("read_only", false)), "SUP area entry remains read-only")
	_assert(not bool(suppress_snapshot.get("ui_sets_gameplay_truth", true)), "SUP area visual does not set gameplay truth")

	scene.queue_free()
	await _wait_frames(2)


func _find_first_suppress_area_entry(render_snapshot: Dictionary) -> Dictionary:
	for entry_variant in Array(render_snapshot.get("waypoint_intent_preview_entries", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		if bool(entry.get("suppress_area_visible", false)):
			return Dictionary(entry.get("suppress_area", {}))
	return {}


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


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
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
