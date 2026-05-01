extends SceneTree

const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")
const CALIBRATION_SCENE: PackedScene = preload("res://scenes/tests/mission_map_3d_calibration.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_146 3D Calibration Workspace Verifier ===")
	_test_mapping_summary()
	await _test_calibration_workspace()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_mapping_summary() -> void:
	var renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	var summary: Dictionary = Dictionary(renderer.call("get_mapping_summary"))
	_assert(Array(summary.get("missing_model_paths", [])).is_empty(), "3D mapping has no missing model paths")
	_assert(int(summary.get("existing_model_count", 0)) >= 12, "3D mapping keeps the curated calibration model set available")
	_assert(not Dictionary(summary.get("source", {})).is_empty(), "3D mapping documents its source")


func _test_calibration_workspace() -> void:
	var scene := CALIBRATION_SCENE.instantiate()
	root.add_child(scene)
	for _index in range(4):
		await process_frame

	var render_result: Dictionary = Dictionary(scene.get("render_result"))
	var stats: Dictionary = Dictionary(render_result.get("stats", {}))
	var snapshot: Dictionary = Dictionary(scene.call("get_calibration_snapshot"))
	var entries: Array = Array(snapshot.get("entries", []))

	_assert(int(stats.get("terrain_count", 0)) == 112, "Calibration workspace keeps the compact 14x8 grid")
	_assert(int(stats.get("object_count", 0)) >= 12, "Calibration workspace renders all curated object families")
	_assert(int(snapshot.get("object_count", 0)) == entries.size(), "Calibration snapshot lists every calibration object")
	_assert(Array(snapshot.get("missing_model_paths", [])).is_empty(), "Calibration snapshot reports no missing model paths")
	_assert(int(snapshot.get("label_count", 0)) == entries.size(), "Calibration workspace creates one label per object")
	_assert(int(snapshot.get("footprint_count", 0)) == entries.size(), "Calibration workspace creates one footprint per object")
	_assert(int(snapshot.get("pivot_count", 0)) == entries.size(), "Calibration workspace creates one pivot marker per object")
	_assert(_entries_have_calibration_values(entries), "Calibration entries expose scale, offset and rotation data")
	_assert(_rendered_objects_are_centered(Dictionary(render_result.get("objects", {}))), "Rendered model bounds are centered on their tile anchors")

	var label_container := scene.get_node_or_null("MapRoot/CalibrationHelpers3D/Labels3D")
	var footprint_container := scene.get_node_or_null("MapRoot/CalibrationHelpers3D/Footprints3D")
	_assert(label_container != null and label_container.get_child_count() == entries.size(), "Label helper container is present and populated")
	_assert(footprint_container != null and footprint_container.get_child_count() == entries.size(), "Footprint helper container is present and populated")

	scene.call("set_calibration_labels_enabled", false)
	await process_frame
	var labels_off_snapshot: Dictionary = Dictionary(scene.call("get_calibration_snapshot"))
	_assert(int(labels_off_snapshot.get("label_count", -1)) == 0 and not bool(labels_off_snapshot.get("labels_enabled", true)), "Label toggle hides calibration labels")

	scene.call("set_calibration_footprints_enabled", false)
	await process_frame
	var footprints_off_snapshot: Dictionary = Dictionary(scene.call("get_calibration_snapshot"))
	_assert(int(footprints_off_snapshot.get("footprint_count", -1)) == 0 and int(footprints_off_snapshot.get("pivot_count", -1)) == 0, "Footprint toggle hides footprints and pivot markers")

	scene.call("set_debug_grid_enabled", false)
	await process_frame
	var no_grid_snapshot: Dictionary = Dictionary(scene.call("get_calibration_snapshot"))
	_assert(not bool(no_grid_snapshot.get("debug_grid_enabled", true)), "Grid toggle rerenders calibration workspace without debug grid")

	scene.queue_free()
	await process_frame


func _entries_have_calibration_values(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for raw_entry in entries:
		var entry: Dictionary = Dictionary(raw_entry)
		if String(entry.get("type_id", "")).is_empty():
			return false
		if String(entry.get("model_key", "")).is_empty():
			return false
		if not bool(entry.get("model_exists", false)):
			return false
		if float(entry.get("scale", 0.0)) <= 0.0:
			return false
		if not entry.has("y_offset") or not entry.has("rotation_offset_degrees") or not entry.has("total_rotation_degrees"):
			return false
	return true


func _rendered_objects_are_centered(objects: Dictionary) -> bool:
	if objects.is_empty():
		return false
	for object_node in objects.values():
		var node := object_node as Node3D
		if node == null:
			return false
		var bounds: Dictionary = _get_global_visual_bounds(node)
		if not bool(bounds.get("valid", false)):
			return false
		var center: Vector3 = Vector3(bounds.get("center", Vector3.ZERO))
		var anchor: Vector3 = node.global_position
		if Vector2(center.x - anchor.x, center.z - anchor.z).length() > 0.03:
			return false
	return true


func _get_global_visual_bounds(node: Node3D) -> Dictionary:
	var bounds: Dictionary = {
		"valid": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
		"center": Vector3.ZERO,
	}
	_accumulate_global_visual_bounds(node, bounds)
	if bool(bounds.get("valid", false)):
		var min_value: Vector3 = Vector3(bounds.get("min", Vector3.ZERO))
		var max_value: Vector3 = Vector3(bounds.get("max", Vector3.ZERO))
		bounds["center"] = (min_value + max_value) * 0.5
	return bounds


func _accumulate_global_visual_bounds(node: Node, bounds: Dictionary) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		_merge_transformed_aabb(bounds, mesh_instance.global_transform, mesh_instance.get_aabb())
	for child in node.get_children():
		_accumulate_global_visual_bounds(child, bounds)


func _merge_transformed_aabb(bounds: Dictionary, transform: Transform3D, aabb: AABB) -> void:
	var corners: Array[Vector3] = [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size,
	]
	for corner in corners:
		var transformed_corner: Vector3 = transform * corner
		if not bool(bounds.get("valid", false)):
			bounds["valid"] = true
			bounds["min"] = transformed_corner
			bounds["max"] = transformed_corner
			continue
		var min_value: Vector3 = Vector3(bounds.get("min", Vector3.ZERO))
		var max_value: Vector3 = Vector3(bounds.get("max", Vector3.ZERO))
		bounds["min"] = Vector3(
			minf(min_value.x, transformed_corner.x),
			minf(min_value.y, transformed_corner.y),
			minf(min_value.z, transformed_corner.z)
		)
		bounds["max"] = Vector3(
			maxf(max_value.x, transformed_corner.x),
			maxf(max_value.y, transformed_corner.y),
			maxf(max_value.z, transformed_corner.z)
		)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
