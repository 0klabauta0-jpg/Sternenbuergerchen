extends SceneTree

const MISSION_LIVE_25D_VISUAL_BRIDGE_SCRIPT: GDScript = preload("res://scripts/tests/mission_live_2_5d_visual_bridge.gd")
const MOVEMENT_LAYER_SCRIPT: GDScript = preload("res://scripts/core/movement_layer.gd")
const TERRAIN_25D_VISUAL_PROJECTION_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_visual_projection.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")

var _passed: int = 0
var _failed: int = 0


class MockOrderVisualizer:
	extends Node

	var waypoints: Array = []
	var area_orders: Array = []

	func get_visible_waypoints() -> Array:
		return waypoints

	func get_visible_area_orders() -> Array:
		return area_orders


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_143 Unit Height Visual Sync Verifier ===")
	_test_projection_reads_floor_specific_ground_height()
	_test_projection_adds_air_altitude_without_moving_2d_unit()
	await _test_bridge_syncs_units_selection_target_debug_and_air_shadow()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_projection_reads_floor_specific_ground_height() -> void:
	var registry = _make_multifloor_registry()
	var unit: Node2D = _make_unit("ground_visual", registry.grid_to_world(Vector2i(0, 0)))
	root.add_child(unit)
	unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 0, "ground", 0)
	var projection = TERRAIN_25D_VISUAL_PROJECTION_SCRIPT.new()
	projection.call("configure_grid", 2.0, 0.35)
	var ground_projection: Dictionary = Dictionary(projection.call("project_node2d", unit, registry))
	unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 1, "ground", 0)
	var roof_projection: Dictionary = Dictionary(projection.call("project_node2d", unit, registry))
	_assert(bool(ground_projection.get("valid", false)) and int(ground_projection.get("floor_index", -1)) == 0, "Ground projection resolves floor 0")
	_assert(bool(roof_projection.get("valid", false)) and int(roof_projection.get("floor_index", -1)) == 1, "Ground projection can resolve a different floor at the same grid")
	_assert(float(roof_projection.get("floor_height", 0.0)) > float(ground_projection.get("floor_height", 0.0)), "Projection reads floor-specific height")
	_assert(Vector3(roof_projection.get("visual_position_3d", Vector3.ZERO)).y > Vector3(ground_projection.get("visual_position_3d", Vector3.ZERO)).y, "Roof visual is higher than ground visual")
	unit.queue_free()
	registry.free()


func _test_projection_adds_air_altitude_without_moving_2d_unit() -> void:
	var registry = _make_multifloor_registry()
	var unit: Node2D = _make_unit("air_visual", registry.grid_to_world(Vector2i(1, 0)) + Vector2(16.0, 8.0))
	root.add_child(unit)
	var position_before: Vector2 = unit.global_position
	unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 1, "air", 3)
	var projection = TERRAIN_25D_VISUAL_PROJECTION_SCRIPT.new()
	projection.call("configure_grid", 2.0, 0.35)
	var air_projection: Dictionary = Dictionary(projection.call("project_node2d", unit, registry))
	var visual_position: Vector3 = Vector3(air_projection.get("visual_position_3d", Vector3.ZERO))
	var shadow_position: Vector3 = Vector3(air_projection.get("shadow_position_3d", Vector3.ZERO))
	var marker_position: Vector3 = Vector3(air_projection.get("marker_position_3d", Vector3.ZERO))
	var debug_position: Vector3 = Vector3(air_projection.get("debug_label_position_3d", Vector3.ZERO))
	var continuous_grid_position: Vector2 = Vector2(air_projection.get("continuous_grid_position", Vector2.ZERO))
	_assert(String(air_projection.get("movement_layer", "")) == "air" and int(air_projection.get("altitude_band", -1)) == 3, "Air projection preserves movement layer and altitude band")
	_assert(continuous_grid_position.x > 1.0 and continuous_grid_position.x < 1.5, "Projection preserves intra-tile movement offset instead of snapping to tile center")
	_assert(visual_position.y > shadow_position.y, "Air unit visual floats above its ground shadow")
	_assert(marker_position.y > visual_position.y and debug_position.y > marker_position.y, "Air marker and debug label stack above the visual")
	_assert(unit.global_position == position_before, "Projection never mutates the authoritative 2D unit position")
	unit.queue_free()
	registry.free()


