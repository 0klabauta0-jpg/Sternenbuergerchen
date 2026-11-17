extends SceneTree

# Ein Wegpunkt-TAKE gilt als erfuellt, wenn im Umkreis seines Ziels kein kampffaehiger
# Gegner mehr steht, kein Gegnerkontakt besteht und der Truppfuehrer nah genug am Ziel ist.
# Dann endet der Befehl und der naechste eingereihte Wegpunkt wird aktiv (D6).

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const FIRETEAM_ID: String = "blue"
const TAKE_CLEAR_RADIUS_WORLD: float = 256.0
const ARRIVAL_SLACK_WORLD: float = 20.0
const ENEMY_NODES: Array[String] = ["EnemyDelta", "EnemyEcho"]
const BLUE_NODES: Array[String] = ["UnitAlpha", "UnitBravo", "UnitDelta", "UnitGolf", "UnitHotel"]

var _passed: int = 0
var _failed: int = 0
var _last_leader_distance: float = INF


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== mission_take_order_completes_when_clear_verifier ===")
	Engine.time_scale = 4.0
	await _test_take_ends_after_fight_and_march_follows()
	await _test_queued_waypoint_activates_after_take()
	await _test_take_on_empty_point_ends_only_near_target()
	await _test_hold_time_and_go_with_queued_waypoint()
	Engine.time_scale = 1.0
	print("mission_take_order_completes_when_clear_verifier passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _open_scene() -> Node:
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	for i in 10:
		await process_frame
	return scene


func _close_scene(scene: Node) -> void:
	scene.queue_free()
	for i in 3:
		await process_frame


func _controller(scene: Node) -> Node:
	return scene.get_node("TacticalController")


func _wait_game(seconds: float) -> void:
	await create_timer(seconds).timeout


func _leader(scene: Node) -> Node2D:
	return _controller(scene).call("_resolve_fireteam_leader_for_behavior", FIRETEAM_ID) as Node2D


func _keep_enemies_down(scene: Node) -> void:
	for node_name in ENEMY_NODES:
		var enemy: Node = scene.get_node(node_name)
		if String(enemy.call("get_vital_state")) == "fit":
			enemy.call("apply_damage", 9999)


func _living_enemy_count(scene: Node) -> int:
	var count: int = 0
	for node_name in ENEMY_NODES:
		if String(scene.get_node(node_name).call("get_vital_state")) == "fit":
			count += 1
	return count


func _waypoint_active(scene: Node, command_type: String) -> bool:
	for plan_variant in Array(_controller(scene).call("get_order_plans_snapshot")):
		var plan: Dictionary = plan_variant
		if String(plan.get("fireteam_id", "")) != FIRETEAM_ID:
			continue
		for waypoint_variant in Array(plan.get("waypoints", [])):
			var waypoint: Dictionary = waypoint_variant
			if String(waypoint.get("command_type", "")) == command_type and String(waypoint.get("status", "")) == "active":
				return true
	return false


func _members_waiting_reservation(scene: Node) -> Array:
	var simulation: Node = scene.get_node("SimulationRoot")
	var waiting: Array = []
	for node_name in BLUE_NODES:
		var unit: Node = scene.get_node(node_name)
		var readout: Dictionary = simulation.call("get_hex_movement_readout", String(unit.call("get_unit_id")))
		if String(readout.get("status", "")) == "waiting_reservation":
			waiting.append(node_name)
	return waiting


func _start_take(scene: Node, target: Vector2) -> bool:
	var controller: Node = _controller(scene)
	controller.call("_set_selected_fireteams", PackedStringArray([FIRETEAM_ID]), false)
	controller.call("set_selected_fireteams_tactical_stance", "aggressive")
	if not bool(controller.call("issue_right_click_command_for_test", target, "take", false)):
		return false
	return bool(controller.call("execute_selected_fireteam_orders"))


# Wartet bis der Truppfuehrer innerhalb von max_distance steht. Haelt Gegner optional nieder.
func _march_until_near(scene: Node, target: Vector2, max_distance: float, max_game_seconds: float, keep_enemies_down: bool = false) -> bool:
	var waited: float = 0.0
	while waited < max_game_seconds:
		await _wait_game(0.5)
		waited += 0.5
		if keep_enemies_down:
			_keep_enemies_down(scene)
		var leader := _leader(scene)
		if leader != null:
			_last_leader_distance = leader.global_position.distance_to(target)
		if leader != null and _last_leader_distance <= max_distance:
			return true
	return false


func _wait_take_ended(scene: Node, keep_enemies_down: bool, max_game_seconds: float) -> bool:
	var waited: float = 0.0
	while waited < max_game_seconds:
		await _wait_game(0.5)
		waited += 0.5
		if keep_enemies_down:
			_keep_enemies_down(scene)
		if not _waypoint_active(scene, "take"):
			return true
	return false


func _test_take_ends_after_fight_and_march_follows() -> void:
	var scene: Node = await _open_scene()
	var target: Vector2 = scene.get_node("EnemyDelta").global_position
	_assert(_start_take(scene, target), "TAKE on the enemy position is accepted and started with GO")
	_assert(await _march_until_near(scene, target, TAKE_CLEAR_RADIUS_WORLD - 30.0, 60.0), "Leader reaches the take area")
	# Gegenprobe a: a living enemy inside the radius keeps the TAKE active.
	await _wait_game(3.0)
	_assert(_living_enemy_count(scene) > 0, "Enemies are still alive inside the take area (precondition)")
	_assert(_waypoint_active(scene, "take"), "TAKE stays active while an enemy lives inside its radius")
	# Fight won.
	_keep_enemies_down(scene)
	_assert(_living_enemy_count(scene) == 0, "All defenders are down")
	_assert(await _wait_take_ended(scene, true, 10.0), "TAKE ends within seconds once the area is clear and the leader stands near")
	var reservation_waited: float = 0.0
	while reservation_waited < 3.0 and not _members_waiting_reservation(scene).is_empty():
		await _wait_game(0.5)
		reservation_waited += 0.5
		_keep_enemies_down(scene)
	_assert(_members_waiting_reservation(scene).is_empty(), "No member stays in waiting_reservation after the TAKE ended: %s" % [_members_waiting_reservation(scene)])
	# Follow-up march must work (this is the case that failed with the stuck TAKE).
	var controller: Node = _controller(scene)
	var march_target := Vector2(-305.0, 568.0)
	var leader := _leader(scene)
	var start_distance: float = leader.global_position.distance_to(march_target) if leader != null else 0.0
	controller.call("_set_selected_fireteams", PackedStringArray([FIRETEAM_ID]), false)
	_assert(bool(controller.call("issue_right_click_command_for_test", march_target, "move", false)), "Waypoint for the follow-up march is created")
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "GO for the follow-up march is accepted")
	var departed: bool = false
	var waited: float = 0.0
	while waited < 6.0:
		await _wait_game(0.5)
		waited += 0.5
		_keep_enemies_down(scene)
		leader = _leader(scene)
		if leader != null and leader.global_position.distance_to(march_target) < start_distance - 80.0:
			departed = true
			break
	_assert(departed, "Squad leader sets off toward the follow-up target after the TAKE")
	var arrived: bool = await _march_until_near(scene, march_target, 200.0, 60.0, true)
	_assert(arrived, "Squad arrives at the follow-up target (leader %.0f away, waiting: %s)" % [_last_leader_distance, _members_waiting_reservation(scene)])
	await _close_scene(scene)


