extends Node

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const FRIENDLY_NODE_NAMES: PackedStringArray = ["UnitAlpha", "UnitBravo", "UnitCharlie", "UnitDelta", "UnitEcho", "UnitFoxtrot", "UnitGolf", "UnitHotel"]
const DEFAULT_META_MAP_PATH: String = "res://maps/test_mission_32x32_slots8.json"
const HOMEBASE_MISSION_CATALOG: Array = [
	{
		"mission_id": "fob_transfer",
		"mission_name": "Operation: FOB Transfer",
		"map_file_path": "res://maps/test_mission_32x32_slots8.json",
		"slot_count": 8,
		"time_limit_seconds": 1200.0,
	},
	{
		"mission_id": "grid_sweep",
		"mission_name": "Operation: Grid Sweep",
		"map_file_path": "res://maps/test_mission_32x32_slots8.json",
		"slot_count": 3,
		"time_limit_seconds": 1200.0,
	},
	{
		"mission_id": "frontier_probe",
		"mission_name": "Operation: Frontier Probe",
		"map_file_path": "res://maps/new_map.json",
		"slot_count": 3,
		"time_limit_seconds": 1200.0,
	},
	{
		"mission_id": "wall_breach",
		"mission_name": "Operation: Wall Breach",
		"map_file_path": "res://maps/wall_test_4x4.json",
		"slot_count": 3,
		"time_limit_seconds": 1200.0,
	},
]
const HOMEBASE_AIRCRAFT_BASE_DEFINITIONS: Dictionary = {
	"dropship": {
		"craft_type": "dropship",
		"display_name": "Dropship",
		"summary": "Single-pilot shuttle for the FOB corridor.",
		"texture_path": "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png",
		"supports_cargo": false,
		"cargo_options": [],
	},
	"craft_cargoB": {
		"craft_type": "craft_cargoB",
		"display_name": "Frachter",
		"summary": "Cargo freighter for Rover-sized payloads.",
		"texture_path": "res://Assets/kenney_space-kit/Side/craft_cargoB.png",
		"supports_cargo": true,
		"cargo_options": [
			{"cargo_id": "", "display_name": "No Cargo"},
			{"cargo_id": "rover", "display_name": "Rover"},
		],
	}
}
const HOMEBASE_TEAM_TRANSFER_DURATION_SECONDS: float = 14.0
const HOMEBASE_PILOT_TRANSFER_DURATION_SECONDS: float = 10.0
const HOMEBASE_CARGO_LOAD_DURATION_SECONDS: float = 9.0
const MISSION_DROPSHIP_TO_MAP_SECONDS: float = 18.0
const MISSION_DROPSHIP_TO_FOB_SECONDS: float = 18.0
const MISSION_PREVIEW_ENABLED: bool = false
const DEFAULT_MISSION_PLANNING_STATE: Dictionary = {
	"has_lz_position": false,
	"lz_position": Vector2.ZERO,
	"approach_angle": "NW",
	"drop_ship_requested": false,
	"meta_transfer_routes": [],
	"selected_fireteam": "ALL",
	"selected_phase": "P1",
	"selected_phase_index": 1,
	"active_phase_index": 0,
	"phase_count": 2,
}

var _available_team_units: Array = UNIT_ROSTER_PRESETS_SCRIPT.get_homebase_roster()
var _all_team_units: Array = UNIT_ROSTER_PRESETS_SCRIPT.get_homebase_roster()
var _selected_unit_ids: PackedStringArray = []
var _homebase_staged_unit_ids: PackedStringArray = []
var _selected_fireteam_ids: PackedStringArray = []
var _active_mission = null
var _last_mission_result: Dictionary = {}
var _current_meta_view: String = "homebase"
var _mission_catalog: Array = HOMEBASE_MISSION_CATALOG.duplicate(true)
var _selected_mission_id: String = "fob_transfer"
var _selected_mission_map_path: String = DEFAULT_META_MAP_PATH
var _homebase_aircraft_definitions: Array = []
var _assigned_aircraft_pilot_by_craft: Dictionary = {}
var _aircraft_location_by_craft: Dictionary = {}
var _selected_aircraft_cargo_by_craft: Dictionary = {}
var _loaded_aircraft_cargo_by_craft: Dictionary = {}
var _pending_homebase_team_transfers: Array = []
var _pending_homebase_pilot_transfers: Array = []
var _pending_homebase_cargo_loads: Array = []
var _pending_mission_craft_transfers: Array = []
var _transfer_sequence: int = 0
var _preview_mission = null
var _preview_mission_signature: Dictionary = {}
var _mission_planning_state: Dictionary = DEFAULT_MISSION_PLANNING_STATE.duplicate(true)
var _active_mission_started_at_msec: int = 0
var _active_mission_time_limit_seconds: float = 0.0
var _last_meta_timer_text: String = ""


func _ready() -> void:
	set_process(true)
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	var debrief_screen = _get_debrief_screen()
	if homebase_screen == null or fob_screen == null or debrief_screen == null:
		push_warning("MetaLayerFlow requires HomebaseScreen, FOBScreen and DebriefScreen children.")
		return

	META_UI_SKIN_SCRIPT.apply_meta_navigation(self)
	_connect_navigation_buttons()
	_ensure_homebase_aircraft_locations()
	_ensure_meta_nav_timer_labels()

	if not homebase_screen.selection_changed.is_connected(_on_homebase_selection_changed):
		homebase_screen.selection_changed.connect(_on_homebase_selection_changed)
	if not homebase_screen.team_confirmed.is_connected(_on_homebase_team_confirmed):
		homebase_screen.team_confirmed.connect(_on_homebase_team_confirmed)
	if not homebase_screen.mission_start_requested.is_connected(_on_homebase_mission_start_requested):
		homebase_screen.mission_start_requested.connect(_on_homebase_mission_start_requested)
	if not homebase_screen.mission_selection_changed.is_connected(_on_homebase_mission_selection_changed):
		homebase_screen.mission_selection_changed.connect(_on_homebase_mission_selection_changed)
	if not homebase_screen.aircraft_add_requested.is_connected(_on_homebase_aircraft_add_requested):
		homebase_screen.aircraft_add_requested.connect(_on_homebase_aircraft_add_requested)
	if not homebase_screen.aircraft_remove_requested.is_connected(_on_homebase_aircraft_remove_requested):
		homebase_screen.aircraft_remove_requested.connect(_on_homebase_aircraft_remove_requested)
	if not homebase_screen.aircraft_pilot_assigned.is_connected(_on_homebase_aircraft_pilot_assigned):
		homebase_screen.aircraft_pilot_assigned.connect(_on_homebase_aircraft_pilot_assigned)
	if not homebase_screen.aircraft_pilot_cleared.is_connected(_on_homebase_aircraft_pilot_cleared):
		homebase_screen.aircraft_pilot_cleared.connect(_on_homebase_aircraft_pilot_cleared)
	if not homebase_screen.aircraft_pilot_transfer_requested.is_connected(_on_homebase_aircraft_pilot_transfer_requested):
		homebase_screen.aircraft_pilot_transfer_requested.connect(_on_homebase_aircraft_pilot_transfer_requested)
	if not homebase_screen.aircraft_cargo_selected.is_connected(_on_homebase_aircraft_cargo_selected):
		homebase_screen.aircraft_cargo_selected.connect(_on_homebase_aircraft_cargo_selected)
	if not homebase_screen.aircraft_cargo_load_requested.is_connected(_on_homebase_aircraft_cargo_load_requested):
		homebase_screen.aircraft_cargo_load_requested.connect(_on_homebase_aircraft_cargo_load_requested)
	if not fob_screen.mission_start_requested.is_connected(_on_fob_mission_start_requested):
		fob_screen.mission_start_requested.connect(_on_fob_mission_start_requested)
	if fob_screen.has_signal("transport_craft_mission_stage_requested") and not fob_screen.transport_craft_mission_stage_requested.is_connected(_on_fob_transport_craft_mission_stage_requested):
		fob_screen.transport_craft_mission_stage_requested.connect(_on_fob_transport_craft_mission_stage_requested)
	if not debrief_screen.return_to_fob_requested.is_connected(_on_debrief_return_to_fob_requested):
		debrief_screen.return_to_fob_requested.connect(_on_debrief_return_to_fob_requested)
	if not debrief_screen.return_to_homebase_requested.is_connected(_on_debrief_return_to_homebase_requested):
		debrief_screen.return_to_homebase_requested.connect(_on_debrief_return_to_homebase_requested)

	var transport_timer := _get_transport_timer()
	if transport_timer != null and not transport_timer.timeout.is_connected(_on_homebase_transport_timer_timeout):
		transport_timer.timeout.connect(_on_homebase_transport_timer_timeout)

	_selected_fireteam_ids = _build_unassigned_fireteam_selection(_selected_unit_ids)
	_refresh_homebase_screen()
	_refresh_fob_screen()
	fob_screen.set_last_mission_result(_last_mission_result)
	_refresh_map_screen()
	_ensure_transport_timer_state()
	_show_homebase()
	call_deferred("_sync_mission_host_visibility")


func _process(_delta: float) -> void:
	_refresh_meta_mission_timer_labels()


func get_selected_unit_ids() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


func get_active_mission():
	return _active_mission


