extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_394 Per Craft Shipcard Commands Verifier ===")
	await _test_homebase_shipcards_board_and_send_independently()
	await _test_mission_dropship_card_commands_are_craft_bound()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_394: FAILED")
		quit(1)
	else:
		print("TASK_394: ALL PASSED")
		quit(0)


func _test_homebase_shipcards_board_and_send_independently() -> void:
	var scene: Node = await _build_two_dropship_meta_scene()
	var homebase_screen := scene.get_node("HomebaseScreen") as Control

	_drop_fireteam_on_shipcard(homebase_screen, "ft1", "dropship_alpha")
	_drop_fireteam_on_shipcard(homebase_screen, "ft2", "dropship_beta")
	homebase_screen.call("_debug_advance_homebase_direct_boarding", 0.5)
	await _wait_frames(3)

	var alpha_payload_card := _find_homebase_payload_fireteam_card(homebase_screen, "ft1", "dropship_alpha")
	var beta_payload_card := _find_homebase_payload_fireteam_card(homebase_screen, "ft2", "dropship_beta")
	_assert(alpha_payload_card != null and beta_payload_card != null, "Two Homebase Dropships accept fireteams immediately without waiting for boarding completion")
	_assert(float(alpha_payload_card.get_meta("homebase_direct_payload_boarding_progress", 0.0)) > 0.0 and float(beta_payload_card.get_meta("homebase_direct_payload_boarding_progress", 0.0)) > 0.0, "Both fireteams start boarding in parallel")

	homebase_screen.call("_debug_advance_homebase_direct_boarding", 80.0)
	await _wait_frames(3)
	var alpha_send := _find_homebase_shipcard_send_button(homebase_screen, "dropship_alpha")
	var beta_send := _find_homebase_shipcard_send_button(homebase_screen, "dropship_beta")
	_assert(alpha_send != null and beta_send != null and not alpha_send.disabled and not beta_send.disabled, "Both shipcard Send buttons are independently enabled after their own boarding completes")
	if alpha_send != null:
		alpha_send.emit_signal("pressed")
	await _wait_frames(6)
	var alpha_transit_card := _find_homebase_shipcard(homebase_screen, "dropship_alpha")
	var refreshed_beta_send := _find_homebase_shipcard_send_button(homebase_screen, "dropship_beta")
	_assert(alpha_transit_card != null and bool(alpha_transit_card.get_meta("homebase_shipcard_in_transit", false)), "First sent Homebase shipcard greys out while second ship remains visible")
	_assert(refreshed_beta_send != null and not refreshed_beta_send.disabled, "Second shipcard Send stays clickable after the first ship launches")
	if refreshed_beta_send != null:
		refreshed_beta_send.emit_signal("pressed")
	await _wait_frames(6)
	for _step in range(3):
		scene.call("_on_homebase_transport_timer_timeout")
	await _wait_frames(4)

	var active_mission: Node = scene.call("get_active_mission")
	var controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state")) if controller != null else {}
	var alpha_card: Dictionary = _find_card(Array(planning_state.get("mission_drop_cards", [])), "dropship_alpha")
	var beta_card: Dictionary = _find_card(Array(planning_state.get("mission_drop_cards", [])), "dropship_beta")
	var alpha_homebase_card := _find_homebase_shipcard(homebase_screen, "dropship_alpha")
	var beta_homebase_card := _find_homebase_shipcard(homebase_screen, "dropship_beta")
	_assert(active_mission != null and controller != null, "Shipcard Send starts or updates the live mission in the background")
	_assert(alpha_homebase_card != null and beta_homebase_card != null and bool(alpha_homebase_card.get_meta("homebase_shipcard_in_transit", false)) and bool(beta_homebase_card.get_meta("homebase_shipcard_in_transit", false)), "Both sent Homebase shipcards stay greyed in transit")
	_assert(String(alpha_card.get("state", "")) == "to_mission" and String(beta_card.get("state", "")) == "to_mission", "Both Direct transfers remain separate to_mission cards")
	_assert(float(alpha_card.get("progress", 0.0)) > 0.0 and float(beta_card.get("progress", 0.0)) > 0.0, "Both Direct transfer progress bars advance independently")

	scene.queue_free()
	await _wait_frames(2)


