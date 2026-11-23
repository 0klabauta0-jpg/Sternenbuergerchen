extends SceneTree
## G3: die Wartezeiten der Gegnerbewegung im Gefechtstreiber zaehlen in Spiel-Ticks,
## nicht in Wanduhr-Millisekunden. Echter Treiber (mission_combat_loop_driver.gd) mit
## kleinen Attrappen fuer Einheit, SimulationRoot und Gelaende; die Ticks setzt der Test
## direkt (_current_tick), so wie _on_tick_processed es je Physik-Tick tut.
## Normale Tickrate: Engine.physics_ticks_per_second = 60 (project.godot setzt nichts anderes).
const DRIVER_SCRIPT := preload("res://scripts/tests/mission_combat_loop_driver.gd")
const REPOSITION_COOLDOWN_TICKS := 240 # 4.0 s * 60
const LIMBO_COVER_COOLDOWN_TICKS := 120 # 2.0 s * 60
const START_TICK := 100

class StubUnit:
	extends Node2D
	var uid: String = "enemy_1"
	func get_unit_id() -> String: return uid
	func get_team_id() -> String: return "team_enemy"
	func get_vital_state() -> String: return "fit"
	func get_effective_cover_score() -> int: return 0

class StubSim:
	extends Node
	var commands: Array = []
	func enqueue_command(command: Dictionary) -> void:
		commands.append(command)

class StubTile:
	extends RefCounted
	var world_position: Vector2 = Vector2(100, 0)
	var cover_value: int = 80

