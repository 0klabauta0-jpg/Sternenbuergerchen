extends SceneTree

const LIVE_MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const RENDER_SPIKE_SCENE_PATH: String = "res://scenes/tests/mission_map_3d_render_spike.tscn"
const FTL_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const REPORT_PATH: String = "res://docs/performance/2_5d_rendering_profile_report.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_216 2.5D Rendering Node and Draw Budget Pass ===")
	await _test_live_mission_render_budget_snapshot()
	await _test_render_spike_budget_snapshot()
	_test_profile_report_exists()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_live_mission_render_budget_snapshot() -> void:
	var scene := _instantiate_scene(LIVE_MISSION_SCENE_PATH)
	_assert(scene != null, "Live mission scene instantiates for render-budget verifier")
	if scene == null:
		return
	root.add_child(scene)
	await _wait_frames(18)
	var primary_view := _find_node_by_name(scene, "Primary3DView")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Live mission exposes Primary3DView render snapshot")
	if primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	_apply_overlay_stress_payload(primary_view)
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(_has_category_budget(snapshot, "map"), "Live snapshot contains map category budget")
	_assert(_has_category_budget(snapshot, "unit"), "Live snapshot contains unit category budget")
	_assert(_has_category_budget(snapshot, "order"), "Live snapshot contains order/overlay category budget")
	_assert(_render_totals_are_non_empty(snapshot), "Live snapshot has non-empty render totals")
	_assert(int(Dictionary(snapshot.get("render_budget_totals", {})).get("mesh_instance_count", 0)) >= int(snapshot.get("ground_mesh_count", 0)), "Live mesh totals cover terrain meshes")
	_assert(_transparency_budget_covers_overlays(snapshot), "Live transparency budget covers labels, VFX and bubbles")
	_assert(_draw_budget_has_monitor_keys(snapshot), "Live draw budget exposes render monitor keys")
	_assert(_pipeline_snapshot_has_monitor_keys(snapshot), "Live pipeline snapshot exposes compilation monitor keys")
	_assert(_no_runtime_fallbacks(snapshot), "Live render-budget snapshot keeps TASK_170 fallback counters clean")
	scene.queue_free()
	await _wait_frames(2)


func _test_render_spike_budget_snapshot() -> void:
	var scene := _instantiate_scene(RENDER_SPIKE_SCENE_PATH)
	_assert(scene != null, "Render spike scene instantiates for render-budget verifier")
	if scene == null:
		return
	root.add_child(scene)
	await _wait_frames(14)
	var primary_view := _find_node_by_name(scene, "Primary3DView")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Render spike exposes Primary3DView render snapshot")
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null else {}
	_assert(_has_category_budget(snapshot, "map"), "Render spike snapshot contains map category budget")
	_assert(int(Dictionary(Dictionary(snapshot.get("render_budget_by_category", {})).get("map", {})).get("mesh_instance_count", 0)) >= int(snapshot.get("ground_mesh_count", 0)), "Render spike map category covers terrain meshes")
	_assert(int(Dictionary(snapshot.get("render_budget_totals", {})).get("material_count", 0)) > 0, "Render spike exposes material count")
	_assert(_draw_budget_has_monitor_keys(snapshot), "Render spike draw budget exposes monitor keys")
	_assert(_pipeline_snapshot_has_monitor_keys(snapshot), "Render spike pipeline snapshot exposes monitor keys")
	_assert(_no_runtime_fallbacks(snapshot), "Render spike keeps TASK_170 fallback counters clean")
	scene.queue_free()
	await _wait_frames(2)


func _test_profile_report_exists() -> void:
	var report: String = _read_text(REPORT_PATH)
	_assert(not report.is_empty(), "2.5D rendering profile report exists")
	_assert(report.contains("TASK_216") and report.contains("TerrainMap3DView"), "Report documents TASK_216 TerrainMap3DView scope")
	_assert(report.contains("MultiMesh") and report.contains("Transparenz"), "Report evaluates instancing and transparency candidates")
	_assert(report.contains("Pipeline") and report.contains("Visual Profiler"), "Report documents pipeline and visual profiler checks")


