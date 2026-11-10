extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1033_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_next_playable_slice_plan.v1"
const NEXT_TASK := "TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke"
const REVIEW_TASK := "TASK_1033 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1033 Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_unready_plan_blocks()
	_test_ready_plan_without_runtime_context_needs_context()
	_test_incomplete_runtime_context_routes_to_review()
	_test_clean_runtime_context_marks_ready()
	_test_controller_exports_first_contact_runtime_hook()
	_test_runtime_hook_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1033_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook: FAILED")
		quit(1)
		return
	print("TASK_1033_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1033 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1033 first-contact runtime hook service exists")
	_assert(task_text.contains(REVIEW_TASK), "Task names TASK_1033")
	_assert(task_text.contains(NEXT_TASK), "Task names runtime smoke follow-up")
	_assert(status_text.contains(REVIEW_TASK), "Implementation status tracks TASK_1033")
	_assert(roadmap_text.contains("TASK_1033 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook (implementiert"), "Roadmap marks TASK_1033 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook (TASK_1033)"), "Mission feedback contract documents TASK_1033")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook (TASK_1033)"), "Decision clarity contract documents TASK_1033")
	_assert(service_text.contains(SCHEMA), "Runtime hook service exposes stable TASK_1033 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1033\""), "Runtime hook service writes TASK_1033 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1032\""), "Runtime hook service links TASK_1032")
	_assert(service_text.contains("\"first_contact_readability\""), "Runtime hook reuses first-contact readability")
	_assert(service_text.contains("\"first_engagement_feedback\""), "Runtime hook reuses first-engagement feedback")
	_assert(service_text.contains("\"combat_hud_density\""), "Runtime hook reuses combat HUD density")
	_assert(service_text.contains("\"creates_command\": false"), "Runtime hook creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Runtime hook creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Runtime hook creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_FIRST_CONTACT_RUNTIME_HOOK_SCRIPT"), "Controller preloads TASK_1033 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook_snapshot"), "Controller exposes TASK_1033 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook_line"), "Command feedback exports TASK_1033 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook_status"), "Command feedback exports TASK_1033 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_next_playable_slice_plan", "Missing TASK_1032 source blocks TASK_1033")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_plan_not_ready"), "Missing source reports plan readiness mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked runtime hook remains read-only")


func _test_unready_plan_blocks() -> void:
	var source: Dictionary = _ready_source_plan()
	source["status"] = "needs_next_playable_slice_plan_completion"
	source["next_playable_slice_plan_ready"] = false
	source["ready_for_first_contact_runtime_hook"] = false
	var snapshot: Dictionary = _build_snapshot(source, _runtime_context())
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_next_playable_slice_plan", "Unready TASK_1032 plan blocks TASK_1033")
	_assert(blocker_ids.has("source_plan_not_ready"), "Unready plan reports readiness mismatch")
	_assert(not bool(snapshot.get("first_contact_runtime_hook_ready", true)), "Unready plan is not runtime-ready")
	_assert(_snapshot_is_read_only(snapshot), "Unready-plan runtime hook remains read-only")


func _test_ready_plan_without_runtime_context_needs_context() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_source_plan(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1033")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1033", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1032", "Snapshot links TASK_1032")
	_assert(String(snapshot.get("status", "")) == "needs_first_contact_runtime_hook_context", "Ready plan without runtime context needs context")
	_assert(issue_ids.has("runtime_context_missing"), "Missing runtime context is explicit")
	_assert(not bool(snapshot.get("first_contact_runtime_hook_ready", true)), "Missing context does not mark runtime hook ready")
	_assert(_snapshot_is_read_only(snapshot), "Context-needed runtime hook remains read-only")


func _test_incomplete_runtime_context_routes_to_review() -> void:
	var context: Dictionary = _runtime_context()
	context["first_contact_readability"] = {"gate": "review", "read_only": true, "ui_sets_gameplay_truth": false}
	var snapshot: Dictionary = _build_snapshot(_ready_source_plan(), context)
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "first_contact_runtime_hook_review", "Incomplete runtime context reports review")
	_assert(String(snapshot.get("gate", "")) == "first_contact_runtime_hook_review", "Incomplete runtime context gate names review")
	_assert(issue_ids.has("first_contact_readability_not_passed"), "Missing contact readability pass is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == REVIEW_TASK, "Incomplete context loops on TASK_1033")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete runtime hook remains read-only")


