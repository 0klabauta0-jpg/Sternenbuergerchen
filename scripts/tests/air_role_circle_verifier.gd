extends SceneTree
## Luftrollen 1b: "Kreisen an Punkt X" mit Rolle (keine / CAS / Luftschutz), echte Rundbahn, Landen aus der Rundbahn.
## Rein rechnerisch an einer kleinen Attrappen-Mission (wie air_arrival_circle_verifier Teil 1), keine Szene, kein Einsatzlauf.
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
	func get_multiplayer_visible_unit_ids(_team: String) -> PackedStringArray:
		return PackedStringArray(["foe"])

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
		print("AIR_ROLE_CIRCLE FAIL: ", label)
	return ok


# ---------------------------------------------------------------- Aufbau
## Felder 5..19, Landezone (10,10); die Schiffe stehen geparkt auf den angegebenen Feldern (parked bleibt falsch, bis ein Fall es setzt).
func _build(model_id: String, craft_ids: Array[String], grids: Dictionary = {}) -> Dictionary:
	var loc := "moon_site"
	var flow := FixFlow.new(); root.add_child(flow)
	var adapter = ADAPTER.new(); flow.add_child(adapter); adapter._flow = flow
	var source = ROOT_SCRIPT.new(); adapter.add_child(source); adapter._simulation = source
	var fleet = FLEET.new(); fleet.configure()
	var configs: Array[Dictionary] = []
	var pilots := {}
	for id in craft_ids:
		fleet.register_craft(id)
		configs.append({"craft_id":id, "model_id":model_id})
		pilots[id] = "pilot_" + id
		flow._craft_location_runtime[id] = loc
		flow._assigned_aircraft_pilot_by_craft[id] = "pilot_" + id
	var equipment = EQUIPMENT.new(); equipment.configure(configs)
	source.configure_singleplayer_owners(null, null, null, fleet); source.configure_ship_equipment(equipment)
	source.configure_departure_adapter(adapter)
	source.get("_space_wing_state").ensure_flying_wings("singleplayer", craft_ids, craft_ids, pilots)
	var mission := Node.new(); mission.set_meta("location_id", loc); flow.add_child(mission)
	var mission_root = ROOT_SCRIPT.new(); mission_root.name = "SimulationRoot"; mission.add_child(mission_root); flow._active_mission = mission
	_check(bool(adapter.bind_mission_air_support(mission).ok), "Aufbau: Luftunterstuetzung ist an die Mission gebunden")
	var terrain = TERRAIN.new(); terrain.name = "Terrain"; mission.add_child(terrain); terrain.configure_iso_grid(Vector2.ZERO, 64, 32, "hex_axial_v1")
	terrain.register_tile(TILE.new({"tile_id":"zero", "grid_position":Vector2i.ZERO, "explicit_hex_ramps":true}))
	var units = UNITS.new(); units.name = "Units"; mission.add_child(units)
	mission_root.unit_registry_path = mission_root.get_path_to(units); mission_root.terrain_registry_path = mission_root.get_path_to(terrain)
	var map = TERRAIN_MAP.create_empty(loc, Vector2i(4, 3), Vector2.ZERO, 64, 32, 3, "hex_axial_v1"); map.set_tactical_grid_rules("hex_tactical_v1")
	mission_root.configure_hex_ground_runtime(map, terrain)
	var persons := {}
	for id in craft_ids:
		var pilot = FixPerson.new(); pilot.unit_id = "pilot_" + id; mission.add_child(pilot); units.register_unit(pilot.unit_id, pilot); mission_root.register_known_unit(pilot.unit_id, pilot)
		pilot.set_meta("dropship_embarked", true)
		persons[id] = pilot
	var vision = FixVision.new(); vision.name = "CombatLoopDriver"; mission.add_child(vision)
	var transport = FixTransport.new(); transport.name = "TacticalController"; mission.add_child(transport)
	for q in range(5, 20):
		for r in range(5, 20): terrain.register_tile(TILE.new({"tile_id":"air:%d:%d" % [q, r], "grid_position":Vector2i(q, r), "explicit_hex_ramps":true}))
	for id in craft_ids:
		transport.landed_position[id] = terrain.grid_to_world(Vector2i(grids.get(id, Vector2i(10, 10))))
	source.tick_counter = 50
	var events: Array = []
	mission_root.air_role_event.connect(func(event: Dictionary) -> void: events.append(event))
	return {"flow":flow, "adapter":adapter, "source":source, "fleet":fleet, "mission_root":mission_root, "terrain":terrain, "transport":transport, "persons":persons, "events":events, "tick":50, "combat":source.get("_space_combat_state")}


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


func _sortie(env: Dictionary, id: String) -> Dictionary:
	var mission_root: Node = env.mission_root
	return Dictionary(mission_root.get("_air_support_sorties")).get(id, {})


func _count(env: Dictionary, id: String, kind: String) -> int:
	var n := 0
	for event in env.events:
		if event.craft_id == id and event.kind == kind:
			n += 1
	return n


func _plane(cell: Vector2i) -> Vector2:
	return GRID.HEX.axial_to_plane(Vector2(cell))


func _circle(env: Dictionary, id: String, center: Vector2i, role: String, request_id: String) -> Dictionary:
	var mission_root: Node = env.mission_root
	return mission_root.request_air_support_circle({"craft_id":id, "center_hex":center, "role":role, "request_id":request_id})


func _ring(center: Vector2i) -> Array:
	var cells: Array = []
	for i in range(6):
		cells.append(center + 4 * GRID.HEX.DIRECTIONS[i])
	return cells


