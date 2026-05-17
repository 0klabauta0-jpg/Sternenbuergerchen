extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const FOB_FIRETEAM_CARD_SCRIPT: GDScript = preload("res://scripts/meta/fob_fireteam_card.gd")
const NPC_COMPACT_CARD_SCENE: PackedScene = preload("res://scenes/meta/components/npc_compact_card.tscn")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_437_fireteam_selection_patrol_contact_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const SCENARIO_PATH: String = "res://data/mission_scenarios/fireteam_command_drill_24x24.json"
const SELECTED_YELLOW: Color = Color("f2c94c")
const MIN_PARALLEL_SPREAD: float = 112.0

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


class AlwaysLos:
	extends RefCounted

	func has_line_of_sight_between_nodes(_attacker, _target, _range: float, _terrain_registry = null) -> bool:
		return true


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_437 Fireteam Selection Patrol Contact Pass ===")
	await _test_selection_visuals_are_yellow_and_grounded()
	await _test_selected_cards_use_yellow_borders()
	_test_move_uses_parallel_slots_and_contact_fire()
	_test_move_command_can_attack_when_fire_at_will()
	await _test_drill_scene_activates_four_patrolling_enemies()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_selection_visuals_are_yellow_and_grounded() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task437_selection_map", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	var unit: Node2D = _make_unit("task437_alpha", "drill", true, Vector2(160.0, 160.0))
	root.add_child(unit)
	primary_view.call("set_unit_nodes", [unit])
	await _wait_frames(8)
	primary_view.call("set_order_visual_payload", {"selected_fireteam_ids": PackedStringArray(["drill"])})
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var markers: Array = Array(snapshot.get("selected_unit_marker_entries", []))
	_assert(markers.size() == 1, "Selected fireteam emits a selected-unit marker")
	if not markers.is_empty():
		var marker: Dictionary = Dictionary(markers[0])
		_assert(_is_yellow(Color(marker.get("color", Color.BLACK))), "Selected-unit marker is yellow")
		_assert(float(marker.get("surface_offset", 99.0)) <= 0.0061, "Selected-unit marker sits close to the ground")
		_assert(float(marker.get("height", 99.0)) <= 0.02, "Selected-unit marker is a flat ground disc, not a spawn block")
	primary_view.queue_free()
	unit.queue_free()
	await _wait_frames(2)


func _test_selected_cards_use_yellow_borders() -> void:
	var fireteam_card = FOB_FIRETEAM_CARD_SCRIPT.new()
	root.add_child(fireteam_card)
	fireteam_card.call("setup_card", "drill", "DRILL", true, false, "medium", "4 operators", "mission_mini")
	await _wait_frames(2)
	_assert(_stylebox_border_is_yellow(fireteam_card), "Selected fireteam mini-card border is yellow")

	var member_card := NPC_COMPACT_CARD_SCENE.instantiate()
	root.add_child(member_card)
	member_card.call("setup_from_profile", {"unit_id": "task437_member", "display_name": "Task Member"}, {"selected": true, "source_context": "mission"})
	await _wait_frames(2)
	_assert(_stylebox_border_is_yellow(member_card), "#17 selected member card border is yellow")
	fireteam_card.queue_free()
	member_card.queue_free()
	await _wait_frames(2)


func _test_move_uses_parallel_slots_and_contact_fire() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var units: Array = _make_fireteam_units("task437_move")
	var profile = _make_move_profile("task437_move")
	var result: Dictionary = controller.start_execution("task437_move", "move", 1, Vector2(320.0, 0.0), profile, units, units[0], simulation)
	_assert(bool(result.get("started", false)), "Normal Move execution starts")
	_assert(simulation.commands.size() == 4, "Normal Move issues one command per member")
	_assert(_all_move_commands_fire_at_will(simulation.commands), "Normal Move commands keep contact fire enabled")
	_assert(_lateral_target_spread(simulation.commands, Vector2.RIGHT) >= MIN_PARALLEL_SPREAD, "Normal Move target slots spread laterally instead of single-file")
	_cleanup_units(units)


func _test_move_command_can_attack_when_fire_at_will() -> void:
	var unit: Node2D = _make_unit("task437_attacker", "drill", true, Vector2.ZERO)
	var enemy: Node2D = _make_unit("task437_target", "red", false, Vector2(64.0, 0.0))
	enemy.team_id = "team_bravo"
	var command = UNIT_COMMAND_SCRIPT.new()
	command.command_type = UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION
	command.source_command_type = "move"
	command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
	command.unit_id = "task437_attacker"
	command.target_position = Vector2(96.0, 0.0)
	unit.call("assign_unit_command", command)
	_assert(bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("can_unit_attack", unit, {})), "Fire-at-will Move is eligible to shoot on contact")
	var contact_pair: Dictionary = Dictionary(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("find_first_contact_pair", {
		"friendly_units": [unit],
		"enemy_units": [enemy],
		"friendly_team_id": "team_alpha",
		"los_system": AlwaysLos.new(),
		"contact_range": 512.0,
	}))
	_assert(String(contact_pair.get("attacker_id", "")) == "task437_attacker" and String(contact_pair.get("target_id", "")) == "task437_target", "Fire-at-will Move produces a friendly contact-fire pair")
	command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_HOLD_FIRE
	unit.call("assign_unit_command", command)
	_assert(not bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("can_unit_attack", unit, {})), "Hold-fire Move still blocks contact shooting")
	unit.queue_free()
	enemy.queue_free()


