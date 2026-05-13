extends SceneTree

const AIRCRAFT_MANAGER_SCRIPT: GDScript = preload("res://scripts/meta/aircraft_manager.gd")
const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const CARGO_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_cargoA_NE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_362 Homebase Aircraft State Manager Extraction ===")
	_test_manager_owns_state_and_direct_staging_gates()
	_test_manager_cargo_pilot_and_transfer_validation()
	await _test_homebase_delegates_aircraft_state_to_manager()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_362: FAILED")
		quit(1)
	else:
		print("TASK_362: ALL PASSED")
		quit(0)


func _test_manager_owns_state_and_direct_staging_gates() -> void:
	var manager = AIRCRAFT_MANAGER_SCRIPT.new()
	var empty_gate: Dictionary = Dictionary(manager.call("build_homebase_direct_staging_craft_gate"))
	_assert(String(empty_gate.get("block_reason", "")).strip_edges() == "no_homebase_craft", "Manager reports no_homebase_craft without visible craft")

	manager.call(
		"set_transport_state",
		[_build_dropship_definition("dropship_alpha"), _build_cargo_definition("cargo_alpha")],
		{"dropship_alpha": "unit_charlie"},
		[],
		{"dropship_alpha": "homebase", "cargo_alpha": "homebase"},
		{},
		{},
		[]
	)
	var snapshot: Dictionary = Dictionary(manager.call("get_contract_snapshot"))
	var dropship_gate: Dictionary = Dictionary(manager.call("build_homebase_direct_staging_craft_gate"))
	_assert(String(snapshot.get("manager_class", "")) == "AircraftManager", "Manager exposes a clear contract snapshot")
	_assert(bool(snapshot.get("owns_aircraft_state", false)) and bool(snapshot.get("owns_validation", false)), "Manager owns aircraft state and validation")
	_assert(not bool(snapshot.get("ui_rendering_owned", true)), "Manager explicitly does not own UI rendering")
	_assert(int(snapshot.get("visible_aircraft_count", 0)) == 2, "Manager filters visible Homebase aircraft")
	_assert(String(snapshot.get("selected_aircraft_id", "")).strip_edges() == "dropship_alpha", "Manager keeps selected aircraft id")
	_assert(bool(dropship_gate.get("can_stage", false)), "Selected Homebase dropship can stage direct payload")

	manager.call("set_selected_aircraft_id", "cargo_alpha")
	var cargo_gate: Dictionary = Dictionary(manager.call("build_homebase_direct_staging_craft_gate"))
	_assert(String(cargo_gate.get("block_reason", "")).strip_edges() == "not_dropship", "Cargo craft blocks direct fireteam staging")


func _test_manager_cargo_pilot_and_transfer_validation() -> void:
	var manager = AIRCRAFT_MANAGER_SCRIPT.new()
	manager.call(
		"set_transport_state",
		[_build_cargo_definition("cargo_alpha")],
		{},
		[],
		{"cargo_alpha": "homebase"},
		{"cargo_alpha": "rover"},
		{},
		[]
	)
	var cargo_def: Dictionary = Dictionary(manager.call("get_aircraft_definition_by_id", "cargo_alpha"))
	_assert(bool(manager.call("can_load_selected_cargo", cargo_def, "cargo_alpha")), "Manager allows loading selected unloaded cargo")
	_assert(not bool(manager.call("can_send_craft", cargo_def, "cargo_alpha")), "Manager blocks cargo craft send until selected cargo is loaded")

	manager.call(
		"set_transport_state",
		[_build_cargo_definition("cargo_alpha")],
		{"cargo_alpha": "unit_delta"},
		[],
		{"cargo_alpha": "homebase"},
		{"cargo_alpha": "rover"},
		{"cargo_alpha": "rover"},
		[]
	)
	cargo_def = Dictionary(manager.call("get_aircraft_definition_by_id", "cargo_alpha"))
	_assert(bool(manager.call("can_send_craft", cargo_def, "cargo_alpha")), "Manager allows send after selected cargo is loaded")
	_assert(not bool(manager.call("can_remove_aircraft", "cargo_alpha")), "Manager blocks removing loaded cargo craft")
	_assert(String(manager.call("find_assigned_craft_for_unit", "unit_delta")) == "cargo_alpha", "Manager resolves assigned pilot craft")

	manager.call(
		"set_transport_state",
		[_build_dropship_definition("dropship_transit")],
		{"dropship_transit": "unit_charlie"},
		[{"craft_id": "dropship_transit", "pilot_unit_id": "unit_charlie", "duration_seconds": 12.0, "elapsed_seconds": 4.0}],
		{"dropship_transit": "transit"},
		{},
		{},
		[]
	)
	var transit_gate: Dictionary = Dictionary(manager.call("build_homebase_direct_staging_craft_gate"))
	_assert(String(transit_gate.get("block_reason", "")).strip_edges() == "craft_in_transit", "Manager blocks direct staging for craft in transit")

	manager.call(
		"set_transport_state",
		[_build_dropship_definition("dropship_loading")],
		{"dropship_loading": "unit_charlie"},
		[],
		{"dropship_loading": "homebase"},
		{},
		{},
		[{"craft_id": "dropship_loading", "cargo_id": "rover", "duration_seconds": 12.0, "elapsed_seconds": 4.0}]
	)
	var loading_gate: Dictionary = Dictionary(manager.call("build_homebase_direct_staging_craft_gate"))
	_assert(String(loading_gate.get("block_reason", "")).strip_edges() == "craft_busy", "Manager blocks direct staging for active Flightdeck work")


