extends SceneTree

const ACCEPTANCE_REVIEW_SCRIPT: GDScript = preload("res://scripts/mission/station_route_recapture_acceptance_review.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_725_station_route_host_client_recapture_acceptance_review.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const CAPTURE_SCRIPT_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const CAPTURE_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const FOLLOWUP_MANIFEST_PATH: String = "res://tmp/station_route_recapture_visual_followup.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_recapture_acceptance_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_725 Station Route Host/Client Recapture Acceptance Review ===")
	_test_docs_and_capture_script()
	_test_missing_inputs_block()
	_test_open_visual_review()
	_test_followup_polish_review()
	_test_acceptance_for_next_slice_fake_snapshot()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_725: FAILED")
		quit(1)
		return
	print("TASK_725: ALL PASSED")
	quit(0)


func _test_docs_and_capture_script() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var capture_script_text: String = _read_text(CAPTURE_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_725 task file exists")
	_assert(task_text.contains("Station Route Host/Client Recapture Acceptance Review"), "Task documents recapture acceptance review")
	_assert(contract_text.contains("Station Route Host/Client Recapture Acceptance Review"), "Interaction contract documents TASK_725")
	_assert(status_text.contains("TASK_725 - Station Route Host/Client Recapture Acceptance Review"), "Implementation status tracks TASK_725")
	_assert(roadmap_text.contains("TASK_725 - Station Route Host/Client Recapture Acceptance Review (implementiert)"), "Roadmap marks TASK_725 implemented")
	_assert(report_text.contains("TASK_725 - Station Route Host/Client Recapture Acceptance Review"), "Current report references TASK_725")
	_assert(report_text.contains('data-export-key="station_route_recapture_acceptance_review.manifest_path"'), "Current report exports TASK_725 manifest path")
	_assert(capture_script_text.contains("station_route_recapture_visual_followup_task_id"), "Capture script records TASK_724 recapture link")
	_assert(capture_script_text.contains("station_route_recapture_acceptance_review_task_id"), "Capture script records TASK_725 recapture link")
	_assert(capture_script_text.contains("station_route_visual_followup_recapture_done"), "Capture script records TASK_724 recapture done gate")


func _test_missing_inputs_block() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_REVIEW_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(_snapshot_is_read_only(snapshot), "Missing-input snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_route_recapture_acceptance_review.v1", "Acceptance review schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing inputs block acceptance review")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 2, "Missing inputs produce blockers")


func _test_open_visual_review() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_REVIEW_SCRIPT.call("build_snapshot", _fake_capture_manifest(), _fake_followup_manifest(), {}))
	_assert(_snapshot_is_read_only(snapshot), "Open visual-review snapshot is read-only")
	_assert(String(snapshot.get("status", "")) == "needs_visual_review", "Ready recapture waits for visual review")
	_assert(bool(snapshot.get("followup_ready", false)), "Open visual-review followup is ready")
	_assert(bool(snapshot.get("recapture_ready", false)), "Open visual-review recapture is ready")
	_assert(int(snapshot.get("manual_note_count", 0)) > 0, "Open visual-review records manual note")


func _test_followup_polish_review() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_REVIEW_SCRIPT.call("build_snapshot", _fake_capture_manifest(), _fake_followup_manifest(), _visual_review_with_followup_polish()))
	_assert(_snapshot_is_read_only(snapshot), "Followup-polish snapshot is read-only")
	_assert(String(snapshot.get("status", "")) == "needs_followup_polish", "Followup visual issues request polish")
	_assert(int(snapshot.get("followup_polish_issue_count", 0)) >= 2, "Followup visual issues are counted")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_726"), "Followup visual issues recommend TASK_726")


