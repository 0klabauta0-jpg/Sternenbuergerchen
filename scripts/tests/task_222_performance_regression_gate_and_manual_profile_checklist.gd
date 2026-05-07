extends SceneTree

const BUDGET_PATH: String = "res://data/performance_budget_contract.json"
const GATE_REPORT_PATH: String = "res://docs/performance/performance_regression_gate.md"
const MANUAL_CHECKLIST_PATH: String = "res://docs/dev/performance_manual_profile_checklist.md"
const TASK_170_SCRIPT_PATH: String = "res://scripts/tests/task_170_performance_warning_gate_verifier.gd"
const RENDER_SPIKE_SCENE_PATH: String = "res://scenes/tests/mission_map_3d_render_spike.tscn"

const NAVIGATION_HARNESS: GDScript = preload("res://scripts/tests/navigation_benchmark_harness.gd")
const SIMULATION_HARNESS: GDScript = preload("res://scripts/tests/simulation_combat_ai_tick_budget_harness.gd")
const UI_HARNESS: GDScript = preload("res://scripts/tests/ui_hud_comic_bubble_performance_harness.gd")
const ASSET_HARNESS: GDScript = preload("res://scripts/tests/asset_vram_shader_pipeline_harness.gd")
const SNAPSHOT_HARNESS: GDScript = preload("res://scripts/tests/multiplayer_snapshot_performance_harness.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_222 Performance Regression Gate and Manual Profile Checklist ===")
	var budget: Dictionary = _load_json(BUDGET_PATH)
	_test_budget_contract(budget)
	_test_docs_exist(budget)
	await _test_render_gate(Dictionary(Dictionary(budget.get("project_budget", {})).get("render", {})))
	_test_navigation_gate(Dictionary(Dictionary(budget.get("project_budget", {})).get("navigation", {})))
	await _test_simulation_gate(Dictionary(Dictionary(budget.get("project_budget", {})).get("simulation", {})))
	await _test_ui_gate(Dictionary(Dictionary(budget.get("project_budget", {})).get("ui", {})))
	await _test_asset_gate(Dictionary(Dictionary(budget.get("project_budget", {})).get("assets", {})))
	_test_snapshot_gate(Dictionary(Dictionary(budget.get("project_budget", {})).get("snapshot", {})))
	_test_warning_gate_contract(Dictionary(budget.get("warning_gate", {})))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_budget_contract(budget: Dictionary) -> void:
	_assert(int(budget.get("schema_version", 0)) == 1, "Budget contract has schema version 1")
	_assert(String(budget.get("task", "")) == "TASK_222", "Budget contract is tied to TASK_222")
	var policy: Dictionary = Dictionary(budget.get("policy", {}))
	_assert(bool(policy.get("local_baseline_is_machine_dependent", false)), "Budget contract marks local baseline as machine dependent")
	_assert(bool(policy.get("raise_budget_only_with_report", false)), "Budget contract requires report for budget raises")
	var project_budget: Dictionary = Dictionary(budget.get("project_budget", {}))
	for section in ["render", "navigation", "simulation", "ui", "assets", "snapshot"]:
		_assert(project_budget.has(section), "Budget contract contains '%s' section" % section)
	var local_baseline: Dictionary = Dictionary(budget.get("local_baseline", {}))
	_assert(Array(local_baseline.get("source_reports", [])).size() >= 7, "Budget contract links all deep-pass performance reports")


func _test_docs_exist(budget: Dictionary) -> void:
	var report: String = _read_text(GATE_REPORT_PATH)
	var checklist: String = _read_text(MANUAL_CHECKLIST_PATH)
	_assert(not report.is_empty(), "Performance regression gate report exists")
	_assert(report.contains("TASK_222") and report.contains("render") and report.contains("snapshot"), "Gate report documents all performance areas")
	_assert(not checklist.is_empty(), "Manual performance profile checklist exists")
	for required_text in ["Godot 4.6", "Profiler", "Visual Profiler", "Video RAM", "Network Profiler", "Stutter"]:
		_assert(checklist.contains(required_text), "Manual checklist covers '%s'" % required_text)
	var source_reports: Array = Array(Dictionary(budget.get("local_baseline", {})).get("source_reports", []))
	for report_path_variant in source_reports:
		var report_path: String = String(report_path_variant)
		_assert(FileAccess.file_exists(report_path), "Budget source report exists: %s" % report_path)


