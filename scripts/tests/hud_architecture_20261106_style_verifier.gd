extends SceneTree
## Exercises real dynamic-style orchestration, skins and role affordances.
## Controlled read owners keep the fixture independent of a running mission.

const SKIN: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const GRID: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/"
const STRATEGIC: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/"
const NAV: String = "TacticalUI/TopNavPanel/NavMargin/NavRow/"
const ALL: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/AllFireteamsButton"
const COMMAND_NAMES: Array[String] = ["MoveButton", "HoldButton", "FlankButton", "TakeButton", "DoorBreachButton", "TargetButton", "ClearTargetButton", "DeleteOrderButton", "WaypointEraseButton", "SortCommandMatrixButton", "FireRuleHoldButton", "FireRuleReturnButton", "FireRuleFreeButton", "FireRuleSuppressButton", "GoCommandMatrixButton"]
const ROE_NAMES: Array[String] = ["FireRuleHoldButton", "FireRuleReturnButton", "FireRuleFreeButton", "FireRuleSuppressButton"]
const STYLE_STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]
const FONT_STATES: Array[String] = ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]

var _passed := 0
var _failed := 0


class CountingController extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var style_calls: Dictionary = {}
	var style_active: Dictionary = {}
	var fixture_local := true
	var fixture_all := false
	var fixture_delete := false
	var fixture_orders := false
	var fixture_rule := ""
	var fixture_approach := "NW"
	var roe_refresh_calls := 0
	var native_layout_calls := 0
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
	func _can_issue_local_commands() -> bool:
		return fixture_local
	func _is_all_fireteams_selected() -> bool:
		return fixture_all
	func _has_deletable_order_focus() -> bool:
		return fixture_delete
	func _has_selected_fireteam_orders_to_execute() -> bool:
		return fixture_orders
	func _get_selected_fire_rule_consensus() -> String:
		return fixture_rule
	func _get_approach_angle_name() -> String:
		return fixture_approach
	func _apply_dynamic_button_base_style(button: Button, is_active: bool) -> void:
		if button == null:
			return
		var button_name := String(button.name)
		style_calls[button_name] = int(style_calls.get(button_name, 0)) + 1
		style_active[button_name] = is_active
		# Keep the real style sink. On the old implementation this entry is never
		# called, so RED reports missing counted final applications, not a parse error.
		META_UI_SKIN_SCRIPT.style_tactical_button(button, is_active)
	func _refresh_fire_rule_button_state() -> void:
		roe_refresh_calls += 1
		super._refresh_fire_rule_button_state()
	func _apply_native_a5_hud_layout() -> void:
		# Native node construction belongs to separate scene/runtime checks. The
		# real command-matrix font/margin overlay still runs before this boundary.
		native_layout_calls += 1
	func configure_case(spec: Dictionary) -> void:
		preview_mode = bool(spec.preview)
		fixture_local = bool(spec.local)
		fixture_all = bool(spec.all_selected)
		fixture_delete = bool(spec.delete_focus)
		fixture_orders = bool(spec.orders)
		fixture_rule = String(spec.rule)
		fixture_approach = String(spec.approach)
		_selected_fireteam_ids = PackedStringArray(["blue"]) if bool(spec.selected) else PackedStringArray()
		_is_target_placement_armed = bool(spec.target)
		_is_lz_placement_armed = bool(spec.lz)
		_drop_ship_requested = bool(spec.drop)
		_phase_execution_by_fireteam = {"blue": {"state": "active"}}
		style_calls.clear()
		style_active.clear()
		roe_refresh_calls = 0
		native_layout_calls = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture := Node.new()
	fixture.name = "DynamicStyleFixture"
	root.add_child(fixture)
	var buttons := _build_buttons(fixture)
	var expected_buttons: Dictionary = {}
	var expected_host := Node.new()
	expected_host.name = "ExpectedStyles"
	fixture.add_child(expected_host)
	for button_name in buttons:
		var expected_button := Button.new()
		expected_button.name = String(button_name)
		expected_button.toggle_mode = ROE_NAMES.has(String(button_name))
		expected_host.add_child(expected_button)
		expected_buttons[button_name] = expected_button
	var controller := CountingController.new()
	controller.name = "TacticalController"
	fixture.add_child(controller)
	var cases: Array[Dictionary] = [
		{"id": "local_ready", "preview": false, "local": true, "selected": true, "all_selected": true, "delete_focus": true, "orders": true, "rule": "return", "approach": "SE", "target": true, "lz": true, "drop": true, "door_enabled": true, "door_severity": "action", "roe_enabled": true, "active_roe": "FireRuleReturnButton", "active": ["MissionNavButton", "AllFireteamsButton", "TargetButton", "DeleteOrderButton", "WaypointEraseButton", "SortCommandMatrixButton", "DoorBreachButton", "GoCommandMatrixButton", "SetLZButton", "CallDropshipButton", "SEButton"]},
		{"id": "preview", "preview": true, "local": true, "selected": true, "all_selected": false, "delete_focus": false, "orders": true, "rule": "free", "approach": "NW", "target": false, "lz": false, "drop": false, "door_enabled": false, "door_severity": "warning", "roe_enabled": false, "active_roe": "", "active": ["MissionNavButton", "NWButton"]},
		{"id": "remote_observer", "preview": false, "local": false, "selected": true, "all_selected": true, "delete_focus": true, "orders": true, "rule": "free", "approach": "NE", "target": true, "lz": false, "drop": false, "door_enabled": false, "door_severity": "success", "roe_enabled": false, "active_roe": "", "active": ["MissionNavButton", "AllFireteamsButton", "TargetButton", "DeleteOrderButton", "WaypointEraseButton", "NEButton"]},
		{"id": "no_selection", "preview": false, "local": true, "selected": false, "all_selected": false, "delete_focus": false, "orders": false, "rule": "mixed", "approach": "SW", "target": false, "lz": false, "drop": false, "door_enabled": false, "door_severity": "neutral", "roe_enabled": false, "active_roe": "", "active": ["MissionNavButton", "SWButton"]},
		{"id": "selected_without_orders", "preview": false, "local": true, "selected": true, "all_selected": false, "delete_focus": false, "orders": false, "rule": "hold", "approach": "NW", "target": false, "lz": false, "drop": false, "door_enabled": false, "door_severity": "neutral", "roe_enabled": true, "active_roe": "FireRuleHoldButton", "active": ["MissionNavButton", "SortCommandMatrixButton", "NWButton"]},
	]
	for spec in cases:
		controller.configure_case(spec)
		var door := buttons["DoorBreachButton"] as Button
		door.set_meta("door_interaction_button_enabled", bool(spec.door_enabled))
		door.set_meta("door_authority_ui_severity", String(spec.door_severity))
		controller.call("_refresh_dynamic_button_styles")
		_check(controller.style_calls.size() == 25, "%s applies one final base skin to each of 25 non-ROE buttons" % spec.id)
		for button_name in buttons:
			var is_roe: bool = ROE_NAMES.has(String(button_name))
			_check(int(controller.style_calls.get(button_name, 0)) == (0 if is_roe else 1), "%s %s has no neutral intermediate application" % [spec.id, button_name])
			if not is_roe:
				_check(bool(controller.style_active.get(button_name, false)) == Array(spec.active).has(button_name), "%s %s uses its current final active state" % [spec.id, button_name])
			_apply_expected_output(expected_buttons[button_name], String(button_name), spec)
			var actual_style := _visible_style(buttons[button_name])
			var expected_style := _visible_style(expected_buttons[button_name])
			_check(actual_style == expected_style, "%s %s preserves the visible skin and role overlays" % [spec.id, button_name])
			if actual_style != expected_style:
				for field in actual_style:
					if actual_style[field] != expected_style.get(field):
						print("STYLE_DIFF ", spec.id, " ", button_name, " ", field, " actual=", actual_style[field], " expected=", expected_style.get(field))
		_check(controller.roe_refresh_calls == 1, "%s preserves the single ROE-owner refresh" % spec.id)
		_check(controller.native_layout_calls == 1, "%s preserves the final layout boundary" % spec.id)
		_check(bool(door.get_meta("door_interaction_button_enabled", false)) == bool(spec.door_enabled), "%s keeps door authority metadata read-only" % spec.id)
		for roe_name in ROE_NAMES:
			var roe := buttons[roe_name] as Button
			_check(roe.disabled == (not bool(spec.roe_enabled)) and roe.button_pressed == (roe_name == String(spec.active_roe)), "%s %s preserves ROE enable and active semantics" % [spec.id, roe_name])
		var first_output: Dictionary = {}
		for button_name in buttons:
			first_output[button_name] = _visible_style(buttons[button_name])
		controller.style_calls.clear()
		controller.call("_refresh_dynamic_button_styles")
		_check(controller.style_calls.size() == 25, "%s still reads every final style on a repeated pass" % spec.id)
		for button_name in buttons:
			_check(first_output[button_name] == _visible_style(buttons[button_name]), "%s repeated %s output is stable" % [spec.id, button_name])
	for expected_button in expected_buttons.values():
		(expected_button as Button).free()
	fixture.free()
	print("HUD_ARCHITECTURE_20261106_STYLES: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("HUD_STYLE_VERIFY_PASS")
	quit(1 if _failed > 0 else 0)


func _build_buttons(fixture: Node) -> Dictionary:
	var paths: Array[String] = [NAV + "HomebaseNavButton", NAV + "FOBNavButton", NAV + "MissionNavButton", ALL]
	for command_name in COMMAND_NAMES:
		paths.append(GRID + command_name)
	for action_name in ["SetLZButton", "CallDropshipButton"]:
		paths.append(STRATEGIC + "StrategicActionRow/" + action_name)
	for phase_name in ["PrevEditPhaseButton", "AddPhaseButton", "NextEditPhaseButton", "NextPhaseButton"]:
		paths.append(STRATEGIC + "PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/" + phase_name)
	for approach in ["NW", "NE", "SW", "SE"]:
		paths.append(STRATEGIC + "ApproachGrid/" + approach + "Button")
	var result: Dictionary = {}
	for path in paths:
		var parts := path.split("/")
		var parent := fixture
		for index in range(parts.size() - 1):
			var child := parent.get_node_or_null(NodePath(parts[index]))
			if child == null:
				child = GridContainer.new() if parts[index] == "CommandGrid" else Control.new()
				child.name = parts[index]
				parent.add_child(child)
			parent = child
		var button := Button.new()
		button.name = parts[-1]
		button.toggle_mode = ROE_NAMES.has(String(button.name))
		button.set_meta("fire_rule_control", button.toggle_mode)
		parent.add_child(button)
		result[String(button.name)] = button
	return result


func _apply_expected_output(button: Button, button_name: String, spec: Dictionary) -> void:
	# Literal active sets above are independently hand-derived from the fixture.
	# The real shared skin is a dependency, not the orchestration under test.
	var is_roe: bool = ROE_NAMES.has(button_name)
	var active: bool = button_name == String(spec.active_roe) if is_roe else Array(spec.active).has(button_name)
	SKIN.style_tactical_button(button, active)
	if is_roe:
		button.disabled = not bool(spec.roe_enabled)
		button.button_pressed = active
		button.self_modulate = Color(1.0, 0.88, 0.34, 1.0) if active else Color.WHITE
		for color_name in ["font_color", "font_pressed_color", "font_hover_color", "font_focus_color"]:
			if active:
				button.add_theme_color_override(color_name, Color(0.02, 0.02, 0.015, 1.0) if color_name in ["font_hover_color", "font_focus_color"] else Color(0.06, 0.055, 0.035, 1.0))
			elif button.has_theme_color_override(color_name):
				button.remove_theme_color_override(color_name)
	if button_name == "DoorBreachButton":
		var door_colors: Dictionary = {"action": [Color(0.72, 0.95, 1.0, 1.0), Color(0.04, 0.07, 0.08, 1.0)], "success": [Color(0.70, 1.0, 0.82, 1.0), Color(0.03, 0.08, 0.045, 1.0)], "warning": [Color(1.0, 0.84, 0.42, 1.0), Color(0.10, 0.07, 0.02, 1.0)]}
		var colors: Array = Array(door_colors.get(String(spec.door_severity), []))
		button.self_modulate = Color.WHITE if colors.is_empty() else colors[0]
		if not colors.is_empty():
			for color_name in ["font_color", "font_pressed_color", "font_hover_color", "font_focus_color"]:
				button.add_theme_color_override(color_name, colors[1])
	if COMMAND_NAMES.has(button_name):
		var font_size := 10
		if button_name == "GoCommandMatrixButton":
			font_size = 13
		elif is_roe:
			font_size = 11
		elif button_name in ["MoveButton", "TakeButton", "HoldButton", "FlankButton", "TargetButton"]:
			font_size = 12
		button.add_theme_font_size_override("font_size", font_size)
		button.add_theme_constant_override("icon_max_width", 14)
		button.add_theme_constant_override("h_separation", 3)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var compact := button.get_theme_stylebox(state).duplicate() as StyleBox
			compact.content_margin_left = 4.0
			compact.content_margin_right = 4.0
			button.add_theme_stylebox_override(state, compact)


func _visible_style(button: Button) -> Dictionary:
	var result: Dictionary = {"font_size": button.get_theme_font_size("font_size"), "self_modulate": button.self_modulate, "disabled": button.disabled, "pressed": button.button_pressed}
	for color_name in FONT_STATES:
		result[color_name] = button.get_theme_color(color_name)
	for state in STYLE_STATES:
		var style := button.get_theme_stylebox(state) as StyleBoxFlat
		result[state] = {} if style == null else {"fill": style.bg_color, "border": style.border_color, "width": style.border_width_left, "radius": style.corner_radius_top_left, "left": style.content_margin_left, "right": style.content_margin_right, "top": style.content_margin_top, "bottom": style.content_margin_bottom}
	return result


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)
