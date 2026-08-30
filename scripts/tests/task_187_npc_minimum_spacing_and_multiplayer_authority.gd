extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const ENEMY_WAVE_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/enemy_wave_controller.gd")

const MIN_SPACING: float = 36.0

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_187 NPC Minimum Spacing and Multiplayer Authority ===")
	await _test_spawn_cluster_is_authoritatively_separated()
	await _test_dropship_deploy_uses_authoritative_spacing()
	await _test_enemy_wave_cluster_is_separated()
	await _test_crossing_units_keep_spacing_during_movement()
	await _test_contact_stop_and_downed_units_keep_space()
	await _test_respawn_and_snapshot_positions_are_separated()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_spawn_cluster_is_authoritatively_separated() -> void:
	var context: Dictionary = _make_context(true)
	var registry: Node = context["unit_registry"]
	var terrain_registry: Node = context["terrain_registry"]
	var simulation_root: Node = context["simulation_root"]
	var alpha = _add_unit(context, "unit_alpha", "team_alpha", "blue", terrain_registry.call("grid_to_world", Vector2i(2, 2)))
	var bravo = _add_unit(context, "unit_bravo", "team_alpha", "blue", alpha.global_position)
	registry.call("register_unit", alpha.get_unit_id(), alpha)
	registry.call("register_unit", bravo.get_unit_id(), bravo)

	simulation_root.call("_physics_process", 0.1)
	var debug_snapshot: Dictionary = Dictionary(simulation_root.call("get_unit_minimum_spacing_debug_snapshot"))
	_assert(_all_registered_units_keep_spacing(registry, MIN_SPACING), "Spawn cluster is separated by the authoritative SimulationRoot spacing pass")
	_assert(_all_registered_units_on_walkable_tiles(registry, terrain_registry), "Spawn separation keeps units on walkable terrain")
	_assert(int(debug_snapshot.get("blocked_pair_count", 0)) == 0, "Spawn separation resolves without blocked-pair fallback")
	_cleanup_context(context)


func _test_dropship_deploy_uses_authoritative_spacing() -> void:
	var context: Dictionary = _make_context(true)
	var registry: Node = context["unit_registry"]
	var terrain_registry: Node = context["terrain_registry"]
	var simulation_root: Node = context["simulation_root"]
	var alpha_position: Vector2 = terrain_registry.call("grid_to_world", Vector2i(2, 2))
	var alpha = _add_unit(context, "unit_alpha", "team_alpha", "blue", alpha_position)
	var bravo = _add_unit(context, "unit_bravo", "team_alpha", "blue", alpha_position)
	registry.call("register_unit", alpha.get_unit_id(), alpha)
	simulation_root.call("register_known_unit", alpha.get_unit_id(), alpha)
	simulation_root.call("register_known_unit", bravo.get_unit_id(), bravo)
	simulation_root.call("enqueue_effect", {
		"effect_type": "dropship_deploy_unit",
		"unit_id": bravo.get_unit_id(),
		"position": alpha_position,
		"runtime_active": true,
		"team_id": "team_alpha",
	})

	simulation_root.call("_physics_process", 0.1)
	_assert(registry.call("has_unit", bravo.get_unit_id()), "Dropship deploy registers the inserted friendly as runtime-active")
	_assert(_all_registered_units_keep_spacing(registry, MIN_SPACING), "Dropship deploy does not stack the inserted friendly on the existing unit")
	_assert(_all_registered_units_on_walkable_tiles(registry, terrain_registry), "Dropship deploy separation keeps units walkable")
	_cleanup_context(context)


func _test_enemy_wave_cluster_is_separated() -> void:
	var context: Dictionary = _make_context(true)
	var registry: Node = context["unit_registry"]
	var terrain_registry: Node = context["terrain_registry"]
	var simulation_root: Node = context["simulation_root"]
	var spawn_position: Vector2 = terrain_registry.call("grid_to_world", Vector2i(2, 2))
	var enemy_delta = _add_unit(context, "enemy_delta", "team_bravo", "", spawn_position)
	var enemy_echo = _add_unit(context, "enemy_echo", "team_bravo", "", spawn_position)
	var wave_controller = ENEMY_WAVE_CONTROLLER_SCRIPT.new()
	wave_controller.name = "EnemyWaveController"
	wave_controller.unit_registry_path = NodePath("../UnitRegistry")
	wave_controller.simulation_root_path = NodePath("../SimulationRoot")
	wave_controller.wave_count = 1
	wave_controller.units_per_wave = 2
	wave_controller.first_wave_delay_seconds = 999.0
	context["scene"].add_child(wave_controller)
	wave_controller.call("initialize_enemy_units", [enemy_delta, enemy_echo])
	wave_controller.call("_start_next_wave")

	simulation_root.call("_physics_process", 0.1)
	_assert(_arrays_equal(_get_registry_unit_ids(registry), ["enemy_delta", "enemy_echo"]), "Enemy wave registers exactly the active wave units")
	_assert(_all_registered_units_keep_spacing(registry, MIN_SPACING), "Enemy wave cluster is separated by the authoritative spacing pass")
	_assert(_all_registered_units_on_walkable_tiles(registry, terrain_registry), "Enemy wave separation keeps enemies on walkable terrain")
	_cleanup_context(context)


