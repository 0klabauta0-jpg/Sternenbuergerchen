extends SceneTree

const SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const LAYOUT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const GRID: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"
const TEAM: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel"
const MINI: String = "TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll"
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for spec in [[Vector2i(1280, 720), 52.0, 300.0, 80.0], [Vector2i(1920, 1080), 64.0, 336.0, 88.0], [Vector2i(3440, 1440), 72.0, 400.0, 96.0]]:
		await _check_size(spec[0], spec[1], spec[2], spec[3])
	print("MISSION_HUD_GROUPS: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check_size(size_value: Vector2i, action_edge: float, card_width: float, portrait_height: float) -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = size_value
	var layout: Dictionary = LAYOUT.get_mission_hud_layout(size_value)
	_expect(layout.selected_fireteam.position.x <= 32 and layout.selected_fireteam.end.y < layout.bottom_dock.position.y, "%s: selected-team parameters are on the left above the action band" % size_value)
	_expect(layout.fireteam_mini.end.y < layout.selected_fireteam.position.y, "%s: portrait stack precedes team parameters without overlap" % size_value)
	var scene: Node = SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(24):
		await process_frame
	var controller: Node = scene.get_node("TacticalController")
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(size_value))
	var band := scene.get_node("TacticalUI/BottomDock") as Control
	var team := scene.get_node(TEAM) as Control
	var mini := scene.get_node("TacticalUI/FireteamMiniPanel") as Control
	var target := scene.get_node("TacticalUI/A5TargetOrderPanel") as Control
	var card_scroll := scene.get_node(MINI) as ScrollContainer
	_expect(viewport_rect.encloses(team.get_global_rect()) and team.get_global_rect().position.x <= 32 and team.get_global_rect().end.y < band.get_global_rect().position.y, "%s: actual selected-team panel occupies its native left slot" % size_value)
	_expect(not team.get_global_rect().intersects(mini.get_global_rect()), "%s: actual card stack and parameter controls remain separate" % size_value)
	_expect(card_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and card_scroll.clip_contents, "%s: many teams have an actual bounded scroll owner" % size_value)
	var action_rects: Array[Rect2] = []
	for name in ["MoveButton", "TakeButton", "HoldButton", "FlankButton", "GoCommandMatrixButton", "TargetButton", "ClearTargetButton", "DeleteOrderButton", "SortCommandMatrixButton"]:
		var button := scene.get_node(GRID + "/" + name) as Button
		var rect: Rect2 = button.get_global_rect()
		_expect(absf(rect.size.x - action_edge) <= 1.0 and absf(rect.size.y - action_edge) <= 1.0, "%s: %s is a readable square at this display height" % [size_value, name])
		_expect(not button.get_signal_connection_list("pressed").is_empty() and band.get_global_rect().encloses(rect), "%s: %s retains its owner callback and complete input rectangle" % [size_value, name])
		action_rects.append(rect)
	for a in range(action_rects.size()):
		for b in range(a + 1, action_rects.size()):
			_expect(not action_rects[a].intersects(action_rects[b]), "%s: action rectangles remain distinct" % size_value)
	_expect(band.get_global_rect().encloses(target.get_global_rect()), "%s: target/order remains beside the two action rows" % size_value)
	var cards: Node = scene.get_node(MINI + "/MiniCardsVBox")
	_expect(cards.get_child_count() > 0, "%s: real fixture supplies actual fireteam cards" % size_value)
	for card in cards.get_children():
		if not card is Control:
			continue
		_expect(absf(card.size.x - card_width) <= 2.0, "%s: team card has the new readable width" % size_value)
		var strip := card.get_node("Margin/VBox/FireteamMemberPortraitStrip") as Control
		_expect(strip.visible and strip.size.y >= portrait_height - 1.0, "%s: actual member portraits retain large readable faces" % size_value)
		if strip.get_child_count() > 0:
			var portrait := strip.get_child(0) as Control
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			click.double_click = true
			portrait.gui_input.emit(click)
			_expect(bool((scene.get_node("TacticalUI/CharacterOverlay") as Control).visible) and String(controller.get("_character_overlay_unit_id")) == String(portrait.get_meta("mission_member_unit_id", "")), "%s: original portrait callback opens that actual member's character details" % size_value)
			controller.call("_close_character_overlay")
	var selected_seen: bool = false
	for card in cards.get_children():
		if card is PanelContainer and bool(card.get_meta("mission_fireteam_mini_card_selected", false)):
			var style := card.get_theme_stylebox("panel") as StyleBoxFlat
			selected_seen = style != null and style.border_width_left >= 3 and style.border_color.r > 0.8
	_expect(selected_seen, "%s: selected original team has a clear yellow outline" % size_value)
	var raw_status := scene.get_node(TEAM + "/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamStatusLabel") as Label
	var raw_text_before: String = raw_status.text
	controller.call("_apply_combat_hud_detail_tooltip_label_contract", raw_status)
	_expect(not raw_status.visible and raw_status.text == raw_text_before, "%s: actual legacy tooltip writer preserves the hidden A5 detail source" % size_value)
	controller.call("_update_ui")
	_expect(not raw_status.visible, "%s: actual owner refresh cannot restore overlapping cyan legacy text" % size_value)
	var team_details := scene.get_node(TEAM + "/A5DetailsButton") as Button
	team_details.pressed.emit()
	var detail_text := scene.get_node("TacticalUI/A5TeamDetailsPopup/Margin/Box/Scroll/Text") as Label
	_expect(not raw_status.text.is_empty() and detail_text.text.contains(raw_status.text), "%s: team details retain the complete refreshed legacy source" % size_value)
	(scene.get_node("TacticalUI/A5TeamDetailsPopup") as PopupPanel).hide()
	var source_before: String = JSON.stringify(controller.get("_mission_drop_cards"))
	var transport := scene.get_node("TacticalUI/MissionDropshipPanel") as Control
	_expect(viewport_rect.encloses(transport.get_global_rect()) and transport.get_global_rect().position.x >= size_value.x * 0.5, "%s: transport card fits the upper-right viewport" % size_value)
	var preview := transport.get_node("CompactCard/Contents/Header/ShipTexture") as TextureRect
	_expect(preview.custom_minimum_size.y >= 80, "%s: Ref03 preview has a larger readable image slot" % size_value)
	var details := transport.get_node("CompactCard/Contents/Header/DetailsButton") as Button
	details.pressed.emit()
	_expect(bool((scene.get_node("TacticalUI/A5DropshipDetailsPopup") as PopupPanel).visible), "%s: transport details keep their existing callback" % size_value)
	(scene.get_node("TacticalUI/A5DropshipDetailsPopup") as PopupPanel).hide()
	controller.call("_refresh_mission_dropship_panel")
	_expect(JSON.stringify(controller.get("_mission_drop_cards")) == source_before, "%s: presentation preserves transport owner payload" % size_value)
	# The same public planning hydration used by MetaFlow supplies route context.
	# No runtime phase, actor position, ETA or transport timer is patched here.
	var planning: Dictionary = controller.call("get_planning_state")
	planning["mission_drop_source"] = "homebase_direct"
	controller.call("set_planning_state", planning)
	controller.call("_apply_native_a5_hud_layout")
	var fob := scene.get_node("TacticalUI/TopNavPanel/NavMargin/NavRow/FOBNavButton") as Button
	_expect(not fob.visible and not fob.get_signal_connection_list("pressed").is_empty(), "%s: direct Homebase route hides only the FOB presentation and preserves its callback" % size_value)
	planning["mission_drop_source"] = "fob"
	controller.call("set_planning_state", planning)
	controller.call("_apply_native_a5_hud_layout")
	_expect(fob.visible, "%s: explicit legacy FOB route retains navigation" % size_value)
	scene.queue_free()
	for _frame in range(4):
		await process_frame


func _expect(value: bool, label: String) -> void:
	if value:
		_passed += 1
		print("PASS: " + label)
	else:
		_failed += 1
		push_error("FAIL: " + label)
