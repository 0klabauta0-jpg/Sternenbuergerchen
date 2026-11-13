extends SceneTree
## C6/C7/C8 regressions. Run only through the isolated Review2 test runner.
const SIM = preload("res://scripts/core/simulation_root.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
const QUERY = preload("res://scripts/core/hex_visibility_query.gd")
const LOS = preload("res://scripts/core/los_system.gd")
const RESOLVER = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const COMMAND = preload("res://scripts/npc/unit_command.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
var passed := 0
var failed := 0

class NPC extends Node2D:
	var unit_id: String
	var team_id: String
	var active_weapon_id := "pistol"
	var is_fireteam_lead := false
	var awareness := 1.0
	var command: RefCounted
	var event_count := 0
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team_id
	func get_fireteam_id() -> String: return team_id + "_ft"
	func get_vital_state() -> String: return "fit"
	func get_health() -> int: return 100
	func get_awareness() -> float: return awareness
	func get_active_weapon_id() -> String: return active_weapon_id
	func get_current_unit_command(): return command
	func get_stealth() -> float: return 0.0
	func get_discipline() -> float: return 0.0
	func get_fire_status() -> String: return String(command.get("fire_status")) if command != null else "fire_at_will"
	func show_event_text(_text: String, _color: Color, _duration: float) -> void: event_count += 1

class QuietDriver extends DRIVER:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)

func _run() -> void:
	_test_half_height_occlusion()
	for direction in range(6): _test_ground_fire(direction)
	_test_legacy_fire()
	_test_diagnostic_purity()
	await process_frame
	print("ASTRA_HEX_COMBAT_FIXES passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _height_registry(height: float, blocker_top: int, topology: String) -> Node:
	var terrain = TERRAIN.new()
	terrain.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, topology)
	for x in range(3):
		terrain.register_tile(TILE.new({"tile_id": str(x), "grid_position": Vector2i(x, 0),
			"world_position": terrain.grid_to_world(Vector2i(x, 0)),
			"explicit_hex_ramps": topology == "hex_axial_v1",
			"height_level": floori(height) if x != 1 else 0,
			"ramp_direction": 0 if x != 1 and height != floorf(height) else -1,
			"blocks_los": x == 1, "object_height": blocker_top if x == 1 else 0}))
	return terrain

func _test_half_height_occlusion() -> void:
	for height in [2.0, 2.5, 3.0]:
		for blocker_top in [2, 3]:
			var terrain := _height_registry(height, blocker_top, "hex_axial_v1")
			var cache = CACHE.new()
			cache.begin_tick(1)
			for reverse in [false, true]:
				var start := Vector2i(2, 0) if reverse else Vector2i.ZERO
				var end := Vector2i.ZERO if reverse else Vector2i(2, 0)
				var actual_height: float = terrain.get_stand_height_at(start)
				_check(is_equal_approx(actual_height, height), "C6 real ramp stand height %s" % height)
				var observer := {"grid": start, "facing_dir": 3 if reverse else 0, "stand_height_steps2": roundi(actual_height * 2.0)}
				var target := {"grid": end, "stand_height_steps2": roundi(float(terrain.get_stand_height_at(end)) * 2.0)}
				var profile := {"range_hex": 3, "arc_degrees": 120.0}
				# Independent geometric oracle: both endpoints are above the blocker iff height > top.
				var expected: bool = height > float(blocker_top)
				_check(bool(QUERY.evaluate(observer, target, terrain, profile).visible) == expected, "C6 pure height=%s top=%s reverse=%s" % [height, blocker_top, reverse])
				_check(bool(cache.query_hex_visibility(observer, target, terrain, profile).visible) == expected, "C6 cache height=%s top=%s reverse=%s" % [height, blocker_top, reverse])
			cache.free()
			terrain.free()
	for height in [2.0, 3.0]:
		for blocker_top in [2, 3]:
			var terrain := _height_registry(height, blocker_top, "square8")
			for reverse in [false, true]:
				var start := Vector2i(2, 0) if reverse else Vector2i.ZERO
				var end := Vector2i.ZERO if reverse else Vector2i(2, 0)
				var blocker: Vector2i = LOS.new().find_first_blocker_grid(start, end, terrain)
				_check((blocker == LOS.NO_BLOCKER_GRID) == (height > float(blocker_top)), "C6 Square8 integer-height legacy remains unchanged")
			terrain.free()

func _fixture(direction: int, hex_active: bool = true) -> Dictionary:
	var scope := Node.new()
	scope.name = "AstraCombatFixture"
	root.add_child(scope)
	var terrain = TERRAIN.new()
	terrain.name = "TerrainRegistry"
	scope.add_child(terrain)
	var topology := "hex_axial_v1" if hex_active else "square8"
	terrain.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, topology)
	var grids: Dictionary = {Vector2i.ZERO: true}
	for axis in HEX.DIRECTIONS:
		for step in range(1, 11): grids[axis * step] = true
	for grid in grids:
		terrain.register_tile(TILE.new({"tile_id": str(grid), "grid_position": grid,
			"world_position": terrain.grid_to_world(grid), "explicit_hex_ramps": hex_active}))
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
	if hex_active:
		var map = MAP.create_empty("astra_hex_fixes", Vector2i(21, 21), Vector2.ZERO, 64, 32, 3, topology)
		map.set_tactical_grid_rules("hex_tactical_v1")
		map._extension_metadata["terrain_height_rules"] = "explicit_hex_ramps_v1"
		_check(bool(sim.configure_hex_ground_runtime(map, terrain).get("ok", false)), "C7 actual Ground owner configured")
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
	own.active_weapon_id = "none"
	own.position = terrain.grid_to_world(HEX.DIRECTIONS[direction] * 8)
	scope.add_child(own)
	var enemy := NPC.new()
	enemy.name = "Enemy"
	enemy.unit_id = "enemy"
	enemy.team_id = "red"
	enemy.position = terrain.grid_to_world(Vector2i.ZERO)
	scope.add_child(enemy)
	for unit in [own, enemy]:
		registry.register_unit(unit.unit_id, unit)
		sim.register_known_unit(unit.unit_id, unit)
	driver.friendly_unit_paths.assign([NodePath("../Own")])
	driver.enemy_unit_paths.assign([NodePath("../Enemy")])
	if hex_active:
		var placements: Array[Dictionary] = [{"unit_id": "own", "grid": HEX.DIRECTIONS[direction] * 8, "facing_dir": (direction + 3) % 6},
			{"unit_id": "enemy", "grid": Vector2i.ZERO, "facing_dir": direction}]
		_check(bool(sim.admit_hex_ground_units(placements).get("ok", false)), "C7 actual Root admission accepted")
	return {"scope": scope, "terrain": terrain, "registry": registry, "sim": sim, "cache": cache, "driver": driver, "own": own, "enemy": enemy}

