extends SceneTree
## LC2b: Abschuss im Einsatz. Rumpf 0 durch Bodenbeschuss -> ein Wurf (air_crash_rules) -> Notlandung, Bruchlandung oder Explosion.
## Teil 1: Baustein ground_fire_vs_air.gd (Rumpf darf 0 erreichen, genau ein Abschuss-Ereignis).
## Nur ueber den isolierten Testlauf (Wegwerfprofil) starten.

const GFA = preload("res://scripts/combat/ground_fire_vs_air.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const RULES = preload("res://scripts/core/air_crash_rules.gd")
const ROOT_SCRIPT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const TERRAIN_MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const STATUS = preload("res://scripts/mission/air_asset_status.gd")
const CASUALTY = preload("res://scripts/core/campaign_casualty_rules.gd")

var passed := 0
var failed := 0


# ---------------------------------------------------------------- Attrappen fuer Teil 2 (wie air_arrival_circle_verifier, Teil 1)
class FixFlow extends Node:
	var _active_mission: Node
	var _craft_location_runtime := {"ship":"moon_site"}
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}
	func get_active_mission() -> Node: return _active_mission

class FixPerson extends Node2D:
	var unit_id := ""
	var health := 100
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return "blue"
	func get_health() -> int: return health
	func get_character_profile_bundle() -> Dictionary: return {"platform_values":{"dropship_piloting":1.0, "fighter_piloting":1.0}}
	func apply_damage(amount: int, _context: Dictionary = {}) -> bool: health -= amount; return true

class FixVision extends Node:
	func get_multiplayer_visible_unit_ids(_team: String) -> PackedStringArray: return PackedStringArray()

## Attrappe des Missionscontrollers: meldet die Insassen und merkt sich, was der Absturz ihm uebergibt.
class FixTransport extends Node:
	var landing_clear := true
	var occupants: Array = ["pilot", "trooper"]
	var crash_calls: Array = []
	func get_campaign_air_support_pilot_guard(_craft_id: String) -> Dictionary: return {"ok":true, "pilot_unit_id":"pilot"}
	func _is_parked_campaign_dropship(_craft_id: String) -> bool: return false
	func _campaign_landed_craft_position(_craft_id: String) -> Vector2: return Vector2.ZERO
	func _ground_ship_touchdown_ready(_id: String, _position: Vector2, _visual: bool) -> bool: return landing_clear
	func get_air_crash_occupant_ids(_craft_id: String) -> Array: return occupants.duplicate()
	func apply_air_crash(craft_id: String, site: Dictionary, results: Dictionary, order: Array) -> Dictionary:
		crash_calls.append({"craft_id":craft_id, "site":site.duplicate(true), "results":results.duplicate(true), "order":order.duplicate()})
		return {"ok":true}


class Roller extends RefCounted:
	var values: Array = []
	var used := 0
	func next() -> float:
		var value: float = float(values[mini(used, values.size() - 1)]) if not values.is_empty() else 0.5
		used += 1
		return value


func _fid(unit) -> String: return String(unit.id)
func _fweapon(unit) -> String: return String(unit.weapon)
func _ffit(unit) -> bool: return bool(unit.fit)
func _fcontact(unit) -> bool: return bool(unit.contact)
func _fsees(unit, _target) -> Dictionary: return {"visible": bool(unit.visible), "range_tiles": float(unit.dist)}


func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s" % label)
		push_error(label)


