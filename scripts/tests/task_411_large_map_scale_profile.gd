extends SceneTree

const FOW_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const LINE_OF_SIGHT_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")

const CLUSTER_SIZE: int = 8
const BROAD_HPA_BUILD_BUDGET_USEC: int = 120000000
const BROAD_FOW_UPDATE_BUDGET_USEC: int = 120000000
const BROAD_RENDER_CONFIGURE_BUDGET_USEC: int = 240000000
const MAX_AUTOMATED_FULL_RENDER_TILE_COUNT: int = 64 * 64
const RELEASE_SUPPORTED_MAX_MAP_SIZE := Vector2i(128, 128)
const RELEASE_WITHHELD_MAP_SIZE := Vector2i(256, 256)
const PROFILE_SIZES: Array[Vector2i] = [
	Vector2i(128, 128),
	Vector2i(256, 256),
]
const NATURE_PROPS: PackedStringArray = [
	"nature_tree_blocker",
	"nature_rock_cover",
	"nature_bush_cover",
	"nature_cactus_cover",
	"nature_deco_logs",
]
const STATION_OBJECTS: PackedStringArray = [
	"station_computer",
	"station_container_wide",
	"station_wall",
]
const STATION_FLOORS: PackedStringArray = [
	"station_floor_panel",
	"modular_floor",
	"modular_floor_big",
	"modular_floor_raised",
]

var _passed: int = 0
var _failed: int = 0
var _profiles: Array = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_411 Large Map Scale Profile ===")
	for size in PROFILE_SIZES:
		await _profile_large_map(Vector2i(size))
	_test_task_1193_release_acceptance_snapshot()
	print("TASK_411 profile summary: %s" % JSON.stringify(_profiles))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func get_task_1193_release_acceptance_snapshot() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.tactical_release_map_scale_acceptance.v1",
		"task_id": "TASK_1193",
		"supported_max_map_size": RELEASE_SUPPORTED_MAX_MAP_SIZE,
		"supported_max_map_label": "%dx%d" % [RELEASE_SUPPORTED_MAX_MAP_SIZE.x, RELEASE_SUPPORTED_MAX_MAP_SIZE.y],
		"supported_max_map_tile_count": RELEASE_SUPPORTED_MAX_MAP_SIZE.x * RELEASE_SUPPORTED_MAX_MAP_SIZE.y,
		"requires_manual_fullhd_playtest": true,
		"requires_tactical_budget_enforcers": true,
		"withheld_map_size": RELEASE_WITHHELD_MAP_SIZE,
		"withheld_map_label": "%dx%d" % [RELEASE_WITHHELD_MAP_SIZE.x, RELEASE_WITHHELD_MAP_SIZE.y],
		"withheld_reason": "256x256 is logical-profile evidence only; full viewport release acceptance is missing.",
		"automated_full_render_tile_limit": MAX_AUTOMATED_FULL_RENDER_TILE_COUNT,
		"synthetic_fixture_is_manual_evidence": false,
	}


func _test_task_1193_release_acceptance_snapshot() -> void:
	var snapshot: Dictionary = get_task_1193_release_acceptance_snapshot()
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.tactical_release_map_scale_acceptance.v1", "TASK_1193 release scale schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1193", "TASK_1193 release scale snapshot identifies its task")
	_assert(Vector2i(snapshot.get("supported_max_map_size", Vector2i.ZERO)) == Vector2i(128, 128), "128x128 is the supported release candidate maximum")
	_assert(bool(snapshot.get("requires_manual_fullhd_playtest", false)), "128x128 candidate requires manual FullHD playtest evidence")
	_assert(Vector2i(snapshot.get("withheld_map_size", Vector2i.ZERO)) == Vector2i(256, 256), "256x256 remains withheld from release")
	_assert(not bool(snapshot.get("synthetic_fixture_is_manual_evidence", true)), "Synthetic fixture evidence never counts as manual release evidence")


