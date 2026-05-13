extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_390 Homebase Direct Mission Transit Cards Verifier ===")
	await _test_homebase_direct_send_uses_live_mission_transit_card()
	await _test_homebase_direct_payload_stays_embarked_until_live_drop()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_390: FAILED")
		quit(1)
	else:
		print("TASK_390: ALL PASSED")
		quit(0)


func _test_homebase_direct_send_uses_live_mission_transit_card() -> void:
	var scene: Node = await _build_meta_scene()
	var homebase_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"])
	await _stage_homebase_direct_payload(scene, homebase_unit_ids, "ft_home", "dropship_alpha")

	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	var fob_screen: Control = scene.get_node("FOBScreen") as Control
	homebase_screen.call("request_mission_start")
	for _frame in range(6):
		await process_frame

	var active_mission: Node = scene.call("get_active_mission")
	var tactical_controller: Node = active_mission.get_node("TacticalController") if active_mission != null else null
	var initial_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state")) if tactical_controller != null else {}
	var pending_transfers: Array = Array(scene.get("_pending_mission_craft_transfers"))
	var mission_card := _get_mission_dropship_card(active_mission)
	var progress_bar := mission_card.get_node("MarginContainer/VBox/ProgressBar") as ProgressBar if mission_card != null else null
	var info_lines_host := mission_card.get_node("MarginContainer/VBox/ContentRow/InfoVBox/InfoLinesHost") as VBoxContainer if mission_card != null else null
	var status_label := info_lines_host.get_child(1) as Label if info_lines_host != null and info_lines_host.get_child_count() > 1 else null
	var passenger_group := _find_node_by_name(active_mission, "PassengerGroup_ft_home")
	var direct_craft_state: Dictionary = _find_craft_state(Array(scene.call("_build_transport_craft_states")), "dropship_alpha")

	_assert(active_mission != null and tactical_controller != null, "Homebase Direct Send opens a live mission controller")
	_assert(String(initial_state.get("mission_drop_source", "")).strip_edges() == "homebase_direct", "Homebase Direct Send records the Direct mission source")
	_assert(String(initial_state.get("mission_drop_state", "")).strip_edges() == "to_mission", "Homebase Direct Send starts as a to_mission transfer instead of waiting")
	_assert(_has_pending_mission_transfer(pending_transfers, "dropship_alpha", "to_mission", "homebase_direct"), "Direct Send creates a source-tagged to_mission craft transfer")
	_assert(mission_card != null and mission_card.visible and mission_card.modulate.a < 1.0, "Mission dropship card is greyed out while Direct dropship is en route")
	_assert(progress_bar != null and progress_bar.visible and progress_bar.value <= 1.0, "Mission dropship card shows the transit progress bar at launch")
	_assert(status_label != null and status_label.text.contains("ETA mission map"), "Mission dropship card reports mission-map ETA while en route")
	_assert(passenger_group != null, "Mission dropship card lists the embarked Direct fireteam payload")
	_assert(int(initial_state.get("mission_drop_passenger_count", 0)) == homebase_unit_ids.size(), "Mission planning keeps the Direct passenger count inside the dropship")
	_assert(bool(direct_craft_state.get("mission_transit_to_map", false)) and not bool(direct_craft_state.get("visible_in_fob", true)), "Direct transit craft stays out of FOB transport visibility")
	_assert(not _contains_any_id(fob_screen.call("get_team"), homebase_unit_ids), "Direct transit fireteam is not mirrored into FOB #10")

	for _step in range(5):
		scene.call("_on_homebase_transport_timer_timeout")
	for _frame in range(2):
		await process_frame
	var progress_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state"))
	_assert(float(progress_state.get("mission_drop_progress", 0.0)) > float(initial_state.get("mission_drop_progress", 0.0)), "Active mission receives Direct transit progress without another nav click")
	_assert(int(progress_state.get("mission_drop_eta_seconds", 0)) < int(initial_state.get("mission_drop_eta_seconds", 999)), "Active mission Direct transit ETA counts down")

	for _step in range(30):
		scene.call("_on_homebase_transport_timer_timeout")
	for _frame in range(4):
		await process_frame
	var waiting_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state"))
	mission_card = _get_mission_dropship_card(active_mission)
	progress_bar = mission_card.get_node("MarginContainer/VBox/ProgressBar") as ProgressBar if mission_card != null else null
	_assert(String(waiting_state.get("mission_drop_state", "")) == "waiting", "Direct dropship switches to waiting after the mission-map transfer completes")
	_assert(int(waiting_state.get("mission_drop_passenger_count", 0)) == homebase_unit_ids.size(), "Direct dropship still owns its passengers after arrival")
	_assert(mission_card != null and mission_card.modulate.a >= 0.99 and progress_bar != null and not progress_bar.visible, "Arrived Direct dropship card returns to full color without transit bar")

	scene.queue_free()
	await process_frame


