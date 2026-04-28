extends SceneTree

const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const RENDER_SPIKE_SCENE: PackedScene = preload("res://scenes/tests/mission_map_3d_render_spike.tscn")
const TERRAIN_25D_CAMERA_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_camera_controller.gd")
const TERRAIN_25D_PICKER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_picker.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_139 2.5D Camera and Picking Verifier ===")
	_test_camera_controller_api()
	_test_picker_resolves_default_and_floor_hits()
	_test_pick_snapshot_can_feed_command_target()
	await _test_scene_picking_survives_rotation_and_zoom()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_camera_controller_api() -> void:
	var camera := Camera3D.new()
	root.add_child(camera)
	var controller = TERRAIN_25D_CAMERA_CONTROLLER_SCRIPT.new()
	controller.call("bind_camera", camera)
	var initial_focus: Vector3 = Vector3(controller.call("get_focus"))
	controller.call("rotate_by", 90.0)
	var after_rotation_focus: Vector3 = Vector3(controller.call("get_focus"))
	controller.call("pan_by_world", Vector3(2.0, 0.0, -1.0))
	var after_pan_focus: Vector3 = Vector3(controller.call("get_focus"))
	controller.call("zoom_by_steps", -2)
	_assert(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Camera controller keeps an orthographic camera")
	_assert(after_rotation_focus == initial_focus, "Camera rotation keeps focus stable")
	_assert(after_pan_focus != initial_focus, "Camera pan changes focus through the controller API")
	_assert(float(controller.call("get_camera_size")) < 14.0, "Camera zoom API changes orthographic size")
	camera.queue_free()


func _test_picker_resolves_default_and_floor_hits() -> void:
	var registry = _make_multifloor_registry()
	var picker = TERRAIN_25D_PICKER_SCRIPT.new()
	picker.call("configure_grid", 2.0, 0.35)
	var ray_origin := Vector3(2.0, 10.0, 2.0)
	var ray_direction := Vector3.DOWN
	var ground_pick: Dictionary = Dictionary(picker.call("pick_ray", ray_origin, ray_direction, registry))
	var highest_pick: Dictionary = Dictionary(picker.call("pick_ray", ray_origin, ray_direction, registry, {"floor_mode": "highest"}))
	var explicit_pick: Dictionary = Dictionary(picker.call("pick_ray", ray_origin, ray_direction, registry, {"floor_index": 1}))
	_assert(bool(ground_pick.get("valid", false)) and Vector2i(ground_pick.get("grid_position", Vector2i.ZERO)) == Vector2i(1, 1), "Picker resolves a world ray to the authoritative grid")
	_assert(int(ground_pick.get("floor_index", -1)) == 0, "Default pick chooses the ground floor")
	_assert(int(highest_pick.get("floor_index", -1)) == 1, "Highest-floor picking can select an elevated slot")
	_assert(int(explicit_pick.get("target_floor_index", -1)) == 1 and bool(explicit_pick.get("walkable", false)), "Explicit floor pick returns floor command data")
	registry.free()


func _test_pick_snapshot_can_feed_command_target() -> void:
	var registry = _make_multifloor_registry()
	var picker = TERRAIN_25D_PICKER_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(picker.call("pick_ray", Vector3(2.0, 10.0, 2.0), Vector3.DOWN, registry, {"floor_index": 1}))
	var command = COMMANDER_COMMAND_SCRIPT.new({
		"command_type": "move",
		"unit_id": "blue",
		"team_id": "team_alpha",
		"target_position": Vector2(snapshot.get("target_position", Vector2.ZERO)),
		"target_floor_index": int(snapshot.get("target_floor_index", 0)),
	})
	_assert(command.is_valid() and int(command.target_floor_index) == 1, "Pick snapshot can feed CommanderCommand target_floor_index")
	registry.free()


func _test_scene_picking_survives_rotation_and_zoom() -> void:
	var scene := RENDER_SPIKE_SCENE.instantiate()
	root.add_child(scene)
	for _index in range(4):
		await process_frame
	var camera := scene.get_node_or_null("Camera3D") as Camera3D
	var world_point := Vector3(10.0, 0.0, 10.0)
	var first_screen_point: Vector2 = camera.unproject_position(world_point)
	var first_pick: Dictionary = Dictionary(scene.call("pick_screen_position", first_screen_point))
	scene.call("rotate_camera_by", 55.0)
	scene.call("zoom_camera_by_steps", -3)
	for _index in range(2):
		await process_frame
	var second_screen_point: Vector2 = camera.unproject_position(world_point)
	var second_pick: Dictionary = Dictionary(scene.call("pick_screen_position", second_screen_point))
	_assert(bool(first_pick.get("valid", false)) and Vector2i(first_pick.get("grid_position", Vector2i.ZERO)) == Vector2i(10, 10), "Scene picking resolves the expected grid before camera rotation")
	_assert(bool(second_pick.get("valid", false)) and Vector2i(second_pick.get("grid_position", Vector2i.ZERO)) == Vector2i(10, 10), "Scene picking resolves the same grid after camera rotation and zoom")
	_assert(scene.get_node_or_null("PickDebugMarker") != null, "Scene exposes a debug marker for the latest grid hit")
	scene.queue_free()
	await process_frame


func _make_multifloor_registry():
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	registry.register_tile(_make_tile(Vector2i(1, 1), 0, 0.0))
	registry.register_tile(_make_tile(Vector2i(1, 1), 1, 3.0))
	return registry


func _make_tile(grid_position: Vector2i, floor_index: int, floor_height: float):
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "tile_%d_%d_f%d" % [grid_position.x, grid_position.y, floor_index],
		"type_id": "ground_flat",
		"grid_position": grid_position,
		"world_position": Vector2(float(grid_position.x - grid_position.y) * 64.0, float(grid_position.x + grid_position.y) * 32.0),
		"walkable": true,
		"floor_index": floor_index,
		"height_level": int(roundf(floor_height)),
		"floor_height": floor_height,
		"is_elevated_surface": floor_height > 0.0,
	})


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
