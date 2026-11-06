extends SceneTree
## Real A5 controls and legacy-boundary observations. UI fixtures only;
## no actors, command owners, physics values or simulation timers are patched.
const SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const NATIVE: GDScript = preload("res://scripts/ui/mission_a5_hud_layout.gd")
const GRID := "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/"

class LabelProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture_local := true
	var fixture_delete := false
	var boundary: Dictionary = {}
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
	func _can_issue_local_commands() -> bool:
		return fixture_local
	func _has_deletable_order_focus() -> bool:
		return fixture_delete
	func _get_selected_fire_rule_consensus() -> String:
		return "return"
	func _apply_native_a5_hud_layout() -> void:
		NATIVE_A5_HUD_LAYOUT_SCRIPT.configure(self, {"target_armed": _is_target_placement_armed, "fire_rule": "return", "fire_rule_enabled": not preview_mode and fixture_local and not _selected_fireteam_ids.is_empty(), "delete_active": fixture_delete, "sort_active": not preview_mode and fixture_local and not _selected_fireteam_ids.is_empty()})
	func _apply_command_matrix_1280_readability() -> void:
		boundary = primary_snapshot()
		super._apply_command_matrix_1280_readability()
	func configure_case(spec: Dictionary) -> void:
		preview_mode = bool(spec.preview)
		fixture_local = bool(spec.local)
		fixture_delete = bool(spec.selected)
		_selected_fireteam_ids = PackedStringArray(["ft1"]) if bool(spec.selected) else PackedStringArray()
		_is_target_placement_armed = bool(spec.target)
	func primary_snapshot() -> Dictionary:
		var result: Dictionary = {}
		for name in NATIVE_A5_HUD_LAYOUT_SCRIPT.LABELS:
			var button := get_node_or_null(COMMAND_GRID_PATH + "/" + String(name)) as Button
			if button != null:
				result[name] = {"text": button.text, "icon": button.icon, "font": button.get_theme_font("font"), "font_size": button.get_theme_font_size("font_size"), "expand": button.expand_icon, "icon_alignment": button.icon_alignment, "vertical_icon_alignment": button.vertical_icon_alignment, "normal_style": button.get_theme_stylebox("normal")}
		return result

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(12):
		await process_frame
	var owner: Node = scene.get_node("TacticalController")
	owner.set_process(false)
	var simulation: Node = scene.get_node("SimulationRoot")
	var probe := LabelProbe.new()
	probe.name = "NativeLabelBoundaryProbe"
	scene.add_child(probe)
	probe.set_meta("native_a5_legacy_setup_complete", true)
	# Deliberately omit any earlier legacy icon initialization for Target.
	var target := probe.get_node(GRID + "TargetButton") as Button
	target.icon = null
	probe.call("_apply_drop_light_hud_button_labels")
	_check(target.icon != null, "Fresh A5 setup still initializes a Target texture before any earlier generic pass")
	var expected_target: Texture2D
	if NATIVE.ICON_IDS.has("TargetButton"):
		expected_target = NATIVE.ICONS.get_icon(String(NATIVE.ICON_IDS.TargetButton))
	else:
		# The legacy cache key uses the controller-relative path, exactly as the
		# original public compatibility pass does; obtain that same immutable input.
		expected_target = probe.call("_get_compact_command_matrix_icon", GRID + "TargetButton", probe.COMMAND_TARGET_ICON)
	_check(target.icon == expected_target, "Fresh Target keeps its actual native or compatible legacy texture identity")
	var cases: Array[Dictionary] = [
		{"id": "ready", "preview": false, "local": true, "selected": true, "target": false},
		{"id": "target_armed", "preview": false, "local": true, "selected": true, "target": true},
		{"id": "preview", "preview": true, "local": true, "selected": true, "target": false},
		{"id": "observer", "preview": false, "local": false, "selected": true, "target": true},
		{"id": "no_selection", "preview": false, "local": true, "selected": false, "target": false},
	]
	for spec in cases:
		probe.configure_case(spec)
		probe.call("_apply_native_a5_hud_layout")
		var expected := probe.primary_snapshot()
		var gate_state := _gate_state(probe)
		var gameplay_before := _owner_state(owner, simulation)
		probe.boundary.clear()
		probe.call("_apply_drop_light_hud_button_labels")
		_check(probe.boundary == expected, "%s generic label/icon pass performs no intermediate native-primary mutation" % spec.id)
		_check(probe.primary_snapshot() == expected, "%s final native labels, icons, fonts and alignments remain identical" % spec.id)
		_check(_gate_state(probe) == gate_state, "%s preserves disabled/toggle state, metadata and actual callback identities" % spec.id)
		_check(_owner_state(owner, simulation) == gameplay_before, "%s styling changes no command/effect queue or real plan owner" % spec.id)
		for name in NATIVE.LABELS:
			var button := probe.get_node(GRID + String(name)) as Button
			_check(not button.tooltip_text.is_empty(), "%s retains the existing detailed command tooltip" % name)
		for name in NATIVE.RULES:
			var button := probe.get_node(GRID + String(name)) as Button
			_check(button.icon == null and button.get_theme_font_size("font_size") == 13, "%s retains native hidden-ROE icon/font presentation" % name)
	probe.set_meta("native_a5_legacy_setup_complete", false)
	probe.configure_case({"preview": false, "local": true, "selected": true, "target": true})
	var legacy_gates := _gate_state(probe)
	probe.call("_apply_drop_light_hud_button_labels")
	_check(String(Dictionary(probe.boundary.MoveButton).text) == "BW" and String(Dictionary(probe.boundary.TargetButton).text) == "ST", "Legacy mode still reaches its original short labels before its compatibility overlay")
	_check(_gate_state(probe) == legacy_gates, "Legacy presentation preserves its original gates and callback identities")
	_check((probe.get_node(GRID + "TargetButton") as Button).icon != null, "Legacy Target texture remains available")
	probe.free()
	scene.queue_free()
	await process_frame
	await process_frame
	print("R3_NATIVE_LABELS: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("R3_NATIVE_LABELS_PASS")
	quit(1 if _failed > 0 else 0)


func _gate_state(probe: Node) -> Dictionary:
	var result: Dictionary = {}
	for name in NATIVE.LABELS:
		var button := probe.get_node(GRID + String(name)) as Button
		result[name] = {"disabled": button.disabled, "toggle": button.toggle_mode, "pressed": button.button_pressed, "callbacks": button.pressed.get_connections(), "action_id": button.get_meta("command_hierarchy_action_id", ""), "help_id": button.get_meta("help_id", ""), "slot_id": button.get_meta("command_matrix_slot_id", "")}
	return result


func _owner_state(owner: Node, simulation: Node) -> Dictionary:
	return {"commands": Array(simulation.get("command_queue")).duplicate(true), "effects": Array(simulation.get("effects_queue")).duplicate(true), "plans": owner.call("get_order_plans_snapshot"), "areas": owner.call("get_area_orders_snapshot"), "tick": simulation.call("get_tick")}


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", message)
	else:
		_failed += 1
		print("FAIL: ", message)
