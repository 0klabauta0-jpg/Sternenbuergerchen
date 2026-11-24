extends SceneTree
## Luftrollen 4b: Rolle Luftschutz - das Schiff waehlt selbst feindliche Flieger im Umkreis 8 (haelt sie bis 12 um die Mitte), verfolgt sie, schiesst mit dem
## Schiffsschuss und kehrt danach auf die Rundbahn zurueck. Der Spieler hat Vorrang. Rein rechnerisch an der Attrappen-Mission von air_cas_role_verifier / air_hostile_aircraft_verifier.
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
const FOE := "pirate_buccaneer_1"

var _passed := 0
var _failed := 0


class FixFlow extends Node:
	var _active_mission: Node
	var _craft_location_runtime := {}
	var _assigned_aircraft_pilot_by_craft := {}
	func get_active_mission() -> Node: return _active_mission
	func is_campaign_start() -> bool: return true

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
	func get_multiplayer_visible_unit_ids(_team: String) -> PackedStringArray: return PackedStringArray(ids)

class FixTransport extends Node:
	var boarded := true
	var style := "normal"
	var parked := {}
	var landed_position := {}
	func _find_mission_dropship_card_entry(_craft_id: String) -> Dictionary: return {"approach_style":style}
	func get_campaign_air_support_pilot_guard(craft_id: String) -> Dictionary:
		return {"ok":true, "pilot_unit_id":"pilot_" + craft_id} if boarded else {"ok":false, "reason":"pilot_boarding_pending"}
	func _is_parked_campaign_dropship(craft_id: String) -> bool: return bool(parked.get(craft_id, false))
	func _campaign_landed_craft_position(craft_id: String) -> Vector2: return landed_position.get(craft_id, Vector2.ZERO)
	func _ground_ship_touchdown_ready(_id: String, _position: Vector2, _visual: bool) -> bool: return true


func _check(ok: bool, label: String) -> bool:
	if ok:
		_passed += 1
	else:
		_failed += 1
		print("AIR_DEFENSE_ROLE FAIL: ", label)
	return ok


# ---------------------------------------------------------------- Aufbau
## Felder 5..19, Landezone (10,10). spawn: Feld des Gegners (Vector2i.ZERO = keiner), er erscheint 1 s nach dem Start des Schiffs. ground: Bodengegner (Team red), sichtbar.
func _build(spawn: Vector2i, ground: Dictionary = {}) -> Dictionary:
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
	var vision = FixVision.new(); vision.name = "CombatLoopDriver"; vision.ids = ground.keys(); mission.add_child(vision)
	var transport = FixTransport.new(); transport.name = "TacticalController"; mission.add_child(transport)
	for q in range(5, 20):
		for r in range(5, 20): terrain.register_tile(TILE.new({"tile_id":"air:%d:%d" % [q, r], "grid_position":Vector2i(q, r), "explicit_hex_ramps":true}))
	transport.landed_position["ship"] = terrain.grid_to_world(Vector2i(10, 10))
	transport.parked["ship"] = true
	var placements: Array[Dictionary] = []
	for id in ground.keys():
		var foe = FixPerson.new(); foe.unit_id = String(id); foe.team = "red"; mission.add_child(foe); units.register_unit(foe.unit_id, foe); mission_root.register_known_unit(foe.unit_id, foe)
		placements.append({"unit_id":String(id), "grid":ground[id]})
	if not placements.is_empty(): mission_root.admit_hex_ground_units(placements)
	source.tick_counter = 50
	var events: Array = []
	mission_root.air_role_event.connect(func(event: Dictionary) -> void: events.append(event))
	if spawn != Vector2i.ZERO: mission_root.configure_enemy_aircraft([{"aircraft_id":FOE, "model_id":"buccaneer", "faction_id":"pirates", "spawn_hex":spawn, "delay_seconds":1.0}])
	return {"flow":flow, "adapter":adapter, "source":source, "fleet":fleet, "mission_root":mission_root, "transport":transport, "pilot":pilot, "events":events, "tick":50, "combat":source.get("_space_combat_state")}


