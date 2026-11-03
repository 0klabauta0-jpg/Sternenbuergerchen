extends SceneTree
## Saved-data / navigation / pure-visual gate. No actors, HP or timers are patched.
## Physical Cutlass insertion and GO remain a separate normal-start test.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const CATALOG = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA_GRAPH = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_PATHFINDER = preload("res://scripts/terrain/hpa_pathfinder.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const LAYOUT = preload("res://scripts/terrain/frontier_gm01_layout.gd")
const AUTHORING = preload("res://scripts/tools/build_gm01_frontier.gd")
const SETUP = preload("res://scripts/tests/mission_test_setup.gd")
const SCENARIO_DATA = preload("res://scripts/mission/mission_scenario_data.gd")
const MAP_PATH := "res://maps/Ground_Mission01_32x32.json"
const SCENARIO_PATH := "res://data/mission_scenarios/ground_mission01_default.json"
const ORIGINAL := "res://docs/qa/gm01_frontier_20261102/original_Ground_Mission01_32x32.json"
const ORIGINAL_SHA := "eb51df71c4767023b8e87ed7e2c136f13d847cabddb25578d1f52fda1c46c8d8"
const SCENARIO_SHA := "792bff6b6dfa6fabf739a737e4e45d34c8e3729a4fdc7d6b62a74a374a27b45f"
const EXPECTED_SIZE := Vector2i(96, 98)
const EXPECTED_OFFSET_ORIGIN := Vector2i(-24, -25)
const EXTENSION_PLANES := [Vector2(35, 27), Vector2(42, 26), Vector2(43, 30)]
const STRUCTURE_HASHES := {
	"habitat_cutaway_01.glb": "6524cd513b1d474dba4a855ef1dad32ec4539513acb46bf73cd1b44463a2d50f",
	"freihafen_hall_01.glb": "cc17a4cebc805a3f165eecd0e3bef95b7a92e851dc592fb8867b92597a894508",
	"utility_fuel_01.glb": "7e7c54b23548b95ee0483a9233f2c5fd256eaac5a01f153c8b8b7c2a1240b274",
}
const EXPECTED_PLANES := {
	"spawn_alpha": Vector2(6, 11), "objective_point": Vector2(11, 12),
	"spawn_enemy_defense": Vector2(13, 13), "spawn_enemy_patrol": Vector2(17, 11),
	"spawn_bravo": Vector2(21, 12),
}
var passed := 0
var failed := 0
var checks: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	checks.append({"passed": value, "label": label})
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)


