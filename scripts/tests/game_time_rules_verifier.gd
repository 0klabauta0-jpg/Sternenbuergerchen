extends SceneTree
## G5b: Spielregeln rechnen in Spielzeit (Simulations-Ticks, 1 Tick = 1/60 s), nicht nach Wanduhr oder Bildzeit.
## Echter Controller, echte SimulationRoot, echter Gefechtstreiber (mission_reactivity_test.tscn); die Ticks setzt der Test
## von Hand (sim._physics_process), die Bilder ebenfalls (controller._process). Zwischen den Ticks wird nie gewartet.
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const HEX_MAP_DATA: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const HEX_REGISTRY: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const HEX_TILE: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX_UNITS: GDScript = preload("res://scripts/registries/unit_registry.gd")
const FIRETEAM_ID: String = "blue"
const TICK: float = 1.0 / 60.0
const ENEMY_NODES: Array[String] = ["EnemyDelta", "EnemyEcho"]

var _passed: int = 0
var _failed: int = 0


class StubTerrain:
	extends RefCounted

	func world_to_grid(world_pos: Vector2) -> Vector2i:
		return Vector2i(roundi(world_pos.x / 32.0), roundi(world_pos.y / 32.0))

	func is_walkable(_grid_pos: Vector2i) -> bool:
		return true


class StubUnit:
	extends Node

	func get_unit_id() -> String:
		return "stub_unit"

	func is_in_contact() -> bool:
		return true


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== game_time_rules_verifier ===")
	await _test_t1_soft_waypoint_completion()
	_test_t2_contact_path_recompute_lock()
	await _test_t3_mission_duration()
	await _test_t4_controller_timers_follow_ticks()
	await _test_t5_rules_read_tick_exact_positions()
	print("GAME_TIME_RULES passed=%d failed=%d" % [_passed, _failed])
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


func _step(sim: Node, ticks: int) -> void:
	for i in ticks:
		sim._physics_process(TICK)


func _keep_enemies_down(scene: Node) -> void:
	for node_name in ENEMY_NODES:
		var enemy: Node = scene.get_node(node_name)
		if String(enemy.call("get_vital_state")) == "fit":
			enemy.call("apply_damage", 9999)


func _start_take(scene: Node) -> bool:
	var controller: Node = scene.get_node("TacticalController")
	var target: Vector2 = scene.get_node("EnemyDelta").global_position
	controller.call("_set_selected_fireteams", PackedStringArray([FIRETEAM_ID]), false)
	controller.call("set_selected_fireteams_tactical_stance", "aggressive")
	if not bool(controller.call("issue_right_click_command_for_test", target, "take", false)):
		return false
	return bool(controller.call("execute_selected_fireteam_orders"))


## Weicher Wegpunkt-Abschluss: 2500 ms Spielzeit = 150 Ticks, auch wenn die Ticks ohne Wartezeit durchlaufen.
func _test_t1_soft_waypoint_completion() -> void:
	var scene: Node = await _open_scene()
	var sim: Node = scene.get_node("SimulationRoot")
	var controller: Node = scene.get_node("TacticalController")
	_check(controller.has_method("_game_now_msec"), "T1 Aufbau: der Controller hat die Spielzeit-Hilfsfunktion _game_now_msec")
	_step(sim, 1)
	var started: int = int(controller.call("_game_now_msec")) if controller.has_method("_game_now_msec") else Time.get_ticks_msec()
	var state: Dictionary = {"started_msec": started}
	_step(sim, 149)
	_check(not bool(controller.call("_is_phase_waypoint_soft_completion_allowed", state)), "T1 Nach 149 Ticks ist der weiche Abschluss noch nicht erlaubt")
	_step(sim, 1)
	_check(bool(controller.call("_is_phase_waypoint_soft_completion_allowed", state)), "T1 Nach 150 Ticks (2,5 s Spielzeit) ist der weiche Abschluss erlaubt")
	_keep_enemies_down(scene)
	_check(_start_take(scene), "T1 Aufbau: TAKE gestartet")
	var execution: Dictionary = Dictionary(Dictionary(controller.get("_phase_execution_by_fireteam")).get(FIRETEAM_ID, {}))
	var real_started: int = int(execution.get("started_msec", -1))
	_step(sim, 3)
	var elapsed_msec: int = int(controller.call("_game_now_msec")) - real_started if controller.has_method("_game_now_msec") else -1
	_check(real_started > 0 and elapsed_msec == 50, "T1 started_msec des echten Befehlsstands ist Spielzeit: 3 Ticks spaeter 50 ms (ist %d)" % elapsed_msec)
	await _close_scene(scene)


