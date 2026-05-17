extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_458_fireteam_contact_decision_diagnostics.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_458 Fireteam Contact Decision Diagnostics ===")
	_test_runtime_records_fired_and_cooldown_diagnostics()
	_test_runtime_records_no_pair_candidate_diagnostics()
	await _test_mission_control_snapshot_exposes_contact_diagnostics()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_runtime_records_fired_and_cooldown_diagnostics() -> void:
	var driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	var simulation := SimulationStub.new()
	simulation.name = "SimulationStub"
	root.add_child(simulation)
	driver.simulation_root_path = NodePath("../SimulationStub")
	root.add_child(driver)
	var friendly = _make_unit("task458_alpha", "team_alpha", "drill", Vector2(100.0, 100.0))
	var enemy = _make_unit("task458_enemy", "team_bravo", "enemy", Vector2(164.0, 100.0))
	root.add_child(friendly)
	root.add_child(enemy)
	friendly.call("assign_unit_command", UNIT_COMMAND_SCRIPT.new({
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA,
		"target_position": enemy.global_position,
		"fire_status": UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL,
		"aim_readiness_percent": 75.0,
	}))
	var friendly_paths: Array[NodePath] = [driver.get_path_to(friendly)]
	var enemy_paths: Array[NodePath] = [driver.get_path_to(enemy)]
	driver.friendly_unit_paths = friendly_paths
	driver.enemy_unit_paths = enemy_paths
	driver.set("_current_tick", 50)
	driver.set("_next_attack_tick", 0)
	driver.set("_detection_progress", {"task458_alpha:task458_enemy": 0})
	driver.call("_try_enqueue_attacks", simulation)
	var fired_snapshot: Dictionary = Dictionary(driver.call("get_contact_decision_diagnostics_snapshot"))
	_assert(String(fired_snapshot.get("reason", "")) == "fired", "Runtime diagnostic records a fired decision")
	_assert(String(fired_snapshot.get("attacker_unit_id", "")) == "task458_alpha", "Fired diagnostic names attacker")
	_assert(String(fired_snapshot.get("target_unit_id", "")) == "task458_enemy", "Fired diagnostic names target")
	_assert(String(fired_snapshot.get("weapon_id", "")) == "rifle", "Fired diagnostic names weapon")
	_assert(not String(fired_snapshot.get("fire_event_id", "")).is_empty(), "Fired diagnostic links muzzle/fire event")
	_assert(simulation.effects.size() == 1, "Fired diagnostic corresponds to one enqueued damage effect")
	driver.call("_try_enqueue_attacks", simulation)
	var cooldown_snapshot: Dictionary = Dictionary(driver.call("get_contact_decision_diagnostics_snapshot"))
	_assert(String(cooldown_snapshot.get("reason", "")) == "cooldown", "Runtime diagnostic records cooldown when contact exists but weapon waits")
	_assert(int(cooldown_snapshot.get("cooldown_ticks_remaining", 0)) > 0, "Cooldown diagnostic exposes remaining ticks")
	_cleanup_nodes([driver, simulation, friendly, enemy])


func _test_runtime_records_no_pair_candidate_diagnostics() -> void:
	var driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	var simulation := SimulationStub.new()
	simulation.name = "SimulationStub"
	root.add_child(simulation)
	driver.simulation_root_path = NodePath("../SimulationStub")
	root.add_child(driver)
	var friendly = _make_unit("task458_idle_alpha", "team_alpha", "drill", Vector2(200.0, 200.0))
	var enemy = _make_unit("task458_idle_enemy", "team_bravo", "enemy", Vector2(264.0, 200.0))
	root.add_child(friendly)
	root.add_child(enemy)
	var friendly_paths: Array[NodePath] = [driver.get_path_to(friendly)]
	var enemy_paths: Array[NodePath] = [driver.get_path_to(enemy)]
	driver.friendly_unit_paths = friendly_paths
	driver.enemy_unit_paths = enemy_paths
	driver.call("_try_enqueue_attacks", simulation)
	var snapshot: Dictionary = Dictionary(driver.call("get_contact_decision_diagnostics_snapshot"))
	var candidate: Dictionary = Dictionary(snapshot.get("candidate", {}))
	_assert(String(snapshot.get("reason", "")) == "no_contact_pair", "Runtime diagnostic records missing contact pair")
	_assert(String(candidate.get("candidate_reason", "")) == "attacker_not_engage_ready", "No-pair diagnostic explains idle attacker")
	_assert(int(snapshot.get("active_enemy_count", 0)) == 1, "No-pair diagnostic exposes active enemy count")
	_cleanup_nodes([driver, simulation, friendly, enemy])


