extends SceneTree

const DRILL_SCENE := preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const GRID_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(20)

	var grid := scene.get_node_or_null(GRID_PATH) as GridContainer
	var controller := scene.get_node_or_null("TacticalController")
	_check(controller != null and controller.has_method("get_command_matrix_1280_readability_snapshot"), "Controller exposes the read-only 1280 readability snapshot")
	_check(grid != null and grid.columns == 5, "Command matrix keeps five stable columns")
	_check(grid != null and grid.get_child_count() >= 20, "Command matrix keeps all command slots")

	var primary_labels := {"MoveButton": "BW", "TakeButton": "NM", "HoldButton": "HL", "FlankButton": "FL", "TargetButton": "ZL"}
	for button_name in primary_labels:
		var button := scene.get_node_or_null("%s/%s" % [GRID_PATH, button_name]) as Button
		var font_size := button.get_theme_font_size("font_size") if button != null else -1
		_check(button != null and font_size >= 12, "%s is readable at 1280 (font=%d)" % [button_name, font_size])
		_check(button != null and button.icon != null, "%s keeps its tactical icon" % button_name)
		_check(button != null and button.text == String(primary_labels[button_name]), "%s keeps its German player-language code" % button_name)
		var normal_style := button.get_theme_stylebox("normal") if button != null else null
		_check(normal_style != null and normal_style.content_margin_left <= 4.0 and normal_style.content_margin_right <= 4.0, "%s reserves enough width for icon and code" % button_name)

	for button_name in ["FireRuleHoldButton", "FireRuleReturnButton", "FireRuleFreeButton", "FireRuleSuppressButton"]:
		var button := scene.get_node_or_null("%s/%s" % [GRID_PATH, button_name]) as Button
		var font_size := button.get_theme_font_size("font_size") if button != null else -1
		_check(button != null and font_size >= 11, "%s is readable at 1280 (font=%d)" % [button_name, font_size])

	var go_button := scene.get_node_or_null("%s/GoCommandMatrixButton" % GRID_PATH) as Button
	var go_font_size := go_button.get_theme_font_size("font_size") if go_button != null else -1
	_check(go_button != null and go_font_size >= 13, "GO keeps the strongest readable label (font=%d)" % go_font_size)

	var marker_count := 0
	var visible_marker_count := 0
	for child_variant in grid.get_children() if grid != null else []:
		var button := child_variant as Button
		if button == null:
			continue
		var marker := button.get_node_or_null("TinyButtonMarker") as Label
		if marker == null:
			continue
		marker_count += 1
		if marker.visible:
			visible_marker_count += 1
	_check(marker_count >= 15, "Technical slot markers remain available for diagnostics")
	_check(visible_marker_count == 0, "Technical slot markers do not clutter the player view")

	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_check(simulation_root != null, "Fixture exposes SimulationRoot")
	if simulation_root != null:
		var command_count_before := Array(simulation_root.get("command_queue")).size()
		var effect_count_before := Array(simulation_root.get("effects_queue")).size()
		controller.call("_apply_command_matrix_1280_readability")
		_check(Array(simulation_root.get("command_queue")).size() == command_count_before, "Readability styling enqueues no command")
		_check(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "Readability styling enqueues no effect")
	var snapshot: Dictionary = Dictionary(controller.call("get_command_matrix_1280_readability_snapshot")) if controller != null else {}
	_check(String(snapshot.get("style_id", "")) == "task_1157_command_matrix_1280_readability_v1", "Snapshot identifies the TASK 1157 style")
	_check(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot declares no gameplay truth")

	scene.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1157 PASS (%d checks)" % _checks)
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