func _tick(env: Dictionary, seconds: float, refill: bool = true) -> void:
	var source: Node = env.source
	var mission_root: Node = env.mission_root
	for i in range(int(round(seconds / DT))):
		env.tick = int(env.tick) + 1
		source.tick_counter = int(env.tick)
		mission_root.tick_counter = int(env.tick)
		source._advance_space_flights(DT, int(env.tick))
		mission_root._advance_air_support_orders(DT)
		if refill and i % 5 == 0: _refill(env, "ship")


## Schild, Rumpf, Waffenenergie voll, Abkuehlzeiten leer (das Schiff soll den Kampf ueberleben, der Luftrumpf bleibt unberuehrt).
func _refill(env: Dictionary, id: String) -> void:
	var entry: Dictionary = env.combat.get("_ship_systems")[id]
	entry.state["hull"] = float(entry.state.hull_capacity)
	entry.state["shield"] = float(entry.stats.shield.capacity)
	entry.state["weapon_energy"] = float(entry.stats.weapon_reserve.capacity)


func _foe_strength(env: Dictionary) -> float:
	var systems: Dictionary = env.combat.get_ship_systems(FOE)
	return -1.0 if systems.is_empty() else float(systems.state.hull) + float(systems.state.shield)


func _pose(env: Dictionary, id: String) -> Dictionary:
	return env.fleet.get_flight_state(id).get_snapshot()


func _sortie(env: Dictionary) -> Dictionary:
	return Dictionary(env.mission_root.get("_air_support_sorties")).get("ship", {})


func _target(env: Dictionary) -> String:
	return String(_sortie(env).get("role_target_id", ""))


func _order(env: Dictionary) -> Dictionary:
	var binding: Dictionary = env.mission_root._resolve_air_support_craft("ship")
	if not binding.get("ok", false): return {}
	return Dictionary(binding.wings.get_snapshot().wings.get(binding.wing_id, {})).get("order", {})


func _count(env: Dictionary, kind: String) -> int:
	var n := 0
	for event in env.events:
		if event.craft_id == "ship" and event.kind == kind: n += 1
	return n


func _circle(env: Dictionary, role: String, request_id: String, center: Vector2i = Vector2i(10, 10)) -> Dictionary:
	return env.mission_root.request_air_support_circle({"craft_id":"ship", "center_hex":center, "role":role, "request_id":request_id})


## Rolle setzen und bis zum Erscheinen des Gegners ticken (ohne Kampf zu fuehren).
func _spawned(env: Dictionary, role: String, request_id: String) -> bool:
	if not bool(_circle(env, role, request_id).get("ok", false)): return false
	for _i in range(40):
		_tick(env, 0.1)
		if env.combat.get_actor(FOE) != null: return true
	return false


# ---------------------------------------------------------------- Faelle
## Fall 1: Gegner auf (17,10), Abstand 7: Ziel nach hoechstens 0,5 s, Rottenbefehl attack_target, Nase aufs Ziel, Schild oder Rumpf des Gegners sinken, Ziel bleibt dasselbe.
func _case_1() -> void:
	var tag := "[1 Ziel, Verfolgung, Feuer] "
	var env: Dictionary = _build(Vector2i(17, 10))
	_check(_spawned(env, "air_defense", "c1"), tag + "Aufbau: Luftschutz an (10,10), Gegner erscheint")
	var full := _foe_strength(env)
	_tick(env, 0.6)
	var order: Dictionary = _order(env)
	_check(_target(env) == FOE, tag + "nach 0,6 s ist role_target_id der Gegner: '%s'" % _target(env))
	_check(order.get("verb") == "attack_target" and order.get("fire_rule") == "free" and order.get("target_id") == FOE, tag + "Rottenbefehl attack_target / free: " + str(order))
	_check(_count(env, "target_engaged") == 1, tag + "Ereignis target_engaged genau einmal")
	var changes := 0
	var last := _target(env)
	var nose_ok := false
	for _i in range(80):
		_tick(env, 0.25)
		if env.combat.get_actor(FOE) == null: break
		if _target(env) != last: changes += 1; last = _target(env)
		var control: Dictionary = Dictionary(env.combat.get_flight_controls().get("ship", {}))
		var goal: Dictionary = Dictionary(control.get("goal", {}))
		var foe_plane: Vector2 = env.combat.get_actor(FOE).get_snapshot().position_plane
		if goal.has("face_plane") and Vector2(goal.face_plane).distance_to(foe_plane) < 1.5: nose_ok = true
	_check(changes == 0, tag + "20 s lang kein Zielwechsel (%d)" % changes)
	_check(nose_ok, tag + "Lenkung mit face_plane auf dem Gegner")
	_check(env.combat.get_actor(FOE) == null or _foe_strength(env) < full, tag + "Schild oder Rumpf des Gegners sinken (%.1f -> %.1f)" % [full, _foe_strength(env)])
	env.flow.free()