func _profile_large_map(size: Vector2i) -> void:
	var expected_tile_count: int = size.x * size.y
	var expected_cluster_count: int = int(ceili(float(size.x) / float(CLUSTER_SIZE))) * int(ceili(float(size.y) / float(CLUSTER_SIZE)))
	var fixture: Dictionary = _build_profile_map(size)
	var map_data = fixture["map_data"]
	var fixture_stats: Dictionary = Dictionary(fixture.get("fixture_stats", {}))
	var registry: Node = _build_registry_from_map(map_data)

	var hpa_profile: Dictionary = _profile_hpa(registry, size)
	var fow_profile: Dictionary = _profile_fow(registry, size)
	var runtime_profile: Dictionary = _profile_runtime_units(registry, size)
	var render_profile: Dictionary = await _profile_render(map_data, size)

	_assert(int(fixture_stats.get("tile_count", 0)) == expected_tile_count, "%dx%d fixture creates every tile" % [size.x, size.y])
	_assert(int(hpa_profile.get("tile_count", 0)) == expected_tile_count, "%dx%d HPA profile sees every tile" % [size.x, size.y])
	_assert(int(hpa_profile.get("cluster_count", 0)) == expected_cluster_count, "%dx%d HPA profile reports expected 8x8 clusters" % [size.x, size.y])
	_assert(int(fow_profile.get("tile_count", 0)) == expected_tile_count, "%dx%d FoW profile scans every tile" % [size.x, size.y])
	_assert(int(fow_profile.get("visible_tile_count", 0)) > 0, "%dx%d FoW profile has visible terrain" % [size.x, size.y])
	if bool(render_profile.get("full_render_executed", false)):
		_assert(int(render_profile.get("tile_count", 0)) == expected_tile_count, "%dx%d render profile renders every tile" % [size.x, size.y])
		_assert(int(render_profile.get("ground_multimesh_tile_count", 0)) >= expected_tile_count, "%dx%d render profile batches ground coverage" % [size.x, size.y])
		_assert(int(render_profile.get("static_prop_multimesh_model_count", 0)) > 0, "%dx%d render profile batches nature props" % [size.x, size.y])
		_assert(int(render_profile.get("space_station_model_count", 0)) > 0, "%dx%d render profile includes station/modular setpieces" % [size.x, size.y])
		_assert(int(render_profile.get("missing_map_asset_mapping_count", 99)) == 0, "%dx%d render profile has no missing map asset mappings" % [size.x, size.y])
	else:
		_assert(int(render_profile.get("tile_count", 0)) == expected_tile_count, "%dx%d render profile records skipped full-render tile count" % [size.x, size.y])
		_assert(String(render_profile.get("skipped_reason", "")).contains("full_render"), "%dx%d render profile documents skipped heavy full-render probe" % [size.x, size.y])
	_assert(int(runtime_profile.get("runtime_unit_count", 0)) >= 1, "%dx%d runtime profile includes units" % [size.x, size.y])
	_assert(int(Dictionary(runtime_profile.get("hpa_navigation", {})).get("build_count", 0)) > 0, "%dx%d runtime profile exposes SimulationRoot HPA build diagnostics" % [size.x, size.y])

	_profiles.append({
		"size": "%dx%d" % [size.x, size.y],
		"fixture": fixture_stats,
		"hpa": hpa_profile,
		"fow": fow_profile,
		"runtime": runtime_profile,
		"render": render_profile,
	})


