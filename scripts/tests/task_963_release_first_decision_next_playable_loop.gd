extends SceneTree

const NextLoop := preload("res://scripts/mission/release_first_decision_next_playable_loop.gd")

const TASK_PATH := "res://docs/tasks/TASK_963_release_first_decision_next_playable_loop.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_next_playable_loop.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_next_playable_loop_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_next_playable_loop.v1"
const FINDINGS_SCHEMA := "sternenbuergerchen.release_first_decision_playtest_findings.v1"
const FIRST_DECISION_SCHEMA := "sternenbuergerchen.first_decision_micro_scenario_polish.v1"
const NEXT_TASK := "TASK_964 - Release First Decision Loop Two Playtest"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_963 Release First Decision Next Playable Loop ===")
	_test_docs_and_static_hooks()
	_test_unaccepted_findings_block_next_loop()
	_test_accepted_findings_build_second_decision_loop()
	_test_live_preview_source_is_honest_but_visible()
	await _test_controller_exports_next_playable_loop()
	_test_next_loop_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_963_release_first_decision_next_playable_loop: FAILED")
		quit(1)
		return
	print("TASK_963_release_first_decision_next_playable_loop: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_963 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_963 next-loop service exists")
	_assert(task_text.contains("TASK_963 - Release First Decision Next Playable Loop"), "Task names TASK_963")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_964 follow-up")
	_assert(status_text.contains("TASK_963 - Release First Decision Next Playable Loop"), "Implementation status tracks TASK_963")
	_assert(roadmap_text.contains("TASK_963 - Release First Decision Next Playable Loop (implementiert"), "Roadmap marks TASK_963 implemented")
	_assert(command_contract_text.contains("Release First Decision Next Playable Loop (TASK_963)"), "Mission feedback contract documents TASK_963")
	_assert(clarity_contract_text.contains("Release First Decision Next Playable Loop (TASK_963)"), "Decision clarity contract documents TASK_963")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_NEXT_PLAYABLE_LOOP_SCRIPT"), "Controller preloads TASK_963 service")
	_assert(controller_text.contains("get_release_first_decision_next_playable_loop_snapshot"), "Controller exposes TASK_963 snapshot")
	_assert(controller_text.contains("release_first_decision_next_playable_loop"), "Command feedback exports TASK_963")
	_assert(service_text.contains(SCHEMA), "Next-loop service exposes stable schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_963\""), "Next-loop service writes TASK_963 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_962\""), "Next-loop service links TASK_962")
	_assert(service_text.contains("NEXT_TASK"), "Next-loop service declares TASK_964")
	_assert(service_text.contains("\"read_only\": true"), "Next-loop service declares read-only")
	_assert(service_text.contains("\"ui_sets_gameplay_truth\": false"), "Next-loop service creates no UI gameplay truth")
	_assert(service_text.contains("\"creates_command\": false"), "Next-loop service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Next-loop service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Next-loop service creates no multiplayer truth")


