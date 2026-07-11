extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const SELECTED_ROW_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow"
const MINI_HOST_PATH := "TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1109 Multi-Dropship Fireteam Selection HUD Consistency ===")
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	await _wait_frames(5)
	var controller := mission.get_node("TacticalController")
	var simulation := mission.get_node("SimulationRoot")
	var blue_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "blue", true)))
	var gold_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "gold", true)))
	_assert(not blue_ids.is_empty() and not gold_ids.is_empty(), "Mission fixture exposes Blue and Gold Fireteams")
	controller.call("set_planning_state", _build_two_embarked_state(controller, blue_ids, gold_ids))
	await _wait_frames(8)

	_assert(_selected_surface_is_hint(mission, "blue"), "Blue starts selected with Dropship hint")
	_assert(_both_absent_from_ground_mini(mission), "Both parallel embarked Fireteams stay out of ground mini cards")
	_assert(_payload_card_is_interactive(mission, "blue") and _payload_card_is_interactive(mission, "gold"), "Both Dropship Fireteam payload cards expose selection input")
	_assert(controller.has_method("select_mission_dropship_fireteam"), "Controller exposes a craft-bound Fireteam selection entrypoint")
	if controller.has_method("select_mission_dropship_fireteam"):
		_assert(bool(controller.call("select_mission_dropship_fireteam", "dropship_gold", "gold")), "Gold payload card selects its craft and Fireteam")
		await _wait_frames(4)
		_assert(String(controller.get("_mission_drop_craft_id")) == "dropship_gold", "Gold selection switches Mission Control craft")
		_assert(_selected_surface_is_hint(mission, "gold"), "Gold selection shows Gold Dropship hint")
		_assert(_both_absent_from_ground_mini(mission), "Selecting Gold does not turn Blue into a ground Fireteam")
		_assert(bool(controller.call("select_mission_dropship_fireteam", "dropship_blue", "blue")), "Blue payload card can be selected again")
		await _wait_frames(4)
		_assert(_selected_surface_is_hint(mission, "blue"), "Blue selection restores Blue Dropship hint")
		_assert(_both_absent_from_ground_mini(mission), "Selecting Blue does not turn Gold into a ground Fireteam")

		var mixed_state: Dictionary = _build_mixed_state(controller, blue_ids, gold_ids)
		controller.call("set_planning_state", mixed_state)
		await _wait_frames(8)
		_assert(_selected_surface_has_member_cards(mission, "blue", blue_ids.size()), "Deboarded Blue selection shows Blue member cards")
		_assert(_mini_ids(mission).has("blue") and not _mini_ids(mission).has("gold"), "Ground mini cards show deployed Blue but hide embarked Gold")
		_assert(bool(controller.call("select_mission_dropship_fireteam", "dropship_gold", "gold")), "Mixed-state Gold payload remains selectable")
		await _wait_frames(4)
		_assert(_selected_surface_is_hint(mission, "gold"), "Mixed-state Gold still shows Dropship hint")
		_assert(_mini_ids(mission).has("blue") and not _mini_ids(mission).has("gold"), "Gold selection preserves Blue ground and Gold embarked truth")

	_assert(Array(simulation.get("command_queue")).is_empty() and Array(simulation.get("effects_queue")).is_empty(), "HUD selection creates no simulation commands or effects")
	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _build_two_embarked_state(controller: Node, blue_ids: Array, gold_ids: Array) -> Dictionary:
	var state: Dictionary = Dictionary(controller.call("get_planning_state"))
	state["mission_drop_craft_id"] = "dropship_blue"
	state["mission_drop_state"] = "waiting"
	state["embarked_unit_ids"] = blue_ids + gold_ids
	state["deployed_unit_ids"] = []
	state["deployed_unit_positions"] = {}
	state["selected_fireteams"] = ["blue"]
	state["mission_drop_cards"] = [
		_card("dropship_blue", "Blue Lift", "blue", blue_ids, "waiting", ""),
		_card("dropship_gold", "Gold Lift", "gold", gold_ids, "waiting", ""),
	]
	return state


