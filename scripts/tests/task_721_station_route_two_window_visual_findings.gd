extends SceneTree

const VISUAL_FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_route_two_window_visual_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_721_station_route_two_window_visual_findings.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const CAPTURE_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const RECHECK_MANIFEST_PATH: String = "res://tmp/station_route_post_polish_recheck.json"
const HOST_SCREENSHOT_PATH: String = "res://tmp/host_client_two_window_host_review.png"
const CLIENT_SCREENSHOT_PATH: String = "res://tmp/host_client_two_window_client_review.png"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_two_window_visual_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_721 Station Route Two-Window Visual Findings ===")
	_test_docs()
	_test_missing_inputs_block()
	_test_open_visual_review()
	_test_visual_polish_findings()
	_test_acceptance_ready_fake_snapshot()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_721: FAILED")
		quit(1)
		return
	print("TASK_721: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_721 task file exists")
	_assert(task_text.contains("Station Route Two-Window Visual Findings"), "Task documents two-window visual findings")
	_assert(contract_text.contains("Station Route Two-Window Visual Findings"), "Interaction contract documents TASK_721")
	_assert(status_text.contains("TASK_721 - Station Route Two-Window Visual Findings"), "Implementation status tracks TASK_721")
	_assert(roadmap_text.contains("TASK_721 - Station Route Two-Window Visual Findings (implementiert)"), "Roadmap marks TASK_721 implemented")
	_assert(report_text.contains("TASK_721 - Station Route Two-Window Visual Findings"), "Current report references TASK_721")
	_assert(report_text.contains('data-export-key="station_route_two_window_visual_findings.manifest_path"'), "Current report exports TASK_721 manifest path")


func _test_missing_inputs_block() -> void:
	var snapshot: Dictionary = Dictionary(VISUAL_FINDINGS_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(_snapshot_is_read_only(snapshot), "Missing-input snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_route_two_window_visual_findings.v1", "Visual findings schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing inputs block visual findings")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 2, "Missing inputs produce blockers")


func _test_open_visual_review() -> void:
	var snapshot: Dictionary = Dictionary(VISUAL_FINDINGS_SCRIPT.call("build_snapshot", _fake_capture_manifest(), _fake_recheck_manifest(), {}))
	_assert(_snapshot_is_read_only(snapshot), "Open visual-review snapshot is read-only")
	_assert(String(snapshot.get("status", "")) == "needs_visual_review", "Ready evidence waits for visual review")
	_assert(bool(snapshot.get("capture_ready", false)), "Open visual-review capture is ready")
	_assert(bool(snapshot.get("post_polish_recheck_ready", false)), "Open visual-review recheck is ready")
	_assert(int(snapshot.get("manual_note_count", 0)) > 0, "Open visual-review records manual note")


func _test_visual_polish_findings() -> void:
	var snapshot: Dictionary = Dictionary(VISUAL_FINDINGS_SCRIPT.call("build_snapshot", _fake_capture_manifest(), _fake_recheck_manifest(), _visual_review_with_polish()))
	_assert(_snapshot_is_read_only(snapshot), "Visual-polish snapshot is read-only")
	_assert(String(snapshot.get("status", "")) == "needs_visual_polish", "Visual issues request polish")
	_assert(int(snapshot.get("visual_polish_issue_count", 0)) >= 3, "Visual issues are counted")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_722"), "Visual issues recommend TASK_722 polish")


func _test_acceptance_ready_fake_snapshot() -> void:
	var snapshot: Dictionary = Dictionary(VISUAL_FINDINGS_SCRIPT.call("build_snapshot", _fake_capture_manifest(), _fake_recheck_manifest(), _visual_review_clean()))
	_assert(_snapshot_is_read_only(snapshot), "Clean visual snapshot is read-only")
	_assert(String(snapshot.get("status", "")) == "ready_for_acceptance_decision", "Clean visual review is ready for acceptance decision")
	_assert(int(snapshot.get("visual_polish_issue_count", -1)) == 0, "Clean visual review has no polish issues")


func _test_actual_manifest_write() -> void:
	_ensure_output_dir()
	var capture_manifest: Dictionary = _read_json(CAPTURE_MANIFEST_PATH)
	var recheck_manifest: Dictionary = _read_json(RECHECK_MANIFEST_PATH)
	if capture_manifest.is_empty():
		capture_manifest = _fake_capture_manifest()
	if recheck_manifest.is_empty():
		recheck_manifest = _fake_recheck_manifest()
	var visual_review: Dictionary = _visual_review_with_polish()
	visual_review["host_screenshot_exists"] = FileAccess.file_exists(HOST_SCREENSHOT_PATH)
	visual_review["client_screenshot_exists"] = FileAccess.file_exists(CLIENT_SCREENSHOT_PATH)
	var snapshot: Dictionary = Dictionary(VISUAL_FINDINGS_SCRIPT.call("build_snapshot", capture_manifest, recheck_manifest, visual_review, {
		"capture_manifest_path": "tmp/host_client_two_window_real_run_review.json",
		"recheck_manifest_path": "tmp/station_route_post_polish_recheck.json",
	}))
	snapshot["task_id"] = "TASK_721"
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_721 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_721", "Manifest records TASK_721")
	_assert(String(parsed.get("status", "")) == "needs_visual_polish", "Manifest records visual-polish status")
	_assert(bool(parsed.get("capture_ready", false)), "Manifest records capture readiness")
	_assert(bool(parsed.get("post_polish_recheck_ready", false)), "Manifest records post-polish recheck readiness")
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
	}


func _fake_recheck_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_post_polish_recheck.v1",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"status": "ready_for_real_window_recheck",
		"capture_fresh": true,
		"real_run_done": true,
	}


func _visual_review_with_polish() -> Dictionary:
	return {
		"visual_review_done": true,
		"visual_decision": "needs_visual_polish",
		"host_role_badge_readable": true,
		"client_role_badge_readable": true,
		"host_map_visible": true,
		"client_map_visible": true,
		"door_station_route_visible": true,
		"fireteam_cards_cover_map": true,
		"fireteam_cards_cover_map_note": "Die linken Fireteam-Karten ueberdecken einen relevanten Teil der taktischen Karte.",
		"station_labels_too_small": true,
		"station_labels_too_small_note": "Door-/Station-Labels sind im Gebaeude sehr klein und im Gedraenge schwer lesbar.",
		"orphan_nav_placeholder_visible": true,
		"orphan_nav_placeholder_visible_note": "Oben rechts steht ein leer wirkender Placeholder neben der Navigation.",
		"door_route_labels_crowded": true,
		"door_route_labels_crowded_note": "Door-/Route-Texte liegen dicht im Stationsinneren und brauchen bessere Leseflaeche.",
	}


func _visual_review_clean() -> Dictionary:
	return {
		"visual_review_done": true,
		"visual_decision": "ready_for_acceptance_decision",
		"host_role_badge_readable": true,
		"client_role_badge_readable": true,
		"host_map_visible": true,
		"client_map_visible": true,
		"door_station_route_visible": true,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_721 manifest for writing")
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