func _test_homebase_direct_payload_stays_embarked_until_live_drop() -> void:
	var scene: Node = await _build_meta_scene()
	var homebase_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"])
	await _stage_homebase_direct_payload(scene, homebase_unit_ids, "ft_home", "dropship_alpha")

	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	homebase_screen.call("request_mission_start")
	for _step in range(30):
		scene.call("_on_homebase_transport_timer_timeout")
	for _frame in range(6):
		await process_frame

	var active_mission: Node = scene.call("get_active_mission")
	var tactical_controller: Node = active_mission.get_node("TacticalController") if active_mission != null else null
	var arrived_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state")) if tactical_controller != null else {}
	var inactive_fireteam_card := _get_fireteam_mini_card(active_mission, "ft_home")
	_assert(String(arrived_state.get("mission_drop_state", "")) == "waiting", "Direct dropship is waiting before the player calls the live drop")
	_assert(_ids_equal(arrived_state.get("embarked_unit_ids", []), homebase_unit_ids), "Direct payload remains embarked before live drop")
	_assert(Array(arrived_state.get("deployed_unit_ids", [])).is_empty(), "Direct payload is not deployed before the live drop")
	_assert(_collect_visible_friendly_unit_ids(active_mission).is_empty(), "Embarked Direct operators remain hidden on the mission map")
	_assert(inactive_fireteam_card != null and inactive_fireteam_card.modulate.a < 1.0, "Fireteam mini-card is present but inactive while its members are still in the dropship")

	arrived_state["has_lz_position"] = true
	arrived_state["lz_position"] = Vector2(320.0, 180.0)
	tactical_controller.call("set_planning_state", arrived_state)
	tactical_controller.call("_on_call_dropship_pressed")
	for _step in range(120):
		tactical_controller.call("_update_drop_sequence", 0.2)
		if String(tactical_controller.get("_drop_sequence_phase")) == "outbound":
			break
	for _frame in range(4):
		await process_frame

	var dropped_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state"))
	var dropped_card: Dictionary = _find_mission_drop_card(Array(dropped_state.get("mission_drop_cards", [])), "dropship_alpha")
	var active_fireteam_card := _get_fireteam_mini_card(active_mission, "ft_home")
	_assert(String(tactical_controller.get("_drop_sequence_phase")) == "outbound", "Direct dropship performs the live LZ drop after it reaches waiting state")
	_assert(Array(dropped_state.get("embarked_unit_ids", [])) == [], "Direct payload leaves the embarked set only after the live drop")
	_assert(_ids_equal(dropped_state.get("deployed_unit_ids", []), homebase_unit_ids), "Direct payload becomes deployed infantry after the live drop")
	_assert(int(dropped_state.get("mission_drop_passenger_count", -1)) == 0 and int(dropped_card.get("passenger_count", -1)) == 0, "Direct dropship card clears its passenger count after disembark")
	_assert(_collect_visible_friendly_unit_ids(active_mission) == _to_sorted_string_array(homebase_unit_ids), "Direct operators become visible on the mission map after disembark")
	_assert(active_fireteam_card != null and active_fireteam_card.modulate.a >= 0.99, "Fireteam mini-card becomes active once the Direct payload is on the ground")

	scene.queue_free()
	await process_frame


func _build_meta_scene() -> Node:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	return scene


