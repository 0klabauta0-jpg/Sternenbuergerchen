extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1026_release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.v1"
const NEXT_TASK := "TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke"
const POLISH_TASK := "TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1026 Release First Decision Loop Two Player Loop Scenario Ship Readiness Review ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_accepted_source_without_packet_needs_ship_readiness_packet()
	_test_incomplete_packet_routes_to_ship_readiness_polish()
	_test_good_packet_marks_ship_readiness_ready()
	_test_controller_exports_ship_readiness_review()
	_test_ship_readiness_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1026_release_first_decision_loop_two_player_loop_scenario_ship_readiness_review: FAILED")
		quit(1)
		return
	print("TASK_1026_release_first_decision_loop_two_player_loop_scenario_ship_readiness_review: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1026 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1026 ship-readiness service exists")
	_assert(task_text.contains("TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Review"), "Task names TASK_1026")
	_assert(task_text.contains(NEXT_TASK), "Task names visible ship smoke follow-up")
	_assert(status_text.contains("TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Review"), "Implementation status tracks TASK_1026")
	_assert(roadmap_text.contains("TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Review (implementiert"), "Roadmap marks TASK_1026 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Ship Readiness Review (TASK_1026)"), "Mission feedback contract documents TASK_1026")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Ship Readiness Review (TASK_1026)"), "Decision clarity contract documents TASK_1026")
	_assert(service_text.contains(SCHEMA), "Ship-readiness service exposes stable TASK_1026 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1026\""), "Ship-readiness service writes TASK_1026 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1025\""), "Ship-readiness service links TASK_1025")
	_assert(service_text.contains("REQUIRED_SHIP_READINESS_ITEMS"), "Ship-readiness service defines required items")
	_assert(service_text.contains("\"ship_readiness_ready\""), "Ship-readiness exposes ready flag")
	_assert(service_text.contains("\"ready_for_visible_ship_smoke\""), "Ship-readiness exposes visible-smoke readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Ship-readiness creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Ship-readiness creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Ship-readiness creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_SHIP_READINESS_REVIEW_SCRIPT"), "Controller preloads TASK_1026 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_ship_readiness_review_snapshot"), "Controller exposes TASK_1026 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_ship_readiness_review_line"), "Command feedback exports TASK_1026 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_ship_readiness_review_status"), "Command feedback exports TASK_1026 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1026")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_rc_not_accepted"), "Missing source reports RC acceptance mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked ship-readiness snapshot remains read-only")


