extends SceneTree
## Offline authoring only. Runtime visuals never call this writer.
## Run after importing assets: godot --headless --path . -s this_file.gd
## An optional --output=res://... writes a candidate instead of the regular map.

const LAYOUT = preload("res://scripts/terrain/frontier_gm01_layout.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const MISSION_SETUP = preload("res://scripts/tests/mission_test_setup.gd")
const ORIGINAL := "res://docs/qa/gm01_frontier_20261102/original_Ground_Mission01_32x32.json"
const OUTPUT := "res://maps/Ground_Mission01_32x32.json"
const SCENARIO := "res://data/mission_scenarios/ground_mission01_default.json"
const SOLID_TYPE := "frontier_scene_solid"
const GRID_SIZE := LAYOUT.GRID_SIZE
const MAP_NAME := "GM01 Frontier Hex 96x98"
const EXTENSION_PLANES := [Vector2(35, 27), Vector2(42, 26), Vector2(43, 30)]
const MARKER_PLANES := {
	"spawn_alpha": Vector2(6, 11),
	"objective_point": Vector2(11, 12),
	"spawn_enemy_defense": Vector2(13, 13),
	"spawn_enemy_patrol": Vector2(17, 11),
	"spawn_bravo": Vector2(21, 12),
}
const PATROL_PLANES := [Vector2(17, 11), Vector2(20, 11), Vector2(20, 13), Vector2(17, 13)]
const TERRACE := Rect2(18.5, 18.5, 5.0, 4.0)
const RAMP_FROM := Vector2i(6, 24)
const RAMP_BRIDGE := Vector2i(7, 24)
const RAMP_TO := Vector2i(8, 24)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node3D.new()
	root.add_child(host)
	var layout: Dictionary = LAYOUT.build(host)
	var payload: Dictionary = compose_payload(layout)
	var issues: PackedStringArray = validate_payload(payload, layout)
	if not issues.is_empty():
		for issue in issues:
			push_error("GM01 authoring refused: " + issue)
		host.free()
		quit(1)
		return
	var output_path: String = OUTPUT
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	if output_path == ORIGINAL or output_path == SCENARIO:
		push_error("GM01 authoring refuses to overwrite the original QA snapshot or scenario")
		host.free()
		quit(1)
		return
	var output_file := FileAccess.open(output_path, FileAccess.WRITE)
	if output_file == null:
		push_error("Could not write GM01 candidate: %s (%s)" % [output_path, FileAccess.get_open_error()])
		host.free()
		quit(1)
		return
	output_file.store_string(JSON.stringify(payload, "\t", true) + "\n")
	output_file.flush()
	output_file.close()
	print("GM01_FRONTIER_AUTHORED path=%s layout=%s tiles=%d blockers=%d sha256=%s" % [
		output_path, payload.get("authored_visual_layout_id", ""),
		Array(payload.get("tiles", [])).size(), Array(layout.get("blockers", [])).size(),
		FileAccess.get_sha256(output_path),
	])
	host.free()
	quit(0)


static func read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if parsed is Dictionary else {}


static func grid_to_world(grid: Vector2i) -> Vector2:
	var plane: Vector2 = HEX.axial_to_plane(Vector2(grid))
	return Vector2((plane.x - plane.y) * 64.0, (plane.x + plane.y) * 32.0)


static func plane_to_grid(plane: Vector2) -> Vector2i:
	return HEX.round_axial(HEX.plane_to_axial(plane))


static func marker_grid(marker_id: String) -> Vector2i:
	return plane_to_grid(MARKER_PLANES.get(marker_id, Vector2.ZERO))


static func footprint_contains(record: Dictionary, grid: Vector2i) -> bool:
	var rect: Rect2 = record.get("rect", Rect2())
	if not rect.has_area():
		return false
	# Intersect the real six-sided cell with the visible model's envelope.
	# Only a tiny contact tolerance is added, never a square cell mask.
	rect = rect.grow(0.015)
	var polygon := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	return not Geometry2D.intersect_polygons(HEX.corners(HEX.axial_to_plane(Vector2(grid))), polygon).is_empty()


static func compose_payload(layout: Dictionary) -> Dictionary:
	# Preserve all scenario-facing metadata and editor marker descriptors verbatim.
	var payload: Dictionary = read_dictionary(ORIGINAL).duplicate(true)
	if payload.is_empty() or String(layout.get("layout_id", "")) != LAYOUT.LAYOUT_ID:
		return {}
	payload["grid_topology"] = HEX.TOPOLOGY_ID
	payload["grid_size"] = {"x": GRID_SIZE.x, "y": GRID_SIZE.y}
	payload["map_name"] = MAP_NAME
	payload["terrain_visual_theme_id"] = "frontier_illustrated_v1"
	payload["authored_visual_layout_id"] = LAYOUT.LAYOUT_ID
	var markers: Dictionary = Dictionary(payload.get("markers", {}))
	for marker_id in MARKER_PLANES:
		var marker: Dictionary = Dictionary(markers.get(marker_id, {}))
		var world: Vector2 = grid_to_world(marker_grid(marker_id))
		# Marker/Patrol serialization intentionally uses the established integer
		# world coordinates; nearest rounding preserves the selected axial cell.
		marker["x"] = int(round(world.x))
		marker["y"] = int(round(world.y))
		markers[marker_id] = marker
	payload["markers"] = markers
	var patrol: Array = []
	for plane in PATROL_PLANES:
		var world: Vector2 = grid_to_world(plane_to_grid(plane))
		patrol.append({"x": int(round(world.x)), "y": int(round(world.y))})
	payload["patrol_paths"] = {"ground_patrol_route": patrol}
	var tiles: Array = []
	var by_grid: Dictionary = {}
	# Rectangular odd-row coverage in physical space; the saved keys remain
	# genuine axial coordinates, including negative q on the western side.
	# Iterate q/r in save order so normal MapData Save/Load is order-stable.
	for grid in LAYOUT.get_authoring_grid_positions():
		var plane: Vector2 = HEX.axial_to_plane(Vector2(grid))
		var tile: Dictionary = {
			"grid_position": {"x": grid.x, "y": grid.y}, "type_id": "ground_flat",
			"walkable": true, "blocks_los": false, "cover_value": 0,
			"height_level": 0, "object_height": 0, "surface_type": "sand", "edge_type": "none",
		}
		if _on_authored_path(plane, Array(layout.get("paths", []))):
			tile["surface_type"] = "road"
		# Existing height contract remains a four-cell-wide loading-yard terrace.
		if TERRACE.has_point(plane):
			tile["height_level"] = 1
			tile["surface_type"] = "ground"
			tile["edge_type"] = "slope" if plane.x < 19.5 else "cliff"
			tile["type_id"] = "slope_se" if plane.x < 19.5 else "ground_flat"
		for blocker_variant in Array(layout.get("blockers", [])):
			var blocker: Dictionary = blocker_variant
			if not footprint_contains(blocker, grid):
				continue
			tile["object_type_id"] = SOLID_TYPE
			tile["walkable"] = false
			tile["blocks_los"] = bool(tile["blocks_los"]) or bool(blocker.get("blocks_los", true))
			tile["object_height"] = maxi(int(tile["object_height"]), int(blocker.get("object_height", 1)))
			tile["cover_value"] = maxi(int(tile["cover_value"]), int(blocker.get("cover_value", 0)))
		tiles.append(tile)
		by_grid[grid] = tile
	# Adjacent usable cover comes from actual solid edges, never random ground tags.
	for grid_variant in by_grid:
		var grid: Vector2i = grid_variant
		var tile: Dictionary = by_grid[grid]
		if not bool(tile["walkable"]):
			continue
		for direction in HEX.neighbor_directions():
			var adjacent: Dictionary = by_grid.get(grid + direction, {})
			if not adjacent.is_empty() and not bool(adjacent.get("walkable", true)):
				tile["cover_value"] = maxi(int(tile["cover_value"]), mini(50, int(float(adjacent.get("cover_value", 0)) * 0.65)))
	payload["tiles"] = tiles
	return payload


static func _on_authored_path(point: Vector2, paths: Array) -> bool:
	for path_variant in paths:
		var path: Dictionary = path_variant
		var points: Array = path.get("points", [])
		var radius: float = maxf(float(path.get("width", 1.0)) * 0.5, 0.15)
		for index in range(1, points.size()):
			var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(point, Vector2(points[index - 1]), Vector2(points[index]))
			if point.distance_to(nearest) <= radius:
				return true
	return false


static func make_registry(payload: Dictionary) -> Node:
	var registry: Node = REGISTRY.new()
	registry.call("configure_iso_grid", Vector2.ZERO, 64.0, 32.0, HEX.TOPOLOGY_ID)
	for tile_variant in Array(payload.get("tiles", [])):
		var facts: Dictionary = Dictionary(tile_variant).duplicate(true)
		var saved_grid: Dictionary = facts.get("grid_position", {})
		var grid := Vector2i(int(saved_grid.get("x", 0)), int(saved_grid.get("y", 0)))
		facts["grid_position"] = grid
		facts["world_position"] = grid_to_world(grid)
		facts["tile_id"] = "tile_%d_%d" % [grid.x, grid.y]
		registry.call("register_tile", TILE.from_dict(facts))
	return registry


static func validate_payload(payload: Dictionary, layout: Dictionary) -> PackedStringArray:
	var issues := PackedStringArray()
	if payload.is_empty():
		issues.append("Original map or shared layout is missing")
		return issues
	if Array(payload.get("tiles", [])).size() != GRID_SIZE.x * GRID_SIZE.y:
		issues.append("Expected exactly%d authored cells" % (GRID_SIZE.x * GRID_SIZE.y))
	var saved_size: Dictionary = payload.get("grid_size", {})
	if Vector2i(int(saved_size.get("x", 0)), int(saved_size.get("y", 0))) != GRID_SIZE:
		issues.append("Expected the real 96x98 odd-row hex coverage up to the visible map edge")
	if String(payload.get("grid_topology", "")) != HEX.TOPOLOGY_ID:
		issues.append("Expected real hex_axial_v1 gameplay topology")
	if Array(layout.get("blockers", [])).is_empty() or Array(layout.get("assets", [])).is_empty():
		issues.append("Expected real imported assets and source footprints")
	for blocker_variant in Array(layout.get("blockers", [])):
		var blocker: Dictionary = blocker_variant
		var rect: Rect2 = blocker.get("rect", Rect2())
		if not rect.has_area() or int(blocker.get("object_height", 0)) < 1 or int(blocker.get("object_height", 0)) > 3:
			issues.append("Invalid solid footprint: %s" % blocker.get("id", "?"))
	var registry: Node = make_registry(payload)
	var pathfinder: RefCounted = PATHFINDER.new()
	for marker_id in MARKER_PLANES:
		if not bool(registry.call("is_walkable", marker_grid(marker_id))):
			issues.append("Marker conflicts with a visible solid: " + marker_id)
	var setup: Node = MISSION_SETUP.new()
	for index in range(8):
		var world: Vector2 = grid_to_world(marker_grid("spawn_alpha")) + Vector2(setup.call("_get_friendly_spawn_offset", index))
		var grid: Vector2i = registry.call("world_to_grid", world)
		if not bool(registry.call("is_walkable", grid)):
			issues.append("Friendly spawn slot%d is blocked at%s" % [index, grid])
	var enemy_index: int = 0
	for group_variant in Array(read_dictionary(SCENARIO).get("enemy_groups", [])):
		var group: Dictionary = group_variant
		var marker_id: String = String(group.get("spawn_marker_id", ""))
		for enemy_id in Array(group.get("enemy_ids", [])):
			var world: Vector2 = grid_to_world(marker_grid(marker_id)) + Vector2(setup.call("_get_enemy_spawn_offset", enemy_index))
			var grid: Vector2i = registry.call("world_to_grid", world)
			if not bool(registry.call("is_walkable", grid)):
				issues.append("Enemy%s global slot%d is blocked at%s" % [enemy_id, enemy_index, grid])
			enemy_index += 1
	setup.free()
	var route_pairs: Array = [[marker_grid("spawn_alpha"), marker_grid("objective_point")], [marker_grid("spawn_enemy_defense"), marker_grid("objective_point")], [marker_grid("spawn_bravo"), marker_grid("objective_point")], [RAMP_FROM, RAMP_TO]]
	for index in range(PATROL_PLANES.size()):
		route_pairs.append([plane_to_grid(PATROL_PLANES[index]), plane_to_grid(PATROL_PLANES[(index + 1) % PATROL_PLANES.size()])])
	# The extension is actual accessible content, not a wider visual backdrop.
	for plane in EXTENSION_PLANES:
		var target: Vector2i = plane_to_grid(plane)
		route_pairs.append([marker_grid("spawn_alpha"), target])
		if not bool(registry.call("is_walkable", target)):
			issues.append("New supply-yard/outer access anchor is blocked at%s" % target)
	# New real ground on all four sides must connect to the original insertion.
	for grid in [Vector2i(-8, 12), Vector2i(-24, 0), Vector2i(71, 0), Vector2i(13, -25), Vector2i(-36, 72)]:
		route_pairs.append([marker_grid("spawn_alpha"), grid])
		if not bool(registry.call("is_walkable", grid)):
			issues.append("New map-edge probe is not real walkable ground at%s" % grid)
	for pair in route_pairs:
		if Array(pathfinder.call("find_path", pair[0], pair[1], registry)).is_empty():
			issues.append("Disconnected required route %s→%s" % [pair[0], pair[1]])
	registry.free()
	return issues
