extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1029_release_first_decision_loop_two_player_loop_scenario_handoff_packet.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_handoff_packet.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_handoff_packet.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_handoff_packet.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_delivery_review.v1"
const NEXT_TASK := "TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run"
const POLISH_TASK := "TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1029 Release First Decision Loop Two Player Loop Scenario Handoff Packet ===")
	_test_docs_and_static_hooks()
	_test_missing_delivery_review_blocks()
	_test_unready_delivery_review_blocks()
	_test_ready_delivery_without_packet_needs_handoff()
	_test_incomplete_packet_routes_to_completion()
	_test_issue_flags_route_to_handoff_polish()
	_test_clean_packet_marks_tester_run_ready()
	_test_controller_exports_handoff_packet()
	_test_handoff_packet_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1029_release_first_decision_loop_two_player_loop_scenario_handoff_packet: FAILED")
		quit(1)
		return
	print("TASK_1029_release_first_decision_loop_two_player_loop_scenario_handoff_packet: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1029 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1029 handoff-packet service exists")
	_assert(task_text.contains("TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet"), "Task names TASK_1029")
	_assert(task_text.contains(NEXT_TASK), "Task names tester-run follow-up")
	_assert(status_text.contains("TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet"), "Implementation status tracks TASK_1029")
	_assert(roadmap_text.contains("TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet (implementiert"), "Roadmap marks TASK_1029 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Handoff Packet (TASK_1029)"), "Mission feedback contract documents TASK_1029")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Handoff Packet (TASK_1029)"), "Decision clarity contract documents TASK_1029")
	_assert(service_text.contains(SCHEMA), "Handoff-packet service exposes stable TASK_1029 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1029\""), "Handoff-packet service writes TASK_1029 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1028\""), "Handoff-packet service links TASK_1028")
	_assert(service_text.contains("REQUIRED_HANDOFF_PACKET_ITEMS"), "Handoff-packet service defines required items")
	_assert(service_text.contains("\"handoff_packet_ready\""), "Handoff-packet service exposes ready flag")
	_assert(service_text.contains("\"ready_for_tester_run\""), "Handoff packet exposes tester-run readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Handoff packet creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Handoff packet creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Handoff packet creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_HANDOFF_PACKET_SCRIPT"), "Controller preloads TASK_1029 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_handoff_packet_snapshot"), "Controller exposes TASK_1029 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_handoff_packet_line"), "Command feedback exports TASK_1029 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_handoff_packet_status"), "Command feedback exports TASK_1029 status")


func _test_missing_delivery_review_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_delivery_review", "Missing source blocks TASK_1029")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_delivery_review_not_ready"), "Missing source reports delivery-review mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked handoff snapshot remains read-only")


