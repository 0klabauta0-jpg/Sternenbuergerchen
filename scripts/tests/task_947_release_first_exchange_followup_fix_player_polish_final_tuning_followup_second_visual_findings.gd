extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_947_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.gd"
const SOURCE_MANIFEST_PATH := "res://tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.v1"
const SECOND_FIX_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.v1"
const SECOND_FIX_STYLE_ID := "task_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix_v1"
const FINDINGS_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.v1"
const FOLLOWUP_FIX_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.v1"
const FOLLOWUP_FIX_STYLE_ID := "task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_v1"
const SOURCE_RECAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_SMOKE_TASK := "TASK_948 - Release First Exchange Playability Smoke"
const NEXT_RETURN_TASK := "TASK_948 - Tactical Decision Clarity Scenario Return"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_947 Release First Exchange Second Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_good_source_needs_manual_review()
	_test_findings_recommend_scenario_return()
	_test_clean_notes_accept_for_smoke()
	_test_optional_actual_source()
	_test_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_947_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_947_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_947 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_947 analyzer exists")
	_assert(task_text.contains("Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Visual Findings"), "Task names TASK_947")
	_assert(task_text.contains(NEXT_SMOKE_TASK), "Task names smoke follow-up")
	_assert(task_text.contains(NEXT_RETURN_TASK), "Task names scenario-return follow-up")
	_assert(status_text.contains("TASK_947 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Visual Findings"), "Implementation status tracks TASK_947")
	_assert(roadmap_text.contains("TASK_947 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Visual Findings (implementiert"), "Roadmap marks TASK_947 implemented")
	_assert(roadmap_text.contains(NEXT_RETURN_TASK), "Roadmap names scenario-return follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Followup-Fix-Player-Polish-Final-Tuning-Followup-Second-Visual-Findings (TASK_947)"), "Contract documents TASK_947")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_947 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_947\""), "Analyzer writes TASK_947 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_946\""), "Analyzer links TASK_946")
	_assert(service_text.contains("SOURCE_SECOND_FIX_TASK_ID: String = \"TASK_945\""), "Analyzer links TASK_945")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_944\""), "Analyzer links TASK_944")
	_assert(service_text.contains("SOURCE_FOLLOWUP_FIX_TASK_ID: String = \"TASK_942\""), "Analyzer links TASK_942")
	_assert(service_text.contains("NEXT_RETURN_TASK"), "Analyzer can route away from polish loop")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "Analyzer declares no shortcut updates")


func _test_missing_source_blocks() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_947 analyzer can be loaded")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", {}, {}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_947")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports TASK_946 mismatch")
	_assert(blocker_ids.has("source_second_fix_task_mismatch"), "Missing source reports TASK_945 mismatch")
	_assert(blocker_ids.has("source_findings_task_mismatch"), "Missing source reports TASK_944 mismatch")
	_assert(blocker_ids.has("source_followup_fix_task_mismatch"), "Missing source reports TASK_942 mismatch")
	_assert(blocker_ids.has("second_fix_schema_mismatch"), "Missing source reports TASK_945 schema mismatch")
	_assert(blocker_ids.has("second_fix_style_mismatch"), "Missing source reports TASK_945 style mismatch")
	_assert(blocker_ids.has("source_recapture_schema_mismatch"), "Missing source reports TASK_943 schema mismatch")
	_assert(blocker_ids.has("source_not_review_ready"), "Missing source reports review-ready mismatch")
	_assert(blocker_ids.has("second_capture_method_not_handle_print"), "Missing source reports capture method mismatch")
	_assert(blocker_ids.has("second_window_capture_not_trusted"), "Missing source reports untrusted capture")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_good_source_needs_manual_review() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_947 analyzer can be loaded for open review")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", _good_source(), {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Open snapshot schema matches TASK_947")
	_assert(String(snapshot.get("task_id", "")) == "TASK_947", "Open snapshot task id matches TASK_947")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_946", "Open snapshot links TASK_946")
	_assert(String(snapshot.get("source_second_fix_task_id", "")) == "TASK_945", "Open snapshot links TASK_945")
	_assert(String(snapshot.get("source_findings_task_id", "")) == "TASK_944", "Open snapshot links TASK_944")
	_assert(String(snapshot.get("source_followup_fix_task_id", "")) == "TASK_942", "Open snapshot links TASK_942")
	_assert(String(snapshot.get("status", "")) == "needs_manual_review", "Good source still needs manual review")
	_assert(bool(snapshot.get("review_ready", false)), "Open snapshot is review-ready")
	_assert(not bool(snapshot.get("accepted", true)), "Open review is not accepted")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_RETURN_TASK, "Open review does not unlock smoke")
	_assert(_snapshot_is_read_only(snapshot), "Open snapshot is read-only")


func _test_findings_recommend_scenario_return() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_947 analyzer can be loaded for findings")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", _good_source(), _rest_notes()))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "ready_for_tactical_decision_clarity_return", "Second findings route away from polish loop")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_RETURN_TASK, "Findings recommend scenario return")
	_assert(String(snapshot.get("recommended_direction", "")) == "stop_first_exchange_polish_loop_and_return_to_playable_scenario", "Findings recommend stopping polish loop")
	_assert(issue_ids.has("second_fire_lane_not_first_world_movement"), "Snapshot records second-lane issue")
	_assert(issue_ids.has("second_lane_not_before_fire_contact_text"), "Snapshot records second lane-before-text issue")
	_assert(issue_ids.has("second_label_halo_still_competes"), "Snapshot records second label/halo issue")
	_assert(String(snapshot.get("primary_issue_id", "")) == "second_fire_lane_not_first_world_movement", "Second fire-lane issue is primary")
	_assert(not bool(snapshot.get("accepted", true)), "Findings are not accepted")
	_assert(bool(snapshot.get("final_source_contact_fire", false)), "Findings keep CONTACT FIRE evidence")
	_assert(_snapshot_is_read_only(snapshot), "Findings snapshot is read-only")


