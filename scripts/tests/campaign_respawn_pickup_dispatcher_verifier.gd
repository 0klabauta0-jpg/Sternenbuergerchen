extends SceneTree
## R4c Respawn, Befund W1 (Pruefbericht 1): Der Shuttle-Dienst waehlt seine Fahrgaeste nur nach der Kennung polisa_recruit_ (und "am Boden").
## Eine frueher Angeworbene, die auf Abholung wartet (awaiting_pickup) und am Boden zurueckbleibt, wuerde so auf den Heimflug geschickt; daheim lehnt
## admit_polisa_shuttle_home sie jetzt ab (Wartende kommen nur mit dem Schiff), der Adapter wiederholt den Schritt alle 0,5 s.
## Dieser Test haelt NUR die Auswahl fest. Mit der Fassung des Dispatchers bis 5d207c752 (scripts/mission/polisa_shuttle_dispatcher.gd, ausserhalb des
## Auftrags R4c) gilt: BEFUND = die Wartende wird gewaehlt (Ausgabe "BEFUND W1 ... gewaehlt"), und die Pruefung ist gruen. Sobald der Dispatcher
## Wartende ausnimmt, wird die Pruefung "BEFUND W1" rot und ist auf "nicht gewaehlt" umzudrehen.
## Abschlusszeile: CAMPAIGN_RESPAWN_PICKUP_DISPATCHER passed=%d failed=%d

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

class Controller extends Node:
	var _deployed_unit_ids := {"polisa_recruit_back": true, "polisa_recruit_fresh": true}
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
	func _roster_unit_awaits_pickup(id: String) -> bool: return id == "polisa_recruit_back"
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
	for case_ids: Array in [[["polisa_recruit_fresh"], "polisa_recruit_fresh"], [["polisa_recruit_back"], "polisa_recruit_back"]]:
		var place := Node.new(); root.add_child(place)
		place.set_meta("location_id", "polisa")
		place.set_meta("singleplayer_visit_identities", {"own": {"unit_ids": case_ids[0]}})
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
		var chosen: bool = bool(start.get("pending", false)) and String(dispatcher.get_snapshot().get("person_id", "")) == String(case_ids[1])
		if String(case_ids[1]) == "polisa_recruit_fresh":
			_check(chosen, "Kontrolle: eine frisch Angeworbene am Boden wird vom Shuttle-Dienst gewaehlt")
		else:
			print("BEFUND W1: die wartende frueher Angeworbene %s wird vom Shuttle-Dienst %s" % [case_ids[1], "gewaehlt" if chosen else "nicht gewaehlt"])
			_check(chosen, "BEFUND W1: die wartende frueher Angeworbene wird vom Shuttle-Dienst gewaehlt (Dispatcher waehlt nur nach Kennung)")
		place.free(); flow.free(); base.free()
	print("CAMPAIGN_RESPAWN_PICKUP_DISPATCHER passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
