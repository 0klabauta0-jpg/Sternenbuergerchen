extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")

class ProbeView extends "res://scripts/terrain/terrain_map_3d_view.gd":
	var quad_count: int = 0
	var pick_count: int = 0
	func _get_tile_top_screen_quad(tile) -> Array[Vector2]:
		quad_count += 1
		return super._get_tile_top_screen_quad(tile)
	func _pick_tile_at_screen_position(position: Vector2):
		pick_count += 1
		return super._pick_tile_at_screen_position(position)

# Keep real input routing and terrain picking; replace authoring callbacks so a
# motion probe cannot queue unrelated UI rebuilds or edit a checked-in map.
class ProbeEditor extends "res://scripts/editor/map_editor.gd":
	var actions: Array = []
	var brush_enabled: bool = false
	func _ready() -> void:
		set_process(false)
	func _is_pointer_over_control() -> bool:
		return false
	func _is_brush_enabled() -> bool:
		return brush_enabled
	func _apply_brush_at_world_position(position: Vector2) -> void:
		actions.append(["brush", position])
	func _apply_height_tool_at_world_position(position: Vector2) -> void:
		actions.append(["height", position])
	func _apply_eraser_at_world_position(position: Vector2) -> void:
		actions.append(["eraser", position])
	func _move_marker_to_world_position(_id: String, position: Vector2, _drag: bool = false) -> bool:
		actions.append(["marker", position])
		return true
	func _move_patrol_waypoint(_index: int, position: Vector2) -> void:
		actions.append(["patrol_drag", position])
	func _select_grid_area_from_world(_start: Vector2, finish: Vector2, _additive: bool = false) -> bool:
		actions.append(["selection_drag", finish])
		return true
	func _update_network_drag_preview_at_world_position(position: Vector2) -> bool:
		actions.append(["network_drag", position])
		return true
	func _queue_patrol_route_preview_update(position: Vector2) -> void:
		actions.append(["patrol_hover", position])
	func _queue_hover_preview_update(position: Vector2) -> void:
		actions.append(["brush_hover", position])
	func _queue_patrol_route_preview_hide() -> void:
		pass
	func _queue_hover_preview_hide() -> void:
		pass
	func _select_tile_at_world_position(position: Vector2) -> void:
		actions.append(["context_select", position])
	func _show_editor_context_menu(_position: Vector2) -> void:
		pass

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	_test_camera_motion_and_context_input()
	_test_authoring_motion_still_uses_height_correct_picks()
	_test_picking_work_is_bounded_on_large_maps()
	_test_picking_matches_exhaustive_polygon_oracle()
	print("REVIEW2_P2_EDITOR_PICKING_RESULT ", JSON.stringify({"passed": _passed, "failed": _failed}))
	if _failed == 0:
		print("REVIEW2_P2_EDITOR_PICKING_PASSED")
	quit(1 if _failed > 0 else 0)


func _make_view(map):
	var view := ProbeView.new()
	root.add_child(view)
	view.set_process(false)
	view.set("_terrain_map_data", map)
	view.call("_rebuild_render_tile_index", map.get_tiles())
	view.call("_read_map_transform")
	view.call("_update_camera_transform")
	return view


func _motion(position: Vector2, relative: Vector2 = Vector2(14, 4)) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.relative = relative
	return event


