extends SceneTree
## FT-0b: Unterdrueckung im Gefecht, beide Seiten gleich, drei Stufen, nach Spielzeit (Ticks).
## T1 Zustandsklasse, T2 Zeit, T3 beide Seiten, T4 Feuer, T5 Bewegung, T6 Plan, T7 Abklingen, T8 Treffer und Deckung.
## Rechnet gegen die echten Klassen (Tracker, Rechenregeln, Treiber, SimulationRoot, Taktik-Controller).
## Schlusszeile: suppression_combat_verifier passed=N failed=M

const MATH = preload("res://scripts/tactical/suppression_math.gd")
const CADENCE = preload("res://scripts/combat/combat_cadence.gd")
const SIM = preload("res://scripts/core/simulation_root.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const COMMAND = preload("res://scripts/npc/unit_command.gd")
const TRACKER_PATH := "res://scripts/tactical/suppression_tracker.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENE_PATH := "res://scenes/tests/mission_reactivity_test.tscn"

const CENTER := Vector2i(20, 20)
var passed := 0
var failed := 0
var _math: GDScript = MATH


class RS extends RefCounted:
	var status := "idle"
	var active_command_type := ""
	var priority := 0
	var fire_status := "fire_at_will"
	var source_command_type := ""
	var move_speed_factor := 1.0
	var cover_score := 0.0
	var attack_bonus := 0.0
	var phase := -1
	var target_position = null
	var movement_posture := ""
	var weapon_posture := ""
	var posture_policy_id := ""
	var sight_range_factor := 1.0
	var aim_readiness_percent := 0.0


class NPC extends Node2D:
	var unit_id: String
	var team_id: String
	var active_weapon_id := "pistol"
	var hp := 100000
	var initiative := -1.0
	var hit_multiplier := -1.0
	var command: RefCounted
	var leadership := 0.5
	var stability := 0.5
	var traits := PackedStringArray()
	var rs := RS.new()
	var awareness := 1.0
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team_id
	func get_fireteam_id() -> String: return team_id + "_ft"
	func get_vital_state() -> String: return "fit" if hp > 0 else "down"
	func get_health() -> int: return hp
	func get_awareness() -> float: return awareness
	func get_active_weapon_id() -> String: return active_weapon_id
	func get_current_unit_command(): return command
	func get_stealth() -> float: return 0.0
	func get_discipline() -> float: return 0.0
	func get_fire_status() -> String: return String(command.get("fire_status")) if command != null else rs.fire_status
	func get_leadership_skill() -> float: return leadership
	func get_trait_ids() -> PackedStringArray: return traits
	func get_runtime_status(): return rs
	func get_attack_bonus() -> float: return rs.attack_bonus
	func get_cover_score() -> float: return rs.cover_score
	func get_move_speed_factor() -> float: return rs.move_speed_factor
	func set_runtime_status(status: String, active_command_type: String, priority: int, fire_status: String, source_command_type: String, move_speed_factor: float, cover_score: float, attack_bonus: float, phase: int, target_position, movement_posture: String, weapon_posture: String, posture_policy_id: String, sight_range_factor: float, aim_readiness_percent: float) -> void:
		rs.status = status
		rs.active_command_type = active_command_type
		rs.priority = priority
		rs.fire_status = fire_status
		rs.source_command_type = source_command_type
		rs.move_speed_factor = move_speed_factor
		rs.cover_score = cover_score
		rs.attack_bonus = attack_bonus
		rs.phase = phase
		rs.target_position = target_position
		rs.movement_posture = movement_posture
		rs.weapon_posture = weapon_posture
		rs.posture_policy_id = posture_policy_id
		rs.sight_range_factor = sight_range_factor
		rs.aim_readiness_percent = aim_readiness_percent
	func show_event_text(_text: String, _color: Color, _duration: float) -> void: pass
	func get_character_profile_bundle() -> Dictionary:
		var axes := {"contact_stability": stability}
		if initiative >= 0.0:
			axes["initiative"] = initiative
		return {"behavior_axes": axes}
	func get_combat_hit_chance_multiplier() -> float:
		return hit_multiplier if hit_multiplier >= 0.0 else 1.0
	func apply_damage(amount: int, _context: Dictionary = {}) -> bool:
		hp -= amount
		return true


## Ohne eigene Verarbeitung; der Test treibt Ticks selbst.
class QuietDriver extends DRIVER:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
		var simulation_root = get_node_or_null(simulation_root_path)
		if simulation_root != null:
			simulation_root.damage_effect_resolved.connect(_on_damage_effect_resolved)
			if has_method("register_suppression_movement_provider"):
				call("register_suppression_movement_provider", simulation_root)

	func _try_enqueue_overwatch(_simulation_root: Node) -> Array:
		return []


func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", label)


func _has(obj, method: String) -> bool:
	return obj != null and obj.has_method(method)


## Aufruf, der bei fehlender Methode sauber als Fehlschlag zaehlt statt abzubrechen.
func _call(obj, method: String, args: Array = [], default = null):
	if not _has(obj, method):
		_check(false, "Methode fehlt: %s" % method)
		return default
	return obj.callv(method, args)


func _run() -> void:
	CADENCE.reset_config()
	_test_t1_tracker()
	_test_t2_time()
	_test_t3_both_sides()
	CADENCE.override_config_for_test({"cadence_scale": 1.0, "reaction_initiative_ticks": 20})
	_test_t4_fire()
	CADENCE.reset_config()
	_test_t5_movement()
	_test_t12_advance_margin()
	_test_t13_level3_parity()
	_test_t7_decay()
	_test_t8_hit_and_cover()
	_test_t9_read_time_modifiers()
	await _test_t6_plan()
	await _test_t10_planning_sync()
	await _test_t14_after_combat_end()
	CADENCE.reset_config()
	await process_frame
	print("suppression_combat_verifier passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


# ---- Hilfen -------------------------------------------------------------------

func _terrain_patch(radius: int) -> Node:
	var terrain = TERRAIN.new()
	terrain.name = "TerrainRegistry"
	terrain.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, "hex_axial_v1")
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var grid := CENTER + Vector2i(dx, dy)
			terrain.register_tile(TILE.new({"tile_id": str(grid), "grid_position": grid,
				"world_position": terrain.grid_to_world(grid), "explicit_hex_ramps": true}))
	return terrain


## spec: {id, team, grid, facing, weapon, hp, initiative, hit_multiplier, leadership, stability, traits, fire_rule}.
func _rig(specs: Array, seed_value: int = 7) -> Dictionary:
	var scope := Node.new()
	scope.name = "SuppressionFixture"
	root.add_child(scope)
	var terrain := _terrain_patch(8)
	scope.add_child(terrain)
	var registry = UNITS.new()
	registry.name = "UnitRegistry"
	scope.add_child(registry)
	var sim = SIM.new()
	sim.name = "SimulationRoot"
	sim.unit_registry_path = NodePath("../UnitRegistry")
	sim.terrain_registry_path = NodePath("../TerrainRegistry")
	scope.add_child(sim)
	sim.set_physics_process(false)
	sim.set_process(false)
	sim.set_combat_rng_seed(seed_value)
	var map = MAP.create_empty("suppression_fixture", Vector2i(160, 80), Vector2.ZERO, 64, 32, 3, "hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	map._extension_metadata["terrain_height_rules"] = "explicit_hex_ramps_v1"
	_check(bool(sim.configure_hex_ground_runtime(map, terrain).get("ok", false)), "Fixture: Bodenlaufzeit konfiguriert")
	var cache = CACHE.new()
	cache.name = "VisibilityCache"
	scope.add_child(cache)
	cache.begin_tick(1)
	var driver := QuietDriver.new()
	driver.ammo_enabled = false  # zaehlt Gelegenheiten und Schuesse ueber viele Schritte; die Munition prueft ammo_combat_verifier
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "blue"
	driver.contact_range = 1000.0
	driver.simulation_root_path = NodePath("../SimulationRoot")
	driver.terrain_registry_path = NodePath("../TerrainRegistry")
	driver.combat_visibility_cache_path = NodePath("../VisibilityCache")
	scope.add_child(driver)
	var placements: Array[Dictionary] = []
	var units: Dictionary = {}
	for spec in specs:
		var npc := NPC.new()
		npc.name = String(spec.id)
		npc.unit_id = String(spec.id)
		npc.team_id = String(spec.team)
		npc.active_weapon_id = String(spec.get("weapon", "pistol"))
		npc.hp = int(spec.get("hp", 100000))
		npc.initiative = float(spec.get("initiative", -1.0))
		npc.hit_multiplier = float(spec.get("hit_multiplier", -1.0))
		npc.leadership = float(spec.get("leadership", 0.5))
		npc.stability = float(spec.get("stability", 0.5))
		npc.traits = PackedStringArray(spec.get("traits", []))
		npc.rs.attack_bonus = float(spec.get("base_attack_bonus", 0.0))
		npc.rs.cover_score = float(spec.get("base_cover", 0.0))
		npc.position = terrain.grid_to_world(spec.grid)
		if npc.team_id == "blue":
			npc.command = COMMAND.new({"command_type": "hold_position", "fire_status": String(spec.get("fire_status", "fire_at_will")), "fire_rule": String(spec.get("fire_rule", "free"))})
		scope.add_child(npc)
		registry.register_unit(npc.unit_id, npc)
		sim.register_known_unit(npc.unit_id, npc)
		if npc.team_id == "blue":
			driver.friendly_unit_paths.append(NodePath("../%s" % npc.name))
		else:
			driver.enemy_unit_paths.append(NodePath("../%s" % npc.name))
		placements.append({"unit_id": npc.unit_id, "grid": spec.grid, "facing_dir": int(spec.get("facing", 0))})
		units[npc.unit_id] = npc
	_check(bool(sim.admit_hex_ground_units(placements).get("ok", false)), "Fixture: Einheiten zugelassen")
	return {"scope": scope, "sim": sim, "cache": cache, "driver": driver, "units": units, "calls": [], "terrain": terrain, "levels": {}}


func _tick(f: Dictionary, with_suppression: bool = false) -> void:
	f.sim._physics_process(0.1)
	f.cache.begin_tick(f.sim.tick_counter)
	f.driver._current_tick = f.sim.tick_counter
	f.driver._advance_return_fire_windows()
	f.driver._advance_detection_timers()
	if with_suppression and _has(f.driver, "_advance_suppression"):
		f.driver.call("_advance_suppression", f.sim.tick_counter)


## Laeuft `ticks` Ticks; jeden 3. Tick entscheidet der Treiber. Mit with_suppression laeuft auch der Unterdrueckungsschritt,
## und der Stufenverlauf der Gruppen in `watch` (Schluessel -> Liste je Tick) wird mitgeschrieben.
func _run_ticks(f: Dictionary, ticks: int, with_suppression: bool = false, watch: Array = []) -> void:
	for i in range(ticks):
		_tick(f, with_suppression)
		if f.sim.tick_counter % 3 == 0:
			f.sim.effects_queue.clear()
			f.driver._run_overwatch_and_attack_step(f.sim, false, {})
			var shooters: Array = []
			for effect in f.sim.effects_queue:
				if String(effect.get("effect_type", "")) == "damage":
					shooters.append(String(effect.get("attacker_unit_id", "")))
			f.calls.append({"tick": f.sim.tick_counter, "shooters": shooters})
		for key in watch:
			if not f.levels.has(key):
				f.levels[key] = []
			f.levels[key].append(int(_call_quiet(f.driver, "get_suppression_level", [key], 0)))


func _call_quiet(obj, method: String, args: Array = [], default = null):
	if not _has(obj, method):
		return default
	return obj.callv(method, args)


func _shots_by(f: Dictionary, unit_id: String) -> int:
	var count := 0
	for entry in f.calls:
		count += Array(entry.shooters).count(unit_id)
	return count


func _key(f: Dictionary, unit_id: String) -> String:
	return String(_call_quiet(f.driver, "suppression_group_key", [f.units[unit_id]], ""))


func _first_step_at(history: Array, level: int) -> int:
	for i in range(history.size()):
		if int(history[i]) >= level:
			return i + 1
	return -1


func _make_tracker():
	if not ResourceLoader.exists(TRACKER_PATH):
		_check(false, "suppression_tracker.gd fehlt")
		return null
	return load(TRACKER_PATH).new()


# ---- T1: Zustandsklasse -------------------------------------------------------

func _test_t1_tracker() -> void:
	var rules: Dictionary = MATH.load_rules()
	var has_step_ticks := false
	for entry in _math.get_script_method_list():
		if String(entry.name) == "step_ticks":
			has_step_ticks = true
	_check(has_step_ticks, "T1: suppression_math.gd hat step_ticks(rules)")
	if has_step_ticks:
		_check(int(_math.call("step_ticks", rules)) == 30, "T1: step_ticks aus den Daten = 30 (Ticks je Schritt)")
		_check(int(_math.call("step_ticks", {})) == 30 and int(_math.call("step_ticks", {"step_ticks": 0})) == 1, "T1: step_ticks ohne Feld = 30, nie unter 1")
	var tr = _make_tracker()
	if tr == null:
		return
	# Gewinne sammeln sich bis zum Schritt.
	for i in range(3):
		tr.note_shot("g", 18, true)
	_check(tr.level_of("g") == 0, "T1: vor dem Schritt keine Stufe, auch nach drei Treffern")
	_check(absf(float(_call(tr, "gains_of", ["g"], -1.0)) - 3.0) < 0.001, "T1: drei Pistolentreffer = 3,0 angesammelt")
	var lv: int = tr.step("g", 0.5, 0.5)
	_check(lv == 2 and tr.level_of("g") == 2, "T1: Schritt: 3,0 - 0,375 = 2,625 -> Stufe 2 (%d)" % lv)
	_check(absf(float(_call(tr, "value_of", ["g"], -1.0)) - 2.625) < 0.002, "T1: Wert nach dem Schritt 2,625")
	_check(absf(float(_call(tr, "gains_of", ["g"], -1.0))) < 0.001, "T1: Gewinne sind nach dem Schritt verbraucht")
	# Halten (Hysterese) und Abfallen ohne neues Feuer.
	_check(tr.step("g", 0.5, 0.5) == 2, "T1: 2,25 haelt Stufe 2 (>= 0,8 x 2,5)")
	_check(tr.step("g", 0.5, 0.5) == 1, "T1: 1,875 faellt auf Stufe 1")
	# Reihenfolge: erst Gewinn und Abbau, dann Stufe. EIN Pistolentreffer = Stufe 0.
	var one = _make_tracker()
	one.note_shot("one", 18, true)
	_check(one.step("one", 0.5, 0.5) == 0, "T1: ein einzelner Pistolentreffer: 1,0 - 0,375 = 0,625 -> nach dem Schritt Stufe 0")
	var steps := 0
	while float(_call(one, "value_of", ["one"], 1.0)) > 0.0 and steps < 20:
		one.step("one", 0.5, 0.5)
		steps += 1
	_check(steps <= 3 and one.level_of("one") == 0, "T1: der Wert faellt nach einem Treffer in wenigen Schritten auf 0 (%d)" % steps)
	# Faktoren: calm = Abbau x 2, reckless = Schwellen x 1,4.
	var calm = _make_tracker()
	for i in range(3):
		calm.note_shot("c", 18, true)
	calm.step("c", 0.5, 0.5, 2.0, 1.0)
	_check(absf(float(_call(calm, "value_of", ["c"], -1.0)) - 2.25) < 0.002, "T1: decay_factor 2 -> 3,0 - 0,75 = 2,25")
	var reckless = _make_tracker()
	for i in range(3):
		reckless.note_shot("r", 18, true)
	_check(reckless.step("r", 0.5, 0.5, 1.0, 1.4) == 1, "T1: threshold_factor 1,4 -> Schwellen 1,4 / 3,5 / 5,6: 2,625 ist nur Stufe 1")
	_check(tr.level_of("unbekannt") == 0 and tr.step("unbekannt", 0.5, 0.5) == 0, "T1: unbekannte Gruppe = Stufe 0")
	# Je Gruppe ein eigener Wert.
	var two = _make_tracker()
	two.note_shot("a", 18, true)
	two.note_shot("a", 18, true)
	two.note_shot("a", 18, true)
	two.note_shot("b", 18, false)
	two.step("a", 0.5, 0.5)
	two.step("b", 0.5, 0.5)
	_check(two.level_of("a") == 2 and two.level_of("b") == 0, "T1: Gruppen haengen nicht zusammen (a=%d b=%d)" % [two.level_of("a"), two.level_of("b")])
	two.reset()
	_check(two.level_of("a") == 0 and absf(float(_call(two, "value_of", ["a"], 1.0))) < 0.001 and _call(two, "group_keys", [], [1]).is_empty(), "T1: reset() loescht alles")


# ---- T2: Zeit in Ticks --------------------------------------------------------

## Tick fuer Tick (1..180) nach drei Pistolentreffern; zwischen den Ticks vergehen `delay_msec` Wanduhr-Millisekunden.
## Gibt die Ticks der Stufenwechsel zurueck.
func _level_changes_with_delay(delay_msec: int) -> Array:
	var f := _rig([
		{"id": "own", "team": "blue", "grid": CENTER, "facing": 0},
		{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0], "facing": 3},
	])
	var key := _key(f, "enemy")
	for i in range(3):
		_call(f.driver, "note_suppression_shot", [f.units["enemy"], 18, true])
	var changes: Array = []
	var last := 0
	for tick in range(1, 181):
		_call(f.driver, "_advance_suppression", [tick])
		if delay_msec > 0:
			OS.delay_msec(delay_msec)
		var level := int(_call_quiet(f.driver, "get_suppression_level", [key], 0))
		if level != last:
			changes.append(tick)
			last = level
	f.scope.free()
	return changes


func _test_t2_time() -> void:
	var f := _rig([
		{"id": "own", "team": "blue", "grid": CENTER, "facing": 0},
		{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0], "facing": 3},
	])
	var drv = f.driver
	var key := _key(f, "enemy")
	_check(not key.is_empty(), "T2: Gegner hat einen Gruppenschluessel (%s)" % key)
	for i in range(3):
		_call(drv, "note_suppression_shot", [f.units["enemy"], 18, true])
	var history: Array = []
	for tick in range(1, 181):
		if _has(drv, "_advance_suppression"):
			drv.call("_advance_suppression", tick)
		history.append(int(_call_quiet(drv, "get_suppression_level", [key], 0)))
	var changes: Array = []
	for i in range(1, history.size()):
		if history[i] != history[i - 1]:
			changes.append(i + 1)
	if not history.is_empty() and history[0] != 0:
		changes.push_front(1)
	var all_on_boundary := true
	for tick in changes:
		if int(tick) % 30 != 0:
			all_on_boundary = false
	_check(not changes.is_empty() and all_on_boundary, "T2: die Stufe aendert sich nur an Schrittgrenzen (alle 30 Ticks): %s" % str(changes))
	_check(changes.size() >= 3 and changes[0] == 30 and changes[1] == 90 and changes[2] == 180, "T2: Stufenwechsel bei Tick 30 (0->2), 90 (2->1), 180 (1->0): %s" % str(changes))
	# Keine Wanduhr: ohne Ticks aendert sich nichts, egal wie viel Zeit vergeht.
	var g := _rig([
		{"id": "own", "team": "blue", "grid": CENTER, "facing": 0},
		{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0], "facing": 3},
	])
	for i in range(3):
		_call(g.driver, "note_suppression_shot", [g.units["enemy"], 18, true])
	_call(g.driver, "_advance_suppression", [30])
	var before := int(_call_quiet(g.driver, "get_suppression_level", [_key(g, "enemy")], -1))
	OS.delay_msec(1600)
	_check(int(_call_quiet(g.driver, "get_suppression_level", [_key(g, "enemy")], -2)) == before and before == 2, "T2: 1,6 s Wanduhr ohne Tick aendern nichts (Stufe %d)" % before)
	# Eine Wanduhr-Abhaengigkeit wuerde rot: dieselbe Tickfolge, einmal ohne und einmal mit 14 ms Wanduhr je Tick (2,5 s
	# insgesamt, mehr als die alten 950 ms), ergibt exakt dieselben Stufenwechsel.
	var fast_changes := _level_changes_with_delay(0)
	var slow_changes := _level_changes_with_delay(14)
	_check(fast_changes == [30, 90, 180] and slow_changes == fast_changes, "T2: Stufenwechsel exakt bei 30/90/180, unabhaengig von der Wanduhr (%s / %s)" % [str(fast_changes), str(slow_changes)])
	var controller_source := FileAccess.get_file_as_string(CONTROLLER_PATH)
	var from_index := controller_source.find("func _update_fireteam_suppression(")
	var to_index := controller_source.find("\nfunc ", from_index + 10)
	var body := controller_source.substr(from_index, to_index - from_index) if from_index >= 0 else "x"
	_check(from_index >= 0 and not body.contains("get_ticks_msec") and not body.contains("get_ticks_usec"), "T2: _update_fireteam_suppression benutzt keine Wanduhr")
	var tracker_source := FileAccess.get_file_as_string(TRACKER_PATH) if FileAccess.file_exists(TRACKER_PATH) else "get_ticks_msec"
	_check(not tracker_source.contains("get_ticks_msec"), "T2: die Zustandsklasse benutzt keine Wanduhr")
	f.scope.free()
	g.scope.free()


