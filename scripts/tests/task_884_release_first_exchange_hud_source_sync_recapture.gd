extends SceneTree

const Recapture := preload("res://scripts/mission/release_first_exchange_hud_source_sync_recapture.gd")

const TASK_PATH := "res://docs/tasks/TASK_884_release_first_exchange_hud_source_sync_recapture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_hud_source_sync_recapture.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_first_exchange_hud_source_sync_recapture.ps1"
const SOURCE_CAPTURE_PATH := "res://tmp/release_first_exchange_hud_source_sync_recapture.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_hud_source_sync_recapture_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_hud_source_sync_recapture.v1"
const HUD_SOURCE_SYNC_SCHEMA := "sternenbuergerchen.release_first_exchange_real_window_hud_source_sync.v1"
const HUD_SOURCE_SYNC_STYLE_ID := "task_883_release_first_exchange_real_window_hud_source_sync_v1"
const FIRE_VISUAL_SCHEMA := "sternenbuergerchen.release_first_exchange_fire_visual_polish.v1"
const FIRE_VISUAL_STYLE_ID := "task_880_release_first_exchange_fire_visual_polish_v1"
const TRACE_SCHEMA := "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const NEXT_TASK := "TASK_885 - Release First Exchange HUD Source Sync Visual Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_884 Release First Exchange HUD Source Sync Recapture ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_review_ready_manifest_builds_recapture()
	_test_manual_review_recording()
	_test_optional_actual_capture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_884_release_first_exchange_hud_source_sync_recapture: FAILED")
		quit(1)
		return
	print("TASK_884_release_first_exchange_hud_source_sync_recapture: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_884 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_884 read-only recapture analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_884 capture tool exists")
	_assert(task_text.contains("Release First Exchange HUD Source Sync Recapture"), "Task names TASK_884")
	_assert(task_text.contains("Kein Combat-Rewrite"), "Task states no combat rewrite")
	_assert(status_text.contains("TASK_884 - Release First Exchange HUD Source Sync Recapture"), "Implementation status tracks TASK_884")
	_assert(roadmap_text.contains("TASK_884 - Release First Exchange HUD Source Sync Recapture (implementiert)"), "Roadmap marks TASK_884 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_885 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-HUD-Source-Sync-Recapture (TASK_884)"), "Contract documents TASK_884")
	_assert(report_text.contains("TASK_884") and report_text.contains("release_first_exchange_hud_source_sync_recapture"), "HTML report tracks TASK_884 artifact")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_884 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_884\""), "Analyzer writes TASK_884 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_883\""), "Analyzer links TASK_883 source")
	_assert(service_text.contains("SOURCE_RECAPTURE_TASK_ID: String = \"TASK_881\""), "Analyzer links TASK_881 source")
	_assert(service_text.contains("SOURCE_TRACE_TASK_ID: String = \"TASK_879\""), "Analyzer links TASK_879 source")
	_assert(service_text.contains(HUD_SOURCE_SYNC_STYLE_ID), "Analyzer records TASK_883 style")
	_assert(service_text.contains("\"contact_fire_visible_in_selected_fireteam\""), "Analyzer requires #17 CONTACT FIRE")
	_assert(service_text.contains("\"contact_fire_visible_in_mission_control\""), "Analyzer requires #18 CONTACT FIRE")
	_assert(service_text.contains("\"contact_fire_visible_in_event_log\""), "Analyzer requires #19 CONTACT FIRE")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")
	_assert(tool_text.contains("capture_release_first_exchange_fire_visual_recapture.ps1"), "Capture tool reuses TASK_881 recapture")
	_assert(tool_text.contains("release_first_exchange_hud_source_sync_recapture.json"), "Capture tool writes TASK_884 manifest")
	_assert(tool_text.contains(HUD_SOURCE_SYNC_STYLE_ID), "Capture tool writes expected TASK_883 style id")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot({}, {}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing capture manifest blocks TASK_884")
	_assert(blocker_ids.has("recapture_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("recapture_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing manifest reports TASK_883 mismatch")
	_assert(blocker_ids.has("source_recapture_mismatch"), "Missing manifest reports TASK_881 mismatch")
	_assert(blocker_ids.has("source_trace_mismatch"), "Missing manifest reports TASK_879 mismatch")
	_assert(blocker_ids.has("source_fire_visual_mismatch"), "Missing manifest reports TASK_880 mismatch")
	_assert(blocker_ids.has("source_visible_status_mismatch"), "Missing manifest reports TASK_876 mismatch")
	_assert(blocker_ids.has("launch_argument_mismatch"), "Missing manifest reports launch mismatch")
	_assert(blocker_ids.has("capture_not_review_ready"), "Missing manifest reports capture gate")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports missing screenshot")
	_assert(blocker_ids.has("hud_source_sync_style_id_mismatch"), "Missing manifest reports TASK_883 style")
	_assert(blocker_ids.has("trace_schema_mismatch"), "Missing manifest reports TASK_879 trace schema")
	_assert(blocker_ids.has("window_capture_not_trusted"), "Missing manifest reports capture trust")
	_assert(blocker_ids.has("runtime_trace_missing"), "Missing manifest reports missing runtime trace")
	_assert(blocker_ids.has("status_source_activation_missing"), "Missing manifest reports missing status source activation")
	_assert(blocker_ids.has("required_recapture_checks_missing"), "Missing manifest reports missing checks")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_review_ready_manifest_builds_recapture() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot(_good_capture_manifest(), _good_hud_source_sync_snapshot(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_884")
	_assert(String(snapshot.get("task_id", "")) == "TASK_884", "Snapshot task id matches TASK_884")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_883", "Snapshot links TASK_883")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_881", "Snapshot links TASK_881")
	_assert(String(snapshot.get("source_trace_task_id", "")) == "TASK_879", "Snapshot links TASK_879")
	_assert(String(snapshot.get("source_fire_visual_task_id", "")) == "TASK_880", "Snapshot links TASK_880")
	_assert(String(snapshot.get("source_visible_status_task_id", "")) == "TASK_876", "Snapshot links TASK_876")
	_assert(String(snapshot.get("capture_gate", "")) == "review_ready", "Snapshot accepts review_ready capture")
	_assert(bool(snapshot.get("capture_review_ready", false)), "Snapshot marks capture review-ready")
	_assert(bool(snapshot.get("launch_argument_ok", false)), "Snapshot records first-go firefight arg")
	_assert(bool(snapshot.get("window_screenshot_written", false)), "Snapshot records window screenshot")
	_assert(bool(snapshot.get("desktop_screenshot_written", false)), "Snapshot records desktop screenshot")
	_assert(String(snapshot.get("window_capture_method", "")) == "window_handle_print", "Snapshot records handle capture")
	_assert(bool(snapshot.get("window_capture_trusted", false)), "Snapshot records trusted capture")
	_assert(bool(snapshot.get("window_handle_capture_succeeded", false)), "Snapshot records handle capture success")
	_assert(bool(snapshot.get("hud_source_sync_schema_ok", false)), "Snapshot accepts TASK_883 schema")
	_assert(bool(snapshot.get("hud_source_sync_style_id_ok", false)), "Snapshot accepts TASK_883 style")
	_assert(bool(snapshot.get("fire_visual_schema_ok", false)), "Snapshot accepts TASK_880 schema")
	_assert(bool(snapshot.get("fire_visual_style_id_ok", false)), "Snapshot accepts TASK_880 style")
	_assert(bool(snapshot.get("trace_schema_ok", false)), "Snapshot accepts TASK_879 trace schema")
	_assert(bool(snapshot.get("runtime_trace_written", false)), "Snapshot records runtime trace")
	_assert(bool(snapshot.get("runtime_trace_activation_observed", false)), "Snapshot records TASK_876 activation")
	_assert(not bool(snapshot.get("runtime_trace_final_no_los_or_contact_pressure_observed", true)), "Snapshot records no stale final status")
	_assert(String(snapshot.get("hud_source_sync_task_id", "")) == "TASK_883", "Snapshot records TASK_883 hud source sync task")
	_assert(String(snapshot.get("hud_source_sync_status", "")) == "pass", "Snapshot records passing TASK_883 hud source sync snapshot")
	_assert(bool(snapshot.get("hud_source_sync_snapshot_read_only", false)), "Snapshot records read-only TASK_883 source")
	_assert(Array(snapshot.get("missing_recapture_checks", [])).is_empty(), "All TASK_884 recapture checks are present")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good capture has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_manual_review", "Good capture waits for manual review")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_885")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Snapshot creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_manual_review_recording() -> void:
	var notes: Dictionary = {
		"manual_visual_review_done": true,
		"contact_fire_readability_ok": true,
		"fire_trace_visible": true,
		"impact_visible": true,
		"target_focus_visible": false,
		"short_fire_status_label_visible": true,
	}
	var snapshot: Dictionary = Recapture.build_snapshot(_good_capture_manifest(), _good_hud_source_sync_snapshot(), notes)
	_assert(String(snapshot.get("status", "")) == "manual_review_recorded", "Manual review status can be recorded")
	_assert(bool(snapshot.get("manual_review_done", false)), "Manual review done flag is recorded")
	_assert(int(snapshot.get("manual_finding_count", 0)) == 6, "Manual findings are exported")
	_assert(bool(snapshot.get("read_only", false)), "Manual review snapshot remains read-only")


func _test_optional_actual_capture_manifest() -> void:
	if not FileAccess.file_exists(SOURCE_CAPTURE_PATH):
		_assert(true, "TASK_884 capture manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(SOURCE_CAPTURE_PATH)
	var snapshot: Dictionary = Recapture.build_snapshot(manifest, _good_hud_source_sync_snapshot(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual capture builds TASK_884 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_883", "Actual capture links TASK_883")
	_assert(String(snapshot.get("expected_hud_source_sync_style_id", "")) == HUD_SOURCE_SYNC_STYLE_ID, "Actual capture records TASK_883 style")
	_assert(bool(snapshot.get("read_only", false)), "Actual capture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual capture snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual capture snapshot updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(SOURCE_CAPTURE_PATH) if FileAccess.file_exists(SOURCE_CAPTURE_PATH) else _good_capture_manifest()
	var snapshot: Dictionary = Recapture.build_snapshot(source_manifest, _good_hud_source_sync_snapshot(), {})
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_884 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_884", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_883", "Roundtrip keeps TASK_883 link")
	_assert(String(roundtrip.get("expected_hud_source_sync_style_id", "")) == HUD_SOURCE_SYNC_STYLE_ID, "Roundtrip keeps TASK_883 style")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_capture_manifest() -> Dictionary:
	return {
		"schema": SCHEMA,
		"task_id": "TASK_884",
		"source_task_id": "TASK_883",
		"source_recapture_task_id": "TASK_881",
		"source_trace_task_id": "TASK_879",
		"source_fire_visual_task_id": "TASK_880",
		"source_visible_status_task_id": "TASK_876",
		"gate": "review_ready",
		"branch": "task/release-first-exchange-hud-source-sync-recapture",
		"git_head": "test",
		"launch_argument": "--release-singleplayer-first-go-firefight",
		"wait_seconds": 52,
		"expected_hud_source_sync_schema": HUD_SOURCE_SYNC_SCHEMA,
		"expected_hud_source_sync_style_id": HUD_SOURCE_SYNC_STYLE_ID,
		"expected_fire_visual_schema": FIRE_VISUAL_SCHEMA,
		"expected_fire_visual_style_id": FIRE_VISUAL_STYLE_ID,
		"expected_trace_schema": TRACE_SCHEMA,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_handle_capture_succeeded": true,
		"foreground_matches_selected_process": true,
		"runtime_trace_written": true,
		"runtime_trace_sample_count": 10,
		"runtime_trace_activation_observed": true,
		"runtime_trace_final_no_los_or_contact_pressure_observed": false,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_exchange_hud_source_sync_recapture.png",
		"desktop_screenshot_path": "tmp/release_first_exchange_hud_source_sync_recapture_desktop.png",
		"hard_failures": [],
		"warnings": [],
		"required_checks": [
			"release_exe_started_with_first_go_firefight_arg",
			"task_883_hud_source_sync_expected",
			"task_881_window_handle_recapture_source_expected",
			"task_879_status_source_trace_expected",
			"window_handle_capture_trusted",
			"contact_fire_visible_in_selected_fireteam",
			"contact_fire_visible_in_mission_control",
			"contact_fire_visible_in_event_log",
			"fire_trace_visible",
			"impact_visible",
			"target_focus_visible",
			"short_fire_status_label_visible",
			"command_surfaces_still_usable",
			"no_stale_no_los_or_contact_pressure_only_message",
			"manual_visual_review_done",
		],
		"manual_review_required": true,
		"manual_review_done": false,
	}


func _good_hud_source_sync_snapshot() -> Dictionary:
	return {
		"schema": HUD_SOURCE_SYNC_SCHEMA,
		"task_id": "TASK_883",
		"status": "pass",
		"style_id": HUD_SOURCE_SYNC_STYLE_ID,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
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
