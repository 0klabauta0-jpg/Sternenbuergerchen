extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")
const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_432_fireteam_muzzle_flash_and_baseline_attack_movement.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_432 Fireteam Muzzle Flash And Baseline Attack Movement ===")
	_test_resolver_forces_baseline_attack_commands_to_rush()
	await _test_muzzle_flash_snapshot_is_visible()
	await _test_drill_scene_renders_all_fireteam_models_and_no_legacy_selection_ring()
	await _test_engage_area_does_not_occupy_and_go_starts_take()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_resolver_forces_baseline_attack_commands_to_rush() -> void:
	FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("clear_caches")
	var units: Array = _make_fireteam_units("resolver")
	var leader = units[0]
	for command_type in ["move", "defend"]:
		var profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call(
			"resolve_profile",
			"resolver",
			units,
			leader,
			command_type,
			Vector2(320.0, -96.0),
			null,
			FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS
		)
		_assert(String(profile.advance_style) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH, "%s uses baseline rush movement" % command_type)
	_cleanup_units(units)


func _test_runtime_take_is_direct_group_order() -> void:
	var command_type := "take"
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var units: Array = _make_fireteam_units(command_type)
	var leader = units[0]
	var profile := {
		"advance_style": FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING,
		"tactical_stance": FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL,
		"cover_priority": 0.6,
		"cohesion_threshold": 120.0,
		"order_fidelity": 0.2,
		"execution_cohesion": 0.35,
		"initiative": 0.5,
	}
	var target_position := Vector2(360.0, -120.0)
	var result: Dictionary = Dictionary(controller.call("start_execution", command_type, command_type, 1, target_position, profile, units, leader, simulation))
	var movement_state: Dictionary = Dictionary(result.get("movement_state", {}))
	_assert(bool(result.get("started", false)), "Take execution starts")
	_assert(String(movement_state.get("effective_style", "")) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH, "Take runtime overrides inherited bound style")
	_assert(Vector2(movement_state.get("order_target_offset", Vector2.INF)).length() <= 0.001, "Take has no fidelity target drift")
	_assert(PackedStringArray(movement_state.get("current_moving_unit_ids", PackedStringArray())).size() == units.size(), "Take moves all members together")
	_assert(PackedStringArray(movement_state.get("current_covering_unit_ids", PackedStringArray())).is_empty(), "Take has no covering subgroup")
	_assert(_commands_are_baseline_attack(simulation.commands, command_type, units.size()), "Take commands stay baseline attack movement")
	_assert(_targets_are_compact(Dictionary(movement_state.get("current_target_positions", {})), target_position), "Take target slots stay compact around the goal")
	_cleanup_units(units)


func _test_muzzle_flash_snapshot_is_visible() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task432_muzzle", Vector2i(5, 5), Vector2.ZERO, 64.0, 32.0, 2)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call(
		"set_order_visual_payload",
		{
			"phase_index": 1,
			"fire_event_dicts": [
				{
					"event_id": "task432_fire",
					"event_type": "weapon_fire",
					"attacker_unit_id": "task432_attacker",
					"target_unit_id": "task432_target",
					"weapon_id": "rifle",
					"attacker_position": Vector2(32.0, 96.0),
					"target_position": Vector2(220.0, 96.0),
				},
			],
		}
	)
	await _wait_frames(6)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var entry: Dictionary = _find_entry(entries, "event_id", "task432_fire")
	_assert(int(snapshot.get("weapon_fire_vfx_visual_count", 0)) == 1, "One fire event still creates one VFX token")
	_assert(bool(entry.get("muzzle_flash_visible", false)), "Muzzle flash sprite is visible")
	_assert(bool(entry.get("muzzle_bloom_visible", false)), "Muzzle bloom marker is visible")
	_assert(float(entry.get("muzzle_flash_pixel_size", 0.0)) >= 0.026, "Muzzle flash is clamped to a readable size")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_drill_scene_renders_all_fireteam_models_and_no_legacy_selection_ring() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)
	var setup := scene.get_node_or_null("MissionSetup")
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(setup != null and controller != null and primary_view != null, "Drill scene exposes setup, controller and primary view")
	if setup == null or controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	if setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	controller.call("_refresh_order_visuals")
	await _wait_frames(8)
	var presence: Dictionary = Dictionary(setup.call("get_expected_unit_presence_snapshot"))
	var expected_friendly_ids: Array = Array(presence.get("friendly_unit_ids", []))
	var expected_enemy_ids: Array = Array(presence.get("enemy_unit_ids", []))
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var visible_ids: Array = Array(snapshot.get("visible_unit_proxy_ids", []))
	_assert(_contains_all(visible_ids, expected_friendly_ids), "All four friendly drill NPC proxies are visible")
	_assert(_contains_all(visible_ids, expected_enemy_ids), "All four enemy drill NPC proxies are visible")
	_assert(int(snapshot.get("animated_unit_model_count", 0)) >= expected_friendly_ids.size() + expected_enemy_ids.size(), "Visible drill proxies use 3D animated unit models")
	for marker_variant in Array(snapshot.get("selected_unit_marker_entries", [])):
		var marker: Dictionary = Dictionary(marker_variant)
		_assert(float(marker.get("surface_offset", 999.0)) <= 0.02, "Selected marker stays at ground height")
	_assert(_legacy_selection_rings_are_hidden(Array(controller.call("_get_all_friendly_units", true))), "Legacy 2D selection rings stay hidden after selection refresh")
	scene.queue_free()
	await _wait_frames(2)