# ---- T3: beide Seiten gleich --------------------------------------------------

## Drei Pistolenschuetzen (Reihenfolge der Richtungen 0,2,4) auf ein Ziel in der Mitte, 6 s = 360 Ticks (12 Schritte).
func _three_on_one(shooter_team: String, target_team: String) -> Dictionary:
	var specs: Array = [{"id": "target", "team": target_team, "grid": CENTER, "facing": 0, "hit_multiplier": 5.0}]
	for index in range(3):
		var direction: int = [0, 2, 4][index]
		specs.append({"id": "s%d" % index, "team": shooter_team, "grid": CENTER + HEX.DIRECTIONS[direction], "facing": (direction + 3) % 6, "weapon": "pistol", "hit_multiplier": 5.0})
	var f := _rig(specs)
	var key := _key(f, "target")
	_run_ticks(f, 360, true, [key])
	f["key"] = key
	return f



func _test_t3_both_sides() -> void:
	var enemy_side := _three_on_one("blue", "red")
	var own_side := _three_on_one("red", "blue")
	var results: Array = []
	for f in [enemy_side, own_side]:
		var side_name := "Gegnergruppe" if f == enemy_side else "eigenes Fireteam"
		var history: Array = f.levels.get(f.key, [])
		var tick1 := _first_step_at(history, 1)
		var tick2 := _first_step_at(history, 2)
		var tick3 := _first_step_at(history, 3)
		print("T3 %s: Stufe 1 ab Tick %d, Stufe 2 ab Tick %d, Stufe 3 ab Tick %d, Schuesse %d" % [side_name, tick1, tick2, tick3, _shots_by(f, "s0") + _shots_by(f, "s1") + _shots_by(f, "s2")])
		_check(tick2 > 0 and tick3 > tick2, "T3: %s erreicht Stufe 2 und danach Stufe 3 innerhalb von 6 s" % side_name)
		_check(tick2 > 0 and tick2 % 30 == 0 and tick3 % 30 == 0, "T3: %s wechselt nur an Schrittgrenzen" % side_name)
		results.append([tick1, tick2, tick3])
	# Gleiche Eingaben, gespiegelte Seiten: die Stufenwechsel fallen auf dieselben Ticks (ohne Toleranz).
	_check(results[0][1] > 0 and results[0] == results[1], "T3: gespiegelt identische Stufenwechsel (Gegner %s, eigene %s)" % [str(results[0]), str(results[1])])
	_check(_shots_by(enemy_side, "s0") + _shots_by(enemy_side, "s1") + _shots_by(enemy_side, "s2") == _shots_by(own_side, "s0") + _shots_by(own_side, "s1") + _shots_by(own_side, "s2"), "T3: gespiegelt gleich viele Schuesse")
	enemy_side.scope.free()
	own_side.scope.free()


