extends SceneTree

const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_129 Cover-aware HPA/Subgoal Vorbereitung Verifier ===")
	_test_cover_aware_path_reduces_exposure()
	_test_hpa_uses_cover_aware_local_costs_and_portal_meta()
	_test_simulation_root_debug_exposes_cover_metrics()
	_test_command_type_changes_navigation_weights()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_cover_aware_path_reduces_exposure() -> void:
	var registry = _make_cover_test_registry(6)
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var from_grid := Vector2i(0, 1)
	var to_grid := Vector2i(6, 1)
	var metric_options: Dictionary = _make_cover_options([Vector2i(3, 1)], 0.0, 0.0)
	var cover_options: Dictionary = _make_cover_options([Vector2i(3, 1)], 4.0, 2.0)
	var plain_path: Array = pathfinder.call("find_path", from_grid, to_grid, registry)
	var cover_path: Array = pathfinder.call("find_path_with_options", from_grid, to_grid, registry, cover_options)
	var plain_score: Dictionary = Dictionary(pathfinder.call("score_path", plain_path, registry, metric_options))
	var cover_score: Dictionary = Dictionary(pathfinder.call("score_path", cover_path, registry, metric_options))
	_assert(not plain_path.is_empty() and not cover_path.is_empty(), "Plain and cover-aware pathfinding both return paths")
	_assert(float(cover_score.get("exposure_sum", 99.0)) < float(plain_score.get("exposure_sum", 0.0)), "Cover-aware path has lower exposure sum than plain path")
	_assert(float(cover_score.get("cover_sum", 0.0)) > float(plain_score.get("cover_sum", 99.0)), "Cover-aware path prefers higher cover tiles")
	_assert(_path_steps_are_traversable(cover_path, registry, pathfinder), "Cover-aware path keeps terrain traversal rules")
	registry.free()


func _test_hpa_uses_cover_aware_local_costs_and_portal_meta() -> void:
	var registry = _make_cover_test_registry(9)
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 3)
	var portals: Array = Array(graph.call("get_portals_snapshot"))
	var has_cover_meta: bool = false
	for portal_variant in portals:
		var portal: Dictionary = Dictionary(portal_variant)
		if portal.has("mean_cover") and portal.has("min_cover"):
			has_cover_meta = true
			break
	var pathfinder = HPA_PATHFINDER_SCRIPT.new()
	var metric_pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var from_grid := Vector2i(0, 1)
	var to_grid := Vector2i(9, 1)
	var metric_options: Dictionary = _make_cover_options([Vector2i(4, 1)], 0.0, 0.0)
	var cover_options: Dictionary = _make_cover_options([Vector2i(4, 1)], 4.0, 2.0)
	var plain_result: Dictionary = Dictionary(pathfinder.call("find_path_with_status", from_grid, to_grid, registry, graph, {}))
	var cover_result: Dictionary = Dictionary(pathfinder.call("find_path_with_status", from_grid, to_grid, registry, graph, cover_options))
	var plain_score: Dictionary = Dictionary(metric_pathfinder.call("score_path", Array(plain_result.get("path", [])), registry, metric_options))
	var cover_score: Dictionary = Dictionary(metric_pathfinder.call("score_path", Array(cover_result.get("path", [])), registry, metric_options))
	_assert(has_cover_meta, "HPA portal snapshot exposes static cover metadata for later subgoal annotation")
	_assert(String(cover_result.get("status", "")) == HPA_PATHFINDER_SCRIPT.STATUS_HPA, "Cover-aware HPA still returns an HPA route across clusters")
	_assert(float(cover_score.get("exposure_sum", 99.0)) < float(plain_score.get("exposure_sum", 0.0)), "Cover-aware HPA route lowers exposure against the plain HPA route")
	registry.free()


