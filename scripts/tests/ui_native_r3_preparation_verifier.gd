extends SceneTree

const HOME: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const FOB: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const GENERATOR: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const PERSONNEL_EVENTS: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const WORK := "Panel/Margin/VBox/ContentRow/"
const BRIEF := "Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/"
const FOB_TEAM := WORK + "FireteamPanel/FireteamMargin/FireteamVBox/"
const LOADOUT := WORK + "StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/"
var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for viewport_size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		await _homebase_states(viewport_size)
		await _fob_states(viewport_size)
	print("RESULTS: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("PASS: native R3 preparation density and state feedback")
	quit(1 if _failed > 0 else 0)


func _homebase_states(viewport_size: Vector2i) -> void:
	var viewport := _viewport(viewport_size)
	var screen := HOME.instantiate() as Control
	viewport.add_child(screen)
	screen.show()
	screen.call("setup_roster", [])
	screen.call("set_transport_state", [], {}, [], [])
	await _frames(6)
	var team := screen.get_node(WORK + "HomebaseFireteamPanel") as Control
	var transport := screen.get_node(WORK + "AircraftPanel") as Control
	_check(transport.size.y <= 192, "%s empty Homebase transport is a short actionable card" % viewport_size)
	_check(team.size.y <= 256, "%s empty Homebase team target does not reserve a full column" % viewport_size)
	var add_ship := screen.get_node(WORK + "AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/AddAircraftButton") as Button
	_check(_reachable(add_ship, viewport_size) and add_ship.pressed.get_connections().size() > 0, "%s empty transport retains native add callback" % viewport_size)
	var briefing_detail := screen.get_node(BRIEF + "MissionBriefingPanel") as Control
	_check(not briefing_detail.visible, "%s compact briefing does not expose a clipped detail-frame fragment" % viewport_size)
	var toggle := screen.get_node(BRIEF + "HeaderRow/R2BriefingDetailsButton") as Button
	toggle.pressed.emit()
	await _frames(3)
	_check(briefing_detail.is_visible_in_tree() and _reachable(toggle, viewport_size), "%s full original briefing is explicitly reachable" % viewport_size)
	toggle.pressed.emit()
	await _frames(3)
	_check(not briefing_detail.visible, "%s returning hides the complete detail body again" % viewport_size)
	var event: Dictionary = PERSONNEL_EVENTS.call("make_event", "recruit_available", "", "Anja", "Anja steht als Verstärkung bereit.", {}, false)
	screen.call("set_personnel_events", [event])
	screen.call("set_last_mission_result_summary", {"route_id": "frontier_probe_aa_computer_cargo", "result": "success", "duration_seconds": 45})
	await _frames(3)
	var personnel_label := screen.get_node(BRIEF + "PersonnelEventsLabel") as Label
	var followup := screen.get_node(BRIEF + "PostDebriefFollowupPanel") as Control
	var followup_summary := followup.get_node("FollowupMargin/FollowupVBox/PostDebriefHomebaseSummaryLabel") as Label
	_check(not personnel_label.visible and not followup.visible and not briefing_detail.visible, "%s late personnel/result setters keep compact detail body folded" % viewport_size)
	_check(personnel_label.text.contains("Anja steht als Verstärkung bereit.") and followup_summary.text.contains("Frontier Probe"), "%s late notices retain existing source text while folded" % viewport_size)
	toggle.pressed.emit()
	await _frames(3)
	_check(personnel_label.is_visible_in_tree() and personnel_label.text.contains("Anja steht als Verstärkung bereit."), "%s explicit details reveal the late personnel notice" % viewport_size)
	_check(followup.is_visible_in_tree() and followup_summary.is_visible_in_tree() and followup_summary.text.contains("Frontier Probe"), "%s explicit details reveal the late confirmed result notice" % viewport_size)
	toggle.pressed.emit()
	await _frames(3)
	_check(not personnel_label.visible and not followup.visible, "%s closing late-notice details folds both original sections again" % viewport_size)
	screen.call("set_personnel_events", [])
	screen.call("set_last_mission_result_summary", {})
	_check_primary_titles(screen, [BRIEF + "MissionHeaderLabel", WORK + "RosterPanel/RosterMargin/RosterVBox/RosterHeaderLabel", WORK + "HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel", WORK + "AircraftPanel/AircraftMargin/AircraftVBox/AircraftHeaderLabel"], viewport_size)
	var empty_team_height := team.size.y
	var empty_transport_height := transport.size.y
	var units := _units(6)
	var ids := _ids(units)
	screen.call("setup_roster", units, PackedStringArray(ids.slice(0, 3)))
	screen.call("set_fireteam_context", PackedStringArray(["ft1", "ft1", "ft1"]), [{"id": "ft1", "label": "ALPHA", "lead_unit_id": ids[0]}])
	screen.call("set_transport_state", _crafts(1), {"r3_ship_0": ids[5]}, [], [], {"r3_ship_0": "homebase"})
	await _frames(6)
	_check(team.size.y > empty_team_height, "%s ground team grows when real members need space" % viewport_size)
	_check(transport.size.y > empty_transport_height, "%s Homebase transport grows for a real ship" % viewport_size)
	var selected: PackedStringArray = screen.call("get_selected_unit_ids")
	screen.call("_on_homebase_shipcard_fireteam_dropped", "ft1", "r3_ship_0")
	await _frames(6)
	var staging: Dictionary = screen.call("get_homebase_direct_staging_snapshot")
	_check(Array(staging.get("payload_fireteam_ids", [])).has("ft1"), "%s actual existing ship drop stages the same team owner" % viewport_size)
	_check(team.size.y <= 168, "%s team workspace contracts after its card moves to transport" % viewport_size)
	_check(selected == PackedStringArray(screen.call("get_selected_unit_ids")), "%s moving team location preserves selected identities" % viewport_size)
	screen.call("_on_homebase_staging_fireteam_dropped", "ft1", "fireteam_pool")
	await _frames(6)
	_check(team.size.y > 168, "%s existing return drop restores the ground work area" % viewport_size)
	var rich_units := _units(24)
	screen.call("setup_roster", rich_units, PackedStringArray(ids.slice(0, 3)))
	screen.call("set_transport_state", _crafts(5), {}, [], [])
	await _frames(6)
	var ship_scroll := screen.get_node(WORK + "AircraftPanel/AircraftMargin/AircraftVBox/ShipCardsScroll") as ScrollContainer
	var cards := _nodes_with_meta(ship_scroll, "homebase_shipcard")
	_check(cards.size() == 5, "%s populated Homebase retains all five actual shipcards" % viewport_size)
	for card: Control in cards:
		_check(card.get_global_rect().position.x >= ship_scroll.get_global_rect().position.x - 1 and card.get_global_rect().end.x <= ship_scroll.get_global_rect().end.x + 1, "%s shipcard %s has no horizontal clipping" % [viewport_size, card.name])
	# Five short empty ships can fit at 1080p. A genuinely long list must scroll.
	screen.call("set_transport_state", _crafts(12), {}, [], [])
	await _frames(6)
	_check(ship_scroll.get_v_scroll_bar().visible, "%s twelve actual ships expose native vertical scrolling" % viewport_size)
	_assert_bounds(screen, viewport_size, [WORK + "RosterPanel", WORK + "HomebaseFireteamPanel", WORK + "AircraftPanel"])
	viewport.queue_free()
	await _frames(3)


func _fob_states(viewport_size: Vector2i) -> void:
	var viewport := _viewport(viewport_size)
	var screen := FOB.instantiate() as Control
	viewport.add_child(screen)
	screen.show()
	var units := _units(6)
	var ids := _ids(units)
	screen.call("set_available_units", units)
	screen.call("configure_transfer", ids, PackedStringArray(["ft1", "ft1", "ft1", "", "", ""]), [{"id": "ft1", "label": "ALPHA", "lead_unit_id": ids[0]}])
	screen.call("_on_staging_fireteam_dropped", "ft1", "loadout")
	await _frames(6)
	var team := screen.get_node(WORK + "FireteamPanel") as Control
	var flightdeck := screen.get_node(WORK + "DropshipPanel") as Control
	var boarding := screen.get_node("Panel/Margin/VBox/DropLightBottomRow/BoardingStatusPanel") as Control
	var loadout := screen.get_node(WORK + "StagingPanel") as Control
	_check(team.size.y <= 144, "%s no free FOB team cards leaves a short context/action area" % viewport_size)
	_check(flightdeck.size.y <= 192 and boarding.size.y <= 72, "%s missing FOB transport does not reserve a full empty deck/status column" % viewport_size)
	_check(loadout.position.y <= 248, "%s released team-space moves actual loadout upward" % viewport_size)
	var member_list := screen.get_node(LOADOUT + "LoadoutMemberScroll/LoadoutMemberList")
	_check(member_list.get_child_count() == 3, "%s compact FOB retains all three real loadout rows" % viewport_size)
	_check_primary_titles(screen, ["Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel", FOB_TEAM + "FireteamHeaderLabel", LOADOUT + "LoadoutHeaderRow/LoadoutHeaderLabel", WORK + "DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/DropshipHeaderLabel"], viewport_size)
	var loadout_status := screen.get_node(LOADOUT + "LoadoutStatusLabel") as Label
	_check(loadout_status.text.contains("Ausrüstung") and not loadout_status.text.contains("Weight"), "%s loadout summary uses understandable player wording" % viewport_size)
	var empty_deck_height := flightdeck.size.y
	screen.call("set_transport_craft_state", _fob_crafts(1))
	await _frames(6)
	_check(flightdeck.size.y > empty_deck_height, "%s public craft-state update expands the FOB deck without resize" % viewport_size)
	screen.call("configure_transfer", ids, PackedStringArray(["ft1", "ft1", "ft1", "", "", ""]), [{"id": "ft1", "label": "ALPHA", "lead_unit_id": ids[0]}, {"id": "ft2", "label": "BRAVO"}])
	var context := screen.get_node(FOB_TEAM + "R2TeamContext") as Label
	screen.call("_on_fireteam_card_pressed", "ft2")
	_check(context.text.begins_with("BRAVO") and context.text.contains("Teamübersicht"), "%s focus-only context follows actual free team location" % viewport_size)
	screen.call("_on_select_fireteam_pressed", "ft1")
	_check(context.text.begins_with("ALPHA") and context.text.contains("Ausrüstung"), "%s focus-only context restores actual loadout location" % viewport_size)
	screen.call("set_transport_craft_state", _fob_crafts(5))
	await _frames(6)
	var ship_scroll := screen.get_node(WORK + "DropshipPanel/DropshipMargin/DropshipVBox/DropshipQueueScroll") as ScrollContainer
	_check(ship_scroll.get_v_scroll_bar().visible, "%s populated FOB deck keeps real craft scroll reachability" % viewport_size)
	for button_name in ["BoardButton", "SendButton"]:
		var button := screen.get_node("Panel/Margin/VBox/DropLightBottomRow/ActionsPanel/Margin/VBox/ActionGrid/" + button_name) as Button
		_check(_reachable(button, viewport_size) and button.pressed.get_connections().size() > 0, "%s %s preserves its existing input/callback boundary" % [viewport_size, button_name])
	_assert_bounds(screen, viewport_size, [WORK + "AvailablePanel", WORK + "FireteamPanel", WORK + "StagingPanel", WORK + "DropshipPanel", "Panel/Margin/VBox/DropLightBottomRow/BoardingStatusPanel", "Panel/Margin/VBox/DropLightBottomRow/ActionsPanel"])
	screen.call("set_transport_craft_state", [])
	await _frames(6)
	_check(flightdeck.size.y <= 192, "%s removing final craft contracts deck on real state update" % viewport_size)
	viewport.queue_free()
	await _frames(3)


func _crafts(count: int) -> Array:
	var result: Array = []
	for index in range(count):
		result.append({"craft_id": "r3_ship_%d" % index, "craft_type": "dropship", "display_name": "Dropship %d" % (index + 1), "supports_cargo": false, "cargo_options": []})
	return result


func _fob_crafts(count: int) -> Array:
	var result := _crafts(count)
	for craft: Dictionary in result:
		craft["visible_in_fob"] = true
		craft["is_boardable"] = true
		craft["is_in_transit"] = false
	return result


func _check_primary_titles(screen: Node, paths: Array, viewport_size: Vector2i) -> void:
	for path: String in paths:
		var label := screen.get_node(path) as Label
		_check(not label.text.begins_with("#") and not label.text.contains("LOADOUT") and not label.text.contains("FIRETEAM") and not label.text.contains("MISSION BRIEF"), "%s primary title uses player wording: %s" % [viewport_size, label.text])


func _assert_bounds(screen: Node, viewport_size: Vector2i, paths: Array) -> void:
	for path: String in paths:
		var panel := screen.get_node(path) as Control
		print("GEOMETRY %s %s %s" % [viewport_size, path, panel.get_global_rect()])
		_check(_inside(panel.get_global_rect(), Rect2(Vector2.ZERO, Vector2(viewport_size))), "%s %s remains bounded" % [viewport_size, panel.name])


func _nodes_with_meta(node: Node, key: String) -> Array:
	var result: Array = []
	if bool(node.get_meta(key, false)):
		result.append(node)
	for child in node.get_children():
		result.append_array(_nodes_with_meta(child, key))
	return result


func _viewport(viewport_size: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.disable_3d = true
	root.add_child(viewport)
	return viewport


func _units(count: int) -> Array:
	return Array(Dictionary(GENERATOR.call("generate_start_roster", "native-r3-preparation", 24, "native_r3_preparation")).get("units", [])).slice(0, count)


func _ids(units: Array) -> PackedStringArray:
	var ids := PackedStringArray()
	for unit: Dictionary in units:
		ids.append(String(unit.unit_id))
	return ids


func _reachable(control: Control, viewport_size: Vector2i) -> bool:
	if control == null or not control.is_visible_in_tree() or not _inside(control.get_global_rect(), Rect2(Vector2.ZERO, Vector2(viewport_size))):
		return false
	var parent := control.get_parent()
	while parent is Control:
		if (parent as Control).clip_contents and not _inside(control.get_global_rect(), (parent as Control).get_global_rect()):
			return false
		parent = parent.get_parent()
	return true


func _inside(rect: Rect2, bounds: Rect2) -> bool:
	return rect.position.x >= bounds.position.x - 1 and rect.position.y >= bounds.position.y - 1 and rect.end.x <= bounds.end.x + 1 and rect.end.y <= bounds.end.y + 1


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	_passed += 1 if condition else 0
	_failed += 0 if condition else 1
	print(("PASS: " if condition else "FAIL: ") + message)