func _test_bridge_syncs_units_selection_target_debug_and_air_shadow() -> void:
	var context: Dictionary = _make_bridge_context()
	var scene: Node = context["scene"]
	var bridge: Node = context["bridge"]
	var ground_unit: Node2D = context["ground_unit"]
	var air_unit: Node2D = context["air_unit"]
	for _index in range(3):
		await process_frame
	ground_unit.call("set_tactical_selected", true)
	ground_unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 0, "ground", 0)
	air_unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 1, "air", 2)
	var air_position_before: Vector2 = air_unit.global_position
	var snapshot: Dictionary = Dictionary(bridge.call("sync_runtime_visuals"))
	var units: Dictionary = Dictionary(snapshot.get("units", {}))
	var ground_snapshot: Dictionary = Dictionary(units.get("ground_visual", {}))
	var air_snapshot: Dictionary = Dictionary(units.get("air_visual", {}))
	var target_snapshot: Dictionary = Dictionary(snapshot.get("target_marker", {}))
	var ground_visual = bridge.get_node_or_null("RuntimeVisual3D/UnitVisuals3D/Unit_ground_visual")
	var ground_selection = bridge.get_node_or_null("RuntimeVisual3D/SelectionVisuals3D/Selection_ground_visual")
	var air_visual = bridge.get_node_or_null("RuntimeVisual3D/UnitVisuals3D/Unit_air_visual")
	var air_shadow = bridge.get_node_or_null("RuntimeVisual3D/AirShadowVisuals3D/AirShadow_air_visual")
	var debug_label = bridge.get_node_or_null("RuntimeVisual3D/DebugLabelAnchors3D/Debug_air_visual")
	var target_visual = bridge.get_node_or_null("RuntimeVisual3D/MarkerVisuals3D/Target_target_marker")
	var preview_visual = bridge.get_node_or_null("RuntimeVisual3D/PathPreviewVisuals3D/Preview_waypoint_0")
	var preview_snapshot: Dictionary = Dictionary(snapshot.get("path_preview", {}))
	_assert(bool(snapshot.get("valid", false)) and int(snapshot.get("unit_count", 0)) == 2, "Bridge runtime visual sync sees registered units")
	_assert(ground_visual is MeshInstance3D and air_visual is MeshInstance3D, "Bridge creates unit 3D visual anchors")
	_assert(ground_selection is MeshInstance3D and ground_selection.visible, "Bridge creates a selection visual on the projected unit height")
	_assert(debug_label is Label3D and String(debug_label.text).contains("AIR 2"), "Bridge creates readable air debug label text")
	_assert(air_shadow is MeshInstance3D and air_shadow.visible, "Bridge creates an air shadow at floor height")
	_assert(target_visual is MeshInstance3D and bool(target_snapshot.get("valid", false)), "Bridge projects the target marker through the shared helper")
	_assert(preview_visual is MeshInstance3D and int(preview_snapshot.get("preview_count", 0)) >= 2, "Bridge projects path and move preview anchors through the shared helper")
	_assert(Vector3(air_snapshot.get("visual_position_3d", Vector3.ZERO)).y > Vector3(ground_snapshot.get("visual_position_3d", Vector3.ZERO)).y, "Bridge places air visuals above ground visuals")
	_assert(air_unit.global_position == air_position_before and ground_unit.global_position == registry_grid_world(context, Vector2i(0, 0)), "Bridge sync does not move 2D units")
	scene.queue_free()
	await process_frame


func _make_bridge_context() -> Dictionary:
	var scene := Node2D.new()
	scene.name = "Task143BridgeContext"
	root.add_child(scene)
	var terrain_registry = _make_multifloor_registry()
	terrain_registry.name = "TerrainRegistry"
	scene.add_child(terrain_registry)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var target_marker := Marker2D.new()
	target_marker.name = "TargetMarker"
	target_marker.global_position = terrain_registry.grid_to_world(Vector2i(1, 0))
	scene.add_child(target_marker)
	var order_visualizer := MockOrderVisualizer.new()
	order_visualizer.name = "FireteamOrderVisualizer"
	order_visualizer.waypoints = [{
		"position": terrain_registry.grid_to_world(Vector2i(0, 0)),
	}, {
		"position": terrain_registry.grid_to_world(Vector2i(1, 0)),
	}]
	order_visualizer.area_orders = [{
		"center_position": terrain_registry.grid_to_world(Vector2i(1, 0)),
		"tile_world_positions": [terrain_registry.grid_to_world(Vector2i(0, 0))],
	}]
	scene.add_child(order_visualizer)
	var ground_unit: Node2D = _make_unit("ground_visual", terrain_registry.grid_to_world(Vector2i(0, 0)))
	scene.add_child(ground_unit)
	ground_unit.call("set_tactical_selected", true)
	ground_unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 0, "ground", 0)
	var air_unit: Node2D = _make_unit("air_visual", terrain_registry.grid_to_world(Vector2i(1, 0)))
	scene.add_child(air_unit)
	air_unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 1, "air", 2)
	unit_registry.call("register_unit", "ground_visual", ground_unit)
	unit_registry.call("register_unit", "air_visual", air_unit)
	var bridge = MISSION_LIVE_25D_VISUAL_BRIDGE_SCRIPT.new()
	bridge.name = "Mission25DVisualBridge"
	bridge.terrain_registry_path = NodePath("../TerrainRegistry")
	bridge.unit_registry_path = NodePath("../UnitRegistry")
	bridge.target_marker_path = NodePath("../TargetMarker")
	bridge.order_visualizer_path = NodePath("../FireteamOrderVisualizer")
	bridge.sync_runtime_visuals_enabled = true
	scene.add_child(bridge)
	return {
		"scene": scene,
		"bridge": bridge,
		"terrain_registry": terrain_registry,
		"unit_registry": unit_registry,
		"ground_unit": ground_unit,
		"air_unit": air_unit,
	}


func _make_multifloor_registry():
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	registry.register_tile(_make_tile(Vector2i(0, 0), 0, 0.0))
	registry.register_tile(_make_tile(Vector2i(1, 0), 0, 0.0))
	registry.register_tile(_make_tile(Vector2i(0, 0), 1, 3.0))
	registry.register_tile(_make_tile(Vector2i(1, 0), 1, 3.0))
	return registry


func _make_tile(grid_position: Vector2i, floor_index: int, floor_height: float):
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "task_143_%d_%d_f%d" % [grid_position.x, grid_position.y, floor_index],
		"type_id": "ground_flat",
		"grid_position": grid_position,
		"world_position": Vector2(float(grid_position.x - grid_position.y) * 64.0, float(grid_position.x + grid_position.y) * 32.0),
		"walkable": true,
		"floor_index": floor_index,
		"height_level": int(roundf(floor_height)),
		"floor_height": floor_height,
		"is_elevated_surface": floor_height > 0.0,
	})


func _make_unit(unit_id: String, position: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.global_position = position
	return unit


func registry_grid_world(context: Dictionary, grid_position: Vector2i) -> Vector2:
	var terrain_registry = context["terrain_registry"]
	return Vector2(terrain_registry.call("grid_to_world", grid_position))


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
