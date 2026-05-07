extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/performance_deep_pass_harness.gd")
const REPORT_PATH: String = "res://docs/performance/performance_baseline_report.md"
const RESEARCH_NOTES_PATH: String = "res://docs/dev/performance_deep_pass_research_notes.md"
const MIN_REPETITIONS: int = 2

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_215 Performance Deep Pass Baseline and Research ===")
	var harness = HARNESS_SCRIPT.new()
	var result: Dictionary = await harness.run_all(root, MIN_REPETITIONS)
	_test_environment_and_windows(result)
	_test_scene_matrix_and_statistics(result)
	_test_navigation_and_snapshot_metrics(result)
	_test_report_and_research_docs()
	print("TASK_215 harness summary: %s" % JSON.stringify(result.get("summary", {})))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_environment_and_windows(result: Dictionary) -> void:
	var environment: Dictionary = Dictionary(result.get("environment", {}))
	var windows: Dictionary = Dictionary(result.get("test_windows", {}))
	_assert(not String(environment.get("godot_version", "")).strip_edges().is_empty(), "Baseline captures Godot version")
	_assert(not String(environment.get("os_name", "")).strip_edges().is_empty(), "Baseline captures OS name")
	_assert(Dictionary(windows.get("fixed_ui_fullhd", {})).get("width", 0) == 1920, "Baseline defines fixed FullHD UI window")
	_assert(Dictionary(windows.get("mission_2_5d", {})).get("height", 0) == 1080, "Baseline defines mission 2.5D test window")


func _test_scene_matrix_and_statistics(result: Dictionary) -> void:
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	var scenes: Dictionary = Dictionary(result.get("scenes", {}))
	_assert(bool(summary.get("has_homebase", false)), "Baseline matrix includes Homebase")
	_assert(bool(summary.get("has_fob", false)), "Baseline matrix includes FOB")
	_assert(bool(summary.get("has_live_mission_2_5d", false)), "Baseline matrix includes live Mission 2.5D")
	_assert(bool(summary.get("has_render_spike", false)), "Baseline matrix includes render spike")
	_assert(int(summary.get("complete_scene_count", 0)) >= 4, "Baseline matrix has complete scene samples")
	_assert(bool(summary.get("has_median_p95_p99", false)), "Baseline stores repeat statistics")
	for scenario_id in ["homebase", "fob", "live_mission_2_5d", "render_spike_32x32"]:
		_assert(_scenario_has_repeated_stats(Dictionary(scenes.get(scenario_id, {}))), "%s scenario has repeated ready/node stats" % scenario_id)
	_assert(_scenario_has_render_stats(Dictionary(scenes.get("live_mission_2_5d", {}))), "Live mission scenario has 2.5D render stats")
	_assert(_scenario_has_render_stats(Dictionary(scenes.get("render_spike_32x32", {}))), "Render spike scenario has 2.5D render stats")
	_assert(_first_run_has_monitor(Dictionary(scenes.get("homebase", {})), "TIME_FPS"), "Scene runs include Performance.get_monitor values")


func _test_navigation_and_snapshot_metrics(result: Dictionary) -> void:
	var navigation: Dictionary = Dictionary(result.get("navigation", {}))
	var nav_summary: Dictionary = Dictionary(navigation.get("summary", {}))
	var snapshot: Dictionary = Dictionary(result.get("snapshot", {}))
	_assert(int(nav_summary.get("scenario_count", 0)) >= 5, "Baseline includes navigation benchmark scenarios")
	_assert(bool(nav_summary.get("has_query_metrics", false)), "Baseline includes navigation query metrics")
	_assert(bool(nav_summary.get("has_delay_metrics", false)), "Baseline includes navigation budget-delay metrics")
	_assert(int(Dictionary(snapshot.get("build_time_usec", {})).get("count", 0)) >= MIN_REPETITIONS, "Baseline includes snapshot build timing")
	_assert(int(Dictionary(snapshot.get("apply_time_usec", {})).get("count", 0)) >= MIN_REPETITIONS, "Baseline includes snapshot apply timing")
	_assert(float(Dictionary(snapshot.get("snapshot_size_bytes", {})).get("median", -1.0)) > 0.0, "Baseline includes snapshot size estimate")
	_assert(bool(snapshot.get("command_queue_empty", false)), "Snapshot baseline leaves command queue empty")
	_assert(bool(snapshot.get("effects_queue_empty", false)), "Snapshot baseline leaves effects queue empty")


func _test_report_and_research_docs() -> void:
	var report: String = _read_text(REPORT_PATH)
	var research: String = _read_text(RESEARCH_NOTES_PATH)
	_assert(not report.is_empty(), "Performance baseline report exists")
	_assert(report.contains("TASK_215") and report.contains("Homebase") and report.contains("FOB"), "Report documents TASK_215 scene matrix")
	_assert(report.contains("Median") and report.contains("P95") and report.contains("P99"), "Report documents repeat-stat fields")
	_assert(report.contains("Live Mission 2.5D") and report.contains("Render Spike"), "Report documents mission and render spike scenarios")
	_assert(not research.is_empty(), "Performance research notes exist")
	_assert(research.contains("Performance.get_monitor()") and research.contains("Godot-Doku-Abgleich"), "Research notes document Godot monitor and docs alignment")
	_assert(research.contains("Forumshinweise") and research.contains("Hypothesen"), "Research notes mark forum guidance as hypotheses")


func _scenario_has_repeated_stats(scenario: Dictionary) -> bool:
	if int(scenario.get("repetitions", 0)) < MIN_REPETITIONS:
		return false
	var stats: Dictionary = Dictionary(scenario.get("stats", {}))
	var ready: Dictionary = Dictionary(stats.get("scene_ready_usec", {}))
	var nodes: Dictionary = Dictionary(stats.get("node_count", {}))
	return int(ready.get("count", 0)) >= MIN_REPETITIONS and float(ready.get("median", -1.0)) >= 0.0 and int(nodes.get("count", 0)) >= MIN_REPETITIONS


func _scenario_has_render_stats(scenario: Dictionary) -> bool:
	var stats: Dictionary = Dictionary(scenario.get("stats", {}))
	var render_stats: Dictionary = Dictionary(stats.get("map_render_duration_msec", {}))
	return int(render_stats.get("count", 0)) >= MIN_REPETITIONS and float(render_stats.get("median", -1.0)) >= 0.0


func _first_run_has_monitor(scenario: Dictionary, monitor_name: String) -> bool:
	var runs: Array = Array(scenario.get("runs", []))
	if runs.is_empty():
		return false
	var first_run: Dictionary = Dictionary(runs[0])
	var monitors: Dictionary = Dictionary(first_run.get("monitor_snapshot", {}))
	var monitor: Dictionary = Dictionary(monitors.get(monitor_name, {}))
	return bool(monitor.get("available", false))


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