func _test_drill_scene_activates_four_patrolling_enemies() -> void:
	root.size = Vector2i(1920, 1080)
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	_assert(scenario != null, "Drill scenario loads")
	if scenario != null:
		var wave_config: Dictionary = Dictionary(scenario.get("wave_config"))
		_assert(int(wave_config.get("wave_count", 0)) == 1 and int(wave_config.get("units_per_wave", 0)) == 4, "Drill scenario starts all four enemies in one wave")
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(60)
	var setup := scene.get_node_or_null("MissionSetup")
	var controller := scene.get_node_or_null("TacticalController")
	var combat_loop := scene.get_node_or_null("CombatLoopDriver")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_assert(setup != null and controller != null and combat_loop != null and simulation_root != null, "Drill scene exposes setup, controller, combat loop and simulation")
	if setup != null and setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	if controller != null:
		var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
		_assert(enemies.size() == 4, "Drill scene has four enemy NPC nodes")
		_assert(_all_canvas_items_visible(enemies), "All four drill enemies are active and visible")
	if combat_loop != null:
		var patrol_paths: Dictionary = Dictionary(combat_loop.get("_enemy_patrol_paths_by_unit_id"))
		_assert(patrol_paths.size() == 4, "Combat loop resolves four active enemy patrol paths after wave activation")
	if combat_loop != null and simulation_root != null and controller != null:
		for friendly in Array(controller.call("_get_all_friendly_units", true)):
			if friendly is Node2D:
				(friendly as Node2D).global_position = Vector2(-3000.0, -3000.0)
		var command_queue: Array = Array(simulation_root.get("command_queue"))
		command_queue.clear()
		simulation_root.set("command_queue", command_queue)
		combat_loop.call("_initialize_enemy_patrol_paths")
		combat_loop.call("_advance_enemy_units", simulation_root)
		var commands: Array = Array(simulation_root.get("command_queue"))
		_assert(_count_commands_by_source(commands, "enemy_patrol") == 4, "Patrol bindings enqueue four enemy patrol commands before contact")
	scene.queue_free()
	await _wait_frames(3)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK_437 - Fireteam Selection Patrol Contact Pass"), "TASK_437 task file exists")
	_assert(status_text.contains("TASK_437 - Fireteam Selection Patrol Contact Pass"), "Implementation status documents TASK_437")
	_assert(roadmap_text.contains("TASK_437 - Fireteam Selection Patrol Contact Pass"), "Roadmap lists TASK_437")


func _make_move_profile(fireteam_id: String):
	var profile = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.new()
	profile.fireteam_id = fireteam_id
	profile.advance_style = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH
	profile.tactical_stance = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL
	profile.cover_priority = 0.4
	profile.cohesion_threshold = 96.0
	profile.order_fidelity = 1.0
	profile.execution_cohesion = 0.65
	profile.initiative = 0.5
	return profile


func _make_fireteam_units(fireteam_id: String) -> Array:
	return [
		_make_unit("%s_lead" % fireteam_id, fireteam_id, true, Vector2(0.0, 0.0)),
		_make_unit("%s_a" % fireteam_id, fireteam_id, false, Vector2(-12.0, 2.0)),
		_make_unit("%s_b" % fireteam_id, fireteam_id, false, Vector2(10.0, -2.0)),
		_make_unit("%s_c" % fireteam_id, fireteam_id, false, Vector2(0.0, 12.0)),
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
	unit.weapon_2_id = "none"
	unit._ready()
	return unit


func _all_move_commands_fire_at_will(commands: Array) -> bool:
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("source_command_type", "")) != "move":
			return false
		if String(command.get("fire_status", "")) != UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL:
			return false
	return true


func _lateral_target_spread(commands: Array, travel_direction: Vector2) -> float:
	var lateral: Vector2 = travel_direction.normalized().orthogonal()
	var min_projection: float = INF
	var max_projection: float = -INF
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if typeof(command.get("target_position", null)) != TYPE_VECTOR2:
			continue
		var projection: float = lateral.dot(Vector2(command.get("target_position")))
		min_projection = minf(min_projection, projection)
		max_projection = maxf(max_projection, projection)
	if min_projection == INF or max_projection == -INF:
		return 0.0
	return max_projection - min_projection


func _all_canvas_items_visible(nodes: Array) -> bool:
	for node in nodes:
		if node is CanvasItem and not (node as CanvasItem).visible:
			return false
	return true


func _count_commands_by_source(commands: Array, source_command_type: String) -> int:
	var count: int = 0
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("source_command_type", "")) == source_command_type:
			count += 1
	return count


func _stylebox_border_is_yellow(control: Control) -> bool:
	if control == null:
		return false
	var stylebox := control.get_theme_stylebox("panel")
	if stylebox is StyleBoxFlat:
		return _is_yellow((stylebox as StyleBoxFlat).border_color)
	return false


func _is_yellow(color: Color) -> bool:
	return color.r >= 0.9 and color.g >= 0.72 and color.b <= 0.36


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
