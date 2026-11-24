extends SceneTree
## G3b: Wartezeiten des Gefechts, die den Ausgang bestimmen, zaehlen in Spiel-Ticks (60 je Sekunde),
## nicht in Wanduhr-Millisekunden: Liege-/Verblutungszeit, Deckungs-Abkuehlzeit eigener Einheiten,
## Haltezeit der Zielzone, Richtungswechsel und Suchwinkel der Sicherung. Die Ticks setzt der Test
## direkt (_current_tick), wie _on_tick_processed es je Physik-Tick tut.
const DRIVER_SCRIPT := preload("res://scripts/tests/mission_combat_loop_driver.gd")
const SECURITY_SCRIPT := preload("res://scripts/tactical/fireteam_security_controller.gd")
const STAGES := preload("res://scripts/combat/bleedout_stages.gd")
const START_TICK := 1000

class StubUnit:
	extends Node2D
	var uid: String = "unit_1"
	var team: String = "team_alpha"
	var vital: String = "down"
	func get_unit_id() -> String: return uid
	func get_team_id() -> String: return team
	func get_vital_state() -> String: return vital

class StubObjective:
	extends RefCounted
	var owning_team_id: String = "team_alpha"
	var capture_progress: float = 1.0

class StubSim:
	extends Node
	var objective := StubObjective.new()
	func get_objective_status():
		return objective
	func enqueue_command(_command: Dictionary) -> void:
		pass

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_rate_is_sixty()
	_test_down_linger_default()
	_test_down_linger_campaign_window()
	_test_friendly_cover_cooldown()
	_test_objective_hold()
	_test_security_shift_delay_and_scan()
	_test_no_wall_clock_in_converted_functions()
	print("combat_game_time_verifier passed=%d failed=%d" % [_passed, _failed])
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
	var driver: Node = DRIVER_SCRIPT.new()
	driver.name = "Driver"
	scene.add_child(driver)
	driver.set("simulation_root_path", driver.get_path_to(sim))
	driver.set("_current_tick", START_TICK)
	return {"scene": scene, "sim": sim, "driver": driver}


func _wall_wait() -> void:
	for _i in range(5):
		OS.delay_msec(30)


func _test_rate_is_sixty() -> void:
	_check(Engine.physics_ticks_per_second == 60, "Tickrate: die Tick-Konstanten gelten bei 60 Ticks/s")


func _test_down_linger_default() -> void:
	var rig := _rig()
	var driver: Node = rig.driver
	var unit := StubUnit.new()
	rig.scene.add_child(unit)
	_check(not bool(driver.call("_has_down_state_linger_elapsed", "unit_1", unit)), "Liegen: erster Aufruf startet nur die Frist")
	_wall_wait()
	_check(not bool(driver.call("_has_down_state_linger_elapsed", "unit_1", unit)), "Liegen: Wanduhrzeit allein beendet die Frist nicht")
	# Verbluten in Stufen (24.11.2026): 180 Ticks (3 s) sind NICHT mehr die ganze Wartezeit. Die erste Stufe gilt bei 180 s
	# = 10800 Ticks; Wurf zustandslos aus Seed (hier 0: der Stub hat keinen combat_rng_seed), Kennung und Stufe.
	var stage_list: Array = STAGES.stages()
	driver.set("_current_tick", START_TICK + 180)
	_check(not bool(driver.call("_has_down_state_linger_elapsed", "unit_1", unit)), "Liegen: nach 180 Ticks (3 s) liegt die Person noch (frueher: fertig)")
	driver.set("_current_tick", START_TICK + 10799)
	_check(not bool(driver.call("_has_down_state_linger_elapsed", "unit_1", unit)), "Liegen: 10799 Ticks (180 s - 1) noch keine Stufe")
	driver.set("_current_tick", START_TICK + 10800)
	_check(bool(driver.call("_has_down_state_linger_elapsed", "unit_1", unit)) == STAGES.stage_hits(stage_list, 0, 0, "unit_1", START_TICK), "Liegen: bei 10800 Ticks (180 s) wird Stufe 1 ausgewertet, ohne Wanduhrzeit (Ergebnis = zustandsloser Wurf)")
	driver.set("_current_tick", START_TICK + 23400)
	_check(bool(driver.call("_has_down_state_linger_elapsed", "unit_1", unit)), "Liegen: bei 23400 Ticks (390 s) verblutet jede Person sicher")
	rig.scene.free()


func _test_down_linger_campaign_window() -> void:
	var rig := _rig()
	var driver: Node = rig.driver
	driver.set("campaign_casualty_rules_enabled", true)
	driver.set("down_revive_window_seconds", 5.0)
	var unit := StubUnit.new()
	rig.scene.add_child(unit)
	driver.call("_has_down_state_linger_elapsed", "unit_1", unit)
	# Das Aufricht-Fenster der Kampagne (down_revive_window_seconds) steuert das Verbluten nicht mehr: dieselben Stufen wie ueberall.
	driver.set("_current_tick", START_TICK + 299)
	_check(not bool(driver.call("_has_down_state_linger_elapsed", "unit_1", unit)), "Kampagne: 299 Ticks noch nicht")
	driver.set("_current_tick", START_TICK + 300)
	_check(not bool(driver.call("_has_down_state_linger_elapsed", "unit_1", unit)), "Kampagne: das Fenster von 5 s (300 Ticks) beendet das Liegen nicht mehr")
	driver.set("_current_tick", START_TICK + 23400)
	_check(bool(driver.call("_has_down_state_linger_elapsed", "unit_1", unit)), "Kampagne: bei 23400 Ticks (390 s) verblutet sie sicher")
	rig.scene.free()


