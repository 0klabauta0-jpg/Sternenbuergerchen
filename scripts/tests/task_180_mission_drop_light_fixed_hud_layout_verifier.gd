extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")

const COMMAND_BUTTON_PATHS := [
	"TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/HoldButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FlankButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TakeButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/DeleteOrderButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/SortCommandMatrixButton",
]

const APPROACH_BUTTON_PATHS := [
	"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NWButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NEButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SWButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SEButton",
]

const FIRE_RULE_BUTTONS := [
	{"name": "FireRuleHoldButton", "slot": 11, "text": "FH"},
	{"name": "FireRuleReturnButton", "slot": 12, "text": "AF"},
	{"name": "FireRuleFreeButton", "slot": 13, "text": "FF"},
	{"name": "FireRuleSuppressButton", "slot": 14, "text": "UN"},
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_180 Mission Drop Light Fixed HUD Layout Verifier ===")
	await _test_mission_hud_fixed_window_positions()
	await _test_mission_hud_buttons_keep_existing_paths()
	await _test_embarked_fireteam_selection_keeps_dropship_truth()
	await _test_styling_pass_does_not_mutate_simulation_root()
	_test_mission_runtime_boundary_files()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_180: FAILED")
		quit(1)
	else:
		print("TASK_180: ALL PASSED")
		quit(0)


func _test_mission_hud_fixed_window_positions() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout")
	var tactical_ui := scene.get_node_or_null("TacticalUI") as CanvasLayer
	_assert(tactical_ui != null and bool(tactical_ui.get_meta("drop_light_fixed_fullhd_layout", false)), "TacticalUI is marked as the fixed drop_light Mission HUD layer")
	_assert(_node_rect_matches_actual(scene.get_node("TacticalUI/MissionIdentityPanel") as Control, layout.get("mission_identity")), "Mission identity uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(scene.get_node("TacticalUI/TopNavPanel") as Control, layout.get("top_nav")), "Mission top nav uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(scene.get_node("TacticalUI/FireteamMiniPanel") as Control, layout.get("fireteam_mini")), "Fireteam mini HUD uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(scene.get_node("TacticalUI/BottomDock") as Control, layout.get("bottom_dock")), "Mission bottom dock uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel") as Control, layout.get("command_matrix")), "#16 command matrix uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel") as Control, layout.get("selected_fireteam")), "#17 selected fireteam uses the fixed contract position and size")
	_assert(_node_rect_matches_actual(scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel") as Control, layout.get("mission_control")), "#18 mission control uses the fixed contract position and size")

	_assert((scene.get_node("TacticalUI/BottomDock") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "Bottom dock host does not consume map input outside fixed panels")
	_assert((scene.get_node("TacticalUI/BottomDock/BottomMargin") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "Bottom margin host does not consume map input outside fixed panels")
	_assert((scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "Bottom row host does not consume map input outside fixed panels")
	_assert(bool((scene.get_node("TacticalUI/FireteamMiniPanel") as Control).get_meta("mission_fireteam_mini_backgroundless", false)), "Fireteam mini HUD renders as cards without a background window")

	_assert((scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandHeaderLabel") as Label).text == "#16 COMMAND MATRIX", "#16 block label is preserved")
	_assert((scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel") as Label).text == "#17 SELECTED FIRETEAM", "#17 block label is preserved")
	_assert((scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicHeaderLabel") as Label).text == "#18 MISSION CONTROL", "#18 block label is preserved")

	scene.queue_free()
	await _wait_frames(2)


func _test_mission_hud_buttons_keep_existing_paths() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	for path in COMMAND_BUTTON_PATHS:
		var button := scene.get_node(path) as Button
		_assert(_button_is_square(button), "%s is a square command button" % button.name)
		_assert(button.pressed.get_connections().size() > 0, "%s keeps an existing pressed callback" % button.name)
		_assert(button.visible and not button.text.strip_edges().is_empty(), "%s remains a visible existing command entry" % button.name)
		_assert(_button_has_tiny_marker(button), "%s has a tiny #16 reference marker" % button.name)

	var command_grid := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid") as GridContainer
	_assert(command_grid != null and int(command_grid.columns) == 5, "#16 command matrix uses five equal command columns")
	_assert(command_grid.get_child_count() >= 20 and int(command_grid.get_meta("command_placeholder_slots", 0)) >= 6, "#16 command matrix exposes reserved same-size command slots")
	for slot_index in range(7, 21):
		if [7, 8, 10, 11, 12, 13, 14, 15, 20].has(slot_index):
			continue
		var slot := command_grid.get_node_or_null("CommandSlot%02d" % slot_index) as Button
		_assert(slot != null and _button_is_square(slot) and bool(slot.get_meta("drop_light_command_placeholder", false)) and slot.disabled, "CommandSlot%02d is a disabled same-size reserve button" % slot_index)
	for fire_rule_variant in FIRE_RULE_BUTTONS:
		var fire_rule_spec: Dictionary = Dictionary(fire_rule_variant)
		var fire_rule_button := command_grid.get_node_or_null(String(fire_rule_spec.get("name", ""))) as Button
		var expected_index: int = int(fire_rule_spec.get("slot", 0)) - 1
		_assert(
			fire_rule_button != null
			and fire_rule_button.get_index() == expected_index
			and _button_is_square(fire_rule_button)
			and bool(fire_rule_button.get_meta("fire_rule_control", false))
			and String(fire_rule_button.text) == String(fire_rule_spec.get("text", "")),
			"%s lives in #%s as an active fire-rule command button (index=%s size=%s min=%s text=%s expected=%s)" % [String(fire_rule_spec.get("name", "")), str(fire_rule_spec.get("slot", "")), str(fire_rule_button.get_index() if fire_rule_button != null else -1), str(fire_rule_button.size if fire_rule_button != null else Vector2.ZERO), str(fire_rule_button.custom_minimum_size if fire_rule_button != null else Vector2.ZERO), String(fire_rule_button.text if fire_rule_button != null else ""), String(fire_rule_spec.get("text", ""))]
		)
	var delete_button := command_grid.get_node_or_null("DeleteOrderButton") as Button
	var door_button := command_grid.get_node_or_null("DoorBreachButton") as Button
	var sort_button := command_grid.get_node_or_null("SortCommandMatrixButton") as Button
	var go_button := command_grid.get_node_or_null("GoCommandMatrixButton") as Button
	var waypoint_erase_button := command_grid.get_node_or_null("WaypointEraseButton") as Button
	var plan_button := command_grid.get_node_or_null("PlanCommandMatrixButton") as Button
	_assert(delete_button != null and delete_button.get_index() == 6 and _button_is_square(delete_button) and delete_button.pressed.get_connections().size() > 0, "Del lives in #16.7 as an active command matrix button")
	_assert(door_button != null and door_button.get_index() == 7 and _button_is_square(door_button) and door_button.pressed.get_connections().size() > 0, "Door/Breach lives in #16.8 as an active command matrix button")
	_assert(sort_button != null and sort_button.get_index() == 9 and _button_is_square(sort_button) and sort_button.pressed.get_connections().size() > 0, "Sort lives in #16.10 as an active command matrix button")
	_assert(go_button != null and go_button.get_index() == 14 and _button_is_square(go_button) and go_button.pressed.get_connections().size() > 0, "GO lives in #16.15 as an active command matrix button")
	_assert(waypoint_erase_button != null and waypoint_erase_button.get_index() == 19 and _button_is_square(waypoint_erase_button) and waypoint_erase_button.pressed.get_connections().size() > 0, "WP- lives in #16.20 as an active command matrix button")
	_assert(plan_button == null, "Plan is no longer a visible command matrix button")

	for path in [
		"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton",
		"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton",
	]:
		var button := scene.get_node(path) as Button
		_assert(_button_is_square(button), "%s is a square mission-control action button" % button.name)
		_assert(button.pressed.get_connections().size() > 0, "%s keeps an existing controller callback" % button.name)

	for path in APPROACH_BUTTON_PATHS:
		var button := scene.get_node(path) as Button
		_assert(_button_is_square(button), "%s is a small square approach button" % button.name)
		_assert(button.pressed.get_connections().size() > 0, "%s keeps an existing approach callback" % button.name)

	var action_row := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow") as HBoxContainer
	_assert(action_row.alignment == BoxContainer.ALIGNMENT_BEGIN, "#18 mission-control action buttons are left aligned")
	var fireteam_info_scroll := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll") as Control
	var fireteam_cards_scroll := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll") as Control
	var fireteam_cards_spacer := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsSpacer") as Control
	_assert(fireteam_info_scroll.custom_minimum_size.x <= 320.0 and fireteam_cards_scroll.custom_minimum_size.x >= 800.0 and String(fireteam_cards_scroll.get_meta("selected_fireteam_cards_source", "")) == "_refresh_selected_fireteam_cards", "#17 selected-fireteam layout reserves the wide right member-card lane")
	_assert(not fireteam_cards_spacer.visible and fireteam_cards_spacer.custom_minimum_size == Vector2.ZERO, "#17 selected-fireteam card spacer no longer pushes cards off to the side")
	var stance_labels := {"cautious": "VORS", "normal": "NORM", "aggressive": "OFF"}
	for stance_id in ["cautious", "normal", "aggressive"]:
		var stance_button := _find_stance_button(scene, stance_id)
		_assert(
			stance_button != null
				and stance_button.text == String(stance_labels.get(stance_id, ""))
				and stance_button.custom_minimum_size == Vector2(64.0, 24.0)
				and stance_button.size_flags_horizontal == Control.SIZE_EXPAND_FILL,
			"%s stance control uses the compact readable #17 segment contract" % stance_id
		)

	var phase_control_panel := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel") as Control
	_assert(not phase_control_panel.visible, "Disabled phase-planning template controls are hidden in the fixed Mission HUD")

	scene.queue_free()
	await _wait_frames(2)


func _test_embarked_fireteam_selection_keeps_dropship_truth() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var controller := scene.get_node_or_null("TacticalController")
	var mission_setup := scene.get_node_or_null("MissionSetup")
	_assert(controller != null and mission_setup != null, "Mission test scene exposes controller and setup for inbound fireteam cards")
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

	var mini_host := scene.get_node("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox") as VBoxContainer
	var selected_card_row := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow") as HBoxContainer
	var mini_fireteam_ids := PackedStringArray()
	for mini_card_variant in mini_host.get_children():
		var mini_card := mini_card_variant as Control
		if mini_card == null:
			continue
		var mini_fireteam_id: String = String(mini_card.get_meta("fireteam_id", "")).strip_edges().to_lower()
		if not mini_fireteam_id.is_empty():
			mini_fireteam_ids.append(mini_fireteam_id)
	_assert(not mini_fireteam_ids.has(fireteam_id), "Embarked selected fireteam stays out of the left ground mini-card list")
	_assert(String(selected_card_row.get_meta("selected_member_cards_fireteam_id", "")).strip_edges().to_lower() == fireteam_id, "#17 member-card lane is sourced from the selected fireteam")
	_assert(selected_card_row.get_child_count() == 1 and selected_card_row.get_child(0) is Label, "Selected embarked fireteam renders one status hint instead of ground member cards")
	var embarked_hint := selected_card_row.get_child(0) as Label if selected_card_row.get_child_count() == 1 else null
	_assert(embarked_hint != null and embarked_hint.text == "Fireteam im Dropship.", "Selected embarked fireteam explains its Dropship state in #17")

	scene.queue_free()
	await _wait_frames(2)


func _test_styling_pass_does_not_mutate_simulation_root() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and simulation_root != null, "Mission scene exposes controller and SimulationRoot for mutation guard")
	if controller == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var command_count_before: int = Array(simulation_root.get("command_queue")).size()
	var effect_count_before: int = Array(simulation_root.get("effects_queue")).size()
	var snapshot_debug_before: Dictionary = Dictionary(simulation_root.call("get_multiplayer_snapshot_debug_snapshot")).duplicate(true)

	controller.call("_apply_drop_light_fixed_hud_layout")
	controller.call("_apply_compact_mission_control_layout")
	controller.call("_apply_drop_light_hud_button_labels")
	await _wait_frames(2)

	var command_count_after: int = Array(simulation_root.get("command_queue")).size()
	var effect_count_after: int = Array(simulation_root.get("effects_queue")).size()
	var snapshot_debug_after: Dictionary = Dictionary(simulation_root.call("get_multiplayer_snapshot_debug_snapshot")).duplicate(true)
	_assert(command_count_after == command_count_before, "Drop Light HUD styling enqueues no SimulationRoot commands")
	_assert(effect_count_after == effect_count_before, "Drop Light HUD styling enqueues no SimulationRoot effects")
	_assert(int(snapshot_debug_after.get("apply_count", 0)) == int(snapshot_debug_before.get("apply_count", 0)), "Drop Light HUD styling applies no multiplayer snapshots")
	_assert(int(snapshot_debug_after.get("last_applied_tick", -1)) == int(snapshot_debug_before.get("last_applied_tick", -1)), "Drop Light HUD styling does not advance snapshot state")

	scene.queue_free()
	await _wait_frames(2)


func _test_mission_runtime_boundary_files() -> void:
	for file_path in [
		"res://scripts/terrain/terrain_map_3d_view.gd",
		"res://scripts/core/simulation_root.gd",
		"res://scripts/terrain/terrain_pathfinder.gd",
		"res://scripts/terrain/hpa_pathfinder.gd",
	]:
		var text := _read_text_file(file_path)
		_assert(not text.contains("drop_light") and not text.contains("DropLight"), "%s remains outside the drop_light Mission HUD implementation" % file_path)


func _node_rect_matches_actual(control: Control, rect_variant: Variant) -> bool:
	if control == null or typeof(rect_variant) != TYPE_RECT2I:
		return false
	var rect: Rect2i = rect_variant
	var matches := _approximately_equal(control.global_position.x, float(rect.position.x)) \
		and _approximately_equal(control.global_position.y, float(rect.position.y)) \
		and _approximately_equal(control.size.x, float(rect.size.x)) \
		and _approximately_equal(control.size.y, float(rect.size.y))
	if not matches:
		print("  RECT MISMATCH %s actual pos=%s size=%s expected pos=%s size=%s" % [
			control.name,
			control.global_position,
			control.size,
			rect.position,
			rect.size,
		])
	return matches


func _button_is_square(button: Button) -> bool:
	if button == null:
		return false
	if button.custom_minimum_size.x <= 0.0 or button.custom_minimum_size.x != button.custom_minimum_size.y:
		return false
	if not bool(button.get_meta("drop_light_square_action_button", false)):
		return false
	return _approximately_equal(button.size.x, button.size.y)


func _button_has_tiny_marker(button: Button) -> bool:
	if button == null:
		return false
	var marker_text: String = String(button.get_meta("drop_light_button_marker", "")).strip_edges()
	var marker := button.get_node_or_null("TinyButtonMarker") as Label
	return marker != null and marker_text.begins_with("16.") and marker.text == marker_text and int(marker.get_theme_font_size("font_size")) <= 7


func _find_stance_button(scene: Node, stance_id: String) -> Button:
	if scene == null:
		return null
	for node in scene.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null:
			continue
		if String(button.get_meta("tactical_stance_id", "")).strip_edges().to_lower() == stance_id:
			return button
	return null


func _approximately_equal(a: float, b: float) -> bool:
	return absf(a - b) <= 0.5


func _read_text_file(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