func _run() -> void:
	var map_hash_before: String = FileAccess.get_sha256(MAP_PATH)
	var map_data = MAP.load_from_file(MAP_PATH)
	_check(map_data != null and not map_data.has_load_issue(), "Regular GM01 loads as real saved TerrainMapData")
	if map_data == null or map_data.has_load_issue():
		_finish({})
		return
	var registry: Node = _registry_from_map(map_data)
	var original: Dictionary = AUTHORING.read_dictionary(ORIGINAL)
	var raw: Dictionary = AUTHORING.read_dictionary(MAP_PATH)
	_check(FileAccess.get_sha256(ORIGINAL) == ORIGINAL_SHA, "Original GM01 QA snapshot remains byte-identical")
	_check(FileAccess.get_sha256(SCENARIO_PATH) == SCENARIO_SHA, "Scenario remains byte-identical, including IDs/tactics/limits")
	_check(map_data.get_map_name() == "GM01 Frontier Hex 96x98" and map_data.get_grid_size() == EXPECTED_SIZE, "Regular GM01 has 96x98 real Hex cells up to the displayed ground edge and an accurate name")
	_check(map_data.get_grid_topology() == HEX.TOPOLOGY_ID and map_data.get_grid_origin() == Vector2.ZERO, "Real axial hex gameplay topology and unchanged art origin are explicit")
	_check(map_data.get_tile_size() == {"half_width": 64.0, "half_height": 32.0}, "Iso tile geometry remains64/32")
	_check(map_data.get_terrain_visual_theme_id() == "frontier_illustrated_v1", "Saved map selects the Frontier art family")
	_check(map_data.has_method("get_authored_visual_layout_id") and String(map_data.call("get_authored_visual_layout_id")) == "gm01_frontier_outpost_v1", "Saved map selects the concrete versioned outpost layout")
	_check(raw.get("enemy_team_configs", {}) == original.get("enemy_team_configs", {}) and raw.get("mission_slot_count", -1) == original.get("mission_slot_count", -2), "Map enemy tactics and slot budget are preserved")
	_check(map_data.get_marker_ids().size() == 5 and map_data.get_patrol_paths().keys() == ["ground_patrol_route"], "Five marker IDs and the existing patrol path ID are preserved")
	for marker_id in EXPECTED_PLANES:
		var actual: Vector2i = registry.call("world_to_grid", map_data.get_marker_position(marker_id))
		var expected: Vector2i = HEX.round_axial(HEX.plane_to_axial(EXPECTED_PLANES[marker_id]))
		_check(actual == expected and bool(registry.call("is_walkable", actual)) and HEX.axial_to_plane(Vector2(actual)).distance_to(EXPECTED_PLANES[marker_id]) <= HEX.DEFAULT_RADIUS + 0.001, "Authored marker%s occupies the nearest legal hex%s beside the original art anchor" % [marker_id, actual])
	_test_scenario()
	_test_spawn_areas(map_data, registry)
	_test_routes(map_data, registry)
	var before_facts: String = _fact_fingerprint(map_data)
	var before_revision: int = int(registry.call("get_revision"))
	var host := Node3D.new()
	root.add_child(host)
	var layout: Dictionary = LAYOUT.build(host)
	_check(_fact_fingerprint(map_data) == before_facts and int(registry.call("get_revision")) == before_revision, "Cold visual composition does not mutate saved facts or Registry revision")
	_check(FileAccess.get_sha256(MAP_PATH) == map_hash_before, "Cold visual composition does not write the map")
	_test_layout_facts(map_data, layout)
	_test_assets(layout)
	var generated: Dictionary = AUTHORING.compose_payload(layout)
	# Compare the writer's exact bytes. JSON parsing promotes integral numbers to
	# floats, so nested Variant Dictionary equality is not a serialization check.
	var generated_json: String = JSON.stringify(generated, "\t", true) + "\n"
	_check(generated_json.sha256_text() == map_hash_before, "Regular GM01 exactly matches its deterministic offline authoring source")
	var authoring_issues: PackedStringArray = AUTHORING.validate_payload(generated, layout)
	_check(authoring_issues.is_empty(), "Offline authoring safety checks pass: %s" % str(authoring_issues))
	_test_roundtrip(map_data, before_facts)
	var facts: Dictionary = {"map_sha256": map_hash_before, "scenario_sha256": FileAccess.get_sha256(SCENARIO_PATH), "layout_id": layout.get("layout_id", ""), "grid_size": {"x": EXPECTED_SIZE.x, "y": EXPECTED_SIZE.y}, "tile_count": map_data.get_tiles().size(), "asset_sources": layout.get("assets", []), "blocker_count": Array(layout.get("blockers", [])).size(), "fact_fingerprint": before_facts}
	host.free()
	_test_normal_view(map_data, before_facts)
	registry.free()
	_finish(facts)


func _registry_from_map(map_data) -> Node:
	var registry: Node = REGISTRY.new()
	var size: Dictionary = map_data.get_tile_size()
	registry.call("configure_iso_grid", map_data.get_grid_origin(), float(size.get("half_width", 64.0)), float(size.get("half_height", 32.0)), map_data.get_grid_topology())
	for tile in map_data.get_tiles():
		registry.call("register_tile", tile)
	return registry


