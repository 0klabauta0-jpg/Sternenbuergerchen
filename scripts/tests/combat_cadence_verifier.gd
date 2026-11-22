extends SceneTree
## Gefechtstakt (INI): jede Einheit beider Seiten schiesst im eigenen Takt, gleichzeitig, ohne Vorrang.
## Teil 1 rechnet nur (CombatCadence). Teil 2 laeuft im echten Treiber (_try_enqueue_attacks) mit kleinen Duellen.
## Schlusszeile: COMBAT_CADENCE passed=N failed=M

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

const CENTER := Vector2i(20, 20)
var passed := 0
var failed := 0


class NPC extends Node2D:
	var unit_id: String
	var team_id: String
	var active_weapon_id := "pistol"
	var hp := 100000
	var initiative := -1.0
	var hit_multiplier := -1.0
	var command: RefCounted
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team_id
	func get_fireteam_id() -> String: return team_id + "_ft"
	func get_vital_state() -> String: return "fit" if hp > 0 else "down"
	func get_health() -> int: return hp
	var awareness := 1.0
	func get_awareness() -> float: return awareness
	func get_active_weapon_id() -> String: return active_weapon_id
	func get_current_unit_command(): return command
	func get_stealth() -> float: return 0.0
	func get_discipline() -> float: return 0.0
	func get_fire_status() -> String: return String(command.get("fire_status")) if command != null else "fire_at_will"
	var events: Array = []
	func show_event_text(text: String, _color: Color, _duration: float) -> void: events.append(text)
	func get_character_profile_bundle() -> Dictionary:
		return {"behavior_axes": {"initiative": initiative}} if initiative >= 0.0 else {}
	func get_combat_hit_chance_multiplier() -> float:
		return hit_multiplier if hit_multiplier >= 0.0 else 1.0
	func apply_damage(amount: int, _context: Dictionary = {}) -> bool:
		hp -= amount
		return true


## Ohne Verarbeitung; mit Hilfen fuer die Tests: Ueberwachungsschuesse nach Plan (Tick -> Schuetzen) mit Sperrzeit,
## erzwungener Disziplinwurf mit Zaehler, Zaehler fuer Zielsuchen (start_detection wird je Suche mit Ziel gerufen).
class QuietDriver extends DRIVER:
	var overwatch_plan: Dictionary = {}
	var overwatch_lock_ticks := 18
	var overwatch_ready_tick: Dictionary = {}
	var forced_roll := -1.0
	var roll_calls := 0
	var search_calls := 0

	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
		var simulation_root = get_node_or_null(simulation_root_path)
		if simulation_root != null:
			simulation_root.damage_effect_resolved.connect(_on_damage_effect_resolved)

	func _try_enqueue_overwatch(_simulation_root: Node) -> Array:
		var shots: Array = []
		for shooter in Array(overwatch_plan.get(_current_tick, [])):
			overwatch_ready_tick[String(shooter)] = _current_tick + overwatch_lock_ticks
			shots.append({"attacker_unit_id": String(shooter), "target_unit_id": "enemy"})
		return shots

	func get_overwatch_member_ready_snapshot() -> Dictionary:
		var snapshot: Dictionary = {}
		for shooter in overwatch_ready_tick.keys():
			var ready_tick: int = int(overwatch_ready_tick[shooter])
			snapshot[shooter] = {"ready": _current_tick >= ready_tick, "ready_tick": ready_tick, "cooldown_remaining_ticks": maxi(ready_tick - _current_tick, 0)}
		return snapshot

	func _next_authoritative_combat_roll() -> float:
		if forced_roll < 0.0:
			return super._next_authoritative_combat_roll()
		roll_calls += 1
		return forced_roll

	func _start_or_continue_detection(attacker, attacker_id: String, target_id: String) -> void:
		search_calls += 1
		super._start_or_continue_detection(attacker, attacker_id, target_id)


func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", label)