func _test_friendly_cover_cooldown() -> void:
	var rig := _rig()
	var driver: Node = rig.driver
	_check(driver.get("FRIENDLY_STANDARD_COVER_COOLDOWN_TICKS") == 96, "Eigene Deckungs-Abkuehlzeit: 1600 ms = 96 Ticks")
	_check(not bool(driver.call("_friendly_cover_on_cooldown", "unit_1")), "Eigene Deckung: anfangs frei")
	driver.call("_arm_friendly_cover_cooldown", "unit_1")
	_wall_wait()
	_check(bool(driver.call("_friendly_cover_on_cooldown", "unit_1")), "Eigene Deckung: Wanduhrzeit gibt nicht frei")
	driver.set("_current_tick", START_TICK + 95)
	_check(bool(driver.call("_friendly_cover_on_cooldown", "unit_1")), "Eigene Deckung: 95 Ticks noch gesperrt")
	driver.set("_current_tick", START_TICK + 96)
	_check(not bool(driver.call("_friendly_cover_on_cooldown", "unit_1")), "Eigene Deckung: nach 96 Ticks frei")
	rig.scene.free()


func _test_objective_hold() -> void:
	var rig := _rig()
	var driver: Node = rig.driver
	driver.set("win_condition", "objective_defense")
	driver.call("_update_objective_hold_tracking")
	_wall_wait()
	_check(is_equal_approx(float(driver.call("_get_objective_defense_elapsed_seconds")), 0.0), "Haltezeit: ohne Tick laeuft sie nicht (Wanduhr egal)")
	driver.set("_current_tick", START_TICK + 120)
	_check(is_equal_approx(float(driver.call("_get_objective_defense_elapsed_seconds")), 2.0), "Haltezeit: 120 Ticks = 2,0 s")
	driver.set("_current_tick", START_TICK + 480)
	_check(float(driver.call("_get_objective_defense_elapsed_seconds")) >= float(driver.get("objective_defense_hold_seconds")), "Haltezeit: 480 Ticks erreichen die 8 s Vorgabe")
	rig.sim.objective.capture_progress = 0.5
	driver.call("_update_objective_hold_tracking")
	_check(is_equal_approx(float(driver.call("_get_objective_defense_elapsed_seconds")), 0.0), "Haltezeit: Verlust der Zone setzt zurueck")
	rig.scene.free()


func _units(count: int) -> Array:
	var units: Array = []
	for index in range(count):
		units.append(null)
	return units


func _test_security_shift_delay_and_scan() -> void:
	var controller = SECURITY_SCRIPT.new()
	# Suchwinkel haengt nur vom Tick ab: gleicher Tick -> gleicher Winkel; eine Periode (156 Ticks = 2,6 s) spaeter derselbe.
	var a: float = float(controller.call("_build_defense_scan_offset", 0, 40))
	var b: float = float(controller.call("_build_defense_scan_offset", 0, 40))
	var c: float = float(controller.call("_build_defense_scan_offset", 0, 40 + 156))
	var d: float = float(controller.call("_build_defense_scan_offset", 0, 40 + 78))
	_check(a == b and is_equal_approx(a, c), "Suchwinkel: gleicher Tick und eine Periode (156 Ticks) spaeter ergeben denselben Winkel")
	_check(not is_equal_approx(a, d), "Suchwinkel: eine halbe Periode spaeter ein anderer Winkel")
	# Verzoegerung des Richtungswechsels 250..1200 ms = 15..72 Ticks
	_check(int(controller.call("_build_shift_delay_ticks", 0.4)) == 72 and int(controller.call("_build_shift_delay_ticks", 0.7)) == 15, "Richtungswechsel: 72 Ticks bei Fuehrung 0,4 und 15 Ticks bei 0,7")


func _source_of(script: GDScript) -> String:
	return script.source_code


func _body_of(source: String, func_name: String) -> String:
	var start: int = source.find("\nfunc %s(" % func_name)
	if start < 0:
		return ""
	var end: int = source.find("\nfunc ", start + 6)
	return source.substr(start, (end if end > 0 else source.length()) - start)


func _test_no_wall_clock_in_converted_functions() -> void:
	var driver_source: String = _source_of(DRIVER_SCRIPT)
	for name in ["_has_down_state_linger_elapsed", "_mark_unit_down_started", "_update_objective_hold_tracking", "_get_objective_defense_elapsed_seconds", "_apply_friendly_standard_behavior"]:
		var body := _body_of(driver_source, name)
		_check(not body.is_empty() and not body.contains("get_ticks_msec"), "Waechter: %s ohne Wanduhr" % name)
	var security_source: String = _source_of(SECURITY_SCRIPT)
	_check(not security_source.contains("get_ticks_msec"), "Waechter: Sicherungs-Controller ohne Wanduhr")
