extends SceneTree
## Luftrollen 5a: Sortie-Spielstand im Kern - Rundbahn, Rolle, Treibstoffuhr, Rueckflug, Zufall, feindlicher Flieger, Atmosphaeren-Pose im Flug-/Flotten-Spielstand.
## Rein rechnerisch an einer kleinen Attrappen-Mission (Fixture wie air_fuel_verifier und air_hostile_aircraft_verifier), echter Versorgungsbesitzer.
## Angeschlossen an das Speichern wird erst in 5b; hier pruefen die Kernfunktionen export/prepare/publish_air_sortie_checkpoint.
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
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const SPACE = preload("res://scripts/core/space_combat_state.gd")
const DT := 0.05
const LOC := "satellite_crash"
const FOE := "pirate_buccaneer_1"
const SCHEMA := "air_sortie_checkpoint.v1"
const BAD := "invalid_air_sortie_checkpoint"

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
	func get_multiplayer_visible_unit_ids(_team: String) -> PackedStringArray:
		return PackedStringArray([])

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
		print("AIR_SORTIE_CHECKPOINT FAIL: ", label)
	return ok


# ---------------------------------------------------------------- Aufbau
## Felder 5..19, Landezone (10,10). accounts: Schiff -> Tankinhalt. spawn: Feld des feindlichen Fliegers (null: keiner konfiguriert).
func _build(craft_ids: Array[String], accounts: Dictionary, spawn: Variant = null) -> Dictionary:
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
	_check(bool(supply.configure([], {}).get("ok", false)), "Aufbau: Versorgungsdaten werden angenommen")
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
	for id in craft_ids:
		var pilot = FixPerson.new(); pilot.unit_id = "pilot_" + id; mission.add_child(pilot); units.register_unit(pilot.unit_id, pilot); mission_root.register_known_unit(pilot.unit_id, pilot)
		pilot.set_meta("dropship_embarked", true)
	var vision = FixVision.new(); vision.name = "CombatLoopDriver"; mission.add_child(vision)
	var transport = FixTransport.new(); transport.name = "TacticalController"; mission.add_child(transport)
	for q in range(5, 20):
		for r in range(5, 20): terrain.register_tile(TILE.new({"tile_id":"air:%d:%d" % [q, r], "grid_position":Vector2i(q, r), "explicit_hex_ramps":true}))
	for id in craft_ids:
		transport.landed_position[id] = terrain.grid_to_world(Vector2i(10, 10))
		transport.parked[id] = true
	source.tick_counter = 50
	var events: Array = []
	mission_root.air_role_event.connect(func(event: Dictionary) -> void: events.append(event))
	if spawn != null:
		mission_root.configure_enemy_aircraft([{"aircraft_id":FOE, "model_id":"buccaneer", "faction_id":"pirates", "spawn_hex":spawn, "delay_seconds":20.0}])
	return {"flow":flow, "adapter":adapter, "source":source, "fleet":fleet, "mission_root":mission_root, "terrain":terrain, "transport":transport, "events":events, "tick":50, "combat":source.get("_space_combat_state"), "supply":supply, "equipment":equipment}


# ---------------------------------------------------------------- Helfer
func _run(env: Dictionary, seconds: float) -> void:
	var source: Node = env.source
	var mission_root: Node = env.mission_root
	for _i in range(int(round(seconds / DT))):
		env.tick = int(env.tick) + 1
		source.tick_counter = int(env.tick)
		source._advance_space_flights(DT, int(env.tick))
		mission_root._advance_air_support_orders(DT)


func _sortie(env: Dictionary, id: String) -> Dictionary:
	return Dictionary(env.mission_root.get("_air_support_sorties")).get(id, {})


func _count(env: Dictionary, id: String, kind: String) -> int:
	var n := 0
	for event in env.events:
		if event.craft_id == id and event.kind == kind:
			n += 1
	return n


func _circle(env: Dictionary, id: String, center: Vector2i, role: String, request_id: String) -> Dictionary:
	return env.mission_root.request_air_support_circle({"craft_id":id, "center_hex":center, "role":role, "request_id":request_id})


func _air_receipts(env: Dictionary) -> Array:
	var ids: Array = []
	for request_id in Dictionary(env.supply.get("_requests")).keys():
		if String(request_id).begins_with("air-fuel:"):
			ids.append(String(request_id))
	return ids


func _wire(block: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(block, "", true, true))


## Block mit geaenderten Inhalt: entschluesseln, aendern (Callable), wieder verpacken.
func _tampered(block: Dictionary, change: Callable) -> Dictionary:
	var data: Dictionary = CODEC.decode_value(block.payload).value
	change.call(data)
	return {"schema":block.schema, "payload":CODEC.encode_value(data).value}


## Gleich bis auf die letzte Gleitkommastelle: der JSON-Umweg (Godot liest Dezimalzahlen nicht immer bitgenau) darf kein Fehlschlag sein.
func _same(left: Variant, right: Variant) -> bool:
	var left_type := typeof(left)
	if left_type in [TYPE_INT, TYPE_FLOAT] and typeof(right) in [TYPE_INT, TYPE_FLOAT]: return absf(float(left) - float(right)) <= 0.000000001 * maxf(1.0, absf(float(left)))
	if left_type != typeof(right): return false
	match left_type:
		TYPE_VECTOR2: return left.distance_to(right) <= 0.000001
		TYPE_DICTIONARY:
			if left.size() != right.size(): return false
			for key in left:
				if not right.has(key) or not _same(left[key], right[key]): return false
			return true
		TYPE_ARRAY:
			if left.size() != right.size(): return false
			for i in left.size():
				if not _same(left[i], right[i]): return false
			return true
	return left == right


