extends SceneTree
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
var passed := 0
var failed := 0

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	var tiles: Array = []
	for r in range(8):
		for q in range(16):
			var tile := {"grid_position":{"x":q,"y":r},"type_id":"ground_flat","height_level":1 if q>=8 else 0,"walkable":true,"blocks_los":false}
			if q == 7: tile.ramp_direction = 0
			if q == 3 and r == 3:
				tile.walkable = false
				tile.blocks_los = true
				tile.object_type_id = "station_set_door_double_closed"
			tiles.append(tile)
	var raw := {"map_name":"Actual Grid Cache Regression","grid_topology":"hex_axial_v1","tactical_grid_rules":"hex_tactical_v1","regional_terrain_version":3,"terrain_height_rules":"explicit_hex_ramps_v1","grid_size":{"x":16,"y":8},"tiles":tiles}
	var file := FileAccess.open("user://grid_cache_map.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(raw)); file.close()
	var map = MAP.load_from_file("user://grid_cache_map.json")
	var registry = REGISTRY.new()
	root.add_child(registry)
	registry.configure_iso_grid(map.get_grid_origin(),64,32,"hex_axial_v1")
	for tile in map.get_tiles(): registry.register_tile(tile)
	var revision: int = registry.get_revision()
	var direct = VIEW.new()
	root.add_child(direct)
	direct.hide()
	direct.set_authoring_markers_visible(false)
	direct.set_runtime_terrain_registry(registry)
	await process_frame
	direct.configure_from_map(map)
	direct.set_process(false)
	var original := _grid_signature(direct)
	_check(original.size() == 2 and _line_count(direct) > 0, "normal regional view produces both actual ramp/plateau grid chunks")
	var producer = VIEW.new()
	root.add_child(producer)
	producer.hide()
	producer.set_authoring_markers_visible(false)
	await process_frame
	producer.configure_terrain_resource_prefill(map)
	var deadline := Time.get_ticks_msec() + 10000
	while producer.get_terrain_resource_preparation_snapshot().status == "preparing_resources" and Time.get_ticks_msec() < deadline:
		await process_frame
	var prepared: Dictionary = producer.get_terrain_resource_preparation_snapshot()
	var cache: RefCounted = producer.get_prepared_terrain_resource_cache()
	_check(prepared.ready and prepared.prepared_chunks == 2 and cache != null, "actual hidden resource prefill completes every fixture chunk")
	if cache == null:
		direct.free(); producer.free(); registry.free(); _finish(); return
	var no_grid := true
	for chunk: Dictionary in cache.get("_chunks").values(): no_grid = no_grid and not _has_grid(chunk.descriptor)
	_check(no_grid and producer.get("_hex_grid_parents").is_empty(), "static prefill retains no obsolete live-grid mesh or parent cache")
	var retained: Dictionary = cache.get_debug_snapshot()
	producer.queue_free()
	await process_frame
	var restored = VIEW.new()
	root.add_child(restored)
	restored.hide()
	restored.set_authoring_markers_visible(false)
	restored.set_runtime_terrain_registry(registry)
	await process_frame
	restored.set_prepared_terrain_resource_cache(cache)
	restored.configure_from_map(map)
	restored.set_process(false)
	var ready: Dictionary = restored.get_terrain_resource_preparation_snapshot()
	_check(ready.ready and ready.resource_restore_count == 2 and ready.geometry_build_count == 0, "receiving view restores static resources without rebuilding terrain")
	_check(_grid_signature(restored) == original, "restored live grid has exactly the same vertices as normal map rendering")
	_check(restored.get_render_snapshot().tile_grid_line_count == _line_count(restored), "restored chunk counters include the newly projected live grid")
	for view in [direct,restored]:
		view.set_fog_of_war_state({"mode":"player","team_id":"team_alpha","visible_tile_ids":[],"explored_tile_ids":[]})
		view.call("_refresh_hex_grid_projection_if_needed")
	_check(_line_count(direct) == 0 and _line_count(restored) == 0, "unknown terrain has no grid in either direct or restored view")
	_check(_grid_signature(direct) == _grid_signature(restored), "cache restore cannot resurrect the prefill's fully visible grid")
	var visible: Array = [map.get_tile_at_grid(Vector2i(7,3)).tile_id, map.get_tile_at_grid(Vector2i(8,3)).tile_id, map.get_tile_at_grid(Vector2i(3,3)).tile_id]
	for view in [direct,restored]:
		view.set_fog_of_war_state({"mode":"player","team_id":"team_alpha","visible_tile_ids":visible,"explored_tile_ids":visible})
		view.call("_refresh_hex_grid_projection_if_needed")
	_check(_grid_signature(direct) == _grid_signature(restored) and _line_count(restored) > 0, "same real visible ramp and plateau generate identical contours")
	var closed := _grid_signature(restored)
	registry.set_runtime_tile_overrides([{"grid_position":Vector2i(3,3),"walkable_override":true,"blocks_los_override":false}])
	for view in [direct,restored]: view.call("_refresh_hex_grid_projection_if_needed")
	_check(_grid_signature(restored) != closed and _grid_signature(direct) == _grid_signature(restored), "authoritative door opening updates the same visible contour after both start paths")
	_check(cache.get_debug_snapshot() == retained, "FoW and door projection never grow or mutate static cache accounting")
	_check(registry.get_revision() == revision + 1 and not map.get_tile_at_grid(Vector2i(3,3)).walkable, "views preserve authored terrain and the single explicit runtime change")
	direct.free(); restored.free(); registry.free()
	_finish()

func _has_grid(record: Dictionary) -> bool:
	if String(record.name) == "TileGridLines3D": return true
	for child: Dictionary in record.children:
		if _has_grid(child): return true
	return false

func _grid_signature(view) -> Dictionary:
	var result: Dictionary = {}
	for key in view.get("_regional_chunk_nodes"):
		var chunk: Node3D = view.get("_regional_chunk_nodes")[key]
		var grid := chunk.get_node_or_null("TileGridLines3D") as MeshInstance3D
		var arrays: Array = []
		if grid != null and grid.mesh != null:
			for surface in grid.mesh.get_surface_count(): arrays.append(grid.mesh.surface_get_arrays(surface))
		result[str(key)] = var_to_bytes(arrays).hex_encode().sha256_text()
	return result

func _line_count(view) -> int:
	var total := 0
	for record: Dictionary in view.get("_hex_grid_parents").values(): total += int(record.get("line_count",0))
	return total

func _finish() -> void:
	print("REVIEW_GRID_CACHE passed=%d failed=%d" % [passed,failed])
	quit(0 if failed == 0 else 1)