## Fall 2: Gegner auf (19,10), Abstand 9 zur Mitte: kein Ziel (gleich nach dem Erscheinen).
func _case_2() -> void:
	var tag := "[2 ausserhalb 8] "
	var env: Dictionary = _build(Vector2i(19, 10))
	_check(_spawned(env, "air_defense", "c2"), tag + "Aufbau")
	_tick(env, 0.3)
	_check(_target(env) == "" and _order(env).get("verb") != "attack_target" and _count(env, "target_engaged") == 0, tag + "kein Ziel, kein Angriffsbefehl")
	# Direkt: Abstand 9 wird nicht gewaehlt, Abstand 8 schon (Mitte um eins verschoben), Halten bis 12.
	var sortie: Dictionary = _sortie(env).duplicate(true)
	var cell: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(env.combat.get_actor(FOE).get_snapshot().position_plane))
	var contacts: Array = [FOE]
	for pair in [[9, ""], [8, FOE]]:
		sortie["air_role"]["center_hex"] = cell - Vector2i(int(pair[0]), 0)
		_check(env.mission_root._air_pick_air_target("ship", sortie, contacts) == String(pair[1]), tag + "Abstand %d: gewaehlt '%s'" % [int(pair[0]), String(pair[1])])
	sortie["air_role"]["center_hex"] = cell - Vector2i(12, 0)
	sortie["role_target_id"] = FOE
	_check(env.mission_root._air_pick_air_target("ship", sortie, contacts) == FOE, tag + "gehaltenes Ziel bei Abstand 12 bleibt")
	sortie["air_role"]["center_hex"] = cell - Vector2i(13, 0)
	_check(env.mission_root._air_pick_air_target("ship", sortie, contacts) == "", tag + "bei Abstand 13 faellt das Ziel weg")
	sortie["role_target_id"] = FOE
	_check(env.mission_root._air_pick_air_target("ship", sortie, []) == "", tag + "nicht mehr auf dem Radar: Ziel weg")
	env.flow.free()


## Fall 3: sichtbarer Bodengegner (Bodenflugabwehr zaehlt nicht), kein Luftziel: kein Ziel, kein Befehl.
func _case_3() -> void:
	var tag := "[3 Bodenziel] "
	var env: Dictionary = _build(Vector2i.ZERO, {"gun":Vector2i(13, 10)})
	_check(bool(_circle(env, "air_defense", "c3").get("ok", false)), tag + "Aufbau")
	_tick(env, 10.0)
	_check(_target(env) == "" and _order(env).get("verb") != "attack_target" and _count(env, "target_engaged") == 0, tag + "kein Ziel, kein Angriffsbefehl auf das Bodenziel")
	env.flow.free()


## Fall 4: Gegner abgeschossen: Ziel weg, Befehl beendet, Ereignis, Lenkung wieder auf einem Wegpunkt der Rundbahn.
func _case_4() -> void:
	var tag := "[4 Rueckkehr] "
	var env: Dictionary = _build(Vector2i(17, 10))
	_check(_spawned(env, "air_defense", "c4"), tag + "Aufbau")
	_tick(env, 3.0)
	_check(_target(env) == FOE, tag + "Aufbau: Ziel gewaehlt")
	env.combat.get("_ship_systems")[FOE].state["hull"] = 0.0
	_tick(env, 5.0)
	var goal: Dictionary = Dictionary(Dictionary(env.combat.get_flight_controls().get("ship", {})).get("goal", {}))
	var on_ring := false
	for cell in _sortie(env).get("waypoints", []):
		if goal.has("target_plane") and Vector2(goal.target_plane).distance_to(GRID.HEX.axial_to_plane(Vector2(cell))) < 0.01: on_ring = true
	_check(_count(env, "hostile_down") == 1 and env.combat.get_actor(FOE) == null, tag + "Gegner abgeschossen, hostile_down einmal")
	_check(_target(env) == "" and _order(env).get("verb") != "attack_target", tag + "Ziel und Angriffsbefehl weg")
	_check(on_ring, tag + "innerhalb 5 s ist wieder ein Wegpunkt der Rundbahn das Ziel: " + str(goal))
	env.flow.free()