# ---------------------------------------------------------------- Faelle
## Fall 1: fliegende Cutlass, Rolle none, echte Rundbahn; die Ausrichtung bleibt unveraendert (Ruling: kein Drehen ohne Ziel).
func _case_1() -> void:
	var tag := "[1 fliegend] "
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	_check(bool(mission_root.request_air_support_takeoff("ship").get("ok", false)), tag + "Aufbau: Start von Hand")
	env.transport.parked["ship"] = false
	var heading0: float = float(_pose(env, "ship").heading_rad)
	var center := Vector2i(10, 10)
	var res: Dictionary = _circle(env, "ship", center, "none", "c1")
	_check(bool(res.get("ok", false)) and not bool(res.get("replayed", true)) and not bool(res.get("took_off", true)) and String(res.get("role", "")) == "none" and res.get("center_hex") == center, tag + "Befehl angenommen, kein Start noetig: " + str(res))
	_check(String(res.get("message", "")) == "Kreist an Feld (10, 10).", tag + "Meldung wortlich: " + String(res.get("message", "")))
	var sortie: Dictionary = _sortie(env, "ship")
	var expected := _ring(center)
	var wps: Array = sortie.get("waypoints", [])
	var same := wps.size() == 6
	for cell in expected:
		same = same and wps.has(cell)
	_check(same, tag + "Wegpunkte = Mitte + 4 * Richtungen (6 Zellen): " + str(wps))
	_check(String(Dictionary(sortie.get("air_role", {})).get("role", "")) == "none" and Dictionary(sortie.air_role).get("verb") == "patrol" and Dictionary(sortie.air_role).get("contact_response") == "observe" and Dictionary(sortie.air_role).get("fire_rule") == "hold", tag + "Rolle im Sortie-Eintrag: none = patrol / observe / hold")
	var snap: Dictionary = mission_root.get_air_support_role_snapshot("ship")
	_check(bool(snap.get("ok", false)) and bool(snap.get("airborne", false)) and snap.get("role") == "none" and snap.get("center_hex") == center and int(snap.get("waypoint_index", -1)) == int(res.get("waypoint_index", -2)) and snap.get("returning") == "", tag + "Schnappschuss: " + str(snap))
	_check(_count(env, "ship", "role_started") == 1 and Dictionary(env.events[0]).keys().size() == 3 and env.events[0].text == "Kreist an Feld (10, 10).", tag + "Ereignis role_started genau einmal mit craft_id/kind/text")
	var idx: int = int(sortie.waypoint_index)
	var switches := 0
	var dmin := INF
	var dmax := 0.0
	var hdev := 0.0
	var vmax := 0.0
	var center_plane := _plane(center)
	for _i in range(1200):
		_tick(env, DT)
		var s: Dictionary = _sortie(env, "ship")
		if int(s.waypoint_index) != idx:
			idx = int(s.waypoint_index)
			switches += 1
		var p: Dictionary = _pose(env, "ship")
		if switches >= 1:
			var d: float = p.position_plane.distance_to(center_plane)
			dmin = minf(dmin, d)
			dmax = maxf(dmax, d)
		hdev = maxf(hdev, absf(wrapf(float(p.heading_rad) - heading0, -PI, PI)))
		vmax = maxf(vmax, p.velocity_plane.length())
	_check(switches >= 3, tag + "in 60 s mindestens 3 Wegpunktwechsel: %d" % switches)
	_check(dmin >= 3.0 and dmax <= 5.0, tag + "Abstand zur Mitte ab dem ersten Wechsel zwischen 3,0 und 5,0 (Ring-Radius 4): %.2f bis %.2f" % [dmin, dmax])
	_check(vmax > 0.5, tag + "das Schiff fliegt wirklich (Hoechsttempo %.2f)" % vmax)
	_check(hdev < deg_to_rad(1.0), tag + "Ausrichtung bleibt unveraendert (groesste Abweichung %.3f Grad)" % rad_to_deg(hdev))
	_check(mission_root.is_air_support_craft_airborne("ship") and _count(env, "ship", "role_ended") == 0, tag + "weiter in der Luft, Rolle nicht beendet")
	env.flow.free()


## Fall 2: gelandetes Schiff startet zuerst, dann Rundbahn.
func _case_2() -> void:
	var tag := "[2 gelandet] "
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	var res: Dictionary = _circle(env, "ship", Vector2i(10, 10), "air_defense", "c2")
	_check(bool(res.get("ok", false)) and bool(res.get("took_off", false)), tag + "Befehl angenommen mit Start: " + str(res))
	_check(String(res.get("message", "")) == "Luftschutz an Feld (10, 10).", tag + "Meldung wortlich: " + String(res.get("message", "")))
	var sortie: Dictionary = _sortie(env, "ship")
	_check(not sortie.is_empty() and mission_root.is_air_support_craft_airborne("ship") and Dictionary(sortie.air_role).get("role") == "air_defense" and Dictionary(sortie.air_role).get("contact_response") == "engage" and Dictionary(sortie.air_role).get("fire_rule") == "free" and Dictionary(sortie.air_role).get("stance") == "normal", tag + "in der Luft, Sortie besteht, Rolle Luftschutz (patrol / engage / free / normal)")
	_check(int(sortie.get("sortie_serial", 0)) >= 1 and sortie.get("returning") == "" and sortie.get("role_target_id") == "" and sortie.get("landing_blocked_reported") == false and float(sortie.get("fuel_seconds", -1.0)) == 0.0 and int(sortie.get("fuel_steps", -1)) == 0 and sortie.get("fuel_warned") == false and sortie.has("ring_blocked_seconds") and float(sortie.get("ring_blocked_seconds", -1.0)) == 0.0 and sortie.get("ring_blocked_reported") == false, tag + "vorbelegte Sortie-Schluessel")
	_check(not Array(sortie.get("waypoints", [])).is_empty() and Array(sortie.waypoints).size() == 6, tag + "Wegpunkte der Rundbahn gesetzt: " + str(sortie.get("waypoints")))
	var idx2: int = int(sortie.waypoint_index)
	var switches2 := 0
	for _i in range(600):
		_tick(env, DT)
		var s2: Dictionary = _sortie(env, "ship")
		if int(s2.waypoint_index) != idx2:
			idx2 = int(s2.waypoint_index)
			switches2 += 1
	var p: Dictionary = _pose(env, "ship")
	_check(switches2 >= 1, tag + "nach 30 s mindestens ein Wegpunktwechsel: %d" % switches2)
	_check(p.position_plane.distance_to(_plane(Vector2i(10, 10))) > 2.0, tag + "Abstand zur Mitte nach 30 s ueber 2,0: %.2f" % p.position_plane.distance_to(_plane(Vector2i(10, 10))))
	var cas_env: Dictionary = _build("cutlass", ["ship"])
	cas_env.transport.parked["ship"] = true
	var cas: Dictionary = _circle(cas_env, "ship", Vector2i(10, 10), "cas", "c2b")
	var cas_role: Dictionary = Dictionary(_sortie(cas_env, "ship").get("air_role", {}))
	_check(bool(cas.get("ok", false)) and String(cas.get("message", "")) == "Luftnahunterstützung an Feld (10, 10)." and cas_role.get("verb") == "attack_area" and cas_role.get("contact_response") == "engage" and cas_role.get("fire_rule") == "free" and float(cas_role.get("protect_radius", 0.0)) == 8.0 and float(cas_role.get("pursuit_limit", 0.0)) == 4.0 and cas_role.get("request_id") == "c2b", tag + "CAS: attack_area / engage / free, Radius 8, Verfolgung 4: " + str(cas))
	cas_env.flow.free()
	env.flow.free()