func _connect_navigation_buttons() -> void:
	for path in [
		"HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/HomebaseNavButton",
		"FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/HomebaseNavButton",
	]:
		var homebase_button := get_node_or_null(path) as Button
		if homebase_button != null and not homebase_button.pressed.is_connected(_on_homebase_nav_pressed):
			homebase_button.pressed.connect(_on_homebase_nav_pressed)

	for path in [
		"HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/FOBNavButton",
		"FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/FOBNavButton",
	]:
		var fob_button := get_node_or_null(path) as Button
		if fob_button != null and not fob_button.pressed.is_connected(_on_fob_nav_pressed):
			fob_button.pressed.connect(_on_fob_nav_pressed)

	for path in [
		"HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/MissionNavButton",
		"FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/MissionNavButton",
	]:
		var mission_button := get_node_or_null(path) as Button
		if mission_button != null and not mission_button.pressed.is_connected(_on_map_nav_pressed):
			mission_button.pressed.connect(_on_map_nav_pressed)


func _on_homebase_nav_pressed() -> void:
	_show_homebase()


func _on_fob_nav_pressed() -> void:
	_show_fob()


func _on_map_nav_pressed() -> void:
	_show_map()


func _on_homebase_selection_changed(selected_unit_ids: PackedStringArray) -> void:
	_homebase_staged_unit_ids = _sanitize_homebase_selection(selected_unit_ids)


func _on_homebase_mission_selection_changed(mission_id: String) -> void:
	var normalized_mission_id: String = mission_id.strip_edges()
	if normalized_mission_id.is_empty() or not _is_known_mission_id(normalized_mission_id):
		return
	if normalized_mission_id == _selected_mission_id:
		return
	_selected_mission_id = normalized_mission_id
	var mission_definition: Dictionary = _get_selected_mission_definition()
	_selected_mission_map_path = String(mission_definition.get("map_file_path", DEFAULT_META_MAP_PATH)).strip_edges()
	_refresh_homebase_screen()
	_refresh_fob_screen()
	_refresh_map_screen()


func _on_homebase_team_confirmed(selected_unit_ids: PackedStringArray) -> void:
	var transferred_unit_ids: PackedStringArray = _filter_available_homebase_unit_ids(selected_unit_ids)
	if transferred_unit_ids.is_empty():
		return

	_pending_homebase_team_transfers.append(_build_homebase_team_transfer_entry(transferred_unit_ids))
	_available_team_units = _remove_units_by_id(_available_team_units, transferred_unit_ids)
	_homebase_staged_unit_ids = PackedStringArray()
	_refresh_homebase_screen()
	_refresh_map_screen()
	_ensure_transport_timer_state()


func _on_homebase_mission_start_requested() -> void:
	var had_preview_deployed_payload: bool = _has_preview_deployed_mission_payload()
	_sync_fob_dropship_state_into_mission_planning(not had_preview_deployed_payload)
	if not _has_mission_start_payload():
		return
	_begin_active_mission_timer()
	_start_mission()


func _on_homebase_aircraft_add_requested(base_craft_type: String) -> void:
	var normalized_craft_type: String = base_craft_type.strip_edges()
	if normalized_craft_type.is_empty():
		normalized_craft_type = "dropship"
	var aircraft_definition := _build_homebase_aircraft_definition(normalized_craft_type, _get_next_homebase_aircraft_index(normalized_craft_type))
	_homebase_aircraft_definitions.append(aircraft_definition)
	_aircraft_location_by_craft[String(aircraft_definition.get("craft_id", "")).strip_edges()] = "homebase"
	_refresh_homebase_screen()


