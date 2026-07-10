extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1046 Terrain Mission Status Payload Signature Guard ===")
	await _test_identical_payload_skips_status_visual_rebuild()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_identical_payload_skips_status_visual_rebuild() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_1046_status_guard", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	await _wait_frames(3)
	var status_root: Node = view.find_child("StatusRoot3D", true, false)
	_assert(status_root != null, "Terrain view exposes StatusRoot3D for mission status visuals")
	if status_root == null:
		view.queue_free()
		await _wait_frames(2)
		return
	var payload: Dictionary = {
		"objective_position": Vector2(192.0, 160.0),
		"objective_capture_radius": 80.0,
		"objective_capture_progress": 0.5,
		"objective_owner_team_id": "team_alpha",
		"objective_capturing_team_id": "team_alpha",
		"objective_contested": false,
		"route_callouts": [{"id": "task1046_route", "world_position": Vector2(224.0, 160.0), "short_label": "SECURE", "tone": "friendly"}],
		"mission_interaction_visual_states": [{"state_id": "task1046_console", "world_position": Vector2(256.0, 160.0), "short_label": "CONSOLE", "tone": "neutral"}],
	}
	view.call("set_mission_status_payload", payload)
	await _wait_frames(1)
	var first_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var first_ids: PackedInt64Array = _child_instance_ids(status_root)
	_assert(not first_ids.is_empty(), "First status payload creates status visual nodes")
	view.call("set_mission_status_payload", payload.duplicate(true))
	await _wait_frames(1)
	var identical_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var identical_ids: PackedInt64Array = _child_instance_ids(status_root)
	_assert(first_ids == identical_ids, "Identical status payload keeps existing StatusRoot3D node instances")
	_assert(int(identical_snapshot.get("mission_status_payload_rebuild_count", 0)) == int(first_snapshot.get("mission_status_payload_rebuild_count", -1)), "Identical status payload does not rebuild status visuals")
	_assert(int(identical_snapshot.get("mission_status_payload_skip_count", 0)) > int(first_snapshot.get("mission_status_payload_skip_count", 0)), "Identical status payload increments visual skip count")
	var diagnostics_only_payload: Dictionary = payload.duplicate(true)
	diagnostics_only_payload["runtime_diagnostics_tick"] = 1046
	view.call("set_mission_status_payload", diagnostics_only_payload)
	await _wait_frames(1)
	var diagnostics_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var diagnostics_ids: PackedInt64Array = _child_instance_ids(status_root)
	_assert(diagnostics_ids == identical_ids, "Unrendered diagnostics change keeps existing StatusRoot3D node instances")
	_assert(int(diagnostics_snapshot.get("mission_status_payload_rebuild_count", 0)) == int(identical_snapshot.get("mission_status_payload_rebuild_count", -1)), "Unrendered diagnostics change does not rebuild status visuals")
	var changed_payload: Dictionary = payload.duplicate(true)
	changed_payload["objective_capture_progress"] = 0.75
	view.call("set_mission_status_payload", changed_payload)
	await _wait_frames(1)
	var changed_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var changed_ids: PackedInt64Array = _child_instance_ids(status_root)
	_assert(changed_ids != identical_ids, "Changed capture status rebuilds StatusRoot3D nodes immediately")
	_assert(int(changed_snapshot.get("mission_status_payload_rebuild_count", 0)) > int(identical_snapshot.get("mission_status_payload_rebuild_count", 0)), "Changed status payload increments rebuild count")
	_assert(bool(changed_snapshot.get("mission_status_payload_read_only", false)), "Status payload guard is read-only")
	_assert(not bool(changed_snapshot.get("mission_status_payload_sets_gameplay_truth", true)), "Status payload guard does not own gameplay truth")
	_assert(not bool(changed_snapshot.get("mission_status_payload_creates_command", true)), "Status payload guard creates no commands")
	view.queue_free()
	await _wait_frames(2)


func _child_instance_ids(parent: Node) -> PackedInt64Array:
	var result: PackedInt64Array = PackedInt64Array()
	for child in parent.get_children():
		result.append(child.get_instance_id())
	return result


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