## Wegneuberechnung bei Feindkontakt: Sperre 600 ms Spielzeit = 36 Ticks, nicht Wanduhr.
func _test_t2_contact_path_recompute_lock() -> void:
	var sim: Node = SIMULATION_ROOT_SCRIPT.new()
	var unit: Node = StubUnit.new()
	var terrain := StubTerrain.new()
	sim.set("tick_counter", 100)
	var cmd: Dictionary = {"requeue_until_target": true}
	var far_path: Array = [Vector2(640.0, 0.0)]
	var same_path: Array = [Vector2(128.0, 0.0)]
	var target: Vector2 = Vector2(128.0, 0.0)
	var first: bool = bool(sim.call("_should_recompute_move_path", cmd, unit, far_path, Vector2.ZERO, target, terrain))
	_check(first, "T2 Aufbau: abweichendes Wegziel loest die Neuberechnung aus")
	var locked: Dictionary = sim.get("_contact_path_recompute_ready_at_msec")
	var now_msec: int = int(sim.call("get_game_msec")) if sim.has_method("get_game_msec") else -1
	_check(now_msec >= 0 and int(locked.get("stub_unit", -1)) - now_msec == 600, "T2 Sperre endet 600 ms Spielzeit nach dem Auslosen (Differenz %d)" % (int(locked.get("stub_unit", -1)) - now_msec))
	_check(not bool(sim.call("_should_recompute_move_path", cmd, unit, same_path, Vector2.ZERO, target, terrain)), "T2 Im selben Tick ist die Neuberechnung gesperrt")
	sim.set("tick_counter", 135)
	_check(not bool(sim.call("_should_recompute_move_path", cmd, unit, same_path, Vector2.ZERO, target, terrain)), "T2 Nach 35 Ticks (583 ms) noch gesperrt")
	sim.set("tick_counter", 136)
	_check(bool(sim.call("_should_recompute_move_path", cmd, unit, same_path, Vector2.ZERO, target, terrain)), "T2 Nach 36 Ticks (600 ms) wieder frei")
	unit.free()
	sim.free()


## Einsatzdauer: N Ticks = N/60 s plus gespeicherter Versatz.
func _test_t3_mission_duration() -> void:
	var scene: Node = await _open_scene()
	var sim: Node = scene.get_node("SimulationRoot")
	var driver: Node = scene.get_node("CombatLoopDriver")
	_check(bool(Dictionary(driver.call("restore_checkpoint_elapsed_time", 5000)).get("ok", false)), "T3 Aufbau: Versatz 5000 ms gesetzt")
	_step(sim, 120)
	var after_120: float = float(driver.call("_get_duration_seconds"))
	_check(absf(after_120 - 7.0) < 0.02, "T3 120 Ticks + 5 s Versatz = 7,00 s (ist %.3f)" % after_120)
	_step(sim, 60)
	var after_180: float = float(driver.call("_get_duration_seconds"))
	_check(absf(after_180 - 8.0) < 0.02, "T3 180 Ticks + 5 s Versatz = 8,00 s (ist %.3f)" % after_180)
	await _close_scene(scene)


func _geti(node: Node, property: String) -> int:
	var value: Variant = node.get(property)
	return int(value) if value != null else -1


## Ein Durchlauf: 120 Ticks von Hand, ein Bild je frame_ticks Ticks. Die Bildzeit (0,5 s je Bild) hat mit der Spielzeit nichts
## zu tun und darf die Zeitgeber nicht antreiben.
func _play_timers(frame_ticks: int) -> Dictionary:
	var scene: Node = await _open_scene()
	var sim: Node = scene.get_node("SimulationRoot")
	var controller: Node = scene.get_node("TacticalController")
	var refresh_before: int = _geti(controller, "_fireteam_security_refresh_count")
	controller.set("_drop_ship_cooldown_remaining", 10.0)
	controller.set("_selected_team_boarding_requests", {"gt_probe": {"craft_id": "gt_none", "elapsed": 0.0, "poll": 99.0}})
	for tick in range(1, 121):
		sim._physics_process(TICK)
		if tick % frame_ticks == 0:
			controller.call("_process", 0.5)
	var requests: Dictionary = controller.get("_selected_team_boarding_requests")
	var result: Dictionary = {
		"refreshes": _geti(controller, "_fireteam_security_refresh_count") - refresh_before,
		"cooldown": float(controller.get("_drop_ship_cooldown_remaining")),
		"boarding": float(Dictionary(requests.get("gt_probe", {})).get("elapsed", -1.0)),
	}
	controller.set("_selected_team_boarding_requests", {})
	await _close_scene(scene)
	return result