func _test_clean_notes_accept_for_smoke() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_947 analyzer can be loaded for accepted review")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", _good_source(), _accepted_notes()))
	_assert(String(snapshot.get("status", "")) == "accepted_for_first_exchange_playability_smoke", "Clean notes accept for playability smoke")
	_assert(bool(snapshot.get("accepted", false)), "Clean notes set accepted flag")
	_assert(bool(snapshot.get("player_readability_ok", false)), "Clean notes mark player readability OK")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_SMOKE_TASK, "Clean notes recommend playability smoke")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_optional_actual_source() -> void:
	if not FileAccess.file_exists(SOURCE_MANIFEST_PATH):
		_assert(true, "TASK_946 source manifest is optional before local capture")
		return
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_947 analyzer can be loaded for actual source")
		return
	var source: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH)
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", source, {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual source builds TASK_947 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_946", "Actual source links TASK_946")
	_assert(_snapshot_is_read_only(snapshot), "Actual source snapshot remains read-only")


func _test_roundtrip() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_947 analyzer can be loaded for roundtrip")
		return
	var source: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH) if FileAccess.file_exists(SOURCE_MANIFEST_PATH) else _good_source()
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", source, _rest_notes()))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_947 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_947", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_946", "Roundtrip keeps TASK_946 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_RETURN_TASK, "Roundtrip keeps next task")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "second_fire_lane_not_first_world_movement", "Roundtrip keeps primary issue")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _good_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_946",
		"source_task_id": "TASK_945",
		"source_findings_task_id": "TASK_944",
		"source_followup_fix_task_id": "TASK_942",
		"source_recapture_task_id": "TASK_943",
		"status": "review_ready",
		"gate": "review_ready",
		"review_ready": true,
		"accepted": false,
		"branch": "task/release-first-exchange-player-readability-polish-review",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"expected_second_fix_schema": SECOND_FIX_SCHEMA,
		"expected_second_fix_style_id": SECOND_FIX_STYLE_ID,
		"expected_findings_schema": FINDINGS_SCHEMA,
		"expected_followup_fix_schema": FOLLOWUP_FIX_SCHEMA,
		"expected_followup_fix_style_id": FOLLOWUP_FIX_STYLE_ID,
		"source_recapture_schema": SOURCE_RECAPTURE_SCHEMA,
		"source_recapture_gate": "review_ready",
		"second_capture_after_deeplink_final": true,
		"second_window_capture_method": "window_handle_print",
		"second_window_capture_trusted": true,
		"second_window_screenshot_path": "tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.png",
		"second_desktop_screenshot_path": "tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture_desktop.png",
		"final_source_contact_fire": true,
		"final_source_snapshot": {
			"selected_starts_contact_fire": true,
			"mission_starts_contact_fire": true,
			"event_log_contains_contact_fire": true,
			"event_log_contains_contact_pressure": false,
		},
		"source_second_fix_snapshot": {
			"schema": SECOND_FIX_SCHEMA,
			"task_id": "TASK_945",
			"style_id": SECOND_FIX_STYLE_ID,
			"gate": "pass",
		},
		"source_findings_snapshot": {
			"schema": FINDINGS_SCHEMA,
			"task_id": "TASK_944",
		},
		"source_followup_fix_snapshot": {
			"schema": FOLLOWUP_FIX_SCHEMA,
			"task_id": "TASK_942",
			"style_id": FOLLOWUP_FIX_STYLE_ID,
		},
		"source_recapture_review": {
			"screenshot_observed_state": "TASK_946_REVIEW_REQUIRED",
		},
		"second_world_read_render_review": {
			"expected_second_fix_schema": SECOND_FIX_SCHEMA,
			"expected_second_fix_style_id": SECOND_FIX_STYLE_ID,
		},
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _rest_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"observed_window_state": "TASK_946_SECOND_REVIEW_REST_FRICTION",
		"contact_fire_hud_surfaces_present": true,
		"event_log_contact_fire_visible": true,
		"second_visible": true,
		"second_fire_lane_not_first_world_movement": true,
		"second_lane_not_before_fire_contact_text": true,
		"second_label_halo_still_competes": true,
		"second_grid_world_noise_still_competes": false,
		"command_surfaces_still_usable": true,
		"player_readability_ok": false,
	}


func _accepted_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"observed_window_state": "TASK_946_SECOND_REVIEW_ACCEPTED",
		"contact_fire_hud_surfaces_present": true,
		"event_log_contact_fire_visible": true,
		"second_visible": true,
		"second_fire_lane_is_first_world_movement": true,
		"second_lane_reads_before_fire_contact_text": true,
		"second_source_target_anchors_carry_direction": true,
		"second_anchors_do_not_read_as_discs": true,
		"second_world_fire_label_stays_behind_lane": true,
		"second_target_halo_stays_behind_lane": true,
		"second_grid_world_noise_not_competing": true,
		"command_surfaces_still_usable": true,
		"player_readability_ok": true,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true)) \
		and not bool(snapshot.get("updates_shortcuts", true))


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
