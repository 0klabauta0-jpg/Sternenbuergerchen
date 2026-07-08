extends SceneTree

const Findings := preload("res://scripts/mission/release_fire_exchange_real_window_contact_fire_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_861_release_fire_exchange_real_window_contact_fire_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html"
const SUMMARY_REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_fire_exchange_real_window_contact_fire_visual_findings.gd"
const RECAPTURE_PATH := "res://tmp/release_fire_exchange_real_window_contact_fire_recapture_acceptance.json"
const CAPTURE_PATH := "res://tmp/release_fire_exchange_real_window_contact_fire_recapture.json"
const OUTPUT_PATH := "res://tmp/release_fire_exchange_real_window_contact_fire_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_fire_exchange_real_window_contact_fire_visual_findings.v1"
const RECAPTURE_SCHEMA := "sternenbuergerchen.release_fire_exchange_real_window_contact_fire_recapture.v1"
const SOURCE_BINDING_STYLE_ID := "task_859_release_fire_exchange_real_window_primary_hud_source_binding_v1"
const NEXT_TASK := "TASK_862 - Release Fire Exchange Real Window Primary HUD Runtime Text Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_861 Release Fire Exchange Real Window Contact-Fire Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_recapture_blocks()
	_test_ready_recapture_builds_findings()
	_test_optional_actual_recapture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_861_release_fire_exchange_real_window_contact_fire_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_861_release_fire_exchange_real_window_contact_fire_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var summary_report_text: String = _read_text(SUMMARY_REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_861 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_861 read-only findings analyzer exists")
	_assert(task_text.contains("Release Fire Exchange Real Window Contact-Fire Visual Findings"), "Task names real-window contact-fire findings")
	_assert(status_text.contains("TASK_861 - Release Fire Exchange Real Window Contact-Fire Visual Findings"), "Implementation status tracks TASK_861")
	_assert(roadmap_text.contains("TASK_861 - Release Fire Exchange Real Window Contact-Fire Visual Findings (implementiert)"), "Roadmap marks TASK_861 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_862 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Real-Window-Contact-Fire-Visual-Findings"), "Contract documents TASK_861")
	_assert(report_text.contains("TASK_861") and report_text.contains("NO FIRE NO_LOS"), "Fire-exchange report tracks TASK_861 finding")
	_assert(summary_report_text.contains("TASK_861") and summary_report_text.contains("NO FIRE"), "Spielstand report tracks TASK_861 finding")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_861 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_861\""), "Analyzer writes TASK_861 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_860\""), "Analyzer links TASK_860 source")
	_assert(service_text.contains("SOURCE_BINDING_TASK_ID: String = \"TASK_859\""), "Analyzer links TASK_859 source")
	_assert(service_text.contains("\"real_window_still_no_fire_no_los_first_reading\""), "Analyzer names real-window still-NO-FIRE issue")
	_assert(service_text.contains("\"contact_fire_not_first_in_selected_fireteam\""), "Analyzer names #17 issue")
	_assert(service_text.contains("\"contact_fire_not_first_in_mission_control\""), "Analyzer names #18 issue")
	_assert(service_text.contains("\"event_log_still_contact_pressure\""), "Analyzer names event-log contact-pressure issue")
	_assert(service_text.contains("\"source_binding_window_gap\""), "Analyzer names source-binding/window gap")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")


