extends SceneTree
## Luftrollen 2: Treibstoff je Flugzeit (1 Einheit je 60 s Spielzeit), Warnung vor dem Heimflug, selbstaendiger Abbruch und Landung.
## Rein rechnerisch an einer kleinen Attrappen-Mission (wie air_role_circle_verifier), echter Versorgungsbesitzer mit den Daten aus
## trade_offers.json (satellite_crash>homebase: Ortsabflug 2, Sprung 10, Landung 0 -> Warnung bei <= 12, Abbruch bei <= 3).
const ROOT_SCRIPT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const TERRAIN_MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const DT := 0.05
const LOC := "satellite_crash"

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
	func _find_mission_dropship_card_entry(craft_id: String) -> Dictionary:
		return {"display_name":"Falke"} if craft_id == "ship" else {}


func _check(ok: bool, label: String) -> bool:
	if ok:
		_passed += 1
	else:
		_failed += 1
		print("AIR_FUEL FAIL: ", label)
	return ok


# ---------------------------------------------------------------- Aufbau
## Felder 5..19, Landezone (10,10). accounts: Schiff -> Tankinhalt; Schiffe ohne Eintrag haben KEIN Treibstoffkonto.
func _build(craft_ids: Array[String], accounts: Dictionary, grids: Dictionary = {}) -> Dictionary:
	var flow := FixFlow.new(); root.add_child(flow)
	var adapter = ADAPTER.new(); flow.add_child(adapter); adapter._flow = flow
	var source = ROOT_SCRIPT.new(); adapter.add_child(source); adapter._simulation = source
	var fleet = FLEET.new(); fleet.configure()
	var configs: Array[Dictionary] = []
	var pilots := {}
	for id in craft_ids:
		fleet.register_craft(id)
		configs.append({"craft_id":id, "model_id":"cutlass"})
		pilots[id] = "pilot_" + id
		flow._craft_location_runtime[id] = LOC
		flow._assigned_aircraft_pilot_by_craft[id] = "pilot_" + id
	var equipment = EQUIPMENT.new(); equipment.configure(configs)
	var supply = SUPPLY.new()
	_check(bool(supply.configure([], {}).get("ok", false)), "Aufbau: Versorgungsdaten aus trade_offers.json werden angenommen")
	for id in accounts:
		_check(supply.register_craft(String(id), float(accounts[id])), "Aufbau: Treibstoffkonto " + String(id))
	source.configure_singleplayer_owners(null, supply, null, fleet); source.configure_ship_equipment(equipment)
	source.configure_departure_adapter(adapter)
	source.get("_space_wing_state").ensure_flying_wings("singleplayer", craft_ids, craft_ids, pilots)
	var mission := Node.new(); mission.set_meta("location_id", LOC); flow.add_child(mission)
	var mission_root = ROOT_SCRIPT.new(); mission_root.name = "SimulationRoot"; mission.add_child(mission_root); flow._active_mission = mission
	_check(bool(adapter.bind_mission_air_support(mission).ok), "Aufbau: Luftunterstuetzung ist an die Mission gebunden")
	var terrain = TERRAIN.new(); terrain.name = "Terrain"; mission.add_child(terrain); terrain.configure_iso_grid(Vector2.ZERO, 64, 32, "hex_axial_v1")
	terrain.register_tile(TILE.new({"tile_id":"zero", "grid_position":Vector2i.ZERO, "explicit_hex_ramps":true}))
	var units = UNITS.new(); units.name = "Units"; mission.add_child(units)
	mission_root.unit_registry_path = mission_root.get_path_to(units); mission_root.terrain_registry_path = mission_root.get_path_to(terrain)
	var map = TERRAIN_MAP.create_empty(LOC, Vector2i(4, 3), Vector2.ZERO, 64, 32, 3, "hex_axial_v1"); map.set_tactical_grid_rules("hex_tactical_v1")
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
		transport.parked[id] = true
	source.tick_counter = 50
	var events: Array = []
	mission_root.air_role_event.connect(func(event: Dictionary) -> void: events.append(event))
	return {"flow":flow, "adapter":adapter, "source":source, "fleet":fleet, "mission_root":mission_root, "terrain":terrain, "transport":transport, "persons":persons, "events":events, "tick":50, "combat":source.get("_space_combat_state"), "supply":supply}


# ---------------------------------------------------------------- Helfer
## Tickt genau round(seconds / DT) Schritte (Spielzeit).
func _run(env: Dictionary, seconds: float) -> void:
	var source: Node = env.source
	var mission_root: Node = env.mission_root
	for _i in range(int(round(seconds / DT))):
		env.tick = int(env.tick) + 1
		source.tick_counter = int(env.tick)
		source._advance_space_flights(DT, int(env.tick))
		mission_root._advance_air_support_orders(DT)


func _sortie(env: Dictionary, id: String) -> Dictionary:
	var mission_root: Node = env.mission_root
	return Dictionary(mission_root.get("_air_support_sorties")).get(id, {})


func _count(env: Dictionary, id: String, kind: String) -> int:
	var n := 0
	for event in env.events:
		if event.craft_id == id and event.kind == kind:
			n += 1
	return n


func _texts(env: Dictionary, id: String, kind: String) -> Array:
	var out: Array = []
	for event in env.events:
		if event.craft_id == id and event.kind == kind:
			out.append(String(event.text))
	return out


func _circle(env: Dictionary, id: String, center: Vector2i, role: String, request_id: String) -> Dictionary:
	var mission_root: Node = env.mission_root
	return mission_root.request_air_support_circle({"craft_id":id, "center_hex":center, "role":role, "request_id":request_id})


