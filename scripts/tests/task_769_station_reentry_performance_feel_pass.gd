extends SceneTree

const PERFORMANCE_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_performance_feel_pass.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_769_station_reentry_performance_feel_pass.md"
const TASK_768_PATH: String = "res://docs/tasks/TASK_768_station_reentry_first_mission_preview_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const PERFORMANCE_BUDGET_PATH: String = "res://data/performance_budget_contract.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_performance_feel_pass.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_769 Station Reentry Performance Feel Pass ===")
	_test_docs_contract_and_report()
	_test_performance_contract()
	_write_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_769: FAILED")
		quit(1)
		return
	print("TASK_769: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_769 task file exists")
	_assert(task_text.contains("Station Reentry Performance Feel Pass"), "TASK_769 task names performance feel pass")
	_assert(FileAccess.file_exists(TASK_768_PATH), "TASK_768 task remains available")
	_assert(status_text.contains("TASK_769 - Station Reentry Performance Feel Pass"), "Implementation status tracks TASK_769")
	_assert(roadmap_text.contains("TASK_769 - Station Reentry Performance Feel Pass (implementiert)"), "Roadmap marks TASK_769 implemented")
	_assert(contract_text.contains("Station-Reentry-Performance-Feel-Pass"), "Mission command feedback contract documents TASK_769")
	_assert(report_text.contains("TASK_769") and report_text.contains("Aktueller Griff: TASK_773"), "Reentry handbook preserves TASK_769 context and current TASK_773 follow-up")
	_assert(report_text.contains('data-export-key="reentry_performance.fast_gate_pass"'), "Reentry handbook exports TASK_769 fast gate")
	_assert(controller_text.contains("STATION_REENTRY_PERFORMANCE_FEEL_PASS_SCRIPT"), "Controller preloads TASK_769 contract")
	_assert(controller_text.contains("get_station_reentry_performance_feel_pass_snapshot"), "Controller exposes TASK_769 snapshot")
	_assert(FileAccess.file_exists(PERFORMANCE_BUDGET_PATH), "Performance budget contract exists")


func _test_performance_contract() -> void:
	var snapshot: Dictionary = Dictionary(PERFORMANCE_SCRIPT.call(
		"build_snapshot",
		_build_preview_snapshot(),
		_build_performance_sample(),
		{}
	))
	_assert(_snapshot_is_read_only(snapshot), "TASK_769 snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_performance_feel_pass.v1", "TASK_769 schema is stable")
	_assert(String(snapshot.get("performance_gate", "")) == "pass", "Performance sample passes broad budget")
	_assert(bool(snapshot.get("ready_for_visible_playtest", false)), "Snapshot is ready for visible playtest")
	_assert(bool(snapshot.get("preview_gate_ok", false)), "TASK_768 preview gate stays green")
	_assert(bool(snapshot.get("preview_text_ok", false)), "Preview text names PREVIEW, ETA and risk")
	_assert(bool(snapshot.get("selected_order_budget_ok", false)), "Selected order text stays in budget")
	_assert(bool(snapshot.get("station_context_ok", false)), "Station context remains visible")
	_assert(bool(snapshot.get("route_cue_budget_ok", false)), "Route and cue stay in budget")
	_assert(bool(snapshot.get("repeated_snapshot_budget_ok", false)), "Repeated snapshot budget stays green")
	_assert(int(snapshot.get("selected_order_char_count", 0)) <= int(snapshot.get("selected_order_char_limit", 0)), "Snapshot records selected-order budget")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_770"), "TASK_769 routes to host/client sync followup")


func _write_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(PERFORMANCE_SCRIPT.call("build_snapshot", _build_preview_snapshot(), _build_performance_sample(), {}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_769 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_769 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_769", "Manifest records TASK_769")
	_assert(bool(parsed.get("ready_for_visible_playtest", false)), "Manifest records visible-playtest readiness")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _build_preview_snapshot() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_first_mission_preview_polish.v1",
		"task_id": "TASK_768",
		"gate": "pass",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"station_context_active": true,
		"selected_order_text": "WP 1/1 MOVE | WARTET AUF GO | Ziel 544,288 | PREVIEW Dist 120m | ETA~2s | RISK ? no intel",
		"station_route_line": "ROUTE AA > DOOR > COM > CARGO | NEXT AA",
		"station_cue_line": "CUE AA: BLUE naeher ran | 3.9km",
		"risk_state": "unknown",
		"risk_preview_text": "RISK ? no intel",
		"distance_world": 120.0,
		"eta_seconds_estimate": 2.0,
	}


func _build_performance_sample() -> Dictionary:
	var budget: int = _snapshot_budget_usec()
	return {
		"sample_count": 5,
		"total_usec": 5000,
		"avg_usec": 1000,
		"max_usec": 1500,
		"budget_avg_usec": budget,
		"budget_max_usec": budget,
	}


func _snapshot_budget_usec() -> int:
	var contract: Dictionary = _read_json(PERFORMANCE_BUDGET_PATH)
	var project_budget: Dictionary = Dictionary(contract.get("project_budget", {}))
	var snapshot_budget: Dictionary = Dictionary(project_budget.get("snapshot", {}))
	return maxi(int(snapshot_budget.get("max_build_p99_usec", 2000000)), 1)


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
