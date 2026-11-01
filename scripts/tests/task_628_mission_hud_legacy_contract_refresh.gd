extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TASK_PATH: String = "res://docs/tasks/TASK_628_mission_hud_legacy_contract_refresh.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const COMMAND_GRID_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"
const SELECTED_CARDS_ROW_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow"

const FIRE_RULE_BUTTONS := [
	{"name": "FireRuleHoldButton", "text": "FH"},
	{"name": "FireRuleReturnButton", "text": "AF"},
	{"name": "FireRuleFreeButton", "text": "FF"},
	{"name": "FireRuleSuppressButton", "text": "UN"},
]

var _passed: int = 0
var _failed: int = 0
var _root: Node


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_628 Mission HUD Legacy Contract Refresh ===")
	_root = get_root()
	_test_docs_track_task()
	await _test_command_matrix_fire_rule_slots()
	await _test_inbound_selected_fireteam_cards_remain_visible()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_628: FAILED")
		quit(1)
	else:
		print("TASK_628: ALL PASSED")
		quit(0)


func _test_docs_track_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_628 task file exists")
	_assert(task_text.contains("Mission HUD Legacy Contract Refresh"), "TASK_628 task names legacy contract refresh")
	_assert(status_text.contains("TASK_628 - Mission HUD Legacy Contract Refresh"), "Implementation status tracks TASK_628")
	_assert(roadmap_text.contains("TASK_628 - Mission HUD Legacy Contract Refresh (implementiert)"), "Roadmap marks TASK_628 implemented")
	_assert(contract_text.contains("Mission-HUD-Legacy-Contract-Refresh"), "Mission command feedback contract documents TASK_628")
	_assert(report_text.contains("TASK_628 Mission HUD Legacy Contract Refresh"), "Rolling report tracks TASK_628")
	_assert(_has_current_task_record(report_text, "latest_completed_task"), "Rolling report retains a non-stale task-progress record")
	_assert(_has_current_task_record(handbook_text, "current_task"), "Status handbook retains a non-stale current-task record")


func _test_command_matrix_fire_rule_slots() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_root.add_child(scene)
	await _wait_frames(4)

	var command_grid := scene.get_node(COMMAND_GRID_PATH) as GridContainer
	_assert(command_grid != null, "Mission scene exposes command grid")
	_assert(command_grid != null and bool(command_grid.get_meta("native_a5_layout", false)), "#16 uses the native A5 layout while preserving existing controls")
	var team_panel := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel") as Control
	for fire_rule_variant in FIRE_RULE_BUTTONS:
		var spec: Dictionary = Dictionary(fire_rule_variant)
		var button := command_grid.get_node_or_null(String(spec.get("name", ""))) as Button
		_assert(button != null, "%s exists" % String(spec.get("name", "")))
		_assert(button != null and team_panel != null and team_panel.get_global_rect().encloses(button.get_global_rect()), "%s is reachable in the selected-team parameters" % String(spec.get("name", "")))
		_assert(button != null and bool(button.get_meta("fire_rule_control", false)), "%s is marked as fire-rule control" % String(spec.get("name", "")))
		_assert(button != null and String(button.text) == String(spec.get("text", "")), "%s keeps compact fire-rule label" % String(spec.get("name", "")))

	scene.queue_free()
	await _wait_frames(2)


func _test_inbound_selected_fireteam_cards_remain_visible() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_root.add_child(scene)
	await _wait_frames(4)

	var controller := scene.get_node_or_null("TacticalController")
	var mission_setup := scene.get_node_or_null("MissionSetup")
	_assert(controller != null and mission_setup != null, "Mission test scene exposes controller and setup")
	if controller == null or mission_setup == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	mission_setup.set("defer_friendly_runtime_activation", true)
	var available_fireteams: PackedStringArray = PackedStringArray(controller.call("_get_available_fireteam_ids"))
	_assert(not available_fireteams.is_empty(), "Mission fixture exposes at least one fireteam")
	if available_fireteams.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	var fireteam_id: String = String(available_fireteams[0])
	var units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	_assert(not units.is_empty(), "Inbound fixture uses actual members from the existing fireteam")
	var embarked_unit_ids: Array = []
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			embarked_unit_ids.append(String(unit.call("get_unit_id")).strip_edges())

	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_state"] = "to_mission"
	planning_state["embarked_unit_ids"] = embarked_unit_ids
	planning_state["deployed_unit_ids"] = []
	planning_state["selected_fireteams"] = [fireteam_id]
	controller.call("set_planning_state", planning_state)
	await _wait_frames(2)

	var selected_card_row := scene.get_node(SELECTED_CARDS_ROW_PATH) as HBoxContainer
	_assert(String(selected_card_row.get_meta("selected_member_cards_fireteam_id", "")).strip_edges().to_lower() == fireteam_id, "#17 member-card lane is sourced from the selected inbound fireteam")
	_assert(selected_card_row.get_child_count() >= max(1, units.size()), "#17 shows inbound fireteam member cards")
	var disabled_card_count: int = 0
	for child in selected_card_row.get_children():
		if child is Control and bool((child as Control).get_meta("mission_selected_fireteam_member_in_drop_transit", false)):
			var card_state: Dictionary = child.call("get_card_userology_snapshot")
			if bool(child.get("_is_disabled")) and not bool(card_state.get("drag_enabled", true)):
				disabled_card_count += 1
	_assert(disabled_card_count >= min(units.size(), selected_card_row.get_child_count()), "Inbound member cards render as disabled/read-only")

	scene.queue_free()
	await _wait_frames(2)


func _has_current_task_record(text: String, key: String) -> bool:
	# These rolling documents move forward independently of this historical
	# verifier. Check their record, not an unrelated later task's exact title.
	var record := RegEx.new()
	record.compile(key + ':\\s*"([^"]+)"')
	var record_match := record.search(text)
	if record_match == null:
		return false
	var value := record_match.get_string(1).strip_edges()
	if value.begins_with("TASK_"):
		return int(value.trim_prefix("TASK_").get_slice(" ", 0)) >= 628
	return not value.is_empty()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