## Fall 5: Rolle CAS mit Gegner in Reichweite: CAS waehlt den Gegner nicht, das Schiff schiesst nicht auf ihn.
func _case_5() -> void:
	var tag := "[5 CAS] "
	var env: Dictionary = _build(Vector2i(17, 10))
	_check(_spawned(env, "cas", "c5"), tag + "Aufbau: CAS, Gegner erscheint")
	var full := _foe_strength(env)
	_tick(env, 6.0)
	_check(_target(env) == "" and _order(env).get("verb") != "attack_target" and _count(env, "target_engaged") == 0, tag + "kein Ziel, kein Angriffsbefehl")
	_check(is_equal_approx(_foe_strength(env), full), tag + "Gegner unversehrt (%.1f von %.1f)" % [_foe_strength(env), full])
	env.flow.free()


## Fall 6: Luftrumpf 45, Stil normal: Abdrehen - Feuer eingestellt, Rueckflug break_off, kein neues Ziel, kein Schuss mehr.
func _case_6() -> void:
	var tag := "[6 Abdrehen] "
	var env: Dictionary = _build(Vector2i(17, 10))
	_check(_spawned(env, "air_defense", "c6"), tag + "Aufbau")
	_tick(env, 3.0)
	_check(_target(env) == FOE, tag + "Aufbau: Ziel gewaehlt")
	env.mission_root.set("_air_asset_status_by_id", {"ship":{"asset_id":"ship", "asset_type":"dropship", "state":"damaged", "integrity":45, "max_integrity":100}})
	_tick(env, 1.0)
	var sortie: Dictionary = _sortie(env)
	_check(String(sortie.get("returning", "")) == "break_off" and Dictionary(sortie.get("air_role", {"x":1})).is_empty() and _target(env) == "", tag + "Rueckflug break_off, Rolle und Ziel leer: " + str(sortie.get("returning")))
	_check(_order(env).get("verb") != "attack_target", tag + "Angriffsbefehl beendet")
	var strength := _foe_strength(env)
	_tick(env, 3.0)
	_check(_foe_strength(env) >= strength - 0.0001 and _count(env, "target_engaged") == 1, tag + "danach kein Schuss und kein neues Ziel (%.1f -> %.1f)" % [strength, _foe_strength(env)])
	env.flow.free()


## Fall 7: der Spieler hat Vorrang. "Feuer einstellen" haelt die Zielwahl an, neue Rolle hebt den Halt auf; ein befohlenes Bodenziel wird nicht ersetzt.
func _case_7() -> void:
	var tag := "[7 Vorrang des Spielers] "
	var env: Dictionary = _build(Vector2i(17, 10))
	_check(_spawned(env, "air_defense", "c7"), tag + "Aufbau")
	_tick(env, 3.0)
	_check(_target(env) == FOE, tag + "Aufbau: Ziel gewaehlt")
	var stopped: Dictionary = env.mission_root.request_air_support_cease_fire("ship", "ui-air-stop:7")
	_check(bool(stopped.get("ok", false)) and bool(_sortie(env).get("cas_hold", false)), tag + "Feuer einstellen des Spielers setzt den Halt: " + str(stopped))
	_tick(env, 1.0)
	var strength := _foe_strength(env)
	_tick(env, 6.0)
	_check(_target(env) == "" and _order(env).get("verb") != "attack_target" and _foe_strength(env) >= strength - 0.0001, tag + "6 s lang kein Ziel, kein Befehl, kein Schuss")
	_check(bool(env.mission_root.get_air_support_role_snapshot("ship").get("cas_hold", false)), tag + "Schnappschuss meldet den Halt")
	_check(bool(_circle(env, "air_defense", "c7b").get("ok", false)) and not bool(_sortie(env).get("cas_hold", false)), tag + "Rolle neu gesetzt hebt den Halt auf")
	# Der Gegner haelt 6 Felder Abstand zum Schiff und kann ausserhalb des Umkreises 8 stehen: bis zu 15 s warten, bis er hineinfliegt.
	for _i in range(60):
		if _target(env) == FOE: break
		_tick(env, 0.25)
	_check(_target(env) == FOE, tag + "danach waehlt das Schiff wieder selbst")
	env.flow.free()
	var env2: Dictionary = _build(Vector2i(17, 10), {"gfoe":Vector2i(13, 10)})
	_check(_spawned(env2, "air_defense", "c7c"), tag + "Aufbau 2")
	var manual: Dictionary = env2.mission_root.request_air_support_attack_order({"craft_id":"ship", "target_unit_id":"gfoe", "request_id":"man7"})
	_check(bool(manual.get("ok", false)), tag + "Aufbau 2: Spielerbefehl auf das Bodenziel: " + str(manual))
	_tick(env2, 3.0)
	_check(_order(env2).get("target_id") == "gfoe" and _target(env2) == "" and _count(env2, "target_engaged") == 0, tag + "Spielerziel bleibt, kein Luftziel dazwischen")
	env2.flow.free()


