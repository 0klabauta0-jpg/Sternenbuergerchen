extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1024_release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.v1"
const NEXT_TASK := "TASK_1025 - Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance"
const POLISH_TASK := "TASK_1025 - Release First Decision Loop Two Player Loop Scenario Targeted RC Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1024 Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_accepted_source_without_manifest_needs_release_candidate_playtest()
	_test_incomplete_manifest_needs_completion()
	_test_regression_manifest_routes_to_polish()
	_test_good_manifest_passes_release_candidate_playtest()
	_test_controller_exports_release_candidate_playtest()
	_test_release_candidate_playtest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1024_release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest: FAILED")
		quit(1)
		return
	print("TASK_1024_release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1024 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1024 release-candidate playtest service exists")
	_assert(task_text.contains("TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest"), "Task names TASK_1024")
	_assert(task_text.contains(NEXT_TASK), "Task names release-candidate acceptance follow-up")
	_assert(status_text.contains("TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest"), "Implementation status tracks TASK_1024")
	_assert(roadmap_text.contains("TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest (implementiert"), "Roadmap marks TASK_1024 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest (TASK_1024)"), "Mission feedback contract documents TASK_1024")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest (TASK_1024)"), "Decision clarity contract documents TASK_1024")
	_assert(service_text.contains(SCHEMA), "Release-candidate playtest service exposes stable TASK_1024 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1024\""), "Release-candidate playtest service writes TASK_1024 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1023\""), "Release-candidate playtest service links TASK_1023")
	_assert(service_text.contains("REQUIRED_PLAYTEST_CHECKS"), "Release-candidate playtest service defines required checks")
	_assert(service_text.contains("\"release_candidate_playtest_passed\""), "Release-candidate playtest exposes pass flag")
	_assert(service_text.contains("\"ready_for_release_candidate_acceptance\""), "Release-candidate playtest exposes acceptance readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Release-candidate playtest creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Release-candidate playtest creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Release-candidate playtest creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_RELEASE_CANDIDATE_PLAYTEST_SCRIPT"), "Controller preloads TASK_1024 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest_snapshot"), "Controller exposes TASK_1024 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest_line"), "Command feedback exports TASK_1024 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest_status"), "Command feedback exports TASK_1024 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1024")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_small_game_accepted"), "Missing source reports small-game acceptance mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked release-candidate snapshot remains read-only")


func _test_accepted_source_without_manifest_needs_release_candidate_playtest() -> void:
	var snapshot: Dictionary = _build_snapshot(_small_game_acceptance_slice(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1024")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1024", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1023", "Snapshot links TASK_1023")
	_assert(String(snapshot.get("source_status", "")) == "small_game_acceptance_slice_passed", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_release_candidate_playtest_manifest", "Accepted source without manifest needs RC playtest")
	_assert(String(snapshot.get("gate", "")) == "needs_release_candidate_playtest_manifest", "Gate asks for RC playtest manifest")
	_assert(issue_ids.has("release_candidate_playtest_manifest_missing"), "Missing RC manifest is explicit")
	_assert(not bool(snapshot.get("release_candidate_playtest_passed", true)), "Missing manifest does not pass RC playtest")
	_assert(_snapshot_is_read_only(snapshot), "Manifest-needed snapshot remains read-only")


func _test_incomplete_manifest_needs_completion() -> void:
	var snapshot: Dictionary = _build_snapshot(_small_game_acceptance_slice(), _incomplete_manifest())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_release_candidate_playtest_completion", "Incomplete manifest needs completion")
	_assert(String(snapshot.get("gate", "")) == "needs_release_candidate_playtest_completion", "Incomplete manifest gate names completion")
	_assert(issue_ids.has("manual_release_candidate_playtest_open"), "Manual playtest completion issue is explicit")
	_assert(issue_ids.has("release_candidate_checks_missing"), "Missing RC checks issue is explicit")
	_assert(int(snapshot.get("missing_playtest_check_count", 0)) > 0, "Incomplete manifest reports missing checks")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest", "Incomplete manifest loops on TASK_1024")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete manifest snapshot remains read-only")


func _test_regression_manifest_routes_to_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_small_game_acceptance_slice(), _regression_manifest())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_playtest_checks", []))
	_assert(String(snapshot.get("status", "")) == "release_candidate_playtest_regression_found", "Regression manifest reports RC regression")
	_assert(String(snapshot.get("gate", "")) == "release_candidate_playtest_regression_found", "Regression gate reports RC regression")
	_assert(missing_checks.has("post_go_feedback_visible"), "Regression records missing post-GO feedback")
	_assert(missing_checks.has("loop_returns_to_next"), "Regression records missing loop return")
	_assert(issue_ids.has("post_go_feedback_missing_in_release_candidate"), "Missing post-GO feedback issue is explicit")
	_assert(issue_ids.has("release_candidate_loop_does_not_return_to_next"), "Missing loop return issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Regression routes to targeted RC polish")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_manifest_passes_release_candidate_playtest() -> void:
	var snapshot: Dictionary = _build_snapshot(_small_game_acceptance_slice(), _good_manifest())
	var completed_checks: Array = Array(snapshot.get("completed_playtest_checks", []))
	_assert(String(snapshot.get("status", "")) == "release_candidate_playtest_passed", "Good manifest passes RC playtest")
	_assert(String(snapshot.get("gate", "")) == "release_candidate_playtest_passed", "Good manifest gate passes")
	_assert(bool(snapshot.get("release_candidate_playtest_passed", false)), "Good manifest sets pass flag")
	_assert(bool(snapshot.get("ready_for_release_candidate_acceptance", false)), "Good manifest is ready for RC acceptance")
	_assert(String(snapshot.get("release_candidate_playtest_line", "")).contains("RC"), "RC line names RC")
	_assert(String(snapshot.get("release_candidate_playtest_line", "")).contains("FOB"), "RC line names FOB")
	_assert(String(snapshot.get("release_candidate_playtest_line", "")).contains("NEXT"), "RC line names NEXT")
	_assert(String(snapshot.get("release_candidate_playtest_line", "")).contains("GO"), "RC line names GO")
	_assert(String(snapshot.get("release_candidate_playtest_line", "")).contains("FEEDBACK"), "RC line names feedback")
	_assert(completed_checks.has("release_exe_started"), "Good manifest started release exe")
	_assert(completed_checks.has("go_executed_once"), "Good manifest executed GO")
	_assert(int(snapshot.get("completed_playtest_check_count", 0)) >= 12, "Good manifest covers RC checks")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed RC playtest recommends acceptance")
	_assert(_snapshot_is_read_only(snapshot), "Passed RC playtest remains read-only")


func _test_controller_exports_release_candidate_playtest() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest_snapshot"):
		_assert(false, "Controller exposes TASK_1024 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest_snapshot(_small_game_acceptance_slice(), _good_manifest())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1024 schema matches")
	_assert(String(snapshot.get("status", "")) == "release_candidate_playtest_passed", "Controller TASK_1024 passes with manifest")
	_assert(String(snapshot.get("release_candidate_playtest_line", "")).contains("NEXT"), "Controller TASK_1024 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1024 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest"), "Command feedback embeds TASK_1024")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest_line"), "Command feedback exports TASK_1024 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest_status"), "Command feedback exports TASK_1024 status")
	controller.queue_free()