func _test_scenario() -> void:
	var scenario = SCENARIO_DATA.load_from_file(SCENARIO_PATH)
	var validation: Dictionary = scenario.validate()
	_check(bool(validation.get("valid", false)), "Unchanged regular scenario validates against the rebuilt map: %s" % str(validation))
	_check(scenario.map_file_path == MAP_PATH and scenario.scenario_id == "ground_mission01_default", "Scenario still dispatches to regular GM01")
	_check(scenario.get_enemy_ids().size() == 8 and scenario.enemy_groups.size() == 2, "Scenario retains two groups and eight original enemies")
	_check(is_equal_approx(scenario.time_limit_seconds, 1200.0) and int(scenario.mission_slot_count_override) == 8 and is_equal_approx(float(scenario.objective.get("capture_radius", 0.0)), 96.0), "1200-second limit, eight enemy slots and96-unit objective radius remain")


func _test_spawn_areas(map_data, registry: Node) -> void:
	var setup: Node = SETUP.new()
	var alpha: Vector2 = map_data.get_marker_position("spawn_alpha")
	var slots_valid := true
	for index in range(8):
		var grid: Vector2i = registry.call("world_to_grid", alpha + Vector2(setup.call("_get_friendly_spawn_offset", index)))
		slots_valid = slots_valid and bool(registry.call("is_walkable", grid)) and int(registry.call("get_height_at", grid)) == 0
	_check(slots_valid, "All eight real friendly slot offsets have legal H0 floor, including the first three units")
	var enemy_index := 0
	var enemy_valid := true
	for group in Array(AUTHORING.read_dictionary(SCENARIO_PATH).get("enemy_groups", [])):
		var centre: Vector2 = map_data.get_marker_position(String(group.get("spawn_marker_id", "")))
		for enemy_id in Array(group.get("enemy_ids", [])):
			var offset: Vector2 = setup.call("_get_enemy_spawn_offset", enemy_index)
			var grid: Vector2i = registry.call("world_to_grid", centre + offset)
			var legal: bool = bool(registry.call("is_walkable", grid))
			if not legal:
				print("GM01_BLOCKED_ENEMY id=%s global_slot=%d grid=%s" % [enemy_id, enemy_index, grid])
			enemy_valid = enemy_valid and legal
			enemy_index += 1
	_check(enemy_index == 8 and enemy_valid, "All real enemy global slot offsets0..7 remain legal; group two does not reset the index")
	var alpha_grid: Vector2i = registry.call("world_to_grid", alpha)
	var straight_move := false
	var pathfinder: RefCounted = PATHFINDER.new()
	for direction in HEX.neighbor_directions():
		var line_clear := true
		for step in range(1, 4):
			line_clear = line_clear and bool(pathfinder.call("can_traverse_step", alpha_grid + direction * (step - 1), alpha_grid + direction * step, registry))
		straight_move = straight_move or line_clear
	_check(straight_move, "Alpha LZ provides a normal legal three-hex initial move along a real hex edge")
	setup.free()


