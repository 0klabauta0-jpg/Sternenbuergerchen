extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1025_release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.v1"
const NEXT_TASK := "TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Review"
const POLISH_TASK := "TASK_1025 - Release First Decision Loop Two Player Loop Scenario Targeted RC Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1025 Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_passed_source_without_review_needs_acceptance_review()
	_test_failed_review_routes_to_targeted_polish()
	_test_good_review_accepts_release_candidate()
	_test_controller_exports_release_candidate_acceptance()
	_test_release_candidate_acceptance_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1025_release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance: FAILED")
		quit(1)
		return
	print("TASK_1025_release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1025 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1025 release-candidate acceptance service exists")
	_assert(task_text.contains("TASK_1025 - Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance"), "Task names TASK_1025")
	_assert(task_text.contains(NEXT_TASK), "Task names ship-readiness follow-up")
	_assert(status_text.contains("TASK_1025 - Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance"), "Implementation status tracks TASK_1025")
	_assert(roadmap_text.contains("TASK_1025 - Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance (implementiert"), "Roadmap marks TASK_1025 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance (TASK_1025)"), "Mission feedback contract documents TASK_1025")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance (TASK_1025)"), "Decision clarity contract documents TASK_1025")
	_assert(service_text.contains(SCHEMA), "Release-candidate acceptance service exposes stable TASK_1025 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1025\""), "Release-candidate acceptance service writes TASK_1025 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1024\""), "Release-candidate acceptance service links TASK_1024")
	_assert(service_text.contains("REQUIRED_ACCEPTANCE_GATES"), "Release-candidate acceptance service defines required gates")
	_assert(service_text.contains("\"release_candidate_accepted\""), "Release-candidate acceptance exposes accepted flag")
	_assert(service_text.contains("\"ready_for_ship_readiness_review\""), "Release-candidate acceptance exposes ship-readiness readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Release-candidate acceptance creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Release-candidate acceptance creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Release-candidate acceptance creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_RELEASE_CANDIDATE_ACCEPTANCE_SCRIPT"), "Controller preloads TASK_1025 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance_snapshot"), "Controller exposes TASK_1025 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance_line"), "Command feedback exports TASK_1025 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance_status"), "Command feedback exports TASK_1025 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1025")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_rc_playtest_not_passed"), "Missing source reports RC playtest mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked RC acceptance snapshot remains read-only")