func _fuel(env: Dictionary, id: String) -> float:
	return float(env.supply.get_fuel(id))


## Alle Belege, die mit "air-fuel:" beginnen (Kennung -> Ergebnis).
func _air_receipts(env: Dictionary) -> Array:
	var ids: Array = []
	for request_id in Dictionary(env.supply.get("_requests")).keys():
		if String(request_id).begins_with("air-fuel:"):
			ids.append(String(request_id))
	return ids


func _plane(cell: Vector2i) -> Vector2:
	return GRID.HEX.axial_to_plane(Vector2(cell))


func _air_command(craft_id: String, amount: float, request_id: String) -> Dictionary:
	return {"contract_category":"singleplayer_supply", "operation":"consume_air_fuel", "payload":{"craft_id":craft_id, "amount":amount}, "request_id":request_id}


# ---------------------------------------------------------------- Faelle
## Fall 1 und 4: Start 14.0, Rolle none; Minutentakt, genau eine Warnung, Abbruch bei 3.0; Guthaben unveraendert, kein Tankerauftrag.
func _case_1() -> void:
	var tag := "[1 Minutentakt] "
	var env: Dictionary = _build(["ship"], {"ship":14.0})
	var supply = env.supply
	var mission_root: Node = env.mission_root
	var credits_before: int = int(supply.get_supply_snapshot().credits)
	var receipts_before: int = Dictionary(supply.get("_requests")).size()
	var revision0: int = supply.get_revision()
	var res: Dictionary = _circle(env, "ship", Vector2i(10, 10), "none", "f1")
	_check(bool(res.get("ok", false)) and bool(res.get("took_off", false)), tag + "Aufbau: Start und Rundbahn: " + str(res))
	_check(is_equal_approx(_fuel(env, "ship"), 14.0) and Dictionary(supply.get("_requests")).size() == receipts_before, tag + "der Start bucht nichts")
	var sortie: Dictionary = _sortie(env, "ship")
	_check(is_equal_approx(float(sortie.get("fuel_seconds", -1.0)), 0.0) and int(sortie.get("fuel_steps", -1)) == 0 and not bool(sortie.get("fuel_warned", true)), tag + "Treibstoffuhr der neuen Sortie beginnt bei 0")
	var snap0: Dictionary = mission_root.get_air_support_role_snapshot("ship")
	_check(is_equal_approx(float(snap0.get("fuel", -9.0)), 14.0) and not bool(snap0.get("fuel_warned", true)), tag + "Schnappschuss: fuel 14.0, nicht gewarnt: " + str(snap0))
	_run(env, 59.9)
	_check(is_equal_approx(_fuel(env, "ship"), 14.0) and _air_receipts(env).is_empty(), tag + "nach 59,9 s noch 14.0, keine Buchung (%s)" % str(_fuel(env, "ship")))
	_run(env, 0.1)
	_check(is_equal_approx(_fuel(env, "ship"), 13.0) and _air_receipts(env).size() == 1, tag + "nach 60 s genau 13.0 (%s)" % str(_fuel(env, "ship")))
	var expected_id := "air-fuel:ship:%s:%d:1:r%d" % [LOC, int(sortie.sortie_serial), revision0]
	_check(_air_receipts(env) == [expected_id], tag + "Beleg-Kennung mit Ort, Serial, Schritt und Revision: erwartet %s, ist %s" % [expected_id, str(_air_receipts(env))])
	_check(_count(env, "ship", "fuel_warning") == 0, tag + "bei 13.0 noch keine Warnung")
	_run(env, 60.0)
	_check(is_equal_approx(_fuel(env, "ship"), 12.0) and _count(env, "ship", "fuel_warning") == 1, tag + "nach 120 s 12.0 und genau eine Warnung")
	_check(_texts(env, "ship", "fuel_warning") == ["Falke: Treibstoff 12 – reicht gerade noch für den Heimflug."], tag + "Warntext wortlich: " + str(_texts(env, "ship", "fuel_warning")))
	var snap1: Dictionary = mission_root.get_air_support_role_snapshot("ship")
	_check(bool(snap1.get("fuel_warned", false)) and is_equal_approx(float(snap1.get("fuel", -9.0)), 12.0) and String(snap1.get("returning", "x")) == "", tag + "Schnappschuss: gewarnt, fuel 12.0, kein Rueckflug")
	_run(env, 60.0)
	_check(is_equal_approx(_fuel(env, "ship"), 11.0) and _count(env, "ship", "fuel_warning") == 1, tag + "nach 180 s 11.0, keine zweite Warnung")
	_run(env, 480.0)
	var after: Dictionary = _sortie(env, "ship")
	_check(is_equal_approx(_fuel(env, "ship"), 3.0), tag + "nach 660 s genau 3.0 (%s)" % str(_fuel(env, "ship")))
	_check(String(after.get("returning", "")) == "fuel" and Dictionary(after.get("air_role", {})).is_empty() and Array(after.get("waypoints", [])).is_empty(), tag + "Rueckflug 'fuel', Rolle und Rundbahn leer")
	_check(_texts(env, "ship", "fuel_return") == ["Falke: Treibstoff 3 – Einsatz abgebrochen, fliegt zur Landezone und landet."] and _count(env, "ship", "landing_pending") == 1, tag + "Abbruchtext wortlich, einmal: " + str(_texts(env, "ship", "fuel_return")))
	var waited := 0.0
	while mission_root.get("_air_support_sorties").has("ship") and waited < 45.0:
		_run(env, 0.5)
		waited += 0.5
	_check(not mission_root.get("_air_support_sorties").has("ship") and _count(env, "ship", "landed") == 1, tag + "das Schiff landet selbst (%.1f s nach dem Abbruch)" % waited)
	# Nach Nachbesserung 1 (W1) bleibt je Schiff nur der juengste Beleg; die 11 Buchungen zeigen sich am Rest und am Schritt in der Kennung.
	_check(is_equal_approx(_fuel(env, "ship"), 3.0) and _air_receipts(env).size() == 1 and String(_air_receipts(env)[0]).contains(":11:r"), tag + "danach 3.0, 11 Buchungen (juengster Beleg Schritt 11): " + str(_air_receipts(env)))
	# Fall 4
	var tag4 := "[4 nichts von selbst] "
	_check(int(supply.get_supply_snapshot().credits) == credits_before, tag4 + "Guthaben unveraendert")
	_check(Dictionary(supply.get_open_tanker_orders()).is_empty(), tag4 + "kein Tankerauftrag")
	var all_air := true
	var new_receipts := 0
	for request_id in Dictionary(supply.get("_requests")).keys():
		new_receipts += 1
		if not String(request_id).begins_with("air-fuel:"): all_air = false
	_check(all_air and new_receipts - receipts_before == 1, tag4 + "alle neuen Belege beginnen mit air-fuel: (%d neue, nach W1 nur der juengste)" % (new_receipts - receipts_before))
	_check(_air_receipts(env).size() == 1 and String(_air_receipts(env)[0]).contains(":11:r"), tag4 + "der eine Beleg ist der der 11. Buchung")
	env.flow.free()