func _test_accepted_source_without_packet_needs_ship_readiness_packet() -> void:
	var snapshot: Dictionary = _build_snapshot(_release_candidate_acceptance(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1026")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1026", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1025", "Snapshot links TASK_1025")
	_assert(String(snapshot.get("source_status", "")) == "release_candidate_accepted", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_ship_readiness_packet", "Accepted source without packet needs ship-readiness packet")
	_assert(String(snapshot.get("gate", "")) == "needs_ship_readiness_packet", "Gate asks for ship-readiness packet")
	_assert(issue_ids.has("ship_readiness_packet_missing"), "Missing ship-readiness packet is explicit")
	_assert(not bool(snapshot.get("ship_readiness_ready", true)), "Missing packet does not mark ship-readiness ready")
	_assert(_snapshot_is_read_only(snapshot), "Packet-needed snapshot remains read-only")


func _test_incomplete_packet_routes_to_ship_readiness_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_release_candidate_acceptance(), _incomplete_packet())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_items: Array = Array(snapshot.get("missing_ship_readiness_items", []))
	_assert(String(snapshot.get("status", "")) == "ship_readiness_incomplete", "Incomplete packet reports incomplete ship readiness")
	_assert(String(snapshot.get("gate", "")) == "ship_readiness_incomplete", "Incomplete packet gate names ship readiness")
	_assert(missing_items.has("tester_instructions"), "Incomplete packet records missing tester instructions")
	_assert(missing_items.has("known_risks"), "Incomplete packet records missing known risks")
	_assert(issue_ids.has("ship_readiness_items_missing"), "Missing readiness items issue is explicit")
	_assert(issue_ids.has("tester_instructions_missing"), "Missing tester instructions issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Incomplete packet routes to ship-readiness polish")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete packet snapshot remains read-only")


func _test_good_packet_marks_ship_readiness_ready() -> void:
	var snapshot: Dictionary = _build_snapshot(_release_candidate_acceptance(), _good_packet())
	var items: Dictionary = Dictionary(snapshot.get("ship_readiness_items", {}))
	_assert(String(snapshot.get("status", "")) == "ship_readiness_ready", "Good packet marks ship-readiness ready")
	_assert(String(snapshot.get("gate", "")) == "ship_readiness_ready", "Good packet gate ready")
	_assert(bool(snapshot.get("ship_readiness_ready", false)), "Good packet sets ship-readiness flag")
	_assert(bool(snapshot.get("ready_for_visible_ship_smoke", false)), "Good packet is ready for visible ship smoke")
	_assert(String(snapshot.get("ship_readiness_line", "")).contains("SHIP READY"), "Readiness line names ship ready")
	_assert(String(snapshot.get("ship_readiness_line", "")).contains("FOB"), "Readiness line names FOB")
	_assert(String(snapshot.get("ship_readiness_line", "")).contains("NEXT"), "Readiness line names NEXT")
	_assert(String(snapshot.get("ship_readiness_line", "")).contains("GO"), "Readiness line names GO")
	_assert(String(snapshot.get("ship_readiness_line", "")).contains("FEEDBACK"), "Readiness line names feedback")
	_assert(String(items.get("release_build_path", "")).ends_with(".exe"), "Good packet carries release exe path")
	_assert(String(items.get("tester_instructions", "")).contains("Singleplayer"), "Good packet carries tester instructions")
	_assert(Array(items.get("known_risks", [])).size() >= 1, "Good packet carries known risks")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Ready packet recommends visible ship smoke")
	_assert(_snapshot_is_read_only(snapshot), "Ready packet remains read-only")


func _test_controller_exports_ship_readiness_review() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_ship_readiness_review_snapshot"):
		_assert(false, "Controller exposes TASK_1026 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_ship_readiness_review_snapshot(_release_candidate_acceptance(), _good_packet())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1026 schema matches")
	_assert(String(snapshot.get("status", "")) == "ship_readiness_ready", "Controller TASK_1026 ready with packet")
	_assert(String(snapshot.get("ship_readiness_line", "")).contains("NEXT"), "Controller TASK_1026 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1026 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_ship_readiness_review"), "Command feedback embeds TASK_1026")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_ship_readiness_review_line"), "Command feedback exports TASK_1026 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_ship_readiness_review_status"), "Command feedback exports TASK_1026 status")
	controller.queue_free()


func _test_ship_readiness_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_release_candidate_acceptance(), _good_packet())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1026 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1026", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1025", "Roundtrip keeps TASK_1025 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_acceptance: Dictionary, packet: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1026 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1026 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_acceptance, packet)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1026 service returns dictionary")
	return _read_only_fallback()


func _release_candidate_acceptance() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1025",
		"source_task_id": "TASK_1024",
		"status": "release_candidate_accepted",
		"gate": "release_candidate_accepted",
		"release_candidate_acceptance_line": "RC ACCEPTANCE ACCEPTED: FOB | NEXT | GO | FEEDBACK | rund",
		"release_candidate_accepted": true,
		"ready_for_ship_readiness_review": true,
		"source_release_build_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.exe",
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


func _good_packet() -> Dictionary:
	return {
		"packet_available": true,
		"release_build_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.exe",
		"pck_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.pck",
		"scenario_id": "release_first_decision_loop_two_player_loop",
		"tester_instructions": "Starte Singleplayer, pruefe FOB, NEXT, GO und FEEDBACK ohne Input-Sackgasse.",
		"operator_goal": "FOB/NEXT/GO/FEEDBACK als kleinen Spielmoment sichtbar spielen.",
		"known_risks": ["Manueller RC-Playtest muss noch sichtbar wiederholt werden."],
		"handoff_items": ["release_build_path", "tester_instructions", "known_risks", "multiplayer_boundary_note"],
		"multiplayer_boundary_note": "Test bleibt singleplayer-sichtbar; Multiplayer-Wahrheit wird nicht gesetzt.",
		"hud_truth_note": "HUD liest nur Snapshot-Status und setzt keine Gameplay-Wahrheit.",
		"ship_readiness_reviewed": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _incomplete_packet() -> Dictionary:
	var packet: Dictionary = _good_packet()
	packet.erase("tester_instructions")
	packet.erase("known_risks")
	packet["ship_readiness_reviewed"] = false
	return packet


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
