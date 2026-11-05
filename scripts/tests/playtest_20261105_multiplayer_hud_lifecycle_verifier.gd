extends "res://scripts/tests/review7_lobby_map_consent_verifier.gd"
## Retain every original ENet/consent assertion; add live HUD owner lifecycle.

var _actual_widget_branch_checked: bool = false


func _cleanup_pair(fixture: Dictionary) -> void:
	for key in ["host", "client"]:
		var lobby: Node = fixture.get(key, null)
		if lobby == null:
			continue
		var mission: Node = lobby.get("_active_mission")
		var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
		if controller == null:
			continue
		_assert(controller.has_method("_ensure_native_a5_selected_card_visible"), "%s has a live-owner deferred HUD focus boundary" % key)
		if not controller.has_method("_ensure_native_a5_selected_card_visible"):
			continue
		var scroll := mission.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll") as ScrollContainer
		var host: Node = scroll.get_node_or_null("MiniCardsVBox") if scroll != null else null
		if host == null:
			continue
		var cards: Array[Node] = host.get_children()
		if cards.is_empty():
			_assert(not bool(controller.call("_ensure_native_a5_selected_card_visible", null, "missing")), "%s empty HUD does not invent a selected card" % key)
			continue
		var card := cards[0] as Control
		var id: String = String(card.get_meta("fireteam_id", ""))
		controller.call("_set_selected_fireteams", PackedStringArray([id]), false)
		await process_frame
		# Widget-only reparent models the actual mission-start replacement. Actor,
		# roster, simulation, transport, map and peer state are left untouched.
		var parking := Control.new()
		mission.add_child(parking)
		card.reparent(parking)
		var card_reference: WeakRef = weakref(card)
		_assert(not bool(controller.call("_ensure_native_a5_selected_card_visible", card_reference, id)), "%s reparented selected widget is not handed to the former scroll owner" % key)
		card.reparent(host)
		await process_frame
		_assert(bool(controller.call("_ensure_native_a5_selected_card_visible", card_reference, id)), "%s current selected widget is focused after actual layout" % key)
		parking.queue_free()
	await super._cleanup_pair(fixture)
	if not _actual_widget_branch_checked:
		_actual_widget_branch_checked = true
		await _test_actual_selected_widget_lifecycle()


func _test_actual_selected_widget_lifecycle() -> void:
	var packed: PackedScene = load("res://scenes/tests/mission_reactivity_test.tscn") as PackedScene
	var mission: Node = packed.instantiate()
	root.add_child(mission)
	for _frame in range(24):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	var ids: PackedStringArray = controller.call("_get_available_fireteam_ids")
	_assert(not ids.is_empty(), "Actual mission fixture supplies a selectable real fireteam")
	if ids.is_empty():
		mission.queue_free()
		await process_frame
		return
	controller.call("_set_selected_fireteams", PackedStringArray([ids[0]]), false)
	for _frame in range(3):
		await process_frame
	var scroll := mission.get_node("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll") as ScrollContainer
	var card_host: Node = scroll.get_node("MiniCardsVBox")
	var card: Control = null
	for candidate in card_host.get_children():
		if candidate is Control and String(candidate.get_meta("fireteam_id", "")) == ids[0]:
			card = candidate as Control
			break
	_assert(is_instance_valid(card), "Lifecycle branch uses the actual owner-created selected MiniCard")
	if not is_instance_valid(card):
		mission.queue_free()
		await process_frame
		return
	var parking := Control.new()
	parking.name = "TemporaryWidgetOwner"
	mission.add_child(parking)
	var card_reference: WeakRef = weakref(card)
	controller.call_deferred("_ensure_native_a5_selected_card_visible", card_reference, String(ids[0]))
	card.reparent(parking)
	_assert(not bool(controller.call("_ensure_native_a5_selected_card_visible", card_reference, String(ids[0]))), "Real selected MiniCard is rejected by its former ancestor after reparent")
	await process_frame
	_assert(card.get_parent() == parking, "Deferred focus neither reparents nor mutates the actual selected widget")
	card.reparent(card_host)
	for _frame in range(3):
		await process_frame
	scroll.scroll_vertical = 100000
	await process_frame
	_assert(bool(controller.call("_ensure_native_a5_selected_card_visible", card_reference, String(ids[0]))), "Restored actual selected MiniCard is focused through its current scroll owner")
	await process_frame
	_assert(scroll.get_global_rect().intersects(card.get_global_rect()), "Selected card occupies the visible scroll rectangle after actual layout")
	var replaced_widget := Control.new()
	parking.add_child(replaced_widget)
	var replaced_reference: WeakRef = weakref(replaced_widget)
	replaced_widget.free()
	_assert(bool(controller.call("_ensure_native_a5_selected_card_visible", replaced_reference, String(ids[0]))), "Expired prior widget reference resolves the current real card by fireteam identity")
	mission.queue_free()
	for _frame in range(3):
		await process_frame
