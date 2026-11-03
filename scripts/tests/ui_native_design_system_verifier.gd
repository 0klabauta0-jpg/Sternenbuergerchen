extends SceneTree

const DESIGN: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
var _failed := 0
var _passed := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
	print("%s: %s" % ["PASS" if condition else "FAIL", message])

func _run() -> void:
	var methods: Array = DESIGN.get_script_method_list()
	for required in ["get_theme", "apply_screen", "style_action_tile"]:
		_check(methods.any(func(method: Dictionary) -> bool: return method.name == required), "Shared native API: " + required)
	if _failed > 0:
		print("RESULTS: %d passed, %d failed" % [_passed, _failed])
		quit(1)
		return
	var screen := Control.new()
	root.add_child(screen)
	DESIGN.call("apply_screen", screen)
	var shared_theme: Theme = DESIGN.call("get_theme")
	_check(screen.theme == shared_theme, "Screen receives cached shared theme")
	_check(DESIGN.call("get_theme") == shared_theme, "Theme is reused rather than rebuilt")
	var option := OptionButton.new()
	option.add_item("Landezone wählen")
	screen.add_child(option)
	var input := LineEdit.new()
	screen.add_child(input)
	var tile := Button.new()
	tile.text = "Plan\nausführen"
	tile.tooltip_text = "Vorhandenen Plan ausführen"
	screen.add_child(tile)
	DESIGN.call("style_action_tile", tile, false, true)
	await process_frame
	_check(option.get_theme_color("font_color").get_luminance() > 0.5, "Dropdown text stays readable on dark surface")
	_check(input.get_theme_color("font_color").get_luminance() > 0.5, "Input text stays readable on dark surface")
	_check(option.get_popup().get_theme_color("font_color").get_luminance() > 0.5, "Popup inherits readable text")
	_check(tile.get_theme_stylebox("focus") != null, "Action tile has visible keyboard focus style")
	_check(tile.tooltip_text == "Vorhandenen Plan ausführen", "Styling preserves control semantics")
	var before := tile.get_theme_stylebox("normal")
	DESIGN.call("style_action_tile", tile, true, false)
	var selected := tile.get_theme_stylebox("normal")
	_check(before != selected, "Primary and selected action states have distinct styling")
	_check(tile.get_theme_stylebox("disabled") != null, "Disabled action styling exists")
	screen.queue_free()
	await process_frame
	print("RESULTS: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("PASS: native UI design system")
	quit(1 if _failed > 0 else 0)
