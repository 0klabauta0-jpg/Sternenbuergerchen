extends SceneTree

const Findings := preload("res://scripts/mission/release_fire_exchange_focused_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_852_release_fire_exchange_focused_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_fire_exchange_focused_visual_findings.gd"
const RECAPTURE_PATH := "res://tmp/release_fire_exchange_focused_visual_recapture_acceptance.json"
const OUTPUT_PATH := "res://tmp/release_fire_exchange_focused_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_fire_exchange_focused_visual_findings.v1"
const RECAPTURE_SCHEMA := "sternenbuergerchen.release_fire_exchange_focused_visual_recapture.v1"
const FOCUS_STYLE_ID := "task_850_release_fire_exchange_focused_visual_polish_v1"
const NEXT_TASK := "TASK_853 - Release Fire Exchange Engagement Readability Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_852 Release Fire Exchange Focused Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_recapture_blocks()
	_test_ready_recapture_builds_findings()
	_test_optional_actual_recapture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_852_release_fire_exchange_focused_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_852_release_fire_exchange_focused_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_852 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_852 read-only findings analyzer exists")
	_assert(task_text.contains("Release Fire Exchange Focused Visual Findings"), "Task names focused visual findings")
	_assert(status_text.contains("TASK_852 - Release Fire Exchange Focused Visual Findings"), "Implementation status tracks TASK_852")
	_assert(roadmap_text.contains("TASK_852 - Release Fire Exchange Focused Visual Findings (implementiert)"), "Roadmap marks TASK_852 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_853 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Focused-Visual-Findings"), "Contract documents TASK_852")
	_assert(report_text.contains("CONTACT PRESSURE") and report_text.contains("NO FIRE"), "Report keeps TASK_851 visible friction")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_852 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_852\""), "Analyzer writes TASK_852 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_851\""), "Analyzer links TASK_851 source")
	_assert(service_text.contains("SOURCE_FOCUS_TASK_ID: String = \"TASK_850\""), "Analyzer links TASK_850 source")
	_assert(service_text.contains("SOURCE_VISIBILITY_TASK_ID: String = \"TASK_847\""), "Analyzer links TASK_847 source")
	_assert(service_text.contains("\"contact_pressure_instead_of_contact_fire\""), "Analyzer names pressure-vs-fire issue")
	_assert(service_text.contains("\"debug_no_fire_reason_visible\""), "Analyzer names debug NO FIRE issue")
	_assert(service_text.contains("\"fire_trace_or_impact_still_not_readable\""), "Analyzer names trace/impact issue")
	_assert(service_text.contains("\"hud_exchange_confirmation_missing\""), "Analyzer names HUD confirmation issue")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "Analyzer declares no shortcut updates")


func _test_missing_recapture_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing recapture manifest blocks TASK_852")
	_assert(blocker_ids.has("recapture_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("recapture_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("capture_not_review_ready"), "Missing manifest reports capture gate issue")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports screenshot missing")
	_assert(blocker_ids.has("focus_style_id_mismatch"), "Missing manifest reports focus style mismatch")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot is still read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_ready_recapture_builds_findings() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_recapture_manifest(), _manual_review_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_852")
	_assert(String(snapshot.get("task_id", "")) == "TASK_852", "Snapshot task id matches TASK_852")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_851", "Snapshot links TASK_851")
	_assert(String(snapshot.get("source_focus_task_id", "")) == "TASK_850", "Snapshot links TASK_850")
	_assert(String(snapshot.get("source_visibility_task_id", "")) == "TASK_847", "Snapshot links TASK_847")
	_assert(String(snapshot.get("source_exchange_task_id", "")) == "TASK_844", "Snapshot links TASK_844")
	_assert(bool(snapshot.get("recapture_schema_ok", false)), "Snapshot accepts TASK_851 schema")
	_assert(String(snapshot.get("recapture_status", "")) == "ready_for_manual_review", "Snapshot accepts TASK_851 status")
	_assert(String(snapshot.get("capture_gate", "")) == "review_ready", "Snapshot accepts review_ready capture")
	_assert(bool(snapshot.get("focus_style_id_ok", false)), "Snapshot accepts TASK_850 style")
	_assert(bool(snapshot.get("window_screenshot_written", false)), "Snapshot records window screenshot")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good recapture has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_polish", "Manual notes produce ready_for_polish")
	_assert(String(snapshot.get("observed_window_state", "")) == "CONTACT_PRESSURE_NO_FIRE_DEBUG", "Snapshot records observed state")
	_assert(int(snapshot.get("positive_finding_count", 0)) >= 3, "Snapshot records positive findings")
	_assert(issue_ids.has("contact_pressure_instead_of_contact_fire"), "Snapshot records pressure-vs-fire issue")
	_assert(issue_ids.has("debug_no_fire_reason_visible"), "Snapshot records debug NO FIRE issue")
	_assert(issue_ids.has("fire_trace_or_impact_still_not_readable"), "Snapshot records trace/impact issue")
	_assert(issue_ids.has("hud_exchange_confirmation_missing"), "Snapshot records HUD confirmation issue")
	_assert(String(snapshot.get("primary_issue_id", "")) == "contact_pressure_instead_of_contact_fire", "Pressure-vs-fire is primary issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_853")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Snapshot creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_optional_actual_recapture_manifest() -> void:
	if not FileAccess.file_exists(RECAPTURE_PATH):
		_assert(true, "TASK_851 recapture acceptance manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(RECAPTURE_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(manifest, _manual_review_notes())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual recapture builds TASK_852 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_851", "Actual recapture links TASK_851")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual recapture keeps TASK_853 recommendation")
	_assert(bool(snapshot.get("read_only", false)), "Actual recapture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual recapture snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual recapture snapshot updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(RECAPTURE_PATH) if FileAccess.file_exists(RECAPTURE_PATH) else _good_recapture_manifest()
	var snapshot: Dictionary = Findings.build_snapshot(source_manifest, _manual_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_852 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_852", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "contact_pressure_instead_of_contact_fire", "Roundtrip manifest keeps primary issue")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip manifest keeps read-only boundary")


func _good_recapture_manifest() -> Dictionary:
	return {
		"schema": RECAPTURE_SCHEMA,
		"task_id": "TASK_851",
		"status": "ready_for_manual_review",
		"capture_gate": "review_ready",
		"expected_focus_style_id": FOCUS_STYLE_ID,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_fire_exchange_focused_visual_recapture.png",
		"desktop_screenshot_path": "tmp/release_fire_exchange_focused_visual_recapture_desktop.png",
	}


func _manual_review_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"observed_window_state": "CONTACT_PRESSURE_NO_FIRE_DEBUG",
		"mission_surface_readable": true,
		"command_matrix_usable": true,
		"contact_pressure_instead_of_contact_fire": true,
		"debug_no_fire_reason_visible": true,
		"fire_trace_or_impact_still_not_readable": true,
		"hud_exchange_confirmation_missing": true,
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
