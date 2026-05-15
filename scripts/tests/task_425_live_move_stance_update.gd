extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_425_live_move_stance_update.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const MOVEMENT_CONTROLLER_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"
const SANDBOX_CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

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
	print("=== TASK_425 Live Move Stance Update ===")
	_test_controller_live_stance_reissues_move_commands()
	await _test_drill_ui_live_stance_updates_active_move()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_controller_live_stance_reissues_move_commands() -> void:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var leader = _make_unit("lead_live", "drill", true, Vector2.ZERO)
	var wing = _make_unit("wing_live", "drill", false, Vector2(-32.0, 0.0))
	var profile = _make_profile("drill", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)

	var start_result: Dictionary = Dictionary(controller.call("start_execution", "drill", "move", 1, Vector2(280.0, 0.0), profile, [leader, wing], leader, simulation))
	var normal_command: Dictionary = _find_last_command(simulation.commands, leader.unit_id)
	var normal_token: String = String(normal_command.get("command_token", ""))
	var normal_speed: float = float(normal_command.get("move_speed_factor", 0.0))
	var normal_state: Dictionary = Dictionary(start_result.get("movement_state", {}))

	_assert(bool(start_result.get("started", false)), "Controller starts a normal active Move")
	_assert(int(normal_state.get("command_revision", -1)) == 0, "Initial Move starts with command revision 0")
	_assert(String(normal_command.get("movement_posture", "")) == "travel", "Initial normal Move uses travel posture")
	_assert(String(normal_command.get("weapon_posture", "")) == "lowered", "Initial normal Move keeps weapon lowered")

	var cautious_result: Dictionary = Dictionary(controller.call("update_tactical_stance", "drill", "cautious", [leader, wing], leader, simulation))
	var cautious_command: Dictionary = _find_last_command(simulation.commands, leader.unit_id)
	var cautious_runtime: Dictionary = Dictionary(leader.call("get_runtime_status").to_dict())
	var cautious_state: Dictionary = Dictionary(cautious_result.get("movement_state", {}))
	_assert(bool(cautious_result.get("updated", false)), "Live cautious update is accepted for an active Move")
	_assert(int(cautious_state.get("command_revision", 0)) > int(normal_state.get("command_revision", 0)), "Live cautious update advances command revision")
	_assert(String(cautious_command.get("command_token", "")) != normal_token, "Live cautious update emits a fresh command token")
	_assert(String(cautious_command.get("movement_posture", "")) == "engage", "Live cautious Move uses engage posture")
	_assert(String(cautious_command.get("weapon_posture", "")) == "aimed", "Live cautious Move keeps weapon aimed")
	_assert(_is_close_ratio(float(cautious_command.get("move_speed_factor", 0.0)), normal_speed, 0.65), "Live cautious Move applies -35 percent speed")
	_assert(is_equal_approx(float(cautious_command.get("sight_range_factor", 0.0)), 1.2), "Live cautious Move applies +20 percent sight")
	_assert(String(cautious_runtime.get("weapon_posture", "")) == "aimed", "Assigned runtime status carries live cautious aimed posture")

	var aggressive_result: Dictionary = Dictionary(controller.call("update_tactical_stance", "drill", "aggressive", [leader, wing], leader, simulation))
	var aggressive_command: Dictionary = _find_last_command(simulation.commands, leader.unit_id)
	var aggressive_state: Dictionary = Dictionary(aggressive_result.get("movement_state", {}))
	_assert(bool(aggressive_result.get("updated", false)), "Live aggressive update is accepted for an active Move")
	_assert(int(aggressive_state.get("command_revision", 0)) > int(cautious_state.get("command_revision", 0)), "Live aggressive update advances command revision again")
	_assert(String(aggressive_command.get("movement_posture", "")) == "run", "Live aggressive Move switches to run posture")
	_assert(String(aggressive_command.get("weapon_posture", "")) == "lowered", "Live aggressive Move lowers weapon")
	_assert(_is_close_ratio(float(aggressive_command.get("move_speed_factor", 0.0)), normal_speed, 1.2), "Live aggressive Move applies +20 percent speed")
	_assert(is_equal_approx(float(aggressive_command.get("sight_range_factor", 0.0)), 0.65), "Live aggressive Move applies -35 percent sight")

	var normal_result: Dictionary = Dictionary(controller.call("update_tactical_stance", "drill", "normal", [leader, wing], leader, simulation))
	var live_normal_command: Dictionary = _find_last_command(simulation.commands, leader.unit_id)
	_assert(bool(normal_result.get("updated", false)), "Live normal update is accepted for an active Move")
	_assert(String(live_normal_command.get("movement_posture", "")) == "travel", "Live normal Move returns to travel posture")
	_assert(String(live_normal_command.get("weapon_posture", "")) == "lowered", "Live normal Move keeps weapon lowered")
	_assert(_is_close_ratio(float(live_normal_command.get("move_speed_factor", 0.0)), normal_speed, 1.0), "Live normal Move restores baseline speed")
	_assert(is_equal_approx(float(live_normal_command.get("sight_range_factor", 0.0)), 1.0), "Live normal Move restores baseline sight")

	wing.queue_free()
	leader.queue_free()


