extends "res://scripts/tests/hud_architecture_20261106_native_capture.gd"
## Same ordinary fullscreen route. The optional comparison camera is applied
## before warmup and restored only after a stable completed measured window.
## Actor, simulation, quality and gameplay settings are never changed here.

const TERRAIN_CAMERA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")


func _visual_snapshot(view: Node) -> Dictionary:
	var snapshot := super._visual_snapshot(view)
	if view != null and view.has_method("get_reference_dressing_snapshot"):
		snapshot["reference_dressing"] = view.call("get_reference_dressing_snapshot")
	return snapshot


func _profile_normal_movement(view: Node) -> void:
	var requested_text := _argument("--r3-comparison-camera", "")
	var original_camera := _camera_facts(view)
	var original_size := float(view.call("get_camera_size"))
	var requested_size := original_size if requested_text.is_empty() else float(requested_text)
	var applied := false
	if not is_equal_approx(original_size, requested_size):
		view.call("zoom_camera", (original_size - requested_size) / TERRAIN_CAMERA_SCRIPT.CAMERA_ZOOM_STEP)
		applied = true
	var comparison_camera := _camera_facts(view)
	await super._profile_normal_movement(view)
	var stable := _camera_facts(view) == comparison_camera
	var restored := false
	if applied and stable:
		view.call("zoom_camera", (float(view.call("get_camera_size")) - original_size) / TERRAIN_CAMERA_SCRIPT.CAMERA_ZOOM_STEP)
		restored = _camera_facts(view) == original_camera
	_facts["r3_camera_profile"] = {
		"comparison_requested": not requested_text.is_empty(),
		"requested_size": requested_size,
		"product_camera_before_measurement": original_camera,
		"comparison_camera": comparison_camera,
		"changed_only_before_warmup": applied,
		"measured_camera_stable": stable,
		"product_camera_restored_after_measurement": restored,
		"post_measurement_camera": _camera_facts(view),
		"actor_writes": false,
		"simulation_writes": false,
		"quality_changes": false,
	}
	await _check_native_camera_navigation(view)


func _check_native_camera_navigation(view: Node) -> void:
	# This check occurs strictly after the complete timed window. It exercises
	# real public camera APIs and the normal setup guard, without actor writes.
	var setup := view.get_parent().get_node_or_null("MissionSetup")
	var data = setup.get("_loaded_terrain_map_data") if setup != null else null
	if not _check(setup != null and data != null, "Native navigation uses actual mission setup/map"):
		return
	var original := _camera_facts(view)
	var original_focus: Vector2 = view.call("get_camera_focus_grid_position")
	var original_yaw := float(view.call("get_camera_yaw_degrees"))
	var original_size := float(view.call("get_camera_size"))
	view.call("zoom_camera", 1.0)
	view.call("pan_camera", Vector2(0.3, 0.2), 0.03)
	view.call("rotate_camera", 15.0)
	await process_frame
	var manual := _camera_facts(view)
	_check(manual != original, "Native camera accepts zoom/pan/rotation")
	_check(bool(setup.call("_frame_reference_mission_camera", view)), "Native GM01 setup recognizes its completed initial frame")
	_check(_camera_facts(view) == manual, "Repeated mission framing preserves manual camera selection")
	view.call("rotate_camera", original_yaw - float(view.call("get_camera_yaw_degrees")))
	view.call("zoom_camera", (float(view.call("get_camera_size")) - original_size) / TERRAIN_CAMERA_SCRIPT.CAMERA_ZOOM_STEP)
	view.call("focus_world_position", view.call("_grid_float_to_world", original_focus))
	await process_frame
	var camera := view.get_node("ViewportContainer/SubViewport/WorldRoot/Camera3D") as Camera3D
	_check(is_equal_approx(camera.size, original_size) and Vector2(view.call("get_camera_focus_grid_position")).is_equal_approx(original_focus) and is_equal_approx(float(view.call("get_camera_yaw_degrees")), original_yaw), "Public APIs restore screenshot camera after navigation check")
	_facts["r3_native_camera_api"] = {"after_profile_only": true, "before": original, "manual": manual, "restored": _camera_facts(view), "physical_input_test": false, "actor_writes": false}
