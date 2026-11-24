extends SceneTree
## Luftrollen 4a: feindliche Piraten-Buccaneer - Auftauchen nach dem ersten eigenen Start, Anflug, Schiffsschuss, Abschuss.
## Rein rechnerisch an der Attrappen-Mission von air_role_circle_verifier (Fixture 1b), keine Szene, kein Einsatzlauf.
const ROOT_SCRIPT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const TERRAIN_MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const SCENARIO = preload("res://scripts/mission/mission_scenario_data.gd")
const DT := 0.05
const FOE := "pirate_buccaneer_1"

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
		return PackedStringArray([])

class FixTransport extends Node:
	var parked := {}
	var landed_position := {}
	func get_campaign_air_support_pilot_guard(craft_id: String) -> Dictionary: return {"ok":true, "pilot_unit_id":"pilot_" + craft_id}
	func _is_parked_campaign_dropship(craft_id: String) -> bool: return bool(parked.get(craft_id, false))
	func _campaign_landed_craft_position(craft_id: String) -> Vector2: return landed_position.get(craft_id, Vector2.ZERO)
	func _ground_ship_touchdown_ready(_id: String, _position: Vector2, _visual: bool) -> bool: return true


func _check(ok: bool, label: String) -> bool:
	if ok:
		_passed += 1
	else:
		_failed += 1
		print("AIR_HOSTILE_AIRCRAFT FAIL: ", label)
	return ok


# ---------------------------------------------------------------- Aufbau
## Felder 5..19, Landezone (10,10) (oder laut grids). Alle Schiffe sind Cutlass, starten von Hand und fliegen; spawn: Feld des Gegners.
func _build(craft_ids: Array[String], spawn: Variant = Vector2i(17, 10), takeoff: bool = true, grids: Dictionary = {}) -> Dictionary:
	var loc := "moon_site"
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
	for id in craft_ids:
		var pilot = FixPerson.new(); pilot.unit_id = "pilot_" + id; mission.add_child(pilot); units.register_unit(pilot.unit_id, pilot); mission_root.register_known_unit(pilot.unit_id, pilot)
		pilot.set_meta("dropship_embarked", true)
	var vision = FixVision.new(); vision.name = "CombatLoopDriver"; mission.add_child(vision)
	var transport = FixTransport.new(); transport.name = "TacticalController"; mission.add_child(transport)
	for q in range(5, 20):
		for r in range(5, 20): terrain.register_tile(TILE.new({"tile_id":"air:%d:%d" % [q, r], "grid_position":Vector2i(q, r), "explicit_hex_ramps":true}))
	for id in craft_ids:
		transport.landed_position[id] = terrain.grid_to_world(Vector2i(grids.get(id, Vector2i(10, 10))))
	source.tick_counter = 50
	var events: Array = []
	mission_root.air_role_event.connect(func(event: Dictionary) -> void: events.append(event))
	var env := {"flow":flow, "adapter":adapter, "source":source, "fleet":fleet, "mission_root":mission_root, "terrain":terrain, "transport":transport, "events":events, "tick":50, "combat":source.get("_space_combat_state")}
	if spawn != null:
		mission_root.configure_enemy_aircraft([{"aircraft_id":FOE, "model_id":"buccaneer", "faction_id":"pirates", "spawn_hex":spawn, "delay_seconds":20.0}])
	if takeoff:
		for id in craft_ids:
			transport.parked[id] = true
			_check(bool(mission_root.request_air_support_takeoff(id).get("ok", false)), "Aufbau: Start von Hand " + id)
			transport.parked[id] = false
	return env


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


func _foe_pose(env: Dictionary) -> Dictionary:
	var actor: RefCounted = env.combat.get_actor(FOE)
	return actor.get_snapshot() if actor != null else {}


func _count(env: Dictionary, kind: String) -> int:
	var n := 0
	for event in env.events:
		if event.kind == kind:
			n += 1
	return n


func _systems_state(env: Dictionary, id: String) -> Dictionary:
	return Dictionary(env.combat.get("_ship_systems")[id]).state


func _cell_of(pose: Dictionary) -> Vector2i:
	return GRID.HEX.round_axial(GRID.HEX.plane_to_axial(pose.position_plane))