func _stage_homebase_direct_payload(scene: Node, unit_ids: PackedStringArray, fireteam_id: String, craft_id: String) -> void:
	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var craft_definitions: Array = [
		{
			"craft_id": craft_id,
			"craft_type": "dropship",
			"display_name": "Homebase Dropship",
			"texture_path": DROPSHIP_TEXTURE_PATH,
			"supports_cargo": false,
			"cargo_options": [],
		}
	]
	var pilot_by_craft: Dictionary = _build_single_value_dictionary(craft_id, "unit_charlie")
	var location_by_craft: Dictionary = _build_single_value_dictionary(craft_id, "homebase")
	scene.set("_homebase_aircraft_definitions", craft_definitions.duplicate(true))
	scene.set("_assigned_aircraft_pilot_by_craft", pilot_by_craft.duplicate(true))
	scene.set("_aircraft_location_by_craft", location_by_craft.duplicate(true))
	homebase_screen.call("setup_roster", roster, unit_ids)
	homebase_screen.call(
		"set_fireteam_context",
		_repeat_fireteam_ids(unit_ids.size(), fireteam_id),
		[_build_fireteam_definition(fireteam_id, unit_ids)]
	)
	homebase_screen.call(
		"set_transport_state",
		craft_definitions,
		pilot_by_craft,
		[],
		[],
		location_by_craft,
		{},
		{},
		[]
	)
	homebase_screen.call("_on_homebase_shipcard_fireteam_dropped", fireteam_id, craft_id)
	var total_seconds: float = float(homebase_screen.call("_debug_get_homebase_fireteam_boarding_total_seconds", fireteam_id))
	homebase_screen.call("_debug_advance_homebase_direct_boarding", total_seconds + 0.1)
	await process_frame
	await process_frame


func _build_fireteam_definition(fireteam_id: String, unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": fireteam_id.to_upper(),
		"lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "",
		"loadout": "medium",
		"respawn_enabled": false,
	}


func _repeat_fireteam_ids(count: int, fireteam_id: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for _index in range(count):
		result.append(fireteam_id)
	return result


func _build_single_value_dictionary(key: String, value: String) -> Dictionary:
	var result: Dictionary = {}
	result[key] = value
	return result


func _get_mission_dropship_card(mission_instance: Node) -> PanelContainer:
	if mission_instance == null:
		return null
	var panel := mission_instance.get_node_or_null("TacticalUI/MissionDropshipPanel") as Control
	if panel == null:
		return null
	for child in panel.get_children():
		var card := child as PanelContainer
		if card != null and bool(card.get_meta("mission_dropship_card", false)):
			return card
	return null


func _get_fireteam_mini_card(mission_instance: Node, fireteam_id: String) -> Control:
	if mission_instance == null:
		return null
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var host := mission_instance.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox") as Control
	if host == null:
		return null
	for child in host.get_children():
		var control := child as Control
		if control != null and String(control.get_meta("fireteam_id", "")).strip_edges().to_lower() == normalized_fireteam_id:
			return control
	return null


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node == null:
		return null
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _find_craft_state(craft_states: Array, craft_id: String) -> Dictionary:
	for state_variant in craft_states:
		if typeof(state_variant) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = Dictionary(state_variant)
		if String(state.get("craft_id", "")).strip_edges() == craft_id:
			return state
	return {}


func _find_mission_drop_card(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == craft_id:
			return card
	return {}


func _has_pending_mission_transfer(transfers: Array, craft_id: String, phase: String, payload_source: String) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	var normalized_phase: String = phase.strip_edges().to_lower()
	var normalized_source: String = payload_source.strip_edges().to_lower()
	for transfer_variant in transfers:
		if typeof(transfer_variant) != TYPE_DICTIONARY:
			continue
		var transfer: Dictionary = Dictionary(transfer_variant)
		if String(transfer.get("craft_id", "")).strip_edges() != normalized_craft_id:
			continue
		if String(transfer.get("phase", "")).strip_edges().to_lower() != normalized_phase:
			continue
		if String(transfer.get("payload_source", "")).strip_edges().to_lower() != normalized_source:
			continue
		return true
	return false


func _collect_visible_friendly_unit_ids(mission_root: Node) -> Array:
	var result: Array = []
	if mission_root == null:
		return result
	for child in mission_root.get_children():
		if not child.has_method("get_team_id") or not child.has_method("get_unit_id"):
			continue
		if String(child.call("get_team_id")).strip_edges() != "team_alpha":
			continue
		if child is CanvasItem and not (child as CanvasItem).visible:
			continue
		result.append(String(child.call("get_unit_id")).strip_edges())
	result.sort()
	return result


func _to_sorted_string_array(values: PackedStringArray) -> Array:
	var result: Array = []
	for value in values:
		result.append(String(value).strip_edges())
	result.sort()
	return result


func _ids_equal(value: Variant, expected: PackedStringArray) -> bool:
	var actual := PackedStringArray(Array(value))
	if actual.size() != expected.size():
		return false
	for index in range(actual.size()):
		if String(actual[index]) != String(expected[index]):
			return false
	return true


func _contains_any_id(value: Variant, ids: PackedStringArray) -> bool:
	var actual := PackedStringArray(Array(value))
	for id_variant in ids:
		if actual.has(String(id_variant)):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
