extends SceneTree

const DRILL_SCENE := preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const STRATEGIC_PANEL_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel"
const STRATEGIC_HEADER_PATH := STRATEGIC_PANEL_PATH + "/StrategicMargin/StrategicScroll/StrategicVBox/StrategicHeaderLabel"
const STRATEGIC_SCROLL_PATH := STRATEGIC_PANEL_PATH + "/StrategicMargin/StrategicScroll"
const STRATEGIC_STATUS_PATH := STRATEGIC_PANEL_PATH + "/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel"

var _checks := 0
var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1160 Mission Control 1280 Readability ===")
	root.size = Vector2i(1280, 720)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(20)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	var panel := scene.get_node_or_null(STRATEGIC_PANEL_PATH) as Control
	var scroll := scene.get_node_or_null(STRATEGIC_SCROLL_PATH) as ScrollContainer
	var header := scene.get_node_or_null(STRATEGIC_HEADER_PATH) as Label
	var status := scene.get_node_or_null(STRATEGIC_STATUS_PATH) as Label
	_check(controller != null and controller.has_method("get_mission_control_1280_readability_snapshot"), "Controller exposes Mission Control 1280 readability snapshot")
	_check(panel != null and panel.visible, "Mission Control panel is visible")
	_check(scroll != null and scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "Mission Control keeps vertical scroll safety")
	_check(header != null and header.text.contains("EINSATZKONTROLLE"), "Mission Control header remains player-facing")
	_check(header != null and header.get_theme_font_size("font_size") >= 13, "Mission Control header is readable at 1280")
	_check(status != null and status.visible, "Mission Control status label is visible")
	_check(status != null and status.get_theme_font_size("font_size") >= 13, "Mission Control status text is readable at 1280")
	_check(status != null and status.get_theme_constant("outline_size") >= 3, "Mission Control status text keeps an outline")
	_check(status != null and int(status.autowrap_mode) != int(TextServer.AUTOWRAP_OFF), "Mission Control status text wraps")
	_check(status != null and not status.clip_text, "Mission Control status text is not clipped")
	_check(status != null and not status.tooltip_text.strip_edges().is_empty(), "Mission Control keeps details in tooltip")
	if status != null:
		var lines := status.text.strip_edges().split("\n", false)
		_check(lines.size() <= 4, "Mission Control keeps at most four visible status lines")
		_check(status.custom_minimum_size.y >= 92.0, "Mission Control reserves readable status height")
	if panel != null and status != null:
		_check(panel.get_global_rect().encloses(status.get_global_rect()), "Mission Control status label stays inside panel bounds")

	if controller != null and controller.has_method("_apply_mission_control_1280_readability") and controller.has_method("get_mission_control_1280_readability_snapshot"):
		var command_count_before := Array(simulation_root.get("command_queue")).size() if simulation_root != null else 0
		var effect_count_before := Array(simulation_root.get("effects_queue")).size() if simulation_root != null else 0
		controller.call("_apply_mission_control_1280_readability")
		var snapshot: Dictionary = Dictionary(controller.call("get_mission_control_1280_readability_snapshot"))
		_check(String(snapshot.get("style_id", "")) == "task_1160_mission_control_1280_readability_v1", "Snapshot identifies TASK 1160")
		_check(int(snapshot.get("status_font_size", 0)) >= 13, "Snapshot records readable status font")
		_check(int(snapshot.get("visible_line_count", 99)) <= 4, "Snapshot records compact visible lines")
		_check(bool(snapshot.get("tooltip_available", false)), "Snapshot records tooltip detail availability")
		_check(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot declares no gameplay truth")
		if simulation_root != null:
			_check(Array(simulation_root.get("command_queue")).size() == command_count_before, "Mission Control readability enqueues no command")
			_check(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "Mission Control readability enqueues no effect")

	scene.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1160 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
