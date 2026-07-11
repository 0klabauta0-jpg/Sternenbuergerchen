extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const FOG_OF_WAR_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const UNIT_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_runtime_status.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_421_move_stance_posture_speed_sight.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const MOVEMENT_CONTROLLER_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"
const FOG_OF_WAR_PATH: String = "res://scripts/core/fog_of_war_system.gd"

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


class TileStub:
	extends RefCounted
	var world_position: Vector2 = Vector2.ZERO
	var tile_id: String = "tile_stub"
	var grid_position: Vector2i = Vector2i.ZERO


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_421 Move Stance Posture Speed Sight ===")
	_test_unit_command_and_runtime_status_carry_sight_factor()
	_test_move_stances_apply_posture_speed_and_sight()
	_test_fog_of_war_uses_runtime_sight_factor()
	_test_visual_resolver_accepts_run_posture()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_unit_command_and_runtime_status_carry_sight_factor() -> void:
	var command = UNIT_COMMAND_SCRIPT.new({
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION,
		"unit_id": "alpha",
		"team_id": "blue",
		"target_position": Vector2(64.0, 0.0),
		"move_speed_factor": 1.2,
		"sight_range_factor": 0.65,
		"movement_posture": "run",
		"weapon_posture": "lowered",
		"posture_policy_id": "move_stance",
	})
	var command_dict: Dictionary = command.to_dict()
	_assert(bool(command.call("is_valid")), "UnitCommand accepts run posture with sight factor")
	_assert(String(command_dict.get("movement_posture", "")) == "run", "UnitCommand normalizes aggressive run posture")
	_assert(is_equal_approx(float(command_dict.get("sight_range_factor", 0.0)), 0.65), "UnitCommand serializes sight_range_factor")

	var runtime_status = UNIT_RUNTIME_STATUS_SCRIPT.new({
		"status": UNIT_RUNTIME_STATUS_SCRIPT.STATUS_PENDING_MOVE,
		"active_command_type": UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION,
		"unit_id": "alpha",
		"team_id": "blue",
		"sight_range_factor": 1.2,
		"movement_posture": "run",
		"weapon_posture": "lowered",
	})
	var runtime_dict: Dictionary = runtime_status.to_dict()
	_assert(bool(runtime_status.call("is_valid")), "UnitRuntimeStatus accepts sight_range_factor")
	_assert(String(runtime_dict.get("movement_posture", "")) == "run", "UnitRuntimeStatus normalizes run posture")
	_assert(is_equal_approx(float(runtime_dict.get("sight_range_factor", 0.0)), 1.2), "UnitRuntimeStatus serializes sight_range_factor")


func _test_move_stances_apply_posture_speed_and_sight() -> void:
	var normal_result: Dictionary = _execute_move_stance(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)
	var cautious_result: Dictionary = _execute_move_stance(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS)
	var aggressive_result: Dictionary = _execute_move_stance(FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE)

	var normal_command: Dictionary = Dictionary(normal_result.get("command", {}))
	var cautious_command: Dictionary = Dictionary(cautious_result.get("command", {}))
	var aggressive_command: Dictionary = Dictionary(aggressive_result.get("command", {}))
	var normal_speed: float = float(normal_command.get("move_speed_factor", 0.0))

	_assert(String(cautious_command.get("weapon_posture", "")) == "aimed", "Cautious Move keeps weapon aimed")
	_assert(String(cautious_command.get("movement_posture", "")) == "engage", "Cautious Move uses engage movement posture")
	_assert(_is_close_ratio(float(cautious_command.get("move_speed_factor", 0.0)), normal_speed, 0.35 / 0.65), "Cautious Move applies the global 35 versus 65 speed profile")
	_assert(is_equal_approx(float(cautious_command.get("sight_range_factor", 0.0)), 1.0), "Cautious Move applies global full sight")

	_assert(String(normal_command.get("movement_posture", "")) == "travel", "Normal Move uses travel/walk posture")
	_assert(String(normal_command.get("weapon_posture", "")) == "lowered", "Normal Move keeps weapon lowered")
	_assert(is_equal_approx(float(normal_command.get("sight_range_factor", 0.0)), 0.8), "Normal Move applies global 80 percent sight")

	_assert(String(aggressive_command.get("movement_posture", "")) == "run", "Aggressive Move uses run posture")
	_assert(String(aggressive_command.get("weapon_posture", "")) == "lowered", "Aggressive Move keeps weapon lowered")
	_assert(_is_close_ratio(float(aggressive_command.get("move_speed_factor", 0.0)), normal_speed, 1.0 / 0.65), "Aggressive Move applies the global 100 versus 65 speed profile")
	_assert(is_equal_approx(float(aggressive_command.get("sight_range_factor", 0.0)), 0.5), "Aggressive Move applies global 50 percent sight")

	for result in [normal_result, cautious_result, aggressive_result]:
		var command: Dictionary = Dictionary(result.get("command", {}))
		var runtime: Dictionary = Dictionary(result.get("runtime", {}))
		_assert(String(command.get("posture_policy_id", "")) == "move_stance", "Move commands carry move_stance policy id")
		_assert(is_equal_approx(float(runtime.get("sight_range_factor", 0.0)), float(command.get("sight_range_factor", 0.0))), "Assigned unit runtime carries command sight factor")


