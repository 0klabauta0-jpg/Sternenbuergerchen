extends SceneTree

const Findings := preload("res://scripts/mission/release_first_exchange_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_846_release_first_exchange_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_visual_findings.gd"
const REPORT_PATH := "res://docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html"
const ACTUAL_RECAPTURE_PATH := "res://tmp/release_first_exchange_real_window_recapture.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_visual_findings.v1"
const EXCHANGE_SCHEMA := "sternenbuergerchen.release_first_exchange_tension_tuning.v1"
const STYLE_ID := "task_844_release_first_exchange_tension_tuning_v1"
const NEXT_TASK := "TASK_847 - Release Fire Exchange Visibility Persistence"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_846 Release First Exchange Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_review_ready_manifest_builds_findings()
	_test_optional_actual_recapture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_846_release_first_exchange_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_846_release_first_exchange_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_846 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_846 read-only analyzer exists")
	_assert(FileAccess.file_exists(REPORT_PATH), "TASK_845 interim report remains available")
	_assert(task_text.contains("Release First Exchange Visual Findings"), "Task names first-exchange visual findings")
	_assert(status_text.contains("TASK_846 - Release First Exchange Visual Findings"), "Implementation status tracks TASK_846")
	_assert(roadmap_text.contains("TASK_846 - Release First Exchange Visual Findings (implementiert)"), "Roadmap marks TASK_846 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_847 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Visual-Findings"), "Contract documents TASK_846")
	_assert(report_text.contains("CONTACT PRESSURE") and report_text.contains("NO FIRE NO_LOS"), "Report carries the current real-window friction")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_846 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_846\""), "Analyzer writes TASK_846 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_845\""), "Analyzer links TASK_845 source")
	_assert(service_text.contains("SOURCE_EXCHANGE_TASK_ID: String = \"TASK_844\""), "Analyzer links TASK_844 exchange source")
	_assert(service_text.contains(NEXT_TASK), "Analyzer recommends TASK_847")
	_assert(service_text.contains("\"first_exchange_not_visible_in_window\""), "Analyzer names primary issue")
	_assert(service_text.contains("\"hud_surfaces_stale_pressure\""), "Analyzer names stale HUD pressure issue")
	_assert(service_text.contains("\"fire_trace_or_impact_not_obvious\""), "Analyzer names fire trace/impact issue")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"ui_sets_gameplay_truth\": false"), "Analyzer declares no gameplay truth mutation")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing recapture manifest blocks findings")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 5, "Missing manifest creates blocker set")
	_assert(blocker_ids.has("recapture_not_review_ready"), "Missing manifest reports recapture_not_review_ready")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports window_screenshot_missing")
	_assert(blocker_ids.has("exchange_schema_mismatch"), "Missing manifest reports exchange_schema_mismatch")
	_assert(blocker_ids.has("exchange_style_id_mismatch"), "Missing manifest reports exchange_style_id_mismatch")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot is still read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot still creates no commands")


func _test_review_ready_manifest_builds_findings() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_recapture_manifest(), _manual_review_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_846")
	_assert(String(snapshot.get("task_id", "")) == "TASK_846", "Snapshot task id matches TASK_846")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_845", "Snapshot links TASK_845")
	_assert(String(snapshot.get("source_exchange_task_id", "")) == "TASK_844", "Snapshot links TASK_844")
	_assert(String(snapshot.get("recapture_gate", "")) == "review_ready", "Snapshot accepts TASK_845 review_ready gate")
	_assert(bool(snapshot.get("exchange_schema_ok", false)), "Snapshot accepts expected exchange schema")
	_assert(bool(snapshot.get("exchange_style_id_ok", false)), "Snapshot accepts expected style id")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Review-ready manifest has no technical blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_polish", "Manual notes produce ready_for_polish")
	_assert(String(snapshot.get("observed_window_state", "")) == "CONTACT_PRESSURE_NO_FIRE", "Snapshot records observed window state")
	_assert(bool(snapshot.get("manual_notes_present", false)), "Snapshot records manual notes present")
	_assert(int(snapshot.get("positive_finding_count", 0)) >= 3, "Snapshot records positive findings")
	_assert(issue_ids.has("first_exchange_not_visible_in_window"), "Snapshot records missing visible exchange")
	_assert(issue_ids.has("hud_surfaces_stale_pressure"), "Snapshot records stale HUD pressure")
	_assert(issue_ids.has("fire_trace_or_impact_not_obvious"), "Snapshot records trace/impact visibility warning")
	_assert(String(snapshot.get("primary_issue_id", "")) == "first_exchange_not_visible_in_window", "Missing visible exchange is primary issue")
	_assert(int(snapshot.get("warning_count", 0)) >= 1, "Snapshot records warning count")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_847")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Snapshot creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")


func _test_optional_actual_recapture_manifest() -> void:
	if not FileAccess.file_exists(ACTUAL_RECAPTURE_PATH):
		_assert(true, "TASK_845 recapture manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(ACTUAL_RECAPTURE_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(manifest, _manual_review_notes())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual recapture builds TASK_846 schema")
	_assert(bool(snapshot.get("read_only", false)), "Actual recapture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual recapture snapshot sets no gameplay truth")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual recapture snapshot keeps TASK_847 recommendation")


func _test_manifest_roundtrip() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_recapture_manifest(), _manual_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_846 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_846", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "first_exchange_not_visible_in_window", "Roundtrip manifest keeps primary issue")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip manifest keeps read-only boundary")


func _good_recapture_manifest() -> Dictionary:
	return {
		"gate": "review_ready",
		"source_task_id": "TASK_844",
		"source_capture_task_id": "TASK_837",
		"expected_exchange_schema": EXCHANGE_SCHEMA,
		"expected_exchange_style_id": STYLE_ID,
		"window_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_exchange_real_window.png",
		"required_checks": [
			"contact_fire_or_fire_exchange_visible",
			"fire_event_trace_or_impact_visible",
			"event_log_contact_fire_or_exchange_detail_visible",
			"command_matrix_controls_remain_usable",
		],
		"manual_review_required": true,
		"manual_review_done": false,
	}


func _manual_review_notes() -> Dictionary:
	return {
		"manual_notes_present": true,
		"observed_window_state": "CONTACT_PRESSURE_NO_FIRE",
		"capture_review_ready": true,
		"layout_still_usable": true,
		"contact_pressure_framed": true,
		"first_exchange_not_visible_in_window": true,
		"hud_surfaces_stale_pressure": true,
		"fire_trace_or_impact_not_obvious": true,
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
