extends SceneTree

const LINE_OF_SIGHT_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_136 2.5D LOS und Cover Heights Verifier ===")
	_test_low_cover_does_not_block_los()
	_test_high_blocker_blocks_los_with_debug_snapshot()
	_test_elevated_source_sees_over_mid_blocker()
	_test_cover_height_and_relative_height_modify_cover_score()
	_test_damage_context_contains_cover_height_profile()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_low_cover_does_not_block_los() -> void:
	var registry = _make_line_registry(0.6)
	var los_system = LINE_OF_SIGHT_SYSTEM_SCRIPT.new()
	var source_position: Vector2 = registry.grid_to_world(Vector2i(0, 0))
	var target_position: Vector2 = registry.grid_to_world(Vector2i(2, 0))
	var snapshot: Dictionary = Dictionary(los_system.call("get_line_of_sight_snapshot", source_position, target_position, registry, 999.0))
	_assert(bool(snapshot.get("has_line_of_sight", false)), "Low cover does not automatically block LOS")
	_assert(Dictionary(Array(snapshot.get("samples", []))[0]).has("sight_height"), "LOS snapshot exposes sight height samples")
	registry.free()


func _test_high_blocker_blocks_los_with_debug_snapshot() -> void:
	var registry = _make_line_registry(2.6)
	var los_system = LINE_OF_SIGHT_SYSTEM_SCRIPT.new()
	var source_position: Vector2 = registry.grid_to_world(Vector2i(0, 0))
	var target_position: Vector2 = registry.grid_to_world(Vector2i(2, 0))
	var snapshot: Dictionary = Dictionary(los_system.call("get_line_of_sight_snapshot", source_position, target_position, registry, 999.0))
	_assert(not bool(snapshot.get("has_line_of_sight", true)), "High blocker interrupts height-aware LOS")
	_assert(Vector2i(snapshot.get("blocking_grid", Vector2i.ZERO)) == Vector2i(1, 0), "LOS snapshot reports blocking grid")
	_assert(float(snapshot.get("blocking_height", 0.0)) > float(snapshot.get("sight_height_at_blocker", 99.0)), "LOS snapshot reports blocker and sight heights")
	registry.free()


func _test_elevated_source_sees_over_mid_blocker() -> void:
	var ground_registry = _make_line_registry(1.6)
	var elevated_registry = _make_line_registry(1.6, 2.0, 0.0)
	var los_system = LINE_OF_SIGHT_SYSTEM_SCRIPT.new()
	var ground_source: Vector2 = ground_registry.grid_to_world(Vector2i(0, 0))
	var ground_target: Vector2 = ground_registry.grid_to_world(Vector2i(2, 0))
	var elevated_source: Vector2 = elevated_registry.grid_to_world(Vector2i(0, 0))
	var elevated_target: Vector2 = elevated_registry.grid_to_world(Vector2i(2, 0))
	var ground_snapshot: Dictionary = Dictionary(los_system.call("get_line_of_sight_snapshot", ground_source, ground_target, ground_registry, 999.0))
	var elevated_snapshot: Dictionary = Dictionary(los_system.call("get_line_of_sight_snapshot", elevated_source, elevated_target, elevated_registry, 999.0))
	_assert(not bool(ground_snapshot.get("has_line_of_sight", true)), "Mid blocker can block same-level ground LOS")
	_assert(bool(elevated_snapshot.get("has_line_of_sight", false)), "Elevated source can see over the same mid blocker")
	_assert(float(elevated_snapshot.get("source_eye_height", 0.0)) > float(ground_snapshot.get("source_eye_height", 0.0)), "LOS snapshot exposes elevated eye height")
	ground_registry.free()
	elevated_registry.free()


func _test_cover_height_and_relative_height_modify_cover_score() -> void:
	var context: Dictionary = _make_combat_context(0.6, 0.0, 0.0)
	var simulation_root = context["simulation_root"]
	var attacker = context["attacker"]
	var target = context["target"]
	var low_profile: Dictionary = Dictionary(simulation_root.call("_build_terrain_cover_height_profile", target, attacker))
	_cleanup_context(context)

	context = _make_combat_context(2.0, 0.0, 0.0)
	simulation_root = context["simulation_root"]
	attacker = context["attacker"]
	target = context["target"]
	var high_profile: Dictionary = Dictionary(simulation_root.call("_build_terrain_cover_height_profile", target, attacker))
	_cleanup_context(context)

	context = _make_combat_context(2.0, 2.0, 0.0)
	simulation_root = context["simulation_root"]
	attacker = context["attacker"]
	target = context["target"]
	var elevated_attacker_profile: Dictionary = Dictionary(simulation_root.call("_build_terrain_cover_height_profile", target, attacker))
	_cleanup_context(context)

	_assert(float(low_profile.get("effective_cover_score", 0.0)) < float(high_profile.get("effective_cover_score", 0.0)), "Cover height increases effective terrain cover")
	_assert(float(elevated_attacker_profile.get("effective_cover_score", 99.0)) < float(high_profile.get("effective_cover_score", 0.0)), "Attacker height advantage reduces target cover")
	_assert(elevated_attacker_profile.has("cover_height_factor") and elevated_attacker_profile.has("height_factor"), "Cover profile exposes cover-height and relative-height factors")


