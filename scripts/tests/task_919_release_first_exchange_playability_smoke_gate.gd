extends SceneTree

const Gate := preload("res://scripts/mission/release_first_exchange_playability_smoke_gate.gd")

const TASK_PATH := "res://docs/tasks/TASK_919_release_first_exchange_playability_smoke_gate.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_playability_smoke_gate.gd"
const SCHEMA := "sternenbuergerchen.release_first_exchange_playability_smoke_gate.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_exchange_final_world_read_visual_findings.v1"
const NEXT_SMOKE_TASK := "TASK_920 - Release First Exchange Playability Smoke Run"
const NEXT_FIX_TASK := "TASK_920 - Release First Exchange Final World Read Followup Fix"
const NEXT_REVIEW_TASK := "TASK_920 - Release First Exchange Manual Window Review"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_919 Release First Exchange Playability Smoke Gate ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_manual_review_blocks_smoke()
	_test_followup_fix_blocks_smoke()
	_test_acceptance_allows_smoke()
	_test_read_only_boundaries()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_919_release_first_exchange_playability_smoke_gate: FAILED")
		quit(1)
		return
	print("TASK_919_release_first_exchange_playability_smoke_gate: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_919 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_919 gate service exists")
	_assert(task_text.contains("Release First Exchange Playability Smoke Gate"), "Task names TASK_919")
	_assert(task_text.contains(NEXT_SMOKE_TASK), "Task names smoke follow-up")
	_assert(task_text.contains(NEXT_FIX_TASK), "Task names fix follow-up")
	_assert(status_text.contains("TASK_919 - Release First Exchange Playability Smoke Gate"), "Implementation status tracks TASK_919")
	_assert(roadmap_text.contains("TASK_919 - Release First Exchange Playability Smoke Gate (implementiert"), "Roadmap marks TASK_919 implemented")
	_assert(roadmap_text.contains(NEXT_SMOKE_TASK), "Roadmap names TASK_920 smoke follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Playability-Smoke-Gate (TASK_919)"), "Contract documents TASK_919")
	_assert(report_text.contains("TASK_919") and report_text.contains("TASK_920"), "HTML report tracks TASK_919 and TASK_920")
	_assert(service_text.contains(SCHEMA), "Gate exposes stable TASK_919 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_919\""), "Gate writes TASK_919 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_918\""), "Gate links TASK_918")
	_assert(service_text.contains("SOURCE_RECAPTURE_TASK_ID: String = \"TASK_917\""), "Gate links TASK_917")
	_assert(service_text.contains("SOURCE_FINAL_TASK_ID: String = \"TASK_916\""), "Gate links TASK_916")
	_assert(service_text.contains("run_playability_smoke_only_after_task_918_acceptance"), "Gate names smoke condition")
	_assert(service_text.contains("\"read_only\": true"), "Gate declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Gate declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Gate declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Gate declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Gate declares no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Gate declares no multiplayer truth")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "Gate updates no shortcuts")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Gate.build_snapshot({})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("gate", "")) == "blocked", "Missing source blocks gate")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports TASK_918 mismatch")
	_assert(blocker_ids.has("source_recapture_task_mismatch"), "Missing source reports TASK_917 mismatch")
	_assert(blocker_ids.has("source_final_task_mismatch"), "Missing source reports TASK_916 mismatch")
	_assert(blocker_ids.has("source_not_read_only"), "Missing source reports read-only mismatch")
	_assert(blocker_ids.has("source_creates_command"), "Missing source reports command mutation risk")
	_assert(not bool(snapshot.get("smoke_ready", true)), "Blocked source is not smoke-ready")


func _test_manual_review_blocks_smoke() -> void:
	var snapshot: Dictionary = Gate.build_snapshot(_source_snapshot("needs_manual_review", false, ""))
	_assert(String(snapshot.get("gate", "")) == "manual_review_required", "Manual review status blocks smoke")
	_assert(bool(snapshot.get("manual_review_required", false)), "Manual review flag is set")
	_assert(not bool(snapshot.get("smoke_ready", true)), "Manual review is not smoke-ready")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_REVIEW_TASK, "Manual review recommends review task")
	_assert(String(snapshot.get("reason", "")) == "task_918_needs_manual_review", "Manual review reason is explicit")