func _test_t4_controller_timers_follow_ticks() -> void:
	var a: Dictionary = await _play_timers(1)
	var b: Dictionary = await _play_timers(4)
	print("T4 A ", a, " B ", b)
	_check(int(a.refreshes) == 10 and int(b.refreshes) == 10, "T4 Sicherungs-Auffrischung genau einmal je 12 Ticks: 120 Ticks = 10 (A %d, B %d)" % [int(a.refreshes), int(b.refreshes)])
	_check(absf(float(a.cooldown) - 8.0) < 0.01 and absf(float(b.cooldown) - 8.0) < 0.01, "T4 Abkuehlzeit des Truppschiffs sinkt nach 120 Ticks um 2 s (A %.3f, B %.3f)" % [float(a.cooldown), float(b.cooldown)])
	_check(absf(float(a.boarding) - 2.0) < 0.01 and absf(float(b.boarding) - 2.0) < 0.01, "T4 Einsteige-Anfrage zaehlt 120 Ticks = 2 s (A %.3f, B %.3f)" % [float(a.boarding), float(b.boarding)])


## G5d: Bodeneinheit fuer die Lage-Probe. Merkt sich, welche global_position eine Regel beim Befehlsannehmen (mitten im Tick) sieht.
class ProbeActor:
	extends Node2D

	var unit_id: String = ""
	var current_command: RefCounted
	var target_position: Vector2 = Vector2.ZERO
	var vital_state: String = "fit"
	var health: int = 100
	var command_reads: Array = []

	func get_unit_id() -> String:
		return unit_id

	func get_team_id() -> String:
		return "blue"

	func get_vital_state() -> String:
		return vital_state

	func get_current_unit_command() -> RefCounted:
		return current_command

	func assign_unit_command(value: RefCounted) -> void:
		current_command = value
		command_reads.append(global_position)

	func set_target_position(value: Vector2) -> void:
		target_position = value

	func get_target_position() -> Vector2:
		return target_position

	func get_move_speed_factor() -> float:
		return 1.0

	func get_combat_speed_multiplier() -> float:
		return 1.0

	func refresh_terrain_readability() -> void:
		pass

	func get_health() -> int:
		return health

	func apply_damage(amount: int, _context: Dictionary = {}) -> bool:
		health = maxi(0, health - amount)
		return true


var _probe_signal_reads: Array = []
var _probe_sim: Node
var _probe_actor: Node2D


func _on_probe_tick(_tick: int) -> void:
	_probe_signal_reads.append(_probe_actor.global_position)


func _hex_move_command(target: Vector2, token: String) -> Dictionary:
	return {"type": "move_to_position", "unit_id": "a", "team_id": "blue", "target_position": target, "move_speed_factor": 1.0, "command_token": token, "requeue_until_target": true}