func _api(env: Dictionary, tag: String) -> bool:
	var mission_root: Node = env.mission_root
	var present: bool = mission_root.has_method("export_air_sortie_checkpoint") and mission_root.has_method("prepare_air_sortie_checkpoint") and mission_root.has_method("publish_air_sortie_checkpoint") and mission_root.has_method("get_air_hostile_ids")
	if not present:
		_check(false, tag + "die Kernfunktionen export/prepare/publish_air_sortie_checkpoint und get_air_hostile_ids fehlen")
		env.flow.free()
	return present


## Stand des Kampagnenkerns und des Sortie-Blocks, der sich durch ein abgelehntes prepare nicht aendern darf.
func _stamp(env: Dictionary) -> Dictionary:
	var mission_root: Node = env.mission_root
	var flight: RefCounted = env.fleet.get_flight_state("ship")
	return {"sorties":Dictionary(mission_root.get("_air_support_sorties")).keys(), "serial":mission_root.get("_air_sortie_serial"), "rng":mission_root.get("_air_ground_rng_state"), "hostile_ids":Array(mission_root.get("_air_hostile_ids")).duplicate(), "pending":Array(mission_root.get("_air_hostile_pending")).duplicate(true),
		"clock":mission_root.get("_air_hostile_clock"), "armed":mission_root.get("_air_hostile_armed"), "configured":mission_root.get("_air_hostile_configured"), "pose":flight.get_snapshot(), "fleet":env.fleet.export_checkpoint_state(["ship"]),
		"nav":env.combat.export_navigation_checkpoint(), "systems":env.combat.export_systems_checkpoint(), "supply":env.supply.export_state(), "models":Dictionary(env.source.get("_air_hostile_models")).duplicate()}


func _enemy_count(env: Dictionary) -> int:
	var n := 0
	var metadata: Dictionary = env.combat.get("_metadata")
	for id in metadata:
		if String(Dictionary(metadata[id]).get("control_domain", "")) == "enemy": n += 1
	return n


# ---------------------------------------------------------------- Faelle
## Fall 1: Rolle none, Wegpunkt 2, Treibstoffuhr 30.5 / Schritt 3 / gewarnt: nach Export, Verwerfen und Laden gleicher Schnappschuss; die Uhr zaehlt weiter.
func _case_1() -> void:
	var tag := "[1 Rundbahn und Treibstoffuhr] "
	var env: Dictionary = _build(["ship"], {"ship":12.5})
	if not _api(env, tag): return
	var mission_root: Node = env.mission_root
	var res: Dictionary = _circle(env, "ship", Vector2i(10, 10), "none", "c1")
	_check(bool(res.get("ok", false)) and bool(res.get("took_off", false)), tag + "Aufbau: Start und Rundbahn: " + str(res))
	var sortie: Dictionary = _sortie(env, "ship")
	_check(bool(mission_root._air_goto_waypoint("ship", sortie, 2).get("ok", false)), tag + "Aufbau: Wegpunkt 2 wird angeflogen")
	sortie["fuel_seconds"] = 30.5
	sortie["fuel_steps"] = 3
	sortie["fuel_warned"] = true
	var before: Dictionary = mission_root.get_air_support_role_snapshot("ship")
	_check(int(before.waypoint_index) == 2 and bool(before.fuel_warned) and String(before.role) == "none" and before.center_hex == Vector2i(10, 10), tag + "Aufbau: Schnappschuss vorher " + str(before))
	var serial: int = int(sortie.sortie_serial)
	var waypoints_before: Array = Array(sortie.waypoints).duplicate()
	var pose_before: Dictionary = Dictionary(sortie.previous_pose).duplicate(true)
	var exported: Dictionary = mission_root.export_air_sortie_checkpoint()
	_check(exported.get("schema") == SCHEMA and exported.has("payload") and exported.size() == 2, tag + "Export hat Schema und Nutzlast: " + str(exported.keys()))
	var wire: Dictionary = _wire(exported)
	Dictionary(mission_root.get("_air_support_sorties")).erase("ship")
	_check(Dictionary(mission_root.get("_air_support_sorties")).is_empty() and not bool(mission_root.get_air_support_role_snapshot("ship").ok), tag + "Sortie verworfen")
	var prepared: Dictionary = mission_root.prepare_air_sortie_checkpoint(wire, {"fleet":env.fleet})
	_check(bool(prepared.get("ok", false)) and not bool(prepared.get("empty", false)) and prepared.has("candidate"), tag + "prepare nimmt den Block an: " + str(prepared.get("reason", "ok")))
	_check(Dictionary(mission_root.get("_air_support_sorties")).is_empty(), tag + "prepare aendert nichts")
	if not prepared.get("ok", false):
		env.flow.free()
		return
	mission_root.publish_air_sortie_checkpoint(prepared.candidate)
	var after: Dictionary = mission_root.get_air_support_role_snapshot("ship")
	_check(after == before, tag + "Schnappschuss gleich wie vorher: " + str(after))
	var restored: Dictionary = _sortie(env, "ship")
	_check(restored.get("flight") == env.fleet.get_flight_state("ship") and int(restored.get("sortie_serial", -1)) == serial and Array(restored.get("waypoints", [])) == waypoints_before and _same(restored.get("previous_pose"), pose_before), tag + "Sortie-Eintrag: Flug, Serial, Wegpunkte, Vorlage")
	_check(is_equal_approx(float(restored.get("fuel_seconds", -1.0)), 30.5) and int(restored.get("fuel_steps", -1)) == 3 and bool(restored.get("fuel_warned", false)) and String(restored.get("role_target_id", "x")) == "", tag + "Treibstoffuhr gesichert, Ziel leer")
	var control: Dictionary = Dictionary(env.combat.get_flight_controls().get("ship", {}))
	_check(bool(control.get("air_support_move", false)) and Vector2(Dictionary(control.get("goal", {})).get("target_plane", Vector2.INF)).distance_to(GRID.HEX.axial_to_plane(Vector2(waypoints_before[2]))) < 0.001, tag + "Lenkung fliegt Wegpunkt 2 an")
	var revision: int = env.supply.get_revision()
	_run(env, 29.4)
	_check(is_equal_approx(float(env.supply.get_fuel("ship")), 12.5) and _air_receipts(env).is_empty(), tag + "nach 29,4 s keine Buchung (%s)" % str(env.supply.get_fuel("ship")))
	_run(env, 0.1)
	_check(is_equal_approx(float(env.supply.get_fuel("ship")), 11.5), tag + "nach 29,5 s genau eine Buchung (%s)" % str(env.supply.get_fuel("ship")))
	var expected_id := "air-fuel:ship:%s:%d:4:r%d" % [LOC, serial, revision]
	_check(_air_receipts(env) == [expected_id], tag + "Beleg-ID mit Schritt 4: erwartet %s, ist %s" % [expected_id, str(_air_receipts(env))])
	_check(int(mission_root.get("_air_fuel_book_failures")) == 0, tag + "keine gescheiterte Buchung (kein request_id_conflict)")
	_check(_count(env, "ship", "fuel_warning") == 0, tag + "keine zweite Warnung")
	env.flow.free()


