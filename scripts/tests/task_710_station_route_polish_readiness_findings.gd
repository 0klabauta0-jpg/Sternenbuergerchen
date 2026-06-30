extends SceneTree

const STATION_ROUTE_POLISH_READINESS_FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_route_polish_readiness_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_710_station_route_polish_readiness_findings.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_polish_readiness_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_710 Station Route Polish Readiness Findings ===")
	_test_docs()
	_test_missing_evidence_blocks()
	_test_open_window_review_snapshot()
	_test_ready_snapshot_after_manual_notes()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_710: FAILED")
		quit(1)
		return
	print("TASK_710: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_710 task file exists")
	_assert(task_text.contains("Station Route Polish Readiness Findings"), "Task documents polish readiness findings")
	_assert(contract_text.contains("Station Route Polish Readiness Findings"), "Interaction contract documents TASK_710")
	_assert(status_text.contains("TASK_710 - Station Route Polish Readiness Findings"), "Implementation status tracks TASK_710")
	_assert(roadmap_text.contains("TASK_710 - Station Route Polish Readiness Findings (implementiert)"), "Roadmap marks TASK_710 implemented")
	_assert(handbook_text.contains("TASK_710 - Station Route Polish Readiness Findings"), "Current handbook references TASK_710")
	_assert(handbook_text.contains('data-export-key="station_route_polish_readiness_findings.manifest_path"'), "Current handbook exports TASK_710 manifest path")


func _test_missing_evidence_blocks() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_POLISH_READINESS_FINDINGS_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(_snapshot_is_read_only(snapshot), "Missing-evidence snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_route_polish_readiness_findings.v1", "Polish readiness schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing evidence blocks readiness")
	_assert(int(snapshot.get("blocking_issue_count", 0)) > 0, "Missing evidence produces blockers")
	_assert(not bool(snapshot.get("visual_polish_ready", true)), "Missing evidence is not visual-polish ready")
	_assert(not bool(snapshot.get("host_client_acceptance_ready", true)), "Missing evidence is not host/client ready")


func _test_open_window_review_snapshot() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_POLISH_READINESS_FINDINGS_SCRIPT.call("build_snapshot", _fake_evidence(), _fake_open_notes(), {}))
	_assert(_snapshot_is_read_only(snapshot), "Open review snapshot is read-only")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Open review has no technical blockers")
	_assert(int(snapshot.get("manual_note_count", 0)) > 0, "Open review records manual notes")
	_assert(String(snapshot.get("status", "")) == "needs_window_review", "Open review waits for window review")
	_assert(bool(snapshot.get("visual_polish_ready", false)), "Open review is technically visual-polish ready")
	_assert(not bool(snapshot.get("host_client_acceptance_ready", true)), "Open review is not host/client ready")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_709"), "Open review recommends TASK_709")


func _test_ready_snapshot_after_manual_notes() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_POLISH_READINESS_FINDINGS_SCRIPT.call("build_snapshot", _fake_evidence(), _fake_done_notes(), {}))
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Done review has no technical blockers")
	_assert(int(snapshot.get("warning_count", -1)) == 0, "Done review has no warnings")
	_assert(String(snapshot.get("status", "")) == "ready_for_host_client_acceptance", "Done review can become host/client ready")
	_assert(bool(snapshot.get("host_client_acceptance_ready", false)), "Done review marks host/client acceptance ready")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("Host/Client"), "Done review recommends host/client acceptance")


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_POLISH_READINESS_FINDINGS_SCRIPT.call("build_snapshot", _fake_evidence(), _fake_open_notes(), {}))
	snapshot["task_id"] = "TASK_710"
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Polish readiness manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_710", "Manifest records TASK_710")
	_assert(String(parsed.get("status", "")) == "needs_window_review", "Manifest records open window review status")
	_assert(not bool(parsed.get("host_client_acceptance_ready", true)), "Manifest does not claim host/client readiness while open")


func _fake_evidence() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_visual_evidence.v1",
		"status": "needs_manual_window_review",
		"png_path": "tmp/station_route_visual_evidence.png",
		"manifest_path": "tmp/station_route_visual_evidence.json",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_window_review_required": true,
		"manual_window_review_done": false,
		"generated_evidence_board": true,
		"viewport_readback_available": false,
		"door_runtime_visual_state": "open",
		"door_layout_tone": "success",
		"all_gates_complete": true,
		"render_object_reaction_visual_count": 17,
		"evidence_board_style_id": "station_route_labeled_v1",
		"evidence_board_label_count": 14,
	}


func _fake_open_notes() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_window_playtest_notes.v1",
		"manifest_path": "tmp/station_route_window_playtest_notes.json",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_window_review_done": false,
		"status": "awaiting_manual_notes",
		"rating": "open",
		"required_check_count": 8,
		"completed_check_count": 0,
		"note_fields": [],
	}


func _fake_done_notes() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_window_playtest_notes.v1",
		"manifest_path": "tmp/station_route_window_playtest_notes.json",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_window_review_done": true,
		"manual_review_done": true,
		"status": "complete",
		"rating": "good_enough",
		"required_check_count": 8,
		"completed_check_count": 8,
		"note_fields": [],
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_710 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


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