## Ein Lauf: 60 Ticks von Hand, nach je ticks_per_frame Ticks ein "Bild", das die Knoten wie SimulationRoot._process mit einem
## Bruchteil aus fractions vorschiebt. Bei Tick 20 und 40 kommt ein neuer Befehl (die Regel liest die Lage beim Annehmen).
func _run_hex_probe(ticks_per_frame: int, fractions: Array) -> Dictionary:
	var sim: Node = SIMULATION_ROOT_SCRIPT.new()
	root.add_child(sim)
	sim.set_physics_process(false)
	sim.set_process(false)
	var terrain: Node = HEX_REGISTRY.new()
	root.add_child(terrain)
	terrain.call("configure_iso_grid", Vector2.ZERO, 64, 32, "hex_axial_v1")
	for x in range(8):
		for y in range(2):
			terrain.call("register_tile", HEX_TILE.new({"tile_id": "%d_%d" % [x, y], "grid_position": Vector2i(x, y)}))
	var registry: Node = HEX_UNITS.new()
	root.add_child(registry)
	sim.set("unit_registry_path", sim.get_path_to(registry))
	sim.set("terrain_registry_path", sim.get_path_to(terrain))
	var map = HEX_MAP_DATA.create_empty("tick_exact_probe", Vector2i(8, 2), Vector2.ZERO, 64, 32, 3, "hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.call("configure_hex_ground_runtime", map, terrain)
	var actor := ProbeActor.new()
	actor.unit_id = "a"
	root.add_child(actor)
	actor.global_position = terrain.call("grid_to_world", Vector2i.ZERO)
	registry.call("register_unit", "a", actor)
	sim.call("register_known_unit", "a", actor)
	var batch: Array[Dictionary] = [{"unit_id": "a", "grid": Vector2i.ZERO}]
	sim.call("admit_hex_ground_units", batch)
	_probe_signal_reads = []
	_probe_sim = sim
	_probe_actor = actor
	sim.connect("tick_processed", Callable(self, "_on_probe_tick"))
	sim.call("enqueue_command", _hex_move_command(terrain.call("grid_to_world", Vector2i(7, 0)), "probe_1"))
	var frame: int = 0
	for tick in range(1, 61):
		if tick == 20 or tick == 40:
			sim.call("enqueue_command", _hex_move_command(terrain.call("grid_to_world", Vector2i(7 - (tick / 20), 1)), "probe_%d" % tick))
		sim._physics_process(TICK)
		if tick % ticks_per_frame == 0:
			sim.call("_project_hex_ground_actors", float(fractions[frame % fractions.size()]))
			frame += 1
	var exact: Vector2 = Dictionary(sim.call("get_hex_motion_projection", "a", 0.0)).get("position_world", Vector2.INF)
	var halfway: Vector2 = Dictionary(sim.call("get_hex_motion_projection", "a", 0.5)).get("position_world", Vector2.INF)
	var result: Dictionary = {"signal": _probe_signal_reads.duplicate(), "commands": actor.command_reads.duplicate(), "exact": exact, "halfway": halfway, "displayed": actor.global_position}
	actor.free()
	registry.free()
	terrain.free()
	sim.free()
	return result


## G5d: Regeln lesen im Tick die tickgenaue Lage, egal wie das Bild die Knoten zwischen den Ticks vorgeschoben hat.
func _test_t5_rules_read_tick_exact_positions() -> void:
	var a: Dictionary = await _run_hex_probe(1, [0.0])
	var b: Dictionary = await _run_hex_probe(1, [0.37, 0.81, 0.5])
	var c: Dictionary = await _run_hex_probe(4, [0.5, 0.13, 0.9])
	_check(Array(a.commands).size() == 3 and Array(b.commands).size() == 3 and Array(c.commands).size() == 3, "T5 Aufbau: je Lauf drei Befehle angenommen (A %d, B %d, C %d)" % [Array(a.commands).size(), Array(b.commands).size(), Array(c.commands).size()])
	_check(Array(a.signal).size() == 60 and Array(b.signal).size() == 60 and Array(c.signal).size() == 60, "T5 Aufbau: je Lauf 60 Tick-Rueckrufe")
	_check(Vector2(a.exact).distance_to(Vector2(a.signal.back())) < 0.001, "T5 Aufbau: im Tick-Rueckruf steht die Einheit auf ihrem Tickstand")
	_check(Array(a.signal) == Array(b.signal) and Array(a.signal) == Array(c.signal), "T5 Im Tick-Rueckruf gelesene Lage ist bei 1 Bild je Tick, 1 Bild je 4 Ticks und anderen Bruchteilen gleich")
	_check(Array(a.commands) == Array(b.commands) and Array(a.commands) == Array(c.commands), "T5 Beim Befehlsannehmen mitten im Tick gelesene Lage ist bei allen Bildtakten gleich (A %s, B %s, C %s)" % [str(a.commands), str(b.commands), str(c.commands)])
	_check(Vector2(c.halfway).distance_to(Vector2(c.exact)) > 0.001 and Vector2(c.displayed).distance_to(Vector2(c.exact)) > 0.001, "T5 Die Anzeige zwischen den Ticks bleibt interpoliert (Bildlage %s, Tickstand %s)" % [str(c.displayed), str(c.exact)])
