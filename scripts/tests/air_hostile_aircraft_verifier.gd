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
const CAPTURE = preload("res://scripts/mission/campaign_active_mission_capture.gd")
const PROJECTION = preload("res://scripts/meta/campaign_save_projection.gd")
const DT := 0.05
const FOE := "pirate_buccaneer_1"

var _passed := 0
var _failed := 0


class FixFlow extends Node:
	var _active_mission: Node
	var _craft_location_runtime := {}
	var _assigned_aircraft_pilot_by_craft := {}
	func get_active_mission() -> Node: return _active_mission
	func is_campaign_start() -> bool: return true

class FixSetup extends Node:
	var scenario_file_path := ""
	var _mission_scenario = null

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
func _build(craft_ids: Array[String], spawn: Variant = Vector2i(17, 10), takeoff: bool = true, grids: Dictionary = {}, setup_path: String = "", setup_scenario: Variant = null) -> Dictionary:
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
	if not setup_path.is_empty() or setup_scenario != null:
		# Kampagnenmodus mit Szenario-Knoten wie im echten Einsatz (Szenario aus Datei oder schon geladen).
		adapter._campaign_mode = true
		var setup := FixSetup.new(); setup.name = "MissionSetup"; setup.scenario_file_path = setup_path; setup._mission_scenario = setup_scenario; mission.add_child(setup)
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
	if spawn is Array:
		mission_root.configure_enemy_aircraft(spawn)
	elif spawn != null:
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
		# Trefferquote 0,5: bis zum ersten Treffer weiterschiessen (Abkuehlzeit und Energie jeweils aufgefrischt).
		var shot: Dictionary = {}
		for attempt in range(40):
			_refill(env, "ship")
			shot = env.source.resolve_local_ship_shot("ship", FOE, "weapon_1", "c5-%d-%d" % [pair[1], attempt])
			if not bool(shot.get("ok", false)) or String(shot.event.get("hit_craft_id", "")) == FOE: break
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
	# Ueber den Takt: Spielerschild bleibt 0, der Gegner fliegt an und schiesst selbst.
	var guard := 0
	while int(env.mission_root.get_air_asset_status_snapshot("ship").get("integrity", 100)) >= 100 and guard < 300:
		guard += 1
		_systems_state(env, "ship")["shield"] = 0.0
		_tick(env, 0.2)
	var status: Dictionary = env.mission_root.get_air_asset_status_snapshot("ship")
	var integrity := int(status.get("integrity", -1))
	_check(integrity < 100 and integrity <= 96 and (100 - integrity) % 4 == 0, tag + "Luftrumpf sinkt in Viererschritten durch Treffer des Gegners im Takt: " + str(status.get("integrity")))
	_check(Dictionary(env.mission_root.get("_air_support_sorties")).has("ship"), tag + "Sortie besteht weiter")
	env.flow.free()


## Fall 7: Luftrumpf 4, Treffer 4: Abschuss laeuft, die Sortie ist weg.
func _case_7() -> void:
	var tag := "[7 Abschuss] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 20.0)
	env.mission_root._apply_air_asset_status_update_effect({"effect_type":"air_asset_status_update", "status_snapshot":{"asset_id":"ship", "asset_type":"dropship", "state":"damaged", "integrity":4, "max_integrity":100}, "event_id":"c7-setup"})
	var guard := 0
	while Dictionary(env.mission_root.get("_air_support_sorties")).has("ship") and guard < 600:
		guard += 1
		_systems_state(env, "ship")["shield"] = 0.0
		_tick(env, 0.2)
	_check(guard < 600, tag + "der Gegner schiesst das Schiff im Takt ab (%d Schritte)" % guard)
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
	_check(_kill_foe(env) > 0 and float(_systems_state(env, FOE).hull) <= 0.0, tag + "Gegner ueber Schiffsschuesse (resolve_local_ship_shot) auf Rumpf 0 geschossen")
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
	_check(env2.combat.get_actor(FOE) != null, tag + "Aufbau: Gegner fliegt")
	# Strenge Probe: der Speicherversuch mit fliegendem Gegner muss genau mit dem eigenen Grund scheitern (kann scheitern, wenn der Grund fehlt).
	var during: Dictionary = CAPTURE.capture_components(env2.flow, env2.adapter)
	_check(not bool(during.get("ok", true)) and String(during.get("reason", "")) == "air_hostile_present", tag + "Speicherversuch mit fliegendem Gegner: Grund air_hostile_present: " + str(during.get("reason", "ok")))
	env2.flow.free()