func _test_homebase_delegates_aircraft_state_to_manager() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

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
		{},
		[],
		[],
		{"dropship_alpha": "homebase"},
		{},
		{},
		[]
	)
	screen.call("_on_aircraft_pilot_drop_panel_unit_dropped", "unit_charlie", "dropship_alpha")
	screen.call("_on_homebase_staging_fireteam_dropped", "ft1", "homebase_dropship")
	screen.call("_debug_advance_homebase_direct_boarding", 9.2)
	await process_frame
	await process_frame

	var manager_snapshot: Dictionary = Dictionary(screen.call("get_aircraft_manager_contract_snapshot"))
	var panel_snapshot: Dictionary = Dictionary(screen.call("get_aircraft_panel_snapshot"))
	var drop_state: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	var panel_manager_snapshot: Dictionary = Dictionary(panel_snapshot.get("aircraft_manager_contract", {}))
	_assert(String(manager_snapshot.get("manager_class", "")) == "AircraftManager", "Homebase exposes AircraftManager contract")
	_assert(int(manager_snapshot.get("assigned_pilot_count", 0)) == 1, "Homebase pilot assignment mutates manager state")
	_assert(String(manager_snapshot.get("selected_aircraft_id", "")).strip_edges() == "dropship_alpha", "Homebase selected craft is delegated to manager")
	_assert(String(panel_manager_snapshot.get("manager_class", "")) == "AircraftManager", "Aircraft panel snapshot includes manager contract")
	_assert(bool(panel_snapshot.get("homebase_direct_craft_ready", false)), "Homebase Direct gate stays ready through manager")
	_assert(bool(drop_state.get("drop_ship_staged", false)), "Homebase Direct payload still launches through real manager-owned craft")
	_assert(String(drop_state.get("mission_drop_craft_id", "")).strip_edges() == "dropship_alpha", "Direct payload exports real craft id after extraction")
	_assert(String(drop_state.get("mission_drop_pilot_unit_id", "")).strip_edges() == "unit_charlie", "Direct payload exports manager-owned pilot id")

	screen.queue_free()
	await process_frame


func _build_fireteam_definition(fireteam_id: String, unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": fireteam_id.to_upper(),
		"lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "",
		"loadout": "medium",
		"respawn_enabled": false,
		"member_unit_ids": unit_ids,
	}


func _build_dropship_definition(craft_id: String, unavailable: bool = false) -> Dictionary:
	return {
		"craft_id": craft_id,
		"craft_type": "dropship",
		"display_name": "Dropship",
		"texture_path": DROPSHIP_TEXTURE_PATH,
		"supports_cargo": false,
		"cargo_options": [],
		"air_asset_unavailable": unavailable,
		"air_asset_recovery_eta_seconds": 45,
	}


func _build_cargo_definition(craft_id: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"craft_type": "craft_cargoB",
		"display_name": "Frachter",
		"texture_path": CARGO_TEXTURE_PATH,
		"supports_cargo": true,
		"cargo_options": [
			{"cargo_id": "", "display_name": "No Cargo"},
			{"cargo_id": "rover", "display_name": "Rover"},
		],
	}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
