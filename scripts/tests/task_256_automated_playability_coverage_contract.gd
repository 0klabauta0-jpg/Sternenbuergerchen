extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/playability/playability_test_harness.gd")
const MATRIX_PATH: String = "res://docs/qa/playability_coverage_matrix.md"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"

const REQUIRED_SCREEN_IDS: Array[String] = [
	"main_menu",
	"settings",
	"singleplayer_setup",
	"multiplayer_lobby",
	"map_editor",
	"homebase",
	"fob",
	"character_sheet",
	"loadout",
	"mission_hud",
	"debrief",
]

const REQUIRED_MATRIX_SECTIONS: Array[String] = [
	"## Status Values",
	"## Screen Coverage",
	"## Flow Contract",
	"## Layout Contract",
	"## Harness Contract",
	"## Report Format",
	"## Maintenance Rules",
]

var _passed: int = 0
var _failed: int = 0
var _synthetic_pressed_count: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_256 Automated Playability Coverage Contract ===")
	_test_coverage_matrix_contract()
	await _test_harness_scene_and_button_helpers()
	await _test_harness_layout_and_report_helpers()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_coverage_matrix_contract() -> void:
	_assert(FileAccess.file_exists(MATRIX_PATH), "Playability coverage matrix exists")
	var matrix: String = _read_text(MATRIX_PATH)
	for section in REQUIRED_MATRIX_SECTIONS:
		_assert(matrix.contains(section), "Matrix contains required section: %s" % section)
	for status in HARNESS_SCRIPT.VALID_COVERAGE_STATUSES:
		_assert(matrix.contains("`%s`" % status), "Matrix documents status: %s" % status)
	for screen_id in REQUIRED_SCREEN_IDS:
		_assert(matrix.contains("| `%s` |" % screen_id), "Matrix covers screen: %s" % screen_id)
	for flow_id in ["flow_main_to_settings", "flow_main_to_multiplayer_lobby", "flow_host_join_ready", "flow_editor_to_lobby_map_transfer"]:
		_assert(matrix.contains("`%s`" % flow_id), "Matrix covers required flow: %s" % flow_id)
	for layout_check in ["layout_fixed_windows", "layout_button_reachability", "layout_scroll_overflow", "layout_text_clipping", "layout_visual_feel"]:
		_assert(matrix.contains("`%s`" % layout_check), "Matrix covers layout check: %s" % layout_check)
	_assert(matrix.contains("screen_id") and matrix.contains("manual checks still required"), "Matrix defines report fields and manual remainder")