# ---- T4: Feuer ----------------------------------------------------------------

func _duel_specs() -> Array:
	return [
		{"id": "own", "team": "blue", "grid": CENTER, "facing": 0, "weapon": "pistol", "fire_rule": "free"},
		{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0], "facing": 3, "weapon": "pistol"},
	]


func _pin(f: Dictionary, unit_id: String, level: int, value: float) -> void:
	var tr = _call_quiet(f.driver, "get_suppression_tracker")
	if tr == null:
		_check(false, "Treiber hat keine Zustandsklasse (get_suppression_tracker)")
		return
	tr.set_state(_key(f, unit_id), value, level)


func _reset_tracker(f: Dictionary) -> void:
	var tr = _call_quiet(f.driver, "get_suppression_tracker")
	if tr != null:
		tr.reset()


## Ein Duell Pistole gegen Pistole, Periode 3 Schritte (Massstab 1): 180 Schritte = 60 faellige Gelegenheiten je Einheit.
func _test_t4_fire() -> void:
	var rules: Dictionary = MATH.load_rules()
	var expected := {}
	for level in range(0, 4):
		var count := 0
		for slot in range(1, 61):
			if MATH.fire_slot_allowed(rules, level, slot):
				count += 1
		expected[level] = count
	_check(expected[0] == 60 and expected[1] == 48 and expected[2] == 34 and expected[3] == 20, "T4: Rechnung der Gelegenheiten 60/48/34/20 (%s)" % str(expected))
	for level in range(0, 4):
		var f := _rig(_duel_specs())
		_pin(f, "own", level, 5.0)
		_run_ticks(f, 540)
		var own_shots := _shots_by(f, "own")
		var enemy_shots := _shots_by(f, "enemy")
		print("T4 eigene Gruppe Stufe %d: eigene Schuesse %d, Gegner %d" % [level, own_shots, enemy_shots])
		_check(own_shots == expected[level], "T4: eigene Einheit, Stufe %d, Feuerregel free: %d von 60 Gelegenheiten (%d)" % [level, expected[level], own_shots])
		_check(enemy_shots == 60, "T4: der Gegner schiesst bei Stufe %d der anderen Seite weiter 60 (%d)" % [level, enemy_shots])
		_check(_call_quiet(f.driver, "get_suppression_slot_count", ["own"], -1) == 60, "T4: die Nummer der Gelegenheit zaehlt durch (60)")
		if level == 3:
			_call(f.driver, "_advance_suppression", [30])
			var own: NPC = f.units["own"]
			_check(own.rs.fire_status == "fire_at_will" and own.get_fire_status() == "fire_at_will", "T4: Feuerstatus bleibt bei Stufe 3 unveraendert (%s)" % own.rs.fire_status)
			_check(is_equal_approx(own.rs.move_speed_factor, 1.0), "T4: der Tempofaktor der Einheit wird nicht mehr auf 0 gesetzt (%s)" % str(own.rs.move_speed_factor))
		f.scope.free()
	# Gegner gleich: Stufe 3 beim Gegner = 20 Schuesse, der eigene schiesst 60.
	var g := _rig(_duel_specs())
	_pin(g, "enemy", 3, 5.0)
	_run_ticks(g, 540)
	_check(_shots_by(g, "enemy") == 20 and _shots_by(g, "own") == 60, "T4: Gegner Stufe 3 -> 20 Schuesse, eigene 60 (%d/%d)" % [_shots_by(g, "enemy"), _shots_by(g, "own")])
	g.scope.free()


