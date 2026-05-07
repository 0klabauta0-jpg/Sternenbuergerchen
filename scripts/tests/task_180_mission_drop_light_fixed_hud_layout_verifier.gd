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
]

const APPROACH_BUTTON_PATHS := [
	"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NWButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NEButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SWButton",
	"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SEButton",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_180 Mission Drop Light Fixed HUD Layout Verifier ===")
	await _test_mission_hud_fixed_window_positions()
	await _test_mission_hud_buttons_keep_existing_paths()
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

	var phase_control_panel := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel") as Control
	_assert(not phase_control_panel.visible, "Disabled phase-planning template controls are hidden in the fixed Mission HUD")

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