func _test_routes(map_data, registry: Node) -> void:
	var pathfinder: RefCounted = PATHFINDER.new()
	var graph: RefCounted = HPA_GRAPH.new()
	_check(bool(graph.call("build_from_registry", registry, 8)), "HPA builds from actual saved GM01 facts")
	var hpa: RefCounted = HPA_PATHFINDER.new()
	var alpha: Vector2i = registry.call("world_to_grid", map_data.get_marker_position("spawn_alpha"))
	var objective: Vector2i = registry.call("world_to_grid", map_data.get_marker_position("objective_point"))
	var defense: Vector2i = registry.call("world_to_grid", map_data.get_marker_position("spawn_enemy_defense"))
	var bravo: Vector2i = registry.call("world_to_grid", map_data.get_marker_position("spawn_bravo"))
	var patrol_start: Vector2i = registry.call("world_to_grid", map_data.get_marker_position("spawn_enemy_patrol"))
	var pairs: Array = [[alpha, objective], [defense, objective], [bravo, objective], [Vector2i(6, 24), Vector2i(8, 24)]]
	for plane in EXTENSION_PLANES:
		var target: Vector2i = HEX.round_axial(HEX.plane_to_axial(plane))
		_check(bool(registry.call("is_walkable", target)), "Expanded supply-yard/outer access anchor%s has actual walkable saved floor" % target)
		pairs.append([alpha, target])
	_check(Array(pathfinder.call("get_neighbor_directions", registry)).size() == 6 and bool(registry.call("are_grid_neighbors", alpha, alpha + Vector2i(1, -1))) and not bool(registry.call("are_grid_neighbors", alpha, alpha + Vector2i(1, 1))), "Actual GM01 navigation has exactly six hex edges and rejects the square diagonal")
	var patrol: Array = map_data.get_patrol_path("ground_patrol_route")
	_check(patrol.size() == 4, "Patrol keeps four meaningful waypoints")
	for index in range(patrol.size()):
		var start: Vector2i = registry.call("world_to_grid", patrol[index])
		var end: Vector2i = registry.call("world_to_grid", patrol[(index + 1) % patrol.size()])
		pairs.append([start, end])
	for pair in pairs:
		var astar: Array = pathfinder.call("find_path", pair[0], pair[1], registry)
		var hpa_path: Array = hpa.call("find_path", pair[0], pair[1], registry, graph)
		var legal := not astar.is_empty() and not hpa_path.is_empty()
		for path in [astar, hpa_path]:
			for index in range(1, path.size()):
				legal = legal and HEX.are_neighbors(path[index - 1], path[index]) and bool(pathfinder.call("can_traverse_step", path[index - 1], path[index], registry))
		_check(legal, "A* and HPA return legal adjacent steps%s→%s" % [pair[0], pair[1]])
	_check(int(registry.call("get_height_at", Vector2i(6, 24))) == 0 and int(registry.call("get_height_at", Vector2i(7, 24))) == 1 and int(registry.call("get_height_at", Vector2i(8, 24))) == 1 and String(registry.call("get_tile_at_grid", Vector2i(7, 24)).edge_type) == "slope", "Physical1179 loading-yard corridor survives as axial6,24→7,24→8,24 with real H0→rampH1→yardH1")
	# Erode by the six surrounding hexes. This seven-hex footprint proves
	# three-hex-wide clearance without importing square diagonal rules.
	var wide_registry: Node = REGISTRY.new()
	wide_registry.call("configure_iso_grid", Vector2.ZERO, 64.0, 32.0, HEX.TOPOLOGY_ID)
	for original in map_data.get_tiles():
		var facts: Dictionary = original.to_dict()
		var grid: Vector2i = original.grid_position
		var clear: bool = bool(original.walkable)
		for adjacent in HEX.neighbors(grid):
			clear = clear and bool(registry.call("is_walkable", adjacent))
		facts["walkable"] = clear
		wide_registry.call("register_tile", TILE.from_dict(facts))
	var wide_graph: RefCounted = HPA_GRAPH.new()
	_check(bool(wide_graph.call("build_from_registry", wide_registry, 8)), "HPA builds on independently eroded three-hex-wide space")
	var wide_pairs: Array = [[alpha, objective], [patrol_start, bravo]]
	for plane in EXTENSION_PLANES:
		wide_pairs.append([alpha, HEX.round_axial(HEX.plane_to_axial(plane))])
	for pair in wide_pairs:
		var wide_astar: Array = pathfinder.call("find_path", pair[0], pair[1], wide_registry)
		var wide_hpa: Array = hpa.call("find_path", pair[0], pair[1], wide_registry, wide_graph)
		_check(not wide_astar.is_empty() and not wide_hpa.is_empty(), "A* and HPA both preserve three-hex clearance for squad route%s→%s" % [pair[0], pair[1]])
	wide_registry.free()