func _test_queued_waypoint_activates_after_take() -> void:
	var scene: Node = await _open_scene()
	var controller: Node = _controller(scene)
	var target: Vector2 = scene.get_node("EnemyDelta").global_position
	_assert(_start_take(scene, target), "TAKE is started before a waypoint is queued behind it")
	var queued_target := Vector2(-305.0, 568.0)
	_assert(bool(controller.call("issue_right_click_command_for_test", queued_target, "move", true)), "A move waypoint is queued behind the active TAKE")
	_assert(await _march_until_near(scene, target, TAKE_CLEAR_RADIUS_WORLD - 30.0, 60.0), "Leader reaches the take area with a waypoint queued")
	_assert(_waypoint_active(scene, "take") and not _waypoint_active(scene, "move"), "Queued waypoint waits behind the TAKE while enemies live")
	_keep_enemies_down(scene)
	_assert(await _wait_take_ended(scene, true, 10.0), "TAKE ends after the fight")
	var became_active: bool = false
	var waited: float = 0.0
	while waited < 5.0:
		if _waypoint_active(scene, "move"):
			became_active = true
			break
		await _wait_game(0.5)
		waited += 0.5
		_keep_enemies_down(scene)
	_assert(became_active, "The queued waypoint becomes active by itself after the TAKE")
	var arrived: bool = await _march_until_near(scene, queued_target, 200.0, 60.0, true)
	_assert(arrived, "Squad marches to the queued waypoint (leader %.0f away, waiting: %s)" % [_last_leader_distance, _members_waiting_reservation(scene)])
	await _close_scene(scene)