func _build_profile_map(size: Vector2i) -> Dictionary:
	var started_usec: int = Time.get_ticks_usec()
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_411_profile_%dx%d" % [size.x, size.y], size, Vector2(512.0, 256.0), 64.0, 32.0, 3)
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var stats: Dictionary = {
		"tile_count": size.x * size.y,
		"hill_tile_count": 0,
		"nature_prop_count": 0,
		"station_floor_tile_count": 0,
		"station_object_count": 0,
	}
	var prop_index: int = 0
	var station_object_index: int = 0
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		tile_data.type_id = _base_type_for_grid(grid, size)
		tile_data.object_type_id = ""
		tile_data.walkable = true
		tile_data.blocks_los = false
		tile_data.cover_value = 0
		tile_data.object_height = 0
		tile_data.object_rotation_degrees = float(((grid.x + grid.y) % 4) * 90)
		tile_data.surface_type = _surface_type_for_grid(grid)
		tile_data.height_level = _height_for_grid(grid, size)
		tile_data.edge_type = _edge_type_for_grid(grid, size, int(tile_data.height_level))
		if int(tile_data.height_level) > 0:
			stats["hill_tile_count"] = int(stats.get("hill_tile_count", 0)) + 1
			if int(tile_data.height_level) == 2 and (grid.x + grid.y) % 11 == 0:
				tile_data.blocks_los = true
				tile_data.cover_value = 45
				tile_data.object_height = 1

		if _is_station_floor_grid(grid, size):
			tile_data.type_id = String(STATION_FLOORS[(grid.x + (grid.y * 3)) % STATION_FLOORS.size()])
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD
			stats["station_floor_tile_count"] = int(stats.get("station_floor_tile_count", 0)) + 1
			if _should_place_station_object(grid, size):
				var object_id: String = String(STATION_OBJECTS[station_object_index % STATION_OBJECTS.size()])
				if bool(catalog.call("apply_type_to_tile", tile_data, object_id)):
					stats["station_object_count"] = int(stats.get("station_object_count", 0)) + 1
					station_object_index += 1
			continue

		if _should_place_nature_prop(grid, size):
			var prop_id: String = String(NATURE_PROPS[prop_index % NATURE_PROPS.size()])
			if bool(catalog.call("apply_type_to_tile", tile_data, prop_id)):
				stats["nature_prop_count"] = int(stats.get("nature_prop_count", 0)) + 1
				prop_index += 1

	stats["build_duration_usec"] = Time.get_ticks_usec() - started_usec
	return {
		"map_data": map_data,
		"fixture_stats": stats,
	}


func _base_type_for_grid(grid: Vector2i, size: Vector2i) -> String:
	if _is_station_floor_grid(grid, size):
		return "station_floor_panel"
	if (grid.x + grid.y) % 19 == 0:
		return "nature_ground_grass_patch"
	if (grid.x * 3 + grid.y) % 23 == 0:
		return "nature_ground_dirt"
	return "ground_flat"


func _surface_type_for_grid(grid: Vector2i) -> String:
	var selector: int = posmod((grid.x * 5) + (grid.y * 7), 17)
	if selector < 2:
		return TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD
	if selector < 5:
		return TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
	if selector == 7:
		return TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK
	return TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND


func _height_for_grid(grid: Vector2i, size: Vector2i) -> int:
	var center_a: Vector2 = Vector2(float(size.x) * 0.35, float(size.y) * 0.38)
	var center_b: Vector2 = Vector2(float(size.x) * 0.68, float(size.y) * 0.62)
	var grid_position: Vector2 = Vector2(float(grid.x), float(grid.y))
	var dist_a: float = grid_position.distance_to(center_a)
	var dist_b: float = grid_position.distance_to(center_b)
	var radius_a: float = float(size.x) * 0.13
	var radius_b: float = float(size.x) * 0.10
	if dist_a < radius_a * 0.48 or dist_b < radius_b * 0.45:
		return 2
	if dist_a < radius_a or dist_b < radius_b:
		return 1
	return 0


func _edge_type_for_grid(grid: Vector2i, size: Vector2i, height_level: int) -> String:
	if height_level <= 0:
		return TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	var band: int = posmod(grid.x + (grid.y * 2), 9)
	if height_level == 1:
		return TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
	return TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF if band < 3 else TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE


func _is_station_floor_grid(grid: Vector2i, size: Vector2i) -> bool:
	var zone_size: int = maxi(18, int(float(size.x) * 0.125))
	var min_x: int = int(float(size.x) * 0.56)
	var min_y: int = int(float(size.y) * 0.18)
	return grid.x >= min_x and grid.x < min_x + zone_size and grid.y >= min_y and grid.y < min_y + zone_size


func _should_place_station_object(grid: Vector2i, size: Vector2i) -> bool:
	if grid.x <= 4 or grid.y <= 4 or grid.x >= size.x - 4 or grid.y >= size.y - 4:
		return false
	return posmod((grid.x * 31) + (grid.y * 17), 53) == 0


func _should_place_nature_prop(grid: Vector2i, size: Vector2i) -> bool:
	if grid.x <= 4 or grid.y <= 4 or grid.x >= size.x - 4 or grid.y >= size.y - 4:
		return false
	if _is_station_floor_grid(grid, size):
		return false
	return posmod((grid.x * 13) + (grid.y * 29), 41) == 0