func _test_layout_facts(map_data, layout: Dictionary) -> void:
	var all_match := true
	var solid_count := 0
	var walkable_cover_count := 0
	var unique: Dictionary = {}
	var in_bounds := true
	var negative_q_count := 0
	var negative_r_count := 0
	var blockers: Array = layout.get("blockers", [])
	for tile in map_data.get_tiles():
		var grid: Vector2i = tile.grid_position
		unique[grid] = true
		var column: int = grid.x + floori(float(grid.y) * 0.5)
		in_bounds = in_bounds and column >= EXPECTED_OFFSET_ORIGIN.x and grid.y >= EXPECTED_OFFSET_ORIGIN.y and column < EXPECTED_OFFSET_ORIGIN.x + EXPECTED_SIZE.x and grid.y < EXPECTED_OFFSET_ORIGIN.y + EXPECTED_SIZE.y
		if grid.x < 0:
			negative_q_count += 1
		if grid.y < 0:
			negative_r_count += 1
		var overlaps := false
		var blocks_los := false
		var height := 0
		var cover := 0
		for blocker in blockers:
			var rect: Rect2 = blocker.get("rect", Rect2())
			# Physical polygon contact: axial keys are never treated as XZ.
			rect = rect.grow(0.015)
			var rectangle := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
			if Geometry2D.intersect_polygons(HEX.corners(HEX.axial_to_plane(Vector2(grid))), rectangle).is_empty():
				continue
			overlaps = true
			blocks_los = blocks_los or bool(blocker.get("blocks_los", false))
			height = maxi(height, int(blocker.get("object_height", 0)))
			cover = maxi(cover, int(blocker.get("cover_value", 0)))
		if overlaps:
			solid_count += 1
			all_match = all_match and tile.object_type_id == "frontier_scene_solid" and not tile.walkable and tile.blocks_los == blocks_los and tile.object_height == height and tile.cover_value == cover
		else:
			all_match = all_match and tile.object_type_id.is_empty() and tile.walkable and not tile.blocks_los and tile.object_height == 0
			if tile.cover_value > 0:
				walkable_cover_count += 1
		all_match = all_match and tile.type_id in ["ground_flat", "slope_se"]
	var expected_count: int = EXPECTED_SIZE.x * EXPECTED_SIZE.y
	_check(map_data.get_tiles().size() == expected_count and unique.size() == expected_count and in_bounds and negative_q_count > 0 and negative_r_count > 0, "All%d axial cells fill96x98 offset coverage, including valid negative-q and negative-r edges" % expected_count)
	_check(all_match and solid_count > 80, "Every massive visible footprint matches saved walkability/LOS/object height/cover, with no phantom objects")
	_check(walkable_cover_count > 20, "Concrete solid edges provide usable walkable adjacent cover")
	var catalog = CATALOG.load_from_file()
	_check(catalog.has_type("frontier_scene_solid") and catalog.is_object_layer_type("frontier_scene_solid"), "Saved footprint type is a registered object layer entry")
	_check(layout.get("flat_ground") is MeshInstance3D and String(layout.get("layout_id", "")) == "gm01_frontier_outpost_v1", "Actual continuous ground and versioned layout are available to the normal view")
	var layout_root := layout.get("root") as Node3D
	_check(layout_root != null and layout_root.find_children("*Citizen*", "", true, false).is_empty() and layout_root.find_children("*Ship*", "", true, false).is_empty(), "Composition includes no preview citizens or static preview dropship")


