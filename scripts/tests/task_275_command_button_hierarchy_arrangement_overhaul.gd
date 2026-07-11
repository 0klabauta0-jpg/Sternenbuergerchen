extends SceneTree

const CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/mission_command_hierarchy_contract.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const DOC_PATH: String = "res://docs/dev/mission_command_button_hierarchy.md"
const TASK_PATH: String = "res://docs/tasks/TASK_275_command_button_hierarchy_arrangement_overhaul.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HELP_CATALOG_PATH: String = "res://data/contextual_help_catalog.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_275 Command Button Hierarchy Arrangement Overhaul ===")
	_test_contract_catalog_and_snapshot()
	_test_doc_contract()
	_test_help_catalog_entries()
	await _test_mission_scene_hierarchy()
	_test_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_contract_catalog_and_snapshot() -> void:
	_assert(FileAccess.file_exists("res://scripts/ui/mission_command_hierarchy_contract.gd"), "Mission command hierarchy contract file exists")
	var groups: PackedStringArray = PackedStringArray(CONTRACT_SCRIPT.call("get_group_order"))
	for group_id in ["goal", "rule", "plan", "air_lz", "breakout"]:
		_assert(groups.has(group_id), "Group order contains %s" % group_id)
	var catalog: Array = Array(CONTRACT_SCRIPT.call("get_action_catalog"))
	for action_id in [
		"move",
		"take",
		"defend",
		"engage",
		"secure",
		"recon",
		"withdraw",
		"delete_order",
		"tempo",
		"fire_rule",
		"contact_response",
		"cover_priority",
		"security_mode",
		"role_suggestion",
		"swap_roles",
		"preview_plan",
		"sort_fireteam",
		"go_plan",
		"set_lz",
		"call_dropship",
		"lz_secure",
		"evac_recover",
		"confirm",
		"override",
		"abort",
		"regroup",
	]:
		_assert(_catalog_has_action(catalog, action_id), "Catalog contains action %s" % action_id)
	var snapshot: Dictionary = Dictionary(CONTRACT_SCRIPT.call("build_hierarchy_snapshot", {
		"selected_fireteam_count": 2,
		"single_fireteam_context": false,
		"multi_fireteam_context": true,
		"can_issue_local_commands": true,
		"can_edit_planning": true,
		"phase_planning_enabled": false,
		"drop_available": true,
	}, {}))
	_assert(bool(snapshot.get("visual_only", false)), "Contract snapshot is visual-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Contract snapshot does not set gameplay truth")
	var actions_by_id: Dictionary = Dictionary(snapshot.get("actions_by_id", {}))
	_assert(Dictionary(actions_by_id.get("tempo", {})).get("panel_role", "") == "#17", "Rule actions live in #17")
	_assert(Dictionary(actions_by_id.get("set_lz", {})).get("group_id", "") == "air_lz", "Set LZ is grouped as Air/LZ")
	_assert(Dictionary(actions_by_id.get("sort_fireteam", {})).get("panel_role", "") == "#16", "Sort lives in #16 for the fixed HUD command matrix")
	_assert(Dictionary(actions_by_id.get("go_plan", {})).get("panel_role", "") == "#16", "GO lives in #16 for the fixed HUD command matrix")
	_assert(str(Dictionary(actions_by_id.get("confirm", {})).get("disabled_reason", "")).contains("TASK_276"), "Breakout actions are reserved for TASK_276")


func _test_doc_contract() -> void:
	_assert(FileAccess.file_exists(DOC_PATH), "Command hierarchy dev doc exists")
	var text: String = _read_text(DOC_PATH)
	for token in [
		"#16",
		"#17",
		"#18",
		"goal",
		"rule",
		"plan",
		"air_lz",
		"breakout",
		"visual_only",
		"ui_sets_gameplay_truth = false",
		"Vorher Matrix",
		"Nachher Gruppen",
		"Disabled Reasons",
		"Offene UX-Fragen",
	]:
		_assert(text.contains(token), "Dev doc contains %s" % token)