# ---- T5: Bewegung -------------------------------------------------------------

func _move_cmd(f: Dictionary, unit_id: String, grid: Vector2i, factor: float) -> Dictionary:
	var cmd := {"command_type": "move_to_position", "unit_id": unit_id, "target_position": f.terrain.grid_to_world(grid)}
	if factor >= 0.0:
		cmd["move_speed_factor"] = factor
	return cmd


func _test_t5_movement() -> void:
	var specs: Array = [
		{"id": "own", "team": "blue", "grid": CENTER, "facing": 0},
		{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0] * 4, "facing": 3},
	]
	var f := _rig(specs)
	_check(_has(f.sim, "set_movement_suppression_provider"), "T5: SimulationRoot nimmt einen Tempo-Lieferanten fuer die Unterdrueckung an")
	# "Zum Feind hin" heisst: das Ziel liegt um MEHR als ein Feld naeher am naechsten Gegner (Nachbesserung 1, W3).
	var toward := CENTER + HEX.DIRECTIONS[0] * 2
	var away := CENTER - HEX.DIRECTIONS[0]
	var own: NPC = f.units["own"]
	var enemy: NPC = f.units["enemy"]
	var expected := {
		0: [0.5, 0.5], 1: [0.4, 0.4], 2: [0.0, 0.3], 3: [0.0, 0.175],
	}
	for level in range(0, 4):
		_pin(f, "own", level, 5.0)
		var f_toward: float = f.sim._extract_move_speed_factor(_move_cmd(f, "own", toward, 0.5), own)
		var f_away: float = f.sim._extract_move_speed_factor(_move_cmd(f, "own", away, 0.5), own)
		_check(absf(f_toward - expected[level][0]) < 0.001, "T5: Stufe %d, Befehl mit eigenem Faktor 0,5, Ziel naeher am Gegner: %s (%s)" % [level, str(expected[level][0]), str(f_toward)])
		_check(absf(f_away - expected[level][1]) < 0.001, "T5: Stufe %d, Befehl mit eigenem Faktor 0,5, Ziel weiter weg: %s (%s)" % [level, str(expected[level][1]), str(f_away)])
	# Ohne Faktor im Befehl wirkt der Faktor der Einheit; Stufe 2 weg vom Feind = 0,6 (Rueckzug bleibt moeglich).
	_pin(f, "own", 2, 5.0)
	var plain_away: float = f.sim._extract_move_speed_factor(_move_cmd(f, "own", away, -1.0), own)
	var plain_toward: float = f.sim._extract_move_speed_factor(_move_cmd(f, "own", toward, -1.0), own)
	_check(absf(plain_away - 0.6) < 0.001 and plain_toward == 0.0, "T5: Befehl ohne Faktor, Stufe 2: weg 0,6, hin 0 (%s/%s)" % [str(plain_away), str(plain_toward)])
	# Gegner gleich behandelt.
	_pin(f, "own", 0, 0.0)
	for level in range(1, 4):
		_pin(f, "enemy", level, 5.0)
		var e_toward: float = f.sim._extract_move_speed_factor(_move_cmd(f, "enemy", CENTER + HEX.DIRECTIONS[0] * 2, 1.0), enemy)
		var e_away: float = f.sim._extract_move_speed_factor(_move_cmd(f, "enemy", CENTER + HEX.DIRECTIONS[0] * 5, 1.0), enemy)
		var want_away: float = [0.8, 0.6, 0.35][level - 1]
		var want_toward: float = [0.8, 0.0, 0.0][level - 1]
		_check(absf(e_toward - want_toward) < 0.001 and absf(e_away - want_away) < 0.001, "T5: Gegner Stufe %d: hin %s weg %s (%s/%s)" % [level, str(want_toward), str(want_away), str(e_toward), str(e_away)])
	# Kein bekannter Gegner -> nicht "zum Feind": Stufe 2 laeuft mit 0,6.
	enemy.hp = 0
	_pin(f, "own", 2, 5.0)
	var no_enemy: float = f.sim._extract_move_speed_factor(_move_cmd(f, "own", toward, 1.0), own)
	_check(absf(no_enemy - 0.6) < 0.001, "T5: ohne bekannten Gegner gilt Stufe 2 mit 0,6 (%s)" % str(no_enemy))
	f.scope.free()


