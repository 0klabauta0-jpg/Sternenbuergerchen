extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const PAYLOAD_UNIT_IDS := ["unit_alpha", "unit_bravo"]
const HOMEBASE_TEAM_UNIT_IDS := ["unit_alpha", "unit_bravo", "unit_delta"]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_351 Homebase Direct Payload Scope Contract ===")
	await _test_drop_state_exports_payload_scope_only()
	await _test_homebase_direct_start_activates_only_payload_units()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_351: FAILED")
		quit(1)
	else:
		print("TASK_351: ALL PASSED")
		quit(0)


func _test_drop_state_exports_payload_scope_only() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	_configure_homebase_with_unboarded_fireteam(screen)
	screen.call("_set_homebase_member_loadout", "ft_hold", "unit_delta", "heavy", "sniper", "none")
	await process_frame

	var drop_state: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	var selected_configs: Array = Array(drop_state.get("selected_team_unit_configs", []))
	var selected_definitions: Array = Array(drop_state.get("selected_fireteam_definitions", []))
	var member_loadouts: Dictionary = Dictionary(drop_state.get("member_loadouts", {}))

	_assert(bool(drop_state.get("drop_ship_staged", false)), "Direct drop state remains launch-ready")
	_assert(_ids_equal(drop_state.get("embarked_unit_ids", []), PAYLOAD_UNIT_IDS), "Embarked ids contain only the Flightdeck fireteam")
	_assert(_ids_equal(drop_state.get("selected_unit_ids", []), PAYLOAD_UNIT_IDS), "Mission selected_unit_ids are payload-only")
	_assert(_ids_equal(drop_state.get("selected_fireteam_ids", []), ["ft_drop", "ft_drop"]), "Mission selected_fireteam_ids are payload-only")
	_assert(_ids_equal(drop_state.get("homebase_team_unit_ids", []), HOMEBASE_TEAM_UNIT_IDS), "Full Homebase team ids stay exported separately")
	_assert(_ids_equal(drop_state.get("homebase_team_fireteam_ids", []), ["ft_drop", "ft_drop", "ft_hold"]), "Full Homebase fireteam ids stay exported separately")
	_assert(_configs_equal_unit_ids(selected_configs, PAYLOAD_UNIT_IDS), "Mission unit configs are payload-only")
	_assert(_has_fireteam_definition(selected_definitions, "ft_drop"), "Mission fireteam definitions include the payload fireteam")
	_assert(not _has_fireteam_definition(selected_definitions, "ft_hold"), "Mission fireteam definitions exclude non-embarked fireteams")
	_assert(member_loadouts.has("unit_alpha") and member_loadouts.has("unit_bravo"), "Payload member loadouts are exported")
	_assert(not member_loadouts.has("unit_delta"), "Non-embarked member loadout does not leak into mission member_loadouts")

	screen.queue_free()
	await process_frame


func _test_homebase_direct_start_activates_only_payload_units() -> void:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	var homebase_screen: Control = scene.get_node("HomebaseScreen") as Control
	_configure_homebase_with_unboarded_fireteam(homebase_screen)
	await process_frame

	homebase_screen.call("request_mission_start")
	await process_frame

	var planning_state: Dictionary = Dictionary(scene.get("_mission_planning_state"))
	var active_mission = scene.get("_active_mission")
	var mission_setup: Node = active_mission.get_node_or_null("MissionSetup") if active_mission is Node else null
	var mission_unit_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_unit_ids")) if mission_setup != null else PackedStringArray()
	var mission_fireteam_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_fireteam_ids")) if mission_setup != null else PackedStringArray()
	var mission_configs: Array = Array(mission_setup.get("selected_team_unit_configs")) if mission_setup != null else []
	var mission_definitions: Array = Array(mission_setup.get("selected_fireteam_definitions")) if mission_setup != null else []
	var mission_member_loadouts: Dictionary = Dictionary(mission_setup.get("member_loadouts")) if mission_setup != null else {}

	_assert(mission_setup != null, "Homebase Direct start creates a MissionSetup")
	_assert(String(planning_state.get("mission_drop_source", "")).strip_edges() == "homebase_direct", "Planning state records Homebase Direct as source")
	_assert(_ids_equal(planning_state.get("embarked_unit_ids", []), PAYLOAD_UNIT_IDS), "Planning state keeps only payload embarked ids")
	_assert(_ids_equal(mission_unit_ids, PAYLOAD_UNIT_IDS), "MissionSetup selected_team_unit_ids are payload-only")
	_assert(_ids_equal(mission_fireteam_ids, ["ft_drop", "ft_drop"]), "MissionSetup selected_team_fireteam_ids are payload-only")
	_assert(_configs_equal_unit_ids(mission_configs, PAYLOAD_UNIT_IDS), "MissionSetup selected_team_unit_configs are payload-only")
	_assert(_has_fireteam_definition(mission_definitions, "ft_drop"), "MissionSetup includes payload fireteam definition")
	_assert(not _has_fireteam_definition(mission_definitions, "ft_hold"), "MissionSetup excludes non-embarked fireteam definition")
	_assert(not mission_member_loadouts.has("unit_delta"), "MissionSetup member_loadouts exclude non-embarked unit")
	_assert(_ids_equal(scene.get("_selected_unit_ids"), PAYLOAD_UNIT_IDS), "MetaLayer selected units switch to payload for mission start")
	_assert(_ids_equal(scene.get("_homebase_staged_unit_ids"), HOMEBASE_TEAM_UNIT_IDS), "MetaLayer preserves full Homebase team context separately")

	scene.queue_free()
	await process_frame


func _configure_homebase_with_unboarded_fireteam(screen: Control) -> void:
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
		[_build_dropship_definition("dropship_alpha")],
		{"dropship_alpha": "unit_charlie"},
		[],
		[],
		{"dropship_alpha": "homebase"},
		{},
		{},
		[]
	)
	screen.call("_on_homebase_staging_fireteam_dropped", "ft_drop", "homebase_dropship")


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


func _configs_equal_unit_ids(configs: Array, expected_unit_ids: Array) -> bool:
	var actual_unit_ids: Array = []
	for config_variant in configs:
		if typeof(config_variant) != TYPE_DICTIONARY:
			continue
		var unit_id: String = String(Dictionary(config_variant).get("unit_id", "")).strip_edges()
		if not unit_id.is_empty():
			actual_unit_ids.append(unit_id)
	return _ids_equal(actual_unit_ids, expected_unit_ids)


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