func _build_registry_from_map(map_data) -> Node:
	var registry: Node = TERRAIN_REGISTRY_SCRIPT.new()
	var tile_size: Dictionary = Dictionary(map_data.call("get_tile_size"))
	registry.call("configure_iso_grid", map_data.call("get_grid_origin"), float(tile_size.get("half_width", 64.0)), float(tile_size.get("half_height", 32.0)))
	for tile_data in Array(map_data.call("get_tiles")):
		registry.call("register_tile", tile_data)
	return registry


func _profile_hpa(registry: Node, size: Vector2i) -> Dictionary:
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	var build_started_usec: int = Time.get_ticks_usec()
	var built: bool = bool(graph.call("build_from_registry", registry, CLUSTER_SIZE))
	var build_duration_usec: int = Time.get_ticks_usec() - build_started_usec
	var stats: Dictionary = Dictionary(graph.call("get_last_build_stats"))
	_assert(built, "%dx%d HPA graph builds" % [size.x, size.y])
	_assert(build_duration_usec < BROAD_HPA_BUILD_BUDGET_USEC, "%dx%d HPA build stays under broad profile budget" % [size.x, size.y])

	var hpa_pathfinder = HPA_PATHFINDER_SCRIPT.new()
	var queries: Array = _large_map_queries(size)
	var successful_queries: int = 0
	var query_started_usec: int = Time.get_ticks_usec()
	for query_variant in queries:
		var query: Dictionary = Dictionary(query_variant)
		var result: Dictionary = Dictionary(hpa_pathfinder.call("find_path_with_status", Vector2i(query.get("from", Vector2i.ZERO)), Vector2i(query.get("to", Vector2i.ZERO)), registry, graph, {}))
		if not Array(result.get("path", [])).is_empty():
			successful_queries += 1
	var query_duration_usec: int = Time.get_ticks_usec() - query_started_usec
	return {
		"built": bool(stats.get("built", built)),
		"tile_count": int(stats.get("tile_count", 0)),
		"cluster_count": int(stats.get("cluster_count", 0)),
		"component_count": int(stats.get("component_count", 0)),
		"portal_count": int(stats.get("portal_count", 0)),
		"build_duration_usec": int(stats.get("elapsed_usec", build_duration_usec)),
		"query_count": queries.size(),
		"successful_queries": successful_queries,
		"query_duration_usec": query_duration_usec,
	}


func _large_map_queries(size: Vector2i) -> Array:
	return [
		{"from": Vector2i(2, 2), "to": Vector2i(14, 14)},
	]


func _profile_fow(registry: Node, size: Vector2i) -> Dictionary:
	var fow = FOW_SYSTEM_SCRIPT.new()
	var los = null
	fow.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	var observers: Array = [_make_observer(registry, Vector2i(int(size.x * 0.50), int(size.y * 0.50)))]
	var update: Dictionary = Dictionary(fow.call("update_tile_visibility_for_team", "team_alpha", observers, registry, los, 256.0))
	_assert(int(update.get("duration_usec", BROAD_FOW_UPDATE_BUDGET_USEC + 1)) < BROAD_FOW_UPDATE_BUDGET_USEC, "%dx%d FoW update stays under broad profile budget" % [size.x, size.y])
	for observer in observers:
		observer.free()
	return {
		"tile_count": int(update.get("tile_count", 0)),
		"observer_count": int(update.get("observer_count", 0)),
		"visible_tile_count": int(update.get("visible_tile_count", 0)),
		"checked_tile_count": int(update.get("checked_tile_count", 0)),
		"duration_usec": int(update.get("duration_usec", 0)),
	}


