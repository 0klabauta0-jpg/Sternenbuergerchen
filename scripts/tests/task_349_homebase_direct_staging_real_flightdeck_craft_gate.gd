extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const CARGO_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_cargoA_NE.png"

var _passed: int = 0
var _failed: int = 0
var _mission_start_signal_count: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_349 Homebase Direct Staging Real Flightdeck Craft Gate ===")
	await _test_no_flightdeck_craft_blocks_direct_launch()
	await _test_real_homebase_dropship_exports_direct_payload()
	await _test_non_boardable_and_busy_crafts_block_direct_launch()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_349: FAILED")
		quit(1)
	else:
		print("TASK_349: ALL PASSED")
		quit(0)


func _test_no_flightdeck_craft_blocks_direct_launch() -> void:
	var screen: Control = await _build_screen_with_fireteam_payload()
	_mission_start_signal_count = 0
	screen.connect("mission_start_requested", Callable(self, "_on_mission_start_requested"))
	screen.call("request_mission_start")

	var drop_state: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	_assert(not bool(drop_state.get("drop_ship_staged", true)), "No Flightdeck craft keeps Direct drop_state blocked")
	_assert(String(drop_state.get("mission_drop_craft_id", "")).strip_edges() != "homebase_dropship", "No synthetic homebase_dropship craft is exported")
	_assert(Array(drop_state.get("embarked_unit_ids", [])).is_empty(), "No craft means no embarked Direct payload")
	_assert(String(snapshot.get("homebase_direct_craft_block_reason", "")).strip_edges() == "no_homebase_craft", "Snapshot reports missing Homebase craft")
	_assert(not bool(screen.call("can_request_mission_start")), "Start guard blocks staged fireteams without a real craft")
	_assert(_mission_start_signal_count == 0, "request_mission_start does not emit without a real craft")
	_assert(_direct_staging_panel_visible(screen), "Direct Flightdeck drop area remains visible while blocked")
	_assert(_direct_status_contains(screen, "Add a dropship"), "Direct Flightdeck status explains the missing craft")

	screen.queue_free()
	await process_frame


func _test_real_homebase_dropship_exports_direct_payload() -> void:
	var screen: Control = await _build_screen_with_fireteam_payload()
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
	await process_frame
	await process_frame

	var drop_state: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	_assert(bool(drop_state.get("drop_ship_staged", false)), "Real Homebase dropship makes Direct drop_state launch-ready")
	_assert(String(drop_state.get("mission_drop_craft_id", "")).strip_edges() == "dropship_alpha", "Direct payload exports the real craft id")
	_assert(String(drop_state.get("mission_drop_texture_path", "")).strip_edges() == DROPSHIP_TEXTURE_PATH, "Direct payload exports the real craft texture")
	_assert(String(drop_state.get("mission_drop_pilot_unit_id", "")).strip_edges() == "unit_charlie", "Direct payload exports the assigned pilot id")
	_assert(int(drop_state.get("mission_drop_passenger_count", 0)) == 2, "Direct payload exports passenger count")
	_assert(Array(drop_state.get("embarked_unit_ids", [])).size() == 2, "Direct payload exports embarked operator ids")
	_assert(bool(snapshot.get("homebase_direct_craft_ready", false)), "Snapshot marks the selected dropship as Direct-ready")
	_assert(bool(screen.call("can_request_mission_start")), "Start guard allows a staged fireteam on a real dropship")

	screen.queue_free()
	await process_frame


func _test_non_boardable_and_busy_crafts_block_direct_launch() -> void:
	await _assert_blocked_craft_case(
		"not_dropship",
		[_build_cargo_definition("cargo_alpha")],
		{},
		[],
		{},
		{},
		{},
		[],
		"Cargo craft blocks fireteam Direct launch"
	)
	await _assert_blocked_craft_case(
		"craft_in_transit",
		[_build_dropship_definition("dropship_transit")],
		{"dropship_transit": "unit_charlie"},
		[{"craft_id": "dropship_transit", "pilot_unit_id": "unit_charlie", "duration_seconds": 12.0, "elapsed_seconds": 4.0}],
		{"dropship_transit": "transit"},
		{},
		{},
		[],
		"Dropship in transit blocks Direct launch"
	)
	await _assert_blocked_craft_case(
		"craft_busy",
		[_build_dropship_definition("dropship_loading")],
		{"dropship_loading": "unit_charlie"},
		[],
		{"dropship_loading": "homebase"},
		{},
		{},
		[{"craft_id": "dropship_loading", "cargo_id": "rover", "duration_seconds": 12.0, "elapsed_seconds": 4.0}],
		"Dropship with active Flightdeck work blocks Direct launch"
	)
	await _assert_blocked_craft_case(
		"air_asset_unavailable",
		[_build_dropship_definition("dropship_recovery", true)],
		{"dropship_recovery": "unit_charlie"},
		[],
		{"dropship_recovery": "homebase"},
		{},
		{},
		[],
		"Unavailable dropship blocks Direct launch"
	)


func _assert_blocked_craft_case(
	expected_reason: String,
	aircraft_definitions: Array,
	assigned_pilot_by_craft: Dictionary,
	pilot_transfer_entries: Array,
	aircraft_location_by_craft: Dictionary,
	selected_cargo_by_craft: Dictionary,
	loaded_cargo_by_craft: Dictionary,
	cargo_load_entries: Array,
	message: String
) -> void:
	var screen: Control = await _build_screen_with_fireteam_payload()
	screen.call(
		"set_transport_state",
		aircraft_definitions,
		assigned_pilot_by_craft,
		[],
		pilot_transfer_entries,
		aircraft_location_by_craft,
		selected_cargo_by_craft,
		loaded_cargo_by_craft,
		cargo_load_entries
	)
	await process_frame
	await process_frame

	var drop_state: Dictionary = Dictionary(screen.call("build_homebase_direct_drop_state"))
	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	_assert(not bool(drop_state.get("drop_ship_staged", true)), message)
	_assert(String(snapshot.get("homebase_direct_craft_block_reason", "")).strip_edges() == expected_reason, "%s reports %s" % [message, expected_reason])
	_assert(not bool(screen.call("can_request_mission_start")), "%s keeps the start guard blocked" % message)
	_assert(_direct_staging_panel_visible(screen), "%s keeps the Direct drop area visible" % message)

	screen.queue_free()
	await process_frame


func _build_screen_with_fireteam_payload() -> Control:
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
	screen.call("_on_homebase_staging_fireteam_dropped", "ft1", "homebase_dropship")
	await process_frame
	await process_frame
	return screen


func _build_fireteam_definition(fireteam_id: String, unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": fireteam_id.to_upper(),
		"lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "",
		"loadout": "medium",
		"respawn_enabled": false,
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


func _direct_staging_panel_visible(screen: Control) -> bool:
	var panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DirectDropshipFireteamPanel") as Control
	return panel != null and panel.visible


func _direct_status_contains(screen: Control, text: String) -> bool:
	var label := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DirectDropshipFireteamPanel/DirectDropshipMargin/DirectDropshipVBox/DirectDropshipStatusLabel") as Label
	return label != null and label.text.contains(text)


func _on_mission_start_requested() -> void:
	_mission_start_signal_count += 1


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
