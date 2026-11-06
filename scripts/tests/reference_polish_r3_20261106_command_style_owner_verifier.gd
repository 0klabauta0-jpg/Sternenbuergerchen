extends SceneTree
## Controlled presenter fixture over real controls, not physical gameplay proof.
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const NATIVE: GDScript = preload("res://scripts/ui/mission_a5_hud_layout.gd")
const NAMES := ["MoveButton", "TakeButton", "HoldButton", "FlankButton", "TargetButton", "GoCommandMatrixButton"]

class Probe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var observe := false
	var readiness_fixture := false
	var theme_notices := 0
	var receipts: Array = []
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func _has_selected_fireteam_orders_to_execute() -> bool:
		return readiness_fixture
	func note_theme_change() -> void:
		theme_notices += 1
	func presentation(button: Button) -> Dictionary:
		var styles := {}
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			var box := button.get_theme_stylebox(state) as StyleBoxFlat
			styles[state] = {"resource": box, "fill": box.bg_color, "border": box.border_color, "margin": Vector4(box.content_margin_left, box.content_margin_top, box.content_margin_right, box.content_margin_bottom), "width": box.border_width_left, "radius": box.corner_radius_top_left}
		var colors := {}
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			colors[key] = button.get_theme_color(key)
		return {"text": button.text, "clip": button.clip_text, "font": button.get_theme_font("font"), "font_size": button.get_theme_font_size("font_size"), "modulate": button.self_modulate, "styles": styles, "colors": colors, "icon": button.icon, "expand_icon": button.expand_icon, "icon_max_width": button.get_theme_constant("icon_max_width"), "icon_alignment": button.icon_alignment, "vertical_icon_alignment": button.vertical_icon_alignment}
	func _apply_release_firefight_command_primary_button_polish(active: bool) -> void:
		var before := {}
		var notices_before := theme_notices
		if observe:
			for spec in _get_release_firefight_command_primary_button_specs():
				var button := get_node(String(spec.path)) as Button
				before[button.name] = presentation(button)
		super._apply_release_firefight_command_primary_button_polish(active)
		if observe:
			var after := {}
			for spec in _get_release_firefight_command_primary_button_specs():
				var button := get_node(String(spec.path)) as Button
				after[button.name] = presentation(button)
			receipts.append({"path": "primary", "active": active, "before": before, "after": after, "theme_notices": theme_notices - notices_before})
	func _apply_release_firefight_command_go_button_polish(active: bool) -> void:
		if not observe:
			super._apply_release_firefight_command_go_button_polish(active)
			return
		var button := get_node(COMMAND_GRID_PATH + "/GoCommandMatrixButton") as Button
		var before := presentation(button) if observe else {}
		var notices_before := theme_notices
		super._apply_release_firefight_command_go_button_polish(active)
		if observe:
			receipts.append({"path": "go", "active": active, "before": before, "after": presentation(button), "theme_notices": theme_notices - notices_before})

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := MISSION.instantiate()
	var original := scene.get_node("TacticalController")
	var probe := Probe.new()
	for property in original.get_property_list():
		var usage := int(property.usage)
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (usage & PROPERTY_USAGE_EDITOR) != 0:
			probe.set(String(property.name), original.get(String(property.name)))
	scene.remove_child(original)
	original.free()
	probe.name = "TacticalController"
	scene.add_child(probe)
	root.add_child(scene)
	for _frame in range(12):
		await process_frame
	probe.set_process(false)
	probe.set_physics_process(false)
	probe.preview_mode = false
	check(bool(probe.call("_can_issue_local_commands")), "Actual local authority permits the controlled presenter readiness cases")
	var simulation := scene.get_node("SimulationRoot")
	for name in NAMES:
		var button := probe.get_node(probe.COMMAND_GRID_PATH + "/" + name) as Button
		button.theme_changed.connect(probe.note_theme_change)
	for dimensions in [Vector2i(3440, 1440), Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		for _frame in range(3):
			await process_frame
		check(Vector2i(probe.get_viewport().get_visible_rect().size) == dimensions, "%s actual logical viewport" % dimensions)
		for ready in [false, true]:
			probe.readiness_fixture = ready
			for active in [false, true]:
				probe.observe = false
				probe.set_meta("native_a5_legacy_setup_complete", true)
				probe.call("_update_ui", true, false)
				probe.call("_apply_native_a5_hud_layout")
				# This is a UI-only precondition for the isolated polish oracle.
				# Actual authority is checked above; no order/actor is manufactured.
				var go_fixture := probe.get_node(probe.COMMAND_GRID_PATH + "/GoCommandMatrixButton") as Button
				go_fixture.disabled = not ready
				var before := owner_state(probe, simulation)
				probe.receipts.clear()
				probe.observe = true
				probe.call("_apply_release_firefight_command_primary_button_polish", active)
				probe.call("_apply_release_firefight_command_go_button_polish", active)
				var context := "%s ready=%s active=%s" % [dimensions, ready, active]
				check_receipts(probe, context)
				var native_aux := auxiliary(probe)
				check(bool(native_aux.GoCommandMatrixButton.metadata.get("release_firefight_command_matrix_go_ready", false)) == ready, context + " reaches the intended actual readiness projection")
				print("R3_STYLE_READINESS_FACTS ", context, " disabled=", go_fixture.disabled, " local=", probe.call("_can_issue_local_commands"), " actual_ready=", native_aux.GoCommandMatrixButton.metadata.get("release_firefight_command_matrix_go_ready", false))
				check(owner_state(probe, simulation) == before, context + " native polish leaves all owners unchanged")
				probe.observe = false
				probe.set_meta("native_a5_legacy_setup_complete", false)
				probe.call("_apply_release_firefight_command_primary_button_polish", active)
				probe.call("_apply_release_firefight_command_go_button_polish", active)
				check(auxiliary(probe) == native_aux, context + " identical tooltip/meta/readiness/disabled/callback projection to explicit legacy oracle")
				check_legacy(probe, active, context)
				check(owner_state(probe, simulation) == before, context + " legacy oracle leaves all owners unchanged")
		probe.observe = false
		probe.set_meta("native_a5_legacy_setup_complete", true)
		probe.call("_apply_native_a5_hud_layout")
		probe.set("_last_release_firefight_command_matrix_visual_signature", "")
		probe.receipts.clear()
		probe.observe = true
		var before := owner_state(probe, simulation)
		probe.call("_update_ui", true, false)
		check_receipts(probe, "%s real full update" % dimensions)
		check(owner_state(probe, simulation) == before, "%s full UI update leaves owners unchanged" % dimensions)
		probe.observe = false
	scene.queue_free()
	await process_frame
	await process_frame
	print("R3_COMMAND_STYLE_OWNER: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R3_COMMAND_STYLE_OWNER_PASS")
	quit(1 if failed else 0)

func check_receipts(probe: Probe, context: String) -> void:
	check(probe.receipts.size() == 2, context + " reaches both real polish functions")
	for receipt in probe.receipts:
		check(receipt.before == receipt.after, context + " " + String(receipt.path) + " preserves native presentation at the legacy boundary")
		check(int(receipt.theme_notices) == 0, context + " " + String(receipt.path) + " emits no redundant native theme notice")
		if receipt.before != receipt.after:
			print("R3_COMMAND_STYLE_BOUNDARY_DIFF ", context, " ", receipt.path)

func auxiliary(probe: Probe) -> Dictionary:
	var result := {}
	for name in NAMES:
		var button := probe.get_node(probe.COMMAND_GRID_PATH + "/" + name) as Button
		var metadata := {}
		for key in button.get_meta_list():
			if String(key).begins_with("release_firefight_command_matrix_"):
				metadata[key] = button.get_meta(key)
		result[name] = {"tooltip": button.tooltip_text, "metadata": metadata, "disabled": button.disabled, "callbacks": button.pressed.get_connections(), "identity": button.get_instance_id()}
	return result

func check_legacy(probe: Probe, active: bool, context: String) -> void:
	var valid := true
	for spec in probe.call("_get_release_firefight_command_primary_button_specs"):
		var button := probe.get_node(String(spec.path)) as Button
		valid = valid and button.text == String(spec.text) and button.clip_text and button.get_theme_font_size("font_size") == probe.RELEASE_FIREFIGHT_COMMAND_MATRIX_PRIMARY_FONT_SIZE
		if active:
			valid = valid and button.self_modulate == Color(0.86, 0.95, 1.0, 1.0)
	var go := probe.get_node(probe.COMMAND_GRID_PATH + "/GoCommandMatrixButton") as Button
	valid = valid and go.text == "GO" and go.clip_text and go.get_theme_font_size("font_size") == probe.RELEASE_FIREFIGHT_COMMAND_MATRIX_GO_FONT_SIZE
	if active:
		var ready := bool(go.get_meta("release_firefight_command_matrix_go_ready", false))
		valid = valid and go.self_modulate == (Color(0.70, 1.0, 0.82, 1.0) if ready else Color(1.0, 0.86, 0.42, 1.0))
		valid = valid and go.get_theme_color("font_color") == Color(0.02, 0.06, 0.035, 1.0) and go.get_theme_color("font_hover_color") == Color(0.0, 0.04, 0.02, 1.0)
	check(valid, context + " keeps complete historical legacy presentation")

func owner_state(owner: Node, simulation: Node) -> Dictionary:
	var actors := {}
	for id in owner.call("_get_displayable_fireteam_ids"):
		for unit in owner.call("_get_fireteam_units", String(id), true):
			actors[String(unit.get_path())] = {"position": unit.global_position, "health": unit.call("get_health") if unit.has_method("get_health") else null, "vital": unit.call("get_vital_state") if unit.has_method("get_vital_state") else ""}
	return {"commands": Array(simulation.get("command_queue")).duplicate(true), "effects": Array(simulation.get("effects_queue")).duplicate(true), "plans": owner.call("get_order_plans_snapshot"), "areas": owner.call("get_area_orders_snapshot"), "tick": simulation.call("get_tick"), "actors": actors}

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", message)
