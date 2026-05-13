extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const LOADOUT_MODIFIER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/command/loadout_modifier_resolver.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_352 Homebase Loadout Defaults Preserve Unit Profiles ===")
	await _test_homebase_direct_preserves_roster_medictool_default()
	await _test_homebase_direct_explicit_override_wins()
	await _test_homebase_direct_mission_start_preserves_profile_loadout_to_resolver()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_352: FAILED")
		quit(1)
	else:
		print("TASK_352: ALL PASSED")
		quit(0)


func _test_homebase_direct_preserves_roster_medictool_default() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	_configure_homebase_direct_staging(screen)
	await process_frame

	var drop_state: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	var member_loadouts: Dictionary = Dictionary(drop_state.get("member_loadouts", {}))
	var bravo_loadout: Dictionary = Dictionary(member_loadouts.get("unit_bravo", {}))
	var definitions: Array = Array(drop_state.get("selected_fireteam_definitions", []))
	var definition_bravo_loadout: Dictionary = _extract_definition_member_loadout(definitions, "ft1", "unit_bravo")

	_assert(bool(drop_state.get("drop_ship_staged", false)), "Direct drop state is launch-ready")
	_assert(bravo_loadout.get("weapon_1") == "smg", "unit_bravo keeps roster primary SMG without player edits")
	_assert(bravo_loadout.get("weapon_2") == "medictool", "unit_bravo keeps roster medictool without player edits")
	_assert(definition_bravo_loadout.get("weapon_1") == "smg", "Fireteam definition keeps unit_bravo profile primary")
	_assert(definition_bravo_loadout.get("weapon_2") == "medictool", "Fireteam definition keeps unit_bravo profile secondary")
	_assert(bool(Dictionary(member_loadouts.get("unit_alpha", {})).get("is_fireteam_lead", false)), "Fireteam lead marker remains exported")

	screen.queue_free()
	await process_frame


func _test_homebase_direct_explicit_override_wins() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	_configure_homebase_direct_staging(screen)
	screen.call("_set_homebase_member_loadout", "ft1", "unit_bravo", "heavy", "rocket_launcher", "none")
	await process_frame

	var drop_state: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	var member_loadouts: Dictionary = Dictionary(drop_state.get("member_loadouts", {}))
	var bravo_loadout: Dictionary = Dictionary(member_loadouts.get("unit_bravo", {}))

	_assert(bravo_loadout.get("armor") == "heavy", "Explicit Homebase armor override wins")
	_assert(bravo_loadout.get("weapon_1") == "rocket_launcher", "Explicit Homebase primary override wins")
	_assert(bravo_loadout.get("weapon_2") == "none", "Explicit Homebase secondary override wins")

	screen.queue_free()
	await process_frame


func _test_homebase_direct_mission_start_preserves_profile_loadout_to_resolver() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	_configure_homebase_direct_staging(homebase_screen)
	await process_frame

	homebase_screen.call("request_mission_start")
	await process_frame

	var active_mission = scene.get("_active_mission")
	var mission_setup: Node = active_mission.get_node_or_null("MissionSetup") if active_mission is Node else null
	var mission_member_loadouts: Dictionary = Dictionary(mission_setup.get("member_loadouts")) if mission_setup != null else {}
	var bravo_loadout: Dictionary = Dictionary(mission_member_loadouts.get("unit_bravo", {}))
	var resolver = LOADOUT_MODIFIER_RESOLVER_SCRIPT.new()
	var resolved_modifiers: Dictionary = Dictionary(resolver.call("resolve_for_member_loadouts", mission_member_loadouts))
	var bravo_modifiers: Dictionary = Dictionary(resolved_modifiers.get("unit_bravo", {}))

	_assert(mission_setup != null, "Homebase Direct start creates MissionSetup")
	_assert(bravo_loadout.get("weapon_1") == "smg", "MissionSetup receives unit_bravo profile primary")
	_assert(bravo_loadout.get("weapon_2") == "medictool", "MissionSetup receives unit_bravo profile medictool")
	_assert(bravo_modifiers.get("weapon_1_id") == "smg", "LoadoutModifierResolver receives profile primary")
	_assert(bravo_modifiers.get("weapon_2_id") == "medictool", "LoadoutModifierResolver receives profile medictool")

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
	screen.call("_debug_advance_homebase_direct_boarding", 9.2)


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


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
