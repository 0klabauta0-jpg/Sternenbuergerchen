extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SIMULATION = preload("res://scripts/core/simulation_root.gd")
const REGISTRY = preload("res://scripts/registries/unit_registry.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	# Catch a decision-scan throttle accidentally slowing simulation-time cooldowns.
	# Real SimulationRoot signal -> real driver tick handler; no cooldown helpers
	# are called by this test. Disabled automatic processing keeps the tick inputs exact.
	var fixture := Node2D.new()
	fixture.name = "CooldownCadenceFixture"
	fixture.process_mode = Node.PROCESS_MODE_DISABLED
	var simulation = SIMULATION.new()
	simulation.name = "SimulationRoot"
	var registry = REGISTRY.new()
	registry.name = "UnitRegistry"
	simulation.add_child(registry)
	simulation.unit_registry_path = NodePath("UnitRegistry")
	fixture.add_child(simulation)
	var friendly = _unit("Friendly", "friendly", "team_alpha", Vector2.ZERO)
	friendly.fireteam_id = "blue"
	var enemy = _unit("Enemy", "enemy", "team_beta", Vector2(10000.0, 10000.0))
	fixture.add_child(friendly)
	fixture.add_child(enemy)
	registry.register_unit("friendly", friendly)
	registry.register_unit("enemy", enemy)
	var driver = DRIVER.new()
	driver.name = "CombatDriver"
	driver.simulation_root_path = NodePath("../SimulationRoot")
	var friendly_paths: Array[NodePath] = [NodePath("../Friendly")]
	var enemy_paths: Array[NodePath] = [NodePath("../Enemy")]
	driver.friendly_unit_paths = friendly_paths
	driver.enemy_unit_paths = enemy_paths
	driver.preview_mode = true
	driver.enemy_advance_enabled = false
	driver.enemy_reposition_enabled = false
	driver.enemy_limbo_behavior_smoke_enabled = false
	driver.combat_tick_budget_debug_enabled = true
	fixture.add_child(driver)
	root.add_child(fixture)
	driver.set_combat_startup_grace_ticks(0)
	driver.set("_discipline_break_cooldown", {"prior_discipline_break": 10})
	driver.set("_misidentification_cooldown", {"prior_misidentification": 15})
	driver.set("_medic_support_cooldown", {"prior_medic_support": 12})
	driver.set("_recent_incoming_fire_tick_by_fireteam", {"blue": 0})
	_check(simulation.tick_processed.is_connected(Callable(driver, "_on_tick_processed")), "Normal simulation signal is connected to the real combat driver")
	var active_ticks: Array = []
	var skipped_ticks: Array = []
	for tick in range(1, 22):
		simulation.tick_processed.emit(tick)
		var state: String = String(driver.get_combat_tick_budget_debug_snapshot().get("state", ""))
		if state == "active":
			active_ticks.append(tick)
		elif state == "decision_cadence_skip":
			skipped_ticks.append(tick)
		match tick:
			1:
				_check(int(driver.get_discipline_break_cooldown().get("prior_discipline_break", 0)) == 9, "Discipline cooldown advances on the first non-decision simulation tick")
				_check(int(driver.get_misidentification_cooldown().get("prior_misidentification", 0)) == 14, "Misidentification cooldown advances on a non-decision tick")
				_check(int(driver.get_medic_support_cooldown().get("prior_medic_support", 0)) == 11, "Medic cooldown advances on a non-decision tick")
			9:
				_check(int(driver.get_discipline_break_cooldown().get("prior_discipline_break", 0)) == 1, "Discipline cooldown remains blocked through the tick before expiry")
			10:
				_check(not driver.get_discipline_break_cooldown().has("prior_discipline_break"), "Ten-tick discipline cooldown expires after ten simulation ticks")
			11:
				_check(int(driver.get_medic_support_cooldown().get("prior_medic_support", 0)) == 1, "Medic cooldown remains blocked immediately before its twelfth tick")
			12:
				_check(not driver.get_medic_support_cooldown().has("prior_medic_support"), "Twelve-tick medic cooldown expires on its twelfth simulation tick")
			14:
				_check(int(driver.get_misidentification_cooldown().get("prior_misidentification", 0)) == 1, "Misidentification cooldown remains blocked through tick fourteen")
			15:
				_check(not driver.get_misidentification_cooldown().has("prior_misidentification"), "Fifteen-tick misidentification cooldown expires on tick fifteen")
			18:
				_check(bool(driver.call("_can_unit_return_fire", friendly)), "Absolute return-fire window includes its eighteenth tick")
			19:
				_check(not bool(driver.call("_can_unit_return_fire", friendly)), "Absolute return-fire window closes at tick nineteen even between decision scans")
	_check(active_ticks == [3, 6, 9, 12, 15, 18, 21], "Expensive combat decisions retain their three-tick cadence")
	_check(skipped_ticks == [1, 2, 4, 5, 7, 8, 10, 11, 13, 14, 16, 17, 19, 20], "Other ticks still skip expensive combat decisions")
	_check(driver.get_discipline_break_cooldown().is_empty() and driver.get_misidentification_cooldown().is_empty() and driver.get_medic_support_cooldown().is_empty(), "Expired cooldown entries do not linger or become negative")
	_check(not driver.is_combat_finished(), "Both real units keep the fixture mission active")
	_check(simulation.command_queue.is_empty() and simulation.effects_queue.is_empty(), "Out-of-contact tick fixture causes no movement, damage or healing")
	driver.set("_medic_support_cooldown", {"paused_medic": 5})
	var previous_pause: bool = paused
	paused = true
	await process_frame
	await process_frame
	paused = previous_pause
	_check(int(driver.get_medic_support_cooldown().get("paused_medic", 0)) == 5, "Paused disabled fixture cannot consume cooldowns from rendered frames")
	_check(int(driver.get("_current_tick")) == 21 and simulation.tick_counter == 0, "Only the explicitly delivered simulation ticks reach the driver")
	fixture.free()
	await process_frame
	print("REVIEW_CYCLES_COOLDOWN_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _unit(node_name: String, unit_id: String, team_id: String, position: Vector2):
	var unit = UNIT.new()
	unit.name = node_name
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.position = position
	return unit


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		print("FAIL: " + message)
