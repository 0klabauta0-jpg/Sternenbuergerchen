extends SceneTree
## Actual default-map rendering state over multiple frames; no gameplay writes.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)

func run() -> void:
	var data = MAP.load_from_file("res://maps/Ground_Mission01_32x32.json")
	var view = VIEW.new()
	root.add_child(view)
	view.configure_from_map(data)
	check(data.get_grid_topology() == "hex_axial_v1", "Default mission is a real Hex map")
	var known := {"mode":"known_terrain", "team_id":"team_alpha", "terrain_knowledge":{"visible_tile_ids":[]}, "current_visibility":{"visible_target_ids":["visible_enemy"]}}
	view.set_fog_of_war_state(known)
	var flashes := 0
	for iteration in range(12):
		if iteration == 6:
			view.render_map()
		if is_instance_valid(view.get("_fow_overlay_safety_cover")):
			flashes += 1
		await process_frame
	check(flashes == 0, "Known terrain never receives a temporary all-black rectangle, including a cold rebuild")
	check(bool(view.call("_fow_is_target_currently_visible", "visible_enemy")) and not bool(view.call("_fow_is_target_currently_visible", "hidden_enemy")), "Removing the known-map flash preserves dynamic enemy filtering")
	var snapshot: Dictionary = view.get_render_snapshot()
	check(int(snapshot.get("tile_grid_line_count", 0)) > 0 and bool(snapshot.get("authored_visual_grid_visible", false)), "Actual Hex edges are visible by default")
	var mask: ArrayMesh = view.call("_make_fow_tile_overlay_mesh", 1.0)
	check(mask != null and mask.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 18, "Visibility mask has six flat triangles, without doubled prism faces")
	var blackout := known.duplicate(true)
	blackout["mode"] = "unexplored_blackout"
	view.set_fog_of_war_state(blackout)
	check(is_instance_valid(view.get("_fow_overlay_safety_cover")), "Unexplored mode retains its protective blackout while unknown cells are batched")
	var cover := view.get("_fow_overlay_safety_cover") as Node3D
	check(cover.position.y > float(view.get("_authored_visual_top_y")) and cover.position.y > 3.0, "Unknown protection is above the actual tall meshes, independently of gameplay height classes")
	for iteration in range(8):
		await process_frame
	snapshot = view.get_render_snapshot()
	check(not is_instance_valid(view.get("_fow_overlay_safety_cover")) and int(snapshot.get("fow_unknown_tile_count", 0)) > 0, "Completed unknown-cell masks replace the temporary cover")
	var west := Vector2i(-16, 40)
	var world: Vector2 = data.call("_grid_to_world", west)
	view.focus_world_position(world)
	view.call("_clamp_focus_to_map")
	check(view.get_camera_focus_grid_position().distance_to(Vector2(west)) < 0.01, "Negative axial coordinates remain reachable by the real camera clamp")
	check(bool(view.call("_visual_chunk_overlaps_map", Vector2i(-1, 3))) and not bool(view.call("_visual_chunk_overlaps_map", Vector2i(100, 3))), "Streaming bounds include negative Hex chunks and reject distant chunks")
	view.focus_map_center()
	var plane: Vector2 = view.get("_map_plane_bounds").get_center()
	var hex = preload("res://scripts/terrain/hex_grid.gd")
	check(hex.axial_to_plane(view.get_camera_focus_grid_position()).distance_to(plane) < 0.01, "Default framing uses the physical Hex footprint")
	var before_pan: Vector2 = hex.axial_to_plane(view.get_camera_focus_grid_position())
	var yaw := deg_to_rad(view.get_camera_yaw_degrees())
	view.pan_camera(Vector2.UP, 0.02)
	var movement: Vector2 = hex.axial_to_plane(view.get_camera_focus_grid_position()) - before_pan
	var expected := Vector2(-sin(yaw), -cos(yaw))
	check(movement.normalized().dot(expected) > 0.999, "Keyboard and drag panning use the camera's physical directions on Hex terrain")
	view.free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	print("GM01_HEX_FOW_ALL_PASS" if failed == 0 else "GM01_HEX_FOW_FAILED")
	quit(0 if failed == 0 else 1)