## Fall 2: Start 3.0 -> kein Lufteinsatz (Kreisen am gelandeten Schiff und Ankunft).
func _case_2() -> void:
	var tag := "[2 zu wenig Treibstoff] "
	var env: Dictionary = _build(["ship"], {"ship":3.0})
	var mission_root: Node = env.mission_root
	var pose_before: Dictionary = env.fleet.get_flight_state("ship").get_snapshot()
	var res: Dictionary = _circle(env, "ship", Vector2i(10, 10), "none", "f2")
	_check(not bool(res.get("ok", true)) and String(res.get("reason", "")) == "air_fuel_low" and String(res.get("message", "")) == "Treibstoff reicht nur noch für den Abflug vom Ort – kein Lufteinsatz.", tag + "Kreisen abgelehnt mit air_fuel_low und Text: " + str(res))
	_check(not mission_root.is_air_support_craft_airborne("ship") and Dictionary(mission_root.get("_air_support_sorties")).is_empty() and env.fleet.get_flight_state("ship").get_snapshot() == pose_before and env.events.is_empty(), tag + "kein Start, keine Sortie, Pose und Ereignisse unveraendert")
	_check(Dictionary(mission_root.get("_air_role_receipts")).is_empty(), tag + "kein Rollenbeleg")
	var arrival: Dictionary = mission_root.request_air_support_arrival("ship", env.terrain.grid_to_world(Vector2i(10, 10)))
	_check(not bool(arrival.get("ok", true)) and String(arrival.get("reason", "")) == "air_fuel_low" and Dictionary(mission_root.get("_air_support_sorties")).is_empty(), tag + "Ankunft abgelehnt mit air_fuel_low: " + str(arrival))
	_check(_air_receipts(env).is_empty() and is_equal_approx(_fuel(env, "ship"), 3.0), tag + "nichts gebucht")
	env.flow.free()
	# Knapp darueber (3.5) darf starten.
	var env2: Dictionary = _build(["ship"], {"ship":3.5})
	var ok2: Dictionary = _circle(env2, "ship", Vector2i(10, 10), "none", "f2b")
	_check(bool(ok2.get("ok", false)), tag + "mit 3.5 ist der Start erlaubt: " + str(ok2))
	env2.flow.free()


## Fall 3: Schiff ohne Konto.
func _case_3() -> void:
	var tag := "[3 ohne Konto] "
	var env: Dictionary = _build(["ship", "other"], {"other":14.0})
	var mission_root: Node = env.mission_root
	var revision: int = env.supply.get_revision()
	var res: Dictionary = _circle(env, "ship", Vector2i(10, 10), "none", "f3")
	_check(bool(res.get("ok", false)), tag + "Aufbau: Kreisen ohne Konto ist erlaubt: " + str(res))
	_run(env, 300.0)
	var snap: Dictionary = mission_root.get_air_support_role_snapshot("ship")
	_check(is_equal_approx(float(snap.get("fuel", 0.0)), -1.0) and not bool(snap.get("fuel_warned", true)), tag + "fuel == -1.0, nicht gewarnt: " + str(snap))
	_check(_air_receipts(env).is_empty() and env.supply.get_revision() == revision and _count(env, "ship", "fuel_return") == 0 and String(_sortie(env, "ship").get("returning", "x")) == "", tag + "300 s ohne Buchung, ohne Abbruch")
	env.flow.free()


