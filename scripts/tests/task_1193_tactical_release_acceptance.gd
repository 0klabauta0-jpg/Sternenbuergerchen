extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_1193_tactical_release_acceptance.md"
const RUNNER_PATH := "res://scripts/tests/run_task_1193_tactical_release_acceptance.ps1"
const BUDGET_PATH := "res://data/performance_budget_contract.json"
const MANUAL_CHECKLIST_PATH := "res://docs/dev/performance_manual_profile_checklist.md"
const SCALE_PROFILE_PATH := "res://scripts/tests/task_411_large_map_scale_profile.gd"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1193 Tactical Release Acceptance Gate ===")
	_test_release_gate_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_release_gate_contract() -> void:
	var task_text := _read_text(TASK_PATH)
	var runner_text := _read_text(RUNNER_PATH)
	var budget_text := _read_text(BUDGET_PATH)
	var checklist_text := _read_text(MANUAL_CHECKLIST_PATH)
	var scale_text := _read_text(SCALE_PROFILE_PATH)
	_assert(task_text.contains("Tactical Release Acceptance Gate"), "TASK_1193 task contract exists")
	_assert(FileAccess.file_exists(RUNNER_PATH), "Strict tactical release acceptance runner exists")
	_assert(budget_text.contains("\"release_acceptance\""), "Budget contract defines release acceptance")
	_assert(budget_text.contains("\"supported_max_map_size\""), "Budget contract fixes supported map boundary")
	_assert(budget_text.contains("\"manual_playtest_may_not_be_synthesized\": true"), "Budget contract forbids synthetic manual evidence")
	_assert(checklist_text.contains("Tactical Release Acceptance"), "Manual checklist contains tactical release acceptance")
	_assert(checklist_text.contains("128x128") and checklist_text.contains("256x256"), "Manual checklist separates supported and withheld map sizes")
	_assert(scale_text.contains("RELEASE_SUPPORTED_MAX_MAP_SIZE"), "TASK_411 exposes the release candidate max map size")
	_assert(scale_text.contains("get_task_1193_release_acceptance_snapshot"), "TASK_411 exposes release scale evidence")
	_assert(runner_text.contains("task_1187_tactical_map_frame_budget"), "Runner executes tactical map budget enforcer")
	_assert(runner_text.contains("task_1179_ground_mission_objective_playthrough"), "Runner executes real ground-mission playthrough enforcer")
	_assert(runner_text.contains("task_222_performance_regression_gate_and_manual_profile_checklist"), "Runner executes broad performance warning enforcer")
	_assert(runner_text.contains("ManualEvidencePath"), "Runner requires a manual evidence path")
	_assert(runner_text.contains("synthetic_fixture") and runner_text.contains("exit 1"), "Runner rejects synthetic or missing manual evidence")
	_assert(runner_text.contains("release_status") and runner_text.contains("blocked"), "Runner reports blocked release status honestly")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
