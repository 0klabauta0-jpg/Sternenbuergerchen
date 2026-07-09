extends SceneTree

const Findings := preload("res://scripts/mission/release_first_exchange_final_world_read_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_918_release_first_exchange_final_world_read_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_final_world_read_visual_findings.gd"
const SOURCE_SNAPSHOT_PATH := "res://tmp/release_first_exchange_final_world_read_recapture_acceptance.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_final_world_read_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_final_world_read_visual_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_exchange_final_world_read_recapture.v1"
const FINAL_SCHEMA := "sternenbuergerchen.release_first_exchange_fire_lane_world_read_final_polish.v1"
const FINAL_STYLE_ID := "task_916_release_first_exchange_fire_lane_world_read_final_v1"
const ACCEPTANCE_SCHEMA := "sternenbuergerchen.release_first_exchange_fire_lane_world_read_acceptance_polish.v1"
const ACCEPTANCE_STYLE_ID := "task_913_release_first_exchange_fire_lane_world_read_acceptance_v1"
const SOURCE_RECAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_fire_lane_world_read_acceptance_recapture.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_SMOKE_TASK := "TASK_919 - Release First Exchange Playability Smoke"
const NEXT_FIX_TASK := "TASK_919 - Release First Exchange Final World Read Followup Fix"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_918 Release First Exchange Final World Read Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_findings_from_open_review()
	_test_clean_notes_accept_for_smoke()
	_test_optional_actual_snapshot()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_918_release_first_exchange_final_world_read_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_918_release_first_exchange_final_world_read_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_918 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_918 analyzer exists")
	_assert(task_text.contains("Release First Exchange Final World Read Visual Findings"), "Task names TASK_918")
	_assert(task_text.contains(NEXT_SMOKE_TASK), "Task names smoke follow-up")
	_assert(task_text.contains(NEXT_FIX_TASK), "Task names followup fix")
	_assert(status_text.contains("TASK_918 - Release First Exchange Final World Read Visual Findings"), "Implementation status tracks TASK_918")
	_assert(roadmap_text.contains("TASK_918 - Release First Exchange Final World Read Visual Findings (implementiert"), "Roadmap marks TASK_918 implemented")
	_assert(roadmap_text.contains(NEXT_SMOKE_TASK), "Roadmap names TASK_919 smoke follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Final-World-Read-Visual-Findings (TASK_918)"), "Contract documents TASK_918")
	_assert(report_text.contains("TASK_918") and report_text.contains("TASK_919"), "HTML report tracks TASK_918 and TASK_919")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_918 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_918\""), "Analyzer writes TASK_918 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_917\""), "Analyzer links TASK_917")
	_assert(service_text.contains("SOURCE_FINAL_TASK_ID: String = \"TASK_916\""), "Analyzer links TASK_916")
	_assert(service_text.contains("SOURCE_RECAPTURE_TASK_ID: String = \"TASK_914\""), "Analyzer links TASK_914")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_915\""), "Analyzer links TASK_915")
	_assert(service_text.contains("SOURCE_ACCEPTANCE_TASK_ID: String = \"TASK_913\""), "Analyzer links TASK_913")
	_assert(service_text.contains("fire_lane_not_first_world_movement_after_final_polish"), "Analyzer names final fire-lane issue")
	_assert(service_text.contains("source_target_anchors_still_not_carrying_direction_after_final_polish"), "Analyzer names final anchor issue")
	_assert(service_text.contains("label_halo_still_competes_after_final_polish"), "Analyzer names final label/halo issue")
	_assert(service_text.contains("do_not_polish_without_task_917_screenshot_evidence"), "Analyzer rejects unproven polish")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "Analyzer updates no shortcuts")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_918")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports TASK_917 mismatch")
	_assert(blocker_ids.has("source_final_task_mismatch"), "Missing source reports TASK_916 mismatch")
	_assert(blocker_ids.has("source_recapture_task_mismatch"), "Missing source reports TASK_914 mismatch")
	_assert(blocker_ids.has("source_findings_task_mismatch"), "Missing source reports TASK_915 mismatch")
	_assert(blocker_ids.has("source_acceptance_task_mismatch"), "Missing source reports TASK_913 mismatch")
	_assert(blocker_ids.has("final_schema_mismatch"), "Missing source reports TASK_916 schema mismatch")
	_assert(blocker_ids.has("final_style_mismatch"), "Missing source reports TASK_916 style mismatch")
	_assert(blocker_ids.has("acceptance_schema_mismatch"), "Missing source reports TASK_913 schema mismatch")
	_assert(blocker_ids.has("acceptance_style_mismatch"), "Missing source reports TASK_913 style mismatch")
	_assert(blocker_ids.has("source_recapture_schema_mismatch"), "Missing source reports TASK_914 schema mismatch")
	_assert(blocker_ids.has("window_capture_method_not_handle_print"), "Missing source reports capture method mismatch")
	_assert(blocker_ids.has("window_capture_not_trusted"), "Missing source reports untrusted capture")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_findings_from_open_review() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_source_snapshot(), _review_notes_with_issues())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var positive_ids: Array = _issue_ids(Array(snapshot.get("positive_findings", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_918")
	_assert(String(snapshot.get("task_id", "")) == "TASK_918", "Snapshot task id matches TASK_918")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_917", "Snapshot links TASK_917")
	_assert(String(snapshot.get("source_final_task_id", "")) == "TASK_916", "Snapshot links TASK_916")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_914", "Snapshot links TASK_914")
	_assert(String(snapshot.get("source_findings_task_id", "")) == "TASK_915", "Snapshot links TASK_915")
	_assert(String(snapshot.get("source_acceptance_task_id", "")) == "TASK_913", "Snapshot links TASK_913")
	_assert(String(snapshot.get("status", "")) == "ready_for_final_world_read_followup_fix", "Findings recommend followup fix")
	_assert(bool(snapshot.get("final_source_contact_fire", false)), "Snapshot records final source CONTACT FIRE")
	_assert(bool(snapshot.get("manual_visual_review_done", false)), "Snapshot records manual review")
	_assert(not bool(snapshot.get("player_readability_ok", true)), "Snapshot does not accept readability")
	_assert(positive_ids.has("final_source_contact_fire_clean"), "Snapshot keeps source positive")
	_assert(positive_ids.has("trusted_window_handle_capture"), "Snapshot keeps trusted capture positive")
	_assert(positive_ids.has("task_916_final_style_present"), "Snapshot records TASK_916 style")
	_assert(positive_ids.has("task_913_acceptance_style_present"), "Snapshot records TASK_913 style")
	_assert(positive_ids.has("contact_fire_hud_surfaces_present"), "Snapshot records CONTACT FIRE surfaces")
	_assert(positive_ids.has("final_polish_visible"), "Snapshot records visible TASK_916 polish")
	_assert(issue_ids.has("fire_lane_not_first_world_movement_after_final_polish"), "Snapshot records final fire-lane issue")
	_assert(issue_ids.has("source_target_anchors_still_not_carrying_direction_after_final_polish"), "Snapshot records final anchor direction issue")
	_assert(issue_ids.has("label_halo_still_competes_after_final_polish"), "Snapshot records final label/halo issue")
	_assert(issue_ids.has("bottom_hud_still_dense_for_first_fire_read"), "Snapshot records bottom HUD issue")
	_assert(String(snapshot.get("primary_issue_id", "")) == "fire_lane_not_first_world_movement_after_final_polish", "Fire-lane issue is primary")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_FIX_TASK, "Snapshot recommends followup fix")
	_assert(String(snapshot.get("recommended_direction", "")) == "move_to_playability_smoke_if_accepted_else_final_world_read_followup_fix", "Snapshot recommends bounded next decision")
	_assert(String(snapshot.get("avoid_next_action", "")) == "do_not_polish_without_task_917_screenshot_evidence", "Snapshot rejects unproven polish")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_clean_notes_accept_for_smoke() -> void:
	var notes: Dictionary = _review_notes_with_issues()
	notes["player_readability_ok"] = true
	notes["fire_lane_is_first_world_movement"] = true
	notes["source_target_anchors_carry_direction"] = true
	notes["world_fire_label_stays_behind_lane"] = true
	notes["target_halo_stays_behind_lane"] = true
	notes["fire_lane_not_first_world_movement_after_final_polish"] = false
	notes["source_target_anchors_still_not_carrying_direction_after_final_polish"] = false
	notes["label_halo_still_competes_after_final_polish"] = false
	notes["bottom_hud_still_dense_for_first_fire_read"] = false
	var snapshot: Dictionary = Findings.build_snapshot(_good_source_snapshot(), notes)
	_assert(String(snapshot.get("status", "")) == "accepted_for_first_exchange_playability_smoke", "Clean notes accept for playability smoke")
	_assert(bool(snapshot.get("player_readability_ok", false)), "Clean notes mark player readability OK")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_SMOKE_TASK, "Clean notes recommend playability smoke")


func _test_optional_actual_snapshot() -> void:
	if not FileAccess.file_exists(SOURCE_SNAPSHOT_PATH):
		_assert(true, "TASK_917 source snapshot is optional before local capture")
		return
	var source_snapshot: Dictionary = _read_json_dict(SOURCE_SNAPSHOT_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(source_snapshot, {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual source builds TASK_918 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_917", "Actual source links TASK_917")
	_assert(String(snapshot.get("source_final_task_id", "")) == "TASK_916", "Actual source links TASK_916")
	_assert(bool(snapshot.get("read_only", false)), "Actual source snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual source snapshot sets no gameplay truth")


func _test_manifest_roundtrip() -> void:
	var source_snapshot: Dictionary = _read_json_dict(SOURCE_SNAPSHOT_PATH) if FileAccess.file_exists(SOURCE_SNAPSHOT_PATH) else _good_source_snapshot()
	var snapshot: Dictionary = Findings.build_snapshot(source_snapshot, _review_notes_with_issues())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_918 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_918", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_917", "Roundtrip keeps TASK_917 link")
	_assert(String(roundtrip.get("source_final_task_id", "")) == "TASK_916", "Roundtrip keeps TASK_916 link")
	_assert(String(roundtrip.get("status", "")) == "ready_for_final_world_read_followup_fix", "Roundtrip keeps findings status")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "fire_lane_not_first_world_movement_after_final_polish", "Roundtrip keeps primary issue")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_FIX_TASK, "Roundtrip keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_source_snapshot() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_917",
		"source_task_id": "TASK_916",
		"source_recapture_task_id": "TASK_914",
		"source_findings_task_id": "TASK_915",
		"source_acceptance_task_id": "TASK_913",
		"status": "review_ready",
		"review_ready": true,
		"accepted": false,
		"gate": "review_ready",
		"branch": "task/release-first-exchange-player-readability-polish-review",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"expected_final_schema": FINAL_SCHEMA,
		"expected_final_style_id": FINAL_STYLE_ID,
		"expected_acceptance_schema": ACCEPTANCE_SCHEMA,
		"expected_acceptance_style_id": ACCEPTANCE_STYLE_ID,
		"source_recapture_schema": SOURCE_RECAPTURE_SCHEMA,
		"source_recapture_gate": "review_ready",
		"post_final_capture_after_deeplink_final": true,
		"post_final_capture_method": "window_handle_print",
		"post_final_window_capture_trusted": true,
		"post_final_window_screenshot_path": "tmp/release_first_exchange_final_world_read_recapture.png",
		"post_final_desktop_screenshot_path": "tmp/release_first_exchange_final_world_read_recapture_desktop.png",
		"final_source_snapshot": {
			"source_observed_state": "FINAL_SOURCE_CONTACT_FIRE",
			"stage": "deeplink_final",
			"selected_starts_contact_fire": true,
			"mission_starts_contact_fire": true,
			"event_log_contains_contact_fire": true,
			"event_log_contains_contact_pressure": false,
		},
		"post_final_fire_lane_world_read_final_render_review": {
			"frame_trace_method": "post_deeplink_final_window_handle_screenshot_final_world_read_review_required",
			"screenshot_observed_state": "TASK_917_REVIEW_REQUIRED",
			"expected_final_schema": FINAL_SCHEMA,
			"expected_final_style_id": FINAL_STYLE_ID,
			"expected_fire_lane_is_first_world_movement": true,
			"expected_source_target_anchors_carry_direction": true,
		},
	}


func _review_notes_with_issues() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"observed_window_state": "CONTACT_FIRE_VISIBLE_FINAL_WORLD_READ_STILL_NEEDS_FOLLOWUP",
		"review_screenshot_path": "tmp/release_first_exchange_final_world_read_recapture.png",
		"player_readability_ok": false,
		"contact_fire_hud_surfaces_present": true,
		"event_log_contact_fire_visible": true,
		"final_polish_visible": true,
		"fire_lane_is_first_world_movement": false,
		"source_target_anchors_carry_direction": false,
		"world_fire_label_stays_behind_lane": false,
		"target_halo_stays_behind_lane": false,
		"grid_world_noise_not_competing": true,
		"command_surfaces_still_usable": true,
		"fire_lane_not_first_world_movement_after_final_polish": true,
		"source_target_anchors_still_not_carrying_direction_after_final_polish": true,
		"label_halo_still_competes_after_final_polish": true,
		"bottom_hud_still_dense_for_first_fire_read": true,
	}


func _issue_ids(issues: Array) -> Array:
	var ids: Array = []
	for issue_variant in issues:
		ids.append(String(Dictionary(issue_variant).get("id", "")))
	return ids


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if parsed is Dictionary else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
