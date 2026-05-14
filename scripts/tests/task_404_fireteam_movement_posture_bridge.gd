extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const TASK_PATH: String = "res://docs/tasks/TASK_404_fireteam_movement_posture_bridge.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"

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
	print("=== TASK_404 Fireteam Movement Posture Bridge ===")
	_test_rush_move_uses_travel_lowered_posture()
	_test_bounding_uses_aimed_mover_and_cover_postures()
	_test_caterpillar_uses_crouch_walk_aimed_posture()
	_test_runtime_animation_resolver_can_use_fireteam_postures()
	_test_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_rush_move_uses_travel_lowered_posture() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("rush_lead", "blue", true, Vector2.ZERO, 0.7, 0.5, 0.5)
	var wing_a = _make_unit("rush_a", "blue", false, Vector2(-32.0, 0.0), 0.8, 0.4, 0.4)
	var wing_b = _make_unit("rush_b", "blue", false, Vector2(32.0, 0.0), 0.6, 0.5, 0.5)
	var profile = _make_profile("blue", "rush", 96.0)
	controller.start_execution("blue", "move", 1, Vector2(260.0, 0.0), profile, [leader, wing_a, wing_b], leader, simulation)
	_assert(simulation.commands.size() == 3, "Rush movement issues one command per fit member")
	for command_variant in simulation.commands:
		var command: Dictionary = Dictionary(command_variant)
		_assert(String(command.get("movement_posture", "")) == "travel", "Rush move command uses travel movement posture")
		_assert(String(command.get("weapon_posture", "")) == "lowered", "Rush move command keeps weapon lowered")
	_cleanup_units([leader, wing_a, wing_b])


func _test_bounding_uses_aimed_mover_and_cover_postures() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("bound_lead", "blue", true, Vector2.ZERO, 0.5, 0.5, 0.8)
	var scout = _make_unit("bound_scout", "blue", false, Vector2(-24.0, 8.0), 0.95, 0.4, 0.4)
	var marksman = _make_unit("bound_marksman", "blue", false, Vector2(24.0, 8.0), 0.45, 0.4, 0.95)
	var rifleman = _make_unit("bound_rifleman", "blue", false, Vector2(8.0, 28.0), 0.55, 0.4, 0.45)
	var profile = _make_profile("blue", "bounding", 96.0)
	controller.start_execution("blue", "move", 1, Vector2(420.0, 80.0), profile, [leader, scout, marksman, rifleman], leader, simulation)
	var scout_command: Dictionary = _find_command(simulation.commands, "bound_scout")
	var leader_command: Dictionary = _find_command(simulation.commands, "bound_lead")
	var marksman_command: Dictionary = _find_command(simulation.commands, "bound_marksman")
	_assert(String(scout_command.get("movement_posture", "")) == "engage", "Bounding mover uses engage movement posture")
	_assert(String(scout_command.get("weapon_posture", "")) == "aimed", "Bounding mover holds weapon aimed")
	_assert(String(leader_command.get("movement_posture", "")) == "overwatch", "Bounding covering lead uses overwatch posture")
	_assert(String(leader_command.get("weapon_posture", "")) == "aimed", "Bounding covering lead holds weapon aimed")
	_assert(String(marksman_command.get("movement_posture", "")) == "overwatch", "Bounding marksman cover command uses overwatch posture")
	_cleanup_units([leader, scout, marksman, rifleman])


func _test_caterpillar_uses_crouch_walk_aimed_posture() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("cat_lead", "gold", true, Vector2.ZERO, 0.45, 0.5, 0.7)
	var scout = _make_unit("cat_scout", "gold", false, Vector2(-20.0, 8.0), 0.95, 0.4, 0.35)
	var support = _make_unit("cat_support", "gold", false, Vector2(20.0, 8.0), 0.5, 0.5, 0.8)
	var profile = _make_profile("gold", "creep", 88.0)
	controller.start_execution("gold", "move", 1, Vector2(300.0, 120.0), profile, [leader, scout, support], leader, simulation)
	var scout_command: Dictionary = _find_command(simulation.commands, "cat_scout")
	var support_command: Dictionary = _find_command(simulation.commands, "cat_support")
	_assert(String(scout_command.get("movement_posture", "")) == "crouch_walk", "Caterpillar moving member uses crouch walk posture")
	_assert(String(scout_command.get("weapon_posture", "")) == "aimed", "Caterpillar moving member keeps weapon aimed")
	_assert(String(support_command.get("movement_posture", "")) == "overwatch", "Caterpillar covering member uses overwatch posture")
	_assert(String(support_command.get("weapon_posture", "")) == "aimed", "Caterpillar covering member keeps weapon aimed")
	_cleanup_units([leader, scout, support])


func _test_runtime_animation_resolver_can_use_fireteam_postures() -> void:
	var view = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	var player := AnimationPlayer.new()
	var library := AnimationLibrary.new()
	for animation_name in ["run", "walkShoot", "crouchWalkShoot", "standShoot", "idle"]:
		library.add_animation(animation_name, Animation.new())
	player.add_animation_library("", library)
	_assert(String(view.call("_resolve_unit_visual_animation_name", player, true, false, "lowered", "travel")) == "run", "Runtime visual resolver maps travel/lowered movement to run")
	_assert(String(view.call("_resolve_unit_visual_animation_name", player, true, false, "aimed", "engage")) == "walkShoot", "Runtime visual resolver maps engage/aimed movement to walkShoot")
	_assert(String(view.call("_resolve_unit_visual_animation_name", player, true, false, "aimed", "crouch_walk")) == "crouchWalkShoot", "Runtime visual resolver maps crouch_walk/aimed movement to crouchWalkShoot")
	_assert(String(view.call("_resolve_unit_visual_animation_name", player, false, false, "aimed", "overwatch")) == "standShoot", "Runtime visual resolver maps covering aimed posture to standShoot")
	player.queue_free()
	view.queue_free()


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	_assert(task_text.contains("movement_posture = travel"), "TASK_404 documents travel posture acceptance")
	_assert(status_text.contains("TASK_404 - Fireteam Movement Posture Bridge"), "Implementation status documents TASK_404")


func _make_profile(fireteam_id: String, advance_style: String, cohesion_threshold: float):
	var profile = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.new()
	profile.fireteam_id = fireteam_id
	profile.advance_style = advance_style
	profile.cover_priority = 0.5
	profile.cohesion_threshold = cohesion_threshold
	return profile


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2, speed: float, toughness: float, accuracy: float) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.is_fireteam_lead = is_lead
	unit.global_position = position_value
	unit.skill_speed = speed
	unit.skill_toughness = toughness
	unit.skill_accuracy = accuracy
	unit.weapon_1_id = "rifle"
	unit._ready()
	return unit


func _find_command(commands: Array, unit_id: String) -> Dictionary:
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("unit_id", "")) == unit_id:
			return command
	return {}


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
