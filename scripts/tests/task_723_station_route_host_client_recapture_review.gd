extends SceneTree

const RECAPTURE_REVIEW_SCRIPT: GDScript = preload("res://scripts/mission/station_route_host_client_recapture_review.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_723_station_route_host_client_recapture_review.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const CAPTURE_SCRIPT_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const CAPTURE_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const HUD_POLISH_MANIFEST_PATH: String = "res://tmp/station_route_hud_visual_polish.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_host_client_recapture_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_723 Station Route Host/Client Recapture Review ===")
	_test_docs_and_capture_script()
	_test_missing_inputs_block()
	_test_open_visual_review()
	_test_followup_polish_review()
	_test_acceptance_ready_fake_snapshot()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_723: FAILED")
		quit(1)
		return
	print("TASK_723: ALL PASSED")
	quit(0)


func _test_docs_and_capture_script() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var capture_script_text: String = _read_text(CAPTURE_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_723 task file exists")
	_assert(task_text.contains("Station Route Host/Client Recapture Review"), "Task documents recapture review")
	_assert(contract_text.contains("Station Route Host/Client Recapture Review"), "Interaction contract documents TASK_723")
	_assert(status_text.contains("TASK_723 - Station Route Host/Client Recapture Review"), "Implementation status tracks TASK_723")
	_assert(roadmap_text.contains("TASK_723 - Station Route Host/Client Recapture Review (implementiert)"), "Roadmap marks TASK_723 implemented")
	_assert(report_text.contains("TASK_723 - Station Route Host/Client Recapture Review"), "Current report references TASK_723")
	_assert(report_text.contains('data-export-key="station_route_host_client_recapture_review.manifest_path"'), "Current report exports TASK_723 manifest path")
	_assert(capture_script_text.contains("station_route_hud_visual_polish_task_id"), "Capture script records TASK_722 recapture link")
	_assert(capture_script_text.contains("station_route_host_client_recapture_review_task_id"), "Capture script records TASK_723 recapture link")
	_assert(capture_script_text.contains("station_route_hud_polish_recapture_done"), "Capture script records recapture done gate")


func _test_missing_inputs_block() -> void:
	var snapshot: Dictionary = Dictionary(RECAPTURE_REVIEW_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(_snapshot_is_read_only(snapshot), "Missing-input snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_route_host_client_recapture_review.v1", "Recapture review schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing inputs block recapture review")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 2, "Missing inputs produce blockers")


func _test_open_visual_review() -> void:
	var snapshot: Dictionary = Dictionary(RECAPTURE_REVIEW_SCRIPT.call("build_snapshot", _fake_capture_manifest(), _fake_hud_polish_manifest(), {}))
	_assert(_snapshot_is_read_only(snapshot), "Open visual-review snapshot is read-only")
	_assert(String(snapshot.get("status", "")) == "needs_visual_review", "Ready recapture waits for visual review")
	_assert(bool(snapshot.get("hud_polish_ready", false)), "Open visual-review HUD polish is ready")
	_assert(bool(snapshot.get("recapture_ready", false)), "Open visual-review recapture is ready")
	_assert(int(snapshot.get("manual_note_count", 0)) > 0, "Open visual-review records manual note")


func _test_followup_polish_review() -> void:
	var snapshot: Dictionary = Dictionary(RECAPTURE_REVIEW_SCRIPT.call("build_snapshot", _fake_capture_manifest(), _fake_hud_polish_manifest(), _visual_review_with_followup_polish()))
	_assert(_snapshot_is_read_only(snapshot), "Followup-polish snapshot is read-only")
	_assert(String(snapshot.get("status", "")) == "needs_followup_polish", "Followup visual issues request polish")
	_assert(int(snapshot.get("followup_polish_issue_count", 0)) >= 2, "Followup visual issues are counted")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_724"), "Followup visual issues recommend TASK_724")


func _test_acceptance_ready_fake_snapshot() -> void:
	var snapshot: Dictionary = Dictionary(RECAPTURE_REVIEW_SCRIPT.call("build_snapshot", _fake_capture_manifest(), _fake_hud_polish_manifest(), _visual_review_clean()))
	_assert(_snapshot_is_read_only(snapshot), "Clean recapture snapshot is read-only")
	_assert(String(snapshot.get("status", "")) == "ready_for_acceptance_decision", "Clean visual review is ready for acceptance decision")
	_assert(int(snapshot.get("followup_polish_issue_count", -1)) == 0, "Clean visual review has no followup polish issues")


func _test_actual_manifest_write() -> void:
	_ensure_output_dir()
	var capture_manifest: Dictionary = _read_json(CAPTURE_MANIFEST_PATH)
	var hud_polish_manifest: Dictionary = _read_json(HUD_POLISH_MANIFEST_PATH)
	if capture_manifest.is_empty():
		capture_manifest = _fake_capture_manifest()
	if hud_polish_manifest.is_empty():
		hud_polish_manifest = _fake_hud_polish_manifest()
	var snapshot: Dictionary = Dictionary(RECAPTURE_REVIEW_SCRIPT.call("build_snapshot", capture_manifest, hud_polish_manifest, {}, {
		"capture_manifest_path": "tmp/host_client_two_window_real_run_review.json",
		"hud_polish_manifest_path": "tmp/station_route_hud_visual_polish.json",
	}))
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_723 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_723", "Manifest records TASK_723")
	_assert(String(parsed.get("status", "")) == "needs_visual_review", "Manifest records open visual-review status")
	_assert(bool(parsed.get("recapture_ready", false)), "Manifest records recapture readiness")
	_assert(bool(parsed.get("hud_polish_ready", false)), "Manifest records HUD-polish readiness")
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
		"station_route_hud_visual_polish_task_id": "TASK_722",
		"station_route_host_client_recapture_review_task_id": "TASK_723",
		"station_route_hud_polish_recapture_done": true,
		"station_route_hud_polish_recapture_gate": "review_ready",
		"review_checks": [
			"station_route_hud_polish_recapture_review",
			"station_route_fireteam_mini_map_safe_margin",
			"station_route_label_backplates_readable",
			"station_route_nav_placeholder_hidden",
		],
	}


func _fake_hud_polish_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_hud_visual_polish.v1",
		"task_id": "TASK_722",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"gate": "ready_for_recapture",
	}


func _visual_review_with_followup_polish() -> Dictionary:
	return {
		"visual_review_done": true,
		"visual_decision": "needs_followup_polish",
		"host_map_visible": true,
		"client_map_visible": true,
		"fireteam_mini_cards_no_longer_cover_map": false,
		"station_route_labels_backplate_readable": true,
		"top_nav_placeholder_hidden": true,
		"door_station_route_visible": true,
		"fireteam_cards_still_cover_map": true,
		"fireteam_cards_still_cover_map_note": "Die Fireteam-Mini-Karten verdecken weiterhin zu viel Kartenrand.",
		"route_line_still_unclear": true,
		"route_line_still_unclear_note": "Route-Line ist im echten Fenster noch nicht schnell genug lesbar.",
	}


func _visual_review_clean() -> Dictionary:
	return {
		"visual_review_done": true,
		"visual_decision": "ready_for_acceptance_decision",
		"host_map_visible": true,
		"client_map_visible": true,
		"fireteam_mini_cards_no_longer_cover_map": true,
		"station_route_labels_backplate_readable": true,
		"top_nav_placeholder_hidden": true,
		"door_station_route_visible": true,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_723 manifest for writing")
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