## Schild, Rumpf, Waffenenergie voll und Abkuehlzeiten leer (fuer Serien von Schuessen).
func _refill(env: Dictionary, id: String, with_hull: bool = true) -> void:
	var entry: Dictionary = env.combat.get("_ship_systems")[id]
	if with_hull: entry.state["hull"] = float(entry.state.hull_capacity)
	entry.state["shield"] = float(entry.stats.shield.capacity)
	entry.state["weapon_energy"] = float(entry.stats.weapon_reserve.capacity)
	entry.cooldowns.clear()


## Nachbesserung 1, W2: Luft-Luft-Belege wachsen nicht ueber die Kampagne an (kein 4096er-Stau, nichts im gespeicherten Stand).
func _case_13() -> void:
	var tag := "[13 Belege] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 20.0)
	_refill(env, FOE); _refill(env, "ship")
	var export_before: int = JSON.stringify(env.combat.export_systems_checkpoint()).length()
	var receipts: Dictionary = env.combat.get("_ship_impact_receipts")
	var ok_count := 0
	var last: Dictionary = {}
	for i in range(6000):
		_refill(env, FOE); _refill(env, "ship")
		last = env.source.resolve_local_ship_shot(FOE, "ship", "weapon_1", "c13-%d" % i)
		if bool(last.get("ok", false)): ok_count += 1
	_check(bool(last.get("ok", false)) and ok_count == 6000, tag + "der 6000. Luft-Luft-Schuss wird noch ausgewertet (%d ok, letzter: %s)" % [ok_count, str(last.get("reason", "ok"))])
	_check(receipts.size() == 0, tag + "kein Luft-Luft-Beleg im dauerhaften Speicher: %d" % receipts.size())
	_refill(env, FOE); _refill(env, "ship")
	_check(JSON.stringify(env.combat.export_systems_checkpoint()).length() == export_before, tag + "gespeicherter Stand waechst nicht")
	# Ein gewoehnlicher Schiffsschuss (Beleg im dauerhaften Speicher) geht danach weiter.
	var normal: Dictionary = last.get("event", {}).duplicate(true)
	normal["id"] = "c13-normal"
	var committed: Dictionary = env.combat._commit_ship_impact(normal)
	_check(bool(committed.get("ok", false)) and receipts.size() == 1, tag + "danach ist ein gewoehnlicher Schiffsschuss moeglich: " + str(committed.get("reason", "ok")))
	env.flow.free()


## Nachbesserung 1, W2: derselbe Beleg im selben Takt wird nicht doppelt ausgewertet (Wiederholung liefert den ersten Befund).
func _case_13b() -> void:
	var tag := "[13b doppelte Kennung] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 20.0)
	_refill(env, FOE); _refill(env, "ship")
	var shot: Dictionary = env.source.resolve_local_ship_shot(FOE, "ship", "weapon_1", "c13b-1")
	_check(bool(shot.get("ok", false)), tag + "erster Schuss: " + str(shot.get("reason", "ok")))
	var shield_after: float = float(_systems_state(env, "ship").shield)
	var again: Dictionary = env.combat._commit_ship_impact(shot.event, true)
	_check(bool(again.get("ok", false)) and bool(again.get("replayed", false)), tag + "Wiederholung ist ein Nachhall: " + str(again))
	_check(is_equal_approx(float(_systems_state(env, "ship").shield), shield_after), tag + "Schild nicht ein zweites Mal gesenkt")
	env.flow.free()


## Schiesst, bis der Gegner nach echten Schiffsschuessen (resolve_local_ship_shot) keinen Rumpf mehr hat; liefert die Zahl der Schuesse.
func _kill_foe(env: Dictionary) -> int:
	var shots := 0
	var guard := 0
	while not env.combat.get_ship_systems(FOE).is_empty() and float(_systems_state(env, FOE).hull) > 0.0 and guard < 3000:
		guard += 1
		_refill(env, "ship", false)
		var shot: Dictionary = env.source.resolve_local_ship_shot("ship", FOE, "weapon_1", "kill-%d" % guard)
		if bool(shot.get("ok", false)): shots += 1
	return shots