func _test_engage_area_does_not_occupy_and_go_starts_take() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill scene exposes controller for area attack checks")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var units: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "drill")
	_assert(units.size() == 4 and leader is Node2D, "Area test has a four-member fireteam")
	if units.size() != 4 or not (leader is Node2D):
		scene.queue_free()
		await _wait_frames(2)
		return
	var base_position: Vector2 = (leader as Node2D).global_position + Vector2(160.0, -96.0)
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["drill"]), base_position + Vector2(-32.0, -32.0), base_position + Vector2(32.0, 32.0), "engage")
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["drill"]), base_position + Vector2(96.0, -32.0), base_position + Vector2(160.0, 32.0), "take")
	var started: bool = bool(controller.call("_activate_next_attack_area_order", "drill", 1))
	_assert(started, "First Engage Area starts")
	var state: Dictionary = _get_area_attack_state(controller, "drill")
	_assert(String(state.get("command_type", "")) == "engage", "First active area order is Engage")
	_move_units_to_assignments(units, Array(state.get("assignments", [])))
	controller.call("_update_area_attack_execution", 0.016)
	await _wait_frames(2)
	state = _get_area_attack_state(controller, "drill")
	_assert(String(state.get("status", "")) == "engaged", "Engage Area completes as engaged, not secured")
	_assert(bool(state.get("waiting_for_go", false)), "Engage Area waits for GO after the fireline")
	_assert(not state.has("occupation_assignments"), "Engage Area does not create a possession assignment set")
	var continued: bool = bool(controller.call("_try_continue_active_area_attack", "drill"))
	await _wait_frames(2)
	state = _get_area_attack_state(controller, "drill")
	_assert(continued and String(state.get("command_type", "")) == "take", "GO after Engage starts the next Take Area")
	_move_units_to_assignments(units, Array(state.get("assignments", [])))
	controller.call("_update_area_attack_execution", 0.016)
	await _wait_frames(2)
	state = _get_area_attack_state(controller, "drill")
	_assert(String(state.get("status", "")) == "occupying", "Take Area advances into occupation after approach")
	_move_units_to_assignments(units, Array(state.get("assignments", [])))
	controller.call("_update_area_attack_execution", 0.016)
	await _wait_frames(2)
	state = _get_area_attack_state(controller, "drill")
	_assert(String(state.get("status", "")) == "secured" and bool(state.get("waiting_for_go", false)), "Take Area still secures and waits for GO")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(task_text.contains("TASK_432 - Fireteam Muzzle Flash And Baseline Attack Movement"), "TASK_432 task file exists")
	_assert(status_text.contains("TASK_432 - Fireteam Muzzle Flash And Baseline Attack Movement"), "Implementation status documents TASK_432")
	_assert(roadmap_text.contains("TASK_432 - Fireteam Muzzle Flash And Baseline Attack Movement"), "Roadmap lists TASK_432")
	_assert(controller_text.contains("AUTONOMOUS_LEADER_FLANKS_ENABLED: bool = false"), "Autonomous leader flanks are disabled for baseline attack checks")


func _make_fireteam_units(fireteam_id: String) -> Array:
	return [
		_make_unit("%s_lead" % fireteam_id, fireteam_id, true, Vector2(0.0, 0.0)),
		_make_unit("%s_a" % fireteam_id, fireteam_id, false, Vector2(-24.0, 0.0)),
		_make_unit("%s_b" % fireteam_id, fireteam_id, false, Vector2(18.0, -10.0)),
		_make_unit("%s_c" % fireteam_id, fireteam_id, false, Vector2(0.0, 20.0)),
	]


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.is_fireteam_lead = is_lead
	unit.global_position = position_value
	unit.skill_speed = 0.5
	unit.skill_toughness = 0.5
	unit.skill_accuracy = 0.5
	unit.weapon_1_id = "rifle"
	unit._ready()
	return unit


func _commands_are_baseline_attack(commands: Array, source_command_type: String, expected_count: int) -> bool:
	if commands.size() != expected_count:
		return false
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("command_type", "")) != UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA:
			return false
		if String(command.get("source_command_type", "")) != source_command_type:
			return false
		if String(command.get("fire_status", "")) != UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL:
			return false
		if bool(command.get("requeue_until_target", false)) != true:
			return false
	return true


func _targets_are_compact(targets: Dictionary, anchor_position: Vector2) -> bool:
	if targets.size() < 4:
		return false
	for target_variant in targets.values():
		var target_position: Vector2 = Vector2(target_variant)
		if target_position.distance_to(anchor_position) > 96.0:
			return false
	return true


func _move_units_to_assignments(units: Array, assignments: Array) -> void:
	var unit_by_id: Dictionary = {}
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			unit_by_id[String(unit.call("get_unit_id")).strip_edges()] = unit
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		var unit_id: String = String(assignment.get("unit_id", "")).strip_edges()
		var unit = unit_by_id.get(unit_id, null)
		if unit is Node2D:
			(unit as Node2D).global_position = Vector2(assignment.get("target_position", (unit as Node2D).global_position))


func _get_area_attack_state(controller: Node, fireteam_id: String) -> Dictionary:
	if controller == null:
		return {}
	var states: Dictionary = Dictionary(controller.get("_area_attack_execution_by_fireteam"))
	return Dictionary(states.get(fireteam_id, {})).duplicate(true)


func _legacy_selection_rings_are_hidden(units: Array) -> bool:
	for unit in units:
		if unit == null:
			continue
		var ring := (unit as Node).get_node_or_null("SelectionRing") as CanvasItem
		if ring != null and ring.visible:
			return false
	return true


func _find_entry(entries: Array, key: String, expected_value: Variant) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if entry.get(key) == expected_value:
			return entry
	return {}


func _contains_all(values: Array, expected_values: Array) -> bool:
	if expected_values.size() < 4:
		return false
	for expected_variant in expected_values:
		if not values.has(expected_variant):
			return false
	return true


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
