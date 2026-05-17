extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_466_fireteam_live_defend_contact_fire_damage.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_466 Fireteam Live Defend Contact Fire Damage ===")
	await _test_auto_defend_live_ticks_fire_and_damage_close_enemy()
	await _test_engage_live_ticks_fire_and_damage_close_enemy()
	await _test_mission_control_contact_diagnostics_visible()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_auto_defend_live_ticks_fire_and_damage_close_enemy() -> void:
	var scene: Node = await _make_ready_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_loop != null and simulation_root != null, "Live DEF test has controller, combat loop and simulation")
	if controller == null or combat_loop == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	var friendlies: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	_assert(friendlies.size() >= 4 and enemies.size() >= 1, "Live DEF test has four friendlies and an active enemy")
	if friendlies.is_empty() or enemies.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	var enemy := enemies[0] as Node2D
	enemy.global_position = Vector2(1280.0, 720.0)
	_prepare_contact_units(controller, "drill", enemy.global_position, Vector2.RIGHT)
	var initial_health: int = int(enemy.call("get_health")) if enemy.has_method("get_health") else 0
	if simulation_root.has_method("set_combat_rng_seed"):
		simulation_root.call("set_combat_rng_seed", 7)
	combat_loop.set("_next_attack_tick", 0)
	_assert(bool(controller.call("_apply_default_fireteam_behavior", "drill", 1)), "Auto DEF 360 command is issued for live contact")
	await _wait_physics_frames(8)

	var result: Dictionary = await _wait_for_live_friendly_fire_on_enemy(controller, combat_loop, enemy, initial_health, 180)
	_assert(String(result.get("reason", "")) == "fired", "Auto DEF 360 produces a fired diagnostic through live ticks: %s" % JSON.stringify(result))
	_assert(bool(result.get("fire_event_seen", false)), "Auto DEF 360 records a live fire event for muzzle/trace visuals")
	_assert(int(result.get("current_health", initial_health)) < initial_health, "Auto DEF 360 damage reaches the enemy through SimulationRoot")
	scene.queue_free()
	await _wait_frames(2)


func _test_engage_live_ticks_fire_and_damage_close_enemy() -> void:
	var scene: Node = await _make_ready_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_loop != null and simulation_root != null, "Live Engage test has controller, combat loop and simulation")
	if controller == null or combat_loop == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	var friendlies: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	_assert(friendlies.size() >= 4 and enemies.size() >= 1, "Live Engage test has four friendlies and an active enemy")
	if friendlies.is_empty() or enemies.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	var enemy := enemies[0] as Node2D
	enemy.global_position = Vector2(1280.0, 720.0)
	_prepare_contact_units(controller, "drill", enemy.global_position, Vector2.RIGHT)
	var initial_health: int = int(enemy.call("get_health")) if enemy.has_method("get_health") else 0
	if simulation_root.has_method("set_combat_rng_seed"):
		simulation_root.call("set_combat_rng_seed", 11)
	combat_loop.set("_next_attack_tick", 0)
	_assert(bool(controller.call("_apply_default_fireteam_behavior", "drill", 1)), "Auto DEF pre-state is applied before live Engage")
	await _wait_physics_frames(8)

	var plan = _make_plan("drill", 1, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE, enemy.global_position)
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	_assert(bool(controller.call("_activate_next_waypoint_for_plan", plan, "drill", 0)), "Live Engage command starts from Auto DEF pre-state")
	await _wait_physics_frames(8)

	var result: Dictionary = await _wait_for_live_friendly_fire_on_enemy(controller, combat_loop, enemy, initial_health, 190)
	_assert(String(result.get("reason", "")) == "fired", "Engage produces a fired diagnostic through live ticks: %s" % JSON.stringify(result))
	_assert(bool(result.get("fire_event_seen", false)), "Engage records a live fire event for muzzle/trace visuals")
	_assert(int(result.get("current_health", initial_health)) < initial_health, "Engage damage reaches the enemy through SimulationRoot")
	scene.queue_free()
	await _wait_frames(2)


func _test_mission_control_contact_diagnostics_visible() -> void:
	var scene: Node = await _make_ready_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_loop != null and simulation_root != null, "Mission Control diagnostic test has scene systems")
	if controller == null or combat_loop == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	if enemies.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return
	var enemy := enemies[0] as Node2D
	enemy.global_position = Vector2(1280.0, 720.0)
	_prepare_contact_units(controller, "drill", enemy.global_position, Vector2.RIGHT)
	combat_loop.set("_next_attack_tick", 0)
	_assert(bool(controller.call("_apply_default_fireteam_behavior", "drill", 1)), "Mission Control diagnostic test applies DEF contact setup")
	await _wait_physics_frames(45)
	controller.call("_update_ui")

	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var text: String = String(feedback.get("contact_decision_diagnostics_text", ""))
	var status_label_text: String = String(feedback.get("mission_control_status_text", ""))
	var strategic_label := controller.get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel") as Label
	_assert(not text.is_empty(), "Contact diagnostics text exists for Mission Control")
	_assert(not status_label_text.is_empty(), "Mission Control status text is populated")
	_assert(strategic_label != null and strategic_label.visible, "Mission Control status label remains visible in #18")
	scene.queue_free()
	await _wait_frames(2)