# ---------------------------------------------------------------- Faelle
## Fall 1: ohne eigenen Start erscheint nie ein Gegner.
func _case_1() -> void:
	var tag := "[1 ohne Start] "
	var env: Dictionary = _build(["ship"], Vector2i(17, 10), false)
	_tick(env, 120.0)
	_check(env.combat.get_actor(FOE) == null and env.combat.get_ship_systems(FOE).is_empty(), tag + "120 s ohne Sortie: kein Gegner im Kampagnenkern")
	_check(not bool(env.mission_root.get("_air_hostile_armed")), tag + "Uhr nicht gestartet")
	env.flow.free()


## Fall 2: nach dem Start erscheint der Gegner nach delay_seconds, nicht frueher.
func _case_2() -> void:
	var tag := "[2 Auftauchen] "
	var env: Dictionary = _build(["ship"])
	var rng_before: int = int(env.source.get("_space_fire_rng"))
	_tick(env, 19.9)
	_check(env.combat.get_actor(FOE) == null, tag + "bei 19,9 s noch kein Gegner")
	_tick(env, 0.1)
	var actor: RefCounted = env.combat.get_actor(FOE)
	_check(actor != null, tag + "bei 20 s ist der Gegner da")
	var meta: Dictionary = env.combat.get_metadata(FOE)
	_check(meta.get("control_domain") == "enemy" and meta.get("faction_id") == "pirates", tag + "control_domain enemy, Fraktion pirates: " + str(meta))
	_check(actor != null and actor.get_snapshot().space_area_id == "atmosphere:moon_site", tag + "Gebiet atmosphere:moon_site")
	var systems: Dictionary = env.combat.get_ship_systems(FOE)
	_check(not systems.is_empty() and is_equal_approx(float(systems.state.hull), float(systems.state.hull_capacity)) and float(systems.state.hull_capacity) > 0.0, tag + "Rumpf voll")
	_check(_cell_of(_foe_pose(env)) == Vector2i(17, 10), tag + "auf dem Feld (17,10)")
	_check(int(env.source.get("_space_fire_rng")) == rng_before, tag + "Zufallsstrom unberuehrt (noch kein Schuss)")
	env.flow.free()


## Fall 3: ist (17,10) belegt, steht der Gegner auf einem Nachbarfeld (Ring 1).
func _case_3() -> void:
	var tag := "[3 Ausweichfeld] "
	var env: Dictionary = _build(["ship", "blocker"], Vector2i(17, 10), true, {"ship":Vector2i(10, 10), "blocker":Vector2i(17, 10)})
	_tick(env, 20.0)
	var actor: RefCounted = env.combat.get_actor(FOE)
	_check(actor != null, tag + "Gegner ist da")
	if actor != null:
		var cell := _cell_of(_foe_pose(env))
		_check(cell != Vector2i(17, 10) and GRID.HEX.distance(cell, Vector2i(17, 10)) == 1, tag + "Nachbarfeld, Ring 1: " + str(cell))
	env.flow.free()


## Fall 4: der Gegner fliegt an und haelt Abstand, schiesst (die Rumpfwerte des Spielers werden hier aufgefrischt, damit er 15 s ueberlebt).
func _case_4() -> void:
	var tag := "[4 Anflug] "
	var env: Dictionary = _build(["ship"], Vector2i(19, 10))
	_tick(env, 20.0)
	var near := INF
	for _i in range(60):
		_tick(env, 0.25)
		var state: Dictionary = _systems_state(env, "ship")
		state["hull"] = float(state.hull_capacity)
		state["shield"] = float(Dictionary(env.combat.get("_ship_systems")["ship"]).stats.shield.capacity)
		near = minf(near, _foe_pose(env).position_plane.distance_to(_pose(env, "ship").position_plane))
	var d: float = _foe_pose(env).position_plane.distance_to(_pose(env, "ship").position_plane)
	_check(d <= 7.0, tag + "nach 15 s Abstand <= 7,0: %.2f" % d)
	_check(near >= 4.5, tag + "haelt Abstand (naehester %.2f)" % near)
	var control: Dictionary = Dictionary(env.combat.get_flight_controls().get(FOE, {}))
	_check(bool(control.get("air_hostile_move", false)) and control.has("goal") and Dictionary(control.goal).has("face_plane"), tag + "Lenkung des Gegners gesetzt (air_hostile_move, Nase aufs Ziel)")
	_check(int(env.source.get("_space_fire_rng")) != 1, tag + "es wurde echt geschossen (Zufallsstrom fortgeschrieben)")
	env.flow.free()


