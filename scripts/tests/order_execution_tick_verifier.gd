extends SceneTree
## G5a: Die Befehlsausfuehrung der Trupps laeuft je Simulations-Tick (Signal tick_processed), nicht je gezeichnetem Bild.
## Echter Controller, echte SimulationRoot und echter Gefechtstreiber (mission_reactivity_test.tscn); die Ticks setzt der
## Test von Hand (sim._physics_process), die Bilder ebenfalls (controller._process). Wanduhr und Bildrate spielen keine Rolle.
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const FIRETEAM_ID: String = "blue"
const TICK: float = 1.0 / 60.0
const TOTAL_TICKS: int = 2400
const CLEAR_TICK: int = 1000
const ENEMY_NODES: Array[String] = ["EnemyDelta", "EnemyEcho"]
const BLUE_NODES: Array[String] = ["UnitAlpha", "UnitBravo", "UnitDelta", "UnitGolf", "UnitHotel"]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== order_execution_tick_verifier ===")
	await _test_t1_t2_same_result_at_other_frame_rate()
	await _test_t3_t5_t6_single_execution_pause_order()
	await _test_t4_fallback_without_simulation()
	print("ORDER_EXECUTION_TICK passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)


func _open_scene() -> Node:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	# Sofort anhalten, bevor ein echter Physik-Tick oder ein echtes Bild laeuft: ab hier setzt nur der Test die Zeit.
	scene.get_node("SimulationRoot").set_physics_process(false)
	scene.get_node("TacticalController").set_process(false)
	for i in 10:
		await process_frame
	return scene


func _close_scene(scene: Node) -> void:
	scene.queue_free()
	for i in 3:
		await process_frame


func _keep_enemies_down(scene: Node) -> void:
	for node_name in ENEMY_NODES:
		var enemy: Node = scene.get_node(node_name)
		if String(enemy.call("get_vital_state")) == "fit":
			enemy.call("apply_damage", 9999)


func _waypoint_active(scene: Node, command_type: String) -> bool:
	for plan_variant in Array(scene.get_node("TacticalController").call("get_order_plans_snapshot")):
		var plan: Dictionary = plan_variant
		if String(plan.get("fireteam_id", "")) != FIRETEAM_ID:
			continue
		for waypoint_variant in Array(plan.get("waypoints", [])):
			var waypoint: Dictionary = waypoint_variant
			if String(waypoint.get("command_type", "")) == command_type and String(waypoint.get("status", "")) == "active":
				return true
	return false


func _start_take(scene: Node) -> bool:
	var controller: Node = scene.get_node("TacticalController")
	var target: Vector2 = scene.get_node("EnemyDelta").global_position
	controller.call("_set_selected_fireteams", PackedStringArray([FIRETEAM_ID]), false)
	controller.call("set_selected_fireteams_tactical_stance", "aggressive")
	if not bool(controller.call("issue_right_click_command_for_test", target, "take", false)):
		return false
	return bool(controller.call("execute_selected_fireteam_orders"))


func _geti(node: Node, property: String) -> int:
	var value: Variant = node.get(property)
	return int(value) if value != null else -1


func _elapsed(scene: Node) -> float:
	var states: Dictionary = scene.get_node("TacticalController").get("_phase_execution_by_fireteam")
	return float(Dictionary(states.get(FIRETEAM_ID, {})).get("take_clear_elapsed", 0.0))


func _unit_fields(scene: Node) -> Array:
	var fields: Array = []
	for node_name in BLUE_NODES:
		var unit: Node2D = scene.get_node(node_name)
		fields.append("%s@%.2f,%.2f/%s" % [node_name, unit.global_position.x, unit.global_position.y, String(unit.call("get_vital_state"))])
	return fields


## Ein Durchlauf: TOTAL_TICKS Ticks von Hand, ein Bild je frame_ticks Ticks (Bild-Delta = die verstrichene Zeit).
func _play(frame_ticks: int, frame_phase: int = 0) -> Dictionary:
	var scene: Node = await _open_scene()
	var sim: Node = scene.get_node("SimulationRoot")
	var controller: Node = scene.get_node("TacticalController")
	var started: bool = _start_take(scene)
	var end_tick: int = -1
	var seen_active: bool = false
	var elapsed_by_tick: Array = [0.0]
	for tick in range(1, TOTAL_TICKS + 1):
		sim._physics_process(TICK)
		if (tick + frame_phase) % frame_ticks == 0:
			controller.call("_process", TICK * float(frame_ticks))
		# Die Gegner stehen im Zielkreis (umkaempft), bis die Einheiten angekommen sind; dann werden sie von Hand
		# niedergehalten. Damit entscheidet die Haltezeit (2 s freier Kreis) ueber den Abschluss des TAKE.
		if tick >= CLEAR_TICK and tick % 30 == 0:
			_keep_enemies_down(scene)
		elapsed_by_tick.append(_elapsed(scene))
		var active: bool = _waypoint_active(scene, "take")
		seen_active = seen_active or active
		if seen_active and end_tick < 0 and not active:
			end_tick = tick
	var result: Dictionary = {"started": started, "seen_active": seen_active, "end_tick": end_tick, "fields": _unit_fields(scene), "elapsed": elapsed_by_tick}
	await _close_scene(scene)
	return result


func _test_t1_t2_same_result_at_other_frame_rate() -> void:
	var a: Dictionary = await _play(1)
	var a2: Dictionary = await _play(1)
	var b: Dictionary = await _play(4, 1)
	print("T1 A  end_tick=%d fields=%s" % [a.end_tick, a.fields])
	print("T1 A2 end_tick=%d fields=%s" % [a2.end_tick, a2.fields])
	print("T1 B  end_tick=%d fields=%s" % [b.end_tick, b.fields])
	_check(bool(a.started) and bool(a.seen_active), "T1 Aufbau: TAKE wird gestartet und ist aktiv")
	_check(int(a.end_tick) > 0, "T1 Aufbau: der TAKE schliesst innerhalb von %d Ticks ab (Tick %d)" % [TOTAL_TICKS, int(a.end_tick)])
	_check(int(a.end_tick) == int(a2.end_tick) and a.fields == a2.fields, "T1 Kontrolle: derselbe Bildtakt zweimal gibt dasselbe Ergebnis (Aufbau ist wiederholbar)")
	_check(int(a.end_tick) == int(b.end_tick), "T1 Abschluss-Tick gleich bei 1 Bild je Tick (%d) und 1 Bild je 4 Ticks (%d)" % [int(a.end_tick), int(b.end_tick)])
	_check(a.fields == b.fields, "T1 Endfelder der Einheiten gleich bei beiden Bildtakten")
	var first: int = -1
	var elapsed_a: Array = a.elapsed
	for tick in range(elapsed_a.size()):
		if float(elapsed_a[tick]) > 0.0:
			first = tick
			break
	var probe: int = first + 60
	var ok_probe: bool = first > 0 and probe < elapsed_a.size()
	var value_a: float = float(elapsed_a[probe]) if ok_probe else -1.0
	var value_b: float = float(b.elapsed[probe]) if ok_probe else -2.0
	print("T2 Haltezeit: erster Tick mit Zaehler=%d, Tick %d: A=%.6f B=%.6f" % [first, probe, value_a, value_b])
	_check(ok_probe and absf(value_a - 61.0 * TICK) < 0.0001, "T2 Haltezeit zaehlt in Spielzeit: 61 Ticks = %.4f s (A: %.4f)" % [61.0 * TICK, value_a])
	_check(ok_probe and absf(value_b - 61.0 * TICK) < 0.0001, "T2 gleiche Haltezeit nach gleichen 61 Ticks bei 1 Bild je 4 Ticks (B: %.4f)" % value_b)


func _test_t3_t5_t6_single_execution_pause_order() -> void:
	var scene: Node = await _open_scene()
	var sim: Node = scene.get_node("SimulationRoot")
	var controller: Node = scene.get_node("TacticalController")
	_keep_enemies_down(scene)
	_check(_start_take(scene), "T3 Aufbau: TAKE gestartet")
	_check(controller.has_method("_on_simulation_tick_for_orders"), "T3 Aufbau: der Tick-Einstieg _on_simulation_tick_for_orders existiert")
	var before: int = _geti(controller, "_order_execution_step_count")
	sim._physics_process(TICK)
	controller.call("_process", TICK)
	_check(_geti(controller, "_order_execution_step_count") == before + 1, "T3 Tick und Bild im selben Durchlauf: die sechs Aufrufe liefen genau einmal")
	before = _geti(controller, "_order_execution_step_count")
	for i in 5:
		controller.call("_process", 0.5)
	_check(_geti(controller, "_order_execution_step_count") == before, "T5 Ohne Tick (Pause) kein Befehlsfortschritt trotz 5 Bildern")
	var elapsed_before: float = _elapsed(scene)
	controller.call("_process", 2.0)
	_check(is_equal_approx(_elapsed(scene), elapsed_before), "T5 Haltezeit bleibt ohne Tick stehen")
	sim._physics_process(TICK)
	_check(_geti(controller, "_order_step_driver_tick_seen") == int(sim.get("tick_counter")), "T6 Reihenfolge: der Gefechtstreiber hat den Tick schon gerechnet, wenn die Befehle laufen (Treiber-Tick %d, Sim-Tick %d)" % [_geti(controller, "_order_step_driver_tick_seen"), int(sim.get("tick_counter"))])
	var driver: Node = scene.get_node("CombatLoopDriver")
	var order: Array = []
	for connection in sim.tick_processed.get_connections():
		order.append(Callable(connection["callable"]).get_object())
	var driver_index: int = order.find(driver)
	var controller_index: int = order.find(controller)
	_check(driver_index >= 0 and controller_index > driver_index, "T6 Anschluss-Reihenfolge am Signal: Treiber (%d) vor Controller (%d)" % [driver_index, controller_index])
	await _close_scene(scene)


func _test_t4_fallback_without_simulation() -> void:
	var scene: Node = await _open_scene()
	var controller: Node = scene.get_node("TacticalController")
	_keep_enemies_down(scene)
	_check(_start_take(scene), "T4 Aufbau: TAKE gestartet")
	scene.get_node("SimulationRoot").name = "SimulationRootAbgehaengt"
	var before: int = _geti(controller, "_order_execution_step_count")
	for i in 3:
		controller.call("_process", 0.25)
	_check(_geti(controller, "_order_execution_step_count") == before + 3, "T4 Ohne tickende Simulation fuehrt _process die Befehle je Bild weiter aus")
	await _close_scene(scene)