## Fall 2: Stand ohne Block: ok, leer, keine Sortie; ohne Luft-Einsatz gibt es keinen Block, nichts wird gezogen oder gezaehlt.
func _case_2() -> void:
	var tag := "[2 ohne Block] "
	var env: Dictionary = _build(["ship"], {"ship":14.0}, Vector2i(17, 10))
	if not _api(env, tag): return
	var mission_root: Node = env.mission_root
	_run(env, 5.0)
	_check(mission_root.export_air_sortie_checkpoint().is_empty(), tag + "ohne Luft-Einsatz: leerer Export (kein Block)")
	_check(int(mission_root.get("_air_ground_rng_state")) == 1 and int(mission_root.get("_air_sortie_serial")) == 0, tag + "Zufallsstrom und Serial unberuehrt")
	var none: Dictionary = mission_root.prepare_air_sortie_checkpoint({}, {"fleet":env.fleet})
	_check(bool(none.get("ok", false)) and bool(none.get("empty", false)), tag + "fehlender Block: ok, leer: " + str(none))
	mission_root.publish_air_sortie_checkpoint(none)
	_check(Dictionary(mission_root.get("_air_support_sorties")).is_empty() and Array(mission_root.get("_air_hostile_ids")).is_empty() and Array(mission_root.get("_air_hostile_pending")).size() == 1, tag + "keine Sortie, Gegnerplan der Konfiguration bleibt")
	_check(int(mission_root.get("_air_ground_rng_state")) == 1 and int(mission_root.get("_air_sortie_serial")) == 0 and not bool(mission_root.get("_air_hostile_armed")), tag + "nach dem Laden ohne Block weiter alles unberuehrt")
	var rng_before: int = int(mission_root.get("_air_ground_rng_state"))
	_check(rng_before == 1 and mission_root.get_air_hostile_ids() == [], tag + "keine Gegnerkennungen")
	env.flow.free()