## Fall 5: Schiffsschuss Spieler -> Gegner: Reichweite 10 x 0,8 = 8 Felder; Abstand 9 verfehlt die Reichweite, Abstand 7 trifft.
func _case_5() -> void:
	var tag := "[5 Schuss] "
	for pair in [[Vector2i(19, 10), 9], [Vector2i(17, 10), 7]]:
		var env: Dictionary = _build(["ship"], pair[0])
		_tick(env, 20.0)
		var rng_before: int = int(env.source.get("_space_fire_rng"))
		var shot: Dictionary = env.source.resolve_local_ship_shot("ship", FOE, "weapon_1", "c5-%d" % pair[1])
		if int(pair[1]) == 9:
			_check(not bool(shot.get("ok", true)) and String(shot.get("reason", "")) == "out_of_range", tag + "Abstand 9: out_of_range " + str(shot.get("reason", "")))
			_check(int(env.source.get("_space_fire_rng")) == rng_before, tag + "Zufallsstrom bleibt ohne echten Schuss")
		else:
			_check(bool(shot.get("ok", false)) and String(shot.event.get("hit_craft_id", "")) == FOE and shot.has("impact"), tag + "Abstand 7: Schuss trifft den Gegner " + str(shot.get("reason", "")))
			_check(int(env.source.get("_space_fire_rng")) != rng_before, tag + "Zufallsstrom fortgeschrieben")
			_check(float(_systems_state(env, FOE).shield) < float(Dictionary(env.combat.get("_ship_systems")[FOE]).stats.shield.capacity), tag + "Schild des Gegners nimmt Schaden")
		var same: Dictionary = env.source.resolve_local_ship_shot("ship", "ship", "weapon_1", "c5-self")
		_check(not bool(same.get("ok", true)), tag + "Schuss auf sich selbst abgelehnt")
		env.flow.free()


## Fall 6: Spielerschild 0, ein Treffer Schaden 4: Luftrumpf 100 -> 96.
func _case_6() -> void:
	var tag := "[6 Luftrumpf sinkt] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 20.0)
	env.combat.advance_ship_systems(3.0)
	_systems_state(env, "ship")["shield"] = 0.0
	var shot: Dictionary = env.mission_root._air_hostile_shoot_slot(env.source, FOE, "ship", "weapon_1")
	_check(bool(shot.get("ok", false)) and float(shot.impact.hull_damage) == 4.0, tag + "Treffer mit Rumpfschaden 4: " + str(shot.get("reason", "")))
	var status: Dictionary = env.mission_root.get_air_asset_status_snapshot("ship")
	_check(int(status.get("integrity", -1)) == 96, tag + "Luftrumpf 96: " + str(status.get("integrity")))
	_check(Dictionary(env.mission_root.get("_air_support_sorties")).has("ship"), tag + "Sortie besteht weiter")
	env.flow.free()


## Fall 7: Luftrumpf 4, Treffer 4: Abschuss laeuft, die Sortie ist weg.
func _case_7() -> void:
	var tag := "[7 Abschuss] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 20.0)
	env.mission_root._apply_air_asset_status_update_effect({"effect_type":"air_asset_status_update", "status_snapshot":{"asset_id":"ship", "asset_type":"dropship", "state":"damaged", "integrity":4, "max_integrity":100}, "event_id":"c7-setup"})
	env.combat.advance_ship_systems(3.0)
	_systems_state(env, "ship")["shield"] = 0.0
	var shot: Dictionary = env.mission_root._air_hostile_shoot_slot(env.source, FOE, "ship", "weapon_1")
	_check(bool(shot.get("ok", false)), tag + "Treffer: " + str(shot.get("reason", "")))
	_check(not Dictionary(env.mission_root.get("_air_support_sorties")).has("ship"), tag + "Sortie beendet (resolve_air_shootdown lief)")
	# Der Ausgang (Notlandung, Bruchlandung, Explosion) wird ausgewuerfelt: hier zaehlt, dass der Abschuss durchlief und das Schiff nicht mehr fliegt.
	var status: Dictionary = env.mission_root.get_air_asset_status_snapshot("ship")
	_check(not status.is_empty() and not env.mission_root.is_air_support_craft_airborne("ship"), tag + "Schiff fliegt nicht mehr, Zustand gebucht: " + str(status.get("state")))
	env.flow.free()


