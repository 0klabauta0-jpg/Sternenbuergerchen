extends SceneTree
## Luftrollen 3: Rolle CAS - das Schiff waehlt selbst gesichtete Bodengegner im Umkreis 8, dreht die Nase aufs Ziel, feuert, bricht nach Stil ab.
## Rein rechnerisch an der kleinen Attrappen-Mission von air_role_circle_verifier (Rundbahn um (10,10)); die Sicht liefert FixVision.
const ROOT_SCRIPT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const TERRAIN_MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const DT := 0.05

var _passed := 0
var _failed := 0


class FixFlow extends Node:
	var _active_mission: Node
	var _craft_location_runtime := {}
	var _assigned_aircraft_pilot_by_craft := {}
	func get_active_mission() -> Node: return _active_mission

class FixPerson extends Node2D:
	var unit_id := ""
	var health := 100
	var team := "blue"
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team
	func get_health() -> int: return health
	func get_character_profile_bundle() -> Dictionary: return {"platform_values":{"dropship_piloting":1.0, "fighter_piloting":1.0}}
	func apply_damage(amount: int, _context: Dictionary = {}) -> bool: health -= amount; return true

class FixVision extends Node:
	var ids: Array = []
	var calls := 0
	func get_multiplayer_visible_unit_ids(_team: String) -> PackedStringArray:
		calls += 1
		return PackedStringArray(ids)

class FixTransport extends Node:
	var boarded := true
	var landing_clear := true
	var parked := {}
	var landed_position := {}
	func get_campaign_air_support_pilot_guard(craft_id: String) -> Dictionary:
		return {"ok":true, "pilot_unit_id":"pilot_" + craft_id} if boarded else {"ok":false, "reason":"pilot_boarding_pending"}
	func _is_parked_campaign_dropship(craft_id: String) -> bool: return bool(parked.get(craft_id, false))
	func _campaign_landed_craft_position(craft_id: String) -> Vector2: return landed_position.get(craft_id, Vector2.ZERO)
	func _ground_ship_touchdown_ready(_id: String, _position: Vector2, _visual: bool) -> bool: return landing_clear


func _check(ok: bool, label: String) -> bool:
	if ok:
		_passed += 1
	else:
		_failed += 1
		print("AIR_CAS_ROLE FAIL: ", label)
	return ok


