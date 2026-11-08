extends SceneTree
## Actual craft/presenter chain over the authored mission Controls. The only
## fixture is a pure UI interaction snapshot; no physical door, actor, command,
## availability owner, authority rule or clock is patched or exercised.
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

class ControllerProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture: Dictionary = {}
	var observe := false
	var legacy_oracle := false
	var boundary_counts: Dictionary = {}
	var changes: Array[Dictionary] = []
	var theme_notices := 0
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func get_primary_mission_interaction_button_snapshot() -> Dictionary:
		return super.get_primary_mission_interaction_button_snapshot() if fixture.is_empty() else fixture.duplicate(true)
	func note_theme_notice() -> void:
		if observe:
			theme_notices += 1
	func reset_observations() -> void:
		boundary_counts.clear()
		changes.clear()
		theme_notices = 0
	func door() -> Button:
		return get_node_or_null(DOOR_BREACH_BUTTON_PATH) as Button
	func style(button: Button) -> Dictionary:
		if button == null:
			return {}
		var styles: Dictionary = {}
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			styles[state] = button.get_theme_stylebox(state)
		var colors: Dictionary = {}
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
			colors[key] = button.get_theme_color(key)
		return {"font": button.get_theme_font("font"), "font_size": button.get_theme_font_size("font_size"), "self_modulate": button.self_modulate, "styles": styles, "colors": colors}
	func _before_step(button: Button) -> Dictionary:
		var native := bool(get_meta("native_a5_legacy_setup_complete", false))
		var before: Dictionary = {"native": native}
		if observe and native:
			before["style"] = style(button)
		if legacy_oracle and native:
			set_meta("native_a5_legacy_setup_complete", false)
		return before
	func _after_step(button: Button, step: String, before: Dictionary) -> void:
		if legacy_oracle and bool(before.native):
			set_meta("native_a5_legacy_setup_complete", true)
		if not observe or not bool(before.native):
			return
		boundary_counts[step] = int(boundary_counts.get(step, 0)) + 1
		var after := style(button)
		if before.style != after:
			changes.append({"step": step, "before": before.style, "after": after})
	func _apply_dynamic_button_base_style(button: Button, active: bool) -> void:
		if button == null or String(button.name) != "DoorBreachButton":
			super._apply_dynamic_button_base_style(button, active)
			return
		var before := _before_step(button)
		super._apply_dynamic_button_base_style(button, active)
		_after_step(button, "dynamic_base", before)
	func _apply_primary_mission_interaction_semantics(snapshot: Dictionary = {}) -> void:
		var button := door()
		var before := _before_step(button)
		super._apply_primary_mission_interaction_semantics(snapshot)
		_after_step(button, "interaction_semantics", before)
	func _apply_door_authority_button_affordance(button: Button, severity: String) -> void:
		var before := _before_step(button)
		super._apply_door_authority_button_affordance(button, severity)
		_after_step(button, "door_affordance", before)
	func _apply_native_a5_hud_layout() -> void:
		var button := door()
		var before: Dictionary = {"native": bool(get_meta("native_a5_legacy_setup_complete", false))}
		if observe and bool(before.native):
			before["style"] = style(button)
		super._apply_native_a5_hud_layout()
		_after_step(button, "native_layout", before)