## Nachbesserung 1, W3: in der Atmosphaere fuehrt fuer eigene Schiffe der Luftrumpf; der Raumrumpf bleibt unberuehrt.
func _case_14() -> void:
	var tag := "[14 Luftrumpf fuehrt] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 20.0)
	var entry: Dictionary = env.combat.get("_ship_systems")["ship"]
	entry.state["hull"] = 50.0
	var hits := 0
	var guard := 0
	while Dictionary(env.mission_root.get("_air_support_sorties")).has("ship") and guard < 600:
		guard += 1
		_refill(env, FOE); _refill(env, "ship", false)
		entry.state["shield"] = 0.0
		var shot: Dictionary = env.mission_root._air_hostile_shoot_slot(env.source, FOE, "ship", "weapon_1")
		if bool(shot.get("ok", false)) and float(shot.impact.hull_damage) > 0.0: hits += 1
	_check(not Dictionary(env.mission_root.get("_air_support_sorties")).has("ship") and not env.mission_root.is_air_support_craft_airborne("ship"), tag + "(a) Raumrumpf 50 %%: das Schiff wird erst bei Luftrumpf 0 abgeschossen (Treffer %d, Schleife %d)" % [hits, guard])
	_check(hits == 25, tag + "(a) 25 Treffer zu 4 Punkten bis Luftrumpf 0: %d" % hits)
	var status: Dictionary = env.mission_root.get_air_asset_status_snapshot("ship")
	_check(not status.is_empty() and int(status.get("integrity", 100)) <= 1, tag + "(a) Luftrumpf aufgebraucht gebucht: " + str(status.get("integrity")))
	env.flow.free()
	var env2: Dictionary = _build(["ship"])
	_tick(env2, 20.0)
	var entry2: Dictionary = env2.combat.get("_ship_systems")["ship"]
	entry2.state["hull"] = 50.0
	var hits2 := 0
	var guard2 := 0
	while hits2 < 5 and guard2 < 200:
		guard2 += 1
		_refill(env2, FOE); _refill(env2, "ship", false)
		entry2.state["shield"] = 0.0
		var shot2: Dictionary = env2.mission_root._air_hostile_shoot_slot(env2.source, FOE, "ship", "weapon_1")
		if bool(shot2.get("ok", false)) and float(shot2.impact.hull_damage) > 0.0: hits2 += 1
	_check(int(env2.mission_root.get_air_asset_status_snapshot("ship").get("integrity", -1)) == 80, tag + "(b) 5 Treffer: Luftrumpf 80")
	_check(is_equal_approx(float(_systems_state(env2, "ship").hull), 50.0), tag + "(b) Raumrumpf nach dem Gefecht unveraendert 50: " + str(_systems_state(env2, "ship").hull))
	env2.flow.free()


## Nachbesserung 1, W4: ohne eigenes Schiff in der Luft dreht der Gegner nach 10 s ab und kehrt nach dem naechsten Start zurueck (nicht nach Abschuss).
func _case_15() -> void:
	var tag := "[15 Abdrehen] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 20.0)
	_systems_state(env, FOE)["hull"] = 60.0
	var landed: Dictionary = env.mission_root.request_air_support_landing("ship")
	_check(bool(landed.get("ok", false)), tag + "Aufbau: Schiff landet: " + str(landed.get("reason", "ok")))
	_tick(env, 9.5)
	_check(env.combat.get_actor(FOE) != null, tag + "nach 9,5 s ohne eigenes Schiff ist er noch da")
	_tick(env, 1.0)
	_check(env.combat.get_actor(FOE) == null and env.combat.get_ship_systems(FOE).is_empty() and Dictionary(env.source.get("_air_hostile_models")).is_empty(), tag + "nach 10 s abgezogen")
	_check(not Dictionary(env.combat.get_flight_controls()).has(FOE) and not Dictionary(env.combat.get("_navigation_claims")).has(FOE), tag + "Lenkung und Navigationsanspruch frei")
	_tick(env, 60.0)
	var texts: Array = []
	for event in env.events:
		if event.kind == "hostile_withdrawn": texts.append(event.text)
	_check(texts == ["Feindlicher Flieger dreht ab."] and env.combat.get_actor(FOE) == null, tag + "Ereignis genau einmal, ohne Start kein Zurueck: " + str(texts))
	env.transport.parked["ship"] = true
	_check(bool(env.mission_root.request_air_support_takeoff("ship").get("ok", false)), tag + "naechster Start")
	env.transport.parked["ship"] = false
	_tick(env, 19.0)
	_check(env.combat.get_actor(FOE) == null, tag + "19 s nach dem Start noch nicht da")
	_tick(env, 1.5)
	var back: Dictionary = env.combat.get_ship_systems(FOE)
	_check(env.combat.get_actor(FOE) != null and not back.is_empty() and is_equal_approx(float(back.state.hull), 60.0) and is_equal_approx(float(back.state.shield), float(back.stats.shield.capacity)), tag + "20 s nach dem Start zurueck: Rumpf 60, Schild voll: " + str(back.get("state", {})))
	env.flow.free()
	var env2: Dictionary = _build(["ship"])
	_tick(env2, 20.0)
	_check(_kill_foe(env2) > 0, tag + "Aufbau: Gegner ueber Schiffsschuesse abgeschossen")
	_tick(env2, 0.4)
	_check(bool(env2.mission_root.request_air_support_landing("ship").get("ok", false)), tag + "Aufbau: Schiff landet")
	_tick(env2, 15.0)
	env2.transport.parked["ship"] = true
	env2.mission_root.request_air_support_takeoff("ship")
	env2.transport.parked["ship"] = false
	_tick(env2, 60.0)
	_check(env2.combat.get_actor(FOE) == null and _count(env2, "hostile_withdrawn") == 0 and _count(env2, "hostile_down") == 1, tag + "abgeschossen: kein Abdrehen, nie zurueck")
	env2.flow.free()


