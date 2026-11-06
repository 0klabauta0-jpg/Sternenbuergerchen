extends SceneTree
## Real controller/readers inside the authored mission scene. Only UI fixture
## ownership/focus is varied; no actor, simulation, combat or timer is patched.
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const NATIVE: GDScript = preload("res://scripts/ui/mission_a5_hud_layout.gd")

class ControllerProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var observe_boundaries := false
	var legacy_style_oracle := false
	var legacy_density_oracle := false
	var native_legacy_changes := 0
	var native_legacy_notices := 0
	var visible_theme_notices := 0
	var density_calls := 0
	var latest_density: Dictionary = {}
	var handoff_receipts: Array[Dictionary] = []
	var target_boundaries: Array[String] = []
	var target_boundary_facts: Array[Dictionary] = []
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func note_theme_notice() -> void:
		visible_theme_notices += 1
	func _apply_left_tactical_stack_1280_mini_card_style(card: Control, selected_fireteam: bool) -> void:
		var native_owned := bool(card.get_meta("native_a5_portrait_team_card", false))
		var before := _native_mini_fields(card)
		var notices_before := visible_theme_notices
		if legacy_style_oracle:
			# Explicit old compatibility route, solely for the unchanged-output oracle.
			card.set_meta("native_a5_portrait_team_card", false)
		super._apply_left_tactical_stack_1280_mini_card_style(card, selected_fireteam)
		if legacy_style_oracle:
			card.set_meta("native_a5_portrait_team_card", native_owned)
		if observe_boundaries and native_owned:
			if before != _native_mini_fields(card):
				native_legacy_changes += 1
			native_legacy_notices += visible_theme_notices - notices_before
	func _native_mini_fields(card: Control) -> Dictionary:
		var title := card.get_node("Margin/VBox/HeaderRow/TitleEdit") as LineEdit
		var stage := card.get_node("Margin/VBox/StageLabel") as Label
		return {"minimum": card.custom_minimum_size, "panel": card.get_theme_stylebox("panel"), "title_size": title.get_theme_font_size("font_size"), "title_uneditable": title.get_theme_color("font_uneditable_color"), "stage_size": stage.get_theme_font_size("font_size")}
	func _build_mission_hud_interaction_density_snapshot(route: Dictionary = {}, cue: Dictionary = {}, progress: Dictionary = {}) -> Dictionary:
		density_calls += 1
		var result := super._build_mission_hud_interaction_density_snapshot(route, cue, progress)
		latest_density = result.duplicate(true)
		return result
	func _build_station_scenario_debrief_handoff_cue_snapshot(route: Dictionary = {}, cue: Dictionary = {}, identity: Dictionary = {}, density: Dictionary = {}) -> Dictionary:
		var calls_before := density_calls
		var expected_input := latest_density.duplicate(true)
		var actual_input := density.duplicate(true)
		var result := super._build_station_scenario_debrief_handoff_cue_snapshot(route, cue, identity, {} if legacy_density_oracle else density)
		handoff_receipts.append({"input": actual_input, "expected": expected_input, "extra_density_calls": density_calls - calls_before, "input_unmodified": density == actual_input, "result": result.duplicate(true)})
		return result
	func _apply_compact_mission_control_layout() -> void:
		if observe_boundaries:
			var target := get_node(COMMAND_GRID_PATH + "/TargetButton") as Button
			target_boundaries.append(target.text)
			target_boundary_facts.append({"text": target.text, "native_meta": bool(get_meta("native_a5_legacy_setup_complete", false)), "native_owner": _native_a5_owns_primary_command_presentation(target), "armed": _is_target_placement_armed, "name": String(target.name)})
		super._apply_compact_mission_control_layout()
	func force_mini_refresh() -> void:
		_last_fireteam_mini_cards_runtime_signature = ""
		_refresh_fireteam_mini_cards()
	func set_target_fixture(armed: bool) -> void:
		_is_target_placement_armed = armed
	func reset_observations() -> void:
		native_legacy_changes = 0
		native_legacy_notices = 0
		density_calls = 0
		latest_density.clear()
		handoff_receipts.clear()
		target_boundaries.clear()
		target_boundary_facts.clear()

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := MISSION.instantiate()
	# Preserve all authored @export bindings before entering the tree. The real
	# inherited _ready wires runtime components and original callbacks normally.
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
	for _frame in range(12):
		await process_frame
	probe.set_process(false)
	probe.set_physics_process(false)
	var simulation := scene.get_node("SimulationRoot")
	var cards := probe.get_node(probe.FIRETEAM_MINI_CARDS_VBOX_PATH)
	_check(cards.get_child_count() > 0, "Authored mission normally initializes real fireteam cards")
	if cards.get_child_count() == 0:
		scene.queue_free()
		await process_frame
		_finish()
		return
	for card in cards.get_children():
		if not card is Control:
			continue
		(card as Control).theme_changed.connect(probe.note_theme_notice)
		(card.get_node("Margin/VBox/HeaderRow/TitleEdit") as Control).theme_changed.connect(probe.note_theme_notice)
		(card.get_node("Margin/VBox/StageLabel") as Control).theme_changed.connect(probe.note_theme_notice)
	probe.observe_boundaries = true
	var ids: PackedStringArray = probe.call("_get_displayable_fireteam_ids")
	var initial_selected: PackedStringArray = probe.get("_selected_fireteam_ids")
	for focus in ids:
		probe.set("_selected_fireteam_ids", PackedStringArray([focus]))
		probe.legacy_style_oracle = true
		probe.force_mini_refresh()
		var expected_cards := _card_tree_state(cards)
		var owner_before := _owner_state(probe, simulation)
		probe.legacy_style_oracle = false
		probe.reset_observations()
		probe.force_mini_refresh()
		_check(probe.native_legacy_changes == 0, "%s current card refresh avoids native style/minimum/font intermediate resets" % focus)
		_check(probe.native_legacy_notices == 0, "%s compatibility styling emits no redundant visible card/title/stage theme notifications" % focus)
		_check(_card_tree_state(cards) == expected_cards, "%s preserves final styles, hidden details, metadata, tooltips, portraits and actual callback identities" % focus)
		_check(_owner_state(probe, simulation) == owner_before, "%s card refresh changes no command/effect, plan, actor or simulation owner" % focus)
		probe.reset_observations()
		probe.force_mini_refresh()
		_check(probe.native_legacy_changes == 0 and probe.native_legacy_notices == 0, "%s repeated explicit refresh remains free of generic native resets" % focus)
	probe.set("_selected_fireteam_ids", initial_selected)
	# The unowned legacy route still creates its historic complete presentation.
	var first := cards.get_child(0) as Control
	first.set_meta("native_a5_portrait_team_card", false)
	probe.call("_apply_left_tactical_stack_1280_mini_card_style", first, true)
	var title := first.get_node("Margin/VBox/HeaderRow/TitleEdit") as LineEdit
	var stage := first.get_node("Margin/VBox/StageLabel") as Label
	var member := first.get_node("Margin/VBox/MemberLabel") as Label
	_check(first.custom_minimum_size.x >= probe.LEFT_TACTICAL_STACK_1280_DETAIL_CARD_MIN_SIZE.x and first.custom_minimum_size.y >= probe.LEFT_TACTICAL_STACK_1280_DETAIL_CARD_MIN_SIZE.y, "Legacy or fresh initialization retains its established minimum geometry")
	_check(title.get_theme_font_size("font_size") == maxi(16, probe.LEFT_TACTICAL_STACK_1280_TITLE_FONT_SIZE) and title.get_theme_font("font") == probe.TACTICAL_UI_THEME_SCRIPT.get_heading_font(), "Legacy or fresh initialization keeps its title font and size")
	_check(stage.get_theme_font_size("font_size") == probe.LEFT_TACTICAL_STACK_1280_STATUS_FONT_SIZE and member.get_theme_font_size("font_size") == probe.LEFT_TACTICAL_STACK_1280_DETAIL_LEAD_FONT_SIZE, "Legacy or fresh initialization retains visible and hidden compatibility fonts")
	_check(bool(first.get_meta("left_tactical_stack_1280_detail_polish_style_applied", false)) and bool(member.get_meta("left_tactical_stack_1280_detail_polish_member_strip", false)), "Legacy compatibility metadata remains available")
	probe.force_mini_refresh()
	for preview in [false, true]:
		probe.preview_mode = preview
		probe.legacy_density_oracle = true
		probe.reset_observations()
		var reference_raw: String = probe.call("_build_strategic_status_text")
		_check(not probe.handoff_receipts.is_empty() and int(probe.handoff_receipts.back().extra_density_calls) > 0, "Explicit old strategic route really rebuilds its handoff density")
		var owner_before := _owner_state(probe, simulation)
		probe.legacy_density_oracle = false
		probe.reset_observations()
		var actual_raw: String = probe.call("_build_strategic_status_text")
		_check(probe.handoff_receipts.size() == 1, "Strategic RAW assembly calls its actual handoff builder once")
		if not probe.handoff_receipts.is_empty():
			var receipt: Dictionary = probe.handoff_receipts.back()
			_check(not Dictionary(receipt.input).is_empty() and receipt.input == receipt.expected, "Handoff receives the current already-built density exactly")
			_check(int(receipt.extra_density_calls) == 0 and bool(receipt.input_unmodified), "Handoff avoids the second density build without mutating its caller input")
		_check(actual_raw == reference_raw, "Strategic RAW text remains byte-identical to the real old fallback route")
		_check(_owner_state(probe, simulation) == owner_before, "Strategic text remains read-only for plans, actors, command/effect queues and simulation")
	probe.preview_mode = false
	var target := probe.get_node(probe.COMMAND_GRID_PATH + "/TargetButton") as Button
	var callbacks := target.pressed.get_connections()
	for native in [true, false]:
		for armed in [false, true]:
			probe.set_meta("native_a5_legacy_setup_complete", native)
			probe.set_target_fixture(armed)
			probe.call("_apply_native_a5_hud_layout")
			var owner_before := _owner_state(probe, simulation)
			probe.reset_observations()
			probe.call("_update_ui", true, false)
			_check(not probe.target_boundaries.is_empty(), "Real UI update reaches its final target/layout boundary")
			if not probe.target_boundaries.is_empty():
				var expected_target: String = NATIVE.LABELS.TargetButton if native else ("ST" if armed else "ZL")
				print("R3_TARGET_BOUNDARY_FACTS " + JSON.stringify({"requested_native": native, "requested_armed": armed, "expected": expected_target, "actual": probe.target_boundaries.back(), "observations": probe.target_boundary_facts}))
				_check(probe.target_boundaries.back() == expected_target, "Native Target keeps Ziel and legacy keeps ST/ZL before final layout")
			_check(target.pressed.get_connections() == callbacks and bool(probe.get("_is_target_placement_armed")) == armed, "Target keeps original callback identity and current armed state")
			_check(_owner_state(probe, simulation) == owner_before, "Target presentation does not enqueue or execute gameplay")
	scene.queue_free()
	await process_frame
	await process_frame
	_finish()


