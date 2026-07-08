extends SceneTree

const Findings := preload("res://scripts/mission/release_fire_exchange_runtime_text_status_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_867_release_fire_exchange_runtime_text_status_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const SUMMARY_REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_fire_exchange_runtime_text_status_visual_findings.gd"
const CAPTURE_PATH := "res://tmp/release_fire_exchange_runtime_text_status_recapture.json"
const OUTPUT_PATH := "res://tmp/release_fire_exchange_runtime_text_status_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_fire_exchange_runtime_text_status_visual_findings.v1"
const RECAPTURE_SCHEMA := "sternenbuergerchen.release_fire_exchange_runtime_text_status_recapture.v1"
const RUNTIME_TEXT_STYLE_ID := "task_862_release_fire_exchange_real_window_primary_hud_runtime_text_v1"
const NEXT_TASK := "TASK_868 - Release First Exchange LOS Setup Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_867 Release Fire Exchange Runtime Text Status Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_recapture_blocks()
	_test_ready_recapture_builds_findings()
	_test_optional_actual_recapture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_867_release_fire_exchange_runtime_text_status_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_867_release_fire_exchange_runtime_text_status_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var summary_report_text: String = _read_text(SUMMARY_REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_867 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_867 read-only findings analyzer exists")
	_assert(task_text.contains("Release Fire Exchange Runtime Text Status Visual Findings"), "Task names status visual findings")
	_assert(status_text.contains("TASK_867 - Release Fire Exchange Runtime Text Status Visual Findings"), "Implementation status tracks TASK_867")
	_assert(roadmap_text.contains("TASK_867 - Release Fire Exchange Runtime Text Status Visual Findings (implementiert)"), "Roadmap marks TASK_867 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_868 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Runtime-Text-Status-Visual-Findings"), "Contract documents TASK_867")
	_assert(summary_report_text.contains("TASK_867") and summary_report_text.contains("TASK_868"), "Spielstand report tracks TASK_867 and next step")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_867 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_867\""), "Analyzer writes TASK_867 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_866\""), "Analyzer links TASK_866 source")
	_assert(service_text.contains("SOURCE_STATUS_POLISH_TASK_ID: String = \"TASK_865\""), "Analyzer links TASK_865 source")
	_assert(service_text.contains("SOURCE_RUNTIME_TEXT_TASK_ID: String = \"TASK_862\""), "Analyzer links TASK_862 source")
	_assert(service_text.contains("\"first_exchange_los_evidence_not_visible\""), "Analyzer names first-exchange LOS evidence issue")
	_assert(service_text.contains("\"contact_fire_text_would_be_misleading_without_los\""), "Analyzer names misleading CONTACT FIRE risk")
	_assert(service_text.contains("do_not_force_contact_fire_text_without_fire_or_los_evidence"), "Analyzer avoids blind HUD override")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")


