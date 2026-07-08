extends SceneTree

const Recapture := preload("res://scripts/mission/release_fire_exchange_contact_fire_primary_hud_recapture.gd")

const TASK_PATH := "res://docs/tasks/TASK_857_release_fire_exchange_contact_fire_primary_hud_recapture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html"
const SUMMARY_REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_fire_exchange_contact_fire_primary_hud_recapture.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_fire_exchange_contact_fire_primary_hud_recapture.ps1"
const SOURCE_CAPTURE_PATH := "res://tmp/release_fire_exchange_contact_fire_primary_hud_recapture.json"
const OUTPUT_PATH := "res://tmp/release_fire_exchange_contact_fire_primary_hud_recapture_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_fire_exchange_contact_fire_primary_hud_recapture.v1"
const PRIMARY_HUD_SCHEMA := "sternenbuergerchen.release_fire_exchange_contact_fire_primary_hud_polish.v1"
const PRIMARY_HUD_STYLE_ID := "task_856_release_fire_exchange_contact_fire_primary_hud_polish_v1"
const READABILITY_STYLE_ID := "task_853_release_fire_exchange_engagement_readability_v1"
const FOCUS_STYLE_ID := "task_850_release_fire_exchange_focused_visual_polish_v1"
const NEXT_TASK := "TASK_858 - Release Fire Exchange Contact-Fire Primary HUD Visual Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_857 Release Fire Exchange Contact-Fire Primary HUD Recapture ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_review_ready_manifest_builds_recapture()
	_test_optional_actual_capture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_857_release_fire_exchange_contact_fire_primary_hud_recapture: FAILED")
		quit(1)
		return
	print("TASK_857_release_fire_exchange_contact_fire_primary_hud_recapture: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var summary_report_text: String = _read_text(SUMMARY_REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_857 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_857 read-only recapture analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_857 capture tool exists")
	_assert(task_text.contains("Release Fire Exchange Contact-Fire Primary HUD Recapture"), "Task names contact-fire primary HUD recapture")
	_assert(status_text.contains("TASK_857 - Release Fire Exchange Contact-Fire Primary HUD Recapture"), "Implementation status tracks TASK_857")
	_assert(roadmap_text.contains("TASK_857 - Release Fire Exchange Contact-Fire Primary HUD Recapture (implementiert)"), "Roadmap marks TASK_857 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_858 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Contact-Fire-Primary-HUD-Recapture"), "Contract documents TASK_857")
	_assert(report_text.contains("TASK_857") and report_text.contains("release_fire_exchange_contact_fire_primary_hud_recapture"), "Fire-exchange report tracks TASK_857 artifact")
	_assert(summary_report_text.contains("TASK_857") and summary_report_text.contains("Recapture"), "Spielstand report tracks TASK_857")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_857 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_857\""), "Analyzer writes TASK_857 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_856\""), "Analyzer links TASK_856 source")
	_assert(service_text.contains(PRIMARY_HUD_SCHEMA), "Analyzer records TASK_856 primary HUD schema")
	_assert(service_text.contains(PRIMARY_HUD_STYLE_ID), "Analyzer records TASK_856 style id")
	_assert(service_text.contains("\"primary_hud_no_debug_no_fire_before_contact_fire\""), "Analyzer requires no primary debug NO FIRE")
	_assert(service_text.contains("\"event_log_contact_fire_visible\""), "Analyzer requires event-log CONTACT FIRE")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")
	_assert(tool_text.contains("capture_release_fire_exchange_after_readability_recapture.ps1"), "Capture tool reuses after-readability recapture")
	_assert(tool_text.contains("TASK_857"), "Capture tool writes TASK_857 manifest")
	_assert(tool_text.contains(PRIMARY_HUD_STYLE_ID), "Capture tool writes expected TASK_856 style id")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot({}, {}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing capture manifest blocks TASK_857")
	_assert(blocker_ids.has("capture_not_review_ready"), "Missing manifest reports capture_not_review_ready")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports window_screenshot_missing")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing manifest reports source_task_mismatch")
	_assert(blocker_ids.has("source_after_readability_recapture_mismatch"), "Missing manifest reports TASK_854 source mismatch")
	_assert(blocker_ids.has("primary_hud_schema_mismatch"), "Missing manifest reports primary_hud_schema_mismatch")
	_assert(blocker_ids.has("primary_hud_style_id_mismatch"), "Missing manifest reports primary_hud_style_id_mismatch")
	_assert(blocker_ids.has("persistence_window_too_short"), "Missing manifest reports short persistence")
	_assert(blocker_ids.has("required_recapture_checks_missing"), "Missing manifest reports missing required checks")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot is still read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_review_ready_manifest_builds_recapture() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot(_good_capture_manifest(), _good_primary_hud_snapshot(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_857")
	_assert(String(snapshot.get("task_id", "")) == "TASK_857", "Snapshot task id matches TASK_857")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_856", "Snapshot links TASK_856")
	_assert(String(snapshot.get("source_after_readability_recapture_task_id", "")) == "TASK_854", "Snapshot links TASK_854")
	_assert(String(snapshot.get("source_readability_task_id", "")) == "TASK_853", "Snapshot links TASK_853")
	_assert(String(snapshot.get("source_focus_task_id", "")) == "TASK_850", "Snapshot links TASK_850")
	_assert(String(snapshot.get("source_visibility_task_id", "")) == "TASK_847", "Snapshot links TASK_847")
	_assert(String(snapshot.get("source_exchange_task_id", "")) == "TASK_844", "Snapshot links TASK_844")
	_assert(String(snapshot.get("capture_gate", "")) == "review_ready", "Snapshot accepts review_ready capture")
	_assert(bool(snapshot.get("capture_review_ready", false)), "Snapshot marks capture review-ready")
	_assert(bool(snapshot.get("window_screenshot_written", false)), "Snapshot records window screenshot")
	_assert(bool(snapshot.get("desktop_screenshot_written", false)), "Snapshot records desktop screenshot")
	_assert(bool(snapshot.get("primary_hud_schema_ok", false)), "Snapshot accepts TASK_856 primary HUD schema")
	_assert(bool(snapshot.get("primary_hud_style_id_ok", false)), "Snapshot accepts TASK_856 primary HUD style")
	_assert(bool(snapshot.get("readability_style_id_ok", false)), "Snapshot accepts TASK_853 readability style")
	_assert(bool(snapshot.get("focus_style_id_ok", false)), "Snapshot accepts TASK_850 focus style")
	_assert(bool(snapshot.get("persistence_window_covers_capture_delay", false)), "Snapshot accepts 45s persistence")
	_assert(String(snapshot.get("primary_hud_task_id", "")) == "TASK_856", "Snapshot records TASK_856 primary HUD task")
	_assert(String(snapshot.get("primary_hud_status", "")) == "pass", "Snapshot records passing primary HUD snapshot")
	_assert(bool(snapshot.get("primary_hud_snapshot_read_only", false)), "Snapshot records read-only primary HUD source")
	_assert(not bool(snapshot.get("primary_lines_contain_debug_no_fire_before_contact_fire", true)), "Snapshot records no debug NO FIRE before CONTACT FIRE")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good capture has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_manual_acceptance", "Good capture waits for manual acceptance")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Manual review stays open")
	_assert(Array(snapshot.get("missing_recapture_checks", [])).is_empty(), "All recapture checks are present")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_858")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Snapshot creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_optional_actual_capture_manifest() -> void:
	if not FileAccess.file_exists(SOURCE_CAPTURE_PATH):
		_assert(true, "TASK_857 capture manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(SOURCE_CAPTURE_PATH)
	var snapshot: Dictionary = Recapture.build_snapshot(manifest, _good_primary_hud_snapshot(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual contact-fire capture builds TASK_857 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_856", "Actual contact-fire capture links TASK_856")
	_assert(String(snapshot.get("expected_primary_hud_style_id", "")) == PRIMARY_HUD_STYLE_ID, "Actual capture records TASK_856 style")
	_assert(bool(snapshot.get("read_only", false)), "Actual contact-fire snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual contact-fire snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual contact-fire snapshot updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(SOURCE_CAPTURE_PATH) if FileAccess.file_exists(SOURCE_CAPTURE_PATH) else _good_capture_manifest()
	var snapshot: Dictionary = Recapture.build_snapshot(source_manifest, _good_primary_hud_snapshot(), {})
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_857 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_857", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_856", "Roundtrip manifest keeps TASK_856 link")
	_assert(String(roundtrip.get("expected_primary_hud_style_id", "")) == PRIMARY_HUD_STYLE_ID, "Roundtrip manifest keeps primary HUD style")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip manifest keeps read-only boundary")


func _good_capture_manifest() -> Dictionary:
	return {
		"gate": "review_ready",
		"source_task_id": "TASK_856",
		"source_after_readability_recapture_task_id": "TASK_854",
		"source_readability_task_id": "TASK_853",
		"source_focus_task_id": "TASK_850",
		"source_visibility_task_id": "TASK_847",
		"source_exchange_task_id": "TASK_844",
		"source_capture_task_id": "TASK_837",
		"branch": "task/release-fire-exchange-contact-fire-primary-hud-recapture",
		"git_head": "test",
		"launch_argument": "--release-singleplayer-first-go-firefight",
		"wait_seconds": 38,
		"expected_primary_hud_schema": PRIMARY_HUD_SCHEMA,
		"expected_primary_hud_style_id": PRIMARY_HUD_STYLE_ID,
		"expected_readability_style_id": READABILITY_STYLE_ID,
		"expected_focus_style_id": FOCUS_STYLE_ID,
		"expected_persistence_duration_msec": 45000,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_fire_exchange_contact_fire_primary_hud_recapture.png",
		"desktop_screenshot_path": "tmp/release_fire_exchange_contact_fire_primary_hud_recapture_desktop.png",
		"hard_failures": [],
		"warnings": [],
		"required_checks": [
			"release_exe_started_with_first_go_firefight_arg",
			"task_856_primary_hud_expected",
			"contact_fire_primary_visible_in_selected_fireteam",
			"contact_fire_primary_visible_in_mission_control",
			"primary_hud_no_debug_no_fire_before_contact_fire",
			"event_log_contact_fire_visible",
			"fire_trace_or_impact_target_focus_visible",
			"command_surfaces_still_usable",
			"manual_visual_review_done",
		],
		"manual_review_required": true,
		"manual_review_done": false,
	}


func _good_primary_hud_snapshot() -> Dictionary:
	return {
		"schema": PRIMARY_HUD_SCHEMA,
		"task_id": "TASK_856",
		"status": "pass",
		"style_id": PRIMARY_HUD_STYLE_ID,
		"persistence_duration_msec": 45000,
		"primary_lines_contain_debug_no_fire_before_contact_fire": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
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