# ---------------------------------------------------------------- Aufbau
## Felder 5..19, Landezone (10,10); Gegner (Team red) auf den angegebenen Feldern; sichtbar ist, was in vision.ids steht.
func _build(foes: Dictionary, visible: Array) -> Dictionary:
	var loc := "moon_site"
	var flow := FixFlow.new(); root.add_child(flow)
	var adapter = ADAPTER.new(); flow.add_child(adapter); adapter._flow = flow
	var source = ROOT_SCRIPT.new(); adapter.add_child(source); adapter._simulation = source
	var fleet = FLEET.new(); fleet.configure(); fleet.register_craft("ship")
	var equipment = EQUIPMENT.new(); equipment.configure([{"craft_id":"ship", "model_id":"cutlass"}])
	source.configure_singleplayer_owners(null, null, null, fleet); source.configure_ship_equipment(equipment)
	source.configure_departure_adapter(adapter)
	source.get("_space_wing_state").ensure_flying_wings("singleplayer", ["ship"], ["ship"], {"ship":"pilot_ship"})
	flow._craft_location_runtime["ship"] = loc
	flow._assigned_aircraft_pilot_by_craft["ship"] = "pilot_ship"
	var mission := Node.new(); mission.set_meta("location_id", loc); flow.add_child(mission)
	var mission_root = ROOT_SCRIPT.new(); mission_root.name = "SimulationRoot"; mission.add_child(mission_root); flow._active_mission = mission
	_check(bool(adapter.bind_mission_air_support(mission).ok), "Aufbau: Luftunterstuetzung ist an die Mission gebunden")
	var terrain = TERRAIN.new(); terrain.name = "Terrain"; mission.add_child(terrain); terrain.configure_iso_grid(Vector2.ZERO, 64, 32, "hex_axial_v1")
	terrain.register_tile(TILE.new({"tile_id":"zero", "grid_position":Vector2i.ZERO, "explicit_hex_ramps":true}))
	var units = UNITS.new(); units.name = "Units"; mission.add_child(units)
	mission_root.unit_registry_path = mission_root.get_path_to(units); mission_root.terrain_registry_path = mission_root.get_path_to(terrain)
	var map = TERRAIN_MAP.create_empty(loc, Vector2i(4, 3), Vector2.ZERO, 64, 32, 3, "hex_axial_v1"); map.set_tactical_grid_rules("hex_tactical_v1")
	mission_root.configure_hex_ground_runtime(map, terrain)
	var pilot = FixPerson.new(); pilot.unit_id = "pilot_ship"; mission.add_child(pilot); units.register_unit(pilot.unit_id, pilot); mission_root.register_known_unit(pilot.unit_id, pilot)
	pilot.set_meta("dropship_embarked", true)
	var vision = FixVision.new(); vision.name = "CombatLoopDriver"; vision.ids = visible.duplicate(); mission.add_child(vision)
	var transport = FixTransport.new(); transport.name = "TacticalController"; mission.add_child(transport)
	for q in range(5, 20):
		for r in range(5, 20): terrain.register_tile(TILE.new({"tile_id":"air:%d:%d" % [q, r], "grid_position":Vector2i(q, r), "explicit_hex_ramps":true}))
	transport.landed_position["ship"] = terrain.grid_to_world(Vector2i(10, 10))
	transport.parked["ship"] = true
	var persons := {}
	var placements: Array[Dictionary] = []
	for id in foes.keys():
		var foe = FixPerson.new(); foe.unit_id = String(id); foe.team = "red"; mission.add_child(foe); units.register_unit(foe.unit_id, foe); mission_root.register_known_unit(foe.unit_id, foe)
		persons[id] = foe
		placements.append({"unit_id":String(id), "grid":foes[id]})
	if not placements.is_empty(): mission_root.admit_hex_ground_units(placements)
	source.tick_counter = 50
	var events: Array = []
	mission_root.air_role_event.connect(func(event: Dictionary) -> void: events.append(event))
	var env := {"flow":flow, "adapter":adapter, "source":source, "fleet":fleet, "mission_root":mission_root, "transport":transport, "vision":vision, "pilot":pilot, "foes":persons, "events":events, "tick":50, "combat":source.get("_space_combat_state"), "shots":[], "nose_error_max":0.0}
	mission_root.air_support_ground_fired.connect(func(_event: Dictionary) -> void: _on_shot(env))
	return env


## Beim Schuss: Abweichung der Nase von der Richtung zum Ziel (das Ziel des Rottenbefehls).
func _on_shot(env: Dictionary) -> void:
	var pose: Dictionary = _pose(env, "ship")
	var order: Dictionary = _order(env)
	var grid: Variant = env.mission_root._air_ground_unit_grid(String(order.get("target_id", "")))
	var error := 999.0
	if typeof(grid) == TYPE_VECTOR2I:
		var aim: Vector2 = GRID.HEX.axial_to_plane(Vector2(grid)) - Vector2(pose.position_plane)
		error = absf(wrapf(aim.angle() - float(pose.heading_rad), -PI, PI))
	env.shots.append(error)
	env.nose_error_max = maxf(float(env.nose_error_max), error)


func _tick(env: Dictionary, seconds: float) -> void:
	var source: Node = env.source
	var mission_root: Node = env.mission_root
	for _i in range(int(round(seconds / DT))):
		env.tick = int(env.tick) + 1
		source.tick_counter = int(env.tick)
		source._advance_space_flights(DT, int(env.tick))
		mission_root._advance_air_support_orders(DT)


func _pose(env: Dictionary, id: String) -> Dictionary:
	return env.fleet.get_flight_state(id).get_snapshot()


func _sortie(env: Dictionary) -> Dictionary:
	return Dictionary(env.mission_root.get("_air_support_sorties")).get("ship", {})


func _target(env: Dictionary) -> String:
	return String(_sortie(env).get("role_target_id", ""))


## Rottenbefehl des Schiffs.
func _order(env: Dictionary) -> Dictionary:
	var binding: Dictionary = env.mission_root._resolve_air_support_craft("ship")
	if not binding.get("ok", false): return {}
	return Dictionary(binding.wings.get_snapshot().wings.get(binding.wing_id, {})).get("order", {})


