extends SceneTree

const LZ_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/dropship_lz_accuracy_contract.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_311 Dropship LZ Target Pick Accuracy Contract ===")
	var requested := Vector2(320.0, 192.0)
	var low_skill: Dictionary = Dictionary(LZ_CONTRACT_SCRIPT.call("resolve_lz_command", requested, "task311", 0.2, 0.2, true))
	var high_skill: Dictionary = Dictionary(LZ_CONTRACT_SCRIPT.call("resolve_lz_command", requested, "task311", 0.9, 0.9, true))
	_assert(Vector2(low_skill.get("requested_lz_position", Vector2.ZERO)) == requested, "Requested LZ is stored separately")
	_assert(low_skill.has("resolved_lz_position") and low_skill.has("actual_landing_position"), "Resolved/actual LZ is stored separately")
	_assert(float(low_skill.get("landing_deviation", 0.0)) <= float(low_skill.get("lz_accuracy_radius", 0.0)), "Deviation stays inside seeded radius")
	_assert(float(high_skill.get("lz_accuracy_radius", 999.0)) < float(low_skill.get("lz_accuracy_radius", 0.0)), "Higher skill reduces deviation radius")
	_assert(String(low_skill.get("multiplayer_authority", "")) == "server_resolved_lz", "Resolved LZ is multiplayer-authoritative")
	await _test_visual_snapshot(requested, low_skill)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_visual_snapshot(requested: Vector2, resolved: Dictionary) -> void:
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task311_lz_visual", Vector2i(8, 8), Vector2(256.0, 128.0), 64.0, 32.0, 2)
	view.call("configure_from_map", map_data)
	view.call("set_mission_drop_visual_state", {
		"has_lz_position": true,
		"lz_position": requested,
		"requested_lz_position": requested,
		"resolved_lz_position": resolved.get("resolved_lz_position", requested),
	})
	await process_frame
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(bool(snapshot.get("requested_lz_marker_visible", false)), "Primary view shows requested LZ marker")
	_assert(bool(snapshot.get("resolved_lz_marker_visible", false)), "Primary view shows resolved LZ marker")
	var ship_position := Vector2(256.0, 256.0)
	var ship_target := Vector2(256.0, 128.0)
	view.call("set_mission_drop_visual_state", {
		"dropship_visible": true,
		"dropship_position": ship_position,
		"dropship_target_position": ship_target,
	})
	await process_frame
	snapshot = Dictionary(view.call("get_render_snapshot"))
	var expected_yaw: float = wrapf(float(view.call("_get_world_direction_yaw", ship_position, ship_target, 0.0)) + 180.0, 0.0, 360.0)
	_assert(_float_eq(float(snapshot.get("dropship_rotation_y", -1.0)), expected_yaw), "Dropship model rotation points the nose toward the flight target")
	view.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)


func _float_eq(left: float, right: float) -> bool:
	return absf(wrapf(left - right, -180.0, 180.0)) <= 0.1
