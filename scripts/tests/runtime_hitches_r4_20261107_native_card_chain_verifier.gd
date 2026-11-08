extends SceneTree
## Real mission and real refresh chain; only UI ownership is varied for the
## legacy presentation oracle. No actor, command, authority or clock is patched.
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

class ControllerProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var observe := false
	var legacy_oracle := false
	var boundary_changes: Array[Dictionary] = []
	var boundary_counts: Dictionary = {}
	var theme_notices := 0
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func force_mini_refresh() -> void:
		_last_fireteam_mini_cards_runtime_signature = ""
		_refresh_fireteam_mini_cards()
	func reset_observations() -> void:
		boundary_changes.clear()
		boundary_counts.clear()
		theme_notices = 0
	func note_theme_notice() -> void:
		if observe:
			theme_notices += 1
	func _before_step(card: Control) -> Dictionary:
		var owned := bool(card.get_meta("native_a5_portrait_team_card", false))
		var result: Dictionary = {"owned": owned}
		if observe and owned:
			result["fields"] = _owned_fields(card)
		if legacy_oracle and owned:
			card.set_meta("native_a5_portrait_team_card", false)
		return result
	func _after_step(card: Control, step: String, before: Dictionary) -> void:
		if legacy_oracle and bool(before.owned):
			card.set_meta("native_a5_portrait_team_card", true)
		if not observe or not bool(before.owned):
			return
		boundary_counts[step] = int(boundary_counts.get(step, 0)) + 1
		var after := _owned_fields(card)
		if before.fields != after:
			boundary_changes.append({"card": String(card.name), "step": step, "before": before.fields, "after": after})
	func _owned_fields(card: Control) -> Dictionary:
		var visibility: Dictionary = {}
		_collect_visibility(card, card, visibility)
		var stage := card.get_node("Margin/VBox/StageLabel") as Label
		var title := card.get_node("Margin/VBox/HeaderRow/TitleEdit") as LineEdit
		return {"visibility": visibility, "stage_text": stage.text, "stage_font_size": stage.get_theme_font_size("font_size"), "stage_color": stage.get_theme_color("font_color"), "title_size": title.get_theme_font_size("font_size"), "title_uneditable": title.get_theme_color("font_uneditable_color"), "panel": card.get_theme_stylebox("panel"), "minimum": card.custom_minimum_size}
	func _collect_visibility(card: Control, node: Node, result: Dictionary) -> void:
		if node is Control:
			result[String(card.get_path_to(node))] = (node as Control).visible
		for child in node.get_children():
			_collect_visibility(card, child, result)
	func _apply_fireteam_mini_status_summary(card: Control, snapshot: Dictionary) -> void:
		var before := _before_step(card)
		super._apply_fireteam_mini_status_summary(card, snapshot)
		_after_step(card, "status_summary", before)
	func _apply_fireteam_mini_suppression_indicator(card: Control, snapshot: Dictionary) -> void:
		var before := _before_step(card)
		super._apply_fireteam_mini_suppression_indicator(card, snapshot)
		_after_step(card, "suppression", before)
	func _apply_fireteam_mini_security_coverage_indicator(card: Control, id: String) -> void:
		var before := _before_step(card)
		super._apply_fireteam_mini_security_coverage_indicator(card, id)
		_after_step(card, "security", before)
	func _apply_fireteam_member_status_row(card: Control, id: String, units: Array = []) -> void:
		var before := _before_step(card)
		super._apply_fireteam_member_status_row(card, id, units)
		_after_step(card, "member_status", before)
	func _apply_fireteam_mini_readiness_footer(card: Control, snapshot: Dictionary) -> void:
		var before := _before_step(card)
		super._apply_fireteam_mini_readiness_footer(card, snapshot)
		_after_step(card, "readiness", before)
	func _apply_fireteam_mini_contact_badge(card: Control, context: Dictionary) -> void:
		var before := _before_step(card)
		super._apply_fireteam_mini_contact_badge(card, context)
		_after_step(card, "contact", before)
	func _apply_fireteam_mini_morale_indicator(card: Control, profile: Dictionary) -> void:
		var before := _before_step(card)
		super._apply_fireteam_mini_morale_indicator(card, profile)
		_after_step(card, "morale", before)
	func _apply_fireteam_mini_coordination_badge(card: Control, context: Dictionary) -> void:
		var before := _before_step(card)
		super._apply_fireteam_mini_coordination_badge(card, context)
		_after_step(card, "coordination", before)
	func _apply_fireteam_mini_stance_toggle(card: Control, id: String) -> void:
		var before := _before_step(card)
		super._apply_fireteam_mini_stance_toggle(card, id)
		_after_step(card, "stance", before)
	func _apply_fireteam_mini_card_leader_portrait(card: Control, lead) -> void:
		var before := _before_step(card)
		super._apply_fireteam_mini_card_leader_portrait(card, lead)
		_after_step(card, "leader_portrait", before)
	func _apply_native_a5_fireteam_card(card: Control, id: String, units: Array, selected: bool, inactive: bool) -> void:
		var before: Dictionary = {"owned": bool(card.get_meta("native_a5_portrait_team_card", false))}
		if observe and bool(before.owned):
			before["fields"] = _owned_fields(card)
		super._apply_native_a5_fireteam_card(card, id, units, selected, inactive)
		_after_step(card, "native_final", before)

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
	var cards := probe.get_node(probe.FIRETEAM_MINI_CARDS_VBOX_PATH)
	check(cards.get_child_count() > 0, "Authored mission initializes actual native mini cards")
	if cards.get_child_count() == 0:
		scene.queue_free()
		await process_frame
		finish()
		return
	probe.force_mini_refresh()
	await process_frame
	await process_frame
	connect_notices(cards, probe)
	_test_pair(probe, simulation, cards, "idle")
	# Flush oracle notifications before measuring a separate actual refresh.
	await process_frame
	await process_frame
	probe.reset_observations()
	probe.observe = true
	var owner_before := owner_state(probe, simulation)
	probe.force_mini_refresh()
	check(owner_state(probe, simulation) == owner_before, "Actual repeated native refresh mutates no runtime owner")
	await process_frame
	await process_frame
	probe.observe = false
	check(probe.theme_notices == 0, "Whole actual native refresh emits no redundant control theme notifications")
	check(probe.boundary_changes.is_empty(), "Whole actual native refresh has no competing native visibility/text/style boundaries")
	print("R4_NATIVE_CHAIN_NOTICES " + JSON.stringify({"theme_notices": probe.theme_notices, "boundary_counts": probe.boundary_counts, "boundary_changes": probe.boundary_changes}))
	var target := (scene.get_node("TargetMarker") as Node2D).global_position + Vector2(128.0, 0.0)
	check(probe.issue_right_click_command_for_test(target, "move", false) and probe.execute_selected_fireteam_orders(), "Interleave uses actual public Move and GO commands")
	_test_pair(probe, simulation, cards, "public_move_go")
	scene.queue_free()
	await process_frame
	await process_frame
	finish()


