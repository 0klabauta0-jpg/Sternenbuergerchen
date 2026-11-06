extends SceneTree
## Verifies final native presentation and observes real mutations across the
## generic base-skin boundary. No synthetic gameplay or long-lived UI cache.

const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const SKIN: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const NATIVE: GDScript = preload("res://scripts/ui/mission_a5_hud_layout.gd")
const GRID: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/"
const PRIMARY: Array[String] = ["MoveButton", "TakeButton", "HoldButton", "FlankButton", "GoCommandMatrixButton", "TargetButton", "ClearTargetButton", "DeleteOrderButton", "SortCommandMatrixButton"]
const STYLE_STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]

var _passed := 0
var _failed := 0


class NativeStyleProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture_local := true
	var fixture_all := false
	var fixture_delete := false
	var fixture_orders := false
	var fixture_rule := "return"
	var primary_base_mutations := 0
	var non_primary_base_calls := 0
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
		return "NW"
	func _apply_native_a5_hud_layout() -> void:
		# Exercise the actual final presenter without unrelated player-text reads.
		NATIVE_A5_HUD_LAYOUT_SCRIPT.configure(self, native_context())
	func _apply_dynamic_button_base_style(button: Button, is_active: bool) -> void:
		var is_primary: bool = button != null and String(button.name) in ["MoveButton", "TakeButton", "HoldButton", "FlankButton", "GoCommandMatrixButton", "TargetButton", "ClearTargetButton", "DeleteOrderButton", "SortCommandMatrixButton"]
		var before: Dictionary = _base_boundary_state(button) if is_primary else {}
		super._apply_dynamic_button_base_style(button, is_active)
		if is_primary:
			if before != _base_boundary_state(button):
				primary_base_mutations += 1
		else:
			non_primary_base_calls += 1
	func native_context() -> Dictionary:
		return {"target_armed": _is_target_placement_armed, "fire_rule": fixture_rule, "fire_rule_enabled": not preview_mode and fixture_local and not _selected_fireteam_ids.is_empty(), "delete_active": fixture_delete, "sort_active": not preview_mode and fixture_local and not _selected_fireteam_ids.is_empty(), "feedback": _last_command_text}
	func configure_case(spec: Dictionary) -> void:
		preview_mode = bool(spec.preview)
		fixture_local = bool(spec.local)
		fixture_all = bool(spec.selected)
		fixture_delete = bool(spec.delete_focus)
		fixture_orders = bool(spec.orders)
		fixture_rule = String(spec.rule)
		_selected_fireteam_ids = PackedStringArray(["blue"]) if bool(spec.selected) else PackedStringArray()
		_is_target_placement_armed = bool(spec.target)
		primary_base_mutations = 0
		non_primary_base_calls = 0
	func _base_boundary_state(button: Button) -> Dictionary:
		var result: Dictionary = {"theme": button.theme, "font_size": button.get_theme_font_size("font_size")}
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			result[state] = button.get_theme_stylebox(state)
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
			result[color_name] = button.get_theme_color(color_name)
		return result


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(12):
		await process_frame
	var probe := NativeStyleProbe.new()
	probe.name = "NativeStyleOwnershipProbe"
	scene.add_child(probe)
	probe.set_meta("native_a5_legacy_setup_complete", true)
	var buttons: Dictionary = {}
	for button_name in PRIMARY:
		var button := probe.get_node_or_null(GRID + button_name) as Button
		_check(button != null, "Real mission scene retains %s" % button_name)
		if button != null:
			buttons[button_name] = button
	if buttons.size() != PRIMARY.size():
		probe.free()
		scene.queue_free()
		await process_frame
		_finish()
		return
	var cases: Array[Dictionary] = [
		{"id": "selected_ready", "preview": false, "local": true, "selected": true, "delete_focus": true, "orders": true, "target": true, "rule": "return", "go_disabled": false},
		{"id": "preview_blocked", "preview": true, "local": true, "selected": true, "delete_focus": false, "orders": true, "target": false, "rule": "hold", "go_disabled": true},
		{"id": "observer", "preview": false, "local": false, "selected": true, "delete_focus": true, "orders": true, "target": true, "rule": "free", "go_disabled": true},
		{"id": "no_selection_or_orders", "preview": false, "local": true, "selected": false, "delete_focus": false, "orders": false, "target": false, "rule": "mixed", "go_disabled": true},
	]
	for spec in cases:
		probe.configure_case(spec)
		(buttons["GoCommandMatrixButton"] as Button).disabled = bool(spec.go_disabled)
		var references: Dictionary = {}
		var callbacks: Dictionary = {}
		for button_name in PRIMARY:
			var button := buttons[button_name] as Button
			# Frozen old order: generic base skin first, final native owner second.
			var base_active := false
			if button_name == "TargetButton":
				base_active = bool(spec.target)
			elif button_name == "DeleteOrderButton":
				base_active = bool(spec.delete_focus)
			elif button_name == "SortCommandMatrixButton":
				base_active = not bool(spec.preview) and bool(spec.local) and bool(spec.selected)
			elif button_name == "GoCommandMatrixButton":
				base_active = not bool(spec.preview) and bool(spec.local) and bool(spec.orders)
			SKIN.style_tactical_button(button, base_active)
			callbacks[button_name] = button.get_signal_connection_list("pressed").duplicate(true)
		NATIVE.configure(probe, probe.native_context())
		for button_name in PRIMARY:
			references[button_name] = _visible_style(buttons[button_name])
		probe.primary_base_mutations = 0
		probe.non_primary_base_calls = 0
		probe.call("_refresh_dynamic_button_styles")
		_check(probe.primary_base_mutations == 0, "%s A5 primary controls avoid the intermediate generic base reset" % spec.id)
		_check(probe.non_primary_base_calls == 16, "%s retains all 16 non-primary base calls" % spec.id)
		for button_name in PRIMARY:
			var button := buttons[button_name] as Button
			_check(_visible_style(button) == references[button_name], "%s %s matches the former final native style" % [spec.id, button_name])
			_check(button.get_signal_connection_list("pressed") == callbacks[button_name], "%s %s preserves its existing callbacks" % [spec.id, button_name])
		_check((buttons["GoCommandMatrixButton"] as Button).disabled == bool(spec.go_disabled), "%s retains the current GO gate" % spec.id)
		probe.primary_base_mutations = 0
		probe.call("_refresh_dynamic_button_styles")
		_check(probe.primary_base_mutations == 0, "%s repeated refresh performs no generic primary-style mutation" % spec.id)
		for button_name in PRIMARY:
			_check(_visible_style(buttons[button_name]) == references[button_name], "%s repeated %s output stays current and stable" % [spec.id, button_name])
	# The original generic sink remains available outside native A5 ownership.
	probe.set_meta("native_a5_legacy_setup_complete", false)
	probe.primary_base_mutations = 0
	probe.call("_apply_dynamic_button_base_style", buttons["MoveButton"], false)
	_check(probe.primary_base_mutations == 1, "Legacy mode still applies the original generic primary skin")
	probe.free()
	scene.queue_free()
	for _frame in range(3):
		await process_frame
	_finish()


func _visible_style(button: Button) -> Dictionary:
	var result: Dictionary = {"text": button.text, "font": button.get_theme_font("font"), "font_size": button.get_theme_font_size("font_size"), "font_color": button.get_theme_color("font_color"), "self_modulate": button.self_modulate, "icon": button.icon, "icon_width": button.get_theme_constant("icon_max_width"), "disabled": button.disabled}
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


func _finish() -> void:
	print("HUD_ARCHITECTURE_20261106_NATIVE_STYLE: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("HUD_NATIVE_STYLE_VERIFY_PASS")
	quit(1 if _failed > 0 else 0)