func _test_render_gate(budget: Dictionary) -> void:
	var packed_scene := load(RENDER_SPIKE_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Render gate loads render spike scene")
	if packed_scene == null:
		return
	var scene_root := packed_scene.instantiate()
	root.add_child(scene_root)
	await _wait_frames(10)
	var primary_view := scene_root.get_node_or_null("Primary3DView")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Render gate exposes Primary3DView snapshot")
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null else {}
	_assert_budget(float(snapshot.get("map_render_duration_msec", 999999.0)), float(budget.get("max_map_render_duration_msec", 0.0)), "Render spike map_render_duration_msec")
	_assert(int(snapshot.get("missing_asset_mapping_count", 0)) <= int(budget.get("max_missing_asset_mapping_count", -1)), "Render gate has no missing asset mappings")
	var texture_fallback_count: int = int(snapshot.get("tile_texture_count", 0)) + int(snapshot.get("asset_texture_count", 0)) + int(snapshot.get("unit_texture_count", 0))
	_assert(texture_fallback_count <= int(budget.get("max_texture_fallback_count", -1)), "Render gate has no texture fallback cards")
	_assert(Dictionary(snapshot.get("pipeline_compilation_snapshot", {})).has("mesh"), "Render gate exposes pipeline snapshot")
	scene_root.queue_free()
	await _wait_frames(2)


func _test_navigation_gate(budget: Dictionary) -> void:
	var harness = NAVIGATION_HARNESS.new()
	var result: Dictionary = Dictionary(harness.call("run_all", root))
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	var budget_delays: Dictionary = Dictionary(scenarios.get("budget_delays", {}))
	var open_hpa: Dictionary = Dictionary(Dictionary(scenarios.get("open_field_queries", {})).get("hpa", {}))
	_assert(bool(summary.get("has_query_metrics", false)), "Navigation gate includes query metrics")
	_assert(bool(summary.get("has_cover_metrics", false)), "Navigation gate includes cover metrics")
	_assert(bool(summary.get("has_los_cover_diagnostics", false)), "Navigation gate includes LOS/Cover diagnostics")
	_assert(int(budget_delays.get("budget_limit", 0)) <= int(budget.get("max_path_query_budget_per_tick", 0)), "Navigation budget limit matches contract")
	_assert(String(budget_delays.get("last_delay_reason", "")) == "budget_exhausted", "Navigation gate keeps budget delay diagnostics")
	_assert_budget(float(open_hpa.get("avg_query_time_usec", 999999.0)), float(budget.get("max_open_hpa_avg_query_usec", 0.0)), "Navigation open HPA avg_query_time_usec")


func _test_simulation_gate(budget: Dictionary) -> void:
	var harness = SIMULATION_HARNESS.new()
	var result: Dictionary = await harness.run_all(root, 1)
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	_assert(bool(summary.get("has_runtime_scopes", false)), "Simulation gate includes SimulationRoot scope timings")
	_assert(bool(summary.get("has_combat_scopes", false)), "Simulation gate includes CombatLoop scope timings")
	_assert(bool(summary.get("has_hotpath_audit", false)), "Simulation gate includes hotpath audit")
	for scenario_id in scenarios.keys():
		var stats: Dictionary = Dictionary(Dictionary(scenarios.get(scenario_id, {})).get("stats", {}))
		_assert_budget(float(Dictionary(stats.get("simulation_total_tick_usec", {})).get("p99", 9999999.0)), float(budget.get("max_simulation_tick_p99_usec", 0.0)), "Simulation %s p99" % String(scenario_id))
		_assert_budget(float(Dictionary(stats.get("combat_total_tick_usec", {})).get("p99", 9999999.0)), float(budget.get("max_combat_tick_p99_usec", 0.0)), "Combat %s p99" % String(scenario_id))


func _test_ui_gate(budget: Dictionary) -> void:
	var harness = UI_HARNESS.new()
	var result: Dictionary = await harness.run_all(root)
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	var screens: Dictionary = Dictionary(result.get("screens", {}))
	_assert(bool(summary.get("fixed_window_stable", false)), "UI gate keeps fixed Drop-Light window size")
	_assert(bool(summary.get("theme_reuse_enabled", false)), "UI gate keeps theme StyleBox reuse")
	_assert(bool(summary.get("bubble_normal_capped", false)), "UI gate keeps normal bubble cap")
	for screen_id in screens.keys():
		var counts: Dictionary = Dictionary(Dictionary(screens.get(screen_id, {})).get("counts", {}))
		_assert_budget(float(counts.get("node_count", 999999.0)), float(budget.get("max_screen_node_count", 0.0)), "UI %s node_count" % String(screen_id))
	var normal_render: Dictionary = Dictionary(Dictionary(Dictionary(result.get("bubbles", {})).get("normal", {})).get("render", {}))
	_assert(int(normal_render.get("feedback_bubble_visual_count", 99)) <= int(budget.get("max_bubble_visual_count", 0)), "UI gate keeps bubble visual count under budget")


func _test_asset_gate(budget: Dictionary) -> void:
	var harness = ASSET_HARNESS.new()
	var result: Dictionary = await harness.run_all(root)
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	var assets: Dictionary = Dictionary(result.get("assets", {}))
	_assert(int(summary.get("asset_count", 0)) >= int(budget.get("min_catalog_asset_count", 0)), "Asset gate has expected catalog breadth")
	_assert(bool(summary.get("all_paths_res", false)), "Asset gate keeps all paths res://")
	_assert(bool(summary.get("all_assets_loadable", false)), "Asset gate loads all measured assets")
	_assert(bool(summary.get("has_pipeline_snapshot", false)), "Asset gate includes pipeline snapshot")
	_assert(bool(summary.get("warmup_side_effect_free", false)), "Asset gate keeps warmup side-effect free")
	_assert_budget(float(assets.get("estimated_texture_vram_bytes", 9999999999.0)), float(budget.get("max_texture_estimated_vram_bytes", 0.0)), "Asset estimated_texture_vram_bytes")
	var max_glb: Dictionary = Dictionary(assets.get("max_glb_file", {}))
	_assert_budget(float(max_glb.get("file_bytes", 999999999.0)), float(budget.get("max_single_glb_file_bytes", 0.0)), "Asset max_single_glb_file_bytes")


func _test_snapshot_gate(budget: Dictionary) -> void:
	var harness = SNAPSHOT_HARNESS.new()
	var result: Dictionary = harness.run_all(root)
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	_assert(bool(summary.get("deterministic_canonical_payload", false)), "Snapshot gate keeps deterministic canonical payload")
	_assert(bool(summary.get("all_payloads_id_only", false)), "Snapshot gate keeps ID-only payloads")
	_assert(bool(summary.get("all_scenarios_side_effect_free", false)), "Snapshot gate keeps apply side-effect free")
	for scenario_id in scenarios.keys():
		var stats: Dictionary = Dictionary(Dictionary(scenarios.get(scenario_id, {})).get("stats", {}))
		_assert_budget(float(Dictionary(stats.get("build_usec", {})).get("p99", 9999999.0)), float(budget.get("max_build_p99_usec", 0.0)), "Snapshot %s build p99" % String(scenario_id))
		_assert_budget(float(Dictionary(stats.get("apply_usec", {})).get("p99", 9999999.0)), float(budget.get("max_apply_p99_usec", 0.0)), "Snapshot %s apply p99" % String(scenario_id))
		_assert_budget(float(Dictionary(stats.get("json_bytes", {})).get("p99", 9999999.0)), float(budget.get("max_large_json_p99_bytes", 0.0)), "Snapshot %s JSON p99 bytes" % String(scenario_id))


func _test_warning_gate_contract(warning_gate: Dictionary) -> void:
	_assert(bool(warning_gate.get("integrates_task_170", false)), "Warning gate contract integrates TASK_170")
	_assert(FileAccess.file_exists(TASK_170_SCRIPT_PATH), "TASK_170 verifier remains available")
	var patterns: Array = Array(warning_gate.get("blocked_patterns", []))
	for pattern in ["ObjectDB instances leaked", "RID allocations.*leaked", "Leaked instance"]:
		_assert(patterns.has(pattern), "Warning gate blocks '%s'" % pattern)
	_assert(bool(warning_gate.get("missing_asset_counters_must_be_zero", false)), "Warning gate keeps missing-asset counters at zero")
	_assert(bool(warning_gate.get("fallback_texture_counters_must_be_zero", false)), "Warning gate keeps fallback texture counters at zero")


func _assert_budget(value: float, budget: float, label: String) -> void:
	_assert(value <= budget, "%s value %.3f <= budget %.3f" % [label, value, budget])


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
