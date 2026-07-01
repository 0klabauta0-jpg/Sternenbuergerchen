extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_734_station_scenario_performance_feel_pass.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const PERFORMANCE_BUDGET_PATH: String = "res://data/performance_budget_contract.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_scenario_performance_feel_pass.json"
const SAMPLE_COUNT: int = 5

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_734 Station Scenario Performance Feel Pass ===")
	_test_docs_contract_and_report()
	await _test_scene_performance_feel_gate()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_734: FAILED")
		quit(1)
		return
	print("TASK_734: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text("res://scripts/tests/mission_tactical_sandbox_controller.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_734 task file exists")
	_assert(task_text.contains("Station Scenario Performance Feel Pass"), "Task documents performance feel pass")
	_assert(contract_text.contains("Station Scenario Performance Feel Pass"), "Interaction contract documents TASK_734")
	_assert(status_text.contains("TASK_734 - Station Scenario Performance Feel Pass"), "Implementation status tracks TASK_734")
	_assert(roadmap_text.contains("TASK_734 - Station Scenario Performance Feel Pass (implementiert)"), "Roadmap marks TASK_734 implemented")
	_assert(report_text.contains("TASK_734 - Station Scenario Performance Feel Pass"), "Current handbook references TASK_734")
	_assert(report_text.contains('data-export-key="station_scenario_performance_feel_pass.manifest_path"'), "Current handbook exports TASK_734 manifest")
	_assert(controller_text.contains("get_station_scenario_performance_feel_pass_snapshot"), "Controller exposes performance feel snapshot")
	_assert(FileAccess.file_exists(PERFORMANCE_BUDGET_PATH), "Performance budget contract exists")


func _test_scene_performance_feel_gate() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(controller != null and combat_driver != null, "Mission scene exposes controller and driver")
	if controller == null or combat_driver == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures station scenario")
	controller.call("_update_ui")
	await _wait_frames(2)
	var sample: Dictionary = _measure_command_feedback_sample(controller)
	var snapshot: Dictionary = Dictionary(controller.call("get_station_scenario_performance_feel_pass_snapshot", sample))
	_write_manifest(snapshot)
	_assert(_snapshot_is_read_only(snapshot), "Performance feel snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_scenario_performance_feel_pass.v1", "Performance feel schema is stable")
	_assert(String(snapshot.get("performance_gate", "")) == "pass", "Repeated snapshot sample stays within budget")
	_assert(bool(snapshot.get("repeated_snapshot_budget_ok", false)), "Repeated snapshot budget flag is green")
	_assert(bool(snapshot.get("density_ok", false)), "Density gate is green")
	_assert(bool(snapshot.get("route_overlap_ok", false)), "Route overlap gate is green")
	_assert(bool(snapshot.get("cue_ok", false)), "Cue gate is green")
	_assert(bool(snapshot.get("ready_for_visible_playtest", false)), "Headless feel gate is ready for visible playtest")
	_assert(int(snapshot.get("sample_count", 0)) == SAMPLE_COUNT, "Snapshot records sample count")
	_assert(int(snapshot.get("avg_usec", 0)) > 0, "Snapshot records average sample time")
	_assert(bool(snapshot.get("line_within_limit", false)), "Mission Control line stays within budget")
	_assert(int(snapshot.get("visible_line_count", 0)) <= int(snapshot.get("max_visible_line_count", 1)), "Visible line count stays capped")
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_734 manifest is written")
	scene.queue_free()
	await _wait_frames(2)


func _measure_command_feedback_sample(controller: Node) -> Dictionary:
	var budget: int = _snapshot_budget_usec()
	var total_usec: int = 0
	var max_usec: int = 0
	for _index in range(SAMPLE_COUNT):
		var started_usec: int = Time.get_ticks_usec()
		var snapshot: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
		var elapsed_usec: int = maxi(1, Time.get_ticks_usec() - started_usec)
		total_usec += elapsed_usec
		max_usec = maxi(max_usec, elapsed_usec)
		_assert(not snapshot.is_empty(), "Command feedback sample is not empty")
	var avg_usec: int = int(ceil(float(total_usec) / float(SAMPLE_COUNT)))
	return {
		"sample_count": SAMPLE_COUNT,
		"total_usec": total_usec,
		"avg_usec": avg_usec,
		"max_usec": max_usec,
		"budget_avg_usec": budget,
		"budget_max_usec": budget,
	}


func _snapshot_budget_usec() -> int:
	var contract: Dictionary = _read_json(PERFORMANCE_BUDGET_PATH)
	var project_budget: Dictionary = Dictionary(contract.get("project_budget", {}))
	var snapshot_budget: Dictionary = Dictionary(project_budget.get("snapshot", {}))
	return maxi(int(snapshot_budget.get("max_build_p99_usec", 2000000)), 1)


func _write_manifest(snapshot: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = snapshot.duplicate(true)
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_734 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