## Fall 3: Gegner mit Rumpf 40, Schild 0: nach dem Laden genau ein Akteur mit gleicher Lage, gleichem Verhalten, Uhr und Meldemerker.
func _case_3() -> void:
	var tag := "[3 Gegner] "
	var env: Dictionary = _build(["ship"], {"ship":50.0}, Vector2i(17, 10))
	if not _api(env, tag): return
	var mission_root: Node = env.mission_root
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "air_defense", "c3").get("ok", false)), tag + "Aufbau: Luftschutz an (10,10)")
	_run(env, 20.0)
	_run(env, 1.0)
	_check(env.combat.get_actor(FOE) != null and mission_root.get_air_hostile_ids() == [FOE] and env.source.has_air_hostile(), tag + "Aufbau: Gegner fliegt")
	var systems: Dictionary = env.combat.get("_ship_systems")[FOE]
	var slot := String(Dictionary(systems.stats.weapons[0]).slot_id)
	systems.state["hull"] = 40.0
	systems.state["shield"] = 0.0
	systems.cooldowns[slot] = 0.5
	var behaviour: Dictionary = mission_root.get("_air_hostile_state")[FOE]
	behaviour["shots"] = {slot:3}
	behaviour["last_shot"] = {slot:12.5}
	behaviour["spotted"] = true
	var pose_before: Dictionary = env.combat.get_actor(FOE).get_snapshot()
	var systems_before: Dictionary = env.combat.get_ship_systems(FOE)
	var exported: Dictionary = mission_root.export_air_sortie_checkpoint()
	_check(exported.get("schema") == SCHEMA, tag + "Export mit Gegner: " + str(exported.get("reason", "ok")))
	var wire: Dictionary = _wire(exported)
	var clock: float = float(mission_root.get("_air_hostile_clock"))
	var now: float = float(mission_root.get("_air_hostile_now"))
	# Neue Welt nachgestellt: Sortie und Gegner verwerfen.
	mission_root._air_hostile_release_all()
	Dictionary(mission_root.get("_air_support_sorties")).erase("ship")
	mission_root.set("_air_hostile_clock", 0.0)
	mission_root.set("_air_hostile_armed", false)
	_check(env.combat.get_actor(FOE) == null and not env.source.has_air_hostile() and _enemy_count(env) == 0, tag + "Gegner verworfen")
	var prepared: Dictionary = mission_root.prepare_air_sortie_checkpoint(wire, {"fleet":env.fleet})
	_check(bool(prepared.get("ok", false)), tag + "prepare nimmt Block mit Gegner an: " + str(prepared.get("reason", "ok")))
	_check(env.combat.get_actor(FOE) == null and _enemy_count(env) == 0, tag + "prepare nimmt den Gegner noch nicht auf")
	if not prepared.get("ok", false):
		env.flow.free()
		return
	mission_root.publish_air_sortie_checkpoint(prepared.candidate)
	_check(_enemy_count(env) == 1 and env.combat.get_actor(FOE) != null and mission_root.get_air_hostile_ids() == [FOE] and Dictionary(env.source.get("_air_hostile_models")).keys() == [FOE], tag + "genau ein Akteur, Kennung im Missions- und Kampagnenkern")
	var restored: Dictionary = env.combat.get_ship_systems(FOE)
	_check(is_equal_approx(float(restored.state.hull), 40.0) and is_equal_approx(float(restored.state.shield), 0.0), tag + "Rumpf 40, Schild 0: %s / %s" % [str(restored.state.hull), str(restored.state.shield)])
	_check(_same(restored.state, systems_before.state) and _same(restored.cooldowns, systems_before.cooldowns) and is_equal_approx(float(restored.cooldowns.get(slot, -1.0)), 0.5), tag + "Systemzustand und Abkuehlzeit gleich")
	var pose: Dictionary = env.combat.get_actor(FOE).get_snapshot()
	var same := true
	for key in ["position_plane", "velocity_plane", "heading_rad", "angular_velocity", "space_area_id", "assist_mode", "motion_mode", "mass", "coordinate_frame"]:
		if not _same(pose[key], pose_before[key]): same = false
	_check(same, tag + "gleiche Lage: %s statt %s" % [str(pose.position_plane), str(pose_before.position_plane)])
	var state: Dictionary = mission_root.get("_air_hostile_state")[FOE]
	_check(bool(state.spotted) and state.shots == {slot:3} and state.last_shot == {slot:12.5} and bool(state.entry.has("aircraft_id")) and not bool(state.holding), tag + "Verhalten: gesichtet, Schussliste, Feuerpause")
	_check(is_equal_approx(float(mission_root.get("_air_hostile_clock")), clock) and is_equal_approx(float(mission_root.get("_air_hostile_now")), now) and bool(mission_root.get("_air_hostile_armed")) and bool(mission_root.get("_air_hostile_configured")), tag + "Uhr, Zeitbezug, bewaffnet und konfiguriert gesichert")
	var again: Dictionary = mission_root.export_air_sortie_checkpoint()
	_check(_same(CODEC.decode_value(again.payload).value, CODEC.decode_value(exported.payload).value), tag + "erneuter Export gleich dem ersten")
	var before_events: int = env.events.size()
	_run(env, 5.0)
	_check(mission_root.get_air_hostile_ids() == [FOE] and _enemy_count(env) == 1 and Array(mission_root.get("_air_hostile_pending")).is_empty(), tag + "nach 5 s weiter genau ein Gegner, kein zweiter")
	var spotted := 0
	for i in range(before_events, env.events.size()):
		if env.events[i].kind == "hostile_spotted": spotted += 1
	_check(spotted == 0, tag + "kein zweites 'gesichtet'")
	# Verdorbener Gegner: unbekanntes Modell, Rumpf ueber Kapazitaet.
	var bad_model: Dictionary = _tampered(wire, func(data: Dictionary) -> void: data.hostiles[FOE]["model_id"] = "carrack")
	_check(String(mission_root.prepare_air_sortie_checkpoint(bad_model, {"fleet":env.fleet}).get("reason", "")) == BAD, tag + "unbekanntes Gegner-Modell abgelehnt")
	var bad_hull: Dictionary = _tampered(wire, func(data: Dictionary) -> void: data.hostiles[FOE].systems_state["hull"] = 9999.0)
	_check(String(mission_root.prepare_air_sortie_checkpoint(bad_hull, {"fleet":env.fleet}).get("reason", "")) == BAD, tag + "Rumpf ueber Kapazitaet abgelehnt")
	var bad_pos: Dictionary = _tampered(wire, func(data: Dictionary) -> void: data.hostiles[FOE]["position_plane"] = Vector2(5000.0, 5000.0))
	_check(String(mission_root.prepare_air_sortie_checkpoint(bad_pos, {"fleet":env.fleet}).get("reason", "")) == BAD, tag + "Gegner ausserhalb der Karte abgelehnt")
	env.flow.free()