## Fall 5: Start 4.0, Landezone belegt: Tank laeuft leer, nie negativ, das Schiff wartet und landet erst bei freier Zone.
func _case_5() -> void:
	var tag := "[5 Landezone belegt] "
	var env: Dictionary = _build(["ship"], {"ship":4.0})
	var mission_root: Node = env.mission_root
	var supply = env.supply
	var credits_before: int = int(supply.get_supply_snapshot().credits)
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "f5").get("ok", false)), tag + "Aufbau: Kreisen mit 4.0")
	env.transport.landing_clear = false
	_run(env, 60.0)
	_check(is_equal_approx(_fuel(env, "ship"), 3.0) and String(_sortie(env, "ship").get("returning", "")) == "fuel", tag + "bei 60 s Rest 3.0 und Rueckflug 'fuel'")
	_check(_count(env, "ship", "fuel_warning") == 0 and _count(env, "ship", "fuel_return") == 1, tag + "Abbruch ohne vorherige Warnung (Rest war schon unter der Heimflugschwelle), ein fuel_return")
	_run(env, 100.0)
	_check(_count(env, "ship", "landing_blocked") == 1 and mission_root.is_air_support_craft_airborne("ship"), tag + "landing_blocked genau einmal, das Schiff schwebt weiter")
	_run(env, 140.0)
	_check(is_equal_approx(_fuel(env, "ship"), 0.0) and _fuel(env, "ship") >= 0.0, tag + "nach weiteren 240 s Rest 0.0, nie negativ (%s)" % str(_fuel(env, "ship")))
	_check(_air_receipts(env).size() == 1 and String(_air_receipts(env)[0]).contains(":4:r"), tag + "insgesamt genau 4 Buchungen (juengster beleg Schritt 4): " + str(_air_receipts(env)))
	_run(env, 120.0)
	_check(_air_receipts(env).size() == 1 and String(_air_receipts(env)[0]).contains(":4:r") and is_equal_approx(_fuel(env, "ship"), 0.0) and _count(env, "ship", "landing_blocked") == 1 and mission_root.is_air_support_craft_airborne("ship"), tag + "bei 0 keine Buchung mehr (Beleg unveraendert Schritt 4), kein Absturz, weiter genau ein landing_blocked")
	var pose: Dictionary = env.fleet.get_flight_state("ship").get_snapshot()
	_check(pose.position_plane.distance_to(_plane(Vector2i(10, 10))) <= 0.15, tag + "wartet ueber der Landezone")
	env.transport.landing_clear = true
	var waited := 0.0
	while mission_root.get("_air_support_sorties").has("ship") and waited < 20.0:
		_run(env, 0.5)
		waited += 0.5
	_check(not mission_root.get("_air_support_sorties").has("ship") and _count(env, "ship", "landed") == 1, tag + "Landezone frei -> Landung (%.1f s)" % waited)
	var preview: Dictionary = supply.preview_leg_fuel({"craft_id":"ship", "leg":"surface_exit", "origin_location_id":LOC, "destination_location_id":"homebase"}, {"departure_authorized":true})
	_check(not bool(preview.get("ok", true)) and String(preview.get("reason", "")) == "leg_fuel_insufficient" and String(preview.get("message", "")) == "Treibstoff reicht nicht für den Rückflug", tag + "danach meldet der Ortsabflug 'Treibstoff reicht nicht fuer den Rueckflug': " + str(preview))
	_check(int(supply.get_supply_snapshot().credits) == credits_before and Dictionary(supply.get_open_tanker_orders()).is_empty(), tag + "Guthaben unveraendert, kein Tankerauftrag von selbst")
	env.flow.free()


## Fall 6: zwei Schiffe, getrennte Konten und Kennungen.
func _case_6() -> void:
	var tag := "[6 zwei Schiffe] "
	var env: Dictionary = _build(["ship", "ship2"], {"ship":14.0, "ship2":14.0}, {"ship":Vector2i(8, 8), "ship2":Vector2i(12, 12)})
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "air_defense", "f6a").get("ok", false)) and bool(_circle(env, "ship2", Vector2i(10, 10), "air_defense", "f6b").get("ok", false)), tag + "Aufbau: beide kreisen")
	_run(env, 120.0)
	_check(is_equal_approx(_fuel(env, "ship"), 12.0) and is_equal_approx(_fuel(env, "ship2"), 12.0), tag + "nach 120 s je 12.0")
	var ids: Array = _air_receipts(env)
	var distinct := {}
	for id in ids: distinct[id] = true
	_check(ids.size() == 2 and distinct.size() == 2 and str(ids).contains("air-fuel:ship:") and str(ids).contains("air-fuel:ship2:") and str(ids).contains(":2:r"), tag + "vier Buchungen (nach W1 je Schiff der juengste Beleg, Schritt 2) mit verschiedenen Kennungen: " + str(ids))
	_check(_count(env, "ship", "fuel_warning") == 1 and _count(env, "ship2", "fuel_warning") == 1, tag + "jedes Schiff warnt einmal")
	_check(_texts(env, "ship2", "fuel_warning") == ["ship2: Treibstoff 12 – reicht gerade noch für den Heimflug."], tag + "ohne Kartenname steht die Kennung im Text: " + str(_texts(env, "ship2", "fuel_warning")))
	env.flow.free()


## Fall 7: der Pilot verschwindet nach 30 s: die Buchung bei 60 s laeuft trotzdem.
func _case_7() -> void:
	var tag := "[7 Pilot weg] "
	var env: Dictionary = _build(["ship"], {"ship":14.0})
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "f7").get("ok", false)), tag + "Aufbau: Kreisen")
	_run(env, 30.0)
	env.persons["ship"].set_meta("dropship_embarked", false)
	env.transport.boarded = false
	_run(env, 30.0)
	_check(is_equal_approx(_fuel(env, "ship"), 13.0) and _air_receipts(env).size() == 1, tag + "bei 60 s trotzdem 13.0 und eine Buchung (%s)" % str(_fuel(env, "ship")))
	_run(env, 60.0)
	_check(is_equal_approx(_fuel(env, "ship"), 12.0), tag + "auch ohne Pilot weiter je Minute (12.0)")
	env.flow.free()