## Fall 3: Punkt ausserhalb der Karte.
func _case_3() -> void:
	var tag := "[3 Punkt ausserhalb] "
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	var pose_before: Dictionary = _pose(env, "ship")
	var wings_before: Dictionary = env.source.get("_space_wing_state").get_snapshot()
	var res: Dictionary = _circle(env, "ship", Vector2i(40, 40), "none", "c3")
	_check(not bool(res.get("ok", true)) and String(res.get("reason", "")) == "role_point_off_map", tag + "abgelehnt: " + str(res))
	_check(_pose(env, "ship") == pose_before and Dictionary(mission_root.get("_air_support_sorties")).is_empty() and not mission_root.is_air_support_craft_airborne("ship") and env.source.get("_space_wing_state").get_snapshot() == wings_before and env.events.is_empty(), tag + "Pose, Rotte und Sortie-Bestand unveraendert, kein Start, kein Ereignis")
	env.flow.free()


## Fall 4: Buccaneer, Kreisbahn am Kartenrand (nur Wegpunkte auf der Karte bleiben).
func _case_4() -> void:
	var tag := "[4 Kartenrand] "
	var env: Dictionary = _build("buccaneer", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	var pose_before: Dictionary = _pose(env, "ship")
	var wings_before: Dictionary = env.source.get("_space_wing_state").get_snapshot()
	var res: Dictionary = _circle(env, "ship", Vector2i(5, 5), "none", "c4a")
	_check(not bool(res.get("ok", true)) and String(res.get("reason", "")) == "circle_off_map", tag + "Mitte (5,5): nur 2 Wegpunkte auf der Karte -> circle_off_map: " + str(res))
	_check(_pose(env, "ship") == pose_before and Dictionary(mission_root.get("_air_support_sorties")).is_empty() and env.source.get("_space_wing_state").get_snapshot() == wings_before, tag + "nichts hat sich geaendert (Pose, Rotte, kein Start)")
	var ok: Dictionary = _circle(env, "ship", Vector2i(7, 10), "none", "c4b")
	var wps: Array = _sortie(env, "ship").get("waypoints", [])
	_check(bool(ok.get("ok", false)) and wps.size() == 4 and wps.has(Vector2i(11, 10)) and wps.has(Vector2i(11, 6)) and wps.has(Vector2i(7, 6)) and wps.has(Vector2i(7, 14)), tag + "Mitte (7,10): genau 4 Wegpunkte: " + str(wps))
	env.flow.free()


## Fall 5: dieselbe Kennung erneut, und dieselbe Kennung mit anderem Inhalt.
func _case_5() -> void:
	var tag := "[5 Kennung] "
	var env: Dictionary = _build("cutlass", ["ship"])
	env.transport.parked["ship"] = true
	var first: Dictionary = _circle(env, "ship", Vector2i(10, 10), "none", "c5")
	var pose_before: Dictionary = _pose(env, "ship")
	var index_before: int = int(_sortie(env, "ship").waypoint_index)
	var events_before: int = env.events.size()
	var again: Dictionary = _circle(env, "ship", Vector2i(10, 10), "none", "c5")
	_check(bool(first.get("ok", false)) and bool(again.get("ok", false)) and bool(again.get("replayed", false)), tag + "gleiche Kennung: replayed: " + str(again))
	_check(_pose(env, "ship") == pose_before and int(_sortie(env, "ship").waypoint_index) == index_before and env.events.size() == events_before, tag + "beim Wiederholen aendert sich nichts (Pose, Wegpunkt, keine neue Meldung)")
	var conflict: Dictionary = _circle(env, "ship", Vector2i(10, 10), "cas", "c5")
	_check(not bool(conflict.get("ok", true)) and String(conflict.get("reason", "")) == "request_id_conflict" and Dictionary(_sortie(env, "ship").air_role).get("role") == "none", tag + "gleiche Kennung, anderer Inhalt: request_id_conflict, Rolle bleibt none: " + str(conflict))
	var bad: Dictionary = env.mission_root.request_air_support_circle({"craft_id":"ship", "center_hex":Vector2i(10, 10), "role":"none"})
	var bad_role: Dictionary = _circle(env, "ship", Vector2i(10, 10), "bomber", "c5x")
	_check(String(bad.get("reason", "")) == "invalid_command" and String(bad_role.get("reason", "")) == "invalid_command", tag + "falsche Form und unbekannte Rolle: invalid_command")
	env.flow.free()


## Fall 6: Pilot nicht an Bord.
func _case_6() -> void:
	var tag := "[6 kein Pilot] "
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	env.persons["ship"].set_meta("dropship_embarked", false)
	var pose_before: Dictionary = _pose(env, "ship")
	var res: Dictionary = _circle(env, "ship", Vector2i(10, 10), "cas", "c6")
	_check(not bool(res.get("ok", true)) and String(res.get("reason", "")) == "pilot_not_aboard", tag + "abgelehnt mit pilot_not_aboard: " + str(res))
	_check(_pose(env, "ship") == pose_before and Dictionary(mission_root.get("_air_support_sorties")).is_empty() and not mission_root.is_air_support_craft_airborne("ship") and Dictionary(mission_root.get("_air_role_receipts")).is_empty(), tag + "kein Start, keine Sortie, kein Beleg")
	env.persons["ship"].set_meta("dropship_embarked", true)
	var retry: Dictionary = _circle(env, "ship", Vector2i(10, 10), "cas", "c6")
	_check(bool(retry.get("ok", false)), tag + "mit Pilot an Bord gilt dieselbe Kennung: " + str(retry))
	env.flow.free()


## Fall 7: zwei Schiffe mit derselben Rolle am selben Punkt.
func _case_7() -> void:
	var tag := "[7 zwei Schiffe] "
	var env: Dictionary = _build("cutlass", ["ship", "ship2"], {"ship":Vector2i(8, 8), "ship2":Vector2i(12, 12)})
	env.transport.parked["ship"] = true
	env.transport.parked["ship2"] = true
	var center := Vector2i(10, 10)
	var a: Dictionary = _circle(env, "ship", center, "air_defense", "c7a")
	var b: Dictionary = _circle(env, "ship2", center, "air_defense", "c7b")
	_check(bool(a.get("ok", false)) and bool(b.get("ok", false)), tag + "beide Befehle angenommen: " + str(a) + " / " + str(b))
	_check(int(b.get("waypoint_index", -1)) == (int(a.get("waypoint_index", -9)) + 3) % 6, tag + "das zweite Schiff startet auf dem gegenueberliegenden Wegpunkt: %s und %s" % [str(a.get("waypoint_index")), str(b.get("waypoint_index"))])
	var bad := 0
	var moved := 0.0
	var start_b: Vector2 = _pose(env, "ship2").position_plane
	var last_idx := {"ship":int(_sortie(env, "ship").waypoint_index), "ship2":int(_sortie(env, "ship2").waypoint_index)}
	var switches := {"ship":0, "ship2":0}
	for _i in range(600):
		_tick(env, DT)
		for id in ["ship", "ship2"]:
			var now_idx: int = int(_sortie(env, id).waypoint_index)
			if now_idx != int(last_idx[id]):
				last_idx[id] = now_idx
				switches[id] = int(switches[id]) + 1
		for id in ["ship", "ship2"]:
			var reason := String(env.combat.get_flight_status(id).get("reason", ""))
			if reason == "occupied" or reason == "navigation_claimed":
				bad += 1
		moved = maxf(moved, _pose(env, "ship2").position_plane.distance_to(start_b))
	_check(bad == 0, tag + "30 s ohne occupied/navigation_claimed im Flugstatus (%d Meldungen)" % bad)
	_check(int(switches.ship) >= 2 and int(switches.ship2) >= 2, tag + "in 30 s wechseln beide Schiffe mindestens zweimal den Wegpunkt: %s" % str(switches))
	_check(moved > 1.0 and env.mission_root.is_air_support_craft_airborne("ship") and env.mission_root.is_air_support_craft_airborne("ship2"), tag + "beide kreisen")
	var fuel_ids: Array = [_sortie(env, "ship").sortie_serial, _sortie(env, "ship2").sortie_serial]
	_check(fuel_ids[0] != fuel_ids[1], tag + "jede Sortie hat eine eigene Seriennummer")
	env.flow.free()


## Fall 8: Rolle beenden (Kreisen aus): das Schiff haelt die Position.
func _case_8() -> void:
	var tag := "[8 Kreisen aus] "
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	_circle(env, "ship", Vector2i(10, 10), "cas", "c8")
	_tick(env, 10.0)
	var res: Dictionary = mission_root.request_air_support_role_clear("ship", "clear8")
	_check(bool(res.get("ok", false)) and not bool(res.get("already_clear", false)) and String(res.get("message", "")) == "Kreisen beendet; das Schiff hält die Position." and not res.has("cease_fire_reason"), tag + "angenommen, Meldung wortlich, ohne cease_fire_reason: " + str(res))
	_tick(env, 3.0)
	var speed: float = _pose(env, "ship").velocity_plane.length()
	_check(speed < 0.1, tag + "nach 3 s Tempo unter 0,1 (%.3f)" % speed)
	var sortie: Dictionary = _sortie(env, "ship")
	_check(Array(sortie.get("waypoints", [1])).is_empty() and Dictionary(sortie.get("air_role", {1:1})).is_empty() and String(sortie.get("returning", "x")) == "" and mission_root.is_air_support_craft_airborne("ship"), tag + "Wegpunkte und Rolle leer, Schiff noch in der Luft")
	_check(_count(env, "ship", "role_ended") == 1, tag + "Ereignis role_ended genau einmal")
	var pose_a: Vector2 = _pose(env, "ship").position_plane
	_tick(env, 5.0)
	_check(_pose(env, "ship").position_plane.distance_to(pose_a) < 0.1, tag + "danach haelt es die Position (keine neue Rundbahn)")
	var second: Dictionary = mission_root.request_air_support_role_clear("ship", "clear8b")
	_check(bool(second.get("ok", false)) and bool(second.get("already_clear", false)), tag + "ohne Rolle: already_clear")
	env.flow.free()


## Fall 9: Landen aus der Rundbahn, auch bei belegter Landezone.
func _case_9() -> void:
	var tag := "[9 Landen] "
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	_circle(env, "ship", Vector2i(10, 10), "none", "c9")
	_tick(env, 12.0)
	var res: Dictionary = mission_root.request_air_support_landing("ship")
	_check(bool(res.get("ok", false)) and bool(res.get("landing_pending", false)) and String(res.get("message", "")) == "Fliegt zur Landezone und landet.", tag + "Landen aus der Rundbahn: landing_pending: " + str(res))
	_check(_count(env, "ship", "landing_pending") == 1 and String(_sortie(env, "ship").get("returning", "")) == "player" and Array(_sortie(env, "ship").waypoints).is_empty(), tag + "Ereignis landing_pending, Rueckflug 'player', Rundbahn weg")
	var waited := 0.0
	while mission_root.get("_air_support_sorties").has("ship") and waited < 30.0:
		_tick(env, 0.5)
		waited += 0.5
	_check(not mission_root.get("_air_support_sorties").has("ship") and not mission_root.is_air_support_craft_airborne("ship"), tag + "nach hoechstens 30 s gelandet (%.1f s)" % waited)
	_check(_count(env, "ship", "landed") == 1, tag + "Ereignis landed genau einmal")
	var snap: Dictionary = mission_root.get_air_support_role_snapshot("ship")
	_check(not bool(snap.get("ok", true)) and not bool(snap.get("airborne", true)) and not env.combat.get_flight_controls().has("ship"), tag + "danach keine Rundbahn-Daten und keine Flugsteuerung mehr")
	env.flow.free()
	# Landezone belegt: das Schiff wartet, die Meldung kommt genau einmal.
	var env2: Dictionary = _build("cutlass", ["ship"])
	var root2: Node = env2.mission_root
	env2.transport.parked["ship"] = true
	_circle(env2, "ship", Vector2i(10, 10), "air_defense", "c9b")
	_tick(env2, 8.0)
	env2.transport.landing_clear = false
	_check(bool(root2.request_air_support_landing("ship").get("ok", false)), tag + "Landen bei belegter Landezone wird angenommen (das Schiff fliegt erst hin)")
	_tick(env2, 25.0)
	var held: Dictionary = _pose(env2, "ship")
	_check(root2.is_air_support_craft_airborne("ship") and _count(env2, "ship", "landing_blocked") == 1 and held.position_plane.distance_to(_plane(Vector2i(10, 10))) <= 0.15 and held.velocity_plane.length() <= 0.1, tag + "wartet ueber der Landezone, landing_blocked genau einmal (%d)" % _count(env2, "ship", "landing_blocked"))
	env2.transport.landing_clear = true
	_tick(env2, 3.0)
	_check(not root2.is_air_support_craft_airborne("ship") and _count(env2, "ship", "landed") == 1 and _count(env2, "ship", "landing_blocked") == 1, tag + "Landezone frei: das Schiff landet")
	env2.flow.free()


## Fall 10: Ankunft im Modus Kreisen fliegt eine echte Rundbahn um die Landezone.
func _case_10() -> void:
	var tag := "[10 Ankunft] "
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	var lz: Vector2 = env.terrain.grid_to_world(Vector2i(10, 10))
	var res: Dictionary = mission_root.request_air_support_arrival("ship", lz)
	_check(bool(res.get("ok", false)), tag + "Ankunft angenommen: " + str(res))
	var sortie: Dictionary = _sortie(env, "ship")
	var role: Dictionary = Dictionary(sortie.get("air_role", {}))
	var wps: Array = Array(sortie.get("waypoints", []))
	var same := wps.size() == 6
	for cell in _ring(Vector2i(10, 10)):
		same = same and wps.has(cell)
	_check(role.get("role") == "none" and role.get("center_hex") == Vector2i(10, 10), tag + "Rolle none, Mitte = Landezone: " + str(role))
	_check(same, tag + "Wegpunkte = die Ringzellen um die Landezone: " + str(wps))
	var idx: int = int(sortie.waypoint_index)
	var switches := 0
	for _i in range(600):
		_tick(env, DT)
		var s: Dictionary = _sortie(env, "ship")
		if int(s.waypoint_index) != idx:
			idx = int(s.waypoint_index)
			switches += 1
	_check(switches >= 1, tag + "nach 30 s mindestens ein Wegpunktwechsel: %d" % switches)
	_check(mission_root.is_air_support_craft_airborne("ship") and _pose(env, "ship").position_plane.distance_to(_plane(Vector2i(10, 10))) > 2.0, tag + "das Schiff fliegt auf der Rundbahn, nicht ueber der Mitte (Abstand %.2f)" % _pose(env, "ship").position_plane.distance_to(_plane(Vector2i(10, 10))))
	env.flow.free()


## Fall 11: Fliegen von Hand beendet die Rolle.
func _case_11() -> void:
	var tag := "[11 Fliegen von Hand] "
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	_circle(env, "ship", Vector2i(10, 10), "cas", "c11")
	_tick(env, 5.0)
	var res: Dictionary = mission_root.request_air_support_move({"craft_id":"ship", "target_hex":Vector2i(14, 10), "request_id":"mv11"})
	_check(bool(res.get("ok", false)), tag + "Fliegen angenommen: " + str(res))
	var sortie: Dictionary = _sortie(env, "ship")
	_check(Dictionary(sortie.get("air_role", {1:1})).is_empty() and Array(sortie.get("waypoints", [1])).is_empty(), tag + "Rolle und Wegpunkte leer")
	_tick(env, 25.0)
	_check(_pose(env, "ship").position_plane.distance_to(_plane(Vector2i(14, 10))) < 0.5, tag + "das Schiff fliegt zum Feld (Abstand %.2f)" % _pose(env, "ship").position_plane.distance_to(_plane(Vector2i(14, 10))))
	_check(_count(env, "ship", "role_ended") == 1, tag + "Ereignis role_ended genau einmal")
	var far: Dictionary = mission_root.request_air_support_landing("ship")
	_check(not bool(far.get("ok", true)) and String(far.get("reason", "")) == "not_at_landing_site" and String(_sortie(env, "ship").get("returning", "x")) == "", tag + "von Hand weggeflogen: Landen bleibt not_at_landing_site, kein Rueckflug")
	env.flow.free()


## Hilfen fuer 13-15: ein zweites Schiff ("blocker") startet von Hand und beansprucht auf Wunsch alle Felder der Karte.
func _blocked_env(ship_parked: bool) -> Dictionary:
	var env: Dictionary = _build("cutlass", ["ship", "blocker"], {"ship":Vector2i(10, 10), "blocker":Vector2i(15, 15)})
	env.transport.parked["blocker"] = true
	_check(bool(env.mission_root.request_air_support_takeoff("blocker").get("ok", false)), "Aufbau: Blocker startet von Hand")
	env.transport.parked["blocker"] = false
	env.transport.parked["ship"] = ship_parked
	return env


## mode "all": alle Felder; "band": alle Felder im Abstand 3 bis 5 um (10,10) (die Rundbahn, nicht die Landezone); "none": nur ein fernes Feld.
func _claim(env: Dictionary, mode: String) -> void:
	var cells: Array[Vector2i] = []
	if mode == "none":
		cells.append(Vector2i(19, 19))
	else:
		for q in range(5, 20):
			for r in range(5, 20):
				var d: int = maxi(maxi(absi(q - 10), absi(r - 10)), absi(q + r - 20))
				if mode == "all" or (d >= 3 and d <= 5):
					cells.append(Vector2i(q, r))
	_check(bool(env.combat.record_navigation_claim("blocker", "atmosphere:moon_site", cells).get("ok", false)), "Aufbau: Anspruch des Blockers (%s)" % mode)


## Fall 13 (W1): gelandetes Schiff, Rundbahn nicht moeglich -> Ablehnung OHNE Start, nichts veraendert.
func _case_13() -> void:
	var tag := "[13 kein Start ohne Rundbahn] "
	var env: Dictionary = _blocked_env(true)
	var mission_root: Node = env.mission_root
	_claim(env, "band")
	var pose_before: Dictionary = _pose(env, "ship")
	var sorties_before: Array = mission_root.get("_air_support_sorties").keys()
	var wings_before: Dictionary = env.source.get("_space_wing_state").get_snapshot()
	var res: Dictionary = _circle(env, "ship", Vector2i(10, 10), "cas", "c13")
	_check(not bool(res.get("ok", true)) and String(res.get("reason", "")) == "navigation_claimed" and not bool(res.get("took_off", false)), tag + "abgelehnt mit dem Grund der Rundbahn, kein took_off: " + str(res))
	_check(_pose(env, "ship") == pose_before and not mission_root.is_air_support_craft_airborne("ship") and mission_root.get("_air_support_sorties").keys() == sorties_before, tag + "Pose und Sortie-Bestand unveraendert, kein Start")
	_check(Dictionary(mission_root.get("_air_role_receipts")).is_empty() and env.events.is_empty() and env.source.get("_space_wing_state").get_snapshot() == wings_before, tag + "kein Beleg, kein Ereignis, Rotte unveraendert")
	_claim(env, "none")
	var retry: Dictionary = _circle(env, "ship", Vector2i(10, 10), "cas", "c13")
	_check(bool(retry.get("ok", false)) and bool(retry.get("took_off", false)) and mission_root.is_air_support_craft_airborne("ship"), tag + "Rundbahn frei: dieselbe Kennung startet und kreist: " + str(retry))
	env.flow.free()


## Fall 13b (W1, Nachlauf): scheitert die Rundbahn trotzdem erst nach dem Start, landet das Schiff sofort wieder.
func _case_13b() -> void:
	var tag := "[13b Rueckwaerts landen] "
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	var pose_before: Dictionary = _pose(env, "ship")
	_check(bool(mission_root.request_air_support_takeoff("ship").get("ok", false)) and mission_root.is_air_support_craft_airborne("ship"), tag + "Aufbau: das Schiff ist gestartet")
	env.transport.parked["ship"] = false
	var out: Dictionary = mission_root._air_undo_circle_start("ship", {"ok":false, "reason":"navigation_claimed"})
	_check(not bool(out.get("ok", true)) and String(out.get("reason", "")) == "navigation_claimed" and out.has("took_off") and not bool(out.took_off), tag + "ok:false mit dem Grund der Rundbahn und took_off:false: " + str(out))
	_check(not mission_root.is_air_support_craft_airborne("ship") and not mission_root.get("_air_support_sorties").has("ship") and _pose(env, "ship").position_plane == pose_before.position_plane and _pose(env, "ship").space_area_id == pose_before.space_area_id, tag + "das Schiff steht wieder am Boden, keine Sortie")
	_check(_count(env, "ship", "role_ended") == 1 and _count(env, "ship", "landed") == 0 and env.events.size() == 1 and env.events[0].text == "Rundbahn nicht möglich – Schiff bleibt gelandet.", tag + "genau ein Ereignis role_ended mit dem Wortlaut (kein landed): " + str(env.events))
	env.flow.free()


## Fall 14 (K2): dauerhaft blockierte Rundbahn meldet sich genau einmal; frei -> weiter; erneut blockiert -> wieder einmal.
func _case_14() -> void:
	var tag := "[14 blockierte Rundbahn] "
	var env: Dictionary = _blocked_env(true)
	var mission_root: Node = env.mission_root
	var res: Dictionary = _circle(env, "ship", Vector2i(10, 10), "none", "c14")
	_check(bool(res.get("ok", false)), tag + "Aufbau: Rundbahn laeuft: " + str(res))
	_tick(env, 6.0)
	_check(_count(env, "ship", "role_blocked") == 0, tag + "frei: keine Blockiermeldung")
	_claim(env, "all")
	_tick(env, 40.0)
	var first: Array = []
	for event in env.events:
		if event.kind == "role_blocked":
			first.append(event)
	_check(first.size() == 1 and first[0].craft_id == "ship" and first[0].text == "Rundbahn blockiert – das Schiff hält die Position.", tag + "nach 5 s Blockade genau ein Ereignis mit dem Wortlaut: " + str(first))
	var sortie: Dictionary = _sortie(env, "ship")
	_check(bool(sortie.get("ring_blocked_reported", false)) and float(sortie.get("ring_blocked_seconds", 0.0)) >= 5.0 and mission_root.is_air_support_craft_airborne("ship"), tag + "Merker gesetzt, Schiff weiter in der Luft")
	_tick(env, 30.0)
	_check(_count(env, "ship", "role_blocked") == 1, tag + "nach weiteren 30 s weiter genau eins: %d" % _count(env, "ship", "role_blocked"))
	_claim(env, "none")
	var idx: int = int(_sortie(env, "ship").waypoint_index)
	var switches := 0
	for _i in range(400):
		_tick(env, DT)
		var s: Dictionary = _sortie(env, "ship")
		if int(s.waypoint_index) != idx:
			idx = int(s.waypoint_index)
			switches += 1
	_check(switches >= 1, tag + "Ring frei: Wegpunktwechsel laufen wieder (%d in 20 s)" % switches)
	_check(not bool(_sortie(env, "ship").get("ring_blocked_reported", true)) and float(_sortie(env, "ship").get("ring_blocked_seconds", 1.0)) == 0.0, tag + "Merker und Zaehler zurueckgesetzt")
	_claim(env, "all")
	_tick(env, 60.0)
	_check(_count(env, "ship", "role_blocked") == 2, tag + "erneut blockiert: meldet sich wieder genau einmal (insgesamt %d)" % _count(env, "ship", "role_blocked"))
	env.flow.free()


## Fall 15 (K3): Kreisen eines fliegenden Schiffs prueft Quelle, Quellen-Gleichheit und Flug-Instanz wie das Fliegen von Hand.
func _case_15() -> void:
	var tag := "[15 Kontext] "
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "c15").get("ok", false)), tag + "Aufbau: Rundbahn laeuft")
	var sortie: Dictionary = _sortie(env, "ship")
	var wps_before: Array = Array(sortie.waypoints).duplicate()
	var started_before: int = _count(env, "ship", "role_started")
	var receipts_before: int = Dictionary(mission_root.get("_air_role_receipts")).size()
	# a) die Quelle rechnet gerade einen Takt
	env.source.is_processing_tick = true
	var busy: Dictionary = _circle(env, "ship", Vector2i(12, 10), "cas", "c15a")
	var busy_move: Dictionary = mission_root.request_air_support_move({"craft_id":"ship", "target_hex":Vector2i(12, 10), "request_id":"mv15a"})
	env.source.is_processing_tick = false
	_check(String(busy.get("reason", "")) == "sortie_context_changed" and String(busy_move.get("reason", "")) == String(busy.get("reason", "")), tag + "Quelle im Takt: sortie_context_changed wie beim Fliegen: " + str(busy) + " / " + str(busy_move))
	# b) andere Quelle in der Sortie
	var own_source: Variant = sortie["source"]
	sortie["source"] = weakref(env.flow)
	var other_source: Dictionary = _circle(env, "ship", Vector2i(12, 10), "cas", "c15b")
	var other_move: Dictionary = mission_root.request_air_support_move({"craft_id":"ship", "target_hex":Vector2i(12, 10), "request_id":"mv15b"})
	sortie["source"] = own_source
	_check(String(other_source.get("reason", "")) == "sortie_context_changed" and String(other_move.get("reason", "")) == String(other_source.get("reason", "")), tag + "andere Quelle: sortie_context_changed wie beim Fliegen: " + str(other_source))
	# c) andere Flug-Instanz in der Sortie
	var own_flight: Variant = sortie["flight"]
	sortie["flight"] = RefCounted.new()
	var other_flight: Dictionary = _circle(env, "ship", Vector2i(12, 10), "cas", "c15c")
	var other_flight_move: Dictionary = mission_root.request_air_support_move({"craft_id":"ship", "target_hex":Vector2i(12, 10), "request_id":"mv15c"})
	sortie["flight"] = own_flight
	_check(String(other_flight.get("reason", "")) == "sortie_context_changed" and String(other_flight_move.get("reason", "")) == String(other_flight.get("reason", "")), tag + "andere Flug-Instanz: sortie_context_changed wie beim Fliegen: " + str(other_flight))
	_check(Array(_sortie(env, "ship").waypoints) == wps_before and _count(env, "ship", "role_started") == started_before and Dictionary(mission_root.get("_air_role_receipts")).size() == receipts_before and Dictionary(_sortie(env, "ship").air_role).get("center_hex") == Vector2i(10, 10), tag + "alle drei Ablehnungen lassen Rundbahn, Rolle, Belege und Ereignisse unveraendert")
	var good: Dictionary = _circle(env, "ship", Vector2i(12, 10), "cas", "c15d")
	_check(bool(good.get("ok", false)) and Dictionary(_sortie(env, "ship").air_role).get("center_hex") == Vector2i(12, 10), tag + "mit unversehrtem Kontext geht derselbe Befehl: " + str(good))
	env.flow.free()


