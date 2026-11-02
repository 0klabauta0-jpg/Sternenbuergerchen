extends SceneTree

const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const CARD_BODY := "MarginContainer/VBox/"
const EXTRA := CARD_BODY + "ExtraContentHost/"
var _passed: int = 0
var _failed: int = 0


class TracedController extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var recursive_lookup_calls: int = 0
	var approach_actions: Array = []

	func _find_friendly_unit_by_id_recursive(root_node: Node, unit_id: String) -> Node:
		recursive_lookup_calls += 1
		return super._find_friendly_unit_by_id_recursive(root_node, unit_id)

	func _on_mission_dropship_card_approach_pressed(craft_id: String, angle_name: String) -> void:
		approach_actions.append([craft_id, angle_name])
		super._on_mission_dropship_card_approach_pressed(craft_id, angle_name)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Review 2026-11-02 P2 Dropship HUD ===")
	root.size = Vector2i(1920, 1080)
	var mission: Node = MISSION_SCENE.instantiate()
	var original: Node = mission.get_node("TacticalController")
	var controller := TracedController.new()
	# Preserve the scene's real exported wiring; only trace actual recursive calls/actions.
	for property in original.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_EDITOR and int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			controller.set(String(property.name), original.get(String(property.name)))
	controller.name = original.name
	var controller_index: int = original.get_index()
	mission.remove_child(original)
	original.free()
	mission.add_child(controller)
	mission.move_child(controller, controller_index)
	root.add_child(mission)
	for _frame in range(4):
		await process_frame
	mission.process_mode = Node.PROCESS_MODE_DISABLED
	var card := _card("alpha", ["unit_alpha", "unit_bravo", "unit_charlie"])
	_apply_cards(controller, [card])
	var panel: Control = mission.get_node("TacticalUI/MissionDropshipPanel")
	var first: Control = _find_card(panel, "alpha")
	_assert(first != null and _find_meta(first, "mission_dropship_passenger_unit_id", "unit_alpha") != null and _find_meta(first, "mission_dropship_passenger_unit_id", "unit_bravo") != null and _find_meta(first, "mission_dropship_passenger_unit_id", "unit_charlie") != null, "Real waiting card renders all three passengers")
	var first_ids: Array = _subtree_ids(first)
	var scan_before: int = int(controller.get_mission_runtime_index_diagnostics().membership_scan_count)
	for _refresh in range(6):
		controller._process(0.35)
	var unchanged: Control = _find_card(panel, "alpha")
	var unchanged_ids: Array = _subtree_ids(unchanged)
	print("WAITING_CARD before_nodes=%d after_nodes=%d before_root=%d after_root=%d retained_nodes=%d" % [first_ids.size(), unchanged_ids.size(), first_ids[0], unchanged_ids[0], _retained_count(first_ids, unchanged_ids)])
	_assert(first_ids == unchanged_ids, "Six real 0.35-second light HUD refreshes retain every unchanged card node")
	_assert(int(controller.get_mission_runtime_index_diagnostics().membership_scan_count) == scan_before, "Stable light refreshes do not rescan mission membership")

	card["state"] = "to_mission"
	card["progress"] = 20.0
	card["eta_seconds"] = 12
	_apply_cards(controller, [card])
	var transit: Control = _find_card(panel, "alpha")
	_assert(transit.get_instance_id() == unchanged_ids[0], "Transit changes retain the keyed craft card")
	_assert(transit.modulate.a < 0.9 and bool(transit.get_meta("mission_dropship_card_inaccessible")), "Transit updates visible dimming and accessibility")
	_assert(_command(transit, "set_lz").disabled and _command(transit, "drop").disabled, "Transit locks existing action buttons")
	var transit_ids: Array = _subtree_ids(transit)
	card["progress"] = 47.0
	card["eta_seconds"] = 7
	_apply_cards(controller, [card])
	transit = _find_card(panel, "alpha")
	_assert(_subtree_ids(transit) == transit_ids, "Progress-only changes retain the entire craft subtree")
	var progress: ProgressBar = transit.get_node(CARD_BODY + "ProgressBar")
	_assert(progress.visible and is_equal_approx(progress.value, 47.0), "Existing progress bar displays changed progress")
	_assert(_info_text(transit).contains("7s"), "Existing info label displays changed ETA")

	card["state"] = "waiting"
	card["has_lz_position"] = true
	card["pilot_unit_id"] = "unit_delta"
	card["pilot_display_name"] = "Pilot Delta"
	_apply_cards(controller, [card])
	var waiting: Control = _find_card(panel, "alpha")
	_assert(not _command(waiting, "set_lz").disabled and not _command(waiting, "drop").disabled, "Waiting with LZ unlocks existing LZ and Drop actions")
	_assert(waiting.modulate.a >= 0.99, "Waiting restores full card visibility")
	var pilot: Node = waiting.get_node(CARD_BODY + "ContentRow/InfoVBox/PilotCardHost/PilotCard")
	var pilot_id: int = pilot.get_instance_id()
	var pilot_unit: Node = mission.get_node("UnitDelta")
	pilot_unit.call("apply_identity_config", {"display_name": "Changed Pilot", "weapon_1_id": "medictool"})
	var passenger: Node = mission.get_node("UnitAlpha")
	passenger.call("apply_identity_config", {"display_name": "Changed Passenger", "portrait_path": "res://icon.svg"})
	controller.recursive_lookup_calls = 0
	controller._refresh_mission_dropship_panel()
	waiting = _find_card(panel, "alpha")
	pilot = waiting.get_node(CARD_BODY + "ContentRow/InfoVBox/PilotCardHost/PilotCard")
	_assert(controller.recursive_lookup_calls == 0, "Dropship pilot, grouping and passenger lookups use the index without recursive tree searches")
	_assert(pilot.get_instance_id() == pilot_id and String(pilot.call("get_profile").display_name) == "Changed Pilot", "Pilot profile changes refresh the existing pilot card")
	_assert(String(pilot.call("get_profile").weapon_1_id) == "medictool", "Pilot loadout changes refresh its rendered profile")
	pilot_unit.call("apply_identity_config", {"weapon_1_id": "smg"})
	controller._refresh_mission_dropship_panel()
	pilot = _find_card(panel, "alpha").get_node(CARD_BODY + "ContentRow/InfoVBox/PilotCardHost/PilotCard")
	_assert(String(pilot.call("get_profile").weapon_1_id) == "smg" and pilot.get_instance_id() == pilot_id, "A weapon-only change invalidates the pilot profile without replacing its card")
	var pilot_tree_ids: Array = _subtree_ids(_find_card(panel, "alpha"))
	for _refresh in range(3):
		controller._refresh_mission_dropship_panel()
	_assert(_subtree_ids(_find_card(panel, "alpha")) == pilot_tree_ids, "Unchanged pilot profiles retain every compact-card child")
	var passenger_chip: Node = _find_meta(waiting, "mission_dropship_passenger_unit_id", "unit_alpha")
	_assert(String(passenger_chip.get_node("PassengerPortraitName").text) == "Changed Passenger" and passenger_chip.get_node("PassengerPortraitRect").texture != null, "Passenger name and portrait changes refresh visible payload content")
	var action_id: int = _command(waiting, "drop").get_instance_id()
	card["embarked_unit_ids"] = ["unit_bravo", "unit_charlie"]
	card["passenger_count"] = 2
	_apply_cards(controller, [card])
	waiting = _find_card(panel, "alpha")
	_assert(_info_text(waiting).contains("Passengers: 2") and _find_meta(waiting, "mission_dropship_passenger_unit_id", "unit_alpha") == null, "Changed payload removes only departed passenger visuals")
	_assert(_command(waiting, "drop").get_instance_id() == action_id, "Payload changes retain the craft's command buttons")
	card["state"] = "unloading"
	card["progress"] = 25.0
	_apply_cards(controller, [card])
	var unloading_ids: Array = _subtree_ids(_find_card(panel, "alpha"))
	card["progress"] = 66.0
	_apply_cards(controller, [card])
	var unloading_group: Node = _find_meta(_find_card(panel, "alpha"), "mission_dropship_fireteam_id", "blue")
	var deboard: ProgressBar = unloading_group.get_child(0).get_node("PassengerFireteamVBox/PassengerDeboardProgress")
	_assert(_subtree_ids(_find_card(panel, "alpha")) == unloading_ids and is_equal_approx(deboard.value, 66.0), "Deboarding progress updates the existing Fireteam bar without replacing payload nodes")
	card["state"] = "waiting"
	card["progress"] = 0.0
	_apply_cards(controller, [card])
	var beta := _card("beta", [])
	_apply_cards(controller, [beta, card], "beta")
	var beta_panel: Control = _find_card(panel, "beta")
	_assert(panel.get_child_count() == 2 and panel.get_child(0) == beta_panel and _find_card(panel, "alpha").get_instance_id() == unchanged_ids[0], "Adding and reordering crafts retains the existing keyed card")
	_assert(bool(beta_panel.get_meta("mission_dropship_selected")) and not bool(_find_card(panel, "alpha").get_meta("mission_dropship_selected")), "Selection styling follows the selected craft")
	var approach: Button = _command(_find_card(panel, "alpha"), "approach_se")
	for _refresh in range(3):
		controller._refresh_mission_dropship_panel()
	approach = _command(_find_card(panel, "alpha"), "approach_se")
	_assert(_handler_count(approach, controller, "_on_mission_dropship_card_approach_pressed") == 1, "Reused command button has exactly one action connection")
	approach.pressed.emit()
	_assert(controller.approach_actions == [["alpha", "SE"]], "Reused action invokes the original craft ID exactly once")
	_assert(String(controller.get_planning_state().mission_drop_craft_id) == "alpha" and bool(_command(_find_card(panel, "alpha"), "approach_se").get_meta("mission_dropship_card_command_active")), "Bound approach action updates selected craft and active approach feedback")
	controller.set("_pending_network_dropship_commands_by_craft", {"alpha": {"compact_line": "WAIT HOST"}})
	controller._refresh_mission_dropship_panel()
	_assert(_command(_find_card(panel, "alpha"), "drop").disabled and _find_card(panel, "alpha").find_child("MissionDropshipCardFeedbackLabel", true, false).text == "WAIT HOST", "Pending state updates feedback and locks only the affected craft")
	controller.set("_pending_network_dropship_commands_by_craft", {})
	_apply_cards(controller, [card])
	_assert(panel.get_child_count() == 1 and _find_card(panel, "beta") == null and _find_card(panel, "alpha").get_instance_id() == unchanged_ids[0], "Removing a craft discards only that craft's nodes")
	mission.queue_free()
	await process_frame
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _apply_cards(controller: Node, cards: Array, selected_id: String = "alpha") -> void:
	var state: Dictionary = controller.call("get_planning_state")
	state["mission_drop_cards"] = cards.duplicate(true)
	state["mission_drop_craft_id"] = selected_id
	for card in cards:
		if String(card.craft_id) == selected_id:
			state["has_lz_position"] = bool(card.get("has_lz_position", false))
			state["embarked_unit_ids"] = Array(card.get("embarked_unit_ids", [])).duplicate()
	controller.call("set_planning_state", state)