## Fall 4: verdorbene Staende: je invalid_air_sortie_checkpoint, Sorties danach leer, Kampagnenkern unveraendert.
func _case_4() -> void:
	var tag := "[4 verdorben] "
	var env: Dictionary = _build(["ship"], {"ship":14.0})
	if not _api(env, tag): return
	var mission_root: Node = env.mission_root
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "cas", "c4").get("ok", false)), tag + "Aufbau: CAS an (10,10)")
	_run(env, 2.0)
	var exported: Dictionary = mission_root.export_air_sortie_checkpoint()
	var wire: Dictionary = _wire(exported)
	Dictionary(mission_root.get("_air_support_sorties")).erase("ship")
	var good: Dictionary = mission_root.prepare_air_sortie_checkpoint(wire, {"fleet":env.fleet})
	_check(bool(good.get("ok", false)), tag + "Gegenprobe: der unveraenderte Block wird angenommen: " + str(good.get("reason", "ok")))
	var landed_fleet = FLEET.new(); landed_fleet.configure(); landed_fleet.register_craft("ship")
	var cases := {
		"waypoint_index 9 bei 6 Wegpunkten": func(data: Dictionary) -> void: data.sorties.ship["waypoint_index"] = 9,
		"waypoint_index negativ": func(data: Dictionary) -> void: data.sorties.ship["waypoint_index"] = -1,
		"fuel_seconds 61": func(data: Dictionary) -> void: data.sorties.ship["fuel_seconds"] = 61.0,
		"fuel_seconds negativ": func(data: Dictionary) -> void: data.sorties.ship["fuel_seconds"] = -0.5,
		"fuel_steps negativ": func(data: Dictionary) -> void: data.sorties.ship["fuel_steps"] = -1,
		"returning unbekannt": func(data: Dictionary) -> void: data.sorties.ship["returning"] = "x",
		"returning mit Rundbahn": func(data: Dictionary) -> void: data.sorties.ship["returning"] = "fuel",
		"landing_grid ausserhalb der Karte": func(data: Dictionary) -> void: data.sorties.ship["landing_grid"] = Vector2i(90, 90),
		"Wegpunkt ausserhalb der Karte": func(data: Dictionary) -> void: data.sorties.ship.waypoints[0] = Vector2i(90, 90),
		"Rolle ausserhalb der Karte": func(data: Dictionary) -> void: data.sorties.ship.air_role["center_hex"] = Vector2i(90, 90),
		"Rolle mit falschem Befehlswort": func(data: Dictionary) -> void: data.sorties.ship.air_role["verb"] = "withdraw",
		"Rolle unbekannt": func(data: Dictionary) -> void: data.sorties.ship.air_role["role"] = "bomber",
		"Haltung unbekannt": func(data: Dictionary) -> void: data.sorties.ship.air_role["stance"] = "wild",
		"Rolle ohne Wegpunkte": func(data: Dictionary) -> void: data.sorties.ship["waypoints"] = [],
		"sortie_serial groesser als der Zaehler": func(data: Dictionary) -> void: data.sorties.ship["sortie_serial"] = 99,
		"unbekannter Schluessel": func(data: Dictionary) -> void: data.sorties.ship["role_target_id"] = "x",
		"Marker kein Wahrheitswert": func(data: Dictionary) -> void: data.sorties.ship["fuel_warned"] = 1,
		"Zufallsstrom negativ": func(data: Dictionary) -> void: data["rng"] = -3,
		"Vorlage in der Atmosphaere": func(data: Dictionary) -> void: data.sorties.ship.previous_pose["space_area_id"] = "atmosphere:" + LOC,
		"Schiff unbekannt": func(data: Dictionary) -> void: data.sorties["ghost"] = data.sorties.ship.duplicate(true),
		"Block ohne Schluessel": func(data: Dictionary) -> void: data.erase("hostiles"),
	}
	for label in cases:
		var stamp_before: Dictionary = _stamp(env)
		var result: Dictionary = mission_root.prepare_air_sortie_checkpoint(_tampered(wire, cases[label]), {"fleet":env.fleet})
		_check(not bool(result.get("ok", true)) and String(result.get("reason", "")) == BAD, tag + label + ": " + str(result.get("reason", "ok")))
		_check(_stamp(env) == stamp_before and Dictionary(mission_root.get("_air_support_sorties")).is_empty(), tag + label + ": Sorties leer, Kern unveraendert")
	# Schiff laut Flug nicht in der Luft.
	var stamp_ground: Dictionary = _stamp(env)
	var ground: Dictionary = mission_root.prepare_air_sortie_checkpoint(wire, {"fleet":landed_fleet})
	_check(String(ground.get("reason", "")) == BAD and _stamp(env) == stamp_ground and Dictionary(mission_root.get("_air_support_sorties")).is_empty(), tag + "Schiff laut Flug nicht in der Luft: " + str(ground.get("reason", "ok")))
	# Schema und Aufbau des Blocks.
	for broken in [{"schema":"air_sortie_checkpoint.v2", "payload":wire.payload}, {"schema":SCHEMA}, {"schema":SCHEMA, "payload":["array", []]}, {"schema":SCHEMA, "payload":wire.payload, "extra":1}, {"schema":SCHEMA, "payload":"kaputt"}]:
		var answer: Dictionary = mission_root.prepare_air_sortie_checkpoint(broken, {"fleet":env.fleet})
		_check(not bool(answer.get("ok", true)) and String(answer.get("reason", "")) == BAD, tag + "falscher Aufbau: " + str(broken.keys()) + " " + str(answer.get("reason", "ok")))
	var no_fleet: Dictionary = mission_root.prepare_air_sortie_checkpoint(wire, {})
	_check(String(no_fleet.get("reason", "")) == BAD, tag + "ohne Flotte in den Bindungen abgelehnt")
	_check(Dictionary(mission_root.get("_air_support_sorties")).is_empty(), tag + "am Ende weiter keine Sortie")
	env.flow.free()