func _test_damage_context_contains_cover_height_profile() -> void:
	var context: Dictionary = _make_combat_context(2.0, 2.0, 0.0)
	var simulation_root = context["simulation_root"]
	var target = context["target"]
	simulation_root.call("_process_effects", [{
		"effect_type": "damage",
		"unit_id": "target",
		"attacker_unit_id": "attacker",
		"attacker_team_id": "team_alpha",
		"allow_friendly_fire": true,
		"damage": 10,
		"hit_chance": 1.0,
		"damage_multiplier": 1.0,
		"roll_override": 0.0,
		"priority": 1,
	}], 0.0)
	var hit_context: Dictionary = Dictionary(target.call("get_last_damage_context"))
	var cover_profile: Dictionary = Dictionary(hit_context.get("target_cover_profile", {}))
	_assert(hit_context.has("target_cover_score"), "Damage hit context keeps target cover score")
	_assert(not cover_profile.is_empty(), "Damage hit context includes cover height profile")
	_assert(float(cover_profile.get("attacker_height_advantage", 0.0)) > 0.0, "Damage cover profile records attacker height advantage")
	_cleanup_context(context)


func _make_line_registry(blocker_height: float, source_floor_height: float = 0.0, target_floor_height: float = 0.0):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(3):
		var grid_position := Vector2i(x, 0)
		var floor_height: float = source_floor_height if x == 0 else target_floor_height if x == 2 else 0.0
		registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
			"tile_id": "line_%d" % x,
			"type_id": "ground_flat",
			"grid_position": grid_position,
			"world_position": registry.grid_to_world(grid_position),
			"walkable": true,
			"floor_height": floor_height,
			"is_elevated_surface": floor_height > 0.0,
			"blocks_los": x == 1,
			"blocks_los_height": blocker_height if x == 1 else 0.0,
			"cover_value": 50 if x == 1 else 0,
			"cover_height": blocker_height if x == 1 else 0.0,
		}))
	return registry


func _make_combat_context(target_cover_height: float, attacker_floor_height: float, target_floor_height: float) -> Dictionary:
	var scene = Node.new()
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var terrain_registry = TERRAIN_REGISTRY_SCRIPT.new()
	terrain_registry.name = "TerrainRegistry"
	terrain_registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	scene.add_child(terrain_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	scene.add_child(simulation_root)
	var attacker = _make_unit("attacker", "team_alpha", terrain_registry.grid_to_world(Vector2i(0, 0)))
	var target = _make_unit("target", "team_bravo", terrain_registry.grid_to_world(Vector2i(1, 0)))
	scene.add_child(attacker)
	scene.add_child(target)
	unit_registry.register_unit("attacker", attacker)
	unit_registry.register_unit("target", target)
	terrain_registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "attacker_tile",
		"type_id": "ground_flat",
		"grid_position": Vector2i(0, 0),
		"world_position": terrain_registry.grid_to_world(Vector2i(0, 0)),
		"walkable": true,
		"floor_height": attacker_floor_height,
		"is_elevated_surface": attacker_floor_height > 0.0,
	}))
	terrain_registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "target_tile",
		"type_id": "cover_tile",
		"grid_position": Vector2i(1, 0),
		"world_position": terrain_registry.grid_to_world(Vector2i(1, 0)),
		"walkable": true,
		"floor_height": target_floor_height,
		"is_elevated_surface": target_floor_height > 0.0,
		"cover_value": 60,
		"cover_height": target_cover_height,
		"blocks_los": target_cover_height >= 2.0,
		"blocks_los_height": target_cover_height,
	}))
	return {
		"scene": scene,
		"unit_registry": unit_registry,
		"terrain_registry": terrain_registry,
		"simulation_root": simulation_root,
		"attacker": attacker,
		"target": target,
	}


func _make_unit(unit_id: String, team_id: String, world_position: Vector2):
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.global_position = world_position
	return unit


func _cleanup_context(context: Dictionary) -> void:
	var scene = context.get("scene", null)
	if scene != null:
		scene.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
