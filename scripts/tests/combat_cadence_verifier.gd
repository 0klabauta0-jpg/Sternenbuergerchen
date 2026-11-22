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
	func get_awareness() -> float: return 1.0
	func get_active_weapon_id() -> String: return active_weapon_id
	func get_current_unit_command(): return command
	func get_stealth() -> float: return 0.0
	func get_discipline() -> float: return 0.0
	func get_fire_status() -> String: return String(command.get("fire_status")) if command != null else "fire_at_will"
	func show_event_text(_text: String, _color: Color, _duration: float) -> void: pass
	func get_character_profile_bundle() -> Dictionary:
		return {"behavior_axes": {"initiative": initiative}} if initiative >= 0.0 else {}
	func get_combat_hit_chance_multiplier() -> float:
		return hit_multiplier if hit_multiplier >= 0.0 else 1.0
	func apply_damage(amount: int, _context: Dictionary = {}) -> bool:
		hp -= amount
		return true


class QuietDriver extends DRIVER:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
		var simulation_root = get_node_or_null(simulation_root_path)
		if simulation_root != null:
			simulation_root.damage_effect_resolved.connect(_on_damage_effect_resolved)


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
	_test_simultaneous_kill()
	_test_fixed_order_independent_of_creation()
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
		npc.position = terrain.grid_to_world(spec.grid)
		if npc.team_id == "blue":
			npc.command = COMMAND.new({"command_type": "hold_position", "fire_status": "fire_at_will", "fire_rule": "free"})
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


## Laeuft `ticks` Ticks; an jedem 3. Tick entscheidet der Treiber. Gibt je Entscheidung die Schuetzen der Reihe nach zurueck
## (nur die in diesem Schritt neu eingereihten Schadenseffekte).
func _run_ticks(f: Dictionary, ticks: int) -> void:
	for i in range(ticks):
		_tick(f)
		if f.sim.tick_counter % 3 == 0:
			f.sim.effects_queue.clear()
			f.driver._try_enqueue_attacks(f.sim)
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
