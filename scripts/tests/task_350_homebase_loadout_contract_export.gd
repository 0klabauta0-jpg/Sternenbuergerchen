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
	print("=== TASK_350 Homebase Loadout Contract Export ===")
	await _test_homebase_direct_drop_state_exports_member_loadouts()
	await _test_homebase_direct_mission_start_exports_loadouts_to_mission_setup()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_350: FAILED")
		quit(1)
	else:
		print("TASK_350: ALL PASSED")
		quit(0)


func _test_homebase_direct_drop_state_exports_member_loadouts() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	_configure_homebase_direct_staging(screen)
	screen.call("_set_homebase_member_loadout", "ft1", "unit_alpha", "heavy", "rocket_launcher", "none")
	await process_frame

	var drop_state: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	var member_loadouts: Dictionary = Dictionary(drop_state.get("member_loadouts", {}))
	var alpha_loadout: Dictionary = Dictionary(member_loadouts.get("unit_alpha", {}))
	var definitions: Array = Array(drop_state.get("selected_fireteam_definitions", []))
	var definition_loadout: Dictionary = _extract_definition_member_loadout(definitions, "ft1", "unit_alpha")

	_assert(bool(drop_state.get("drop_ship_staged", false)), "Direct drop state remains launch-ready with a real dropship")
	_assert(alpha_loadout.get("armor") == "heavy", "Direct drop state exports armor through FOB member_loadouts contract")
	_assert(alpha_loadout.get("weapon_1") == "rocket_launcher", "Direct drop state exports primary weapon_1")
	_assert(alpha_loadout.get("weapon_2") == "none", "Direct drop state exports secondary weapon_2")
	_assert(bool(alpha_loadout.get("is_fireteam_lead", false)), "Direct member_loadouts preserve fireteam lead marker")
	_assert(not alpha_loadout.has("kit") and not alpha_loadout.has("primary") and not alpha_loadout.has("sidearm"), "Direct loadout export does not leak Homebase-only alias keys")
	_assert(definition_loadout.get("armor") == "heavy" and definition_loadout.get("weapon_1") == "rocket_launcher", "Selected fireteam definitions carry the same member_loadouts contract")
	_assert(_loadout_dropdowns_use_contract_values(screen), "Homebase loadout dropdowns only expose FOB-compatible contract values")

	screen.queue_free()
	await process_frame


func _test_homebase_direct_mission_start_exports_loadouts_to_mission_setup() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	_configure_homebase_direct_staging(homebase_screen)
	homebase_screen.call("_set_homebase_member_loadout", "ft1", "unit_alpha", "heavy", "rocket_launcher", "none")
	await process_frame

	homebase_screen.call("request_mission_start")
	await process_frame
	var active_mission = scene.get("_active_mission")
	var mission_setup: Node = active_mission.get_node_or_null("MissionSetup") if active_mission is Node else null
	var mission_member_loadouts: Dictionary = Dictionary(mission_setup.get("member_loadouts")) if mission_setup != null else {}
	var mission_definitions: Array = Array(mission_setup.get("selected_fireteam_definitions")) if mission_setup != null else []
	var mission_unit_configs: Array = Array(mission_setup.get("selected_team_unit_configs")) if mission_setup != null else []
	var alpha_loadout: Dictionary = Dictionary(mission_member_loadouts.get("unit_alpha", {}))

	_assert(mission_setup != null, "Homebase Direct start creates a mission setup")
	_assert(alpha_loadout.get("armor") == "heavy", "MissionSetup receives Homebase armor override")
	_assert(alpha_loadout.get("weapon_1") == "rocket_launcher", "MissionSetup receives Homebase weapon_1 override")
	_assert(alpha_loadout.get("weapon_2") == "none", "MissionSetup receives Homebase weapon_2 override")
	_assert(_extract_definition_member_loadout(mission_definitions, "ft1", "unit_alpha").get("weapon_1") == "rocket_launcher", "MissionSetup fireteam definitions include Homebase member_loadouts")
	_assert(_unit_config_has_fireteam(mission_unit_configs, "unit_alpha", "ft1"), "MissionSetup receives Homebase-selected unit config fireteam ids")

	scene.queue_free()
	await process_frame


func _configure_homebase_direct_staging(screen: Control) -> void:
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo"]))
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1"]),
		[_build_fireteam_definition("ft1", PackedStringArray(["unit_alpha", "unit_bravo"]))]
	)
	screen.call(
		"set_transport_state",
		[_build_dropship_definition("dropship_alpha")],
		{"dropship_alpha": "unit_charlie"},
		[],
		[],
		{"dropship_alpha": "homebase"},
		{},
		{},
		[]
	)
	screen.call("_on_homebase_staging_fireteam_dropped", "ft1", "homebase_dropship")


func _build_fireteam_definition(fireteam_id: String, unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": fireteam_id.to_upper(),
		"lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "",
		"loadout": "medium",
		"respawn_enabled": false,
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


func _extract_definition_member_loadout(definitions: Array, fireteam_id: String, unit_id: String) -> Dictionary:
	for definition_variant in definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		if String(definition.get("id", "")).strip_edges() != fireteam_id:
			continue
		var member_loadouts: Dictionary = Dictionary(definition.get("member_loadouts", {}))
		return Dictionary(member_loadouts.get(unit_id, {})) if member_loadouts.has(unit_id) else {}
	return {}


func _unit_config_has_fireteam(unit_configs: Array, unit_id: String, fireteam_id: String) -> bool:
	for config_variant in unit_configs:
		if typeof(config_variant) != TYPE_DICTIONARY:
			continue
		var config: Dictionary = Dictionary(config_variant)
		if String(config.get("unit_id", "")).strip_edges() == unit_id and String(config.get("fireteam_id", "")).strip_edges() == fireteam_id:
			return true
	return false


func _loadout_dropdowns_use_contract_values(screen: Control) -> bool:
	var root_node := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll/LoadoutMemberList")
	if root_node == null:
		return false
	var allowed_values := {
		"light": true,
		"medium": true,
		"heavy": true,
		"none": true,
		"smg": true,
		"rifle": true,
		"sniper": true,
		"rocket_launcher": true,
		"medictool": true,
	}
	for option_button in _collect_option_buttons(root_node):
		for item_index in range(option_button.item_count):
			var value: String = String(option_button.get_item_metadata(item_index)).strip_edges()
			if not allowed_values.has(value):
				return false
	return true


func _collect_option_buttons(root_node: Node) -> Array[OptionButton]:
	var result: Array[OptionButton] = []
	if root_node is OptionButton:
		result.append(root_node as OptionButton)
	for child in root_node.get_children():
		result.append_array(_collect_option_buttons(child))
	return result


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