# ---- T12: Vorruecken mit Spielraum, Deckung und Rueckzug nie gesperrt (Nachbesserung 1, W3) --------------

func _test_t12_advance_margin() -> void:
	var specs: Array = [
		{"id": "own", "team": "blue", "grid": CENTER, "facing": 0},
		{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0] * 4, "facing": 3},
	]
	var f := _rig(specs)
	var own: NPC = f.units["own"]
	var enemy: NPC = f.units["enemy"]
	var d0: Vector2i = HEX.DIRECTIONS[0]
	var enemy_grid := CENTER + d0 * 4
	# Ein Deckungsfeld seitlich, hoechstens ein Feld naeher am Gegner als jetzt.
	var side_cell := Vector2i(-999, -999)
	for direction in HEX.DIRECTIONS:
		var cell: Vector2i = CENTER + direction
		if HEX.distance(cell, enemy_grid) == HEX.distance(CENTER, enemy_grid):
			side_cell = cell
	var one_closer: Vector2i = CENTER + d0
	var two_closer: Vector2i = CENTER + d0 * 2
	_check(side_cell != Vector2i(-999, -999), "T12: Vorbereitung: ein seitliches Feld gleich weit vom Gegner gefunden")
	for level in [2, 3]:
		var want_slow: float = [0.0, 0.0, 0.6, 0.35][level]
		_reset_tracker(f)
		_pin(f, "own", level, 5.0)
		var side: float = f.sim._extract_move_speed_factor(_move_cmd(f, "own", side_cell, -1.0), own)
		var near: float = f.sim._extract_move_speed_factor(_move_cmd(f, "own", one_closer, -1.0), own)
		var far: float = f.sim._extract_move_speed_factor(_move_cmd(f, "own", two_closer, -1.0), own)
		_check(absf(side - want_slow) < 0.001, "T12: Stufe %d: Deckungsziel seitlich laeuft mit %s (%s)" % [level, str(want_slow), str(side)])
		_check(absf(near - want_slow) < 0.001, "T12: Stufe %d: ein Feld naeher am Gegner zaehlt noch nicht als Vorruecken (%s)" % [level, str(near)])
		_check(far == 0.0, "T12: Stufe %d: Vorruecken um zwei Felder steht (%s)" % [level, str(far)])
		# Deckung und Rueckzug sind nie gesperrt, auch wenn das Ziel naeher am Gegner liegt.
		for purpose in [
			{"command_type": "seek_cover"},
			{"command_type": "retreat"},
			{"source_command_type": "retreat"},
			{"source_command_type": "fall_back"},
			{"source_command_type": "disengage"},
			{"contact_cover_decision": "take_cover"},
		]:
			var cmd := _move_cmd(f, "own", two_closer, -1.0)
			for k in purpose.keys():
				cmd[k] = purpose[k]
			var factor: float = f.sim._extract_move_speed_factor(cmd, own)
			_check(absf(factor - want_slow) < 0.001, "T12: eigene Einheit Stufe %d, %s: laeuft mit %s (%s)" % [level, str(purpose), str(want_slow), str(factor)])
	# Gegner: Ausweichen in Deckung (enemy_limbo_cover) ist nie gesperrt, echtes Vorruecken schon.
	_reset_tracker(f)
	_pin(f, "enemy", 2, 3.0)
	var enemy_cmd := _move_cmd(f, "enemy", CENTER + d0 * 2, -1.0)
	var advance: float = f.sim._extract_move_speed_factor(enemy_cmd, enemy)
	enemy_cmd["source_command_type"] = "enemy_limbo_cover"
	var cover_run: float = f.sim._extract_move_speed_factor(enemy_cmd, enemy)
	_check(advance == 0.0 and absf(cover_run - 0.6) < 0.001, "T12: Gegner Stufe 2: Vorruecken steht (%s), Ausweichen in Deckung laeuft mit 0,6 (%s)" % [str(advance), str(cover_run)])
	f.scope.free()


# ---- T13: Stufe 3 ist fuer beide Seiten gleich: kein Vorruecken, danach geht es weiter (Nachbesserung 1, Punkt 5) ----

## Eine Gegnergruppe auf Stufe 3 rueckt mit demselben Befehl nicht vor, bis die Stufe unter 2 faellt, und laeuft dann mit
## demselben Befehl weiter - genau wie ein eigenes Fireteam mit unterbrochenem Plan. Kein eigenes Plansystem fuer Gegner:
## der Befehl bleibt bestehen, die Sperre kommt aus dem Tempofaktor (Stufe >= 2 zum Feind hin = 0).
func _test_t13_level3_parity() -> void:
	var results := {}
	for side in ["blue", "red"]:
		var other := "red" if side == "blue" else "blue"
		var f := _rig([
			{"id": "m", "team": side, "grid": CENTER, "facing": 0},
			{"id": "x", "team": other, "grid": CENTER + HEX.DIRECTIONS[0] * 5, "facing": 3},
		])
		var unit: NPC = f.units["m"]
		var cmd := _move_cmd(f, "m", CENTER + HEX.DIRECTIONS[0] * 3, -1.0)
		_pin(f, "m", 3, 5.0)
		var tick := 0
		var blocked_until := -1
		var first_free := -1
		for step in range(1, 60):
			tick += 30
			_call(f.driver, "_advance_suppression", [tick])
			var level := int(_call_quiet(f.driver, "get_suppression_level", [_key(f, "m")], 0))
			var factor: float = f.sim._extract_move_speed_factor(cmd, unit)
			if level >= 2:
				if factor != 0.0:
					_check(false, "T13 (%s): Stufe %d rueckt vor (%s)" % [side, level, str(factor)])
				blocked_until = step
			elif first_free < 0:
				first_free = step
				_check(factor > 0.0, "T13 (%s): unter Stufe 2 laeuft derselbe Befehl weiter (%s)" % [side, str(factor)])
				break
		_check(blocked_until > 0 and first_free > blocked_until, "T13 (%s): gesperrt bis Schritt %d, frei ab Schritt %d" % [side, blocked_until, first_free])
		results[side] = [blocked_until, first_free]
		f.scope.free()
	_check(results["blue"] == results["red"], "T13: eigene und Gegnerseite gleich: %s / %s" % [str(results["blue"]), str(results["red"])])


# ---- T7: Abklingen ------------------------------------------------------------

func _burst(f: Dictionary, target_id: String, shots: int) -> void:
	for i in range(shots):
		_call(f.driver, "note_suppression_shot", [f.units[target_id], 18, true])


func _snapshot_units(f: Dictionary, ids: Array, base_bonus: float, base_cover: float) -> bool:
	for unit_id in ids:
		var u: NPC = f.units[unit_id]
		if not is_equal_approx(u.rs.attack_bonus, base_bonus) or not is_equal_approx(u.rs.cover_score, base_cover) or not is_equal_approx(u.rs.move_speed_factor, 1.0) or u.rs.fire_status != "fire_at_will":
			return false
	return true