func _card(craft_id: String, payload: Array) -> Dictionary:
	return {"craft_id": craft_id, "display_name": craft_id, "state": "waiting", "progress": 0.0, "embarked_unit_ids": payload, "passenger_count": payload.size(), "boarded_fireteam_ids": ["blue"], "approach_angle": "NW", "has_lz_position": false}


func _find_card(panel: Node, craft_id: String) -> Control:
	for child in panel.get_children():
		if String(child.get_meta("mission_dropship_craft_id", "")) == craft_id:
			return child as Control
	return null


func _command(card: Node, action_id: String) -> Button:
	return _find_meta(card, "mission_dropship_card_command", action_id) as Button


func _handler_count(button: Button, controller: Node, method: String) -> int:
	var count: int = 0
	for connection in button.pressed.get_connections():
		var callback: Callable = connection.callable
		if callback.get_object() == controller and callback.get_method() == method:
			count += 1
	return count


func _find_meta(node: Node, key: String, value: String) -> Node:
	if String(node.get_meta(key, "")) == value:
		return node
	for child in node.get_children():
		var found: Node = _find_meta(child, key, value)
		if found != null:
			return found
	return null


func _subtree_ids(node: Node) -> Array:
	var ids: Array = [node.get_instance_id()]
	for child in node.get_children():
		ids.append_array(_subtree_ids(child))
	return ids


func _retained_count(before: Array, after: Array) -> int:
	var count: int = 0
	for instance_id in before:
		if after.has(instance_id):
			count += 1
	return count


func _info_text(card: Node) -> String:
	var lines: PackedStringArray = []
	for child in card.get_node(CARD_BODY + "ContentRow/InfoVBox/InfoLinesHost").get_children():
		lines.append(child.text)
	return " | ".join(lines)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		push_error("FAIL: " + message)
