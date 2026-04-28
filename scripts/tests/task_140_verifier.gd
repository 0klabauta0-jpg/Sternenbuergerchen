extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_renderer.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_140 2.5D Editor and Visual Sync Verifier ===")
	_test_height_fields_roundtrip()
	_test_2d_height_overlay()
	_test_3d_renderer_uses_floor_height()
	await _test_editor_controls_apply_height_fields()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_height_fields_roundtrip() -> void:
	var temp_path: String = "user://task_140_height_roundtrip.json"
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_140_roundtrip", Vector2i(2, 1), Vector2.ZERO)
	var tile_data = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	tile_data.height_level = 2
	tile_data.floor_height = 2.5
	tile_data.unit_eye_height_bonus = 0.75
	tile_data.cover_height = 1.25
	tile_data.blocks_los_height = 2.75
	tile_data.height_transition_type = TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_RAMP
	var save_error: Error = map_data.call("save_to_file", temp_path)
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", temp_path)
	var reloaded_tile = reloaded.call("get_tile_at_grid", Vector2i(1, 0)) if reloaded != null else null
	_assert(save_error == OK, "Map saves 2.5D height fields")
	_assert(reloaded_tile != null and is_equal_approx(float(reloaded_tile.floor_height), 2.5), "Map roundtrip keeps floor_height")
	_assert(reloaded_tile != null and is_equal_approx(float(reloaded_tile.unit_eye_height_bonus), 0.75), "Map roundtrip keeps unit eye height bonus")
	_assert(reloaded_tile != null and is_equal_approx(float(reloaded_tile.cover_height), 1.25), "Map roundtrip keeps cover_height")
	_assert(reloaded_tile != null and is_equal_approx(float(reloaded_tile.blocks_los_height), 2.75), "Map roundtrip keeps blocks_los_height")
	_assert(reloaded_tile != null and String(reloaded_tile.height_transition_type) == TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_RAMP, "Map roundtrip keeps height transition type")


func _test_2d_height_overlay() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_140_overlay", Vector2i(3, 1), Vector2.ZERO)
	var flat_tile = map_data.call("get_tile_at_grid", Vector2i(0, 0))
	var ramp_tile = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	var cover_tile = map_data.call("get_tile_at_grid", Vector2i(2, 0))
	ramp_tile.height_level = 1
	ramp_tile.floor_height = 1.0
	ramp_tile.height_transition_type = TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_RAMP
	cover_tile.cover_height = 1.5
	cover_tile.blocks_los_height = 2.0
	var map_root := Node2D.new()
	root.add_child(map_root)
	var renderer = TERRAIN_MAP_RENDERER_SCRIPT.new()
	var render_result: Dictionary = Dictionary(renderer.call("render_map_with_options", map_data, map_root, {"show_height_overlay": true}))
	var overlays: Dictionary = Dictionary(render_result.get("height_overlays", {}))
	var ramp_label := overlays.get(Vector2i(1, 0), null) as Label
	var cover_label := overlays.get(Vector2i(2, 0), null) as Label
	_assert(not overlays.has(Vector2i(0, 0)) and flat_tile != null, "Flat legacy tile gets no height overlay")
	_assert(ramp_label != null and ramp_label.text.find("ramp") >= 0, "Height overlay exposes transition type")
	_assert(cover_label != null and cover_label.text.find("C1.5") >= 0 and cover_label.text.find("L2.0") >= 0, "Height overlay exposes cover and LOS heights")
	map_root.queue_free()


func _test_3d_renderer_uses_floor_height() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_140_3d_height", Vector2i(2, 1), Vector2.ZERO)
	var flat_tile = map_data.call("get_tile_at_grid", Vector2i(0, 0))
	var elevated_tile = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	elevated_tile.floor_height = 3.0
	elevated_tile.height_level = 0
	elevated_tile.object_type_id = "technik_generator_se"
	var map_root := Node3D.new()
	root.add_child(map_root)
	var renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	var render_result: Dictionary = Dictionary(renderer.call("render_map", map_data, map_root, {"show_debug_grid": true}))
	var terrain_nodes: Dictionary = Dictionary(render_result.get("terrain", {}))
	var object_nodes: Dictionary = Dictionary(render_result.get("objects", {}))
	var flat_node := terrain_nodes.get(Vector2i(0, 0), null) as Node3D
	var elevated_node := terrain_nodes.get(Vector2i(1, 0), null) as Node3D
	var object_node := object_nodes.get(Vector2i(1, 0), null) as Node3D
	var expected_y: float = 3.0 * float(renderer.call("get_grid_height_step"))
	_assert(flat_node != null and is_equal_approx(flat_node.position.y, 0.0) and flat_tile != null, "Legacy flat 3D ground stays at y=0")
	_assert(elevated_node != null and is_equal_approx(elevated_node.position.y, expected_y), "3D ground uses floor_height for y placement")
	_assert(object_node != null and object_node.position.y > elevated_node.position.y, "3D object stays above elevated ground with model offset")
	map_root.queue_free()


func _test_editor_controls_apply_height_fields() -> void:
	var scene = MAP_EDITOR_SCENE.instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	scene.set("_selected_grid_position", Vector2i.ZERO)
	scene.call("_refresh_property_panel")
	var floor_spin := scene.get_node("UI/PropertyPanel/Margin/VBox/FloorHeightRow/FloorHeightSpinBox") as SpinBox
	var eye_spin := scene.get_node("UI/PropertyPanel/Margin/VBox/EyeHeightRow/EyeHeightSpinBox") as SpinBox
	var cover_spin := scene.get_node("UI/PropertyPanel/Margin/VBox/CoverHeightRow/CoverHeightSpinBox") as SpinBox
	var los_spin := scene.get_node("UI/PropertyPanel/Margin/VBox/LosHeightRow/LosHeightSpinBox") as SpinBox
	var transition_option := scene.get_node("UI/PropertyPanel/Margin/VBox/TransitionRow/TransitionOptionButton") as OptionButton
	_assert(floor_spin != null and floor_spin.editable, "Editor exposes editable floor_height control")
	_assert(cover_spin != null and los_spin != null and transition_option != null, "Editor exposes 2.5D cover/LOS/transition controls")
	floor_spin.value = 2.0
	eye_spin.value = 0.5
	cover_spin.value = 1.0
	los_spin.value = 2.25
	transition_option.select(1)
	scene.set("_last_selected_height_transition_type", TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_RAMP)
	scene.call("_apply_property_controls_to_selected_tile")
	var map_data = scene.get("_terrain_map_data")
	var tile_data = map_data.call("get_tile_at_grid", Vector2i.ZERO) if map_data != null else null
	var height_overlay := scene.get_node_or_null("HeightOverlay/HeightOverlay_0_0") as Label
	_assert(tile_data != null and is_equal_approx(float(tile_data.floor_height), 2.0), "Editor applies floor_height to selected tile")
	_assert(tile_data != null and is_equal_approx(float(tile_data.unit_eye_height_bonus), 0.5), "Editor applies unit eye height bonus")
	_assert(tile_data != null and is_equal_approx(float(tile_data.cover_height), 1.0), "Editor applies cover_height")
	_assert(tile_data != null and is_equal_approx(float(tile_data.blocks_los_height), 2.25), "Editor applies blocks_los_height")
	_assert(tile_data != null and String(tile_data.height_transition_type) == TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_RAMP, "Editor applies height transition type")
	_assert(height_overlay != null and height_overlay.text.find("ramp") >= 0, "Editor refreshes the height overlay after property edit")
	scene.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