func _on_homebase_aircraft_remove_requested(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	if _assigned_aircraft_pilot_by_craft.has(normalized_craft_id):
		return
	if _has_active_homebase_pilot_transfer(normalized_craft_id):
		return
	if _has_active_homebase_cargo_load(normalized_craft_id):
		return
	if _loaded_aircraft_cargo_by_craft.has(normalized_craft_id):
		return

	var remaining_aircraft: Array = []
	for craft_variant in _homebase_aircraft_definitions:
		var craft_def: Dictionary = Dictionary(craft_variant)
		if String(craft_def.get("craft_id", "")).strip_edges() == normalized_craft_id:
			continue
		remaining_aircraft.append(craft_def)
	_homebase_aircraft_definitions = remaining_aircraft
	_aircraft_location_by_craft.erase(normalized_craft_id)
	_selected_aircraft_cargo_by_craft.erase(normalized_craft_id)
	_loaded_aircraft_cargo_by_craft.erase(normalized_craft_id)
	_refresh_homebase_screen()


func _on_homebase_aircraft_pilot_assigned(craft_id: String, pilot_unit_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	var normalized_pilot_id: String = pilot_unit_id.strip_edges()
	if normalized_craft_id.is_empty() or normalized_pilot_id.is_empty():
		return
	if not _is_unit_available_in_homebase(normalized_pilot_id):
		return

	for assigned_craft_id_variant in _assigned_aircraft_pilot_by_craft.keys():
		var assigned_craft_id: String = String(assigned_craft_id_variant).strip_edges()
		if String(_assigned_aircraft_pilot_by_craft.get(assigned_craft_id, "")).strip_edges() != normalized_pilot_id:
			continue
		_assigned_aircraft_pilot_by_craft.erase(assigned_craft_id)

	_assigned_aircraft_pilot_by_craft[normalized_craft_id] = normalized_pilot_id
	_homebase_staged_unit_ids = _remove_unit_ids_from_list(_homebase_staged_unit_ids, PackedStringArray([normalized_pilot_id]))
	_refresh_homebase_screen()


func _on_homebase_aircraft_pilot_cleared(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_assigned_aircraft_pilot_by_craft.erase(normalized_craft_id)
	_refresh_homebase_screen()


func _on_homebase_aircraft_cargo_selected(craft_id: String, cargo_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	var normalized_cargo_id: String = cargo_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	var craft_def: Dictionary = _find_homebase_aircraft_definition(normalized_craft_id)
	if craft_def.is_empty() or not bool(craft_def.get("supports_cargo", false)):
		return
	if _has_active_homebase_cargo_load(normalized_craft_id) or _loaded_aircraft_cargo_by_craft.has(normalized_craft_id):
		return
	if normalized_cargo_id.is_empty():
		_selected_aircraft_cargo_by_craft.erase(normalized_craft_id)
	else:
		_selected_aircraft_cargo_by_craft[normalized_craft_id] = normalized_cargo_id
	_refresh_homebase_screen()


func _on_homebase_aircraft_cargo_load_requested(craft_id: String, cargo_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	var normalized_cargo_id: String = cargo_id.strip_edges()
	if normalized_craft_id.is_empty() or normalized_cargo_id.is_empty():
		return
	var craft_def: Dictionary = _find_homebase_aircraft_definition(normalized_craft_id)
	if craft_def.is_empty() or not bool(craft_def.get("supports_cargo", false)):
		return
	if not _craft_supports_cargo_id(craft_def, normalized_cargo_id):
		return
	if _has_active_homebase_cargo_load(normalized_craft_id) or _has_active_homebase_pilot_transfer(normalized_craft_id):
		return
	if _loaded_aircraft_cargo_by_craft.has(normalized_craft_id):
		return
	_selected_aircraft_cargo_by_craft[normalized_craft_id] = normalized_cargo_id
	_pending_homebase_cargo_loads.append(_build_homebase_cargo_load_entry(normalized_craft_id, normalized_cargo_id))
	_refresh_homebase_screen()
	_ensure_transport_timer_state()


func _on_homebase_aircraft_pilot_transfer_requested(craft_id: String, pilot_unit_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	var normalized_pilot_id: String = pilot_unit_id.strip_edges()
	if normalized_craft_id.is_empty() or normalized_pilot_id.is_empty():
		return
	if String(_assigned_aircraft_pilot_by_craft.get(normalized_craft_id, "")).strip_edges() != normalized_pilot_id:
		return
	if not _is_unit_available_in_homebase(normalized_pilot_id):
		return
	if _has_active_homebase_pilot_transfer(normalized_craft_id):
		return
	if _has_active_homebase_cargo_load(normalized_craft_id):
		return
	var selected_cargo_id: String = String(_selected_aircraft_cargo_by_craft.get(normalized_craft_id, "")).strip_edges()
	var loaded_cargo_id: String = String(_loaded_aircraft_cargo_by_craft.get(normalized_craft_id, "")).strip_edges()
	if not selected_cargo_id.is_empty() and loaded_cargo_id.is_empty():
		return

	_aircraft_location_by_craft[normalized_craft_id] = "transit"
	_available_team_units = _remove_units_by_id(_available_team_units, PackedStringArray([normalized_pilot_id]))
	_pending_homebase_pilot_transfers.append(_build_homebase_pilot_transfer_entry(normalized_craft_id, normalized_pilot_id, loaded_cargo_id))
	_refresh_fob_screen()
	_refresh_homebase_screen()
	_refresh_map_screen()
	_ensure_transport_timer_state()


func _on_fob_mission_start_requested(selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray) -> void:
	_selected_unit_ids = selected_unit_ids.duplicate()
	_selected_fireteam_ids = selected_fireteam_ids.duplicate()
	var had_preview_deployed_payload: bool = _has_preview_deployed_mission_payload()
	_sync_fob_dropship_state_into_mission_planning(not had_preview_deployed_payload)
	if not _has_mission_start_payload():
		return
	_begin_active_mission_timer()
	_start_mission()


func _on_fob_transport_craft_mission_stage_requested(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_begin_mission_craft_transfer(normalized_craft_id, "to_mission", MISSION_DROPSHIP_TO_MAP_SECONDS)
	var fob_screen = _get_fob_screen()
	if fob_screen != null and fob_screen.has_method("mark_transport_craft_launch_ready"):
		fob_screen.call("mark_transport_craft_launch_ready", normalized_craft_id)
	_sync_fob_dropship_state_into_mission_planning()
	_refresh_fob_screen()
	_refresh_homebase_screen()
	_refresh_map_screen()
	_ensure_transport_timer_state()


func _on_debrief_return_to_fob_requested() -> void:
	_show_fob()


func _on_debrief_return_to_homebase_requested() -> void:
	_show_homebase()


func _start_mission() -> void:
	var mission_host = _get_mission_host()
	if mission_host == null:
		push_warning("MetaLayerFlow requires a MissionHost child.")
		return
	_release_preview_mission()

	if _active_mission != null:
		_active_mission.queue_free()
		_active_mission = null

	var mission_instance = MISSION_TEST_SCENE.instantiate()
	_configure_mission_instance(mission_instance, _selected_unit_ids, _selected_fireteam_ids, false)
	mission_host.add_child(mission_instance)
	_active_mission = mission_instance
	_connect_planning_state_bridge(_active_mission)
	_connect_mission_end(_active_mission)
	_show_mission()


func _configure_mission_instance(mission_instance: Node, selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray, preview_mode: bool) -> void:
	if selected_unit_ids.is_empty():
		selected_unit_ids = _selected_unit_ids.duplicate()
	if selected_fireteam_ids.is_empty():
		selected_fireteam_ids = _selected_fireteam_ids.duplicate()
	_configure_mission_overlay_nodes(mission_instance, preview_mode)

	var mission_setup = mission_instance.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("selected_team_unit_ids", selected_unit_ids)
		mission_setup.set("selected_team_fireteam_ids", selected_fireteam_ids)
		var fob_screen: Node = get_node_or_null("FOBScreen")
		if fob_screen != null and fob_screen.has_method("get_fireteam_definitions"):
			mission_setup.set("selected_fireteam_definitions", Array(fob_screen.call("get_fireteam_definitions")).duplicate(true))
		mission_setup.set("map_file_path", String(_get_selected_mission_definition().get("map_file_path", DEFAULT_META_MAP_PATH)).strip_edges())
		mission_setup.set("defer_friendly_runtime_activation", _should_defer_friendly_runtime_activation())
		mission_setup.set("allow_full_roster_when_selection_empty", false)

		var fob_loadouts: Dictionary = _build_fob_member_loadouts()
		if not fob_loadouts.is_empty():
			mission_setup.set("member_loadouts", fob_loadouts)

	var tactical_controller = mission_instance.get_node_or_null("TacticalController")
	if tactical_controller != null:
		tactical_controller.set("preview_mode", preview_mode)
		if tactical_controller.has_method("set_planning_state"):
			tactical_controller.call("set_planning_state", _mission_planning_state)

	var command_flow_driver = mission_instance.get_node_or_null("CommandFlowDriver")
	if command_flow_driver != null and not selected_unit_ids.is_empty():
		command_flow_driver.set("unit_id", String(selected_unit_ids[0]))

	var combat_driver = mission_instance.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("friendly_unit_paths", _build_selected_friendly_paths(selected_unit_ids))
		combat_driver.set("mission_time_limit_seconds", float(_get_selected_mission_definition().get("time_limit_seconds", 1200.0)))
		if _active_mission_started_at_msec > 0:
			combat_driver.set("mission_timer_started_at_msec", _active_mission_started_at_msec)

	if preview_mode:
		_disable_node_processing(mission_instance.get_node_or_null("SimulationRoot"))
		_disable_node_processing(mission_instance.get_node_or_null("CombatLoopDriver"))
		_disable_node_processing(mission_instance.get_node_or_null("RespawnManager"))
		_disable_node_processing(mission_instance.get_node_or_null("EnemyWaveController"))
		_disable_node_processing(mission_instance.get_node_or_null("AlphaFlowDriver"))
		_disable_node_processing(mission_instance.get_node_or_null("BravoFlowDriver"))
		_disable_node_processing(mission_instance.get_node_or_null("CharlieFlowDriver"))


func _connect_mission_end(mission_instance: Node) -> void:
	if mission_instance == null:
		return

	var combat_driver = mission_instance.get_node_or_null("CombatLoopDriver")
	if combat_driver == null:
		return

	if not combat_driver.combat_resolved.is_connected(_on_mission_combat_resolved):
		combat_driver.combat_resolved.connect(_on_mission_combat_resolved)


func _on_mission_combat_resolved(mission_result: Dictionary) -> void:
	if _active_mission == null:
		return

	_last_mission_result = _build_mission_result(_active_mission, mission_result)
	var fob_screen = _get_fob_screen()
	if fob_screen != null:
		fob_screen.set_last_mission_result(_last_mission_result)

	var debrief_screen = _get_debrief_screen()
	if debrief_screen != null:
		debrief_screen.set_mission_result(_last_mission_result)

	_release_active_mission()
	_reset_active_mission_timer()
	_refresh_map_screen()
	_show_debrief()


func _build_mission_result(mission_instance: Node, mission_result: Dictionary) -> Dictionary:
	var team_states: Array = []
	var friendly_slot_count: int = mini(_selected_unit_ids.size(), FRIENDLY_NODE_NAMES.size())
	for slot_index in range(friendly_slot_count):
		var node_name: String = String(FRIENDLY_NODE_NAMES[slot_index])
		var requested_unit_id: String = String(_selected_unit_ids[slot_index])

		var unit = mission_instance.get_node_or_null(node_name)
		if unit == null:
			continue

		var resolved_unit_id: String = requested_unit_id
		if unit.has_method("get_unit_id"):
			resolved_unit_id = String(unit.call("get_unit_id"))

		var health_points: int = -1
		if unit.has_method("get_health"):
			health_points = int(unit.call("get_health"))

		var vital_state: String = "unknown"
		if unit.has_method("get_vital_state"):
			vital_state = String(unit.call("get_vital_state"))

		team_states.append(
			{
				"unit_id": resolved_unit_id,
				"display_name": String(unit.get("display_name")),
				"fireteam_id": String(unit.get("fireteam_id")),
				"vital_state": vital_state,
				"health_points": health_points,
			}
		)

	var merged_result: Dictionary = mission_result.duplicate(true)
	if merged_result.is_empty():
		merged_result = {
			"winning_team_id": "",
			"mission_outcome": "ended",
			"result": "ended",
			"win_condition_type": "",
			"objective_captured": false,
			"duration_seconds": 0.0,
		}

	merged_result["selected_unit_ids"] = _selected_unit_ids.duplicate()
	merged_result["selected_fireteam_ids"] = _selected_fireteam_ids.duplicate()
	merged_result["team_states"] = team_states
	return merged_result


func _release_active_mission() -> void:
	if _active_mission == null:
		return

	_active_mission.queue_free()
	_active_mission = null


func _release_preview_mission() -> void:
	if _preview_mission == null:
		return

	_preview_mission.queue_free()
	_preview_mission = null
	_preview_mission_signature = {}


func _on_homebase_transport_timer_timeout() -> void:
	var completed_team_transfers: Array = []
	var active_team_transfers: Array = []
	for entry_variant in _pending_homebase_team_transfers:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		entry["elapsed_seconds"] = min(float(entry.get("elapsed_seconds", 0.0)) + 1.0, float(entry.get("duration_seconds", HOMEBASE_TEAM_TRANSFER_DURATION_SECONDS)))
		if float(entry.get("elapsed_seconds", 0.0)) >= float(entry.get("duration_seconds", HOMEBASE_TEAM_TRANSFER_DURATION_SECONDS)):
			completed_team_transfers.append(entry)
		else:
			active_team_transfers.append(entry)
	_pending_homebase_team_transfers = active_team_transfers

	var completed_pilot_transfers: Array = []
	var active_pilot_transfers: Array = []
	for entry_variant in _pending_homebase_pilot_transfers:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		entry["elapsed_seconds"] = min(float(entry.get("elapsed_seconds", 0.0)) + 1.0, float(entry.get("duration_seconds", HOMEBASE_PILOT_TRANSFER_DURATION_SECONDS)))
		if float(entry.get("elapsed_seconds", 0.0)) >= float(entry.get("duration_seconds", HOMEBASE_PILOT_TRANSFER_DURATION_SECONDS)):
			completed_pilot_transfers.append(entry)
		else:
			active_pilot_transfers.append(entry)
	_pending_homebase_pilot_transfers = active_pilot_transfers

	var completed_cargo_loads: Array = []
	var active_cargo_loads: Array = []
	for entry_variant in _pending_homebase_cargo_loads:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		entry["elapsed_seconds"] = min(float(entry.get("elapsed_seconds", 0.0)) + 1.0, float(entry.get("duration_seconds", HOMEBASE_CARGO_LOAD_DURATION_SECONDS)))
		if float(entry.get("elapsed_seconds", 0.0)) >= float(entry.get("duration_seconds", HOMEBASE_CARGO_LOAD_DURATION_SECONDS)):
			completed_cargo_loads.append(entry)
		else:
			active_cargo_loads.append(entry)
	_pending_homebase_cargo_loads = active_cargo_loads

	var completed_mission_craft_transfers: Array = []
	var active_mission_craft_transfers: Array = []
	for entry_variant in _pending_mission_craft_transfers:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		var default_duration: float = MISSION_DROPSHIP_TO_MAP_SECONDS if String(entry.get("phase", "")).strip_edges() == "to_mission" else MISSION_DROPSHIP_TO_FOB_SECONDS
		entry["elapsed_seconds"] = min(float(entry.get("elapsed_seconds", 0.0)) + 1.0, float(entry.get("duration_seconds", default_duration)))
		if float(entry.get("elapsed_seconds", 0.0)) >= float(entry.get("duration_seconds", default_duration)):
			completed_mission_craft_transfers.append(entry)
		else:
			active_mission_craft_transfers.append(entry)
	_pending_mission_craft_transfers = active_mission_craft_transfers

	var fob_changed: bool = false
	for entry_variant in completed_team_transfers:
		_complete_homebase_team_transfer(Dictionary(entry_variant))
		fob_changed = true
	for entry_variant in completed_cargo_loads:
		_complete_homebase_cargo_load(Dictionary(entry_variant))
	for entry_variant in completed_pilot_transfers:
		_complete_homebase_pilot_transfer(Dictionary(entry_variant))
		fob_changed = true
	for entry_variant in completed_mission_craft_transfers:
		_complete_mission_craft_transfer(Dictionary(entry_variant))
		fob_changed = true

	_refresh_fob_screen()
	_refresh_homebase_screen()
	_refresh_map_screen()
	_ensure_transport_timer_state()


func _complete_homebase_team_transfer(entry: Dictionary) -> void:
	for unit_id_variant in entry.get("unit_ids", []):
		_append_unit_to_fob(String(unit_id_variant).strip_edges())


func _complete_homebase_pilot_transfer(entry: Dictionary) -> void:
	var craft_id: String = String(entry.get("craft_id", "")).strip_edges()
	var pilot_unit_id: String = String(entry.get("pilot_unit_id", "")).strip_edges()
	if not craft_id.is_empty():
		_aircraft_location_by_craft[craft_id] = "fob"
	_selected_unit_ids = _remove_unit_ids_from_list(_selected_unit_ids, PackedStringArray([pilot_unit_id]))
	_selected_fireteam_ids = _build_unassigned_fireteam_selection(_selected_unit_ids)


func _complete_homebase_cargo_load(entry: Dictionary) -> void:
	var craft_id: String = String(entry.get("craft_id", "")).strip_edges()
	var cargo_id: String = String(entry.get("cargo_id", "")).strip_edges()
	if craft_id.is_empty() or cargo_id.is_empty():
		return
	_loaded_aircraft_cargo_by_craft[craft_id] = cargo_id
	_selected_aircraft_cargo_by_craft[craft_id] = cargo_id


func _begin_mission_craft_transfer(craft_id: String, phase: String, duration_seconds: float) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	var normalized_phase: String = phase.strip_edges().to_lower()
	if normalized_craft_id.is_empty() or normalized_phase.is_empty():
		return
	var next_transfers: Array = []
	for entry_variant in _pending_mission_craft_transfers:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		if String(entry.get("craft_id", "")).strip_edges() == normalized_craft_id:
			continue
		next_transfers.append(entry)
	_pending_mission_craft_transfers = next_transfers
	if normalized_phase == "to_mission":
		_aircraft_location_by_craft[normalized_craft_id] = "fob"
	elif normalized_phase == "to_fob":
		_aircraft_location_by_craft[normalized_craft_id] = "mission"
	_pending_mission_craft_transfers.append(_build_mission_craft_transfer_entry(normalized_craft_id, normalized_phase, duration_seconds))


func _complete_mission_craft_transfer(entry: Dictionary) -> void:
	var craft_id: String = String(entry.get("craft_id", "")).strip_edges()
	var phase: String = String(entry.get("phase", "")).strip_edges().to_lower()
	if craft_id.is_empty():
		return
	match phase:
		"to_mission":
			_aircraft_location_by_craft[craft_id] = "mission"
		"to_fob":
			_aircraft_location_by_craft[craft_id] = "fob"


func _find_pending_mission_craft_transfer(craft_id: String) -> Dictionary:
	for entry_variant in _pending_mission_craft_transfers:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return entry.duplicate(true)
	return {}


func _append_unit_to_fob(unit_id: String) -> void:
	if unit_id.is_empty() or _selected_unit_ids.has(unit_id):
		return
	_selected_unit_ids.append(unit_id)
	_selected_fireteam_ids.append("")


func _refresh_homebase_screen() -> void:
	var homebase_screen = _get_homebase_screen()
	if homebase_screen == null:
		return
	homebase_screen.setup_roster(_available_team_units, _homebase_staged_unit_ids)
	homebase_screen.set_fireteam_context(_build_unassigned_fireteam_selection(_homebase_staged_unit_ids))
	var selected_mission: Dictionary = _get_selected_mission_definition()
	homebase_screen.set_mission_context(
		_mission_catalog,
		String(selected_mission.get("map_file_path", DEFAULT_META_MAP_PATH)).strip_edges(),
		String(selected_mission.get("mission_name", "Operation: FOB Transfer")).strip_edges(),
		int(selected_mission.get("slot_count", FRIENDLY_NODE_NAMES.size())),
		String(selected_mission.get("mission_id", _selected_mission_id)).strip_edges()
	)
	homebase_screen.set_transport_state(
		_homebase_aircraft_definitions,
		_assigned_aircraft_pilot_by_craft,
		_pending_homebase_team_transfers,
		_pending_homebase_pilot_transfers,
		_aircraft_location_by_craft,
		_selected_aircraft_cargo_by_craft,
		_loaded_aircraft_cargo_by_craft,
		_pending_homebase_cargo_loads
	)
	homebase_screen.set_mission_occupancy(_selected_unit_ids.size() + _count_assigned_aircraft_pilots(), _count_assigned_aircraft_pilots())
	var fob_screen = _get_fob_screen()
	if fob_screen != null and fob_screen.has_method("can_request_mission_start"):
		var has_preview_deployed_payload: bool = _has_preview_deployed_mission_payload()
		homebase_screen.set_mission_launch_state(
			bool(fob_screen.call("can_request_mission_start")) or has_preview_deployed_payload,
			"Fireteam already deployed on the mission map. Start live mission when ready." if has_preview_deployed_payload else String(fob_screen.call("get_mission_launch_summary"))
		)
	else:
		homebase_screen.set_mission_launch_state(_has_preview_deployed_mission_payload(), "Fireteam already deployed on the mission map. Start live mission when ready.")


func _refresh_fob_screen() -> void:
	var fob_screen = _get_fob_screen()
	if fob_screen == null:
		return
	_sync_fob_transfer_selection_from_screen()
	var selected_mission: Dictionary = _get_selected_mission_definition()
	var fireteam_definitions: Array = fob_screen.get_fireteam_definitions()
	var transport_craft_states: Array = _build_transport_craft_states()
	fob_screen.set_available_units(_build_fob_profile_unit_subset(transport_craft_states))
	fob_screen.set_transport_craft_state(transport_craft_states)
	fob_screen.set_mission_context(
		String(selected_mission.get("mission_name", "Operation: FOB Transfer")).strip_edges(),
		String(selected_mission.get("map_file_path", DEFAULT_META_MAP_PATH)).get_file().get_basename(),
		int(selected_mission.get("slot_count", FRIENDLY_NODE_NAMES.size()))
	)
	fob_screen.configure_transfer(_selected_unit_ids, _selected_fireteam_ids, fireteam_definitions)


func _ensure_transport_timer_state() -> void:
	var transport_timer := _get_transport_timer()
	if transport_timer == null:
		return
	var has_pending_transfers: bool = not _pending_homebase_team_transfers.is_empty() or not _pending_homebase_pilot_transfers.is_empty() or not _pending_homebase_cargo_loads.is_empty() or not _pending_mission_craft_transfers.is_empty()
	transport_timer.wait_time = 1.0
	transport_timer.one_shot = false
	if has_pending_transfers:
		if transport_timer.is_stopped():
			transport_timer.start()
	else:
		transport_timer.stop()


func _build_homebase_team_transfer_entry(unit_ids: PackedStringArray) -> Dictionary:
	_transfer_sequence += 1
	return {
		"transfer_id": "team_%d" % _transfer_sequence,
		"unit_ids": unit_ids.duplicate(),
		"elapsed_seconds": 0.0,
		"duration_seconds": HOMEBASE_TEAM_TRANSFER_DURATION_SECONDS,
	}


func _build_homebase_pilot_transfer_entry(craft_id: String, pilot_unit_id: String, cargo_id: String = "") -> Dictionary:
	_transfer_sequence += 1
	return {
		"transfer_id": "pilot_%d" % _transfer_sequence,
		"craft_id": craft_id,
		"pilot_unit_id": pilot_unit_id,
		"cargo_id": cargo_id,
		"elapsed_seconds": 0.0,
		"duration_seconds": HOMEBASE_PILOT_TRANSFER_DURATION_SECONDS,
	}


func _build_mission_craft_transfer_entry(craft_id: String, phase: String, duration_seconds: float) -> Dictionary:
	_transfer_sequence += 1
	return {
		"transfer_id": "mission_craft_%d" % _transfer_sequence,
		"craft_id": craft_id,
		"phase": phase,
		"elapsed_seconds": 0.0,
		"duration_seconds": maxf(duration_seconds, 1.0),
	}


func _build_homebase_cargo_load_entry(craft_id: String, cargo_id: String) -> Dictionary:
	_transfer_sequence += 1
	return {
		"transfer_id": "cargo_%d" % _transfer_sequence,
		"entry_type": "cargo_load",
		"craft_id": craft_id,
		"cargo_id": cargo_id,
		"elapsed_seconds": 0.0,
		"duration_seconds": HOMEBASE_CARGO_LOAD_DURATION_SECONDS,
	}


func _build_homebase_aircraft_definition(craft_type: String, craft_index: int) -> Dictionary:
	var base_definition: Dictionary = _get_homebase_aircraft_base_definition(craft_type)
	return {
		"craft_id": "%s_%d" % [craft_type, craft_index],
		"craft_type": craft_type,
		"display_name": "%s %d" % [String(base_definition.get("display_name", craft_type)), craft_index],
		"summary": String(base_definition.get("summary", "")),
		"texture_path": String(base_definition.get("texture_path", "")),
		"supports_cargo": bool(base_definition.get("supports_cargo", false)),
		"cargo_options": Array(base_definition.get("cargo_options", [])).duplicate(true),
	}


func _ensure_homebase_aircraft_locations() -> void:
	var visible_craft_ids: Dictionary = {}
	for craft_variant in _homebase_aircraft_definitions:
		var craft_def: Dictionary = Dictionary(craft_variant)
		var craft_id: String = String(craft_def.get("craft_id", "")).strip_edges()
		if craft_id.is_empty():
			continue
		visible_craft_ids[craft_id] = true
		if String(_aircraft_location_by_craft.get(craft_id, "")).strip_edges().is_empty():
			_aircraft_location_by_craft[craft_id] = "homebase"

	for craft_id_variant in _aircraft_location_by_craft.keys():
		var craft_id: String = String(craft_id_variant).strip_edges()
		if visible_craft_ids.has(craft_id):
			continue
		_aircraft_location_by_craft.erase(craft_id)


func _get_homebase_aircraft_base_definition(craft_type: String) -> Dictionary:
	if HOMEBASE_AIRCRAFT_BASE_DEFINITIONS.has(craft_type):
		return Dictionary(HOMEBASE_AIRCRAFT_BASE_DEFINITIONS.get(craft_type, {})).duplicate(true)
	return Dictionary(HOMEBASE_AIRCRAFT_BASE_DEFINITIONS.get("dropship", {})).duplicate(true)


func _get_next_homebase_aircraft_index(craft_type: String) -> int:
	var next_index: int = 1
	for craft_variant in _homebase_aircraft_definitions:
		var craft_def: Dictionary = Dictionary(craft_variant)
		if String(craft_def.get("craft_type", "")).strip_edges() != craft_type:
			continue
		next_index = maxi(next_index, int(String(craft_def.get("craft_id", "0")).split("_")[-1]) + 1)
	return next_index


func _find_homebase_aircraft_definition(craft_id: String) -> Dictionary:
	for craft_variant in _homebase_aircraft_definitions:
		var craft_def: Dictionary = Dictionary(craft_variant)
		if String(craft_def.get("craft_id", "")).strip_edges() == craft_id:
			return craft_def
	return {}


func _build_transport_craft_states() -> Array:
	_ensure_homebase_aircraft_locations()
	var craft_states: Array = []
	for craft_variant in _homebase_aircraft_definitions:
		var craft_def: Dictionary = Dictionary(craft_variant)
		var craft_id: String = String(craft_def.get("craft_id", "")).strip_edges()
		if craft_id.is_empty():
			continue

		var pilot_unit_id: String = String(_assigned_aircraft_pilot_by_craft.get(craft_id, "")).strip_edges()
		var cargo_id: String = String(_loaded_aircraft_cargo_by_craft.get(craft_id, _selected_aircraft_cargo_by_craft.get(craft_id, ""))).strip_edges()
		var pilot_transfer_entry: Dictionary = _find_pending_homebase_pilot_transfer(craft_id)
		var mission_transfer_entry: Dictionary = _find_pending_mission_craft_transfer(craft_id)
		var craft_location: String = String(_aircraft_location_by_craft.get(craft_id, "homebase")).strip_edges().to_lower()
		var is_in_transit: bool = not pilot_transfer_entry.is_empty() or craft_location == "transit"
		var mission_phase: String = ""
		if is_in_transit:
			craft_location = "transit"
		if not mission_transfer_entry.is_empty():
			mission_phase = String(mission_transfer_entry.get("phase", "")).strip_edges().to_lower()
			is_in_transit = true
			craft_location = "mission" if mission_phase == "to_mission" else "fob"
		elif craft_location == "mission":
			mission_phase = "waiting"
		elif craft_location != "fob" and craft_location != "transit":
			craft_location = "homebase"

		var passenger_count: int = 0
		if mission_phase == "to_mission" or mission_phase == "waiting":
			passenger_count = Array(_mission_planning_state.get("embarked_unit_ids", [])).size()
		elif mission_phase == "to_fob":
			passenger_count = int(_mission_planning_state.get("mission_drop_passenger_count", 0))

		var progress_value: float = 0.0
		var eta_seconds: int = 0
		if not mission_transfer_entry.is_empty():
			var mission_duration_seconds: float = max(float(mission_transfer_entry.get("duration_seconds", MISSION_DROPSHIP_TO_MAP_SECONDS)), 1.0)
			var mission_elapsed_seconds: float = clamp(float(mission_transfer_entry.get("elapsed_seconds", 0.0)), 0.0, mission_duration_seconds)
			progress_value = (mission_elapsed_seconds / mission_duration_seconds) * 100.0
			eta_seconds = maxi(int(ceil(mission_duration_seconds - mission_elapsed_seconds)), 0)
		elif not pilot_transfer_entry.is_empty():
			var duration_seconds: float = max(float(pilot_transfer_entry.get("duration_seconds", HOMEBASE_PILOT_TRANSFER_DURATION_SECONDS)), 1.0)
			var elapsed_seconds: float = clamp(float(pilot_transfer_entry.get("elapsed_seconds", 0.0)), 0.0, duration_seconds)
			progress_value = (elapsed_seconds / duration_seconds) * 100.0
			eta_seconds = maxi(int(ceil(duration_seconds - elapsed_seconds)), 0)
		elif craft_location == "fob":
			progress_value = 100.0

		craft_states.append(
			{
				"craft_id": craft_id,
				"craft_type": String(craft_def.get("craft_type", "dropship")).strip_edges(),
				"display_name": String(craft_def.get("display_name", craft_id)).strip_edges(),
				"summary": String(craft_def.get("summary", "")).strip_edges(),
				"texture_path": String(craft_def.get("texture_path", "")).strip_edges(),
				"location": craft_location,
				"visible_in_homebase": craft_location == "homebase",
				"visible_in_fob": craft_location == "fob" or (craft_location == "transit" and not pilot_transfer_entry.is_empty()),
				"is_in_transit": is_in_transit,
				"pilot_unit_id": pilot_unit_id,
				"pilot_display_name": _resolve_unit_display_name(pilot_unit_id),
				"pilot_portrait_path": _resolve_unit_portrait_path(pilot_unit_id),
				"cargo_id": cargo_id,
				"cargo_display_name": _build_homebase_cargo_display_name(craft_def, cargo_id),
				"passenger_count": passenger_count,
				"transfer_progress": progress_value,
				"transfer_eta_seconds": eta_seconds,
				"is_boardable": String(craft_def.get("craft_type", "dropship")).strip_edges() == "dropship" and craft_location == "fob" and mission_phase.is_empty(),
				"mission_phase": mission_phase,
				"mission_waiting": mission_phase == "waiting",
				"mission_transit_to_map": mission_phase == "to_mission",
				"mission_transit_to_fob": mission_phase == "to_fob",
			}
		)
	return craft_states


func _find_pending_homebase_pilot_transfer(craft_id: String) -> Dictionary:
	for entry_variant in _pending_homebase_pilot_transfers:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return entry.duplicate(true)
	return {}


func _resolve_unit_display_name(unit_id: String) -> String:
	if unit_id.is_empty():
		return "none"
	for unit_variant in _all_team_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = unit_variant
		if String(unit_data.get("unit_id", "")).strip_edges() != unit_id:
			continue
		return String(unit_data.get("display_name", unit_id)).strip_edges()
	return unit_id


func _count_assigned_aircraft_pilots() -> int:
	var unique_pilot_ids: Dictionary = {}
	for pilot_id_variant in _assigned_aircraft_pilot_by_craft.values():
		var pilot_id: String = String(pilot_id_variant).strip_edges()
		if pilot_id.is_empty():
			continue
		unique_pilot_ids[pilot_id] = true
	return unique_pilot_ids.size()


func _resolve_unit_portrait_path(unit_id: String) -> String:
	if unit_id.is_empty():
		return ""
	for unit_variant in _all_team_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = unit_variant
		if String(unit_data.get("unit_id", "")).strip_edges() != unit_id:
			continue
		return String(unit_data.get("portrait_path", "")).strip_edges()
	return ""


func _build_homebase_cargo_display_name(craft_def: Dictionary, cargo_id: String) -> String:
	var normalized_cargo_id: String = cargo_id.strip_edges()
	if normalized_cargo_id.is_empty():
		return ""
	for cargo_variant in Array(craft_def.get("cargo_options", [])):
		var cargo_option: Dictionary = Dictionary(cargo_variant)
		if String(cargo_option.get("cargo_id", "")).strip_edges() != normalized_cargo_id:
			continue
		return String(cargo_option.get("display_name", normalized_cargo_id)).strip_edges()
	return normalized_cargo_id.capitalize()


func _has_active_homebase_cargo_load(craft_id: String) -> bool:
	for entry_variant in _pending_homebase_cargo_loads:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return true
	return false


func _craft_supports_cargo_id(craft_def: Dictionary, cargo_id: String) -> bool:
	var normalized_cargo_id: String = cargo_id.strip_edges()
	if normalized_cargo_id.is_empty():
		return false
	for cargo_variant in Array(craft_def.get("cargo_options", [])):
		var cargo_option: Dictionary = Dictionary(cargo_variant)
		if String(cargo_option.get("cargo_id", "")).strip_edges() == normalized_cargo_id:
			return true
	return false


func _filter_available_homebase_unit_ids(unit_ids: PackedStringArray) -> PackedStringArray:
	var available_lookup: Dictionary = {}
	for unit_data in _available_team_units:
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue
		available_lookup[unit_id] = true

	var filtered_unit_ids: PackedStringArray = []
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty() or not available_lookup.has(unit_id) or filtered_unit_ids.has(unit_id):
			continue
		if _is_unit_assigned_to_aircraft(unit_id):
			continue
		filtered_unit_ids.append(unit_id)
	return filtered_unit_ids


func _sanitize_homebase_selection(unit_ids: PackedStringArray) -> PackedStringArray:
	return _filter_available_homebase_unit_ids(unit_ids)


func _remove_unit_ids_from_list(source_ids: PackedStringArray, removed_ids: PackedStringArray) -> PackedStringArray:
	var filtered_ids: PackedStringArray = []
	for unit_id_variant in source_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty() or removed_ids.has(unit_id):
			continue
		filtered_ids.append(unit_id)
	return filtered_ids


func _is_unit_available_in_homebase(unit_id: String) -> bool:
	for unit_data in _available_team_units:
		if String(unit_data.get("unit_id", "")).strip_edges() == unit_id:
			return true
	return false


func _is_unit_assigned_to_aircraft(unit_id: String) -> bool:
	for pilot_id_variant in _assigned_aircraft_pilot_by_craft.values():
		if String(pilot_id_variant).strip_edges() == unit_id:
			return true
	return false


func _has_active_homebase_pilot_transfer(craft_id: String) -> bool:
	for entry_variant in _pending_homebase_pilot_transfers:
		if String(Dictionary(entry_variant).get("craft_id", "")).strip_edges() == craft_id:
			return true
	return false


func _get_transport_timer() -> Timer:
	return get_node_or_null("TransportTimer") as Timer


func _build_selected_friendly_paths(selected_unit_ids: PackedStringArray) -> Array[NodePath]:
	var selected_paths: Array[NodePath] = []
	var friendly_slot_count: int = mini(selected_unit_ids.size(), FRIENDLY_NODE_NAMES.size())
	for slot_index in range(friendly_slot_count):
		var node_name: String = String(FRIENDLY_NODE_NAMES[slot_index])
		selected_paths.append(NodePath("../%s" % node_name))

	return selected_paths


func _build_fob_profile_unit_subset(transport_craft_states: Array) -> Array:
	var profile_unit_ids: PackedStringArray = _selected_unit_ids.duplicate()
	var transit_state_by_unit_id: Dictionary = {}
	for entry_variant in _pending_homebase_team_transfers:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var duration_seconds: float = maxf(float(entry.get("duration_seconds", HOMEBASE_TEAM_TRANSFER_DURATION_SECONDS)), 1.0)
		var elapsed_seconds: float = clampf(float(entry.get("elapsed_seconds", 0.0)), 0.0, duration_seconds)
		var transfer_progress: float = (elapsed_seconds / duration_seconds) * 100.0
		var transfer_eta_seconds: int = maxi(int(ceil(duration_seconds - elapsed_seconds)), 0)
		for unit_id_variant in entry.get("unit_ids", []):
			var unit_id: String = String(unit_id_variant).strip_edges()
			if unit_id.is_empty():
				continue
			if not profile_unit_ids.has(unit_id):
				profile_unit_ids.append(unit_id)
			transit_state_by_unit_id[unit_id] = {
				"is_transit_to_fob": true,
				"transfer_progress": transfer_progress,
				"transfer_eta_seconds": transfer_eta_seconds,
			}
	for craft_state_variant in transport_craft_states:
		if typeof(craft_state_variant) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = craft_state_variant
		if not bool(craft_state.get("visible_in_fob", false)):
			continue
		var pilot_unit_id: String = String(craft_state.get("pilot_unit_id", "")).strip_edges()
		if pilot_unit_id.is_empty() or profile_unit_ids.has(pilot_unit_id):
			continue
		profile_unit_ids.append(pilot_unit_id)

	var result: Array = []
	for unit_variant in _all_team_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = Dictionary(unit_variant)
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or not profile_unit_ids.has(unit_id):
			continue
		var fob_unit_data: Dictionary = unit_data.duplicate(true)
		if transit_state_by_unit_id.has(unit_id):
			for key_variant in Dictionary(transit_state_by_unit_id[unit_id]).keys():
				fob_unit_data[String(key_variant)] = Dictionary(transit_state_by_unit_id[unit_id])[key_variant]
		result.append(fob_unit_data)
	return result


func _show_homebase() -> void:
	_current_meta_view = "homebase"
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	var debrief_screen = _get_debrief_screen()
	_sync_fob_transfer_selection_from_screen()
	if homebase_screen != null:
		homebase_screen.visible = true
		_refresh_homebase_screen()
	if fob_screen != null:
		fob_screen.visible = false
	if debrief_screen != null:
		debrief_screen.visible = false
	_refresh_preview_mission_lifecycle()
	_sync_mission_host_visibility()
	_set_navigation_visible(true)
	_refresh_navigation_state()


func _show_fob() -> void:
	_current_meta_view = "fob"
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	var debrief_screen = _get_debrief_screen()
	if homebase_screen != null:
		homebase_screen.visible = false
	if fob_screen != null:
		fob_screen.visible = true
		_refresh_fob_screen()
		fob_screen.set_last_mission_result(_last_mission_result)
	if debrief_screen != null:
		debrief_screen.visible = false
	_refresh_preview_mission_lifecycle()
	_sync_mission_host_visibility()
	_set_navigation_visible(true)
	_refresh_map_screen()
	_refresh_navigation_state()


func _show_map() -> void:
	_current_meta_view = "map"
	_sync_fob_transfer_selection_from_screen()
	if not MISSION_PREVIEW_ENABLED:
		_start_or_show_live_mission_from_nav()
		return
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	var debrief_screen = _get_debrief_screen()
	if homebase_screen != null:
		homebase_screen.visible = false
	if fob_screen != null:
		fob_screen.visible = false
	if debrief_screen != null:
		debrief_screen.visible = false
	_refresh_preview_mission_lifecycle()
	_sync_mission_host_visibility()
	_set_navigation_visible(true)
	_refresh_map_screen()
	_refresh_navigation_state()


func _show_mission() -> void:
	_current_meta_view = "mission"
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	var debrief_screen = _get_debrief_screen()
	if homebase_screen != null:
		homebase_screen.visible = false
	if fob_screen != null:
		fob_screen.visible = false
	if debrief_screen != null:
		debrief_screen.visible = false
	_refresh_preview_mission_lifecycle()
	_sync_mission_host_visibility()
	_set_navigation_visible(false)


func _start_or_show_live_mission_from_nav() -> void:
	_sync_fob_dropship_state_into_mission_planning(false)
	if _active_mission == null:
		if _active_mission_started_at_msec <= 0:
			_begin_active_mission_timer()
		_start_mission()
		return
	_apply_planning_state_to_mission(_active_mission)
	_show_mission()


func _show_debrief() -> void:
	_current_meta_view = "debrief"
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	var debrief_screen = _get_debrief_screen()
	if homebase_screen != null:
		homebase_screen.visible = false
	if fob_screen != null:
		fob_screen.visible = false
	if debrief_screen != null:
		debrief_screen.visible = true
	_refresh_preview_mission_lifecycle()
	_sync_mission_host_visibility()
	_set_navigation_visible(false)


func _set_navigation_visible(is_visible: bool) -> void:
	var homebase_nav_paths: PackedStringArray = [
		"HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow",
		"FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow",
	]
	for path in homebase_nav_paths:
		var nav_row := get_node_or_null(path) as Control
		if nav_row != null:
			nav_row.visible = is_visible


func _refresh_navigation_state() -> void:
	for pair in [
		{"path": "HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/HomebaseNavButton", "view": "homebase"},
		{"path": "HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/FOBNavButton", "view": "fob"},
		{"path": "HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/MissionNavButton", "view": "map"},
		{"path": "FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/HomebaseNavButton", "view": "homebase"},
		{"path": "FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/FOBNavButton", "view": "fob"},
		{"path": "FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/MissionNavButton", "view": "map"},
	]:
		var button := get_node_or_null(String(pair["path"])) as Button
		if button == null:
			continue
		var view_name: String = String(pair["view"])
		button.disabled = _current_meta_view == view_name
		if button.disabled:
			META_UI_SKIN_SCRIPT.style_primary_button(button)
		else:
			META_UI_SKIN_SCRIPT.style_secondary_button(button)


func _refresh_map_screen() -> void:
	if not MISSION_PREVIEW_ENABLED:
		_release_preview_mission()
		return
	if _active_mission == null:
		_sync_fob_dropship_state_into_mission_planning()
	_refresh_preview_mission_lifecycle()


func _build_fob_member_loadouts() -> Dictionary:
	var fob_screen = _get_fob_screen()
	if fob_screen == null:
		return {}

	var result: Dictionary = {}
	var definitions: Array = fob_screen.get_fireteam_definitions()
	for definition_variant in definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_variant
		var lead_unit_id: String = String(definition.get("lead_unit_id", "")).strip_edges()
		var member_loadouts = definition.get("member_loadouts", {})
		if typeof(member_loadouts) != TYPE_DICTIONARY:
			continue
		for unit_id_variant in member_loadouts.keys():
			var unit_id: String = String(unit_id_variant).strip_edges()
			if unit_id.is_empty():
				continue
			var loadout = member_loadouts[unit_id_variant]
			if typeof(loadout) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = (loadout as Dictionary).duplicate()
			if not lead_unit_id.is_empty() and unit_id == lead_unit_id:
				entry["is_fireteam_lead"] = true
			result[unit_id] = entry
	return result


func _build_homebase_transfer_route_entries() -> Array:
	var route_entries: Array = []
	for entry_variant in _pending_homebase_team_transfers:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var duration_seconds: float = maxf(float(entry.get("duration_seconds", HOMEBASE_TEAM_TRANSFER_DURATION_SECONDS)), 1.0)
		var elapsed_seconds: float = clampf(float(entry.get("elapsed_seconds", 0.0)), 0.0, duration_seconds)
		var unit_ids: PackedStringArray = PackedStringArray(Array(entry.get("unit_ids", [])))
		route_entries.append(
			{
				"transfer_id": String(entry.get("transfer_id", "")).strip_edges(),
				"entry_type": "team",
				"progress_value": (elapsed_seconds / duration_seconds) * 100.0,
				"eta_seconds": maxi(int(ceil(duration_seconds - elapsed_seconds)), 0),
				"member_count": unit_ids.size(),
				"display_name": "%d Operators" % unit_ids.size(),
			}
		)
	for entry_variant in _pending_homebase_pilot_transfers:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var duration_seconds: float = maxf(float(entry.get("duration_seconds", HOMEBASE_PILOT_TRANSFER_DURATION_SECONDS)), 1.0)
		var elapsed_seconds: float = clampf(float(entry.get("elapsed_seconds", 0.0)), 0.0, duration_seconds)
		var craft_id: String = String(entry.get("craft_id", "")).strip_edges()
		var craft_definition: Dictionary = _find_homebase_aircraft_definition(craft_id)
		route_entries.append(
			{
				"transfer_id": String(entry.get("transfer_id", "")).strip_edges(),
				"entry_type": "pilot",
				"progress_value": (elapsed_seconds / duration_seconds) * 100.0,
				"eta_seconds": maxi(int(ceil(duration_seconds - elapsed_seconds)), 0),
				"member_count": 0,
				"display_name": String(craft_definition.get("display_name", craft_id)).strip_edges(),
			}
		)
	return route_entries


func _sync_fob_dropship_state_into_mission_planning(clear_deployed_unit_ids: bool = false) -> void:
	var fob_screen = _get_fob_screen()
	if fob_screen == null or not fob_screen.has_method("build_mission_drop_state"):
		_mission_planning_state["embarked_unit_ids"] = []
		_mission_planning_state["meta_transfer_routes"] = _build_homebase_transfer_route_entries()
		if clear_deployed_unit_ids:
			_mission_planning_state["deployed_unit_ids"] = []
		return

	var drop_state: Dictionary = Dictionary(fob_screen.call("build_mission_drop_state")).duplicate(true)
	_mission_planning_state["embarked_unit_ids"] = Array(PackedStringArray(Array(drop_state.get("embarked_unit_ids", []))))
	_mission_planning_state["drop_queued_fireteam_ids"] = Array(PackedStringArray(Array(drop_state.get("queued_fireteam_ids", []))))
	_mission_planning_state["drop_ship_staged"] = bool(drop_state.get("drop_ship_staged", false))
	_mission_planning_state["launch_ready_craft_id"] = String(drop_state.get("launch_ready_craft_id", "")).strip_edges()
	_mission_planning_state["mission_drop_craft_id"] = String(drop_state.get("mission_drop_craft_id", "")).strip_edges()
	_mission_planning_state["mission_drop_display_name"] = String(drop_state.get("mission_drop_display_name", "")).strip_edges()
	_mission_planning_state["mission_drop_title_text"] = String(drop_state.get("mission_drop_title_text", "")).strip_edges()
	_mission_planning_state["mission_drop_texture_path"] = String(drop_state.get("mission_drop_texture_path", "")).strip_edges()
	_mission_planning_state["mission_drop_state"] = String(drop_state.get("mission_drop_state", "")).strip_edges()
	_mission_planning_state["mission_drop_pilot_text"] = String(drop_state.get("mission_drop_pilot_text", "")).strip_edges()
	_mission_planning_state["mission_drop_status_line"] = String(drop_state.get("mission_drop_status_line", "")).strip_edges()
	_mission_planning_state["mission_drop_progress"] = float(drop_state.get("mission_drop_progress", 0.0))
	_mission_planning_state["mission_drop_eta_seconds"] = int(drop_state.get("mission_drop_eta_seconds", 0))
	_mission_planning_state["mission_drop_pilot_unit_id"] = String(drop_state.get("mission_drop_pilot_unit_id", "")).strip_edges()
	_mission_planning_state["mission_drop_pilot_display_name"] = String(drop_state.get("mission_drop_pilot_display_name", "")).strip_edges()
	_mission_planning_state["mission_drop_pilot_portrait_path"] = String(drop_state.get("mission_drop_pilot_portrait_path", "")).strip_edges()
	_mission_planning_state["mission_drop_passenger_count"] = int(drop_state.get("mission_drop_passenger_count", 0))
	_mission_planning_state["meta_transfer_routes"] = _build_homebase_transfer_route_entries()
	if clear_deployed_unit_ids or not _mission_planning_state.has("deployed_unit_ids"):
		_mission_planning_state["deployed_unit_ids"] = []
	if not _mission_planning_state.has("mission_drop_return_requested"):
		_mission_planning_state["mission_drop_return_requested"] = false


func _has_preview_deployed_mission_payload() -> bool:
	return not Array(_mission_planning_state.get("deployed_unit_ids", [])).is_empty()


func _has_mission_start_payload() -> bool:
	if not bool(_mission_planning_state.get("drop_ship_staged", false)) and not _has_preview_deployed_mission_payload():
		return false
	if not Array(_mission_planning_state.get("embarked_unit_ids", [])).is_empty():
		return true
	return _has_preview_deployed_mission_payload()


func _should_defer_friendly_runtime_activation() -> bool:
	return not Array(_mission_planning_state.get("embarked_unit_ids", [])).is_empty()


func _sync_fob_transfer_selection_from_screen() -> void:
	var fob_screen = _get_fob_screen()
	if fob_screen == null or not fob_screen.has_method("get_team") or not fob_screen.has_method("get_selected_fireteam_ids"):
		return
	if _selected_unit_ids.is_empty():
		return

	var screen_unit_ids := PackedStringArray(fob_screen.call("get_team"))
	var screen_fireteam_ids := PackedStringArray(fob_screen.call("get_selected_fireteam_ids"))
	var next_selected_fireteam_ids: PackedStringArray = _build_unassigned_fireteam_selection(_selected_unit_ids)
	for unit_index in range(_selected_unit_ids.size()):
		var unit_id: String = String(_selected_unit_ids[unit_index]).strip_edges()
		if unit_id.is_empty():
			continue
		var screen_index: int = screen_unit_ids.find(unit_id)
		if screen_index >= 0 and screen_index < screen_fireteam_ids.size():
			next_selected_fireteam_ids[unit_index] = String(screen_fireteam_ids[screen_index]).strip_edges()
		elif unit_index < _selected_fireteam_ids.size():
			next_selected_fireteam_ids[unit_index] = String(_selected_fireteam_ids[unit_index]).strip_edges()
	_selected_fireteam_ids = next_selected_fireteam_ids


func _begin_active_mission_timer() -> void:
	_active_mission_started_at_msec = Time.get_ticks_msec()
	_active_mission_time_limit_seconds = float(_get_selected_mission_definition().get("time_limit_seconds", 1200.0))
	_last_meta_timer_text = ""
	_refresh_meta_mission_timer_labels()


func _reset_active_mission_timer() -> void:
	_active_mission_started_at_msec = 0
	_active_mission_time_limit_seconds = 0.0
	_last_meta_timer_text = ""
	_refresh_meta_mission_timer_labels()


func _ensure_meta_nav_timer_labels() -> void:
	for path in [
		"HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow",
		"FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow",
	]:
		var nav_row := get_node_or_null(path) as HBoxContainer
		if nav_row == null:
			continue
		var timer_label := nav_row.get_node_or_null("MissionTimerLabel") as Label
		if timer_label == null:
			timer_label = Label.new()
			timer_label.name = "MissionTimerLabel"
			timer_label.custom_minimum_size = Vector2(44.0, 0.0)
			timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			timer_label.add_theme_font_size_override("font_size", 8)
			nav_row.add_child(timer_label)


func _refresh_meta_mission_timer_labels() -> void:
	var next_text: String = _build_meta_mission_timer_text()
	if next_text == _last_meta_timer_text:
		return
	_last_meta_timer_text = next_text
	for path in [
		"HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/MissionTimerLabel",
		"FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/MissionTimerLabel",
	]:
		var timer_label := get_node_or_null(path) as Label
		if timer_label != null:
			timer_label.text = next_text


func _build_meta_mission_timer_text() -> String:
	if _active_mission_started_at_msec <= 0 or _active_mission_time_limit_seconds <= 0.0:
		return "--:--"
	var total_seconds: int = int(round(float(_get_selected_mission_definition().get("time_limit_seconds", 1200.0))))
	if _active_mission_started_at_msec > 0 and _active_mission_time_limit_seconds > 0.0:
		var elapsed_seconds: int = maxi(int(float(Time.get_ticks_msec() - _active_mission_started_at_msec) / 1000.0), 0)
		total_seconds = maxi(int(round(_active_mission_time_limit_seconds)) - elapsed_seconds, 0)
	return _format_timer_seconds(total_seconds)


func _format_timer_seconds(total_seconds: int) -> String:
	var clamped_total_seconds: int = maxi(total_seconds, 0)
	var minutes: int = clamped_total_seconds / 60
	var seconds: int = clamped_total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _get_homebase_screen():
	return get_node_or_null("HomebaseScreen")


func _get_fob_screen():
	return get_node_or_null("FOBScreen")


func _get_debrief_screen():
	return get_node_or_null("DebriefScreen")


func _get_mission_host():
	return get_node_or_null("MissionHost")


func _ensure_preview_mission() -> void:
	if not MISSION_PREVIEW_ENABLED:
		return
	var mission_host = _get_mission_host()
	if mission_host == null:
		return
	var desired_signature: Dictionary = _build_preview_mission_signature()
	if _preview_mission != null and _preview_mission_signature == desired_signature:
		return
	_release_preview_mission()
	var preview_instance = MISSION_TEST_SCENE.instantiate()
	_configure_mission_instance(preview_instance, _selected_unit_ids, _selected_fireteam_ids, true)
	mission_host.add_child(preview_instance)
	_preview_mission = preview_instance
	_preview_mission_signature = desired_signature
	_connect_planning_state_bridge(_preview_mission)
	_sync_mission_host_visibility()


func _build_preview_mission_signature() -> Dictionary:
	var selected_mission: Dictionary = _get_selected_mission_definition()
	return {
		"mission_id": String(selected_mission.get("mission_id", _selected_mission_id)).strip_edges(),
		"map_file_path": String(selected_mission.get("map_file_path", DEFAULT_META_MAP_PATH)).strip_edges(),
		"selected_unit_ids": Array(_selected_unit_ids),
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
	}


func _connect_planning_state_bridge(mission_instance: Node) -> void:
	if mission_instance == null:
		return
	var tactical_controller = mission_instance.get_node_or_null("TacticalController")
	if tactical_controller == null:
		return
	if tactical_controller.has_method("set_planning_state"):
		tactical_controller.call("set_planning_state", _mission_planning_state)
	if not tactical_controller.planning_state_changed.is_connected(_on_mission_planning_state_changed):
		tactical_controller.planning_state_changed.connect(_on_mission_planning_state_changed)


func _apply_planning_state_to_mission(mission_instance: Node) -> void:
	if mission_instance == null:
		return
	var tactical_controller = mission_instance.get_node_or_null("TacticalController")
	if tactical_controller != null and tactical_controller.has_method("set_planning_state"):
		tactical_controller.call("set_planning_state", _mission_planning_state)


func _on_mission_planning_state_changed(planning_state: Dictionary) -> void:
	if planning_state.is_empty():
		return
	_mission_planning_state = DEFAULT_MISSION_PLANNING_STATE.duplicate(true)
	for key_variant in planning_state.keys():
		var key: String = String(key_variant)
		_mission_planning_state[key] = planning_state[key_variant]
	if bool(_mission_planning_state.get("mission_drop_return_requested", false)):
		var fob_screen = _get_fob_screen()
		if fob_screen != null and fob_screen.has_method("clear_mission_boarded_payload"):
			fob_screen.call("clear_mission_boarded_payload")
		var mission_craft_id: String = String(_mission_planning_state.get("mission_drop_craft_id", "")).strip_edges()
		if not mission_craft_id.is_empty():
			_begin_mission_craft_transfer(mission_craft_id, "to_fob", MISSION_DROPSHIP_TO_FOB_SECONDS)
		_mission_planning_state["mission_drop_return_requested"] = false
		_sync_fob_dropship_state_into_mission_planning()
	if _preview_mission != null:
		_apply_planning_state_to_mission(_preview_mission)
	if _active_mission != null:
		_apply_planning_state_to_mission(_active_mission)
	_refresh_homebase_screen()
	_refresh_fob_screen()
	_refresh_map_screen()
	_ensure_transport_timer_state()


func _disable_node_processing(node: Node) -> void:
	if node == null:
		return
	node.process_mode = Node.PROCESS_MODE_DISABLED


func _is_mission_host_visible_for_current_view() -> bool:
	if _current_meta_view == "map":
		return _preview_mission != null if MISSION_PREVIEW_ENABLED else _active_mission != null
	if _current_meta_view == "mission":
		return _active_mission != null
	return false


func _refresh_preview_mission_lifecycle() -> void:
	if not MISSION_PREVIEW_ENABLED:
		_release_preview_mission()
		return
	if _active_mission == null and (_current_meta_view == "map" or _should_keep_preview_mission_loaded()):
		_ensure_preview_mission()
		if _preview_mission != null:
			_apply_planning_state_to_mission(_preview_mission)
		return
	_release_preview_mission()


func _should_keep_preview_mission_loaded() -> bool:
	if _active_mission != null:
		return false
	if _current_meta_view == "map":
		return true
	return not String(_mission_planning_state.get("mission_drop_craft_id", "")).strip_edges().is_empty()


func _sync_mission_host_visibility() -> void:
	_set_mission_host_visible(_is_mission_host_visible_for_current_view())


func _set_mission_host_visible(is_visible: bool) -> void:
	var mission_host = _get_mission_host()
	if mission_host == null:
		return
	for child in mission_host.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = is_visible
		_set_mission_instance_ui_visibility(child, is_visible)
		_set_mission_overlay_visibility(child, is_visible)
		var tactical_controller := child.get_node_or_null("TacticalController")
		if tactical_controller != null and tactical_controller.has_method("set_tactical_ui_visible"):
			tactical_controller.call("set_tactical_ui_visible", is_visible)
		child.process_mode = Node.PROCESS_MODE_INHERIT if is_visible else Node.PROCESS_MODE_DISABLED


func _set_mission_instance_ui_visibility(mission_instance: Node, is_visible: bool) -> void:
	if mission_instance == null:
		return
	for path in [
		"TacticalUI/MissionTint",
		"TacticalUI/MissionIdentityPanel",
		"TacticalUI/TopNavPanel",
		"TacticalUI/BottomDock",
	]:
		var canvas_item := mission_instance.get_node_or_null(path) as CanvasItem
		if canvas_item != null:
			canvas_item.visible = is_visible
	var overlay := mission_instance.get_node_or_null("TacticalUI/CharacterOverlay") as Control
	if overlay != null and not is_visible:
		overlay.visible = false


func _configure_mission_overlay_nodes(mission_instance: Node, preview_mode: bool) -> void:
	if mission_instance == null:
		return
	for node_path in ["CombatLoopDriver", "EnemyWaveController", "ObjectiveStatusView"]:
		var node := mission_instance.get_node_or_null(node_path)
		if node == null:
			continue
		node.set("preview_mode", preview_mode)
		if node.has_method("set_preview_mode"):
			node.call("set_preview_mode", preview_mode)


func _set_mission_overlay_visibility(mission_instance: Node, is_visible: bool) -> void:
	if mission_instance == null:
		return
	for node_path in ["CombatLoopDriver", "EnemyWaveController", "ObjectiveStatusView"]:
		var node := mission_instance.get_node_or_null(node_path)
		if node == null or not node.has_method("set_overlay_visible"):
			continue
		node.call("set_overlay_visible", is_visible)


func _build_unassigned_fireteam_selection(selected_unit_ids: PackedStringArray) -> PackedStringArray:
	var fireteam_ids: PackedStringArray = []
	for _unit_id in selected_unit_ids:
		fireteam_ids.append("")
	return fireteam_ids


func _build_unit_subset_by_ids(unit_ids: PackedStringArray) -> Array:
	var wanted_ids: Dictionary = {}
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		wanted_ids[unit_id] = true

	var result: Array = []
	for unit_variant in _all_team_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = unit_variant
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or not wanted_ids.has(unit_id):
			continue
		result.append(unit_data.duplicate(true))
	return result


func _remove_units_by_id(source_units: Array, removed_ids: PackedStringArray) -> Array:
	var removed_lookup: Dictionary = {}
	for unit_id_variant in removed_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		removed_lookup[unit_id] = true

	var result: Array = []
	for unit_variant in source_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = unit_variant
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or removed_lookup.has(unit_id):
			continue
		result.append(unit_data.duplicate(true))
	return result


func _is_known_mission_map_path(map_file_path: String) -> bool:
	for mission_variant in _mission_catalog:
		var mission_definition: Dictionary = Dictionary(mission_variant)
		if String(mission_definition.get("map_file_path", "")).strip_edges() == map_file_path:
			return true
	return false


func _is_known_mission_id(mission_id: String) -> bool:
	for mission_variant in _mission_catalog:
		var mission_definition: Dictionary = Dictionary(mission_variant)
		if String(mission_definition.get("mission_id", "")).strip_edges() == mission_id:
			return true
	return false


func _resolve_mission_slot_count(mission_definition: Dictionary) -> int:
	var explicit_slot_count: int = int(mission_definition.get("slot_count", 0))
	if explicit_slot_count > 0:
		return explicit_slot_count
	var map_file_path: String = String(mission_definition.get("map_file_path", DEFAULT_META_MAP_PATH)).strip_edges()
	if map_file_path.is_empty():
		map_file_path = DEFAULT_META_MAP_PATH
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", map_file_path)
	if terrain_map_data != null and terrain_map_data.has_method("get_mission_slot_count"):
		return maxi(int(terrain_map_data.call("get_mission_slot_count")), 1)
	return FRIENDLY_NODE_NAMES.size()


func _build_resolved_mission_definition(mission_definition: Dictionary) -> Dictionary:
	var resolved_definition: Dictionary = mission_definition.duplicate(true)
	resolved_definition["slot_count"] = _resolve_mission_slot_count(mission_definition)
	return resolved_definition


func _get_selected_mission_definition() -> Dictionary:
	for mission_variant in _mission_catalog:
		var mission_definition: Dictionary = Dictionary(mission_variant)
		if String(mission_definition.get("mission_id", "")).strip_edges() == _selected_mission_id:
			return _build_resolved_mission_definition(mission_definition)
	for mission_variant in _mission_catalog:
		var mission_definition: Dictionary = Dictionary(mission_variant)
		if String(mission_definition.get("map_file_path", "")).strip_edges() == _selected_mission_map_path:
			return _build_resolved_mission_definition(mission_definition)
	if _mission_catalog.is_empty():
		return {
			"mission_id": _selected_mission_id,
			"mission_name": "Operation: FOB Transfer",
			"map_file_path": DEFAULT_META_MAP_PATH,
			"slot_count": _resolve_mission_slot_count({"map_file_path": DEFAULT_META_MAP_PATH}),
		}
	return _build_resolved_mission_definition(Dictionary(_mission_catalog[0]))