var passed := 0
var failed := 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := MISSION.instantiate()
	var original := scene.get_node("TacticalController")
	var probe := ControllerProbe.new()
	for property in original.get_property_list():
		var usage := int(property.usage)
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (usage & PROPERTY_USAGE_EDITOR) != 0:
			probe.set(String(property.name), original.get(String(property.name)))
	scene.remove_child(original)
	original.free()
	probe.name = "TacticalController"
	scene.add_child(probe)
	root.add_child(scene)
	for _frame in range(16):
		await process_frame
	var simulation := scene.get_node("SimulationRoot")
	var button := probe.door()
	check(button != null and bool(probe.get_meta("native_a5_legacy_setup_complete", false)), "Real mission normally initializes the native context button")
	if button == null:
		scene.queue_free()
		await process_frame
		finish()
		return
	var callbacks := button.pressed.get_connections()
	button.theme_changed.connect(probe.note_theme_notice)
	for enabled in [false, true]:
		probe.fixture = interaction_fixture(enabled)
		var source_before := probe.fixture.duplicate(true)
		probe.call("_apply_primary_mission_interaction_semantics", probe.fixture)
		button.set_meta("door_authority_ui_severity", "action" if enabled else "warning")
		probe.call("_apply_native_a5_hud_layout")
		await process_frame
		await process_frame
		var owner_before := owner_state(probe, simulation)
		probe.legacy_oracle = true
		probe.call("_refresh_runtime_mission_hud_surfaces", true)
		probe.legacy_oracle = false
		var expected := full_button(probe, button)
		check(owner_state(probe, simulation) == owner_before, "enabled=%s explicit old presentation path leaves all owners unchanged" % enabled)
		probe.reset_observations()
		probe.observe = true
		probe.call("_refresh_runtime_mission_hud_surfaces", true)
		probe.observe = false
		check(int(probe.boundary_counts.get("dynamic_base", 0)) == 1 and int(probe.boundary_counts.get("interaction_semantics", 0)) == 1 and int(probe.boundary_counts.get("native_layout", 0)) >= 2, "enabled=%s trace reaches actual dynamic, semantics and repeated native presenters" % enabled)
		check(probe.changes.is_empty(), "enabled=%s actual forced craft refresh preserves native style at every competing boundary" % enabled)
		check(full_button(probe, button) == expected, "enabled=%s complete final styles/rects/text/gates/tooltips/metadata/callbacks match actual old path" % enabled)
		check(button.visible and button.disabled == not enabled and String(button.get_meta("mission_interaction_type", "")) == "door" and bool(button.get_meta("mission_interaction_requires_go", false)) == enabled, "enabled=%s fresh source immediately preserves exact context visibility and command gates" % enabled)
		check(button.get_theme_font_size("font_size") == 12 and button.pressed.get_connections() == callbacks, "enabled=%s native context keeps final Font12 and original callbacks" % enabled)
		check(probe.fixture == source_before and owner_state(probe, simulation) == owner_before, "enabled=%s projection mutates neither source nor runtime owner" % enabled)
		print("R4_NATIVE_CRAFT_TRACE " + JSON.stringify({"enabled": enabled, "boundaries": probe.boundary_counts, "changes": probe.changes, "synthetic_component": true}))
		# Flush old-path notifications before a separate true repeated refresh.
		await process_frame
		await process_frame
		probe.reset_observations()
		probe.observe = true
		probe.call("_refresh_runtime_mission_hud_surfaces", true)
		await process_frame
		await process_frame
		probe.observe = false
		check(probe.theme_notices == 0 and probe.changes.is_empty(), "enabled=%s repeated actual craft pass emits no redundant context theme/style changes" % enabled)
		print("R4_NATIVE_CRAFT_NOTICES " + JSON.stringify({"enabled": enabled, "theme_notices": probe.theme_notices, "changes": probe.changes}))
		probe.set_meta("native_a5_legacy_setup_complete", false)
		probe.call("_apply_primary_mission_interaction_semantics", probe.fixture)
		check(button.get_theme_font_size("font_size") == 13 and button.disabled == not enabled and button.pressed.get_connections() == callbacks, "enabled=%s unowned direct semantics retains full generic legacy presentation" % enabled)
		probe.set_meta("native_a5_legacy_setup_complete", true)
		probe.call("_apply_native_a5_hud_layout")
	scene.queue_free()
	await process_frame
	await process_frame
	finish()


func interaction_fixture(enabled: bool) -> Dictionary:
	return {"schema": "sternenbuergerchen.mission_primary_interaction_button.v1", "visible": true, "disabled": not enabled, "text": "Sturm->GO" if enabled else "Sturm", "tooltip_text": "Fixture current pure interaction projection", "interaction_id": "fixture_door_context", "interaction_type": "door", "required_order": "breach_door", "status": "usable" if enabled else "blocked", "display_token": "DOOR", "help_id": "mission.command.breach_door", "shortcut": "B", "requires_go": enabled, "disabled_reason": "" if enabled else "fixture blocked", "read_only": true, "ui_sets_gameplay_truth": false}


func full_button(probe: ControllerProbe, button: Button) -> Dictionary:
	var metadata: Dictionary = {}
	for key in button.get_meta_list():
		metadata[key] = button.get_meta(key)
	return {"identity": button, "style": probe.style(button), "text": button.text, "disabled": button.disabled, "visible": button.visible, "rect": button.get_global_rect(), "minimum": button.custom_minimum_size, "tooltip": button.tooltip_text, "metadata": metadata, "pressed": button.pressed.get_connections(), "gui_input": button.gui_input.get_connections(), "icon": button.icon, "icon_alignment": button.icon_alignment, "expand_icon": button.expand_icon, "clip_text": button.clip_text}


func owner_state(owner: Node, simulation: Node) -> Dictionary:
	var actors: Dictionary = {}
	for id in owner.call("_get_displayable_fireteam_ids"):
		for unit in owner.call("_get_fireteam_units", String(id), true):
			actors[String(unit.get_path())] = {"position": unit.global_position, "health": unit.call("get_health") if unit.has_method("get_health") else null, "vital": unit.call("get_vital_state") if unit.has_method("get_vital_state") else ""}
	return {"commands": Array(simulation.get("command_queue")).duplicate(true), "effects": Array(simulation.get("effects_queue")).duplicate(true), "plans": owner.call("get_order_plans_snapshot"), "areas": owner.call("get_area_orders_snapshot"), "tick": simulation.call("get_tick"), "actors": actors}


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		print("FAIL: " + label)


func finish() -> void:
	print("R4_NATIVE_CRAFT_CHAIN: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_NATIVE_CRAFT_CHAIN_PASS")
	quit(1 if failed > 0 else 0)