## Fall 8: Pilotverlust beendet die Rolle, danach kein Schuss mehr.
func _case_8() -> void:
	var tag := "[8 Pilot weg] "
	var env: Dictionary = _build(Vector2i(17, 10))
	_check(_spawned(env, "air_defense", "c8"), tag + "Aufbau")
	_tick(env, 3.0)
	_check(_target(env) == FOE, tag + "Aufbau: Ziel gewaehlt")
	env.transport.boarded = false
	env.pilot.set_meta("dropship_embarked", false)
	_tick(env, 1.0)
	_check(_count(env, "role_ended") == 1 and String(env.mission_root.get_air_support_role_snapshot("ship").get("role", "x")) == "", tag + "role_ended einmal, Rolle leer")
	var strength := _foe_strength(env)
	_tick(env, 5.0)
	_check(_foe_strength(env) >= strength - 0.0001, tag + "danach kein Schuss")
	env.flow.free()


## Nachbesserung 1 (W1): Wechsel CAS -> Luftschutz. Der Bodenbefehl, den CAS selbst gegeben hat, endet; das Schiff nimmt den Flieger. Ein Spielerbefehl bleibt.
func _case_9() -> void:
	var tag := "[9 CAS -> Luftschutz] "
	var env: Dictionary = _build(Vector2i(17, 10), {"gfoe":Vector2i(13, 10)})
	var ground_shots := [0]
	env.mission_root.air_support_ground_fired.connect(func(_event: Dictionary) -> void: ground_shots[0] += 1)
	_check(_spawned(env, "cas", "c9"), tag + "Aufbau: CAS, Gegner erscheint")
	_tick(env, 1.0)
	_check(_order(env).get("target_id") == "gfoe" and String(_sortie(env).get("cas_order_id", "")) != "", tag + "Aufbau: CAS hat selbst den Bodenbefehl auf gfoe gegeben: " + str(_order(env)))
	_check(bool(_circle(env, "air_defense", "c9b").get("ok", false)), tag + "Spieler setzt Luftschutz")
	_check(_order(env).get("target_id") != "gfoe" and not _sortie(env).has("cas_order_id"), tag + "der Bodenbefehl der alten Rolle ist weg, cas_order_id geloescht: " + str(_order(env)))
	var shots_at_switch: int = ground_shots[0]
	for _i in range(60):
		if _target(env) == FOE: break
		_tick(env, 0.25)
	_check(_target(env) == FOE and _order(env).get("target_id") == FOE, tag + "das Schiff nimmt den Flieger als Ziel: '%s' / %s" % [_target(env), str(_order(env))])
	_tick(env, 3.0)
	_check(ground_shots[0] == shots_at_switch, tag + "kein weiterer Schuss auf das Bodenziel (%d -> %d)" % [shots_at_switch, ground_shots[0]])
	env.flow.free()
	# Gegenfall: ein Befehl des Spielers auf das Bodenziel bleibt beim Wechsel stehen.
	var env2: Dictionary = _build(Vector2i(17, 10), {"gfoe":Vector2i(13, 10)})
	_check(_spawned(env2, "cas", "c9c"), tag + "Aufbau 2: CAS")
	var manual: Dictionary = env2.mission_root.request_air_support_attack_order({"craft_id":"ship", "target_unit_id":"gfoe", "request_id":"man9"})
	_check(bool(manual.get("ok", false)), tag + "Aufbau 2: Spielerbefehl auf gfoe: " + str(manual))
	var manual_id := String(_order(env2).get("order_id", ""))
	_check(bool(_circle(env2, "air_defense", "c9d").get("ok", false)), tag + "Spieler setzt Luftschutz (Gegenfall)")
	_tick(env2, 3.0)
	_check(_order(env2).get("target_id") == "gfoe" and String(_order(env2).get("order_id", "")) == manual_id and _target(env2) == "", tag + "Spielerbefehl bleibt stehen, kein Luftziel: " + str(_order(env2)))
	env2.flow.free()


