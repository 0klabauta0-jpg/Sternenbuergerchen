extends SceneTree

const VisualPolish := preload("res://scripts/mission/release_first_decision_loop_two_player_loop_visual_polish.gd")
const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_983_release_first_decision_loop_two_player_loop_visual_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_visual_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_visual_polish_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_visual_polish.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_visual_findings.v1"
const RUNTIME_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_runtime_choice_buttons.v1"
const NEXT_TASK := "TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_983 Release First Decision Loop Two Player Loop Visual Polish ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_issue_source_builds_button_visual_polish()
	_test_accepted_source_still_exports_polish_contract()
	_test_controller_exports_player_loop_visual_polish()
	_test_visual_polish_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_983_release_first_decision_loop_two_player_loop_visual_polish: FAILED")
		quit(1)
		return
	print("TASK_983_release_first_decision_loop_two_player_loop_visual_polish: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_983 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_983 visual polish service exists")
	_assert(task_text.contains("TASK_983 - Release First Decision Loop Two Player Loop Visual Polish"), "Task names TASK_983")
	_assert(task_text.contains(NEXT_TASK), "Task names acceptance follow-up")
	_assert(status_text.contains("TASK_983 - Release First Decision Loop Two Player Loop Visual Polish"), "Implementation status tracks TASK_983")
	_assert(roadmap_text.contains("TASK_983 - Release First Decision Loop Two Player Loop Visual Polish (implementiert"), "Roadmap marks TASK_983 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Visual Polish (TASK_983)"), "Mission feedback contract documents TASK_983")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Visual Polish (TASK_983)"), "Decision clarity contract documents TASK_983")
	_assert(service_text.contains(SCHEMA), "Visual polish service exposes stable TASK_983 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_983\""), "Visual polish service writes TASK_983 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_982\""), "Visual polish service links TASK_982")
	_assert(service_text.contains("RUNTIME_TASK_ID: String = \"TASK_979\""), "Visual polish service links TASK_979")
	_assert(service_text.contains("\"button_visual_specs\""), "Visual polish exposes button visual specs")
	_assert(service_text.contains("\"button_min_width\""), "Visual polish exposes minimum button width")
	_assert(service_text.contains("\"choice_feedback_line\""), "Visual polish exposes feedback line")
	_assert(service_text.contains("\"creates_command\": false"), "Visual polish creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Visual polish creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_VISUAL_POLISH_SCRIPT"), "Controller preloads TASK_983 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_visual_polish_snapshot"), "Controller exposes TASK_983 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_visual_polish_line"), "Command feedback exports TASK_983 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_visual_polish_task"), "Choice buttons store TASK_983 polish meta")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = VisualPolish.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_983")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_polishable"), "Missing source reports non-polishable source")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_issue_source_builds_button_visual_polish() -> void:
	var snapshot: Dictionary = VisualPolish.build_snapshot(_issue_source(), _runtime_buttons_source())
	var specs: Array = Array(snapshot.get("button_visual_specs", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_983")
	_assert(String(snapshot.get("task_id", "")) == "TASK_983", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_982", "Snapshot links TASK_982")
	_assert(String(snapshot.get("runtime_task_id", "")) == "TASK_979", "Snapshot links TASK_979")
	_assert(String(snapshot.get("status", "")) == "player_loop_visual_polish_ready", "Issue source builds visual polish")
	_assert(bool(snapshot.get("active", false)), "Visual polish is active")
	_assert(int(snapshot.get("button_visual_spec_count", 0)) == 4, "Visual polish has four button specs")
	_assert(String(snapshot.get("choice_group_line", "")).contains("SECURE"), "Group line names SECURE")
	_assert(String(snapshot.get("choice_group_line", "")).contains("GO separat"), "Group line keeps GO separate")
	_assert(String(snapshot.get("choice_feedback_line", "")).contains("Confirm"), "Feedback line names confirm")
	_assert(String(snapshot.get("choice_feedback_line", "")).contains("GO"), "Feedback line points to GO")
	_assert(_visual_specs_are_polished(specs), "Button visual specs are polished")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Visual polish recommends acceptance slice")
	_assert(_snapshot_is_read_only(snapshot), "Visual polish remains read-only")


func _test_accepted_source_still_exports_polish_contract() -> void:
	var snapshot: Dictionary = VisualPolish.build_snapshot(_accepted_source(), _runtime_buttons_source())
	_assert(String(snapshot.get("status", "")) == "player_loop_visual_polish_ready", "Accepted source keeps visual polish ready")
	_assert(String(snapshot.get("source_status", "")) == "accepted_for_player_loop_acceptance_slice", "Accepted source status is recorded")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Accepted source recommends acceptance slice")
	_assert(String(snapshot.get("recommended_direction", "")) == "build_player_loop_acceptance_slice", "Accepted source recommends acceptance direction")
	_assert(_snapshot_is_read_only(snapshot), "Accepted polish remains read-only")


func _test_controller_exports_player_loop_visual_polish() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_visual_polish_snapshot(_issue_source(), _runtime_buttons_source())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_983 schema matches")
	_assert(int(snapshot.get("button_visual_spec_count", 0)) == 4, "Controller TASK_983 has four specs")
	_assert(String(snapshot.get("choice_group_line", "")).contains("RESET"), "Controller TASK_983 line names reset")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_983 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_visual_polish"), "Command feedback embeds TASK_983")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_visual_polish_line"), "Command feedback exports TASK_983 line")
	controller.queue_free()


func _test_visual_polish_roundtrip() -> void:
	var snapshot: Dictionary = VisualPolish.build_snapshot(_issue_source(), _runtime_buttons_source())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_983 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_983", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_982", "Roundtrip keeps TASK_982 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _issue_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_982",
		"source_task_id": "TASK_981",
		"status": "ready_for_player_loop_visual_polish",
		"manual_review_done": true,
		"issue_count": 3,
		"issues": [
			{"id": "runtime_choice_buttons_not_readable", "text": "Choice-Buttons brauchen mehr Leseflaeche."},
			{"id": "choice_confirm_feedback_not_visible", "text": "Confirm-Feedback muss sichtbarer werden."},
			{"id": "player_readability_not_ok", "text": "Vier-Choice-Loop wirkt noch nicht rund."},
		],
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _accepted_source() -> Dictionary:
	var source: Dictionary = _issue_source()
	source["status"] = "accepted_for_player_loop_acceptance_slice"
	source["issue_count"] = 0
	source["issues"] = []
	return source


func _runtime_buttons_source() -> Dictionary:
	return {
		"schema": RUNTIME_SCHEMA,
		"task_id": "TASK_979",
		"source_task_id": "TASK_978",
		"status": "runtime_choice_buttons_ready",
		"gate": "runtime_choice_buttons_ready",
		"active": true,
		"button_specs": [
			_spec("secure_area", "SECURE", "CommandSlot08", "defend"),
			_spec("push_objective", "PUSH", "CommandSlot09", "move"),
			_spec("flank_pressure", "FLANK", "CommandSlot10", "flank"),
			_spec("reset_spacing", "RESET", "CommandSlot11", "move"),
		],
		"button_count": 4,
		"runtime_buttons_line": "CHOICE BUTTONS SECURE / PUSH / FLANK / RESET | GO separat",
		"press_action": "confirm_release_first_decision_loop_two_player_loop_choice_button",
		"execute_action": "execute_selected_fireteam_orders",
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _spec(choice_id: String, text: String, slot_name: String, command_type: String) -> Dictionary:
	return {
		"choice_id": choice_id,
		"button_text": text,
		"slot_name": slot_name,
		"slot_path": "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/%s" % slot_name,
		"command_type": command_type,
		"press_action": "confirm_release_first_decision_loop_two_player_loop_choice_button",
		"execute_action": "execute_selected_fireteam_orders",
		"button_enabled": true,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


func _visual_specs_are_polished(specs: Array) -> bool:
	if specs.size() != 4:
		return false
	for spec_variant in specs:
		var spec := Dictionary(spec_variant)
		if float(spec.get("button_min_width", 0.0)) < 74.0:
			return false
		if float(spec.get("button_min_height", 0.0)) < 44.0:
			return false
		if not String(spec.get("button_tooltip", "")).contains("GO separat"):
			return false
		if String(spec.get("visual_style_id", "")).is_empty():
			return false
		if bool(spec.get("creates_command", true)):
			return false
	return true


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