## Nachbesserung 1, W5: Werte in den Daten; je Waffe hoechstens ein Schuss je Sekunde.
func _case_16() -> void:
	var tag := "[16 Zahmer] "
	var env: Dictionary = _build(["ship"])
	var config: Dictionary = env.mission_root._air_role_config("hostile_aircraft")
	_check(is_equal_approx(float(config.get("accuracy", -1.0)), 0.5) and is_equal_approx(float(config.get("fire_interval_seconds", -1.0)), 1.0) and is_equal_approx(float(config.get("withdraw_seconds", -1.0)), 10.0), tag + "Daten: accuracy 0,5, fire_interval_seconds 1,0, withdraw_seconds 10,0: " + str(config))
	_tick(env, 20.0)
	for _i in range(12):
		_tick(env, 0.25)
		_refill(env, "ship")
	var before: Dictionary = Dictionary(Dictionary(env.mission_root.get("_air_hostile_state")).get(FOE, {})).get("shots", {}).duplicate(true)
	for _i in range(40):
		_tick(env, 0.25)
		_refill(env, "ship")
	var after: Dictionary = Dictionary(Dictionary(env.mission_root.get("_air_hostile_state")).get(FOE, {})).get("shots", {})
	var total := 0
	var worst := 0
	for slot in after:
		var n := int(after[slot]) - int(before.get(slot, 0))
		total += n
		worst = maxi(worst, n)
	_check(total >= 6 and worst <= 10, tag + "in 10 s je Waffe hoechstens 10 Schuesse, insgesamt aber geschossen (je Waffe max %d, gesamt %d): %s" % [worst, total, str(after)])
	env.flow.free()