func _test_missing_recapture_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing recapture manifest blocks TASK_861")
	_assert(blocker_ids.has("recapture_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("recapture_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("capture_not_review_ready"), "Missing manifest reports capture gate issue")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports screenshot missing")
	_assert(blocker_ids.has("source_binding_style_id_mismatch"), "Missing manifest reports source binding style mismatch")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot is still read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_ready_recapture_builds_findings() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_recapture_manifest(), _manual_review_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_861")
	_assert(String(snapshot.get("task_id", "")) == "TASK_861", "Snapshot task id matches TASK_861")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_860", "Snapshot links TASK_860")
	_assert(String(snapshot.get("source_binding_task_id", "")) == "TASK_859", "Snapshot links TASK_859")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_857", "Snapshot links TASK_857")
	_assert(String(snapshot.get("source_primary_hud_task_id", "")) == "TASK_856", "Snapshot links TASK_856")
	_assert(String(snapshot.get("source_readability_task_id", "")) == "TASK_853", "Snapshot links TASK_853")
	_assert(String(snapshot.get("source_focus_task_id", "")) == "TASK_850", "Snapshot links TASK_850")
	_assert(String(snapshot.get("source_visibility_task_id", "")) == "TASK_847", "Snapshot links TASK_847")
	_assert(String(snapshot.get("source_exchange_task_id", "")) == "TASK_844", "Snapshot links TASK_844")
	_assert(bool(snapshot.get("recapture_schema_ok", false)), "Snapshot accepts TASK_860 schema")
	_assert(String(snapshot.get("capture_gate", "")) == "review_ready", "Snapshot accepts review_ready capture")
	_assert(bool(snapshot.get("source_binding_style_id_ok", false)), "Snapshot accepts TASK_859 style")
	_assert(bool(snapshot.get("window_screenshot_written", false)), "Snapshot records window screenshot")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good recapture has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_polish", "Manual notes produce ready_for_polish")
	_assert(String(snapshot.get("observed_window_state", "")) == "NO_FIRE_NO_LOS_CONTACT_PRESSURE_LOS_RANGE", "Snapshot records observed state")
	_assert(int(snapshot.get("positive_finding_count", 0)) >= 3, "Snapshot records positive findings")
	_assert(issue_ids.has("real_window_still_no_fire_no_los_first_reading"), "Snapshot records still-NO-FIRE first-reading issue")
	_assert(issue_ids.has("contact_fire_not_first_in_selected_fireteam"), "Snapshot records #17 issue")
	_assert(issue_ids.has("contact_fire_not_first_in_mission_control"), "Snapshot records #18 issue")
	_assert(issue_ids.has("event_log_still_contact_pressure"), "Snapshot records event-log issue")
	_assert(issue_ids.has("source_binding_window_gap"), "Snapshot records source-binding/window gap")
	_assert(String(snapshot.get("primary_issue_id", "")) == "real_window_still_no_fire_no_los_first_reading", "Still-NO-FIRE is primary issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_862")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Snapshot creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_optional_actual_recapture_manifest() -> void:
	if not FileAccess.file_exists(RECAPTURE_PATH) and not FileAccess.file_exists(CAPTURE_PATH):
		_assert(true, "TASK_860 recapture manifest is optional before local capture")
		return
	var manifest_path: String = RECAPTURE_PATH if FileAccess.file_exists(RECAPTURE_PATH) else CAPTURE_PATH
	var manifest: Dictionary = _read_json_dict(manifest_path)
	var snapshot: Dictionary = Findings.build_snapshot(manifest, _manual_review_notes())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual recapture builds TASK_861 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_860", "Actual recapture links TASK_860")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual recapture keeps TASK_862 recommendation")
	_assert(bool(snapshot.get("read_only", false)), "Actual recapture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual recapture snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual recapture snapshot updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(RECAPTURE_PATH) if FileAccess.file_exists(RECAPTURE_PATH) else _good_recapture_manifest()
	var snapshot: Dictionary = Findings.build_snapshot(source_manifest, _manual_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_861 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_861", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "real_window_still_no_fire_no_los_first_reading", "Roundtrip manifest keeps primary issue")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip manifest keeps read-only boundary")


func _good_recapture_manifest() -> Dictionary:
	return {
		"schema": RECAPTURE_SCHEMA,
		"task_id": "TASK_860",
		"status": "ready_for_manual_acceptance",
		"capture_gate": "review_ready",
		"expected_source_binding_style_id": SOURCE_BINDING_STYLE_ID,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_fire_exchange_real_window_contact_fire_recapture.png",
		"desktop_screenshot_path": "tmp/release_fire_exchange_real_window_contact_fire_recapture_desktop.png",
	}


func _manual_review_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"observed_window_state": "NO_FIRE_NO_LOS_CONTACT_PRESSURE_LOS_RANGE",
		"mission_surface_readable": true,
		"command_matrix_usable": true,
		"real_window_still_no_fire_no_los_first_reading": true,
		"contact_fire_not_first_in_selected_fireteam": true,
		"contact_fire_not_first_in_mission_control": true,
		"event_log_still_contact_pressure": true,
		"source_binding_window_gap": true,
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
