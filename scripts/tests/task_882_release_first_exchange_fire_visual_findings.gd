extends SceneTree

const Findings := preload("res://scripts/mission/release_first_exchange_fire_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_882_release_first_exchange_fire_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_fire_visual_findings.gd"
const CAPTURE_PATH := "res://tmp/release_first_exchange_fire_visual_recapture.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_fire_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_fire_visual_findings.v1"
const CAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_fire_visual_recapture.v1"
const FIRE_VISUAL_SCHEMA := "sternenbuergerchen.release_first_exchange_fire_visual_polish.v1"
const FIRE_VISUAL_STYLE_ID := "task_880_release_first_exchange_fire_visual_polish_v1"
const TRACE_SCHEMA := "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const VISIBLE_STATUS_SCHEMA := "sternenbuergerchen.release_first_exchange_visible_status_source_reconciliation.v1"
const VISIBLE_STATUS_STYLE_ID := "task_876_release_first_exchange_visible_status_source_reconciliation_v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_883 - Release First Exchange Real Window HUD Source Sync Fix"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_882 Release First Exchange Fire Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_capture_blocks()
	_test_ready_capture_builds_findings()
	_test_optional_actual_capture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_882_release_first_exchange_fire_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_882_release_first_exchange_fire_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_882 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_882 read-only findings analyzer exists")
	_assert(task_text.contains("Release First Exchange Fire Visual Findings"), "Task names TASK_882")
	_assert(task_text.contains("TASK_883"), "Task names TASK_883 follow-up")
	_assert(status_text.contains("TASK_882 - Release First Exchange Fire Visual Findings"), "Implementation status tracks TASK_882")
	_assert(roadmap_text.contains("TASK_882 - Release First Exchange Fire Visual Findings (implementiert)"), "Roadmap marks TASK_882 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_883 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Fire-Visual-Findings (TASK_882)"), "Contract documents TASK_882")
	_assert(report_text.contains("TASK_882") and report_text.contains("TASK_883"), "HTML report tracks TASK_882 and TASK_883")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes TASK_882 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_882\""), "Analyzer writes TASK_882 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_881\""), "Analyzer links TASK_881")
	_assert(service_text.contains("SOURCE_FIRE_VISUAL_TASK_ID: String = \"TASK_880\""), "Analyzer links TASK_880")
	_assert(service_text.contains("SOURCE_TRACE_TASK_ID: String = \"TASK_879\""), "Analyzer links TASK_879")
	_assert(service_text.contains("\"task_880_fire_visual_not_real_window_first_reading\""), "Analyzer names TASK_880 real-window mismatch")
	_assert(service_text.contains("\"selected_fireteam_still_no_los_first\""), "Analyzer names #17 issue")
	_assert(service_text.contains("\"mission_control_still_no_los_first\""), "Analyzer names #18 issue")
	_assert(service_text.contains("\"event_log_contact_pressure_still_dominates\""), "Analyzer names #19 issue")
	_assert(service_text.contains("\"contact_fire_text_not_visible_in_window\""), "Analyzer names missing CONTACT FIRE text issue")
	_assert(service_text.contains("\"fire_trace_or_impact_not_decision_clear\""), "Analyzer names unclear fire visual issue")
	_assert(service_text.contains("sync_real_window_hud_and_event_log_sources_with_final_contact_fire_trace_state"), "Analyzer recommends HUD/Event-Log source sync")
	_assert(service_text.contains("do_not_tune_fire_vfx_again_before_visible_hud_source_sync"), "Analyzer rejects more blind VFX tuning")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")