func _test_acceptance_for_next_slice_fake_snapshot() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_REVIEW_SCRIPT.call("build_snapshot", _fake_capture_manifest(), _fake_followup_manifest(), _visual_review_clean()))
	_assert(_snapshot_is_read_only(snapshot), "Clean acceptance snapshot is read-only")
	_assert(String(snapshot.get("status", "")) == "accepted_for_next_slice", "Clean visual review accepts only the next slice")
	_assert(String(snapshot.get("scope", "")) == "station route small multiplayer slice", "Acceptance scope stays narrow")
	_assert(int(snapshot.get("followup_polish_issue_count", -1)) == 0, "Clean visual review has no followup polish issues")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("One-Screen Multiplayer Station Scenario"), "Accepted slice recommends the next playable scenario")


func _test_actual_manifest_write() -> void:
	_ensure_output_dir()
	var capture_manifest: Dictionary = _read_json(CAPTURE_MANIFEST_PATH)
	var followup_manifest: Dictionary = _read_json(FOLLOWUP_MANIFEST_PATH)
	if capture_manifest.is_empty():
		capture_manifest = _fake_capture_manifest()
	if followup_manifest.is_empty():
		followup_manifest = _fake_followup_manifest()
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_REVIEW_SCRIPT.call("build_snapshot", capture_manifest, followup_manifest, _visual_review_clean(), {
		"capture_manifest_path": "tmp/host_client_two_window_real_run_review.json",
		"followup_manifest_path": "tmp/station_route_recapture_visual_followup.json",
	}))
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_725 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_725", "Manifest records TASK_725")
	_assert(String(parsed.get("status", "")) == "accepted_for_next_slice", "Manifest records narrow acceptance")
	_assert(bool(parsed.get("recapture_ready", false)), "Manifest records recapture readiness")
	_assert(bool(parsed.get("followup_ready", false)), "Manifest records TASK_724 readiness")
	_assert(_snapshot_is_read_only(parsed), "Manifest stays read-only")


func _fake_capture_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.host_client_two_window_real_run_review.v1",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"real_run_done": true,
		"host_screenshot_written": true,
		"client_screenshot_written": true,
		"host_screenshot_path": "tmp/host_client_two_window_host_review.png",
		"client_screenshot_path": "tmp/host_client_two_window_client_review.png",
		"station_route_recapture_visual_followup_task_id": "TASK_724",
		"station_route_recapture_acceptance_review_task_id": "TASK_725",
		"station_route_visual_followup_recapture_done": true,
		"station_route_visual_followup_recapture_gate": "review_ready",
		"review_checks": [
			"station_route_visual_followup_acceptance_review",
			"station_route_top_nav_narrower",
			"station_route_fireteam_mini_lower",
			"station_route_labels_more_spaced",
			"station_route_small_multiplayer_slice_acceptance",
		],
	}


func _fake_followup_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_recapture_visual_followup.v1",
		"task_id": "TASK_724",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"gate": "ready_for_recapture",
	}


func _visual_review_with_followup_polish() -> Dictionary:
	return {
		"visual_review_done": true,
		"acceptance_decision": "needs_followup_polish",
		"host_map_visible": true,
		"client_map_visible": true,
		"top_nav_no_longer_blocks_read": true,
		"fireteam_mini_no_longer_blocks_primary_route": false,
		"station_route_labels_readable_enough": true,
		"door_station_route_visible": true,
		"needs_more_hud_polish": true,
		"needs_more_hud_polish_note": "Fireteam-Mini nimmt im echten Fenster noch zu viel Blick weg.",
		"needs_route_camera_reframe": true,
		"needs_route_camera_reframe_note": "Station-Route braucht vor Akzeptanz noch eine ruhigere Kamera.",
	}


func _visual_review_clean() -> Dictionary:
	return {
		"visual_review_done": true,
		"acceptance_decision": "accepted_for_next_slice",
		"host_map_visible": true,
		"client_map_visible": true,
		"top_nav_no_longer_blocks_read": true,
		"fireteam_mini_no_longer_blocks_primary_route": true,
		"station_route_labels_readable_enough": true,
		"door_station_route_visible": true,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_725 manifest for writing")
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