func _test_t7_decay() -> void:
	for side in ["blue", "red"]:
		var other := "red" if side == "blue" else "blue"
		var specs: Array = []
		for index in range(3):
			specs.append({"id": "m%d" % index, "team": side, "grid": CENTER + HEX.DIRECTIONS[index], "facing": 0, "base_attack_bonus": 0.05, "base_cover": 10.0, "leadership": 0.5 if index > 0 else 0.9})
		specs.append({"id": "x", "team": other, "grid": CENTER + HEX.DIRECTIONS[0] * 5, "facing": 3})
		var f := _rig(specs)
		_burst(f, "m1", 12)
		var tick := 30
		_call(f.driver, "_advance_suppression", [tick])
		var key := _key(f, "m1")
		_check(int(_call_quiet(f.driver, "get_suppression_level", [key], 0)) == 3, "T7 (%s): Stufe 3 nach dem Feuerstoss" % side)
		# Nachbesserung 1 (W1): nichts wird in den Laufzeitstatus geschrieben; der Abzug kommt beim Lesen aus der Stufe.
		_check(_snapshot_units(f, ["m0", "m1", "m2"], 0.05, 10.0), "T7 (%s): unter Stufe 3 bleiben die Laufzeitwerte der Einheiten unberuehrt" % side)
		var mods: Dictionary = Dictionary(_call_quiet(f.driver, "get_suppression_combat_modifiers", [f.units["m1"]], {}))
		_check(absf(float(mods.get("hit_bonus", 0.0)) + 0.15) < 0.001 and absf(float(mods.get("cover_floor", 0.0)) - 24.0) < 0.001, "T7 (%s): unter Stufe 3 liefert der Treiber -0,15 Treffer und Deckungsboden 24 (%s)" % [side, str(mods)])
		# Der Fuehrer faellt aus, waehrend die Gruppe niedergehalten ist.
		f.units["m0"].hp = 0
		var steps := 0
		while int(_call_quiet(f.driver, "get_suppression_level", [key], 0)) > 0 and steps < 40:
			tick += 30
			_call(f.driver, "_advance_suppression", [tick])
			steps += 1
		_check(steps > 0 and steps < 40, "T7 (%s): auch nach dem Tod des Fuehrers faellt die Stufe nach endlicher Zeit auf 0 (%d Schritte)" % [side, steps])
		f.units["m0"].hp = 100000
		tick += 30
		_call(f.driver, "_advance_suppression", [tick])
		_check(_snapshot_units(f, ["m0", "m1", "m2"], 0.05, 10.0), "T7 (%s): Trefferabzug, Deckungsboden und Tempo stehen wieder auf den Basiswerten" % side)
		_check(absf(float(f.sim._extract_move_speed_factor(_move_cmd(f, "m1", CENTER, 1.0), f.units["m1"])) - 1.0) < 0.001, "T7 (%s): Laufen wieder mit vollem Tempo" % side)
		f.scope.free()
		# Die Gruppe wird ausgeloescht, waehrend sie niedergehalten ist.
		var g := _rig(specs)
		_burst(g, "m1", 12)
		tick = 30
		_call(g.driver, "_advance_suppression", [tick])
		for unit_id in ["m0", "m1", "m2"]:
			g.units[unit_id].hp = 0
		tick += 30
		_call(g.driver, "_advance_suppression", [tick])
		_check(int(_call_quiet(g.driver, "get_suppression_level", [key], 0)) == 0, "T7 (%s): eine ausgeloeschte Gruppe haelt keine Stufe" % side)
		for unit_id in ["m0", "m1", "m2"]:
			g.units[unit_id].hp = 100000
		tick += 30
		_call(g.driver, "_advance_suppression", [tick])
		_check(_snapshot_units(g, ["m0", "m1", "m2"], 0.05, 10.0), "T7 (%s): wiederbelebte Mitglieder tragen keinen Rest (Basiswerte)" % side)
		g.scope.free()


# ---- T8: Treffer und Deckung (Regel 7) ----------------------------------------

func _resolve_shot(f: Dictionary, attacker_id: String, target_id: String) -> Dictionary:
	var captured: Array = []
	var capture := func(result: Dictionary) -> void: captured.append(result)
	f.sim.damage_effect_resolved.connect(capture)
	var attacker: NPC = f.units[attacker_id]
	f.sim._apply_damage_effect({"effect_type": "damage", "unit_id": target_id, "attacker_unit_id": attacker_id, "attacker_team_id": attacker.team_id, "damage": 18, "hit_chance": 0.5, "roll_override": 0.99, "weapon_id": "pistol"})
	f.sim.damage_effect_resolved.disconnect(capture)
	return captured[0] if not captured.is_empty() else {}


func _test_t8_hit_and_cover() -> void:
	var tick := 0
	for pair in [["own", "enemy"], ["enemy", "own"]]:
		var shooter_id: String = pair[0]
		var target_id: String = pair[1]
		var f := _rig([
			{"id": "own", "team": "blue", "grid": CENTER, "facing": 0, "base_cover": 10.0},
			{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0], "facing": 3, "base_cover": 10.0},
		])
		var base := _resolve_shot(f, shooter_id, target_id)
		var base_hit := float(base.get("hit_chance_resolved", -1.0))
		_check(not base.is_empty(), "T8: Grundschuss aufgeloest (%s -> %s)" % [shooter_id, target_id])
		var want := {1: -0.05, 2: -0.10, 3: -0.15}
		var seeded := {1: 1.5, 2: 3.0, 3: 5.0}
		for level in [1, 2, 3]:
			_pin(f, shooter_id, level, seeded[level])
			tick += 30
			_call(f.driver, "_advance_suppression", [tick])
			var shot := _resolve_shot(f, shooter_id, target_id)
			# Die eigene Deckung des Schuetzen (ab Stufe 2 Boden 24) gibt im Grundspiel einen kleinen Treffer-Bonus
			# (ATTACKER_COVER_HIT_BONUS_FACTOR); der gehoert nicht zur Unterdrueckungs-Abwertung und wird herausgerechnet.
			var cover_bonus := (float(shot.get("attacker_cover_ratio", 0.0)) - float(base.get("attacker_cover_ratio", 0.0))) * 0.05
			var diff := float(shot.get("hit_chance_resolved", -9.0)) - base_hit - cover_bonus
			_check(absf(diff - float(want[level])) < 0.002, "T8: %s unter Stufe %d trifft um %s schlechter (%s)" % [shooter_id, level, str(want[level]), str(diff)])
		_reset_tracker(f)
		tick += 30
		_call(f.driver, "_advance_suppression", [tick])
		var restored := _resolve_shot(f, shooter_id, target_id)
		_check(absf(float(restored.get("hit_chance_resolved", -9.0)) - base_hit) < 0.002, "T8: bei Stufe 0 wieder der Grundwert (%s)" % shooter_id)
		# Deckungsboden fuer das Ziel: Stufe 1 = 0, Stufe 2 und 3 = 24 (Basis 10).
		for level in [1, 2, 3]:
			_reset_tracker(f)
			_pin(f, target_id, level, seeded[level])
			tick += 30
			_call(f.driver, "_advance_suppression", [tick])
			var covered := _resolve_shot(f, shooter_id, target_id)
			var expected_cover: float = 10.0 if level == 1 else 24.0
			_check(absf(float(covered.get("target_cover_score", -1.0)) - expected_cover) < 0.01, "T8: Ziel %s unter Stufe %d hat Deckung %s (%s)" % [target_id, level, str(expected_cover), str(covered.get("target_cover_score", -1.0))])
		f.scope.free()


# ---- T9: Abzug beim Lesen (Nachbesserung 1, W1) -------------------------------

func _resolve_shot_with(f: Dictionary, attacker_id: String, target_id: String, roll: float, hit_chance: float) -> Dictionary:
	var captured: Array = []
	var capture := func(result: Dictionary) -> void: captured.append(result)
	f.sim.damage_effect_resolved.connect(capture)
	var attacker: NPC = f.units[attacker_id]
	f.sim._apply_damage_effect({"effect_type": "damage", "unit_id": target_id, "attacker_unit_id": attacker_id, "attacker_team_id": attacker.team_id, "damage": 18, "hit_chance": hit_chance, "roll_override": roll, "weapon_id": "pistol"})
	f.sim.damage_effect_resolved.disconnect(capture)
	return captured[0] if not captured.is_empty() else {}


## Ein neuer Befehl schreibt neue Werte in den Laufzeitstatus (so macht es assign_unit_command).
func _new_command_values(unit: NPC, bonus: float, cover: float) -> void:
	unit.rs.attack_bonus = bonus
	unit.rs.cover_score = cover


