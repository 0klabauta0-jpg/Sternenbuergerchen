extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_332_terrain_map_frame_budget_proxy_sync_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/terrain_map_frame_budget_proxy_sync_pass.md"
const VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_332 Terrain Map Frame Budget Proxy Sync Pass ===")
	_test_docs_status_and_report()
	_test_static_frame_budget_boundaries()
	await _test_live_proxy_sync_and_order_signature_budget()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_docs_status_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_332 task file marks implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_332 checklist is complete")
	_assert(status_text.contains("### TASK_332 - Terrain Map Frame Budget Proxy Sync Pass") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_332 implemented")
	_assert(roadmap_text.contains("TASK_332 - Terrain Map Frame Budget Proxy Sync Pass (implementiert"), "Roadmap marks TASK_332 implemented")
	for token in ["Proxy-Sync", "Order-Visual", "Dirty", "Frame-Budget", "keine Gameplay-Semantik"]:
		_assert(report_text.to_lower().contains(token.to_lower()), "Report documents %s" % token)


func _test_static_frame_budget_boundaries() -> void:
	var view_text: String = _read_text(VIEW_PATH)
	_assert(not view_text.contains("var_to_str(order_payload)"), "Order visual signature avoids full order_payload serialization")
	_assert(view_text.contains("_append_order_signature_dictionary") and view_text.contains("compact:v2"), "Order visual signature uses a compact sorted signature builder")
	_assert(view_text.contains("_unit_proxy_static_diagnostics_dirty"), "Unit proxy diagnostics are guarded by a dirty flag")
	_assert(view_text.contains("func _refresh_unit_proxy_static_diagnostic_counts"), "Heavy unit proxy counters are isolated behind a refresh function")
	_assert(view_text.contains("unit_proxy_static_diagnostic_refresh_count"), "Render snapshot exposes proxy diagnostic refresh count")
	_assert(view_text.contains("\"order_visual_signature_mode\": \"compact\""), "Render snapshot exposes compact order signature mode")


func _test_live_proxy_sync_and_order_signature_budget() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Mission scene exposes Primary3DView snapshot")
	if primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var initial_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(initial_snapshot.get("unit_proxy_count", 0)) > 0, "Live scene creates unit proxies")
	_assert(String(initial_snapshot.get("order_visual_signature_mode", "")) == "compact", "Live snapshot reports compact order signature mode")
	var static_refresh_before: int = int(initial_snapshot.get("unit_proxy_static_diagnostic_refresh_count", 0))
	var motion_sync_before: int = int(initial_snapshot.get("unit_proxy_motion_sync_count", 0))
	var visibility_sync_before: int = int(initial_snapshot.get("unit_proxy_visibility_sync_count", 0))
	var badge_sync_before: int = int(initial_snapshot.get("unit_proxy_status_badge_sync_count", 0))
	await _wait_frames(10)
	var steady_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(steady_snapshot.get("unit_proxy_motion_sync_count", 0)) > motion_sync_before, "Unit proxy motion sync remains frame-live")
	_assert(int(steady_snapshot.get("unit_proxy_visibility_sync_count", 0)) > visibility_sync_before, "Unit proxy visibility sync remains frame-live")
	_assert(int(steady_snapshot.get("unit_proxy_status_badge_sync_count", 0)) > badge_sync_before, "Unit proxy badge sync remains frame-live")
	_assert(int(steady_snapshot.get("unit_proxy_static_diagnostic_refresh_count", 0)) == static_refresh_before, "Static proxy diagnostics do not refresh every frame after the dirty pass")
	_assert(not bool(steady_snapshot.get("unit_proxy_static_diagnostics_dirty", true)), "Static proxy diagnostics clear their dirty flag")
	_assert(int(steady_snapshot.get("unit_proxy_last_sync_duration_usec", -1)) >= 0, "Unit proxy sync exposes a local duration sample")
	print("TASK_332 proxy budget sample: %s" % JSON.stringify({
		"unit_proxy_count": int(steady_snapshot.get("unit_proxy_count", 0)),
		"static_refresh_count": int(steady_snapshot.get("unit_proxy_static_diagnostic_refresh_count", 0)),
		"motion_sync_count": int(steady_snapshot.get("unit_proxy_motion_sync_count", 0)),
		"visibility_sync_count": int(steady_snapshot.get("unit_proxy_visibility_sync_count", 0)),
		"badge_sync_count": int(steady_snapshot.get("unit_proxy_status_badge_sync_count", 0)),
		"last_sync_duration_usec": int(steady_snapshot.get("unit_proxy_last_sync_duration_usec", 0)),
	}))

	var drop_position := Vector2(448.0, 285.0)
	primary_view.call("set_mission_drop_visual_state", {
		"has_lz_position": true,
		"lz_position": drop_position,
		"dropship_visible": true,
		"dropship_position": drop_position - Vector2(64.0, 24.0),
		"dropship_target_position": drop_position,
	})
	var drop_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(drop_snapshot.get("dropship_visual_count", 0)) >= 1, "Dropship visuals still update through their own payload path")

	var order_payload: Dictionary = {
		"phase_index": 1,
		"selected_fireteam_ids": PackedStringArray(["blue"]),
		"fire_sector_overlay_enabled": true,
		"fireteam_anchors": [
			{"fireteam_id": "blue", "position": drop_position - Vector2(32.0, 16.0)},
		],
		"plan_dicts": [
			{
				"phase": 1,
				"fireteam_id": "blue",
				"waypoints": [
					{"target_position": drop_position + Vector2(32.0, 16.0), "command_type": "take"},
				],
			},
		],
		"area_order_dicts": [
			{
				"area_order_id": "task_332_budget_area",
				"command_type": "engage",
				"center_position": drop_position,
				"tile_world_positions": [drop_position],
			},
		],
	}
	primary_view.call("set_order_visual_payload", order_payload)
	var first_order_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(first_order_snapshot.get("area_order_count", 0)) >= 1, "Compact signature still rebuilds area order visuals")
	_assert(int(first_order_snapshot.get("waypoint_visual_count", 0)) >= 1, "Compact signature still rebuilds waypoint visuals")
	_assert(bool(first_order_snapshot.get("friendly_fire_sector_overlay_enabled", false)), "Compact signature preserves fire-sector overlay state")
	var first_rebuild_count: int = int(first_order_snapshot.get("order_visual_rebuild_count", 0))
	var compact_signature_count: int = int(first_order_snapshot.get("order_visual_signature_compact_count", 0))
	primary_view.call("set_order_visual_payload", order_payload.duplicate(true))
	var second_order_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(second_order_snapshot.get("order_visual_rebuild_count", 0)) == first_rebuild_count, "Identical order payload does not rebuild order visuals")
	_assert(int(second_order_snapshot.get("order_visual_signature_compact_count", 0)) > compact_signature_count, "Identical order payload still uses compact signature comparison")
	_assert(int(second_order_snapshot.get("order_visual_signature_full_fallback_count", -1)) == 0, "Order visual signature uses no full serialization fallback")
	print("TASK_332 order budget sample: %s" % JSON.stringify({
		"order_visual_rebuild_count": int(second_order_snapshot.get("order_visual_rebuild_count", 0)),
		"compact_signature_count": int(second_order_snapshot.get("order_visual_signature_compact_count", 0)),
		"full_fallback_count": int(second_order_snapshot.get("order_visual_signature_full_fallback_count", -1)),
		"dynamic_refresh_count": int(second_order_snapshot.get("order_dynamic_visual_refresh_count", 0)),
		"dynamic_rebuild_count": int(second_order_snapshot.get("order_dynamic_visual_rebuild_count", 0)),
	}))

	primary_view.call("set_order_visual_payload", {})
	var clear_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(Array(clear_snapshot.get("order_selected_fireteam_ids", [])).is_empty(), "Clearing order payload clears selected fireteams in the map snapshot")

	scene.queue_free()
	await _wait_frames(2)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


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
