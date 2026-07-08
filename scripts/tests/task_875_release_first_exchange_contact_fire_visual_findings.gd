extends SceneTree

const Findings := preload("res://scripts/mission/release_first_exchange_contact_fire_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_875_release_first_exchange_contact_fire_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task874_recapture_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_contact_fire_visual_findings.gd"
const CAPTURE_PATH := "res://tmp/release_first_exchange_contact_fire_real_window_recapture.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_contact_fire_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_contact_fire_visual_findings.v1"
const CAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_contact_fire_real_window_recapture.v1"
const CONTACT_FIRE_SCHEMA := "sternenbuergerchen.release_first_exchange_contact_fire_readability_fix.v1"
const CONTACT_FIRE_STYLE_ID := "task_873_release_first_exchange_contact_fire_readability_fix_v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_876 - Release First Exchange Visible Status Source Reconciliation"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_875 Release First Exchange CONTACT-FIRE Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_capture_blocks()
	_test_ready_capture_builds_findings()
	_test_optional_actual_capture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_875_release_first_exchange_contact_fire_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_875_release_first_exchange_contact_fire_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_875 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_875 read-only findings analyzer exists")
	_assert(task_text.contains("Release First Exchange CONTACT-FIRE Visual Findings"), "Task names TASK_875")
	_assert(task_text.contains("TASK_876"), "Task names TASK_876 follow-up")
	_assert(status_text.contains("TASK_875 - Release First Exchange CONTACT-FIRE Visual Findings"), "Implementation status tracks TASK_875")
	_assert(roadmap_text.contains("TASK_875 - Release First Exchange CONTACT-FIRE Visual Findings (implementiert)"), "Roadmap marks TASK_875 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_876 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-CONTACT-FIRE-Visual-Findings (TASK_875)"), "Contract documents TASK_875")
	_assert(report_text.contains("TASK_874"), "HTML report tracks TASK_874 source")
	_assert(report_text.contains("NO_LOS") or report_text.contains("NO FIRE"), "HTML report names remaining first-exchange issue")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes TASK_875 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_875\""), "Analyzer writes TASK_875 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_874\""), "Analyzer links TASK_874")
	_assert(service_text.contains("SOURCE_READABILITY_TASK_ID: String = \"TASK_873\""), "Analyzer links TASK_873")
	_assert(service_text.contains("\"task_873_evidence_not_real_window_first_reading\""), "Analyzer names TASK_873 real-window mismatch")
	_assert(service_text.contains("\"selected_fireteam_still_no_los_first\""), "Analyzer names #17 NO_LOS issue")
	_assert(service_text.contains("\"event_log_contact_pressure_still_dominates\""), "Analyzer names CONTACT PRESSURE issue")
	_assert(service_text.contains("do_not_add_cosmetic_contact_fire_text_without_status_source_reconciliation"), "Analyzer rejects cosmetic masking")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")