## Fall 8: Gegner-Rumpf 0: Akteur weg, hostile_down genau einmal, kein Wiederauftauchen.
func _case_8() -> void:
	var tag := "[8 Gegner abgeschossen] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 20.0)
	_tick(env, 1.0)
	_check(_count(env, "hostile_spotted") == 1, tag + "hostile_spotted genau einmal")
	_systems_state(env, FOE)["hull"] = 0.0
	_tick(env, 0.4)
	_check(env.combat.get_actor(FOE) == null and env.combat.get_ship_systems(FOE).is_empty(), tag + "Akteur und Systeme weg")
	_check(not Dictionary(env.combat.get_flight_controls()).has(FOE) and not Dictionary(env.combat.get("_navigation_claims")).has(FOE), tag + "Steuerung und Anspruch frei")
	_tick(env, 60.0)
	_check(_count(env, "hostile_down") == 1 and env.combat.get_actor(FOE) == null, tag + "hostile_down einmal, kein Wiederauftauchen in 60 s")
	var texts: Array = []
	for event in env.events:
		if event.kind in ["hostile_down", "hostile_spotted"]: texts.append(event.text)
	_check(texts.has("Piraten-Buccaneer abgeschossen.") and texts.has("Feindlicher Flieger gesichtet: Buccaneer."), tag + "Texte wortlich: " + str(texts))
	env.flow.free()


## Fall 9: Missionskern freigeben: der Gegner verlaesst den Kampagnenkern.
func _case_9() -> void:
	var tag := "[9 Aufraeumen] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 20.0)
	_check(env.combat.get_actor(FOE) != null, tag + "Aufbau: Gegner fliegt")
	env.mission_root.queue_free()
	await process_frame
	await process_frame
	_check(env.combat.get_actor(FOE) == null and env.combat.get_ship_systems(FOE).is_empty() and Dictionary(env.source.get("_air_hostile_models")).is_empty(), tag + "Gegner nicht mehr im Kampagnenkern")
	env.flow.free()


## Fall 10: Luftradar des Spielers kennt den Gegner als Projektion mit control_domain "enemy".
func _case_10() -> void:
	var tag := "[10 Radar] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 20.0)
	var radar: Dictionary = env.mission_root.get_air_support_radar_contacts("ship")
	_check(bool(radar.get("ok", false)) and Array(radar.get("contacts", [])).has(FOE), tag + "Gegner unter den Kontakten: " + str(radar.get("contacts", radar.get("reason", ""))))
	var found := {}
	for projection: Dictionary in Array(radar.get("projections", [])):
		if projection.craft_id == FOE: found = projection
	_check(not found.is_empty() and found.get("control_domain") == "enemy" and found.get("position") is Vector2, tag + "Projektion mit control_domain enemy: " + str(found))
	env.flow.free()