## Nachbesserung 1, W1: Speichern mit fliegendem Gegner wird mit eigenem Grund und Satz abgelehnt (mit und ohne Lenkung).
func _case_17() -> void:
	var tag := "[17 Speichern] "
	var sentence := "Speichern geht gerade nicht: Ein feindlicher Flieger ist in der Luft."
	_check(PROJECTION.blocked_text("air_hostile_present") == sentence, tag + "Satz zum Grund air_hostile_present: " + PROJECTION.blocked_text("air_hostile_present"))
	var env0: Dictionary = _build(["ship"])
	_tick(env0, 10.0)
	_check(env0.source.has_method("has_air_hostile") and not env0.source.has_air_hostile(), tag + "vor dem Auftauchen kein Gegner im Kampagnenkern (Speichern nicht gesperrt)")
	env0.flow.free()
	var env1: Dictionary = _build(["ship"])
	_tick(env1, 21.0)
	_check(Dictionary(env1.combat.get_flight_controls()).has(FOE), tag + "Aufbau: Gegner mit Lenkung")
	var with_control: Dictionary = CAPTURE.capture_components(env1.flow, env1.adapter)
	_check(not bool(with_control.get("ok", true)) and String(with_control.get("reason", "")) == "air_hostile_present", tag + "mit Lenkung: " + str(with_control.get("reason", "ok")))
	env1.flow.free()
	var env2: Dictionary = _build(["ship"], Vector2i(19, 19))
	_tick(env2, 20.2)
	_check(env2.combat.get_actor(FOE) != null and not Dictionary(env2.combat.get_flight_controls()).has(FOE), tag + "Aufbau: Gegner ohne Lenkung")
	var without_control: Dictionary = CAPTURE.capture_components(env2.flow, env2.adapter)
	_check(not bool(without_control.get("ok", true)) and String(without_control.get("reason", "")) == "air_hostile_present", tag + "ohne Lenkung: " + str(without_control.get("reason", "ok")))
	env2.flow.free()
	var env3: Dictionary = _build(["ship"])
	_tick(env3, 20.0)
	_check(_kill_foe(env3) > 0, tag + "Aufbau: Gegner abgeschossen")
	_tick(env3, 0.4)
	_check(env3.source.has_method("has_air_hostile") and not env3.source.has_air_hostile(), tag + "nach dem Abschuss kein Gegner mehr (Speichern wieder frei)")
	env3.flow.free()


## Nachbesserung 1, K1: der Gegner haelt sein Ziel, auch wenn ein anderes eigenes Schiff naeher kommt.
func _case_18() -> void:
	var tag := "[18 Ziel halten] "
	var env: Dictionary = _build(["ship", "ship2"], Vector2i(17, 10), true, {"ship":Vector2i(10, 10), "ship2":Vector2i(12, 18)})
	_tick(env, 20.0)
	_tick(env, 0.6)
	var face0: Variant = Dictionary(Dictionary(env.combat.get_flight_controls().get(FOE, {})).get("goal", {})).get("face_plane")
	var first := ""
	if face0 is Vector2:
		for id in ["ship", "ship2"]:
			if (face0 as Vector2).distance_to(_pose(env, id).position_plane) < 0.3: first = id
	_check(not first.is_empty(), tag + "Aufbau: der Gegner hat ein erstes Ziel: " + str(face0))
	var other := "ship2" if first == "ship" else "ship"
	var goal: Dictionary = env.mission_root._air_set_goal(other, Vector2i(15, 11))
	_check(bool(goal.get("ok", false)), tag + "Aufbau: das andere Schiff fliegt am Gegner vorbei: " + str(goal.get("reason", "ok")))
	var seen := {}
	var closest := INF
	for _i in range(50):
		_tick(env, 0.2)
		_refill(env, "ship"); _refill(env, "ship2")
		var control: Dictionary = Dictionary(env.combat.get_flight_controls().get(FOE, {}))
		var face: Variant = Dictionary(control.get("goal", {})).get("face_plane")
		closest = minf(closest, _foe_pose(env).position_plane.distance_to(_pose(env, other).position_plane) - _foe_pose(env).position_plane.distance_to(_pose(env, first).position_plane))
		if face is Vector2:
			for id in ["ship", "ship2"]:
				if (face as Vector2).distance_to(_pose(env, id).position_plane) < 0.3: seen[id] = true
	_check(closest < -1.0, tag + "Aufbau: das andere Schiff war zeitweise mehr als ein Feld naeher (%.2f)" % closest)
	_check(seen.keys() == [first], tag + "in 10 s kein Zielwechsel, bleibt bei %s: %s" % [first, str(seen.keys())])
	env.flow.free()


## Nachbesserung 1, K2/K4: Merkzettel je Gegner werden auf jedem Weg geleert; ohne Ziel keine Dauer-Lenkung.
func _case_19() -> void:
	var tag := "[19 Aufraeumen/Lage halten] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 22.0)
	var area := "atmosphere:moon_site"
	var cfg := {"sensor_range":1.0, "standoff_hex":6.0}
	var rev0 := int(Dictionary(env.combat.get("_claim_revisions")).get(area, 0))
	for _i in range(5): env.mission_root._air_hostile_step(env.source, env.combat, FOE, cfg)
	var rev1 := int(Dictionary(env.combat.get("_claim_revisions")).get(area, 0))
	_check(rev1 - rev0 <= 2, tag + "ohne Ziel hoechstens eine Lenkung in 5 Schritten (Anspruchsaenderungen %d)" % (rev1 - rev0))
	env.combat.remove_actor(FOE)
	_tick(env, 0.5)
	_check(Dictionary(env.source.get("_air_hostile_models")).is_empty() and Array(env.mission_root.get("_air_hostile_ids")).is_empty() and Dictionary(env.mission_root.get("_air_hostile_state")).is_empty(), tag + "fehlt der Akteur, sind Modell- und Merkzettel leer")
	env.flow.free()


