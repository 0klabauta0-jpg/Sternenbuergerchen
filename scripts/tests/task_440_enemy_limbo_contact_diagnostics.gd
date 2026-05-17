extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_440_enemy_limbo_contact_diagnostics.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

const ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_limbo_behavior_adapter.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends Node

	signal tick_processed(tick_number: int, tick_delta: float)

	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_440 Enemy Limbo Contact Diagnostics ===")
	_test_adapter_reports_decision_reasons()
	_test_driver_records_contact_hold_decision()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_adapter_reports_decision_reasons() -> void:
	var adapter = ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT.new()
	var agent := Node2D.new()
	root.add_child(agent)

	var calls: Array = []
	var cover_result: Dictionary = Dictionary(
		adapter.call(
			"evaluate",
			agent,
			{
				"unit_id": "diag_cover_enemy",
				"should_seek_cover": true,
				"has_contact": true,
				"has_patrol": true,
				"cover_score": 0,
				"seek_cover_action": Callable(self, "_record_action").bind(calls, "cover"),
				"contact_hold_action": Callable(self, "_record_action").bind(calls, "contact"),
				"patrol_action": Callable(self, "_record_action").bind(calls, "patrol"),
			},
			root,
			0.016
		)
	)
	_assert(String(cover_result.get("selected_action", "")) == "seek_cover", "Adapter selects cover when cover branch is valid")
	_assert(String(cover_result.get("reason", "")) == ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT.REASON_SEEK_COVER, "Adapter reports cover decision reason")
	_assert(bool(cover_result.get("has_contact", false)), "Adapter echoes contact flag for diagnostics")

	var fail_result: Dictionary = Dictionary(
		adapter.call(
			"evaluate",
			agent,
			{
				"unit_id": "diag_idle_enemy",
				"should_seek_cover": false,
				"has_contact": false,
				"has_patrol": false,
				"seek_cover_action": Callable(self, "_record_action").bind(calls, "cover_fail"),
				"contact_hold_action": Callable(self, "_record_action").bind(calls, "contact_fail"),
				"patrol_action": Callable(self, "_record_action").bind(calls, "patrol_fail"),
			},
			root,
			0.016
		)
	)
	_assert(not bool(fail_result.get("handled", true)), "Adapter leaves no-branch context unhandled")
	_assert(String(fail_result.get("reason", "")) == "no_contact_no_patrol", "Adapter explains no-branch context")
	agent.queue_free()


func _test_driver_records_contact_hold_decision() -> void:
	var context: Dictionary = _make_driver_context()
	var driver: Node = context["driver"]
	var simulation: Node = context["simulation"]
	var enemy: Node = context["enemy"]

	_assert(bool(driver.call("_try_enqueue_enemy_limbo_behavior", simulation, enemy)), "Driver handles visible enemy contact through Limbo")
	var command: Dictionary = _last_command(simulation)
	_assert(String(command.get("command_type", "")) == "hold_position", "Contact Limbo action emits hold_position")
	_assert(String(command.get("fire_status", "")) == "fire_at_will", "Contact hold command explicitly keeps fire_at_will")
	_assert(String(command.get("enemy_bt_reason", "")) == ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT.REASON_CONTACT_HOLD, "Contact command carries BT reason")
	_assert(String(enemy.get_meta("enemy_limbo_behavior_reason", "")) == ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT.REASON_CONTACT_HOLD, "Enemy meta carries Limbo reason for snapshots")

	var snapshot: Dictionary = Dictionary(driver.call("get_enemy_limbo_behavior_snapshot"))
	var decisions: Array = Array(snapshot.get("decisions", []))
	_assert(int(snapshot.get("decision_count", 0)) == 1, "Driver snapshot records one Limbo decision")
	_assert(decisions.size() == 1 and String(Dictionary(decisions[0]).get("selected_action", "")) == "contact_hold", "Decision snapshot records selected action")
	_assert(decisions.size() == 1 and bool(Dictionary(decisions[0]).get("has_contact", false)), "Decision snapshot records contact flag")
	_cleanup_context(context)


func _make_driver_context() -> Dictionary:
	var harness := Node.new()
	harness.name = "Task440Harness"
	root.add_child(harness)

	var simulation := SimulationStub.new()
	simulation.name = "SimulationRoot"
	harness.add_child(simulation)

	var friendly := _make_unit("task440_friendly", "team_alpha", Vector2(96.0, 0.0))
	var enemy := _make_unit("task440_enemy", "team_bravo", Vector2.ZERO)
	harness.add_child(friendly)
	harness.add_child(enemy)

	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "team_alpha"
	driver.preview_mode = true
	driver.enemy_limbo_behavior_smoke_enabled = true
	driver.enemy_limbo_cover_min_cover_score = 20
	var friendly_paths: Array[NodePath] = [NodePath("../task440_friendly")]
	var enemy_paths: Array[NodePath] = [NodePath("../task440_enemy")]
	driver.friendly_unit_paths = friendly_paths
	driver.enemy_unit_paths = enemy_paths
	driver.simulation_root_path = NodePath("../SimulationRoot")
	harness.add_child(driver)

	return {
		"harness": harness,
		"driver": driver,
		"simulation": simulation,
		"friendly": friendly,
		"enemy": enemy,
	}


func _make_unit(unit_id: String, team_id: String, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
	unit.fireteam_id = "blue" if team_id == "team_alpha" else "red"
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "rifle"
	unit.skill_accuracy = 0.62
	unit.skill_speed = 0.54
	unit.skill_leadership = 0.35
	unit.skill_toughness = 0.5
	unit.global_position = position_value
	unit._ready()
	return unit


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("Enemy Limbo Contact Diagnostics"), "Task file documents the diagnostic slice")
	_assert(status_text.contains("TASK_440"), "Implementation status mentions TASK_440")
	_assert(roadmap_text.contains("TASK_440"), "Task roadmap includes TASK_440")


func _record_action(out: Array, action_id: String) -> bool:
	out.append(action_id)
	return true


func _last_command(simulation: Node) -> Dictionary:
	var commands: Array = Array(simulation.get("commands"))
	if commands.is_empty():
		return {}
	return Dictionary(commands[commands.size() - 1])


func _cleanup_context(context: Dictionary) -> void:
	var harness: Node = context.get("harness", null)
	if harness != null:
		harness.queue_free()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