func _count(env: Dictionary, kind: String) -> int:
	var n := 0
	for event in env.events:
		if event.craft_id == "ship" and event.kind == kind: n += 1
	return n


func _texts(env: Dictionary, kind: String) -> Array:
	var texts: Array = []
	for event in env.events:
		if event.craft_id == "ship" and event.kind == kind: texts.append(event.text)
	return texts


func _circle(env: Dictionary, role: String, request_id: String) -> Dictionary:
	return env.mission_root.request_air_support_circle({"craft_id":"ship", "center_hex":Vector2i(10, 10), "role":role, "request_id":request_id})


# ---------------------------------------------------------------- Faelle
## Fall 1: Gegner auf (13,10) sichtbar: Ziel nach hoechstens 0,5 s, Angriffsbefehl, Schuesse mit Nase auf dem Ziel.
func _case_1() -> void:
	var tag := "[1 Ziel und Feuer] "
	var env: Dictionary = _build({"foe":Vector2i(13, 10)}, ["foe"])
	_check(bool(_circle(env, "cas", "c1").get("ok", false)), tag + "Aufbau: CAS an (10,10)")
	_tick(env, 0.6)
	var order: Dictionary = _order(env)
	_check(_target(env) == "foe", tag + "nach 0,6 s ist role_target_id foe: '%s'" % _target(env))
	_check(order.get("verb") == "attack_target" and order.get("fire_rule") == "free" and order.get("target_id") == "foe", tag + "Rottenbefehl attack_target / free auf foe: " + str(order))
	_check(_texts(env, "target_engaged") == ["ship greift foe an."], tag + "Ereignis target_engaged mit dem Wortlaut, einmal: " + str(_texts(env, "target_engaged")))
	_tick(env, 20.0)
	_check(env.shots.size() >= 1, tag + "in 20 s mindestens ein air_support_ground_fired (%d)" % env.shots.size())
	_check(not env.shots.is_empty() and float(env.shots[0]) < deg_to_rad(10.0), tag + "beim ersten Schuss Nasenfehler unter 10 Grad: %.1f" % (rad_to_deg(float(env.shots[0])) if not env.shots.is_empty() else -1.0))
	_check(float(env.nose_error_max) < deg_to_rad(10.0), tag + "bei jedem Schuss Nasenfehler unter 10 Grad (groesster %.1f)" % rad_to_deg(float(env.nose_error_max)))
	_check(_count(env, "target_engaged") == 1 and _count(env, "role_ended") == 0, tag + "kein zweites target_engaged, Rolle laeuft")
	var bad := 0
	for _i in range(200):
		_tick(env, DT)
		var reason := String(env.combat.get_flight_status("ship").get("reason", ""))
		if reason == "occupied" or reason == "navigation_claimed": bad += 1
	_check(bad == 0, tag + "10 s weiter ohne occupied/navigation_claimed im Flugstatus (%d)" % bad)
	env.flow.free()


## Fall 2: nur ein Gegner auf (19,10), Abstand 9 zur Mitte: kein Ziel.
func _case_2() -> void:
	var tag := "[2 ausserhalb 8] "
	var env: Dictionary = _build({"foe":Vector2i(19, 10)}, ["foe"])
	_circle(env, "cas", "c2")
	_tick(env, 5.0)
	_check(_target(env) == "" and _order(env).get("verb") != "attack_target" and _count(env, "target_engaged") == 0, tag + "kein Ziel, kein Angriffsbefehl")
	env.flow.free()


## Fall 3: Wahl nach Abstand, Halten, Wechsel nur bei Tod.
func _case_3() -> void:
	var tag := "[3 Wahl, Halten, Wechsel] "
	var env: Dictionary = _build({"foe":Vector2i(13, 10), "foe3":Vector2i(12, 10)}, ["foe", "foe3"])
	_circle(env, "cas", "c3")
	_tick(env, 0.6)
	_check(_target(env) == "foe3", tag + "der naechste (Abstand 2) wird gewaehlt: '%s'" % _target(env))
	var rt: Object = env.mission_root.get("_hex_ground_runtime")
	var moved: Dictionary = rt.relocate_unit("foe", Vector2i(11, 10), int(rt.get("_revision")))
	_check(bool(moved.get("ok", false)), tag + "Aufbau: foe rueckt auf (11,10): " + str(moved))
	_tick(env, 2.0)
	_check(_target(env) == "foe3" and _count(env, "target_engaged") == 1, tag + "kein Wechsel, obwohl foe jetzt naeher ist")
	env.foes["foe3"].health = 0
	_tick(env, 0.6)
	_check(_target(env) == "foe", tag + "foe3 tot: naechster Takt foe: '%s'" % _target(env))
	_check(_texts(env, "target_engaged") == ["ship greift foe3 an.", "ship greift foe an."], tag + "zwei Ereignisse target_engaged in Reihenfolge: " + str(_texts(env, "target_engaged")))
	env.flow.free()