func _test_followup_fix_blocks_smoke() -> void:
	var snapshot: Dictionary = Gate.build_snapshot(_source_snapshot("ready_for_final_world_read_followup_fix", false, "fire_lane_not_first_world_movement_after_final_polish"))
	_assert(String(snapshot.get("gate", "")) == "followup_fix_required", "Follow-up status blocks smoke")
	_assert(bool(snapshot.get("followup_fix_required", false)), "Follow-up fix flag is set")
	_assert(not bool(snapshot.get("smoke_ready", true)), "Follow-up fix is not smoke-ready")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_FIX_TASK, "Follow-up status recommends fix task")
	_assert(String(snapshot.get("source_primary_issue_id", "")) == "fire_lane_not_first_world_movement_after_final_polish", "Primary issue is preserved")


func _test_acceptance_allows_smoke() -> void:
	var snapshot: Dictionary = Gate.build_snapshot(_source_snapshot("accepted_for_first_exchange_playability_smoke", true, ""))
	var checks: Array = Array(snapshot.get("smoke_required_checks", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Accepted gate schema matches TASK_919")
	_assert(String(snapshot.get("task_id", "")) == "TASK_919", "Accepted gate task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_918", "Accepted gate links TASK_918")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_917", "Accepted gate preserves TASK_917 link")
	_assert(String(snapshot.get("source_final_task_id", "")) == "TASK_916", "Accepted gate preserves TASK_916 link")
	_assert(String(snapshot.get("gate", "")) == "smoke_ready", "Accepted TASK_918 unlocks smoke")
	_assert(bool(snapshot.get("smoke_ready", false)), "Smoke-ready flag is true")
	_assert(not bool(snapshot.get("manual_review_required", true)), "Accepted source needs no manual review")
	_assert(not bool(snapshot.get("followup_fix_required", true)), "Accepted source needs no fix")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_SMOKE_TASK, "Accepted source recommends smoke run")
	_assert(checks.has("exe_singleplayer_start_reaches_homebase"), "Smoke checks cover EXE singleplayer start")
	_assert(checks.has("homebase_direct_sortie_start_is_actionable"), "Smoke checks cover homebase direct sortie")
	_assert(checks.has("dropship_lz_go_reaches_mission"), "Smoke checks cover dropship/LZ/GO")
	_assert(checks.has("contact_fire_visible_in_selected_fireteam_mission_control_and_event_log"), "Smoke checks cover CONTACT FIRE surfaces")
	_assert(checks.has("fire_lane_remains_first_world_movement"), "Smoke checks cover world read")
	_assert(checks.has("first_exchange_no_obvious_performance_spike"), "Smoke checks cover performance smoke")


func _test_read_only_boundaries() -> void:
	var snapshot: Dictionary = Gate.build_snapshot(_source_snapshot("accepted_for_first_exchange_playability_smoke", true, ""))
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Snapshot creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _source_snapshot(status: String, player_readability_ok: bool, primary_issue_id: String) -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_918",
		"source_task_id": "TASK_917",
		"source_final_task_id": "TASK_916",
		"status": status,
		"branch": "task/release-first-exchange-player-readability-polish-review",
		"git_head": "test",
		"review_screenshot_path": "tmp/release_first_exchange_final_world_read_recapture.png",
		"window_screenshot_path": "tmp/release_first_exchange_final_world_read_recapture.png",
		"final_source_contact_fire": true,
		"player_readability_ok": player_readability_ok,
		"primary_issue_id": primary_issue_id,
		"issue_count": 0 if primary_issue_id == "" else 1,
		"positive_findings": [{"id": "final_source_contact_fire_clean"}],
		"issues": [] if primary_issue_id == "" else [{"id": primary_issue_id}],
		"read_only": true,
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
