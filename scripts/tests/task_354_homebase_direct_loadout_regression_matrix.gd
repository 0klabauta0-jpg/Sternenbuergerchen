extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const PAYLOAD_UNIT_IDS := ["unit_alpha", "unit_bravo"]
const HOMEBASE_TEAM_UNIT_IDS := ["unit_alpha", "unit_bravo", "unit_delta"]
const FOB_UNIT_IDS := ["unit_echo", "unit_foxtrot"]
const FOB_FIRETEAM_ID := "ft2"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_354 Homebase Direct Loadout Regression Matrix ===")
	await _test_homebase_drop_state_scope_defaults_and_dropdown_path()
	await _test_homebase_direct_mission_setup_modifiers_matrix()
	await _test_fob_fallback_ignores_homebase_direct_loadouts()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_354: FAILED")
		quit(1)
	else:
		print("TASK_354: ALL PASSED")
		quit(0)


func _test_homebase_drop_state_scope_defaults_and_dropdown_path() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	await _configure_homebase_matrix(screen)

	var drop_state: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	var member_loadouts: Dictionary = Dictionary(drop_state.get("member_loadouts", {}))
	var alpha_loadout: Dictionary = Dictionary(member_loadouts.get("unit_alpha", {}))
	var bravo_loadout: Dictionary = Dictionary(member_loadouts.get("unit_bravo", {}))
	var definitions: Array = Array(drop_state.get("selected_fireteam_definitions", []))

	_assert(bool(drop_state.get("drop_ship_staged", false)), "Homebase Direct drop state is launch-ready")
	_assert(_ids_equal(drop_state.get("selected_unit_ids", []), PAYLOAD_UNIT_IDS), "Drop state selected_unit_ids stay payload-only")
	_assert(_ids_equal(drop_state.get("homebase_team_unit_ids", []), HOMEBASE_TEAM_UNIT_IDS), "Drop state keeps full Homebase team separately")
	_assert(member_loadouts.has("unit_alpha") and member_loadouts.has("unit_bravo"), "Drop state exports payload member loadouts")
	_assert(not member_loadouts.has("unit_delta"), "Drop state excludes non-embarked edited loadout")
	_assert(alpha_loadout.get("armor") == "heavy" and alpha_loadout.get("weapon_1") == "rocket_launcher" and alpha_loadout.get("weapon_2") == "none", "UI dropdown path exports alpha heavy/rocket/none")
	_assert(bravo_loadout.get("weapon_1") == "smg" and bravo_loadout.get("weapon_2") == "medictool", "Medic profile default remains smg/medictool without player action")
	_assert(_has_fireteam_definition(definitions, "ft_drop"), "Selected definitions include payload fireteam")
	_assert(not _has_fireteam_definition(definitions, "ft_hold"), "Selected definitions exclude non-payload fireteam")

	screen.queue_free()
	await process_frame


func _test_homebase_direct_mission_setup_modifiers_matrix() -> void:
	var scene: Node = await _build_meta_scene()
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	await _configure_homebase_matrix(homebase_screen)

	homebase_screen.call("request_mission_start")
	await process_frame
	await process_frame

	var planning_state: Dictionary = Dictionary(scene.get("_mission_planning_state"))
	var active_mission = scene.get("_active_mission")
	var mission_setup: Node = active_mission.get_node_or_null("MissionSetup") if active_mission is Node else null
	var mission_member_loadouts: Dictionary = Dictionary(mission_setup.get("member_loadouts")) if mission_setup != null else {}
	var mission_alpha_loadout: Dictionary = Dictionary(mission_member_loadouts.get("unit_alpha", {}))
	var mission_bravo_loadout: Dictionary = Dictionary(mission_member_loadouts.get("unit_bravo", {}))
	var alpha_modifiers: Dictionary = Dictionary(mission_setup.call("get_unit_loadout_modifiers_dict", "unit_alpha")) if mission_setup != null else {}
	var bravo_modifiers: Dictionary = Dictionary(mission_setup.call("get_unit_loadout_modifiers_dict", "unit_bravo")) if mission_setup != null else {}

	_assert(mission_setup != null, "Homebase Direct launch creates MissionSetup")
	_assert(String(planning_state.get("mission_drop_source", "")).strip_edges() == "homebase_direct", "Planning source is Homebase Direct")
	_assert(_ids_equal(mission_setup.get("selected_team_unit_ids"), PAYLOAD_UNIT_IDS), "MissionSetup selected units are payload-only")
	_assert(not mission_member_loadouts.has("unit_delta"), "MissionSetup member_loadouts exclude non-embarked unit")
	_assert(mission_alpha_loadout.get("weapon_1") == "rocket_launcher" and mission_alpha_loadout.get("weapon_2") == "none", "MissionSetup receives UI-selected alpha weapons")
	_assert(mission_bravo_loadout.get("weapon_1") == "smg" and mission_bravo_loadout.get("weapon_2") == "medictool", "MissionSetup receives medic profile defaults")
	_assert(alpha_modifiers.get("weapon_1_id") == "rocket_launcher" and alpha_modifiers.get("weapon_2_id") == "none", "MissionSetup modifiers resolve alpha Homebase loadout")
	_assert(bravo_modifiers.get("weapon_1_id") == "smg" and bravo_modifiers.get("weapon_2_id") == "medictool", "MissionSetup modifiers resolve medic default loadout")
	_assert(float(alpha_modifiers.get("loadout_weight", 0.0)) > float(bravo_modifiers.get("loadout_weight", 0.0)), "Heavy rocket loadout weighs more than medic default")

	scene.queue_free()
	await process_frame


