extends SceneTree
## Real in-tree theme notifications; no mission, gameplay, or timing claim.
const THEME: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]
const COLORS: Array[String] = ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]

class NoticeButton extends Button:
	var theme_notifications := 0
	func _notification(what: int) -> void:
		if what == NOTIFICATION_THEME_CHANGED:
			theme_notifications += 1

class NoticeOption extends OptionButton:
	var theme_notifications := 0
	func _notification(what: int) -> void:
		if what == NOTIFICATION_THEME_CHANGED:
			theme_notifications += 1

class NoticeLabel extends Label:
	var theme_notifications := 0
	func _notification(what: int) -> void:
		if what == NOTIFICATION_THEME_CHANGED:
			theme_notifications += 1

class NoticePanel extends PanelContainer:
	var theme_notifications := 0
	func _notification(what: int) -> void:
		if what == NOTIFICATION_THEME_CHANGED:
			theme_notifications += 1

class NoticeProgress extends ProgressBar:
	var theme_notifications := 0
	func _notification(what: int) -> void:
		if what == NOTIFICATION_THEME_CHANGED:
			theme_notifications += 1

var _passed := 0
var _failed := 0
var _pressed_calls := 0
var _facts: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	root.add_child(host)
	var button := NoticeButton.new()
	button.text = "Existing command"
	button.tooltip_text = "Existing tooltip"
	button.toggle_mode = true
	button.button_pressed = true
	button.disabled = true
	button.pressed.connect(_on_pressed)
	host.add_child(button)
	var option := NoticeOption.new()
	option.add_item("Existing option")
	option.select(0)
	host.add_child(option)
	var label := NoticeLabel.new()
	label.text = "Existing identity"
	host.add_child(label)
	var panel := NoticePanel.new()
	host.add_child(panel)
	var progress := NoticeProgress.new()
	progress.value = 63.0
	host.add_child(progress)
	await process_frame
	await process_frame
	var command_state := _command_state(button)
	for status in ["neutral", "selected", "danger", "success", "warning", "go", "accent"]:
		THEME.style_command_button(button, status)
		var expected := _button_style(button)
		_facts["button_" + status] = expected
		button.theme_notifications = 0
		THEME.style_command_button(button, status)
		_check(button.theme_notifications == 0, "%s identical button styling emits no theme notification" % status)
		_check(_button_style(button) == expected, "%s keeps every final style/color/font" % status)
		_check(_command_state(button) == command_state, "%s preserves command fields and callback identity" % status)
	_check(button.get_theme_font_size("font_size") == THEME.BUTTON_FONT_SIZE, "Command font remains the existing theme size")
	THEME.style_command_button(button, "selected")
	var selected := _button_style(button)
	var wrong := StyleBoxFlat.new()
	wrong.bg_color = Color.MAGENTA
	button.add_theme_stylebox_override("normal", wrong)
	button.add_theme_color_override("font_color", Color.MAGENTA)
	button.add_theme_font_size_override("font_size", 72)
	button.theme = Theme.new()
	THEME.style_command_button(button, "selected")
	_check(_button_style(button) == selected and button.theme == THEME.get_theme(), "Actual external style, color, size and theme overrides are repaired")
	_check(wrong.bg_color == Color.MAGENTA, "Repair does not mutate a foreign StyleBox resource")
	var inherited := THEME.get_theme().duplicate(true) as Theme
	inherited.set_color("font_color", "Button", THEME.COLOR_TEXT)
	button.theme = inherited
	button.remove_theme_color_override("font_color")
	_check(button.get_theme_color("font_color") == THEME.COLOR_TEXT, "Fixture inherited font color already equals the desired value")
	THEME.style_command_button(button, "selected")
	_check(button.has_theme_color_override("font_color"), "Styler still installs its owned override when inherited value happens to match")
	for spec in [{"selected": false, "primary": false}, {"selected": true, "primary": false}, {"selected": false, "primary": true}]:
		THEME.style_action_tile(button, bool(spec.selected), bool(spec.primary))
		var expected := _button_style(button)
		_facts["tile_" + str(spec)] = expected
		button.theme_notifications = 0
		THEME.style_action_tile(button, bool(spec.selected), bool(spec.primary))
		_check(button.theme_notifications == 0, "Action tile applies no generic intermediate margin/font reset: %s" % spec)
		_check(_button_style(button) == expected, "Action tile retains its complete final output: %s" % spec)
		_check(button.get_theme_stylebox("normal").content_margin_left == 4.0 and button.get_theme_font_size("font_size") == 11, "Action tile keeps its existing four-pixel margin and eleven-point font")
	THEME.style_command_button(option, "neutral")
	var popup_theme := option.get_popup().theme
	option.theme_notifications = 0
	THEME.style_command_button(option, "neutral")
	_check(option.theme_notifications == 0, "Unchanged OptionButton styling emits no theme notification")
	_check(option.get_popup().theme == popup_theme and popup_theme == THEME.get_theme() and option.selected == 0, "Option popup retains shared theme and actual selection")
	option.get_popup().theme = Theme.new()
	THEME.style_command_button(option, "neutral")
	_check(option.get_popup().theme == THEME.get_theme(), "Externally replaced popup theme is repaired")
	for muted in [false, true]:
		THEME.style_label(label, muted, 17)
		var expected := {"color": label.get_theme_color("font_color"), "size": label.get_theme_font_size("font_size")}
		label.theme_notifications = 0
		THEME.style_label(label, muted, 17)
		_check(label.theme_notifications == 0, "Unchanged body label avoids repeated theme notifications")
		_check(label.get_theme_color("font_color") == expected.color and label.get_theme_font_size("font_size") == expected.size and label.text == "Existing identity", "Body label preserves output and identity")
	THEME.style_section_heading(label, 19)
	var heading_font := label.get_theme_font("font")
	label.theme_notifications = 0
	THEME.style_section_heading(label, 19)
	_check(label.theme_notifications == 0, "Unchanged heading avoids repeated font/color/constant notifications")
	_check(label.get_theme_font("font") == heading_font and label.get_theme_font_size("font_size") == 19, "Heading retains shared font and requested size")
	label.add_theme_font_override("font", SystemFont.new())
	THEME.style_section_heading(label, 19)
	_check(label.get_theme_font("font") == heading_font, "Heading repairs an actual foreign font override")
	THEME.style_badge(label, "warning")
	var badge_style := label.get_theme_stylebox("normal")
	label.theme_notifications = 0
	THEME.style_badge(label, "warning")
	_check(label.theme_notifications == 0 and label.get_theme_stylebox("normal") == badge_style and label.get_theme_color("font_color") == THEME.status_color("warning") and label.get_theme_font_size("font_size") == 11, "Badge keeps its complete final output without repeated notifications")
	for selected_card in [false, true]:
		THEME.style_card(panel, selected_card)
		var expected := panel.get_theme_stylebox("panel")
		var children := panel.get_child_count()
		panel.theme_notifications = 0
		THEME.style_card(panel, selected_card)
		_check(panel.theme_notifications == 0 and panel.get_theme_stylebox("panel") == expected, "Unchanged card avoids notifications and keeps the exact style resource")
		_check(panel.get_child_count() == children, "Card decoration does not rebuild children")
	THEME.style_progress_bar(progress, "warning")
	var fill := progress.get_theme_stylebox("fill")
	progress.theme_notifications = 0
	THEME.style_progress_bar(progress, "warning")
	_check(progress.theme_notifications == 0 and progress.get_theme_stylebox("fill") == fill and progress.value == 63.0, "Progress styling is idempotent and preserves its existing value")
	button.pressed.emit()
	_check(_pressed_calls == 1 and _command_state(button) == command_state, "The original callback remains connected once with unchanged gates")
	print("R3_THEME_OUTPUT_FACTS " + JSON.stringify(_facts))
	host.queue_free()
	await process_frame
	await process_frame
	print("R3_THEME_IDEMPOTENCY: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("R3_THEME_IDEMPOTENCY_PASS")
	quit(1 if _failed > 0 else 0)


func _on_pressed() -> void:
	_pressed_calls += 1


func _command_state(button: Button) -> Dictionary:
	return {"text": button.text, "tooltip": button.tooltip_text, "disabled": button.disabled, "toggle": button.toggle_mode, "pressed": button.button_pressed, "callbacks": button.pressed.get_connections()}


func _button_style(button: Button) -> Dictionary:
	var result: Dictionary = {"font_size": button.get_theme_font_size("font_size")}
	for color in COLORS:
		result[color] = button.get_theme_color(color).to_html()
	for state in STATES:
		var style := button.get_theme_stylebox(state) as StyleBoxFlat
		result[state] = {"fill": style.bg_color.to_html(), "border": style.border_color.to_html(), "radius": style.corner_radius_top_left, "widths": [style.border_width_left, style.border_width_top, style.border_width_right, style.border_width_bottom], "margins": [style.content_margin_left, style.content_margin_top, style.content_margin_right, style.content_margin_bottom]}
	return result


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", message)
	else:
		_failed += 1
		print("FAIL: ", message)
