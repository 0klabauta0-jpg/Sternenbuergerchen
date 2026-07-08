extends SceneTree

const Findings := preload("res://scripts/mission/release_correct_window_first_exchange_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_872_release_correct_window_first_exchange_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task871_window_capture_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_correct_window_first_exchange_visual_findings.gd"
const CAPTURE_PATH := "res://tmp/release_first_exchange_los_setup_real_window_recapture.json"
const OUTPUT_PATH := "res://tmp/release_correct_window_first_exchange_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_correct_window_first_exchange_visual_findings.v1"
const RECAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_los_setup_real_window_recapture.v1"
const LOS_STYLE_ID := "task_868_release_first_exchange_los_setup_polish_v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_873 - Release First Exchange CONTACT-FIRE Readability Fix"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_872 Release Correct Window First Exchange Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_recapture_blocks()
	_test_ready_recapture_builds_findings()
	_test_optional_actual_recapture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_872_release_correct_window_first_exchange_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_872_release_correct_window_first_exchange_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_872 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_872 read-only findings analyzer exists")
	_assert(task_text.contains("Release Correct Window First Exchange Visual Findings"), "Task names correct-window findings")
	_assert(status_text.contains("TASK_872 - Release Correct Window First Exchange Visual Findings"), "Implementation status tracks TASK_872")
	_assert(roadmap_text.contains("TASK_872 - Release Correct Window First Exchange Visual Findings (implementiert)"), "Roadmap marks TASK_872 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_873 follow-up")
	_assert(contract_text.contains("Release-Correct-Window-First-Exchange-Visual-Findings"), "Contract documents TASK_872")
	_assert(report_text.contains("Richtiges Spiel-Fenster wieder sichtbar"), "HTML report names correct window content")
	_assert(report_text.contains("NO_LOS / CONTACT PRESSURE"), "HTML report names remaining first-exchange issue")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_872 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_872\""), "Analyzer writes TASK_872 id")
	_assert(service_text.contains("SOURCE_CAPTURE_FIX_TASK_ID: String = \"TASK_871\""), "Analyzer links TASK_871")
	_assert(service_text.contains("\"correct_window_first_exchange_still_no_los\""), "Analyzer names correct-window NO_LOS issue")
	_assert(service_text.contains("\"event_log_contact_pressure_still_dominates\""), "Analyzer names CONTACT PRESSURE issue")
	_assert(service_text.contains("\"contact_fire_not_yet_player_readable\""), "Analyzer names CONTACT-FIRE readability issue")
	_assert(service_text.contains("do_not_mask_no_los_with_contact_fire_text_without_runtime_evidence"), "Analyzer rejects cosmetic CONTACT-FIRE masking")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")


