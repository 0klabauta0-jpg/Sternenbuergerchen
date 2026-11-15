extends SceneTree
## Real native UI/owner callbacks on the existing mission fixture; no flight,
## actor-position, timer, health or simulation-state patch is used here.
const SCENE = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TEAM := "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel"
const MINI := "TacticalUI/FireteamMiniPanel"
var passed := 0
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failures.append(message)


func _run() -> void:
	var require_rendered := OS.get_cmdline_user_args().has("--require-rendered-ui")
	if require_rendered:
		_check(DisplayServer.get_name() != "headless", "rendered UI evidence requires an actual non-headless display server")
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		await _check_scene(size)
		await _check_transport_modal_actions(size)
		await _check_transport_details_scroll(size)
	for message in failures:
		push_error(message)
	print("A5 reference groups: %d passed, %d failed" % [passed, failures.size()])
	if failures.is_empty():
		print("A5_REFERENCE_GROUPS_ALL_PASS")
		if require_rendered:
			print("A5_REFERENCE_GROUPS_RENDERED_ALL_PASS")
	quit(0 if failures.is_empty() else 1)


func _check_scene(size: Vector2i) -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = size
	var scene := SCENE.instantiate()
	root.add_child(scene)
	for frame in range(24):
		await process_frame
	var prefix := "%s: " % size
	var controller := scene.get_node("TacticalController")
	var band := scene.get_node("TacticalUI/BottomDock") as Control
	var mini := scene.get_node(MINI) as Control
	var cards := scene.get_node(MINI + "/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	_check(cards.get_child_count() > 0, prefix + "real fixture exposes its actual fireteams")
	_check(mini.get_global_rect().position.x <= 24 and mini.get_global_rect().end.y <= band.get_global_rect().position.y and mini.get_global_rect().position.y > size.y * 0.25, prefix + "portrait team stack is left and near the lower band")
	_check(not (scene.get_node(TEAM + "/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll") as Control).is_visible_in_tree(), prefix + "no duplicate separate NPC strip remains on the map")
	_check((scene.get_node(TEAM) as Control).size.x <= 392, prefix + "team parameter group is narrower than the previous 512px block")
	var opened_portrait := false
	for card in cards.get_children():
		if not card is Control:
			continue
		_check(bool(card.get_meta("native_a5_portrait_team_card", false)), prefix + "existing team card uses the A5 presentation")
		var strip := card.get_node("Margin/VBox/FireteamMemberPortraitStrip") as Control
		var count := card.get_node("Margin/VBox/HeaderRow/A5MemberCount") as Label
		var status := card.get_node("Margin/VBox/StageLabel") as Label
		_check(strip.visible and strip.get_child_count() > 0 and strip.custom_minimum_size.y >= 64, prefix + "actual member portraits dominate their team card")
		_check(count.visible and count.text.contains("/") and count.get_theme_font_size("font_size") >= 16, prefix + "real team occupancy has a readable header")
		_check(status.visible and not status.text.contains("|") and status.get_theme_font_size("font_size") >= 13, prefix + "one player-facing status replaces the diagnostic rows")
		if not opened_portrait and strip.get_child_count() > 0:
			var portrait := strip.get_child(0) as Control
			var unit_id := String(portrait.get_meta("mission_member_unit_id", ""))
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			click.double_click = true
			portrait.gui_input.emit(click)
			var overlay := scene.get_node("TacticalUI/CharacterOverlay") as Control
			_check(not unit_id.is_empty() and overlay.visible and String(controller.get("_character_overlay_unit_id")) == unit_id, prefix + "portrait double-click opens that original person's existing character sheet")
			controller.call("_close_character_overlay")
			opened_portrait = true
	var transport := scene.get_node("TacticalUI/MissionDropshipPanel") as Control
	_check(transport.visible and transport.size.x <= 304 and transport.get_global_rect().position.y <= 24, prefix + "dropship primary is a compact upper-right card")
	var state := transport.get_node("CompactCard/Contents/Header/Identity/A5TransportState") as Label
	_check(state.is_visible_in_tree() and not state.text.is_empty() and state.get_theme_font_size("font_size") >= 14, prefix + "primary transport state remains readable")
	_check_compact_readout(transport, prefix)
	for action in ["set_lz", "drop"]:
		var button := transport.get_node("CompactCard/Contents/Actions/" + action) as Button
		_check(not button.get_signal_connection_list("pressed").is_empty() and (not button.visible or (button.size.y >= 28 and transport.get_global_rect().encloses(button.get_global_rect()))), prefix + action + " retains a real callback and an input-sized primary slot")
	var owner_before := JSON.stringify(controller.get("_mission_drop_cards"))
	var selected_before := String(controller.get("_mission_drop_craft_id"))
	var details := transport.get_node("CompactCard/Contents/Header/DetailsButton") as Button
	details.pressed.emit()
	var popup := scene.get_node("TacticalUI/A5DropshipDetailsPopup") as PopupPanel
	var close := popup.get_node("Contents/CloseButton") as Button
	_check(popup.visible and not paused, prefix + "native transport details open without pausing")
	_check(Rect2(Vector2.ZERO, Vector2(size)).encloses(Rect2(Vector2(popup.position), Vector2(popup.size))), prefix + "details popup fits the actual viewport")
	_check(popup.get_node_or_null("Contents/Scroll/A5DropshipFullPanel") != null, prefix + "full existing transport controls have a native scroll owner")
	for refresh in range(3):
		controller.call("_refresh_mission_dropship_panel")
	_check(popup.visible and popup.get_node("Contents/CloseButton") == close, prefix + "transport refresh retains the modal and its stable close control")
	_check(JSON.stringify(controller.get("_mission_drop_cards")) == owner_before and String(controller.get("_mission_drop_craft_id")) == selected_before, prefix + "opening and refreshing details never invents transport state or selection")
	controller.call("set_tactical_ui_visible", false)
	_check(not popup.visible and not transport.is_visible_in_tree(), prefix + "leaving tactical UI closes transport details and primary")
	controller.call("set_tactical_ui_visible", true)
	controller.call("_refresh_mission_dropship_panel")
	var log_header := scene.get_node("TacticalUI/TacticalEventLogPanel/EventLogMargin/EventLogVBox/EventLogHeader/EventLogHeaderLabel") as Label
	var log_filter := scene.get_node("TacticalUI/TacticalEventLogPanel/EventLogMargin/EventLogVBox/EventLogHeader/EventLogSelectedFilterButton") as CheckButton
	_check(log_header.text == "Protokoll", prefix + "protocol uses a plain player heading without a technical section ID")
	_check(not log_filter.get_signal_connection_list("toggled").is_empty(), prefix + "protocol retains its real selection filter")
	# Display-only long-event fixture. It does not enter the owner's event log.
	var log_panel := scene.get_node("TacticalUI/TacticalEventLogPanel")
	log_panel.call("set_feedback_snapshot", {"tactical_event_log": [{"event_id": "a5_long_text", "created_msec": 1200, "fireteam_id": "qa", "severity": "info", "short_text": "Lange vollständige Ereignisrückmeldung mit erhaltenem Kontext. ".repeat(7)}]})
	var event_label := log_panel.find_child("EventTextLabel", true, false) as Label
	var event_scroll := log_panel.find_child("EventLogScroll", true, false) as ScrollContainer
	_check(event_label != null and event_label.max_lines_visible == 2 and event_label.mouse_filter == Control.MOUSE_FILTER_PASS and event_label.tooltip_text.ends_with(event_label.text), prefix + "two-line events expose their complete text in a reachable tooltip")
	_check(event_scroll != null and event_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, prefix + "long-event tooltip keeps native protocol scrolling")
	var ids: PackedStringArray = controller.call("_get_available_fireteam_ids")
	if not ids.is_empty():
		controller.call("_set_selected_fireteams", PackedStringArray([ids[0]]), false)
		var refs: Array = controller.call("_create_waypoints_for_selected_fireteams", controller.call("_get_target_position"))
		controller.call("_refresh_button_state")
		var go := scene.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton") as Button
		_check(not refs.is_empty() and not go.disabled, prefix + "existing real planner enables GO for the post-refresh regression")
		if not refs.is_empty() and not go.disabled:
			go.pressed.emit()
		for refresh in range(3):
			controller.call("_update_ui", false, false)
			await process_frame
		_check(not (scene.get_node(TEAM + "/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll") as Control).is_visible_in_tree(), prefix + "GO and light refreshes do not resurrect the separate NPC strip")
		var portraits_remain := cards.get_child_count() > 0
		for card in cards.get_children():
			var strip := card.get_node_or_null("Margin/VBox/FireteamMemberPortraitStrip") as Control
			portraits_remain = portraits_remain and strip != null and strip.visible and strip.get_child_count() > 0
		_check(portraits_remain, prefix + "GO/status refresh preserves the actual left-hand member portraits")
	scene.queue_free()
	for frame in range(4):
		await process_frame


func _check_transport_modal_actions(size: Vector2i) -> void:
	# Explicit UI hydration fixture through the same public planning API used by
	# MetaFlow. No flight/actor/timer is advanced or manufactured by this fixture.
	root.size = size
	var scene := SCENE.instantiate()
	root.add_child(scene)
	for frame in range(8):
		await process_frame
	var controller := scene.get_node("TacticalController")
	var planning: Dictionary = Dictionary(controller.call("get_planning_state"))
	var craft_id := "a5_ui_lz_1"
	planning["mission_drop_craft_id"] = craft_id
	planning["mission_drop_state"] = "to_mission"
	planning["mission_drop_cards"] = [{"craft_id": craft_id, "craft_type": "dropship", "display_name": "A5 UI fixture", "state": "to_mission", "eta_seconds": 30, "progress": 0, "passenger_count": 0, "embarked_unit_ids": [], "has_lz_position": false}]
	controller.call("set_planning_state", planning)
	controller.call("_open_native_dropship_details")
	var popup := scene.get_node("TacticalUI/A5DropshipDetailsPopup") as PopupPanel
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	_check(popup.visible and not bool(controller.get("_is_lz_placement_armed")), "%s: rejected in-transit LZ action leaves details open and never pretends arming succeeded" % size)
	popup.hide()
	# Native Popup/Window hide and focus restoration settle at the UI boundary.
	# A user cannot close and re-open through two separate pointer events before
	# that boundary; keep the public hydration fixture equally sequenced.
	await process_frame
	planning["mission_drop_state"] = "waiting"
	planning["mission_drop_cards"][0]["state"] = "waiting"
	planning["mission_drop_cards"][0]["eta_seconds"] = 0
	controller.call("set_planning_state", planning)
	await process_frame
	controller.call("_open_native_dropship_details")
	for frame in range(4):
		await process_frame
	var transport := scene.get_node("TacticalUI/MissionDropshipPanel") as Control
	_check_compact_readout(transport, "%s: waiting caption: " % size)
	_check_detail_card_layout(popup, "%s: single craft: " % size)
	var full := popup.get_node("Contents/Scroll/A5DropshipFullPanel") as Control
	_check(float(popup.size.y) - full.get_global_rect().end.y <= 24, "%s: single-craft popup ends near its actual detail content instead of leaving a fixed empty lower half" % size)
	var title := transport.get_node("CompactCard/Contents/Header/Identity/A5TransportHeading") as Label
	_check(title.text.contains("Cutlass") and title.text.ends_with("A5 UI fixture"), "%s: the known mission transport role retains its Cutlass class and the original player caption" % size)
	var two_lines := title.get_visible_line_count() == 2 and title.custom_minimum_size.y >= 2 * ceilf(title.get_theme_font("font").get_height(title.get_theme_font_size("font_size")))
	_check(two_lines, "%s: the real long class/name caption retains two drawable font lines" % size)
	if not two_lines:
		print("A5_CAPTION_DIAGNOSTIC ", JSON.stringify({"viewport": str(size), "text": title.text, "rect": str(title.get_global_rect()), "minimum": str(title.get_combined_minimum_size()), "custom_minimum": str(title.custom_minimum_size), "font_size": title.get_theme_font_size("font_size"), "text_width": title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x, "line_count": title.get_line_count(), "visible_line_count": title.get_visible_line_count(), "metric_signature": str(title.get_meta("native_a5_readout_metrics", [])), "source_cards": controller.call("_get_mission_dropship_card_entries")}))
	var lz: Button = null
	for child in popup.find_children("*", "Button", true, false):
		if String(child.get_meta("mission_dropship_craft_id", "")) == craft_id and String(child.get_meta("mission_dropship_card_command", "")) == "set_lz":
			lz = child as Button
			break
	_check(lz != null and not lz.disabled and lz.is_visible_in_tree(), "%s: waiting craft exposes its actual enabled details LZ action" % size)
	if lz == null or lz.disabled or not lz.is_visible_in_tree():
		_print_modal_facts("waiting_lz", controller, popup, lz)
	if lz != null and not lz.disabled:
		lz.grab_focus()
		var focus_preserved := true
		var tooltips_preserved := true
		for refresh in range(3):
			controller.call("_update_ui", false, false)
			controller.call("_refresh_mission_dropship_panel")
			await process_frame
			var focused := popup.gui_get_focus_owner() as Button
			focus_preserved = focus_preserved and focused != null and String(focused.get_meta("mission_dropship_craft_id", "")) == craft_id and String(focused.get_meta("mission_dropship_card_command", "")) == "set_lz" and not focused.get_signal_connection_list("pressed").is_empty()
			tooltips_preserved = tooltips_preserved and _details_tooltips_reachable(popup)
		_check(focus_preserved and popup.visible, "%s: three real refreshes preserve keyboard focus on the same craft/action and its callback" % size)
		_check(tooltips_preserved, "%s: three real refreshes retain reachable full-text label tooltips without blocking scroll propagation" % size)
		if not focus_preserved or not popup.visible:
			_print_modal_facts("refreshed_focus", controller, popup, popup.gui_get_focus_owner())
		var focused := popup.gui_get_focus_owner() as Button
		if focused != null:
			focused.pressed.emit()
		_check(not popup.visible and bool(controller.get("_is_lz_placement_armed")) and String(controller.get("_lz_placement_craft_id")) == craft_id, "%s: enabled details LZ action arms the real placement owner and releases the modal map blocker" % size)
	scene.queue_free()
	for frame in range(4):
		await process_frame


func _check_transport_details_scroll(size: Vector2i) -> void:
	# Multiple UI-source cards exercise native overflow only. No actor, flight,
	# position, health, or timing state is changed to manufacture a gameplay pass.
	root.size = size
	var scene := SCENE.instantiate()
	root.add_child(scene)
	for frame in range(8):
		await process_frame
	var controller := scene.get_node("TacticalController")
	var planning: Dictionary = Dictionary(controller.call("get_planning_state"))
	var entries: Array = []
	for index in range(5):
		entries.append({"craft_id": "a5_scroll_%d" % index, "display_name": "Transport %d" % index, "state": "waiting", "embarked_unit_ids": [], "has_lz_position": false})
	planning["mission_drop_craft_id"] = "a5_scroll_0"
	planning["mission_drop_cards"] = entries
	planning["mission_drop_state"] = "waiting"
	controller.call("set_planning_state", planning)
	controller.call("_open_native_dropship_details")
	for frame in range(6):
		await process_frame
	var popup := scene.get_node("TacticalUI/A5DropshipDetailsPopup") as PopupPanel
	var scroll := popup.get_node("Contents/Scroll") as ScrollContainer
	var full := scroll.get_node("A5DropshipFullPanel") as Control
	var prefix := "%s: multiple crafts: " % size
	_check(full.get_child_count() == 5, prefix + "every actual source craft remains available in full transport details")
	_check_detail_card_layout(popup, prefix)
	var fits_viewport := Rect2(Vector2.ZERO, Vector2(size)).encloses(Rect2(Vector2(popup.position), Vector2(popup.size))) and popup.size.y <= size.y - 48
	_check(fits_viewport, prefix + "large detail content remains inside the viewport with native overflow")
	if not fits_viewport:
		print("A5_DETAILS_BOUNDS_DIAGNOSTIC ", JSON.stringify({"viewport": str(size), "owner_viewport": str(controller.get_viewport().get_visible_rect()), "popup_position": str(popup.position), "popup_size": str(popup.size), "popup_min_size": str(popup.min_size), "contents_minimum": str((popup.get_node("Contents") as Control).get_combined_minimum_size()), "scroll_rect": str(scroll.get_global_rect()), "scroll_minimum": str(scroll.get_combined_minimum_size()), "full_rect": str(full.get_global_rect()), "full_minimum": str(full.get_combined_minimum_size()), "scroll_value": scroll.scroll_vertical, "scroll_max": scroll.get_v_scroll_bar().max_value, "scroll_page": scroll.get_v_scroll_bar().page}))
	_check(full.size.y > scroll.size.y and scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, prefix + "multiple readable craft cards expose a real native vertical scroll range")
	scroll.scroll_vertical = 96
	await process_frame
	var previous := scroll.scroll_vertical
	_check(previous > 0, prefix + "fixture actually scrolls away from the first detail card")
	var preserved := true
	for refresh in range(3):
		controller.call("_update_ui", false, false)
		controller.call("_refresh_mission_dropship_panel")
		await process_frame
		preserved = preserved and scroll.scroll_vertical == previous
	_check(preserved and popup.visible, prefix + "three real snapshot refreshes preserve the actual scroll position without reopening the modal")
	controller.call("set_tactical_ui_visible", false)
	_check(not popup.visible, prefix + "leaving the mission closes a scrolled detail modal")
	scene.queue_free()
	for frame in range(4):
		await process_frame


func _check_detail_card_layout(popup: PopupPanel, prefix: String) -> void:
	var scroll := popup.get_node("Contents/Scroll") as ScrollContainer
	var full := scroll.get_node("A5DropshipFullPanel") as Control
	var filled := is_equal_approx(full.position.x, 0.0)
	for child in full.get_children():
		var card := child as Control
		filled = filled and card != null and absf(card.position.x) <= 1 and absf(card.size.x - full.size.x) <= 1
	_check(filled and full.get_child_count() > 0, prefix + "existing craft cards fill the native scroll width without a legacy right-aligned gutter")
	var readable := true
	for child in full.find_children("*", "Label", true, false):
		var label := child as Label
		readable = readable and label.get_theme_font_size("font_size") >= 12
	var commands_sized := true
	for child in full.find_children("*", "Button", true, false):
		var button := child as Button
		readable = readable and button.get_theme_font_size("font_size") >= 12
		if bool(button.get_meta("mission_dropship_card_command_button", false)):
			commands_sized = commands_sized and button.size.y >= 28 and not button.get_signal_connection_list("pressed").is_empty()
	_check(readable, prefix + "pilot, passenger, status and action captions retain at least 12px inside details only")
	_check(commands_sized, prefix + "full detail actions retain their real callbacks and native input height")
	_check(_details_tooltips_reachable(popup), prefix + "nonempty detail labels expose full-text tooltips through native mouse input")


func _details_tooltips_reachable(popup: PopupPanel) -> bool:
	var full := popup.get_node("Contents/Scroll/A5DropshipFullPanel") as Control
	var checked := 0
	for child in full.find_children("*", "Label", true, false):
		var label := child as Label
		if not label.visible or label.text.is_empty():
			continue
		checked += 1
		if label.tooltip_text.is_empty() or not label.tooltip_text.contains(label.text) or label.mouse_filter != Control.MOUSE_FILTER_PASS:
			return false
	return checked > 0


func _check_compact_readout(transport: Control, prefix: String) -> void:
	var header := transport.get_node("CompactCard/Contents/Header") as Control
	for name in ["A5TransportHeading", "A5TransportState"]:
		var label := header.get_node("Identity/" + name) as Label
		var font_height := ceilf(label.get_theme_font("font").get_height(label.get_theme_font_size("font_size")))
		_check(label.is_visible_in_tree() and label.get_visible_line_count() > 0 and label.custom_minimum_size.y >= font_height and header.get_global_rect().encloses(label.get_global_rect()), prefix + name + " has actual drawable font height inside the compact header")


func _print_modal_facts(stage: String, controller: Node, popup: PopupPanel, control: Control) -> void:
	var ancestors: Array = []
	var node: Node = control
	while node != null and ancestors.size() < 12:
		var fact := {"name": String(node.name), "class": node.get_class()}
		if node is CanvasItem:
			fact["visible"] = (node as CanvasItem).visible
			fact["in_tree_visible"] = (node as CanvasItem).is_visible_in_tree()
		if node is Control:
			fact["rect"] = str((node as Control).get_global_rect())
		ancestors.append(fact)
		node = node.get_parent()
	print("A5_MODAL_DIAGNOSTIC ", JSON.stringify({"stage": stage, "popup_visible": popup.visible, "tactical_ui_visible": controller.get("_tactical_ui_visible"), "source_cards": controller.call("_get_mission_dropship_card_entries"), "focus_path": str(popup.gui_get_focus_owner().get_path()) if popup.gui_get_focus_owner() != null else "none", "ancestors": ancestors}))