## Fall 5: Zufall: nach Export und Laden liefert draw_air_ground_roll() denselben Wert wie ohne Speichern.
func _case_5() -> void:
	var tag := "[5 Zufall] "
	var env: Dictionary = _build(["ship"], {"ship":14.0})
	if not _api(env, tag): return
	var mission_root: Node = env.mission_root
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "c5").get("ok", false)), tag + "Aufbau: Kreisen")
	mission_root.set("_air_ground_rng_state", 12345)
	var exported: Dictionary = mission_root.export_air_sortie_checkpoint()
	var wire: Dictionary = _wire(exported)
	var expected_state := (12345 * 1103515245 + 12345) & 0x7fffffff
	var reference: float = mission_root.draw_air_ground_roll()
	_check(is_equal_approx(reference, float(expected_state) / 2147483648.0), tag + "Aufbau: Bezugswert ohne Speichern")
	for _i in range(7): mission_root.draw_air_ground_roll()
	Dictionary(mission_root.get("_air_support_sorties")).erase("ship")
	var prepared: Dictionary = mission_root.prepare_air_sortie_checkpoint(wire, {"fleet":env.fleet})
	_check(bool(prepared.get("ok", false)), tag + "prepare: " + str(prepared.get("reason", "ok")))
	if prepared.get("ok", false):
		mission_root.publish_air_sortie_checkpoint(prepared.candidate)
		_check(int(mission_root.get("_air_ground_rng_state")) == 12345, tag + "Zufallsstrom wieder bei 12345")
		_check(is_equal_approx(float(mission_root.draw_air_ground_roll()), reference), tag + "derselbe Wert wie ohne Speichern")
	env.flow.free()


## Fall 6: Rueckflug 'fuel' mit gemeldeter blockierter Landung: laeuft nach dem Laden weiter, kein zweites landing_blocked, landet, sobald frei.
func _case_6() -> void:
	var tag := "[6 Rueckflug und blockierte Landung] "
	var env: Dictionary = _build(["ship"], {"ship":14.0})
	if not _api(env, tag): return
	var mission_root: Node = env.mission_root
	env.transport.landing_clear = false
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "c6").get("ok", false)), tag + "Aufbau: Kreisen")
	_check(bool(mission_root._air_begin_return("ship", "fuel").get("ok", false)), tag + "Aufbau: Rueckflug 'fuel'")
	var waited := 0.0
	while _count(env, "ship", "landing_blocked") == 0 and waited < 90.0:
		_run(env, 0.5)
		waited += 0.5
	_check(_count(env, "ship", "landing_blocked") == 1 and bool(_sortie(env, "ship").get("landing_blocked_reported", false)), tag + "Aufbau: landing_blocked einmal gemeldet (%.1f s)" % waited)
	var before: Dictionary = mission_root.get_air_support_role_snapshot("ship")
	var exported: Dictionary = mission_root.export_air_sortie_checkpoint()
	var wire: Dictionary = _wire(exported)
	Dictionary(mission_root.get("_air_support_sorties")).erase("ship")
	var prepared: Dictionary = mission_root.prepare_air_sortie_checkpoint(wire, {"fleet":env.fleet})
	_check(bool(prepared.get("ok", false)), tag + "prepare: " + str(prepared.get("reason", "ok")))
	if not prepared.get("ok", false):
		env.flow.free()
		return
	mission_root.publish_air_sortie_checkpoint(prepared.candidate)
	var after: Dictionary = mission_root.get_air_support_role_snapshot("ship")
	_check(after == before and String(after.returning) == "fuel", tag + "Rueckflug 'fuel' unveraendert: " + str(after))
	_check(bool(_sortie(env, "ship").get("landing_blocked_reported", false)), tag + "Meldemerker gesichert")
	_run(env, 10.0)
	_check(_count(env, "ship", "landing_blocked") == 1 and Dictionary(mission_root.get("_air_support_sorties")).has("ship"), tag + "nach 10 s kein zweites landing_blocked, Schiff wartet")
	env.transport.landing_clear = true
	waited = 0.0
	while Dictionary(mission_root.get("_air_support_sorties")).has("ship") and waited < 30.0:
		_run(env, 0.5)
		waited += 0.5
	_check(not Dictionary(mission_root.get("_air_support_sorties")).has("ship") and _count(env, "ship", "landed") == 1, tag + "landet, sobald die Landezone frei ist (%.1f s)" % waited)
	_check(_count(env, "ship", "landing_blocked") == 1, tag + "weiter nur ein landing_blocked")
	env.flow.free()