func _test_missing_recapture_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing recapture manifest blocks TASK_872")
	_assert(blocker_ids.has("recapture_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("recapture_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("source_los_setup_mismatch"), "Missing manifest reports TASK_868 mismatch")
	_assert(blocker_ids.has("source_status_recapture_mismatch"), "Missing manifest reports TASK_866 mismatch")
	_assert(blocker_ids.has("source_exchange_mismatch"), "Missing manifest reports TASK_844 mismatch")
	_assert(blocker_ids.has("launch_argument_mismatch"), "Missing manifest reports launch argument mismatch")
	_assert(blocker_ids.has("capture_not_review_ready"), "Missing manifest reports capture gate issue")
	_assert(blocker_ids.has("visible_window_not_review_ready"), "Missing manifest reports visible-window gate issue")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports screenshot missing")
	_assert(blocker_ids.has("window_capture_not_trusted"), "Missing manifest reports untrusted TASK_871 capture")
	_assert(blocker_ids.has("los_setup_style_id_mismatch"), "Missing manifest reports TASK_868 style mismatch")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_ready_recapture_builds_findings() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_recapture_manifest(), _manual_review_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_872")
	_assert(String(snapshot.get("task_id", "")) == "TASK_872", "Snapshot task id matches TASK_872")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_869", "Snapshot links TASK_869")
	_assert(String(snapshot.get("source_capture_fix_task_id", "")) == "TASK_871", "Snapshot links TASK_871")
	_assert(String(snapshot.get("source_los_setup_task_id", "")) == "TASK_868", "Snapshot links TASK_868")
	_assert(bool(snapshot.get("recapture_schema_ok", false)), "Snapshot accepts TASK_869 schema")
	_assert(String(snapshot.get("capture_gate", "")) == "review_ready", "Snapshot records review_ready capture")
	_assert(String(snapshot.get("window_capture_method", "")) == "window_handle_print", "Snapshot records handle capture method")
	_assert(bool(snapshot.get("window_capture_trusted", false)), "Snapshot records trusted capture")
	_assert(bool(snapshot.get("window_handle_capture_succeeded", false)), "Snapshot records handle capture success")
	_assert(bool(snapshot.get("correct_window_content_confirmed", false)), "Snapshot confirms Sternenbuergerchen window")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good recapture has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_contact_fire_readability_fix", "Manual notes produce contact-fire fix status")
	_assert(String(snapshot.get("observed_window_state", "")) == "STERNENBUERGERCHEN_MISSION_WINDOW", "Snapshot records correct window state")
	_assert(String(snapshot.get("selected_fireteam_primary_reading", "")).contains("LOS/RANGE"), "Snapshot records selected-fireteam LOS/RANGE reading")
	_assert(String(snapshot.get("event_log_primary_reading", "")).contains("CONTACT PRESSURE"), "Snapshot records CONTACT PRESSURE reading")
	_assert(issue_ids.has("correct_window_first_exchange_still_no_los"), "Snapshot records correct-window NO_LOS issue")
	_assert(issue_ids.has("event_log_contact_pressure_still_dominates"), "Snapshot records CONTACT PRESSURE issue")
	_assert(issue_ids.has("contact_fire_not_yet_player_readable"), "Snapshot records CONTACT-FIRE issue")
	_assert(String(snapshot.get("primary_issue_id", "")) == "correct_window_first_exchange_still_no_los", "NO_LOS is primary issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_873")
	_assert(String(snapshot.get("recommended_direction", "")) == "fix_first_exchange_contact_fire_readability_on_correct_release_window", "Snapshot recommends first-exchange readability fix")
	_assert(String(snapshot.get("avoid_next_action", "")) == "do_not_mask_no_los_with_contact_fire_text_without_runtime_evidence", "Snapshot rejects cosmetic CONTACT-FIRE masking")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_optional_actual_recapture_manifest() -> void:
	if not FileAccess.file_exists(CAPTURE_PATH):
		_assert(true, "TASK_869 recapture manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(CAPTURE_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(manifest, _manual_review_notes())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual recapture builds TASK_872 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_869", "Actual recapture links TASK_869")
	_assert(String(snapshot.get("source_capture_fix_task_id", "")) == "TASK_871", "Actual recapture links TASK_871")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual recapture keeps TASK_873 recommendation")
	_assert(bool(snapshot.get("read_only", false)), "Actual recapture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual recapture snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual recapture snapshot updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(CAPTURE_PATH) if FileAccess.file_exists(CAPTURE_PATH) else _good_recapture_manifest()
	var snapshot: Dictionary = Findings.build_snapshot(source_manifest, _manual_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_872 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_872", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "correct_window_first_exchange_still_no_los", "Roundtrip keeps primary issue")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_recapture_manifest() -> Dictionary:
	return {
		"schema": RECAPTURE_SCHEMA,
		"task_id": "TASK_869",
		"source_task_id": "TASK_868",
		"source_status_recapture_task_id": "TASK_866",
		"source_exchange_task_id": "TASK_844",
		"gate": "review_ready",
		"visible_window_gate": "review_ready",
		"launch_argument": FIRST_GO_ARG,
		"expected_los_setup_style_id": LOS_STYLE_ID,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_handle_capture_succeeded": true,
		"window_crop_trusted": true,
		"window_focus_succeeded": true,
		"foreground_matches_selected_process": true,
		"foreground_process_id": 42040,
		"selected_process_id": 42040,
		"window_screenshot_path": "tmp/release_first_exchange_los_setup_real_window_recapture.png",
		"desktop_screenshot_path": "tmp/release_first_exchange_los_setup_real_window_recapture_desktop.png",
	}


func _manual_review_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"observed_window_state": "STERNENBUERGERCHEN_MISSION_WINDOW",
		"correct_window_content_confirmed": true,
		"selected_fireteam_primary_reading": "#17 NEXT LOS/RANGE KORRIGIEREN | WHY KEIN ZIEL",
		"mission_control_primary_reading": "#18 Kampf NO FIRE NO_LOS",
		"event_log_primary_reading": "#19 CONTACT PRESSURE: Position korrigieren",
		"contact_fire_readability_ok": false,
		"fire_trace_or_impact_visible": false,
		"correct_window_first_exchange_still_no_los": true,
		"event_log_contact_pressure_still_dominates": true,
		"contact_fire_not_yet_player_readable": true,
		"fire_trace_or_impact_not_visible": true,
	}


func _issue_ids(issues: Array) -> Array:
	var ids: Array = []
	for issue_variant in issues:
		ids.append(String(Dictionary(issue_variant).get("id", "")))
	return ids


func _read_json_dict(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
