extends SceneTree

const Polish := preload("res://scripts/mission/release_first_decision_loop_two_visual_polish.gd")
const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_971_release_first_decision_loop_two_visual_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_visual_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_visual_polish_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_visual_polish.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_visual_findings.v1"
const RUNTIME_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_runtime_button.v1"
const NEXT_TASK := "TASK_972 - Release First Decision Loop Two Playability Smoke"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_971 Release First Decision Loop Two Visual Polish ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_issue_source_builds_visual_polish()
	_test_clean_source_routes_to_playability_smoke()
	_test_controller_exports_visual_polish()
	_test_polish_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_971_release_first_decision_loop_two_visual_polish: FAILED")
		quit(1)
		return
	print("TASK_971_release_first_decision_loop_two_visual_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_971 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_971 visual polish service exists")
	_assert(task_text.contains("TASK_971 - Release First Decision Loop Two Visual Polish"), "Task names TASK_971")
	_assert(task_text.contains(NEXT_TASK), "Task names playability smoke follow-up")
	_assert(status_text.contains("TASK_971 - Release First Decision Loop Two Visual Polish"), "Implementation status tracks TASK_971")
	_assert(roadmap_text.contains("TASK_971 - Release First Decision Loop Two Visual Polish (implementiert"), "Roadmap marks TASK_971 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Visual Polish (TASK_971)"), "Mission feedback contract documents TASK_971")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Visual Polish (TASK_971)"), "Decision clarity contract documents TASK_971")
	_assert(service_text.contains(SCHEMA), "Polish service exposes stable TASK_971 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_971\""), "Polish service writes TASK_971 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_970\""), "Polish service links TASK_970")
	_assert(service_text.contains("\"button_text\": \"2ND\""), "Polish keeps compact 2ND button text")
	_assert(service_text.contains("\"go_separation_line\""), "Polish exposes GO separation line")
	_assert(service_text.contains("\"read_only\": true"), "Polish declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Polish creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Polish creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Polish creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_VISUAL_POLISH_SCRIPT"), "Controller preloads TASK_971 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_visual_polish_snapshot"), "Controller exposes TASK_971 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_visual_polish_line"), "Command feedback exports TASK_971 line")
	_assert(controller_text.contains("release_first_decision_loop_two_visual_polish_task"), "Button stores TASK_971 polish meta")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Polish.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_971")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_polishable"), "Missing source reports polishable mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_issue_source_builds_visual_polish() -> void:
	var snapshot: Dictionary = Polish.build_snapshot(_issue_source(), _runtime_button())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_971")
	_assert(String(snapshot.get("task_id", "")) == "TASK_971", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_970", "Snapshot links TASK_970")
	_assert(String(snapshot.get("status", "")) == "visual_polish_ready", "Issue source builds visual polish")
	_assert(bool(snapshot.get("active", false)), "Visual polish is active")
	_assert(String(snapshot.get("button_text", "")) == "2ND", "Button text remains compact")
	_assert(String(snapshot.get("button_tooltip", "")).contains("zweiten Griff"), "Tooltip explains second decision")
	_assert(String(snapshot.get("button_tooltip", "")).contains("GO separat"), "Tooltip explains separate GO")
	_assert(String(snapshot.get("hud_line", "")).contains("2ND"), "HUD line names 2ND")
	_assert(String(snapshot.get("hud_line", "")).contains("GO separat"), "HUD line keeps GO separate")
	_assert(String(snapshot.get("post_confirm_line", "")).contains("danach GO"), "Post-confirm line points to GO")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Visual polish recommends playability smoke")
	_assert(_snapshot_is_read_only(snapshot), "Visual polish remains read-only")


func _test_clean_source_routes_to_playability_smoke() -> void:
	var snapshot: Dictionary = Polish.build_snapshot(_accepted_source(), _runtime_button())
	_assert(String(snapshot.get("status", "")) == "visual_polish_ready", "Accepted source keeps visual polish ready")
	_assert(String(snapshot.get("source_status", "")) == "accepted_for_loop_two_playability_smoke", "Accepted source status is recorded")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Accepted source recommends playability smoke")
	_assert(String(snapshot.get("recommended_direction", "")) == "run_loop_two_playability_smoke", "Accepted source recommends smoke direction")
	_assert(_snapshot_is_read_only(snapshot), "Accepted polish remains read-only")


func _test_controller_exports_visual_polish() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_visual_polish_snapshot(_issue_source(), _runtime_button())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_971 schema matches")
	_assert(String(snapshot.get("button_text", "")) == "2ND", "Controller TASK_971 keeps button text")
	_assert(String(snapshot.get("hud_line", "")).contains("GO separat"), "Controller TASK_971 line keeps GO separate")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_971 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_visual_polish"), "Command feedback embeds TASK_971")
	_assert(String(feedback.get("release_first_decision_loop_two_visual_polish_line", "")).contains("2ND"), "Command feedback exports TASK_971 line")
	controller.queue_free()


func _test_polish_roundtrip() -> void:
	var snapshot: Dictionary = Polish.build_snapshot(_issue_source(), _runtime_button())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_971 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_971", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_970", "Roundtrip keeps TASK_970 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _issue_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_970",
		"source_task_id": "TASK_969",
		"source_schema": "sternenbuergerchen.release_first_decision_loop_two_real_window_capture.v1",
		"status": "ready_for_loop_two_visual_polish",
		"manual_review_done": true,
		"issue_count": 3,
		"issues": [
			{"id": "second_decision_button_not_visible", "text": "`2ND` ist zu schwach."},
			{"id": "go_button_separation_unclear", "text": "`GO` muss klar getrennt bleiben."},
			{"id": "post_confirm_feedback_not_readable", "text": "Feedback nach `2ND` ist zu duenn."},
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
	source["status"] = "accepted_for_loop_two_playability_smoke"
	source["issue_count"] = 0
	source["issues"] = []
	return source


func _runtime_button() -> Dictionary:
	return {
		"schema": RUNTIME_SCHEMA,
		"task_id": "TASK_968",
		"source_task_id": "TASK_967",
		"gate": "runtime_button_ready",
		"status": "ready_for_real_window_capture",
		"selected_choice_id": "hold_angle",
		"selected_command_type": "defend",
		"button_text": "2ND",
		"button_role": "second_decision_confirm",
		"button_slot_path": "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/CommandSlot07",
		"button_enabled": true,
		"button_tooltip": "2ND: zweiten Griff bestaetigen, danach GO separat ausfuehren.",
		"press_action": "confirm_release_first_decision_loop_two_runtime_button",
		"confirm_action": "_issue_command",
		"execute_action": "execute_selected_fireteam_orders",
		"separate_go_required": true,
		"auto_executes_go": false,
		"runtime_line": "2ND HOLD Defend | bereit | GO bleibt separat",
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