func _test_simulation_root_debug_exposes_cover_metrics() -> void:
	var context: Dictionary = _make_simulation_context(_make_cover_test_registry(6), Vector2i(0, 1), "cover_debug_alpha")
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = context["unit"]
	simulation_root.call("set_navigation_debug_enabled", true)
	var target_position: Vector2 = registry.grid_to_world(Vector2i(6, 1))
	var cmd: Dictionary = _build_move_command(unit.get_unit_id(), target_position, "defend")
	cmd["navigation_cover_aware"] = true
	cmd["navigation_threat_grids"] = [Vector2i(3, 1)]
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, unit.global_position, target_position, registry)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_navigation_debug_snapshot"))
	var metrics: Dictionary = Dictionary(snapshot.get("last_path_metrics", {}))
	_assert(not path.is_empty(), "SimulationRoot builds cover-aware move path")
	_assert(int(metrics.get("path_length_grid", 0)) > 0, "Navigation debug snapshot exposes path length")
	_assert(metrics.has("exposure_sum") and metrics.has("cover_sum"), "Navigation debug snapshot exposes exposure and cover sums")
	_assert(float(metrics.get("cover_sum", 0.0)) > 0.0, "Navigation debug cover sum reflects covered route tiles")
	_cleanup_context(context)


func _test_command_type_changes_navigation_weights() -> void:
	var context: Dictionary = _make_simulation_context(_make_cover_test_registry(4), Vector2i(0, 1), "weights_alpha")
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var target_position: Vector2 = registry.grid_to_world(Vector2i(4, 1))
	var move_options: Dictionary = Dictionary(simulation_root.call("_build_navigation_cost_options", _build_move_command("weights_alpha", target_position, "move"), registry))
	var defend_options: Dictionary = Dictionary(simulation_root.call("_build_navigation_cost_options", _build_move_command("weights_alpha", target_position, "defend"), registry))
	var flank_options: Dictionary = Dictionary(simulation_root.call("_build_navigation_cost_options", _build_move_command("weights_alpha", target_position, "flank"), registry))
	_assert(float(defend_options.get("cover_weight", 0.0)) > float(move_options.get("cover_weight", 0.0)), "Defend commands weight cover more strongly than neutral move")
	_assert(float(flank_options.get("exposure_weight", 0.0)) > float(move_options.get("exposure_weight", 0.0)), "Flank commands avoid exposure more strongly than neutral move")
	_cleanup_context(context)


func _make_cover_options(hazard_grids: Array, exposure_weight: float, cover_weight: float) -> Dictionary:
	return {
		"cover_aware_enabled": true,
		"hazard_grids": hazard_grids,
		"exposure_weight": exposure_weight,
		"cover_weight": cover_weight,
		"exposure_max_grid_distance": 4.0,
	}


func _make_cover_test_registry(max_x: int):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(0, max_x + 1):
		for y in range(0, 3):
			var grid_position := Vector2i(x, y)
			registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
				"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
				"type_id": "ground_flat",
				"grid_position": grid_position,
				"world_position": registry.grid_to_world(grid_position),
				"walkable": true,
				"blocks_los": y == 0 and x > 0 and x < max_x,
				"cover_value": 90 if y == 0 and x > 0 and x < max_x else 0,
				"surface_type": "ground",
			}))
	return registry


func _make_simulation_context(terrain_registry, unit_grid: Vector2i, unit_id: String) -> Dictionary:
	var scene = Node.new()
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	terrain_registry.name = "TerrainRegistry"
	scene.add_child(terrain_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	scene.add_child(simulation_root)
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	unit.global_position = terrain_registry.grid_to_world(unit_grid)
	scene.add_child(unit)
	unit_registry.register_unit(unit.get_unit_id(), unit)
	return {
		"scene": scene,
		"unit_registry": unit_registry,
		"terrain_registry": terrain_registry,
		"simulation_root": simulation_root,
		"unit": unit,
	}


func _build_move_command(unit_id: String, target_position: Vector2, source_command_type: String) -> Dictionary:
	return {
		"command_type": "move_to_position",
		"source_command_type": source_command_type,
		"unit_id": unit_id,
		"team_id": "team_alpha",
		"target_position": target_position,
		"move_speed_factor": 1.0,
		"requeue_until_target": true,
	}


func _path_steps_are_traversable(path: Array, registry, pathfinder) -> bool:
	for index in range(1, path.size()):
		if not bool(pathfinder.call("can_traverse_step", Vector2i(path[index - 1]), Vector2i(path[index]), registry)):
			return false
	return true


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
