extends SceneTree
## G1: Sichtfehler im Gefecht.
## Regel A: Ein Ziel im Abstand <= 1 Feld liegt immer im Sichtbogen (Nachbar im Ruecken ist sichtbar).
## Regel D: Wer getroffen wird, weiss woher: Hat ein Schuetze die eigene Fireteam innerhalb von
##          RETURN_FIRE_WINDOW_TICKS GETROFFEN, gilt gegen ihn der Sichtbogen nicht (360 Grad).
##          Reichweite, Sichtlinie und Verdeckung gelten weiter. Beide Seiten gleich.
## Lauf nur ueber das isolierte Wegwerfprofil (Review2-Sperre).

const SIM = preload("res://scripts/core/simulation_root.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
const QUERY = preload("res://scripts/core/hex_visibility_query.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const COMMAND = preload("res://scripts/npc/unit_command.gd")

const WINDOW := 18
var passed := 0
var failed := 0


class NPC extends Node2D:
	var unit_id: String
	var team_id: String
	var active_weapon_id := "pistol"
	var is_fireteam_lead := false
	var hp := 100
	var command: RefCounted
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team_id
	func get_fireteam_id() -> String: return team_id + "_ft"
	func get_vital_state() -> String: return "fit"
	func get_health() -> int: return hp
	func get_awareness() -> float: return 1.0
	func get_active_weapon_id() -> String: return active_weapon_id
	func get_current_unit_command(): return command
	func get_stealth() -> float: return 0.0
	func get_discipline() -> float: return 0.0
	func get_fire_status() -> String: return String(command.get("fire_status")) if command != null else "fire_at_will"
	func show_event_text(_text: String, _color: Color, _duration: float) -> void: pass
	func apply_damage(amount: int, _context: Dictionary = {}) -> bool:
		hp -= amount
		return true


## Wie der echte Treiber (_ready verbindet damage_effect_resolved), aber ohne eigene Tick-Verarbeitung.
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
	_test_neighbor_always_visible_pure()
	_test_distance_two_and_three_stay_outside_arc()
	_test_hit_lifts_arc_for_both_sides()
	_test_hit_does_not_lift_range_or_blocker()
	_test_real_scenario_geometry()
	await process_frame
	print("COMBAT_REAR_VISIBILITY_RESULTS: passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _terrain_patch(center: Vector2i, radius: int) -> Node:
	var terrain = TERRAIN.new()
	terrain.name = "TerrainRegistry"
	terrain.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, "hex_axial_v1")
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var grid := center + Vector2i(dx, dy)
			terrain.register_tile(TILE.new({"tile_id": str(grid), "grid_position": grid,
				"world_position": terrain.grid_to_world(grid), "explicit_hex_ramps": true}))
	return terrain


# (a) Reine Abfrage und Cache-Abfrage: jeder Nachbar ist fuer jede Blickrichtung sichtbar.
func _test_neighbor_always_visible_pure() -> void:
	var center := Vector2i(10, 10)
	var terrain := _terrain_patch(center, 6)
	var cache = CACHE.new()
	cache.begin_tick(1)
	var profile := {"range_hex": 8, "arc_degrees": 120.0}
	for facing in range(6):
		var observer := {"grid": center, "facing_dir": facing, "stand_height_steps2": 0}
		for direction in range(6):
			var target := {"grid": center + HEX.DIRECTIONS[direction], "stand_height_steps2": 0}
			var pure: Dictionary = QUERY.evaluate(observer, target, terrain, profile)
			var cached: Dictionary = cache.query_hex_visibility(observer, target, terrain, profile)
			var behind: bool = direction == (facing + 3) % 6
			_check(bool(pure.visible), "a pure: Nachbar Richtung %d bei Blick %d%s sichtbar" % [direction, facing, " (im Ruecken)" if behind else ""])
			_check(cached == pure, "a cache gleich pure: Nachbar Richtung %d bei Blick %d" % [direction, facing])
	cache.free()
	terrain.free()


# (b) Flanke bleibt: Abstand 2 und 3 genau im Ruecken, kein Treffer.
func _test_distance_two_and_three_stay_outside_arc() -> void:
	var center := Vector2i(10, 10)
	var terrain := _terrain_patch(center, 6)
	var cache = CACHE.new()
	cache.begin_tick(1)
	var profile := {"range_hex": 8, "arc_degrees": 120.0}
	for facing in range(6):
		var observer := {"grid": center, "facing_dir": facing, "stand_height_steps2": 0}
		for steps in [2, 3]:
			var target := {"grid": center + HEX.DIRECTIONS[(facing + 3) % 6] * steps, "stand_height_steps2": 0}
			_check(String(QUERY.evaluate(observer, target, terrain, profile).reason) == "outside_arc", "b pure: Abstand %d im Ruecken bei Blick %d bleibt outside_arc" % [steps, facing])
			_check(String(cache.query_hex_visibility(observer, target, terrain, profile).reason) == "outside_arc", "b cache: Abstand %d im Ruecken bei Blick %d bleibt outside_arc" % [steps, facing])
	cache.free()
	terrain.free()


func _fixture(own_grid: Vector2i, own_facing: int, enemy_grid: Vector2i, enemy_facing: int, own_weapon: String, enemy_weapon: String) -> Dictionary:
	var scope := Node.new()
	scope.name = "RearVisibilityFixture"
	root.add_child(scope)
	var terrain := _terrain_patch(own_grid, 8)
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
	var map = MAP.create_empty("rear_visibility_fixture", Vector2i(160, 80), Vector2.ZERO, 64, 32, 3, "hex_axial_v1")
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
	var own := NPC.new()
	own.name = "Own"
	own.unit_id = "own"
	own.team_id = "blue"
	own.active_weapon_id = own_weapon
	own.position = terrain.grid_to_world(own_grid)
	# Wie nach der Ankunft am Ziel: haltend, Waffen frei (Voraussetzung fuer is_engage_ready).
	own.command = COMMAND.new({"command_type": "hold_position", "fire_status": "fire_at_will", "fire_rule": "free"})
	scope.add_child(own)
	var enemy := NPC.new()
	enemy.name = "Enemy"
	enemy.unit_id = "enemy"
	enemy.team_id = "red"
	enemy.active_weapon_id = enemy_weapon
	enemy.position = terrain.grid_to_world(enemy_grid)
	scope.add_child(enemy)
	for unit in [own, enemy]:
		registry.register_unit(unit.unit_id, unit)
		sim.register_known_unit(unit.unit_id, unit)
	driver.friendly_unit_paths.assign([NodePath("../Own")])
	driver.enemy_unit_paths.assign([NodePath("../Enemy")])
	var placements: Array[Dictionary] = [{"unit_id": "own", "grid": own_grid, "facing_dir": own_facing},
		{"unit_id": "enemy", "grid": enemy_grid, "facing_dir": enemy_facing}]
	_check(bool(sim.admit_hex_ground_units(placements).get("ok", false)), "Fixture: Einheiten zugelassen")
	return {"scope": scope, "terrain": terrain, "registry": registry, "sim": sim, "cache": cache, "driver": driver, "own": own, "enemy": enemy}


func _tick(f: Dictionary) -> void:
	f.sim._physics_process(0.1)
	f.cache.begin_tick(f.sim.tick_counter)
	f.driver._current_tick = f.sim.tick_counter
	f.driver._advance_return_fire_windows()


## Echter Weg: Trefferwirkung ueber enqueue_effect und einen Root-Tick; der Treiber hoert damage_effect_resolved.
func _inject_shot(f: Dictionary, shooter_id: String, victim_id: String, hit: bool) -> void:
	var shooter = f.own if shooter_id == "own" else f.enemy
	f.sim.enqueue_effect({"effect_type": "damage", "unit_id": victim_id, "attacker_unit_id": shooter_id,
		"attacker_team_id": shooter.team_id, "weapon_id": "pistol", "damage": 18, "hit_chance": 1.0,
		"damage_multiplier": 1.0, "target_cover_override": 0.0, "roll_override": 0.0 if hit else 0.99})
	_tick(f)


func _sees(f: Dictionary, observer_id: String) -> Dictionary:
	var observer = f.own if observer_id == "own" else f.enemy
	var target = f.enemy if observer_id == "own" else f.own
	return f.driver._query_current_visibility(observer, target, 1000.0)


# (c)/(d) Abstand 3 im Ruecken: Treffer macht den Schuetzen sichtbar, nach dem Fenster nicht mehr.
func _test_hit_lifts_arc_for_both_sides() -> void:
	for victim_id in ["own", "enemy"]:
		var shooter_id := "enemy" if victim_id == "own" else "own"
		var victim_grid := Vector2i(20, 20)
		var shooter_grid: Vector2i = victim_grid + HEX.DIRECTIONS[3] * 3
		# Opfer schaut nach Osten (Richtung 0), der Schuetze steht im Westen (im Ruecken), schaut zum Opfer.
		var own_grid: Vector2i = victim_grid if victim_id == "own" else shooter_grid
		var enemy_grid: Vector2i = shooter_grid if victim_id == "own" else victim_grid
		# Beide schauen nach Osten (Richtung 0): das Opfer steht im Osten, der Schuetze 3 Felder hinter ihm.
		var f := _fixture(own_grid, 0, enemy_grid, 0,
			"pistol" if victim_id == "own" else "none", "pistol" if victim_id == "enemy" else "none")
		var tag := "Opfer %s" % victim_id
		var before: Dictionary = _sees(f, victim_id)
		_check(String(before.get("reason", "")) == "outside_arc" and not bool(before.get("visible", true)), "%s: vorher outside_arc (%s)" % [tag, before.get("reason", "")])
		_check(f.driver._find_first_contact_pair().is_empty() or String(f.driver._find_first_contact_pair().get("attacker_id", "")) != victim_id, "%s: vorher kein Gegenschuss-Paar des Opfers" % tag)
		# Fehlschuss hebt den Bogen nicht auf.
		_inject_shot(f, shooter_id, victim_id, false)
		_check(String(_sees(f, victim_id).get("reason", "")) == "outside_arc", "%s: Fehlschuss hebt den Sichtbogen nicht auf" % tag)
		# Treffer
		_inject_shot(f, shooter_id, victim_id, true)
		var during: Dictionary = _sees(f, victim_id)
		_check(bool(during.get("visible", false)), "%s: nach Treffer sichtbar (%s)" % [tag, during.get("reason", "")])
		var pair: Dictionary = f.driver._find_first_contact_pair()
		_check(String(pair.get("attacker_id", "")) == victim_id and String(pair.get("target_id", "")) == shooter_id, "%s: Gegenschuss-Paar vorhanden (%s)" % [tag, pair.get("attacker_id", "")])
		var effects_before: int = f.sim.effects_queue.size()
		f.driver._try_enqueue_attacks(f.sim)
		var returned := false
		for effect in f.sim.effects_queue:
			if String(effect.get("attacker_unit_id", "")) == victim_id and String(effect.get("unit_id", "")) == shooter_id:
				returned = true
		_check(f.sim.effects_queue.size() > effects_before and returned, "%s: es faellt ein Gegenschuss" % tag)
		# Fenster laeuft ab (kein neuer Treffer).
		f.sim.effects_queue.clear()
		# Gefechtstakt: das Fenster ist je Einheit max(18, ceil(p) x 3 + 18) Ticks (Takt des Opfers), nicht mehr fest 18.
		for step in range(int(f.driver._get_return_fire_window_ticks(f.driver._resolve_unit_by_id(victim_id))) + 2):
			_tick(f)
		var after: Dictionary = _sees(f, victim_id)
		_check(String(after.get("reason", "")) == "outside_arc" and not bool(after.get("visible", true)), "%s: nach dem Fenster wieder outside_arc (%s)" % [tag, after.get("reason", "")])
		# Der Schuetze hatte nie einen Treffer erlitten: Er selbst sieht das Opfer vorne ohnehin (Blick Osten, Opfer im Osten bzw. Westen).
		f.scope.free()


# (e) Treffer aus dem Ruecken hebt Reichweite und Verdeckung nicht auf.
func _test_hit_does_not_lift_range_or_blocker() -> void:
	var victim_grid := Vector2i(20, 20)
	var shooter_grid: Vector2i = victim_grid + HEX.DIRECTIONS[3] * 3
	var f := _fixture(victim_grid, 0, shooter_grid, 0, "pistol", "none")
	_inject_shot(f, "enemy", "own", true)
	_check(bool(_sees(f, "own").get("visible", false)), "e: Grundlage - nach Treffer sichtbar")
	var spacing: float = float(f.terrain.get_movement_distance(f.terrain.grid_to_world(Vector2i.ZERO), f.terrain.grid_to_world(Vector2i(1, 0))))
	var short_range: Dictionary = f.driver._query_current_visibility(f.own, f.enemy, spacing * 2.0)
	_check(String(short_range.get("reason", "")) == "out_of_range" and not bool(short_range.get("visible", true)), "e: Schuetze ausser Reichweite bleibt unsichtbar (%s)" % short_range.get("reason", ""))
	f.terrain.set_runtime_tile_overrides([{"grid_position": victim_grid + HEX.DIRECTIONS[3], "blocks_los_override": true, "object_height_override": 2}])
	var blocked: Dictionary = _sees(f, "own")
	_check(String(blocked.get("reason", "")) == "terrain_blocked" and not bool(blocked.get("visible", true)), "e: Schuetze hinter Sichtblocker bleibt unsichtbar (%s)" % blocked.get("reason", ""))
	f.terrain.clear_runtime_tile_overrides()
	f.scope.free()


# (f) Der echte Fall aus Auftrag 2: Fuehrer auf (106,36), Blick 5, Wache auf (105,36). Die Wache liegt im Nachbarfeld.
func _test_real_scenario_geometry() -> void:
	var leader_grid := Vector2i(106, 36)
	var guard_grid := Vector2i(105, 36)
	var f := _fixture(leader_grid, 5, guard_grid, 0, "pistol", "pistol")
	var sees: Dictionary = _sees(f, "own")
	_check(bool(sees.get("visible", false)), "f: Fuehrer (106,36) Blick 5 sieht die Wache auf (105,36) (%s)" % sees.get("reason", ""))
	var pair: Dictionary = f.driver._find_first_contact_pair()
	_check(String(pair.get("attacker_id", "")) == "own" and String(pair.get("target_id", "")) == "enemy", "f: Kontaktpaar ist Fuehrer gegen Wache (%s)" % pair.get("attacker_id", ""))
	_tick(f)  # der Schussplatz des Treibers oeffnet ab Tick 1
	var effects_before: int = f.sim.effects_queue.size()
	f.driver._try_enqueue_attacks(f.sim)
	var leader_fired := false
	for effect in f.sim.effects_queue:
		if String(effect.get("attacker_unit_id", "")) == "own" and String(effect.get("unit_id", "")) == "enemy":
			leader_fired = true
	_check(f.sim.effects_queue.size() > effects_before and leader_fired, "f: der Fuehrer schiesst")
	f.scope.free()