## Fall 8: Spielzeit, nicht Echtzeit: delta 0 bucht nie.
func _case_8() -> void:
	var tag := "[8 delta 0] "
	var env: Dictionary = _build(["ship"], {"ship":14.0})
	var mission_root: Node = env.mission_root
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "f8").get("ok", false)), tag + "Aufbau: Kreisen")
	var revision: int = env.supply.get_revision()
	for _i in range(1000):
		mission_root._advance_air_support_orders(0.0)
	_check(is_equal_approx(_fuel(env, "ship"), 14.0) and _air_receipts(env).is_empty() and env.supply.get_revision() == revision, tag + "1000 Ticks mit delta 0.0: keine Buchung")
	_check(is_equal_approx(float(_sortie(env, "ship").get("fuel_seconds", -1.0)), 0.0), tag + "Treibstoffuhr steht")
	env.flow.free()


## Fall 9: Versorgungsbefehl consume_air_fuel.
func _case_9() -> void:
	var tag := "[9 Befehl] "
	var supply = SUPPLY.new()
	supply.configure([], {})
	supply.register_craft("ship", 14.0)
	var denied: Dictionary = supply.apply_command(_air_command("ship", 1.0, "air-fuel:ship:dep:1:1:r1"))
	_check(not bool(denied.get("ok", true)) and String(denied.get("reason", "")) == "air_fuel_not_authorized" and is_equal_approx(supply.get_fuel("ship"), 14.0), tag + "ohne Kontext air_fuel_not_authorized, nichts gebucht: " + str(denied))
	var forged: Dictionary = supply.apply_command(_air_command("ship", 1.0, "air-fuel:ship:dep:1:1:r1"), {"air_fuel_authorized":"yes"})
	_check(not bool(forged.get("ok", true)) and String(forged.get("reason", "")) == "air_fuel_not_authorized", tag + "ein anderer Wert als true genuegt nicht")
	var ctx := {"air_fuel_authorized":true}
	var first: Dictionary = supply.apply_command(_air_command("ship", 1.0, "air-fuel:ship:dep:1:1:r1"), ctx)
	_check(bool(first.get("ok", false)) and not first.has("replayed") and String(first.get("craft_id", "")) == "ship" and is_equal_approx(float(first.get("consumed", -1.0)), 1.0) and is_equal_approx(float(first.get("fuel", -1.0)), 13.0) and is_equal_approx(supply.get_fuel("ship"), 13.0), tag + "erste Buchung: consumed 1.0, fuel 13.0: " + str(first))
	var again: Dictionary = supply.apply_command(_air_command("ship", 1.0, "air-fuel:ship:dep:1:1:r1"), ctx)
	_check(bool(again.get("ok", false)) and bool(again.get("replayed", false)) and is_equal_approx(supply.get_fuel("ship"), 13.0), tag + "gleiche Kennung zweimal: replayed, Rest nur einmal gesenkt")
	var other_rev: Dictionary = supply.apply_command(_air_command("ship", 1.0, "air-fuel:ship:dep:1:1:r2"), ctx)
	_check(bool(other_rev.get("ok", false)) and not other_rev.has("replayed") and is_equal_approx(supply.get_fuel("ship"), 12.0), tag + "gleiches Schiff, Abflug, Serial, Schritt, aber andere Revision: zieht ZWEIMAL ab (12.0)")
	# Nachbesserung 1 (W1): nach der Buchung r2 ist der aeltere Beleg r1 desselben Schiffs weg; der juengste (r2) schuetzt weiter.
	var conflict: Dictionary = supply.apply_command(_air_command("ship", 2.0, "air-fuel:ship:dep:1:1:r2"), ctx)
	_check(not bool(conflict.get("ok", true)) and String(conflict.get("reason", "")) == "request_id_conflict" and is_equal_approx(supply.get_fuel("ship"), 12.0), tag + "dieselbe Kennung mit anderer Menge: request_id_conflict")
	var unknown: Dictionary = supply.apply_command(_air_command("ghost", 1.0, "air-fuel:ghost:1"), ctx)
	_check(not bool(unknown.get("ok", true)) and String(unknown.get("reason", "")) == "unknown_craft", tag + "unbekanntes Schiff: unknown_craft")
	var capacity: float = supply.get_fuel_capacity()
	var counter := 0
	for bad in [0.0, -1.0, capacity + 1.0, INF, NAN]:
		counter += 1
		var rejected: Dictionary = supply.apply_command(_air_command("ship", bad, "air-fuel:bad:%d" % counter), ctx)
		_check(not bool(rejected.get("ok", true)) and String(rejected.get("reason", "")) in ["invalid_air_fuel", "invalid_command"], tag + "ungueltige Menge %s abgelehnt: %s" % [str(bad), str(rejected)])
	_check(is_equal_approx(supply.get_fuel("ship"), 12.0), tag + "ungueltige Mengen aendern nichts")
	supply.register_craft("low", 0.5)
	var low: Dictionary = supply.apply_command(_air_command("low", 1.0, "air-fuel:low:1"), ctx)
	_check(bool(low.get("ok", false)) and is_equal_approx(float(low.get("consumed", -1.0)), 0.5) and is_equal_approx(float(low.get("fuel", -1.0)), 0.0) and is_equal_approx(supply.get_fuel("low"), 0.0), tag + "Abzug minf(Menge, Rest): nie unter 0")
	var credits: int = int(supply.get_supply_snapshot().credits)
	supply.apply_command(_air_command("low", 1.0, "air-fuel:low:2"), ctx)
	_check(supply.get_fuel("low") >= 0.0 and int(supply.get_supply_snapshot().credits) == credits and Dictionary(supply.get_open_tanker_orders()).is_empty(), tag + "bei 0 bleibt es 0, kauft nie, kein Tankerauftrag")
	# Der Beleg ueberlebt Speichern und Laden des Versorgungsstands (neue Belege duerfen den Ladevorgang nicht brechen).
	var restored = SUPPLY.new()
	restored.configure([], {})
	var loaded: Dictionary = restored.restore_state(supply.export_state())
	_check(bool(loaded.get("ok", false)) and is_equal_approx(restored.get_fuel("ship"), 12.0) and bool(restored.apply_command(_air_command("ship", 1.0, "air-fuel:ship:dep:1:1:r2"), ctx).get("replayed", false)), tag + "Beleg nach Speichern und Laden: Rest 12.0, die juengste Kennung bleibt replayed: " + str(loaded))