func _test_take_on_empty_point_ends_only_near_target() -> void:
	var scene: Node = await _open_scene()
	var target: Vector2 = scene.get_node("EnemyDelta").global_position
	_keep_enemies_down(scene)
	_assert(_start_take(scene, target), "TAKE on an empty point is accepted")
	var controller: Node = _controller(scene)
	var constants: Dictionary = controller.get_script().get_script_constant_map()
	var anchor_radius: float = float(constants["PHASE_WAYPOINT_COMPLETE_RADIUS"])
	var center_radius: float = float(constants["PHASE_WAYPOINT_SOFT_CENTER_REACHED_RADIUS"])
	var ended: bool = false
	var anchor_distance: float = INF
	var center_near: bool = false
	var leader_distance_at_end: float = INF
	var waited: float = 0.0
	while waited < 70.0:
		await _wait_game(0.25)
		waited += 0.25
		_keep_enemies_down(scene)
		if not _waypoint_active(scene, "take"):
			ended = true
			var leader := _leader(scene)
			leader_distance_at_end = leader.global_position.distance_to(target) if leader != null else INF
			var anchor := controller.call("_get_selection_anchor_for_fireteam", FIRETEAM_ID) as Node2D
			anchor_distance = anchor.global_position.distance_to(target) if anchor != null else INF
			center_near = bool(controller.call("_is_fireteam_center_near_position", FIRETEAM_ID, target, center_radius + ARRIVAL_SLACK_WORLD))
			break
	_assert(ended, "TAKE on an empty point does end once the squad has arrived")
	# Never contested, nothing jams: only the normal arrival rule (anchor <= 26 or centre <= 48, plus a little movement between polls) may end it.
	_assert(anchor_distance <= anchor_radius + ARRIVAL_SLACK_WORLD or center_near, "TAKE on an empty point ends only on arrival (anchor %.0f, centre near: %s, leader %.0f away)" % [anchor_distance, center_near, leader_distance_at_end])
	await _close_scene(scene)


# Haltezeit und GO: the controller clock is stepped by hand (set_process(false) + _process(delta)) so the 2 s hold can be observed exactly.
func _test_hold_time_and_go_with_queued_waypoint() -> void:
	var scene: Node = await _open_scene()
	var controller: Node = _controller(scene)
	var target: Vector2 = scene.get_node("EnemyDelta").global_position
	_assert(_start_take(scene, target), "Hold test: TAKE started")
	_assert(bool(controller.call("issue_right_click_command_for_test", Vector2(-305.0, 568.0), "move", true)), "Hold test: waypoint queued behind the TAKE")
	_assert(await _march_until_near(scene, target, TAKE_CLEAR_RADIUS_WORLD - 30.0, 60.0), "Hold test: leader reaches the take area")
	await _wait_game(1.5)
	controller.set_process(false)
	_keep_enemies_down(scene)
	_assert(_waypoint_active(scene, "take"), "Hold test: TAKE still active right after the last defender fell")
	controller.call("_process", 0.5)
	controller.call("_process", 0.5)
	_assert(_waypoint_active(scene, "take"), "Hold test: after 1 s of clear area the TAKE is still active")
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "Hold test: GO before the hold time is over is accepted")
	_assert(_waypoint_active(scene, "take") and not _waypoint_active(scene, "move"), "Hold test: that GO does not end the TAKE and starts no march")
	controller.call("_process", 0.5)
	_assert(_waypoint_active(scene, "take"), "Hold test: after 1.5 s the TAKE is still active")
	controller.call("_process", 0.5)
	_assert(not _waypoint_active(scene, "take") and _waypoint_active(scene, "move"), "Hold test: after more than 2 s the TAKE ended and the queued waypoint is active")
	controller.set_process(true)
	await _close_scene(scene)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		print("FAIL: %s" % message)