func _test_fob_fallback_ignores_homebase_direct_loadouts() -> void:
	var scene: Node = await _build_meta_scene()
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	await _configure_homebase_matrix(homebase_screen)
	await _stage_fob_waiting_payload(scene)

	scene.call("_on_fob_mission_start_requested", PackedStringArray(FOB_UNIT_IDS), _repeat_fireteam_ids(FOB_UNIT_IDS.size(), FOB_FIRETEAM_ID))
	await process_frame
	await process_frame

	var planning_state: Dictionary = Dictionary(scene.get("_mission_planning_state"))
	var active_mission = scene.get("_active_mission")
	var mission_setup: Node = active_mission.get_node_or_null("MissionSetup") if active_mission is Node else null
	var mission_member_loadouts: Dictionary = Dictionary(mission_setup.get("member_loadouts")) if mission_setup != null else {}
	var echo_loadout: Dictionary = Dictionary(mission_member_loadouts.get("unit_echo", {}))

	_assert(mission_setup != null, "FOB launch creates MissionSetup")
	_assert(String(planning_state.get("mission_drop_source", "")).strip_edges() == "fob", "FOB launch keeps FOB payload source")
	_assert(_ids_equal(mission_setup.get("selected_team_unit_ids"), FOB_UNIT_IDS), "FOB launch uses FOB selected units")
	_assert(mission_member_loadouts.has("unit_echo"), "FOB member_loadouts reach MissionSetup")
	_assert(echo_loadout.get("weapon_1") == "sniper" and echo_loadout.get("weapon_2") == "none", "FOB loadout remains the active fallback payload")
	_assert(not mission_member_loadouts.has("unit_alpha") and not mission_member_loadouts.has("unit_bravo"), "Homebase Direct loadouts do not leak into FOB launch")

	scene.queue_free()
	await process_frame


func _build_meta_scene() -> Node:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	return scene


func _configure_homebase_matrix(screen: Control) -> void:
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(HOMEBASE_TEAM_UNIT_IDS))
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft_drop", "ft_drop", "ft_hold"]),
		[
			_build_fireteam_definition("ft_drop", PackedStringArray(PAYLOAD_UNIT_IDS)),
			_build_fireteam_definition("ft_hold", PackedStringArray(["unit_delta"])),
		]
	)
	screen.call(
		"set_transport_state",
		[_build_dropship_definition("homebase_dropship_alpha")],
		{"homebase_dropship_alpha": "unit_charlie"},
		[],
		[],
		{"homebase_dropship_alpha": "homebase"},
		{},
		{},
		[]
	)
	screen.call("_on_homebase_staging_fireteam_dropped", "ft_drop", "loadout")
	await process_frame
	_assert(await _select_homebase_loadout_option(screen, "unit_alpha", "armor", "heavy"), "UI dropdown selected alpha armor")
	_assert(await _select_homebase_loadout_option(screen, "unit_alpha", "weapon_1", "rocket_launcher"), "UI dropdown selected alpha primary")
	_assert(await _select_homebase_loadout_option(screen, "unit_alpha", "weapon_2", "none"), "UI dropdown selected alpha secondary")

	screen.call("_on_homebase_staging_fireteam_dropped", "ft_hold", "loadout")
	await process_frame
	_assert(await _select_homebase_loadout_option(screen, "unit_delta", "weapon_1", "sniper"), "UI dropdown changed non-payload fireteam")

	screen.call("_on_homebase_staging_fireteam_dropped", "ft_drop", "homebase_dropship")
	await process_frame
	await process_frame