func _test_fog_of_war_uses_runtime_sight_factor() -> void:
	var observer = _make_unit("observer", "drill", true, Vector2.ZERO)
	var tile = TileStub.new()
	var fog = FOG_OF_WAR_SYSTEM_SCRIPT.new()

	tile.world_position = Vector2(110.0, 0.0)
	observer.set_runtime_status(
		"pending_move",
		UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION,
		12,
		"hold_fire",
		"move",
		1.0,
		0.0,
		0.0,
		1,
		tile.world_position,
		"engage",
		"aimed",
		"move_stance",
		1.2
	)
	_assert(bool(fog.call("_observer_can_see_tile", observer, tile, null, null, 100.0)), "Cautious runtime sight factor extends fog visibility")

	tile.world_position = Vector2(80.0, 0.0)
	observer.set_runtime_status(
		"pending_move",
		UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION,
		12,
		"hold_fire",
		"move",
		1.0,
		0.0,
		0.0,
		1,
		tile.world_position,
		"run",
		"lowered",
		"move_stance",
		0.65
	)
	_assert(not bool(fog.call("_observer_can_see_tile", observer, tile, null, null, 100.0)), "Aggressive runtime sight factor reduces fog visibility")
	observer.queue_free()


func _test_visual_resolver_accepts_run_posture() -> void:
	var view = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	var player := AnimationPlayer.new()
	var library := AnimationLibrary.new()
	for animation_name in ["run", "walk", "idle"]:
		library.add_animation(animation_name, Animation.new())
	player.add_animation_library("", library)
	_assert(String(view.call("_resolve_unit_visual_animation_name", player, true, false, "lowered", "run")) == "run", "Terrain visual resolver maps run posture to run animation")
	player.queue_free()
	view.queue_free()


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var controller_text: String = _read_text(MOVEMENT_CONTROLLER_PATH)
	var fog_text: String = _read_text(FOG_OF_WAR_PATH)
	_assert(task_text.contains("TASK_421 - Move Stance Posture Speed Sight"), "TASK_421 task file exists")
	_assert(status_text.contains("TASK_421 - Move Stance Posture Speed Sight"), "Implementation status documents TASK_421")
	_assert(roadmap_text.contains("TASK_421 - Move Stance Posture Speed Sight"), "Roadmap lists TASK_421")
	_assert(controller_text.contains("STANCE_CAUTIOUS_SPEED_MULTIPLIER: float = 0.35"), "Movement controller documents global cautious speed multiplier")
	_assert(controller_text.contains("STANCE_AGGRESSIVE_SIGHT_FACTOR: float = 0.5"), "Movement controller documents global aggressive sight factor")
	_assert(fog_text.contains("_get_observer_sight_range_factor"), "Fog-of-war reads observer sight range factor")


func _execute_move_stance(tactical_stance: String) -> Dictionary:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("lead_%s" % tactical_stance, "drill", true, Vector2.ZERO)
	var wing = _make_unit("wing_%s" % tactical_stance, "drill", false, Vector2(-32.0, 0.0))
	var profile = _make_profile("drill", tactical_stance)
	controller.start_execution("drill", "move", 1, Vector2(280.0, 0.0), profile, [leader, wing], leader, simulation)
	var leader_command: Dictionary = _find_command(simulation.commands, leader.unit_id)
	var runtime_dict: Dictionary = Dictionary(leader.get_runtime_status().to_dict())
	wing.queue_free()
	leader.queue_free()
	return {
		"command": leader_command,
		"runtime": runtime_dict,
	}


func _make_profile(fireteam_id: String, tactical_stance: String):
	var profile = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.new()
	profile.fireteam_id = fireteam_id
	profile.advance_style = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH
	profile.tactical_stance = tactical_stance
	profile.cover_priority = 0.5
	profile.cohesion_threshold = 96.0
	profile.order_fidelity = 1.0
	profile.execution_cohesion = 0.65
	profile.initiative = 0.5
	return profile


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


func _find_command(commands: Array, unit_id: String) -> Dictionary:
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("unit_id", "")) == unit_id:
			return command
	return {}


func _is_close_ratio(value: float, baseline: float, expected_ratio: float) -> bool:
	if baseline <= 0.0:
		return false
	return absf((value / baseline) - expected_ratio) <= 0.002


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