## Fall 10: scheitert der Rueckflug (Landezone beansprucht), wird bei jedem 0,2-s-Takt neu versucht; fuel_return kommt nur einmal.
func _case_10() -> void:
	var tag := "[10 Abbruch scheitert] "
	var env: Dictionary = _build(["ship", "blocker"], {"ship":4.0}, {"ship":Vector2i(10, 10), "blocker":Vector2i(15, 15)})
	var mission_root: Node = env.mission_root
	_check(bool(mission_root.request_air_support_takeoff("blocker").get("ok", false)), tag + "Aufbau: Blocker startet von Hand")
	env.transport.parked["blocker"] = false
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "f10").get("ok", false)), tag + "Aufbau: Schiff kreist")
	var cells: Array[Vector2i] = []
	for q in range(5, 20):
		for r in range(5, 20):
			if maxi(maxi(absi(q - 10), absi(r - 10)), absi(q + r - 20)) <= 2:
				cells.append(Vector2i(q, r))
	_check(bool(env.combat.record_navigation_claim("blocker", "atmosphere:" + LOC, cells).get("ok", false)), tag + "Aufbau: Landezone beansprucht")
	_run(env, 60.0)
	var sortie: Dictionary = _sortie(env, "ship")
	_check(is_equal_approx(_fuel(env, "ship"), 3.0) and String(sortie.get("returning", "x")) == "" and not Array(sortie.get("waypoints", [])).is_empty(), tag + "bei 60 s Rest 3.0, der Rueckflug scheitert, die Rundbahn laeuft weiter")
	_check(_count(env, "ship", "fuel_return") == 1 and _count(env, "ship", "landing_pending") == 0, tag + "fuel_return genau einmal (beim ersten Versuch), kein landing_pending")
	_run(env, 10.0)
	_check(_count(env, "ship", "fuel_return") == 1 and String(_sortie(env, "ship").get("returning", "x")) == "", tag + "nach weiteren 10 s weiter genau ein fuel_return, weiter kein Rueckflug")
	env.combat.release_navigation_claim("blocker")
	# Der Anspruch deckt auch die Rundbahn ab: das Schiff haelt ueber der Landezone und landet im selben Takt, in dem der Rueckflug beginnt.
	_run(env, 1.0)
	var ok10: bool = _count(env, "ship", "fuel_return") == 1 and _count(env, "ship", "landing_pending") == 1 and _count(env, "ship", "landed") == 1 and not mission_root.get("_air_support_sorties").has("ship")
	_check(ok10, tag + "Anspruch frei: der naechste Versuch gelingt (ein landing_pending), das Schiff landet, weiter nur ein fuel_return")
	env.flow.free()


## Fall 11: Schnappschuss ohne Sortie; abgebrochener Start bucht nichts.
func _case_11() -> void:
	var tag := "[11 Schnappschuss, Start abgebrochen] "
	var env: Dictionary = _build(["ship", "ship2"], {"ship":9.0})
	var mission_root: Node = env.mission_root
	var snap: Dictionary = mission_root.get_air_support_role_snapshot("ship")
	_check(not bool(snap.get("ok", true)) and is_equal_approx(float(snap.get("fuel", 0.0)), 9.0) and not bool(snap.get("fuel_warned", true)), tag + "ohne Sortie, mit Konto: fuel 9.0, nicht gewarnt: " + str(snap))
	var snap2: Dictionary = mission_root.get_air_support_role_snapshot("ship2")
	_check(not bool(snap2.get("ok", true)) and is_equal_approx(float(snap2.get("fuel", 0.0)), -1.0) and not bool(snap2.get("fuel_warned", true)), tag + "ohne Sortie, ohne Konto: fuel -1.0: " + str(snap2))
	_check(bool(mission_root.request_air_support_takeoff("ship").get("ok", false)), tag + "Aufbau: Start von Hand")
	env.transport.parked["ship"] = false
	var undone: Dictionary = mission_root._air_undo_circle_start("ship", {"ok":false, "reason":"navigation_claimed"})
	_check(not bool(undone.get("ok", true)) and _air_receipts(env).is_empty() and is_equal_approx(_fuel(env, "ship"), 9.0), tag + "abgebrochener Start: nichts gebucht, Rest 9.0")
	# Neue Sortie beginnt mit Uhr 0 (keine Altzeit aus dem Takt der vorigen).
	env.transport.parked["ship"] = true
	_run(env, 0.15)
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "f11").get("ok", false)) and is_equal_approx(float(_sortie(env, "ship").get("fuel_seconds", -1.0)), 0.0), tag + "neue Sortie: Treibstoffuhr 0")
	_run(env, 59.9)
	_check(is_equal_approx(_fuel(env, "ship"), 9.0), tag + "59,9 s nach dem Start noch keine Buchung")
	env.flow.free()


