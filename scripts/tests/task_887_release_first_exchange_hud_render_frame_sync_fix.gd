extends SceneTree

const SyncFix := preload("res://scripts/mission/release_first_exchange_hud_render_frame_sync_fix.gd")

const TASK_PATH := "res://docs/tasks/TASK_887_release_first_exchange_real_window_hud_render_frame_sync_fix.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_hud_render_frame_sync_fix.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_first_exchange_hud_render_frame_sync_fix.ps1"
const SOURCE_MANIFEST_PATH := "res://tmp/release_first_exchange_hud_render_frame_sync_fix.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_hud_render_frame_sync_fix_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_hud_render_frame_sync_fix.v1"
const TRACE_SCHEMA := "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const RUNTIME_TRACE_SCHEMA := "sternenbuergerchen.release_first_exchange_exported_status_source_trace_runtime.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_888 - Release First Exchange Player Readability Polish Review"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_887 Release First Exchange HUD Render Frame Sync Fix ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_good_manifest_passes_sync()
	_test_stale_post_final_frame_reviews()
	_test_optional_actual_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_887_release_first_exchange_hud_render_frame_sync_fix: FAILED")
		quit(1)
		return
	print("TASK_887_release_first_exchange_hud_render_frame_sync_fix: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_887 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_887 analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_887 capture tool exists")
	_assert(task_text.contains("Release First Exchange Real Window HUD Render Frame Sync Fix"), "Task names TASK_887")
	_assert(task_text.contains("post_final_capture_after_deeplink_final"), "Task requires post-final capture ordering")
	_assert(status_text.contains("TASK_887 - Release First Exchange Real Window HUD Render Frame Sync Fix"), "Implementation status tracks TASK_887")
	_assert(roadmap_text.contains("TASK_887 - Release First Exchange Real Window HUD Render Frame Sync Fix (implementiert)"), "Roadmap marks TASK_887 implemented")
	_assert(contract_text.contains("Release-First-Exchange-Real-Window-HUD-Render-Frame-Sync-Fix (TASK_887)"), "Contract documents TASK_887")
	_assert(report_text.contains("TASK_887") and report_text.contains("TASK_888"), "HTML report tracks TASK_887 and TASK_888")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_887 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_887\""), "Analyzer writes TASK_887 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_886\""), "Analyzer links TASK_886")
	_assert(service_text.contains("SOURCE_TRACE_TASK_ID: String = \"TASK_879\""), "Analyzer links TASK_879")
	_assert(service_text.contains("\"render_frame_synced_to_final_trace\""), "Analyzer exposes sync gate")
	_assert(service_text.contains("\"post_final_capture_after_deeplink_final\""), "Analyzer checks post-final ordering")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")
	_assert(tool_text.contains("capture_release_first_exchange_exported_status_source_trace.ps1"), "Capture tool waits through TASK_879 trace")
	_assert(tool_text.contains("capture_release_singleplayer_visible_window.ps1"), "Capture tool captures the running process after trace")
	_assert(tool_text.contains("post_final_render_frame_review"), "Capture tool writes post-final render review")
	_assert(tool_text.contains("release_first_exchange_hud_render_frame_sync_fix.json"), "Capture tool writes TASK_887 manifest")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = SyncFix.build_snapshot({})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing manifest blocks TASK_887")
	_assert(blocker_ids.has("manifest_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("manifest_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing manifest reports TASK_886 mismatch")
	_assert(blocker_ids.has("source_trace_task_mismatch"), "Missing manifest reports TASK_879 mismatch")
	_assert(blocker_ids.has("runtime_trace_schema_mismatch"), "Missing manifest reports runtime trace schema mismatch")
	_assert(blocker_ids.has("final_source_not_deeplink_final"), "Missing manifest reports final source stage mismatch")
	_assert(blocker_ids.has("post_final_capture_not_after_trace"), "Missing manifest reports capture ordering mismatch")
	_assert(blocker_ids.has("selected_process_missing"), "Missing manifest reports missing process")
	_assert(blocker_ids.has("post_final_capture_method_not_handle_print"), "Missing manifest reports capture method mismatch")
	_assert(blocker_ids.has("post_final_window_capture_not_trusted"), "Missing manifest reports untrusted capture")
	_assert(blocker_ids.has("post_final_window_screenshot_missing"), "Missing manifest reports missing screenshot")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no command")


func _test_good_manifest_passes_sync() -> void:
	var snapshot: Dictionary = SyncFix.build_snapshot(_good_manifest())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_887")
	_assert(String(snapshot.get("task_id", "")) == "TASK_887", "Snapshot task id matches TASK_887")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_886", "Snapshot links TASK_886")
	_assert(String(snapshot.get("source_trace_task_id", "")) == "TASK_879", "Snapshot links TASK_879")
	_assert(String(snapshot.get("source_hud_sync_task_id", "")) == "TASK_883", "Snapshot links TASK_883")
	_assert(String(snapshot.get("source_visible_status_task_id", "")) == "TASK_876", "Snapshot links TASK_876")
	_assert(String(snapshot.get("status", "")) == "pass", "Good manifest passes TASK_887")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good manifest has no blockers")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Good manifest has no issues")
	_assert(bool(snapshot.get("post_final_capture_after_deeplink_final", false)), "Snapshot records post-final capture ordering")
	_assert(String(snapshot.get("post_final_capture_method", "")) == "window_handle_print", "Snapshot records handle-print capture")
	_assert(bool(snapshot.get("post_final_window_capture_trusted", false)), "Snapshot records trusted post-final capture")
	_assert(bool(snapshot.get("final_source_contact_fire", false)), "Snapshot records final source CONTACT FIRE")
	_assert(bool(snapshot.get("post_final_render_contact_fire", false)), "Snapshot records post-final render CONTACT FIRE")
	_assert(bool(snapshot.get("render_frame_synced_to_final_trace", false)), "Snapshot marks frame/source synced")
	_assert(String(snapshot.get("runtime_trace_latest_stage", "")) == "deeplink_final", "Snapshot records deeplink_final")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_888")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_stale_post_final_frame_reviews() -> void:
	var manifest: Dictionary = _good_manifest()
	var review: Dictionary = Dictionary(manifest.get("post_final_render_frame_review", {}))
	review["rendered_no_fire_or_contact_pressure_first"] = true
	review["event_log_contact_fire_first"] = false
	manifest["post_final_render_frame_review"] = review
	var snapshot: Dictionary = SyncFix.build_snapshot(manifest)
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "review", "Stale post-final frame becomes review")
	_assert(not bool(snapshot.get("render_frame_synced_to_final_trace", true)), "Stale post-final frame is not synced")
	_assert(issue_ids.has("post_final_render_not_contact_fire"), "Stale frame reports render CONTACT FIRE issue")
	_assert(issue_ids.has("post_final_render_still_stale_first_reading"), "Stale frame reports stale first reading")