func _test_t9_read_time_modifiers() -> void:
	var tick := 0
	for pair in [["own", "enemy"], ["enemy", "own"]]:
		var shooter_id: String = pair[0]
		var target_id: String = pair[1]
		var shooter: NPC
		var target: NPC
		var f := _rig([
			{"id": "own", "team": "blue", "grid": CENTER, "facing": 0, "base_cover": 10.0, "base_attack_bonus": 0.05},
			{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0], "facing": 3, "base_cover": 10.0, "base_attack_bonus": 0.05},
		])
		shooter = f.units[shooter_id]
		target = f.units[target_id]
		# (a) Ein neuer Befehl waehrend Stufe 2 nimmt den Abzug nicht weg.
		_pin(f, shooter_id, 2, 3.0)
		tick += 30
		_call(f.driver, "_advance_suppression", [tick])
		_new_command_values(shooter, 0.07, 12.0)
		var suppressed := _resolve_shot_with(f, shooter_id, target_id, 0.99, 0.5)
		_reset_tracker(f)
		tick += 30
		_call(f.driver, "_advance_suppression", [tick])
		_new_command_values(shooter, 0.07, 12.0)
		var plain := _resolve_shot_with(f, shooter_id, target_id, 0.99, 0.5)
		var diff := float(suppressed.get("hit_chance_resolved", -9.0)) - float(plain.get("hit_chance_resolved", -9.0))
		_check(not suppressed.is_empty() and absf(diff + 0.10) < 0.002, "T9a: %s: nach einem neuen Befehl gilt unter Stufe 2 weiter -0,10 Trefferchance (%s)" % [shooter_id, str(diff)])
		_pin(f, target_id, 2, 3.0)
		tick += 30
		_call(f.driver, "_advance_suppression", [tick])
		_new_command_values(target, 0.0, 12.0)
		var covered := _resolve_shot_with(f, shooter_id, target_id, 0.99, 0.5)
		_check(absf(float(covered.get("target_cover_score", -1.0)) - 24.0) < 0.01, "T9a: %s: nach einem neuen Befehl gilt unter Stufe 2 weiter der Deckungsboden 24 (%s)" % [target_id, str(covered.get("target_cover_score", -1.0))])
		# (b) Faellt die Stufe auf 0, bleiben die Werte des inzwischen neuen Befehls; nichts Altes wird zurueckgeschrieben.
		_reset_tracker(f)
		_pin(f, shooter_id, 2, 3.0)
		tick += 30
		_call(f.driver, "_advance_suppression", [tick])
		_new_command_values(shooter, 0.08, 40.0)
		_reset_tracker(f)
		tick += 30
		_call(f.driver, "_advance_suppression", [tick])
		_check(is_equal_approx(shooter.rs.attack_bonus, 0.08) and is_equal_approx(shooter.rs.cover_score, 40.0), "T9b: %s: nach dem Abklingen stehen die Werte des neuen Befehls (%s/%s)" % [shooter_id, str(shooter.rs.attack_bonus), str(shooter.rs.cover_score)])
		f.scope.free()
		# (c) Schaden bei Treffer mit und ohne Unterdrueckung gleich.
		var g := _rig([
			{"id": "own", "team": "blue", "grid": CENTER, "facing": 0, "base_cover": 10.0, "base_attack_bonus": 0.05},
			{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0], "facing": 3, "base_cover": 10.0, "base_attack_bonus": 0.05},
		])
		var clean := _resolve_shot_with(g, shooter_id, target_id, 0.0, 1.0)
		_pin(g, shooter_id, 3, 5.0)
		tick += 30
		_call(g.driver, "_advance_suppression", [tick])
		var pressed := _resolve_shot_with(g, shooter_id, target_id, 0.0, 1.0)
		_check(not clean.is_empty() and int(clean.get("damage_resolved", -1)) > 0 and int(clean.get("damage_resolved", -1)) == int(pressed.get("damage_resolved", -2)), "T9c: %s: Schaden bei Treffer mit und ohne Stufe 3 gleich (%s/%s)" % [shooter_id, str(clean.get("damage_resolved", -1)), str(pressed.get("damage_resolved", -2))])
		g.scope.free()


# ---- T10: Planabgleich im Gefecht (Nachbesserung 1, W2) ----------------------

## Ein Planabgleich (set_planning_state) mitten im Gefecht loescht weder die Stufen beider Seiten noch die Vormerkung der
## Unterbrechung; der unterbrochene Plan wird nach dem Abklingen fortgesetzt.
func _test_t10_planning_sync() -> void:
	var scene = load(SCENE_PATH).instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	var controller = scene.get_node("TacticalController")
	var driver = scene.get_node("CombatLoopDriver")
	var sim = scene.get_node("SimulationRoot")
	sim.set_physics_process(false)
	sim.set_process(false)
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(240.0, 170.0))
	controller.call("advance_to_next_phase")
	var unit_alpha = scene.get_node("UnitAlpha")
	var key := String(_call_quiet(driver, "suppression_group_key", [unit_alpha], ""))
	var tick := 40020
	for i in range(60):
		_call(driver, "note_suppression_shot", [unit_alpha, 18, true])
		tick += 30
		_call(driver, "_advance_suppression", [tick])
		controller.call("_update_fireteam_suppression", 0.016)
		if int(_call_quiet(driver, "get_suppression_level", [key], 0)) >= 3:
			break
	var tracker = _call_quiet(driver, "get_suppression_tracker")
	if tracker != null:
		tracker.set_state("enemy:probe", 3.0, 2)
	_check(int(_call_quiet(driver, "get_suppression_level", [key], 0)) >= 3, "T10: eigenes Fireteam steht vor dem Planabgleich auf Stufe 3")
	_check(_first_waypoint_status(controller.call("get_order_plans_snapshot"), "blue") == "interrupted", "T10: der Plan ist unterbrochen")
	controller.call("set_planning_state", {})
	_check(int(_call_quiet(driver, "get_suppression_level", [key], 0)) >= 3, "T10: ein Planabgleich laesst die Stufe des eigenen Fireteams stehen")
	_check(int(_call_quiet(driver, "get_suppression_level", ["enemy:probe"], 0)) == 2, "T10: ein Planabgleich laesst die Stufe der Gegnergruppe stehen")
	_check(bool(controller.get("_suppression_interrupt_pending_by_fireteam").get("blue", false)), "T10: die Vormerkung der Unterbrechung bleibt nach dem Planabgleich")
	controller.call("_update_fireteam_suppression", 0.016)
	_check(int(_call_quiet(driver, "get_suppression_level", [key], 0)) >= 3, "T10: auch ein Bild danach steht die Stufe noch")
	# Feuer hoert auf; nach dem Abklingen unter Stufe 2 wird der Plan fortgesetzt.
	var resumed := false
	for i in range(80):
		tick += 30
		_call(driver, "_advance_suppression", [tick])
		controller.call("_update_fireteam_suppression", 0.016)
		if int(_call_quiet(driver, "get_suppression_level", [key], 0)) < 2:
			resumed = not bool(controller.get("_suppression_interrupt_pending_by_fireteam").get("blue", false))
			break
	_check(resumed, "T10: nach dem Abklingen wird fortgesetzt, auch wenn dazwischen ein Planabgleich lief")
	_check(_first_waypoint_status(controller.call("get_order_plans_snapshot"), "blue") != "interrupted", "T10: kein Plan bleibt auf interrupted stehen")
	scene.queue_free()
	await process_frame


# ---- T14: Gefechtsende (Nachbesserung 2, N1) ---------------------------------