func _apply_overlay_stress_payload(primary_view: Node) -> void:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = "task216_bubble_lead"
	unit.fireteam_id = "blue"
	unit.team_id = "team_alpha"
	unit.is_fireteam_lead = true
	unit.skill_leadership = 0.9
	unit.discipline = 0.9
	unit.awareness = 0.9
	unit.global_position = Vector2(448.0, 285.0)
	unit._ready()
	var bubble_payload: Dictionary = Dictionary(FTL_RESOLVER_SCRIPT.call("build_command_feedback", "contact", "contact", unit, unit.global_position, {}, {"fireteam_id": "blue"}))
	primary_view.call(
		"set_order_visual_payload",
		{
			"phase_index": 1,
			"feedback_bubble_dicts": [bubble_payload],
			"fire_event_dicts": [
				{
					"event_id": "task216_muzzle",
					"weapon_id": "rifle",
					"attacker_unit_id": "task216_bubble_lead",
					"target_unit_id": "task216_target",
					"attacker_position": Vector2(448.0, 285.0),
					"target_position": Vector2(560.0, 260.0),
					"source": "task216_render_budget",
				},
			],
		}
	)
	unit.free()


func _has_category_budget(snapshot: Dictionary, category_id: String) -> bool:
	var categories: Dictionary = Dictionary(snapshot.get("render_budget_by_category", {}))
	if not categories.has(category_id):
		return false
	var category: Dictionary = Dictionary(categories.get(category_id, {}))
	return int(category.get("node_count", 0)) > 0 and category.has("mesh_instance_count") and category.has("material_count")


func _render_totals_are_non_empty(snapshot: Dictionary) -> bool:
	var totals: Dictionary = Dictionary(snapshot.get("render_budget_totals", {}))
	return int(totals.get("category_count", 0)) >= 8 and int(totals.get("node_count", 0)) > 0 and int(totals.get("mesh_instance_count", 0)) > 0


func _transparency_budget_covers_overlays(snapshot: Dictionary) -> bool:
	var transparency: Dictionary = Dictionary(snapshot.get("render_transparency_budget", {}))
	return int(transparency.get("transparent_overlay_count", -1)) >= 0 and int(transparency.get("feedback_bubble_count", 0)) >= 1 and int(transparency.get("weapon_fire_vfx_count", 0)) >= 1


func _draw_budget_has_monitor_keys(snapshot: Dictionary) -> bool:
	var draw_budget: Dictionary = Dictionary(snapshot.get("draw_budget_snapshot", {}))
	return draw_budget.has("draw_calls_in_frame") and draw_budget.has("objects_in_frame") and draw_budget.has("video_mem_used")


func _pipeline_snapshot_has_monitor_keys(snapshot: Dictionary) -> bool:
	var pipeline: Dictionary = Dictionary(snapshot.get("pipeline_compilation_snapshot", {}))
	return pipeline.has("canvas") and pipeline.has("mesh") and pipeline.has("surface") and pipeline.has("draw") and pipeline.has("specialization")


func _no_runtime_fallbacks(snapshot: Dictionary) -> bool:
	return int(snapshot.get("missing_asset_mapping_count", 0)) == 0 \
		and int(snapshot.get("missing_map_asset_mapping_count", 0)) == 0 \
		and int(snapshot.get("missing_unit_model_count", 0)) == 0 \
		and int(snapshot.get("missing_dropship_model_count", 0)) == 0 \
		and int(snapshot.get("tile_texture_count", 0)) == 0 \
		and int(snapshot.get("asset_texture_count", 0)) == 0 \
		and int(snapshot.get("unit_texture_count", 0)) == 0


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		return null
	return packed_scene.instantiate()


func _find_node_by_name(node: Node, node_name: String) -> Node:
	if node == null:
		return null
	if String(node.name) == node_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
