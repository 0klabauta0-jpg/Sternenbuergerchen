extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1032_release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.v1"
const NEXT_TASK := "TASK_1033 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook"
const PLAN_TASK := "TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan"
const POLISH_TASK := "TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1032 Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan ===")
	_test_docs_and_static_hooks()
	_test_missing_acceptance_blocks()
	_test_unaccepted_source_blocks()
	_test_accepted_source_without_plan_needs_slice_plan()
	_test_incomplete_plan_routes_to_completion()
	_test_issue_flags_route_to_plan_polish()
	_test_clean_plan_marks_ready_for_first_contact_runtime_hook()
	_test_controller_exports_next_playable_slice_plan()
	_test_plan_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1032_release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan: FAILED")
		quit(1)
		return
	print("TASK_1032_release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1032 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1032 next-slice service exists")
	_assert(task_text.contains("TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan"), "Task names TASK_1032")
	_assert(task_text.contains(NEXT_TASK), "Task names first-contact runtime follow-up")
	_assert(status_text.contains("TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan"), "Implementation status tracks TASK_1032")
	_assert(roadmap_text.contains("TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan (implementiert"), "Roadmap marks TASK_1032 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan (TASK_1032)"), "Mission feedback contract documents TASK_1032")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan (TASK_1032)"), "Decision clarity contract documents TASK_1032")
	_assert(command_contract_text.contains("get_mission_first_contact_readability_snapshot"), "Contract keeps First-Contact reuse visible")
	_assert(command_contract_text.contains("get_mission_first_engagement_feedback_snapshot"), "Contract keeps First-Engagement reuse visible")
	_assert(service_text.contains(SCHEMA), "Next-slice service exposes stable TASK_1032 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1032\""), "Next-slice service writes TASK_1032 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1031\""), "Next-slice service links TASK_1031")
	_assert(service_text.contains("REQUIRED_PLAN_ITEMS"), "Next-slice service defines required plan items")
	_assert(service_text.contains("\"ready_for_first_contact_runtime_hook\""), "Next-slice service exposes runtime-hook readiness")
	_assert(service_text.contains("\"first_contact_readability\""), "Next-slice service reuses first-contact readability")
	_assert(service_text.contains("\"first_engagement_feedback\""), "Next-slice service reuses first-engagement feedback")
	_assert(service_text.contains("\"creates_command\": false"), "Next-slice plan creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Next-slice plan creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Next-slice plan creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_NEXT_PLAYABLE_SLICE_PLAN_SCRIPT"), "Controller preloads TASK_1032 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan_snapshot"), "Controller exposes TASK_1032 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan_line"), "Command feedback exports TASK_1032 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan_status"), "Command feedback exports TASK_1032 status")


func _test_missing_acceptance_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_tester_run_acceptance", "Missing source blocks TASK_1032")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_acceptance_not_ready"), "Missing source reports acceptance mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked next-slice snapshot remains read-only")