func _test_help_catalog_entries() -> void:
	var catalog: Dictionary = _read_json(HELP_CATALOG_PATH)
	var entries: Array = Array(catalog.get("entries", []))
	for help_id in [
		"mission.command.group.goal",
		"mission.command.group.rule",
		"mission.command.group.plan",
		"mission.command.group.air_lz",
		"mission.command.group.breakout",
	]:
		_assert(_help_catalog_has_id(entries, help_id), "Help catalog contains %s" % help_id)


func _test_mission_scene_hierarchy() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node("TacticalController")
	_assert(controller != null and controller.has_method("get_command_hierarchy_snapshot"), "Controller exposes command hierarchy snapshot")
	if controller == null:
		return

	var snapshot: Dictionary = Dictionary(controller.call("get_command_hierarchy_snapshot"))
	_assert(bool(snapshot.get("visual_only", false)), "Mission hierarchy snapshot is visual-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Mission hierarchy does not claim gameplay truth")
	var groups_by_id: Dictionary = Dictionary(snapshot.get("groups_by_id", {}))
	for group_id in ["goal", "rule", "plan", "air_lz", "breakout"]:
		_assert(groups_by_id.has(group_id), "Mission snapshot contains group %s" % group_id)
	_assert(str(Dictionary(groups_by_id.get("goal", {})).get("panel_role", "")) == "#16", "Goal group is assigned to #16")
	_assert(str(Dictionary(groups_by_id.get("rule", {})).get("panel_role", "")) == "#17", "Rule group is assigned to #17")
	_assert(str(Dictionary(groups_by_id.get("air_lz", {})).get("panel_role", "")) == "#18", "Air/LZ group is assigned to #18")

	var actions_by_id: Dictionary = Dictionary(snapshot.get("actions_by_id", {}))
	_assert(Dictionary(actions_by_id.get("move", {})).get("group_id", "") == "goal", "Move action is a goal command")
	_assert(Dictionary(actions_by_id.get("call_dropship", {})).get("group_id", "") == "air_lz", "Drop action is an Air/LZ command")
	_assert(str(Dictionary(actions_by_id.get("confirm", {})).get("disabled_reason", "")).contains("TASK_276"), "Breakout confirm is visibly disabled for later task")

	_assert_button_metadata(controller, "move", str(CONTRACT_SCRIPT.get("BUTTON_PATH_MOVE")), "goal", "#16")
	_assert_button_metadata(controller, "take", str(CONTRACT_SCRIPT.get("BUTTON_PATH_TAKE")), "goal", "#16")
	_assert_button_metadata(controller, "defend", str(CONTRACT_SCRIPT.get("BUTTON_PATH_HOLD")), "goal", "#16")
	_assert_button_metadata(controller, "engage", str(CONTRACT_SCRIPT.get("BUTTON_PATH_TARGET")), "goal", "#16")
	_assert_button_metadata(controller, "delete_order", str(CONTRACT_SCRIPT.get("BUTTON_PATH_DELETE_ORDER")), "goal", "#16")
	_assert_button_metadata(controller, "sort_fireteam", str(CONTRACT_SCRIPT.get("BUTTON_PATH_SORT")), "plan", "#16")
	_assert_button_metadata(controller, "set_lz", str(CONTRACT_SCRIPT.get("BUTTON_PATH_SET_LZ")), "air_lz", "#18")
	_assert_button_metadata(controller, "call_dropship", str(CONTRACT_SCRIPT.get("BUTTON_PATH_CALL_DROPSHIP")), "air_lz", "#18")
	_assert_button_metadata(controller, "approach_nw", str(CONTRACT_SCRIPT.get("BUTTON_PATH_APPROACH_NW")), "air_lz", "#18")

	var command_grid := controller.get_node_or_null(str(CONTRACT_SCRIPT.get("BUTTON_PATH_MOVE")).get_base_dir()) as GridContainer
	_assert(command_grid != null and int(command_grid.columns) == 5, "#16 command grid uses five columns for the fixed 5x4 command matrix")
	if command_grid != null:
		var order: PackedStringArray = PackedStringArray(command_grid.get_meta("command_hierarchy_order", PackedStringArray()))
		_assert(order.size() >= 8 and order[0] == "move" and order[1] == "take" and order.has("delete_order") and order.has("sort_fireteam"), "#16 command grid order includes Move/Take plus Delete/Sort")
		_assert(command_grid.get_child_count() >= 20, "#16 command grid exposes the full 5x4 slot frame")
		_assert(int(command_grid.get_meta("command_placeholder_slots", 0)) >= 5, "#16 command grid keeps the five current reserve slots marked for communication")
		var sort_button := command_grid.get_node_or_null("SortCommandMatrixButton") as Button
		_assert(sort_button != null and sort_button.get_index() == 9, "Sort command occupies #16.10")

	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	await _wait_frames(3)
	var single_snapshot: Dictionary = Dictionary(controller.call("get_command_hierarchy_snapshot"))
	_assert(bool(single_snapshot.get("single_fireteam_context", false)) and not bool(single_snapshot.get("multi_fireteam_context", true)), "Single-fireteam context is distinguishable")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	await _wait_frames(3)
	var multi_snapshot: Dictionary = Dictionary(controller.call("get_command_hierarchy_snapshot"))
	_assert(bool(multi_snapshot.get("multi_fireteam_context", false)), "Multi-fireteam context is distinguishable")
	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	await _wait_frames(3)
	var empty_snapshot: Dictionary = Dictionary(controller.call("get_command_hierarchy_snapshot"))
	var empty_actions: Dictionary = Dictionary(empty_snapshot.get("actions_by_id", {}))
	_assert(str(Dictionary(empty_actions.get("move", {})).get("disabled_reason", "")).contains("select"), "No-selection Move disabled reason is visible")

	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(Dictionary(feedback.get("command_hierarchy", {})).has("groups_by_id"), "Command feedback snapshot includes hierarchy")
	_assert(Dictionary(Dictionary(feedback.get("command_buttons", {})).get("hierarchy", {})).has("actions_by_id"), "Command button snapshot keeps hierarchy compatibility anchor")

	scene.queue_free()
	await _wait_frames(2)