## Fall 7: Flug-/Flotten-Spielstand: Atmosphaeren-Pose nur mit ID in air_sortie_craft_ids; der bisherige Fall ohne Liste bleibt abgelehnt.
func _case_7() -> void:
	var tag := "[7 Atmosphaere im Flotten-Spielstand] "
	var env: Dictionary = _build(["ship"], {"ship":14.0})
	if not _api(env, tag): return
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "c7").get("ok", false)), tag + "Aufbau: Kreisen")
	_run(env, 2.0)
	var flight: RefCounted = env.fleet.get_flight_state("ship")
	var pose: Dictionary = flight.get_snapshot()
	_check(String(pose.space_area_id) == "atmosphere:" + LOC and pose.motion_mode == "tactical", tag + "Aufbau: Flugpose in der Atmosphaere")
	# Flug allein.
	var plain: Dictionary = flight.export_checkpoint_state()
	_check(not plain.has("schema") and String(plain.get("reason", "")) == "unsupported_flight_checkpoint", tag + "Flug ohne Erlaubnis: abgelehnt (bisheriger Fall): " + str(plain.get("reason", "ok")))
	var allowed: Dictionary = flight.export_checkpoint_state(true)
	_check(allowed.get("schema") == "space_flight_checkpoint.v1" and String(allowed.space_area_id) == "atmosphere:" + LOC, tag + "Flug mit Erlaubnis: Export")
	var flight_wire: Dictionary = _wire(allowed)
	_check(not bool(flight.prepare_checkpoint_restore(flight_wire).get("ok", true)), tag + "Flug: Wiederherstellen ohne Erlaubnis abgelehnt")
	_check(bool(flight.prepare_checkpoint_restore(flight_wire, true).get("ok", false)), tag + "Flug: Wiederherstellen mit Erlaubnis angenommen")
	var inactive_wire: Dictionary = flight_wire.duplicate(true)
	inactive_wire["motion_mode"] = "inactive"
	_check(not bool(flight.prepare_checkpoint_restore(inactive_wire, true).get("ok", true)), tag + "Flug: Atmosphaere im Modus inactive bleibt abgelehnt")
	# Flotte: Reisezustand der Phase surface am Ort (so steht ein gelandetes Schiff vor dem Start), Flugpose in der Luft.
	var owner: RefCounted = env.fleet._owners["ship"]
	var raw: Dictionary = owner._checkpoint_raw_state()
	raw["phase"] = "surface"
	raw["craft_id"] = "ship"
	raw["location_id"] = LOC
	raw["orbit_id"] = String(env.fleet.get_craft_snapshot("ship").location_orbits.get(LOC, ""))
	raw["target_orbit_id"] = ""
	raw["target_orbit_marker_id"] = ""
	raw["route_hexes"] = []
	var travel := {"schema":"space_travel_checkpoint.v1", "craft_id":"ship", "system_fingerprint":JSON.stringify(owner.get("_definition"), "", true).sha256_text(), "travel":CODEC.encode_value(raw).value, "flight":allowed}
	var fleet_state := {"schema":"space_fleet_checkpoint.v1", "focus":"ship", "crafts":{"ship":travel}, "receipts":{}}
	var fleet_wire: Dictionary = _wire(fleet_state)
	var receiver = FLEET.new(); receiver.configure()
	var before: Dictionary = receiver.export_checkpoint_state()
	var with_list: Dictionary = receiver.prepare_checkpoint_restore(fleet_wire, ["ship"], ["ship"])
	_check(bool(with_list.get("ok", false)), tag + "Flotte mit ID in air_sortie_craft_ids angenommen: " + str(with_list.get("reason", "ok")))
	_check(not bool(receiver.prepare_checkpoint_restore(fleet_wire, ["ship"]).get("ok", true)), tag + "Flotte ohne Liste abgelehnt")
	_check(not bool(receiver.prepare_checkpoint_restore(fleet_wire, ["ship"], []).get("ok", true)), tag + "Flotte mit leerer Liste abgelehnt")
	_check(not bool(receiver.prepare_checkpoint_restore(fleet_wire, ["ship"], ["other"]).get("ok", true)), tag + "Flotte mit fremder ID in der Liste abgelehnt")
	_check(receiver.export_checkpoint_state() == before, tag + "abgelehnte und gepruefte Wiederherstellungen lassen den Empfaenger unberuehrt")
	if with_list.get("ok", false):
		var rebuilt: RefCounted = with_list.candidate
		_check(rebuilt.get_flight_state("ship") != flight and rebuilt.get_flight_state("ship").get_snapshot().space_area_id == "atmosphere:" + LOC, tag + "frische Flug-Instanz mit Atmosphaeren-Pose")
		_check(rebuilt.export_checkpoint_state(["ship"]) == fleet_state, tag + "Flotten-Spielstand mit Liste ueberlebt den Rundlauf")
		_check(rebuilt.export_checkpoint_state().get("ok", true) == false, tag + "ohne Liste laesst sich die Flotte in der Luft weiter nicht sichern")
	# Reisephase ohne Ort oder falsches Gebiet: auch mit Liste abgelehnt.
	var grounded_raw: Dictionary = raw.duplicate(true)
	grounded_raw["phase"] = "grounded"
	grounded_raw["location_id"] = "homebase"
	grounded_raw["orbit_id"] = ""
	var bad_phase: Dictionary = _wire(fleet_state)
	bad_phase.crafts.ship.travel = CODEC.encode_value(grounded_raw).value
	_check(not bool(receiver.prepare_checkpoint_restore(bad_phase, ["ship"], ["ship"]).get("ok", true)), tag + "Phase grounded mit Atmosphaere auch mit Liste abgelehnt")
	var other_area: Dictionary = _wire(fleet_state)
	other_area.crafts.ship.flight["space_area_id"] = "atmosphere:trade_outpost"
	_check(not bool(receiver.prepare_checkpoint_restore(other_area, ["ship"], ["ship"]).get("ok", true)), tag + "Atmosphaere eines anderen Orts abgelehnt")
	env.flow.free()


