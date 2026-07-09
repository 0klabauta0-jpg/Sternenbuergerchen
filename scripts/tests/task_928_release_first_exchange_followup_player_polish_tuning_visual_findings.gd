extends SceneTree

const Findings := preload("res://scripts/mission/release_first_exchange_followup_player_polish_tuning_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_928_release_first_exchange_followup_player_polish_tuning_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task926_in_progress_2026_07_09.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_followup_player_polish_tuning_visual_findings.gd"
const SOURCE_SNAPSHOT_PATH := "res://tmp/release_first_exchange_followup_player_polish_tuning_recapture_acceptance.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_followup_player_polish_tuning_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_followup_player_polish_tuning_visual_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_player_polish_tuning_recapture.v1"
const TUNING_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_player_polish_tuning.v1"
const TUNING_STYLE_ID := "task_926_release_first_exchange_followup_player_polish_tuning_v1"
const PLAYER_POLISH_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_world_read_player_polish.v1"
const PLAYER_POLISH_STYLE_ID := "task_923_release_first_exchange_followup_world_read_player_v1"
const SOURCE_RECAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_player_polish_recapture.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_SMOKE_TASK := "TASK_929 - Release First Exchange Playability Smoke"
const NEXT_POLISH_TASK := "TASK_929 - Release First Exchange Followup Player Polish Tuning Final Readability Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_928 Release First Exchange Followup Player Polish Tuning Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_needs_manual_review_without_notes()
	_test_findings_from_open_review()
	_test_clean_notes_accept_for_smoke()
	_test_optional_actual_snapshot()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_928_release_first_exchange_followup_player_polish_tuning_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_928_release_first_exchange_followup_player_polish_tuning_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_928 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_928 analyzer exists")
	_assert(FileAccess.file_exists(REPORT_PATH), "TASK_928 progress report exists")
	_assert(task_text.contains("Release First Exchange Followup Player Polish Tuning Visual Findings"), "Task names TASK_928")
	_assert(task_text.contains(NEXT_SMOKE_TASK), "Task names smoke follow-up")
	_assert(task_text.contains(NEXT_POLISH_TASK), "Task names final polish follow-up")
	_assert(status_text.contains("TASK_928 - Release First Exchange Followup Player Polish Tuning Visual Findings"), "Implementation status tracks TASK_928")
	_assert(roadmap_text.contains("TASK_928 - Release First Exchange Followup Player Polish Tuning Visual Findings (implementiert"), "Roadmap marks TASK_928 implemented")
	_assert(roadmap_text.contains(NEXT_SMOKE_TASK), "Roadmap names smoke follow-up")
	_assert(roadmap_text.contains(NEXT_POLISH_TASK), "Roadmap names final polish follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Followup-Player-Polish-Tuning-Visual-Findings (TASK_928)"), "Contract documents TASK_928")
	_assert(report_text.contains("TASK_928") and report_text.contains("TASK_929"), "HTML report tracks TASK_928 and TASK_929")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_928 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_928\""), "Analyzer writes TASK_928 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_927\""), "Analyzer links TASK_927")
	_assert(service_text.contains("SOURCE_TUNING_TASK_ID: String = \"TASK_926\""), "Analyzer links TASK_926")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_925\""), "Analyzer links TASK_925")
	_assert(service_text.contains("SOURCE_RECAPTURE_TASK_ID: String = \"TASK_924\""), "Analyzer links TASK_924")
	_assert(service_text.contains("SOURCE_PLAYER_POLISH_TASK_ID: String = \"TASK_923\""), "Analyzer links TASK_923")
	_assert(service_text.contains("tuning_fire_lane_not_first_world_movement"), "Analyzer names tuning fire-lane issue")
	_assert(service_text.contains("tuning_lane_not_before_fire_contact_text"), "Analyzer names lane-before-text issue")
	_assert(service_text.contains("tuning_source_target_anchors_still_weak"), "Analyzer names tuning anchor issue")
	_assert(service_text.contains("do_not_reopen_combat_truth_or_add_more_hud_text"), "Analyzer rejects combat/HUD-truth drift")
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
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_928")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports TASK_927 mismatch")
	_assert(blocker_ids.has("source_tuning_task_mismatch"), "Missing source reports TASK_926 mismatch")
	_assert(blocker_ids.has("source_findings_task_mismatch"), "Missing source reports TASK_925 mismatch")
	_assert(blocker_ids.has("source_recapture_task_mismatch"), "Missing source reports TASK_924 mismatch")
	_assert(blocker_ids.has("source_player_polish_task_mismatch"), "Missing source reports TASK_923 mismatch")
	_assert(blocker_ids.has("tuning_schema_mismatch"), "Missing source reports tuning schema mismatch")
	_assert(blocker_ids.has("tuning_style_mismatch"), "Missing source reports tuning style mismatch")
	_assert(blocker_ids.has("player_polish_schema_mismatch"), "Missing source reports player-polish schema mismatch")
	_assert(blocker_ids.has("player_polish_style_mismatch"), "Missing source reports player-polish style mismatch")
	_assert(blocker_ids.has("source_recapture_schema_mismatch"), "Missing source reports source recapture schema mismatch")
	_assert(blocker_ids.has("window_capture_method_not_handle_print"), "Missing source reports capture method mismatch")
	_assert(blocker_ids.has("window_capture_not_trusted"), "Missing source reports untrusted capture")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_needs_manual_review_without_notes() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_source_snapshot(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_manual_review", "Good TASK_927 source still needs manual review")
	_assert(bool(snapshot.get("review_ready", false)), "Good TASK_927 source is review-ready")
	_assert(not bool(snapshot.get("accepted", true)), "Good TASK_927 source is not accepted without notes")
	_assert(issue_ids.has("manual_visual_review_missing"), "Missing notes report manual review issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_POLISH_TASK, "Open review does not unlock smoke")


func _test_findings_from_open_review() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_source_snapshot(), _review_notes_with_issues())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var positive_ids: Array = _issue_ids(Array(snapshot.get("positive_findings", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_928")
	_assert(String(snapshot.get("task_id", "")) == "TASK_928", "Snapshot task id matches TASK_928")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_927", "Snapshot links TASK_927")
	_assert(String(snapshot.get("source_tuning_task_id", "")) == "TASK_926", "Snapshot links TASK_926")
	_assert(String(snapshot.get("source_findings_task_id", "")) == "TASK_925", "Snapshot links TASK_925")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_924", "Snapshot links TASK_924")
	_assert(String(snapshot.get("source_player_polish_task_id", "")) == "TASK_923", "Snapshot links TASK_923")
	_assert(String(snapshot.get("status", "")) == "ready_for_followup_player_polish_tuning_final_readability_polish", "Findings recommend final readability polish")
	_assert(bool(snapshot.get("review_ready", false)), "Snapshot is review-ready")
	_assert(not bool(snapshot.get("accepted", true)), "Open review is not accepted")
	_assert(bool(snapshot.get("final_source_contact_fire", false)), "Snapshot records final source CONTACT FIRE")
	_assert(bool(snapshot.get("manual_visual_review_done", false)), "Snapshot records manual review")
	_assert(not bool(snapshot.get("player_readability_ok", true)), "Snapshot does not accept readability")
	_assert(positive_ids.has("final_source_contact_fire_clean"), "Snapshot keeps source positive")
	_assert(positive_ids.has("trusted_window_handle_capture"), "Snapshot keeps trusted capture positive")
	_assert(positive_ids.has("task_926_tuning_style_present"), "Snapshot records TASK_926 style")
	_assert(positive_ids.has("task_923_player_polish_style_present"), "Snapshot records TASK_923 style")
	_assert(positive_ids.has("contact_fire_hud_surfaces_present"), "Snapshot records CONTACT FIRE surfaces")
	_assert(positive_ids.has("tuning_visible"), "Snapshot records visible TASK_926 tuning")
	_assert(issue_ids.has("tuning_fire_lane_not_first_world_movement"), "Snapshot records tuning fire-lane issue")
	_assert(issue_ids.has("tuning_lane_not_before_fire_contact_text"), "Snapshot records lane-before-text issue")
	_assert(issue_ids.has("tuning_source_target_anchors_still_weak"), "Snapshot records tuning anchor issue")
	_assert(issue_ids.has("tuning_label_halo_still_competes"), "Snapshot records tuning label/halo issue")
	_assert(issue_ids.has("bottom_hud_still_dense_for_first_fire_read"), "Snapshot records bottom HUD issue")
	_assert(String(snapshot.get("primary_issue_id", "")) == "tuning_fire_lane_not_first_world_movement", "Tuning fire-lane issue is primary")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_POLISH_TASK, "Snapshot recommends final polish")
	_assert(String(snapshot.get("recommended_direction", "")) == "move_to_playability_smoke_if_accepted_else_final_readability_polish", "Snapshot recommends bounded next decision")
	_assert(String(snapshot.get("avoid_next_action", "")) == "do_not_reopen_combat_truth_or_add_more_hud_text", "Snapshot rejects truth drift")
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
	notes["tuning_fire_lane_is_first_world_movement"] = true
	notes["tuning_lane_reads_before_fire_contact_text"] = true
	notes["tuning_source_target_anchors_carry_direction"] = true
	notes["tuning_world_fire_label_stays_behind_lane"] = true
	notes["tuning_target_halo_stays_behind_lane"] = true
	notes["tuning_grid_world_noise_not_competing"] = true
	notes["tuning_fire_lane_not_first_world_movement"] = false
	notes["tuning_lane_not_before_fire_contact_text"] = false
	notes["tuning_source_target_anchors_still_weak"] = false
	notes["tuning_label_halo_still_competes"] = false
	notes["tuning_grid_world_noise_still_competes"] = false
	notes["bottom_hud_still_dense_for_first_fire_read"] = false
	var snapshot: Dictionary = Findings.build_snapshot(_good_source_snapshot(), notes)
	_assert(String(snapshot.get("status", "")) == "accepted_for_first_exchange_playability_smoke", "Clean notes accept for playability smoke")
	_assert(bool(snapshot.get("accepted", false)), "Clean notes set accepted flag")
	_assert(bool(snapshot.get("player_readability_ok", false)), "Clean notes mark player readability OK")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_SMOKE_TASK, "Clean notes recommend playability smoke")


func _test_optional_actual_snapshot() -> void:
	if not FileAccess.file_exists(SOURCE_SNAPSHOT_PATH):
		_assert(true, "TASK_927 source snapshot is optional before local capture")
		return
	var source_snapshot: Dictionary = _read_json_dict(SOURCE_SNAPSHOT_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(source_snapshot, {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual source builds TASK_928 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_927", "Actual source links TASK_927")
	_assert(String(snapshot.get("source_tuning_task_id", "")) == "TASK_926", "Actual source links TASK_926")
	_assert(bool(snapshot.get("read_only", false)), "Actual source snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual source snapshot sets no gameplay truth")


func _test_manifest_roundtrip() -> void:
	var source_snapshot: Dictionary = _read_json_dict(SOURCE_SNAPSHOT_PATH) if FileAccess.file_exists(SOURCE_SNAPSHOT_PATH) else _good_source_snapshot()
	var snapshot: Dictionary = Findings.build_snapshot(source_snapshot, _review_notes_with_issues())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_928 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_928", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_927", "Roundtrip keeps TASK_927 link")
	_assert(String(roundtrip.get("source_tuning_task_id", "")) == "TASK_926", "Roundtrip keeps TASK_926 link")
	_assert(String(roundtrip.get("status", "")) == "ready_for_followup_player_polish_tuning_final_readability_polish", "Roundtrip keeps findings status")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "tuning_fire_lane_not_first_world_movement", "Roundtrip keeps primary issue")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_POLISH_TASK, "Roundtrip keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_source_snapshot() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_927",
		"source_task_id": "TASK_926",
		"source_findings_task_id": "TASK_925",
		"source_recapture_task_id": "TASK_924",
		"source_player_polish_task_id": "TASK_923",
		"status": "review_ready",
		"review_ready": true,
		"accepted": false,
		"gate": "review_ready",
		"branch": "task/release-first-exchange-player-readability-polish-review",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"expected_tuning_schema": TUNING_SCHEMA,
		"expected_tuning_style_id": TUNING_STYLE_ID,
		"expected_player_polish_schema": PLAYER_POLISH_SCHEMA,
		"expected_player_polish_style_id": PLAYER_POLISH_STYLE_ID,
		"source_recapture_schema": SOURCE_RECAPTURE_SCHEMA,
		"source_recapture_gate": "review_ready",
		"post_player_polish_tuning_capture_after_deeplink_final": true,
		"post_player_polish_tuning_capture_method": "window_handle_print",
		"post_player_polish_tuning_window_capture_trusted": true,
		"post_player_polish_tuning_window_screenshot_path": "tmp/release_first_exchange_followup_player_polish_tuning_recapture.png",
		"post_player_polish_tuning_desktop_screenshot_path": "tmp/release_first_exchange_followup_player_polish_tuning_recapture_desktop.png",
		"final_source_contact_fire": true,
		"final_source_snapshot": {
			"source_observed_state": "FINAL_SOURCE_CONTACT_FIRE",
			"stage": "deeplink_final",
			"selected_starts_contact_fire": true,
			"mission_starts_contact_fire": true,
			"event_log_contains_contact_fire": true,
			"event_log_contains_contact_pressure": false,
		},
		"post_player_polish_tuning_world_read_render_review": {
			"frame_trace_method": "post_deeplink_final_window_handle_screenshot_followup_player_polish_tuning_review_required",
			"screenshot_observed_state": "TASK_927_REVIEW_REQUIRED",
			"expected_tuning_schema": TUNING_SCHEMA,
			"expected_tuning_style_id": TUNING_STYLE_ID,
			"expected_fire_lane_is_first_world_movement": true,
			"expected_fire_lane_reads_before_fire_contact_text": true,
		},
	}


func _review_notes_with_issues() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"observed_window_state": "CONTACT_FIRE_VISIBLE_TUNING_STILL_NEEDS_FINAL_READABILITY_POLISH",
		"review_screenshot_path": "tmp/release_first_exchange_followup_player_polish_tuning_recapture.png",
		"player_readability_ok": false,
		"contact_fire_hud_surfaces_present": true,
		"event_log_contact_fire_visible": true,
		"tuning_visible": true,
		"tuning_fire_lane_is_first_world_movement": false,
		"tuning_lane_reads_before_fire_contact_text": false,
		"tuning_source_target_anchors_carry_direction": false,
		"tuning_world_fire_label_stays_behind_lane": false,
		"tuning_target_halo_stays_behind_lane": false,
		"tuning_grid_world_noise_not_competing": true,
		"command_surfaces_still_usable": true,
		"tuning_fire_lane_not_first_world_movement": true,
		"tuning_lane_not_before_fire_contact_text": true,
		"tuning_source_target_anchors_still_weak": true,
		"tuning_label_halo_still_competes": true,
		"tuning_grid_world_noise_still_competes": false,
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
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


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
