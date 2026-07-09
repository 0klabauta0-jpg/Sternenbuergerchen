extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_950_wire_decision_scenario_into_f6_mission_hud.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH := "res://scripts/mission/order_preview_threat_overlay_playtest_scenario.gd"
const SCHEMA := "sternenbuergerchen.order_preview_threat_overlay_f6_hud.v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_950 Wire Decision Scenario Into F6 Mission HUD ===")
	_test_docs_and_static_hooks()
	await _test_controller_exports_decision_overlay_hud_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_950_wire_decision_scenario_into_f6_mission_hud: FAILED")
		quit(1)
		return
	print("TASK_950_wire_decision_scenario_into_f6_mission_hud: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_950 task file exists")
	_assert(task_text.contains("TASK_950 - Wire Decision Scenario Into F6 Mission HUD"), "Task names TASK_950")
	_assert(status_text.contains("TASK_950 - Wire Decision Scenario Into F6 Mission HUD"), "Implementation status tracks TASK_950")
	_assert(roadmap_text.contains("TASK_950 - Wire Decision Scenario Into F6 Mission HUD (implementiert"), "Roadmap marks TASK_950 implemented")
	_assert(command_contract_text.contains("F6 Mission HUD Wiring (TASK_950)"), "Mission feedback contract documents TASK_950")
	_assert(clarity_contract_text.contains("F6 Mission HUD Wiring (TASK_950)"), "Decision clarity contract documents TASK_950")
	_assert(controller_text.contains("ORDER_PREVIEW_THREAT_OVERLAY_PLAYTEST_SCENARIO_SCRIPT"), "Controller preloads TASK_949 scenario service")
	_assert(controller_text.contains("get_order_preview_threat_overlay_f6_hud_snapshot"), "Controller exposes TASK_950 snapshot")
	_assert(controller_text.contains("_build_order_preview_threat_overlay_f6_choice_line"), "Controller builds compact choice line")
	_assert(controller_text.contains("order_preview_threat_overlay_choice_line"), "Command feedback exports choice line")
	_assert(controller_text.contains("\"creates_command\": false"), "Controller keeps TASK_950 read-only command boundary")
	_assert(controller_text.contains("\"creates_movement\": false"), "Controller keeps TASK_950 read-only movement boundary")


func _test_controller_exports_decision_overlay_hud_snapshot() -> void:
	var controller_script: Resource = load(CONTROLLER_PATH)
	if controller_script == null:
		_assert(false, "Controller script can be loaded")
		return
	var controller: Node = controller_script.new()
	get_root().add_child(controller)
	await process_frame
	_assert(controller.has_method("get_order_preview_threat_overlay_f6_hud_snapshot"), "Controller has TASK_950 public snapshot method")
	if not controller.has_method("get_order_preview_threat_overlay_f6_hud_snapshot"):
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_order_preview_threat_overlay_f6_hud_snapshot"))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "HUD snapshot schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_950", "HUD snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_949", "HUD snapshot links TASK_949")
	_assert(String(snapshot.get("gate", "")) == "pass", "HUD snapshot gate passes")
	_assert(int(snapshot.get("visible_choice_count", 0)) == 3, "HUD snapshot exposes three visible choices")
	var line: String = String(snapshot.get("mission_control_choice_line", ""))
	_assert(line.contains("SAFE") and line.contains("RISKY") and line.contains("SUICIDAL"), "Mission Control line names all risk states")
	_assert(line.length() <= int(snapshot.get("choice_line_char_limit", 128)), "Mission Control choice line stays compact")
	_assert(String(snapshot.get("recommended_choice_id", "")) == "covered_push", "HUD snapshot keeps safe recommendation")
	_assert(_snapshot_is_read_only(snapshot), "HUD snapshot remains read-only")
	var cards: Array = Array(snapshot.get("visible_choice_cards", []))
	_assert(_cards_have_choice(cards, "covered_push", "safe"), "Choice cards include safe covered push")
	_assert(_cards_have_choice(cards, "exposed_crossing", "risky"), "Choice cards include risky exposed crossing")
	_assert(_cards_have_choice(cards, "kill_zone_dash", "suicidal"), "Choice cards include suicidal kill-zone dash")
	_assert(controller.has_method("get_command_feedback_snapshot"), "Controller still exposes command feedback snapshot")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(feedback.get("order_preview_threat_overlay_choice_line", "")) == line, "Command feedback exports TASK_950 choice line")
	_assert(String(Dictionary(feedback.get("order_preview_threat_overlay_f6_hud", {})).get("schema", "")) == SCHEMA, "Command feedback embeds TASK_950 snapshot")
	_assert(String(feedback.get("mission_control_status_text", "")).contains(line), "Mission Control status text contains decision choice line")
	controller.queue_free()


func _cards_have_choice(cards: Array, expected_id: String, expected_risk: String) -> bool:
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("choice_id", "")) == expected_id and String(card.get("risk_state", "")) == expected_risk:
			return bool(card.get("visible_before_go", false)) and not String(card.get("text", "")).is_empty()
	return false


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


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