func _test_crossing_units_keep_spacing_during_movement() -> void:
	var context: Dictionary = _make_context(false)
	var registry: Node = context["unit_registry"]
	var simulation_root: Node = context["simulation_root"]
	var alpha = _add_unit(context, "unit_alpha", "team_alpha", "blue", Vector2(-90.0, 0.0))
	var bravo = _add_unit(context, "unit_bravo", "team_alpha", "gold", Vector2(90.0, 0.0))
	registry.call("register_unit", alpha.get_unit_id(), alpha)
	registry.call("register_unit", bravo.get_unit_id(), bravo)
	simulation_root.local_avoidance_enabled = true
	simulation_root.local_avoidance_debug_enabled = true
	simulation_root.call("enqueue_command", _move_command(alpha.get_unit_id(), Vector2(90.0, 0.0)))
	simulation_root.call("enqueue_command", _move_command(bravo.get_unit_id(), Vector2(-90.0, 0.0)))
	var minimum_observed_distance: float = INF
	for _tick in range(12):
		simulation_root.call("_physics_process", 0.1)
		minimum_observed_distance = minf(minimum_observed_distance, alpha.global_position.distance_to(bravo.global_position))
	var debug_snapshot: Dictionary = Dictionary(simulation_root.call("get_local_avoidance_debug_snapshot", alpha.get_unit_id()))
	_assert(minimum_observed_distance >= MIN_SPACING - 0.01, "Crossing friendly units keep minimum distance during movement")
	_assert(int(debug_snapshot.get("neighbor_count", 0)) > 0, "Movement pass still uses LocalAvoidance neighbor diagnostics")
	_cleanup_context(context)


func _test_contact_stop_and_downed_units_keep_space() -> void:
	var context: Dictionary = _make_context(false)
	var registry: Node = context["unit_registry"]
	var simulation_root: Node = context["simulation_root"]
	var friendly = _add_unit(context, "unit_alpha", "team_alpha", "blue", Vector2.ZERO)
	var enemy = _add_unit(context, "enemy_delta", "team_bravo", "", Vector2.ZERO)
	var downed = _add_unit(context, "unit_down", "team_alpha", "blue", Vector2(12.0, 0.0))
	downed.call("apply_damage", 999, {})
	registry.call("register_unit", friendly.get_unit_id(), friendly)
	registry.call("register_unit", enemy.get_unit_id(), enemy)
	registry.call("register_unit", downed.get_unit_id(), downed)
	simulation_root.call("_physics_process", 0.1)
	var debug_snapshot: Dictionary = Dictionary(simulation_root.call("get_unit_minimum_spacing_debug_snapshot"))
	_assert(_all_registered_units_keep_spacing(registry, MIN_SPACING), "Friendly/enemy contact stop and downed units do not stack")
	_assert(bool(debug_snapshot.get("downed_units_keep_space", false)), "Minimum-spacing contract documents downed units as space-occupying")
	_cleanup_context(context)


func _test_respawn_and_snapshot_positions_are_separated() -> void:
	var context: Dictionary = _make_context(true)
	var registry: Node = context["unit_registry"]
	var terrain_registry: Node = context["terrain_registry"]
	var simulation_root: Node = context["simulation_root"]
	var spawn_position: Vector2 = terrain_registry.call("grid_to_world", Vector2i(2, 2))
	var alpha = _add_unit(context, "unit_alpha", "team_alpha", "blue", spawn_position)
	var bravo = _add_unit(context, "unit_bravo", "team_alpha", "blue", spawn_position)
	bravo.call("apply_damage", 999, {})
	registry.call("register_unit", alpha.get_unit_id(), alpha)
	registry.call("register_unit", bravo.get_unit_id(), bravo)
	simulation_root.call("enqueue_effect", {
		"effect_type": "respawn",
		"unit_id": bravo.get_unit_id(),
		"spawn_position": spawn_position,
	})
	simulation_root.call("_physics_process", 0.1)
	var snapshot: Dictionary = Dictionary(simulation_root.call("build_multiplayer_snapshot"))
	_assert(_all_registered_units_keep_spacing(registry, MIN_SPACING), "Respawn position is separated before the authority tick ends")
	_assert(_all_registered_units_on_walkable_tiles(registry, terrain_registry), "Respawn separation keeps units on walkable terrain")
	_assert(_snapshot_units_keep_spacing(Array(snapshot.get("units", [])), MIN_SPACING), "Multiplayer snapshot contains already-separated authoritative positions")
	_cleanup_context(context)