## Fall 4: Ziel nicht mehr sichtbar: Feuerstopp, Ziel leer.
func _case_4() -> void:
	var tag := "[4 Sicht verloren] "
	var env: Dictionary = _build({"foe":Vector2i(13, 10)}, ["foe"])
	_circle(env, "cas", "c4")
	_tick(env, 0.6)
	_check(_target(env) == "foe", tag + "Aufbau: Ziel foe")
	env.vision.ids = []
	_tick(env, 0.6)
	_check(_target(env) == "" and _order(env).get("verb") != "attack_target", tag + "Feuerstopp und kein Ziel: '%s' / %s" % [_target(env), str(_order(env))])
	var shots_before: int = env.shots.size()
	_tick(env, 5.0)
	_check(env.shots.size() == shots_before, tag + "danach kein Schuss mehr")
	env.vision.ids = ["foe"]
	_tick(env, 0.6)
	_check(_target(env) == "foe", tag + "wieder sichtbar: wieder Ziel foe")
	env.flow.free()


## Fall 5: Rollen none und air_defense waehlen nie ein Bodenziel.
func _case_5() -> void:
	var tag := "[5 none / air_defense] "
	for role in ["none", "air_defense"]:
		var env: Dictionary = _build({"foe":Vector2i(13, 10)}, ["foe"])
		_check(bool(_circle(env, role, "c5" + role).get("ok", false)), tag + "Aufbau: " + role)
		_tick(env, 10.0)
		_check(_target(env) == "" and _order(env).get("verb") != "attack_target" and env.shots.is_empty() and env.vision.calls == 0, tag + "%s: in 10 s kein Bodenziel, kein Schuss, keine Sichtabfrage (%d)" % [role, env.vision.calls])
		env.flow.free()


## Fall 6: Rumpf 45 von 100, Stil normal: Abdrehen, Rueckflug, kein neuer Angriffsbefehl; Rueckflug wird nicht durch Pilotverlust beendet.
func _case_6() -> void:
	var tag := "[6 Abdrehen] "
	var env: Dictionary = _build({"foe":Vector2i(13, 10)}, ["foe"])
	_circle(env, "cas", "c6")
	_tick(env, 0.6)
	_check(_target(env) == "foe", tag + "Aufbau: Ziel foe")
	env.mission_root.set("_air_asset_status_by_id", {"ship":{"asset_id":"ship", "asset_type":"dropship", "state":"damaged", "integrity":45, "max_integrity":100}})
	_tick(env, 1.0)
	var sortie: Dictionary = _sortie(env)
	_check(String(sortie.get("returning", "")) == "break_off" and Dictionary(sortie.get("air_role", {"x":1})).is_empty() and _target(env) == "", tag + "Rueckflug break_off, Rolle und Ziel leer: " + str(sortie.get("returning")))
	_check(_texts(env, "break_off_return") == ["ship bricht den Einsatz ab und fliegt zur Landezone."], tag + "Ereignis break_off_return mit dem Wortlaut, einmal: " + str(_texts(env, "break_off_return")))
	_check(_order(env).get("verb") != "attack_target", tag + "Angriffsbefehl beendet")
	var engaged: int = _count(env, "target_engaged")
	_tick(env, 3.0)
	_check(_order(env).get("verb") != "attack_target" and _count(env, "target_engaged") == engaged and _count(env, "break_off_return") == 1, tag + "kein neuer Angriffsbefehl im Rueckflug, Ereignis weiter einmal")
	env.transport.boarded = false
	env.pilot.set_meta("dropship_embarked", false)
	_tick(env, 2.0)
	_check(_count(env, "role_ended") == 0 and String(_sortie(env).get("returning", "")) == "break_off", tag + "Pilotverlust im Rueckflug: kein role_ended, Rueckflug bleibt")
	env.flow.free()
	# Treibstoff-Rueckflug: ebenfalls keine Zielwahl.
	var env2: Dictionary = _build({"foe":Vector2i(13, 10)}, ["foe"])
	_circle(env2, "cas", "c6b")
	_tick(env2, 0.6)
	_check(bool(env2.mission_root._air_begin_return("ship", "fuel").get("ok", false)), tag + "Aufbau 2: Rueckflug wegen Treibstoff")
	var engaged2: int = _count(env2, "target_engaged")
	_tick(env2, 3.0)
	_check(_target(env2) == "" and _order(env2).get("verb") != "attack_target" and _count(env2, "target_engaged") == engaged2, tag + "im Treibstoff-Rueckflug keine Zielwahl")
	env2.flow.free()