func _test_passed_source_without_review_needs_acceptance_review() -> void:
	var snapshot: Dictionary = _build_snapshot(_release_candidate_playtest(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1025")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1025", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1024", "Snapshot links TASK_1024")
	_assert(String(snapshot.get("source_status", "")) == "release_candidate_playtest_passed", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_release_candidate_acceptance_review", "Passed source without review needs acceptance review")
	_assert(String(snapshot.get("gate", "")) == "needs_release_candidate_acceptance_review", "Gate asks for RC acceptance review")
	_assert(issue_ids.has("release_candidate_acceptance_review_missing"), "Missing RC acceptance review is explicit")
	_assert(not bool(snapshot.get("release_candidate_accepted", true)), "Missing review does not accept RC")
	_assert(_snapshot_is_read_only(snapshot), "Review-needed snapshot remains read-only")


func _test_failed_review_routes_to_targeted_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_release_candidate_playtest(), _failed_review())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var failed_gates: Array = Array(snapshot.get("failed_acceptance_gates", []))
	_assert(String(snapshot.get("status", "")) == "release_candidate_acceptance_regression_found", "Failed review reports RC acceptance regression")
	_assert(String(snapshot.get("gate", "")) == "release_candidate_acceptance_regression_found", "Failed review gate reports regression")
	_assert(failed_gates.has("no_visible_player_blockers"), "Failed review records visible blocker gate")
	_assert(failed_gates.has("ship_readiness_notes_written"), "Failed review records ship-readiness notes gate")
	_assert(issue_ids.has("visible_player_blockers_remain"), "Visible blocker issue is explicit")
	_assert(issue_ids.has("ship_readiness_notes_missing"), "Ship-readiness notes issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Regression routes to targeted RC polish")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_review_accepts_release_candidate() -> void:
	var snapshot: Dictionary = _build_snapshot(_release_candidate_playtest(), _good_review())
	var gates: Array = Array(snapshot.get("passed_acceptance_gates", []))
	_assert(String(snapshot.get("status", "")) == "release_candidate_accepted", "Good review accepts RC")
	_assert(String(snapshot.get("gate", "")) == "release_candidate_accepted", "Good review gate accepts")
	_assert(bool(snapshot.get("release_candidate_accepted", false)), "Good review sets accepted flag")
	_assert(bool(snapshot.get("ready_for_ship_readiness_review", false)), "Good review is ready for ship-readiness review")
	_assert(String(snapshot.get("release_candidate_acceptance_line", "")).contains("ACCEPTED"), "Acceptance line names accepted")
	_assert(String(snapshot.get("release_candidate_acceptance_line", "")).contains("FOB"), "Acceptance line names FOB")
	_assert(String(snapshot.get("release_candidate_acceptance_line", "")).contains("NEXT"), "Acceptance line names NEXT")
	_assert(String(snapshot.get("release_candidate_acceptance_line", "")).contains("GO"), "Acceptance line names GO")
	_assert(String(snapshot.get("release_candidate_acceptance_line", "")).contains("FEEDBACK"), "Acceptance line names feedback")
	_assert(gates.has("rc_playtest_passed"), "Good review keeps RC pass gate")
	_assert(gates.has("no_visible_player_blockers"), "Good review passes visible blocker gate")
	_assert(gates.has("ship_readiness_notes_written"), "Good review passes ship-readiness notes gate")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Accepted RC recommends ship-readiness review")
	_assert(_snapshot_is_read_only(snapshot), "Accepted RC remains read-only")


func _test_controller_exports_release_candidate_acceptance() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance_snapshot"):
		_assert(false, "Controller exposes TASK_1025 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance_snapshot(_release_candidate_playtest(), _good_review())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1025 schema matches")
	_assert(String(snapshot.get("status", "")) == "release_candidate_accepted", "Controller TASK_1025 accepts with review")
	_assert(String(snapshot.get("release_candidate_acceptance_line", "")).contains("NEXT"), "Controller TASK_1025 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1025 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance"), "Command feedback embeds TASK_1025")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance_line"), "Command feedback exports TASK_1025 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance_status"), "Command feedback exports TASK_1025 status")
	controller.queue_free()


func _test_release_candidate_acceptance_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_release_candidate_playtest(), _good_review())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1025 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1025", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1024", "Roundtrip keeps TASK_1024 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_playtest: Dictionary, acceptance_review: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1025 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1025 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_playtest, acceptance_review)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1025 service returns dictionary")
	return _read_only_fallback()


func _release_candidate_playtest() -> Dictionary:
	var checks: Array = [
		"release_exe_started",
		"singleplayer_entry_opened",
		"fob_screen_loaded",
		"alpha_bravo_context_visible",
		"next_confirm_go_flow_used",
		"go_executed_once",
		"post_go_feedback_visible",
		"loop_returns_to_next",
		"no_input_dead_end",
		"performance_responsive",
		"no_hud_gameplay_truth",
		"multiplayer_boundary_preserved",
	]
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1024",
		"source_task_id": "TASK_1023",
		"status": "release_candidate_playtest_passed",
		"gate": "release_candidate_playtest_passed",
		"release_candidate_playtest_line": "RC PLAYTEST PASS: FOB | NEXT | GO | FEEDBACK | rund",
		"release_candidate_playtest_passed": true,
		"ready_for_release_candidate_acceptance": true,
		"release_exe_started": true,
		"release_build_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.exe",
		"completed_playtest_checks": checks,
		"missing_playtest_checks": [],
		"issue_count": 0,
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _good_review() -> Dictionary:
	return {
		"review_available": true,
		"manual_acceptance_done": true,
		"accepted_by": "codex_fixture",
		"acceptance_notes": "FOB/NEXT/GO/FEEDBACK sind als kleiner RC-Spielmoment lesbar und ohne sichtbare Sackgasse.",
		"ship_readiness_notes": "Naechster Schritt: Ship-readiness pruefen, Build-Pfad und Testerhinweise buendeln.",
		"rc_playtest_passed": true,
		"release_build_present": true,
		"no_visible_player_blockers": true,
		"no_regression_issues": true,
		"no_input_dead_end": true,
		"performance_acceptable": true,
		"multiplayer_boundary_preserved": true,
		"no_hud_gameplay_truth": true,
		"ship_readiness_notes_written": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_review() -> Dictionary:
	var review: Dictionary = _good_review()
	review["no_visible_player_blockers"] = false
	review["ship_readiness_notes_written"] = false
	review["ship_readiness_notes"] = ""
	review["acceptance_notes"] = "Post-GO-Feedback ist sichtbar, aber es bleiben sichtbare Spielerblocker."
	return review


func _read_only_fallback() -> Dictionary:
	return {
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