func _make_context(with_terrain: bool) -> Dictionary:
	var scene := Node.new()
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var terrain_registry = null
	if with_terrain:
		terrain_registry = TERRAIN_REGISTRY_SCRIPT.new()
		terrain_registry.name = "TerrainRegistry"
		terrain_registry.call("configure_iso_grid", Vector2.ZERO, 64.0, 32.0)
		for x in range(0, 5):
			for y in range(0, 5):
				var grid := Vector2i(x, y)
				terrain_registry.call("register_tile", TERRAIN_TILE_DATA_SCRIPT.new({
					"tile_id": "%d_%d" % [grid.x, grid.y],
					"type_id": "ground_flat",
					"grid_position": grid,
					"world_position": terrain_registry.call("grid_to_world", grid),
					"walkable": true,
					"surface_type": "ground",
				}))
		scene.add_child(terrain_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.unit_minimum_spacing_enabled = true
	simulation_root.unit_minimum_spacing_distance = MIN_SPACING
	simulation_root.unit_minimum_spacing_debug_enabled = true
	if with_terrain:
		simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	scene.add_child(simulation_root)
	return {
		"scene": scene,
		"unit_registry": unit_registry,
		"terrain_registry": terrain_registry,
		"simulation_root": simulation_root,
	}


func _add_unit(context: Dictionary, unit_id: String, team_id: String, fireteam_id: String, position: Vector2):
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.global_position = position
	context["scene"].add_child(unit)
	var simulation_root: Node = context["simulation_root"]
	simulation_root.call("register_known_unit", unit_id, unit)
	return unit


func _move_command(unit_id: String, target_position: Vector2) -> Dictionary:
	return {
		"command_type": "move_to_position",
		"unit_id": unit_id,
		"team_id": "team_alpha",
		"target_position": target_position,
		"move_speed_factor": 1.0,
		"local_avoidance_enabled": true,
		"requeue_until_target": true,
	}


func _all_registered_units_keep_spacing(unit_registry: Node, minimum_distance: float) -> bool:
	var units: Array = Array(unit_registry.call("get_all_units"))
	for index_a in range(units.size()):
		for index_b in range(index_a + 1, units.size()):
			var unit_a := units[index_a] as Node2D
			var unit_b := units[index_b] as Node2D
			if unit_a == null or unit_b == null:
				continue
			if unit_a.global_position.distance_to(unit_b.global_position) < minimum_distance - 0.01:
				return false
	return true


func _all_registered_units_on_walkable_tiles(unit_registry: Node, terrain_registry: Node) -> bool:
	if terrain_registry == null:
		return true
	for unit in Array(unit_registry.call("get_all_units")):
		if not (unit is Node2D):
			continue
		var grid: Vector2i = terrain_registry.call("world_to_grid", (unit as Node2D).global_position)
		if not bool(terrain_registry.call("is_walkable", grid)):
			return false
	return true


func _snapshot_units_keep_spacing(snapshot_units: Array, minimum_distance: float) -> bool:
	for index_a in range(snapshot_units.size()):
		for index_b in range(index_a + 1, snapshot_units.size()):
			var entry_a: Dictionary = Dictionary(snapshot_units[index_a])
			var entry_b: Dictionary = Dictionary(snapshot_units[index_b])
			if typeof(entry_a.get("position", null)) != TYPE_VECTOR2 or typeof(entry_b.get("position", null)) != TYPE_VECTOR2:
				return false
			var position_a: Vector2 = Vector2(entry_a.get("position", Vector2.ZERO))
			var position_b: Vector2 = Vector2(entry_b.get("position", Vector2.ZERO))
			if position_a.distance_to(position_b) < minimum_distance - 0.01:
				return false
	return true


func _get_registry_unit_ids(unit_registry: Node) -> Array:
	var unit_ids: Array = []
	for unit in Array(unit_registry.call("get_all_units")):
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		unit_ids.append(String(unit.call("get_unit_id")))
	unit_ids.sort()
	return unit_ids


func _arrays_equal(a: Array, b: Array) -> bool:
	var left: Array = a.duplicate()
	var right: Array = b.duplicate()
	left.sort()
	right.sort()
	if left.size() != right.size():
		return false
	for index in range(left.size()):
		if String(left[index]) != String(right[index]):
			return false
	return true


func _cleanup_context(context: Dictionary) -> void:
	var scene: Node = context.get("scene", null)
	if scene != null:
		scene.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