func _test_drill_ui_live_stance_updates_active_move() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill scene exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var units: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "drill")
	_assert(units.size() == 4 and leader is Node2D, "Drill fireteam exposes four runtime members and a leader")
	if units.size() != 4 or not (leader is Node2D):
		scene.queue_free()
		await _wait_frames(2)
		return

	var target_position: Vector2 = (leader as Node2D).global_position + Vector2(260.0, -80.0)
	var profile = _make_profile("drill", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)
	profile.metadata = {
		"origin_command_type": "move",
		"rough_target_position": target_position,
	}
	controller.call("_set_active_behavior_profile", "drill", profile)
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = "wp_live_stance"
	waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE
	waypoint.target_position = target_position
	var issued: bool = bool(controller.call("_issue_waypoint_for_fireteam", "drill", waypoint, 1, profile))
	await _wait_frames(2)
	var initial_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	_assert(issued and not initial_state.is_empty(), "Drill scene starts an active Move execution")

	var cautious_applied: bool = bool(controller.call("set_fireteams_tactical_stance", PackedStringArray(["drill"]), "cautious"))
	await _wait_frames(2)
	var cautious_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	_assert(cautious_applied, "Drill UI applies cautious stance during active Move")
	_assert(String(cautious_state.get("tactical_stance", "")) == "cautious", "Active Move state stores live cautious stance")
	_assert(int(cautious_state.get("command_revision", 0)) > int(initial_state.get("command_revision", 0)), "Drill UI live stance advances command revision")
	_assert(_all_units_have_posture(units, "engage", "aimed"), "Drill UI cautious live update raises weapons into Aim")

	var aggressive_applied: bool = bool(controller.call("set_fireteams_tactical_stance", PackedStringArray(["drill"]), "aggressive"))
	await _wait_frames(2)
	var aggressive_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	_assert(aggressive_applied, "Drill UI applies aggressive stance during active Move")
	_assert(String(aggressive_state.get("tactical_stance", "")) == "aggressive", "Active Move state stores live aggressive stance")
	_assert(int(aggressive_state.get("command_revision", 0)) > int(cautious_state.get("command_revision", 0)), "Drill UI aggressive update advances command revision again")
	_assert(_all_units_have_posture(units, "run", "lowered"), "Drill UI aggressive live update switches to run/lowered")

	var normal_applied: bool = bool(controller.call("set_fireteams_tactical_stance", PackedStringArray(["drill"]), "normal"))
	await _wait_frames(2)
	_assert(normal_applied, "Drill UI applies normal stance during active Move")
	_assert(_all_units_have_posture(units, "travel", "lowered"), "Drill UI normal live update returns to travel/lowered")

	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var movement_text: String = _read_text(MOVEMENT_CONTROLLER_PATH)
	var sandbox_text: String = _read_text(SANDBOX_CONTROLLER_PATH)
	_assert(task_text.contains("TASK_425 - Live Move Stance Update"), "TASK_425 task file exists")
	_assert(status_text.contains("TASK_425 - Live Move Stance Update"), "Implementation status documents TASK_425")
	_assert(roadmap_text.contains("TASK_425 - Live Move Stance Update"), "Roadmap lists TASK_425")
	_assert(movement_text.contains("func update_tactical_stance"), "Movement controller exposes live stance update")
	_assert(movement_text.contains("command_revision"), "Movement controller tokens carry command revision")
	_assert(sandbox_text.contains("_apply_live_tactical_stance_to_fireteam"), "Mission controller forwards UI stance changes to active Move execution")


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


func _find_last_command(commands: Array, unit_id: String) -> Dictionary:
	for index in range(commands.size() - 1, -1, -1):
		var command: Dictionary = Dictionary(commands[index])
		if String(command.get("unit_id", "")) == unit_id:
			return command
	return {}


func _all_units_have_posture(units: Array, expected_movement_posture: String, expected_weapon_posture: String) -> bool:
	for unit in units:
		if unit == null or not unit.has_method("get_runtime_status"):
			return false
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status == null or not runtime_status.has_method("to_dict"):
			return false
		var runtime_dict: Dictionary = Dictionary(runtime_status.to_dict())
		if String(runtime_dict.get("movement_posture", "")) != expected_movement_posture:
			return false
		if String(runtime_dict.get("weapon_posture", "")) != expected_weapon_posture:
			return false
	return true


func _is_close_ratio(value: float, baseline: float, expected_ratio: float) -> bool:
	if baseline <= 0.0:
		return false
	return absf((value / baseline) - expected_ratio) <= 0.002


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
