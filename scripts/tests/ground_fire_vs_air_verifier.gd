extends SceneTree
## LC6: Bodentruppen beschiessen das eigene Schiff in der Luft. Nur Raketenwerfer und Schienenkanone wirken
## gegen Schiffe (Entscheidung des Auftraggebers 22.11.2026); alle anderen Waffen haelt der Schild ab.
## Teil 1: der Baustein scripts/combat/ground_fire_vs_air.gd mit Attrappen (Zahlen, Takt, Meldungen).
## Teil 2: echter Driver, echte SimulationRoot, echtes Hex-Gelaende (Sicht, Boden-vor, Zufallsstrom, Mehrspieler leer).
## Teil 3: die Rumpfsperre in der SimulationRoot und der echte Wachmann von outpost_recovery.
## Nur ueber den isolierten Testlauf (Wegwerfprofil) starten.

const SIM = preload("res://scripts/core/simulation_root.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
const GFA = preload("res://scripts/combat/ground_fire_vs_air.gd")
const RESOLVER = preload("res://scripts/combat/air_asset_threat_resolver.gd")
const WEAPONS = preload("res://scripts/core/weapon_data.gd")
const COMBAT_RESOLVER = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const RNG = preload("res://scripts/core/gameplay_rng_state.gd")
const SETUP_SCRIPT = preload("res://scripts/tests/mission_test_setup.gd")
const DATA_SCRIPT = preload("res://scripts/mission/mission_scenario_data.gd")
const TEST_UNIT_SCRIPT = preload("res://scripts/npc/test_unit.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

const SCENARIO_GUARD := "res://data/mission_scenarios/outpost_recovery.json"
const EPS := 0.0001

var passed := 0
var failed := 0


class NPC extends Node2D:
	var unit_id: String
	var team_id: String
	var active_weapon_id := "pistol"
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team_id
	func get_fireteam_id() -> String: return team_id + "_ft"
	func get_vital_state() -> String: return "fit"
	func get_health() -> int: return 100
	func get_awareness() -> float: return 1.0
	func get_active_weapon_id() -> String: return active_weapon_id
	func get_current_unit_command(): return null
	func get_stealth() -> float: return 0.0
	func get_discipline() -> float: return 0.0
	func get_fire_status() -> String: return "fire_at_will"
	func show_event_text(_text: String, _color: Color, _duration: float) -> void: pass


class QuietDriver extends DRIVER:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)


## SimulationRoot ohne Flottenbesitzer: dieselben Luft-Eintraege, aber die Ziele kommen aus der Liste.
class AirSim extends SIM:
	var fake_targets: Array = []
	var ceased: Array = []
	func get_air_support_threat_targets() -> Array:
		var result: Array = []
		var terrain: Node = _air_ground_registry()
		for entry in fake_targets:
			var item: Dictionary = Dictionary(entry).duplicate(true)
			item["position"] = terrain.grid_to_world(item.cell)
			item["status"] = get_air_asset_status_snapshot(String(item.craft_id))
			result.append(item)
		return result
	func request_air_support_cease_fire(craft_id: String, _request_id: String) -> Dictionary:
		ceased.append(craft_id)
		return {"ok": true}


class Roller extends RefCounted:
	var values: Array = []
	var used := 0
	func next() -> float:
		var value: float = float(values[mini(used, values.size() - 1)]) if not values.is_empty() else 0.5
		used += 1
		return value


## Attrappe fuer Teil 1: {id, weapon, fit, contact, visible, range}
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


func _near(a: float, b: float) -> bool:
	return absf(a - b) <= EPS


func _run() -> void:
	_test_resolver_numbers_and_takt()
	_test_other_weapons_never_shoot()
	_test_sight_range_landed_and_lock()
	_test_ground_target_goes_first_module()
	_test_pilot_evasion()
	_test_hull_floor()
	_test_break_off_and_messages()
	_test_driver_real_rig()
	_test_hull_gate_in_root()
	_test_real_outpost_guard()
	await process_frame
	print("GROUND_FIRE_VS_AIR passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


# ---------------------------------------------------------------- Teil 1: Baustein

func _unit(id: String, weapon: String, rng_range: float = 6.0) -> Dictionary:
	return {"id": id, "weapon": weapon, "fit": true, "contact": false, "visible": true, "dist": rng_range}


func _target(integrity: int = 100, max_integrity: int = 100, skill: float = 0.5, status_state: String = "intact") -> Dictionary:
	return {"craft_id": "cutlass", "display_name": "Cutlass", "pilot_skill": skill, "position": Vector2(10, 10), "cell": Vector2i.ZERO,
		"status": {"asset_id": "cutlass", "asset_type": "dropship", "state": status_state, "integrity": integrity, "max_integrity": max_integrity}}


func _ctx(tick: int, targets: Array, shooters: Array, roller: Roller) -> Dictionary:
	return {"tick": tick, "targets": targets, "shooters": shooters, "id_of": Callable(self, "_fid"), "weapon_of": Callable(self, "_fweapon"),
		"is_fit": Callable(self, "_ffit"), "has_ground_contact": Callable(self, "_fcontact"), "sees": Callable(self, "_fsees"), "roll": Callable(roller, "next")}


func _texts(result: Dictionary) -> Array:
	var texts: Array = []
	for message in result.messages: texts.append(String(message.text))
	return texts


func _shots(result: Dictionary) -> Array:
	return result.events.filter(func(e): return e.type == "shot")


func _test_resolver_numbers_and_takt() -> void:
	for case in [{"weapon": "rocket_launcher", "ticks": 26, "warning": "Cutlass: Raketenwerfer schaltet auf!", "base": 90},
			{"weapon": "rail_gun", "ticks": 18, "warning": "Cutlass: Schienenkanone zielt!", "base": 70}]:
		var weapon: String = case.weapon
		var ticks: int = case.ticks
		var gfa = GFA.new()
		var roller := Roller.new()
		roller.values = [0.0]
		var shooter := _unit("g1", weapon)
		var warning: Dictionary = gfa.step(_ctx(100, [_target(1000, 1000)], [shooter], roller))
		_check(_texts(warning) == [case.warning], "a %s: erst die Warnung, wortgleich" % weapon)
		_check(_shots(warning).is_empty() and roller.used == 0, "a %s: die Warnung trifft nicht und wuerfelt nicht" % weapon)
		_check(int(warning.updates.cutlass.snapshot.integrity) == 1000, "a %s: die Warnung kostet keinen Rumpf" % weapon)
		var early: Dictionary = gfa.step(_ctx(100 + ticks - 1, [_target(1000, 1000, 0.5, "locked")], [shooter], roller))
		_check(early.events.is_empty(), "a %s: vor Ablauf des Waffentakts (%d) kein Schuss" % [weapon, ticks])
		var shot: Dictionary = gfa.step(_ctx(100 + ticks, [_target(1000, 1000, 0.5, "locked")], [shooter], roller))
		var shots: Array = _shots(shot)
		_check(shots.size() == 1 and roller.used == 1, "a %s: genau ein Schuss im Takt, ein Wurf" % weapon)
		if shots.size() == 1:
			var risk: float = float(shots[0].risk)
			var expected: int = int(round(float(case.base) * lerpf(0.65, 1.25, risk)))
			_check(bool(shots[0].hit) and int(shots[0].damage) == expected, "a %s: Treffer senkt den Rumpf um den Wert des Bausteins (%d)" % [weapon, expected])
			_check(int(shot.updates.cutlass.snapshot.integrity) == 1000 - expected, "a %s: der gebuchte Rumpf stimmt" % weapon)
			_check(_near(float(shots[0].chance), risk * (1.0 - 0.375)), "a %s: Chance = risk x (1 - Ausweichen 0,375)" % weapon)
			_check(_texts(shot) == ["Cutlass wird vom Boden beschossen."], "g %s: Treffermeldung wortgleich, einmal" % weapon)
		roller.values = [0.999]
		var missed: Dictionary = gfa.step(_ctx(100 + 2 * ticks, [_target(1000, 1000, 0.5, "hit")], [shooter], roller))
		_check(_shots(missed).size() == 1 and not bool(_shots(missed)[0].hit) and int(_shots(missed)[0].damage) == 0 and not missed.updates.has("cutlass"), "a %s: Fehlschuss kostet nichts, bucht nichts" % weapon)
		_check(_texts(missed).is_empty(), "g %s: Fehlschuss und zweiter Schuss melden nichts neu" % weapon)


func _test_other_weapons_never_shoot() -> void:
	for weapon in ["pistol", "smg", "rifle", "sniper", "medictool", "none"]:
		var gfa = GFA.new()
		var roller := Roller.new()
		roller.values = [0.0]
		var any_event := false
		for tick in range(0, 400, 5):
			var result: Dictionary = gfa.step(_ctx(tick, [_target()], [_unit("g1", weapon, 2.0)], roller))
			any_event = any_event or not result.events.is_empty() or not result.updates.is_empty() or not result.messages.is_empty()
		_check(not any_event and roller.used == 0, "a2 %s: kein Schuss, keine Meldung, kein Wurf - der Schild haelt ab" % weapon)
		_check(not GFA.weapon_threatens_ships(weapon), "a2 %s: wirkt nicht gegen Schiffe" % weapon)
	_check(GFA.weapon_threatens_ships("rocket_launcher") and GFA.weapon_threatens_ships("rail_gun"), "a2: nur Raketenwerfer und Schienenkanone wirken")


func _test_sight_range_landed_and_lock() -> void:
	var gfa = GFA.new()
	var roller := Roller.new()
	roller.values = [0.0]
	var shooter := _unit("g1", "rocket_launcher", 18.0)
	_check(_texts(gfa.step(_ctx(0, [_target()], [shooter], roller))).size() == 1, "b: genau an der Reichweitengrenze (18 Felder) wird aufgeschaltet")
	var far := _unit("g2", "rocket_launcher", 19.0)
	_check(gfa.step(_ctx(0, [_target()], [far], roller)).events.is_empty(), "b: ausser Reichweite (19 > 18): kein Schuss")
	var far_rail := _unit("g3", "rail_gun", 21.0)
	_check(gfa.step(_ctx(0, [_target()], [far_rail], roller)).events.is_empty(), "b: Schienenkanone 21 > 20: kein Schuss")
	var blind := _unit("g4", "rocket_launcher")
	blind.visible = false
	_check(gfa.step(_ctx(0, [_target()], [blind], roller)).events.is_empty(), "b: ohne Sichtlinie kein Schuss")
	_check(GFA.new().step(_ctx(0, [], [_unit("g5", "rocket_launcher")], roller)).events.is_empty(), "b: Schiff nicht in der Luft (gelandet / Anflugfolge: keine Ziele): kein Schuss")
	var down := _unit("g6", "rocket_launcher")
	down.fit = false
	_check(gfa.step(_ctx(0, [_target()], [down], roller)).events.is_empty(), "b: nicht kampffaehig: kein Schuss")
	# einmal je Aufschaltung: Sicht verloren und wieder da -> erneut Warnung
	var gfb = GFA.new()
	var seen := _unit("g7", "rocket_launcher")
	_check(_texts(gfb.step(_ctx(0, [_target()], [seen], roller))).size() == 1, "g: erste Aufschaltung meldet")
	_check(_texts(gfb.step(_ctx(1, [_target(100, 100, 0.5, "locked")], [seen], roller))).is_empty(), "g: dieselbe Aufschaltung meldet nicht noch einmal")
	seen.visible = false
	gfb.step(_ctx(2, [_target(100, 100, 0.5, "locked")], [seen], roller))
	seen.visible = true
	_check(_texts(gfb.step(_ctx(40, [_target(100, 100, 0.5, "locked")], [seen], roller))) == ["Cutlass: Raketenwerfer schaltet auf!"], "g: neue Aufschaltung nach verlorener Sicht meldet wieder")


func _test_ground_target_goes_first_module() -> void:
	var gfa = GFA.new()
	var roller := Roller.new()
	var shooter := _unit("g1", "rocket_launcher")
	shooter.contact = true
	var silent := true
	for tick in range(0, 60):
		var result: Dictionary = gfa.step(_ctx(tick, [_target()], [shooter], roller))
		silent = silent and result.events.is_empty() and result.messages.is_empty() and result.updates.is_empty()
	_check(silent and roller.used == 0, "c: mit Bodenziel in Kontakt kein Schuss, keine Warnung, kein Wurf aufs Schiff")
	shooter.contact = false
	_check(_texts(gfa.step(_ctx(60, [_target()], [shooter], roller))).size() == 1, "c: ohne Bodenziel schaltet er sofort auf (Takt nicht angetastet)")


func _test_pilot_evasion() -> void:
	_check(_near(GFA.evasion_for(0.0), 0.15) and _near(GFA.evasion_for(1.0), 0.60) and _near(GFA.evasion_for(0.5), 0.375), "d: Ausweichen 0,15 bis 0,60 aus dem Pilotenprofil der Flugabwehr")
	var chances: Dictionary = {}
	for skill in [0.0, 1.0]:
		var gfa = GFA.new()
		var roller := Roller.new()
		roller.values = [0.5]
		var shooter := _unit("g1", "rocket_launcher")
		gfa.step(_ctx(0, [_target(1000, 1000, skill)], [shooter], roller))
		var result: Dictionary = gfa.step(_ctx(26, [_target(1000, 1000, skill, "locked")], [shooter], roller))
		chances[skill] = _shots(result)[0]
	_check(float(chances[1.0].chance) < float(chances[0.0].chance), "d: der gute Pilot wird seltener getroffen als der schwache")
	_check(_near(float(chances[0.0].chance), float(chances[0.0].risk) * 0.85) and _near(float(chances[1.0].chance), float(chances[1.0].risk) * 0.40), "d: Chance = risk x (1 - Ausweichen), ohne weitere Grenze")
	var between: float = (float(chances[0.0].chance) + float(chances[1.0].chance)) * 0.5
	var outcomes: Dictionary = {}
	for skill in [0.0, 1.0]:
		var gfa = GFA.new()
		var roller := Roller.new()
		roller.values = [between]
		var shooter := _unit("g1", "rocket_launcher")
		gfa.step(_ctx(0, [_target(1000, 1000, skill)], [shooter], roller))
		outcomes[skill] = bool(_shots(gfa.step(_ctx(26, [_target(1000, 1000, skill, "locked")], [shooter], roller)))[0].hit)
	_check(outcomes[0.0] and not outcomes[1.0], "d: derselbe Wurf trifft den schwachen, verfehlt den guten Piloten")


func _test_hull_floor() -> void:
	var gfa = GFA.new()
	var roller := Roller.new()
	roller.values = [0.0]
	var shooter := _unit("g1", "rail_gun")
	var status := _target(3, 100, 0.5, "locked")
	gfa.step(_ctx(0, [_target(3, 100)], [shooter], roller))
	var lowest := 100
	var hits := 0
	var tick := 18
	for i in range(6):
		var result: Dictionary = gfa.step(_ctx(tick, [status], [shooter], roller))
		for shot in _shots(result):
			if shot.hit:
				hits += 1
				lowest = mini(lowest, int(shot.integrity_after))
		if result.updates.has("cutlass"): status.status = result.updates.cutlass.snapshot
		tick += 18
	_check(hits >= 3 and lowest == 1 and int(status.status.integrity) == 1, "e: Rumpf faellt durch Bodenbeschuss nie unter 1 %% (Treffer %d, tiefster Stand %d)" % [hits, lowest])
	_check(String(status.status.state) != "crashed" and String(status.status.state) != "destroyed", "e: kein Abschuss in LC6")


func _test_break_off_and_messages() -> void:
	_check(GFA.is_broken_off({"integrity": 35, "max_integrity": 100}) and not GFA.is_broken_off({"integrity": 36, "max_integrity": 100}), "f: Grenze 35 % auf oder darunter")
	_check(GFA.is_broken_off({"integrity": 70, "max_integrity": 200}) and not GFA.is_broken_off({}), "f: Verhaeltnis zaehlt, leerer Stand ist nicht abgedreht")
	var gfa = GFA.new()
	var roller := Roller.new()
	roller.values = [0.0]
	var shooter := _unit("g1", "rocket_launcher")
	gfa.step(_ctx(0, [_target()], [shooter], roller))
	var hit: Dictionary = gfa.step(_ctx(26, [_target(100, 100, 0.5, "locked")], [shooter], roller))
	_check(_texts(hit) == ["Cutlass wird vom Boden beschossen.", "Cutlass schwer beschädigt – dreht ab. Rumpf 1 %."], "f/g: beide Meldungen wortgleich")
	_check(hit.cease == ["cutlass"], "f: Feuerstopp wird angefordert")
	var again: Dictionary = gfa.step(_ctx(52, [_target(1, 100, 0.5, "damaged")], [shooter], roller))
	_check(_texts(again).is_empty() and again.cease == ["cutlass"], "g: Meldungen je Ereignis nur einmal; Feuerstopp bleibt ausstehend, bis er gelingt")
	gfa.mark_cease_done("cutlass")
	_check(gfa.step(_ctx(78, [_target(1, 100, 0.5, "damaged")], [shooter], roller)).cease.is_empty(), "f: nach gelungenem Feuerstopp nichts mehr ausstehend")
	gfa.step(_ctx(80, [], [shooter], roller))
	gfa.step(_ctx(120, [_target()], [shooter], roller))
	var second_flight: Dictionary = gfa.step(_ctx(146, [_target(100, 100, 0.5, "locked")], [shooter], roller))
	_check(_texts(second_flight).has("Cutlass wird vom Boden beschossen."), "g: ein neuer Flug meldet seinen ersten Treffer erneut")


# ---------------------------------------------------------------- Teil 2: echter Driver, echte SimulationRoot

## enemy_weapon: Waffe des Gegners bei (0,0), Blick nach DIRECTIONS[0]. own_dir >= 0: ein eigener Soldat (ohne Waffe)
## im Abstand 5 auf dieser Richtung (Bodenziel in Kontakt, wenn er vor dem Gegner steht).
func _fixture(enemy_weapon: String, own_dir: int, airborne: bool) -> Dictionary:
	var scope := Node.new()
	scope.name = "GroundFireFixture"
	root.add_child(scope)
	var terrain = TERRAIN.new()
	terrain.name = "TerrainRegistry"
	scope.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, "hex_axial_v1")
	var grids: Dictionary = {Vector2i.ZERO: true}
	for axis in HEX.DIRECTIONS:
		for step in range(1, 11): grids[axis * step] = true
	for grid in grids:
		terrain.register_tile(TILE.new({"tile_id": str(grid), "grid_position": grid,
			"world_position": terrain.grid_to_world(grid), "explicit_hex_ramps": true}))
	var registry = UNITS.new()
	registry.name = "UnitRegistry"
	scope.add_child(registry)
	var sim = AirSim.new() if airborne else SIM.new()
	sim.name = "SimulationRoot"
	sim.unit_registry_path = NodePath("../UnitRegistry")
	sim.terrain_registry_path = NodePath("../TerrainRegistry")
	scope.add_child(sim)
	sim.set_physics_process(false)
	sim.set_process(false)
	var map = MAP.create_empty("ground_fire_vs_air", Vector2i(21, 21), Vector2.ZERO, 64, 32, 3, "hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	map._extension_metadata["terrain_height_rules"] = "explicit_hex_ramps_v1"
	_check(bool(sim.configure_hex_ground_runtime(map, terrain).get("ok", false)), "Aufbau: echter Ground-Besitzer eingerichtet")
	var cache = CACHE.new()
	cache.name = "VisibilityCache"
	scope.add_child(cache)
	cache.begin_tick(1)
	var driver := QuietDriver.new()
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "blue"
	driver.contact_range = 1000.0
	driver.simulation_root_path = NodePath("../SimulationRoot")
	driver.terrain_registry_path = NodePath("../TerrainRegistry")
	driver.combat_visibility_cache_path = NodePath("../VisibilityCache")
	scope.add_child(driver)
	var enemy := NPC.new()
	enemy.name = "Enemy"
	enemy.unit_id = "enemy"
	enemy.team_id = "red"
	enemy.active_weapon_id = enemy_weapon
	enemy.position = terrain.grid_to_world(Vector2i.ZERO)
	scope.add_child(enemy)
	var placements: Array[Dictionary] = [{"unit_id": "enemy", "grid": Vector2i.ZERO, "facing_dir": 0}]
	var own: NPC = null
	if own_dir >= 0:
		own = NPC.new()
		own.name = "Own"
		own.unit_id = "own"
		own.team_id = "blue"
		own.active_weapon_id = "none"
		own.position = terrain.grid_to_world(HEX.DIRECTIONS[own_dir] * 5)
		scope.add_child(own)
		placements.append({"unit_id": "own", "grid": HEX.DIRECTIONS[own_dir] * 5, "facing_dir": (own_dir + 3) % 6})
	var units: Array = [enemy] if own == null else [own, enemy]
	for unit in units:
		registry.register_unit(unit.unit_id, unit)
		sim.register_known_unit(unit.unit_id, unit)
	driver.enemy_unit_paths.assign([NodePath("../Enemy")])
	driver.friendly_unit_paths.assign([] if own == null else [NodePath("../Own")])
	_check(bool(sim.admit_hex_ground_units(placements).get("ok", false)), "Aufbau: echte Aufnahme der Einheiten")
	return {"scope": scope, "terrain": terrain, "sim": sim, "cache": cache, "driver": driver, "enemy": enemy, "own": own}


func _tick(f: Dictionary) -> Dictionary:
	f.sim._physics_process(0.1)
	f.cache.begin_tick(f.sim.tick_counter)
	f.driver._current_tick = f.sim.tick_counter
	f.driver._advance_detection_timers()
	f.driver._advance_ground_fire_vs_air(f.sim)
	var module = f.driver._ground_fire_vs_air
	return module.last_result if module != null else {}


func _set_air_stream(f: Dictionary, value: int) -> void:
	var state: Dictionary = f.sim.export_gameplay_rng_state()
	state["air_ground"] = value
	RNG.publish(f.sim, state)


func _first_roll(state: int) -> float:
	return float((state * 1103515245 + 12345) & 0x7fffffff) / 2147483648.0


## Ein Stand des Stroms, dessen erster Wurf kleiner als `limit` ist (trifft sicher: kleinste Chance ist ueber 0,3).
func _stream_with_first_roll_below(limit: float) -> int:
	for candidate in range(1, 5000):
		if _first_roll(candidate) < limit: return candidate
	return 1


func _ship(f: Dictionary, direction: int, steps: int, skill: float = 0.5) -> void:
	f.sim.fake_targets = [{"craft_id": "cutlass", "cell": HEX.DIRECTIONS[direction] * steps, "pilot_skill": skill}]


## Laeuft ticks Takte und sammelt, was der Baustein je Takt gemeldet hat.
func _run_ticks(f: Dictionary, ticks: int) -> Array:
	var log: Array = []
	for i in range(ticks):
		var result: Dictionary = _tick(f)
		for event in Array(result.get("events", [])): log.append(event.duplicate())
		for message in Array(result.get("messages", [])): log.append({"type": "message", "text": message.text, "tick": f.sim.tick_counter})
	return log


func _kinds(log: Array, kind: String) -> Array:
	return log.filter(func(e): return e.type == kind)


func _test_driver_real_rig() -> void:
	# a (echt): Raketenwerfer-Gegner, Schiff vor ihm in 6 Feldern, kein Bodenziel. Strom: erster Wurf trifft sicher.
	var f := _fixture("rocket_launcher", -1, true)
	_ship(f, 0, 6)
	var hit_state := _stream_with_first_roll_below(0.2)
	_set_air_stream(f, hit_state)
	var log := _run_ticks(f, 80)
	var warnings := _kinds(log, "warning")
	var shots := _kinds(log, "shot")
	_check(warnings.size() == 1 and shots.size() >= 1, "a (Driver): erst eine Warnung, dann Schuesse (%d / %d)" % [warnings.size(), shots.size()])
	if shots.size() >= 1 and warnings.size() == 1:
		_check(int(shots[0].tick) - int(warnings[0].tick) == 26, "a (Driver): erster Schuss genau einen Raketenwerfer-Takt (26) nach der Warnung")
	for i in range(1, shots.size()):
		_check(int(shots[i].tick) - int(shots[i - 1].tick) == 26, "a (Driver): Schuesse im Takt der Waffe (%d)" % i)
	var status: Dictionary = f.sim.get_air_asset_status_snapshot("cutlass")
	_check(not status.is_empty() and int(status.integrity) == 1 and int(status.integrity) >= 1, "a/e (Driver): Treffer gebucht ueber den Status-Effekt, Rumpf auf 1 %%, nie darunter (%s)" % [str(status.get("integrity", "-"))])
	_check(String(status.get("state", "")) == "damaged", "a (Driver): Zustand beschaedigt")
	var texts: Array = _kinds(log, "message").map(func(e): return e.text)
	# Ohne Controller (Aufbau) heisst das Schiff nach seiner Kennung; im Spiel kommt der Name von der Schiffskarte.
	_check(texts == ["cutlass: Raketenwerfer schaltet auf!", "cutlass wird vom Boden beschossen.", "cutlass schwer beschädigt – dreht ab. Rumpf 1 %."], "g (Driver): Meldungen wortgleich, je einmal (%s)" % str(texts))
	_check(f.sim.ceased == ["cutlass"], "f (Driver): Feuerstopp genau einmal angefordert und gelungen")
	# Der Sichtbogen des Gegners gilt nicht: Schiff HINTER ihm.
	f.scope.free()
	f = _fixture("rocket_launcher", -1, true)
	_ship(f, 3, 6)
	_set_air_stream(f, hit_state)
	log = _run_ticks(f, 40)
	_check(_kinds(log, "warning").size() == 1, "a (Driver): Schiff hinter dem Gegner (ausserhalb seines Sichtbogens) wird trotzdem aufgeschaltet")
	# b: Sichtblocker zwischen Gegner und Schiff
	f.scope.free()
	f = _fixture("rocket_launcher", -1, true)
	_ship(f, 0, 6)
	f.terrain.set_runtime_tile_overrides([{"grid_position": HEX.DIRECTIONS[0] * 3, "blocks_los_override": true, "object_height_override": 4}])
	log = _run_ticks(f, 60)
	_check(log.is_empty(), "b (Driver): Sichtblocker zwischen Gegner und Schiff - kein Schuss, keine Warnung")
	f.terrain.clear_runtime_tile_overrides()
	log = _run_ticks(f, 3)
	_check(_kinds(log, "warning").size() == 1, "b (Driver): ohne Blocker schaltet er auf")
	# b: gelandet / Anflugfolge: die SimulationRoot meldet nur Schiffe der Sortie; ohne Sortie leer
	f.sim.fake_targets = []
	log = _run_ticks(f, 60)
	_check(log.is_empty(), "b (Driver): ohne Schiff in der Luft kein Schuss")
	f.scope.free()
	# a2 (echt): Pistole / Gewehr / Maschinenpistole mit Schiff in der Luft
	for weapon in ["pistol", "smg", "rifle"]:
		f = _fixture(weapon, -1, true)
		_ship(f, 0, 3)
		var before_state: Dictionary = f.sim.export_gameplay_rng_state()
		log = _run_ticks(f, 120)
		_check(log.is_empty() and f.sim.get_air_asset_status_snapshot("cutlass").is_empty() and f.sim.export_gameplay_rng_state() == before_state, "a2 (Driver) %s: kein Schuss, Rumpf unveraendert, Zufallsstrom unberuehrt" % weapon)
		f.scope.free()
	# c: Boden vor + Ablauf des Bodengefechts mit und ohne Schiff identisch
	var without_ship := _ground_sequence(false)
	var with_ship := _ground_sequence(true)
	_check(not without_ship.shots.is_empty(), "c (Driver): Bodengefecht schiesst (Gegner mit Raketenwerfer gegen den Soldaten)")
	_check(without_ship.shots == with_ship.shots and without_ship.next_attack == with_ship.next_attack, "c (Driver): Schussfolge und Schussplatz mit und ohne Schiff in der Luft identisch")
	_check(with_ship.air_events == 0, "c (Driver): der Gegner mit Bodenziel schiesst nicht aufs Schiff (Ereignisse %d)" % int(with_ship.air_events))
	# h: gleicher Ablauf zweimal -> gleiche Folge, Strom im Spielstand
	var run_a := _determinism_run()
	var run_b := _determinism_run()
	_check(run_a.log == run_b.log and run_a.state == run_b.state and not run_a.log.is_empty(), "h: gleicher Ablauf zweimal, gleiche Schuss- und Trefferfolge und gleicher Strom (%d Ereignisse)" % run_a.log.size())
	_check(int(run_a.state.air_ground) != int(run_a.start.air_ground) and RNG.validate(run_a.state), "h: der Strom des Luft-Boden-Feuers hat gewuerfelt und steht gueltig im Spielstand")
	# Anschluss: der echte Tick-Weg des Drivers (Signal tick_processed) ruft den Baustein auf.
	f = _fixture("rocket_launcher", -1, true)
	_ship(f, 0, 6)
	_set_air_stream(f, hit_state)
	f.sim.tick_processed.connect(f.driver._on_tick_processed)
	var seen_warning := false
	for i in range(40):
		f.sim._physics_process(0.1)
		f.cache.begin_tick(f.sim.tick_counter)
		var module = f.driver._ground_fire_vs_air
		if module != null and not Array(module.last_result.get("events", [])).is_empty(): seen_warning = true
	_check(seen_warning and int(f.sim.get_air_asset_status_snapshot("cutlass").get("integrity", 100)) == 1, "Anschluss: der echte Tick-Weg des Drivers (tick_processed) schiesst: Ereignisse gemeldet, Rumpf gebucht")
	f.scope.free()
	# i: Skirmish / Mehrspieler (keine Luftunterstuetzung): nichts feuert, nichts wird gewuerfelt
	f = _fixture("rocket_launcher", -1, false)
	var start: Dictionary = f.sim.export_gameplay_rng_state()
	log = _run_ticks(f, 120)
	var air_effects := 0
	for effect in f.sim.effects_queue:
		if String(Dictionary(effect).get("effect_type", "")) == "air_asset_status_update": air_effects += 1
	_check(f.sim.get_air_support_threat_targets().is_empty() and log.is_empty() and air_effects == 0 and f.sim.export_gameplay_rng_state() == start, "i: ohne Luftunterstuetzung (Skirmish/Mehrspieler) keine Ziele, kein Schuss, kein Wurf")
	f.scope.free()


func _ground_sequence(with_ship: bool) -> Dictionary:
	var f := _fixture("rocket_launcher", 0, with_ship)
	if with_ship: _ship(f, 3, 6)
	var shots: Array = []
	var air_events := 0
	for i in range(120):
		f.sim._physics_process(0.1)
		f.cache.begin_tick(f.sim.tick_counter)
		f.driver._current_tick = f.sim.tick_counter
		f.driver._advance_detection_timers()
		f.driver._try_enqueue_attacks(f.sim)
		for effect in f.sim.effects_queue:
			var e: Dictionary = effect
			if String(e.get("effect_type", "")) == "damage": shots.append([f.sim.tick_counter, String(e.get("attacker_unit_id", "")), String(e.get("unit_id", ""))])
		f.driver._advance_ground_fire_vs_air(f.sim)
		var module = f.driver._ground_fire_vs_air
		if module != null: air_events += Array(module.last_result.get("events", [])).size() + Array(module.last_result.get("messages", [])).size()
		f.sim.effects_queue.clear()
	var result := {"shots": shots, "next_attack": int(f.driver._next_attack_tick), "air_events": air_events}
	f.scope.free()
	return result


func _determinism_run() -> Dictionary:
	var f := _fixture("rail_gun", -1, true)
	_ship(f, 0, 7, 0.0)
	_set_air_stream(f, 12345)
	var start: Dictionary = f.sim.export_gameplay_rng_state()
	var log: Array = []
	for event in _run_ticks(f, 200):
		var e: Dictionary = event
		log.append([String(e.type), int(e.get("tick", 0)), String(e.get("attacker_id", "")), bool(e.get("hit", false)), snappedf(float(e.get("roll", 0.0)), 0.000001), int(e.get("damage", 0))])
	var state: Dictionary = f.sim.export_gameplay_rng_state()
	f.scope.free()
	return {"log": log, "state": state, "start": start}


# ---------------------------------------------------------------- Teil 3: Rumpfsperre in der Root, echter Wachmann

func _hull_effect(integrity: int) -> Dictionary:
	return {"effect_type": "air_asset_status_update", "asset_id": "cutlass", "asset_type": "dropship", "state": "damaged",
		"status_snapshot": {"asset_id": "cutlass", "asset_type": "dropship", "state": "damaged", "integrity": integrity, "max_integrity": 100}, "priority": 80}


func _test_hull_gate_in_root() -> void:
	var f := _fixture("pistol", -1, false)
	var sim = f.sim
	sim.enqueue_effect(_hull_effect(30))
	sim._physics_process(0.1)
	_check(int(sim.get_air_asset_status_snapshot("cutlass").get("integrity", -1)) == 30, "f (Root): Rumpf 30 % ueber den Status-Effekt gebucht")
	var order: Dictionary = sim.request_air_support_attack_order({"craft_id": "cutlass", "target_unit_id": "enemy", "request_id": "r1"})
	_check(not bool(order.get("ok", true)) and order.get("message") == "Schiff schwer beschädigt: kein Angriff mehr möglich." and order.get("reason") == "hull_too_damaged", "f (Root): neuer Angriffsbefehl abgelehnt, Satz wortgleich")
	var preview: Dictionary = sim.preview_air_support_ground_fire({"craft_id": "cutlass", "target_unit_id": "enemy", "weapon_slot": "w1"})
	var fire: Dictionary = sim.request_air_support_ground_fire({"craft_id": "cutlass", "target_unit_id": "enemy", "weapon_slot": "w1", "request_id": "r2"})
	_check(preview.get("reason") == "hull_too_damaged" and fire.get("reason") == "hull_too_damaged" and fire.get("message") == "Schiff schwer beschädigt: kein Angriff mehr möglich.", "f (Root): Bodenfeuer abgelehnt (Vorschau und Feuer)")
	sim.enqueue_effect(_hull_effect(35))
	sim._physics_process(0.1)
	_check(sim.request_air_support_attack_order({"craft_id": "cutlass", "target_unit_id": "enemy", "request_id": "r3"}).get("reason") == "hull_too_damaged", "f (Root): bei genau 35 % gilt die Sperre (auf oder darunter)")
	sim.enqueue_effect(_hull_effect(36))
	sim._physics_process(0.1)
	_check(sim.request_air_support_attack_order({"craft_id": "cutlass", "target_unit_id": "enemy", "request_id": "r4"}).get("reason") == "air_source_unavailable", "f (Root): bei 36 % keine Sperre, der Befehl geht an den normalen Weg")
	_check(sim.request_air_support_landing("cutlass").get("reason") != "hull_too_damaged" and sim.request_air_support_move({"craft_id": "cutlass", "target_hex": Vector2i.ZERO, "request_id": "m1"}).get("reason") != "hull_too_damaged", "f (Root): Fliegen und Landen haben keine Rumpfsperre")
	f.scope.free()


func _test_real_outpost_guard() -> void:
	var holder := Node.new()
	root.add_child(holder)
	var setup = SETUP_SCRIPT.new()
	setup.set("_mission_scenario", DATA_SCRIPT.load_from_file(SCENARIO_GUARD))
	var unit: Node = TEST_UNIT_SCRIPT.new()
	unit.set("unit_id", "outpost_recovery_guard_01")
	unit.set("team_id", "team_bravo")
	holder.add_child(unit)
	unit.call("apply_identity_config", {"skill_accuracy": 0.4})
	setup.call("_apply_authored_enemy_loadout", unit, "outpost_recovery_guard_01", "team_bravo")
	setup.free()
	var weapon := String(COMBAT_RESOLVER.get_unit_active_weapon_id(unit))
	_check(weapon == "pistol", "j: der echte Wachmann aus dem Auftrag 2 traegt die Pistole (%s)" % weapon)
	var gfa = GFA.new()
	var roller := Roller.new()
	roller.values = [0.0]
	var silent := true
	for tick in range(0, 300, 3):
		var ctx := {"tick": tick, "targets": [_target()], "shooters": [unit], "id_of": Callable(self, "_real_id"), "weapon_of": Callable(self, "_real_weapon"),
			"is_fit": Callable(self, "_real_fit"), "has_ground_contact": Callable(self, "_fcontact_false"), "sees": Callable(self, "_fsees_close"), "roll": Callable(roller, "next")}
		var result: Dictionary = gfa.step(ctx)
		silent = silent and result.events.is_empty() and result.updates.is_empty() and result.messages.is_empty()
	_check(silent and roller.used == 0, "j: der Wachmann (Pistole) steht ueber dem Schiff in Sicht und Reichweite und schiesst NICHT - Rumpf bleibt 100 %")
	holder.free()


func _real_id(unit) -> String: return String(unit.call("get_unit_id"))
func _real_weapon(unit) -> String: return String(COMBAT_RESOLVER.get_unit_active_weapon_id(unit))
func _real_fit(unit) -> bool: return bool(COMBAT_RESOLVER.can_enemy_attack(unit))
func _fcontact_false(_unit) -> bool: return false
func _fsees_close(_unit, _target) -> Dictionary: return {"visible": true, "range_tiles": 1.0}