func _test_missing_capture_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing capture manifest blocks TASK_875")
	_assert(blocker_ids.has("capture_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("capture_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("source_readability_mismatch"), "Missing manifest reports TASK_873 mismatch")
	_assert(blocker_ids.has("source_recapture_mismatch"), "Missing manifest reports TASK_869 mismatch")
	_assert(blocker_ids.has("source_los_setup_mismatch"), "Missing manifest reports TASK_868 mismatch")
	_assert(blocker_ids.has("source_exchange_mismatch"), "Missing manifest reports TASK_844 mismatch")
	_assert(blocker_ids.has("source_capture_fix_mismatch"), "Missing manifest reports TASK_871 mismatch")
	_assert(blocker_ids.has("capture_not_review_ready"), "Missing manifest reports capture gate")
	_assert(blocker_ids.has("launch_argument_mismatch"), "Missing manifest reports launch argument")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports screenshot missing")
	_assert(blocker_ids.has("contact_fire_readability_schema_mismatch"), "Missing manifest reports TASK_873 schema")
	_assert(blocker_ids.has("contact_fire_readability_style_id_mismatch"), "Missing manifest reports TASK_873 style")
	_assert(blocker_ids.has("window_capture_method_not_handle_print"), "Missing manifest reports capture method")
	_assert(blocker_ids.has("window_capture_not_trusted"), "Missing manifest reports untrusted capture")
	_assert(blocker_ids.has("window_handle_capture_failed"), "Missing manifest reports handle failure")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_ready_capture_builds_findings() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_capture_manifest(), _manual_review_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_875")
	_assert(String(snapshot.get("task_id", "")) == "TASK_875", "Snapshot task id matches TASK_875")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_874", "Snapshot links TASK_874")
	_assert(String(snapshot.get("source_readability_task_id", "")) == "TASK_873", "Snapshot links TASK_873")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_869", "Snapshot links TASK_869")
	_assert(String(snapshot.get("source_los_setup_task_id", "")) == "TASK_868", "Snapshot links TASK_868")
	_assert(String(snapshot.get("source_exchange_task_id", "")) == "TASK_844", "Snapshot links TASK_844")
	_assert(String(snapshot.get("source_capture_fix_task_id", "")) == "TASK_871", "Snapshot links TASK_871")
	_assert(bool(snapshot.get("capture_schema_ok", false)), "Snapshot accepts TASK_874 schema")
	_assert(String(snapshot.get("capture_gate", "")) == "review_ready", "Snapshot records review_ready capture")
	_assert(String(snapshot.get("window_capture_method", "")) == "window_handle_print", "Snapshot records handle capture method")
	_assert(bool(snapshot.get("window_capture_trusted", false)), "Snapshot records trusted capture")
	_assert(bool(snapshot.get("window_handle_capture_succeeded", false)), "Snapshot records handle capture success")
	_assert(bool(snapshot.get("correct_window_content_confirmed", false)), "Snapshot confirms Sternenbuergerchen window")
	_assert(bool(snapshot.get("command_surfaces_still_usable", false)), "Snapshot confirms command surfaces")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good capture has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_visible_status_source_reconciliation", "Manual notes produce reconciliation status")
	_assert(String(snapshot.get("observed_window_state", "")) == "STERNENBUERGERCHEN_FIRST_EXCHANGE_WINDOW", "Snapshot records observed window state")
	_assert(String(snapshot.get("selected_fireteam_primary_reading", "")).contains("LOS/RANGE"), "Snapshot records selected-fireteam LOS/RANGE reading")
	_assert(String(snapshot.get("mission_control_primary_reading", "")).contains("NO FIRE NO_LOS"), "Snapshot records Mission Control NO_LOS reading")
	_assert(String(snapshot.get("event_log_primary_reading", "")).contains("CONTACT PRESSURE"), "Snapshot records CONTACT PRESSURE reading")
	_assert(issue_ids.has("task_873_evidence_not_real_window_first_reading"), "Snapshot records TASK_873 mismatch issue")
	_assert(issue_ids.has("selected_fireteam_still_no_los_first"), "Snapshot records #17 issue")
	_assert(issue_ids.has("mission_control_still_no_los_first"), "Snapshot records #18 issue")
	_assert(issue_ids.has("event_log_contact_pressure_still_dominates"), "Snapshot records #19 issue")
	_assert(issue_ids.has("fire_trace_or_impact_not_clear"), "Snapshot records FireTrace/Impact issue")
	_assert(String(snapshot.get("primary_issue_id", "")) == "task_873_evidence_not_real_window_first_reading", "TASK_873 mismatch is primary issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_876")
	_assert(String(snapshot.get("recommended_direction", "")) == "reconcile_task_873_evidence_with_real_window_selected_fireteam_mission_control_event_log_sources", "Snapshot recommends source reconciliation")
	_assert(String(snapshot.get("avoid_next_action", "")) == "do_not_add_cosmetic_contact_fire_text_without_status_source_reconciliation", "Snapshot rejects cosmetic CONTACT FIRE masking")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_optional_actual_capture_manifest() -> void:
	if not FileAccess.file_exists(CAPTURE_PATH):
		_assert(true, "TASK_874 capture manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(CAPTURE_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(manifest, _manual_review_notes())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual capture builds TASK_875 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_874", "Actual capture links TASK_874")
	_assert(String(snapshot.get("source_readability_task_id", "")) == "TASK_873", "Actual capture links TASK_873")
	_assert(String(snapshot.get("expected_contact_fire_readability_style_id", "")) == CONTACT_FIRE_STYLE_ID, "Actual capture records TASK_873 style")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual capture keeps TASK_876 recommendation")
	_assert(bool(snapshot.get("read_only", false)), "Actual capture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual capture snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual capture snapshot updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(CAPTURE_PATH) if FileAccess.file_exists(CAPTURE_PATH) else _good_capture_manifest()
	var snapshot: Dictionary = Findings.build_snapshot(source_manifest, _manual_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_875 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_875", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_874", "Roundtrip manifest keeps TASK_874 link")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "task_873_evidence_not_real_window_first_reading", "Roundtrip keeps primary issue")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_capture_manifest() -> Dictionary:
	return {
		"schema": CAPTURE_SCHEMA,
		"task_id": "TASK_874",
		"source_task_id": "TASK_873",
		"source_recapture_task_id": "TASK_869",
		"source_los_setup_task_id": "TASK_868",
		"source_exchange_task_id": "TASK_844",
		"source_capture_fix_task_id": "TASK_871",
		"gate": "review_ready",
		"branch": "task/release-first-exchange-contact-fire-real-window-recapture",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"expected_contact_fire_readability_schema": CONTACT_FIRE_SCHEMA,
		"expected_contact_fire_readability_style_id": CONTACT_FIRE_STYLE_ID,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_handle_capture_succeeded": true,
		"foreground_matches_selected_process": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_exchange_contact_fire_real_window_recapture.png",
		"desktop_screenshot_path": "tmp/release_first_exchange_contact_fire_real_window_recapture_desktop.png",
		"hard_failures": [],
		"warnings": [],
	}


func _manual_review_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"observed_window_state": "STERNENBUERGERCHEN_FIRST_EXCHANGE_WINDOW",
		"correct_window_content_confirmed": true,
		"selected_fireteam_primary_reading": "#17 NEXT LOS/RANGE KORRIGIEREN | WHY KEIN ZIEL | Kampf NO FIRE NO_LOS",
		"mission_control_primary_reading": "#18 NEXT LOS/RANGE KORRIGIEREN | Kampf NO FIRE NO_LOS",
		"event_log_primary_reading": "#19 FT1 CONTACT PRESSURE: Position korrigieren",
		"contact_fire_readability_ok": false,
		"fire_trace_or_impact_visible": false,
		"command_surfaces_still_usable": true,
		"task_873_evidence_not_real_window_first_reading": true,
		"selected_fireteam_still_no_los_first": true,
		"mission_control_still_no_los_first": true,
		"event_log_contact_pressure_still_dominates": true,
		"fire_trace_or_impact_not_clear": true,
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
