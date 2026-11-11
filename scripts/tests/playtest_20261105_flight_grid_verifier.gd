extends SceneTree

const VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var view: CanvasLayer = VIEW_SCRIPT.new()
	var lz := Vector2.ZERO
	var far: Vector2 = view.call("_position_3d_to_world", Vector3(16.0, 0.0, 0.0))
	var middle: Vector2 = view.call("_position_3d_to_world", Vector3(4.0, 0.0, 0.0))
	var near: Vector2 = view.call("_position_3d_to_world", Vector3(0.5, 0.0, 0.0))
	var legacy := {"flight_altitude_clearance": 1.36}
	_expect(is_equal_approx(_height(view, legacy, far), 1.36), "No-state legacy explicit clearance is preserved")
	var payload := {"state": "inbound", "lz_position": lz, "dropship_target_position": lz}
	var original: Dictionary = payload.duplicate(true)
	var cruise: float = _height(view, payload, far)
	var descending: float = _height(view, payload, middle)
	var approach: float = _height(view, payload, near)
	_expect(cruise >= 4.0, "Inbound has clearly separated cruise altitude")
	_expect(cruise > descending and descending > approach, "Actual LZ distance produces monotone descent")
	_expect(approach < 0.25, "Final approach converges onto touchdown")
	for phase in ["landed", "unloading", "complete"]:
		payload["state"] = phase
		_expect(_height(view, payload, lz) <= 0.06, "Real %s phase reaches surface contact" % phase)
	payload["state"] = "outbound"
	var contact: float = _height(view, payload, lz)
	var climbing: float = _height(view, payload, middle)
	var departing: float = _height(view, payload, far)
	_expect(contact <= 0.06 and climbing > contact and departing > climbing, "Outbound rises with actual distance from LZ")
	payload["state"] = "inbound"
	_expect(payload == original, "Visual height leaves input payload and route unchanged")
	payload["flight_heading_origin"] = far
	var inbound_yaw: float = view.call("_get_dropship_rotation_y_for_payload", payload, near)
	payload["state"] = "landed"
	var landed_yaw: float = view.call("_get_dropship_rotation_y_for_payload", payload, lz)
	payload["state"] = "complete"
	var parked_yaw: float = view.call("_get_dropship_rotation_y_for_payload", payload, lz)
	_expect(is_equal_approx(inbound_yaw, landed_yaw) and is_equal_approx(inbound_yaw, parked_yaw),
		"Cutlass holds its approach heading through touchdown and parking")
	payload["state"] = "inbound"
	view.set("_regional_height_step", 0.75)
	view.set("_max_render_height", 8)
	var second_far: Vector2 = view.call("_position_3d_to_world", Vector3(24.0, 0.0, 0.0))
	_expect(is_equal_approx(_height(view, payload, far), _height(view, payload, second_far)),
		"Regional cruise uses a common altitude above high terrain")
	_expect(_height(view, payload, lz) <= 0.06, "Regional approach reaches its landing datum")
	view.set("_regional_height_step", 0.0)
	_expect(view.has_method("_make_hex_grid_material"), "Hex path exposes dedicated antialiased material")
	if view.has_method("_make_hex_grid_material"):
		var material: Material = view.call("_make_hex_grid_material", true)
		_expect(material is ShaderMaterial, "Hex lines use pixel coverage shader")
		if material is ShaderMaterial:
			var shader_text: String = (material as ShaderMaterial).shader.code
			_expect(shader_text.contains("fwidth") and shader_text.contains("smoothstep"), "Grid shader smooths edges and distant contrast")
			_expect(not shader_text.contains("depth_test_disabled"), "Grid keeps terrain depth test")
	view.free()
	_test_display_only_air_helper()
	print("PLAYTEST_FLIGHT_GRID: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _height(view: CanvasLayer, payload: Dictionary, position: Vector2) -> float:
	var displayed: Vector3 = view.call("_world_to_air_layer_3d_position_for_payload", payload, position)
	return displayed.y


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		push_error("FAIL: " + message)


func _test_display_only_air_helper() -> void:
	var helper_script := load("res://scripts/terrain/mission_flight_visual.gd") as GDScript
	_expect(helper_script != null, "Bounded display-only air helper loads")
	if helper_script == null:
		return
	var owner := Node3D.new()
	root.add_child(owner)
	var helper: Node3D = helper_script.new()
	owner.add_child(helper)
	helper.call("configure_cutlass_ref03")
	helper.call("set_flight_phase", "inbound")
	var air: Dictionary = helper.call("get_visual_snapshot")
	_expect(bool(air.get("operating", false)) and int(air.get("plume_count", 0)) == 4, "Real inbound phase activates four matched Cutlass nozzles")
	helper.call("set_flight_phase", "landed")
	_expect(not bool(Dictionary(helper.call("get_visual_snapshot")).get("operating", true)), "Touchdown turns flight exhaust off")
	helper.call("set_flight_phase", "unknown")
	_expect(not bool(Dictionary(helper.call("get_visual_snapshot")).get("operating", true)), "Unknown source phase cannot manufacture thrust")
	owner.free()
	var drone_owner := Node3D.new()
	drone_owner.position = Vector3(4.0, 2.0, 7.0)
	root.add_child(drone_owner)
	var model := Node3D.new()
	model.position = Vector3(0.0, 0.4, 0.0)
	drone_owner.add_child(model)
	var drone_helper: Node3D = helper_script.new()
	drone_owner.add_child(drone_helper)
	var nozzles: Array[Vector3] = [Vector3(0.0, 0.32, 0.0)]
	drone_helper.call("configure_service_drone", model, nozzles)
	drone_helper.call("set_operating_visual", true)
	drone_helper.call("advance_visual", 0.25)
	_expect(drone_owner.position == Vector3(4.0, 2.0, 7.0), "Service drone animation preserves source placement anchor")
	_expect(not model.position.is_equal_approx(Vector3(0.0, 0.4, 0.0)), "Operating service drone changes only mesh hover pose")
	drone_helper.call("set_operating_visual", false)
	_expect(model.position == Vector3(0.0, 0.4, 0.0) and model.rotation == Vector3.ZERO, "Inactive owner restores mesh base pose and stops thrust")
	var helper_reference: WeakRef = weakref(drone_helper)
	drone_owner.free()
	_expect(helper_reference.get_ref() == null, "Removing source owner releases drone effect and cached mesh reference")