## Alle Luftbelege eines Schiffs im Export der Versorgung (Kennungen).
func _export_air_ids(supply: RefCounted, craft_id: String) -> Array:
	var ids: Array = []
	var requests: Dictionary = supply.export_state().requests
	for request_id in requests:
		if String(request_id).begins_with("air-fuel:") and String(Dictionary(requests[request_id].result).get("craft_id", "")) == craft_id: ids.append(String(request_id))
	ids.sort()
	return ids


## Fall 12 (Nachbesserung 1, W1): je Schiff bleibt nur der juengste Luftbeleg; andere Belege bleiben; alte Staende mit vielen Luftbelegen laden.
func _case_12() -> void:
	var tag := "[12 Belege begrenzt] "
	var supply = SUPPLY.new()
	supply.configure([], {})
	supply.register_craft("ship", 14.0)
	supply.register_craft("ship2", 14.0)
	var ctx := {"air_fuel_authorized":true}
	var other := {"signature":"x", "result":{"ok":true}}
	var requests: Dictionary = supply.get("_requests")
	requests["other-receipt"] = other
	for n in range(1, 11):
		supply.apply_command(_air_command("ship", 1.0, "air-fuel:ship:dep:1:%d:r%d" % [n, n]), ctx)
		if n <= 3: supply.apply_command(_air_command("ship2", 1.0, "air-fuel:ship2:dep:1:%d:r%d" % [n, n + 100]), ctx)
	_check(_export_air_ids(supply, "ship") == ["air-fuel:ship:dep:1:10:r10"], tag + "nach 10 Buchungen genau ein Luftbeleg des Schiffs, der juengste: " + str(_export_air_ids(supply, "ship")))
	_check(_export_air_ids(supply, "ship2") == ["air-fuel:ship2:dep:1:3:r103"], tag + "zwei Schiffe: das zweite hat ebenfalls genau einen, den juengsten: " + str(_export_air_ids(supply, "ship2")))
	_check(Dictionary(supply.get("_requests")).has("other-receipt"), tag + "ein anderer Beleg bleibt unberuehrt")
	var fuel_before: float = supply.get_fuel("ship")
	var replay: Dictionary = supply.apply_command(_air_command("ship", 1.0, "air-fuel:ship:dep:1:10:r10"), ctx)
	_check(bool(replay.get("replayed", false)) and is_equal_approx(supply.get_fuel("ship"), fuel_before) and is_equal_approx(fuel_before, 4.0), tag + "Wiederholung der letzten Kennung: replayed, kein zweiter Abzug (Rest %.1f)" % fuel_before)
	# Ein alter Stand mit 30 Luftbelegen laedt unveraendert und schrumpft bei der naechsten Buchung.
	var old = SUPPLY.new()
	old.configure([], {})
	old.register_craft("ship", 14.0)
	var old_requests: Dictionary = old.get("_requests")
	for n in range(1, 31):
		var id := "air-fuel:ship:dep:1:%d:r%d" % [n, n]
		old_requests[id] = {"signature":JSON.stringify({"operation":"consume_air_fuel", "payload":{"craft_id":"ship", "amount":1.0}}, "", true), "result":{"ok":true, "craft_id":"ship", "consumed":1.0, "fuel":14.0, "request_id":id, "operation":"consume_air_fuel"}}
	var restored = SUPPLY.new()
	restored.configure([], {})
	var loaded: Dictionary = restored.restore_state(old.export_state())
	_check(bool(loaded.get("ok", false)) and _export_air_ids(restored, "ship").size() == 30, tag + "Stand mit 30 alten Luftbelegen laedt unveraendert: " + str(loaded))
	if bool(loaded.get("ok", false)):
		restored.apply_command(_air_command("ship", 1.0, "air-fuel:ship:dep:2:1:r99"), ctx)
		_check(_export_air_ids(restored, "ship") == ["air-fuel:ship:dep:2:1:r99"], tag + "bei der naechsten Buchung schrumpft er auf einen Beleg: " + str(_export_air_ids(restored, "ship").size()))


const FUEL_STOP_TEXT := "Treibstoff reicht nur noch für den Abflug vom Ort – das Schiff landet."


