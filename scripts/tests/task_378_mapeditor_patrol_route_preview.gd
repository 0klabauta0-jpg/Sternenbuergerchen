extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_378 MapEditor Patrol Route Preview ===")
	await _test_reference_resolution_and_snapshot()
	await _test_hover_preview_batches_and_replaces_stale_routes()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("TASK_378: ALL PASSED")
		quit(0)


func _test_reference_resolution_and_snapshot() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	_install_patrol_fixture(editor)

	_assert(bool(editor.call("preview_patrol_route_for_reference", "route_alpha", "patrol_id")), "Preview accepts a direct patrol path ID")
	var direct_snapshot: Dictionary = Dictionary(editor.call("get_patrol_route_preview_snapshot"))
	_assert(String(direct_snapshot.get("patrol_path_id", "")) == "route_alpha", "Direct patrol ID resolves to route_alpha")
	_assert(int(direct_snapshot.get("waypoint_count", 0)) == 3, "Preview snapshot reports route waypoint count")
	_assert(int(direct_snapshot.get("segment_count", 0)) == 2, "Preview snapshot reports route segment count")
	_assert(Array(direct_snapshot.get("segments", [])).size() == 2 and Vector2(Dictionary(Array(direct_snapshot.get("segments", []))[0]).get("direction", Vector2.ZERO)).length() > 0.9, "Preview snapshot carries readable direction data")
	_assert(bool(direct_snapshot.get("visual_only", false)) and not bool(direct_snapshot.get("ui_sets_gameplay_truth", true)), "Preview contract stays visual-only")

	_assert(bool(editor.call("preview_patrol_route_for_reference", "binding_bravo", "binding_id")), "Preview accepts a scenario binding ID")
	var binding_snapshot: Dictionary = Dictionary(editor.call("get_patrol_route_preview_snapshot"))
	_assert(String(binding_snapshot.get("patrol_path_id", "")) == "route_bravo", "Binding ID resolves to the bound route")
	_assert(String(binding_snapshot.get("source_type", "")) == "binding_id", "Binding source type is retained")

	_assert(bool(editor.call("preview_patrol_route_for_reference", "enemy_bravo", "target_id")), "Preview accepts a scenario target/spawn ID")
	var target_snapshot: Dictionary = Dictionary(editor.call("get_patrol_route_preview_snapshot"))
	_assert(String(target_snapshot.get("patrol_path_id", "")) == "route_bravo", "Target ID resolves through scenario patrol binding")

	var overlay: Node = editor.get_node_or_null("PatrolOverlay")
	_assert(overlay != null and overlay.get_child_count() > 0, "2D patrol overlay draws preview route children")

	editor.queue_free()
	await _wait_frames(2)


func _test_hover_preview_batches_and_replaces_stale_routes() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	_install_patrol_fixture(editor)
	await _wait_frames(2)

	var map_data = editor.get("_terrain_map_data")
	var alpha_before: Array = Array(map_data.call("get_patrol_path", "route_alpha")) if map_data != null else []
	var base_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	var base_flush_count: int = int(base_debug.get("flush_count", 0))

	editor.call("_queue_patrol_route_preview_update", Vector2(128.0, 128.0))
	editor.call("_queue_patrol_route_preview_update", Vector2(576.0, 192.0))
	var queued_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	_assert(bool(queued_debug.get("queued", false)), "Patrol preview hover queues through the editor UI dirty batch")
	_assert(PackedStringArray(queued_debug.get("pending_flag_names", PackedStringArray())).has("patrol_preview"), "Queued flags include patrol_preview")

	await _wait_frames(2)
	var flushed_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	var hover_snapshot: Dictionary = Dictionary(editor.call("get_patrol_route_preview_snapshot"))
	_assert(int(flushed_debug.get("flush_count", 0)) == base_flush_count + 1, "Multiple patrol hover updates coalesce into one UI flush")
	_assert(String(hover_snapshot.get("patrol_path_id", "")) == "route_bravo", "Latest hover route replaces stale preview route")
	_assert(String(hover_snapshot.get("source_type", "")) == "waypoint_hover", "Hover preview records waypoint source")

	editor.call("_queue_patrol_route_preview_update", Vector2(128.0, 128.0))
	await _wait_frames(2)
	var second_hover_snapshot: Dictionary = Dictionary(editor.call("get_patrol_route_preview_snapshot"))
	_assert(String(second_hover_snapshot.get("patrol_path_id", "")) == "route_alpha", "Subsequent hover can switch back to the first route")

	var alpha_after: Array = Array(map_data.call("get_patrol_path", "route_alpha")) if map_data != null else []
	_assert(alpha_before.size() == alpha_after.size(), "Hover preview does not mutate patrol path data")

	var primary_view: Node = editor.get_node_or_null("Primary3DView")
	if primary_view != null and primary_view.has_method("get_render_snapshot"):
		await _wait_frames(4)
		var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
		_assert(String(render_snapshot.get("editor_patrol_preview_path_id", "")) == "route_alpha", "Primary 3D view receives the active preview route")
		_assert(int(render_snapshot.get("editor_patrol_preview_segment_count", 0)) == 2, "Primary 3D view highlights the preview route segments")

	editor.queue_free()
	await _wait_frames(2)


func _install_patrol_fixture(editor: Node) -> void:
	var map_data = editor.get("_terrain_map_data")
	if map_data == null:
		return
	map_data.call("set_patrol_path", "route_alpha", [Vector2(96.0, 96.0), Vector2(128.0, 128.0), Vector2(160.0, 96.0)])
	map_data.call("set_patrol_path", "route_bravo", [Vector2(512.0, 128.0), Vector2(576.0, 192.0), Vector2(640.0, 256.0)])
	editor.call(
		"set_mission_scenario_authoring_fields",
		{
			"version": 1,
			"scenario_id": "task_378_patrol_preview",
			"display_name": "TASK 378 Patrol Preview",
			"map_file_path": "res://maps/test_mission.json",
			"time_limit_seconds": 180.0,
			"mission_slot_count_override": 3,
			"objective": {"position": Vector2(128.0, 128.0), "capture_radius": 64.0},
			"enemy_groups": [
				{
					"group_id": "red_test_group",
					"display_name": "Test Contacts",
					"team_id": "team_bravo",
					"enemy_ids": ["enemy_delta", "enemy_bravo"],
					"spawn_position": Vector2(256.0, 256.0),
				},
			],
			"wave_config": {"wave_count": 1, "units_per_wave": 2, "first_wave_delay_seconds": 0.0, "wave_delay_seconds": 30.0},
			"patrol_bindings": [
				{"binding_id": "binding_alpha", "target_id": "enemy_delta", "patrol_path_id": "route_alpha", "mode": "pre_contact"},
				{"binding_id": "binding_bravo", "target_id": "enemy_bravo", "patrol_path_id": "route_bravo", "mode": "pre_contact"},
			],
		}
	)
	editor.call("_refresh_patrol_overlay")


func _make_editor():
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	return editor


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
