extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_677_mission_interaction_use_intent.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_677 Mission Interaction Use Intent ===")
	_test_docs()
	await _test_controller_use_intents()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_677: FAILED")
		quit(1)
		return
	print("TASK_677: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_677 task file exists")
	_assert(task_text.contains("Mission Interaction Use Intent"), "Task documents use intent")
	_assert(contract_text.contains("Use Intent"), "Interaction contract documents Use Intent")
	_assert(contract_text.contains("create_selected_mission_interaction_use_intent"), "Interaction contract names controller use intent method")
	_assert(_read_text(STATUS_PATH).contains("TASK_677 - Mission Interaction Use Intent"), "Implementation status tracks TASK_677")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_677 - Mission Interaction Use Intent"), "Roadmap lists TASK_677")
	_assert(_read_text(HANDBOOK_PATH).contains("TASK_677 - Mission Interaction Use Intent"), "Current handbook references TASK_677")


func _test_controller_use_intents() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var mission_setup: Node = scene.get_node_or_null("MissionSetup")
	_assert(controller != null and combat_driver != null and mission_setup != null, "Mission scene exposes controller, combat driver and setup")
	if controller == null or combat_driver == null or mission_setup == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	await _wait_frames(2)
	_assert(not fireteam_id.is_empty() and PackedStringArray(controller.call("get_selected_fireteam_ids")).has(fireteam_id), "Verifier selects a fireteam for interaction use")

	var blocked_intent: Dictionary = Dictionary(controller.call("create_selected_mission_interaction_use_intent", "cargo_landing_hold"))
	_assert(not bool(blocked_intent.get("accepted", true)), "Blocked cargo interaction does not create an intent")
	_assert(String(blocked_intent.get("blocked_reason", "")) == "interaction_not_usable", "Blocked cargo intent names not-usable reason")
	_assert(int(Dictionary(controller.call("get_command_feedback_snapshot")).get("planned_waypoint_count", 0)) == 0, "Blocked cargo intent does not create waypoints")

	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	var cargo_intent: Dictionary = Dictionary(controller.call("create_selected_mission_interaction_use_intent", "cargo_landing_hold"))
	_assert(bool(cargo_intent.get("accepted", false)), "Cargo interaction creates an accepted use intent after AA complete")
	_assert(String(cargo_intent.get("command_type", "")) == "defend", "Cargo use intent maps required_order defend to waypoint command")
	_assert(bool(cargo_intent.get("requires_go", false)), "Cargo use intent requires GO instead of auto-executing")
	_assert(bool(cargo_intent.get("scenario_truth_read_only", false)) and not bool(cargo_intent.get("ui_sets_gameplay_truth", true)), "Cargo use intent does not set scenario truth")
	var cargo_waypoint: Dictionary = _find_waypoint_for_interaction(controller, fireteam_id, "cargo_landing_hold")
	_assert(String(cargo_waypoint.get("command_type", "")) == "defend", "Cargo intent creates a defend waypoint")
	_assert(String(Dictionary(cargo_waypoint.get("metadata", {})).get("source", "")) == "mission_interaction_use_intent", "Cargo waypoint metadata names use intent source")

	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var objective_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, objective_position)
	await _wait_frames(2)
	var station_intent: Dictionary = Dictionary(controller.call("create_selected_mission_interaction_use_intent", "station_computer"))
	_assert(bool(station_intent.get("accepted", false)), "Station computer creates an accepted use intent when selected fireteam is in range")
	_assert(String(station_intent.get("command_type", "")) == "take", "Station computer maps required_order take to waypoint command")
	var station_waypoint: Dictionary = _find_waypoint_for_interaction(controller, fireteam_id, "station_computer")
	_assert(String(station_waypoint.get("command_type", "")) == "take", "Station computer intent creates a take waypoint")
	_assert(Vector2(station_waypoint.get("target_position", Vector2.ZERO)).distance_to(objective_position) <= 1.0, "Station computer waypoint targets the marker position")
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var exported_intent: Dictionary = Dictionary(command_feedback.get("mission_interaction_use_intent", {}))
	_assert(bool(command_feedback.get("mission_interaction_use_intent_accepted", false)), "Command feedback exports accepted use intent")
	_assert(String(exported_intent.get("interaction_id", "")) == "station_computer", "Command feedback exports station computer as latest use intent")
	_assert(String(command_feedback.get("mission_interaction_use_intent_command_type", "")) == "take", "Command feedback exports latest use intent command type")

	scene.queue_free()
	await _wait_frames(2)


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
		candidate_id = _first_configured_fireteam_id(mission_setup)
	if candidate_id.is_empty():
		candidate_id = "ft1"
	controller.call("_set_selected_fireteams", PackedStringArray([candidate_id]), false)
	var selected_ids: PackedStringArray = PackedStringArray(controller.call("get_selected_fireteam_ids"))
	if not selected_ids.is_empty():
		return String(selected_ids[0]).strip_edges().to_lower()
	for option_variant in Array(controller.call("_get_fireteam_selection_options")):
		if typeof(option_variant) != TYPE_DICTIONARY:
			continue
		var option_ids: PackedStringArray = PackedStringArray(Array(Dictionary(option_variant).get("ids", [])))
		if option_ids.size() != 1:
			continue
		controller.call("_set_selected_fireteams", option_ids, false)
		selected_ids = PackedStringArray(controller.call("get_selected_fireteam_ids"))
		if not selected_ids.is_empty():
			return String(selected_ids[0]).strip_edges().to_lower()
	return ""


func _first_configured_fireteam_id(mission_setup: Node) -> String:
	var configured_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_fireteam_ids"))
	if not configured_ids.is_empty():
		return String(configured_ids[0]).strip_edges().to_lower()
	return ""


func _find_waypoint_for_interaction(controller: Node, fireteam_id: String, interaction_id: String) -> Dictionary:
	for plan_variant in Array(Dictionary(controller.call("get_command_feedback_snapshot")).get("waypoint_intent_preview", [])):
		if typeof(plan_variant) == TYPE_DICTIONARY:
			var preview: Dictionary = Dictionary(plan_variant)
			if String(Dictionary(preview.get("metadata", {})).get("interaction_id", "")) == interaction_id:
				return preview
	for plan_variant in Array(controller.call("_serialize_order_plans")):
		var plan: Dictionary = Dictionary(plan_variant)
		if String(plan.get("fireteam_id", "")).strip_edges().to_lower() != fireteam_id:
			continue
		for waypoint_variant in Array(plan.get("waypoints", [])):
			var waypoint: Dictionary = Dictionary(waypoint_variant)
			if String(Dictionary(waypoint.get("metadata", {})).get("interaction_id", "")) == interaction_id:
				return waypoint
	return {}


func _move_fireteam_units(scene: Node, fireteam_id: String, center_position: Vector2) -> void:
	var offset_index: int = 0
	for child in scene.get_children():
		if not (child is Node2D):
			continue
		if not child.has_method("get_fireteam_id"):
			continue
		if String(child.call("get_fireteam_id")).strip_edges().to_lower() != fireteam_id:
			continue
		var offset: Vector2 = Vector2(float(offset_index % 2) * 10.0, float(int(offset_index / 2)) * 10.0)
		(child as Node2D).global_position = center_position + offset
		offset_index += 1


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