func _test_pair(probe: ControllerProbe, simulation: Node, cards: Node, label: String) -> void:
	# Both comparisons occur in one synchronous frame against the same actual
	# owners; the oracle changes only existing UI presentation ownership.
	var before := owner_state(probe, simulation)
	probe.observe = false
	probe.legacy_oracle = true
	probe.force_mini_refresh()
	probe.legacy_oracle = false
	var expected := card_tree_state(cards)
	check(owner_state(probe, simulation) == before, "%s legacy presentation oracle leaves all actual owners intact" % label)
	probe.reset_observations()
	probe.observe = true
	probe.force_mini_refresh()
	probe.observe = false
	check(not probe.boundary_counts.is_empty() and int(probe.boundary_counts.get("native_final", 0)) > 0, "%s observed chain reaches actual native final presenters" % label)
	check(probe.boundary_changes.is_empty(), "%s actual refresh avoids competing native visibility/text/style projections" % label)
	check(card_tree_state(cards) == expected, "%s final complete card values/metadata/rects/tooltips/resources/callbacks match real legacy oracle" % label)
	check(owner_state(probe, simulation) == before, "%s actual refresh changes no actor/tick/plan/command/effect owner" % label)
	print("R4_NATIVE_CHAIN_TRACE " + JSON.stringify({"case": label, "boundary_counts": probe.boundary_counts, "boundary_changes": probe.boundary_changes, "synthetic_component": true}))


func connect_notices(node: Node, probe: ControllerProbe) -> void:
	if node is Control:
		(node as Control).theme_changed.connect(probe.note_theme_notice)
	for child in node.get_children():
		connect_notices(child, probe)


func card_tree_state(cards: Node) -> Dictionary:
	var result: Dictionary = {}
	capture(cards, cards, result)
	return result


func capture(host: Node, node: Node, result: Dictionary) -> void:
	if node is Control:
		var item := node as Control
		var facts: Dictionary = {"identity": item, "visible": item.visible, "position": item.position, "size": item.size, "minimum": item.custom_minimum_size, "h_flags": item.size_flags_horizontal, "tooltip": item.tooltip_text, "metadata": {}, "gui_input": item.gui_input.get_connections()}
		for key in item.get_meta_list():
			facts.metadata[key] = item.get_meta(key)
		if item is Label or item is LineEdit:
			facts.text = item.get("text")
			facts.font = item.get_theme_font("font")
			facts.font_size = item.get_theme_font_size("font_size")
			facts.color = item.get_theme_color("font_color")
		if item is LineEdit:
			facts.uneditable_color = item.get_theme_color("font_uneditable_color")
			facts.normal = item.get_theme_stylebox("normal")
			facts.read_only = item.get_theme_stylebox("read_only")
			facts.submit_callbacks = (item as LineEdit).text_submitted.get_connections()
			facts.blur_callbacks = (item as LineEdit).focus_exited.get_connections()
		if item is PanelContainer:
			facts.panel = item.get_theme_stylebox("panel")
		if item is TextureRect:
			facts.texture = (item as TextureRect).texture
		if item is BaseButton:
			facts.pressed_callbacks = (item as BaseButton).pressed.get_connections()
		if item.has_signal("card_pressed"):
			facts.card_callbacks = item.get_signal_connection_list("card_pressed")
		result[String(host.get_path_to(item))] = facts.duplicate(true)
	for child in node.get_children():
		capture(host, child, result)


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
	print("R4_NATIVE_CARD_CHAIN: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_NATIVE_CARD_CHAIN_PASS")
	quit(1 if failed > 0 else 0)