func _test_unaccepted_source_blocks() -> void:
	var source: Dictionary = _accepted_source()
	source["status"] = "needs_acceptance_review_completion"
	source["tester_run_accepted"] = false
	source["ready_for_next_playable_slice"] = false
	var snapshot: Dictionary = _build_snapshot(source, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_tester_run_acceptance", "Unaccepted TASK_1031 source blocks")
	_assert(blocker_ids.has("source_acceptance_not_ready"), "Unaccepted source reports acceptance mismatch")
	_assert(not bool(snapshot.get("next_playable_slice_plan_ready", true)), "Unaccepted source is not plan-ready")
	_assert(_snapshot_is_read_only(snapshot), "Unaccepted-source plan remains read-only")


func _test_accepted_source_without_plan_needs_slice_plan() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_source(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_items: Array = Array(snapshot.get("missing_plan_items", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1032")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1032", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1031", "Snapshot links TASK_1031")
	_assert(String(snapshot.get("source_status", "")) == "tester_run_accepted", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_next_playable_slice_plan", "Accepted source without plan needs slice plan")
	_assert(String(snapshot.get("gate", "")) == "needs_next_playable_slice_plan", "Gate asks for next playable slice plan")
	_assert(issue_ids.has("next_slice_plan_missing"), "Missing next-slice plan is explicit")
	_assert(missing_items.has("first_contact_readability_reused"), "Missing plan exposes first-contact reuse item")
	_assert(not bool(snapshot.get("next_playable_slice_plan_ready", true)), "Missing plan does not mark plan ready")
	_assert(_snapshot_is_read_only(snapshot), "Plan-needed snapshot remains read-only")


func _test_incomplete_plan_routes_to_completion() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_source(), _incomplete_plan())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_items: Array = Array(snapshot.get("missing_plan_items", []))
	_assert(String(snapshot.get("status", "")) == "needs_next_playable_slice_plan_completion", "Incomplete plan reports completion need")
	_assert(String(snapshot.get("gate", "")) == "needs_next_playable_slice_plan_completion", "Incomplete plan gate names completion")
	_assert(missing_items.has("first_engagement_feedback_reused"), "Incomplete plan records missing first engagement item")
	_assert(missing_items.has("next_task_named"), "Incomplete plan records missing next task")
	_assert(issue_ids.has("next_slice_plan_items_missing"), "Missing plan items issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == PLAN_TASK, "Incomplete plan loops on TASK_1032")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete plan snapshot remains read-only")


func _test_issue_flags_route_to_plan_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_source(), _plan_notes(true, _all_item_ids(), ["ignores_existing_contact_stack", "performance_budget_unclear"]))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "next_playable_slice_plan_regression_found", "Issue flags report plan regression")
	_assert(String(snapshot.get("gate", "")) == "next_playable_slice_plan_regression_found", "Issue gate reports plan regression")
	_assert(issue_ids.has("next_slice_plan_issue_ignores_existing_contact_stack"), "Contact-stack issue is explicit")
	_assert(issue_ids.has("next_slice_plan_issue_performance_budget_unclear"), "Performance issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Issue flags route to plan polish")
	_assert(_snapshot_is_read_only(snapshot), "Issue plan remains read-only")


func _test_clean_plan_marks_ready_for_first_contact_runtime_hook() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_source(), _plan_notes(true, _all_item_ids(), []))
	var line: String = String(snapshot.get("next_slice_line", ""))
	var plan: Dictionary = Dictionary(snapshot.get("slice_plan", {}))
	var runtime_beats: Array = Array(plan.get("runtime_beats", []))
	var player_questions: Array = Array(plan.get("player_questions", []))
	_assert(String(snapshot.get("status", "")) == "next_playable_slice_plan_ready", "Clean plan marks next-slice plan ready")
	_assert(String(snapshot.get("gate", "")) == "next_playable_slice_plan_ready", "Clean plan gate ready")
	_assert(bool(snapshot.get("next_playable_slice_plan_ready", false)), "Clean plan sets plan-ready flag")
	_assert(bool(snapshot.get("ready_for_first_contact_runtime_hook", false)), "Clean plan is ready for first-contact runtime hook")
	_assert(line.contains("NEXT SLICE READY"), "Next-slice line names ready")
	_assert(line.contains("CONTACT"), "Next-slice line names contact")
	_assert(line.contains("COVER"), "Next-slice line names cover")
	_assert(line.contains("LOS"), "Next-slice line names LOS")
	_assert(line.contains("FIRE/WAIT"), "Next-slice line names fire/wait")
	_assert(line.contains("FEEDBACK"), "Next-slice line names feedback")
	_assert(String(plan.get("slice_id", "")) == "first_contact_decision", "Plan selects first-contact decision slice")
	_assert(runtime_beats.has("first_contact_report"), "Plan contains first contact report beat")
	_assert(runtime_beats.has("first_engagement_feedback"), "Plan contains first engagement feedback beat")
	_assert(player_questions.has("Wer sieht wen?"), "Plan asks who sees whom")
	_assert(Array(plan.get("reuse_contracts", [])).has("first_contact_readability"), "Plan reuses first-contact contract")
	_assert(Array(plan.get("reuse_contracts", [])).has("combat_hud_density"), "Plan reuses combat HUD density")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Clean plan recommends first-contact runtime hook")
	_assert(_snapshot_is_read_only(snapshot), "Clean plan remains read-only")


func _test_controller_exports_next_playable_slice_plan() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan_snapshot"):
		_assert(false, "Controller exposes TASK_1032 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan_snapshot(_accepted_source(), _plan_notes(true, _all_item_ids(), []))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1032 schema matches")
	_assert(String(snapshot.get("status", "")) == "next_playable_slice_plan_ready", "Controller TASK_1032 ready with plan")
	_assert(String(snapshot.get("next_slice_line", "")).contains("CONTACT"), "Controller TASK_1032 line names contact")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1032 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan"), "Command feedback embeds TASK_1032")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan_line"), "Command feedback exports TASK_1032 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan_status"), "Command feedback exports TASK_1032 status")
	controller.queue_free()