func _prepare_contact_units(controller: Node, fireteam_id: String, enemy_position: Vector2, forward: Vector2) -> void:
	_place_fireteam(controller, fireteam_id, enemy_position + Vector2(-74.0, 0.0), forward)
	for unit in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		if unit == null:
			continue
		if unit.has_method("set"):
			unit.set("skill_accuracy", 1.0)
		if unit.has_method("set_tactical_stance_indicator"):
			unit.call("set_tactical_stance_indicator", "cautious", 1)


func _wait_for_live_friendly_fire_on_enemy(controller: Node, combat_loop: Node, enemy: Node2D, initial_health: int, max_physics_frames: int) -> Dictionary:
	var fire_event_seen: bool = false
	var last_diagnostics: Dictionary = {}
	var last_friendly_fire_diagnostics: Dictionary = {}
	var enemy_id: String = String(enemy.call("get_unit_id")) if enemy != null and enemy.has_method("get_unit_id") else ""
	for _i in range(max_physics_frames):
		await _wait_physics_frames(1)
		controller.call("_update_ui")
		var fire_events: Array = Array(combat_loop.call("get_fire_event_snapshot"))
		if not fire_events.is_empty():
			fire_event_seen = true
		last_diagnostics = Dictionary(combat_loop.call("get_contact_decision_diagnostics_snapshot"))
		var current_health: int = int(enemy.call("get_health")) if enemy != null and enemy.has_method("get_health") else initial_health
		var friendly_fired_on_enemy: bool = (
			String(last_diagnostics.get("reason", "")) == "fired"
			and String(last_diagnostics.get("attacker_team_id", "")) == "team_alpha"
			and String(last_diagnostics.get("target_unit_id", "")) == enemy_id
		)
		if friendly_fired_on_enemy:
			last_friendly_fire_diagnostics = last_diagnostics.duplicate(true)
		if current_health < initial_health and (friendly_fired_on_enemy or not last_friendly_fire_diagnostics.is_empty()):
			var result: Dictionary = last_diagnostics if friendly_fired_on_enemy else last_friendly_fire_diagnostics
			result["fire_event_seen"] = fire_event_seen
			result["current_health"] = current_health
			return result
	last_diagnostics["fire_event_seen"] = fire_event_seen
	last_diagnostics["current_health"] = int(enemy.call("get_health")) if enemy != null and enemy.has_method("get_health") else initial_health
	return last_diagnostics


func _make_ready_scene():
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(90)
	var setup := scene.get_node_or_null("MissionSetup")
	if setup != null and setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	await _wait_frames(8)
	return scene


func _make_plan(fireteam_id: String, phase: int, command_type: String, target_position: Vector2):
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "task466_%s_p%d_%s" % [fireteam_id, phase, command_type]
	plan.fireteam_id = fireteam_id
	plan.phase = phase
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING
	plan.active_waypoint_index = -1
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = "wp_0"
	waypoint.command_type = command_type
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
	waypoint.target_position = target_position
	plan.waypoints.append(waypoint)
	return plan


func _place_fireteam(controller: Node, fireteam_id: String, center: Vector2, forward: Vector2) -> void:
	var units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	units.sort_custom(func(a, b) -> bool:
		return String(a.call("get_unit_id")) < String(b.call("get_unit_id"))
	)
	var safe_forward: Vector2 = forward.normalized() if forward.length_squared() > 0.001 else Vector2.RIGHT
	var lateral: Vector2 = safe_forward.orthogonal()
	var offsets: Array[Vector2] = [
		Vector2.ZERO,
		lateral * 42.0,
		-safe_forward * 48.0,
		-safe_forward * 48.0 + lateral * 42.0,
	]
	for index in range(mini(units.size(), offsets.size())):
		var unit = units[index]
		if unit is Node2D:
			(unit as Node2D).global_position = center + offsets[index]


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_466 - Fireteam Live Defend Contact Fire Damage"), "TASK_466 task file exists")
	_assert(status_text.contains("TASK_466 - Fireteam Live Defend Contact Fire Damage"), "Implementation status documents TASK_466")
	_assert(roadmap_text.contains("TASK_466 - Fireteam Live Defend Contact Fire Damage"), "Roadmap lists TASK_466")
	_assert(contract_text.contains("TASK_466 Live-Kontaktfeuer/Damage"), "Behavior contract documents TASK_466")


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame


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