## Fall 11: Szenario-Daten (Pruefszenario, ohne Block, ungueltige Eintraege) und Lage von spawn_hex auf der Karte.
func _case_11() -> void:
	var tag := "[11 Szenario] "
	var scenario = SCENARIO.load_from_file("res://data/mission_scenarios/ground_mission02_128x128.json")
	var config: Array = scenario.get_enemy_aircraft_config() if scenario != null else []
	_check(config.size() == 1 and config[0] == {"aircraft_id":"pirate_buccaneer_1", "model_id":"buccaneer", "faction_id":"pirates", "spawn_hex":Vector2i(40, 12), "delay_seconds":20.0}, tag + "Pruefszenario liefert den Eintrag: " + str(config))
	var plain = SCENARIO.load_from_file("res://data/mission_scenarios/ground_mission01_default.json")
	_check(plain != null and plain.get_enemy_aircraft_config() == [], tag + "Szenario ohne Block: []")
	var bad = SCENARIO.new()
	bad.tactical_authoring = {"enemy_aircraft":[{"aircraft_id":"a", "model_id":"tank", "spawn_hex":{"x":1, "y":1}}, {"aircraft_id":"b", "model_id":"cutlass", "spawn_hex":{"x":3, "y":4}}, {"aircraft_id":"b", "model_id":"cutlass", "spawn_hex":{"x":3, "y":4}}, {"aircraft_id":"c", "model_id":"buccaneer", "spawn_hex":{"x":1.5, "y":1}}, {"aircraft_id":"d", "model_id":"buccaneer", "spawn_hex":{"x":1, "y":1}, "delay_seconds":-1.0}, 7]}
	var kept: Array = bad.get_enemy_aircraft_config()
	_check(kept.size() == 1 and kept[0].aircraft_id == "b" and kept[0].faction_id == "pirates" and is_equal_approx(float(kept[0].delay_seconds), 20.0), tag + "ungueltige Eintraege fallen weg, Vorgaben greifen: " + str(kept))
	var map_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://maps/Ground_Mission02_128x128.json"))
	var on_map := false
	var spawn_alpha := Vector2.ZERO
	if typeof(map_data) == TYPE_DICTIONARY:
		for tile: Dictionary in Array(map_data.get("tiles", [])):
			if int(tile.grid_position.x) == 40 and int(tile.grid_position.y) == 12: on_map = true
		var marker: Dictionary = Dictionary(map_data.get("markers", {})).get("spawn_alpha", {})
		spawn_alpha = Vector2(float(marker.get("x", 0.0)), float(marker.get("y", 0.0)))
	_check(on_map, tag + "spawn_hex (40,12) liegt auf der Karte")
	var a: float = spawn_alpha.y / 32.0
	var b: float = spawn_alpha.x / 64.0
	var landing: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(Vector2((a + b) * 0.5, (a - b) * 0.5)))
	_check(GRID.HEX.distance(landing, Vector2i(40, 12)) >= 20, tag + "mindestens 20 Felder von der Landezone (Spawn Alpha %s): %d" % [str(landing), GRID.HEX.distance(landing, Vector2i(40, 12))])


## Fall 12: ohne Eintrag und ohne Gegner aendert sich nichts (kein Zufallszug, kein Akteur); Speichern-Probe mit fliegendem Gegner.
func _case_12() -> void:
	var tag := "[12 unveraendert] "
	var env: Dictionary = _build(["ship"], null)
	_tick(env, 40.0)
	_check(int(env.source.get("_space_fire_rng")) == 1 and Array(env.mission_root.get("_air_hostile_ids")).is_empty() and Array(env.mission_root.get("_air_hostile_pending")).is_empty(), tag + "kein Eintrag: Zufallsstrom 1, nichts vorgemerkt")
	_check(Array(env.combat.get_area_actor_ids("atmosphere:moon_site")) == ["ship"], tag + "nur das eigene Schiff im Gebiet")
	var before: Dictionary = env.combat.export_navigation_checkpoint()
	_check(String(before.get("schema", "")) == "space_navigation_checkpoint.v1", tag + "Navigationsstand ohne Gegner exportierbar")
	env.flow.free()
	var env2: Dictionary = _build(["ship"])
	_tick(env2, 20.2)
	var during: Dictionary = env2.combat.export_navigation_checkpoint()
	print("AIR_HOSTILE_AIRCRAFT INFO Navigationsstand mit fliegendem Gegner: ", str(during.get("schema", during.get("reason", "?"))))
	_check(during is Dictionary and (String(during.get("schema", "")) == "space_navigation_checkpoint.v1" or String(during.get("reason", "")) == "invalid_navigation_checkpoint"), tag + "Speichern-Probe mit fliegendem Gegner: Antwort ohne Absturz")
	env2.flow.free()


func _initialize() -> void:
	_case_1()
	_case_2()
	_case_3()
	_case_4()
	_case_5()
	_case_6()
	_case_7()
	_case_8()
	await _case_9()
	_case_10()
	_case_11()
	_case_12()
	print("AIR_HOSTILE_AIRCRAFT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