func _test_mission_dropship_card_commands_are_craft_bound() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(6)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes tactical controller for card-bound command checks")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_craft_id"] = "dropship_alpha"
	planning_state["mission_drop_state"] = "waiting"
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(320.0, 180.0)
	planning_state["deployed_unit_ids"] = []
	planning_state["deployed_unit_positions"] = {}
	planning_state["mission_drop_cards"] = [
		{
			"craft_id": "dropship_alpha",
			"display_name": "Dropship Alpha",
			"state": "waiting",
			"progress": 100.0,
			"embarked_unit_ids": ["unit_alpha", "unit_bravo"],
			"boarded_fireteam_ids": ["blue"],
			"has_lz_position": true,
			"lz_position": Vector2(320.0, 180.0),
			"approach_angle": "NW",
		},
		{
			"craft_id": "dropship_beta",
			"display_name": "Dropship Beta",
			"state": "waiting",
			"progress": 100.0,
			"embarked_unit_ids": ["unit_charlie", "unit_delta"],
			"boarded_fireteam_ids": ["blue"],
			"has_lz_position": true,
			"lz_position": Vector2(704.0, 352.0),
			"approach_angle": "SE",
		},
	]
	controller.call("set_planning_state", planning_state)
	await _wait_frames(6)

	var beta_approach_button := _find_mission_card_command(scene, "dropship_beta", "approach_sw")
	_assert(beta_approach_button != null and not beta_approach_button.disabled, "Dropship Beta card exposes its own Approach command")
	if beta_approach_button != null:
		beta_approach_button.emit_signal("pressed")
	await _wait_frames(3)
	var approach_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var alpha_after_approach: Dictionary = _find_card(Array(approach_state.get("mission_drop_cards", [])), "dropship_alpha")
	var beta_after_approach: Dictionary = _find_card(Array(approach_state.get("mission_drop_cards", [])), "dropship_beta")
	_assert(String(beta_after_approach.get("approach_angle", "")) == "SW" and String(alpha_after_approach.get("approach_angle", "")) == "NW", "Card Approach command changes only the owning Dropship")
	_assert(_legacy_mission_control_commands_are_hidden(scene), "#18 Mission Control hides legacy LZ/Drop/Approach controls while shipcards own them")

	var alpha_lz_button := _find_mission_card_command(scene, "dropship_alpha", "set_lz")
	_assert(alpha_lz_button != null and not alpha_lz_button.disabled, "Dropship Alpha card exposes its own LZ command")
	if alpha_lz_button != null:
		alpha_lz_button.emit_signal("pressed")
	await _wait_frames(2)
	_assert(String(controller.get("_lz_placement_craft_id")) == "dropship_alpha", "Card LZ command arms placement for the owning craft")

	var alpha_drop_button := _find_mission_card_command(scene, "dropship_alpha", "drop")
	_assert(alpha_drop_button != null and not alpha_drop_button.disabled, "Dropship Alpha card exposes its own Drop command")
	if alpha_drop_button != null:
		alpha_drop_button.emit_signal("pressed")
	await _wait_frames(3)
	_assert(String(controller.get("_drop_sequence_craft_id")) == "dropship_alpha" and String(controller.get("_drop_sequence_phase")) == "inbound", "Alpha card Drop starts Alpha inbound")

	var beta_drop_button := _find_mission_card_command(scene, "dropship_beta", "drop")
	_assert(beta_drop_button != null and not beta_drop_button.disabled, "Dropship Beta card stays commandable while Alpha is inbound")
	if beta_drop_button != null:
		beta_drop_button.emit_signal("pressed")
	await _wait_frames(3)
	var parallel_sequences: Dictionary = Dictionary(controller.get("_parallel_drop_sequences_by_craft"))
	var after_drop_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var alpha_after_drop: Dictionary = _find_card(Array(after_drop_state.get("mission_drop_cards", [])), "dropship_alpha")
	var beta_after_drop: Dictionary = _find_card(Array(after_drop_state.get("mission_drop_cards", [])), "dropship_beta")
	_assert(parallel_sequences.has("dropship_alpha") and String(controller.get("_drop_sequence_craft_id")) == "dropship_beta", "Beta card Drop starts without cancelling Alpha inbound")
	_assert(String(alpha_after_drop.get("state", "")) == "inbound" and String(beta_after_drop.get("state", "")) == "inbound", "Both Dropships hold independent inbound states after card Drop commands")

	scene.queue_free()
	await _wait_frames(2)