## Fall 8: skip_ids: Navigation und Systeme ohne den Gegner (er steht nur im Sortie-Block); ohne Liste wie bisher.
func _case_8() -> void:
	var tag := "[8 skip_ids] "
	var env: Dictionary = _build(["ship"], {"ship":50.0}, Vector2i(17, 10))
	if not _api(env, tag): return
	var mission_root: Node = env.mission_root
	_check(bool(_circle(env, "ship", Vector2i(10, 10), "none", "c8").get("ok", false)), tag + "Aufbau: Kreisen")
	_run(env, 21.0)
	_check(mission_root.get_air_hostile_ids() == [FOE] and Dictionary(env.combat.get_flight_controls()).has(FOE), tag + "Aufbau: Gegner fliegt mit eigener Steuerung")
	_check(Dictionary(Dictionary(env.combat.get_flight_controls().get("ship", {})).get("goal", {})).has("face_plane"), tag + "Aufbau: die Lenkung des Schiffs hat goal.face_plane (Nase auf den Wegpunkt)")
	var skip: Array = mission_root.get_air_hostile_ids()
	var nav: Dictionary = env.combat.export_navigation_checkpoint(skip)
	_check(nav.get("schema") == "space_navigation_checkpoint.v1", tag + "Navigation ohne Gegner exportiert: " + str(nav.get("reason", "ok")))
	if nav.has("schema"):
		var data: Dictionary = CODEC.decode_value(nav.payload).value
		_check(data.metadata.keys() == ["ship"] and data.flight_snapshots.keys() == ["ship"] and data.indexed_revisions.keys() == ["ship"] and not data.controls.has(FOE) and not data.status.has(FOE) and not data.claims.has(FOE), tag + "Navigation: nur das eigene Schiff")
		var actors: Array = []
		for entry in nav.registry.actors: actors.append(entry.craft_id)
		_check(actors == ["ship"], tag + "Navigationsindex: nur das eigene Schiff " + str(actors))
		# Ohne JSON-Umweg: dort koennen Gleitkommawerte in der letzten Stelle abweichen, im echten Laden stammen Flug und Navigation aber aus demselben Draht.
		var candidate: Dictionary = SPACE.prepare_navigation_checkpoint_candidate(nav, {"ship":env.fleet.get_flight_state("ship")}, {"ship":{"equipment_owner":env.equipment, "mission_root":mission_root}})
		_check(bool(candidate.get("ok", false)), tag + "Navigation ohne Gegner laesst sich einschliesslich Luft-Steuerung (goal.face_plane) wiederherstellen: " + str(candidate.get("reason", "ok")))
	var full: Dictionary = env.combat.export_navigation_checkpoint()
	_check(not full.has("schema") or CODEC.decode_value(full.payload).value.metadata.has(FOE), tag + "ohne Liste wie bisher (Gegner nicht herausgenommen)")
	var systems: Dictionary = env.combat.export_systems_checkpoint(skip)
	_check(systems.get("schema") == "space_systems_checkpoint.v1" and CODEC.decode_value(systems.payload).value.systems.keys() == ["ship"], tag + "Systeme ohne Gegner")
	var systems_all: Dictionary = env.combat.export_systems_checkpoint()
	_check(CODEC.decode_value(systems_all.payload).value.systems.size() == 2 and systems_all == env.combat.export_systems_checkpoint([]), tag + "Systeme ohne Liste wie bisher")
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
	print("AIR_SORTIE_CHECKPOINT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
