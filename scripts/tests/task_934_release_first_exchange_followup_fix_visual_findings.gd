extends SceneTree

const Findings := preload("res://scripts/mission/release_first_exchange_followup_fix_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_934_release_first_exchange_followup_fix_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task932_ausblick_2026_07_09.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_followup_fix_visual_findings.gd"
const SOURCE_SNAPSHOT_PATH := "res://tmp/release_first_exchange_followup_fix_recapture_acceptance.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_followup_fix_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_visual_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_recapture.v1"
const FOLLOWUP_FIX_SCHEMA := "sternenbuergerchen.release_first_exchange_final_readability_followup_fix.v1"
const FOLLOWUP_FIX_STYLE_ID := "task_932_release_first_exchange_final_readability_followup_v1"
const FINDINGS_SCHEMA := "sternenbuergerchen.release_first_exchange_final_readability_visual_findings.v1"
const FINAL_READABILITY_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_player_polish_tuning_final_readability_polish.v1"
const FINAL_READABILITY_STYLE_ID := "task_929_release_first_exchange_followup_player_polish_tuning_final_readability_v1"
const SOURCE_RECAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_final_readability_recapture.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_SMOKE_TASK := "TASK_935 - Release First Exchange Playability Smoke"
const NEXT_FIX_TASK := "TASK_935 - Release First Exchange Followup Fix Player Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_934 Release First Exchange Followup Fix Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_needs_manual_review_without_notes()
	_test_findings_from_open_review()
	_test_clean_notes_accept_for_smoke()
	_test_optional_actual_snapshot()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_934_release_first_exchange_followup_fix_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_934_release_first_exchange_followup_fix_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_934 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_934 analyzer exists")
	_assert(FileAccess.file_exists(REPORT_PATH), "TASK_934 progress report exists")
	_assert(task_text.contains("Release First Exchange Followup Fix Visual Findings"), "Task names TASK_934")
	_assert(task_text.contains(NEXT_SMOKE_TASK), "Task names smoke follow-up")
	_assert(task_text.contains(NEXT_FIX_TASK), "Task names follow-up polish")
	_assert(status_text.contains("TASK_934 - Release First Exchange Followup Fix Visual Findings"), "Implementation status tracks TASK_934")
	_assert(roadmap_text.contains("TASK_934 - Release First Exchange Followup Fix Visual Findings (implementiert"), "Roadmap marks TASK_934 implemented")
	_assert(roadmap_text.contains(NEXT_SMOKE_TASK), "Roadmap names smoke follow-up")
	_assert(roadmap_text.contains(NEXT_FIX_TASK), "Roadmap names follow-up polish")
	_assert(contract_text.contains("Release-First-Exchange-Followup-Fix-Visual-Findings (TASK_934)"), "Contract documents TASK_934")
	_assert(report_text.contains("TASK_934") and report_text.contains("TASK_935"), "HTML report tracks TASK_934 and TASK_935")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_934 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_934\""), "Analyzer writes TASK_934 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_933\""), "Analyzer links TASK_933")
	_assert(service_text.contains("SOURCE_FOLLOWUP_FIX_TASK_ID: String = \"TASK_932\""), "Analyzer links TASK_932")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_931\""), "Analyzer links TASK_931")
	_assert(service_text.contains("SOURCE_RECAPTURE_TASK_ID: String = \"TASK_930\""), "Analyzer links TASK_930")
	_assert(service_text.contains("SOURCE_FINAL_READABILITY_TASK_ID: String = \"TASK_929\""), "Analyzer links TASK_929")
	_assert(service_text.contains("followup_fix_fire_lane_not_first_world_movement"), "Analyzer names follow-up fire-lane issue")
	_assert(service_text.contains("followup_fix_lane_not_before_fire_contact_text"), "Analyzer names lane-before-text issue")
	_assert(service_text.contains("followup_fix_label_halo_still_competes"), "Analyzer names label/halo issue")
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
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_934")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports TASK_933 mismatch")
	_assert(blocker_ids.has("source_followup_fix_task_mismatch"), "Missing source reports TASK_932 mismatch")
	_assert(blocker_ids.has("source_findings_task_mismatch"), "Missing source reports TASK_931 mismatch")
	_assert(blocker_ids.has("source_recapture_task_mismatch"), "Missing source reports TASK_930 mismatch")
	_assert(blocker_ids.has("source_final_readability_task_mismatch"), "Missing source reports TASK_929 mismatch")
	_assert(blocker_ids.has("followup_fix_schema_mismatch"), "Missing source reports follow-up schema mismatch")
	_assert(blocker_ids.has("followup_fix_style_mismatch"), "Missing source reports follow-up style mismatch")
	_assert(blocker_ids.has("findings_schema_mismatch"), "Missing source reports TASK_931 findings schema mismatch")
	_assert(blocker_ids.has("final_readability_schema_mismatch"), "Missing source reports final readability schema mismatch")
	_assert(blocker_ids.has("final_readability_style_mismatch"), "Missing source reports final readability style mismatch")
	_assert(blocker_ids.has("source_recapture_schema_mismatch"), "Missing source reports source recapture schema mismatch")
	_assert(blocker_ids.has("window_capture_method_not_handle_print"), "Missing source reports capture method mismatch")
	_assert(blocker_ids.has("window_capture_not_trusted"), "Missing source reports untrusted capture")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_needs_manual_review_without_notes() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_source_snapshot(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_manual_review", "Good TASK_933 source still needs manual review")
	_assert(bool(snapshot.get("review_ready", false)), "Good TASK_933 source is review-ready")
	_assert(not bool(snapshot.get("accepted", true)), "Good TASK_933 source is not accepted without notes")
	_assert(issue_ids.has("manual_visual_review_missing"), "Missing notes report manual review issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_FIX_TASK, "Open review does not unlock smoke")


func _test_findings_from_open_review() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_source_snapshot(), _review_notes_with_issues())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var positive_ids: Array = _issue_ids(Array(snapshot.get("positive_findings", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_934")
	_assert(String(snapshot.get("task_id", "")) == "TASK_934", "Snapshot task id matches TASK_934")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_933", "Snapshot links TASK_933")
	_assert(String(snapshot.get("source_followup_fix_task_id", "")) == "TASK_932", "Snapshot links TASK_932")
	_assert(String(snapshot.get("source_findings_task_id", "")) == "TASK_931", "Snapshot links TASK_931")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_930", "Snapshot links TASK_930")
	_assert(String(snapshot.get("source_final_readability_task_id", "")) == "TASK_929", "Snapshot links TASK_929")
	_assert(String(snapshot.get("status", "")) == "ready_for_followup_fix_player_polish", "Findings recommend follow-up polish")
	_assert(bool(snapshot.get("review_ready", false)), "Snapshot is review-ready")
	_assert(not bool(snapshot.get("accepted", true)), "Open review is not accepted")
	_assert(bool(snapshot.get("final_source_contact_fire", false)), "Snapshot records final source CONTACT FIRE")
	_assert(bool(snapshot.get("manual_visual_review_done", false)), "Snapshot records manual review")
	_assert(not bool(snapshot.get("player_readability_ok", true)), "Snapshot does not accept readability")
	_assert(positive_ids.has("final_source_contact_fire_clean"), "Snapshot keeps source positive")
	_assert(positive_ids.has("trusted_window_handle_capture"), "Snapshot keeps trusted capture positive")
	_assert(positive_ids.has("task_932_followup_fix_style_present"), "Snapshot records TASK_932 style")
	_assert(positive_ids.has("task_929_final_readability_style_present"), "Snapshot records TASK_929 style")
	_assert(positive_ids.has("contact_fire_hud_surfaces_present"), "Snapshot records CONTACT FIRE surfaces")
	_assert(positive_ids.has("followup_fix_visible"), "Snapshot records visible TASK_932 follow-up fix")
	_assert(issue_ids.has("followup_fix_fire_lane_not_first_world_movement"), "Snapshot records follow-up fire-lane issue")
	_assert(issue_ids.has("followup_fix_lane_not_before_fire_contact_text"), "Snapshot records lane-before-text issue")
	_assert(issue_ids.has("followup_fix_label_halo_still_competes"), "Snapshot records label/halo issue")
	_assert(String(snapshot.get("primary_issue_id", "")) == "followup_fix_fire_lane_not_first_world_movement", "Follow-up fire-lane issue is primary")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_FIX_TASK, "Snapshot recommends follow-up polish")
	_assert(String(snapshot.get("recommended_direction", "")) == "move_to_playability_smoke_if_accepted_else_followup_fix_player_polish", "Snapshot recommends bounded next decision")
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
	notes["followup_fix_fire_lane_is_first_world_movement"] = true
	notes["followup_fix_lane_reads_before_fire_contact_text"] = true
	notes["followup_fix_source_target_anchors_carry_direction"] = true
	notes["followup_fix_anchors_do_not_read_as_discs"] = true
	notes["followup_fix_world_fire_label_stays_behind_lane"] = true
	notes["followup_fix_target_halo_stays_behind_lane"] = true
	notes["followup_fix_grid_world_noise_not_competing"] = true
	notes["followup_fix_fire_lane_not_first_world_movement"] = false
	notes["followup_fix_lane_not_before_fire_contact_text"] = false
	notes["followup_fix_source_target_anchors_still_weak"] = false
	notes["followup_fix_anchors_read_as_discs"] = false
	notes["followup_fix_label_halo_still_competes"] = false
	notes["followup_fix_grid_world_noise_still_competes"] = false
	notes["bottom_hud_still_dense_for_first_fire_read"] = false
	var snapshot: Dictionary = Findings.build_snapshot(_good_source_snapshot(), notes)
	_assert(String(snapshot.get("status", "")) == "accepted_for_first_exchange_playability_smoke", "Clean notes accept for playability smoke")
	_assert(bool(snapshot.get("accepted", false)), "Clean notes set accepted flag")
	_assert(bool(snapshot.get("player_readability_ok", false)), "Clean notes mark player readability OK")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_SMOKE_TASK, "Clean notes recommend playability smoke")


func _test_optional_actual_snapshot() -> void:
	if not FileAccess.file_exists(SOURCE_SNAPSHOT_PATH):
		_assert(true, "TASK_933 source snapshot is optional before local capture")
		return
	var source_snapshot: Dictionary = _read_json_dict(SOURCE_SNAPSHOT_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(source_snapshot, {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual source builds TASK_934 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_933", "Actual source links TASK_933")
	_assert(String(snapshot.get("source_followup_fix_task_id", "")) == "TASK_932", "Actual source links TASK_932")
	_assert(bool(snapshot.get("read_only", false)), "Actual source snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual source snapshot sets no gameplay truth")


func _test_manifest_roundtrip() -> void:
	var source_snapshot: Dictionary = _read_json_dict(SOURCE_SNAPSHOT_PATH) if FileAccess.file_exists(SOURCE_SNAPSHOT_PATH) else _good_source_snapshot()
	var snapshot: Dictionary = Findings.build_snapshot(source_snapshot, _review_notes_with_issues())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_934 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_934", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_933", "Roundtrip keeps TASK_933 link")
	_assert(String(roundtrip.get("source_followup_fix_task_id", "")) == "TASK_932", "Roundtrip keeps TASK_932 link")
	_assert(String(roundtrip.get("status", "")) == "ready_for_followup_fix_player_polish", "Roundtrip keeps findings status")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "followup_fix_fire_lane_not_first_world_movement", "Roundtrip keeps primary issue")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_FIX_TASK, "Roundtrip keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_source_snapshot() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_933",
		"source_task_id": "TASK_932",
		"source_findings_task_id": "TASK_931",
		"source_recapture_task_id": "TASK_930",
		"source_final_readability_task_id": "TASK_929",
		"status": "review_ready",
		"review_ready": true,
		"accepted": false,
		"gate": "review_ready",
		"branch": "task/release-first-exchange-player-readability-polish-review",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"expected_followup_fix_schema": FOLLOWUP_FIX_SCHEMA,
		"expected_followup_fix_style_id": FOLLOWUP_FIX_STYLE_ID,
		"expected_findings_schema": FINDINGS_SCHEMA,
		"expected_final_readability_schema": FINAL_READABILITY_SCHEMA,
		"expected_final_readability_style_id": FINAL_READABILITY_STYLE_ID,
		"source_recapture_schema": SOURCE_RECAPTURE_SCHEMA,
		"source_recapture_gate": "review_ready",
		"followup_fix_capture_after_deeplink_final": true,
		"followup_fix_capture_method": "window_handle_print",
		"followup_fix_window_capture_trusted": true,
		"followup_fix_window_screenshot_path": "tmp/release_first_exchange_followup_fix_recapture.png",
		"followup_fix_desktop_screenshot_path": "tmp/release_first_exchange_followup_fix_recapture_desktop.png",
		"final_source_contact_fire": true,
		"final_source_snapshot": {
			"source_observed_state": "FINAL_SOURCE_CONTACT_FIRE",
			"stage": "deeplink_final",
			"selected_starts_contact_fire": true,
			"mission_starts_contact_fire": true,
			"event_log_contains_contact_fire": true,
			"event_log_contains_contact_pressure": false,
		},
		"source_followup_fix_snapshot": {
			"schema": FOLLOWUP_FIX_SCHEMA,
			"task_id": "TASK_932",
			"style_id": FOLLOWUP_FIX_STYLE_ID,
		},
		"source_final_readability_findings_snapshot": {
			"schema": FINDINGS_SCHEMA,
			"task_id": "TASK_931",
		},
		"followup_fix_world_read_render_review": {
			"frame_trace_method": "post_deeplink_final_window_handle_screenshot_followup_fix_review_required",
			"screenshot_observed_state": "TASK_933_REVIEW_REQUIRED",
			"expected_followup_fix_schema": FOLLOWUP_FIX_SCHEMA,
			"expected_followup_fix_style_id": FOLLOWUP_FIX_STYLE_ID,
			"expected_fire_lane_is_first_world_movement": true,
			"expected_fire_lane_reads_before_fire_contact_text": true,
		},
	}


func _review_notes_with_issues() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"observed_window_state": "CONTACT_FIRE_VISIBLE_FOLLOWUP_FIX_NEEDS_FINDING_DECISION",
		"review_screenshot_path": "tmp/release_first_exchange_followup_fix_recapture.png",
		"player_readability_ok": false,
		"contact_fire_hud_surfaces_present": true,
		"event_log_contact_fire_visible": true,
		"followup_fix_visible": true,
		"followup_fix_fire_lane_is_first_world_movement": false,
		"followup_fix_lane_reads_before_fire_contact_text": false,
		"followup_fix_source_target_anchors_carry_direction": true,
		"followup_fix_anchors_do_not_read_as_discs": true,
		"followup_fix_world_fire_label_stays_behind_lane": false,
		"followup_fix_target_halo_stays_behind_lane": false,
		"followup_fix_grid_world_noise_not_competing": true,
		"command_surfaces_still_usable": true,
		"followup_fix_fire_lane_not_first_world_movement": true,
		"followup_fix_lane_not_before_fire_contact_text": true,
		"followup_fix_source_target_anchors_still_weak": false,
		"followup_fix_anchors_read_as_discs": false,
		"followup_fix_label_halo_still_competes": true,
		"followup_fix_grid_world_noise_still_competes": false,
		"bottom_hud_still_dense_for_first_fire_read": false,
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