## Fall 7: ohne Sortie wird die Sicht nie abgefragt.
func _case_7() -> void:
	var tag := "[7 keine Sortie] "
	var env: Dictionary = _build({"foe":Vector2i(13, 10)}, ["foe"])
	_tick(env, 5.0)
	_check(env.vision.calls == 0 and Dictionary(env.mission_root.get("_air_support_sorties")).is_empty(), tag + "100 Ticks ohne Sortie: keine Sichtabfrage (%d)" % env.vision.calls)
	env.flow.free()


## Fall 8: manuelles "Feuer" ersetzt das Ziel, die Rolle bleibt.
func _case_8() -> void:
	var tag := "[8 manueller Angriff] "
	var env: Dictionary = _build({"foe":Vector2i(13, 10), "foe3":Vector2i(12, 10)}, ["foe", "foe3"])
	_circle(env, "cas", "c8")
	_tick(env, 0.6)
	_check(_target(env) == "foe3", tag + "Aufbau: Ziel foe3")
	var manual: Dictionary = env.mission_root.request_air_support_attack_order({"craft_id":"ship", "target_unit_id":"foe", "request_id":"man8"})
	_check(bool(manual.get("ok", false)), tag + "Aufbau: manueller Angriffsbefehl auf foe: " + str(manual))
	_tick(env, 3.0)
	var snap: Dictionary = env.mission_root.get_air_support_role_snapshot("ship")
	_check(_target(env) == "foe" and String(snap.get("role", "")) == "cas" and _order(env).get("target_id") == "foe", tag + "Ziel foe, Rolle bleibt cas: %s / %s" % [_target(env), str(snap.get("role"))])
	env.flow.free()


## Fall 9 (Plan Zeile 32): Pilot faellt waehrend der Rolle weg: role_ended "kein Pilot an Bord", das Schiff schwebt, kein Schuss, Treibstoff-Uhr unberuehrt.
func _case_9() -> void:
	var tag := "[9 Pilot weg] "
	var env: Dictionary = _build({"foe":Vector2i(13, 10)}, ["foe"])
	_circle(env, "cas", "c9")
	_tick(env, 3.0)
	env.transport.boarded = false
	env.pilot.set_meta("dropship_embarked", false)
	_tick(env, 1.0)
	_check(_count(env, "role_ended") == 1 and _texts(env, "role_ended") == ["Rolle beendet – kein Pilot an Bord."], tag + "genau ein role_ended mit dem Wortlaut: " + str(_texts(env, "role_ended")))
	var snap: Dictionary = env.mission_root.get_air_support_role_snapshot("ship")
	_check(bool(snap.get("ok", false)) and bool(snap.get("airborne", false)) and String(snap.get("role", "x")) == "" and String(snap.get("returning", "x")) == "", tag + "das Schiff ist in der Luft, ohne Rolle: " + str(snap))
	var shots: int = env.shots.size()
	_tick(env, 10.0)
	_check(env.shots.size() == shots and _count(env, "role_ended") == 1, tag + "danach kein Schuss, kein zweites role_ended")


func _initialize() -> void:
	_case_1()
	_case_2()
	_case_3()
	_case_4()
	_case_5()
	_case_6()
	_case_7()
	_case_8()
	_case_9()
	print("AIR_CAS_ROLE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