class StubTerrain:
	extends Node
	var with_cover: bool = true
	func get_walkable_cover_tiles_in_radius(_position: Vector2, _radius: float) -> Array:
		return [StubTile.new()] if with_cover else []

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_a_reposition_released_by_ticks()
	_test_b_no_wall_clock_in_enemy_movement_functions()
	_test_c_limbo_cover_wait_counts_ticks()
	_test_d_same_tick_sequence_same_result()
	_test_e_defaults_are_the_old_seconds_at_normal_rate()
	_test_k3_stale_entries_after_tick_reset()
	print("enemy_movement_game_time_verifier passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
	else:
		_failed += 1
		print("FAIL ", label)


func _rig() -> Dictionary:
	var scene := Node.new()
	root.add_child(scene)
	var sim := StubSim.new()
	sim.name = "Sim"
	scene.add_child(sim)
	var terrain := StubTerrain.new()
	terrain.name = "Terrain"
	scene.add_child(terrain)
	var unit := StubUnit.new()
	unit.name = "Enemy1"
	scene.add_child(unit)
	var driver: Node = DRIVER_SCRIPT.new()
	driver.name = "Driver"
	scene.add_child(driver)
	driver.set("simulation_root_path", driver.get_path_to(sim))
	driver.set("terrain_registry_path", driver.get_path_to(terrain))
	driver.set("_hotpath_unit_cache_active", true)
	driver.set("_hotpath_enemy_units", [unit])
	driver.set("_current_tick", START_TICK)
	return {"scene": scene, "sim": sim, "unit": unit, "driver": driver}


func _hit(rig: Dictionary, tick: int) -> void:
	rig.driver.set("_current_tick", tick)
	rig.driver.call("_try_reposition_enemy_on_damage", rig.unit, {"attacker_unit_id": "friend_1"})


func _test_a_reposition_released_by_ticks() -> void:
	var rig := _rig()
	_hit(rig, START_TICK)
	_check(rig.sim.commands.size() == 1, "a: erster Treffer loest ein Ausweichen aus")
	_hit(rig, START_TICK)
	_check(rig.sim.commands.size() == 1, "a: im selben Tick gesperrt")
	_hit(rig, START_TICK + REPOSITION_COOLDOWN_TICKS - 1)
	_check(rig.sim.commands.size() == 1, "a: einen Tick vor Ablauf noch gesperrt")
	_hit(rig, START_TICK + REPOSITION_COOLDOWN_TICKS)
	_check(rig.sim.commands.size() == 2, "a: nach genau der Abkuehlzeit in Ticks (ohne Wanduhrzeit) wieder erlaubt")
	rig.scene.free()


func _source_of(script: GDScript) -> String:
	return script.source_code


func _body_of(source: String, func_name: String) -> String:
	var start: int = source.find("\nfunc %s(" % func_name)
	if start < 0:
		return ""
	var end: int = source.find("\nfunc ", start + 6)
	return source.substr(start, (end if end > 0 else source.length()) - start)


# Waechter gegen Rueckfall: die Funktionen der Gegnerbewegung duerfen keine Wanduhr lesen.
func _test_b_no_wall_clock_in_enemy_movement_functions() -> void:
	var source: String = _source_of(DRIVER_SCRIPT)
	for name in ["_try_reposition_enemy_on_damage", "_enemy_limbo_should_seek_cover", "_try_enqueue_enemy_limbo_cover_move", "_enemy_reposition_on_cooldown", "_enemy_limbo_cover_on_cooldown", "_tick_cooldown_active", "_build_enemy_reposition_target"]:
		var body := _body_of(source, name)
		_check(not body.is_empty() and not body.contains("get_ticks_msec"), "b: %s ohne Wanduhr" % name)


func _test_c_limbo_cover_wait_counts_ticks() -> void:
	var rig := _rig()
	var driver: Node = rig.driver
	_check(bool(driver.call("_enemy_limbo_should_seek_cover", rig.unit, true, "enemy_1")), "c: ohne vorherige Deckungssuche ist sie erlaubt")
	_check(bool(driver.call("_try_enqueue_enemy_limbo_cover_move", rig.sim, rig.unit)), "c: Deckungsbefehl wird abgesetzt")
	_check(not bool(driver.call("_enemy_limbo_should_seek_cover", rig.unit, true, "enemy_1")), "c: direkt danach gesperrt")
	for _i in range(5):
		OS.delay_msec(30)
	_check(not bool(driver.call("_enemy_limbo_should_seek_cover", rig.unit, true, "enemy_1")), "c: Wanduhrzeit allein gibt nicht frei")
	driver.set("_current_tick", START_TICK + LIMBO_COVER_COOLDOWN_TICKS - 1)
	_check(not bool(driver.call("_enemy_limbo_should_seek_cover", rig.unit, true, "enemy_1")), "c: einen Tick vor Ablauf gesperrt")
	driver.set("_current_tick", START_TICK + LIMBO_COVER_COOLDOWN_TICKS)
	_check(bool(driver.call("_enemy_limbo_should_seek_cover", rig.unit, true, "enemy_1")), "c: nach genau der Abkuehlzeit in Ticks wieder erlaubt")
	rig.scene.free()


func _run_sequence(with_cover: bool = true) -> Array:
	var rig := _rig()
	rig.scene.get_node("Terrain").with_cover = with_cover
	var seen: Array = []
	for tick in [100, 120, 339, 340, 345, 580, 581, 600]:
		var before: int = rig.sim.commands.size()
		_hit(rig, tick)
		if rig.sim.commands.size() > before:
			var command: Dictionary = rig.sim.commands[rig.sim.commands.size() - 1]
			seen.append([tick, Vector2(command.get("target_position", Vector2.ZERO))])
	rig.scene.free()
	return seen


func _test_d_same_tick_sequence_same_result() -> void:
	var first := _run_sequence()
	OS.delay_msec(40) # anderer Wanduhrstand beim zweiten Durchlauf
	var second := _run_sequence()
	_check(first.size() == 3, "d: Ticks 100/340/600 loesen aus, die dazwischen nicht (%d Ausloesungen)" % first.size())
	_check(first == second, "d: zwei Durchlaeufe derselben Tickfolge geben dieselben Ziele zu denselben Ticks")
	# Ohne Deckungsfelder waehlt der Treiber das Ziel aus einem Hash ueber den Tick (Fallback-Zweig):
	# gleiche Tickfolge -> gleiche Ziele, andere Ticks -> andere Ziele (Tick geht wirklich in die Zielwahl ein).
	var hash_first := _run_sequence(false)
	var hash_second := _run_sequence(false)
	_check(hash_first.size() == 3 and hash_first == hash_second, "d: Hash-Zweig, gleiche Tickfolge gibt gleiche Ziele")
	_check(hash_first.size() == 3 and hash_first[0][1] != hash_first[1][1] and hash_first[1][1] != hash_first[2][1], "d: Hash-Zweig, die Ziele haengen vom Tick ab")


func _test_e_defaults_are_the_old_seconds_at_normal_rate() -> void:
	var driver: Node = DRIVER_SCRIPT.new()
	_check(driver.get("enemy_reposition_cooldown_ticks") == REPOSITION_COOLDOWN_TICKS, "e: Ausweich-Abkuehlzeit = 4 s * 60 = 240 Ticks")
	_check(driver.get("enemy_limbo_cover_cooldown_ticks") == LIMBO_COVER_COOLDOWN_TICKS, "e: Deckungs-Abkuehlzeit = 2 s * 60 = 120 Ticks")
	_check(Engine.physics_ticks_per_second == 60, "e: die Tick-Konstanten gelten bei 60 Ticks/s")
	driver.free()


# K3: Tickzaehler springt zurueck (Laden eines Zwischenstands): ein alter Eintrag sperrt nie laenger als die
# Abkuehlzeit und entsperrt nie zu frueh; der Neustart des Einsatzes leert die Eintraege.
func _test_k3_stale_entries_after_tick_reset() -> void:
	var rig := _rig()
	var driver: Node = rig.driver
	driver.set("_current_tick", 100)
	driver.get("_enemy_reposition_ready_at_tick")["enemy_1"] = 1000
	_check(not bool(driver.call("_enemy_reposition_on_cooldown", "enemy_1")), "k3: Eintrag weit in der Zukunft (Zaehler zurueckgesetzt) gilt als abgelaufen")
	driver.set("_current_tick", 800)
	_check(bool(driver.call("_enemy_reposition_on_cooldown", "enemy_1")), "k3: Eintrag 200 Ticks voraus (innerhalb der Abkuehlzeit) sperrt weiter")
	driver.set("_current_tick", 1000)
	_check(not bool(driver.call("_enemy_reposition_on_cooldown", "enemy_1")), "k3: Eintrag erreicht - frei")
	driver.get("_enemy_reposition_ready_at_tick")["enemy_1"] = 1200
	driver.get("_enemy_limbo_cover_ready_at_tick")["enemy_1"] = 1200
	driver.get("_friendly_cover_ready_at_tick")["unit_1"] = 1200
	var result: Dictionary = driver.call("restore_checkpoint_elapsed_time", 5000)
	_check(bool(result.get("ok", false)), "k3: Wiederherstellen der Missionszeit gelingt")
	_check(Dictionary(driver.get("_enemy_reposition_ready_at_tick")).is_empty() and Dictionary(driver.get("_enemy_limbo_cover_ready_at_tick")).is_empty() and Dictionary(driver.get("_friendly_cover_ready_at_tick")).is_empty(), "k3: Laden leert alle Abkuehl-Eintraege")
	rig.scene.free()