func _run() -> void:
	_test_step_shootdown()
	_test_root_outcomes("cutlass")
	_test_root_outcomes("buccaneer")
	_test_casualty_rules()
	await process_frame
	print("AIR_SHOOTDOWN passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _unit(id: String, weapon: String) -> Dictionary:
	return {"id": id, "weapon": weapon, "fit": true, "contact": false, "visible": true, "dist": 6.0}


func _target(craft_type: String, integrity: int = 100, state: String = "intact") -> Dictionary:
	return {"craft_id": "viper", "display_name": "Viper", "pilot_skill": 0.5, "position": Vector2(10, 10), "cell": Vector2i.ZERO,
		"approach_style": "aggressiv", "craft_type": craft_type,
		"status": {"asset_id": "viper", "asset_type": "fighter", "state": state, "integrity": integrity, "max_integrity": 100}}


func _ctx(tick: int, targets: Array, shooters: Array, roller: Roller) -> Dictionary:
	return {"tick": tick, "targets": targets, "shooters": shooters, "id_of": Callable(self, "_fid"), "weapon_of": Callable(self, "_fweapon"),
		"is_fit": Callable(self, "_ffit"), "has_ground_contact": Callable(self, "_fcontact"), "sees": Callable(self, "_fsees"), "roll": Callable(roller, "next")}


## Leichter Jaeger, Raketenwerfer: zwei Treffer (je 50 %) holen ihn herunter; genau EIN Abschuss-Ereignis, auch wenn weitere Schuetzen und Takte folgen.
func _test_step_shootdown() -> void:
	var gfa = GFA.new()
	var roller := Roller.new()
	roller.values = [0.0]
	var shooters: Array = [_unit("g1", "rocket_launcher"), _unit("g2", "rocket_launcher")]
	var target := _target("fighter")
	gfa.step(_ctx(0, [target], shooters, roller))
	var status: Dictionary = target.status
	var tick: int = GFA.lock_ticks("rocket_launcher")
	var after: Array = []
	var shootdowns := 0
	var shot_events := 0
	var last_update: Dictionary = {}
	for i in range(6):
		target.status = status
		var result: Dictionary = gfa.step(_ctx(tick, [target], shooters, roller))
		shootdowns += Array(result.get("shootdowns", [])).size()
		shootdowns += result.events.filter(func(e): return e.type == "shootdown").size()
		for shot in result.events.filter(func(e): return e.type == "shot"):
			shot_events += 1
			if bool(shot.hit): after.append(int(shot.integrity_after))
		if result.updates.has("viper"):
			status = result.updates.viper.snapshot
			last_update = result.updates.viper
		tick += GFA.lock_ticks("rocket_launcher")
	_check(after == [50, 0] or after == [0], "Rumpf faellt auf 0 (Treffer-Folge %s)" % [str(after)])
	_check(int(status.integrity) == 0 and String(status.state) in ["crashed", "destroyed"], "Zustand nach dem zweiten Treffer: Rumpf 0 und Endzustand (%s)" % [str(status.get("state"))])
	_check(shootdowns == 2, "genau ein Abschuss: ein Ereignis und ein Eintrag in der Liste (gezaehlt %d)" % shootdowns)
	var entry: Dictionary = {}
	var fresh = GFA.new()
	var roller2 := Roller.new()
	roller2.values = [0.0]
	var t2 := _target("fighter", 50, "damaged")
	fresh.step(_ctx(0, [t2], [_unit("g1", "rocket_launcher")], roller2))
	var killing: Dictionary = fresh.step(_ctx(GFA.lock_ticks("rocket_launcher"), [t2], [_unit("g1", "rocket_launcher")], roller2))
	if not Array(killing.get("shootdowns", [])).is_empty(): entry = killing.shootdowns[0]
	_check(String(entry.get("craft_id", "")) == "viper" and is_equal_approx(float(entry.get("pilot_skill", -1.0)), 0.5), "Eintrag der Liste: Schiff und Pilotenwert (%s)" % [str(entry)])
	_check(not last_update.is_empty(), "das Ergebnis traegt den Endstand des Rumpfs")


# ---------------------------------------------------------------- Teil 2: SimulationRoot.resolve_air_shootdown mit Flotte und Flug
func _seed_for(outcome: String, skill: float, rules: Dictionary) -> int:
	for candidate in range(1, 20000):
		if String(RULES.resolve_shootdown(skill, rules, candidate).outcome) == outcome: return candidate
	return -1


func _air_fixture(model_id: String) -> Dictionary:
	var flow := FixFlow.new(); root.add_child(flow)
	var adapter = ADAPTER.new(); flow.add_child(adapter); adapter._flow = flow
	var source = ROOT_SCRIPT.new(); adapter.add_child(source); adapter._simulation = source
	var fleet = FLEET.new(); fleet.configure(); fleet.register_craft("ship")
	var equipment = EQUIPMENT.new(); equipment.configure([{"craft_id":"ship", "model_id":model_id}])
	source.configure_singleplayer_owners(null, null, null, fleet); source.configure_ship_equipment(equipment)
	source.configure_departure_adapter(adapter)
	source.get("_space_wing_state").ensure_flying_wings("singleplayer", ["ship"], ["ship"], {"ship":"pilot"})
	var mission := Node.new(); mission.set_meta("location_id", "moon_site"); flow.add_child(mission)
	var mission_root = ROOT_SCRIPT.new(); mission_root.name = "SimulationRoot"; mission.add_child(mission_root); flow._active_mission = mission
	adapter.bind_mission_air_support(mission)
	var terrain = TERRAIN.new(); terrain.name = "Terrain"; mission.add_child(terrain); terrain.configure_iso_grid(Vector2.ZERO, 64, 32, "hex_axial_v1")
	terrain.register_tile(TILE.new({"tile_id":"zero", "grid_position":Vector2i.ZERO, "explicit_hex_ramps":true}))
	var units = UNITS.new(); units.name = "Units"; mission.add_child(units)
	mission_root.unit_registry_path = mission_root.get_path_to(units); mission_root.terrain_registry_path = mission_root.get_path_to(terrain)
	var map = TERRAIN_MAP.create_empty("moon_site", Vector2i(4, 3), Vector2.ZERO, 64, 32, 3, "hex_axial_v1"); map.set_tactical_grid_rules("hex_tactical_v1")
	mission_root.configure_hex_ground_runtime(map, terrain)
	for id in ["pilot", "trooper"]:
		var person = FixPerson.new(); person.unit_id = id; mission.add_child(person); units.register_unit(id, person); mission_root.register_known_unit(id, person)
		person.set_meta("dropship_embarked", true)
	var vision = FixVision.new(); vision.name = "CombatLoopDriver"; mission.add_child(vision)
	var transport = FixTransport.new(); transport.name = "TacticalController"; mission.add_child(transport)
	for q in range(5, 20):
		for r in range(5, 20): terrain.register_tile(TILE.new({"tile_id":"air:%d:%d" % [q, r], "grid_position":Vector2i(q, r), "explicit_hex_ramps":true}))
	var lz_grid := Vector2i(10, 10)
	var flight: RefCounted = fleet.get_flight_state("ship")
	var initial_pose: Dictionary = flight.get_snapshot()
	source.tick_counter = 50
	var arrival: Dictionary = mission_root.request_air_support_arrival("ship", terrain.grid_to_world(lz_grid))
	_check(bool(arrival.get("ok", false)) and mission_root.is_air_support_craft_airborne("ship"), "Aufbau %s: Schiff in der Luft ueber der Landezone (%s)" % [model_id, str(arrival)])
	return {"flow": flow, "root": mission_root, "flight": flight, "initial": initial_pose, "transport": transport, "lz_grid": lz_grid}


func _down_status() -> Dictionary:
	return {"asset_id": "ship", "asset_type": "dropship", "state": "crashed", "integrity": 0, "max_integrity": 100}


func _shoot(f: Dictionary, outcome: String, rules: Dictionary, skill: float = 0.0) -> Dictionary:
	f.root.set("_air_ground_rng_state", _seed_for(outcome, skill, rules))
	return f.root.resolve_air_shootdown("ship", skill, "Cutlass", _down_status())


func _test_root_outcomes(model_id: String) -> void:
	var rules: Dictionary = RULES.load_rules()
	var tag := "[%s] " % model_id
	# --- Notlandung: Schiff gelandet (Pose wie vor dem Flug), Rumpf aus den Daten, Insassen unberuehrt an Bord.
	var f := _air_fixture(model_id)
	var emergency := _shoot(f, "emergency_landing", rules)
	_check(bool(emergency.get("ok", false)) and emergency.outcome == "emergency_landing", tag + "Notlandung gewuerfelt: " + str(emergency.get("outcome", emergency)))
	_check(not f.root.is_air_support_craft_airborne("ship") and not Dictionary(f.root.get("_air_support_sorties")).has("ship"), tag + "Notlandung: Schiff nicht mehr in der Luft, Sortie beendet")
	_check(f.flight.get_snapshot().motion_mode == f.initial.motion_mode and f.flight.get_snapshot().position_plane == f.initial.position_plane, tag + "Notlandung: Schiff steht wieder wie vor dem Flug")
	var landed: Dictionary = f.root.get_air_asset_status_snapshot("ship")
	_check(int(landed.get("integrity", -1)) == int(rules.emergency_landing_hull_percent) and not STATUS.is_terminal_state(String(landed.get("state", ""))), tag + "Notlandung: Rumpf %d %% (aus den Daten), kein Endzustand (%s)" % [int(rules.emergency_landing_hull_percent), str(landed.get("state"))])
	_check(emergency.messages == ["Notlandung geglückt. Rumpf %d %%." % int(rules.emergency_landing_hull_percent)], tag + "Notlandung: Meldung wortgleich: " + str(emergency.messages))
	_check(f.root.get_air_crash_sites().is_empty() and f.transport.crash_calls.is_empty() and not f.root.is_air_craft_crashed("ship"), tag + "Notlandung: keine Absturzstelle, Insassen unberuehrt (nichts abgesetzt)")
	var again: Dictionary = f.root.resolve_air_shootdown("ship", 0.0, "Cutlass", _down_status())
	_check(not bool(again.get("ok", true)) and f.root.get_air_crash_sites().is_empty(), tag + "kein zweiter Abschuss desselben Schiffs")
	f.flow.free()
	# --- Notlandung ohne freie Landezone: Bruchlandung.
	f = _air_fixture(model_id)
	f.transport.landing_clear = false
	var blocked := _shoot(f, "emergency_landing", rules)
	_check(bool(blocked.get("ok", false)) and blocked.outcome == "crash" and f.root.is_air_craft_crashed("ship"), tag + "Notlandung ohne freie Landezone wird als Bruchlandung behandelt: " + str(blocked.get("outcome", blocked)))
	f.flow.free()
	# --- Bruchlandung und Explosion.
	for outcome in ["crash", "explosion"]:
		f = _air_fixture(model_id)
		var seed_value: int = _seed_for(outcome, 0.0, rules)
		var after_shot: int = int(RULES.resolve_shootdown(0.0, rules, seed_value).rng_state)
		var expected: Dictionary = RULES.resolve_occupants(outcome, ["pilot", "trooper"], rules, after_shot)
		var down := _shoot(f, outcome, rules)
		_check(bool(down.get("ok", false)) and down.outcome == outcome, tag + outcome + ": gewuerfelt")
		_check(not f.root.is_air_support_craft_airborne("ship") and not Dictionary(f.root.get("_air_support_sorties")).has("ship"), tag + outcome + ": Schiff aus der Luft")
		_check(f.transport.crash_calls.size() == 1 and f.transport.crash_calls[0].results == expected.results and f.transport.crash_calls[0].order == ["pilot", "trooper"], tag + outcome + ": Insassen in fester Reihenfolge (Pilot zuerst) mit den Ausgaengen aus resolve_occupants")
		_check(int(f.root.get("_air_ground_rng_state")) == int(expected.rng_state), tag + outcome + ": Zufallszustand zurueckgelegt (Schiff-Wurf, dann Insassen)")
		var sites: Array = f.root.get_air_crash_sites()
		_check(sites.size() == 1 and sites[0] == {"craft_id": "ship", "model_id": model_id, "grid": f.lz_grid, "outcome": outcome}, tag + outcome + ": Absturzstelle gemerkt: " + str(sites))
		var final_status: Dictionary = f.root.get_air_asset_status_snapshot("ship")
		_check(int(final_status.get("integrity", -1)) == 0 and STATUS.is_terminal_state(String(final_status.get("state", ""))), tag + outcome + ": Schiff im Endzustand, Rumpf 0")
		var wanted_first: String = "Cutlass explodiert." if outcome == "explosion" else "Bruchlandung! Cutlass ist verloren."
		_check(down.messages.size() == 2 and down.messages[0] == wanted_first, tag + outcome + ": Meldung wortgleich: " + str(down.messages))
		var dead := 0
		var hurt := 0
		for id in expected.results:
			if expected.results[id].state == "dead": dead += 1
			elif expected.results[id].state in ["light", "severe"]: hurt += 1
		var balance: String = ", ".join(([("%d verletzt" % hurt)] if hurt > 0 else []) + ([("%d tot" % dead)] if dead > 0 else [])) if hurt + dead > 0 else "Alle unversehrt"
		_check(down.messages.size() == 2 and down.messages[1] == balance, tag + outcome + ": Bilanz-Zeile '%s' (gemeldet: %s)" % [balance, str(down.messages)])
		if outcome == "explosion":
			var unhurt := 0
			for id in expected.results:
				if expected.results[id].state == "unhurt": unhurt += 1
			_check(unhurt == 0, tag + "Explosion: kein Unversehrter")
		var second: Dictionary = f.root.resolve_air_shootdown("ship", 0.0, "Cutlass", _down_status())
		_check(not bool(second.get("ok", true)) and f.root.get_air_crash_sites().size() == 1 and f.transport.crash_calls.size() == 1, tag + outcome + ": genau ein Abschuss je Schiff")
		var takeoff: Dictionary = f.root.request_air_support_takeoff("ship")
		_check(not bool(takeoff.get("ok", true)), tag + outcome + ": kein neuer Start nach dem Absturz (%s)" % str(takeoff.get("reason")))
		f.flow.free()
	# --- Gleicher Startzustand, gleicher Ablauf.
	var runs: Array = []
	for i in range(2):
		f = _air_fixture(model_id)
		var one := _shoot(f, "crash", rules)
		runs.append({"outcome": one.outcome, "messages": one.messages, "results": one.get("results", {}), "rng": f.root.get("_air_ground_rng_state"), "sites": f.root.get_air_crash_sites()})
		f.flow.free()
	_check(runs[0] == runs[1], tag + "gleicher Startzustand: gleicher Ablauf (zweimal)")


# ---------------------------------------------------------------- Teil 3: Einstufung am Einsatzende (campaign_casualty_rules)
func _ts(id: String, vital: String, extra: Dictionary = {}) -> Dictionary:
	var state := {"unit_id": id, "vital_state": vital, "health_points": 0 if vital != "fit" else 100, "was_downed": vital != "fit", "near_ship": false, "aboard": false}
	state.merge(extra, true)
	return state


func _member(id: String, role: String, leadership := 0.0, piloting := 0.0) -> Dictionary:
	return {"unit_id": id, "roster_role_category": role, "skill_values": {"leadership": leadership}, "dropship_piloting": piloting}


func _test_casualty_rules() -> void:
	var rules: Dictionary = CASUALTY.load_rules()
	# Wer beim Absturz gestorben ist, ist tot - auch in einem gewonnenen Einsatz, auch nahe am Schiff und an Bord.
	var dead_won: Dictionary = CASUALTY.classify_unit(_ts("a", "down", {"killed_in_crash": true, "near_ship": true, "aboard": true}), "won")
	_check(dead_won.outcome == "dead", "beim Absturz gestorben: tot, obwohl 'won', nahe am Schiff und an Bord (%s)" % str(dead_won))
	var alive_won: Dictionary = CASUALTY.classify_unit(_ts("a", "down", {"near_ship": true, "aboard": true}), "won")
	_check(alive_won.outcome == "wounded", "unveraendert: ohne das Merkmal rettet 'nahe am Schiff' (wounded)")
	var roster: Array = [_member("lead", "operator", 0.6), _member("pilot", "pilot", 0.0, 0.7), _member("two", "operator", 0.4)]
	var crash_pilot: Dictionary = {"killed_in_crash": true, "crashed_aboard": true}
	var dead_pilot: Dictionary = CASUALTY.resolve_mission([_ts("lead", "fit"), _ts("two", "fit"), _ts("pilot", "down", crash_pilot)], "won", roster, "pilot", rules, {"respawn_limit": 3})
	_check(not bool(dead_pilot.total_loss) and Array(dead_pilot.respawn_unit_ids) == ["pilot"], "toter Pilot (Absturz) allein ist kein Totalverlust; Respawn-Regeln gelten (%s)" % str(dead_pilot.get("total_loss_reason")))
	var respawn_entry: Dictionary = {}
	for entry in dead_pilot.casualties:
		if entry.unit_id == "pilot": respawn_entry = entry
	_check(String(respawn_entry.get("outcome", "")) == "dead" and String(Dictionary(respawn_entry.get("respawn_state", {})).get("source", "")) == "crash", "Respawn-Quelle 'crash' fuer den beim Absturz Gestorbenen")
	var lying_pilot: Dictionary = CASUALTY.resolve_mission([_ts("lead", "fit"), _ts("two", "fit"), _ts("pilot", "down", {"crashed_aboard": true})], "won", roster, "pilot", rules, {"respawn_limit": 3})
	_check(not bool(lying_pilot.total_loss), "am Boden liegender Pilot (Absturz) allein ist kein Totalverlust")
	var plain_down: Dictionary = CASUALTY.resolve_mission([_ts("lead", "fit"), _ts("two", "fit"), _ts("pilot", "down")], "won", roster, "pilot", rules, {"respawn_limit": 3})
	_check(bool(plain_down.total_loss) and plain_down.total_loss_reason == "pilot_down", "unveraendert: ein anderweitig ausgefallener Pilot bleibt pilot_down")
	var all_down: Dictionary = CASUALTY.resolve_mission([_ts("lead", "down"), _ts("two", "down"), _ts("pilot", "down", crash_pilot)], "won", roster, "pilot", rules, {"respawn_limit": 3})
	_check(bool(all_down.total_loss) and all_down.total_loss_reason == "ground_team_down", "sind alle eigenen Personen tot oder am Boden, gilt die vorhandene Niederlage-Regel (ground_team_down)")
