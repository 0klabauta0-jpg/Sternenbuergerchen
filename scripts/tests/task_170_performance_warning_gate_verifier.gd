extends SceneTree

const LIVE_MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const RENDER_SPIKE_SCENE_PATH: String = "res://scenes/tests/mission_map_3d_render_spike.tscn"
const NAVIGATION_BENCHMARK_HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/navigation_benchmark_harness.gd")
const MAX_PRIMARY_RENDER_DURATION_MSEC: int = 8000
const MAX_OPEN_HPA_AVG_QUERY_USEC: float = 200000.0

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_170 Performance and Warning Budget Gate ===")
	await _test_live_primary_snapshot_gate()
	await _test_render_spike_budget_gate()
	await _test_navigation_budget_summary_gate()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_live_primary_snapshot_gate() -> void:
	var live_scene := _instantiate_scene(LIVE_MISSION_SCENE_PATH)
	_assert(live_scene != null, "Live mission scene instantiates for TASK_170 gate")
	if live_scene == null:
		return
	root.add_child(live_scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var primary_view := live_scene.get_node_or_null("Primary3DView")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Live mission exposes Primary3DView snapshot")
	if primary_view == null:
		live_scene.queue_free()
		await _wait_frames(2)
		return

	var initial_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(initial_snapshot.get("tile_count", 0)) > 0, "Live gate snapshot renders terrain")
	_assert(int(initial_snapshot.get("ground_mesh_count", 0)) == int(initial_snapshot.get("tile_count", 0)), "Live gate keeps ground meshes aligned with tile count")
	_assert_no_primary_fallbacks("Live initial", initial_snapshot)
	_assert_render_budget("Live initial", initial_snapshot)

	var lz_position := Vector2(448.0, 285.0)
	primary_view.call(
		"set_mission_drop_visual_state",
		{
			"has_lz_position": true,
			"lz_position": lz_position,
			"dropship_visible": true,
			"dropship_position": lz_position - Vector2(64.0, 32.0),
			"dropship_target_position": lz_position,
		}
	)
	primary_view.call(
		"set_order_visual_payload",
		{
			"phase_index": 1,
			"selected_fireteam_ids": PackedStringArray(["blue"]),
			"fireteam_anchors": [
				{"fireteam_id": "blue", "position": lz_position - Vector2(32.0, 16.0)},
			],
			"plan_dicts": [
				{
					"phase": 1,
					"fireteam_id": "blue",
					"waypoints": [
						{"target_position": lz_position + Vector2(32.0, 16.0), "command_type": "take"},
					],
				},
			],
			"area_order_dicts": [
				{
					"area_order_id": "task_170_gate_area",
					"command_type": "engage",
					"center_position": lz_position,
					"tile_world_positions": [lz_position],
				},
			],
		}
	)
	primary_view.call(
		"set_contact_entries",
		[
			{
				"unit_id": "task_170_contact",
				"fireteam_id": "blue",
				"last_known_position": lz_position + Vector2(96.0, -24.0),
				"detection_state": "confirmed",
			},
		],
		PackedStringArray(["blue"])
	)
	primary_view.call(
		"set_mission_status_payload",
		{
			"objective_position": lz_position,
			"objective_capture_radius": 80.0,
			"objective_capture_progress": 0.5,
			"mission_resolved": true,
			"result": "victory",
			"win_condition_type": "objective_capture",
			"winning_team_id": "team_alpha",
		}
	)
	await _wait_frames(6)

	var applied_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert_no_primary_fallbacks("Live applied", applied_snapshot)
	_assert_render_budget("Live applied", applied_snapshot)
	_assert(bool(applied_snapshot.get("dropship_model_visible", false)), "Live gate uses dropship GLB model")
	_assert(not bool(applied_snapshot.get("dropship_texture_visible", false)), "Live gate keeps dropship texture fallback disabled")
	_assert(int(applied_snapshot.get("area_order_count", 0)) >= 1, "Live gate mirrors area order snapshot")
	_assert(int(applied_snapshot.get("waypoint_visual_count", 0)) >= 1, "Live gate mirrors waypoint snapshot")
	_assert(int(applied_snapshot.get("contact_count", 0)) >= 1, "Live gate mirrors contact snapshot")
	_assert(bool(applied_snapshot.get("objective_status_visible", false)), "Live gate mirrors objective status snapshot")
	_assert(bool(applied_snapshot.get("mission_result_visible", false)), "Live gate mirrors mission result snapshot")
	_assert(int(applied_snapshot.get("render_snapshot_request_count", 0)) >= 2, "Live gate counts render snapshot requests")
	_assert(int(applied_snapshot.get("drop_payload_apply_count", 0)) >= 1, "Live gate counts dropship payload applies")
	_assert(int(applied_snapshot.get("order_payload_apply_count", 0)) >= 1, "Live gate counts order payload applies")
	_assert(int(applied_snapshot.get("contact_payload_apply_count", 0)) >= 1, "Live gate counts contact payload applies")
	_assert(int(applied_snapshot.get("mission_status_payload_apply_count", 0)) >= 1, "Live gate counts mission status payload applies")
	print("Gate live primary counters: %s" % JSON.stringify(_snapshot_budget_summary(applied_snapshot)))

	live_scene.queue_free()
	await _wait_frames(2)