func _run() -> void:
	_test_period_steps()
	_test_is_due()
	_test_duel_both_sides_shoot()
	_test_cooldown_does_not_displace_other_side()
	_test_three_against_one()
	_test_twelve_shooters_twelve_events()
	_test_simultaneous_kill()
	_test_fixed_order_independent_of_creation()
	_test_overwatch_does_not_displace_normal_fire()
	_test_alternating_overwatch_enemy_keeps_cadence()
	_test_discipline_roll_only_when_due()
	_test_target_search_only_for_due_units()
	_test_dead_shooter_keeps_hit_chance()
	_test_normal_shot_sets_overwatch_lock()
	_test_detection_runs_before_due()
	_test_respawn_clears_warm_state()
	await process_frame
	print("COMBAT_CADENCE passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


# ---- Teil 1: reine Rechnung -------------------------------------------------

func _test_period_steps() -> void:
	_check(CADENCE.period_steps(10, 0.5) == 4, "Gewehr 10 Ticks, Initiative 0,5 -> 4")
	_check(CADENCE.period_steps(10, 0.9) == 3, "10 / 0,9 -> 3")
	_check(CADENCE.period_steps(10, 0.1) == 5, "10 / 0,1 -> 5")
	_check(CADENCE.period_steps(3, 0.9) == 1, "3 / 0,9 -> 1 (nie unter 1)")
	_check(CADENCE.period_steps(1, 0.5) == 1, "1 / 0,5 -> 1")
	_check(CADENCE.period_steps(0, 0.5) == 1, "0 Ticks -> 1")
	_check(CADENCE.period_steps(9, 0.5) == 3, "Pistole 9 -> 3")
	_check(CADENCE.period_steps(6, 0.5) == 2, "MP 6 -> 2")
	_check(CADENCE.period_steps(26, 0.5) == 9, "Rakete 26 -> 9")
	_check(CADENCE.period_steps(10, 0.67) == 3, "Grenze 0,67 gehoert zu schnell (-1)")
	_check(CADENCE.period_steps(10, 0.66) == 4, "0,66 ohne Verschiebung")
	_check(CADENCE.period_steps(10, 0.33) == 5, "Grenze 0,33 gehoert zu langsam (+1)")
	_check(CADENCE.period_steps(10, 0.34) == 4, "0,34 ohne Verschiebung")
	_check(CADENCE.period_steps(10, 0.0) == 5 and CADENCE.period_steps(10, 1.0) == 3, "0 und 1 an den Raendern")
	for invalid in [NAN, -1.0, 1.5, INF]:
		_check(CADENCE.period_steps(10, invalid) == CADENCE.period_steps(10, 0.5), "ungueltige Initiative %s wie 0,5" % str(invalid))


func _test_is_due() -> void:
	var due2: Array = []
	var due5: Array = []
	for step in range(1, 11):
		if CADENCE.is_due(step, 2): due2.append(step)
		if CADENCE.is_due(step, 5): due5.append(step)
	_check(due2 == [2, 4, 6, 8, 10], "Periode 2 in 10 Schritten: 2,4,6,8,10 (%s)" % str(due2))
	_check(due5 == [5, 10], "Periode 5 in 10 Schritten: 5,10 (%s)" % str(due5))
	_check(CADENCE.is_due(7, 1) and CADENCE.is_due(7, 0), "Periode 1 (und Schutz fuer 0) ist immer dran")
	_check(CADENCE.is_due(1000003, 1000003) and not CADENCE.is_due(1000002, 1000003), "Zaehler ohne Obergrenze")


# ---- Teil 2: echter Treiber -------------------------------------------------

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


## spec: {id, team, grid, facing, weapon, hp, initiative, hit_multiplier}. Reihenfolge der Liste = Anlegereihenfolge.
func _rig(specs: Array, seed_value: int = 7) -> Dictionary:
	var scope := Node.new()
	scope.name = "CadenceFixture"
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
	var map = MAP.create_empty("cadence_fixture", Vector2i(160, 80), Vector2.ZERO, 64, 32, 3, "hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	map._extension_metadata["terrain_height_rules"] = "explicit_hex_ramps_v1"
	_check(bool(sim.configure_hex_ground_runtime(map, terrain).get("ok", false)), "Fixture: Bodenlaufzeit konfiguriert")
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
		npc.awareness = float(spec.get("awareness", 1.0))
		npc.position = terrain.grid_to_world(spec.grid)
		if npc.team_id == "blue":
			npc.command = COMMAND.new({"command_type": "hold_position", "fire_status": String(spec.get("fire_status", "fire_at_will")), "fire_rule": "free"})
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
	return {"scope": scope, "sim": sim, "cache": cache, "driver": driver, "units": units, "log": [], "calls": []}


func _tick(f: Dictionary) -> void:
	f.sim._physics_process(0.1)
	f.cache.begin_tick(f.sim.tick_counter)
	f.driver._current_tick = f.sim.tick_counter
	f.driver._advance_return_fire_windows()
	f.driver._advance_detection_timers()


## Laeuft `ticks` Ticks; an jedem 3. Tick entscheidet der Treiber. Gibt je Entscheidung die Schuetzen der Reihe nach zurueck
## (nur die in diesem Schritt neu eingereihten Schadenseffekte).
func _run_ticks(f: Dictionary, ticks: int) -> void:
	for i in range(ticks):
		_tick(f)
		if f.sim.tick_counter % 3 == 0:
			f.sim.effects_queue.clear()
			f.driver._run_overwatch_and_attack_step(f.sim, false, {})
			var shooters: Array = []
			for effect in f.sim.effects_queue:
				if String(effect.get("effect_type", "")) == "damage":
					shooters.append(String(effect.get("attacker_unit_id", "")))
			f.calls.append({"tick": f.sim.tick_counter, "shooters": shooters})


func _shots_by(f: Dictionary, unit_id: String) -> int:
	var count := 0
	for entry in f.calls:
		count += Array(entry.shooters).count(unit_id)
	return count


func _line(own_grid: Vector2i, enemy_grid: Vector2i, own_weapon: String, enemy_weapon: String) -> Array:
	return [
		{"id": "own", "team": "blue", "grid": own_grid, "facing": 0, "weapon": own_weapon},
		{"id": "enemy", "team": "red", "grid": enemy_grid, "facing": 3, "weapon": enemy_weapon},
	]


## Das kleine Duell: Ein eigener gegen einen Gegner, Pistole gegen Pistole, beide sehen sich. Heute: Gegner 0 Schuesse.
func _test_duel_both_sides_shoot() -> void:
	var f := _rig(_line(CENTER, CENTER + HEX.DIRECTIONS[0], "pistol", "pistol"))
	_run_ticks(f, 90)
	var own_shots := _shots_by(f, "own")
	var enemy_shots := _shots_by(f, "enemy")
	print("DUELL Schussbilanz (90 Ticks, 30 Schritte): eigene=%d Gegner=%d" % [own_shots, enemy_shots])
	_check(enemy_shots > 0, "Duell: der Gegner gibt Schuesse ab (heute 0)")
	_check(own_shots == 10 and enemy_shots == 10, "Duell: Pistole Periode 3 -> je 10 Schuesse in 30 Schritten (%d/%d)" % [own_shots, enemy_shots])
	var together := 0
	for entry in f.calls:
		if Array(entry.shooters).has("own") and Array(entry.shooters).has("enemy"):
			together += 1
	_check(together == 10, "Duell: beide schiessen im selben Schritt, wenn die Perioden zusammenfallen (%d)" % together)
	f.scope.free()


## Gewehr (Periode 4) gegen Pistole (Periode 3): Der eigene ist in Abklingzeit, der Gegner schiesst trotzdem in seinem Schritt.
func _test_cooldown_does_not_displace_other_side() -> void:
	var f := _rig(_line(CENTER, CENTER + HEX.DIRECTIONS[0], "rifle", "pistol"))
	_run_ticks(f, 90)
	_check(_shots_by(f, "own") == 7, "Gewehr Periode 4: 7 Schuesse in 30 Schritten (%d)" % _shots_by(f, "own"))
	_check(_shots_by(f, "enemy") == 10, "Pistole Periode 3: 10 Schuesse, vom Gewehr nicht verdraengt (%d)" % _shots_by(f, "enemy"))
	var enemy_alone := false
	for entry in f.calls:
		if int(entry.tick) == 9:
			enemy_alone = Array(entry.shooters) == ["enemy"]
	_check(enemy_alone, "Schritt 3: nur der Gegner ist dran und schiesst, obwohl der eigene Schuetze ein Ziel hat")
	f.scope.free()


func _test_three_against_one() -> void:
	var single := _rig(_line(CENTER, CENTER + HEX.DIRECTIONS[0], "pistol", "pistol"))
	_run_ticks(single, 90)
	var single_shots := _shots_by(single, "own")
	single.scope.free()
	var specs: Array = [{"id": "enemy", "team": "red", "grid": CENTER, "facing": 0, "weapon": "pistol"}]
	for index in range(3):
		var direction: int = [0, 2, 4][index]
		specs.append({"id": "own%d" % index, "team": "blue", "grid": CENTER + HEX.DIRECTIONS[direction], "facing": (direction + 3) % 6, "weapon": "pistol"})
	var f := _rig(specs)
	_run_ticks(f, 9)
	# Regel 9a: jeder Schuss des Schritts hat sein eigenes Feuer-Ereignis (Ton und Muendungsfeuer haengen daran).
	var shooters_seen: Dictionary = {}
	var event_ids: Dictionary = {}
	var events_with_position := 0
	for event in f.driver.get_fire_event_snapshot():
		if int(event.get("tick", -1)) == 9:
			shooters_seen[String(event.get("attacker_unit_id", ""))] = true
			event_ids[String(event.get("event_id", ""))] = true
			if event.has("muzzle_position") or event.has("attacker_position"):
				events_with_position += 1
	_check(shooters_seen.size() == 4 and event_ids.size() == 4, "Regel 9a: vier Schuetzen im selben Schritt -> vier Feuer-Ereignisse mit vier Schuetzen (%s)" % str(shooters_seen.keys()))
	_check(events_with_position == 4, "Regel 9a: jedes Ereignis traegt eine Muendungs-/Schuetzenposition (%d)" % events_with_position)
	_run_ticks(f, 81)
	var own_total := _shots_by(f, "own0") + _shots_by(f, "own1") + _shots_by(f, "own2")
	print("DREI gegen EINEN: eigene=%d (einer allein: %d) Gegner=%d" % [own_total, single_shots, _shots_by(f, "enemy")])
	_check(own_total == 3 * single_shots, "Drei Eigene schiessen dreimal so oft wie einer (%d gegen %d)" % [own_total, single_shots])
	_check(_shots_by(f, "enemy") == single_shots, "Der einzelne Gegner schiesst weiter in seinem Takt (%d)" % _shots_by(f, "enemy"))
	f.scope.free()


## Zwoelf Schuetzen im selben Schritt: zwoelf Feuer-Ereignisse in der Liste (MAX_RECENT_FIRE_EVENTS war 8).
func _test_twelve_shooters_twelve_events() -> void:
	var specs: Array = [{"id": "enemy", "team": "red", "grid": CENTER, "facing": 0, "weapon": "none"}]
	for direction in range(6):
		specs.append({"id": "n%02d" % direction, "team": "blue", "grid": CENTER + HEX.DIRECTIONS[direction], "facing": (direction + 3) % 6, "weapon": "pistol"})
		specs.append({"id": "m%02d" % direction, "team": "blue", "grid": CENTER + HEX.DIRECTIONS[direction] * 2, "facing": (direction + 3) % 6, "weapon": "pistol"})
	var f := _rig(specs)
	_run_ticks(f, 9)
	var shooters_seen: Dictionary = {}
	var events_at_tick := 0
	for event in f.driver.get_fire_event_snapshot():
		if int(event.get("tick", -1)) == 9:
			events_at_tick += 1
			shooters_seen[String(event.get("attacker_unit_id", ""))] = true
	_check(Array(f.calls[-1].shooters).size() == 12, "12 Schuetzen im selben Schritt schiessen (%d)" % Array(f.calls[-1].shooters).size())
	_check(events_at_tick == 12 and shooters_seen.size() == 12, "12 Schuetzen -> 12 Feuer-Ereignisse mit 12 verschiedenen Schuetzen (%d/%d)" % [events_at_tick, shooters_seen.size()])
	f.scope.free()


## Zwei Einheiten mit 1 Trefferpunkt und (fast) sicherer Trefferchance fallen im selben Schritt beide.
func _test_simultaneous_kill() -> void:
	var seed_value := _find_seed_with_low_rolls(2, 0.5)
	_check(seed_value > 0, "Testseed mit zwei niedrigen ersten Wuerfen gefunden")
	var specs := _line(CENTER, CENTER + HEX.DIRECTIONS[0], "pistol", "pistol")
	for spec in specs:
		spec["hp"] = 1
		spec["hit_multiplier"] = 10.0
	var f := _rig(specs, seed_value)
	_run_ticks(f, 9)
	_check(Array(f.calls[-1].shooters).size() == 2, "Schritt 3: beide geben ihren Schuss ab")
	_tick(f)
	_check(f.units["own"].hp <= 0 and f.units["enemy"].hp <= 0, "beide fallen im selben Schritt (own=%d enemy=%d)" % [f.units["own"].hp, f.units["enemy"].hp])
	f.scope.free()


func _find_seed_with_low_rolls(count: int, limit: float) -> int:
	for candidate in range(1, 500):
		var rng := RandomNumberGenerator.new()
		rng.seed = candidate
		var ok := true
		for i in range(count):
			if rng.randf() >= limit:
				ok = false
		if ok:
			return candidate
	return -1


## Gleicher Zufallsstart, Einheiten in anderer Reihenfolge angelegt, Seiten der Namen vertauscht: gleicher Ablauf.
func _test_fixed_order_independent_of_creation() -> void:
	var base: Array = [
		{"id": "u1", "team": "blue", "grid": CENTER + HEX.DIRECTIONS[0], "facing": 3, "weapon": "smg"},
		{"id": "u2", "team": "red", "grid": CENTER, "facing": 0, "weapon": "smg"},
		{"id": "u3", "team": "blue", "grid": CENTER + HEX.DIRECTIONS[2], "facing": 5, "weapon": "pistol"},
		{"id": "u4", "team": "red", "grid": CENTER + HEX.DIRECTIONS[1], "facing": 4, "weapon": "pistol"},
	]
	var reversed: Array = base.duplicate()
	reversed.reverse()
	var a := _rig(base, 11)
	var b := _rig(reversed, 11)
	var log_a := _hit_log(a, 60)
	var log_b := _hit_log(b, 60)
	_check(not log_a.is_empty(), "Ablauf hat Schuesse (%d)" % log_a.size())
	_check(log_a == log_b, "gleicher Zufallsstart -> gleicher Ablauf, egal in welcher Reihenfolge die Einheiten angelegt wurden")
	var sorted_ok := true
	for entry in a.calls:
		var shooters: Array = entry.shooters
		var copy := shooters.duplicate()
		copy.sort()
		sorted_ok = sorted_ok and shooters == copy
	_check(sorted_ok, "Schuetzen eines Schritts stehen nach unit_id sortiert, nicht nach Seite")
	var mixed := false
	for entry in a.calls:
		if (Array(entry.shooters).has("u1") or Array(entry.shooters).has("u3")) and (Array(entry.shooters).has("u2") or Array(entry.shooters).has("u4")):
			mixed = true
	_check(mixed, "Seiten sind im selben Schritt gemischt (kein Vorrang einer Seite)")
	a.scope.free()
	b.scope.free()


func _hit_log(f: Dictionary, ticks: int) -> Array:
	var entries: Array = []
	f.sim.damage_effect_resolved.connect(func(result: Dictionary) -> void:
		entries.append("%d:%s>%s:%s:%.6f" % [f.sim.tick_counter, result.get("attacker_unit_id", ""), result.get("target_unit_id", ""), str(result.get("hit", false)), float(result.get("roll", -1.0))]))
	_run_ticks(f, ticks)
	_tick(f)
	return entries


# ---- Nachbesserung 1 ---------------------------------------------------------

func _shooters_at(f: Dictionary, tick: int) -> Array:
	for entry in f.calls:
		if int(entry.tick) == tick:
			return entry.shooters
	return []


## K1 Fall 1 und 3: Ein Ueberwachungsschuss des eigenen Schuetzen verdraengt den faelligen Gegner nicht, und der
## Ueberwachungsschuetze gibt im selben Schritt und in seiner Sperrzeit keinen zusaetzlichen normalen Schuss ab.
func _test_overwatch_does_not_displace_normal_fire() -> void:
	var f := _rig(_line(CENTER, CENTER + HEX.DIRECTIONS[0], "pistol", "pistol"))
	f.driver.overwatch_plan = {9: ["own"]}
	_run_ticks(f, 30)
	_check(_shooters_at(f, 9) == ["enemy"], "K1: Schritt 3: Ueberwachung des eigenen, der faellige Gegner schiesst trotzdem (%s)" % str(_shooters_at(f, 9)))
	_check(not Array(_shooters_at(f, 9)).has("own"), "K1: kein zusaetzlicher normaler Schuss im Schritt des Ueberwachungsschusses")
	_check(_shooters_at(f, 18) == ["enemy"], "K1: in der Sperrzeit (bis Tick 27) kein normaler Schuss des Ueberwachungsschuetzen (%s)" % str(_shooters_at(f, 18)))
	_check(_shooters_at(f, 27) == ["enemy", "own"] or _shooters_at(f, 27) == ["own", "enemy"], "K1: nach der Sperrzeit schiesst er wieder normal (%s)" % str(_shooters_at(f, 27)))
	f.scope.free()


## K1 Fall 2: Zwei eigene Ueberwachungsschuetzen wechseln sich ab (Schritt 3, 6, 9 ...): der Gegner schiesst in
## 30 Schritten so oft, wie seine Periode es hergibt (Pistole, Periode 3 -> 10).
func _test_alternating_overwatch_enemy_keeps_cadence() -> void:
	var specs: Array = [{"id": "enemy", "team": "red", "grid": CENTER, "facing": 0, "weapon": "pistol"}]
	for index in range(2):
		var direction: int = [0, 2][index]
		specs.append({"id": "ow%d" % (index + 1), "team": "blue", "grid": CENTER + HEX.DIRECTIONS[direction], "facing": (direction + 3) % 6, "weapon": "pistol"})
	var f := _rig(specs)
	var plan: Dictionary = {}
	for tick in range(9, 91, 18):
		plan[tick] = ["ow1"]
		plan[tick + 9] = ["ow2"]
	f.driver.overwatch_plan = plan
	_run_ticks(f, 90)
	_check(_shots_by(f, "enemy") == 10, "K1: Gegner schiesst trotz abwechselnder Ueberwachung 10 Mal in 30 Schritten (%d)" % _shots_by(f, "enemy"))
	_check(_shots_by(f, "ow1") == 0, "K1: ow1 (jeden zweiten Schritt Ueberwachung, dazwischen gesperrt) gibt keinen normalen Schuss ab (%d)" % _shots_by(f, "ow1"))
	_check(_shots_by(f, "ow2") == 1, "K1: ow2 schiesst nur im Schritt 3 normal, danach Ueberwachung oder Sperrzeit (%d)" % _shots_by(f, "ow2"))
	f.scope.free()


## W2: Der Disziplinwurf faellt nur fuer faellige Einheiten; die Meldung nur, wenn der Schuss folgt.
func _test_discipline_roll_only_when_due() -> void:
	var specs: Array = [
		{"id": "own", "team": "blue", "grid": CENTER, "facing": 0, "weapon": "rifle", "fire_status": "hold_fire"},
		{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0], "facing": 3, "weapon": "none"},
	]
	var quiet := _rig(specs)
	quiet.driver.forced_roll = 0.99
	_run_ticks(quiet, 36)
	_check(quiet.driver.roll_calls >= 1 and quiet.driver.roll_calls <= 3, "W2: Feuerstopp, Periode 4, 12 Schritte -> hoechstens 3 Wuerfe (%d)" % quiet.driver.roll_calls)
	quiet.scope.free()
	var breaking := _rig(specs)
	breaking.driver.forced_roll = 0.0
	_run_ticks(breaking, 36)
	var messages: int = Array(breaking.units["own"].events).count("FEUERSTOPP GEBROCHEN!")
	var shots := _shots_by(breaking, "own")
	_check(shots >= 1 and messages == shots, "W2: Meldung nur mit folgendem Schuss (Meldungen %d, Schuesse %d)" % [messages, shots])
	breaking.scope.free()


## W3: 12 gegen 12, 30 Schritte: Zielsuchen hoechstens so viele wie faellige Einheiten-Schritte plus ein Anlauf je Einheit.
func _test_target_search_only_for_due_units() -> void:
	var specs: Array = []
	for index in range(12):
		var column: int = index % 6 - 3
		var row: int = index / 6
		specs.append({"id": "a%02d" % index, "team": "blue", "grid": CENTER + Vector2i(column, -1 - row), "facing": 0, "weapon": "rocket"})
		specs.append({"id": "b%02d" % index, "team": "red", "grid": CENTER + Vector2i(column, 1 + row), "facing": 3, "weapon": "rocket"})
	var f := _rig(specs)
	_run_ticks(f, 90)
	# Rakete, Periode 9: gesucht wird im faelligen Schritt und im Erkennungsfenster davor (5 Schritte), sonst nicht.
	var searched_steps := 0
	for step in range(1, 31):
		if CADENCE.steps_until_due(step, 9) <= 5:
			searched_steps += 1
	var due_unit_steps := 24 * searched_steps
	var shots_total := 0
	for entry in f.calls:
		shots_total += Array(entry.shooters).size()
	print("W3 Zielsuchen: %d (faellige Einheiten-Schritte %d, ohne Gating %d), Schuesse %d" % [f.driver.search_calls, due_unit_steps, 24 * 30, shots_total])
	_check(shots_total > 0, "W3: 12 gegen 12 schiessen (%d)" % shots_total)
	_check(f.driver.search_calls <= due_unit_steps + 24, "W3: Zielsuchen <= faellige Einheiten-Schritte + ein Anlauf je Einheit (%d <= %d)" % [f.driver.search_calls, due_unit_steps + 24])
	f.scope.free()


## k1: Trefferchance und Schussfreigabe haengen nicht von der Gesundheit des Schuetzen ab; wer im selben Schritt
## frueher in der Reihenfolge faellt, trifft mit unveraenderter Chance. Haengt das je an der Gesundheit, muss
## das Buchen auf "erst alle Wuerfe, dann alle Buchungen" umgestellt werden (Kommentar in simulation_root.gd).
func _test_dead_shooter_keeps_hit_chance() -> void:
	var chances: Array = []
	for own_hp in [1, 100000]:
		var specs := _line(CENTER, CENTER + HEX.DIRECTIONS[0], "pistol", "pistol")
		specs[0]["hp"] = own_hp
		specs[0]["hit_multiplier"] = 1.0
		specs[1]["hit_multiplier"] = 10.0
		var f := _rig(specs, 7)
		var seen: Array = []
		f.sim.damage_effect_resolved.connect(func(result: Dictionary) -> void:
			if String(result.get("attacker_unit_id", "")) == "own":
				seen.append(float(result.get("hit_chance_resolved", -1.0))))
		_run_ticks(f, 9)
		_tick(f)
		if own_hp == 1:
			_check(f.units["own"].hp <= 0, "k1: der eigene Schuetze faellt im selben Schritt (hp %d)" % f.units["own"].hp)
		_check(seen.size() == 1, "k1: sein Schuss wird trotzdem gewertet (%d)" % seen.size())
		chances.append(seen[0] if not seen.is_empty() else -2.0)
		f.scope.free()
	_check(chances[0] > 0.0 and is_equal_approx(chances[0], chances[1]), "k1: Trefferchance unveraendert, ob der Schuetze faellt oder nicht (%s)" % str(chances))


# ---- Runde 2, Teil A ---------------------------------------------------------

## Ein Ueberwachungsversuch mit dem ECHTEN Controller: Gegner wird um 10 verschoben (Bewegungsschwelle 5), dann update().
func _overwatch_try(f: Dictionary, controller: RefCounted, tick: int) -> Array:
	var enemy = f.units["enemy"]
	var own = f.units["own"]
	enemy.position += Vector2(10.0, 0.0)
	var snapshot: Array = [{
		"overwatch_ready": true,
		"fireteam_id": "blue_ft",
		"anchor_position": own.position,
		"member_assignments": [{"unit_id": "own", "center_angle": 0.0, "arc_width": TAU}],
	}]
	return Array(controller.call("update", f.sim, snapshot, {"blue_ft": [own]}, [enemy], f.scope.get_node("TerrainRegistry"), 1000.0, tick))


## K1r: Ein Normalschuss sperrt dasselbe Mitglied fuer die Ueberwachung eine Periode lang. Echter Controller.
func _test_normal_shot_sets_overwatch_lock() -> void:
	var control := _rig(_line(CENTER, CENTER + HEX.DIRECTIONS[0], "pistol", "none"))
	var control_controller: RefCounted = control.driver._overwatch_controller
	control_controller.call("update", null, [], {}, [control.units["enemy"]], null, 1000.0, 0)
	_check(_overwatch_try(control, control_controller, 12).size() == 1, "K1r Kontrolle: ohne Normalschuss loest die Ueberwachung aus")
	control.scope.free()
	var f := _rig(_line(CENTER, CENTER + HEX.DIRECTIONS[0], "pistol", "none"))
	var controller: RefCounted = f.driver._overwatch_controller
	controller.call("update", null, [], {}, [f.units["enemy"]], null, 1000.0, 0)
	_run_ticks(f, 9)
	_check(_shots_by(f, "own") == 1, "K1r: Normalschuss in Schritt 3")
	_check(_overwatch_try(f, controller, 12).is_empty(), "K1r: im Schritt danach kein Ueberwachungsschuss desselben Mitglieds")
	_check(_overwatch_try(f, controller, 15).is_empty(), "K1r: auch im uebernaechsten Schritt noch gesperrt (Periode 3 Schritte)")
	_check(_overwatch_try(f, controller, 18).size() == 1, "K1r: nach Ablauf der Periode wieder moeglich")
	f.scope.free()


## N1: Ein Ziel, das 4 Schritte vor der Faelligkeit auftaucht (Rakete, Periode 9, Erkennung 9 Ticks), wird im faelligen
## Schritt beschossen, nicht erst eine Periode spaeter. Und weit vor der Faelligkeit wird weiter nicht gesucht.
func _test_detection_runs_before_due() -> void:
	var specs: Array = [
		{"id": "own", "team": "blue", "grid": CENTER, "facing": 0, "weapon": "rocket", "awareness": 0.4},
		{"id": "enemy", "team": "red", "grid": CENTER + HEX.DIRECTIONS[0], "facing": 3, "weapon": "none", "hp": 0},
	]
	var f := _rig(specs)
	_run_ticks(f, 41)
	f.units["enemy"].hp = 100000  # der Gegner "taucht auf" (vorher am Boden, kein Ziel)
	_run_ticks(f, 20)
	var first_shot_tick := -1
	for entry in f.calls:
		if Array(entry.shooters).has("own"):
			first_shot_tick = int(entry.tick)
			break
	_check(first_shot_tick == 54, "N1: Ziel 4 Schritte vor der Faelligkeit -> Schuss im faelligen Schritt (Tick %d, erwartet 54)" % first_shot_tick)
	f.scope.free()
	# Weit vor der Faelligkeit nicht suchen: Ziel von Anfang an sichtbar, Schritte 1..27, nur Anlauf + Fenster + faellige Schritte.
	var g := _rig(_line(CENTER, CENTER + HEX.DIRECTIONS[0], "rocket", "none"))
	_run_ticks(g, 81)
	_check(g.driver.search_calls < 27 and g.driver.search_calls >= 5, "N1: Rakete sucht nicht in jedem Schritt (%d von 27)" % g.driver.search_calls)
	g.scope.free()


## n2: Wiederbeleben mit gleicher ID leert Anlauf und Kontaktmerker der Einheit.
func _test_respawn_clears_warm_state() -> void:
	var f := _rig(_line(CENTER, CENTER + HEX.DIRECTIONS[0], "pistol", "pistol"))
	f.driver._attack_warmed_ids["own"] = true
	f.driver._attack_contact_ids["own"] = true
	f.driver._attack_warmed_ids["enemy"] = true
	f.driver._on_unit_respawn_completed("own")
	_check(not f.driver._attack_warmed_ids.has("own") and not f.driver._attack_contact_ids.has("own"), "n2: Respawn leert Anlauf und Kontakt der Einheit")
	_check(f.driver._attack_warmed_ids.has("enemy"), "n2: andere Einheiten bleiben unberuehrt")
	f.scope.free()
