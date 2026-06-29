extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TACTICAL_COMMAND_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_571_fire_rule_controls_readability_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const COMMAND_HIERARCHY_PATH: String = "res://scripts/ui/mission_command_hierarchy_contract.gd"
const MISSION_CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

const FIRE_RULE_BUTTON_PATHS: Dictionary = {
	"hold": "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FireRuleHoldButton",
	"return": "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FireRuleReturnButton",
	"free": "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FireRuleFreeButton",
	"suppress": "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FireRuleSuppressButton",
}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_571 Fire Rule Controls Readability Polish ===")
	_test_docs_and_wiring()
	await _test_fire_rule_controls_in_mission_hud()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_571: FAILED")
		quit(1)
		return
	print("TASK_571: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var hierarchy_text: String = _read_text(COMMAND_HIERARCHY_PATH)
	var controller_text: String = _read_text(MISSION_CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_571 task file exists")
	_assert(task_text.contains("Fire Rule Controls Readability Polish"), "TASK_571 task file names the polish")
	_assert(status_text.contains("TASK_571 - Fire Rule Controls Readability Polish"), "Implementation status tracks TASK_571")
	_assert(roadmap_text.contains("TASK_571 - Fire Rule Controls Readability Polish"), "Roadmap tracks TASK_571")
	_assert(report_text.contains("TASK_571 - Fire Rule Controls Readability Polish"), "HTML report tracks TASK_571")
	_assert(report_text.contains("TASK_572 - Fire Rule F6 Readability Smoke"), "HTML report names TASK_572 follow-up")
	_assert(report_text.contains("Fire Rule Controls Readability Polish"), "HTML report keeps TASK_571 completion context")
	_assert(contract_text.contains("Fire-Rule-Controls-Readability-Polish"), "Mission command feedback contract documents TASK_571")
	_assert(hierarchy_text.contains("BUTTON_PATH_FIRE_RULE_HOLD"), "Command hierarchy exposes fire-rule button paths")
	_assert(hierarchy_text.contains("fire_rule_suppress"), "Command hierarchy exposes suppress fire-rule action")
	_assert(controller_text.contains("get_fire_rule_controls_readability_snapshot"), "Mission controller exposes fire-rule controls snapshot")
	_assert(controller_text.contains("_on_fire_rule_button_pressed"), "Mission controller wires fire-rule button presses")


func _test_fire_rule_controls_in_mission_hud() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)

	var controller: Node = scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission fixture exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	controller.call("_refresh_button_state")
	var empty_snapshot: Dictionary = Dictionary(controller.call("get_fire_rule_controls_readability_snapshot"))
	_assert(not bool(empty_snapshot.get("ui_sets_gameplay_truth", true)), "Fire-rule controls remain read-only UI")
	_assert(int(empty_snapshot.get("button_count", 0)) == 4, "Four fire-rule buttons are snapshotted")
	_assert(_all_buttons_exist(empty_snapshot), "All fire-rule buttons exist")
	_assert(_all_buttons_disabled(empty_snapshot), "Fire-rule buttons are disabled without selection")

	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_refresh_button_state")
	await _wait_frames(2)
	var selected_snapshot: Dictionary = Dictionary(controller.call("get_fire_rule_controls_readability_snapshot"))
	_assert(_all_buttons_enabled(selected_snapshot), "Fire-rule buttons are enabled with selected fireteam")
	_assert(_button_snapshot(selected_snapshot, "hold").get("text", "") == "HF", "Hold Fire button uses compact label")
	_assert(_button_snapshot(selected_snapshot, "return").get("text", "") == "RF", "Return Fire button uses compact label")
	_assert(_button_snapshot(selected_snapshot, "free").get("text", "") == "FW", "Fire at Will button uses compact label")
	_assert(_button_snapshot(selected_snapshot, "suppress").get("text", "") == "SUP", "Suppress button uses compact label")
	_assert(String(_button_snapshot(selected_snapshot, "hold").get("help_id", "")).contains("fire_rule_hold"), "Hold Fire button carries help id")

	var hold_button := scene.get_node_or_null(String(FIRE_RULE_BUTTON_PATHS["hold"])) as BaseButton
	var free_button := scene.get_node_or_null(String(FIRE_RULE_BUTTON_PATHS["free"])) as BaseButton
	_assert(hold_button != null and free_button != null, "Hold and Free buttons are real BaseButton nodes")
	if hold_button != null:
		hold_button.emit_signal("pressed")
	await _wait_frames(2)
	var hold_snapshot: Dictionary = Dictionary(controller.call("get_fire_rule_controls_readability_snapshot"))
	_assert(String(controller.call("get_fireteam_fire_rule", "blue")) == TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD, "Hold button sets selected fireteam through controller")
	_assert(bool(_button_snapshot(hold_snapshot, "hold").get("active", false)), "Hold button shows active state")
	_assert(not bool(_button_snapshot(hold_snapshot, "free").get("active", true)), "Free button is inactive after Hold")

	if free_button != null:
		free_button.emit_signal("pressed")
	await _wait_frames(2)
	var free_snapshot: Dictionary = Dictionary(controller.call("get_fire_rule_controls_readability_snapshot"))
	_assert(String(controller.call("get_fireteam_fire_rule", "blue")) == TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_FREE, "Free button sets selected fireteam through controller")
	_assert(bool(_button_snapshot(free_snapshot, "free").get("active", false)), "Free button shows active state")
	_assert(String(free_snapshot.get("selected_fire_rule_consensus", "")) == TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_FREE, "Snapshot exposes selected fire-rule consensus")

	var available_fireteams: PackedStringArray = PackedStringArray(controller.call("_get_available_fireteam_ids"))
	if available_fireteams.size() >= 2:
		var first_fireteam: String = String(available_fireteams[0])
		var second_fireteam: String = String(available_fireteams[1])
		controller.call("set_fireteams_fire_rule", PackedStringArray([first_fireteam]), TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_FREE)
		controller.call("set_fireteams_fire_rule", PackedStringArray([second_fireteam]), TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_HOLD)
		controller.call("_set_selected_fireteams", PackedStringArray([first_fireteam, second_fireteam]), false)
		controller.call("_refresh_button_state")
		await _wait_frames(2)
		var mixed_snapshot: Dictionary = Dictionary(controller.call("get_fire_rule_controls_readability_snapshot"))
		_assert(String(mixed_snapshot.get("selected_fire_rule_consensus", "")) == "mixed", "Mixed selection is exposed as mixed")
		_assert(not _any_button_active(mixed_snapshot), "Mixed selection does not show a false single active fire-rule")
	else:
		_assert(true, "Mixed selection skipped because fixture exposes only one fireteam")

	scene.queue_free()
	await _wait_frames(2)


func _all_buttons_exist(snapshot: Dictionary) -> bool:
	for rule in FIRE_RULE_BUTTON_PATHS.keys():
		if not bool(_button_snapshot(snapshot, String(rule)).get("exists", false)):
			return false
	return true


func _all_buttons_disabled(snapshot: Dictionary) -> bool:
	for rule in FIRE_RULE_BUTTON_PATHS.keys():
		if not bool(_button_snapshot(snapshot, String(rule)).get("disabled", true)):
			return false
	return true


func _all_buttons_enabled(snapshot: Dictionary) -> bool:
	for rule in FIRE_RULE_BUTTON_PATHS.keys():
		if bool(_button_snapshot(snapshot, String(rule)).get("disabled", true)):
			return false
	return true


func _any_button_active(snapshot: Dictionary) -> bool:
	for rule in FIRE_RULE_BUTTON_PATHS.keys():
		if bool(_button_snapshot(snapshot, String(rule)).get("active", false)):
			return true
	return false


func _button_snapshot(snapshot: Dictionary, rule: String) -> Dictionary:
	var buttons: Dictionary = Dictionary(snapshot.get("buttons", {}))
	return Dictionary(buttons.get(rule, {}))


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
