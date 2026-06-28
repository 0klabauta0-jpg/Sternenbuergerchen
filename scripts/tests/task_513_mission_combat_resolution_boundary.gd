extends SceneTree

const RESOLVER_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_resolution_resolver.gd")

const RESOLVER_PATH: String = "res://scripts/mission/mission_combat_resolution_resolver.gd"
const DRIVER_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"
const TASK_PATH: String = "res://docs/tasks/TASK_513_mission_combat_resolution_boundary.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_513 Mission Combat Resolution Boundary ===")
	_test_resolution_decisions()
	_test_victory_conditions()
	_test_countdown_sources()
	_test_mission_result_payload()
	_test_source_boundaries()
	_test_docs_reference_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_resolution_decisions() -> void:
	var resolver = RESOLVER_SCRIPT.new()
	var decision: Dictionary = Dictionary(resolver.call("build_resolution_decision", {
		"combat_finished": false,
		"duration_seconds": 31.0,
		"mission_time_limit_seconds": 30.0,
		"enemy_team_id": "team_bravo",
	}))
	_assert(String(decision.get("result", "")) == "defeat" and String(decision.get("result_condition_override", "")) == "time_limit", "Time limit resolves defeat with time_limit override")

	decision = Dictionary(resolver.call("build_resolution_decision", {
		"victory_condition_met": true,
		"friendly_team_id": "team_alpha",
		"enemy_team_id": "team_bravo",
	}))
	_assert(String(decision.get("result", "")) == "victory" and String(decision.get("winning_team_id", "")) == "team_alpha", "Victory condition resolves friendly victory")

	decision = Dictionary(resolver.call("build_resolution_decision", {
		"friendly_fit_count": 0,
		"has_seen_active_friendly_units": true,
		"has_pending_friendly_insertions": false,
		"enemy_team_id": "team_bravo",
	}))
	_assert(String(decision.get("result", "")) == "defeat" and String(decision.get("winning_team_id", "")) == "team_bravo", "No fit friendlies after insertion resolves defeat")

	decision = Dictionary(resolver.call("build_resolution_decision", {
		"friendly_fit_count": 0,
		"has_seen_active_friendly_units": true,
		"has_pending_friendly_insertions": true,
		"enemy_team_id": "team_bravo",
	}))
	_assert(decision.is_empty(), "Pending friendly insertion blocks defeat resolution")


func _test_victory_conditions() -> void:
	var resolver = RESOLVER_SCRIPT.new()
	_assert(bool(resolver.call("is_victory_condition_met", "objective_capture", true, 0.0, 8.0, false)), "Objective capture victory follows objective ownership")
	_assert(not bool(resolver.call("is_victory_condition_met", "objective_defense", true, 3.0, 8.0, false)), "Objective defense waits for hold duration")
	_assert(bool(resolver.call("is_victory_condition_met", "objective_defense", true, 8.1, 8.0, false)), "Objective defense resolves after hold duration")
	_assert(bool(resolver.call("is_victory_condition_met", "elimination", false, 0.0, 0.0, true)), "Elimination victory follows enemy elimination")


func _test_countdown_sources() -> void:
	var resolver = RESOLVER_SCRIPT.new()
	var countdown: Dictionary = Dictionary(resolver.call("build_objective_countdown_source", "objective_defense", 8.0, 3.0, true, 0.0, -1.0))
	_assert(String(countdown.get("timer_source", "")) == "objective_defense_hold" and String(countdown.get("timer_state", "")) == "active", "Objective defense countdown is active while holding")
	_assert(is_equal_approx(float(countdown.get("countdown_seconds", -1.0)), 5.0), "Objective defense countdown reports remaining hold seconds")

	countdown = Dictionary(resolver.call("build_objective_countdown_source", "objective_capture", 0.0, 0.0, false, 30.0, 12.5))
	_assert(String(countdown.get("timer_source", "")) == "mission_time_limit" and String(countdown.get("timer_state", "")) == "active", "Time limit countdown is active when mission timer runs")
	_assert(is_equal_approx(float(countdown.get("countdown_seconds", -1.0)), 12.5), "Time limit countdown reports remaining seconds")
	_assert(Dictionary(resolver.call("build_objective_countdown_source", "objective_capture", 0.0, 0.0, false, 0.0, -1.0)).is_empty(), "No countdown source when no timed condition exists")


func _test_mission_result_payload() -> void:
	var resolver = RESOLVER_SCRIPT.new()
	var result: Dictionary = Dictionary(resolver.call("build_mission_result", {
		"result": "victory",
		"winning_team_id": "team_alpha",
		"friendly_team_id": "team_alpha",
		"win_condition_type": "objective_capture",
		"objective_captured": true,
		"duration_seconds": 42.0,
		"team_states": [{"team_id": "team_alpha", "fit_count": 4}],
		"fireteam_tactical_debrief": [{"fireteam_id": "blue", "contact_report_count": 2}],
	}))
	_assert(String(result.get("mission_outcome", "")) == "won", "Mission result keeps authority contract outcome")
	_assert(String(result.get("win_condition_type", "")) == "objective_capture", "Mission result keeps win condition type")
	_assert(Array(result.get("fireteam_tactical_debrief", [])).size() == 1, "Mission result keeps fireteam tactical debrief")


func _test_source_boundaries() -> void:
	var resolver_source: String = _read_text(RESOLVER_PATH)
	var driver_source: String = _read_text(DRIVER_PATH)
	_assert(resolver_source.contains("class_name MissionCombatResolutionResolver"), "Mission combat resolution resolver exists under scripts/mission")
	_assert(not resolver_source.contains("enqueue_command") and not resolver_source.contains("enqueue_effect"), "Resolver does not mutate command or effect queues")
	_assert(not resolver_source.contains("get_node_or_null") and not resolver_source.contains("get_tree()"), "Resolver has no SceneTree dependency")
	_assert(driver_source.contains("MISSION_COMBAT_RESOLUTION_RESOLVER_SCRIPT"), "Combat driver preloads resolution resolver")
	_assert(driver_source.contains("build_resolution_decision"), "Combat driver delegates resolution decisions")
	_assert(driver_source.contains("build_objective_countdown_source"), "Combat driver delegates countdown source")


func _test_docs_reference_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("TASK_513 - Mission Combat Resolution Boundary"), "TASK_513 task file exists")
	_assert(roadmap_text.contains("TASK_513 - Mission Combat Resolution Boundary"), "Roadmap lists TASK_513")
	_assert(status_text.contains("TASK_513 - Mission Combat Resolution Boundary"), "Implementation status lists TASK_513")
	_assert(report_text.contains("TASK_513 - Mission Combat Resolution Boundary"), "Review report references TASK_513")


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
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