func _test_missing_recapture_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing recapture manifest blocks TASK_867")
	_assert(blocker_ids.has("recapture_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("recapture_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("capture_not_review_ready"), "Missing manifest reports capture gate issue")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports screenshot missing")
	_assert(blocker_ids.has("runtime_text_style_id_mismatch"), "Missing manifest reports runtime style mismatch")
	_assert(blocker_ids.has("source_status_polish_mismatch"), "Missing manifest reports TASK_865 source mismatch")
	_assert(blocker_ids.has("source_runtime_text_mismatch"), "Missing manifest reports TASK_862 source mismatch")
	_assert(blocker_ids.has("source_recapture_mismatch"), "Missing manifest reports TASK_863 recapture mismatch")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot is still read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_ready_recapture_builds_findings() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_recapture_manifest(), _manual_review_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_867")
	_assert(String(snapshot.get("task_id", "")) == "TASK_867", "Snapshot task id matches TASK_867")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_866", "Snapshot links TASK_866")
	_assert(String(snapshot.get("source_status_polish_task_id", "")) == "TASK_865", "Snapshot links TASK_865")
	_assert(String(snapshot.get("source_runtime_text_task_id", "")) == "TASK_862", "Snapshot links TASK_862")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_863", "Snapshot links TASK_863")
	_assert(bool(snapshot.get("recapture_schema_ok", false)), "Snapshot accepts TASK_866 schema")
	_assert(String(snapshot.get("capture_gate", "")) == "review_ready", "Snapshot accepts review_ready capture")
	_assert(bool(snapshot.get("runtime_text_style_id_ok", false)), "Snapshot accepts TASK_862 style")
	_assert(bool(snapshot.get("window_screenshot_written", false)), "Snapshot records window screenshot")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good recapture has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_los_setup_polish", "Manual notes produce LOS setup polish status")
	_assert(String(snapshot.get("observed_window_state", "")) == "NO_LOS_CONTACT_PRESSURE", "Snapshot records observed state")
	_assert(int(snapshot.get("positive_finding_count", 0)) >= 4, "Snapshot records positive findings")
	_assert(issue_ids.has("first_exchange_los_evidence_not_visible"), "Snapshot records LOS evidence issue")
	_assert(issue_ids.has("selected_fireteam_still_no_los_first"), "Snapshot records #17 NO_LOS issue")
	_assert(issue_ids.has("mission_control_still_no_los_first"), "Snapshot records #18 NO_LOS issue")
	_assert(issue_ids.has("event_log_contact_pressure_position_correct"), "Snapshot records CONTACT PRESSURE issue")
	_assert(issue_ids.has("contact_fire_text_would_be_misleading_without_los"), "Snapshot records misleading CONTACT FIRE risk")
	_assert(String(snapshot.get("primary_issue_id", "")) == "first_exchange_los_evidence_not_visible", "LOS evidence is primary issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_868")
	_assert(String(snapshot.get("recommended_direction", "")) == "fix_first_exchange_los_or_reframe_contact_pressure", "Snapshot recommends honest next direction")
	_assert(String(snapshot.get("avoid_next_action", "")) == "do_not_force_contact_fire_text_without_fire_or_los_evidence", "Snapshot rejects blind HUD override")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Snapshot creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_optional_actual_recapture_manifest() -> void:
	if not FileAccess.file_exists(CAPTURE_PATH):
		_assert(true, "TASK_866 recapture manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(CAPTURE_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(manifest, _manual_review_notes())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual recapture builds TASK_867 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_866", "Actual recapture links TASK_866")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual recapture keeps TASK_868 recommendation")
	_assert(bool(snapshot.get("read_only", false)), "Actual recapture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual recapture snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual recapture snapshot updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(CAPTURE_PATH) if FileAccess.file_exists(CAPTURE_PATH) else _good_recapture_manifest()
	var snapshot: Dictionary = Findings.build_snapshot(source_manifest, _manual_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_867 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_867", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "first_exchange_los_evidence_not_visible", "Roundtrip manifest keeps primary issue")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip manifest keeps read-only boundary")


func _good_recapture_manifest() -> Dictionary:
	return {
		"schema": RECAPTURE_SCHEMA,
		"task_id": "TASK_866",
		"source_task_id": "TASK_865",
		"source_runtime_text_task_id": "TASK_862",
		"source_recapture_task_id": "TASK_863",
		"gate": "review_ready",
		"expected_runtime_text_style_id": RUNTIME_TEXT_STYLE_ID,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_fire_exchange_runtime_text_status_recapture.png",
		"desktop_screenshot_path": "tmp/release_fire_exchange_runtime_text_status_recapture_desktop.png",
	}


func _manual_review_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"observed_window_state": "NO_LOS_CONTACT_PRESSURE",
		"mission_surface_readable": true,
		"first_exchange_los_evidence_not_visible": true,
		"selected_fireteam_still_no_los_first": true,
		"mission_control_still_no_los_first": true,
		"event_log_contact_pressure_position_correct": true,
		"contact_fire_text_would_be_misleading_without_los": true,
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