func _tick(f: Dictionary) -> void:
	f.sim._physics_process(0.1)
	f.cache.begin_tick(f.sim.tick_counter)
	f.driver._current_tick = f.sim.tick_counter
	f.driver._advance_detection_timers()

func _face(f: Dictionary, direction: int, id: String) -> void:
	var result: Dictionary = f.sim.queue_hex_facing_intent("enemy", direction, id, "security_assignment")
	_check(bool(result.get("ok", false)), "C7 facing uses accepted Root intent")
	_tick(f)
	_check(int(f.sim.get_hex_unit_state("enemy").facing_dir) == direction, "C7 Root commits new facing")

func _test_ground_fire(direction: int) -> void:
	var f := _fixture(direction)
	var driver = f.driver
	var axis: Vector2i = HEX.DIRECTIONS[direction]
	_check(driver._get_detection_delay_ticks(f.enemy) == 0, "C7 zero-delay fixture")
	_check(String(driver._find_first_contact_pair().get("attacker_id", "")) == "enemy", "C7 valid front shot at pistol limit axis %d" % direction)
	f.own.position = Vector2(9000, -9000)
	f.enemy.position = Vector2(-9000, 9000)
	_check(driver._is_target_attackable(f.enemy, f.own), "C7 logical position ignores render drift axis %d" % direction)
	var readout: Dictionary = driver.build_cover_effectiveness_readout_for_units(f.enemy, f.own, "")
	var physical_distance: float = f.terrain.get_movement_distance(f.terrain.grid_to_world(Vector2i.ZERO), f.terrain.grid_to_world(axis * 8))
	_check(readout.range_state == "in_range" and is_equal_approx(float(readout.distance_world), physical_distance), "C7 diagnostic uses canonical range axis %d" % direction)
	_face(f, (direction + 3) % 6, "astra_rear_%d" % direction)
	_check(not driver._has_valid_los(f.enemy, f.own), "C7 contact rejects rear target")
	_check(driver._find_first_contact_pair().is_empty() and not driver._is_target_attackable(f.enemy, f.own), "C7 zero-delay actual fire selection rejects rear target")
	_check(f.sim.effects_queue.is_empty(), "C7 blocked selection queues no damage")
	_face(f, direction, "astra_front_%d" % direction)
	f.enemy.awareness = 0.8
	driver._detection_progress.clear()
	var delay: int = driver._get_detection_delay_ticks(f.enemy)
	_check(delay > 0 and driver._find_first_contact_pair().is_empty(), "C7 positive delay waits")
	for step in range(delay):
		_tick(f)
		var pair: Dictionary = driver._find_first_contact_pair()
		_check(pair.is_empty() if step < delay - 1 else String(pair.get("attacker_id", "")) == "enemy", "C7 detection deadline axis %d tick %d" % [direction, step])
	_face(f, (direction + 3) % 6, "astra_delayed_rear_%d" % direction)
	_check(driver._find_first_contact_pair().is_empty(), "C7 completed positive-delay detection does not authorize rear fire")
	_face(f, direction, "astra_delayed_front_%d" % direction)
	f.terrain.set_runtime_tile_overrides([{"grid_position": axis * 4, "blocks_los_override": true, "object_height_override": 2}])
	_check(not driver._is_target_attackable(f.enemy, f.own), "C7 same-tick blocker forbids firing")
	f.terrain.clear_runtime_tile_overrides()
	_check(driver._is_target_attackable(f.enemy, f.own), "C7 removing blocker restores valid shot")
	f.sim.release_hex_ground_unit("own", "astra_range")
	var placements: Array[Dictionary] = [{"unit_id": "own", "grid": axis * 9, "facing_dir": (direction + 3) % 6}]
	_check(bool(f.sim.admit_hex_ground_units(placements).get("ok", false)), "C7 range fixture readmitted")
	f.own.position = f.enemy.position + Vector2.ONE
	_check(not driver._is_target_attackable(f.enemy, f.own), "C7 physical range rejects ninth hex axis %d" % direction)
	f.sim.release_hex_ground_unit("own", "astra_unadmitted")
	_check(not driver._is_target_attackable(f.enemy, f.own), "C7 missing admission never falls back to nearby render position")
	f.scope.free()

