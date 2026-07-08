extends SceneTree

const FrameTrace := preload("res://scripts/mission/release_first_exchange_hud_render_frame_trace.gd")

const TASK_PATH := "res://docs/tasks/TASK_886_release_first_exchange_real_window_hud_render_frame_trace.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_hud_render_frame_trace.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_first_exchange_hud_render_frame_trace.ps1"
const SOURCE_MANIFEST_PATH := "res://tmp/release_first_exchange_hud_render_frame_trace.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_hud_render_frame_trace_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_hud_render_frame_trace.v1"
const RECAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_hud_source_sync_recapture.v1"
const TRACE_SCHEMA := "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const RUNTIME_TRACE_SCHEMA := "sternenbuergerchen.release_first_exchange_exported_status_source_trace_runtime.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_887 - Release First Exchange Real Window HUD Render Frame Sync Fix"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_886 Release First Exchange HUD Render Frame Trace ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_ready_manifest_builds_frame_mismatch()
	_test_optional_actual_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_886_release_first_exchange_hud_render_frame_trace: FAILED")
		quit(1)
		return
	print("TASK_886_release_first_exchange_hud_render_frame_trace: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_886 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_886 analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_886 capture tool exists")
	_assert(task_text.contains("Release First Exchange Real Window HUD Render Frame Trace"), "Task names TASK_886")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_887 follow-up")
	_assert(status_text.contains("TASK_886 - Release First Exchange Real Window HUD Render Frame Trace"), "Implementation status tracks TASK_886")
	_assert(roadmap_text.contains("TASK_886 - Release First Exchange Real Window HUD Render Frame Trace (implementiert)"), "Roadmap marks TASK_886 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_887 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Real-Window-HUD-Render-Frame-Trace (TASK_886)"), "Contract documents TASK_886")
	_assert(report_text.contains("TASK_886") and report_text.contains("TASK_887"), "HTML report tracks TASK_886 and TASK_887")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_886 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_886\""), "Analyzer writes TASK_886 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_885\""), "Analyzer links TASK_885")
	_assert(service_text.contains("SOURCE_RECAPTURE_TASK_ID: String = \"TASK_884\""), "Analyzer links TASK_884")
	_assert(service_text.contains("SOURCE_HUD_SYNC_TASK_ID: String = \"TASK_883\""), "Analyzer links TASK_883")
	_assert(service_text.contains("\"render_frame_differs_from_final_trace\""), "Analyzer names render/source mismatch")
	_assert(service_text.contains("\"capture_frame_not_bound_to_final_source\""), "Analyzer names frame binding issue")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")
	_assert(tool_text.contains("capture_release_first_exchange_hud_source_sync_recapture.ps1"), "Capture tool reuses TASK_884")
	_assert(tool_text.contains("release_first_exchange_hud_render_frame_trace.json"), "Capture tool writes TASK_886 manifest")
	_assert(tool_text.contains("render_frame_review"), "Capture tool writes render frame review")
	_assert(tool_text.contains("final_source_snapshot"), "Capture tool writes final source snapshot")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = FrameTrace.build_snapshot({})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing manifest blocks TASK_886")
	_assert(blocker_ids.has("trace_schema_mismatch"), "Missing manifest reports TASK_886 schema mismatch")
	_assert(blocker_ids.has("trace_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("source_findings_mismatch"), "Missing manifest reports TASK_885 mismatch")
	_assert(blocker_ids.has("source_recapture_mismatch"), "Missing manifest reports TASK_884 mismatch")
	_assert(blocker_ids.has("source_hud_sync_mismatch"), "Missing manifest reports TASK_883 mismatch")
	_assert(blocker_ids.has("source_trace_mismatch"), "Missing manifest reports TASK_879 mismatch")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports missing screenshot")
	_assert(blocker_ids.has("runtime_trace_missing"), "Missing manifest reports missing runtime trace")
	_assert(blocker_ids.has("rendered_texts_missing"), "Missing manifest reports missing rendered texts")
	_assert(blocker_ids.has("final_source_snapshot_missing"), "Missing manifest reports missing final source snapshot")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_ready_manifest_builds_frame_mismatch() -> void:
	var snapshot: Dictionary = FrameTrace.build_snapshot(_good_manifest())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_886")
	_assert(String(snapshot.get("task_id", "")) == "TASK_886", "Snapshot task id matches TASK_886")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_885", "Snapshot links TASK_885")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_884", "Snapshot links TASK_884")
	_assert(String(snapshot.get("source_hud_sync_task_id", "")) == "TASK_883", "Snapshot links TASK_883")
	_assert(String(snapshot.get("source_trace_task_id", "")) == "TASK_879", "Snapshot links TASK_879")
	_assert(String(snapshot.get("source_fire_visual_task_id", "")) == "TASK_880", "Snapshot links TASK_880")
	_assert(String(snapshot.get("source_visible_status_task_id", "")) == "TASK_876", "Snapshot links TASK_876")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good manifest has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_render_sync_fix", "Frame mismatch is ready for TASK_887")
	_assert(bool(snapshot.get("rendered_texts_collected", false)), "Snapshot records rendered text readback")
	_assert(String(snapshot.get("rendered_screenshot_observed_state", "")).contains("NO_FIRE"), "Snapshot records screenshot NO_FIRE state")
	_assert(String(snapshot.get("final_source_observed_state", "")) == "FINAL_SOURCE_CONTACT_FIRE", "Snapshot records final CONTACT_FIRE source state")
	_assert(bool(snapshot.get("source_selected_starts_contact_fire", false)), "Source selected status starts CONTACT FIRE")
	_assert(bool(snapshot.get("source_mission_starts_contact_fire", false)), "Source mission status starts CONTACT FIRE")
	_assert(bool(snapshot.get("source_event_log_contains_contact_fire", false)), "Source event log contains CONTACT FIRE")
	_assert(not bool(snapshot.get("source_event_log_contains_contact_pressure", true)), "Source event log does not contain CONTACT PRESSURE")
	_assert(String(snapshot.get("rendered_selected_fireteam_text", "")).contains("NO FIRE"), "Rendered #17 text records NO FIRE")
	_assert(String(snapshot.get("rendered_event_log_text", "")).contains("CONTACT PRESSURE"), "Rendered #19 text records CONTACT PRESSURE")
	_assert(bool(snapshot.get("render_frame_differs_from_final_trace", false)), "Snapshot detects render/source mismatch")
	_assert(issue_ids.has("render_frame_differs_from_final_trace"), "Snapshot records primary render/source issue")
	_assert(issue_ids.has("capture_frame_not_bound_to_final_source"), "Snapshot records frame binding issue")
	_assert(issue_ids.has("rendered_selected_fireteam_still_no_fire"), "Snapshot records #17 render issue")
	_assert(issue_ids.has("rendered_event_log_still_contact_pressure"), "Snapshot records #19 render issue")
	_assert(issue_ids.has("event_log_render_differs_from_source"), "Snapshot records Event Log source mismatch")
	_assert(String(snapshot.get("primary_issue_id", "")) == "render_frame_differs_from_final_trace", "Render/source mismatch is primary")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_887")
	_assert(String(snapshot.get("recommended_direction", "")) == "bind_capture_frame_to_final_hud_source_or_trace_late_surface_overwrite", "Snapshot recommends sync direction")
	_assert(String(snapshot.get("avoid_next_action", "")) == "do_not_add_more_contact_fire_text_before_render_frame_sync", "Snapshot rejects blind text layering")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_optional_actual_manifest() -> void:
	if not FileAccess.file_exists(SOURCE_MANIFEST_PATH):
		_assert(true, "TASK_886 manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH)
	var snapshot: Dictionary = FrameTrace.build_snapshot(manifest)
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual manifest builds TASK_886 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_885", "Actual manifest links TASK_885")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_884", "Actual manifest links TASK_884")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual manifest keeps TASK_887 recommendation")
	_assert(bool(snapshot.get("read_only", false)), "Actual manifest snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual manifest snapshot sets no gameplay truth")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH) if FileAccess.file_exists(SOURCE_MANIFEST_PATH) else _good_manifest()
	var snapshot: Dictionary = FrameTrace.build_snapshot(source_manifest)
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_886 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_886", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_885", "Roundtrip keeps TASK_885 link")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "render_frame_differs_from_final_trace", "Roundtrip keeps primary issue")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_manifest() -> Dictionary:
	return {
		"schema": SCHEMA,
		"task_id": "TASK_886",
		"source_task_id": "TASK_885",
		"source_recapture_task_id": "TASK_884",
		"source_hud_sync_task_id": "TASK_883",
		"source_trace_task_id": "TASK_879",
		"source_fire_visual_task_id": "TASK_880",
		"source_visible_status_task_id": "TASK_876",
		"gate": "review_ready",
		"branch": "task/release-first-exchange-hud-render-frame-trace",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"wait_seconds": 52,
		"source_recapture_schema": RECAPTURE_SCHEMA,
		"source_trace_schema": TRACE_SCHEMA,
		"source_runtime_trace_schema": RUNTIME_TRACE_SCHEMA,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_handle_capture_succeeded": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_exchange_hud_render_frame_trace.png",
		"desktop_screenshot_path": "tmp/release_first_exchange_hud_render_frame_trace_desktop.png",
		"runtime_trace_written": true,
		"runtime_trace_sample_count": 10,
		"hard_failures": [],
		"render_frame_review": {
			"frame_trace_method": "task_884_window_handle_screenshot_manual_text_readback_plus_task_879_latest_sample",
			"rendered_texts_collected": true,
			"screenshot_observed_state": "STERNENBUERGERCHEN_NO_FIRE_NO_LOS_CONTACT_PRESSURE",
			"rendered_selected_fireteam_text": "#17 NEXT LOS/RANGE KORRIGIEREN | WHY KEIN ZIEL | Kampf NO FIRE NO_LOS",
			"rendered_mission_control_text": "#18 NEXT LOS/RANGE KORRIGIEREN | Kampf NO FIRE NO_LOS",
			"rendered_event_log_text": "#19 FT1 CONTACT PRESSURE: Position korrigieren",
			"capture_frame_not_bound_to_final_source": true,
		},
		"final_source_snapshot": {
			"source_observed_state": "FINAL_SOURCE_CONTACT_FIRE",
			"stage": "deeplink_final",
			"timestamp_msec": 70685,
			"selected_starts_contact_fire": true,
			"mission_starts_contact_fire": true,
			"event_log_contains_contact_fire": true,
			"event_log_contains_contact_pressure": false,
			"selected_fireteam_status_text": "CONTACT FIRE | FIRE player_ste>ground_pat RIFLE HIT",
			"mission_control_status_text": "CONTACT FIRE | FIRE player_ste>ground_pat RIFLE HIT",
			"event_log_short_text": "CONTACT FIRE: Feuerwechsel lesen",
		},
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