func _test_assets(layout: Dictionary) -> void:
	var manifest_ok := true
	var manifest_paths: Dictionary = {}
	for entry in Array(layout.get("assets", [])):
		var path: String = String(entry.get("path", ""))
		manifest_paths[path] = true
		manifest_ok = manifest_ok and FileAccess.file_exists(path) and String(entry.get("sha256", "")).length() == 64 and FileAccess.get_sha256(path) == entry.get("sha256", "")
	_check(manifest_ok and manifest_paths.size() >= 3, "Every referenced model/atlas/license source has a valid real file SHA256")
	for filename in STRUCTURE_HASHES:
		var path: String = "res://Assets/curated/frontier_illustrated_20261101/structures_pass04/" + filename
		_check(manifest_paths.has(path) and FileAccess.get_sha256(path) == STRUCTURE_HASHES[filename], "Imported Frontier structure remains source-pinned: " + filename)


func _fact_fingerprint(map_data) -> String:
	var facts: Array = []
	for tile in map_data.get_tiles():
		facts.append(tile.to_dict())
	return JSON.stringify({"tiles": facts, "markers": map_data.get_markers(), "patrol": map_data.get_patrol_paths(), "tactics": map_data.get_enemy_team_configs()}).sha256_text()


func _test_roundtrip(map_data, fingerprint: String) -> void:
	var path := "user://gm01_frontier_rebuild_roundtrip.json"
	_check(map_data.save_to_file(path) == OK, "Normal TerrainMapData save writes an isolated user-data roundtrip")
	var loaded = MAP.load_from_file(path)
	_check(loaded != null and not loaded.has_load_issue() and _fact_fingerprint(loaded) == fingerprint, "Save/Load preserves every authored terrain fact, marker, patrol and tactic")
	_check(loaded.has_method("get_authored_visual_layout_id") and String(loaded.call("get_authored_visual_layout_id")) == "gm01_frontier_outpost_v1" and loaded.get_grid_topology() == HEX.TOPOLOGY_ID, "Save/Load preserves versioned layout ID and real axial hex topology")


