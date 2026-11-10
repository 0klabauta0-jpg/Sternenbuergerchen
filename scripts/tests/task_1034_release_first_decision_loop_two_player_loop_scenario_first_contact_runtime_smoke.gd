extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1034_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.v1"
const NEXT_TASK := "TASK_1035 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings"
const REVIEW_TASK := "TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke"
const POLISH_TASK := "TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1034 Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_unready_hook_blocks()
	_test_ready_hook_without_trace_needs_smoke_trace()
	_test_incomplete_trace_routes_to_completion()
	_test_issue_flags_route_to_polish()
	_test_clean_trace_passes_smoke()
	_test_controller_exports_first_contact_runtime_smoke()
	_test_smoke_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1034_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke: FAILED")
		quit(1)
		return
	print("TASK_1034_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var feedback_source_text: String = _read_text("res://scripts/mission/diagnostics/mission_command_feedback_diagnostics.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1034 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1034 runtime smoke service exists")
	_assert(task_text.contains(REVIEW_TASK), "Task names TASK_1034")
	_assert(task_text.contains(NEXT_TASK), "Task names player-feel follow-up")
	_assert(status_text.contains(REVIEW_TASK), "Implementation status tracks TASK_1034")
	_assert(roadmap_text.contains("TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke (implementiert"), "Roadmap marks TASK_1034 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke (TASK_1034)"), "Mission feedback contract documents TASK_1034")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke (TASK_1034)"), "Decision clarity contract documents TASK_1034")
	_assert(service_text.contains(SCHEMA), "Runtime smoke service exposes stable TASK_1034 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1034\""), "Runtime smoke service writes TASK_1034 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1033\""), "Runtime smoke service links TASK_1033")
	_assert(service_text.contains("REQUIRED_SMOKE_CHECKS"), "Runtime smoke service defines required checks")
	_assert(service_text.contains("\"real_snapshot_context_used\""), "Runtime smoke requires real snapshot context")
	_assert(service_text.contains("\"creates_command\": false"), "Runtime smoke creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Runtime smoke creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Runtime smoke creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_FIRST_CONTACT_RUNTIME_SMOKE_SCRIPT"), "Controller preloads TASK_1034 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke_snapshot"), "Controller exposes TASK_1034 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke_line"), "Command feedback exports TASK_1034 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke_status"), "Command feedback exports TASK_1034 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_first_contact_runtime_hook", "Missing TASK_1033 source blocks TASK_1034")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_hook_not_ready"), "Missing source reports hook readiness mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked smoke remains read-only")


func _test_unready_hook_blocks() -> void:
	var source: Dictionary = _ready_source_hook()
	source["status"] = "first_contact_runtime_hook_review"
	source["first_contact_runtime_hook_ready"] = false
	var snapshot: Dictionary = _build_snapshot(source, _smoke_trace(true, _all_check_ids(), []))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_first_contact_runtime_hook", "Unready TASK_1033 source blocks TASK_1034")
	_assert(blocker_ids.has("source_hook_not_ready"), "Unready hook reports readiness mismatch")
	_assert(not bool(snapshot.get("first_contact_runtime_smoke_passed", true)), "Unready hook does not pass smoke")
	_assert(_snapshot_is_read_only(snapshot), "Unready-hook smoke remains read-only")


func _test_ready_hook_without_trace_needs_smoke_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_source_hook(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1034")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1034", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1033", "Snapshot links TASK_1033")
	_assert(String(snapshot.get("status", "")) == "needs_first_contact_runtime_smoke_trace", "Ready hook without trace needs smoke trace")
	_assert(issue_ids.has("first_contact_runtime_smoke_trace_missing"), "Missing smoke trace is explicit")
	_assert(not bool(snapshot.get("first_contact_runtime_smoke_passed", true)), "Missing trace does not pass smoke")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed smoke remains read-only")


func _test_incomplete_trace_routes_to_completion() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_source_hook(), _smoke_trace(false, [
		"runtime_hook_ready",
		"contact_line_visible",
		"player_questions_answered",
		"contact_hook_visible",
		"why_hook_visible",
	], []))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_smoke_checks", []))
	_assert(String(snapshot.get("status", "")) == "needs_first_contact_runtime_smoke_completion", "Incomplete trace reports completion need")
	_assert(String(snapshot.get("gate", "")) == "needs_first_contact_runtime_smoke_completion", "Incomplete trace gate names completion")
	_assert(missing_checks.has("go_still_separate"), "Incomplete trace records missing GO separation")
	_assert(missing_checks.has("real_snapshot_context_used"), "Incomplete trace records missing real snapshot context")
	_assert(issue_ids.has("first_contact_runtime_smoke_checks_missing"), "Missing checks issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == REVIEW_TASK, "Incomplete trace loops on TASK_1034")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete trace smoke remains read-only")


func _test_issue_flags_route_to_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_source_hook(), _smoke_trace(true, _all_check_ids(), ["contact_line_overwritten", "hud_truth_boundary_risk"]))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "first_contact_runtime_smoke_regression_found", "Issue flags report smoke regression")
	_assert(String(snapshot.get("gate", "")) == "first_contact_runtime_smoke_regression_found", "Issue gate reports smoke regression")
	_assert(issue_ids.has("first_contact_runtime_smoke_issue_contact_line_overwritten"), "Contact-line issue is explicit")
	_assert(issue_ids.has("first_contact_runtime_smoke_issue_hud_truth_boundary_risk"), "HUD-boundary issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Issue flags route to smoke polish")
	_assert(_snapshot_is_read_only(snapshot), "Issue smoke remains read-only")


