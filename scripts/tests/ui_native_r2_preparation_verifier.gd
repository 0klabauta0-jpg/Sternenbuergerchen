extends SceneTree

const HOMEBASE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const FOB: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const GENERATOR: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const HOME_WORK := "Panel/Margin/VBox/ContentRow/"
const FOB_LOADOUT := "Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/"
const HOME_BRIEF := "Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for viewport_size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		await _test_homebase(viewport_size)
		await _test_fob(viewport_size)
	print("RESULTS: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("PASS: native R2 preparation layout and callbacks")
	quit(1 if _failed > 0 else 0)


func _test_homebase(viewport_size: Vector2i) -> void:
	var viewport := _make_viewport(viewport_size)
	var screen := HOMEBASE.instantiate() as Control
	viewport.add_child(screen)
	screen.show()
	var units := _fixture_units()
	var first_id := String(Dictionary(units[0]).unit_id)
	screen.call("setup_roster", units)
	await _wait_frames(6)
	_check_windows(screen, viewport_size, {
		"topbar": "DropLightTopbar", "mission_brief": "Panel/Margin/VBox/MissionPanel",
		"roster": HOME_WORK + "RosterPanel", "fireteams": HOME_WORK + "HomebaseFireteamPanel",
		"flightdeck": HOME_WORK + "AircraftPanel",
	}, "Homebase")
	var brief := screen.get_node("Panel/Margin/VBox/MissionPanel") as Control
	_check(brief.size.y <= 140, "%s Homebase briefing leaves height for preparation" % viewport_size)
	for panel_name in ["RosterPanel", "HomebaseFireteamPanel", "AircraftPanel"]:
		var panel := screen.get_node(HOME_WORK + panel_name) as Control
		if panel_name == "RosterPanel":
			_check(panel.is_visible_in_tree() and panel.size.y >= viewport_size.y - 240, "%s Homebase roster retains full-height personnel work" % viewport_size)
		elif panel_name == "AircraftPanel":
			_check(panel.is_visible_in_tree() and panel.size.y <= 192, "%s empty Homebase transport remains a compact actionable area" % viewport_size)
		else:
			_check(panel.is_visible_in_tree() and panel.size.y >= 128 and panel.size.y <= 256, "%s empty Homebase team retains its native drop target without a full empty column" % viewport_size)
	var briefing_scroll := screen.get_node("Panel/Margin/VBox/MissionPanel/MissionMargin") as ScrollContainer
	_check(briefing_scroll != null and briefing_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "%s complete briefing has a bounded native scroll" % viewport_size)
	var roster_scroll := screen.get_node(HOME_WORK + "RosterPanel/RosterMargin/RosterVBox/RosterScroll") as ScrollContainer
	var first_roster_card := _find_unit_card(roster_scroll, first_id)
	_check(first_roster_card != null and first_roster_card.get_global_rect().size.x <= roster_scroll.size.x and first_roster_card.get_global_rect().end.x <= roster_scroll.get_global_rect().end.x + 1, "%s compact Homebase roster card fits without clipping its right frame" % viewport_size)
	var toggle := screen.get_node(HOME_BRIEF + "HeaderRow/R2BriefingDetailsButton") as Button
	_check(_reachable(toggle, viewport_size), "%s briefing details button is initially reachable" % viewport_size)
	var team_before: PackedStringArray = screen.call("get_selected_unit_ids")
	toggle.pressed.emit()
	await _wait_frames(4)
	_check(bool(Dictionary(screen.call("get_native_r2_layout_snapshot")).briefing_details_open), "%s briefing toggle opens focused details view" % viewport_size)
	_check(_inside(brief.get_global_rect(), Rect2(Vector2.ZERO, Vector2(viewport_size))), "%s full briefing frame stays inside viewport" % viewport_size)
	_check(not (screen.get_node(HOME_WORK + "RosterPanel") as Control).visible, "%s focused briefing temporarily uses preparation area" % viewport_size)
	briefing_scroll.scroll_vertical = int(briefing_scroll.get_v_scroll_bar().max_value)
	await _wait_frames(3)
	var briefing_content := screen.get_node(HOME_BRIEF.trim_suffix("/")) as Control
	_check(briefing_scroll.scroll_vertical > 0 or briefing_content.get_global_rect().end.y <= briefing_scroll.get_global_rect().end.y + 1, "%s full briefing can reach its final content" % viewport_size)
	briefing_scroll.scroll_vertical = 0
	await _wait_frames(2)
	toggle.pressed.emit()
	await _wait_frames(4)
	_check(team_before == PackedStringArray(screen.call("get_selected_unit_ids")), "%s briefing navigation does not mutate selected team" % viewport_size)
	_check((screen.get_node(HOME_WORK + "RosterPanel") as Control).is_visible_in_tree(), "%s return restores roster work area" % viewport_size)

	# Exercise existing selection and assignment owners rather than set fields.
	screen.call("_on_compact_card_pressed", first_id, null, "roster")
	var fireteam_list := screen.get_node(HOME_WORK + "HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList")
	var assign_target := fireteam_list.get_child(0) as Control
	_check(_reachable(assign_target, viewport_size) and assign_target.has_signal("unit_dropped"), "%s Homebase active fireteam drop target stays reachable" % viewport_size)
	var drag_data := {"type": "homebase_unit_card", "unit_id": first_id}
	_check(bool(assign_target.call("_can_drop_data", Vector2.ZERO, drag_data)), "%s Homebase fireteam accepts actual operator drag contract" % viewport_size)
	assign_target.call("_drop_data", Vector2.ZERO, drag_data)
	await _wait_frames(4)
	var selected: PackedStringArray = screen.call("get_selected_unit_ids")
	var assigned: PackedStringArray = screen.call("get_selected_fireteam_ids")
	var index := selected.find(first_id)
	_check(index >= 0 and index < assigned.size() and not assigned[index].is_empty(), "%s existing Homebase callback assigns focused operator" % viewport_size)
	var selected_before: PackedStringArray = selected.duplicate()
	screen.call("_on_compact_card_open_requested", first_id, null, "roster")
	await _wait_frames(4)
	var popup := screen.get_node("CharacterSheetPopup") as Control
	var close := popup.get_node("PopupPanel/PopupMargin/PopupVBox/PopupHeaderRow/ClosePopupButton") as Button
	var sheet := popup.get_node("PopupPanel/PopupMargin/PopupVBox/PopupScroll/GeneratedSheetContent")
	_check(_reachable(popup, viewport_size) and _reachable(close, viewport_size), "%s Homebase character popup and close stay inside viewport" % viewport_size)
	_check(_editable_count(sheet) == 0, "%s Homebase character sheet remains read-only" % viewport_size)
	close.pressed.emit()
	await _wait_frames(2)
	_check(not popup.visible and selected_before == PackedStringArray(screen.call("get_selected_unit_ids")), "%s closing character detail preserves team assignment" % viewport_size)
	viewport.queue_free()
	await _wait_frames(3)


func _test_fob(viewport_size: Vector2i) -> void:
	var viewport := _make_viewport(viewport_size)
	var screen := FOB.instantiate() as Control
	viewport.add_child(screen)
	screen.show()
	var units := _fixture_units()
	# Supplied transport snapshot, using the existing public presentation fields.
	units[5]["is_transit_to_fob"] = true
	units[5]["transfer_progress"] = 0.4
	var ids := PackedStringArray()
	for unit: Dictionary in units:
		ids.append(String(unit.unit_id))
	# Parallel assignment IDs are the actual FOB membership API. Definition
	# member IDs alone are deliberately not used to fabricate loadout rows.
	screen.call("set_available_units", units)
	screen.call("configure_transfer", ids, PackedStringArray(["ft1", "ft1", "ft1", "", "", ""]), [
		{"id": "ft1", "label": "ALPHA", "lead_unit_id": ids[0], "member_unit_ids": PackedStringArray([ids[0], ids[1], ids[2]])},
		{"id": "ft2", "label": "BRAVO"},
	])
	screen.call("_on_staging_fireteam_dropped", "ft1", "loadout")
	await _wait_frames(6)
	_check_windows(screen, viewport_size, {
		"topbar": "Panel/Margin/VBox/MissionPanel", "unassigned_pool": HOME_WORK + "AvailablePanel",
		"fireteams": HOME_WORK + "FireteamPanel", "loadout": HOME_WORK + "StagingPanel",
		"flightdeck": HOME_WORK + "DropshipPanel", "boarding_status": "Panel/Margin/VBox/DropLightBottomRow/BoardingStatusPanel",
		"actions": "Panel/Margin/VBox/DropLightBottomRow/ActionsPanel",
	}, "FOB")
	var list := screen.get_node(FOB_LOADOUT + "LoadoutMemberScroll/LoadoutMemberList") as VBoxContainer
	_check(list.get_child_count() == 3, "%s real FOB loadout state produces all three member rows" % viewport_size)
	var context := screen.get_node(HOME_WORK + "FireteamPanel/FireteamMargin/FireteamVBox/R2TeamContext") as Label
	_check(context.text.contains("Ausrüstung"), "%s team context explains location of staged team" % viewport_size)
	# Both existing focus callbacks must refresh feedback synchronously. Do not
	# await a frame/resize: an incidental minimum-size notification hid this bug.
	var unchanged_viewport_size := viewport.size
	screen.call("_on_fireteam_card_pressed", "ft2")
	_check(context.text.begins_with("BRAVO") and context.text.contains("Teamübersicht") and not context.text.contains("Ausrüstung"), "%s card-only focus change immediately reads free BRAVO context" % viewport_size)
	screen.call("_on_select_fireteam_pressed", "ft1")
	_check(context.text.begins_with("ALPHA") and context.text.contains("Ausrüstung"), "%s selection-only focus change immediately restores ALPHA loadout context" % viewport_size)
	_check(viewport.size == unchanged_viewport_size, "%s team context refresh requires no viewport resize" % viewport_size)
	var staging_scroll := screen.get_node(HOME_WORK + "StagingPanel/StagingMargin") as ScrollContainer
	_check(staging_scroll != null, "%s full FOB staging remains in bounded native scroll" % viewport_size)
	var first_row := list.get_node("LoadoutMemberRow_%s" % ids[0]) as Control
	var armor := first_row.find_child("ArmorSelect", true, false) as OptionButton
	var weapon := first_row.find_child("Weapon1Select", true, false) as OptionButton
	_check(armor != null and weapon != null and armor.item_count > 1 and weapon.item_count > 1, "%s loadout retains populated native dropdowns" % viewport_size)
	var respawn := screen.get_node(HOME_WORK + "StagingPanel/StagingMargin/StagingVBox/RespawnPanel") as Control
	_check(respawn.size.y <= 104, "%s empty respawn panel stays compact" % viewport_size)
	_check(_reachable(armor, viewport_size), "%s first armor choice is reachable before scrolling" % viewport_size)
	if armor != null:
		var armor_id := String(armor.get_item_metadata(0))
		armor.item_selected.emit(0)
		await _wait_frames(3)
		var definition := _find_definition(screen, "ft1")
		_check(String(Dictionary(Dictionary(definition.get("member_loadouts", {})).get(ids[0], {})).get("armor", "")) == armor_id, "%s armor callback updates existing member loadout owner" % viewport_size)
	first_row = (screen.get_node(FOB_LOADOUT + "LoadoutMemberScroll/LoadoutMemberList") as VBoxContainer).get_node("LoadoutMemberRow_%s" % ids[0]) as Control
	weapon = first_row.find_child("Weapon1Select", true, false) as OptionButton
	if weapon != null:
		var weapon_id := String(weapon.get_item_metadata(1))
		weapon.item_selected.emit(1)
		await _wait_frames(3)
		var definition := _find_definition(screen, "ft1")
		_check(String(Dictionary(Dictionary(definition.get("member_loadouts", {})).get(ids[0], {})).get("weapon_1", "")) == weapon_id, "%s weapon callback updates existing member loadout owner" % viewport_size)
	screen.call("_on_set_fireteam_lead_pressed", "ft1", ids[1])
	await _wait_frames(3)
	_check(String(_find_definition(screen, "ft1").get("lead_unit_id", "")) == ids[1], "%s existing leader callback retains selected member identity" % viewport_size)
	# Scroll each existing viewport to a real dropdown before asserting reachability.
	staging_scroll.ensure_control_visible(screen.get_node(FOB_LOADOUT + "LoadoutMemberScroll") as Control)
	await _wait_frames(3)
	var member_scroll := screen.get_node(FOB_LOADOUT + "LoadoutMemberScroll") as ScrollContainer
	member_scroll.scroll_vertical = 0
	await _wait_frames(2)
	first_row = (screen.get_node(FOB_LOADOUT + "LoadoutMemberScroll/LoadoutMemberList") as VBoxContainer).get_node("LoadoutMemberRow_%s" % ids[0]) as Control
	armor = first_row.find_child("ArmorSelect", true, false) as OptionButton
	_check(_reachable(armor, viewport_size), "%s first loadout dropdown can be scrolled into real input bounds" % viewport_size)
	screen.call("_on_operator_card_open_requested", ids[0], null, "loadout_staging")
	await _wait_frames(4)
	var overlay := screen.get_node("CharacterOverlay") as Control
	var close := overlay.get_node("OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/CloseOverlayButton") as Button
	var sheet := overlay.get_node("OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/GeneratedOverlayContent")
	_check(_reachable(close, viewport_size), "%s FOB character close remains inside viewport" % viewport_size)
	_check(overlay.mouse_filter == Control.MOUSE_FILTER_STOP and _editable_count(sheet) == 0, "%s FOB character overlay keeps input boundary and read-only sheet" % viewport_size)
	close.pressed.emit()
	await _wait_frames(2)
	_check(not overlay.visible, "%s FOB detail closes through existing callback" % viewport_size)
	var transit_card := _find_unit_card(screen.get_node(HOME_WORK + "AvailablePanel"), ids[5])
	_check(transit_card != null and not bool(Dictionary(transit_card.call("get_card_userology_snapshot")).get("drag_enabled", true)), "%s supplied transit operator keeps drag disabled" % viewport_size)
	if transit_card != null:
		_check(transit_card.call("_get_drag_data", Vector2.ZERO) == null, "%s transit card cannot create assignment drag data" % viewport_size)
	var action_grid := screen.get_node("Panel/Margin/VBox/DropLightBottomRow/ActionsPanel/Margin/VBox/ActionGrid")
	for button_name in ["BoardButton", "SendButton"]:
		_check(_reachable(action_grid.get_node(button_name) as Control, viewport_size), "%s FOB %s stays inside viewport" % [viewport_size, button_name])
	viewport.queue_free()
	await _wait_frames(3)


func _check_windows(screen: Control, viewport_size: Vector2i, paths: Dictionary, family: String) -> void:
	var layout: Dictionary = screen.call("get_native_r2_layout_snapshot")
	var bounds := Rect2(Vector2.ZERO, Vector2(viewport_size))
	for key: String in paths:
		var control := screen.get_node(String(paths[key])) as Control
		var expected := Rect2(layout[key])
		print("GEOMETRY %s %s %s actual=%s expected=%s" % [family, viewport_size, key, control.get_global_rect(), expected])
		_check(control.get_global_rect().is_equal_approx(expected), "%s %s %s uses current native owner geometry" % [viewport_size, family, key])
		_check(_inside(control.get_global_rect(), bounds), "%s %s %s is bounded" % [viewport_size, family, key])


func _find_definition(screen: Control, fireteam_id: String) -> Dictionary:
	for definition: Dictionary in screen.call("get_fireteam_definitions"):
		if String(definition.id) == fireteam_id:
			return definition
	return {}


func _find_unit_card(node: Node, unit_id: String) -> Control:
	if node.has_method("get_unit_id") and String(node.call("get_unit_id")) == unit_id:
		return node as Control
	for child in node.get_children():
		var found := _find_unit_card(child, unit_id)
		if found != null:
			return found
	return null


func _fixture_units() -> Array:
	var roster: Dictionary = GENERATOR.call("generate_start_roster", "native-r2-preparation", 24, "native_r2_preparation")
	return Array(roster.units).slice(0, 6)


func _make_viewport(viewport_size: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.disable_3d = true
	root.add_child(viewport)
	return viewport


func _editable_count(node: Node) -> int:
	var count := 1 if node is LineEdit or node is SpinBox or node is HSlider or node is OptionButton else 0
	for child in node.get_children():
		count += _editable_count(child)
	return count


func _reachable(control: Control, viewport_size: Vector2i) -> bool:
	if control == null or not control.is_visible_in_tree() or not _inside(control.get_global_rect(), Rect2(Vector2.ZERO, Vector2(viewport_size))):
		if control != null:
			print("UNREACHABLE %s visible=%s rect=%s min=%s parent=%s" % [control.get_path(), control.is_visible_in_tree(), control.get_global_rect(), control.get_combined_minimum_size(), control.get_parent().get_path()])
		return false
	var parent := control.get_parent()
	while parent is Control:
		if (parent as Control).clip_contents and not _inside(control.get_global_rect(), (parent as Control).get_global_rect()):
			print("CLIPPED %s rect=%s by %s rect=%s" % [control.name, control.get_global_rect(), parent.name, (parent as Control).get_global_rect()])
			return false
		parent = parent.get_parent()
	return true


func _inside(rect: Rect2, bounds: Rect2) -> bool:
	return rect.position.x >= bounds.position.x - 1 and rect.position.y >= bounds.position.y - 1 and rect.end.x <= bounds.end.x + 1 and rect.end.y <= bounds.end.y + 1


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		print("FAIL: " + message)