## Nachbesserung 1: ohne Eintrag enemy_aircraft aendert sich nichts (Zufallsstrom, Taktzaehler) - Adapter in Kampagne (leere Liste) gegen gar nicht konfiguriert.
func _signature(env: Dictionary) -> Array:
	var root_node: Node = env.mission_root
	return [int(env.source.get("_space_fire_rng")), int(env.source.tick_counter), root_node.get("_air_role_poll"), root_node.get("_air_support_fire_poll"), root_node.get("_air_hostile_poll"), root_node.get("_air_hostile_clock"), Array(root_node.get("_air_hostile_ids")).size(), Array(root_node.get("_air_hostile_pending")).size()]


func _case_20() -> void:
	var tag := "[20 ohne Eintrag] "
	var a: Dictionary = _build(["ship"], null, true, {}, "res://data/mission_scenarios/ground_mission01_default.json")
	_tick(a, 60.0)
	var b: Dictionary = _build(["ship"], [])
	_tick(b, 60.0)
	var c: Dictionary = _build(["ship"], null)
	_tick(c, 60.0)
	var sig_a := _signature(a)
	_check(sig_a == _signature(b) and sig_a == _signature(c), tag + "Adapter/Kampagne = leere Liste = nicht konfiguriert: %s | %s | %s" % [str(sig_a), str(_signature(b)), str(_signature(c))])
	_check(int(sig_a[0]) == 1 and a.combat.get_area_actor_ids("atmosphere:moon_site") == ["ship"], tag + "kein Zufallszug, nur das eigene Schiff im Gebiet")
	a.flow.free(); b.flow.free(); c.flow.free()


## Nachbesserung 1, K3: das schon geladene Szenario des Einsatzes wird benutzt (kein zweites Laden von der Platte).
func _case_21() -> void:
	var tag := "[21 geladenes Szenario] "
	var scenario = SCENARIO.new()
	scenario.tactical_authoring = {"enemy_aircraft":[{"aircraft_id":"k3_foe", "model_id":"buccaneer", "spawn_hex":{"x":17, "y":10}, "delay_seconds":20.0}]}
	var env: Dictionary = _build(["ship"], null, true, {}, "", scenario)
	var pending: Array = Array(env.mission_root.get("_air_hostile_pending"))
	_check(pending.size() == 1 and String(pending[0].aircraft_id) == "k3_foe", tag + "Eintrag aus dem geladenen Szenario uebernommen: " + str(pending))
	env.flow.free()


## Nachbesserung 1, K5: Ziel nur bei passendem control_domain; Fraktion allein genuegt nicht.
func _case_22() -> void:
	var tag := "[22 control_domain] "
	var env: Dictionary = _build(["ship"])
	_tick(env, 20.0)
	_refill(env, FOE); _refill(env, "ship")
	var meta: Dictionary = env.combat.get("_metadata")[FOE]
	meta["control_domain"] = "neutral"
	var refused: Dictionary = env.source.resolve_local_ship_shot("ship", FOE, "weapon_1", "c22-1")
	_check(not bool(refused.get("ok", true)) and String(refused.get("reason", "")) == "not_hostile", tag + "andere Fraktion, aber control_domain neutral: abgelehnt: " + str(refused.get("reason", "ok")))
	meta["control_domain"] = "enemy"
	var allowed: Dictionary = env.source.resolve_local_ship_shot("ship", FOE, "weapon_1", "c22-2")
	_check(bool(allowed.get("ok", false)), tag + "control_domain enemy: Schuss moeglich: " + str(allowed.get("reason", "ok")))
	env.flow.free()


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
	_case_13()
	_case_13b()
	_case_14()
	_case_15()
	_case_16()
	_case_17()
	_case_18()
	_case_19()
	_case_20()
	_case_21()
	_case_22()
	print("AIR_HOSTILE_AIRCRAFT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