func _test_harness_scene_and_button_helpers() -> void:
	_assert(ResourceLoader.exists(MAIN_MENU_SCENE_PATH), "Main menu scene path still resolves for harness smoke")
	var main_menu: Node = HARNESS_SCRIPT.instantiate_scene(MAIN_MENU_SCENE_PATH, root)
	_assert(main_menu != null, "Harness can instantiate PackedScene paths")
	if main_menu != null:
		await process_frame
		var multiplayer_button: BaseButton = HARNESS_SCRIPT.find_button(main_menu, {"name": "MultiplayerButton", "route": "res://scenes/ui/multiplayer_lobby.tscn"})
		_assert(multiplayer_button != null, "Harness finds buttons by node name and route metadata")
		var descriptor: Dictionary = Dictionary(HARNESS_SCRIPT.describe_button(main_menu, multiplayer_button))
		_assert(bool(descriptor.get("exists", false)) and String(descriptor.get("route", "")) == "res://scenes/ui/multiplayer_lobby.tscn", "Harness button descriptor exposes route metadata")
		main_menu.queue_free()
		await process_frame

	var screen := Control.new()
	screen.name = "SyntheticPlayabilityScreen"
	screen.size = Vector2(480.0, 320.0)
	root.add_child(screen)
	var row := HBoxContainer.new()
	row.name = "ActionRow"
	row.position = Vector2(16.0, 16.0)
	row.size = Vector2(448.0, 72.0)
	screen.add_child(row)
	var action_button := Button.new()
	action_button.name = "PrimaryActionButton"
	action_button.text = "Board"
	action_button.set_meta("action_id", "board")
	action_button.set_meta("icon_id", "transport_board")
	action_button.custom_minimum_size = Vector2(96.0, 48.0)
	action_button.pressed.connect(_on_synthetic_button_pressed)
	row.add_child(action_button)
	var route_button := Button.new()
	route_button.name = "RouteButton"
	route_button.text = "Mission"
	route_button.set_meta("route", "res://scenes/tests/mission_fireteam_dev_test.tscn")
	row.add_child(route_button)
	await process_frame
	_assert(HARNESS_SCRIPT.collect_buttons(screen).size() == 2, "Harness collects buttons recursively")
	_assert(HARNESS_SCRIPT.find_button(screen, {"text": "Board", "action_id": "board"}) == action_button, "Harness finds buttons by text and action_id")
	_assert(HARNESS_SCRIPT.find_button(screen, {"icon_id": "transport_board"}) == action_button, "Harness finds buttons by icon metadata")
	_assert(HARNESS_SCRIPT.has_pressed_callback(action_button), "Harness detects pressed callback connections")
	var press_result: Dictionary = Dictionary(HARNESS_SCRIPT.press_button_for_test(action_button))
	_assert(bool(press_result.get("pressed", false)) and _synthetic_pressed_count == 1, "Harness safely emits enabled button presses")
	action_button.disabled = true
	press_result = Dictionary(HARNESS_SCRIPT.press_button_for_test(action_button))
	_assert(not bool(press_result.get("pressed", true)) and String(press_result.get("reason", "")) == "disabled", "Harness refuses disabled button presses")
	screen.queue_free()
	await process_frame


func _test_harness_layout_and_report_helpers() -> void:
	var screen := Control.new()
	screen.name = "SyntheticLayoutScreen"
	screen.size = Vector2(400.0, 300.0)
	root.add_child(screen)
	var fixed_panel := PanelContainer.new()
	fixed_panel.name = "FixedPanel"
	fixed_panel.position = Vector2(24.0, 32.0)
	fixed_panel.size = Vector2(180.0, 120.0)
	screen.add_child(fixed_panel)
	var clipped_panel := PanelContainer.new()
	clipped_panel.name = "ClippedPanel"
	clipped_panel.position = Vector2(360.0, 260.0)
	clipped_panel.size = Vector2(96.0, 80.0)
	screen.add_child(clipped_panel)
	var scroll := ScrollContainer.new()
	scroll.name = "RosterScroll"
	scroll.position = Vector2(220.0, 24.0)
	scroll.size = Vector2(144.0, 180.0)
	screen.add_child(scroll)
	await process_frame
	_assert(HARNESS_SCRIPT.fixed_rect_matches(fixed_panel, Rect2(Vector2(24.0, 32.0), Vector2(180.0, 120.0))), "Harness checks fixed panel rectangles")
	_assert(HARNESS_SCRIPT.is_control_inside_viewport(fixed_panel, screen.size), "Harness confirms visible controls inside viewport")
	_assert(not HARNESS_SCRIPT.is_control_inside_viewport(clipped_panel, screen.size), "Harness detects controls outside viewport")
	_assert(HARNESS_SCRIPT.has_scroll_container(screen), "Harness detects ScrollContainer coverage")
	var clipped: Array = HARNESS_SCRIPT.collect_clipped_controls(screen, screen.size)
	_assert(not clipped.is_empty(), "Harness returns clipped-control diagnostics")
	var report: Dictionary = Dictionary(HARNESS_SCRIPT.build_screen_report("synthetic", ["missing_button"], ["manual_scale"], ["visual_feel"]))
	_assert(String(report.get("status", "")) == "failed" and int(report.get("failure_count", 0)) == 1, "Harness report separates failures from warnings/manual items")
	_assert(HARNESS_SCRIPT.coverage_status_is_valid("automated") and not HARNESS_SCRIPT.coverage_status_is_valid("unknown"), "Harness validates coverage status values")
	screen.queue_free()
	await process_frame


func _on_synthetic_button_pressed() -> void:
	_synthetic_pressed_count += 1


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
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
