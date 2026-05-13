extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_392 Parallel Boarding Transit Feedback Verifier ===")
	await _test_homebase_allows_parallel_dropship_boarding()
	await _test_direct_transit_greys_homebase_and_mission_until_arrival()
	await _test_mission_lz_inbound_is_accessible_and_deboarding_reports_on_cards()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_392: FAILED")
		quit(1)
	else:
		print("TASK_392: ALL PASSED")
		quit(0)


func _test_homebase_allows_parallel_dropship_boarding() -> void:
	var screen: Control = await _build_two_dropship_homebase_screen()
	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	screen.call("_debug_advance_homebase_direct_boarding", 0.6)
	await process_frame
	await process_frame

	_drop_fireteam_on_shipcard(screen, "ft2", "dropship_beta")
	screen.call("_debug_advance_homebase_direct_boarding", 0.6)
	await process_frame
	await process_frame

	var alpha_card := _find_homebase_payload_fireteam_card(screen, "ft1", "dropship_alpha")
	var beta_card := _find_homebase_payload_fireteam_card(screen, "ft2", "dropship_beta")
	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	var payload_by_craft: Dictionary = Dictionary(snapshot.get("payload_fireteam_ids_by_craft", {}))
	_assert(alpha_card != null and beta_card != null, "Two Dropships can keep separate Fireteam payload cards at the same time")
	_assert(float(alpha_card.get_meta("homebase_direct_payload_boarding_progress", 0.0)) > 0.0, "First Dropship keeps boarding progress while another craft receives a Fireteam")
	_assert(float(beta_card.get_meta("homebase_direct_payload_boarding_progress", 0.0)) > 0.0, "Second Dropship starts boarding immediately instead of waiting for the first craft")
	_assert(Array(payload_by_craft.get("dropship_alpha", [])).has("ft1") and Array(payload_by_craft.get("dropship_beta", [])).has("ft2"), "Direct payload truth remains per Dropship during parallel boarding")
	_assert(_find_homebase_fireteam_panel_card(screen, "ft1") == null and _find_homebase_fireteam_panel_card(screen, "ft2") == null, "Boarding Fireteams do not jump back to #10 while another Dropship is active")

	screen.queue_free()
	await process_frame