func _test_unready_delivery_review_blocks() -> void:
	var source: Dictionary = _delivery_review_ready()
	source["status"] = "needs_delivery_review"
	source["delivery_review_ready"] = false
	source["ready_for_handoff_packet"] = false
	var snapshot: Dictionary = _build_snapshot(source, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_delivery_review", "Unready TASK_1028 source blocks")
	_assert(blocker_ids.has("source_delivery_review_not_ready"), "Unready source reports delivery-review mismatch")
	_assert(not bool(snapshot.get("handoff_packet_ready", true)), "Unready source is not handoff-ready")
	_assert(_snapshot_is_read_only(snapshot), "Unready-source handoff remains read-only")


func _test_ready_delivery_without_packet_needs_handoff() -> void:
	var snapshot: Dictionary = _build_snapshot(_delivery_review_ready(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_items: Array = Array(snapshot.get("missing_handoff_packet_items", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1029")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1029", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1028", "Snapshot links TASK_1028")
	_assert(String(snapshot.get("source_status", "")) == "delivery_review_ready", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_handoff_packet", "Ready source without packet needs handoff packet")
	_assert(String(snapshot.get("gate", "")) == "needs_handoff_packet", "Gate asks for handoff packet")
	_assert(issue_ids.has("handoff_packet_notes_missing"), "Missing handoff notes are explicit")
	_assert(missing_items.has("start_instruction_written"), "Missing notes expose start instruction item")
	_assert(not bool(snapshot.get("handoff_packet_ready", true)), "Missing notes do not mark handoff ready")
	_assert(_snapshot_is_read_only(snapshot), "Handoff-needed snapshot remains read-only")


func _test_incomplete_packet_routes_to_completion() -> void:
	var snapshot: Dictionary = _build_snapshot(_delivery_review_ready(), _incomplete_packet())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_items: Array = Array(snapshot.get("missing_handoff_packet_items", []))
	_assert(String(snapshot.get("status", "")) == "needs_handoff_packet_completion", "Incomplete packet reports completion need")
	_assert(String(snapshot.get("gate", "")) == "needs_handoff_packet_completion", "Incomplete packet gate names completion")
	_assert(missing_items.has("risk_summary_written"), "Incomplete packet records missing risk summary")
	_assert(missing_items.has("next_tester_action_written"), "Incomplete packet records missing next tester action")
	_assert(issue_ids.has("handoff_packet_items_missing"), "Missing handoff items issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet", "Incomplete packet loops on TASK_1029")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete handoff snapshot remains read-only")


func _test_issue_flags_route_to_handoff_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_delivery_review_ready(), _packet(true, _all_item_ids(), ["stale_handoff_package", "start_steps_unclear"]))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "handoff_packet_regression_found", "Issue flags report handoff regression")
	_assert(String(snapshot.get("gate", "")) == "handoff_packet_regression_found", "Issue gate reports handoff regression")
	_assert(issue_ids.has("handoff_packet_issue_stale_handoff_package"), "Stale handoff issue is explicit")
	_assert(issue_ids.has("handoff_packet_issue_start_steps_unclear"), "Start-step issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Issue flags route to handoff polish")
	_assert(_snapshot_is_read_only(snapshot), "Issue handoff remains read-only")


func _test_clean_packet_marks_tester_run_ready() -> void:
	var snapshot: Dictionary = _build_snapshot(_delivery_review_ready(), _packet(true, _all_item_ids(), []))
	var line: String = String(snapshot.get("handoff_packet_line", ""))
	_assert(String(snapshot.get("status", "")) == "handoff_packet_ready", "Clean packet marks handoff ready")
	_assert(String(snapshot.get("gate", "")) == "handoff_packet_ready", "Clean packet gate ready")
	_assert(bool(snapshot.get("handoff_packet_ready", false)), "Clean packet sets handoff-ready flag")
	_assert(bool(snapshot.get("ready_for_tester_run", false)), "Clean packet is ready for tester run")
	_assert(line.contains("HANDOFF READY"), "Handoff line names ready")
	_assert(line.contains("EXE"), "Handoff line names EXE")
	_assert(line.contains("FOB"), "Handoff line names FOB")
	_assert(line.contains("NEXT"), "Handoff line names NEXT")
	_assert(line.contains("GO"), "Handoff line names GO")
	_assert(line.contains("FEEDBACK"), "Handoff line names feedback")
	_assert(String(snapshot.get("release_build_path", "")).ends_with(".exe"), "Clean packet carries release exe path")
	_assert(Dictionary(snapshot.get("handoff_notes", {})).has("start_instruction"), "Clean packet carries start instruction")
	_assert(Array(snapshot.get("test_steps", [])).size() >= 4, "Clean packet exposes tester steps")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Clean packet recommends tester run")
	_assert(_snapshot_is_read_only(snapshot), "Clean packet remains read-only")


func _test_controller_exports_handoff_packet() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_handoff_packet_snapshot"):
		_assert(false, "Controller exposes TASK_1029 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_handoff_packet_snapshot(_delivery_review_ready(), _packet(true, _all_item_ids(), []))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1029 schema matches")
	_assert(String(snapshot.get("status", "")) == "handoff_packet_ready", "Controller TASK_1029 ready with packet")
	_assert(String(snapshot.get("handoff_packet_line", "")).contains("NEXT"), "Controller TASK_1029 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1029 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_handoff_packet"), "Command feedback embeds TASK_1029")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_handoff_packet_line"), "Command feedback exports TASK_1029 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_handoff_packet_status"), "Command feedback exports TASK_1029 status")
	controller.queue_free()


func _test_handoff_packet_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_delivery_review_ready(), _packet(true, _all_item_ids(), []))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1029 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1029", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1028", "Roundtrip keeps TASK_1028 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_delivery_review: Dictionary, handoff_packet_notes: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1029 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1029 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_delivery_review, handoff_packet_notes)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1029 service returns dictionary")
	return _read_only_fallback()


func _delivery_review_ready() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1028",
		"source_task_id": "TASK_1027",
		"status": "delivery_review_ready",
		"gate": "delivery_review_ready",
		"delivery_review_line": "DELIVERY READY: EXE | FOB | NEXT | GO | FEEDBACK | Handoff-Paket kann geschnitten werden.",
		"delivery_review_ready": true,
		"ready_for_handoff_packet": true,
		"release_build_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.exe",
		"pck_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.pck",
		"scenario_id": "release_first_decision_loop_two_player_loop",
		"tester_instructions": "Starte Singleplayer, pruefe FOB, NEXT, GO und FEEDBACK.",
		"operator_goal": "FOB/NEXT/GO/FEEDBACK als kleinen Spielmoment sichtbar spielen.",
		"known_risks": ["Manueller Sichttest bleibt noetig."],
		"delivery_notes": {
			"start_instruction": "Starte die frische EXE, klicke Einzelspieler, pruefe FOB/NEXT/GO/FEEDBACK.",
			"shortcut_warning": "Nicht die alte Taskleisten-Verknuepfung nutzen.",
			"risk_note": "Restrisiken fuer manuellen Sichttest akzeptiert.",
			"handoff_note": "Naechster Schritt ist ein kleines Handoff-Paket.",
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


func _incomplete_packet() -> Dictionary:
	return _packet(true, ["delivery_review_ready", "release_files_named", "start_instruction_written", "shortcut_warning_written"], [])


func _packet(done: bool, completed_items: Array, issue_ids: Array) -> Dictionary:
	return {
		"handoff_packet_available": true,
		"handoff_packet_done": done,
		"completed_handoff_packet_items": completed_items,
		"issue_flags": issue_ids,
		"start_instruction": "Starte die frische EXE, klicke Einzelspieler, pruefe FOB/NEXT/GO/FEEDBACK.",
		"shortcut_warning": "Nicht die alte Taskleisten-Verknuepfung nutzen.",
		"risk_summary": "Manueller Sichttest bleibt noetig, ist fuer diesen Handoff akzeptiert.",
		"next_tester_action": "TASK_1030 Tester Run mit frischer EXE ausfuehren.",
		"multiplayer_note": "Zwei-Spieler-Kontext bleibt vorbereitet, aber dieses Paket setzt keine Multiplayer-Wahrheit.",
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _all_item_ids() -> Array:
	return [
		"delivery_review_ready",
		"release_files_named",
		"start_instruction_written",
		"shortcut_warning_written",
		"risk_summary_written",
		"next_tester_action_written",
		"multiplayer_boundary_preserved",
		"hud_truth_boundary_preserved",
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