func _test_clean_runtime_context_marks_ready() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_source_plan(), _runtime_context())
	var line: String = String(snapshot.get("first_contact_runtime_line", ""))
	var steps: Array = Array(snapshot.get("runtime_steps", []))
	var questions: Dictionary = Dictionary(snapshot.get("player_question_answers", {}))
	var hooks: Array = Array(snapshot.get("command_matrix_runtime_hooks", []))
	_assert(String(snapshot.get("status", "")) == "first_contact_runtime_hook_ready", "Clean runtime context marks TASK_1033 ready")
	_assert(String(snapshot.get("gate", "")) == "first_contact_runtime_hook_ready", "Clean runtime hook gate ready")
	_assert(bool(snapshot.get("first_contact_runtime_hook_ready", false)), "Clean runtime hook sets ready flag")
	_assert(line.contains("CONTACT"), "Runtime line names contact")
	_assert(line.contains("COVER"), "Runtime line names cover")
	_assert(line.contains("LOS"), "Runtime line names LOS")
	_assert(line.contains("FIRE/WAIT"), "Runtime line names fire/wait")
	_assert(line.contains("GO separat"), "Runtime line keeps GO separate")
	_assert(_step_ids(steps).has("first_contact_report"), "Runtime steps include contact report")
	_assert(_step_ids(steps).has("first_engagement_feedback"), "Runtime steps include first engagement feedback")
	_assert(String(questions.get("Wer sieht wen?", "")).contains("Kontakt"), "Runtime answers who sees whom")
	_assert(_hook_ids(hooks).has("why"), "Runtime hooks include why/readability hook")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Clean runtime hook recommends smoke")
	_assert(_snapshot_is_read_only(snapshot), "Clean runtime hook remains read-only")


func _test_controller_exports_first_contact_runtime_hook() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook_snapshot"):
		_assert(false, "Controller exposes TASK_1033 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook_snapshot(_ready_source_plan(), _runtime_context())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1033 schema matches")
	_assert(String(snapshot.get("status", "")) == "first_contact_runtime_hook_ready", "Controller TASK_1033 ready with context")
	_assert(String(snapshot.get("first_contact_runtime_line", "")).contains("CONTACT"), "Controller TASK_1033 line names contact")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1033 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook"), "Command feedback embeds TASK_1033")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook_line"), "Command feedback exports TASK_1033 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook_status"), "Command feedback exports TASK_1033 status")
	controller.queue_free()


func _test_runtime_hook_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_source_plan(), _runtime_context())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1033 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1033", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1032", "Roundtrip keeps TASK_1032 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_plan: Dictionary, runtime_context: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1033 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1033 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_plan, runtime_context)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1033 service returns dictionary")
	return _read_only_fallback()


func _ready_source_plan() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1032",
		"source_task_id": "TASK_1031",
		"status": "next_playable_slice_plan_ready",
		"gate": "next_playable_slice_plan_ready",
		"selected_slice_id": "first_contact_decision",
		"next_slice_line": "NEXT SLICE READY: CONTACT | COVER | LOS | FIRE/WAIT | FEEDBACK | TASK_1033",
		"next_playable_slice_plan_ready": true,
		"ready_for_first_contact_runtime_hook": true,
		"slice_plan": {
			"slice_id": "first_contact_decision",
			"runtime_beats": ["first_contact_report", "cover_los_readout", "first_engagement_feedback", "fire_or_wait_reason", "feedback_to_next_choice"],
			"reuse_contracts": ["first_contact_readability", "first_engagement_feedback", "fire_cover_visual_polish", "combat_hud_density"],
			"player_questions": ["Wer sieht wen?", "Warum ist das sicher oder gefaehrlich?", "Warum schiesst das Fireteam oder wartet es?", "Was ist der naechste Griff?"],
			"next_task": REVIEW_TASK,
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
	}


func _runtime_context() -> Dictionary:
	return {
		"first_contact_readability": {
			"gate": "pass",
			"selected_contact_count": 1,
			"first_contact": {"report_text": "Kontakt: 2 Gegner, 70m, confidence 72%"},
			"contact_feedback_text": "CONTACT sichtbar",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
		"first_engagement_feedback": {
			"gate": "pass",
			"engagement_status": "waiting",
			"engagement_reason": "cover_los_check",
			"contact_decision_text": "WAIT | COVER partial | LOS blocked",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
		"fire_cover_visual_polish": {
			"gate": "pass",
			"first_fire_visual": {"trace_color": "red", "status_label": "WAIT"},
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
		"combat_hud_density": {
			"gate": "pass",
			"compact_line": "WAIT COV+ LOS- RNG 70",
			"combat_hud_density": {
				"active": true,
				"compact_line": "WAIT COV+ LOS- RNG 70",
				"contains_fire_state": true,
				"contains_cover_context": true,
				"contains_los_context": true,
				"contains_range_context": true,
				"read_only": true,
				"ui_sets_gameplay_truth": false,
			},
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
		"selected_fireteam_id": "FT1",
		"selected_role_id": "alpha",
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _step_ids(steps: Array) -> Array:
	var ids: Array = []
	for step_variant in steps:
		if typeof(step_variant) == TYPE_DICTIONARY:
			ids.append(String(Dictionary(step_variant).get("step_id", "")))
	return ids


func _hook_ids(hooks: Array) -> Array:
	var ids: Array = []
	for hook_variant in hooks:
		if typeof(hook_variant) == TYPE_DICTIONARY:
			ids.append(String(Dictionary(hook_variant).get("hook_id", "")))
	return ids


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