func _test_direct_transit_greys_homebase_and_mission_until_arrival() -> void:
	var scene: Node = await _build_meta_scene()
	await _stage_homebase_direct_payload(scene, PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"]), "ft_home", "dropship_alpha")
	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	homebase_screen.call("request_mission_start")
	for _frame in range(6):
		await process_frame

	var active_mission: Node = scene.call("get_active_mission")
	var mission_card := _find_mission_dropship_card(active_mission, "dropship_alpha")
	var homebase_shipcard := _find_homebase_shipcard(homebase_screen, "dropship_alpha")
	var homebase_progress := _find_node_with_meta(homebase_shipcard, "homebase_shipcard_transfer_progress") as ProgressBar
	var mission_progress := mission_card.get_node_or_null("MarginContainer/VBox/ProgressBar") as ProgressBar if mission_card != null else null
	_assert(homebase_shipcard != null and homebase_shipcard.modulate.a < 1.0 and bool(homebase_shipcard.get_meta("homebase_shipcard_in_transit", false)), "Homebase Flightdeck keeps the sent Dropship greyed while it flies to Mission")
	_assert(homebase_progress != null and homebase_progress.visible and homebase_progress.value <= 1.0, "Homebase Flightdeck sent Dropship shows transit progress")
	_assert(mission_card != null and mission_card.modulate.a < 1.0 and bool(mission_card.get_meta("mission_dropship_card_inaccessible", false)), "Mission Dropship card is greyed only while Direct transit is inaccessible")
	_assert(mission_progress != null and mission_progress.visible, "Mission Dropship card shows the Direct transit progress bar")

	for _step in range(30):
		scene.call("_on_homebase_transport_timer_timeout")
	for _frame in range(6):
		await process_frame

	mission_card = _find_mission_dropship_card(active_mission, "dropship_alpha")
	homebase_shipcard = _find_homebase_shipcard(homebase_screen, "dropship_alpha")
	var tactical_controller: Node = active_mission.get_node("TacticalController") if active_mission != null else null
	var planning_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state")) if tactical_controller != null else {}
	_assert(String(planning_state.get("mission_drop_state", "")) == "waiting", "Direct Dropship arrives on the Mission after the transit timer")
	_assert(homebase_shipcard == null, "Arrived Direct Dropship disappears from Homebase Flightdeck")
	_assert(mission_card != null and mission_card.modulate.a >= 0.99 and bool(mission_card.get_meta("mission_dropship_card_accessible", false)), "Arrived Mission Dropship card is full color and accessible")

	scene.queue_free()
	await process_frame


func _test_mission_lz_inbound_is_accessible_and_deboarding_reports_on_cards() -> void:
	var scene: Node = await _build_meta_scene()
	await _stage_homebase_direct_payload(scene, PackedStringArray(["unit_alpha", "unit_bravo", "unit_delta"]), "ft_home", "dropship_alpha")
	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	homebase_screen.call("request_mission_start")
	for _step in range(30):
		scene.call("_on_homebase_transport_timer_timeout")
	for _frame in range(6):
		await process_frame

	var active_mission: Node = scene.call("get_active_mission")
	var tactical_controller: Node = active_mission.get_node("TacticalController") if active_mission != null else null
	var arrived_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state"))
	arrived_state["has_lz_position"] = true
	arrived_state["lz_position"] = Vector2(320.0, 180.0)
	tactical_controller.call("set_planning_state", arrived_state)
	tactical_controller.call("_on_call_dropship_pressed")
	await process_frame

	var inbound_card := _find_mission_dropship_card(active_mission, "dropship_alpha")
	var payload_group := _find_node_by_name(inbound_card, "PassengerGroup_ft_home") as Control
	_assert(String(tactical_controller.get("_drop_sequence_phase")) == "inbound", "Mission LZ call starts the Dropship inbound sequence")
	_assert(inbound_card != null and inbound_card.modulate.a >= 0.99 and bool(inbound_card.get_meta("mission_dropship_card_accessible", false)), "LZ inbound Dropship stays accessible because it is on the map")
	_assert(payload_group != null and bool(payload_group.get_meta("mission_dropship_fireteam_payload_card", false)), "Mission Dropship card keeps the embarked Fireteam payload card")
	_assert(_count_nodes_with_meta(payload_group, "mission_dropship_passenger_portrait") >= 3, "Mission payload Fireteam card shows mini portraits for embarked members")

	for _step in range(180):
		tactical_controller.call("_update_drop_sequence", 0.2)
		if String(tactical_controller.get("_drop_sequence_phase")) == "unloading":
			break
	await process_frame
	var unloading_card := _find_mission_dropship_card(active_mission, "dropship_alpha")
	var unloading_progress := unloading_card.get_node_or_null("MarginContainer/VBox/ProgressBar") as ProgressBar if unloading_card != null else null
	_assert(String(tactical_controller.get("_drop_sequence_phase")) == "unloading", "Dropship enters a timed Deboarding state after Touchdown")
	_assert(unloading_card != null and unloading_card.modulate.a >= 0.99, "Deboarding Dropship card is not greyed because the craft is present on the map")
	_assert(unloading_progress != null and unloading_progress.visible, "Deboarding shows a progress bar on the Dropship card")
	_assert(_find_node_by_name(unloading_card, "MissionDropshipCardFeedbackLabel") != null, "Touchdown feedback is shown on the Dropship card")

	for _step in range(80):
		tactical_controller.call("_update_drop_sequence", 0.2)
		if String(tactical_controller.get("_drop_sequence_phase")) == "outbound":
			break
	await process_frame
	var outbound_card := _find_mission_dropship_card(active_mission, "dropship_alpha")
	var trupp_ab_label := _find_text_label(outbound_card, "Trupp ab")
	var dropped_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state"))
	_assert(String(tactical_controller.get("_drop_sequence_phase")) == "outbound", "Dropship leaves after the timed Deboarding completes")
	_assert(trupp_ab_label != null, "Fireteam/Dropship card feedback reports Trupp ab after all infantry disembark")
	_assert(Array(dropped_state.get("embarked_unit_ids", [])).is_empty(), "Deboarding clears embarked unit truth only after the drop completes")

	scene.queue_free()
	await process_frame


func _build_two_dropship_homebase_screen() -> Control:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("set_mission_context", [], "res://maps/Ground_Mission01_32x32.json", "Task 392", 5, "task_392")
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft2", "ft2"]),
		[
			_build_fireteam_definition("ft1", "ALPHA", PackedStringArray(["unit_alpha", "unit_bravo"])),
			_build_fireteam_definition("ft2", "BRAVO", PackedStringArray(["unit_charlie", "unit_delta"])),
		]
	)
	screen.call(
		"set_transport_state",
		[_build_dropship_definition("dropship_alpha", "Dropship Alpha"), _build_dropship_definition("dropship_beta", "Dropship Beta")],
		{"dropship_alpha": "unit_echo", "dropship_beta": "unit_foxtrot"},
		[],
		[],
		{"dropship_alpha": "homebase", "dropship_beta": "homebase"},
		{},
		{},
		[]
	)
	await process_frame
	await process_frame
	return screen


func _build_meta_scene() -> Node:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(4):
		await process_frame
	return scene