func _test_mission_control_snapshot_exposes_contact_diagnostics() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(80)
	var setup := scene.get_node_or_null("MissionSetup")
	var controller := scene.get_node_or_null("TacticalController")
	var combat_loop := scene.get_node_or_null("CombatLoopDriver")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_assert(setup != null and controller != null and combat_loop != null and simulation_root != null, "Drill scene exposes controller, combat loop and simulation root")
	if setup == null or controller == null or combat_loop == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	if setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var friendlies: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	_assert(not friendlies.is_empty() and not enemies.is_empty(), "Drill scene has friendly and enemy units for diagnostic snapshot")
	if friendlies.is_empty() or enemies.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return
	var friendly := friendlies[0] as Node2D
	var enemy := enemies[0] as Node2D
	friendly.global_position = Vector2(960.0, 540.0)
	enemy.global_position = friendly.global_position + Vector2(64.0, 0.0)
	friendly.call("set_runtime_status", "holding", "hold_position", 30, "fire_at_will", "defend", 1.0, 0.0, 0.0, 1, friendly.global_position, "engage", "aimed", "task458_diag", 1.0, 75.0)
	var friendly_id: String = String(friendly.call("get_unit_id"))
	var enemy_id: String = String(enemy.call("get_unit_id"))
	combat_loop.set("_detection_progress", {"%s:%s" % [friendly_id, enemy_id]: 0})
	combat_loop.set("_current_tick", 80)
	combat_loop.set("_next_attack_tick", 0)
	combat_loop.call("_try_enqueue_attacks", simulation_root)
	controller.call("_update_ui")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var diagnostic: Dictionary = Dictionary(feedback.get("contact_decision_diagnostics", {}))
	_assert(String(diagnostic.get("reason", "")) == "fired", "Command feedback snapshot exposes fired contact diagnostic")
	_assert(String(feedback.get("contact_decision_diagnostics_text", "")).contains("CONTACT FIRE"), "Command feedback snapshot exposes readable contact diagnostic text")
	_assert(String(feedback.get("mission_control_status_text", "")).contains("CONTACT FIRE"), "Mission Control status label shows contact diagnostic text")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_458 - Fireteam Contact Decision Diagnostics"), "TASK_458 task file exists")
	_assert(status_text.contains("TASK_458 - Fireteam Contact Decision Diagnostics"), "Implementation status documents TASK_458")
	_assert(roadmap_text.contains("TASK_458 - Fireteam Contact Decision Diagnostics"), "Roadmap lists TASK_458")
	_assert(contract_text.contains("TASK_458 Contact-Decision-Diagnose"), "Behavior contract documents TASK_458 diagnostics")


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, position_value: Vector2):
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.global_position = position_value
	unit.skill_speed = 0.5
	unit.skill_toughness = 0.5
	unit.skill_accuracy = 0.5
	unit.weapon_1_id = "rifle"
	unit._ready()
	return unit


func _cleanup_nodes(nodes: Array) -> void:
	for node_variant in nodes:
		if node_variant is Node:
			var node := node_variant as Node
			if node.is_inside_tree():
				node.queue_free()
			else:
				node.free()


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("  FAIL: %s" % message)


class SimulationStub:
	extends Node
	signal tick_processed(tick: int)

	var effects: Array = []

	func enqueue_effect(effect: Dictionary) -> void:
		effects.append(effect.duplicate(true))
