extends SceneTree
## Selection equivalence against the pre-cache loop, using the real scorer,
## weapon ranges and terrain LOS. Synthetic probes never start a mission.
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
var passed := 0
var failed := 0
var cases: Array = []


class ProbeUnit extends Node2D:
	var unit_id := ""
	var weapon_id := "rifle"
	func get_unit_id() -> String:
		return unit_id
	func get_active_weapon_id() -> String:
		return weapon_id


class CandidateRegistry extends "res://scripts/terrain/terrain_registry.gd":
	var candidates: Array = []
	func get_walkable_cover_tiles_in_radius(_center: Vector2, _radius: float) -> Array:
		return candidates.duplicate()


class CountingDriver extends "res://scripts/tests/mission_combat_loop_driver.gd":
	var fixture_registry: Node
	var real_los = preload("res://scripts/core/los_system.gd").new()
	var score_calls := 0
	var calls_by_pair: Dictionary = {}
	var scores_by_pair: Dictionary = {}
	func _get_terrain_registry():
		return fixture_registry
	func _get_combat_visibility_system():
		return real_los
	func _score_enemy_cover_tile(unit, tile, focus_position: Vector2) -> float:
		var key := "%s:%s" % [unit.get_unit_id(), tile.get_instance_id() if tile != null else 0]
		score_calls += 1
		calls_by_pair[key] = int(calls_by_pair.get(key, 0)) + 1
		var score: float = super._score_enemy_cover_tile(unit, tile, focus_position)
		scores_by_pair[key] = score
		return score
	func reset_counts() -> void:
		score_calls = 0
		calls_by_pair.clear()
		scores_by_pair.clear()
	func legacy_targets(units: Array, focus_position: Vector2, claimed_targets: Array) -> Dictionary:
		# The old selection loop: score repeatedly inside comparator and threshold.
		var targets: Dictionary = {}
		for unit in units:
			if unit == null or not (unit is Node2D) or not unit.has_method("get_unit_id"):
				continue
			var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
			if unit_id.is_empty():
				continue
			var candidates: Array = fixture_registry.call("get_walkable_cover_tiles_in_radius", unit.global_position, ENEMY_TACTICS_COVER_SEARCH_RADIUS)
			candidates.sort_custom(func(a, b) -> bool:
				return _score_enemy_cover_tile(unit, a, focus_position) > _score_enemy_cover_tile(unit, b, focus_position)
			)
			for tile in candidates:
				if tile == null or typeof(tile.world_position) != TYPE_VECTOR2:
					continue
				var position: Vector2 = tile.world_position
				if not _is_enemy_tactic_slot_available(position, claimed_targets):
					continue
				if _score_enemy_cover_tile(unit, tile, focus_position) <= -999.0:
					continue
				targets[unit_id] = position
				claimed_targets.append(position)
				break
		return targets


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)


func _unit(id: String, position: Vector2, host: Node) -> ProbeUnit:
	var unit := ProbeUnit.new()
	unit.unit_id = id
	host.add_child(unit)
	unit.global_position = position
	return unit


func _compare(label: String, driver: CountingDriver, units: Array, focus: Vector2, initial_claims: Array = []) -> Dictionary:
	driver.reset_counts()
	var legacy_claims := initial_claims.duplicate()
	var legacy: Dictionary = driver.legacy_targets(units, focus, legacy_claims)
	var legacy_calls := driver.score_calls
	var legacy_scores := driver.scores_by_pair.duplicate()
	driver.reset_counts()
	var cached_claims := initial_claims.duplicate()
	var cached: Dictionary = driver._build_enemy_cover_slot_targets(units, focus, cached_claims)
	check(cached == legacy and cached.keys() == legacy.keys(), label + ": identical selected targets and unit order")
	check(cached_claims == legacy_claims, label + ": identical claimed-slot/tie selection order")
	check(driver.scores_by_pair == legacy_scores, label + ": identical actual scorer results and first-read set")
	var once := true
	for count in driver.calls_by_pair.values():
		once = once and int(count) == 1
	check(once and driver.score_calls <= legacy_calls, label + ": every requested unit/tile score computed at most once")
	var result := {"case": label, "legacy_calls": legacy_calls, "cached_calls": driver.score_calls, "selected_count": cached.size()}
	cases.append(result)
	print("COVER_SCORE_CACHE_CASE ", JSON.stringify(result))
	return result


func _fixture() -> CandidateRegistry:
	var registry := CandidateRegistry.new()
	registry.configure_iso_grid(Vector2.ZERO, 16.0, 8.0, "hex_axial_v1")
	for q in range(35):
		for r in range(9):
			var grid := Vector2i(q, r)
			registry.register_tile(TILE.from_dict({"tile_id": "probe_%d_%d" % [q, r], "type_id": "ground_flat", "grid_position": grid, "world_position": registry.grid_to_world(grid), "walkable": true, "blocks_los": false}))
	for grid in [Vector2i(2, 3), Vector2i(3, 5), Vector2i(5, 4), Vector2i(5, 3), Vector2i(7, 2), Vector2i(8, 5), Vector2i(10, 2), Vector2i(11, 5), Vector2i(12, 6)]:
		var tile = registry.get_tile_at_grid(grid)
		tile.cover_value = 30 + registry.candidates.size() * 6
		registry.candidates.append(tile)
	registry.get_tile_at_grid(Vector2i(5, 3)).height_level = 1
	var wall = registry.get_tile_at_grid(Vector2i(14, 4))
	wall.walkable = false
	wall.blocks_los = true
	wall.object_height = 3
	return registry