func _build_two_dropship_meta_scene() -> Node:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)
	var homebase_screen := scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var craft_definitions: Array = [_build_dropship_definition("dropship_alpha", "Dropship Alpha"), _build_dropship_definition("dropship_beta", "Dropship Beta")]
	var pilot_by_craft := {"dropship_alpha": "unit_echo", "dropship_beta": "unit_foxtrot"}
	var location_by_craft := {"dropship_alpha": "homebase", "dropship_beta": "homebase"}
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	scene.set("_homebase_aircraft_definitions", craft_definitions.duplicate(true))
	scene.set("_assigned_aircraft_pilot_by_craft", pilot_by_craft.duplicate(true))
	scene.set("_aircraft_location_by_craft", location_by_craft.duplicate(true))
	homebase_screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
	homebase_screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft2", "ft2"]),
		[
			_build_fireteam_definition("ft1", "ALPHA", PackedStringArray(["unit_alpha", "unit_bravo"])),
			_build_fireteam_definition("ft2", "BRAVO", PackedStringArray(["unit_charlie", "unit_delta"])),
		]
	)
	homebase_screen.call("set_transport_state", craft_definitions, pilot_by_craft, [], [], location_by_craft, {}, {}, [])
	await _wait_frames(3)
	return scene


func _drop_fireteam_on_shipcard(screen: Control, fireteam_id: String, craft_id: String) -> void:
	var target := _find_shipcard_drop_target(screen, craft_id)
	if target == null:
		return
	target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id})


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	if screen == null:
		return null
	for node in _collect_nodes(screen):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("homebase_fireteam_drop_target", false)) \
			and bool(control.get_meta("homebase_fireteam_drop_enabled", false)) \
			and String(control.get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return control
	return null


func _find_homebase_payload_fireteam_card(screen: Control, fireteam_id: String, craft_id: String) -> Control:
	if screen == null:
		return null
	for node in _collect_nodes(screen):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("homebase_shipcard_payload_fireteam_card", false)) \
			and String(control.get_meta("fireteam_id", "")).strip_edges() == fireteam_id \
			and String(control.get_meta("craft_id", "")).strip_edges() == craft_id:
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


func _find_homebase_shipcard_send_button(screen: Control, craft_id: String) -> Button:
	var shipcard := _find_homebase_shipcard(screen, craft_id)
	if shipcard == null:
		return null
	for node in _collect_nodes(shipcard):
		var button := node as Button
		if button != null and String(button.name) == "ShipSendButton" and String(button.get_meta("craft_id", "")).strip_edges() == craft_id:
			return button
	return null


func _find_mission_card_command(scene: Node, craft_id: String, command_id: String) -> Button:
	if scene == null:
		return null
	for node in _collect_nodes(scene):
		var button := node as Button
		if button != null \
			and bool(button.get_meta("mission_dropship_card_command_button", false)) \
			and String(button.get_meta("mission_dropship_craft_id", "")).strip_edges() == craft_id \
			and String(button.get_meta("mission_dropship_card_command", "")).strip_edges() == command_id:
			return button
	return null


func _find_card(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == craft_id:
			return card
	return {}


func _legacy_mission_control_commands_are_hidden(scene: Node) -> bool:
	for path in [
		"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton",
		"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton",
		"TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid",
	]:
		var control := scene.get_node_or_null(path) as Control
		if control == null or control.is_visible_in_tree():
			return false
	return true


func _build_dropship_definition(craft_id: String, display_name: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"craft_type": "dropship",
		"capacity": 8,
		"crew_capacity": 1,
		"cargo_capacity": 1,
		"texture_path": DROPSHIP_TEXTURE_PATH,
	}


func _build_fireteam_definition(fireteam_id: String, label: String, member_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": label,
		"lead_unit_id": String(member_ids[0]) if not member_ids.is_empty() else "",
		"member_unit_ids": Array(member_ids),
		"loadout": "medium",
		"respawn_enabled": false,
	}


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
