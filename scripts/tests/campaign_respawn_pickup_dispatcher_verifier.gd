extends SceneTree
## R4c Respawn, Befund W1 (Pruefbericht 1): Der Shuttle-Dienst waehlt seine Fahrgaeste nur nach der Kennung polisa_recruit_ (und "am Boden").
## Eine frueher Angeworbene, die auf Abholung wartet (awaiting_pickup) und am Boden zurueckbleibt, wuerde so auf den Heimflug geschickt; daheim lehnt
## admit_polisa_shuttle_home sie jetzt ab (Wartende kommen nur mit dem Schiff), der Adapter wiederholt den Schritt alle 0,5 s.
## R4f: Der Dispatcher nimmt Wartende (awaiting_pickup) und Ausgefallene (respawning) aus der Auswahl aus; dieser Test haelt NUR die Auswahl fest.
## Abschlusszeile: CAMPAIGN_RESPAWN_PICKUP_DISPATCHER passed=%d failed=%d

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

class Controller extends Node:
	var _deployed_unit_ids := {"polisa_recruit_back": true, "polisa_recruit_down": true, "polisa_recruit_fresh": true, "polisa_recruit_nofile": true}
class Setup extends Node:
	func get_polisa_recruit_admission(_id: String) -> Dictionary: return {"ok": true}
class Terrain extends Node:
	func get_legal_hex_neighbors(_grid: Vector2i) -> Array: return [Vector2i(3, 4)]
	func is_walkable(_grid: Vector2i) -> bool: return true
class Simulation extends Node:
	var terrain: Node
	func get_hex_unit_state(_id: String) -> Dictionary: return {"grid": Vector2i(2, 4)}
	func get_hex_ground_terrain_registry() -> Node: return terrain
	func get_hex_ground_planning_snapshot() -> Dictionary: return {"occupant_by_grid": {}}
class Flow extends Node:
	var place: Node
	func get_mission_for_craft(_id: String) -> Node: return place
	func _request_singleplayer_return(_id: String) -> Dictionary: return {"ok": true}
	## Kader wie im Spiel: Wartende (awaiting_pickup), Ausgefallene (respawning), eine nie gestorbene Angeworbene (active).
	var _all_team_units: Array = [
		{"unit_id": "polisa_recruit_back", "availability_status": "awaiting_pickup"},
		{"unit_id": "polisa_recruit_down", "availability_status": "respawning"},
		{"unit_id": "polisa_recruit_fresh", "availability_status": "active"},
	]
class Base extends Node:
	func get_shuttle_person_status(_id: String) -> Dictionary: return {"ok": true, "has_bed": false, "has_task": false}
class Bridge extends RefCounted:
	func request_station_pilot(_place: Node, craft: String, _cell: Vector2i) -> Dictionary: return {"ok": true, "unit_id": "station_shuttle_pilot_" + craft.sha256_text().substr(0, 16)}
class Owner extends RefCounted:
	var phase := "idle"
	func configure(_verify: Callable, _status: Callable) -> Dictionary: return {"ok": true}
	func get_snapshot() -> Dictionary: return {"phase": phase}

var _passed := 0
var _failed := 0

func _init() -> void: call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok: _passed += 1; print("PASS: ", label)
	else: _failed += 1; print("FAIL: ", label)

func _run() -> void:
	var verdict: Dictionary = GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_PICKUP_DISPATCHER refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	## Fall: [Besucher-Kennungen, erwartete Wahl ("" = niemand), Beschriftung]
	for case_ids: Array in [
		[["polisa_recruit_fresh"], "polisa_recruit_fresh", "Kontrolle: eine nie gestorbene Angeworbene am Boden wird vom Shuttle-Dienst gewaehlt"],
		[["polisa_recruit_nofile"], "polisa_recruit_nofile", "Kontrolle: eine Angeworbene ohne Kader-Eintrag wird gewaehlt (nur die Kennung zaehlt)"],
		[["polisa_recruit_back"], "", "W1: eine Wartende (awaiting_pickup) mit Kennung wird NICHT gewaehlt"],
		[["polisa_recruit_down"], "", "W1: eine Ausgefallene (respawning) mit Kennung wird NICHT gewaehlt"],
		[["polisa_recruit_back", "polisa_recruit_down", "polisa_recruit_fresh"], "polisa_recruit_fresh", "W1: neben Wartender und Ausgefallener wird die nie gestorbene gewaehlt"],
	]:
		var place := Node.new(); root.add_child(place)
		place.set_meta("location_id", "polisa")
		place.set_meta("singleplayer_visit_identities", {"own": {"unit_ids": case_ids[0]}})
		# Ohne Kader-Eintrag fuer "nofile" bewusst.
		var c := Controller.new(); c.name = "TacticalController"; place.add_child(c)
		var setup := Setup.new(); setup.name = "MissionSetup"; place.add_child(setup)
		var terrain := Terrain.new(); place.add_child(terrain)
		var sim := Simulation.new(); sim.name = "SimulationRoot"; sim.terrain = terrain; place.add_child(sim)
		var flow := Flow.new(); root.add_child(flow); flow.place = place
		var base := Base.new(); root.add_child(base)
		var dispatcher = load("res://scripts/mission/polisa_shuttle_dispatcher.gd").new()
		dispatcher._bridge = Bridge.new()
		dispatcher.configure(flow, base, Owner.new(), Callable())
		var start: Dictionary = dispatcher.request_departure("own")
		var picked := String(dispatcher.get_snapshot().get("person_id", ""))
		if String(case_ids[1]).is_empty():
			_check(not bool(start.get("pending", false)) and picked.is_empty(), String(case_ids[2]) + " (gewaehlt: '%s', pending: %s)" % [picked, str(start.get("pending", false))])
		else:
			_check(bool(start.get("pending", false)) and picked == String(case_ids[1]), String(case_ids[2]) + " (gewaehlt: '%s')" % picked)
		place.free(); flow.free(); base.free()
	print("CAMPAIGN_RESPAWN_PICKUP_DISPATCHER passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