func _test_plan_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_source(), _plan_notes(true, _all_item_ids(), []))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1032 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1032", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1031", "Roundtrip keeps TASK_1031 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_acceptance: Dictionary, plan_notes: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1032 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1032 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_acceptance, plan_notes)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1032 service returns dictionary")
	return _read_only_fallback()


func _accepted_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1031",
		"source_task_id": "TASK_1030",
		"status": "tester_run_accepted",
		"gate": "tester_run_accepted",
		"acceptance_line": "ACCEPTED: EXE | FOB | NEXT | GO | FEEDBACK | naechster spielbarer Slice planen.",
		"tester_run_accepted": true,
		"ready_for_next_playable_slice": true,
		"release_build_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.exe",
		"pck_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.pck",
		"scenario_id": "release_first_decision_loop_two_player_loop",
		"known_risks": ["Manueller Sichttest bleibt noetig."],
		"acceptance_notes": {
			"acceptance_summary": "Tester Run als kleiner FOB/NEXT/GO/FEEDBACK-Spielmoment akzeptiert.",
			"risk_note": "Bekannte Risiken sind akzeptiert.",
			"polish_note": "Keine blockernde Sichtpolitur.",
			"next_slice": "naechster spielbarer Slice: erster Kampfkontakt mit lesbarer Entscheidung.",
		},
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


func _incomplete_plan() -> Dictionary:
	return _plan_notes(true, [
		"accepted_tester_run_reused",
		"slice_goal_chosen",
		"first_contact_readability_reused",
		"fire_cover_visuals_reused",
		"player_questions_defined",
	], [])


func _plan_notes(done: bool, completed_items: Array, issue_ids: Array) -> Dictionary:
	return {
		"next_slice_plan_available": true,
		"next_slice_plan_done": done,
		"selected_slice_id": "first_contact_decision",
		"completed_plan_items": completed_items,
		"issue_flags": issue_ids,
		"plan_summary": "Erster Kontakt wird der naechste spielbare Slice.",
		"player_goal": "Nach GO liest der Spieler Kontakt, Cover/LOS, Fire/Wait und naechsten Griff.",
		"two_player_note": "Alpha liest Kontakt und GO, Bravo bleibt als zweiter Spieler-/Multiplayer-Rand erhalten.",
		"performance_note": "Nutzt vorhandene Snapshots und keine neuen Hotpath-Scans.",
		"next_task_note": NEXT_TASK,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _all_item_ids() -> Array:
	return [
		"accepted_tester_run_reused",
		"slice_goal_chosen",
		"first_contact_readability_reused",
		"first_engagement_feedback_reused",
		"fire_cover_visuals_reused",
		"combat_hud_density_reused",
		"player_questions_defined",
		"two_player_role_boundary_defined",
		"multiplayer_boundary_preserved",
		"next_task_named",
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