func _stage_fob_waiting_payload(scene: Node) -> void:
	var fob_screen: Control = scene.get_node("FOBScreen") as Control
	var fob_unit_ids := PackedStringArray(FOB_UNIT_IDS)
	var fob_fireteam_ids := _repeat_fireteam_ids(fob_unit_ids.size(), FOB_FIRETEAM_ID)
	fob_screen.call("configure_transfer", fob_unit_ids, fob_fireteam_ids, [_build_fireteam_definition(FOB_FIRETEAM_ID, fob_unit_ids)])
	fob_screen.call("_set_member_loadout", FOB_FIRETEAM_ID, "unit_echo", "heavy", "sniper", "none")
	fob_screen.set("_dropship_transport_craft_id", "dropship_fob")
	fob_screen.call("set_transport_craft_state", [_build_transport_craft_state("dropship_fob")])
	fob_screen.set("_dropship_phase", "ready")
	fob_screen.set("_dropship_staged_fireteam_ids", PackedStringArray([FOB_FIRETEAM_ID]))
	fob_screen.set("_boarded_unit_ids", fob_unit_ids)
	fob_screen.set("_boarded_fireteam_ids", PackedStringArray([FOB_FIRETEAM_ID]))
	fob_screen.call("mark_transport_craft_launch_ready", "dropship_fob")
	await process_frame
	await process_frame


func _select_homebase_loadout_option(screen: Control, unit_id: String, key: String, target_value: String) -> bool:
	var selector := _find_homebase_loadout_selector(screen, unit_id, key)
	if selector == null:
		return false
	for item_index in range(selector.item_count):
		if String(selector.get_item_metadata(item_index)).strip_edges() != target_value:
			continue
		selector.select(item_index)
		selector.item_selected.emit(item_index)
		await process_frame
		return true
	return false


func _find_homebase_loadout_selector(screen: Control, unit_id: String, key: String) -> OptionButton:
	var list := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll/LoadoutMemberList") as VBoxContainer
	if list == null:
		return null
	for child in list.get_children():
		if String(child.get_meta("unit_id", "")).strip_edges() != unit_id:
			continue
		var selectors: Array[OptionButton] = _collect_option_buttons(child)
		var selector_index: int = _selector_index_for_key(key)
		if selector_index >= 0 and selector_index < selectors.size():
			return selectors[selector_index]
	return null


func _selector_index_for_key(key: String) -> int:
	match key.strip_edges().to_lower():
		"armor", "kit":
			return 0
		"weapon_1", "primary":
			return 1
		"weapon_2", "secondary", "sidearm":
			return 2
		_:
			return -1


func _collect_option_buttons(root_node: Node) -> Array[OptionButton]:
	var result: Array[OptionButton] = []
	if root_node is OptionButton:
		result.append(root_node as OptionButton)
	for child in root_node.get_children():
		result.append_array(_collect_option_buttons(child))
	return result


func _build_fireteam_definition(fireteam_id: String, unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": fireteam_id.to_upper(),
		"lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "",
		"loadout": "medium",
		"respawn_enabled": false,
		"member_unit_ids": unit_ids.duplicate(),
	}


func _build_dropship_definition(craft_id: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"craft_type": "dropship",
		"display_name": "Dropship",
		"texture_path": DROPSHIP_TEXTURE_PATH,
		"supports_cargo": false,
		"cargo_options": [],
	}


func _build_transport_craft_state(craft_id: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"craft_type": "dropship",
		"display_name": "FOB Dropship",
		"texture_path": DROPSHIP_TEXTURE_PATH,
		"location": "mission",
		"visible_in_homebase": false,
		"visible_in_fob": true,
		"is_in_transit": false,
		"is_boardable": false,
		"mission_phase": "waiting",
		"mission_waiting": true,
		"mission_transit_to_map": false,
		"mission_transit_to_fob": false,
		"passenger_count": 2,
		"transfer_progress": 100.0,
		"transfer_eta_seconds": 0,
	}


func _repeat_fireteam_ids(count: int, fireteam_id: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for _index in range(count):
		result.append(fireteam_id)
	return result


func _has_fireteam_definition(definitions: Array, fireteam_id: String) -> bool:
	for definition_variant in definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		if String(Dictionary(definition_variant).get("id", "")).strip_edges() == fireteam_id:
			return true
	return false


func _ids_equal(value: Variant, expected: Array) -> bool:
	var actual: Array = Array(value)
	if actual.size() != expected.size():
		return false
	for index in range(actual.size()):
		if String(actual[index]) != String(expected[index]):
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
