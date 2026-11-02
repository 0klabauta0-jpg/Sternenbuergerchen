extends SceneTree
## Real saved edge facts + renderer picking/FoW. No actors or timers patched.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const AUTHORING = preload("res://scripts/tools/build_gm01_frontier.gd")
const SOURCE := "res://maps/Ground_Mission01_32x32.json"
const PROBES := {"west": Vector2i(-24, 0), "east": Vector2i(71, 0), "north": Vector2i(13, -25), "south": Vector2i(-36, 72)}
const OUTSIDE := {"west": Vector2i(-28, 0), "east": Vector2i(75, 0), "north": Vector2i(15, -29), "south": Vector2i(-38, 76)}
var passed := 0
var failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)


func _settle_mask(view: Node) -> void:
	for _frame in range(48):
		await process_frame
		if not bool(view.get("_fow_overlay_full_rebuild_pending")):
			return
	_check(false, "Full-map visibility mask finishes its bounded batch build")


func _valid_path(path: Array, from: Vector2i, to: Vector2i, registry: Node) -> bool:
	if path.is_empty() or Vector2i(path.front()) != from or Vector2i(path.back()) != to:
		return false
	for index in range(path.size()):
		if not bool(registry.call("is_walkable", path[index])):
			return false
		if index > 0 and not HEX.are_neighbors(Vector2i(path[index - 1]), Vector2i(path[index])):
			return false
	return true


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i.ZERO
	var source_sha := FileAccess.get_sha256(SOURCE)
	var data = MAP.load_from_file(SOURCE)
	_check(data != null and not data.has_load_issue() and data.get_grid_topology() == "hex_axial_v1", "Regular saved GM01 loads through the actual Hex contract")
	if data == null or data.has_load_issue():
		_finish()
		return
	var tiles: Dictionary = {}
	var rows: Dictionary = {}
	for tile in data.get_tiles():
		tiles[tile.grid_position] = tile
		var column: int = tile.grid_position.x + floori(float(tile.grid_position.y) * 0.5)
		var columns: Dictionary = rows.get(tile.grid_position.y, {})
		columns[column] = true
		rows[tile.grid_position.y] = columns
	var complete := rows.size() == 98
	for row in range(-25, 73):
		var columns: Dictionary = rows.get(row, {})
		complete = complete and columns.size() == 96
		for column in range(-24, 72):
			complete = complete and columns.has(column)
	_check(data.get_grid_size() == Vector2i(96, 98) and tiles.size() == 9408 and complete, "All 9408 real cells fill 96 columns and 98 rows without gaps, including negative r")
	var registry: Node = REGISTRY.new()
	var tile_size: Dictionary = data.get_tile_size()
	registry.call("configure_iso_grid", data.get_grid_origin(), float(tile_size["half_width"]), float(tile_size["half_height"]), data.get_grid_topology())
	for tile in tiles.values():
		registry.call("register_tile", tile)
	var revision := int(registry.call("get_revision"))
	var spawn: Vector2i = registry.call("world_to_grid", data.get_marker_position("spawn_alpha"))
	var finder = PATHFINDER.new()
	for side in PROBES:
		var grid: Vector2i = PROBES[side]
		_check(tiles.has(grid) and bool(registry.call("is_walkable", grid)), side + " edge is actual saved selectable/walkable ground")
		var path: Array = finder.find_path(spawn, grid, registry)
		_check(_valid_path(path, spawn, grid, registry), side + " edge has an actual legal six-neighbor route from the original insertion")
		_check(not tiles.has(OUTSIDE[side]) and not bool(registry.call("is_walkable", OUTSIDE[side])), side + " exterior has no invented gameplay cell")
	var west_move := Vector2i(-8, 12)
	_check(_valid_path(finder.find_path(spawn, west_move, registry), spawn, west_move, registry) and HEX.axial_to_plane(Vector2(west_move)).x < 0.0, "Native GO target (-8,12) is reachable beyond the former western border")
	var view: CanvasLayer = VIEW.new()
	root.add_child(view)
	view.call("configure_from_map", data)
	var snapshot: Dictionary = view.call("get_render_snapshot")
	_check(bool(snapshot.get("ground_matches_saved_hex_coverage", false)) and int(snapshot.get("authored_ground_cell_count", 0)) == tiles.size(), "Runtime ground consumes precisely the loaded MapData cells, not an offline fallback")
	_check(not bool(snapshot.get("visual_streaming_active", true)), "Fixed authored ground/grid/FoW stay resident rather than rebuilding on camera chunks")
	_test_ground_mesh(view, tiles)
	var known := {"mode": "known_terrain", "team_id": "team_alpha", "terrain_knowledge": {"visible_tile_ids": []}, "current_visibility": {"visible_target_ids": ["visible_enemy"]}}
	view.call("set_fog_of_war_state", known)
	await _settle_mask(view)
	var refresh_before := int(view.get("_visual_streaming_refresh_count"))
	for side in PROBES:
		var grid: Vector2i = PROBES[side]
		var tile = tiles[grid]
		view.call("focus_world_position", tile.world_position)
		view.call("_clamp_focus_to_map")
		await process_frame
		_check(Vector2(view.call("get_camera_focus_grid_position")).distance_to(Vector2(grid)) < 0.001, side + " edge survives actual camera bounds, including negative coordinates")
		var screen: Vector2 = view.call("world_to_screen_position", tile.world_position)
		var picked: Variant = view.call("screen_to_grid_position", screen)
		_check(typeof(picked) == TYPE_VECTOR2I and Vector2i(picked) == grid, side + " edge is picked as the exact real Hex")
		var exterior_world: Vector2 = AUTHORING.grid_to_world(OUTSIDE[side])
		var exterior_screen: Vector2 = view.call("world_to_screen_position", exterior_world)
		_check(view.call("screen_to_grid_position", exterior_screen) == null, side + " outside surface is not silently clamped to a playable Hex")
		var known_states: Dictionary = view.get("_fow_overlay_tile_states_by_id")
		_check(String(known_states.get(tile.tile_id, "missing")) == "known", side + " real edge receives the same known-terrain mask")
	_check(int(view.get("_visual_streaming_refresh_count")) == refresh_before, "Camera travel to all edges causes no full authored map/grid/FoW rebuild")
	_check(bool(view.call("_fow_is_target_currently_visible", "visible_enemy")) and not bool(view.call("_fow_is_target_currently_visible", "hidden_enemy")), "Full ground coverage preserves the independent dynamic enemy visibility gate")
	var blackout: Dictionary = known.duplicate(true)
	blackout["mode"] = "unexplored_blackout"
	view.call("set_fog_of_war_state", blackout)
	await _settle_mask(view)
	snapshot = view.call("get_render_snapshot")
	_check(int(snapshot.get("fow_unknown_tile_count", 0)) == tiles.size(), "Unknown mask protects all 9408 cells up to the real map edge")
	var unknown_states: Dictionary = view.get("_fow_overlay_tile_states_by_id")
	for side in PROBES:
		_check(String(unknown_states.get(tiles[PROBES[side]].tile_id, "missing")) == "unknown", side + " edge stays unknown in blackout mode")
	var roundtrip := "user://gm01_map_edge_roundtrip.json"
	var saved: bool = data.save_to_file(roundtrip) == OK
	var loaded = MAP.load_from_file(roundtrip)
	var edges_roundtrip := loaded != null and not loaded.has_load_issue() and loaded.get_tiles().size() == tiles.size()
	for grid in PROBES.values():
		edges_roundtrip = edges_roundtrip and loaded != null and loaded.get_tile_at_grid(grid) != null
	_check(saved and edges_roundtrip, "Normal Save/Load retains every new edge and negative row")
	var small = MAP.create_empty("same_id_small_probe", Vector2i(2, 2), Vector2.ZERO, 64.0, 32.0, 3, "hex_axial_v1")
	small.set_authored_visual_layout_id("gm01_frontier_outpost_v1")
	view.call("configure_from_map", small)
	snapshot = view.call("get_render_snapshot")
	_check(int(snapshot.get("authored_ground_cell_count", -1)) == 4 and int(snapshot.get("authored_ground_vertex_count", 0)) == 28 and bool(snapshot.get("ground_matches_saved_hex_coverage", false)), "Same-layout map switch uses its four actual saved cells, never leaves the large ground behind")
	_check(String(Dictionary(snapshot.get("editor_light", {})).get("background_color", "")) == "102c38ff", "Only the actual authored GM01 has a distinct dark offmap background instead of apparent sand")
	var legacy = MAP.create_empty("map_edge_legacy_probe", Vector2i(2, 2), Vector2.ZERO)
	view.call("configure_from_map", legacy)
	snapshot = view.call("get_render_snapshot")
	_check(not bool(snapshot.get("authored_visual_layout_active", true)) and int(snapshot.get("authored_ground_cell_count", -1)) == 0, "Legacy map switch removes the authored ground and its diagnostics")
	var legacy_background: String = "aa6e58ff" if bool(view.get("_frontier_art_enabled")) else VIEW.EDITOR_EMPTY_BACKGROUND_COLOR.to_html(true)
	_check(String(Dictionary(snapshot.get("editor_light", {})).get("background_color", "")) == legacy_background, "Plain legacy map switch restores its normal editor/art-profile background")
	legacy.set_terrain_visual_theme_id("frontier_illustrated_v1")
	view.call("configure_from_map", legacy)
	snapshot = view.call("get_render_snapshot")
	_check(String(Dictionary(snapshot.get("editor_light", {})).get("background_color", "")) == "aa6e58ff", "Generic Frontier maps retain their existing art-profile background without the GM01-only override")
	_check(int(registry.call("get_revision")) == revision and FileAccess.get_sha256(SOURCE) == source_sha, "Ground, camera, masks, picking and roundtrip tests do not mutate source/Registry facts")
	view.free()
	registry.free()
	await process_frame
	_finish()