func _right_button(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = pressed
	return event


func _test_camera_motion_and_context_input() -> void:
	var map = MAP.create_empty("camera_motion", Vector2i(8, 8), Vector2.ZERO)
	var view = _make_view(map)
	var editor := ProbeEditor.new()
	root.add_child(editor)
	editor.set("_terrain_3d_view", view)
	var screen := Vector2(350, 250)
	for mode in ["_is_panning", "_is_rotating_3d_camera"]:
		editor.set(mode, true)
		view.pick_count = 0
		var before: Vector2 = view.get_camera_focus_grid_position()
		var yaw: float = view.get_camera_yaw_degrees()
		editor.call("_unhandled_input", _motion(screen))
		_assert(view.pick_count == 0, "%s motion performs zero terrain picks" % mode)
		_assert(view.get_camera_focus_grid_position() != before if mode == "_is_panning" else not is_equal_approx(view.get_camera_yaw_degrees(), yaw), "%s still changes its camera" % mode)
		editor.set(mode, false)
	view.pick_count = 0
	editor.call("_unhandled_input", _right_button(screen, true))
	editor.call("_unhandled_input", _motion(screen + Vector2(35, 0), Vector2(35, 0)))
	editor.call("_unhandled_input", _right_button(screen + Vector2(35, 0), false))
	_assert(view.pick_count == 0, "Right-camera gesture press, drag and release perform zero picks")
	view.pick_count = 0
	editor.call("_unhandled_input", _motion(screen))
	_assert(view.pick_count == 0, "Idle hover without an authoring tool performs zero picks")
	view.pick_count = 0
	editor.call("_unhandled_input", _right_button(screen, true))
	editor.call("_unhandled_input", _right_button(screen, false))
	_assert(view.pick_count == 1, "A context click resolves its tile once on release")
	_assert(editor.actions.size() == 1 and editor.actions[0][0] == "context_select", "Context click still selects before opening its menu")
	editor.free()
	view.free()


func _test_authoring_motion_still_uses_height_correct_picks() -> void:
	var map = MAP.create_empty("authoring_motion", Vector2i(8, 8), Vector2.ZERO)
	var target = map.get_tile_at_grid(Vector2i(4, 4))
	target.height_level = 2
	var view = _make_view(map)
	var camera: Camera3D = view.get("_camera")
	var screen: Vector2 = camera.unproject_position(view.call("_grid_to_3d_position", Vector2(4, 4), 1.052))
	for action in ["marker", "patrol_drag", "selection_drag", "height", "eraser", "brush", "network_drag", "patrol_hover", "brush_hover"]:
		var editor := ProbeEditor.new()
		root.add_child(editor)
		editor.set("_terrain_3d_view", view)
		match action:
			"marker":
				editor.set("_is_dragging_marker", true)
				editor.set("_dragged_marker_id", "test_marker")
				editor.set("_has_dragged_marker", true)
				editor.set("_is_panning", true) # Existing active marker drag retains priority.
			"patrol_drag":
				editor.set("_patrol_tool_enabled", true)
				editor.set("_dragged_patrol_waypoint_index", 0)
				editor.set("_is_rotating_3d_camera", true)
			"selection_drag":
				editor.set("_right_mouse_pressed", true)
				editor.set("_selection_tool_enabled", true)
				editor.set("_right_mouse_press_screen_position", screen - Vector2(50, 0))
			"height", "eraser", "brush":
				editor.set("_is_painting", true)
				if action == "height": editor.set("_height_tool_enabled", true)
				if action == "eraser": editor.set("_eraser_tool_enabled", true)
				if action == "brush":
					editor.brush_enabled = true
					editor.set("_selected_type_id", "ground_flat")
			"network_drag":
				editor.set("_is_network_dragging", true)
			"patrol_hover":
				editor.set("_patrol_tool_enabled", true)
			"brush_hover":
				editor.brush_enabled = true
		view.pick_count = 0
		editor.call("_unhandled_input", _motion(screen))
		_assert(view.pick_count == 1, "%s uses one terrain pick" % action)
		_assert(editor.actions.size() == 1 and editor.actions[0][0] == action and Vector2(editor.actions[0][1]).is_equal_approx(target.world_position), "%s receives the raised tile's world center" % action)
		editor.free()
	view.free()


func _test_picking_work_is_bounded_on_large_maps() -> void:
	for side in [128, 256]:
		var map = MAP.create_empty("large_pick", Vector2i(side, side), Vector2.ZERO)
		var view = _make_view(map)
		var camera: Camera3D = view.get("_camera")
		var grid := Vector2i(side / 2, side / 2)
		var screen: Vector2 = camera.unproject_position(view.call("_grid_to_3d_position", Vector2(grid), 0.052))
		view.quad_count = 0
		var picked = view.call("_pick_tile_at_screen_position", screen)
		_assert(picked != null and picked.grid_position == grid, "%d map picks the visible center tile" % side)
		_assert(view.quad_count <= 27, "%d map projects at most 27 candidate polygons, got %d" % [side, view.quad_count])
		print("PICK_OPERATIONS ", JSON.stringify({"side": side, "tiles": side * side, "candidate_polygons": view.quad_count}))
		view.free()


func _test_picking_matches_exhaustive_polygon_oracle() -> void:
	for topology in ["square8", "hex_axial_v1"]:
		var map = MAP.create_empty("height_pick_oracle", Vector2i(8, 8), Vector2(80, 40), 64.0, 32.0, 3, topology)
		for tile in map.get_tiles():
			tile.height_level = (tile.grid_position.x + 2 * tile.grid_position.y) % 3
		var view = _make_view(map)
		var camera: Camera3D = view.get("_camera")
		for yaw in [0.0, 45.0, 140.0, 255.0]:
			view.set("_camera_yaw_degrees", yaw)
			view.call("_update_camera_transform")
			var mismatches: int = 0
			for tile in map.get_tiles():
				var quad: Array[Vector2] = view.call("_get_tile_top_screen_quad", tile)
				var center: Vector2 = camera.unproject_position(view.call("_grid_to_3d_position", Vector2(tile.grid_position), tile.height_level * 0.5 + 0.052))
				for screen in [center, center.lerp(quad[0], 0.85), center.lerp(quad[1], 0.85), quad[0], quad[0].lerp(quad[1], 0.5)]:
					var expected = _exhaustive_pick(view, map, Vector2(screen))
					var actual = view.call("_pick_tile_at_screen_position", Vector2(screen))
					if actual != expected:
						mismatches += 1
			_assert(mismatches == 0, "%s yaw %.0f matches the original exhaustive polygon oracle including overlapping heights (%d mismatches)" % [topology, yaw, mismatches])
		var edited = map.get_tile_at_grid(Vector2i(3, 3))
		edited.height_level = 2
		var edited_screen: Vector2 = camera.unproject_position(view.call("_grid_to_3d_position", Vector2(3, 3), 1.052))
		_assert(view.call("_pick_tile_at_screen_position", edited_screen) == _exhaustive_pick(view, map, edited_screen), "%s picking reads an in-place height edit" % topology)
		_assert(view.call("_pick_tile_at_screen_position", Vector2(-100000, -100000)) == null, "%s off-map pick returns no tile" % topology)
		for tile in map.get_tiles():
			tile.height_level = 0
		# Loaded maps may list tiles in a different order; ties must still use
		# that source order instead of ray-plane/candidate enumeration order.
		var reversed_tiles: Array = map.get_tiles()
		reversed_tiles.reverse()
		map.set("_tiles", reversed_tiles)
		view.call("_rebuild_render_tile_index", reversed_tiles)
		for yaw in [0.0, 90.0, 180.0, 270.0]:
			view.set("_camera_yaw_degrees", yaw)
			view.call("_update_camera_transform")
			var boundary_mismatches: int = 0
			for tile in map.get_tiles():
				var quad: Array[Vector2] = view.call("_get_tile_top_screen_quad", tile)
				for screen in [quad[0], quad[0].lerp(quad[1], 0.5)]:
					if view.call("_pick_tile_at_screen_position", screen) != _exhaustive_pick(view, map, screen):
						boundary_mismatches += 1
			_assert(boundary_mismatches == 0, "%s flat terrain yaw %.0f retains boundary winners (%d mismatches)" % [topology, yaw, boundary_mismatches])
		view.free()


# Independent exhaustive reference keeps the old public picking behavior while
# allowing the implementation to narrow its candidate set.
func _exhaustive_pick(view, map, screen: Vector2):
	var camera: Camera3D = view.get("_camera")
	var best = null
	var best_score: float = INF
	var forward: Vector3 = -camera.global_transform.basis.z.normalized()
	for tile in map.get_tiles():
		var quad: Array[Vector2] = view.call("_get_tile_top_screen_quad", tile)
		if not bool(view.call("_screen_point_is_inside_convex_quad", screen, quad)):
			continue
		var center: Vector3 = view.call("_grid_to_3d_position", Vector2(tile.grid_position), tile.height_level * 0.5 + 0.095)
		var score: float = (center - camera.global_position).dot(forward) + screen.distance_squared_to(camera.unproject_position(center)) * 0.0001
		if score < best_score:
			best_score = score
			best = tile
	return best


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)