func _test_legacy_fire() -> void:
	var f := _fixture(0, false)
	f.own.position = f.terrain.grid_to_world(Vector2i(1, 0))
	_check(not f.driver.get_hex_sight_adapter().is_active(), "C7 legacy does not activate Ground")
	_check(String(f.driver._find_first_contact_pair().get("attacker_id", "")) == "enemy", "C7 legacy valid fire remains available")
	f.own.position = f.terrain.grid_to_world(Vector2i(9, 0))
	_check(not f.driver._is_target_attackable(f.enemy, f.own), "C7 legacy range remains enforced")
	f.scope.free()

func _state_for_read(f: Dictionary) -> Dictionary:
	return {"cooldown": f.driver.get_discipline_break_cooldown().duplicate(true),
		"last_event": f.driver._last_event_text, "unit_events": f.own.event_count,
		"root_rng": f.sim._combat_rng.state, "tick": f.sim.tick_counter,
		"commands": f.sim.command_queue.duplicate(true), "effects": f.sim.effects_queue.duplicate(true),
		"ground": f.sim.get_hex_ground_planning_snapshot(), "ground_events": f.sim.get_hex_ground_events()}

func _test_diagnostic_purity() -> void:
	var f := _fixture(0)
	f.own.active_weapon_id = "pistol"
	f.own.command = COMMAND.new({"command_type": "hold_position", "fire_status": "hold_fire", "fire_rule": "return"})
	f.enemy.active_weapon_id = "none"
	# Produce the actual no-enemy published diagnostic, then register an arriving enemy.
	f.registry.unregister_unit("enemy")
	f.driver._try_enqueue_attacks(f.sim)
	_check(f.driver.get_contact_decision_diagnostics_snapshot().candidate.candidate_reason == "no_enemy_combat_units", "C8 real empty-presence diagnostic published")
	f.registry.register_unit("enemy", f.enemy)
	var selected_seed := -1
	var expected_roll := -1.0
	for candidate in range(1000):
		seed(candidate)
		var roll := randf()
		if roll < DRIVER.DISCIPLINE_BREAK_BASE_CHANCE:
			selected_seed = candidate
			expected_roll = roll
			break
	_check(selected_seed >= 0, "C8 seed triggers real discipline decision")
	seed(selected_seed)
	var before := _state_for_read(f)
	var context: Dictionary = f.driver._build_fire_decision_context()
	var pair := {"attacker": f.own, "target": f.enemy, "attacker_id": "own", "target_id": "enemy"}
	for iteration in range(4):
		var snapshot: Dictionary = f.driver.get_contact_decision_diagnostics_snapshot()
		_check(int(snapshot.active_enemy_count) == 1 and not bool(snapshot.candidate.attacker_ready), "C8 presence refresh stays read-only and does not invent return fire")
		f.driver.get_contact_decision_diagnostics_for_fireteams([])
		f.driver.get_contact_decision_diagnostics_for_fireteams(["blue_ft"])
		var diagnostic: Dictionary = f.driver._build_contact_pair_decision_diagnostic(pair)
		_check(diagnostic.attacker_fire_rule_outcome == "return_fire_wait", "C8 pair diagnostic waits without discipline roll")
		_check(not bool(RESOLVER.build_fire_rule_outcome_diagnostic(f.own, context).can_attack), "C8 default outcome diagnostic is pure too")
	_check(_state_for_read(f) == before, "C8 repeated public reads preserve cooldown, events, Root queues, RNG and Ground")
	_check(randf() == expected_roll, "C8 repeated reads preserve next global RNG value")
	seed(selected_seed)
	_check(f.driver._can_unit_attack(f.own), "C8 actual gameplay still rolls a permitted discipline break")
	_check(not f.driver.get_discipline_break_cooldown().is_empty() and f.own.event_count > int(before.unit_events), "C8 gameplay commits discipline cooldown and event")
	_check(not f.driver._can_unit_attack(f.own), "C8 gameplay discipline cooldown still prevents repeated break")
	var committed: Dictionary = f.driver._build_contact_pair_decision_diagnostic(pair, {"effect": {"weapon_id": "pistol"}})
	_check(bool(committed.fire_rule_outcome.can_attack), "C8 accepted effect remains reported as accepted after cooldown commit")
	f.driver._recent_incoming_fire_tick_by_fireteam["blue_ft"] = f.driver._current_tick
	_check(RESOLVER.can_unit_attack_for_readout(f.own, context), "C8 existing return-fire window remains readable")
	f.own.command = COMMAND.new({"command_type": "hold_position", "fire_status": "hold_fire", "fire_rule": "hold"})
	_check(not RESOLVER.can_unit_attack_for_readout(f.own, context), "C8 explicit hold remains held")
	f.own.command = COMMAND.new({"command_type": "hold_position", "fire_status": "fire_at_will", "fire_rule": "free"})
	_check(RESOLVER.can_unit_attack_for_readout(f.own, context), "C8 free fire remains ready")
	f.scope.free()