## Nachbesserung 1 (K2): Wechsel Luftschutz -> nur kreisen beendet den Luft-Luft-Befehl; danach kein Schuss mehr, die Schluessel der Rolle sind weg.
func _case_10() -> void:
	var tag := "[10 Luftschutz -> kreisen] "
	var env: Dictionary = _build(Vector2i(17, 10))
	_check(_spawned(env, "air_defense", "c10"), tag + "Aufbau")
	for _i in range(60):
		if _target(env) == FOE: break
		_tick(env, 0.25)
	_check(_target(env) == FOE and String(_sortie(env).get("air_order_id", "")) != "", tag + "Aufbau: Luftschutz hat den Flieger im Befehl")
	_tick(env, 2.0)
	_check(bool(_circle(env, "none", "c10b").get("ok", false)), tag + "Spieler setzt nur kreisen")
	var sortie: Dictionary = _sortie(env)
	_check(_order(env).get("verb") != "attack_target" and _target(env) == "", tag + "Angriffsbefehl beendet, Ziel leer: " + str(_order(env)))
	_check(not sortie.has("air_order_id") and not sortie.has("air_pursuit") and not sortie.has("air_last_shot"), tag + "air_order_id / air_pursuit / air_last_shot geloescht")
	var strength := _foe_strength(env)
	_tick(env, 5.0)
	_check(_foe_strength(env) >= strength - 0.0001 and not _sortie(env).has("air_last_shot") and _order(env).get("verb") != "attack_target", tag + "danach kein Luft-Luft-Schuss (%.1f -> %.1f)" % [strength, _foe_strength(env)])
	env.flow.free()


## Nachbesserung 1: Datenwerte der Luft-Luft-Schuesse und das Spielerintervall (hoechstens ein Schuss je Sekunde und Waffe).
func _case_11() -> void:
	var tag := "[11 Daten, Schussfolge] "
	var file := FileAccess.open("res://data/combat/air_roles.json", FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	var cfg: Dictionary = Dictionary(Dictionary(parsed).get("player_air_to_air", {})) if typeof(parsed) == TYPE_DICTIONARY else {}
	_check(is_equal_approx(float(cfg.get("accuracy", -1.0)), 0.6) and is_equal_approx(float(cfg.get("fire_interval_seconds", -1.0)), 1.0), tag + "player_air_to_air aus air_roles.json: " + str(cfg))
	var env: Dictionary = _build(Vector2i(17, 10))
	_check(_spawned(env, "air_defense", "c11"), tag + "Aufbau")
	for _i in range(60):
		if _target(env) == FOE: break
		_tick(env, 0.25)
	var seen := {}
	var total := 0
	var worst := 0
	for _window in range(3):
		var per_slot := {}
		for _i in range(int(round(5.0 / DT))):
			_tick(env, DT)
			var last: Dictionary = Dictionary(_sortie(env).get("air_last_shot", {}))
			for slot in last.keys():
				if seen.get(slot, null) != last[slot]:
					seen[slot] = last[slot]
					per_slot[slot] = int(per_slot.get(slot, 0)) + 1
					total += 1
		for slot in per_slot.keys(): worst = maxi(worst, int(per_slot[slot]))
	_check(total >= 1, tag + "in 15 s fallen Luft-Luft-Schuesse (%d)" % total)
	_check(worst <= 6, tag + "in jedem 5-s-Fenster hoechstens 5 (+1) Schuesse je Waffe (groesster Wert %d)" % worst)
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
	_case_9()
	_case_10()
	_case_11()
	print("AIR_DEFENSE_ROLE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
