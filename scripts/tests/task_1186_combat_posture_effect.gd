extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const COMBAT_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1186 Combat Posture Effect ===")
	await _test_enemy_facing_and_posture_commit_through_root_effect()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_enemy_facing_and_posture_commit_through_root_effect() -> void:
	var context: Dictionary = await _make_context()
	var simulation_root: Node = context["simulation_root"]
	var driver: Node = context["driver"]
	var attacker: Node2D = context["attacker"]
	var target: Node2D = context["target"]
	driver.call("_store_combat_attacker_facing", attacker, target)
	_assert(not attacker.has_meta("facing_angle"), "Combat producer does not set facing before the root tick")
	var before_status = attacker.call("get_runtime_status")
	_assert(String(before_status.get("movement_posture")) != "engage", "Combat producer does not set enemy posture before the root tick")
	_assert(simulation_root.effects_queue.size() == 1, "Combat producer enqueues exactly one posture effect")
	simulation_root.call("_physics_process", 0.1)
	_assert(attacker.has_meta("facing_angle"), "SimulationRoot commits combat facing")
	_assert(is_equal_approx(float(attacker.get_meta("facing_angle")), 0.0), "Committed facing points from attacker to target")
	var committed_status = attacker.call("get_runtime_status")
	_assert(String(committed_status.get("movement_posture")) == "engage", "SimulationRoot commits enemy movement posture")
	_assert(String(committed_status.get("weapon_posture")) == "aimed", "SimulationRoot commits enemy weapon posture")
	_assert(simulation_root.effects_queue.is_empty(), "Posture effect is applied exactly once")
	_cleanup_context(context)


func _make_context() -> Dictionary:
	var scene := Node.new()
	scene.name = "Task1186CombatPosture"
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	scene.add_child(simulation_root)
	var attacker: Node2D = TEST_UNIT_SCRIPT.new()
	attacker.name = "Enemy"
	attacker.unit_id = "enemy_alpha"
	attacker.team_id = "team_bravo"
	attacker.global_position = Vector2.ZERO
	scene.add_child(attacker)
	var target: Node2D = TEST_UNIT_SCRIPT.new()
	target.name = "Friendly"
	target.unit_id = "friendly_alpha"
	target.team_id = "team_alpha"
	target.global_position = Vector2(64.0, 0.0)
	scene.add_child(target)
	unit_registry.call("register_unit", "enemy_alpha", attacker)
	unit_registry.call("register_unit", "friendly_alpha", target)
	simulation_root.call("register_known_unit", "enemy_alpha", attacker)
	simulation_root.call("register_known_unit", "friendly_alpha", target)
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "team_alpha"
	driver.simulation_root_path = NodePath("../SimulationRoot")
	scene.add_child(driver)
	await process_frame
	return {"scene": scene, "simulation_root": simulation_root, "driver": driver, "attacker": attacker, "target": target}


func _cleanup_context(context: Dictionary) -> void:
	var scene: Node = context.get("scene", null)
	if scene != null:
		scene.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