func _card_tree_state(host: Node) -> Dictionary:
	var state: Dictionary = {}
	_capture_controls(host, host, state)
	return state


func _capture_controls(host: Node, node: Node, result: Dictionary) -> void:
	if node is Control:
		var control := node as Control
		var item: Dictionary = {"identity": control, "visible": control.visible, "minimum": control.custom_minimum_size, "tooltip": control.tooltip_text, "gui_callbacks": control.gui_input.get_connections(), "metadata": {}}
		for key in control.get_meta_list():
			item.metadata[key] = control.get_meta(key)
		if control is Label or control is LineEdit:
			item.text = control.get("text")
			item.font = control.get_theme_font("font")
			item.font_size = control.get_theme_font_size("font_size")
			item.font_color = control.get_theme_color("font_color")
		if control is LineEdit:
			item.uneditable_color = control.get_theme_color("font_uneditable_color")
		if control is TextureRect:
			item.texture = (control as TextureRect).texture
		if control is PanelContainer:
			item.panel = control.get_theme_stylebox("panel")
		if control is BaseButton:
			item.pressed_callbacks = (control as BaseButton).pressed.get_connections()
		if control.has_signal("card_pressed"):
			item.card_callbacks = control.get_signal_connection_list("card_pressed")
		result[String(host.get_path_to(node))] = item.duplicate(true)
	for child in node.get_children():
		_capture_controls(host, child, result)


func _owner_state(owner: Node, simulation: Node) -> Dictionary:
	var actors: Dictionary = {}
	for id in owner.call("_get_displayable_fireteam_ids"):
		for unit in owner.call("_get_fireteam_units", String(id), true):
			actors[String(unit.get_path())] = {"position": unit.global_position, "health": unit.call("get_health") if unit.has_method("get_health") else null, "vital": unit.call("get_vital_state") if unit.has_method("get_vital_state") else ""}
	return {"commands": Array(simulation.get("command_queue")).duplicate(true), "effects": Array(simulation.get("effects_queue")).duplicate(true), "plans": owner.call("get_order_plans_snapshot"), "areas": owner.call("get_area_orders_snapshot"), "tick": simulation.call("get_tick"), "actors": actors}


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", message)
	else:
		_failed += 1
		print("FAIL: ", message)


func _finish() -> void:
	print("R3_CONTROLLER_OWNERSHIP: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("R3_CONTROLLER_OWNERSHIP_PASS")
	quit(1 if _failed > 0 else 0)
