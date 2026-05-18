extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const BASE_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/fireteam_command_drill_24x24.json"
const MAP_PATH: String = "res://maps/fireteam_command_drill_24x24.json"
const TASK_PATH: String = "res://docs/tasks/TASK_469_fireteam_f6_drill_combat_config.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_469 Fireteam F6 Drill Combat Config ===")
	_test_scenario_carries_drill_win_condition()
	await _test_direct_drill_scene_initializes_combat_units()
	await _test_base_scene_accepts_drill_scenario_combat_override()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_scenario_carries_drill_win_condition() -> void:
	var scenario = SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	_assert(scenario != null, "Drill scenario loads")
	if scenario == null:
		return
	_assert(String(scenario.get("win_condition")) == "elimination", "Drill scenario declares elimination win condition")
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	_assert(bool(validation.get("valid", false)), "Drill scenario remains valid with win_condition")
	var serialized: Dictionary = Dictionary(scenario.call("to_dict"))
	_assert(String(serialized.get("win_condition", "")) == "elimination", "Drill scenario serializes win_condition")


func _test_direct_drill_scene_initializes_combat_units() -> void:
	var scene: Node = DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(120)
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(combat_loop != null, "Direct F6 drill exposes CombatLoopDriver")
	if combat_loop == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assert(String(combat_loop.get("win_condition")) == "elimination", "Direct F6 drill keeps elimination win condition")
	_assert(not bool(combat_loop.call("is_combat_finished")), "Direct F6 drill does not resolve before runtime units are registered")
	_assert(_get_active_friendly_count(combat_loop) >= 4, "Direct F6 drill registers four active friendly units in CombatLoop")
	_assert(_get_active_enemy_count(combat_loop) >= 4, "Direct F6 drill registers four active enemy units in CombatLoop")
	scene.queue_free()
	await _wait_frames(2)


func _test_base_scene_accepts_drill_scenario_combat_override() -> void:
	var scene: Node = BASE_SCENE.instantiate()
	var setup: Node = scene.get_node_or_null("MissionSetup")
	var combat_loop: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(setup != null and combat_loop != null, "Base mission scene exposes setup and combat loop before ready")
	if setup == null or combat_loop == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	setup.set("map_file_path", MAP_PATH)
	setup.set("scenario_file_path", SCENARIO_PATH)
	setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
	setup.set("selected_team_fireteam_ids", PackedStringArray(["drill", "drill", "drill", "drill"]))
	setup.set("defer_friendly_runtime_activation", false)
	setup.set("allow_full_roster_when_selection_empty", false)
	combat_loop.set("win_condition", "objective_capture")
	root.add_child(scene)
	await _wait_frames(120)
	_assert(String(combat_loop.get("win_condition")) == "elimination", "Injected drill scenario overrides inherited objective_capture")
	_assert(not bool(combat_loop.call("is_combat_finished")), "Injected drill scenario stays combat-active after F6-style ready")
	_assert(_get_active_friendly_count(combat_loop) >= 4, "Injected drill scenario registers active friendlies")
	_assert(_get_active_enemy_count(combat_loop) >= 4, "Injected drill scenario registers active enemies")
	scene.queue_free()
	await _wait_frames(2)


func _get_active_friendly_count(combat_loop: Node) -> int:
	if combat_loop == null or not combat_loop.has_method("get_unit_presence_audit_snapshot"):
		return 0
	var snapshot: Dictionary = Dictionary(combat_loop.call("get_unit_presence_audit_snapshot"))
	return Array(snapshot.get("active_friendly_unit_ids", [])).size()


func _get_active_enemy_count(combat_loop: Node) -> int:
	if combat_loop == null or not combat_loop.has_method("get_unit_presence_audit_snapshot"):
		return 0
	var snapshot: Dictionary = Dictionary(combat_loop.call("get_unit_presence_audit_snapshot"))
	return Array(snapshot.get("active_enemy_unit_ids", [])).size()


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK_469 - Fireteam F6 Drill Combat Config"), "TASK_469 task file exists")
	_assert(status_text.contains("TASK_469 - Fireteam F6 Drill Combat Config"), "Implementation status documents TASK_469")
	_assert(roadmap_text.contains("TASK_469 - Fireteam F6 Drill Combat Config"), "Roadmap lists TASK_469")


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