func _stage_homebase_direct_payload(scene: Node, unit_ids: PackedStringArray, fireteam_id: String, craft_id: String) -> void:
	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var craft_definitions: Array = [_build_dropship_definition(craft_id, "Homebase Dropship")]
	var pilot_by_craft: Dictionary = {}
	pilot_by_craft[craft_id] = "unit_charlie"
	var location_by_craft: Dictionary = {}
	location_by_craft[craft_id] = "homebase"
	scene.set("_homebase_aircraft_definitions", craft_definitions.duplicate(true))
	scene.set("_assigned_aircraft_pilot_by_craft", pilot_by_craft.duplicate(true))
	scene.set("_aircraft_location_by_craft", location_by_craft.duplicate(true))
	homebase_screen.call("setup_roster", roster, unit_ids)
	homebase_screen.call("set_fireteam_context", _repeat_fireteam_ids(unit_ids.size(), fireteam_id), [_build_fireteam_definition(fireteam_id, fireteam_id.to_upper(), unit_ids)])
	homebase_screen.call("set_transport_state", craft_definitions, pilot_by_craft, [], [], location_by_craft, {}, {}, [])
	homebase_screen.call("_on_homebase_shipcard_fireteam_dropped", fireteam_id, craft_id)
	var total_seconds: float = float(homebase_screen.call("_debug_get_homebase_fireteam_boarding_total_seconds", fireteam_id))
	homebase_screen.call("_debug_advance_homebase_direct_boarding", total_seconds + 0.2)
	for _frame in range(3):
		await process_frame


func _build_fireteam_definition(fireteam_id: String, label: String, unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": label,
		"lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "",
		"loadout": "medium",
		"respawn_enabled": false,
	}


func _build_dropship_definition(craft_id: String, display_name: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"craft_type": "dropship",
		"display_name": display_name,
		"texture_path": DROPSHIP_TEXTURE_PATH,
		"supports_cargo": false,
		"cargo_options": [],
	}


func _repeat_fireteam_ids(count: int, fireteam_id: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for _index in range(count):
		result.append(fireteam_id)
	return result


func _drop_fireteam_on_shipcard(screen: Control, fireteam_id: String, craft_id: String) -> void:
	var target := _find_shipcard_drop_target(screen, craft_id)
	if target == null:
		return
	target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id, "source_context": "fireteam_list"})


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	if aircraft_panel == null:
		return null
	for node in _collect_nodes(aircraft_panel):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("homebase_fireteam_drop_target", false)) \
			and bool(control.get_meta("homebase_fireteam_drop_enabled", false)) \
			and String(control.get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return control
	return null


func _find_homebase_shipcard(screen: Control, craft_id: String) -> PanelContainer:
	if screen == null:
		return null
	for node in _collect_nodes(screen):
		var panel := node as PanelContainer
		if panel != null and bool(panel.get_meta("homebase_shipcard", false)) and String(panel.get_meta("craft_id", "")).strip_edges() == craft_id:
			return panel
	return null


func _find_homebase_payload_fireteam_card(screen: Control, fireteam_id: String, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	if aircraft_panel == null:
		return null
	for node in _collect_nodes(aircraft_panel):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("homebase_shipcard_payload_fireteam_card", false)) \
			and String(control.get_meta("fireteam_id", "")).strip_edges() == fireteam_id \
			and String(control.get_meta("craft_id", "")).strip_edges() == craft_id:
			return control
	return null


func _find_homebase_fireteam_panel_card(screen: Control, fireteam_id: String) -> Control:
	var list := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList") as VBoxContainer
	if list == null:
		return null
	for child in list.get_children():
		if child.has_method("get_fireteam_id") and String(child.call("get_fireteam_id")).strip_edges() == fireteam_id:
			return child as Control
	return null


func _find_mission_dropship_card(mission_root: Node, craft_id: String) -> PanelContainer:
	if mission_root == null:
		return null
	var panel := mission_root.get_node_or_null("TacticalUI/MissionDropshipPanel") as Control
	if panel == null:
		return null
	for child in panel.get_children():
		var card := child as PanelContainer
		if card != null and bool(card.get_meta("mission_dropship_card", false)) and String(card.get_meta("mission_dropship_craft_id", "")).strip_edges() == craft_id:
			return card
	return null


func _find_node_with_meta(root_node: Node, meta_key: String) -> Node:
	if root_node == null:
		return null
	if root_node.has_meta(meta_key):
		return root_node
	for child in root_node.get_children():
		var found := _find_node_with_meta(child, meta_key)
		if found != null:
			return found
	return null


func _find_node_by_name(root_node: Node, target_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == target_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _find_text_label(root_node: Node, expected_text: String) -> Label:
	if root_node == null:
		return null
	var label := root_node as Label
	if label != null and label.text == expected_text:
		return label
	for child in root_node.get_children():
		var found := _find_text_label(child, expected_text)
		if found != null:
			return found
	return null


func _count_nodes_with_meta(root_node: Node, meta_key: String) -> int:
	var count := 0
	for node in _collect_nodes(root_node):
		if node.has_meta(meta_key):
			count += 1
	return count


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