func _assert_button_metadata(controller: Node, action_id: String, button_path: String, group_id: String, panel_role: String) -> void:
	var button := controller.get_node_or_null(button_path) as BaseButton
	_assert(button != null, "%s button exists" % action_id)
	if button == null:
		return
	_assert(str(button.get_meta("command_hierarchy_action_id", "")) == action_id, "%s carries action metadata" % action_id)
	_assert(str(button.get_meta("command_hierarchy_group_id", "")) == group_id, "%s carries group metadata" % action_id)
	_assert(str(button.get_meta("command_hierarchy_panel_role", "")) == panel_role, "%s carries panel metadata" % action_id)
	_assert(not str(button.get_meta("command_hierarchy_group_help_id", "")).is_empty(), "%s carries group help metadata" % action_id)
	_assert(not button.tooltip_text.is_empty(), "%s exposes hierarchy tooltip/disabled reason channel" % action_id)
	_assert(button.pressed.get_connections().size() > 0, "%s keeps pressed signal connection" % action_id)


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_275 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("TASK_275") and status_text.to_lower().contains("implementiert"), "Implementation status mentions TASK_275 implemented")
	_assert(roadmap_text.contains("TASK_275") and roadmap_text.to_lower().contains("implementiert"), "Roadmap mentions TASK_275 implemented")


func _catalog_has_action(catalog: Array, action_id: String) -> bool:
	for action_variant in catalog:
		if str(Dictionary(action_variant).get("action_id", "")) == action_id:
			return true
	return false


func _help_catalog_has_id(entries: Array, help_id: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		if str(Dictionary(entry_variant).get("help_id", "")) == help_id:
			return true
	return false


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