func _test_render_spike_budget_gate() -> void:
	var render_scene := _instantiate_scene(RENDER_SPIKE_SCENE_PATH)
	_assert(render_scene != null, "Render spike scene instantiates for TASK_170 gate")
	if render_scene == null:
		return
	root.add_child(render_scene)
	await _wait_frames(10)

	var primary_view := render_scene.get_node_or_null("Primary3DView")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Render spike exposes Primary3DView snapshot")
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null else {}
	_assert(int(snapshot.get("tile_count", 0)) > 0, "Render spike gate renders terrain")
	_assert(int(snapshot.get("ground_mesh_count", 0)) == int(snapshot.get("tile_count", 0)), "Render spike gate keeps ground meshes aligned with tile count")
	_assert(int(snapshot.get("asset_model_count", 0)) > 0, "Render spike gate renders mapped 3D asset models")
	_assert_no_primary_fallbacks("Render spike", snapshot)
	_assert_render_budget("Render spike", snapshot)
	print("Gate render spike counters: %s" % JSON.stringify(_snapshot_budget_summary(snapshot)))

	render_scene.queue_free()
	await _wait_frames(2)


func _test_navigation_budget_summary_gate() -> void:
	var harness = NAVIGATION_BENCHMARK_HARNESS_SCRIPT.new()
	var result: Dictionary = Dictionary(harness.call("run_all", root))
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	var budget: Dictionary = Dictionary(scenarios.get("budget_delays", {}))
	var open_field: Dictionary = Dictionary(scenarios.get("open_field_queries", {}))
	var open_hpa: Dictionary = Dictionary(open_field.get("hpa", {}))

	_assert(int(summary.get("scenario_count", 0)) >= 5, "Navigation gate sees all benchmark scenarios")
	_assert(bool(summary.get("has_query_metrics", false)), "Navigation gate has query metrics")
	_assert(bool(summary.get("has_cover_metrics", false)), "Navigation gate has cover metrics")
	_assert(bool(summary.get("has_delay_metrics", false)), "Navigation gate has delay metrics")
	_assert(bool(summary.get("has_avoidance_metrics", false)), "Navigation gate has avoidance metrics")
	_assert(int(budget.get("new_path_queries_this_tick", -1)) <= int(budget.get("budget_limit", 0)), "Navigation gate respects new path query budget")
	_assert(int(budget.get("delayed_this_tick", 0)) > 0, "Navigation gate reports delayed path queries")
	_assert(int(budget.get("pending_query_count", 0)) > 0, "Navigation gate reports pending path queries")
	_assert(String(budget.get("last_delay_reason", "")) == "budget_exhausted", "Navigation gate reports budget_exhausted delay reason")
	_assert(float(open_hpa.get("avg_query_time_usec", -1.0)) >= 0.0, "Navigation gate reports HPA query timing")
	_assert(float(open_hpa.get("avg_query_time_usec", MAX_OPEN_HPA_AVG_QUERY_USEC + 1.0)) < MAX_OPEN_HPA_AVG_QUERY_USEC, "Navigation gate keeps open HPA query timing below broad local budget")
	print("Gate navigation summary: %s" % JSON.stringify({
		"summary": summary,
		"budget_delays": budget,
		"open_hpa_avg_query_time_usec": float(open_hpa.get("avg_query_time_usec", -1.0)),
	}))
	await _wait_frames(4)


func _assert_no_primary_fallbacks(label: String, snapshot: Dictionary) -> void:
	_assert(int(snapshot.get("missing_asset_mapping_count", 0)) == 0, "%s has no missing 3D mappings" % label)
	_assert(int(snapshot.get("missing_map_asset_mapping_count", 0)) == 0, "%s has no missing map asset mappings" % label)
	_assert(int(snapshot.get("missing_unit_model_count", 0)) == 0, "%s has no missing unit model mappings" % label)
	_assert(int(snapshot.get("missing_dropship_model_count", 0)) == 0, "%s has no missing dropship model mappings" % label)
	_assert(int(snapshot.get("tile_texture_count", 0)) == 0, "%s does not use terrain Sprite3D fallback cards" % label)
	_assert(int(snapshot.get("height_edge_texture_count", 0)) == 0, "%s does not use height-edge texture fallback cards" % label)
	_assert(int(snapshot.get("asset_texture_count", 0)) == 0, "%s does not use asset Sprite3D fallback cards" % label)
	_assert(int(snapshot.get("placeholder_object_count", 0)) == 0, "%s does not use block placeholder fallback objects" % label)
	_assert(int(snapshot.get("unit_texture_count", 0)) == 0, "%s does not use unit texture/capsule fallbacks" % label)


func _assert_render_budget(label: String, snapshot: Dictionary) -> void:
	_assert(int(snapshot.get("map_render_duration_msec", MAX_PRIMARY_RENDER_DURATION_MSEC + 1)) < MAX_PRIMARY_RENDER_DURATION_MSEC, "%s render duration stays under %d msec" % [label, MAX_PRIMARY_RENDER_DURATION_MSEC])


func _snapshot_budget_summary(snapshot: Dictionary) -> Dictionary:
	return {
		"tile_count": int(snapshot.get("tile_count", 0)),
		"asset_model_count": int(snapshot.get("asset_model_count", 0)),
		"unit_model_count": int(snapshot.get("unit_model_count", 0)),
		"missing_asset_mapping_count": int(snapshot.get("missing_asset_mapping_count", 0)),
		"map_render_duration_msec": int(snapshot.get("map_render_duration_msec", 0)),
		"render_snapshot_request_count": int(snapshot.get("render_snapshot_request_count", 0)),
		"order_payload_apply_count": int(snapshot.get("order_payload_apply_count", 0)),
		"contact_payload_apply_count": int(snapshot.get("contact_payload_apply_count", 0)),
		"drop_payload_apply_count": int(snapshot.get("drop_payload_apply_count", 0)),
		"mission_status_payload_apply_count": int(snapshot.get("mission_status_payload_apply_count", 0)),
	}


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		return null
	return packed_scene.instantiate()


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