func _test_release_candidate_playtest_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_small_game_acceptance_slice(), _good_manifest())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1024 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1024", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1023", "Roundtrip keeps TASK_1023 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_acceptance: Dictionary, manifest: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1024 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1024 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_acceptance, manifest)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1024 service returns dictionary")
	return _read_only_fallback()


func _small_game_acceptance_slice() -> Dictionary:
	var checks: Array = [
		"entry_fob_next_visible",
		"objective_and_roles_clear",
		"next_confirm_go_boundary_clear",
		"go_stays_separate",
		"post_go_feedback_returns_to_next",
		"hud_calm",
		"performance_feels_responsive",
		"two_player_context_clear",
		"multiplayer_boundary_preserved",
		"no_new_hud_gameplay_truth",
	]
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1023",
		"source_task_id": "TASK_1022",
		"status": "small_game_acceptance_slice_passed",
		"gate": "small_game_acceptance_slice_passed",
		"trace_available": true,
		"completed_checks": checks,
		"missing_acceptance_checks": [],
		"small_game_acceptance_line": "SMALL GAME ACCEPTANCE PASS: FOB | NEXT | GO separat | FEEDBACK | rund",
		"small_game_acceptance_slice_passed": true,
		"ready_for_release_candidate_playtest": true,
		"recommended_next_task": "TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest",
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


func _good_manifest() -> Dictionary:
	var checks: Array = _required_checks()
	return {
		"manifest_available": true,
		"manual_playtest_done": true,
		"release_exe_started": true,
		"release_build_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.exe",
		"playtest_window": "singleplayer_release_candidate",
		"completed_playtest_checks": checks,
		"post_go_feedback_visible": true,
		"loop_returns_to_next": true,
		"performance_responsive": true,
		"multiplayer_boundary_preserved": true,
		"no_hud_gameplay_truth": true,
		"issue_flags": {},
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _incomplete_manifest() -> Dictionary:
	return {
		"manifest_available": true,
		"manual_playtest_done": false,
		"release_exe_started": true,
		"completed_playtest_checks": ["release_exe_started", "singleplayer_entry_opened"],
		"issue_flags": {},
	}


func _regression_manifest() -> Dictionary:
	var manifest: Dictionary = _good_manifest()
	var checks: Array = _required_checks()
	checks.erase("post_go_feedback_visible")
	checks.erase("loop_returns_to_next")
	manifest["completed_playtest_checks"] = checks
	manifest["post_go_feedback_visible"] = false
	manifest["loop_returns_to_next"] = false
	manifest["issue_flags"] = {
		"post_go_feedback_missing_in_release_candidate": true,
		"release_candidate_loop_does_not_return_to_next": true,
	}
	return manifest


func _required_checks() -> Array:
	return [
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