func _test_optional_actual_manifest() -> void:
	if not FileAccess.file_exists(SOURCE_MANIFEST_PATH):
		_assert(true, "TASK_887 manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH)
	var snapshot: Dictionary = SyncFix.build_snapshot(manifest)
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual manifest builds TASK_887 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_886", "Actual manifest links TASK_886")
	_assert(String(snapshot.get("source_trace_task_id", "")) == "TASK_879", "Actual manifest links TASK_879")
	_assert(bool(snapshot.get("read_only", false)), "Actual manifest snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual manifest snapshot sets no gameplay truth")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH) if FileAccess.file_exists(SOURCE_MANIFEST_PATH) else _good_manifest()
	var snapshot: Dictionary = SyncFix.build_snapshot(source_manifest)
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_887 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_887", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_886", "Roundtrip keeps TASK_886 link")
	_assert(bool(roundtrip.get("render_frame_synced_to_final_trace", false)), "Roundtrip keeps sync result")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_manifest() -> Dictionary:
	return {
		"schema": SCHEMA,
		"task_id": "TASK_887",
		"source_task_id": "TASK_886",
		"source_trace_task_id": "TASK_879",
		"source_hud_sync_task_id": "TASK_883",
		"source_visible_status_task_id": "TASK_876",
		"gate": "review_ready",
		"branch": "task/release-first-exchange-hud-render-frame-sync-fix",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"wait_seconds": 52,
		"source_trace_schema": TRACE_SCHEMA,
		"source_runtime_trace_schema": RUNTIME_TRACE_SCHEMA,
		"runtime_trace_written": true,
		"runtime_trace_sample_count": 10,
		"selected_process_id": 111,
		"post_final_capture_process_id": 111,
		"post_final_capture_after_deeplink_final": true,
		"post_final_window_capture_method": "window_handle_print",
		"post_final_window_capture_trusted": true,
		"post_final_window_handle_capture_succeeded": true,
		"post_final_window_screenshot_written": true,
		"post_final_desktop_screenshot_written": true,
		"post_final_window_screenshot_path": "tmp/release_first_exchange_hud_render_frame_sync_fix.png",
		"post_final_desktop_screenshot_path": "tmp/release_first_exchange_hud_render_frame_sync_fix_desktop.png",
		"hard_failures": [],
		"final_source_snapshot": {
			"source_observed_state": "FINAL_SOURCE_CONTACT_FIRE",
			"stage": "deeplink_final",
			"timestamp_msec": 72304,
			"selected_starts_contact_fire": true,
			"mission_starts_contact_fire": true,
			"event_log_contains_contact_fire": true,
			"event_log_contains_contact_pressure": false,
			"selected_fireteam_status_text": "CONTACT FIRE | FIRE player_ste>ground_pat RIFLE HIT",
			"mission_control_status_text": "CONTACT FIRE | FIRE player_ste>ground_pat RIFLE HIT",
			"event_log_short_text": "CONTACT FIRE: Feuerwechsel lesen",
		},
		"post_final_render_frame_review": {
			"frame_trace_method": "post_deeplink_final_window_handle_screenshot_manual_text_readback",
			"rendered_texts_collected": true,
			"screenshot_observed_state": "STERNENBUERGERCHEN_CONTACT_FIRE_POST_FINAL",
			"rendered_selected_fireteam_text": "#17 CONTACT FIRE | FIRE player_ste>ground_pat RIFLE FIRED/HIT",
			"rendered_mission_control_text": "#18 CONTACT FIRE | FIRE player_ste>ground_pat RIFLE FIRED/HIT",
			"rendered_event_log_text": "#19 FT1 CONTACT FIRE: Feuerwechsel lesen",
			"selected_fireteam_contact_fire_first": true,
			"mission_control_contact_fire_first": true,
			"event_log_contact_fire_first": true,
			"rendered_no_fire_or_contact_pressure_first": false,
			"contact_fire_readability_ok": true,
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
