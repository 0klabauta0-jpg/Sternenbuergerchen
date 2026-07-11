extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const LAYOUT_CONTRACT := preload("res://scripts/meta/drop_light_layout_contract.gd")
const STRATEGIC_PANEL_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel"
const COMMAND_PANEL_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel"
const FIRETEAM_PANEL_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1107 Mission Control Fixed Layout Repair ===")
	root.size = LAYOUT_CONTRACT.TARGET_VIEWPORT
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	var layout: Dictionary = LAYOUT_CONTRACT.get_mission_hud_layout()
	var strategic := mission.get_node(STRATEGIC_PANEL_PATH) as Control
	var command := mission.get_node(COMMAND_PANEL_PATH) as Control
	var fireteam := mission.get_node(FIRETEAM_PANEL_PATH) as Control
	var strategic_scroll := mission.get_node(STRATEGIC_PANEL_PATH + "/StrategicMargin/StrategicScroll") as ScrollContainer

	await _wait_frames(1)
	var first_rect := _control_rect(strategic)
	await _wait_frames(5)
	var settled_rect := _control_rect(strategic)
	await _wait_frames(6)
	var late_rect := _control_rect(strategic)
	var expected: Rect2 = Rect2(layout.get("mission_control"))
	print("DIAG expected=%s first=%s settled=%s late=%s min=%s parent=%s top_level=%s" % [
		expected, first_rect, settled_rect, late_rect, strategic.get_combined_minimum_size(),
		strategic.get_parent().get_class(), strategic.top_level,
	])
	_assert(_rect_matches(settled_rect, expected), "Mission Control settles on the fixed layout contract")
	_assert(_rect_matches(late_rect, expected), "Mission Control remains stable after late container frames")
	_assert(_rect_matches(_control_rect(command), Rect2(layout.get("command_matrix"))), "Command Matrix remains on its fixed rect")
	_assert(_rect_matches(_control_rect(fireteam), Rect2(layout.get("selected_fireteam"))), "Selected Fireteam remains on its fixed rect")
	_assert(strategic_scroll.size.x <= expected.size.x and strategic_scroll.size.y <= expected.size.y, "Mission Control scroll viewport stays bounded by the panel")
	_assert(strategic_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "Mission Control keeps automatic vertical scrolling")
	_assert(bool(strategic.get_meta("drop_light_fixed_fullhd_layout", false)), "Mission Control keeps the shared fixed-layout marker")
	var controller := mission.get_node("TacticalController")
	_assert(Array(mission.get_node("SimulationRoot").get("command_queue")).is_empty(), "Layout repair creates no gameplay commands")
	_assert(not Dictionary(controller.call("get_command_feedback_snapshot")).has("layout_sets_gameplay_truth"), "Mission Control layout adds no gameplay-truth field")

	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _control_rect(control: Control) -> Rect2:
	return Rect2(control.global_position, control.size)


func _rect_matches(actual: Rect2, expected: Rect2, tolerance: float = 0.5) -> bool:
	return actual.position.distance_to(expected.position) <= tolerance and actual.size.distance_to(expected.size) <= tolerance


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