func _build_mixed_state(controller: Node, blue_ids: Array, gold_ids: Array) -> Dictionary:
	var state: Dictionary = Dictionary(controller.call("get_planning_state"))
	state["mission_drop_craft_id"] = "dropship_blue"
	state["mission_drop_state"] = "outbound"
	state["embarked_unit_ids"] = gold_ids.duplicate()
	state["deployed_unit_ids"] = blue_ids.duplicate()
	state["deployed_unit_positions"] = _positions(blue_ids, Vector2(320.0, 180.0))
	state["selected_fireteams"] = ["blue"]
	state["mission_drop_cards"] = [
		_card("dropship_blue", "Blue Lift", "blue", [], "outbound", "Trupp ab"),
		_card("dropship_gold", "Gold Lift", "gold", gold_ids, "waiting", ""),
	]
	return state


func _card(craft_id: String, display_name: String, fireteam_id: String, payload: Array, state: String, feedback: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"title_text": "#19 %s" % display_name,
		"state": state,
		"progress": 100.0,
		"passenger_count": payload.size(),
		"embarked_unit_ids": payload.duplicate(),
		"boarded_fireteam_ids": [fireteam_id],
		"has_lz_position": true,
		"lz_position": Vector2(320.0, 180.0),
		"approach_angle": "NW",
		"card_feedback_text": feedback,
	}


func _selected_surface_is_hint(mission: Node, fireteam_id: String) -> bool:
	var row := mission.get_node(SELECTED_ROW_PATH) as HBoxContainer
	return String(row.get_meta("selected_member_cards_fireteam_id", "")).strip_edges().to_lower() == fireteam_id \
		and row.get_child_count() == 1 and row.get_child(0) is Label \
		and String((row.get_child(0) as Label).text) == "Fireteam im Dropship."


func _selected_surface_has_member_cards(mission: Node, fireteam_id: String, expected_count: int) -> bool:
	var row := mission.get_node(SELECTED_ROW_PATH) as HBoxContainer
	if String(row.get_meta("selected_member_cards_fireteam_id", "")).strip_edges().to_lower() != fireteam_id:
		return false
	var count := 0
	for child in row.get_children():
		if not child is Label:
			count += 1
	return count >= expected_count


func _both_absent_from_ground_mini(mission: Node) -> bool:
	var ids := _mini_ids(mission)
	return not ids.has("blue") and not ids.has("gold")


func _mini_ids(mission: Node) -> PackedStringArray:
	var result := PackedStringArray()
	var host := mission.get_node(MINI_HOST_PATH) as VBoxContainer
	for child_variant in host.get_children():
		var child := child_variant as Control
		if child == null:
			continue
		var fireteam_id: String = String(child.get_meta("fireteam_id", "")).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			result.append(fireteam_id)
	return result


func _payload_card_is_interactive(mission: Node, fireteam_id: String) -> bool:
	for node in _collect_tree(mission):
		var control := node as Control
		if control == null or not bool(control.get_meta("mission_dropship_fireteam_payload_card", false)):
			continue
		if String(control.get_meta("mission_dropship_fireteam_id", "")).strip_edges().to_lower() != fireteam_id:
			continue
		return control.mouse_filter == Control.MOUSE_FILTER_STOP and control.focus_mode == Control.FOCUS_ALL and not control.gui_input.get_connections().is_empty()
	return false


func _collect_tree(node: Node) -> Array:
	var result: Array = [node]
	for child in node.get_children():
		result.append_array(_collect_tree(child))
	return result


func _unit_ids(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")))
	return result


func _positions(unit_ids: Array, origin: Vector2) -> Dictionary:
	var result := {}
	for index in range(unit_ids.size()):
		result[String(unit_ids[index])] = origin + Vector2(float(index) * 20.0, float(index) * 10.0)
	return result


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