func _test_ground_mesh(view: Node, tiles: Dictionary) -> void:
	var facts: Dictionary = view.get("_authored_visual_layout_facts")
	var ground := facts.get("flat_ground") as MeshInstance3D
	if ground == null or not ground.mesh is ArrayMesh or ground.mesh.get_surface_count() != 1:
		_check(false, "Authored ground is a real bounded Hex-union mesh")
		return
	var arrays: Array = ground.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var clockwise_top := normals.size() == vertices.size()
	for index in range(0, indices.size(), 3):
		var a: Vector3 = vertices[indices[index]]
		var b: Vector3 = vertices[indices[index + 1]]
		var c: Vector3 = vertices[indices[index + 2]]
		clockwise_top = clockwise_top and (b - a).cross(c - a).y < -0.00001
	for normal in normals:
		clockwise_top = clockwise_top and normal.dot(Vector3.UP) > 0.999
	_check(clockwise_top, "Every ground face uses Godot clockwise top-facing winding with upward shading normals")
	var geometry_matches := vertices.size() == tiles.size() * 7 and indices.size() == tiles.size() * 18
	var found: Dictionary = {}
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for cell_index in range(vertices.size() / 7):
		var center: Vector3 = vertices[cell_index * 7]
		var grid: Vector2i = HEX.round_axial(HEX.plane_to_axial(Vector2(center.x, center.z)))
		found[grid] = true
		geometry_matches = geometry_matches and tiles.has(grid)
		var corners: PackedVector2Array = HEX.corners(HEX.axial_to_plane(Vector2(grid)))
		for corner_index in range(6):
			var vertex: Vector3 = vertices[cell_index * 7 + corner_index + 1]
			var plane := Vector2(vertex.x, vertex.z)
			geometry_matches = geometry_matches and plane.distance_to(corners[corner_index]) < 0.0002 and absf(vertex.y - 0.0015) < 0.0001
			low = low.min(plane)
			high = high.max(plane)
	_check(geometry_matches and found.size() == tiles.size(), "Every rendered ground polygon belongs to exactly one saved Hex; no decorative outside PlaneMesh")
	var bounds: AABB = ground.mesh.get_aabb()
	_check(Vector2(bounds.position.x, bounds.position.z).distance_to(low) < 0.001 and Vector2(bounds.end.x, bounds.end.z).distance_to(high) < 0.001 and low.x < -24.0 and low.y < -21.65 and high.x > 71.75 and high.y > 62.35, "Exact scalloped Hex boundary encloses the formerly visible 96x84m ground")
	_check(ground.position.is_zero_approx(), "Ground reconstruction preserves the original world-XZ material and model anchors")


func _finish() -> void:
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	print("GM01_FRONTIER_MAP_EDGE_ALL_PASS" if failed == 0 else "GM01_FRONTIER_MAP_EDGE_FAILED")
	quit(0 if failed == 0 else 1)