## Fall 16 (K6, K7): Kreisen aus prueft die Form; ein gescheiterter Feuerstopp steht als cease_fire_reason in der Antwort; Adapter-Zweige.
func _case_16() -> void:
	var tag := "[16 Kreisen aus: Form und Adapter] "
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "cas", "c16").get("ok", false)), tag + "Aufbau: Rolle laeuft")
	var no_craft: Dictionary = mission_root.request_air_support_role_clear("", "clear16")
	var no_request: Dictionary = mission_root.request_air_support_role_clear("ship", "")
	var long_request: Dictionary = mission_root.request_air_support_role_clear("ship", "x".repeat(129))
	_check(String(no_craft.get("reason", "")) == "invalid_command" and String(no_request.get("reason", "")) == "invalid_command" and String(long_request.get("reason", "")) == "invalid_command" and not bool(no_craft.get("ok", true)) and not bool(no_request.get("ok", true)) and not bool(long_request.get("ok", true)), tag + "ohne Schiff, ohne Kennung, Kennung zu lang: invalid_command")
	_check(not Dictionary(_sortie(env, "ship").air_role).is_empty() and not Array(_sortie(env, "ship").waypoints).is_empty() and _count(env, "ship", "role_ended") == 0, tag + "die Rolle laeuft unveraendert weiter")
	var long_ok: Dictionary = mission_root.request_air_support_role_clear("ship", "y".repeat(128))
	_check(bool(long_ok.get("ok", false)) and not bool(long_ok.get("already_clear", true)), tag + "128 Zeichen sind erlaubt: " + str(long_ok))
	# Adapter: Form
	var adapter: Node = env.adapter
	var a_none: Dictionary = adapter.request_operation("air_support_role_clear", {"request_id":"r16"})
	var a_type: Dictionary = adapter.request_operation("air_support_role_clear", {"craft_id":5, "request_id":"r16"})
	_check(not bool(a_none.get("ok", true)) and String(a_none.get("reason", "")) == "invalid_command" and not bool(a_type.get("ok", true)) and String(a_type.get("reason", "")) == "invalid_command", tag + "Adapter: fehlende oder falsche craft_id -> invalid_command: " + str(a_none) + " / " + str(a_type))
	# Adapter: Kreisen (Erfolg und Ablehnung) und Kreisen aus (Erfolg)
	var a_ok: Dictionary = adapter.request_operation("air_support_circle", {"craft_id":"ship", "center_hex":Vector2i(12, 10), "role":"air_defense", "request_id":"a16"})
	_check(bool(a_ok.get("ok", false)) and String(a_ok.get("message", "")) == "Luftschutz an Feld (12, 10)." and Dictionary(_sortie(env, "ship").air_role).get("role") == "air_defense", tag + "Adapter air_support_circle: Erfolg: " + str(a_ok))
	var a_bad: Dictionary = adapter.request_operation("air_support_circle", {"craft_id":"ship", "center_hex":Vector2i(40, 40), "role":"cas", "request_id":"a16b"})
	_check(not bool(a_bad.get("ok", true)) and String(a_bad.get("reason", "")) == "role_point_off_map" and Dictionary(_sortie(env, "ship").air_role).get("center_hex") == Vector2i(12, 10), tag + "Adapter air_support_circle: Ablehnung role_point_off_map, Rolle bleibt: " + str(a_bad))
	var a_clear: Dictionary = adapter.request_operation("air_support_role_clear", {"craft_id":"ship", "request_id":"a16c"})
	_check(bool(a_clear.get("ok", false)) and not bool(a_clear.get("already_clear", true)) and Array(_sortie(env, "ship").waypoints).is_empty(), tag + "Adapter air_support_role_clear: Erfolg: " + str(a_clear))
	env.flow.free()
	# Feuerstopp scheitert (Rotte haelt eine Anweisung, die kein Angriff ist) -> cease_fire_reason, Antwort bleibt ok.
	var env2: Dictionary = _build("cutlass", ["ship"])
	var root2: Node = env2.mission_root
	env2.transport.parked["ship"] = true
	_check(bool(_circle(env2, "ship", Vector2i(10, 10), "none", "c16b").get("ok", false)), tag + "Aufbau 2: Rundbahn laeuft")
	var binding: Dictionary = root2._resolve_air_support_craft("ship")
	var patrol: Array[Vector2i] = [Vector2i(10, 6), Vector2i(14, 10), Vector2i(10, 14)]
	var revision: int = binding.wings.get_snapshot().revision
	var issued: Dictionary = binding.wings.apply_command({"contract_category":"space_combat", "operation":"order_issue", "request_id":"order16", "expected_revision":revision, "payload":{"wing_ids":[binding.wing_id], "verb":"patrol", "stance":"normal", "contact_response":"observe", "fire_rule":"hold", "protect_radius":8.0, "pursuit_limit":4.0, "waypoints":patrol}}, {"authorized":true, "actor_id":"singleplayer", "phase":"tactical"})
	_check(bool(issued.get("ok", false)), tag + "Aufbau 2: Patrouille in der Rotte: " + str(issued))
	var cleared: Dictionary = root2.request_air_support_role_clear("ship", "clear16b")
	_check(bool(cleared.get("ok", false)) and not bool(cleared.get("already_clear", true)) and String(cleared.get("cease_fire_reason", "")) == "no_attack_order", tag + "Feuerstopp gescheitert: ok bleibt, cease_fire_reason = no_attack_order: " + str(cleared))
	env2.flow.free()