func run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var driver := CountingDriver.new() # Outside tree: no mission _ready side effects.
	var registry := _fixture()
	driver.fixture_registry = registry
	var focus: Vector2 = registry.grid_to_world(Vector2i(20, 4))
	var first := _unit("first", registry.grid_to_world(Vector2i(5, 4)), host)
	var second := _unit("second", registry.grid_to_world(Vector2i(6, 4)), host)
	var third := _unit("third", registry.grid_to_world(Vector2i(7, 4)), host)
	var blocked = registry.get_tile_at_grid(Vector2i(5, 4))
	check(driver._score_enemy_cover_tile(first, blocked, focus) == -1000.0, "Fixture contains an actual LOS-blocked candidate")
	var first_case := _compare("Hex LOS and mixed cover", driver, [first, second, third], focus)
	check(int(first_case["cached_calls"]) < int(first_case["legacy_calls"]), "Real comparator repeats are removed without lowering candidate count")
	_compare("Several occupied cover slots", driver, [first, second, third], focus, [registry.candidates[7].world_position, registry.candidates[8].world_position])
	first.weapon_id = "smg"
	check(driver._score_enemy_cover_tile(first, registry.candidates[0], focus) == -1000.0, "Fixture contains an actual weapon-range rejection")
	_compare("Per-unit changed weapon/range", driver, [first, second, third], focus)
	first.global_position = registry.grid_to_world(Vector2i(10, 6))
	_compare("Same invocation inputs after unit movement", driver, [first, second], focus)
	registry.candidates[8].cover_value = 5
	registry.candidates[7].height_level = 1
	_compare("Changed cover and height before next call", driver, [first, second], focus)
	registry.get_tile_at_grid(Vector2i(14, 4)).blocks_los = false
	check(driver._score_enemy_cover_tile(second, blocked, focus) > -999.0, "Fixture opens the same formerly blocked LOS")
	_compare("Changed LOS before next call", driver, [first, second], focus)
	_compare("Changed focus before next call", driver, [first, second], registry.grid_to_world(Vector2i(8, 4)))
	var originals := registry.candidates.duplicate()
	var ties: Array = []
	for position in [Vector2(-20.0, 50.0), Vector2(20.0, 50.0)]:
		ties.append(TILE.from_dict({"tile_id": "tie_%d" % ties.size(), "type_id": "ground_flat", "grid_position": Vector2i(ties.size(), 3), "world_position": position, "walkable": true, "blocks_los": false, "cover_value": 50}))
	registry.candidates = ties
	first.global_position = Vector2.ZERO
	second.global_position = Vector2.ZERO
	first.weapon_id = "rifle"
	var tie_focus := Vector2(0.0, 100.0)
	check(driver._score_enemy_cover_tile(first, ties[0], tie_focus) == driver._score_enemy_cover_tile(first, ties[1], tie_focus), "Fixture contains an exact real-score tie")
	_compare("Exact ties and slot claiming", driver, [first, second, third], tie_focus)
	registry.candidates = [ties[0]]
	var single := _compare("One already claimed candidate", driver, [first], tie_focus, [ties[0].world_position])
	check(int(single["cached_calls"]) == 0 and int(single["legacy_calls"]) == 0, "Lazy memo adds no score/LOS call for an unavailable single slot")
	registry.candidates = []
	_compare("Empty candidate set", driver, [first], focus)
	registry.candidates = originals
	var map_sha := FileAccess.get_sha256("res://maps/Ground_Mission01_32x32.json")
	var data = MAP.load_from_file("res://maps/Ground_Mission01_32x32.json")
	var actual: Node = REGISTRY.new()
	var size: Dictionary = data.get_tile_size()
	actual.call("configure_iso_grid", data.get_grid_origin(), size["half_width"], size["half_height"], data.get_grid_topology())
	for tile in data.get_tiles():
		actual.call("register_tile", tile)
	driver.fixture_registry = actual
	first.global_position = data.get_marker_position("spawn_enemy_patrol")
	second.global_position = data.get_marker_position("spawn_enemy_defense")
	_compare("Regular saved GM01 cover candidates", driver, [first, second], data.get_marker_position("objective_point"))
	check(FileAccess.get_sha256("res://maps/Ground_Mission01_32x32.json") == map_sha, "Reference/cache checks never change the actual map")
	driver.free()
	actual.free()
	registry.free()
	host.queue_free()
	await process_frame
	print("COVER_SCORE_CACHE_SUMMARY ", JSON.stringify(cases))
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	print("GM01_FRONTIER_COVER_SCORE_CACHE_ALL_PASS" if failed == 0 else "GM01_FRONTIER_COVER_SCORE_CACHE_FAILED")
	quit(0 if failed == 0 else 1)