func _test_normal_view(map_data, fingerprint: String) -> void:
	root.size = Vector2i(1280, 720)
	var view: CanvasLayer = VIEW.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var first_stage := view.get("_authored_visual_layout_root") as Node3D
	var snapshot: Dictionary = view.call("get_render_snapshot")
	var solid_count := 0
	for tile in map_data.get_tiles():
		if tile.object_type_id == "frontier_scene_solid":
			solid_count += 1
	_check(bool(snapshot.get("authored_visual_layout_active", false)) and int(snapshot.get("authored_visual_owned_tile_count", -1)) == solid_count and bool(snapshot.get("authored_visual_grid_visible", false)), "Normal view installs the saved layout, owns every solid and shows the subtle actual hex grid")
	var fog_mesh: Mesh = view.call("_make_fow_tile_overlay_mesh", 1.0)
	_check(_is_flat_hex_mesh(fog_mesh), "Authored hex visibility uses one flat six-sided surface instead of square planes or double-blended boxes")
	var budgets: Dictionary = snapshot.get("render_budget_by_category", {})
	_check(int(Dictionary(budgets.get("authored_layout", {})).get("mesh_instance_count", 0)) > 0, "Render diagnostics include the complete authored scenery")
	var negative_probe := Vector2i(-14, 34)
	var probe_tile = map_data.get_tile_at_grid(negative_probe)
	_check(probe_tile != null and bool(probe_tile.walkable), "Western negative-q probe is a real playable cell")
	if probe_tile != null:
		view.call("focus_world_position", probe_tile.world_position)
		var focus: Vector2 = view.call("get_camera_focus_grid_position")
		_check(focus.distance_to(Vector2(negative_probe)) < 0.001, "Camera can focus negative-q western ground without a zero-based clamp")
		var screen: Vector2 = view.call("world_to_screen_position", probe_tile.world_position)
		var picked: Variant = view.call("screen_to_grid_position", screen)
		_check(typeof(picked) == TYPE_VECTOR2I and Vector2i(picked) == negative_probe, "Screen picking resolves the same negative-q hex under the focused camera")
		var chunk: Vector2i = view.call("_get_ground_batch_chunk_position", negative_probe)
		_check(bool(view.call("_visual_chunk_overlaps_map", chunk)), "Streaming does not discard the playable negative-q chunk")
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for tile in map_data.get_tiles():
		var plane: Vector2 = HEX.axial_to_plane(Vector2(tile.grid_position))
		low = low.min(plane)
		high = high.max(plane)
	view.call("focus_map_center")
	var centre: Vector2 = HEX.axial_to_plane(Vector2(view.call("get_camera_focus_grid_position")))
	_check(centre.distance_to((low + high) * 0.5) < 0.001, "Map-center framing uses actual physical hex coverage instead of axial metadata midpoints")
	view.call("render_map")
	view.call("configure_from_map", map_data)
	var second_stage := view.get("_authored_visual_layout_root") as Node3D
	_check(is_instance_valid(first_stage) and first_stage == second_stage and view.find_children("FrontierGM01Outpost", "Node3D", true, false).size() == 1, "Repeated render/configure reuses one stage without duplicate scenery")
	view.call("set_authored_visual_grid_visible", true)
	snapshot = view.call("get_render_snapshot")
	_check(bool(snapshot.get("authored_visual_grid_visible", false)), "Authored actual hex grid remains explicitly available for diagnostics")
	_check(_fact_fingerprint(map_data) == fingerprint, "Normal view and debug-grid controls leave every gameplay fact unchanged")
	var legacy = MAP.create_empty("legacy_probe", Vector2i(2, 2), Vector2.ZERO)
	view.call("configure_from_map", legacy)
	snapshot = view.call("get_render_snapshot")
	_check(not bool(snapshot.get("authored_visual_layout_active", true)) and int(snapshot.get("authored_visual_owned_tile_count", -1)) == 0 and view.find_children("FrontierGM01Outpost", "Node3D", true, false).is_empty(), "Switching to a legacy map removes authored stage and object ownership")
	_check(view.call("_make_fow_tile_overlay_mesh", 1.0) is BoxMesh, "Legacy visibility overlay geometry is preserved")
	var unknown = MAP.create_empty("future_probe", Vector2i(2, 2), Vector2.ZERO)
	unknown.call("set_authored_visual_layout_id", "future_layout_v9")
	view.call("configure_from_map", unknown)
	snapshot = view.call("get_render_snapshot")
	var unknown_path := "user://gm01_frontier_unknown_layout_roundtrip.json"
	var saved: bool = unknown.save_to_file(unknown_path) == OK
	var reloaded = MAP.load_from_file(unknown_path)
	_check(not bool(snapshot.get("authored_visual_layout_active", true)) and saved and String(reloaded.call("get_authored_visual_layout_id")) == "future_layout_v9", "Unknown layout IDs remain opaque saved data and do not instantiate a guessed scene")
	view.free()


func _is_flat_hex_mesh(mesh: Mesh) -> bool:
	if not mesh is ArrayMesh or mesh.get_surface_count() != 1:
		return false
	var arrays: Array = (mesh as ArrayMesh).surface_get_arrays(0)
	var points := PackedVector2Array()
	for vertex in arrays[Mesh.ARRAY_VERTEX]:
		if absf(vertex.y) > 0.0001:
			return false
		points.append(Vector2(vertex.x, vertex.z))
	# Convex hull repeats its initial vertex: six sides therefore yield seven.
	return Geometry2D.convex_hull(points).size() == 7


func _finish(facts: Dictionary) -> void:
	var report: Dictionary = facts.duplicate(true)
	report["passed"] = passed
	report["failed"] = failed
	report["checks"] = checks
	report["scope"] = "saved authored GM01 / pure visual facts / A* / HPA / source hashes / SaveLoad; physical insertion is a separate normal-start test"
	var file := FileAccess.open("user://gm01_frontier_rebuild_verifier.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t") + "\n")
	print("GM01_FRONTIER_REBUILD_RESULT passed=%d failed=%d report=user://gm01_frontier_rebuild_verifier.json" % [passed, failed])
	quit(1 if failed > 0 else 0)