func _test_clean_trace_passes_smoke() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_source_hook(), _smoke_trace(true, _all_check_ids(), []))
	var line: String = String(snapshot.get("first_contact_runtime_smoke_line", ""))
	_assert(String(snapshot.get("status", "")) == "first_contact_runtime_smoke_passed", "Clean trace passes first-contact runtime smoke")
	_assert(String(snapshot.get("gate", "")) == "first_contact_runtime_smoke_passed", "Clean trace gate passed")
	_assert(bool(snapshot.get("first_contact_runtime_smoke_passed", false)), "Clean trace sets smoke-passed flag")
	_assert(bool(snapshot.get("ready_for_first_contact_player_feel_findings", false)), "Clean trace routes to player-feel findings")
	_assert(line.contains("CONTACT"), "Smoke line names contact")
	_assert(line.contains("WHY"), "Smoke line names why")
	_assert(line.contains("NEXT"), "Smoke line names next")
	_assert(line.contains("GO separat"), "Smoke line keeps GO separate")
	_assert(line.contains("FEEDBACK"), "Smoke line names feedback")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Clean trace recommends player-feel findings")
	_assert(_snapshot_is_read_only(snapshot), "Clean smoke remains read-only")


func _test_controller_exports_first_contact_runtime_smoke() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke_snapshot"):
		_assert(false, "Controller exposes TASK_1034 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke_snapshot(_ready_source_hook(), _smoke_trace(true, _all_check_ids(), []))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1034 schema matches")
	_assert(String(snapshot.get("status", "")) == "first_contact_runtime_smoke_passed", "Controller TASK_1034 passes with trace")
	_assert(String(snapshot.get("first_contact_runtime_smoke_line", "")).contains("CONTACT"), "Controller TASK_1034 line names contact")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1034 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke"), "Command feedback embeds TASK_1034")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke_line"), "Command feedback exports TASK_1034 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke_status"), "Command feedback exports TASK_1034 status")
	controller.queue_free()


func _test_smoke_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_source_hook(), _smoke_trace(true, _all_check_ids(), []))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1034 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1034", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1033", "Roundtrip keeps TASK_1033 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_hook: Dictionary, smoke_trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1034 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1034 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_hook, smoke_trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1034 service returns dictionary")
	return _read_only_fallback()


func _ready_source_hook() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1033",
		"source_task_id": "TASK_1032",
		"status": "first_contact_runtime_hook_ready",
		"gate": "first_contact_runtime_hook_ready",
		"first_contact_runtime_hook_ready": true,
		"first_contact_runtime_line": "CONTACT READY: CONTACT | COVER | LOS | FIRE/WAIT | FEEDBACK | GO separat",
		"player_question_answers": {
			"Wer sieht wen?": "Kontakt: 2 Gegner, 70m",
			"Warum ist das sicher oder gefaehrlich?": "COVER/LOS/RANGE: WAIT COV+ LOS- RNG 70",
			"Warum schiesst das Fireteam oder wartet es?": "FIRE/WAIT: WAIT | COVER partial | LOS blocked",
			"Was ist der naechste Griff?": "NEXT lesen, WHY pruefen, GO separat bestaetigen.",
		},
		"command_matrix_runtime_hooks": [
			{"hook_id": "contact", "enabled": true, "read_only": true},
			{"hook_id": "why", "enabled": true, "read_only": true},
			{"hook_id": "next", "enabled": true, "read_only": true},
			{"hook_id": "go", "enabled": true, "auto_executes": false, "read_only": true},
		],
		"reused_contracts": ["first_contact_readability", "first_engagement_feedback", "fire_cover_visual_polish", "combat_hud_density"],
		"first_contact_readability": {"gate": "pass", "selected_contact_count": 1, "read_only": true, "ui_sets_gameplay_truth": false},
		"first_engagement_feedback": {"gate": "pass", "read_only": true, "ui_sets_gameplay_truth": false},
		"fire_cover_visual_polish": {"gate": "pass", "read_only": true, "ui_sets_gameplay_truth": false},
		"combat_hud_density": {"gate": "pass", "compact_line": "WAIT COV+ LOS- RNG 70", "read_only": true, "ui_sets_gameplay_truth": false},
		"requires_existing_go_path": true,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _smoke_trace(done: bool, completed_checks: Array, issue_flags: Array) -> Dictionary:
	return {
		"trace_available": true,
		"smoke_done": done,
		"completed_smoke_checks": completed_checks,
		"issue_flags": issue_flags,
		"post_smoke_feedback_line": "FEEDBACK: Kontakt gelesen, WHY sichtbar, NEXT bleibt bereit.",
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _all_check_ids() -> Array:
	return [
		"runtime_hook_ready",
		"contact_line_visible",
		"player_questions_answered",
		"contact_hook_visible",
		"why_hook_visible",
		"next_hook_visible",
		"go_still_separate",
		"no_auto_go",
		"real_snapshot_context_used",
		"first_contact_gate_pass",
		"first_engagement_gate_pass",
		"combat_hud_gate_pass",
		"feedback_returns_to_next",
		"hud_read_only_boundary_ok",
		"multiplayer_boundary_preserved",
		"performance_budget_ok",
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