## Fall 17 (K10): Abschuss beendet Rolle und Rueckflug mit role_ended (kein landed); ohne Rolle kein Ereignis.
func _case_17() -> void:
	var tag := "[17 Abschuss] "
	var status := {"asset_id":"ship", "asset_type":"dropship", "state":"crashed", "integrity":0, "max_integrity":100}
	var env: Dictionary = _build("cutlass", ["ship"])
	var mission_root: Node = env.mission_root
	env.transport.parked["ship"] = true
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "cas", "c17").get("ok", false)), tag + "Aufbau: Rolle laeuft")
	_tick(env, 3.0)
	var down: Dictionary = mission_root.resolve_air_shootdown("ship", 0.0, "Cutlass", status)
	_check(bool(down.get("ok", false)) and not mission_root.get("_air_support_sorties").has("ship"), tag + "Abschuss aufgeloest, Sortie weg: " + str(down.get("outcome")))
	var ended: Array = []
	for event in env.events:
		if event.kind == "role_ended":
			ended.append(event)
	_check(ended.size() == 1 and ended[0].text == "Rolle beendet – Schiff nicht mehr in der Luft." and _count(env, "ship", "landed") == 0, tag + "genau ein role_ended mit dem Wortlaut, kein landed: " + str(env.events))
	env.flow.free()
	# Rueckflug
	var env2: Dictionary = _build("cutlass", ["ship"])
	var root2: Node = env2.mission_root
	env2.transport.parked["ship"] = true
	_circle(env2, "ship", Vector2i(10, 10), "none", "c17b")
	_tick(env2, 5.0)
	_check(bool(root2.request_air_support_landing("ship").get("ok", false)) and String(_sortie(env2, "ship").get("returning", "")) == "player", tag + "Aufbau 2: Rueckflug laeuft")
	var down2: Dictionary = root2.resolve_air_shootdown("ship", 0.0, "Cutlass", status)
	_check(bool(down2.get("ok", false)) and _count(env2, "ship", "role_ended") == 1 and _count(env2, "ship", "landed") == 0, tag + "im Rueckflug abgeschossen: genau ein role_ended, kein landed")
	env2.flow.free()
	# Ohne Rolle und ohne Rueckflug: kein Ereignis
	var env3: Dictionary = _build("cutlass", ["ship"])
	var root3: Node = env3.mission_root
	env3.transport.parked["ship"] = true
	_check(bool(root3.request_air_support_takeoff("ship").get("ok", false)), tag + "Aufbau 3: Start von Hand")
	var down3: Dictionary = root3.resolve_air_shootdown("ship", 0.0, "Cutlass", status)
	_check(bool(down3.get("ok", false)) and env3.events.is_empty(), tag + "ohne Rolle und Rueckflug kein Ereignis")
	env3.flow.free()


## Fall 12: ohne gebundene Luftunterstuetzung (Skirmish).
func _case_12() -> void:
	var tag := "[12 ohne Bindung] "
	var lone = ROOT_SCRIPT.new()
	var res: Dictionary = lone.request_air_support_circle({"craft_id":"ship", "center_hex":Vector2i(10, 10), "role":"none", "request_id":"c12"})
	_check(not bool(res.get("ok", true)) and String(res.get("reason", "")) == "air_source_unavailable", tag + "abgelehnt: " + str(res))
	lone.free()


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
	_case_10()
	_case_11()
	_case_12()
	_case_13()
	_case_13b()
	_case_14()
	_case_15()
	_case_16()
	_case_17()
	print("AIR_ROLE_CIRCLE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