func _test_unaccepted_findings_block_next_loop() -> void:
	var findings: Dictionary = _accepted_findings()
	findings["status"] = "needs_manual_review"
	findings["accepted"] = false
	findings["manual_review_done"] = false
	var snapshot: Dictionary = NextLoop.build_snapshot(findings, _first_decision(), _firefight_decision(), {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Unaccepted TASK_962 source blocks TASK_963")
	_assert(blocker_ids.has("source_findings_not_accepted"), "Unaccepted source is named")
	_assert(not bool(snapshot.get("active", true)), "Blocked next loop is not active")
	_assert(_snapshot_is_read_only(snapshot), "Blocked next loop remains read-only")


func _test_accepted_findings_build_second_decision_loop() -> void:
	var snapshot: Dictionary = NextLoop.build_snapshot(_accepted_findings(), _first_decision(), _firefight_decision(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Next-loop schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_963", "Next-loop task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_962", "Next-loop links TASK_962")
	_assert(String(snapshot.get("status", "")) == "ready_for_second_decision_loop", "Accepted findings arm second loop")
	_assert(bool(snapshot.get("active", false)), "Second loop is active")
	_assert(String(snapshot.get("primary_line", "")).begins_with("NEXT "), "Second loop exposes NEXT line")
	_assert(String(snapshot.get("why_line", "")).begins_with("WHY "), "Second loop exposes WHY line")
	_assert(_line_within_limit(String(snapshot.get("primary_line", "")), 96), "Primary line stays compact")
	_assert(_line_within_limit(String(snapshot.get("why_line", "")), 96), "WHY line stays compact")
	_assert(_second_choices_are_readable(Array(snapshot.get("second_decision_choices", []))), "Second decision choices are readable")
	_assert(_choice_ids(Array(snapshot.get("second_decision_choices", []))) == ["hold_angle", "advance_cover", "fallback_regroup"], "Second choices keep stable order")
	_assert(String(snapshot.get("visible_loop_line", "")).contains("HOLD"), "Visible loop line names hold option")
	_assert(String(snapshot.get("visible_loop_line", "")).contains("ADV"), "Visible loop line names advance option")
	_assert(String(snapshot.get("visible_loop_line", "")).contains("BACK"), "Visible loop line names fallback option")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Next loop recommends TASK_964")
	_assert(_snapshot_is_read_only(snapshot), "Accepted next loop remains read-only")


func _test_live_preview_source_is_honest_but_visible() -> void:
	var context: Dictionary = {"allow_live_preview_without_task_962_acceptance": true}
	var snapshot: Dictionary = NextLoop.build_snapshot({}, _first_decision(), _firefight_decision(), context)
	_assert(String(snapshot.get("status", "")) == "preview_available_needs_task_962_acceptance", "Live preview does not fake TASK_962 acceptance")
	_assert(bool(snapshot.get("active", false)), "Live preview still exposes the next loop")
	_assert(bool(snapshot.get("manual_acceptance_required", false)), "Live preview keeps manual acceptance required")
	_assert(not bool(snapshot.get("accepted_for_next_loop", true)), "Live preview is not accepted")
	_assert(String(snapshot.get("primary_line", "")).contains("NEXT"), "Live preview exposes NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Live preview remains read-only")


func _test_controller_exports_next_playable_loop() -> void:
	var controller_script: Resource = load(CONTROLLER_PATH)
	if controller_script == null:
		_assert(false, "Controller script can be loaded")
		return
	var controller: Node = controller_script.new()
	get_root().add_child(controller)
	await process_frame
	_assert(controller.has_method("get_release_first_decision_next_playable_loop_snapshot"), "Controller has TASK_963 public snapshot")
	if not controller.has_method("get_release_first_decision_next_playable_loop_snapshot"):
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call(
		"get_release_first_decision_next_playable_loop_snapshot",
		_accepted_findings(),
		_first_decision(),
		_firefight_decision()
	))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_963 schema matches")
	_assert(bool(snapshot.get("active", false)), "Controller TASK_963 loop is active with accepted source")
	_assert(_second_choices_are_readable(Array(snapshot.get("second_decision_choices", []))), "Controller TASK_963 choices are readable")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(Dictionary(feedback.get("release_first_decision_next_playable_loop", {})).get("schema", "")) == SCHEMA, "Command feedback embeds TASK_963")
	_assert(String(feedback.get("release_first_decision_next_loop_line", "")).contains("NEXT"), "Command feedback exports TASK_963 line")
	_assert(_snapshot_is_read_only(Dictionary(feedback.get("release_first_decision_next_playable_loop", {}))), "Command feedback TASK_963 remains read-only")
	controller.queue_free()


func _test_next_loop_roundtrip() -> void:
	var snapshot: Dictionary = NextLoop.build_snapshot(_accepted_findings(), _first_decision(), _firefight_decision(), {})
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_963 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_963", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_962", "Roundtrip keeps TASK_962 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _accepted_findings() -> Dictionary:
	return {
		"schema": FINDINGS_SCHEMA,
		"task_id": "TASK_962",
		"source_task_id": "TASK_961",
		"status": "accepted_for_release_first_decision_next_loop",
		"accepted": true,
		"manual_review_required": true,
		"manual_review_done": true,
		"positive_findings": [
			{"id": "first_decision_preview_readable"},
			{"id": "go_and_post_go_feedback_readable"},
			{"id": "player_readability_ok"},
		],
		"issues": [],
		"blocking_issues": [],
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _first_decision() -> Dictionary:
	return {
		"schema": FIRST_DECISION_SCHEMA,
		"task_id": "TASK_956",
		"gate": "pass",
		"status": "ready_for_first_decision_micro_scenario",
		"primary_cue_line": "NEXT Gedeckt pruefen -> GO",
		"why_line": "WHY Deckung ok, 0 Feindlinie",
		"after_go_line": "Nach GO: Bewegung startet; Kontakt-Feedback beobachten",
		"choice_row_count": 3,
		"choice_rows": [
			{"risk_token": "SAFE", "player_label": "Gedeckt"},
			{"risk_token": "RISKY", "player_label": "Querung"},
			{"risk_token": "SUICIDAL", "player_label": "Killzone"},
		],
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _firefight_decision() -> Dictionary:
	return {
		"active": true,
		"decision_line": "NEXT HIT LESEN / DEFEND | WHY FEUER",
		"next_token": "HIT LESEN / DEFEND",
		"why_token": "FEUER",
		"line_within_limit": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _second_choices_are_readable(choices: Array) -> bool:
	if choices.size() != 3:
		return false
	for choice_variant in choices:
		if typeof(choice_variant) != TYPE_DICTIONARY:
			return false
		var choice: Dictionary = Dictionary(choice_variant)
		for key in ["choice_id", "label", "player_text", "command_hint", "risk_label"]:
			if String(choice.get(key, "")).strip_edges().is_empty():
				return false
		if _contains_raw_first_choice_id(String(choice.get("label", ""))) or _contains_raw_first_choice_id(String(choice.get("player_text", ""))):
			return false
	return true


func _choice_ids(choices: Array) -> Array:
	var ids: Array = []
	for choice_variant in choices:
		ids.append(String(Dictionary(choice_variant).get("choice_id", "")))
	return ids


func _line_within_limit(line: String, limit: int) -> bool:
	return not line.strip_edges().is_empty() and line.length() <= limit and not _contains_raw_first_choice_id(line)


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _contains_raw_first_choice_id(text: String) -> bool:
	return text.contains("covered_push") or text.contains("exposed_crossing") or text.contains("kill_zone_dash")


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