## Fall 13 (Nachbesserung 1, W2): im Treibstoff-Rueckflug lehnen Fliegen, Kreisen und Kreisen aus ab; der Rueckflug laeuft weiter.
func _case_13() -> void:
	var tag := "[13 Befehle im Treibstoff-Rueckflug] "
	var env: Dictionary = _build(["ship"], {"ship":4.0})
	var mission_root: Node = env.mission_root
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "cas", "f13").get("ok", false)), tag + "Aufbau: Kreisen")
	_run(env, 60.0)
	_check(String(_sortie(env, "ship").get("returning", "")) == "fuel" and _count(env, "ship", "fuel_return") == 1, tag + "Aufbau: Treibstoff-Rueckflug laeuft (returning fuel)")
	var moved: Dictionary = mission_root.request_air_support_move({"craft_id":"ship", "target_hex":Vector2i(14, 10), "request_id":"w2m"})
	var circled: Dictionary = _circle(env, "ship", Vector2i(12, 10), "cas", "w2c")
	var cleared: Dictionary = mission_root.request_air_support_role_clear("ship", "w2r")
	for pair in [["Fliegen", moved], ["Kreisen", circled], ["Kreisen aus", cleared]]:
		var answer: Dictionary = pair[1]
		_check(not bool(answer.get("ok", true)) and String(answer.get("reason", "")) == "air_fuel_low" and String(answer.get("message", "")) == FUEL_STOP_TEXT, tag + "%s abgelehnt mit air_fuel_low und Text: %s" % [pair[0], str(answer)])
	_check(Dictionary(mission_root.get("_air_support_move_receipts")).is_empty() and Dictionary(mission_root.get("_air_role_receipts")).keys() == ["f13"] and Dictionary(_sortie(env, "ship").get("air_role", {"x":1})).is_empty(), tag + "kein Beleg, keine Rolle, kein Ziel gesetzt")
	_run(env, 0.6)
	_check(String(_sortie(env, "ship").get("returning", "")) == "fuel" and _count(env, "ship", "fuel_return") == 1 and _count(env, "ship", "landing_pending") == 1, tag + "der Rueckflug laeuft ungestoert weiter, fuel_return genau einmal")
	_run(env, 40.0)
	_check(not mission_root.is_air_support_craft_airborne("ship") and _count(env, "ship", "fuel_return") == 1, tag + "das Schiff landet, weiter genau ein fuel_return")
	env.flow.free()


## Fall 14 (Nachbesserung 1, K3): die Uhr laeuft auch ohne Rundbahn und bei blockierter Rundbahn.
func _case_14() -> void:
	var tag := "[14 Uhr ohne Rundbahn] "
	var env: Dictionary = _build(["ship"], {"ship":14.0})
	var mission_root: Node = env.mission_root
	_check(bool(mission_root.request_air_support_takeoff("ship").get("ok", false)), tag + "Aufbau: Start von Hand (keine Rundbahn)")
	env.transport.parked["ship"] = false
	_run(env, 60.0)
	_check(is_equal_approx(_fuel(env, "ship"), 13.0) and Array(_sortie(env, "ship").get("waypoints", [1])).is_empty(), tag + "schwebend ohne Rundbahn: nach 60 s eine Buchung (13.0)")
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "f14").get("ok", false)), tag + "Aufbau: Kreisen")
	_run(env, 1.0)
	_check(bool(mission_root.request_air_support_role_clear("ship", "f14c").get("ok", false)) and Array(_sortie(env, "ship").get("waypoints", [1])).is_empty(), tag + "Kreisen aus: wieder ohne Rundbahn")
	_run(env, 59.0)
	_check(is_equal_approx(_fuel(env, "ship"), 12.0), tag + "auch nach Kreisen aus laeuft die Uhr (12.0)")
	env.flow.free()
	var env2: Dictionary = _build(["ship", "blocker"], {"ship":14.0}, {"ship":Vector2i(10, 10), "blocker":Vector2i(15, 15)})
	var root2: Node = env2.mission_root
	_check(bool(root2.request_air_support_takeoff("blocker").get("ok", false)), tag + "Aufbau 2: Blocker startet von Hand")
	env2.transport.parked["blocker"] = false
	_check(bool(_circle(env2, "ship", Vector2i(10, 10), "none", "f14b").get("ok", false)), tag + "Aufbau 2: Schiff kreist")
	var cells: Array[Vector2i] = []
	for q in range(5, 20):
		for r in range(5, 20): cells.append(Vector2i(q, r))
	_check(bool(env2.combat.record_navigation_claim("blocker", "atmosphere:" + LOC, cells).get("ok", false)), tag + "Aufbau 2: alle Felder beansprucht (Rundbahn blockiert)")
	_run(env2, 120.0)
	_check(_count(env2, "ship", "role_blocked") == 1 and is_equal_approx(_fuel(env2, "ship"), 12.0), tag + "Rundbahn blockiert: die Uhr laeuft weiter (12.0 nach 120 s), eine Blockiermeldung")
	env2.flow.free()


## Fall 15 (Nachbesserung 1, K2): scheitert eine Buchung, verfaellt die Minute nicht stumm (Zaehler _air_fuel_book_failures, push_warning).
func _case_15() -> void:
	var tag := "[15 Buchung scheitert] "
	var env: Dictionary = _build(["ship"], {"ship":14.0})
	var mission_root: Node = env.mission_root
	mission_root.set("_air_role_data_cache", {"circle":{"radius_hex":4, "waypoint_switch_distance":1.0, "arrival_starts_ring":true}, "cas":{"protect_radius":8.0, "pursuit_limit":4.0, "target_poll_seconds":0.5}, "air_defense":{"protect_radius":8.0, "pursuit_limit":4.0}, "fuel":{"seconds_per_unit":60.0, "units_per_step":1000.0, "land_margin":1.0}})
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "f15").get("ok", false)), tag + "Aufbau: Kreisen mit unsinniger Menge je Minute")
	_run(env, 61.0)
	var failures: Variant = mission_root.get("_air_fuel_book_failures")
	_check(is_equal_approx(_fuel(env, "ship"), 14.0) and typeof(failures) == TYPE_INT and int(failures) == 1, tag + "die Buchung scheitert: Rest 14.0 und genau ein gezaehlter Fehlschlag (%s)" % str(failures))
	env.flow.free()


func _initialize() -> void:
	_case_1()
	_case_2()
	_case_3()
	_case_5()
	_case_6()
	_case_7()
	_case_8()
	_case_9()
	_case_10()
	_case_11()
	_case_12()
	_case_13()
	_case_14()
	_case_15()
	print("AIR_FUEL passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