## Nach dem Gefechtsende laeuft der Unterdrueckungs-Schritt weiter (ueber den echten _on_tick_processed): der Wert klingt
## normal ab, die Stufe faellt, Tempo, Plan und GO-Erholung werden wieder frei. Kein hartes Zuruecksetzen.
func _test_t14_after_combat_end() -> void:
	var scene = load(SCENE_PATH).instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	var controller = scene.get_node("TacticalController")
	var driver = scene.get_node("CombatLoopDriver")
	var sim = scene.get_node("SimulationRoot")
	sim.set_physics_process(false)
	sim.set_process(false)
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(240.0, 170.0))
	controller.call("advance_to_next_phase")
	var unit_alpha = scene.get_node("UnitAlpha")
	var key := String(_call_quiet(driver, "suppression_group_key", [unit_alpha], ""))
	var tick := 50040
	for i in range(60):
		_call(driver, "note_suppression_shot", [unit_alpha, 18, true])
		tick += 30
		_call(driver, "_advance_suppression", [tick])
		controller.call("_update_fireteam_suppression", 0.016)
		if int(_call_quiet(driver, "get_suppression_level", [key], 0)) >= 3:
			break
	var tracker = _call_quiet(driver, "get_suppression_tracker")
	if tracker != null:
		tracker.set_state("enemy:probe", 5.0, 3)
	_check(int(_call_quiet(driver, "get_suppression_level", [key], 0)) >= 3, "T14: eigenes Fireteam steht bei Gefechtsende auf Stufe 3")
	_check(_first_waypoint_status(controller.call("get_order_plans_snapshot"), "blue") == "interrupted", "T14: der Plan ist unterbrochen")
	driver.set("_combat_finished", true)
	var cmd := {"command_type": "move_to_position", "target_position": unit_alpha.global_position + Vector2(400.0, 0.0)}
	var steps := 0
	while steps < 80:
		tick += 30
		driver.call("_on_tick_processed", tick)
		controller.call("_update_fireteam_suppression", 0.016)
		steps += 1
		if int(_call_quiet(driver, "get_suppression_level", [key], 0)) == 0:
			break
	_check(bool(driver.get("_combat_finished")), "T14: das Gefecht ist weiter beendet (kein Neustart durch den Test)")
	_check(int(_call_quiet(driver, "get_suppression_level", [key], 0)) == 0 and steps < 80, "T14: nach Gefechtsende faellt die Stufe nach endlich vielen Schritten auf 0 (%d Schritte)" % steps)
	_check(absf(float(_call_quiet(driver, "get_suppression_move_factor", [unit_alpha, cmd], 0.0)) - 1.0) < 0.001, "T14: der Tempofaktor ist wieder 1,0")
	_check(not bool(controller.get("_suppression_interrupt_pending_by_fireteam").get("blue", false)), "T14: die Vormerkung der Unterbrechung ist erledigt")
	_check(_first_waypoint_status(controller.call("get_order_plans_snapshot"), "blue") != "interrupted", "T14: der Plan ist fortgesetzt")
	_check(not bool(controller.call("_is_fireteam_go_recovery_blocked", "blue")), "T14: GO-Erholung ist wieder frei")
	# Gegnergruppe: dieselbe Abklingzeit nach Gefechtsende (Sonde ohne Mitglieder wird vergessen, daher eine echte Gruppe).
	scene.queue_free()
	await process_frame
	var f := _rig([
		{"id": "own", "team": "blue", "grid": CENTER, "facing": 0},
		{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0] * 3, "facing": 3},
	])
	f.driver.set("_combat_finished", true)
	_pin(f, "enemy", 3, 5.0)
	var ekey := _key(f, "enemy")
	var etick := 60000
	var esteps := 0
	while esteps < 80 and int(_call_quiet(f.driver, "get_suppression_level", [ekey], 0)) > 0:
		etick += 30
		f.driver.call("_on_tick_processed", etick)
		esteps += 1
	_check(int(_call_quiet(f.driver, "get_suppression_level", [ekey], 0)) == 0 and esteps < 80, "T14: Gegnergruppe faellt nach Gefechtsende auf 0 (%d Schritte)" % esteps)
	_check(esteps >= 3, "T14: das Abklingen laeuft normal ueber mehrere Schritte, kein Zuruecksetzen auf einen Schlag (%d)" % esteps)
	f.scope.free()


# ---- T6: Plan -----------------------------------------------------------------

func _first_waypoint_status(plan_dicts: Array, fireteam_id: String) -> String:
	for plan_variant in plan_dicts:
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		var plan_dict: Dictionary = Dictionary(plan_variant)
		if String(plan_dict.get("fireteam_id", "")) != fireteam_id:
			continue
		var waypoints: Array = Array(plan_dict.get("waypoints", []))
		if waypoints.is_empty():
			return ""
		return String(Dictionary(waypoints[0]).get("status", ""))
	return ""


## Echter Taktik-Controller in der Teststage: die Planunterbrechung kommt erst bei Stufe 3 (interrupts_plan),
## die Fortsetzung, sobald die Stufe unter 2 faellt (nicht erst bei 0).
func _test_t6_plan() -> void:
	var scene = load(SCENE_PATH).instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	var controller = scene.get_node("TacticalController")
	var driver = scene.get_node("CombatLoopDriver")
	var sim = scene.get_node("SimulationRoot")
	sim.set_physics_process(false)
	sim.set_process(false)
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(240.0, 170.0))
	controller.call("advance_to_next_phase")
	var unit_alpha = scene.get_node("UnitAlpha")
	var key := String(_call_quiet(driver, "suppression_group_key", [unit_alpha], ""))
	_check(not key.is_empty(), "T6: Fireteam blue hat einen Gruppenschluessel (%s)" % key)
	_check(String(controller.call("get_fireteam_suppression_snapshot", "blue").get("fireteam_id", "blue")) != "x", "T6: Controller liefert den Unterdrueckungsstand")
	var tick := 30000
	var status_at_2 := ""
	var status_at_3 := ""
	var seen_2 := false
	var seen_3 := false
	for i in range(60):
		_call(driver, "note_suppression_shot", [unit_alpha, 18, true])
		tick += 30
		_call(driver, "_advance_suppression", [tick])
		controller.call("_update_fireteam_suppression", 0.016)
		var level := int(_call_quiet(driver, "get_suppression_level", [key], 0))
		var status := _first_waypoint_status(controller.call("get_order_plans_snapshot"), "blue")
		if level == 2 and not seen_2:
			seen_2 = true
			status_at_2 = status
		if level >= 3:
			seen_3 = true
			status_at_3 = status
			break
	_check(seen_2 and status_at_2 != "interrupted", "T6: Stufe 2 unterbricht den Plan nicht (%s)" % status_at_2)
	_check(seen_3 and status_at_3 == "interrupted", "T6: Stufe 3 unterbricht den Plan (%s)" % status_at_3)
	_check(bool(controller.get("_suppression_interrupt_pending_by_fireteam").get("blue", false)), "T6: Unterbrechung ist vorgemerkt")
	# Feuer hoert auf: bei Stufe 2 bleibt die Unterbrechung, erst darunter wird fortgesetzt.
	var held_at_2 := false
	var resumed_below_2 := false
	for i in range(60):
		tick += 30
		_call(driver, "_advance_suppression", [tick])
		controller.call("_update_fireteam_suppression", 0.016)
		var level := int(_call_quiet(driver, "get_suppression_level", [key], 0))
		var pending := bool(controller.get("_suppression_interrupt_pending_by_fireteam").get("blue", false))
		if level >= 2 and pending:
			held_at_2 = true
		if level < 2:
			resumed_below_2 = not pending
			break
	_check(held_at_2, "T6: bei Stufe 2 und 3 bleibt der Plan unterbrochen, auch wenn niemand mehr schiesst")
	_check(resumed_below_2, "T6: sobald die Stufe unter 2 faellt, geht es automatisch weiter")
	var status_after := _first_waypoint_status(controller.call("get_order_plans_snapshot"), "blue")
	_check(status_after != "interrupted", "T6: der Plan ist nach der Fortsetzung nicht mehr unterbrochen (%s)" % status_after)
	scene.queue_free()
	await process_frame
