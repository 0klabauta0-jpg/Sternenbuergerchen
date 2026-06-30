extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_660_decision_drill_snapshot_performance_budget.md"
const TASK_659_PATH: String = "res://docs/tasks/TASK_659_frontier_probe_decision_drill_f6_evidence.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const TASK_659_SCRIPT_PATH: String = "res://scripts/tests/task_659_frontier_probe_decision_drill_f6_evidence.gd"
const SELF_SCRIPT_PATH: String = "res://scripts/tests/task_660_decision_drill_snapshot_performance_budget.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/decision_drill_snapshot_performance_budget.json"
const FAST_VERIFIER_TARGET_MS: int = 1000
const FULL_DRILL_RECAPTURE_BUDGET_MS: int = 150000

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var started_msec: int = Time.get_ticks_msec()
	print("=== TASK_660 Decision Drill Snapshot Performance Budget ===")
	_test_docs_and_report()
	_test_budget_contract()
	_write_budget_manifest(started_msec)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_660: FAILED")
		quit(1)
		return
	print("TASK_660: ALL PASSED")
	quit(0)


func _test_docs_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_660 task file exists")
	_assert(task_text.contains("Decision Drill Snapshot Performance Budget"), "TASK_660 task names performance budget")
	_assert(status_text.contains("TASK_660 - Decision Drill Snapshot Performance Budget"), "Implementation status tracks TASK_660")
	_assert(roadmap_text.contains("TASK_660 - Decision Drill Snapshot Performance Budget (implementiert)"), "Roadmap marks TASK_660 implemented")
	_assert(contract_text.contains("Decision-Drill-Snapshot-Performance-Budget"), "Mission feedback contract documents TASK_660")
	_assert(report_text.contains("TASK_660 - Decision Drill Snapshot Performance Budget"), "Current handbook report tracks TASK_660")
	_assert(report_text.contains("latest_completed_task:"), "Current handbook export records a latest task")
	_assert(report_text.contains("recommended_next_task:"), "Current handbook recommends a follow-up task")
	_assert(report_text.contains('data-export-key="status.task_660_done"'), "Current handbook exports TASK_660 done status")
	_assert(report_text.contains('data-export-key="decision_drill_performance.fast_gate_pass"'), "Current handbook exports fast gate")
	_assert(report_text.contains('data-note-key="notes.decision_drill_performance"'), "Current handbook exports TASK_660 notes")


func _test_budget_contract() -> void:
	var task_659_text: String = _read_text(TASK_659_SCRIPT_PATH)
	var self_text: String = _read_text(SELF_SCRIPT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_659_text.contains("FULL_DRILL_RECAPTURE_BUDGET_MS"), "TASK_659 carries an explicit full-drill budget")
	_assert(task_659_text.contains("recapture_policy"), "TASK_659 manifest records recapture policy")
	_assert(task_659_text.contains("TASK_660 - Decision Drill Snapshot Performance Budget"), "TASK_659 still points to TASK_660")
	var mission_scene_const_token: String = "const " + "MISSION_TEST_SCENE"
	var mission_scene_path_token: String = "mission_reactivity_test" + ".tscn"
	_assert(not self_text.contains(mission_scene_const_token), "TASK_660 verifier does not preload the mission scene")
	_assert(not self_text.contains(mission_scene_path_token), "TASK_660 verifier avoids scene instantiation")
	_assert(contract_text.contains("fast_verifier_target_ms"), "Contract records fast verifier budget")
	_assert(contract_text.contains("full_drill_recapture_budget_ms"), "Contract records full drill recapture budget")
	_assert(contract_text.contains("TASK_661 - Host Client Decision Drill Click Evidence"), "Contract recommends host/client click evidence next")


func _write_budget_manifest(started_msec: int) -> void:
	_ensure_output_dir()
	var elapsed_msec: int = maxi(1, Time.get_ticks_msec() - started_msec)
	var manifest := {
		"schema": "sternenbuergerchen.decision_drill_snapshot_performance_budget.v1",
		"task_id": "TASK_660",
		"source_task_id": "TASK_659",
		"budget_type": "fast_contract_guard_for_heavy_decision_drill",
		"fast_verifier_elapsed_msec": elapsed_msec,
		"fast_verifier_target_ms": FAST_VERIFIER_TARGET_MS,
		"fast_gate": "pass" if elapsed_msec <= FAST_VERIFIER_TARGET_MS else "warn",
		"full_drill_recapture_budget_ms": FULL_DRILL_RECAPTURE_BUDGET_MS,
		"full_drill_policy": "run TASK_659 only when visual evidence or command-path recapture is required",
		"recapture_policy": {
			"default_regression": "TASK_660 fast budget guard",
			"full_visual_recapture": "TASK_659 frontier probe decision drill F6 evidence",
			"manual_window_review_required": true,
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"recommended_next_task": "TASK_661 - Host Client Decision Drill Click Evidence",
	}
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_660 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_660 manifest is written")
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.decision_drill_snapshot_performance_budget.v1", "Manifest uses TASK_660 schema")
	_assert(String(manifest.get("fast_gate", "")) != "", "Manifest records fast gate")
	_assert(bool(manifest.get("read_only", false)), "Manifest is read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


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
