extends SceneTree

const Review := preload("res://scripts/mission/release_first_exchange_player_readability_polish_review.gd")

const TASK_PATH := "res://docs/tasks/TASK_888_release_first_exchange_player_readability_polish_review.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_player_readability_polish_review.gd"
const SOURCE_MANIFEST_PATH := "res://tmp/release_first_exchange_hud_render_frame_sync_fix.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_player_readability_polish_review.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_player_readability_polish_review.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_exchange_hud_render_frame_sync_fix.v1"
const TRACE_SCHEMA := "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const RUNTIME_TRACE_SCHEMA := "sternenbuergerchen.release_first_exchange_exported_status_source_trace_runtime.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_889 - Release First Exchange HUD Density And Fire Visual Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_888 Release First Exchange Player Readability Polish Review ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_synced_frame_builds_readability_findings()
	_test_clean_readability_can_be_accepted()
	_test_optional_actual_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_888_release_first_exchange_player_readability_polish_review: FAILED")
		quit(1)
		return
	print("TASK_888_release_first_exchange_player_readability_polish_review: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_888 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_888 analyzer exists")
	_assert(task_text.contains("Release First Exchange Player Readability Polish Review"), "Task names TASK_888")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_889 follow-up")
	_assert(status_text.contains("TASK_888 - Release First Exchange Player Readability Polish Review"), "Implementation status tracks TASK_888")
	_assert(roadmap_text.contains("TASK_888 - Release First Exchange Player Readability Polish Review (implementiert)"), "Roadmap marks TASK_888 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_889 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Player-Readability-Polish-Review (TASK_888)"), "Contract documents TASK_888")
	_assert(report_text.contains("TASK_888") and report_text.contains("TASK_889"), "HTML report tracks TASK_888 and TASK_889")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_888 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_888\""), "Analyzer writes TASK_888 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_887\""), "Analyzer links TASK_887")
	_assert(service_text.contains("SOURCE_RENDER_TRACE_TASK_ID: String = \"TASK_886\""), "Analyzer links TASK_886")
	_assert(service_text.contains("SOURCE_TRACE_TASK_ID: String = \"TASK_879\""), "Analyzer links TASK_879")
	_assert(service_text.contains("\"bottom_hud_density_high\""), "Analyzer names bottom HUD density issue")
	_assert(service_text.contains("\"mission_control_text_clipped\""), "Analyzer names Mission Control clipping issue")
	_assert(service_text.contains("\"event_log_overlay_too_small\""), "Analyzer names Event Log readability issue")
	_assert(service_text.contains("\"world_fire_trace_too_subtle\""), "Analyzer names FireTrace subtlety issue")
	_assert(service_text.contains("\"selected_fireteam_member_cards_crowd_status\""), "Analyzer names member-card crowding issue")
	_assert(service_text.contains("polish_hud_density_event_log_and_fire_visual_hierarchy"), "Analyzer recommends visual hierarchy polish")
	_assert(service_text.contains("do_not_reopen_combat_truth_or_add_new_hud_state"), "Analyzer rejects reopening combat truth")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = Review.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source manifest blocks TASK_888")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing manifest reports source schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing manifest reports TASK_887 mismatch")
	_assert(blocker_ids.has("source_render_trace_task_mismatch"), "Missing manifest reports TASK_886 mismatch")
	_assert(blocker_ids.has("source_trace_task_mismatch"), "Missing manifest reports TASK_879 mismatch")
	_assert(blocker_ids.has("source_hud_sync_task_mismatch"), "Missing manifest reports TASK_883 mismatch")
	_assert(blocker_ids.has("source_visible_status_task_mismatch"), "Missing manifest reports TASK_876 mismatch")
	_assert(blocker_ids.has("source_trace_schema_mismatch"), "Missing manifest reports trace schema mismatch")
	_assert(blocker_ids.has("runtime_trace_schema_mismatch"), "Missing manifest reports runtime trace schema mismatch")
	_assert(blocker_ids.has("launch_argument_mismatch"), "Missing manifest reports launch argument")
	_assert(blocker_ids.has("post_final_capture_not_after_trace"), "Missing manifest reports post-final ordering")
	_assert(blocker_ids.has("post_final_capture_method_not_handle_print"), "Missing manifest reports capture method")
	_assert(blocker_ids.has("post_final_window_capture_not_trusted"), "Missing manifest reports untrusted capture")
	_assert(blocker_ids.has("post_final_window_screenshot_missing"), "Missing manifest reports missing screenshot")
	_assert(blocker_ids.has("final_source_not_deeplink_final"), "Missing manifest reports final source stage")
	_assert(blocker_ids.has("post_final_render_texts_missing"), "Missing manifest reports render readback")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_synced_frame_builds_readability_findings() -> void:
	var snapshot: Dictionary = Review.build_snapshot(_good_source_manifest(), _review_notes_with_issues())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var positive_ids: Array = _issue_ids(Array(snapshot.get("positive_findings", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_888")
	_assert(String(snapshot.get("task_id", "")) == "TASK_888", "Snapshot task id matches TASK_888")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_887", "Snapshot links TASK_887")
	_assert(String(snapshot.get("source_render_trace_task_id", "")) == "TASK_886", "Snapshot links TASK_886")
	_assert(String(snapshot.get("source_trace_task_id", "")) == "TASK_879", "Snapshot links TASK_879")
	_assert(String(snapshot.get("source_hud_sync_task_id", "")) == "TASK_883", "Snapshot links TASK_883")
	_assert(String(snapshot.get("source_visible_status_task_id", "")) == "TASK_876", "Snapshot links TASK_876")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_887 schema")
	_assert(String(snapshot.get("source_gate", "")) == "review_ready", "Snapshot records review-ready source")
	_assert(bool(snapshot.get("post_final_capture_after_deeplink_final", false)), "Snapshot records post-final capture ordering")
	_assert(String(snapshot.get("post_final_capture_method", "")) == "window_handle_print", "Snapshot records window-handle capture")
	_assert(bool(snapshot.get("post_final_window_capture_trusted", false)), "Snapshot records trusted capture")
	_assert(bool(snapshot.get("final_source_contact_fire", false)), "Snapshot records final CONTACT FIRE source")
	_assert(bool(snapshot.get("post_final_render_contact_fire", false)), "Snapshot records rendered CONTACT FIRE")
	_assert(bool(snapshot.get("technical_contact_fire_frame_ok", false)), "Snapshot marks technical frame OK")
	_assert(bool(snapshot.get("manual_visual_review_done", false)), "Snapshot records manual review")
	_assert(not bool(snapshot.get("player_readability_ok", true)), "Snapshot keeps player readability not OK")
	_assert(String(snapshot.get("status", "")) == "ready_for_visual_polish", "Density issues produce visual-polish status")
	_assert(positive_ids.has("final_source_contact_fire_clean"), "Snapshot keeps source positive")
	_assert(positive_ids.has("post_final_window_contact_fire_visible"), "Snapshot keeps render positive")
	_assert(positive_ids.has("event_log_contact_fire_visible"), "Snapshot keeps event-log positive")
	_assert(positive_ids.has("fire_trace_or_impact_visible"), "Snapshot keeps fire visual positive")
	_assert(issue_ids.has("bottom_hud_density_high"), "Snapshot records bottom HUD density")
	_assert(issue_ids.has("mission_control_text_clipped"), "Snapshot records Mission Control clipping")
	_assert(issue_ids.has("event_log_overlay_too_small"), "Snapshot records Event Log issue")
	_assert(issue_ids.has("world_fire_trace_too_subtle"), "Snapshot records FireTrace subtlety")
	_assert(issue_ids.has("selected_fireteam_member_cards_crowd_status"), "Snapshot records member-card crowding")
	_assert(issue_ids.has("next_grip_competes_with_combat_text"), "Snapshot records next-grip competition")
	_assert(String(snapshot.get("primary_issue_id", "")) == "bottom_hud_density_high", "Bottom HUD density is primary issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_889")
	_assert(String(snapshot.get("recommended_direction", "")) == "polish_hud_density_event_log_and_fire_visual_hierarchy", "Snapshot recommends visual hierarchy polish")
	_assert(String(snapshot.get("avoid_next_action", "")) == "do_not_reopen_combat_truth_or_add_new_hud_state", "Snapshot rejects reopening combat truth")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_clean_readability_can_be_accepted() -> void:
	var notes: Dictionary = _review_notes_with_issues()
	notes["player_readability_ok"] = true
	notes["bottom_hud_density_high"] = false
	notes["mission_control_text_clipped"] = false
	notes["event_log_overlay_too_small"] = false
	notes["world_fire_trace_too_subtle"] = false
	notes["selected_fireteam_member_cards_crowd_status"] = false
	notes["next_grip_competes_with_combat_text"] = false
	var snapshot: Dictionary = Review.build_snapshot(_good_source_manifest(), notes)
	_assert(String(snapshot.get("status", "")) == "accepted_for_next_release_smoke", "Clean notes can accept readability")
	_assert(bool(snapshot.get("player_readability_ok", false)), "Clean notes mark player readability OK")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Clean notes still keep TASK_889 as optional polish next")


func _test_optional_actual_manifest() -> void:
	if not FileAccess.file_exists(SOURCE_MANIFEST_PATH):
		_assert(true, "TASK_887 source manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH)
	var snapshot: Dictionary = Review.build_snapshot(manifest, _review_notes_with_issues())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual manifest builds TASK_888 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_887", "Actual manifest links TASK_887")
	_assert(bool(snapshot.get("technical_contact_fire_frame_ok", false)), "Actual manifest keeps technical CONTACT FIRE frame")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual manifest recommends TASK_889")
	_assert(bool(snapshot.get("read_only", false)), "Actual manifest snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual manifest snapshot sets no gameplay truth")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH) if FileAccess.file_exists(SOURCE_MANIFEST_PATH) else _good_source_manifest()
	var snapshot: Dictionary = Review.build_snapshot(source_manifest, _review_notes_with_issues())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_888 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_888", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_887", "Roundtrip keeps TASK_887 link")
	_assert(String(roundtrip.get("status", "")) == "ready_for_visual_polish", "Roundtrip keeps visual-polish status")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "bottom_hud_density_high", "Roundtrip keeps primary issue")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_source_manifest() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_887",
		"source_task_id": "TASK_886",
		"source_trace_task_id": "TASK_879",
		"source_hud_sync_task_id": "TASK_883",
		"source_visible_status_task_id": "TASK_876",
		"gate": "review_ready",
		"branch": "task/release-first-exchange-hud-render-frame-sync-fix",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"source_trace_schema": TRACE_SCHEMA,
		"source_runtime_trace_schema": RUNTIME_TRACE_SCHEMA,
		"runtime_trace_sample_count": 10,
		"post_final_capture_after_deeplink_final": true,
		"post_final_window_capture_method": "window_handle_print",
		"post_final_window_capture_trusted": true,
		"post_final_window_screenshot_written": true,
		"post_final_window_screenshot_path": "tmp/release_first_exchange_hud_render_frame_sync_fix.png",
		"post_final_desktop_screenshot_path": "tmp/release_first_exchange_hud_render_frame_sync_fix_desktop.png",
		"hard_failures": [],
		"final_source_snapshot": {
			"source_observed_state": "FINAL_SOURCE_CONTACT_FIRE",
			"stage": "deeplink_final",
			"selected_starts_contact_fire": true,
			"mission_starts_contact_fire": true,
			"event_log_contains_contact_fire": true,
			"event_log_contains_contact_pressure": false,
		},
		"post_final_render_frame_review": {
			"rendered_texts_collected": true,
			"screenshot_observed_state": "STERNENBUERGERCHEN_CONTACT_FIRE_POST_FINAL",
			"selected_fireteam_contact_fire_first": true,
			"mission_control_contact_fire_first": true,
			"event_log_contact_fire_first": true,
			"rendered_no_fire_or_contact_pressure_first": false,
		},
	}


func _review_notes_with_issues() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"observed_window_state": "STERNENBUERGERCHEN_CONTACT_FIRE_POST_FINAL_DENSE",
		"review_screenshot_path": "tmp/release_first_exchange_hud_render_frame_sync_fix.png",
		"player_readability_ok": false,
		"contact_fire_hud_surfaces_present": true,
		"event_log_contact_fire_visible": true,
		"world_fire_contact_labels_present": true,
		"fire_trace_or_impact_visible": true,
		"target_focus_visible": true,
		"command_surfaces_still_usable": true,
		"bottom_hud_density_high": true,
		"mission_control_text_clipped": true,
		"event_log_overlay_too_small": true,
		"world_fire_trace_too_subtle": true,
		"selected_fireteam_member_cards_crowd_status": true,
		"next_grip_competes_with_combat_text": true,
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