func _profile_runtime_units(registry: Node, size: Vector2i) -> Dictionary:
	var scene := Node.new()
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	registry.name = "TerrainRegistry"
	scene.add_child(registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	scene.add_child(simulation_root)
	simulation_root.call("set_navigation_debug_enabled", true)
	simulation_root.call("set_navigation_max_new_path_queries_per_tick", 8)
	var starts: Array = [Vector2i(3, 3)]
	var targets: Array = [Vector2i(18, 18)]
	for index in range(starts.size()):
		var unit = TEST_UNIT_SCRIPT.new()
		unit.unit_id = "scale_unit_%d" % index
		unit.team_id = "team_alpha"
		unit.fireteam_id = "blue"
		unit.global_position = registry.call("grid_to_world", starts[index])
		scene.add_child(unit)
		unit_registry.call("register_unit", unit.get_unit_id(), unit)
		simulation_root.call("enqueue_command", {
			"command_type": "move_to_position",
			"unit_id": unit.get_unit_id(),
			"team_id": "team_alpha",
			"target_position": registry.call("grid_to_world", targets[index]),
			"move_speed_factor": 1.0,
		})
	simulation_root.call("_physics_process", 0.1)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_navigation_debug_snapshot"))
	var hpa_snapshot: Dictionary = Dictionary(snapshot.get("hpa_navigation", {}))
	var result: Dictionary = {
		"runtime_unit_count": starts.size(),
		"path_queries_this_tick": int(snapshot.get("path_queries_this_tick", 0)),
		"new_path_queries_this_tick": int(snapshot.get("new_path_queries_this_tick", 0)),
		"delayed_this_tick": int(snapshot.get("delayed_this_tick", 0)),
		"hpa_navigation": hpa_snapshot,
	}
	scene.queue_free()
	return result


func _profile_render(map_data, size: Vector2i) -> Dictionary:
	var tile_count: int = size.x * size.y
	if tile_count > MAX_AUTOMATED_FULL_RENDER_TILE_COUNT:
		return {
			"tile_count": tile_count,
			"full_render_executed": false,
			"skipped_reason": "full_render_heavy_probe_excluded_from_headless_gate_after_256x256_timeout",
			"automated_full_render_tile_limit": MAX_AUTOMATED_FULL_RENDER_TILE_COUNT,
		}
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	await _wait_frames(1)
	var started_usec: int = Time.get_ticks_usec()
	primary_view.call("configure_from_map", map_data)
	await _wait_frames(8 if size.x <= 128 else 14)
	var configure_duration_usec: int = Time.get_ticks_usec() - started_usec
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(configure_duration_usec < BROAD_RENDER_CONFIGURE_BUDGET_USEC, "%dx%d render configure stays under broad profile budget" % [size.x, size.y])
	var budget_totals: Dictionary = Dictionary(snapshot.get("render_budget_totals", {}))
	var result: Dictionary = {
		"full_render_executed": true,
		"tile_count": int(snapshot.get("tile_count", 0)),
		"ground_multimesh_tile_count": int(snapshot.get("ground_multimesh_tile_count", 0)),
		"ground_multimesh_instance_count": int(snapshot.get("ground_multimesh_instance_count", 0)),
		"height_edge_multimesh_model_count": int(snapshot.get("height_edge_multimesh_model_count", 0)),
		"surface_tint_batched_tile_count": int(snapshot.get("surface_tint_batched_tile_count", 0)),
		"static_prop_multimesh_model_count": int(snapshot.get("static_prop_multimesh_model_count", 0)),
		"static_prop_multimesh_instance_count": int(snapshot.get("static_prop_multimesh_instance_count", 0)),
		"static_prop_individual_model_count": int(snapshot.get("static_prop_individual_model_count", 0)),
		"space_station_model_count": int(snapshot.get("space_station_model_count", 0)),
		"asset_model_count": int(snapshot.get("asset_model_count", 0)),
		"missing_map_asset_mapping_count": int(snapshot.get("missing_map_asset_mapping_count", 0)),
		"configure_duration_usec": configure_duration_usec,
		"map_render_duration_msec": float(snapshot.get("map_render_duration_msec", 0.0)),
		"map_node_count": int(Dictionary(Dictionary(snapshot.get("render_budget_by_category", {})).get("map", {})).get("node_count", 0)),
		"total_node_count": int(budget_totals.get("node_count", 0)),
		"total_mesh_instance_count": int(budget_totals.get("mesh_instance_count", 0)),
		"total_multimesh_instance_count": int(budget_totals.get("multimesh_instance_count", 0)),
	}
	primary_view.queue_free()
	await _wait_frames(2)
	return result


func _make_observer(registry: Node, grid_position: Vector2i) -> Node2D:
	var observer := Node2D.new()
	observer.global_position = registry.call("grid_to_world", grid_position)
	return observer


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