func _test_missing_capture_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing capture manifest blocks TASK_882")
	_assert(blocker_ids.has("capture_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("capture_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("source_fire_visual_mismatch"), "Missing manifest reports TASK_880 mismatch")
	_assert(blocker_ids.has("source_trace_mismatch"), "Missing manifest reports TASK_879 mismatch")
	_assert(blocker_ids.has("source_visible_status_mismatch"), "Missing manifest reports TASK_876 mismatch")
	_assert(blocker_ids.has("source_recapture_mismatch"), "Missing manifest reports TASK_877 mismatch")
	_assert(blocker_ids.has("source_focus_mismatch"), "Missing manifest reports TASK_850 mismatch")
	_assert(blocker_ids.has("source_exchange_mismatch"), "Missing manifest reports TASK_844 mismatch")
	_assert(blocker_ids.has("capture_not_review_ready"), "Missing manifest reports capture gate")
	_assert(blocker_ids.has("launch_argument_mismatch"), "Missing manifest reports launch argument")
	_assert(blocker_ids.has("fire_visual_style_id_mismatch"), "Missing manifest reports TASK_880 style")
	_assert(blocker_ids.has("trace_schema_mismatch"), "Missing manifest reports TASK_879 trace")
	_assert(blocker_ids.has("visible_status_style_id_mismatch"), "Missing manifest reports TASK_876 style")
	_assert(blocker_ids.has("runtime_trace_missing"), "Missing manifest reports runtime trace")
	_assert(blocker_ids.has("status_source_activation_missing"), "Missing manifest reports status source activation")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports screenshot missing")
	_assert(blocker_ids.has("window_capture_method_not_handle_print"), "Missing manifest reports capture method")
	_assert(blocker_ids.has("window_capture_not_trusted"), "Missing manifest reports untrusted capture")
	_assert(blocker_ids.has("window_handle_capture_failed"), "Missing manifest reports handle failure")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_ready_capture_builds_findings() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_capture_manifest(), _manual_review_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_882")
	_assert(String(snapshot.get("task_id", "")) == "TASK_882", "Snapshot task id matches TASK_882")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_881", "Snapshot links TASK_881")
	_assert(String(snapshot.get("source_fire_visual_task_id", "")) == "TASK_880", "Snapshot links TASK_880")
	_assert(String(snapshot.get("source_trace_task_id", "")) == "TASK_879", "Snapshot links TASK_879")
	_assert(String(snapshot.get("source_visible_status_task_id", "")) == "TASK_876", "Snapshot links TASK_876")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_877", "Snapshot links TASK_877")
	_assert(String(snapshot.get("source_focus_task_id", "")) == "TASK_850", "Snapshot links TASK_850")
	_assert(String(snapshot.get("source_exchange_task_id", "")) == "TASK_844", "Snapshot links TASK_844")
	_assert(bool(snapshot.get("capture_schema_ok", false)), "Snapshot accepts TASK_881 schema")
	_assert(String(snapshot.get("capture_gate", "")) == "review_ready", "Snapshot records review_ready capture")
	_assert(bool(snapshot.get("fire_visual_schema_ok", false)), "Snapshot accepts TASK_880 schema")
	_assert(bool(snapshot.get("fire_visual_style_id_ok", false)), "Snapshot accepts TASK_880 style")
	_assert(bool(snapshot.get("trace_schema_ok", false)), "Snapshot accepts TASK_879 trace")
	_assert(bool(snapshot.get("visible_status_schema_ok", false)), "Snapshot accepts TASK_876 schema")
	_assert(bool(snapshot.get("visible_status_style_id_ok", false)), "Snapshot accepts TASK_876 style")
	_assert(bool(snapshot.get("runtime_trace_written", false)), "Snapshot records runtime trace")
	_assert(bool(snapshot.get("runtime_trace_activation_observed", false)), "Snapshot records TASK_876 activation")
	_assert(not bool(snapshot.get("runtime_trace_final_no_los_or_contact_pressure_observed", true)), "Snapshot records clean final trace")
	_assert(String(snapshot.get("window_capture_method", "")) == "window_handle_print", "Snapshot records handle capture method")
	_assert(bool(snapshot.get("window_capture_trusted", false)), "Snapshot records trusted capture")
	_assert(bool(snapshot.get("window_handle_capture_succeeded", false)), "Snapshot records handle capture success")
	_assert(bool(snapshot.get("correct_window_content_confirmed", false)), "Snapshot confirms Sternenbuergerchen window")
	_assert(bool(snapshot.get("command_surfaces_still_usable", false)), "Snapshot confirms command surfaces")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good capture has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_real_window_hud_source_sync_fix", "Manual notes produce TASK_883-ready status")
	_assert(String(snapshot.get("observed_window_state", "")) == "STERNENBUERGERCHEN_NO_LOS_CONTACT_PRESSURE_AFTER_TASK_880", "Snapshot records observed window state")
	_assert(String(snapshot.get("selected_fireteam_primary_reading", "")).contains("LOS/RANGE"), "Snapshot records selected-fireteam LOS/RANGE reading")
	_assert(String(snapshot.get("mission_control_primary_reading", "")).contains("NO FIRE NO_LOS"), "Snapshot records Mission Control NO_LOS reading")
	_assert(String(snapshot.get("event_log_primary_reading", "")).contains("CONTACT PRESSURE"), "Snapshot records CONTACT PRESSURE reading")
	_assert(issue_ids.has("task_880_fire_visual_not_real_window_first_reading"), "Snapshot records TASK_880 mismatch issue")
	_assert(issue_ids.has("selected_fireteam_still_no_los_first"), "Snapshot records #17 issue")
	_assert(issue_ids.has("mission_control_still_no_los_first"), "Snapshot records #18 issue")
	_assert(issue_ids.has("event_log_contact_pressure_still_dominates"), "Snapshot records #19 issue")
	_assert(issue_ids.has("contact_fire_text_not_visible_in_window"), "Snapshot records missing CONTACT FIRE issue")
	_assert(issue_ids.has("fire_trace_or_impact_not_decision_clear"), "Snapshot records unclear fire visual issue")
	_assert(String(snapshot.get("primary_issue_id", "")) == "task_880_fire_visual_not_real_window_first_reading", "TASK_880 mismatch is primary issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_883")
	_assert(String(snapshot.get("recommended_direction", "")) == "sync_real_window_hud_and_event_log_sources_with_final_contact_fire_trace_state", "Snapshot recommends source sync")
	_assert(String(snapshot.get("avoid_next_action", "")) == "do_not_tune_fire_vfx_again_before_visible_hud_source_sync", "Snapshot rejects more blind VFX tuning")
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
		_assert(true, "TASK_881 capture manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(CAPTURE_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(manifest, _manual_review_notes())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual capture builds TASK_882 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_881", "Actual capture links TASK_881")
	_assert(String(snapshot.get("source_fire_visual_task_id", "")) == "TASK_880", "Actual capture links TASK_880")
	_assert(String(snapshot.get("expected_fire_visual_style_id", "")) == FIRE_VISUAL_STYLE_ID, "Actual capture records TASK_880 style")
	_assert(bool(snapshot.get("runtime_trace_activation_observed", false)), "Actual capture records TASK_879 trace activation")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual capture keeps TASK_883 recommendation")
	_assert(bool(snapshot.get("read_only", false)), "Actual capture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual capture snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual capture snapshot updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(CAPTURE_PATH) if FileAccess.file_exists(CAPTURE_PATH) else _good_capture_manifest()
	var snapshot: Dictionary = Findings.build_snapshot(source_manifest, _manual_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_882 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_882", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_881", "Roundtrip manifest keeps TASK_881 link")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "task_880_fire_visual_not_real_window_first_reading", "Roundtrip keeps primary issue")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_capture_manifest() -> Dictionary:
	return {
		"schema": CAPTURE_SCHEMA,
		"task_id": "TASK_881",
		"source_task_id": "TASK_880",
		"source_trace_task_id": "TASK_879",
		"source_visible_status_task_id": "TASK_876",
		"source_recapture_task_id": "TASK_877",
		"source_focus_task_id": "TASK_850",
		"source_exchange_task_id": "TASK_844",
		"gate": "review_ready",
		"branch": "task/release-first-exchange-fire-visual-recapture",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"wait_seconds": 52,
		"expected_fire_visual_schema": FIRE_VISUAL_SCHEMA,
		"expected_fire_visual_style_id": FIRE_VISUAL_STYLE_ID,
		"expected_trace_schema": TRACE_SCHEMA,
		"expected_visible_status_schema": VISIBLE_STATUS_SCHEMA,
		"expected_visible_status_style_id": VISIBLE_STATUS_STYLE_ID,
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
		"window_screenshot_path": "tmp/release_first_exchange_fire_visual_recapture.png",
		"desktop_screenshot_path": "tmp/release_first_exchange_fire_visual_recapture_desktop.png",
		"hard_failures": [],
		"warnings": [],
	}


func _manual_review_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"observed_window_state": "STERNENBUERGERCHEN_NO_LOS_CONTACT_PRESSURE_AFTER_TASK_880",
		"correct_window_content_confirmed": true,
		"selected_fireteam_primary_reading": "#17 NEXT LOS/RANGE KORRIGIEREN | WHY KEIN ZIEL | Kampf NO FIRE NO_LOS",
		"mission_control_primary_reading": "#18 NEXT LOS/RANGE KORRIGIEREN | Kampf NO FIRE NO_LOS",
		"event_log_primary_reading": "#19 FT1 CONTACT PRESSURE: Position korrigieren",
		"contact_fire_readability_ok": false,
		"fire_trace_or_impact_visible": false,
		"target_focus_visible": false,
		"command_surfaces_still_usable": true,
		"task_880_fire_visual_not_real_window_first_reading": true,
		"selected_fireteam_still_no_los_first": true,
		"mission_control_still_no_los_first": true,
		"event_log_contact_pressure_still_dominates": true,
		"contact_fire_text_not_visible_in_window": true,
		"fire_trace_or_impact_not_decision_clear": true,
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
