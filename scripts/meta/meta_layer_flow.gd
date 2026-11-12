extends Node

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const MISSION_PROGRESSION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/mission_progression_resolver.gd")
const PERSONNEL_EVENT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_resolver.gd")
const AIR_ASSET_RECOVERY_STATE_SCRIPT: GDScript = preload("res://scripts/meta/air_asset_recovery_state.gd")
const REGIONAL_CAMPAIGN_MAPS := [
	"res://maps/satellite_crash_site.json",
	"res://maps/trade_outpost.json",
	"res://maps/fortified_outpost.json",
]
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const REAL_WINDOW_FIREFIGHT_SIGHT_REVIEW_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_release_candidate_real_window_firefight_sight_review.gd")
const VISIBLE_FIREFIGHT_FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_release_candidate_visible_firefight_findings.gd")
const RELEASE_FIRST_EXCHANGE_FIXTURE_SCRIPT: GDScript = preload("res://scripts/tests/release_first_exchange_fixture.gd")
const FRIENDLY_NODE_NAMES: PackedStringArray = ["UnitAlpha", "UnitBravo", "UnitCharlie", "UnitDelta", "UnitEcho", "UnitFoxtrot", "UnitGolf", "UnitHotel"]
const DEFAULT_META_MAP_PATH: String = "res://maps/Ground_Mission01_32x32.json"
const DEFAULT_META_SCENARIO_PATH: String = "res://data/mission_scenarios/ground_mission01_default.json"
const FRONTIER_VERTICAL_SLICE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const STATION_ROUTE_ONE_SCREEN_SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const NO_SCENARIO_FILE_PATH: String = ""
const HOMEBASE_MISSION_CATALOG: Array = [
	{
		"mission_id": "fob_transfer",
		"mission_name": "Operation: FOB Transfer",
		"map_file_path": DEFAULT_META_MAP_PATH,
		"scenario_file_path": DEFAULT_META_SCENARIO_PATH,
		"slot_count": 8,
		"time_limit_seconds": 1200.0,
	},
	{
		"mission_id": "grid_sweep",
		"mission_name": "Operation: Grid Sweep",
		"map_file_path": DEFAULT_META_MAP_PATH,
		"scenario_file_path": DEFAULT_META_SCENARIO_PATH,
		"slot_count": 3,
		"time_limit_seconds": 1200.0,
	},
	{
		"mission_id": "fireteam_command_drill",
		"mission_name": "Operation: Fireteam Command Drill",
		"map_file_path": "res://maps/fireteam_command_drill_24x24.json",
		"scenario_file_path": "res://data/mission_scenarios/fireteam_command_drill_24x24.json",
		"slot_count": 4,
		"time_limit_seconds": 900.0,
		"win_condition": "elimination",
	},
	{
		"mission_id": "frontier_probe",
		"mission_name": "Operation: Frontier Probe",
		"map_file_path": "res://maps/station_outpost_192x192.json",
		"scenario_file_path": NO_SCENARIO_FILE_PATH,
		"slot_count": 3,
		"time_limit_seconds": 1200.0,
	},
	{
		"mission_id": "frontier_probe_vertical_slice",
		"mission_name": "Operation: Frontier Probe Slice",
		"map_file_path": "res://maps/station_outpost_192x192.json",
		"scenario_file_path": FRONTIER_VERTICAL_SLICE_SCENARIO_PATH,
		"slot_count": 8,
		"time_limit_seconds": 1500.0,
		"win_condition": "objective_capture",
	},
	{
		"mission_id": "station_route_one_screen_multiplayer_drill",
		"mission_name": "Operation: Station Route",
		"map_file_path": "res://maps/station_outpost_192x192.json",
		"scenario_file_path": STATION_ROUTE_ONE_SCREEN_SCENARIO_PATH,
		"slot_count": 8,
		"time_limit_seconds": 900.0,
		"win_condition": "objective_capture",
	},
	{
		"mission_id": "wall_breach",
		"mission_name": "Operation: Wall Breach",
		"map_file_path": "res://maps/wall_test_4x4.json",
		"scenario_file_path": NO_SCENARIO_FILE_PATH,
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
		"texture_path": "res://Assets/kenney_space-kit/Isometric/craft_cargoA_NE.png",
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
const MISSION_DROPSHIP_TO_HOMEBASE_SECONDS: float = 18.0
const MISSION_PREVIEW_ENABLED: bool = false
const MISSION_DROP_SOURCE_FOB := "fob"
const MISSION_DROP_SOURCE_HOMEBASE_DIRECT := "homebase_direct"
const MISSION_DROP_SOURCE_HOMEBASE_DIRECT_THEN_FOB := "homebase_direct_then_fob"
const SINGLEPLAYER_RELEASE_DEFAULT_MISSION_ID := "grid_sweep"
const SINGLEPLAYER_BOOTSTRAP_FIRETEAM_ID := "ft1"
const SINGLEPLAYER_BOOTSTRAP_CRAFT_TYPE := "dropship"
const SINGLEPLAYER_BOOTSTRAP_FIRETEAM_SIZE := 3
const RELEASE_SINGLEPLAYER_START_MISSION_DEEPLINK_ARG := "--release-singleplayer-start-mission"
const RELEASE_SINGLEPLAYER_LZ_DROP_PREVIEW_DEEPLINK_ARG := "--release-singleplayer-lz-drop-preview"
const RELEASE_SINGLEPLAYER_FIRST_GO_FIREFIGHT_DEEPLINK_ARG := "--release-singleplayer-first-go-firefight"
const RELEASE_FIRST_EXCHANGE_EXPORTED_STATUS_TRACE_ENV := "STERNENBUERGERCHEN_RELEASE_FIRST_EXCHANGE_TRACE_PATH"
const RELEASE_FIRST_EXCHANGE_EXPORTED_STATUS_TRACE_ARG_PREFIX := "--release-first-exchange-trace-path="
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
	"mission_drop_source": MISSION_DROP_SOURCE_HOMEBASE_DIRECT,
}

var _available_team_units: Array = UNIT_ROSTER_PRESETS_SCRIPT.get_homebase_roster()
var _singleplayer_runtime: Node
var _game_start_request: Dictionary = {}
var _campaign_start: RefCounted
var _campaign_tutorial: Control
var _active_singleplayer_identity: Dictionary = {}
var _location_registry = preload("res://scripts/mission/location_runtime_registry.gd").new()
var _location_contexts: Dictionary = {}
var _craft_location_runtime: Dictionary = {}
var _view_craft_by_location: Dictionary = {} # UI selection only; never a visit/travel identity.
var _polisa_handoff_requests: Dictionary = {}
var _polisa_purchase_seal_key := str(Time.get_ticks_usec()) + ":" + str(randi())
var _space_approaches: Dictionary = {}
var _surface_preparation_results: Dictionary = {}
var _retired_terrain_workers: Array[Thread] = []
const TERRAIN_PREPARATION_TIMEOUT_MSEC := 180000
var _location_callback_active := false
var _polisa_station_screen: Control
var _singleplayer_services: Control
var _singleplayer_services_elapsed: float = 0.0
var _star_map_screen: Control
var _space_approach_remaining: float = 0.0
var _space_approach_craft_id: String = ""
var _all_team_units: Array = UNIT_ROSTER_PRESETS_SCRIPT.get_homebase_roster()
var _selected_unit_ids: PackedStringArray = []
var _homebase_staged_unit_ids: PackedStringArray = []
var _homebase_staged_fireteam_ids: PackedStringArray = []
var _selected_fireteam_ids: PackedStringArray = []
var _active_mission = null
var _last_mission_result: Dictionary = {}
var _current_meta_view: String = "homebase"
var _mission_catalog: Array = HOMEBASE_MISSION_CATALOG.duplicate(true)
var _selected_mission_id: String = SINGLEPLAYER_RELEASE_DEFAULT_MISSION_ID
var _selected_mission_map_path: String = DEFAULT_META_MAP_PATH
var _homebase_aircraft_definitions: Array = []
var _pending_campaign_mission_result: Dictionary = {}
var _assigned_aircraft_pilot_by_craft: Dictionary = {}
var _aircraft_location_by_craft: Dictionary = {}
var _selected_aircraft_cargo_by_craft: Dictionary = {}
var _loaded_aircraft_cargo_by_craft: Dictionary = {}
var _pending_homebase_team_transfers: Array = []
var _pending_homebase_pilot_transfers: Array = []
var _pending_homebase_cargo_loads: Array = []
var _pending_mission_craft_transfers: Array = []
var _pending_surface_departures: Dictionary = {}
var _surface_departure_serial: int = 0
var _surface_departure_retry_cursor: int = 0
var _air_asset_recovery_by_craft: Dictionary = {}
var _transfer_sequence: int = 0
var _preview_mission = null
var _preview_mission_signature: Dictionary = {}
var _mission_planning_state: Dictionary = DEFAULT_MISSION_PLANNING_STATE.duplicate(true)
var _active_mission_started_at_msec: int = 0
var _active_mission_time_limit_seconds: float = 0.0
var _last_meta_timer_text: String = ""
var _transport_refresh_timing_debug_enabled: bool = false
var _transport_refresh_timing_debug_snapshot: Dictionary = {}
var _runtime_frame_timing_debug_enabled := false
var _runtime_frame_timing_debug = preload("res://scripts/core/frame_timing_accumulator.gd").new()
var _transport_refresh_timing_debug_invocation_count: int = 0
var _homebase_presentation_dirty: bool = false
var _full_plan_apply_count: int = 0
var _transport_delta_apply_count: int = 0
var _unchanged_plan_skip_count: int = 0
var _release_start_mission_deeplink_requested: bool = false
var _release_start_mission_deeplink_applied: bool = false
var _release_start_mission_deeplink_status: String = "idle"
var _release_start_mission_deeplink_reason: String = ""
var _release_lz_drop_preview_deeplink_requested: bool = false
var _release_lz_drop_preview_deeplink_applied: bool = false
var _release_lz_drop_preview_deeplink_status: String = "idle"
var _release_lz_drop_preview_deeplink_reason: String = ""
var _release_first_go_firefight_deeplink_requested: bool = false
var _release_first_go_firefight_deeplink_applied: bool = false
var _release_first_go_firefight_deeplink_status: String = "idle"
var _release_first_go_firefight_deeplink_reason: String = ""
var _release_first_go_firefight_pre_go_passed: bool = false
var _release_first_exchange_los_setup_polish_evidence: Dictionary = {}
var _release_first_exchange_contact_fire_readability_fix_evidence: Dictionary = {}
var _release_first_exchange_exported_status_trace_samples: Array = []


func _ready() -> void:
	set_process(true)
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	var debrief_screen = _get_debrief_screen()
	if homebase_screen == null or fob_screen == null or debrief_screen == null:
		push_warning("MetaLayerFlow requires HomebaseScreen, FOBScreen and DebriefScreen children.")
		return

	_game_start_request = load("res://scripts/meta/game_start_contract.gd").consume_start(get_tree())
	if is_campaign_start():
		_campaign_start = load("res://scripts/meta/campaign_start_configuration.gd").new()
		_campaign_start.call("configure", self, _game_start_request)
		if not String(_campaign_start.get("error_message")).is_empty():
			call_deferred("_campaign_load_failed")
			return
	elif _game_start_request.has("preset_id") or _game_start_request.has("points_draft"):
		load("res://scripts/meta/skirmish_start_configuration.gd").new().configure(self, _game_start_request)
	else:
		_load_persistent_player_roster()
	if not has_meta("skirmish_preset_id"):
		_ensure_singleplayer_release_start_bootstrap()
	META_UI_SKIN_SCRIPT.apply_meta_navigation(self)
	_connect_navigation_buttons()
	_ensure_homebase_aircraft_locations()
	_singleplayer_runtime = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	_singleplayer_runtime.name = "SingleplayerRuntime"
	add_child(_singleplayer_runtime)
	_singleplayer_runtime.call("configure", self, homebase_screen)
	var encounter_layer := CanvasLayer.new()
	encounter_layer.layer=95
	encounter_layer.name="CampaignSpaceEncounterLayer"
	add_child(encounter_layer)
	var encounter_panel=load("res://scripts/meta/campaign_space_encounter_presenter.gd").new()
	encounter_layer.add_child(encounter_panel)
	encounter_panel.configure(_singleplayer_runtime)
	if is_campaign_start():
		_campaign_tutorial = load("res://scripts/meta/campaign_tutorial_presenter.gd").new()
		var tutorial_layer := CanvasLayer.new()
		tutorial_layer.name = "CampaignTutorialLayer"
		tutorial_layer.layer = 110
		add_child(tutorial_layer)
		tutorial_layer.add_child(_campaign_tutorial)
		_campaign_tutorial.call("configure", _singleplayer_runtime, self)
	var service_layer := CanvasLayer.new()
	service_layer.name = "SingleplayerServiceLayer"
	service_layer.layer = 80
	add_child(service_layer)
	_singleplayer_services = load("res://scripts/meta/singleplayer_services_presenter.gd").new()
	_singleplayer_services.name = "MissionServices"
	service_layer.add_child(_singleplayer_services)
	_singleplayer_services.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_singleplayer_services.position = Vector2(get_viewport().get_visible_rect().size.x - 350, 80)
	_singleplayer_services.size = Vector2(330, 0)
	_singleplayer_services.call("configure", Callable(_singleplayer_runtime, "get_snapshot"), Callable(_singleplayer_runtime, "request_operation"))
	_singleplayer_services.hide()
	var star_layer := CanvasLayer.new()
	star_layer.name = "StarMapLayer"
	star_layer.layer = 90
	add_child(star_layer)
	_star_map_screen = load("res://scripts/ui/star_map_screen.gd").new()
	_star_map_screen.name = "StarMapScreen"
	star_layer.add_child(_star_map_screen)
	_star_map_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_star_map_screen.call("configure", Callable(self, "_get_star_map_snapshot"), Callable(self, "_request_star_map_operation"), Callable(self, "_get_star_map_area_projection"))
	_star_map_screen.hide()
	_ensure_meta_nav_timer_labels()

	if not homebase_screen.selection_changed.is_connected(_on_homebase_selection_changed):
		homebase_screen.selection_changed.connect(_on_homebase_selection_changed)
	if homebase_screen.has_signal("fireteam_context_changed") and not homebase_screen.fireteam_context_changed.is_connected(_on_homebase_fireteam_context_changed):
		homebase_screen.fireteam_context_changed.connect(_on_homebase_fireteam_context_changed)
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
	if fob_screen.has_signal("transport_craft_pilot_assigned") and not fob_screen.transport_craft_pilot_assigned.is_connected(_on_fob_transport_craft_pilot_assigned):
		fob_screen.transport_craft_pilot_assigned.connect(_on_fob_transport_craft_pilot_assigned)
	if fob_screen.has_signal("transport_craft_pilot_cleared") and not fob_screen.transport_craft_pilot_cleared.is_connected(_on_fob_transport_craft_pilot_cleared):
		fob_screen.transport_craft_pilot_cleared.connect(_on_fob_transport_craft_pilot_cleared)
	if not debrief_screen.return_to_fob_requested.is_connected(_on_debrief_return_to_fob_requested):
		debrief_screen.return_to_fob_requested.connect(_on_debrief_return_to_fob_requested)
	if not debrief_screen.return_to_homebase_requested.is_connected(_on_debrief_return_to_homebase_requested):
		debrief_screen.return_to_homebase_requested.connect(_on_debrief_return_to_homebase_requested)

	var transport_timer := _get_transport_timer()
	if transport_timer != null and not transport_timer.timeout.is_connected(_on_homebase_transport_timer_timeout):
		transport_timer.timeout.connect(_on_homebase_transport_timer_timeout)

	if _selected_fireteam_ids.size() != _selected_unit_ids.size():
		_selected_fireteam_ids = _build_unassigned_fireteam_selection(_selected_unit_ids)
	_refresh_homebase_screen()
	_seed_singleplayer_bootstrap_homebase_payload()
	_refresh_homebase_screen()
	_ensure_singleplayer_visible_homebase_actionability()
	_refresh_fob_screen()
	fob_screen.set_last_mission_result(_last_mission_result)
	_refresh_map_screen()
	_ensure_transport_timer_state()
	_show_homebase()
	call_deferred("_sync_mission_host_visibility")
	call_deferred("_apply_release_start_mission_deeplink")
	call_deferred("_apply_release_lz_drop_preview_deeplink")
	call_deferred("_apply_release_first_go_firefight_deeplink")


func _process(_delta: float) -> void:
	var profile_enabled := _runtime_frame_timing_debug_enabled
	var frame_started_usec := Time.get_ticks_usec() if profile_enabled else 0
	var scope_started_usec := frame_started_usec
	var scopes: Dictionary = {}
	_poll_retired_terrain_workers()
	for craft_id in _space_approaches.keys():
		if not _space_approaches.has(craft_id): continue
		_space_approaches[craft_id].remaining=maxf(0.0,float(_space_approaches[craft_id].remaining)-_delta)
		if float(_space_approaches[craft_id].remaining)<=0.0: _finish_space_approach(String(craft_id))
	if profile_enabled:
		scopes["travel_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_refresh_meta_mission_timer_labels()
	if profile_enabled:
		scopes["timer_labels_usec"] = Time.get_ticks_usec() - scope_started_usec
	_singleplayer_services_elapsed += _delta
	if _singleplayer_services_elapsed >= 0.25:
		_singleplayer_services_elapsed = 0.0
		if profile_enabled: scope_started_usec = Time.get_ticks_usec()
		_refresh_singleplayer_services()
		if profile_enabled:
			scopes["services_usec"] = Time.get_ticks_usec() - scope_started_usec
			scope_started_usec = Time.get_ticks_usec()
		if _location_contexts.is_empty():
			if not _pending_campaign_mission_result.is_empty(): _on_mission_combat_resolved(_pending_campaign_mission_result.duplicate(true))
		else:
			for id in _location_contexts.keys():
				var pending: Dictionary=_location_contexts[id].get("pending",{})
				if not pending.is_empty(): _on_location_combat_resolved(pending.duplicate(true),_location_registry.get_location(String(id)))
		if profile_enabled: scopes["pending_results_usec"] = Time.get_ticks_usec() - scope_started_usec
		if is_campaign_start() and _singleplayer_runtime != null:
			if profile_enabled: scope_started_usec = Time.get_ticks_usec()
			_singleplayer_runtime.call("observe_campaign_progress")
			if profile_enabled:
				scopes["observe_campaign_usec"] = Time.get_ticks_usec() - scope_started_usec
				scope_started_usec = Time.get_ticks_usec()
			var saved: Dictionary = _campaign_start.call("save_home_checkpoint", self, _singleplayer_runtime)
			if bool(saved.get("ok", false)) or String(saved.get("reason", "")) not in ["away_from_checkpoint", "preparation_in_progress"]:
				set_meta("campaign_checkpoint_result", saved)
			if profile_enabled:
				scopes["checkpoint_usec"] = Time.get_ticks_usec() - scope_started_usec
				scope_started_usec = Time.get_ticks_usec()
			if _campaign_tutorial != null:
				_campaign_tutorial.call("refresh")
			if profile_enabled: scopes["tutorial_usec"] = Time.get_ticks_usec() - scope_started_usec
	if profile_enabled:
		_runtime_frame_timing_debug.record_sample(Engine.get_process_frames(), Time.get_ticks_usec() - frame_started_usec, scopes)


func set_runtime_frame_timing_debug_enabled(enabled: bool) -> void:
	_runtime_frame_timing_debug_enabled = enabled
	if not enabled: _runtime_frame_timing_debug.clear()
	if _campaign_tutorial != null and _campaign_tutorial.has_method("set_runtime_frame_timing_debug_enabled"):
		_campaign_tutorial.call("set_runtime_frame_timing_debug_enabled", enabled)


func get_runtime_frame_timing_debug_snapshot(process_frame: int = -1) -> Dictionary:
	var frame_id := Engine.get_process_frames() if process_frame < 0 else process_frame
	var result: Dictionary = _runtime_frame_timing_debug.get_snapshot(frame_id)
	result["enabled"] = _runtime_frame_timing_debug_enabled
	result["read_only"] = true
	result["tutorial"] = _campaign_tutorial.call("get_runtime_frame_timing_debug_snapshot", frame_id) if _campaign_tutorial != null and _campaign_tutorial.has_method("get_runtime_frame_timing_debug_snapshot") else {}
	return result


func set_transport_refresh_timing_debug_enabled(enabled: bool) -> void:
	_transport_refresh_timing_debug_enabled = enabled
	if not enabled:
		_transport_refresh_timing_debug_snapshot.clear()
		_transport_refresh_timing_debug_invocation_count = 0


func get_transport_refresh_timing_debug_snapshot() -> Dictionary:
	return _transport_refresh_timing_debug_snapshot.duplicate(true)


func get_meta_presentation_debug_snapshot() -> Dictionary:
	return {
		"homebase_dirty": _homebase_presentation_dirty,
		"full_plan_apply_count": _full_plan_apply_count,
		"transport_delta_apply_count": _transport_delta_apply_count,
		"unchanged_plan_skip_count": _unchanged_plan_skip_count,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"snapshot_serialized": false,
	}


func get_selected_unit_ids() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


func get_active_mission():
	return _active_mission


func get_homebase_to_mission_handoff_snapshot() -> Dictionary:
	var selected_mission: Dictionary = _get_selected_mission_definition()
	var active_mission: Node = _active_mission
	var mission_setup: Node = active_mission.get_node_or_null("MissionSetup") if active_mission != null else null
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var planning_state: Dictionary = _mission_planning_state.duplicate(true)
	var mission_setup_snapshot: Dictionary = _build_mission_setup_handoff_snapshot(mission_setup)
	var tactical_snapshot: Dictionary = _build_tactical_controller_handoff_snapshot(tactical_controller)
	var checks: Array = []
	var selected_unit_ids: Array = Array(_selected_unit_ids)
	var selected_fireteam_ids: Array = Array(_selected_fireteam_ids)
	# A handoff snapshot is read-only. For a Homebase-direct launch, report the
	# instantiated MissionSetup payload instead of mutating the flow's retained
	# UI selection while the mission is active.
	if String(planning_state.get("mission_drop_source", "")).strip_edges().to_lower() == MISSION_DROP_SOURCE_HOMEBASE_DIRECT and mission_setup != null:
		var mission_setup_selected_unit_ids: Array = Array(PackedStringArray(mission_setup.get("selected_team_unit_ids")))
		if not mission_setup_selected_unit_ids.is_empty():
			selected_unit_ids = mission_setup_selected_unit_ids
			selected_fireteam_ids = Array(PackedStringArray(mission_setup.get("selected_team_fireteam_ids")))
	var embarked_unit_ids: Array = Array(planning_state.get("embarked_unit_ids", []))
	var mission_setup_unit_ids: Array = Array(mission_setup_snapshot.get("selected_team_unit_ids", []))
	var mission_setup_fireteam_ids: Array = Array(mission_setup_snapshot.get("selected_team_fireteam_ids", []))
	var planning_fireteam_definitions: Array = Array(planning_state.get("selected_fireteam_definitions", []))
	var planning_member_loadouts: Dictionary = Dictionary(planning_state.get("member_loadouts", {}))
	var mission_setup_member_loadouts: Dictionary = Dictionary(mission_setup_snapshot.get("member_loadouts", {}))
	var mission_cards: Array = Array(planning_state.get("mission_drop_cards", []))

	_append_handoff_check(
		checks,
		"active_mission_exists",
		active_mission != null,
		"critical",
		"Homebase start should create or update one active mission."
	)
	_append_handoff_check(
		checks,
		"mission_setup_exists",
		mission_setup != null,
		"critical",
		"Active mission should expose MissionSetup."
	)
	_append_handoff_check(
		checks,
		"mission_selection_matches",
		String(mission_setup_snapshot.get("map_file_path", "")).strip_edges() == String(selected_mission.get("map_file_path", DEFAULT_META_MAP_PATH)).strip_edges() \
			and String(mission_setup_snapshot.get("scenario_file_path", "")).strip_edges() == String(selected_mission.get("scenario_file_path", NO_SCENARIO_FILE_PATH)).strip_edges(),
		"critical",
		"MissionSetup should receive the selected mission map and scenario.",
		{
			"selected_mission_id": String(selected_mission.get("mission_id", "")).strip_edges(),
			"selected_map_path": String(selected_mission.get("map_file_path", DEFAULT_META_MAP_PATH)).strip_edges(),
			"setup_map_path": String(mission_setup_snapshot.get("map_file_path", "")).strip_edges(),
			"selected_scenario_path": String(selected_mission.get("scenario_file_path", NO_SCENARIO_FILE_PATH)).strip_edges(),
			"setup_scenario_path": String(mission_setup_snapshot.get("scenario_file_path", "")).strip_edges(),
		}
	)
	_append_handoff_check(
		checks,
		"unit_selection_matches",
		_arrays_match_ordered(selected_unit_ids, mission_setup_unit_ids) and _arrays_match_ordered(embarked_unit_ids, mission_setup_unit_ids),
		"critical",
		"Selected, embarked and MissionSetup unit IDs should match.",
		{
			"selected_unit_ids": selected_unit_ids.duplicate(true),
			"embarked_unit_ids": embarked_unit_ids.duplicate(true),
			"mission_setup_unit_ids": mission_setup_unit_ids.duplicate(true),
		}
	)
	_append_handoff_check(
		checks,
		"fireteam_selection_matches",
		_arrays_match_ordered(selected_fireteam_ids, mission_setup_fireteam_ids),
		"critical",
		"Selected Fireteam IDs should reach MissionSetup in the same order.",
		{
			"selected_fireteam_ids": selected_fireteam_ids.duplicate(true),
			"mission_setup_fireteam_ids": mission_setup_fireteam_ids.duplicate(true),
		}
	)
	_append_handoff_check(
		checks,
		"fireteam_definitions_present",
		not planning_fireteam_definitions.is_empty() \
			and int(mission_setup_snapshot.get("selected_fireteam_definition_count", 0)) == planning_fireteam_definitions.size(),
		"critical",
		"Fireteam definitions should be copied from Homebase planning into MissionSetup.",
		{
			"planning_definition_count": planning_fireteam_definitions.size(),
			"setup_definition_count": int(mission_setup_snapshot.get("selected_fireteam_definition_count", 0)),
		}
	)
	_append_handoff_check(
		checks,
		"member_loadouts_match",
		not planning_member_loadouts.is_empty() \
			and _member_loadout_keys_match(planning_member_loadouts, mission_setup_member_loadouts),
		"critical",
		"Member loadouts should be preserved across the Handoff.",
		{
			"planning_loadout_unit_ids": _sorted_dictionary_keys(planning_member_loadouts),
			"setup_loadout_unit_ids": _sorted_dictionary_keys(mission_setup_member_loadouts),
		}
	)
	_append_handoff_check(
		checks,
		"dropship_payload_present",
		String(planning_state.get("mission_drop_source", "")).strip_edges() == MISSION_DROP_SOURCE_HOMEBASE_DIRECT \
			and not String(planning_state.get("mission_drop_craft_id", "")).strip_edges().is_empty() \
			and int(planning_state.get("mission_drop_passenger_count", 0)) == mission_setup_unit_ids.size() \
			and not mission_cards.is_empty(),
		"critical",
		"Planning state should keep the Homebase-direct Dropship payload.",
		{
			"mission_drop_source": String(planning_state.get("mission_drop_source", "")).strip_edges(),
			"mission_drop_craft_id": String(planning_state.get("mission_drop_craft_id", "")).strip_edges(),
			"mission_drop_passenger_count": int(planning_state.get("mission_drop_passenger_count", 0)),
			"mission_drop_card_count": mission_cards.size(),
		}
	)
	_append_handoff_check(
		checks,
		"tactical_planning_state_matches",
		bool(tactical_snapshot.get("planning_state_present", false)) \
			and String(tactical_snapshot.get("mission_drop_craft_id", "")).strip_edges() == String(planning_state.get("mission_drop_craft_id", "")).strip_edges(),
		"critical",
		"TacticalController should receive the same planning-state dropship reference.",
		tactical_snapshot
	)
	_append_handoff_check(
		checks,
		"timer_started",
		_active_mission_started_at_msec > 0,
		"critical",
		"Mission timer should start when the Homebase start request launches the mission.",
		{"active_mission_started_at_msec": _active_mission_started_at_msec}
	)

	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"ui_sets_gameplay_truth": false,
		"handoff_id": "homebase_to_mission_launch_handoff_v1",
		"handoff_gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"selected_mission_id": String(selected_mission.get("mission_id", "")).strip_edges(),
		"selected_mission_name": String(selected_mission.get("mission_name", "")).strip_edges(),
		"selected_unit_ids": selected_unit_ids.duplicate(true),
		"selected_fireteam_ids": selected_fireteam_ids.duplicate(true),
		"planning": {
			"mission_drop_source": String(planning_state.get("mission_drop_source", "")).strip_edges(),
			"mission_drop_craft_id": String(planning_state.get("mission_drop_craft_id", "")).strip_edges(),
			"mission_drop_state": String(planning_state.get("mission_drop_state", "")).strip_edges(),
			"mission_drop_passenger_count": int(planning_state.get("mission_drop_passenger_count", 0)),
			"embarked_unit_ids": embarked_unit_ids.duplicate(true),
			"drop_queued_fireteam_ids": Array(planning_state.get("drop_queued_fireteam_ids", [])).duplicate(true),
			"mission_drop_card_count": mission_cards.size(),
			"member_loadout_unit_ids": _sorted_dictionary_keys(planning_member_loadouts),
		},
		"mission_setup": mission_setup_snapshot,
		"tactical_controller": tactical_snapshot,
		"checks": checks,
		"issues": _build_handoff_issue_list(checks),
		"recommended_next_action": "Verify first insertion, LZ selection and first Commander order readability in the live mission HUD.",
	}


func get_release_candidate_mission_launch_actionability_snapshot() -> Dictionary:
	var handoff: Dictionary = get_homebase_to_mission_handoff_snapshot()
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var insertion: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_mission_insertion_first_order_readability_snapshot"):
		insertion = Dictionary(tactical_controller.call("get_mission_insertion_first_order_readability_snapshot"))
	var card_ui: Dictionary = Dictionary(insertion.get("card_ui", {}))
	var insertion_next_step: Dictionary = Dictionary(insertion.get("insertion_next_step", {}))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"handoff_gate_pass",
		String(handoff.get("handoff_gate", "")) == "pass" and int(handoff.get("failed_count", -1)) == 0,
		"critical",
		"Homebase Start Mission should preserve selected team, loadout, dropship and planning data.",
		{"handoff_gate": String(handoff.get("handoff_gate", "")), "failed_count": int(handoff.get("failed_count", -1))}
	)
	_append_handoff_check(
		checks,
		"mission_view_visible",
		_current_meta_view == "mission" and _is_mission_host_visible_for_current_view(),
		"critical",
		"After the Homebase Start Mission button the player should see the Mission view.",
		{"current_meta_view": _current_meta_view, "mission_host_visible_for_current_view": _is_mission_host_visible_for_current_view()}
	)
	_append_handoff_check(
		checks,
		"tactical_controller_present",
		tactical_controller != null and not insertion.is_empty(),
		"critical",
		"Active mission should expose the TacticalController insertion readability snapshot."
	)
	_append_handoff_check(
		checks,
		"insertion_gate_pass",
		String(insertion.get("gate", "")) == "pass" and not bool(insertion.get("ui_sets_gameplay_truth", true)),
		"critical",
		"First mission insertion snapshot should be readable and read-only before the player chooses an LZ.",
		{"gate": String(insertion.get("gate", ""))}
	)
	_append_handoff_check(
		checks,
		"lz_next_step_visible",
		bool(card_ui.get("set_lz_button_present", false)) \
			or String(insertion.get("mission_control_status_text", "")).find("LZ") >= 0 \
			or String(insertion_next_step.get("next_step_text", "")).find("LZ") >= 0,
		"critical",
		"Mission view should expose LZ as the next step after launch.",
		{
			"set_lz_button_present": bool(card_ui.get("set_lz_button_present", false)),
			"mission_control_status_text": String(insertion.get("mission_control_status_text", "")),
			"insertion_next_step_text": String(insertion_next_step.get("next_step_text", "")),
		}
	)
	_append_handoff_check(
		checks,
		"selected_panel_next_step_cue_visible",
		String(insertion_next_step.get("next_step_id", "")) == "set_lz" \
			and String(insertion_next_step.get("next_step_text", "")).find("LZ") >= 0 \
			and String(insertion.get("selected_fireteam_status_text", "")).find("Naechster Griff") >= 0,
		"critical",
		"The selected Fireteam panel should explain LZ/Drop before any units are on the ground.",
		{
			"next_step_id": String(insertion_next_step.get("next_step_id", "")),
			"next_step_text": String(insertion_next_step.get("next_step_text", "")),
			"selected_fireteam_status_text": String(insertion.get("selected_fireteam_status_text", "")),
		}
	)
	_append_handoff_check(
		checks,
		"drop_waits_for_lz",
		not bool(insertion.get("selected_card_has_lz", true)) \
			and bool(card_ui.get("drop_button_present", false)) \
			and bool(card_ui.get("drop_button_disabled", true)),
		"critical",
		"Drop should be visible but disabled until the player has placed an LZ.",
		{
			"selected_card_has_lz": bool(insertion.get("selected_card_has_lz", true)),
			"drop_button_present": bool(card_ui.get("drop_button_present", false)),
			"drop_button_disabled": bool(card_ui.get("drop_button_disabled", true)),
		}
	)
	_append_handoff_check(
		checks,
		"selected_fireteam_and_order_controls_visible",
		_insertion_check_passed(insertion, "selected_fireteam_visible") \
			and _insertion_check_passed(insertion, "first_order_controls_visible"),
		"critical",
		"Mission view should keep the selected Fireteam plus Move/Defend/GO controls readable."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		not bool(handoff.get("ui_sets_gameplay_truth", true)) \
			and bool(insertion.get("read_only", false)) \
			and not bool(insertion.get("ui_sets_gameplay_truth", true)),
		"critical",
		"Launch actionability snapshot reads handoff and mission insertion data only."
	)

	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_reentry_release_candidate_mission_launch_actionability_smoke.v1",
		"task_id": "TASK_811",
		"source_task_id": "TASK_810",
		"singleplayer_path_expected": "MainMenu -> Einzelspieler -> Homebase -> Start Mission -> Mission",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"handoff": handoff,
		"insertion": insertion,
		"insertion_gate": String(insertion.get("gate", "")),
		"mission_drop_craft_id": String(insertion.get("mission_drop_craft_id", "")),
		"selected_payload_count": int(insertion.get("selected_payload_count", 0)),
		"selected_card_has_lz": bool(insertion.get("selected_card_has_lz", false)),
		"set_lz_button_present": bool(card_ui.get("set_lz_button_present", false)),
		"drop_button_present": bool(card_ui.get("drop_button_present", false)),
		"drop_button_disabled": bool(card_ui.get("drop_button_disabled", true)),
		"insertion_next_step": insertion_next_step,
		"insertion_next_step_id": String(insertion_next_step.get("next_step_id", "")),
		"insertion_next_step_text": String(insertion_next_step.get("next_step_text", "")),
		"selected_fireteam_status_text": String(insertion.get("selected_fireteam_status_text", "")),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "fail",
		"recommended_next_task": "TASK_812 - Station Reentry Release Candidate LZ Drop Preview Actionability Smoke",
	}


func get_release_start_mission_deeplink_snapshot(user_args: PackedStringArray = PackedStringArray()) -> Dictionary:
	var args: PackedStringArray = user_args if user_args.size() > 0 else _get_release_cmdline_args()
	var requested: bool = _has_release_start_mission_deeplink_arg(args)
	var actionability: Dictionary = get_release_candidate_mission_launch_actionability_snapshot() if _active_mission != null else {}
	return {
		"schema": "sternenbuergerchen.release_start_mission_deeplink_evidence.v1",
		"task_id": "TASK_830",
		"arg": RELEASE_SINGLEPLAYER_START_MISSION_DEEPLINK_ARG,
		"args": Array(args),
		"requested": requested,
		"applied": _release_start_mission_deeplink_applied,
		"status": _release_start_mission_deeplink_status,
		"reason": _release_start_mission_deeplink_reason,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": _active_mission != null,
		"actionability_status": String(actionability.get("status", "")),
		"insertion_gate": String(actionability.get("insertion_gate", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _get_release_cmdline_args() -> PackedStringArray:
	var normalized := PackedStringArray()
	for arg in OS.get_cmdline_args():
		var text: String = String(arg).strip_edges()
		if not text.is_empty() and not normalized.has(text):
			normalized.append(text)
	for arg in OS.get_cmdline_user_args():
		var text: String = String(arg).strip_edges()
		if not text.is_empty() and not normalized.has(text):
			normalized.append(text)
	return normalized


func _has_release_start_mission_deeplink_arg(args: PackedStringArray) -> bool:
	for arg in args:
		if String(arg).strip_edges() == RELEASE_SINGLEPLAYER_START_MISSION_DEEPLINK_ARG:
			return true
	return false


func _apply_release_start_mission_deeplink(user_args: PackedStringArray = PackedStringArray()) -> void:
	var args: PackedStringArray = user_args if user_args.size() > 0 else _get_release_cmdline_args()
	if not _has_release_start_mission_deeplink_arg(args):
		return
	_release_start_mission_deeplink_requested = true
	_release_start_mission_deeplink_status = "requested"
	_release_start_mission_deeplink_reason = ""
	set_meta("release_start_mission_deeplink_requested", true)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	if _current_meta_view != "homebase":
		_release_start_mission_deeplink_status = "skipped"
		_release_start_mission_deeplink_reason = "current_view_not_homebase"
		return

	var homebase_screen = _get_homebase_screen()
	_ensure_singleplayer_visible_homebase_actionability()
	if homebase_screen == null or not homebase_screen.has_method("request_mission_start"):
		_release_start_mission_deeplink_status = "blocked"
		_release_start_mission_deeplink_reason = "homebase_missing"
		return
	if not _is_singleplayer_visible_homebase_actionable(homebase_screen):
		_release_start_mission_deeplink_status = "blocked"
		_release_start_mission_deeplink_reason = "homebase_not_actionable"
		return

	homebase_screen.call("request_mission_start")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_release_start_mission_deeplink_applied = _current_meta_view == "mission" and _active_mission != null
	_release_start_mission_deeplink_status = "applied" if _release_start_mission_deeplink_applied else "blocked"
	_release_start_mission_deeplink_reason = "" if _release_start_mission_deeplink_applied else "mission_view_not_visible"
	set_meta("release_start_mission_deeplink_applied", _release_start_mission_deeplink_applied)


func get_release_lz_drop_preview_deeplink_snapshot(user_args: PackedStringArray = PackedStringArray()) -> Dictionary:
	var args: PackedStringArray = user_args if user_args.size() > 0 else _get_release_cmdline_args()
	var requested: bool = _has_release_lz_drop_preview_deeplink_arg(args)
	var preview: Dictionary = get_release_candidate_lz_drop_preview_actionability_snapshot() if _active_mission != null else {}
	return {
		"schema": "sternenbuergerchen.release_lz_drop_preview_deeplink_evidence.v1",
		"task_id": "TASK_831",
		"arg": RELEASE_SINGLEPLAYER_LZ_DROP_PREVIEW_DEEPLINK_ARG,
		"args": Array(args),
		"requested": requested,
		"applied": _release_lz_drop_preview_deeplink_applied,
		"status": _release_lz_drop_preview_deeplink_status,
		"reason": _release_lz_drop_preview_deeplink_reason,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": _active_mission != null,
		"preview_status": String(preview.get("status", "")),
		"first_move_gate": String(preview.get("first_move_gate", "")),
		"selected_card_has_lz": bool(preview.get("selected_card_has_lz", false)),
		"deployed_selected_unit_count": int(preview.get("deployed_selected_unit_count", 0)),
		"planned_waypoint_count": int(preview.get("planned_waypoint_count", 0)),
		"waypoint_intent_preview_count": int(preview.get("waypoint_intent_preview_count", 0)),
		"visualized_waypoint_count": int(preview.get("visualized_waypoint_count", 0)),
		"go_ready": bool(preview.get("go_ready", false)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _has_release_lz_drop_preview_deeplink_arg(args: PackedStringArray) -> bool:
	for arg in args:
		if String(arg).strip_edges() == RELEASE_SINGLEPLAYER_LZ_DROP_PREVIEW_DEEPLINK_ARG:
			return true
	return false


func _apply_release_lz_drop_preview_deeplink(user_args: PackedStringArray = PackedStringArray()) -> void:
	var args: PackedStringArray = user_args if user_args.size() > 0 else _get_release_cmdline_args()
	if not _has_release_lz_drop_preview_deeplink_arg(args):
		return
	_release_lz_drop_preview_deeplink_requested = true
	_release_lz_drop_preview_deeplink_status = "requested"
	_release_lz_drop_preview_deeplink_reason = ""
	set_meta("release_lz_drop_preview_deeplink_requested", true)
	_append_release_first_exchange_exported_status_trace_sample("lz_setup_begin", null, {}, args)

	if _active_mission == null:
		var started: bool = await _request_release_start_mission_from_homebase_for_deeplink()
		if not started:
			_release_lz_drop_preview_deeplink_status = "blocked"
			_release_lz_drop_preview_deeplink_reason = "start_mission_failed"
			return
	_append_release_first_exchange_exported_status_trace_sample("lz_mission_started", null, {}, args)

	var handoff: Dictionary = get_homebase_to_mission_handoff_snapshot()
	var planning: Dictionary = Dictionary(handoff.get("planning", {}))
	var craft_id: String = String(planning.get("mission_drop_craft_id", "")).strip_edges()
	if craft_id.is_empty():
		_release_lz_drop_preview_deeplink_status = "blocked"
		_release_lz_drop_preview_deeplink_reason = "missing_mission_drop_craft_id"
		return
	_complete_release_lz_drop_preview_craft_arrival(craft_id)
	var transfer_ready: Dictionary = await _wait_release_lz_setup_condition(func() -> bool:
		var mission: Node = _active_mission
		return mission != null \
			and mission.get_node_or_null("TacticalController") != null \
			and mission.get_node_or_null("Primary3DView") != null
	)
	_append_release_first_exchange_exported_status_trace_sample("lz_transfer_ready", null, {"craft_id": craft_id, "readiness": transfer_ready}, args)
	if not bool(transfer_ready.get("ready", false)):
		_release_lz_drop_preview_deeplink_status = "blocked"
		_release_lz_drop_preview_deeplink_reason = "transfer_runtime_not_ready"
		return

	var active_mission: Node = _active_mission
	var controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var primary_view: Node = active_mission.get_node_or_null("Primary3DView") if active_mission != null else null
	if controller == null or primary_view == null:
		_release_lz_drop_preview_deeplink_status = "blocked"
		_release_lz_drop_preview_deeplink_reason = "mission_controller_or_view_missing"
		return

	var lz_world := Vector2(384.0, 224.0)
	controller.call("_on_mission_dropship_card_set_lz_pressed", craft_id)
	if not bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", lz_world))):
		_release_lz_drop_preview_deeplink_status = "blocked"
		_release_lz_drop_preview_deeplink_reason = "lz_placement_failed"
		return
	_append_release_first_exchange_exported_status_trace_sample("lz_placement_ready", null, {"craft_id": craft_id}, args)
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	var drop_ready: Dictionary = await _wait_release_lz_setup_condition(func() -> bool:
		var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
		return bool(planning_state.get("drop_ship_requested", false))
	)
	if not bool(drop_ready.get("ready", false)):
		_release_lz_drop_preview_deeplink_status = "blocked"
		_release_lz_drop_preview_deeplink_reason = "drop_sequence_not_ready"
		return
	var simulation_root: Node = active_mission.get_node_or_null("SimulationRoot")
	var deploy_start_tick: int = int(simulation_root.call("get_tick")) if simulation_root != null and simulation_root.has_method("get_tick") else -1
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	var deboard_ready: Dictionary = await _wait_release_lz_setup_condition(func() -> bool:
		var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
		var deployed_ids: Array = Array(planning_state.get("deployed_unit_ids", []))
		var current_tick: int = int(simulation_root.call("get_tick")) if simulation_root != null and simulation_root.has_method("get_tick") else deploy_start_tick + 1
		return not deployed_ids.is_empty() \
			and current_tick > deploy_start_tick
	, 8, true)
	_append_release_first_exchange_exported_status_trace_sample("lz_deboard_ready", null, {"craft_id": craft_id, "readiness": deboard_ready}, args)
	if not bool(deboard_ready.get("ready", false)):
		_release_lz_drop_preview_deeplink_status = "blocked"
		_release_lz_drop_preview_deeplink_reason = "deboard_runtime_not_ready"
		return

	var move_target := Vector2(544.0, 288.0)
	if not bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)):
		_release_lz_drop_preview_deeplink_status = "blocked"
		_release_lz_drop_preview_deeplink_reason = "move_preview_failed"
		return
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	var preview_ready: Dictionary = await _wait_release_lz_setup_condition(func() -> bool:
		var preview_snapshot: Dictionary = get_release_candidate_lz_drop_preview_actionability_snapshot()
		return String(preview_snapshot.get("status", "")) == "pass" \
			and int(preview_snapshot.get("planned_waypoint_count", 0)) > 0 \
			and bool(preview_snapshot.get("go_ready", false))
	)
	_append_release_first_exchange_exported_status_trace_sample("lz_preview_ready", null, {"craft_id": craft_id, "readiness": preview_ready}, args)
	if not bool(preview_ready.get("ready", false)):
		_release_lz_drop_preview_deeplink_status = "blocked"
		_release_lz_drop_preview_deeplink_reason = "move_preview_not_ready"
		return

	var snapshot: Dictionary = get_release_lz_drop_preview_deeplink_snapshot(PackedStringArray([RELEASE_SINGLEPLAYER_LZ_DROP_PREVIEW_DEEPLINK_ARG]))
	_release_lz_drop_preview_deeplink_applied = String(snapshot.get("preview_status", "")) == "pass" \
		and String(snapshot.get("first_move_gate", "")) == "pass" \
		and int(snapshot.get("planned_waypoint_count", 0)) > 0
	_release_lz_drop_preview_deeplink_status = "applied" if _release_lz_drop_preview_deeplink_applied else "blocked"
	_release_lz_drop_preview_deeplink_reason = "" if _release_lz_drop_preview_deeplink_applied else "preview_snapshot_not_pass"
	set_meta("release_lz_drop_preview_deeplink_applied", _release_lz_drop_preview_deeplink_applied)


func _request_release_start_mission_from_homebase_for_deeplink() -> bool:
	if _current_meta_view != "homebase":
		return _current_meta_view == "mission" and _active_mission != null
	var homebase_screen = _get_homebase_screen()
	_ensure_singleplayer_visible_homebase_actionability()
	if homebase_screen == null or not homebase_screen.has_method("request_mission_start"):
		return false
	if not _is_singleplayer_visible_homebase_actionable(homebase_screen):
		return false
	homebase_screen.call("request_mission_start")
	var mission_ready: Dictionary = await _wait_release_lz_setup_condition(func() -> bool:
		return _current_meta_view == "mission" and _active_mission != null
	, 12)
	return bool(mission_ready.get("ready", false))


func _complete_release_lz_drop_preview_craft_arrival(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_remove_pending_mission_craft_transfer(normalized_craft_id)
	_complete_mission_craft_transfer({"craft_id": normalized_craft_id, "phase": "to_mission"})
	_sync_homebase_direct_mission_drop_transport_fields()
	_start_or_update_active_mission()


func get_release_first_go_firefight_deeplink_snapshot(user_args: PackedStringArray = PackedStringArray()) -> Dictionary:
	var args: PackedStringArray = user_args if user_args.size() > 0 else _get_release_cmdline_args()
	var requested: bool = _has_release_first_go_firefight_deeplink_arg(args)
	var firefight: Dictionary = get_release_candidate_first_go_firefight_actionability_snapshot() if _active_mission != null else {}
	return {
		"schema": "sternenbuergerchen.release_first_go_firefight_deeplink_evidence.v1",
		"task_id": "TASK_832",
		"arg": RELEASE_SINGLEPLAYER_FIRST_GO_FIREFIGHT_DEEPLINK_ARG,
		"args": Array(args),
		"requested": requested,
		"synthetic_fixture": bool(get_meta("release_first_exchange_synthetic_fixture", false)),
		"applied": _release_first_go_firefight_deeplink_applied,
		"status": _release_first_go_firefight_deeplink_status,
		"reason": _release_first_go_firefight_deeplink_reason,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": _active_mission != null,
		"firefight_status": String(firefight.get("status", "")),
		"pre_go_status": String(firefight.get("pre_go_status", "")),
		"pre_go_was_actionable": _release_first_go_firefight_pre_go_passed,
		"execution_gate": String(firefight.get("execution_gate", "")),
		"contact_gate": String(firefight.get("contact_gate", "")),
		"engagement_gate": String(firefight.get("engagement_gate", "")),
		"go_executed": bool(firefight.get("go_executed", false)),
		"movement_state_count": int(firefight.get("movement_state_count", 0)),
		"selected_contact_count": int(firefight.get("selected_contact_count", 0)),
		"engagement_status": String(firefight.get("engagement_status", "")),
		"fire_event_count": int(firefight.get("fire_event_count", 0)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _has_release_first_go_firefight_deeplink_arg(args: PackedStringArray) -> bool:
	for arg in args:
		if String(arg).strip_edges() == RELEASE_SINGLEPLAYER_FIRST_GO_FIREFIGHT_DEEPLINK_ARG:
			return true
	return false


func _release_first_exchange_exported_status_trace_path(args: PackedStringArray = PackedStringArray()) -> String:
	var env_path: String = OS.get_environment(RELEASE_FIRST_EXCHANGE_EXPORTED_STATUS_TRACE_ENV).strip_edges()
	if not env_path.is_empty():
		return env_path.replace("\\", "/")
	for arg_variant in args:
		var arg: String = String(arg_variant).strip_edges()
		if arg.begins_with(RELEASE_FIRST_EXCHANGE_EXPORTED_STATUS_TRACE_ARG_PREFIX):
			return arg.substr(RELEASE_FIRST_EXCHANGE_EXPORTED_STATUS_TRACE_ARG_PREFIX.length()).strip_edges().replace("\\", "/")
	return ""


func _append_release_first_exchange_exported_status_trace_sample(
	stage: String,
	controller: Node = null,
	extra: Dictionary = {},
	args: PackedStringArray = PackedStringArray()
) -> void:
	var trace_path: String = _release_first_exchange_exported_status_trace_path(args)
	if trace_path.is_empty():
		return
	var sample: Dictionary = _build_release_first_exchange_exported_status_trace_sample(stage, controller, extra)
	_release_first_exchange_exported_status_trace_samples.append(sample)
	_write_release_first_exchange_exported_status_trace(trace_path, sample)


func _build_release_first_exchange_exported_status_trace_sample(stage: String, controller: Node = null, extra: Dictionary = {}) -> Dictionary:
	var command_feedback: Dictionary = {}
	var status_source_snapshot: Dictionary = {}
	if controller != null:
		if controller.has_method("get_command_feedback_snapshot"):
			command_feedback = Dictionary(controller.call("get_command_feedback_snapshot")).duplicate(true)
		if controller.has_method("get_release_first_exchange_visible_status_source_reconciliation_snapshot"):
			status_source_snapshot = Dictionary(controller.call("get_release_first_exchange_visible_status_source_reconciliation_snapshot")).duplicate(true)
	else:
		var compact_density: Dictionary = Dictionary(extra.get("combat_hud_density", {})).duplicate(true)
		var compact_event_log_text: String = String(extra.get("event_log_short_text", "")).strip_edges()
		command_feedback = {
			"combat_hud_density": compact_density,
			"selected_fireteam_status_label_text": String(extra.get("selected_fireteam_status_text", "")),
			"mission_control_status_text": String(extra.get("mission_control_status_text", "")),
			"release_firefight_event_log_display": {
				"fallback_entry": {"short_text": compact_event_log_text},
			},
		}
	var combat_hud_density: Dictionary = Dictionary(command_feedback.get("combat_hud_density", {})).duplicate(true)
	var visibility_persistence: Dictionary = Dictionary(combat_hud_density.get("visibility_persistence", {})).duplicate(true)
	var event_log_display: Dictionary = Dictionary(command_feedback.get("release_firefight_event_log_display", {})).duplicate(true)
	var fallback_entry: Dictionary = Dictionary(event_log_display.get("fallback_entry", {})).duplicate(true)
	var selected_text: String = String(command_feedback.get("selected_fireteam_status_label_text", command_feedback.get("selected_status_text", ""))).strip_edges()
	if selected_text.is_empty():
		selected_text = String(status_source_snapshot.get("selected_fireteam_status_text", "")).strip_edges()
	var mission_text: String = String(command_feedback.get("mission_control_status_text", "")).strip_edges()
	if mission_text.is_empty():
		mission_text = String(status_source_snapshot.get("mission_control_status_text", "")).strip_edges()
	var event_log_text: String = String(fallback_entry.get("short_text", status_source_snapshot.get("event_log_short_text", ""))).strip_edges()
	var timestamp_msec: int = Time.get_ticks_msec()
	var first_timestamp_msec: int = timestamp_msec
	var previous_timestamp_msec: int = timestamp_msec
	if not _release_first_exchange_exported_status_trace_samples.is_empty():
		var first_sample: Dictionary = Dictionary(_release_first_exchange_exported_status_trace_samples[0])
		var previous_sample: Dictionary = Dictionary(_release_first_exchange_exported_status_trace_samples.back())
		first_timestamp_msec = int(first_sample.get("timestamp_msec", timestamp_msec))
		previous_timestamp_msec = int(previous_sample.get("timestamp_msec", timestamp_msec))
	return {
		"stage": String(stage).strip_edges(),
		"timestamp_msec": timestamp_msec,
		"elapsed_msec": maxi(timestamp_msec - first_timestamp_msec, 0),
		"delta_msec": maxi(timestamp_msec - previous_timestamp_msec, 0),
		"deeplink_requested": _release_first_go_firefight_deeplink_requested,
		"deeplink_applied": _release_first_go_firefight_deeplink_applied,
		"deeplink_status": _release_first_go_firefight_deeplink_status,
		"deeplink_reason": _release_first_go_firefight_deeplink_reason,
		"pre_go_passed": _release_first_go_firefight_pre_go_passed,
		"active_mission_exists": _active_mission != null,
		"controller_present": controller != null,
		"contact_fire_readability_fix_status": String(_release_first_exchange_contact_fire_readability_fix_evidence.get("status", "")),
		"contact_fire_readability_fix_active": bool(_release_first_exchange_contact_fire_readability_fix_evidence.get("active", false)),
		"status_source_snapshot_present": not status_source_snapshot.is_empty(),
		"status_source_snapshot_gate": String(status_source_snapshot.get("gate", "")),
		"status_source_active": bool(status_source_snapshot.get("active", false)),
		"status_source_style_id": String(status_source_snapshot.get("style_id", "")),
		"combat_hud_density_active": bool(combat_hud_density.get("active", false)),
		"combat_hud_density_source": String(combat_hud_density.get("source", "")),
		"combat_hud_density_compact_line": String(combat_hud_density.get("compact_line", "")).strip_edges(),
		"combat_hud_density_visibility_active": bool(combat_hud_density.get("visibility_persistence_active", false)),
		"combat_hud_density_status_source_active": bool(combat_hud_density.get("release_first_exchange_visible_status_source_active", false)),
		"combat_hud_density_status_source_style_id": String(combat_hud_density.get("release_first_exchange_visible_status_source_style_id", "")),
		"visibility_persistence_task_id": String(visibility_persistence.get("task_id", "")),
		"visibility_persistence_style_id": String(visibility_persistence.get("style_id", "")),
		"selected_fireteam_status_text": selected_text,
		"mission_control_status_text": mission_text,
		"event_log_short_text": event_log_text,
		"selected_starts_contact_fire": selected_text.to_upper().begins_with("CONTACT FIRE"),
		"mission_starts_contact_fire": mission_text.to_upper().begins_with("CONTACT FIRE"),
		"event_log_contains_contact_fire": event_log_text.to_upper().contains("CONTACT FIRE"),
		"selected_contains_no_los": selected_text.to_upper().contains("NO_LOS") or selected_text.to_upper().contains("LOS/RANGE"),
		"mission_contains_no_los": mission_text.to_upper().contains("NO_LOS") or mission_text.to_upper().contains("LOS/RANGE"),
		"event_log_contains_contact_pressure": event_log_text.to_upper().contains("CONTACT PRESSURE"),
		"extra": extra.duplicate(true),
	}


func _build_release_first_exchange_compact_trace_extra(extra: Dictionary = {}) -> Dictionary:
	var result: Dictionary = extra.duplicate(true)
	var evidence: Dictionary = _release_first_exchange_contact_fire_readability_fix_evidence
	var source_density: Dictionary = Dictionary(evidence.get("combat_hud_density", {}))
	var source_visibility: Dictionary = Dictionary(source_density.get("visibility_persistence", {}))
	result["combat_hud_density"] = {
		"active": bool(source_density.get("active", false)),
		"source": String(source_density.get("source", "")),
		"compact_line": String(source_density.get("compact_line", "")),
		"visibility_persistence_active": bool(source_density.get("visibility_persistence_active", false)),
		"release_first_exchange_visible_status_source_active": bool(source_density.get("release_first_exchange_visible_status_source_active", false)),
		"release_first_exchange_visible_status_source_style_id": String(source_density.get("release_first_exchange_visible_status_source_style_id", "")),
		"visibility_persistence": {
			"task_id": String(source_visibility.get("task_id", "")),
			"style_id": String(source_visibility.get("style_id", "")),
		},
	}
	for key in [
		"selected_fireteam_status_text",
		"mission_control_status_text",
		"event_log_short_text",
	]:
		if evidence.has(key):
			result[key] = evidence.get(key)
	return result


func _write_release_first_exchange_exported_status_trace(trace_path: String, latest_sample: Dictionary) -> void:
	var activation_observed: bool = false
	var final_sample: Dictionary = latest_sample.duplicate(true)
	for sample_variant in _release_first_exchange_exported_status_trace_samples:
		var sample: Dictionary = Dictionary(sample_variant)
		if bool(sample.get("status_source_active", false)) \
				or bool(sample.get("combat_hud_density_status_source_active", false)) \
				or String(sample.get("visibility_persistence_task_id", "")) == "TASK_876":
			activation_observed = true
	var final_no_los_or_pressure: bool = bool(final_sample.get("selected_contains_no_los", false)) \
		or bool(final_sample.get("mission_contains_no_los", false)) \
		or bool(final_sample.get("event_log_contains_contact_pressure", false))
	var payload: Dictionary = {
		"schema": "sternenbuergerchen.release_first_exchange_exported_status_source_trace_runtime.v1",
		"task_id": "TASK_879",
		"source_task_id": "TASK_878",
		"source_visible_status_task_id": "TASK_876",
		"source_readability_task_id": "TASK_873",
		"trace_path": trace_path,
		"sample_count": _release_first_exchange_exported_status_trace_samples.size(),
		"activation_observed": activation_observed,
		"final_no_los_or_contact_pressure_observed": final_no_los_or_pressure,
		"latest_sample": latest_sample.duplicate(true),
		"samples": _release_first_exchange_exported_status_trace_samples.duplicate(true),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}
	var file := FileAccess.open(trace_path, FileAccess.WRITE)
	if file == null:
		push_warning("TASK_879 trace could not write %s" % trace_path)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func _apply_release_first_go_firefight_deeplink(user_args: PackedStringArray = PackedStringArray()) -> void:
	var args: PackedStringArray = user_args if user_args.size() > 0 else _get_release_cmdline_args()
	if not _has_release_first_go_firefight_deeplink_arg(args):
		return
	_release_first_exchange_exported_status_trace_samples = []
	_release_first_go_firefight_deeplink_requested = true
	_release_first_go_firefight_deeplink_status = "requested"
	_release_first_go_firefight_deeplink_reason = ""
	set_meta("release_first_go_firefight_deeplink_requested", true)
	set_meta("release_first_exchange_synthetic_fixture", true)
	_append_release_first_exchange_exported_status_trace_sample("deeplink_requested", null, {"synthetic_fixture": true}, args)

	await get_tree().process_frame
	await _apply_release_lz_drop_preview_deeplink(PackedStringArray([RELEASE_SINGLEPLAYER_LZ_DROP_PREVIEW_DEEPLINK_ARG]))
	var first_go_lz_ready: Dictionary = await _wait_release_lz_setup_condition(func() -> bool:
		var mission: Node = _active_mission
		return _release_lz_drop_preview_deeplink_applied \
			and mission != null \
			and mission.get_node_or_null("TacticalController") != null \
			and mission.get_node_or_null("CombatLoopDriver") != null \
			and mission.get_node_or_null("SimulationRoot") != null
	)
	_append_release_first_exchange_exported_status_trace_sample("first_go_lz_setup_ready", null, first_go_lz_ready, args)
	if not bool(first_go_lz_ready.get("ready", false)):
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = "lz_drop_preview_failed"
		_append_release_first_exchange_exported_status_trace_sample("blocked_lz_drop_preview_failed", null, {"reason": _release_first_go_firefight_deeplink_reason, "readiness": first_go_lz_ready}, args)
		return

	var active_mission: Node = _active_mission
	var controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var combat_driver: Node = active_mission.get_node_or_null("CombatLoopDriver") if active_mission != null else null
	var simulation_root: Node = active_mission.get_node_or_null("SimulationRoot") if active_mission != null else null
	if controller == null or combat_driver == null or simulation_root == null:
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = "mission_runtime_nodes_missing"
		_append_release_first_exchange_exported_status_trace_sample("blocked_mission_runtime_nodes_missing", controller, {"reason": _release_first_go_firefight_deeplink_reason}, args)
		return
	_append_release_first_exchange_exported_status_trace_sample("mission_runtime_nodes_ready", null, {}, args)

	var pre_go: Dictionary = get_release_candidate_lz_drop_preview_actionability_snapshot()
	var first_move: Dictionary = Dictionary(pre_go.get("first_move", {}))
	var selected_fireteam_id: String = _first_release_fireteam_id(first_move)
	_release_first_go_firefight_pre_go_passed = String(pre_go.get("status", "")) == "pass"
	_append_release_first_exchange_exported_status_trace_sample("pre_go_snapshot", controller, {
		"pre_go_status": String(pre_go.get("status", "")),
		"selected_fireteam_id": selected_fireteam_id,
	}, args)
	if not _release_first_go_firefight_pre_go_passed or selected_fireteam_id.is_empty():
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = "pre_go_not_actionable"
		_append_release_first_exchange_exported_status_trace_sample("blocked_pre_go_not_actionable", controller, {"reason": _release_first_go_firefight_deeplink_reason}, args)
		return
	if not bool(controller.call("execute_selected_fireteam_orders")):
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = "go_execution_failed"
		_append_release_first_exchange_exported_status_trace_sample("blocked_go_execution_failed", controller, {"reason": _release_first_go_firefight_deeplink_reason}, args)
		return
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	_append_release_first_exchange_exported_status_trace_sample("after_go_execute_refresh", null, {"selected_fireteam_id": selected_fireteam_id}, args)
	var go_ready: Dictionary = await _wait_release_first_go_runtime_ready(controller, simulation_root)
	_append_release_first_exchange_exported_status_trace_sample("after_go_runtime_ready", null, go_ready, args)
	if not bool(go_ready.get("ready", false)):
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = "go_runtime_not_ready"
		_append_release_first_exchange_exported_status_trace_sample("blocked_go_runtime_not_ready", controller, go_ready, args)
		return

	var release_fixture = RELEASE_FIRST_EXCHANGE_FIXTURE_SCRIPT.new()
	var fixture_result: Dictionary = await release_fixture.prepare(get_tree(), controller, combat_driver, simulation_root, selected_fireteam_id)
	var contact_setup: Dictionary = Dictionary(fixture_result.get("contact_setup", {})).duplicate(true)
	if String(fixture_result.get("status", "")) != "prepared" or contact_setup.is_empty():
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = String(fixture_result.get("reason", "contact_setup_failed"))
		_append_release_first_exchange_exported_status_trace_sample("blocked_contact_setup_failed", controller, {
			"reason": _release_first_go_firefight_deeplink_reason,
			"synthetic_fixture": true,
		}, args)
		return
	_release_first_exchange_los_setup_polish_evidence = contact_setup.duplicate(true)
	set_meta("release_first_exchange_los_setup_polish_evidence", _release_first_exchange_los_setup_polish_evidence)
	_append_release_first_exchange_exported_status_trace_sample("after_contact_setup", null, {
		"contact_setup": contact_setup.duplicate(true),
		"synthetic_fixture": true,
	}, args)
	_append_release_first_exchange_exported_status_trace_sample("engagement_commands_ready", null, {
		"command_queue_count": int(fixture_result.get("command_queue_count", 0)),
		"synthetic_fixture": true,
	}, args)
	_append_release_first_exchange_exported_status_trace_sample("engagement_authority_tick_ready", null, {
		"simulation_tick": int(fixture_result.get("simulation_tick", -1)),
		"command_queue_count": int(fixture_result.get("command_queue_count", 0)),
		"synthetic_fixture": true,
	}, args)
	_append_release_first_exchange_exported_status_trace_sample("engagement_contact_tracking_ready", null, {
		"selected_contact_count": int(fixture_result.get("selected_contact_count", 0)),
		"synthetic_fixture": true,
	}, args)
	var fire_events_after_decision: Array = Array(combat_driver.call("get_fire_event_snapshot")) if combat_driver.has_method("get_fire_event_snapshot") else []
	_append_release_first_exchange_exported_status_trace_sample("engagement_fire_event_ready", null, {
		"fire_event_count": fire_events_after_decision.size(),
		"first_fire_event_id": String(Dictionary(fire_events_after_decision[0]).get("event_id", "")) if not fire_events_after_decision.is_empty() else "",
		"synthetic_fixture": true,
	}, args)
	controller.call("refresh_contact_overlay")
	controller.call("refresh_fireteam_security_state")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	_append_release_first_exchange_exported_status_trace_sample("engagement_visual_feedback_ready", null, {}, args)
	var immediate_exchange_evidence: Dictionary = _build_release_first_exchange_immediate_evidence(controller)
	set_meta("release_first_exchange_tension_tuning_evidence", immediate_exchange_evidence)
	_append_release_first_exchange_exported_status_trace_sample("engagement_evidence_ready", null, {
		"immediate_exchange_status": String(immediate_exchange_evidence.get("status", "")),
		"first_exchange_visible": bool(immediate_exchange_evidence.get("first_exchange_visible", false)),
	}, args)
	_append_release_first_exchange_exported_status_trace_sample("after_immediate_exchange_evidence", null, {"immediate_exchange_status": String(immediate_exchange_evidence.get("status", ""))}, args)
	var immediate_tactical_exchange: Dictionary = Dictionary(immediate_exchange_evidence.get("tactical_exchange", {})).duplicate(true)
	if controller.has_method("apply_release_first_exchange_contact_fire_readability_fix"):
		_release_first_exchange_contact_fire_readability_fix_evidence = Dictionary(controller.call(
			"apply_release_first_exchange_contact_fire_readability_fix",
			immediate_tactical_exchange
		)).duplicate(true)
		set_meta("release_first_exchange_contact_fire_readability_fix_evidence", _release_first_exchange_contact_fire_readability_fix_evidence)
		_append_release_first_exchange_exported_status_trace_sample("after_contact_fire_readability_fix", null, _build_release_first_exchange_compact_trace_extra({
			"readability_status": String(_release_first_exchange_contact_fire_readability_fix_evidence.get("status", "")),
			"readability_active": bool(_release_first_exchange_contact_fire_readability_fix_evidence.get("active", false)),
		}), args)
	elif controller.has_method("record_release_fire_exchange_visibility_evidence"):
		controller.call("record_release_fire_exchange_visibility_evidence", immediate_tactical_exchange)
		controller.call("_refresh_world_overlays")
		controller.call("_update_ui")
		_append_release_first_exchange_exported_status_trace_sample("after_visibility_evidence_fallback", null, _build_release_first_exchange_compact_trace_extra({"fallback": true}), args)
	var immediate_exchange_applied: bool = String(immediate_exchange_evidence.get("status", "")) == "pass" \
		and bool(immediate_exchange_evidence.get("first_exchange_visible", false))
	if immediate_exchange_applied:
		_release_first_go_firefight_deeplink_applied = true
		_release_first_go_firefight_deeplink_status = "applied"
		_release_first_go_firefight_deeplink_reason = ""
		set_meta("release_first_go_firefight_deeplink_applied", true)
	_append_release_first_exchange_exported_status_trace_sample("after_immediate_exchange_applied_gate", null, _build_release_first_exchange_compact_trace_extra({"immediate_exchange_applied": immediate_exchange_applied}), args)
	var visible_ready: Dictionary = await _wait_release_first_exchange_visible_ready(controller)
	_append_release_first_exchange_exported_status_trace_sample("after_final_wait_before_snapshot", null, _build_release_first_exchange_compact_trace_extra(visible_ready), args)
	if not bool(visible_ready.get("ready", false)):
		_release_first_go_firefight_deeplink_applied = false
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = "first_exchange_visible_not_ready"
		set_meta("release_first_go_firefight_deeplink_applied", false)
		_append_release_first_exchange_exported_status_trace_sample("blocked_first_exchange_visible_not_ready", controller, visible_ready, args)
		return

	var snapshot: Dictionary = get_release_first_go_firefight_deeplink_snapshot(PackedStringArray([RELEASE_SINGLEPLAYER_FIRST_GO_FIREFIGHT_DEEPLINK_ARG]))
	_release_first_go_firefight_deeplink_applied = immediate_exchange_applied \
		or (String(snapshot.get("firefight_status", "")) == "pass" \
			and bool(snapshot.get("go_executed", false)) \
			and int(snapshot.get("selected_contact_count", 0)) > 0 \
			and not String(snapshot.get("engagement_status", "")).strip_edges().is_empty())
	_release_first_go_firefight_deeplink_status = "applied" if _release_first_go_firefight_deeplink_applied else "blocked"
	_release_first_go_firefight_deeplink_reason = "" if _release_first_go_firefight_deeplink_applied else "firefight_snapshot_not_pass"
	set_meta("release_first_go_firefight_deeplink_applied", _release_first_go_firefight_deeplink_applied)
	_append_release_first_exchange_exported_status_trace_sample("deeplink_final", null, _build_release_first_exchange_compact_trace_extra(snapshot), args)


func _wait_release_first_go_runtime_ready(controller: Node, simulation_root: Node, max_checks: int = 8) -> Dictionary:
	var last_snapshot: Dictionary = {}
	var start_tick: int = int(simulation_root.call("get_tick")) if simulation_root != null and simulation_root.has_method("get_tick") else -1
	for check_index in range(maxi(max_checks, 1)):
		await get_tree().physics_frame
		await get_tree().process_frame
		var command_queue_empty: bool = true
		var command_queue_count: int = 0
		if simulation_root != null:
			var queue_variant: Variant = simulation_root.get("command_queue")
			if typeof(queue_variant) == TYPE_ARRAY:
				command_queue_count = Array(queue_variant).size()
				command_queue_empty = command_queue_count == 0
		var execution: Dictionary = {}
		if controller != null and controller.has_method("get_mission_first_move_execution_feedback_snapshot"):
			execution = Dictionary(controller.call("get_mission_first_move_execution_feedback_snapshot"))
		var go_feedback_visible: bool = _insertion_check_passed(execution, "go_feedback_visible")
		var movement_state_visible: bool = _insertion_check_passed(execution, "movement_state_visible")
		var current_tick: int = int(simulation_root.call("get_tick")) if simulation_root != null and simulation_root.has_method("get_tick") else start_tick + 1
		var authoritative_tick_advanced: bool = current_tick > start_tick
		var ready: bool = authoritative_tick_advanced \
			and String(execution.get("gate", "")) == "pass" \
			and go_feedback_visible \
			and movement_state_visible
		last_snapshot = {
			"ready": ready,
			"checks": check_index + 1,
			"command_queue_empty": command_queue_empty,
			"command_queue_count": command_queue_count,
			"start_tick": start_tick,
			"current_tick": current_tick,
			"authoritative_tick_advanced": authoritative_tick_advanced,
			"execution_gate": String(execution.get("gate", "")),
			"go_feedback_visible": go_feedback_visible,
			"movement_state_visible": movement_state_visible,
		}
		if ready:
			return last_snapshot
	return last_snapshot


func _wait_release_first_exchange_visible_ready(controller: Node, max_checks: int = 8) -> Dictionary:
	for check_index in range(maxi(max_checks, 1)):
		await get_tree().process_frame
		var feedback: Dictionary = {}
		var source: Dictionary = {}
		if controller != null and controller.has_method("get_command_feedback_snapshot"):
			feedback = Dictionary(controller.call("get_command_feedback_snapshot"))
		if controller != null and controller.has_method("get_release_first_exchange_visible_status_source_reconciliation_snapshot"):
			source = Dictionary(controller.call("get_release_first_exchange_visible_status_source_reconciliation_snapshot"))
		var status_source: Dictionary = Dictionary(source.get("status_source", {}))
		var fire_event_id: String = String(status_source.get("fire_event_id", "")).strip_edges()
		var selected_text: String = String(feedback.get("selected_fireteam_status_label_text", "")).strip_edges()
		var mission_text: String = String(feedback.get("mission_control_status_text", "")).strip_edges()
		var ready: bool = bool(source.get("active", false)) \
			and not fire_event_id.is_empty() \
			and selected_text.to_upper().begins_with("CONTACT FIRE") \
			and mission_text.to_upper().begins_with("CONTACT FIRE")
		if ready:
			return {
				"ready": true,
				"checks": check_index + 1,
				"fire_event_id": fire_event_id,
				"status_source_active": true,
			}
	return {"ready": false, "checks": maxi(max_checks, 1), "status_source_active": false}


func _first_release_fireteam_id(first_move: Dictionary) -> String:
	for fireteam_id_variant in Array(first_move.get("selected_fireteam_ids", [])):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			return fireteam_id
	return ""


func _wait_release_deeplink_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _wait_release_lz_setup_condition(predicate: Callable, max_checks: int = 8, include_physics_tick: bool = false) -> Dictionary:
	var bounded_checks: int = maxi(max_checks, 1)
	for check_index in range(bounded_checks):
		if predicate.is_valid() and bool(predicate.call()):
			return {"ready": true, "checks": check_index}
		if include_physics_tick:
			await get_tree().physics_frame
		await get_tree().process_frame
	var ready_after_wait: bool = predicate.is_valid() and bool(predicate.call())
	return {"ready": ready_after_wait, "checks": bounded_checks}


func get_release_candidate_lz_drop_preview_actionability_snapshot() -> Dictionary:
	var handoff: Dictionary = get_homebase_to_mission_handoff_snapshot()
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var insertion: Dictionary = {}
	var first_move: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_mission_insertion_first_order_readability_snapshot"):
		insertion = Dictionary(tactical_controller.call("get_mission_insertion_first_order_readability_snapshot"))
	if tactical_controller != null and tactical_controller.has_method("get_mission_first_move_decision_readability_snapshot"):
		first_move = Dictionary(tactical_controller.call("get_mission_first_move_decision_readability_snapshot"))
	var launch_handoff_reached: bool = String(handoff.get("handoff_gate", "")) == "pass" and int(handoff.get("failed_count", -1)) == 0
	if not launch_handoff_reached:
		launch_handoff_reached = active_mission != null \
			and _current_meta_view == "mission" \
			and _is_mission_host_visible_for_current_view() \
			and not insertion.is_empty() \
			and not first_move.is_empty()
	var checks: Array = []
	_append_handoff_check(
		checks,
		"handoff_gate_pass",
		launch_handoff_reached,
		"critical",
		"LZ/Drop/Preview smoke should build on a reached Homebase-to-Mission handoff."
	)
	_append_handoff_check(
		checks,
		"mission_view_visible",
		_current_meta_view == "mission" and _is_mission_host_visible_for_current_view(),
		"critical",
		"LZ/Drop/Preview smoke should run while the Mission view is visible."
	)
	_append_handoff_check(
		checks,
		"tactical_controller_present",
		tactical_controller != null and not insertion.is_empty() and not first_move.is_empty(),
		"critical",
		"Active mission should expose insertion and first-move readability snapshots."
	)
	_append_handoff_check(
		checks,
		"lz_was_set",
		bool(insertion.get("selected_card_has_lz", false)) or int(insertion.get("lz_marker_count", 0)) > 0,
		"critical",
		"Selected dropship should have an LZ before the drop/preview phase.",
		{
			"selected_card_has_lz": bool(insertion.get("selected_card_has_lz", false)),
			"lz_marker_count": int(insertion.get("lz_marker_count", 0)),
			"dropship_lz_label_count": int(insertion.get("dropship_lz_label_count", 0)),
		}
	)
	_append_handoff_check(
		checks,
		"selected_fireteam_deployed",
		_insertion_check_passed(first_move, "selected_fireteam_deployed") \
			and Array(first_move.get("deployed_selected_unit_ids", [])).size() > 0,
		"critical",
		"Drop should deploy the selected Fireteam before the first move preview."
	)
	_append_handoff_check(
		checks,
		"first_move_preview_gate_pass",
		String(first_move.get("gate", "")) == "pass" and not bool(first_move.get("ui_sets_gameplay_truth", true)),
		"critical",
		"First move decision snapshot should pass after planning and remain read-only.",
		{"gate": String(first_move.get("gate", ""))}
	)
	_append_handoff_check(
		checks,
		"preview_before_go_visible",
		_insertion_check_passed(first_move, "planned_waypoint_present") \
			and _insertion_check_passed(first_move, "waypoint_preview_visible") \
			and _insertion_check_passed(first_move, "waypoint_visualized"),
		"critical",
		"Move preview, path/ghost visualization and planned waypoint should be visible before GO."
	)
	_append_handoff_check(
		checks,
		"go_ready_not_executed",
		_insertion_check_passed(first_move, "go_ready") and int(first_move.get("planned_waypoint_count", 0)) > 0,
		"critical",
		"GO should be ready for the planned move, while the snapshot still represents the pre-GO preview state."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		not bool(handoff.get("ui_sets_gameplay_truth", true)) \
			and bool(insertion.get("read_only", false)) \
			and not bool(insertion.get("ui_sets_gameplay_truth", true)) \
			and bool(first_move.get("read_only", false)) \
			and not bool(first_move.get("ui_sets_gameplay_truth", true)),
		"critical",
		"LZ/Drop/Preview actionability snapshot reads existing mission state only."
	)

	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_reentry_release_candidate_lz_drop_preview_actionability_smoke.v1",
		"task_id": "TASK_812",
		"source_task_id": "TASK_811",
		"singleplayer_path_expected": "MainMenu -> Einzelspieler -> Homebase -> Start Mission -> LZ -> Drop -> Move Preview",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"handoff": handoff,
		"insertion": insertion,
		"first_move": first_move,
		"insertion_gate": String(insertion.get("gate", "")),
		"first_move_gate": String(first_move.get("gate", "")),
		"mission_drop_craft_id": String(insertion.get("mission_drop_craft_id", first_move.get("mission_drop_craft_id", ""))),
		"selected_card_has_lz": bool(insertion.get("selected_card_has_lz", false)),
		"selected_payload_count": int(insertion.get("selected_payload_count", 0)),
		"deployed_selected_unit_count": Array(first_move.get("deployed_selected_unit_ids", [])).size(),
		"planned_waypoint_count": int(first_move.get("planned_waypoint_count", 0)),
		"waypoint_intent_preview_count": int(first_move.get("waypoint_intent_preview_count", 0)),
		"visualized_waypoint_count": int(first_move.get("visualized_waypoint_count", 0)),
		"go_ready": bool(first_move.get("go_ready", false)),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "fail",
		"recommended_next_task": "TASK_813 - Station Reentry Release Candidate First GO Firefight Actionability Smoke",
	}


func get_release_candidate_first_go_firefight_actionability_snapshot() -> Dictionary:
	var pre_go: Dictionary = get_release_candidate_lz_drop_preview_actionability_snapshot()
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var execution: Dictionary = {}
	var contact: Dictionary = {}
	var engagement: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_mission_first_move_execution_feedback_snapshot"):
		execution = Dictionary(tactical_controller.call("get_mission_first_move_execution_feedback_snapshot"))
	if tactical_controller != null and tactical_controller.has_method("get_mission_first_contact_readability_snapshot"):
		contact = Dictionary(tactical_controller.call("get_mission_first_contact_readability_snapshot"))
	if tactical_controller != null and tactical_controller.has_method("get_mission_first_engagement_feedback_snapshot"):
		engagement = Dictionary(tactical_controller.call("get_mission_first_engagement_feedback_snapshot"))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"pre_go_chain_was_actionable",
		String(pre_go.get("status", "")) == "pass" or (
			bool(pre_go.get("selected_card_has_lz", false)) \
				and int(pre_go.get("deployed_selected_unit_count", 0)) > 0 \
				and int(pre_go.get("planned_waypoint_count", 0)) > 0
		),
		"critical",
		"First GO/Firefight smoke should build on a readable LZ/Drop/Preview chain."
	)
	_append_handoff_check(
		checks,
		"mission_view_visible",
		_current_meta_view == "mission" and _is_mission_host_visible_for_current_view(),
		"critical",
		"First GO/Firefight smoke should run while the Mission view is visible."
	)
	_append_handoff_check(
		checks,
		"tactical_controller_present",
		tactical_controller != null and not execution.is_empty() and not contact.is_empty() and not engagement.is_empty(),
		"critical",
		"Active mission should expose execution, contact and engagement readability snapshots."
	)
	_append_handoff_check(
		checks,
		"go_execution_visible",
		String(execution.get("gate", "")) == "pass" \
			and _insertion_check_passed(execution, "go_feedback_visible") \
			and _insertion_check_passed(execution, "movement_state_visible"),
		"critical",
		"GO should create readable execution and movement feedback for the selected Fireteam.",
		{
			"execution_gate": String(execution.get("gate", "")),
			"movement_state_count": int(execution.get("movement_state_count", 0)),
		}
	)
	_append_handoff_check(
		checks,
		"first_contact_visible",
		String(contact.get("gate", "")) == "pass" \
			and _insertion_check_passed(contact, "selected_fireteam_has_contact") \
			and _insertion_check_passed(contact, "contact_report_text_visible"),
		"critical",
		"First contact should be readable as contact entry, report text and tactical feedback.",
		{
			"contact_gate": String(contact.get("gate", "")),
			"selected_contact_count": int(contact.get("selected_contact_count", 0)),
		}
	)
	_append_handoff_check(
		checks,
		"first_engagement_feedback_visible",
		String(engagement.get("gate", "")) == "pass" \
			and _insertion_check_passed(engagement, "engagement_decision_visible") \
			and _insertion_check_passed(engagement, "target_or_block_reason_visible") \
			and _insertion_check_passed(engagement, "feedback_text_visible"),
		"critical",
		"First engagement should expose fired/waiting/blocked status plus target or block reason.",
		{
			"engagement_gate": String(engagement.get("gate", "")),
			"engagement_status": String(engagement.get("engagement_status", "")),
			"fire_event_count": int(engagement.get("fire_event_count", 0)),
		}
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(pre_go.get("read_only", false)) \
			and not bool(pre_go.get("ui_sets_gameplay_truth", true)) \
			and bool(execution.get("read_only", false)) \
			and not bool(execution.get("ui_sets_gameplay_truth", true)) \
			and bool(contact.get("read_only", false)) \
			and not bool(contact.get("ui_sets_gameplay_truth", true)) \
			and bool(engagement.get("read_only", false)) \
			and not bool(engagement.get("ui_sets_gameplay_truth", true)),
		"critical",
		"First GO/Firefight actionability snapshot reads existing mission state only."
	)

	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_reentry_release_candidate_first_go_firefight_actionability_smoke.v1",
		"task_id": "TASK_813",
		"source_task_id": "TASK_812",
		"singleplayer_path_expected": "MainMenu -> Einzelspieler -> Homebase -> Start Mission -> LZ -> Drop -> Move Preview -> GO -> First Contact -> First Engagement",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"pre_go": pre_go,
		"execution": execution,
		"contact": contact,
		"engagement": engagement,
		"pre_go_status": String(pre_go.get("status", "")),
		"execution_gate": String(execution.get("gate", "")),
		"contact_gate": String(contact.get("gate", "")),
		"engagement_gate": String(engagement.get("gate", "")),
		"go_executed": _insertion_check_passed(execution, "go_feedback_visible"),
		"movement_state_count": int(execution.get("movement_state_count", 0)),
		"selected_contact_count": int(contact.get("selected_contact_count", 0)),
		"engagement_status": String(engagement.get("engagement_status", "")),
		"fire_event_count": int(engagement.get("fire_event_count", 0)),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "fail",
		"recommended_next_task": "TASK_814 - Station Reentry Release Candidate Firefight Feel And HUD Polish Review",
	}


func get_release_candidate_firefight_feel_hud_polish_review_snapshot() -> Dictionary:
	var source: Dictionary = get_release_candidate_first_go_firefight_actionability_snapshot()
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var hud_polish: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_candidate_firefight_feel_hud_polish_snapshot"):
		hud_polish = Dictionary(tactical_controller.call("get_release_candidate_firefight_feel_hud_polish_snapshot"))
	var player_action: Dictionary = Dictionary(hud_polish.get("player_action", {}))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_first_go_firefight_passed",
		String(source.get("status", "")) == "pass",
		"critical",
		"Firefight HUD polish review should build on a green first-GO/firefight smoke.",
		{"source_status": String(source.get("status", ""))}
	)
	_append_handoff_check(
		checks,
		"tactical_hud_polish_snapshot_present",
		tactical_controller != null and not hud_polish.is_empty(),
		"critical",
		"Active mission should expose the tactical firefight HUD polish snapshot."
	)
	_append_handoff_check(
		checks,
		"firefight_hud_polish_gate_passes",
		String(hud_polish.get("gate", "")) == "pass",
		"critical",
		"Firefight HUD polish should pass compact readout, tooltip and bounds checks.",
		{
			"hud_gate": String(hud_polish.get("gate", "")),
			"compact_line": String(hud_polish.get("compact_line", "")),
		}
	)
	_append_handoff_check(
		checks,
		"player_next_action_visible",
		bool(player_action.get("active", false))
			and String(player_action.get("next_action_line", "")).begins_with("Naechster Griff:"),
		"critical",
		"Firefight readout should tell the player the next tactical action."
	)
	_append_handoff_check(
		checks,
		"hud_text_shared_between_surfaces",
		_insertion_check_passed(hud_polish, "combat_readout_visible_in_both_huds"),
		"critical",
		"Mission Control and Selected Fireteam should share the same compact combat readout."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(source.get("read_only", false))
			and not bool(source.get("ui_sets_gameplay_truth", true))
			and bool(hud_polish.get("read_only", false))
			and not bool(hud_polish.get("ui_sets_gameplay_truth", true))
			and not bool(hud_polish.get("creates_command", true))
			and not bool(hud_polish.get("creates_fire_event", true))
			and not bool(hud_polish.get("creates_damage_event", true))
			and not bool(hud_polish.get("sets_multiplayer_truth", true)),
		"critical",
		"Firefight HUD polish review reads existing mission state only."
	)

	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_reentry_release_candidate_firefight_feel_hud_polish_review.v1",
		"task_id": "TASK_814",
		"source_task_id": "TASK_813",
		"singleplayer_path_expected": "MainMenu -> Einzelspieler -> Homebase -> Start Mission -> LZ -> Drop -> Move Preview -> GO -> First Contact -> First Engagement -> Firefight HUD Readout",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"hud_polish": hud_polish,
		"source_status": String(source.get("status", "")),
		"hud_polish_gate": String(hud_polish.get("gate", "")),
		"compact_line": String(hud_polish.get("compact_line", "")),
		"player_next_action_line": String(player_action.get("next_action_line", "")),
		"player_why_line": String(player_action.get("why_line", "")),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "fail",
		"recommended_next_task": "TASK_815 - Station Reentry Release Candidate Real Window Firefight Sight Review",
	}


func get_release_candidate_real_window_firefight_sight_review_snapshot(review_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_candidate_firefight_feel_hud_polish_review_snapshot()
	return REAL_WINDOW_FIREFIGHT_SIGHT_REVIEW_SCRIPT.build_snapshot(source, review_notes, options)


func get_release_candidate_visible_firefight_findings_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_candidate_real_window_firefight_sight_review_snapshot(real_window_review_notes, options)
	return VISIBLE_FIREFIGHT_FINDINGS_SCRIPT.build_snapshot(source, findings_notes, options)


func get_release_candidate_targeted_firefight_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Dictionary = get_release_candidate_visible_firefight_findings_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_polish: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_candidate_targeted_firefight_polish_snapshot"):
		tactical_polish = Dictionary(tactical_controller.call("get_release_candidate_targeted_firefight_polish_snapshot"))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"tactical_polish_snapshot_present",
		not tactical_polish.is_empty(),
		"critical",
		"Active mission should expose targeted firefight polish."
	)
	_append_handoff_check(
		checks,
		"decision_line_visible",
		String(tactical_polish.get("gate", "")) == "pass"
			and not String(tactical_polish.get("decision_line", "")).strip_edges().is_empty(),
		"critical",
		"Targeted firefight polish should expose a visible NEXT/WHY decision line."
	)
	_append_handoff_check(
		checks,
		"findings_source_read_only",
		bool(findings.get("read_only", false)) and not bool(findings.get("ui_sets_gameplay_truth", true)),
		"critical",
		"TASK_817 reads TASK_816 findings without mutating gameplay truth."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_polish.get("read_only", false))
			and not bool(tactical_polish.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_polish.get("creates_command", true))
			and not bool(tactical_polish.get("creates_fire_event", true))
			and not bool(tactical_polish.get("creates_damage_event", true))
			and not bool(tactical_polish.get("sets_multiplayer_truth", true)),
		"critical",
		"Targeted firefight polish reads existing mission/HUD state only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_reentry_release_candidate_targeted_firefight_polish.v1",
		"task_id": "TASK_817",
		"source_task_id": "TASK_816",
		"source_status": String(findings.get("status", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"findings": findings,
		"tactical_polish": tactical_polish,
		"decision_line": String(tactical_polish.get("decision_line", "")),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_818 - Station Reentry Release Candidate Playable Build Acceptance",
	}


func get_release_firefight_hud_readability_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_candidate_targeted_firefight_polish_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_readability: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_firefight_hud_readability_polish_snapshot"):
		tactical_readability = Dictionary(tactical_controller.call("get_release_firefight_hud_readability_polish_snapshot"))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_targeted_firefight_polish_passes",
		String(source.get("status", "")) == "pass",
		"critical",
		"TASK_833 builds on a passing TASK_817 targeted Firefight polish snapshot."
	)
	_append_handoff_check(
		checks,
		"tactical_readability_snapshot_present",
		not tactical_readability.is_empty(),
		"critical",
		"Active mission should expose tactical HUD readability polish."
	)
	_append_handoff_check(
		checks,
		"contact_fire_first_in_selected_fireteam",
		String(tactical_readability.get("gate", "")) == "pass"
			and String(tactical_readability.get("selected_fireteam_first_line", "")).strip_edges().begins_with("CONTACT FIRE")
			and not String(tactical_readability.get("decision_line", "")).strip_edges().is_empty(),
		"critical",
		"Selected Fireteam should lead with active contact fire and keep NEXT/WHY immediately below it."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_readability.get("read_only", false))
			and not bool(tactical_readability.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_readability.get("creates_command", true))
			and not bool(tactical_readability.get("creates_fire_event", true))
			and not bool(tactical_readability.get("creates_damage_event", true))
			and not bool(tactical_readability.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_833 reads existing mission/HUD state only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_firefight_hud_readability_polish.v1",
		"task_id": "TASK_833",
		"source_task_id": "TASK_817",
		"source_status": String(source.get("status", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_readability": tactical_readability,
		"decision_line": String(tactical_readability.get("decision_line", "")),
		"selected_fireteam_first_line": String(tactical_readability.get("selected_fireteam_first_line", "")),
		"selected_fireteam_status_text": String(tactical_readability.get("selected_fireteam_status_text", "")),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_834 - Release Firefight HUD Real Window Recapture",
	}


func get_release_firefight_hud_real_window_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_firefight_hud_readability_polish_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_real_window: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_firefight_hud_real_window_polish_snapshot"):
		tactical_real_window = Dictionary(tactical_controller.call("get_release_firefight_hud_real_window_polish_snapshot"))
	var label_style: Dictionary = Dictionary(tactical_real_window.get("selected_fireteam_label_style", {}))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_readability_passes",
		String(source.get("status", "")) == "pass",
		"critical",
		"TASK_834 builds on a passing TASK_833 readability snapshot."
	)
	_append_handoff_check(
		checks,
		"tactical_real_window_snapshot_present",
		not tactical_real_window.is_empty(),
		"critical",
		"Active mission should expose tactical real-window HUD polish."
	)
	_append_handoff_check(
		checks,
		"real_window_style_active",
		String(tactical_real_window.get("gate", "")) == "pass"
			and String(tactical_real_window.get("style_id", "")) == "task_834_release_firefight_hud_real_window_v1"
			and bool(tactical_real_window.get("real_window_style_active", false)),
		"critical",
		"Selected Fireteam should carry the TASK_834 real-window style."
	)
	_append_handoff_check(
		checks,
		"real_window_label_readable",
		int(label_style.get("font_size", 0)) >= 12
			and int(label_style.get("outline_size", 0)) >= 3
			and bool(tactical_real_window.get("selected_fireteam_label_autowrap_enabled", false))
			and not bool(tactical_real_window.get("selected_fireteam_label_clip_text", true))
			and float(tactical_real_window.get("selected_fireteam_label_min_height", 0.0)) >= 62.0,
		"critical",
		"Selected Fireteam should be larger, outlined, wrapped and not clipped."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_real_window.get("read_only", false))
			and not bool(tactical_real_window.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_real_window.get("creates_command", true))
			and not bool(tactical_real_window.get("creates_fire_event", true))
			and not bool(tactical_real_window.get("creates_damage_event", true))
			and not bool(tactical_real_window.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_834 reads existing mission/HUD state only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_firefight_hud_real_window_polish.v1",
		"task_id": "TASK_834",
		"source_task_id": "TASK_833",
		"source_status": String(source.get("status", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_real_window": tactical_real_window,
		"decision_line": String(tactical_real_window.get("decision_line", "")),
		"visible_decision_line": String(tactical_real_window.get("visible_decision_line", "")),
		"contact_fire_line": String(tactical_real_window.get("contact_fire_line", "")),
		"selected_fireteam_status_text": String(tactical_real_window.get("selected_fireteam_status_text", "")),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_835 - Release Firefight Bottom Dock Density Polish",
	}


func get_release_firefight_bottom_dock_density_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_firefight_hud_real_window_polish_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_bottom_dock: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_firefight_bottom_dock_density_polish_snapshot"):
		tactical_bottom_dock = Dictionary(tactical_controller.call("get_release_firefight_bottom_dock_density_polish_snapshot"))
	var label_style: Dictionary = Dictionary(tactical_bottom_dock.get("mission_control_label_style", {}))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_real_window_passes",
		String(source.get("status", "")) == "pass",
		"critical",
		"TASK_835 builds on a passing TASK_834 real-window snapshot."
	)
	_append_handoff_check(
		checks,
		"tactical_bottom_dock_snapshot_present",
		not tactical_bottom_dock.is_empty(),
		"critical",
		"Active mission should expose tactical bottom-dock density polish."
	)
	_append_handoff_check(
		checks,
		"mission_control_contact_fire_first",
		String(tactical_bottom_dock.get("gate", "")) == "pass"
			and String(tactical_bottom_dock.get("contact_fire_line", "")).strip_edges().begins_with("CONTACT FIRE")
			and String(tactical_bottom_dock.get("mission_control_first_line", "")).strip_edges() == String(tactical_bottom_dock.get("contact_fire_line", "")).strip_edges(),
		"critical",
		"Mission Control should lead with its CONTACT FIRE readout."
	)
	_append_handoff_check(
		checks,
		"mission_control_visible_decision_second",
		String(tactical_bottom_dock.get("gate", "")) == "pass"
			and not String(tactical_bottom_dock.get("visible_decision_line", "")).strip_edges().is_empty()
			and String(tactical_bottom_dock.get("mission_control_second_line", "")).strip_edges() == String(tactical_bottom_dock.get("visible_decision_line", "")).strip_edges(),
		"critical",
		"Mission Control should keep the compact NEXT/WHY decision directly below contact fire."
	)
	_append_handoff_check(
		checks,
		"bottom_dock_density_style_active",
		String(tactical_bottom_dock.get("gate", "")) == "pass"
			and String(tactical_bottom_dock.get("style_id", "")) == "task_835_release_firefight_bottom_dock_density_v1"
			and bool(tactical_bottom_dock.get("bottom_dock_density_style_active", false)),
		"critical",
		"Mission Control should carry the TASK_835 bottom-dock density style."
	)
	_append_handoff_check(
		checks,
		"bottom_dock_label_readable",
		int(label_style.get("font_size", 0)) >= 11
			and int(label_style.get("outline_size", 0)) >= 3
			and bool(tactical_bottom_dock.get("mission_control_label_autowrap_enabled", false))
			and not bool(tactical_bottom_dock.get("mission_control_label_clip_text", true))
			and float(tactical_bottom_dock.get("mission_control_label_min_height", 0.0)) >= 84.0,
		"critical",
		"Mission Control should be larger, outlined, wrapped and not clipped."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_bottom_dock.get("read_only", false))
			and not bool(tactical_bottom_dock.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_bottom_dock.get("creates_command", true))
			and not bool(tactical_bottom_dock.get("creates_fire_event", true))
			and not bool(tactical_bottom_dock.get("creates_damage_event", true))
			and not bool(tactical_bottom_dock.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_835 reads existing mission/HUD state only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_firefight_bottom_dock_density_polish.v1",
		"task_id": "TASK_835",
		"source_task_id": "TASK_834",
		"source_status": String(source.get("status", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_bottom_dock": tactical_bottom_dock,
		"decision_line": String(tactical_bottom_dock.get("decision_line", "")),
		"visible_decision_line": String(tactical_bottom_dock.get("visible_decision_line", "")),
		"contact_fire_line": String(tactical_bottom_dock.get("contact_fire_line", "")),
		"selected_contact_fire_line": String(tactical_bottom_dock.get("selected_contact_fire_line", "")),
		"mission_control_status_text": String(tactical_bottom_dock.get("mission_control_status_text", "")),
		"mission_control_first_line": String(tactical_bottom_dock.get("mission_control_first_line", "")),
		"mission_control_second_line": String(tactical_bottom_dock.get("mission_control_second_line", "")),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_836 - Release Firefight Command Matrix Visual Polish",
	}


func get_release_firefight_command_matrix_visual_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_firefight_bottom_dock_density_polish_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_command_matrix: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_firefight_command_matrix_visual_polish_snapshot"):
		tactical_command_matrix = Dictionary(tactical_controller.call("get_release_firefight_command_matrix_visual_polish_snapshot"))
	var command_matrix: Dictionary = Dictionary(tactical_command_matrix.get("command_matrix", {}))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_bottom_dock_passes",
		String(source.get("status", "")) == "pass",
		"critical",
		"TASK_836 builds on a passing TASK_835 bottom-dock snapshot."
	)
	_append_handoff_check(
		checks,
		"tactical_command_matrix_snapshot_present",
		not tactical_command_matrix.is_empty(),
		"critical",
		"Active mission should expose tactical command-matrix visual polish."
	)
	_append_handoff_check(
		checks,
		"command_matrix_style_active",
		String(tactical_command_matrix.get("gate", "")) == "pass"
			and String(tactical_command_matrix.get("style_id", "")) == "task_836_release_firefight_command_matrix_visual_v1"
			and bool(command_matrix.get("active", false)),
		"critical",
		"Command Matrix should carry the TASK_836 style in the first Firefight."
	)
	_append_handoff_check(
		checks,
		"go_button_prominent",
		String(tactical_command_matrix.get("gate", "")) == "pass"
			and bool(command_matrix.get("go_button_prominent", false))
			and float(command_matrix.get("go_button_visual_weight", 0.0)) >= 2.4,
		"critical",
		"GO should be visually prominent before the player commits the next order."
	)
	_append_handoff_check(
		checks,
		"primary_and_fire_rule_readable",
		String(tactical_command_matrix.get("gate", "")) == "pass"
			and int(command_matrix.get("primary_readable_count", 0)) >= 5
			and int(command_matrix.get("active_fire_rule_count", 0)) == 1,
		"critical",
		"Primary command buttons and exactly one active Fire-Rule should be readable."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_command_matrix.get("read_only", false))
			and not bool(tactical_command_matrix.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_command_matrix.get("creates_command", true))
			and not bool(tactical_command_matrix.get("creates_fire_event", true))
			and not bool(tactical_command_matrix.get("creates_damage_event", true))
			and not bool(tactical_command_matrix.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_836 reads existing mission/HUD state only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_firefight_command_matrix_visual_polish.v1",
		"task_id": "TASK_836",
		"source_task_id": "TASK_835",
		"source_status": String(source.get("status", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"style_id": String(tactical_command_matrix.get("style_id", command_matrix.get("style_id", ""))),
		"source": source,
		"tactical_command_matrix": tactical_command_matrix,
		"command_matrix": command_matrix,
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_837 - Release First GO Firefight Real Capture Review",
	}


func get_release_firefight_real_window_findings_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_firefight_command_matrix_visual_polish_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_findings: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_firefight_real_window_findings_polish_snapshot"):
		tactical_findings = Dictionary(tactical_controller.call("get_release_firefight_real_window_findings_polish_snapshot"))
	var event_log_display: Dictionary = Dictionary(tactical_findings.get("event_log_display", {}))
	var event_log_panel: Dictionary = Dictionary(tactical_findings.get("event_log_panel", {}))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"firefight_mission_visible",
		active_mission != null and _is_mission_host_visible_for_current_view(),
		"critical",
		"TASK_838 observes the active First-GO Firefight mission."
	)
	_append_handoff_check(
		checks,
		"tactical_findings_snapshot_present",
		not tactical_findings.is_empty(),
		"critical",
		"Active mission should expose tactical real-window findings polish."
	)
	_append_handoff_check(
		checks,
		"event_log_has_visible_status",
		String(tactical_findings.get("gate", "")) == "pass"
			and int(event_log_display.get("display_count", 0)) >= 1
			and int(event_log_panel.get("rendered_entry_count", 0)) >= 1,
		"critical",
		"#19 Event Log should show a readable status row instead of NO EVENTS in the first Firefight."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_findings.get("read_only", false))
			and not bool(tactical_findings.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_findings.get("creates_command", true))
			and not bool(tactical_findings.get("creates_fire_event", true))
			and not bool(tactical_findings.get("creates_damage_event", true))
			and not bool(tactical_findings.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_838 reads existing event-log, decision and combat snapshots only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_firefight_real_window_findings_polish.v1",
		"task_id": "TASK_838",
		"source_task_id": "TASK_837",
		"source_status": String(source.get("status", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_findings": tactical_findings,
		"event_log_display": event_log_display,
		"event_log_panel": event_log_panel,
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_839 - Release Firefight World Label Declutter",
	}


func get_release_firefight_world_label_declutter_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_firefight_real_window_findings_polish_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_declutter: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_firefight_world_label_declutter_snapshot"):
		tactical_declutter = Dictionary(tactical_controller.call("get_release_firefight_world_label_declutter_snapshot"))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_findings_polish_passes",
		String(source.get("status", "")) == "pass",
		"critical",
		"TASK_839 builds on a passing TASK_838 real-window findings polish snapshot."
	)
	_append_handoff_check(
		checks,
		"tactical_declutter_snapshot_present",
		not tactical_declutter.is_empty(),
		"critical",
		"Active mission should expose tactical world-label declutter."
	)
	_append_handoff_check(
		checks,
		"declutter_gate_passes",
		String(tactical_declutter.get("gate", "")) == "pass",
		"critical",
		"Primary3D should reduce redundant world labels during the release firefight readout."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_declutter.get("read_only", false))
			and not bool(tactical_declutter.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_declutter.get("creates_command", true))
			and not bool(tactical_declutter.get("creates_fire_event", true))
			and not bool(tactical_declutter.get("creates_damage_event", true))
			and not bool(tactical_declutter.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_839 changes visual density only and does not create gameplay truth."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_firefight_world_label_declutter.v1",
		"task_id": "TASK_839",
		"source_task_id": "TASK_838",
		"source_status": String(source.get("status", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_declutter": tactical_declutter,
		"style_id": String(tactical_declutter.get("style_id", "")),
		"density_mode": String(tactical_declutter.get("density_mode", "")),
		"suppressed_count": int(tactical_declutter.get("suppressed_count", 0)),
		"rendered_count": int(tactical_declutter.get("rendered_count", 0)),
		"unit_badge_suppressed_count": int(tactical_declutter.get("unit_badge_suppressed_count", 0)),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_840 - Release Firefight World Label Real Window Recapture",
	}


func get_release_first_firefight_contact_framing_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_firefight_world_label_declutter_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_framing: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_first_firefight_contact_framing_snapshot"):
		tactical_framing = Dictionary(tactical_controller.call("get_release_first_firefight_contact_framing_snapshot"))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_declutter_snapshot_available",
		String(source.get("status", "")) == "pass" or String(source.get("status", "")) == "review",
		"critical",
		"TASK_843 builds after the release firefight visual-declutter chain."
	)
	_append_handoff_check(
		checks,
		"tactical_framing_snapshot_present",
		not tactical_framing.is_empty(),
		"critical",
		"Active mission should expose tactical first-firefight contact framing."
	)
	_append_handoff_check(
		checks,
		"framing_gate_passes",
		String(tactical_framing.get("gate", "")) == "pass",
		"critical",
		"First Firefight should be framed as fire exchange or contact pressure."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_framing.get("read_only", false))
			and not bool(tactical_framing.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_framing.get("creates_command", true))
			and not bool(tactical_framing.get("creates_fire_event", true))
			and not bool(tactical_framing.get("creates_damage_event", true))
			and not bool(tactical_framing.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_843 reads existing contact/combat snapshots only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_first_firefight_contact_framing.v1",
		"task_id": "TASK_843",
		"source_task_id": "TASK_842",
		"source_status": String(source.get("status", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_framing": tactical_framing,
		"style_id": String(tactical_framing.get("style_id", "")),
		"framing_state": String(tactical_framing.get("framing_state", "")),
		"framing_line": String(tactical_framing.get("framing_line", "")),
		"pressure_reason": String(tactical_framing.get("pressure_reason", "")),
		"next_step": String(tactical_framing.get("next_step", "")),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_844 - Release First Exchange Tension Tuning",
	}


func _build_release_first_exchange_immediate_evidence(tactical_controller: Node) -> Dictionary:
	var tactical_exchange: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_first_exchange_immediate_evidence_snapshot"):
		tactical_exchange = Dictionary(tactical_controller.call("get_release_first_exchange_immediate_evidence_snapshot")).duplicate(true)
	var tactical_exchange_passes: bool = String(tactical_exchange.get("gate", "")) == "pass" \
		and bool(tactical_exchange.get("first_exchange_visible", false))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"tactical_exchange_snapshot_present",
		not tactical_exchange.is_empty(),
		"critical",
		"Immediate release evidence reads the active tactical exchange."
	)
	_append_handoff_check(
		checks,
		"first_exchange_visible",
		tactical_exchange_passes,
		"critical",
		"Immediate release evidence references a real FireEvent."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_exchange.get("read_only", false))
			and not bool(tactical_exchange.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_exchange.get("creates_command", true))
			and not bool(tactical_exchange.get("creates_fire_event", true))
			and not bool(tactical_exchange.get("creates_damage_event", true))
			and not bool(tactical_exchange.get("sets_multiplayer_truth", true)),
		"critical",
		"Immediate release evidence remains a read-only view of combat truth."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_first_exchange_tension_tuning.v1",
		"task_id": "TASK_844",
		"source_task_id": "TASK_843",
		"source_status": "pass" if tactical_exchange_passes else "review",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": _active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": {
			"schema": "sternenbuergerchen.release_first_exchange_immediate_handoff.v1",
			"read_only": true,
		},
		"tactical_exchange": tactical_exchange,
		"style_id": String(tactical_exchange.get("style_id", "")),
		"framing_state": String(tactical_exchange.get("framing_state", "")),
		"framing_line": String(tactical_exchange.get("framing_line", "")),
		"fire_event_count": int(tactical_exchange.get("fire_event_count", 0)),
		"first_fire_event_id": String(tactical_exchange.get("first_fire_event_id", "")),
		"first_exchange_visible": bool(tactical_exchange.get("first_exchange_visible", false)),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_845 - Release First Exchange Real Window Recapture",
	}


func get_release_first_exchange_tension_tuning_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_first_firefight_contact_framing_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_exchange: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_first_exchange_tension_tuning_snapshot"):
		tactical_exchange = Dictionary(tactical_controller.call("get_release_first_exchange_tension_tuning_snapshot"))
	var immediate_evidence: Dictionary = Dictionary(get_meta("release_first_exchange_tension_tuning_evidence", {})).duplicate(true)
	if String(immediate_evidence.get("schema", "")) == "sternenbuergerchen.release_first_exchange_tension_tuning.v1":
		var immediate_tactical: Dictionary = Dictionary(immediate_evidence.get("tactical_exchange", {})).duplicate(true)
		if bool(immediate_tactical.get("first_exchange_visible", false)):
			tactical_exchange = immediate_tactical
	var tactical_exchange_passes: bool = String(tactical_exchange.get("gate", "")) == "pass" and bool(tactical_exchange.get("first_exchange_visible", false))
	var source_contact_framing_available: bool = String(source.get("status", "")) == "pass" or tactical_exchange_passes
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_contact_framing_available",
		source_contact_framing_available,
		"critical",
		"TASK_844 builds on TASK_843 contact-framing or direct FireEvent evidence."
	)
	_append_handoff_check(
		checks,
		"tactical_exchange_snapshot_present",
		not tactical_exchange.is_empty(),
		"critical",
		"Active mission should expose the tactical first-exchange tuning snapshot."
	)
	_append_handoff_check(
		checks,
		"first_exchange_visible",
		tactical_exchange_passes,
		"critical",
		"Release First-GO Firefight should show a real fire exchange."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_exchange.get("read_only", false))
			and not bool(tactical_exchange.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_exchange.get("creates_command", true))
			and not bool(tactical_exchange.get("creates_fire_event", true))
			and not bool(tactical_exchange.get("creates_damage_event", true))
			and not bool(tactical_exchange.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_844 reads the already created exchange evidence only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_first_exchange_tension_tuning.v1",
		"task_id": "TASK_844",
		"source_task_id": "TASK_843",
		"source_status": String(source.get("status", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_exchange": tactical_exchange,
		"style_id": String(tactical_exchange.get("style_id", "")),
		"framing_state": String(tactical_exchange.get("framing_state", "")),
		"framing_line": String(tactical_exchange.get("framing_line", "")),
		"fire_event_count": int(tactical_exchange.get("fire_event_count", 0)),
		"first_fire_event_id": String(tactical_exchange.get("first_fire_event_id", "")),
		"first_exchange_visible": bool(tactical_exchange.get("first_exchange_visible", false)),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_845 - Release First Exchange Real Window Recapture",
	}


func get_release_first_exchange_los_setup_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = Dictionary(options.get("source_snapshot", {})).duplicate(true)
	if source.is_empty():
		source = get_release_first_exchange_tension_tuning_snapshot(real_window_review_notes, findings_notes, options)
	var setup_evidence: Dictionary = Dictionary(options.get("setup_evidence", {})).duplicate(true)
	if setup_evidence.is_empty():
		setup_evidence = _release_first_exchange_los_setup_polish_evidence.duplicate(true)
	if setup_evidence.is_empty():
		setup_evidence = Dictionary(get_meta("release_first_exchange_los_setup_polish_evidence", {})).duplicate(true)
	var tactical_exchange: Dictionary = Dictionary(source.get("tactical_exchange", {})).duplicate(true)
	var diagnostics: Dictionary = Dictionary(tactical_exchange.get("contact_decision_diagnostics", {})).duplicate(true)
	var placement_readout: Dictionary = Dictionary(setup_evidence.get("placement_readout", {})).duplicate(true)
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_first_exchange_available",
		String(source.get("status", "")) == "pass" and bool(source.get("first_exchange_visible", false)),
		"critical",
		"TASK_868 builds on the existing TASK_844 first-exchange evidence."
	)
	_append_handoff_check(
		checks,
		"los_setup_evidence_present",
		not setup_evidence.is_empty(),
		"critical",
		"Release first-exchange setup records the exact friendly/enemy pair used for the window run."
	)
	_append_handoff_check(
		checks,
		"placement_verified_attackable",
		bool(setup_evidence.get("placement_verified_attackable", false)),
		"critical",
		"Release first-exchange target placement is validated through the existing combat readout."
	)
	_append_handoff_check(
		checks,
		"placement_los_and_range_stable",
		String(placement_readout.get("range_state", "")).strip_edges().to_lower() == "in_range"
			and String(placement_readout.get("los_state", "")).strip_edges().to_lower() != "blocked"
			and bool(placement_readout.get("combat_attackable", false)),
		"critical",
		"Placement readout reports in-range, non-blocked LOS and attackable target."
	)
	_append_handoff_check(
		checks,
		"diagnostics_still_fire_exchange",
		String(diagnostics.get("status", "")).strip_edges().to_lower() == "fired"
			and String(diagnostics.get("los_state", "")).strip_edges().to_lower() != "blocked"
			and String(diagnostics.get("range_state", "")).strip_edges().to_lower() == "in_range",
		"critical",
		"Current combat diagnostics still point at a fired first exchange."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(source.get("read_only", false))
			and not bool(source.get("ui_sets_gameplay_truth", true))
			and not bool(source.get("creates_command", true))
			and not bool(source.get("creates_fire_event", true))
			and not bool(source.get("creates_damage_event", true))
			and not bool(source.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_868 snapshot reads setup and combat evidence only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_first_exchange_los_setup_polish.v1",
		"task_id": "TASK_868",
		"source_task_id": "TASK_867",
		"source_exchange_task_id": "TASK_844",
		"source_status": String(source.get("status", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"style_id": "task_868_release_first_exchange_los_setup_polish_v1",
		"synthetic_fixture": bool(setup_evidence.get("synthetic_fixture", false)),
		"setup_evidence": setup_evidence,
		"placement_verified_attackable": bool(setup_evidence.get("placement_verified_attackable", false)),
		"placement_attempt_count": int(setup_evidence.get("placement_attempt_count", 0)),
		"pair_candidate_count": int(setup_evidence.get("pair_candidate_count", 0)),
		"placement_los_state": String(placement_readout.get("los_state", "")).strip_edges(),
		"placement_range_state": String(placement_readout.get("range_state", "")).strip_edges(),
		"placement_combat_attackable": bool(placement_readout.get("combat_attackable", false)),
		"framing_state": String(source.get("framing_state", "")),
		"first_exchange_visible": bool(source.get("first_exchange_visible", false)),
		"fire_event_count": int(source.get("fire_event_count", 0)),
		"first_fire_event_id": String(source.get("first_fire_event_id", "")),
		"diagnostics_status": String(diagnostics.get("status", "")),
		"diagnostics_los_state": String(diagnostics.get("los_state", "")),
		"diagnostics_range_state": String(diagnostics.get("range_state", "")),
		"source": source,
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_869 - Release First Exchange Real Window Recapture",
	}


func get_release_first_exchange_contact_fire_readability_fix_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var evidence: Dictionary = Dictionary(options.get("evidence", {})).duplicate(true)
	if evidence.is_empty():
		evidence = _release_first_exchange_contact_fire_readability_fix_evidence.duplicate(true)
	if evidence.is_empty():
		evidence = Dictionary(get_meta("release_first_exchange_contact_fire_readability_fix_evidence", {})).duplicate(true)
	if evidence.is_empty():
		return {
			"schema": "sternenbuergerchen.release_first_exchange_contact_fire_readability_fix.v1",
			"task_id": "TASK_873",
			"source_task_id": "TASK_872",
			"style_id": "task_873_release_first_exchange_contact_fire_readability_fix_v1",
			"status": "blocked",
			"reason": "contact_fire_readability_fix_not_applied",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_fire_event": false,
			"creates_damage_event": false,
			"creates_movement": false,
			"sets_multiplayer_truth": false,
			"updates_shortcuts": false,
			"recommended_next_task": "TASK_874 - Release First Exchange CONTACT-FIRE Real Window Recapture",
		}
	var result: Dictionary = evidence.duplicate(true)
	result["real_window_review_notes"] = real_window_review_notes.duplicate(true)
	result["findings_notes"] = findings_notes.duplicate(true)
	result["options"] = options.duplicate(true)
	result["recommended_next_task"] = String(result.get("recommended_next_task", "TASK_874 - Release First Exchange CONTACT-FIRE Real Window Recapture"))
	return result


func get_release_fire_exchange_visibility_persistence_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_first_exchange_tension_tuning_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_persistence: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_fire_exchange_visibility_persistence_snapshot"):
		tactical_persistence = Dictionary(tactical_controller.call("get_release_fire_exchange_visibility_persistence_snapshot"))
	var source_exchange_available: bool = String(source.get("status", "")) == "pass" and bool(source.get("first_exchange_visible", false))
	if not source_exchange_available:
		source_exchange_available = bool(tactical_persistence.get("visibility_persistence_active", false)) and not String(tactical_persistence.get("fire_event_id", "")).strip_edges().is_empty()
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_first_exchange_available",
		source_exchange_available,
		"critical",
		"TASK_847 builds on the green TASK_844 first-exchange chain."
	)
	_append_handoff_check(
		checks,
		"tactical_persistence_snapshot_present",
		not tactical_persistence.is_empty(),
		"critical",
		"Active mission should expose the tactical fire-exchange visibility-persistence snapshot."
	)
	_append_handoff_check(
		checks,
		"visibility_persistence_gate_passes",
		String(tactical_persistence.get("gate", "")) == "pass" and bool(tactical_persistence.get("visibility_persistence_active", false)),
		"critical",
		"Fire-Exchange evidence should remain readable in the release HUD surfaces."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_persistence.get("read_only", false))
			and not bool(tactical_persistence.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_persistence.get("creates_command", true))
			and not bool(tactical_persistence.get("creates_fire_event", true))
			and not bool(tactical_persistence.get("creates_damage_event", true))
			and not bool(tactical_persistence.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_847 reads and displays existing exchange evidence only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_fire_exchange_visibility_persistence.v1",
		"task_id": "TASK_847",
		"source_task_id": "TASK_846",
		"source_exchange_task_id": "TASK_844",
		"source_status": String(source.get("status", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_persistence": tactical_persistence,
		"style_id": String(tactical_persistence.get("style_id", "")),
		"visibility_persistence_active": bool(tactical_persistence.get("visibility_persistence_active", false)),
		"compact_line": String(tactical_persistence.get("compact_line", "")),
		"decision_line": String(tactical_persistence.get("decision_line", "")),
		"event_log_short_text": String(tactical_persistence.get("event_log_short_text", "")),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_848 - Release First Exchange Recapture Acceptance",
	}


func get_release_fire_exchange_focused_visual_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_fire_exchange_visibility_persistence_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_focus: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_fire_exchange_focused_visual_polish_snapshot"):
		tactical_focus = Dictionary(tactical_controller.call("get_release_fire_exchange_focused_visual_polish_snapshot"))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_visibility_persistence_passes",
		String(source.get("status", "")) == "pass" and bool(source.get("visibility_persistence_active", false)),
		"critical",
		"TASK_850 builds on the green TASK_847 visibility-persistence chain."
	)
	_append_handoff_check(
		checks,
		"tactical_focus_snapshot_present",
		not tactical_focus.is_empty(),
		"critical",
		"Active mission should expose the tactical TASK_850 visual-focus snapshot."
	)
	_append_handoff_check(
		checks,
		"focused_visual_polish_gate_passes",
		String(tactical_focus.get("gate", "")) == "pass" and bool(tactical_focus.get("focused_visual_polish_active", false)),
		"critical",
		"Primary3D should report active focused fire-exchange visual polish."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_focus.get("read_only", false))
			and not bool(tactical_focus.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_focus.get("creates_command", true))
			and not bool(tactical_focus.get("creates_fire_event", true))
			and not bool(tactical_focus.get("creates_damage_event", true))
			and not bool(tactical_focus.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_850 changes visual focus only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_fire_exchange_focused_visual_polish.v1",
		"task_id": "TASK_850",
		"source_task_id": "TASK_849",
		"source_visibility_task_id": "TASK_847",
		"source_exchange_task_id": "TASK_844",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_focus": tactical_focus,
		"style_id": String(tactical_focus.get("style_id", "")),
		"focused_visual_polish_active": bool(tactical_focus.get("focused_visual_polish_active", false)),
		"world_line_dimming_active": bool(tactical_focus.get("world_line_dimming_active", false)),
		"fire_vfx_focus_active": bool(tactical_focus.get("fire_vfx_focus_active", false)),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_851 - Release Fire Exchange Focused Visual Recapture",
	}


func get_release_first_exchange_fire_visual_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = {
		"schema": "sternenbuergerchen.release_first_exchange_exported_status_source_trace_runtime_summary.v1",
		"task_id": "TASK_879",
		"sample_count": _release_first_exchange_exported_status_trace_samples.size(),
		"primary_issue_id": "exported_status_source_trace_acceptance_ready" if not _release_first_exchange_exported_status_trace_samples.is_empty() else "",
		"recommended_next_task": "TASK_880 - Release First Exchange Fire Visual Polish",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}
	var focus: Dictionary = get_release_fire_exchange_focused_visual_polish_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_visual: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_first_exchange_fire_visual_polish_snapshot"):
		tactical_visual = Dictionary(tactical_controller.call("get_release_first_exchange_fire_visual_polish_snapshot"))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_trace_acceptance_ready",
		String(source.get("primary_issue_id", "")) == "exported_status_source_trace_acceptance_ready"
			or String(source.get("recommended_next_task", "")).contains("Fire Visual Polish"),
		"warning",
		"TASK_880 follows TASK_879 only after the exported status-source trace points at visual polish."
	)
	_append_handoff_check(
		checks,
		"source_focus_available",
		String(focus.get("status", "")) == "pass" and bool(focus.get("focused_visual_polish_active", false)),
		"critical",
		"The existing TASK_850 focus visual path should still be active."
	)
	_append_handoff_check(
		checks,
		"tactical_first_exchange_visual_snapshot_present",
		not tactical_visual.is_empty(),
		"critical",
		"Active mission should expose the tactical TASK_880 visual snapshot."
	)
	_append_handoff_check(
		checks,
		"first_exchange_fire_visual_gate_passes",
		String(tactical_visual.get("gate", "")) == "pass" and bool(tactical_visual.get("first_exchange_fire_visual_polish_active", false)),
		"critical",
		"Primary3D should report active first-exchange FireTrace/Impact/Target-Focus polish."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_visual.get("read_only", false))
			and not bool(tactical_visual.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_visual.get("creates_command", true))
			and not bool(tactical_visual.get("creates_fire_event", true))
			and not bool(tactical_visual.get("creates_damage_event", true))
			and not bool(tactical_visual.get("creates_movement", true))
			and not bool(tactical_visual.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_880 changes visual emphasis only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_first_exchange_fire_visual_polish.v1",
		"task_id": "TASK_880",
		"source_task_id": "TASK_879",
		"source_status_task_id": "TASK_876",
		"source_focus_task_id": "TASK_850",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"focus": focus,
		"tactical_visual": tactical_visual,
		"style_id": String(tactical_visual.get("style_id", "")),
		"first_exchange_fire_visual_polish_active": bool(tactical_visual.get("first_exchange_fire_visual_polish_active", false)),
		"trace_width": float(tactical_visual.get("trace_width", 0.0)),
		"impact_radius": float(tactical_visual.get("impact_radius", 0.0)),
		"target_focus_radius": float(tactical_visual.get("target_focus_radius", 0.0)),
		"fire_status_label_font_size": int(tactical_visual.get("fire_status_label_font_size", 0)),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_881 - Release First Exchange Fire Visual Recapture",
	}


func get_release_fire_exchange_contact_fire_primary_hud_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_fire_exchange_focused_visual_polish_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_primary_hud: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_fire_exchange_contact_fire_primary_hud_polish_snapshot"):
		tactical_primary_hud = Dictionary(tactical_controller.call("get_release_fire_exchange_contact_fire_primary_hud_polish_snapshot"))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_focus_snapshot_available",
		String(source.get("status", "")) == "pass" or String(source.get("status", "")) == "review",
		"warning",
		"TASK_856 follows the existing release fire-exchange focus chain."
	)
	_append_handoff_check(
		checks,
		"tactical_primary_hud_snapshot_present",
		not tactical_primary_hud.is_empty(),
		"critical",
		"Active mission should expose the tactical TASK_856 primary-HUD snapshot."
	)
	_append_handoff_check(
		checks,
		"contact_fire_primary_hud_gate_passes",
		String(tactical_primary_hud.get("status", "")) == "pass" and bool(tactical_primary_hud.get("active", false)),
		"critical",
		"#17/#18 should present CONTACT FIRE as the first readable fire-exchange state."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_primary_hud.get("read_only", false))
			and not bool(tactical_primary_hud.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_primary_hud.get("creates_command", true))
			and not bool(tactical_primary_hud.get("creates_fire_event", true))
			and not bool(tactical_primary_hud.get("creates_damage_event", true))
			and not bool(tactical_primary_hud.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_856 changes HUD readability only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_fire_exchange_contact_fire_primary_hud_polish.v1",
		"task_id": "TASK_856",
		"source_task_id": "TASK_855",
		"source_focus_task_id": "TASK_850",
		"source_visibility_task_id": "TASK_847",
		"source_exchange_task_id": "TASK_844",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_primary_hud": tactical_primary_hud,
		"style_id": String(tactical_primary_hud.get("style_id", "")),
		"contact_fire_primary_line": String(tactical_primary_hud.get("contact_fire_primary_line", "")),
		"selected_fireteam_contains_contact_fire_primary": bool(tactical_primary_hud.get("selected_fireteam_contains_contact_fire_primary", false)),
		"mission_control_contains_contact_fire_primary": bool(tactical_primary_hud.get("mission_control_contains_contact_fire_primary", false)),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_857 - Release Fire Exchange Contact-Fire Primary HUD Recapture",
	}


func get_release_fire_exchange_real_window_primary_hud_source_binding_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_fire_exchange_contact_fire_primary_hud_polish_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_source_binding: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_fire_exchange_real_window_primary_hud_source_binding_polish_snapshot"):
		tactical_source_binding = Dictionary(tactical_controller.call("get_release_fire_exchange_real_window_primary_hud_source_binding_polish_snapshot"))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_primary_hud_snapshot_available",
		String(source.get("status", "")) == "pass" or String(source.get("status", "")) == "review",
		"warning",
		"TASK_859 follows the TASK_856 CONTACT-FIRE primary-HUD source."
	)
	_append_handoff_check(
		checks,
		"tactical_source_binding_snapshot_present",
		not tactical_source_binding.is_empty(),
		"critical",
		"Active mission should expose the tactical TASK_859 real-window source-binding snapshot."
	)
	_append_handoff_check(
		checks,
		"real_window_surfaces_bound_to_contact_fire",
		String(tactical_source_binding.get("status", "")) == "pass"
			and bool(tactical_source_binding.get("selected_fireteam_real_window_bound_to_contact_fire", false))
			and bool(tactical_source_binding.get("mission_control_real_window_bound_to_contact_fire", false)),
		"critical",
		"#17/#18 real-window HUD text should begin with the CONTACT-FIRE primary source during active fire evidence."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_source_binding.get("read_only", false))
			and not bool(tactical_source_binding.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_source_binding.get("creates_command", true))
			and not bool(tactical_source_binding.get("creates_fire_event", true))
			and not bool(tactical_source_binding.get("creates_damage_event", true))
			and not bool(tactical_source_binding.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_859 changes source binding for display text only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_fire_exchange_real_window_primary_hud_source_binding_polish.v1",
		"task_id": "TASK_859",
		"source_task_id": "TASK_858",
		"source_primary_hud_task_id": "TASK_856",
		"source_visibility_task_id": "TASK_847",
		"source_exchange_task_id": "TASK_844",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_source_binding": tactical_source_binding,
		"style_id": String(tactical_source_binding.get("style_id", "")),
		"contact_fire_primary_line": String(tactical_source_binding.get("contact_fire_primary_line", "")),
		"selected_fireteam_real_window_bound_to_contact_fire": bool(tactical_source_binding.get("selected_fireteam_real_window_bound_to_contact_fire", false)),
		"mission_control_real_window_bound_to_contact_fire": bool(tactical_source_binding.get("mission_control_real_window_bound_to_contact_fire", false)),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_860 - Release Fire Exchange Real Window Contact-Fire Recapture",
	}


func get_release_fire_exchange_real_window_primary_hud_runtime_text_polish_snapshot(real_window_review_notes: Dictionary = {}, findings_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = get_release_fire_exchange_real_window_primary_hud_source_binding_polish_snapshot(real_window_review_notes, findings_notes, options)
	var active_mission: Node = _active_mission
	var tactical_controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var tactical_runtime_text: Dictionary = {}
	if tactical_controller != null and tactical_controller.has_method("get_release_fire_exchange_real_window_primary_hud_runtime_text_polish_snapshot"):
		tactical_runtime_text = Dictionary(tactical_controller.call("get_release_fire_exchange_real_window_primary_hud_runtime_text_polish_snapshot"))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"source_binding_snapshot_available",
		String(source.get("status", "")) == "pass" or String(source.get("status", "")) == "review",
		"warning",
		"TASK_862 follows the TASK_859 real-window source-binding snapshot."
	)
	_append_handoff_check(
		checks,
		"tactical_runtime_text_snapshot_present",
		not tactical_runtime_text.is_empty(),
		"critical",
		"Active mission should expose the tactical TASK_862 runtime-text snapshot."
	)
	_append_handoff_check(
		checks,
		"runtime_text_surfaces_contact_fire_first",
		String(tactical_runtime_text.get("status", "")) == "pass"
			and bool(tactical_runtime_text.get("selected_fireteam_runtime_text_contact_fire_first", false))
			and bool(tactical_runtime_text.get("mission_control_runtime_text_contact_fire_first", false)),
		"critical",
		"#17/#18 runtime HUD labels should begin with CONTACT FIRE during active fire evidence."
	)
	_append_handoff_check(
		checks,
		"read_only_boundaries",
		bool(tactical_runtime_text.get("read_only", false))
			and not bool(tactical_runtime_text.get("ui_sets_gameplay_truth", true))
			and not bool(tactical_runtime_text.get("creates_command", true))
			and not bool(tactical_runtime_text.get("creates_fire_event", true))
			and not bool(tactical_runtime_text.get("creates_damage_event", true))
			and not bool(tactical_runtime_text.get("sets_multiplayer_truth", true)),
		"critical",
		"TASK_862 changes runtime display text only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.release_fire_exchange_real_window_primary_hud_runtime_text_polish.v1",
		"task_id": "TASK_862",
		"source_task_id": "TASK_861",
		"source_binding_task_id": "TASK_859",
		"source_primary_hud_task_id": "TASK_856",
		"source_visibility_task_id": "TASK_847",
		"source_exchange_task_id": "TASK_844",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
		"current_meta_view": _current_meta_view,
		"active_mission_exists": active_mission != null,
		"mission_host_visible": _is_mission_host_visible_for_current_view(),
		"source": source,
		"tactical_runtime_text": tactical_runtime_text,
		"style_id": String(tactical_runtime_text.get("style_id", "")),
		"contact_fire_primary_line": String(tactical_runtime_text.get("contact_fire_primary_line", "")),
		"selected_fireteam_runtime_text_contact_fire_first": bool(tactical_runtime_text.get("selected_fireteam_runtime_text_contact_fire_first", false)),
		"mission_control_runtime_text_contact_fire_first": bool(tactical_runtime_text.get("mission_control_runtime_text_contact_fire_first", false)),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_863 - Release Fire Exchange Runtime Text Recapture",
	}


func get_debrief_return_homebase_handoff_snapshot() -> Dictionary:
	var homebase_screen: Node = _get_homebase_screen()
	var fob_screen: Node = _get_fob_screen()
	var debrief_screen: Node = _get_debrief_screen()
	var mission_host: Node = _get_mission_host()
	var return_button := get_node_or_null("DebriefScreen/Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton") as Button
	var debrief_result: Dictionary = {}
	if debrief_screen != null and debrief_screen.has_method("get_mission_result"):
		debrief_result = Dictionary(debrief_screen.call("get_mission_result")).duplicate(true)
	var result_preserved: bool = _debrief_handoff_results_match(_last_mission_result, debrief_result)
	var signal_connected: bool = debrief_screen != null \
		and debrief_screen.has_signal("return_to_homebase_requested") \
		and debrief_screen.is_connected("return_to_homebase_requested", Callable(self, "_on_debrief_return_to_homebase_requested"))
	var return_action_available: bool = debrief_screen != null \
		and return_button != null \
		and not return_button.disabled \
		and signal_connected
	var active_mission_released: bool = _active_mission == null
	var checks: Array = []
	_append_handoff_check(
		checks,
		"homebase_target_available",
		homebase_screen != null,
		"critical",
		"Debrief return should have a Homebase target screen."
	)
	_append_handoff_check(
		checks,
		"debrief_source_available",
		debrief_screen != null,
		"critical",
		"Debrief return should have a Debrief source screen."
	)
	_append_handoff_check(
		checks,
		"return_action_connected",
		signal_connected,
		"critical",
		"Debrief return signal should be connected to the MetaLayerFlow handoff."
	)
	_append_handoff_check(
		checks,
		"return_action_available",
		return_action_available,
		"critical",
		"Return to Homebase action should be available from Debrief."
	)
	_append_handoff_check(
		checks,
		"mission_result_preserved",
		result_preserved,
		"critical",
		"Debrief and MetaLayerFlow should carry the same last mission result."
	)
	_append_handoff_check(
		checks,
		"active_mission_released",
		active_mission_released,
		"critical",
		"Returning from Debrief should not leave the finished active mission attached."
	)
	_append_handoff_check(
		checks,
		"read_only_snapshot",
		true,
		"critical",
		"Snapshot reads handoff state only."
	)

	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.debrief_return_homebase_handoff.v1",
		"task_id": "TASK_586",
		"ui_sets_gameplay_truth": false,
		"read_only": true,
		"handoff_id": "debrief_return_homebase_handoff_v1",
		"handoff_gate": "pass" if failed_count == 0 else "fail",
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"current_meta_view": _current_meta_view,
		"target_meta_view": "homebase",
		"return_action_id": "debrief_return_homebase",
		"return_action_label": "Return to Homebase",
		"return_action_available": return_action_available,
		"return_signal_connected": signal_connected,
		"homebase_target_exists": homebase_screen != null,
		"debrief_source_exists": debrief_screen != null,
		"homebase_visible": homebase_screen != null and homebase_screen.visible,
		"fob_visible": fob_screen != null and fob_screen.visible,
		"debrief_visible": debrief_screen != null and debrief_screen.visible,
		"navigation_visible": _is_meta_navigation_visible(),
		"expected_post_return_navigation_visible": true,
		"active_mission_released": active_mission_released,
		"mission_host_child_count": mission_host.get_child_count() if mission_host != null else -1,
		"last_mission_result": _last_mission_result.duplicate(true),
		"debrief_mission_result": debrief_result.duplicate(true),
		"debrief_has_mission_result": not debrief_result.is_empty(),
		"mission_result_preserved": result_preserved,
		"checks": checks,
		"issues": _build_handoff_issue_list(checks),
		"recommended_next_action": "Polish the visible Debrief screen layout and make the AAR data pleasant to read.",
	}


func get_frontier_probe_meta_debrief_route_smoke_snapshot() -> Dictionary:
	var debrief_handoff: Dictionary = get_debrief_return_homebase_handoff_snapshot()
	var last_result: Dictionary = Dictionary(debrief_handoff.get("last_mission_result", {})).duplicate(true)
	var debrief_result: Dictionary = Dictionary(debrief_handoff.get("debrief_mission_result", {})).duplicate(true)
	var result_source: Dictionary = debrief_result if not debrief_result.is_empty() else last_result
	var scenario_id: String = _extract_frontier_probe_scenario_id(result_source)
	var route_id: String = String(result_source.get("route_id", "")).strip_edges()
	if route_id.is_empty() and _is_frontier_probe_result(result_source):
		route_id = "frontier_probe_aa_computer_cargo"
	var current_stage: String = "unexpected"
	if _current_meta_view == "debrief":
		current_stage = "debrief_review"
	elif _current_meta_view == "homebase":
		current_stage = "homebase_returned"
	var frontier_probe_result_present: bool = _is_frontier_probe_result(result_source)
	var before_return_ready: bool = current_stage == "debrief_review" \
		and bool(debrief_handoff.get("debrief_visible", false)) \
		and not bool(debrief_handoff.get("homebase_visible", true)) \
		and bool(debrief_handoff.get("return_action_available", false))
	var after_return_ready: bool = current_stage == "homebase_returned" \
		and bool(debrief_handoff.get("homebase_visible", false)) \
		and not bool(debrief_handoff.get("debrief_visible", true)) \
		and bool(debrief_handoff.get("navigation_visible", false))
	var checks: Array = []
	_append_handoff_check(
		checks,
		"frontier_probe_result_present",
		frontier_probe_result_present,
		"critical",
		"Debrief route smoke should carry the Frontier Probe mission result."
	)
	_append_handoff_check(
		checks,
		"route_id_present",
		not route_id.is_empty(),
		"critical",
		"Debrief route smoke should expose a stable route id."
	)
	_append_handoff_check(
		checks,
		"task_586_handoff_gate_passes",
		String(debrief_handoff.get("gate", "")) == "pass",
		"critical",
		"Frontier Probe route smoke should reuse the existing Debrief return handoff gate."
	)
	_append_handoff_check(
		checks,
		"stage_is_debrief_or_homebase",
		before_return_ready or after_return_ready,
		"critical",
		"Route smoke should be valid either while Debrief is visible or after returning to Homebase."
	)
	_append_handoff_check(
		checks,
		"mission_result_preserved",
		bool(debrief_handoff.get("mission_result_preserved", false)),
		"critical",
		"Frontier Probe result should stay identical between MetaLayerFlow and Debrief."
	)
	_append_handoff_check(
		checks,
		"active_mission_released",
		bool(debrief_handoff.get("active_mission_released", false)),
		"critical",
		"Finished Frontier Probe mission should not remain attached during Debrief/Homebase return."
	)
	_append_handoff_check(
		checks,
		"read_only_snapshot",
		true,
		"critical",
		"Snapshot reads route state only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.frontier_probe_meta_debrief_route_smoke.v1",
		"task_id": "TASK_639",
		"source_task_ids": ["TASK_638", "TASK_586"],
		"ui_sets_gameplay_truth": false,
		"read_only": true,
		"route_smoke_id": "frontier_probe_meta_debrief_route_smoke_v1",
		"route_smoke_gate": "pass" if failed_count == 0 else "fail",
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"current_meta_view": _current_meta_view,
		"current_stage": current_stage,
		"route_id": route_id,
		"scenario_id": scenario_id,
		"frontier_probe_result_present": frontier_probe_result_present,
		"debrief_visible": bool(debrief_handoff.get("debrief_visible", false)),
		"homebase_visible": bool(debrief_handoff.get("homebase_visible", false)),
		"navigation_visible": bool(debrief_handoff.get("navigation_visible", false)),
		"return_action_available": bool(debrief_handoff.get("return_action_available", false)),
		"return_signal_connected": bool(debrief_handoff.get("return_signal_connected", false)),
		"mission_result_preserved": bool(debrief_handoff.get("mission_result_preserved", false)),
		"active_mission_released": bool(debrief_handoff.get("active_mission_released", false)),
		"before_return_ready": before_return_ready,
		"after_return_ready": after_return_ready,
		"last_mission_result": last_result.duplicate(true),
		"debrief_mission_result": debrief_result.duplicate(true),
		"debrief_handoff_gate": String(debrief_handoff.get("gate", "")),
		"debrief_handoff": debrief_handoff.duplicate(true),
		"checks": checks,
		"issues": _build_handoff_issue_list(checks),
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "TASK_640 - Frontier Probe Post Debrief Homebase Readability",
	}


func get_station_scenario_meta_debrief_route_smoke_snapshot() -> Dictionary:
	var debrief_handoff: Dictionary = get_debrief_return_homebase_handoff_snapshot()
	var last_result: Dictionary = Dictionary(debrief_handoff.get("last_mission_result", {})).duplicate(true)
	var debrief_result: Dictionary = Dictionary(debrief_handoff.get("debrief_mission_result", {})).duplicate(true)
	var result_source: Dictionary = debrief_result if not debrief_result.is_empty() else last_result
	var scenario_id: String = _extract_station_scenario_id(result_source)
	var route_id: String = String(result_source.get("route_id", "")).strip_edges()
	if route_id.is_empty() and _is_station_scenario_result(result_source):
		route_id = "station_route_aa_door_computer_cargo"
	var current_stage: String = "unexpected"
	if _current_meta_view == "debrief":
		current_stage = "debrief_review"
	elif _current_meta_view == "homebase":
		current_stage = "homebase_returned"
	var station_result_present: bool = _is_station_scenario_result(result_source)
	var before_return_ready: bool = current_stage == "debrief_review" \
		and bool(debrief_handoff.get("debrief_visible", false)) \
		and not bool(debrief_handoff.get("homebase_visible", true)) \
		and bool(debrief_handoff.get("return_action_available", false))
	var after_return_ready: bool = current_stage == "homebase_returned" \
		and bool(debrief_handoff.get("homebase_visible", false)) \
		and not bool(debrief_handoff.get("debrief_visible", true)) \
		and bool(debrief_handoff.get("navigation_visible", false))
	var mini_aar: Dictionary = Dictionary(result_source.get("mini_aar_debrief", {})).duplicate(true)
	var checks: Array = []
	_append_handoff_check(
		checks,
		"station_result_present",
		station_result_present,
		"critical",
		"Debrief route smoke should carry the Station Scenario mission result."
	)
	_append_handoff_check(
		checks,
		"route_id_present",
		not route_id.is_empty(),
		"critical",
		"Debrief route smoke should expose a stable Station route id."
	)
	_append_handoff_check(
		checks,
		"task_586_handoff_gate_passes",
		String(debrief_handoff.get("gate", "")) == "pass",
		"critical",
		"Station route smoke should reuse the existing Debrief return handoff gate."
	)
	_append_handoff_check(
		checks,
		"stage_is_debrief_or_homebase",
		before_return_ready or after_return_ready,
		"critical",
		"Station route smoke should be valid either while Debrief is visible or after returning to Homebase."
	)
	_append_handoff_check(
		checks,
		"mission_result_preserved",
		bool(debrief_handoff.get("mission_result_preserved", false)),
		"critical",
		"Station result should stay identical between MetaLayerFlow and Debrief."
	)
	_append_handoff_check(
		checks,
		"mini_aar_available",
		String(mini_aar.get("schema", "")) == "sternenbuergerchen.mini_aar_debrief_screen_stub.v1",
		"critical",
		"Station result should carry the existing mini AAR Debrief payload."
	)
	_append_handoff_check(
		checks,
		"active_mission_released",
		bool(debrief_handoff.get("active_mission_released", false)),
		"critical",
		"Finished Station mission should not remain attached during Debrief/Homebase return."
	)
	_append_handoff_check(
		checks,
		"read_only_snapshot",
		true,
		"critical",
		"Snapshot reads route state only."
	)
	var failed_count: int = _count_handoff_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_scenario_meta_debrief_route_smoke.v1",
		"task_id": "TASK_744",
		"source_task_ids": ["TASK_743", "TASK_586", "TASK_639"],
		"ui_sets_gameplay_truth": false,
		"read_only": true,
		"route_smoke_id": "station_scenario_meta_debrief_route_smoke_v1",
		"route_smoke_gate": "pass" if failed_count == 0 else "fail",
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"current_meta_view": _current_meta_view,
		"current_stage": current_stage,
		"route_id": route_id,
		"scenario_id": scenario_id,
		"station_result_present": station_result_present,
		"route_tokens": PackedStringArray(["AA", "DOOR", "COM", "CARGO"]),
		"debrief_visible": bool(debrief_handoff.get("debrief_visible", false)),
		"homebase_visible": bool(debrief_handoff.get("homebase_visible", false)),
		"navigation_visible": bool(debrief_handoff.get("navigation_visible", false)),
		"return_action_available": bool(debrief_handoff.get("return_action_available", false)),
		"return_signal_connected": bool(debrief_handoff.get("return_signal_connected", false)),
		"mission_result_preserved": bool(debrief_handoff.get("mission_result_preserved", false)),
		"active_mission_released": bool(debrief_handoff.get("active_mission_released", false)),
		"before_return_ready": before_return_ready,
		"after_return_ready": after_return_ready,
		"mini_aar_debrief": mini_aar.duplicate(true),
		"last_mission_result": last_result.duplicate(true),
		"debrief_mission_result": debrief_result.duplicate(true),
		"debrief_handoff_gate": String(debrief_handoff.get("gate", "")),
		"debrief_handoff": debrief_handoff.duplicate(true),
		"checks": checks,
		"issues": _build_handoff_issue_list(checks),
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "TASK_745 - Station Scenario Post Debrief Homebase Readability",
	}


func request_debrief_return_homebase_for_test() -> Dictionary:
	_on_debrief_return_to_homebase_requested()
	return get_debrief_return_homebase_handoff_snapshot()


func _build_mission_setup_handoff_snapshot(mission_setup: Node) -> Dictionary:
	if mission_setup == null:
		return {
			"present": false,
			"selected_team_unit_ids": [],
			"selected_team_fireteam_ids": [],
			"selected_fireteam_definition_count": 0,
			"selected_team_unit_config_count": 0,
			"member_loadouts": {},
			"map_file_path": "",
			"scenario_file_path": "",
		}
	return {
		"present": true,
		"selected_team_unit_ids": Array(PackedStringArray(mission_setup.get("selected_team_unit_ids"))),
		"selected_team_fireteam_ids": Array(PackedStringArray(mission_setup.get("selected_team_fireteam_ids"))),
		"selected_fireteam_definition_count": Array(mission_setup.get("selected_fireteam_definitions")).size(),
		"selected_team_unit_config_count": Array(mission_setup.get("selected_team_unit_configs")).size(),
		"member_loadouts": Dictionary(mission_setup.get("member_loadouts")).duplicate(true),
		"map_file_path": String(mission_setup.get("map_file_path")).strip_edges(),
		"scenario_file_path": String(mission_setup.get("scenario_file_path")).strip_edges(),
		"defer_friendly_runtime_activation": bool(mission_setup.get("defer_friendly_runtime_activation")),
	}


func _build_tactical_controller_handoff_snapshot(tactical_controller: Node) -> Dictionary:
	if tactical_controller == null:
		return {
			"present": false,
			"planning_state_present": false,
			"mission_drop_craft_id": "",
			"mission_drop_source": "",
			"mission_drop_state": "",
			"mission_drop_card_count": 0,
		}
	var planning_state: Dictionary = {}
	if tactical_controller.has_method("get_planning_state"):
		planning_state = Dictionary(tactical_controller.call("get_planning_state")).duplicate(true)
	return {
		"present": true,
		"planning_state_present": not planning_state.is_empty(),
		"mission_drop_craft_id": String(planning_state.get("mission_drop_craft_id", "")).strip_edges(),
		"mission_drop_source": String(planning_state.get("mission_drop_source", "")).strip_edges(),
		"mission_drop_state": String(planning_state.get("mission_drop_state", "")).strip_edges(),
		"mission_drop_card_count": Array(planning_state.get("mission_drop_cards", [])).size(),
		"drop_ship_staged": bool(planning_state.get("drop_ship_staged", false)),
	}


func _append_handoff_check(checks: Array, check_id: String, passed: bool, severity: String, message: String, details: Dictionary = {}) -> void:
	checks.append({
		"id": check_id,
		"passed": passed,
		"severity": severity,
		"message": message,
		"details": details.duplicate(true),
	})


func _count_handoff_failures(checks: Array, severity_filter: String) -> int:
	var count: int = 0
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)) and String(check.get("severity", "")) == severity_filter:
			count += 1
	return count


func _build_handoff_issue_list(checks: Array) -> Array:
	var issues: Array = []
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			issues.append({
				"id": String(check.get("id", "")),
				"severity": String(check.get("severity", "")),
				"message": String(check.get("message", "")),
			})
	return issues


func _insertion_check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _arrays_match_ordered(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for index in range(left.size()):
		if String(left[index]).strip_edges() != String(right[index]).strip_edges():
			return false
	return true


func _member_loadout_keys_match(left: Dictionary, right: Dictionary) -> bool:
	var left_keys: PackedStringArray = _sorted_dictionary_keys(left)
	var right_keys: PackedStringArray = _sorted_dictionary_keys(right)
	return _arrays_match_ordered(Array(left_keys), Array(right_keys))


func _sorted_dictionary_keys(dictionary: Dictionary) -> PackedStringArray:
	var keys: PackedStringArray = []
	for key_variant in dictionary.keys():
		var key: String = String(key_variant).strip_edges()
		if not key.is_empty():
			keys.append(key)
	keys.sort()
	return keys


func _debrief_handoff_results_match(left: Dictionary, right: Dictionary) -> bool:
	if left.is_empty() or right.is_empty():
		return false
	for key in ["result", "mission_outcome", "winning_team_id", "win_condition_type"]:
		if String(left.get(key, "")).strip_edges() != String(right.get(key, "")).strip_edges():
			return false
	if absf(float(left.get("duration_seconds", 0.0)) - float(right.get("duration_seconds", -1.0))) > 0.01:
		return false
	return Array(left.get("team_states", [])).size() == Array(right.get("team_states", [])).size()


func _extract_frontier_probe_scenario_id(mission_result: Dictionary) -> String:
	for key in ["scenario_id", "mission_id", "source_mission_id"]:
		var value: String = String(mission_result.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	var scenario_file_path: String = String(mission_result.get("scenario_file_path", "")).strip_edges()
	if scenario_file_path.get_file().get_basename() == "frontier_probe_vertical_slice":
		return "frontier_probe_vertical_slice"
	return ""


func _is_frontier_probe_result(mission_result: Dictionary) -> bool:
	if mission_result.is_empty():
		return false
	var route_id: String = String(mission_result.get("route_id", "")).strip_edges()
	if route_id == "frontier_probe_aa_computer_cargo":
		return true
	var scenario_id: String = _extract_frontier_probe_scenario_id(mission_result)
	if scenario_id == "frontier_probe_vertical_slice":
		return true
	var scenario_file_path: String = String(mission_result.get("scenario_file_path", "")).strip_edges()
	return scenario_file_path.ends_with("frontier_probe_vertical_slice.json")


func _extract_station_scenario_id(mission_result: Dictionary) -> String:
	for key in ["scenario_id", "mission_id", "source_mission_id"]:
		var value: String = String(mission_result.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	var scenario_file_path: String = String(mission_result.get("scenario_file_path", "")).strip_edges()
	if scenario_file_path.get_file().get_basename() == "station_route_one_screen_multiplayer_drill":
		return "station_route_one_screen_multiplayer_drill"
	return ""


func _is_station_scenario_result(mission_result: Dictionary) -> bool:
	if mission_result.is_empty():
		return false
	var route_id: String = String(mission_result.get("route_id", "")).strip_edges()
	if route_id == "station_route_aa_door_computer_cargo":
		return true
	var scenario_id: String = _extract_station_scenario_id(mission_result)
	if scenario_id == "station_route_one_screen_multiplayer_drill":
		return true
	var scenario_file_path: String = String(mission_result.get("scenario_file_path", "")).strip_edges()
	return scenario_file_path.ends_with("station_route_one_screen_multiplayer_drill.json")


func _is_meta_navigation_visible() -> bool:
	for path in [
		"HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow",
		"FOBScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow",
	]:
		var nav_row := get_node_or_null(String(path)) as Control
		if nav_row != null and nav_row.visible:
			return true
	return false


func get_air_asset_recovery_snapshot() -> Dictionary:
	var result: Dictionary = {}
	var craft_ids: Array = _air_asset_recovery_by_craft.keys()
	craft_ids.sort()
	for craft_id_variant in craft_ids:
		var craft_id: String = String(craft_id_variant).strip_edges()
		result[craft_id] = Dictionary(_air_asset_recovery_by_craft.get(craft_id, {})).duplicate(true)
	return result


func load_air_asset_recovery_snapshot(snapshot: Dictionary) -> void:
	_air_asset_recovery_by_craft.clear()
	for craft_id_variant in snapshot.keys():
		var craft_id: String = String(craft_id_variant).strip_edges()
		if craft_id.is_empty() or typeof(snapshot.get(craft_id_variant)) != TYPE_DICTIONARY:
			continue
		_air_asset_recovery_by_craft[craft_id] = Dictionary(snapshot.get(craft_id_variant, {})).duplicate(true)
		if not _is_space_craft_away(craft_id) and bool(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("is_recovery_active", Dictionary(_air_asset_recovery_by_craft.get(craft_id, {})))):
			_aircraft_location_by_craft[craft_id] = "homebase"
	_refresh_homebase_screen()
	_refresh_fob_screen()
	_ensure_transport_timer_state()


func advance_air_asset_recovery_time(delta_seconds: float) -> void:
	_advance_air_asset_recoveries(maxf(delta_seconds, 0.0))
	_refresh_homebase_screen()
	_refresh_fob_screen()
	_ensure_transport_timer_state()


func apply_air_asset_recovery_from_mission_result_for_test(mission_result: Dictionary) -> Dictionary:
	var result: Dictionary = _apply_air_asset_recovery_from_mission_result(mission_result)
	_refresh_homebase_screen()
	_refresh_fob_screen()
	_ensure_transport_timer_state()
	return result


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
	_homebase_staged_fireteam_ids = _normalize_homebase_fireteam_selection(_homebase_staged_unit_ids, _homebase_staged_fireteam_ids)


func _on_homebase_fireteam_context_changed(selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray) -> void:
	_homebase_staged_unit_ids = _sanitize_homebase_selection(selected_unit_ids)
	_homebase_staged_fireteam_ids = _normalize_homebase_fireteam_selection(_homebase_staged_unit_ids, selected_fireteam_ids)


func _on_homebase_mission_selection_changed(mission_id: String) -> void:
	if _singleplayer_runtime != null:
		var travel: Dictionary = _singleplayer_runtime.call("get_space_travel_snapshot")
		if String(travel.get("phase", "grounded")) in ["quantum", "stopped", "approach", "surface"]:
			return
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
	_homebase_staged_fireteam_ids = PackedStringArray()
	_refresh_homebase_screen()
	_refresh_map_screen()
	_ensure_transport_timer_state()


func _on_homebase_mission_start_requested() -> void:
	if _active_mission == null and _singleplayer_runtime != null and not bool(_singleplayer_runtime.call("is_campaign_mission")):
		_active_singleplayer_identity.clear()
	var had_preview_deployed_payload: bool = _has_preview_deployed_mission_payload()
	var requested_direct_craft_id: String = _consume_homebase_direct_mission_craft_id()
	_sync_homebase_direct_staging_from_screen()
	var payload_source: String = MISSION_DROP_SOURCE_HOMEBASE_DIRECT if _has_homebase_direct_payload_from_screen(requested_direct_craft_id) else MISSION_DROP_SOURCE_HOMEBASE_DIRECT_THEN_FOB
	_sync_fob_dropship_state_into_mission_planning(
		not had_preview_deployed_payload,
		payload_source,
		requested_direct_craft_id
	)
	if not _has_mission_start_payload():
		return
	if _singleplayer_runtime != null and bool(_singleplayer_runtime.call("is_campaign_mission")):
		var launch: Dictionary = _singleplayer_runtime.call("launch_to_moon_orbit", requested_direct_craft_id)
		if not bool(launch.get("ok", false)):
			_get_homebase_screen().set_meta("singleplayer_departure_error", launch)
			return
		_last_mission_result.clear()
		_show_star_map()
		return
	if payload_source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT:
		_begin_homebase_direct_mission_transfer_from_planning()
		_sync_homebase_direct_mission_drop_transport_fields()
		_refresh_homebase_screen()
		_ensure_transport_timer_state()
	_begin_active_mission_timer()
	var keep_homebase_visible: bool = not requested_direct_craft_id.is_empty() and _current_meta_view == "homebase"
	_start_or_update_active_mission()
	if keep_homebase_visible:
		_show_homebase()


func _on_homebase_aircraft_add_requested(base_craft_type: String) -> void:
	if has_meta("skirmish_points_budget"):
		_singleplayer_runtime.call("request_operation", "skirmish_ship", {"item_id": "cutlass" if base_craft_type == "dropship" else "buccaneer"})
		return
	var normalized_craft_type: String = base_craft_type.strip_edges()
	if normalized_craft_type.is_empty():
		normalized_craft_type = "dropship"
	var aircraft_definition := _build_homebase_aircraft_definition(normalized_craft_type, _get_next_homebase_aircraft_index(normalized_craft_type))
	_homebase_aircraft_definitions.append(aircraft_definition)
	_aircraft_location_by_craft[String(aircraft_definition.get("craft_id", "")).strip_edges()] = "homebase"
	if _singleplayer_runtime != null:
		_singleplayer_runtime.call("sync_crafts")
	_refresh_homebase_screen()


func _on_homebase_aircraft_remove_requested(craft_id: String) -> void:
	if has_meta("skirmish_points_budget"):
		_singleplayer_runtime.call("request_operation", "skirmish_return_ship", {"craft_id": craft_id})
		return
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
	if _singleplayer_runtime != null:
		_singleplayer_runtime.call("sync_crafts")
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
	if _singleplayer_runtime != null:
		_singleplayer_runtime.call("sync_space_wings")
	if _singleplayer_runtime == null:
		_homebase_staged_unit_ids = _remove_unit_ids_from_list(_homebase_staged_unit_ids, PackedStringArray([normalized_pilot_id]))
	_refresh_homebase_screen()


func _on_homebase_aircraft_pilot_cleared(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_assigned_aircraft_pilot_by_craft.erase(normalized_craft_id)
	if _singleplayer_runtime != null:
		_singleplayer_runtime.call("sync_space_wings")
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
	_sync_fob_dropship_state_into_mission_planning(not had_preview_deployed_payload, MISSION_DROP_SOURCE_FOB)
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
	_sync_fob_dropship_state_into_mission_planning(false, MISSION_DROP_SOURCE_FOB)
	_refresh_fob_screen()
	_refresh_homebase_screen()
	_refresh_map_screen()
	_ensure_transport_timer_state()


func _on_fob_transport_craft_pilot_assigned(craft_id: String, pilot_unit_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	var normalized_pilot_id: String = pilot_unit_id.strip_edges()
	if normalized_craft_id.is_empty() or normalized_pilot_id.is_empty():
		return
	if _find_homebase_aircraft_definition(normalized_craft_id).is_empty() or not _is_known_roster_unit(normalized_pilot_id):
		return
	if not _find_pending_mission_craft_transfer(normalized_craft_id).is_empty() or _has_active_homebase_pilot_transfer(normalized_craft_id):
		return
	var previous_pilot_id: String = String(_assigned_aircraft_pilot_by_craft.get(normalized_craft_id, "")).strip_edges()
	for assigned_craft_id_variant in _assigned_aircraft_pilot_by_craft.keys():
		var assigned_craft_id: String = String(assigned_craft_id_variant).strip_edges()
		if assigned_craft_id == normalized_craft_id:
			continue
		if String(_assigned_aircraft_pilot_by_craft.get(assigned_craft_id, "")).strip_edges() == normalized_pilot_id:
			_assigned_aircraft_pilot_by_craft.erase(assigned_craft_id)
	if not previous_pilot_id.is_empty() and previous_pilot_id != normalized_pilot_id:
		_append_unit_to_fob(previous_pilot_id)
	_assigned_aircraft_pilot_by_craft[normalized_craft_id] = normalized_pilot_id
	if _singleplayer_runtime != null:
		_singleplayer_runtime.call("sync_space_wings")
	_remove_unit_from_fob_selection(normalized_pilot_id)
	_refresh_fob_screen()
	_refresh_homebase_screen()
	_refresh_map_screen()


func _on_fob_transport_craft_pilot_cleared(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	if _find_homebase_aircraft_definition(normalized_craft_id).is_empty():
		return
	if not _find_pending_mission_craft_transfer(normalized_craft_id).is_empty() or _has_active_homebase_pilot_transfer(normalized_craft_id):
		return
	var previous_pilot_id: String = String(_assigned_aircraft_pilot_by_craft.get(normalized_craft_id, "")).strip_edges()
	_assigned_aircraft_pilot_by_craft.erase(normalized_craft_id)
	if _singleplayer_runtime != null:
		_singleplayer_runtime.call("sync_space_wings")
	if not previous_pilot_id.is_empty():
		_append_unit_to_fob(previous_pilot_id)
	_refresh_fob_screen()
	_refresh_homebase_screen()
	_refresh_map_screen()


func _on_debrief_return_to_fob_requested() -> void:
	if _continue_campaign_after_failed_extraction():
		return
	_show_fob()


func _on_debrief_return_to_homebase_requested() -> void:
	if _continue_campaign_after_failed_extraction():
		return
	_show_homebase()


func _continue_campaign_after_failed_extraction() -> bool:
	if not is_campaign_start() or not bool(_last_mission_result.get("campaign_checkpoint_retry_required", false)):
		return false
	# This is an explicit rollback, never a physical arrival or a fresh save.
	load("res://scripts/meta/game_start_contract.gd").request_start(get_tree(), "campaign", "continue")
	get_tree().change_scene_to_file("res://scenes/meta/meta_layer_test.tscn")
	return true


func _start_mission(prepared_map = null, prepared_cache: RefCounted = null) -> void:
	if not get_surface_departure_retirement_guard(String(_active_singleplayer_identity.get("craft_id", "")), String(_active_singleplayer_identity.get("location_id", ""))).ok:
		return
	var mission_host = _get_mission_host()
	if mission_host == null:
		push_warning("MetaLayerFlow requires a MissionHost child.")
		return
	_release_preview_mission()

	var location_id:=String(_active_singleplayer_identity.get("location_id",""))
	if not location_id.is_empty():
		var existing: Node=_location_registry.get_location(location_id)
		if existing!=null:
			var previous_scenario := String(Dictionary(existing.get_meta("singleplayer_mission_identity",{})).get("scenario_id",""))
			var incoming_scenario := String(_active_singleplayer_identity.get("scenario_id",""))
			var prior_driver: Node=existing.get_node_or_null("CombatLoopDriver")
			var resolved_retry := prior_driver != null and bool(prior_driver.get("_combat_finished")) and not String(_active_singleplayer_identity.get("job_id","")).is_empty()
			if is_campaign_start() and (previous_scenario != incoming_scenario or resolved_retry):
				# A new job at the same place gets fresh scenario gates while finite
				# discoveries/depletion remain with the persistent resource owner.
				_singleplayer_runtime.call("release_location_resources",location_id)
				_location_contexts.erase(location_id)
				if _active_mission==existing: _active_mission=null
				existing.free()
			else:
				var resident_view := existing.get_node_or_null("Primary3DView")
				if prepared_cache != null and resident_view != null:
					resident_view.call("set_prepared_terrain_resource_cache", prepared_cache)
					resident_view.call("render_map")
				_admit_existing_location(existing)
				_show_mission()
				return
	if _active_mission != null:
		if String(_active_mission.get_meta("location_id","")).is_empty(): _active_mission.queue_free()
		else: _remember_location(_active_mission)
		_active_mission = null

	var mission_instance = MISSION_TEST_SCENE.instantiate()
	_configure_mission_instance(mission_instance, _selected_unit_ids, _selected_fireteam_ids, false, prepared_map, prepared_cache)
	mission_host.add_child(mission_instance)
	_active_mission = mission_instance
	if not location_id.is_empty():
		mission_instance.set_meta("location_id",location_id)
		_location_registry.register_location(location_id,mission_instance)
		_remember_location(mission_instance)
		if _singleplayer_runtime.has_method("register_location_resources"):
			_singleplayer_runtime.call("register_location_resources", mission_instance, location_id)
	_sync_active_homebase_direct_selection_from_mission_setup()
	_connect_planning_state_bridge(_active_mission)
	_connect_mission_end(_active_mission)
	_show_mission()
	# MissionSetup adds its separate 3D CanvasLayer deferred during startup.
	call_deferred("_sync_mission_host_visibility")


func _start_or_update_active_mission(prepared_map = null, prepared_cache: RefCounted = null) -> void:
	if not get_surface_departure_retirement_guard(String(_active_singleplayer_identity.get("craft_id", "")), String(_active_singleplayer_identity.get("location_id", ""))).ok:
		return
	var location_id:=String(_active_singleplayer_identity.get("location_id",""))
	if not location_id.is_empty():
		_start_mission(prepared_map, prepared_cache)
		return
	if _active_mission != null:
		_release_preview_mission()
		_configure_mission_instance(_active_mission, _selected_unit_ids, _selected_fireteam_ids, false)
		_apply_planning_state_to_mission(_active_mission)
		_sync_active_homebase_direct_selection_from_mission_setup()
		_show_mission()
		return
	_start_mission(prepared_map, prepared_cache)


func _configure_mission_instance(mission_instance: Node, selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray, preview_mode: bool, prepared_map = null, prepared_cache: RefCounted = null) -> void:
	_bind_location_visit(mission_instance, _active_singleplayer_identity.duplicate(true) if not preview_mode else {})
	if selected_unit_ids.is_empty():
		selected_unit_ids = _selected_unit_ids.duplicate()
	if selected_fireteam_ids.is_empty():
		selected_fireteam_ids = _selected_fireteam_ids.duplicate()
	var mission_planning: Dictionary = _include_campaign_pilot_in_departing_payload(_mission_planning_state)
	var location_id:=String(_active_singleplayer_identity.get("location_id",""))
	if not preview_mode and not location_id.is_empty():
		mission_planning=_planning_for_location(mission_planning,location_id)
		selected_unit_ids=PackedStringArray(mission_planning.get("embarked_unit_ids",[]))
		selected_fireteam_ids=PackedStringArray()
		for id in selected_unit_ids:
			var found_team: String="ft1"
			for card: Dictionary in Array(mission_planning.get("mission_drop_cards",[])):
				var members: Array=Array(card.get("embarked_unit_ids",[]))
				if members.has(id):
					var selected: Array=_build_homebase_direct_card_fireteam_selection(card,members)
					var index: int=members.find(id)
					if index<selected.size(): found_team=String(selected[index])
			selected_fireteam_ids.append(found_team)
		_mission_planning_state=mission_planning.duplicate(true)
	if is_campaign_start() and not selected_unit_ids.is_empty():
		selected_unit_ids = selected_unit_ids.duplicate()
		selected_fireteam_ids = selected_fireteam_ids.duplicate()
		# Temporary sortie membership preserves the homebase fireteam assignment.
		var pilot_id: String = String(mission_planning.get("mission_drop_pilot_unit_id", ""))
		if pilot_id.is_empty():
			pilot_id = String(_assigned_aircraft_pilot_by_craft.get(String(mission_planning.get("mission_drop_craft_id", "")), ""))
		if pilot_id.is_empty() and _assigned_aircraft_pilot_by_craft.size() == 1:
			pilot_id = String(_assigned_aircraft_pilot_by_craft.values()[0])
		if not pilot_id.is_empty() and not selected_unit_ids.has(pilot_id):
			selected_unit_ids.append(pilot_id)
			selected_fireteam_ids.append(String(selected_fireteam_ids[0]) if not selected_fireteam_ids.is_empty() else "ft1")
		for id_variant in Array(mission_planning.get("embarked_unit_ids", [])):
			var id: String = String(id_variant)
			if selected_unit_ids.has(id) or not _is_known_roster_unit(id): continue
			selected_unit_ids.append(id)
			selected_fireteam_ids.append(String(selected_fireteam_ids[0]) if not selected_fireteam_ids.is_empty() else "ft1")
		mission_instance.set_meta("campaign_ground_pilot_id", pilot_id)
		for card: Dictionary in Array(mission_planning.get("mission_drop_cards", [])):
			if String(card.get("pilot_unit_id", "")) != pilot_id:
				continue
			var payload: Array = Array(card.get("embarked_unit_ids", [])).duplicate()
			if not payload.has(pilot_id): payload.append(pilot_id)
			card["embarked_unit_ids"] = payload
			card["passenger_count"] = payload.size()
		var embarked: Array = Array(mission_planning.get("embarked_unit_ids", [])).duplicate()
		if not pilot_id.is_empty() and not embarked.has(pilot_id): embarked.append(pilot_id)
		mission_planning["embarked_unit_ids"] = embarked
	if is_campaign_start() and not preview_mode:
		_mission_planning_state = mission_planning.duplicate(true)
	_configure_mission_overlay_nodes(mission_instance, preview_mode)
	var selected_mission: Dictionary = _get_selected_mission_definition()

	var mission_setup = mission_instance.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("selected_team_unit_ids", selected_unit_ids)
		mission_setup.set("selected_team_fireteam_ids", selected_fireteam_ids)
		var planning_fireteam_definitions: Array = Array(_mission_planning_state.get("selected_fireteam_definitions", []))
		if not planning_fireteam_definitions.is_empty():
			mission_setup.set("selected_fireteam_definitions", planning_fireteam_definitions.duplicate(true))
		else:
			var fob_screen: Node = get_node_or_null("FOBScreen")
			if fob_screen != null and fob_screen.has_method("get_fireteam_definitions"):
				mission_setup.set("selected_fireteam_definitions", Array(fob_screen.call("get_fireteam_definitions")).duplicate(true))
		var planning_unit_configs: Array = Array(_mission_planning_state.get("selected_team_unit_configs", []))
		if is_campaign_start():
			# Homebase Direct bypasses the legacy FOB roster presenter. Pass the
			# authoritative campaign profiles rather than its unknown-ID fallback.
			planning_unit_configs = []
			for unit: Dictionary in _all_team_units:
				if selected_unit_ids.has(String(unit.get("unit_id", ""))):
					planning_unit_configs.append(unit.duplicate(true))
		if not planning_unit_configs.is_empty():
			mission_setup.set("selected_team_unit_configs", planning_unit_configs.duplicate(true))
		else:
			var fob_screen_for_configs: Node = get_node_or_null("FOBScreen")
			if fob_screen_for_configs != null and fob_screen_for_configs.has_method("get_selected_unit_configs"):
				mission_setup.set("selected_team_unit_configs", Array(fob_screen_for_configs.call("get_selected_unit_configs")).duplicate(true))
		mission_setup.set("map_file_path", String(selected_mission.get("map_file_path", DEFAULT_META_MAP_PATH)).strip_edges())
		if prepared_map != null:
			mission_setup.call("use_prepared_terrain", String(mission_setup.get("map_file_path")), prepared_map)
		if prepared_cache != null:
			mission_setup.call("use_prepared_terrain_resource_cache", prepared_cache)
		mission_setup.set("scenario_file_path", String(selected_mission.get("scenario_file_path", NO_SCENARIO_FILE_PATH)).strip_edges())
		mission_setup.set("defer_friendly_runtime_activation", _should_defer_friendly_runtime_activation())
		mission_setup.set("allow_full_roster_when_selection_empty", false)
		var gameplay_settings: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings"))
		mission_setup.set("fog_of_war_mode", String(gameplay_settings.get("fog_of_war_mode", "known_terrain")))

		var planning_member_loadouts: Dictionary = Dictionary(_mission_planning_state.get("member_loadouts", {})).duplicate(true)
		if is_campaign_start():
			var homebase_loadout_owner: Node = _get_homebase_screen()
			for id in selected_unit_ids:
				planning_member_loadouts[id] = Dictionary(homebase_loadout_owner.call("_get_member_loadout", id)).duplicate(true)
		if is_campaign_start():
			mission_planning["member_loadouts"] = planning_member_loadouts.duplicate(true)
			if not preview_mode:
				_mission_planning_state["member_loadouts"] = planning_member_loadouts.duplicate(true)
		if not planning_member_loadouts.is_empty():
			mission_setup.set("member_loadouts", planning_member_loadouts)
		else:
			var fob_loadouts: Dictionary = _build_fob_member_loadouts()
			if not fob_loadouts.is_empty():
				mission_setup.set("member_loadouts", fob_loadouts)
		if mission_setup.has_method("apply_runtime_selection_contract"):
			mission_setup.call("apply_runtime_selection_contract")



	var tactical_controller = mission_instance.get_node_or_null("TacticalController")
	if tactical_controller != null:
		tactical_controller.set("preview_mode", preview_mode)
		if tactical_controller.has_method("set_planning_state"):
			tactical_controller.call("set_planning_state", mission_planning)

	var command_flow_driver = mission_instance.get_node_or_null("CommandFlowDriver")
	if command_flow_driver != null and not selected_unit_ids.is_empty():
		command_flow_driver.set("unit_id", String(selected_unit_ids[0]))

	var combat_driver = mission_instance.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("friendly_unit_paths", _build_selected_friendly_paths(selected_unit_ids))
		combat_driver.set("mission_time_limit_seconds", float(selected_mission.get("time_limit_seconds", 1200.0)))
		var selected_win_condition: String = String(selected_mission.get("win_condition", "")).strip_edges().to_lower()
		if not selected_win_condition.is_empty():
			combat_driver.set("win_condition", selected_win_condition)
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


func _sync_active_homebase_direct_selection_from_mission_setup() -> void:
	if _active_mission == null:
		return
	if String(_mission_planning_state.get("mission_drop_source", "")).strip_edges().to_lower() != MISSION_DROP_SOURCE_HOMEBASE_DIRECT:
		return
	var mission_unit_ids := PackedStringArray(Array(_mission_planning_state.get("embarked_unit_ids", [])))
	var mission_setup: Node = _active_mission.get_node_or_null("MissionSetup")
	if mission_unit_ids.is_empty() and mission_setup != null:
		mission_unit_ids = PackedStringArray(mission_setup.get("selected_team_unit_ids"))
	if mission_unit_ids.is_empty():
		return
	var mission_fireteam_ids: PackedStringArray = []
	if mission_setup != null:
		mission_fireteam_ids = PackedStringArray(mission_setup.get("selected_team_fireteam_ids"))
	if mission_fireteam_ids.size() != mission_unit_ids.size():
		var launched_craft_id: String = String(_mission_planning_state.get("mission_drop_craft_id", "")).strip_edges()
		for card_variant in Array(_mission_planning_state.get("mission_drop_cards", [])):
			if typeof(card_variant) != TYPE_DICTIONARY:
				continue
			var card: Dictionary = Dictionary(card_variant)
			if String(card.get("craft_id", "")).strip_edges() != launched_craft_id:
				continue
			mission_fireteam_ids = PackedStringArray(_build_homebase_direct_card_fireteam_selection(card, Array(mission_unit_ids)))
			break
	_selected_unit_ids = mission_unit_ids.duplicate()
	_selected_fireteam_ids = _normalize_homebase_fireteam_selection(_selected_unit_ids, mission_fireteam_ids)


func _connect_mission_end(mission_instance: Node) -> void:
	if mission_instance == null:
		return

	var combat_driver = mission_instance.get_node_or_null("CombatLoopDriver")
	if combat_driver == null:
		return

	var callback: Callable=_on_location_combat_resolved.bind(mission_instance) if not String(mission_instance.get_meta("location_id","")).is_empty() else _on_mission_combat_resolved
	if not combat_driver.combat_resolved.is_connected(callback): combat_driver.combat_resolved.connect(callback)


func _on_mission_combat_resolved(mission_result: Dictionary) -> void:
	if _active_mission == null:
		return
	var resolved_result: Dictionary = mission_result.duplicate(true)
	var failed_extraction := false
	if is_campaign_start():
		var crew_boarding: Dictionary = _active_mission.get_node("TacticalController").call("request_campaign_crew_boarding", String(_active_singleplayer_identity.get("craft_id", "")))
		if not bool(crew_boarding.get("ok", false)):
			if String(crew_boarding.get("reason", "")) in ["pilot_unavailable", "crew_unavailable"]:
				# A terminal casualty cannot walk/board. Finish the existing result
				# lifecycle without authorizing a ghost flight or rewarding extraction.
				failed_extraction = true
				resolved_result["original_mission_result"] = mission_result.duplicate(true)
				resolved_result["result"] = "defeat"
				resolved_result["mission_outcome"] = "defeat"
				resolved_result["winning_team_id"] = ""
				resolved_result["campaign_checkpoint_retry_required"] = true
				resolved_result["extraction_failure"] = crew_boarding.duplicate(true)
			else:
				_pending_campaign_mission_result = mission_result.duplicate(true)
				_get_homebase_screen().set_meta("singleplayer_departure_error", crew_boarding)
				return
	if not failed_extraction and _singleplayer_runtime != null and not _active_singleplayer_identity.is_empty():
		var return_gate: Dictionary = _singleplayer_runtime.call("authorize_return", String(_active_singleplayer_identity.get("craft_id", "")))
		if not bool(return_gate.get("ok", false)):
			# Preserve the actual scene and its confirmed result if a transport
			# invariant fails; never orphan a remote craft by releasing its world.
			_get_homebase_screen().set_meta("singleplayer_departure_error", return_gate)
			return
	_pending_campaign_mission_result.clear()
	if _singleplayer_runtime != null:
		_singleplayer_runtime.call("record_mission_result", resolved_result, _active_singleplayer_identity.duplicate(true))

	_last_mission_result = _build_mission_result(_active_mission, resolved_result)
	_last_mission_result = _apply_air_asset_recovery_from_mission_result(_last_mission_result)
	if not failed_extraction:
		_return_homebase_direct_craft_after_mission()
	_last_mission_result = _apply_mission_progression_to_roster(_last_mission_result)
	if failed_extraction:
		_last_mission_result["progression_save_ok"] = false
	var fob_screen = _get_fob_screen()
	if fob_screen != null:
		fob_screen.set_last_mission_result(_last_mission_result)

	var debrief_screen = _get_debrief_screen()
	if debrief_screen != null:
		debrief_screen.set_mission_result(_last_mission_result)

	_release_active_mission()
	var drop_source := _get_mission_drop_source()
	_mission_planning_state = DEFAULT_MISSION_PLANNING_STATE.duplicate(true)
	_mission_planning_state["mission_drop_source"] = drop_source
	_reset_active_mission_timer()
	_ensure_transport_timer_state()
	_refresh_map_screen()
	if _has_space_route_in_progress():
		_show_star_map()
	else:
		_show_debrief()


func _return_homebase_direct_craft_after_mission() -> void:
	if not _is_homebase_direct_mission_drop_source():
		return
	var cards: Array = _mission_planning_state.get("mission_drop_cards", [])
	var selected_craft_id := String(_mission_planning_state.get("mission_drop_craft_id", ""))
	for craft_id in _build_homebase_direct_mission_sync_craft_ids(cards):
		var result_craft:=String(_active_singleplayer_identity.get("craft_id",""))
		if not result_craft.is_empty() and String(craft_id)!=result_craft: continue
		var transfer := _find_pending_mission_craft_transfer(craft_id)
		var card := _find_mission_drop_card_in_planning_state(craft_id)
		var source := String(card.get("payload_source", "")).strip_edges().to_lower()
		var direct_craft := source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT or (source.is_empty() and craft_id == selected_craft_id)
		var inbound := String(transfer.get("phase", "")) == "to_mission" \
			and String(transfer.get("payload_source", "")) == MISSION_DROP_SOURCE_HOMEBASE_DIRECT
		var on_map := transfer.is_empty() and direct_craft \
			and String(_aircraft_location_by_craft.get(craft_id, "")) == "mission"
		if inbound or on_map:
			_begin_mission_craft_transfer(craft_id, "to_homebase", MISSION_DROPSHIP_TO_HOMEBASE_SECONDS, MISSION_DROP_SOURCE_HOMEBASE_DIRECT)


func _build_mission_result(mission_instance: Node, mission_result: Dictionary) -> Dictionary:
	var result_unit_ids: PackedStringArray = _selected_unit_ids.duplicate()
	var result_fireteam_ids: PackedStringArray = _selected_fireteam_ids.duplicate()
	if is_campaign_start():
		var setup: Node = mission_instance.get_node_or_null("MissionSetup")
		if setup != null:
			result_unit_ids = PackedStringArray(setup.get("selected_team_unit_ids"))
			result_fireteam_ids = PackedStringArray(setup.get("selected_team_fireteam_ids"))
	var team_states: Array = []
	var friendly_slot_count: int = mini(result_unit_ids.size(), FRIENDLY_NODE_NAMES.size())
	for slot_index in range(friendly_slot_count):
		var node_name: String = String(FRIENDLY_NODE_NAMES[slot_index])
		var requested_unit_id: String = String(result_unit_ids[slot_index])

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
				"portrait_path": _resolve_unit_portrait_path(resolved_unit_id),
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

	merged_result["selected_unit_ids"] = result_unit_ids.duplicate()
	merged_result["selected_fireteam_ids"] = result_fireteam_ids.duplicate()
	merged_result["team_states"] = team_states
	var air_asset_status: Dictionary = _extract_air_asset_status_from_mission(mission_instance)
	if not air_asset_status.is_empty():
		merged_result["air_asset_status"] = air_asset_status
	# The optional live AAR snapshot assumes a fit tactical selection anchor.
	# Terminal casualties already have authoritative team/tactical result data.
	var mini_aar_debrief: Dictionary = {} if bool(merged_result.get("campaign_checkpoint_retry_required", false)) else _extract_mini_aar_debrief_from_mission(mission_instance)
	if not mini_aar_debrief.is_empty():
		merged_result["mini_aar_debrief"] = mini_aar_debrief
	return merged_result


func _extract_mini_aar_debrief_from_mission(mission_instance: Node) -> Dictionary:
	if mission_instance == null:
		return {}
	var tactical_controller := mission_instance.get_node_or_null("TacticalController")
	if tactical_controller == null or not tactical_controller.has_method("get_mini_aar_debrief_screen_snapshot"):
		return {}
	var snapshot: Dictionary = Dictionary(tactical_controller.call("get_mini_aar_debrief_screen_snapshot")).duplicate(true)
	if String(snapshot.get("schema", "")) != "sternenbuergerchen.mini_aar_debrief_screen_stub.v1":
		return {}
	if not bool(snapshot.get("read_only", false)) or bool(snapshot.get("ui_sets_gameplay_truth", true)):
		return {}
	return snapshot


func _extract_air_asset_status_from_mission(mission_instance: Node) -> Dictionary:
	if mission_instance == null:
		return {}
	var tactical_controller := mission_instance.get_node_or_null("TacticalController")
	if tactical_controller != null and tactical_controller.has_method("get_air_asset_status_snapshot"):
		var controller_status: Dictionary = Dictionary(tactical_controller.call("get_air_asset_status_snapshot")).duplicate(true)
		if not controller_status.is_empty():
			return controller_status
	var simulation_root := mission_instance.get_node_or_null("SimulationRoot")
	if simulation_root != null and simulation_root.has_method("get_air_asset_status_snapshot"):
		var simulation_status: Dictionary = Dictionary(simulation_root.call("get_air_asset_status_snapshot")).duplicate(true)
		if simulation_status.has(String(_mission_planning_state.get("mission_drop_craft_id", ""))):
			return Dictionary(simulation_status.get(String(_mission_planning_state.get("mission_drop_craft_id", "")), {})).duplicate(true)
		for key_variant in simulation_status.keys():
			if typeof(simulation_status.get(key_variant)) == TYPE_DICTIONARY:
				return Dictionary(simulation_status.get(key_variant, {})).duplicate(true)
	return {}


func _apply_air_asset_recovery_from_mission_result(mission_result: Dictionary) -> Dictionary:
	var result: Dictionary = mission_result.duplicate(true)
	var air_asset_status: Dictionary = Dictionary(result.get("air_asset_status", {})).duplicate(true)
	if air_asset_status.is_empty():
		return result
	var craft_id: String = String(air_asset_status.get("asset_id", _mission_planning_state.get("mission_drop_craft_id", ""))).strip_edges()
	if craft_id.is_empty():
		craft_id = String(_mission_planning_state.get("launch_ready_craft_id", "")).strip_edges()
	if craft_id.is_empty():
		return result
	var craft_definition: Dictionary = _find_homebase_aircraft_definition(craft_id)
	var craft_context: Dictionary = {
		"craft_id": craft_id,
		"craft_type": String(craft_definition.get("craft_type", air_asset_status.get("asset_type", "dropship"))).strip_edges(),
		"display_name": String(craft_definition.get("display_name", air_asset_status.get("display_name", craft_id))).strip_edges(),
		"pilot_unit_id": String(_assigned_aircraft_pilot_by_craft.get(craft_id, air_asset_status.get("pilot_unit_id", _mission_planning_state.get("mission_drop_pilot_unit_id", "")))).strip_edges(),
	}
	var recovery_state: Dictionary = Dictionary(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("from_air_asset_status", air_asset_status, craft_context, {})).duplicate(true)
	if String(recovery_state.get("meta_state", "craft_available")) == "craft_available":
		result["air_asset_recovery"] = recovery_state
		return result
	_air_asset_recovery_by_craft[craft_id] = recovery_state
	# Recovery metadata is not evidence of a physical arrival. The orbital
	# lifecycle alone returns this craft home; terminal extraction uses Continue.
	if not _is_space_craft_away(craft_id):
		_aircraft_location_by_craft[craft_id] = "homebase"
		_remove_pending_mission_craft_transfer(craft_id)
	if String(_mission_planning_state.get("launch_ready_craft_id", "")).strip_edges() == craft_id:
		_mission_planning_state["launch_ready_craft_id"] = ""
	if String(_mission_planning_state.get("mission_drop_craft_id", "")).strip_edges() == craft_id:
		_mission_planning_state["mission_drop_state"] = "unavailable"
		_mission_planning_state["mission_drop_return_requested"] = true
		_mission_planning_state["drop_ship_staged"] = false
	result["air_asset_recovery"] = recovery_state
	result["air_asset_loss_recovery_summary"] = String(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("build_debrief_summary", recovery_state))
	result["softlock_guard"] = true
	return result


func _apply_mission_progression_to_roster(mission_result: Dictionary) -> Dictionary:
	var result: Dictionary = mission_result.duplicate(true)
	if _all_team_units.is_empty():
		return result
	var roster: Dictionary = _build_progression_roster_payload()
	if roster.is_empty():
		return result
	var progression_result: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", roster, result))
	var updated_roster: Dictionary = Dictionary(progression_result.get("updated_roster", {})).duplicate(true)
	var updated_units: Array = Array(updated_roster.get("units", []))
	if not updated_units.is_empty():
		_replace_roster_units(updated_units)
	result["character_events"] = Array(progression_result.get("character_events", [])).duplicate(true)
	result["progression_summary"] = Dictionary(progression_result.get("summary", {})).duplicate(true)
	result["progression_unit_updates"] = Array(progression_result.get("unit_updates", [])).duplicate(true)
	result["progression_award_summary"] = Dictionary(progression_result.get("award_summary", {})).duplicate(true)
	result["fireteam_cohesion"] = Dictionary(progression_result.get("fireteam_cohesion", {})).duplicate(true)
	var personnel_result: Dictionary = Dictionary(PERSONNEL_EVENT_RESOLVER_SCRIPT.call("evaluate_roster", updated_roster, {"mission_result": result}))
	updated_roster = Dictionary(personnel_result.get("updated_roster", updated_roster)).duplicate(true)
	result["personnel_events"] = Array(personnel_result.get("events", [])).duplicate(true)
	result["personnel_notifications"] = PackedStringArray(personnel_result.get("notifications", PackedStringArray()))
	if is_campaign_start() or has_meta("skirmish_preset_id"):
		# Campaign/preset progress never overwrites the saved team library. is one coherent home checkpoint, never local_player.
		result["progression_save_ok"] = true
		result["progression_save_path"] = "user://campaigns/introduction/checkpoint_v1.json"
		_replace_roster_units(Array(updated_roster.get("units", [])))
		return result
	var save_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", updated_roster, PLAYER_ROSTER_STORE_SCRIPT.DEFAULT_PROFILE_ID))
	result["progression_save_ok"] = bool(save_result.get("ok", false))
	result["progression_save_path"] = String(save_result.get("path", ""))
	result["progression_save_diagnostics"] = PackedStringArray(save_result.get("diagnostics", PackedStringArray()))
	return result


func _build_progression_roster_payload() -> Dictionary:
	var load_result: Dictionary = {} if is_campaign_start() or has_meta("skirmish_preset_id") else Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", PLAYER_ROSTER_STORE_SCRIPT.DEFAULT_PROFILE_ID))
	var roster: Dictionary = Dictionary(load_result.get("roster", {})).duplicate(true) if bool(load_result.get("ok", false)) else {}
	if roster.is_empty():
		roster = {
			"schema_version": 1,
			"generator_id": "meta_layer_progression_runtime",
			"seed": "meta_layer_runtime",
			"player_profile_id": "campaign_introduction" if is_campaign_start() else PLAYER_ROSTER_STORE_SCRIPT.DEFAULT_PROFILE_ID,
			"units": _all_team_units.duplicate(true),
			"relationship_pairs": [],
			"fireteam_suggestions": [],
			"multiplayer_boundary": {
				"ownership_scope": "player_profile_local",
			},
		}
	else:
		roster["units"] = _all_team_units.duplicate(true)
	roster["roster_size"] = Array(roster.get("units", [])).size()
	return roster


func _replace_roster_units(updated_units: Array) -> void:
	var units_by_id: Dictionary = {}
	var next_all_units: Array = []
	for unit_variant in updated_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant).duplicate(true)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue
		units_by_id[unit_id] = unit
		next_all_units.append(unit)
	if next_all_units.is_empty():
		return
	_all_team_units = next_all_units
	_available_team_units = _replace_units_by_id(_available_team_units, units_by_id)


func _replace_units_by_id(source_units: Array, units_by_id: Dictionary) -> Array:
	var result: Array = []
	for unit_variant in source_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
		if units_by_id.has(unit_id):
			result.append(Dictionary(units_by_id.get(unit_id, {})).duplicate(true))
		else:
			result.append(unit.duplicate(true))
	return result


func _release_active_mission() -> void:
	_pending_campaign_mission_result.clear()
	if _active_mission == null:
		return

	if not String(_active_mission.get_meta("location_id","")).is_empty():
		_remember_location(_active_mission)
		_active_mission=null
		_sync_mission_host_visibility()
		return
	var tactical_controller = _active_mission.get_node_or_null("TacticalController")
	if tactical_controller != null and tactical_controller.planning_state_changed.is_connected(_on_mission_planning_state_changed):
		tactical_controller.planning_state_changed.disconnect(_on_mission_planning_state_changed)
	_active_mission.queue_free()
	_active_mission = null


func _release_preview_mission() -> void:
	if _preview_mission == null:
		return

	_preview_mission.queue_free()
	_preview_mission = null
	_preview_mission_signature = {}


func _on_homebase_transport_timer_timeout() -> void:
	_retry_space_surface_departures()
	var profile_enabled: bool = _transport_refresh_timing_debug_enabled
	var refresh_started_usec: int = Time.get_ticks_usec() if profile_enabled else 0
	var scope_started_usec: int = refresh_started_usec
	var refresh_scopes_usec: Dictionary = {}
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
		if String(entry.get("phase", "")) == "surface_retirement":
			active_mission_craft_transfers.append(entry)
			continue
		var default_duration: float = _get_mission_craft_transfer_default_duration(String(entry.get("phase", "")).strip_edges())
		entry["elapsed_seconds"] = min(float(entry.get("elapsed_seconds", 0.0)) + 1.0, float(entry.get("duration_seconds", default_duration)))
		if float(entry.get("elapsed_seconds", 0.0)) >= float(entry.get("duration_seconds", default_duration)):
			completed_mission_craft_transfers.append(entry)
		else:
			active_mission_craft_transfers.append(entry)
	_pending_mission_craft_transfers = active_mission_craft_transfers

	_advance_air_asset_recoveries(1.0)
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

	if profile_enabled:
		refresh_scopes_usec["transfer_advance_and_completions_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_refresh_fob_screen()
	if profile_enabled:
		refresh_scopes_usec["refresh_fob_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	var previous_transport_planning: Dictionary = _mission_planning_state.duplicate(true)
	if _is_homebase_direct_mission_drop_source():
		_sync_homebase_direct_mission_drop_transport_fields()
	else:
		_sync_mission_drop_transport_fields_from_fob()
	if profile_enabled:
		refresh_scopes_usec["sync_transport_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_refresh_homebase_screen()
	if profile_enabled:
		refresh_scopes_usec["refresh_homebase_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	# The Timer changed transport fields, not the tactical order plan. Send only
	# that actual delta to the existing mission owner; legacy consumers retain
	# the full refresh fallback. Transfer/recovery mutations above are unchanged.
	var transport_delta: Dictionary = _build_planning_delta(previous_transport_planning, _mission_planning_state)
	if _active_mission == null or not _try_apply_mission_transport_delta(_active_mission, transport_delta):
		_refresh_map_screen()
	if profile_enabled:
		refresh_scopes_usec["refresh_map_usec"] = Time.get_ticks_usec() - scope_started_usec
		scope_started_usec = Time.get_ticks_usec()
	_ensure_transport_timer_state()
	if profile_enabled:
		refresh_scopes_usec["ensure_timer_state_usec"] = Time.get_ticks_usec() - scope_started_usec
		_transport_refresh_timing_debug_invocation_count += 1
		var total_usec: int = Time.get_ticks_usec() - refresh_started_usec
		var named_refresh_usec: int = int(refresh_scopes_usec["refresh_fob_usec"]) + int(refresh_scopes_usec["sync_transport_usec"]) + int(refresh_scopes_usec["refresh_homebase_usec"]) + int(refresh_scopes_usec["refresh_map_usec"])
		refresh_scopes_usec["other_usec"] = maxi(total_usec - named_refresh_usec, 0)
		_transport_refresh_timing_debug_snapshot = {
			"enabled": true, "read_only": true, "derived_only": true,
			"ui_sets_gameplay_truth": false, "snapshot_serialized": false,
			"total_usec": total_usec, "scopes_usec": refresh_scopes_usec,
			"invocation_count": _transport_refresh_timing_debug_invocation_count,
			"completed_at_msec": Time.get_ticks_msec(),
		}


func _advance_air_asset_recoveries(delta_seconds: float) -> bool:
	if _air_asset_recovery_by_craft.is_empty():
		return false
	var changed: bool = false
	var next_recoveries: Dictionary = {}
	for craft_id_variant in _air_asset_recovery_by_craft.keys():
		var craft_id: String = String(craft_id_variant).strip_edges()
		if craft_id.is_empty():
			continue
		var previous_state: Dictionary = Dictionary(_air_asset_recovery_by_craft.get(craft_id, {})).duplicate(true)
		if _is_space_craft_away(craft_id):
			next_recoveries[craft_id] = previous_state
			continue
		var next_state: Dictionary = Dictionary(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("tick_recovery", previous_state, delta_seconds)).duplicate(true)
		next_recoveries[craft_id] = next_state
		if JSON.stringify(previous_state) != JSON.stringify(next_state):
			changed = true
		if String(next_state.get("meta_state", "craft_available")) == "craft_available":
			_aircraft_location_by_craft[craft_id] = "homebase"
	_air_asset_recovery_by_craft = next_recoveries
	return changed


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


func _begin_mission_craft_transfer(craft_id: String, phase: String, duration_seconds: float, payload_source: String = MISSION_DROP_SOURCE_FOB) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	var normalized_phase: String = phase.strip_edges().to_lower()
	if normalized_craft_id.is_empty() or normalized_phase.is_empty():
		return
	if not get_surface_departure_retirement_guard(normalized_craft_id).ok:
		return
	if normalized_phase == "to_homebase" and _singleplayer_runtime != null and not _active_singleplayer_identity.is_empty():
		var travel: Dictionary = _singleplayer_runtime.call("get_space_travel_snapshot",normalized_craft_id)
		var surface_exit: bool = String(travel.get("craft_id", "")) == normalized_craft_id and String(travel.get("phase", "")) == "surface"
		var retirement_record: Dictionary = _prepare_space_surface_departure(normalized_craft_id) if surface_exit else {}
		if surface_exit and retirement_record.is_empty(): return
		var return_gate: Dictionary = _singleplayer_runtime.call("authorize_return", normalized_craft_id)
		if not bool(return_gate.get("ok", false)):
			return
		if surface_exit:
			var previous_transfer_id: String = String(_find_pending_mission_craft_transfer(normalized_craft_id).get("transfer_id", ""))
			var orbit: Dictionary = _singleplayer_runtime.call("enter_space_orbit", normalized_craft_id)
			if not bool(orbit.get("ok", false)):
				return
			if not previous_transfer_id.is_empty():
				_pending_mission_craft_transfers = _pending_mission_craft_transfers.filter(func(entry: Dictionary) -> bool:
					return not (String(entry.get("craft_id", "")) == normalized_craft_id and String(entry.get("transfer_id", "")) == previous_transfer_id))
			if _register_space_surface_departure(normalized_craft_id, retirement_record):
				call_deferred("_finish_space_surface_departure", normalized_craft_id, retirement_record)
			return
	var normalized_source: String = payload_source.strip_edges().to_lower()
	if normalized_source.is_empty():
		normalized_source = MISSION_DROP_SOURCE_FOB
	var next_transfers: Array = []
	for entry_variant in _pending_mission_craft_transfers:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		if String(entry.get("craft_id", "")).strip_edges() == normalized_craft_id:
			continue
		next_transfers.append(entry)
	_pending_mission_craft_transfers = next_transfers
	if normalized_phase == "to_mission":
		_aircraft_location_by_craft[normalized_craft_id] = "homebase" if normalized_source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT else "fob"
	elif normalized_phase == "to_fob" or normalized_phase == "to_homebase":
		_aircraft_location_by_craft[normalized_craft_id] = "mission"
	_pending_mission_craft_transfers.append(_build_mission_craft_transfer_entry(normalized_craft_id, normalized_phase, duration_seconds, normalized_source))


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
		"to_homebase":
			_aircraft_location_by_craft[craft_id] = "homebase"
			call_deferred("_finish_singleplayer_visit_if_returned")


func _get_mission_craft_transfer_default_duration(phase: String) -> float:
	match phase.strip_edges().to_lower():
		"to_mission":
			return MISSION_DROPSHIP_TO_MAP_SECONDS
		"to_homebase":
			return MISSION_DROPSHIP_TO_HOMEBASE_SECONDS
		_:
			return MISSION_DROPSHIP_TO_FOB_SECONDS


func _find_pending_mission_craft_transfer(craft_id: String) -> Dictionary:
	for entry_variant in _pending_mission_craft_transfers:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return entry.duplicate(true)
	return {}


func _remove_pending_mission_craft_transfer(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	var retained: Array = []
	for entry_variant in _pending_mission_craft_transfers:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		if String(entry.get("craft_id", "")).strip_edges() == normalized_craft_id:
			if String(entry.get("phase", "")) == "surface_retirement" and _pending_surface_departures.has(normalized_craft_id):
				retained.append(entry)
			continue
		retained.append(entry)
	_pending_mission_craft_transfers = retained


func _append_unit_to_fob(unit_id: String) -> void:
	if unit_id.is_empty() or _selected_unit_ids.has(unit_id):
		return
	_selected_unit_ids.append(unit_id)
	_selected_fireteam_ids.append("")


func _remove_unit_from_fob_selection(unit_id: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return
	var next_unit_ids: PackedStringArray = []
	var next_fireteam_ids: PackedStringArray = []
	for unit_index in range(_selected_unit_ids.size()):
		var current_unit_id: String = String(_selected_unit_ids[unit_index]).strip_edges()
		if current_unit_id.is_empty() or current_unit_id == normalized_unit_id:
			continue
		next_unit_ids.append(current_unit_id)
		next_fireteam_ids.append(String(_selected_fireteam_ids[unit_index]).strip_edges() if unit_index < _selected_fireteam_ids.size() else "")
	_selected_unit_ids = next_unit_ids
	_selected_fireteam_ids = next_fireteam_ids


func _refresh_homebase_screen() -> void:
	var homebase_screen = _get_homebase_screen()
	if homebase_screen == null:
		return
	# Keep the owner's normalization even when only its hidden presenter waits.
	_homebase_staged_fireteam_ids = _normalize_homebase_fireteam_selection(_homebase_staged_unit_ids, _homebase_staged_fireteam_ids)
	if _active_mission != null and not homebase_screen.is_visible_in_tree():
		_homebase_presentation_dirty = true
		return
	_homebase_presentation_dirty = false
	var fob_screen = _get_fob_screen()
	var fireteam_definitions: Array = []
	if fob_screen != null and fob_screen.has_method("get_fireteam_definitions"):
		fireteam_definitions = Array(fob_screen.call("get_fireteam_definitions")).duplicate(true)
	homebase_screen.setup_roster(_available_team_units, _homebase_staged_unit_ids)
	# This is a presentation refresh, not a request to equip old FOB exports.
	homebase_screen.set_fireteam_context(_homebase_staged_fireteam_ids, fireteam_definitions, false)
	var selected_mission: Dictionary = _get_selected_mission_definition()
	homebase_screen.set_mission_context(
		_mission_catalog,
		String(selected_mission.get("map_file_path", DEFAULT_META_MAP_PATH)).strip_edges(),
		String(selected_mission.get("mission_name", "Operation: FOB Transfer")).strip_edges(),
		int(selected_mission.get("slot_count", FRIENDLY_NODE_NAMES.size())),
		String(selected_mission.get("mission_id", _selected_mission_id)).strip_edges()
	)
	homebase_screen.set_transport_state(
		_build_homebase_aircraft_definitions_with_recovery(),
		_assigned_aircraft_pilot_by_craft,
		_pending_homebase_team_transfers,
		_pending_homebase_pilot_transfers,
		_aircraft_location_by_craft,
		_selected_aircraft_cargo_by_craft,
		_loaded_aircraft_cargo_by_craft,
		_pending_homebase_cargo_loads
	)
	homebase_screen.set_mission_occupancy(_selected_unit_ids.size() + _count_assigned_aircraft_pilots(), _count_assigned_aircraft_pilots())
	if fob_screen != null and fob_screen.has_method("can_request_mission_start"):
		var has_preview_deployed_payload: bool = _has_preview_deployed_mission_payload()
		homebase_screen.set_mission_launch_state(
			bool(fob_screen.call("can_request_mission_start")) or has_preview_deployed_payload,
			"Fireteam already deployed on the mission map. Start live mission when ready." if has_preview_deployed_payload else String(fob_screen.call("get_mission_launch_summary"))
		)
	else:
		homebase_screen.set_mission_launch_state(_has_preview_deployed_mission_payload(), "Fireteam already deployed on the mission map. Start live mission when ready.")
	if homebase_screen.has_method("set_personnel_events"):
		homebase_screen.call("set_personnel_events", Array(_last_mission_result.get("personnel_events", [])))
	if homebase_screen.has_method("set_last_mission_result_summary"):
		homebase_screen.call("set_last_mission_result_summary", _last_mission_result.duplicate(true))
	if homebase_screen.has_method("set_post_mission_skill_delta_summary"):
		homebase_screen.call("set_post_mission_skill_delta_summary", Dictionary(_last_mission_result.get("progression_award_summary", {})))


func _build_homebase_aircraft_definitions_with_recovery() -> Array:
	return _build_transport_craft_states()


func _load_persistent_player_roster() -> void:
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", PLAYER_ROSTER_STORE_SCRIPT.DEFAULT_PROFILE_ID))
	if not bool(load_result.get("ok", false)):
		set_meta("player_roster_source", "unit_roster_presets")
		set_meta("player_roster_diagnostics", PackedStringArray(load_result.get("diagnostics", PackedStringArray())))
		return
	var units: Array = Array(PLAYER_ROSTER_STORE_SCRIPT.call("roster_to_unit_array", Dictionary(load_result.get("roster", {}))))
	if units.is_empty():
		set_meta("player_roster_source", "unit_roster_presets_empty_save")
		return
	_all_team_units = units.duplicate(true)
	_available_team_units = units.duplicate(true)
	set_meta("player_roster_source", "user_save")
	set_meta("player_roster_profile_id", String(load_result.get("profile_id", PLAYER_ROSTER_STORE_SCRIPT.DEFAULT_PROFILE_ID)))
	set_meta("player_roster_store_path", String(load_result.get("path", "")))


func _ensure_singleplayer_release_start_bootstrap() -> void:
	if is_campaign_start():
		return
	_ensure_singleplayer_release_default_mission_selection()
	_ensure_singleplayer_release_homebase_direct_drop_source()
	_ensure_singleplayer_bootstrap_roster_floor()
	_homebase_staged_unit_ids = _filter_known_unit_ids(_homebase_staged_unit_ids)
	_selected_unit_ids = _filter_known_unit_ids(_selected_unit_ids)
	if _homebase_staged_unit_ids.size() < mini(SINGLEPLAYER_BOOTSTRAP_FIRETEAM_SIZE, 2) or _selected_unit_ids.size() < mini(SINGLEPLAYER_BOOTSTRAP_FIRETEAM_SIZE, 2):
		_homebase_staged_unit_ids = _pick_singleplayer_bootstrap_fireteam_unit_ids()
		_homebase_staged_fireteam_ids = _build_singleplayer_bootstrap_fireteam_ids(_homebase_staged_unit_ids)
		_selected_unit_ids = _homebase_staged_unit_ids.duplicate()
		_selected_fireteam_ids = _homebase_staged_fireteam_ids.duplicate()
		set_meta("singleplayer_bootstrap_selection_repaired", true)

	var bootstrap_craft_id: String = _ensure_singleplayer_bootstrap_dropship()
	if bootstrap_craft_id.is_empty():
		return
	if String(_assigned_aircraft_pilot_by_craft.get(bootstrap_craft_id, "")).strip_edges().is_empty():
		var pilot_unit_id: String = _pick_singleplayer_bootstrap_pilot_unit_id(_homebase_staged_unit_ids)
		if not pilot_unit_id.is_empty():
			_assigned_aircraft_pilot_by_craft[bootstrap_craft_id] = pilot_unit_id
			set_meta("singleplayer_bootstrap_pilot_repaired", true)
	_aircraft_location_by_craft[bootstrap_craft_id] = "homebase"
	set_meta("singleplayer_bootstrap_craft_id", bootstrap_craft_id)
	set_meta("singleplayer_bootstrap_fireteam_id", _get_singleplayer_bootstrap_payload_fireteam_id())
	set_meta("singleplayer_bootstrap_enabled", true)


func _ensure_singleplayer_release_default_mission_selection() -> bool:
	var normalized_mission_id: String = _selected_mission_id.strip_edges()
	if normalized_mission_id == SINGLEPLAYER_RELEASE_DEFAULT_MISSION_ID and _is_known_mission_id(normalized_mission_id):
		var current_definition: Dictionary = _get_mission_definition_by_id(normalized_mission_id)
		var current_map_path: String = String(current_definition.get("map_file_path", _selected_mission_map_path)).strip_edges()
		if not current_map_path.is_empty() and current_map_path != _selected_mission_map_path:
			_selected_mission_map_path = current_map_path
			set_meta("singleplayer_bootstrap_mission_selection_repaired", true)
			return true
		return false
	if not normalized_mission_id.is_empty() and normalized_mission_id != "fob_transfer" and _is_known_mission_id(normalized_mission_id):
		return false

	var default_definition: Dictionary = _get_mission_definition_by_id(SINGLEPLAYER_RELEASE_DEFAULT_MISSION_ID)
	if default_definition.is_empty():
		return false
	_selected_mission_id = SINGLEPLAYER_RELEASE_DEFAULT_MISSION_ID
	_selected_mission_map_path = String(default_definition.get("map_file_path", DEFAULT_META_MAP_PATH)).strip_edges()
	set_meta("singleplayer_bootstrap_mission_selection_repaired", true)
	return true


func _ensure_singleplayer_release_homebase_direct_drop_source() -> bool:
	var current_source: String = _get_mission_drop_source()
	if current_source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT:
		return false
	_mission_planning_state["mission_drop_source"] = MISSION_DROP_SOURCE_HOMEBASE_DIRECT
	_mission_planning_state["drop_ship_requested"] = false
	_mission_planning_state["drop_ship_staged"] = false
	set_meta("singleplayer_bootstrap_drop_source_repaired", true)
	set_meta("singleplayer_bootstrap_drop_source_previous", current_source)
	return true


func _seed_singleplayer_bootstrap_homebase_payload() -> void:
	# Campaign people begin outside. Boarding is an explicit physical walk to
	# the actual ship, unlike the ready-to-launch Skirmish convenience setup.
	if is_campaign_start():
		# A coherent home checkpoint may contain already boarded crew. Restore
		# the existing payload owner too, rather than only hiding their visuals.
		var saved_units: Dictionary = Dictionary(_campaign_start.get("checkpoint").get("base_personnel", {})).get("units", {})
		var saved_craft: String = String(get_meta("singleplayer_bootstrap_craft_id", ""))
		var campaign_screen: Node = _get_homebase_screen()
		if campaign_screen != null and not saved_craft.is_empty():
			var boarded_teams := PackedStringArray()
			for team_id: String in _homebase_staged_fireteam_ids:
				var members: PackedStringArray = campaign_screen.call("_get_member_unit_ids_for_fireteam", team_id)
				var all_aboard: bool = not members.is_empty()
				for id: String in members:
					var person: Dictionary = saved_units.get(id, {})
					all_aboard = all_aboard and String(person.get("status", "")) == "aboard" and String(person.get("craft_id", "")) == saved_craft
				if all_aboard:
					boarded_teams.append(team_id)
			if not boarded_teams.is_empty():
				campaign_screen.call("seed_homebase_direct_launch_payload", saved_craft, boarded_teams, true)
		return
	var homebase_screen = _get_homebase_screen()
	if homebase_screen == null or not homebase_screen.has_method("seed_homebase_direct_launch_payload"):
		return
	var bootstrap_craft_id: String = String(get_meta("singleplayer_bootstrap_craft_id", "")).strip_edges()
	if bootstrap_craft_id.is_empty():
		return
	var payload_fireteam_id: String = _get_singleplayer_bootstrap_payload_fireteam_id()
	if payload_fireteam_id.is_empty():
		return
	homebase_screen.call(
		"seed_homebase_direct_launch_payload",
		bootstrap_craft_id,
		PackedStringArray([payload_fireteam_id]),
		not is_campaign_start()
	)
	set_meta("singleplayer_bootstrap_payload_seeded", true)


func _ensure_singleplayer_visible_homebase_actionability() -> void:
	if has_meta("skirmish_preset_id"):
		return
	# Startup recovery must never rebuild an established multi-place roster.
	if not _location_contexts.is_empty(): return
	if _singleplayer_runtime != null and String(Dictionary(_singleplayer_runtime.call("get_space_travel_snapshot")).get("phase", "grounded")) != "grounded":
		return
	if is_campaign_start():
		return
	if not bool(get_meta("singleplayer_bootstrap_enabled", false)) or _active_mission != null or not _last_mission_result.is_empty():
		return
	var homebase_screen = _get_homebase_screen()
	if homebase_screen == null:
		return
	var mission_selection_repaired: bool = _ensure_singleplayer_release_default_mission_selection()
	var drop_source_repaired: bool = _ensure_singleplayer_release_homebase_direct_drop_source()
	if mission_selection_repaired or drop_source_repaired:
		_refresh_homebase_screen()
	if _is_singleplayer_visible_homebase_actionable(homebase_screen):
		set_meta("singleplayer_visible_homebase_deadend_repaired", false)
		return

	_repair_singleplayer_bootstrap_start_state(false)
	_refresh_homebase_screen()
	_seed_singleplayer_bootstrap_homebase_payload()
	_refresh_homebase_screen()
	if _is_singleplayer_visible_homebase_actionable(homebase_screen):
		set_meta("singleplayer_visible_homebase_deadend_repaired", true)
		set_meta("singleplayer_visible_homebase_deadend_repair_mode", "preserve_existing")
		return

	_repair_singleplayer_bootstrap_start_state(true)
	_refresh_homebase_screen()
	_seed_singleplayer_bootstrap_homebase_payload()
	_refresh_homebase_screen()
	set_meta("singleplayer_visible_homebase_deadend_repaired", _is_singleplayer_visible_homebase_actionable(homebase_screen))
	set_meta("singleplayer_visible_homebase_deadend_repair_mode", "force_default")


func _schedule_singleplayer_visible_homebase_actionability_guard() -> void:
	if has_meta("skirmish_preset_id"):
		return
	if not _location_contexts.is_empty(): return
	if is_campaign_start():
		return
	if not bool(get_meta("singleplayer_bootstrap_enabled", false)) or not _last_mission_result.is_empty():
		return
	if _active_mission != null or _active_mission_started_at_msec > 0:
		return
	if bool(get_meta("singleplayer_visible_homebase_post_show_guard_pending", false)):
		return
	set_meta("singleplayer_visible_homebase_post_show_guard_pending", true)
	call_deferred("_run_singleplayer_visible_homebase_actionability_post_show_guard")


func _run_singleplayer_visible_homebase_actionability_post_show_guard() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	set_meta("singleplayer_visible_homebase_post_show_guard_pending", false)
	if _active_mission != null or _active_mission_started_at_msec > 0:
		set_meta("singleplayer_visible_homebase_post_show_guard_skipped_view", "active_mission")
		return
	if _current_meta_view != "homebase":
		set_meta("singleplayer_visible_homebase_post_show_guard_skipped_view", _current_meta_view)
		return

	var homebase_screen = _get_homebase_screen()
	var before_actionable: bool = _is_singleplayer_visible_homebase_actionable(homebase_screen)
	set_meta("singleplayer_visible_homebase_post_show_guard_ran", true)
	set_meta("singleplayer_visible_homebase_post_show_guard_before_actionable", before_actionable)
	_ensure_singleplayer_visible_homebase_actionability()
	var after_actionable: bool = _is_singleplayer_visible_homebase_actionable(homebase_screen)
	set_meta("singleplayer_visible_homebase_post_show_guard_after_actionable", after_actionable)
	set_meta("singleplayer_visible_homebase_post_show_guard_repaired", not before_actionable and after_actionable)


func _is_singleplayer_visible_homebase_actionable(homebase_screen: Node) -> bool:
	if homebase_screen == null or not homebase_screen.has_method("get_homebase_direct_staging_snapshot"):
		return false
	if _selected_mission_id.strip_edges() != SINGLEPLAYER_RELEASE_DEFAULT_MISSION_ID:
		return false
	if _get_mission_drop_source() != MISSION_DROP_SOURCE_HOMEBASE_DIRECT:
		return false
	var craft_id: String = String(get_meta("singleplayer_bootstrap_craft_id", "")).strip_edges()
	var staging: Dictionary = Dictionary(homebase_screen.call("get_homebase_direct_staging_snapshot"))
	var payload_operator_count: int = int(staging.get("payload_operator_count", 0))
	var boarded_operator_count: int = int(staging.get("boarded_operator_count", 0))
	var has_payload: bool = payload_operator_count >= mini(SINGLEPLAYER_BOOTSTRAP_FIRETEAM_SIZE, 2)
	var has_boarding: bool = boarded_operator_count >= payload_operator_count and payload_operator_count > 0
	var has_craft_payload: bool = not craft_id.is_empty() and bool(homebase_screen.call("can_request_mission_start", craft_id))
	var can_start_any: bool = bool(homebase_screen.call("can_request_mission_start"))
	var visible_aircraft_count: int = Array(staging.get("visible_aircraft_definitions", [])).size()
	if visible_aircraft_count <= 0 and homebase_screen.has_method("get_aircraft_panel_snapshot"):
		var aircraft: Dictionary = Dictionary(homebase_screen.call("get_aircraft_panel_snapshot"))
		visible_aircraft_count = Array(aircraft.get("visible_aircraft_definitions", [])).size()
	var readiness_ready: bool = true
	if homebase_screen.has_method("get_pre_mission_readiness_snapshot"):
		var readiness: Dictionary = Dictionary(homebase_screen.call("get_pre_mission_readiness_snapshot"))
		readiness_ready = String(readiness.get("overall_state", "")).strip_edges() == "ready"
	return visible_aircraft_count > 0 and has_payload and has_boarding and readiness_ready and (has_craft_payload or can_start_any)


func _repair_singleplayer_bootstrap_start_state(force_default_selection: bool) -> void:
	_ensure_singleplayer_bootstrap_roster_floor()
	_homebase_staged_unit_ids = _filter_known_unit_ids(_homebase_staged_unit_ids)
	_selected_unit_ids = _filter_known_unit_ids(_selected_unit_ids)
	if force_default_selection or _homebase_staged_unit_ids.size() < mini(SINGLEPLAYER_BOOTSTRAP_FIRETEAM_SIZE, 2):
		_homebase_staged_unit_ids = _pick_singleplayer_bootstrap_fireteam_unit_ids()
		_homebase_staged_fireteam_ids = _build_singleplayer_bootstrap_fireteam_ids(_homebase_staged_unit_ids)
	else:
		_homebase_staged_fireteam_ids = _normalize_homebase_fireteam_selection(_homebase_staged_unit_ids, _homebase_staged_fireteam_ids)
	if force_default_selection or _selected_unit_ids.size() < mini(SINGLEPLAYER_BOOTSTRAP_FIRETEAM_SIZE, 2):
		_selected_unit_ids = _homebase_staged_unit_ids.duplicate()
		_selected_fireteam_ids = _homebase_staged_fireteam_ids.duplicate()
	else:
		_selected_fireteam_ids = _normalize_homebase_fireteam_selection(_selected_unit_ids, _selected_fireteam_ids)

	var bootstrap_craft_id: String = _ensure_singleplayer_bootstrap_dropship()
	if bootstrap_craft_id.is_empty():
		return
	if String(_assigned_aircraft_pilot_by_craft.get(bootstrap_craft_id, "")).strip_edges().is_empty():
		var pilot_unit_id: String = _pick_singleplayer_bootstrap_pilot_unit_id(_homebase_staged_unit_ids)
		if not pilot_unit_id.is_empty():
			_assigned_aircraft_pilot_by_craft[bootstrap_craft_id] = pilot_unit_id
			set_meta("singleplayer_bootstrap_pilot_repaired", true)
	_aircraft_location_by_craft[bootstrap_craft_id] = "homebase"
	set_meta("singleplayer_bootstrap_craft_id", bootstrap_craft_id)
	set_meta("singleplayer_bootstrap_fireteam_id", _get_singleplayer_bootstrap_payload_fireteam_id())
	set_meta("singleplayer_bootstrap_enabled", true)


func get_singleplayer_start_bootstrap_snapshot() -> Dictionary:
	var craft_id: String = String(get_meta("singleplayer_bootstrap_craft_id", "")).strip_edges()
	return {
		"enabled": bool(get_meta("singleplayer_bootstrap_enabled", false)),
		"payload_seeded": bool(get_meta("singleplayer_bootstrap_payload_seeded", false)),
		"visible_homebase_deadend_repaired": bool(get_meta("singleplayer_visible_homebase_deadend_repaired", false)),
		"visible_homebase_deadend_repair_mode": String(get_meta("singleplayer_visible_homebase_deadend_repair_mode", "")).strip_edges(),
		"visible_homebase_post_show_guard_ran": bool(get_meta("singleplayer_visible_homebase_post_show_guard_ran", false)),
		"visible_homebase_post_show_guard_before_actionable": bool(get_meta("singleplayer_visible_homebase_post_show_guard_before_actionable", false)),
		"visible_homebase_post_show_guard_after_actionable": bool(get_meta("singleplayer_visible_homebase_post_show_guard_after_actionable", false)),
		"visible_homebase_post_show_guard_repaired": bool(get_meta("singleplayer_visible_homebase_post_show_guard_repaired", false)),
		"selected_unit_ids": Array(_selected_unit_ids),
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
		"selected_mission_id": _selected_mission_id,
		"selected_mission_map_path": _selected_mission_map_path,
		"mission_drop_source": _get_mission_drop_source(),
		"mission_selection_repaired": bool(get_meta("singleplayer_bootstrap_mission_selection_repaired", false)),
		"drop_source_repaired": bool(get_meta("singleplayer_bootstrap_drop_source_repaired", false)),
		"drop_source_previous": String(get_meta("singleplayer_bootstrap_drop_source_previous", "")).strip_edges(),
		"homebase_staged_unit_ids": Array(_homebase_staged_unit_ids),
		"homebase_staged_fireteam_ids": Array(_homebase_staged_fireteam_ids),
		"craft_id": craft_id,
		"craft_count": _homebase_aircraft_definitions.size(),
		"pilot_unit_id": String(_assigned_aircraft_pilot_by_craft.get(craft_id, "")).strip_edges(),
		"craft_location": String(_aircraft_location_by_craft.get(craft_id, "")).strip_edges(),
		"roster_source": String(get_meta("player_roster_source", "")).strip_edges(),
		"roster_repaired": bool(get_meta("singleplayer_bootstrap_roster_repaired", false)),
		"selection_repaired": bool(get_meta("singleplayer_bootstrap_selection_repaired", false)),
		"pilot_repaired": bool(get_meta("singleplayer_bootstrap_pilot_repaired", false)),
		"available_unit_count": _available_team_units.size(),
		"all_unit_count": _all_team_units.size(),
		"has_pilot_candidate": _has_singleplayer_bootstrap_pilot_candidate(),
	}


func _ensure_singleplayer_bootstrap_roster_floor() -> void:
	if is_campaign_start():
		return
	var fallback_roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.get_homebase_roster()
	if _all_team_units.is_empty() or _available_team_units.is_empty():
		_all_team_units = fallback_roster.duplicate(true)
		_available_team_units = fallback_roster.duplicate(true)
		set_meta("singleplayer_bootstrap_roster_source", "unit_roster_presets")
		return
	var needs_repair: bool = _count_non_pilot_units(_available_team_units) < mini(SINGLEPLAYER_BOOTSTRAP_FIRETEAM_SIZE, 2) or not _has_singleplayer_bootstrap_pilot_candidate()
	if not needs_repair:
		return
	_all_team_units = _merge_missing_units_by_id(_all_team_units, fallback_roster)
	_available_team_units = _merge_missing_units_by_id(_available_team_units, fallback_roster)
	set_meta("singleplayer_bootstrap_roster_repaired", true)


func _merge_missing_units_by_id(base_units: Array, fallback_units: Array) -> Array:
	var result: Array = []
	var known_ids: Dictionary = {}
	for unit_variant in base_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant).duplicate(true)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or known_ids.has(unit_id):
			continue
		known_ids[unit_id] = true
		result.append(unit)
	for unit_variant in fallback_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var fallback_unit: Dictionary = Dictionary(unit_variant).duplicate(true)
		var fallback_id: String = String(fallback_unit.get("unit_id", "")).strip_edges()
		if fallback_id.is_empty() or known_ids.has(fallback_id):
			continue
		known_ids[fallback_id] = true
		result.append(fallback_unit)
	return result


func _filter_known_unit_ids(unit_ids: PackedStringArray) -> PackedStringArray:
	var known_ids: Dictionary = {}
	for unit_variant in _all_team_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_id: String = String(Dictionary(unit_variant).get("unit_id", "")).strip_edges()
		if not unit_id.is_empty():
			known_ids[unit_id] = true
	var result: PackedStringArray = PackedStringArray()
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty() or result.has(unit_id) or not known_ids.has(unit_id):
			continue
		result.append(unit_id)
	return result


func _count_non_pilot_units(units: Array) -> int:
	var count: int = 0
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		if not _is_singleplayer_pilot_candidate(Dictionary(unit_variant)):
			count += 1
	return count


func _has_singleplayer_bootstrap_pilot_candidate() -> bool:
	return not _pick_singleplayer_bootstrap_pilot_unit_id(_homebase_staged_unit_ids).is_empty()


func _get_singleplayer_bootstrap_payload_fireteam_id() -> String:
	for fireteam_id_variant in _homebase_staged_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges()
		if not fireteam_id.is_empty():
			return fireteam_id
	if is_campaign_start():
		return ""
	return SINGLEPLAYER_BOOTSTRAP_FIRETEAM_ID


func _pick_singleplayer_bootstrap_fireteam_unit_ids() -> PackedStringArray:
	var picked: PackedStringArray = PackedStringArray()
	for unit_variant in _available_team_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if _is_singleplayer_pilot_candidate(unit):
			continue
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or picked.has(unit_id):
			continue
		picked.append(unit_id)
		if picked.size() >= SINGLEPLAYER_BOOTSTRAP_FIRETEAM_SIZE:
			return picked
	for unit_variant in _available_team_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_id: String = String(Dictionary(unit_variant).get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or picked.has(unit_id):
			continue
		picked.append(unit_id)
		if picked.size() >= SINGLEPLAYER_BOOTSTRAP_FIRETEAM_SIZE:
			return picked
	return picked


func _build_singleplayer_bootstrap_fireteam_ids(unit_ids: PackedStringArray) -> PackedStringArray:
	var fireteam_ids: PackedStringArray = PackedStringArray()
	for _unit_id in unit_ids:
		fireteam_ids.append(SINGLEPLAYER_BOOTSTRAP_FIRETEAM_ID)
	return fireteam_ids


func _ensure_singleplayer_bootstrap_dropship() -> String:
	for craft_variant in _homebase_aircraft_definitions:
		if typeof(craft_variant) != TYPE_DICTIONARY:
			continue
		var craft_def: Dictionary = Dictionary(craft_variant)
		var craft_id: String = String(craft_def.get("craft_id", "")).strip_edges()
		if craft_id.is_empty():
			continue
		if String(craft_def.get("craft_type", "")).strip_edges() == SINGLEPLAYER_BOOTSTRAP_CRAFT_TYPE:
			return craft_id
	var aircraft_definition := _build_homebase_aircraft_definition(SINGLEPLAYER_BOOTSTRAP_CRAFT_TYPE, _get_next_homebase_aircraft_index(SINGLEPLAYER_BOOTSTRAP_CRAFT_TYPE))
	_homebase_aircraft_definitions.append(aircraft_definition)
	return String(aircraft_definition.get("craft_id", "")).strip_edges()


func _pick_singleplayer_bootstrap_pilot_unit_id(excluded_unit_ids: PackedStringArray) -> String:
	for unit_variant in _available_team_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or excluded_unit_ids.has(unit_id):
			continue
		if _is_singleplayer_pilot_candidate(unit):
			return unit_id
	for unit_variant in _available_team_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_id: String = String(Dictionary(unit_variant).get("unit_id", "")).strip_edges()
		if not unit_id.is_empty() and not excluded_unit_ids.has(unit_id):
			return unit_id
	return ""


func _is_singleplayer_pilot_candidate(unit: Dictionary) -> bool:
	var role_category: String = String(unit.get("roster_role_category", "")).strip_edges().to_lower()
	var role_name: String = String(unit.get("role_name", "")).strip_edges().to_lower()
	if role_category.contains("pilot") or role_name.contains("pilot"):
		return true
	for key in ["dropship_piloting", "freighter_piloting", "fighter_piloting"]:
		if float(unit.get(key, 0.0)) > 0.0:
			return true
	return false


func _refresh_fob_screen() -> void:
	var fob_screen = _get_fob_screen()
	if fob_screen == null:
		return
	if _is_homebase_direct_mission_drop_source():
		fob_screen.set_meta("homebase_direct_bypass_active", true)
		return
	fob_screen.set_meta("homebase_direct_bypass_active", false)
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
	var has_pending_transfers: bool = not _pending_homebase_team_transfers.is_empty() or not _pending_homebase_pilot_transfers.is_empty() or not _pending_homebase_cargo_loads.is_empty() or not _pending_mission_craft_transfers.is_empty() or _has_active_air_asset_recovery()
	transport_timer.wait_time = 1.0
	transport_timer.one_shot = false
	if has_pending_transfers:
		if transport_timer.is_stopped():
			transport_timer.start()
	else:
		transport_timer.stop()


func _has_active_air_asset_recovery() -> bool:
	for recovery_variant in _air_asset_recovery_by_craft.values():
		if typeof(recovery_variant) != TYPE_DICTIONARY:
			continue
		if bool(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("is_recovery_active", Dictionary(recovery_variant))):
			return true
	return false


func _build_homebase_team_transfer_entry(unit_ids: PackedStringArray) -> Dictionary:
	_transfer_sequence += 1
	return {
		"transfer_id": "team_%d" % _transfer_sequence,
		"unit_ids": unit_ids.duplicate(),
		"unit_profiles": _build_unit_subset_by_ids(unit_ids),
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


func _build_mission_craft_transfer_entry(craft_id: String, phase: String, duration_seconds: float, payload_source: String = MISSION_DROP_SOURCE_FOB) -> Dictionary:
	_transfer_sequence += 1
	var normalized_source: String = payload_source.strip_edges().to_lower()
	if normalized_source.is_empty():
		normalized_source = MISSION_DROP_SOURCE_FOB
	var departure: Dictionary = {}
	if _singleplayer_runtime != null:
		departure = Dictionary(_singleplayer_runtime.call("get_snapshot").get("campaign", {}).get("departures_by_craft_id", {}).get(craft_id, {}))
	return {
		"transfer_id": "mission_craft_%d" % _transfer_sequence,
		"destination_location_id": "homebase" if phase == "to_homebase" else String(departure.get("destination_location_id", "")),
		"job_id": String(departure.get("job_id", "")),
		"origin_pad_id": String(departure.get("landing_pad_id", "")),
		"craft_id": craft_id,
		"phase": phase,
		"payload_source": normalized_source,
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
		var mission_transfer_source: String = String(mission_transfer_entry.get("payload_source", "")).strip_edges().to_lower()
		var is_homebase_direct_mission_transfer: bool = mission_transfer_source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT
		var craft_location: String = String(_aircraft_location_by_craft.get(craft_id, "homebase")).strip_edges().to_lower()
		var is_in_transit: bool = not pilot_transfer_entry.is_empty() or craft_location == "transit"
		var mission_phase: String = ""
		if is_in_transit:
			craft_location = "transit"
		if not mission_transfer_entry.is_empty():
			mission_phase = String(mission_transfer_entry.get("phase", "")).strip_edges().to_lower()
			is_in_transit = true
			if mission_phase == "to_mission":
				craft_location = "mission"
			elif mission_phase == "to_fob":
				craft_location = "fob"
			elif mission_phase == "to_homebase":
				craft_location = "mission"
		elif craft_location == "mission":
			mission_phase = "waiting"
		elif craft_location not in ["fob", "transit", "starmap"]:
			craft_location = "homebase"
		var recovery_state: Dictionary = Dictionary(_air_asset_recovery_by_craft.get(craft_id, {})).duplicate(true)
		var recovery_patch: Dictionary = {}
		var recovery_active: bool = false
		if not recovery_state.is_empty():
			recovery_patch = Dictionary(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("build_transport_patch", recovery_state)).duplicate(true)
			recovery_active = bool(recovery_patch.get("air_asset_unavailable", false))

		var planning_card: Dictionary = _find_mission_drop_card_in_planning_state(craft_id)
		var passenger_count: int = 0
		if mission_phase == "to_mission" or mission_phase == "waiting":
			if not planning_card.is_empty() and planning_card.has("passenger_count"):
				passenger_count = int(planning_card.get("passenger_count", 0))
			elif not planning_card.is_empty() and planning_card.has("embarked_unit_ids"):
				passenger_count = Array(planning_card.get("embarked_unit_ids", [])).size()
			else:
				passenger_count = Array(_mission_planning_state.get("embarked_unit_ids", [])).size()
		elif mission_phase == "to_fob" or mission_phase == "to_homebase":
			if not planning_card.is_empty() and planning_card.has("passenger_count"):
				passenger_count = int(planning_card.get("passenger_count", 0))
			elif craft_id == String(_mission_planning_state.get("mission_drop_craft_id", "")):
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

		var craft_state: Dictionary = {
			"craft_id": craft_id,
			"craft_type": String(craft_def.get("craft_type", "dropship")).strip_edges(),
			"display_name": String(craft_def.get("display_name", craft_id)).strip_edges(),
			"summary": String(craft_def.get("summary", "")).strip_edges(),
			"texture_path": String(craft_def.get("texture_path", "")).strip_edges(),
			"location": craft_location,
			"visible_in_homebase": craft_location in ["homebase", "starmap"] or recovery_active or (mission_phase == "to_mission" and is_homebase_direct_mission_transfer),
			"visible_in_fob": craft_location == "fob" or recovery_active or (mission_phase == "to_mission" and not is_homebase_direct_mission_transfer) or (craft_location == "transit" and not pilot_transfer_entry.is_empty()),
			"is_in_transit": is_in_transit,
			"pilot_unit_id": pilot_unit_id,
			"pilot_display_name": _resolve_unit_display_name(pilot_unit_id),
			"pilot_portrait_path": _resolve_unit_portrait_path(pilot_unit_id),
			"cargo_id": cargo_id,
			"cargo_display_name": _build_homebase_cargo_display_name(craft_def, cargo_id),
			"passenger_count": passenger_count,
			"transfer_progress": progress_value,
			"transfer_eta_seconds": eta_seconds,
			"is_boardable": (not recovery_active) and String(craft_def.get("craft_type", "dropship")).strip_edges() == "dropship" and craft_location == "fob" and mission_phase.is_empty(),
			"mission_phase": mission_phase,
			"mission_waiting": mission_phase == "waiting",
			"mission_transit_to_map": mission_phase == "to_mission",
			"mission_transit_to_fob": mission_phase == "to_fob",
			"mission_transit_to_homebase": mission_phase == "to_homebase",
		}
		if not recovery_patch.is_empty():
			craft_state.merge(recovery_patch, true)
		craft_states.append(craft_state)
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
		var portrait_id := String(unit_data.get("portrait_id", "")).strip_edges()
		var portrait_path := String(unit_data.get("portrait_path", "")).strip_edges()
		if portrait_id.is_empty() and portrait_path.is_empty():
			return ""
		return PORTRAIT_IDENTITY_CATALOG_SCRIPT.resolve_path(portrait_id, portrait_path)
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
		if _is_unit_assigned_to_aircraft(unit_id) and _singleplayer_runtime == null:
			continue
		filtered_unit_ids.append(unit_id)
	return filtered_unit_ids


func _sanitize_homebase_selection(unit_ids: PackedStringArray) -> PackedStringArray:
	return _filter_available_homebase_unit_ids(unit_ids)


func _normalize_homebase_fireteam_selection(unit_ids: PackedStringArray, fireteam_ids: PackedStringArray) -> PackedStringArray:
	var normalized_fireteam_ids: PackedStringArray = []
	for unit_index in range(unit_ids.size()):
		var fireteam_id := ""
		if unit_index < fireteam_ids.size():
			fireteam_id = String(fireteam_ids[unit_index]).strip_edges().to_lower()
		normalized_fireteam_ids.append(fireteam_id)
	return normalized_fireteam_ids


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


func _is_known_roster_unit(unit_id: String) -> bool:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return false
	for unit_variant in _all_team_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		if String(Dictionary(unit_variant).get("unit_id", "")).strip_edges() == normalized_unit_id:
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


func _show_homebase(allow_remote_operations: bool = false) -> void:
	if _has_space_route_in_progress() and not allow_remote_operations:
		_show_star_map()
		return
	if _star_map_screen != null:
		_star_map_screen.hide()
	_current_meta_view = "homebase"
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	var debrief_screen = _get_debrief_screen()
	if not _is_homebase_direct_mission_drop_source():
		_sync_fob_transfer_selection_from_screen()
	if homebase_screen != null:
		homebase_screen.visible = true
		_refresh_homebase_screen()
		_ensure_singleplayer_visible_homebase_actionability()
		_refresh_homebase_screen()
		_schedule_singleplayer_visible_homebase_actionability_guard()
	if fob_screen != null:
		fob_screen.visible = false
	if debrief_screen != null:
		debrief_screen.visible = false
	_refresh_preview_mission_lifecycle()
	_sync_mission_host_visibility()
	_set_navigation_visible(true)
	_refresh_navigation_state()


func get_release_singleplayer_normal_click_homebase_guard_snapshot() -> Dictionary:
	var homebase_screen = _get_homebase_screen()
	var bootstrap: Dictionary = get_singleplayer_start_bootstrap_snapshot()
	var staging: Dictionary = {}
	var readiness: Dictionary = {}
	var startflow: Dictionary = {}
	var aircraft: Dictionary = {}
	if homebase_screen != null:
		if homebase_screen.has_method("get_homebase_direct_staging_snapshot"):
			staging = Dictionary(homebase_screen.call("get_homebase_direct_staging_snapshot"))
		if homebase_screen.has_method("get_pre_mission_readiness_snapshot"):
			readiness = Dictionary(homebase_screen.call("get_pre_mission_readiness_snapshot"))
		if homebase_screen.has_method("get_pre_mission_startflow_visual_snapshot"):
			startflow = Dictionary(homebase_screen.call("get_pre_mission_startflow_visual_snapshot"))
		if homebase_screen.has_method("get_aircraft_panel_snapshot"):
			aircraft = Dictionary(homebase_screen.call("get_aircraft_panel_snapshot"))

	var readiness_text: String = String(readiness.get("rendered_item_text", ""))
	var mission_team_limit_text: String = String(startflow.get("mission_team_limit_text", "")).strip_edges()
	var mission_transfer_text: String = String(startflow.get("mission_transfer_text", "")).strip_edges()
	var mission_summary_text: String = String(startflow.get("mission_summary_text", "")).strip_edges()
	var combined_mission_copy: String = "%s\n%s\n%s" % [mission_team_limit_text, mission_transfer_text, mission_summary_text]
	var visible_aircraft_count: int = Array(aircraft.get("visible_aircraft_definitions", [])).size()
	if visible_aircraft_count <= 0:
		visible_aircraft_count = Array(staging.get("visible_aircraft_definitions", [])).size()
	var checks: Array = [
		_build_release_normal_click_guard_check(
			"homebase_visible",
			homebase_screen != null and bool(homebase_screen.visible) and _current_meta_view == "homebase",
			"The normal Singleplayer click should land on the visible Homebase screen."
		),
		_build_release_normal_click_guard_check(
			"mission_is_grid_sweep",
			String(bootstrap.get("selected_mission_id", "")) == SINGLEPLAYER_RELEASE_DEFAULT_MISSION_ID,
			"The normal Singleplayer click must not remain on the stale FOB Transfer setup."
		),
		_build_release_normal_click_guard_check(
			"drop_source_homebase_direct",
			String(bootstrap.get("mission_drop_source", "")) == MISSION_DROP_SOURCE_HOMEBASE_DIRECT,
			"The release start should use the Homebase Direct dropship path."
		),
		_build_release_normal_click_guard_check(
			"flightdeck_has_ship",
			visible_aircraft_count >= 1,
			"The visible Flightdeck should show at least one shipcard."
		),
		_build_release_normal_click_guard_check(
			"payload_has_operators",
			int(staging.get("payload_operator_count", 0)) >= mini(SINGLEPLAYER_BOOTSTRAP_FIRETEAM_SIZE, 2),
			"The bootstrap payload should contain a playable Fireteam."
		),
		_build_release_normal_click_guard_check(
			"payload_boarded",
			int(staging.get("boarded_operator_count", 0)) >= int(staging.get("payload_operator_count", 0)) and int(staging.get("payload_operator_count", 0)) > 0,
			"The visible payload should start boarded for the first release sortie."
		),
		_build_release_normal_click_guard_check(
			"readiness_ready",
			String(readiness.get("overall_state", "")) == "ready",
			"The Pre-Mission readiness should be ready after the normal click."
		),
		_build_release_normal_click_guard_check(
			"start_mission_enabled",
			String(startflow.get("start_button_text", "")) == "Einsatz starten" and not bool(startflow.get("start_button_disabled", true)),
			"The visible Start Mission button should be enabled."
		),
		_build_release_normal_click_guard_check(
			"no_stop_blockers",
			readiness_text.find("STOP Team") < 0 and readiness_text.find("STOP Dropship") < 0 and readiness_text.find("STOP Pilot") < 0 and readiness_text.find("STOP Boarding") < 0,
			"The normal click must not show the old STOP Team/Dropship/Pilot/Boarding blockers."
		),
		_build_release_normal_click_guard_check(
			"homebase_direct_copy_clear",
			mission_team_limit_text.begins_with("Einsatz:") and mission_transfer_text.find("Direct sortie") >= 0 and mission_summary_text.find("Start Mission") >= 0 and combined_mission_copy.find("send the team to FOB") < 0 and combined_mission_copy.find("FOB Transfer") < 0,
			"The visible Homebase Direct copy should not look like the stale FOB transfer workflow."
		),
	]
	var failed_checks: Array = []
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_checks.append(check)
	return {
		"schema": "sternenbuergerchen.release_singleplayer_normal_click_homebase_guard.v1",
		"task_id": "BUGFIX_release_singleplayer_normal_click_homebase_guard",
		"status": "pass" if failed_checks.is_empty() else "fail",
		"failed_count": failed_checks.size(),
		"checks": checks,
		"failed_checks": failed_checks,
		"current_meta_view": _current_meta_view,
		"selected_mission_id": String(bootstrap.get("selected_mission_id", "")),
		"mission_drop_source": String(bootstrap.get("mission_drop_source", "")),
		"visible_aircraft_count": visible_aircraft_count,
		"payload_operator_count": int(staging.get("payload_operator_count", 0)),
		"boarded_operator_count": int(staging.get("boarded_operator_count", 0)),
		"readiness_overall_state": String(readiness.get("overall_state", "")),
		"rendered_readiness_item_text": readiness_text,
		"mission_team_limit_text": mission_team_limit_text,
		"mission_transfer_text": mission_transfer_text,
		"mission_summary_text": mission_summary_text,
		"start_button_text": String(startflow.get("start_button_text", "")),
		"start_button_disabled": bool(startflow.get("start_button_disabled", true)),
		"bootstrap": bootstrap,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _build_release_normal_click_guard_check(check_id: String, passed: bool, message: String) -> Dictionary:
	return {
		"id": check_id,
		"passed": passed,
		"message": message,
	}


func _show_fob() -> void:
	# FOB remains an internal transport compatibility surface. Regular
	# singleplayer navigation always returns to the Operations homebase.
	_show_homebase()
	return


func _show_fob_internal() -> void:
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
	if not _can_open_mission_from_navigation():
		return
	_current_meta_view = "map"
	if not _is_homebase_direct_mission_drop_source():
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
	if _star_map_screen != null:
		_star_map_screen.hide()
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
	if _has_space_route_in_progress() or (_singleplayer_runtime != null and bool(_singleplayer_runtime.call("is_campaign_mission")) and _active_mission == null):
		_show_star_map()
		return
	if not _is_homebase_direct_mission_drop_source():
		_sync_fob_dropship_state_into_mission_planning(false, MISSION_DROP_SOURCE_FOB)
	if _active_mission == null:
		if _active_mission_started_at_msec <= 0:
			_begin_active_mission_timer()
		_start_mission()
		return
	_apply_planning_state_to_mission(_active_mission)
	_show_mission()


func _can_open_mission_from_navigation() -> bool:
	# After Debrief, the next live mission needs a new launch from Homebase or FOB.
	return MISSION_PREVIEW_ENABLED or _active_mission != null or _last_mission_result.is_empty()


func _show_debrief() -> void:
	if _star_map_screen != null:
		_star_map_screen.hide()
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
		button.disabled = view_name == "fob" or _current_meta_view == view_name or (view_name == "map" and not _can_open_mission_from_navigation())
		if view_name == "fob":
			button.text = "F̶O̶B̶ — gesperrt"
			button.tooltip_text = "FOB ist im Einzelspieler vorerst gesperrt"
		if button.disabled:
			META_UI_SKIN_SCRIPT.style_primary_button(button)
		else:
			META_UI_SKIN_SCRIPT.style_secondary_button(button)


func _refresh_map_screen() -> void:
	if not MISSION_PREVIEW_ENABLED:
		_release_preview_mission()
		if _active_mission != null:
			_apply_planning_state_to_mission(_active_mission)
		return
	if _active_mission == null:
		_sync_fob_dropship_state_into_mission_planning(false, MISSION_DROP_SOURCE_FOB)
	_refresh_preview_mission_lifecycle()


func _build_fob_member_loadouts() -> Dictionary:
	var fob_screen = _get_fob_screen()
	if fob_screen == null:
		return {}
	return _build_member_loadouts_from_fireteam_definitions(fob_screen.get_fireteam_definitions())


func _build_member_loadouts_from_fireteam_definitions(definitions: Array) -> Dictionary:
	var result: Dictionary = {}
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


func _get_homebase_direct_drop_state(craft_id: String = "") -> Dictionary:
	var drop_state: Dictionary = _peek_homebase_direct_drop_state(craft_id)
	if not bool(drop_state.get("drop_ship_staged", false)):
		return {}
	var mission_unit_ids := PackedStringArray(Array(drop_state.get("selected_unit_ids", [])))
	var mission_fireteam_ids := PackedStringArray(Array(drop_state.get("selected_fireteam_ids", [])))
	var mission_setup_unit_ids := PackedStringArray(Array(drop_state.get("mission_setup_unit_ids", mission_unit_ids)))
	var mission_setup_fireteam_ids := PackedStringArray(Array(drop_state.get("mission_setup_fireteam_ids", mission_fireteam_ids)))
	var homebase_unit_ids := PackedStringArray(Array(drop_state.get("homebase_team_unit_ids", mission_unit_ids)))
	var homebase_fireteam_ids := PackedStringArray(Array(drop_state.get("homebase_team_fireteam_ids", mission_fireteam_ids)))
	_homebase_staged_unit_ids = _sanitize_homebase_selection(homebase_unit_ids)
	_homebase_staged_fireteam_ids = _normalize_homebase_fireteam_selection(_homebase_staged_unit_ids, homebase_fireteam_ids)
	if not mission_setup_unit_ids.is_empty():
		_selected_unit_ids = mission_setup_unit_ids.duplicate()
		_selected_fireteam_ids = _normalize_homebase_fireteam_selection(_selected_unit_ids, mission_setup_fireteam_ids)
	elif not mission_unit_ids.is_empty():
		_selected_unit_ids = mission_unit_ids.duplicate()
		_selected_fireteam_ids = _normalize_homebase_fireteam_selection(_selected_unit_ids, mission_fireteam_ids)
	return drop_state


func _peek_homebase_direct_drop_state(craft_id: String = "") -> Dictionary:
	var homebase_screen = _get_homebase_screen()
	if homebase_screen == null or not homebase_screen.has_method("build_homebase_direct_drop_state"):
		return {}
	var normalized_craft_id: String = craft_id.strip_edges()
	if not normalized_craft_id.is_empty() and homebase_screen.has_method("build_homebase_direct_drop_state_for_craft"):
		return Dictionary(homebase_screen.call("build_homebase_direct_drop_state_for_craft", normalized_craft_id)).duplicate(true)
	return Dictionary(homebase_screen.call("build_homebase_direct_drop_state")).duplicate(true)


func _consume_homebase_direct_mission_craft_id() -> String:
	var homebase_screen = _get_homebase_screen()
	if homebase_screen == null or not homebase_screen.has_method("consume_homebase_direct_mission_craft_id"):
		return ""
	return String(homebase_screen.call("consume_homebase_direct_mission_craft_id")).strip_edges()


func _has_homebase_direct_payload_from_screen(craft_id: String = "") -> bool:
	var drop_state: Dictionary = _peek_homebase_direct_drop_state(craft_id)
	if drop_state.is_empty():
		return false
	if int(drop_state.get("homebase_direct_payload_operator_count", 0)) > 0:
		return true
	if not Array(drop_state.get("queued_unit_ids", [])).is_empty():
		return true
	return not Array(drop_state.get("queued_fireteam_ids", [])).is_empty()


func _get_fob_mission_drop_state(fob_screen) -> Dictionary:
	if fob_screen == null or not fob_screen.has_method("build_mission_drop_state"):
		return {}
	return Dictionary(fob_screen.call("build_mission_drop_state")).duplicate(true)


func _sync_fob_dropship_state_into_mission_planning(clear_deployed_unit_ids: bool = false, payload_source: String = MISSION_DROP_SOURCE_FOB, direct_craft_id: String = "") -> void:
	var normalized_source: String = payload_source.strip_edges().to_lower()
	if normalized_source.is_empty():
		normalized_source = MISSION_DROP_SOURCE_FOB

	var drop_state: Dictionary = {}
	var applied_source: String = ""
	var fob_screen = _get_fob_screen()
	if normalized_source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT or normalized_source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT_THEN_FOB:
		drop_state = _get_homebase_direct_drop_state(direct_craft_id)
		if not drop_state.is_empty():
			applied_source = MISSION_DROP_SOURCE_HOMEBASE_DIRECT
	if drop_state.is_empty() and (normalized_source == MISSION_DROP_SOURCE_FOB or normalized_source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT_THEN_FOB):
		drop_state = _get_fob_mission_drop_state(fob_screen)
		if not drop_state.is_empty():
			applied_source = MISSION_DROP_SOURCE_FOB
	if drop_state.is_empty():
		_mission_planning_state["embarked_unit_ids"] = []
		_mission_planning_state["meta_transfer_routes"] = _build_homebase_transfer_route_entries()
		_mission_planning_state["mission_drop_cards"] = []
		_mission_planning_state["mission_drop_source"] = ""
		_mission_planning_state["selected_fireteam_definitions"] = []
		_mission_planning_state["selected_team_unit_configs"] = []
		_mission_planning_state["member_loadouts"] = {}
		if clear_deployed_unit_ids:
			_mission_planning_state["deployed_unit_ids"] = []
			_mission_planning_state["deployed_unit_positions"] = {}
		return

	if applied_source == MISSION_DROP_SOURCE_FOB:
		_sync_fob_payload_selection_from_screen(fob_screen, drop_state)
	drop_state = _merge_existing_mission_drop_card_planning_fields(drop_state)
	if applied_source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT:
		drop_state = _apply_homebase_direct_setup_selection_from_drop_cards(drop_state)
		var direct_unit_ids := PackedStringArray(Array(drop_state.get("selected_unit_ids", [])))
		var direct_fireteam_ids := PackedStringArray(Array(drop_state.get("selected_fireteam_ids", [])))
		if not direct_unit_ids.is_empty():
			_selected_unit_ids = direct_unit_ids.duplicate()
			_selected_fireteam_ids = _normalize_homebase_fireteam_selection(_selected_unit_ids, direct_fireteam_ids)
			_homebase_staged_unit_ids = _selected_unit_ids.duplicate()
			_homebase_staged_fireteam_ids = _selected_fireteam_ids.duplicate()
	if applied_source != MISSION_DROP_SOURCE_HOMEBASE_DIRECT:
		drop_state = _apply_selected_mission_drop_card_override(drop_state)
	drop_state = _include_campaign_pilot_in_departing_payload(drop_state)
	_mission_planning_state["embarked_unit_ids"] = Array(PackedStringArray(Array(drop_state.get("embarked_unit_ids", []))))
	_mission_planning_state["drop_queued_fireteam_ids"] = Array(PackedStringArray(Array(drop_state.get("queued_fireteam_ids", []))))
	_mission_planning_state["drop_ship_staged"] = bool(drop_state.get("drop_ship_staged", false))
	_mission_planning_state["mission_drop_source"] = applied_source
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
	_mission_planning_state["mission_drop_cards"] = Array(drop_state.get("mission_drop_cards", [])).duplicate(true)
	_mission_planning_state["meta_transfer_routes"] = _build_homebase_transfer_route_entries()
	_sync_mission_setup_contract_fields(drop_state, applied_source, fob_screen)
	if clear_deployed_unit_ids or not _mission_planning_state.has("deployed_unit_ids"):
		_mission_planning_state["deployed_unit_ids"] = []
	if clear_deployed_unit_ids:
		_mission_planning_state["deployed_unit_positions"] = {}
	if not _mission_planning_state.has("mission_drop_return_requested"):
		_mission_planning_state["mission_drop_return_requested"] = false


func _include_campaign_pilot_in_departing_payload(state: Dictionary) -> Dictionary:
	if not is_campaign_start(): return state
	var result: Dictionary = state.duplicate(true)
	for card: Dictionary in Array(result.get("mission_drop_cards", [])):
		var pilot_id: String = String(card.get("pilot_unit_id", ""))
		if pilot_id.is_empty() or not String(card.get("state", "")) in ["to_mission", "waiting"]: continue
		if Array(_mission_planning_state.get("deployed_unit_ids", [])).has(pilot_id): continue
		var payload: Array = Array(card.get("embarked_unit_ids", [])).duplicate()
		if not payload.has(pilot_id): payload.append(pilot_id)
		if _singleplayer_runtime != null:
			var personnel: Node = _singleplayer_runtime.call("get_base_personnel_runtime")
			if personnel != null:
				for person: Dictionary in Array(personnel.call("get_snapshot").get("units", [])):
					var id: String = String(person.get("unit_id", ""))
					if String(person.get("status", "")) == "aboard" and String(person.get("craft_id", "")) == String(card.get("craft_id", "")) and not payload.has(id):
						payload.append(id)
		card["embarked_unit_ids"] = payload
		card["passenger_count"] = payload.size()
		if String(card.get("craft_id", "")) == String(result.get("mission_drop_craft_id", "")):
			result["embarked_unit_ids"] = payload.duplicate()
			result["mission_drop_passenger_count"] = payload.size()
	return result


func _sync_mission_setup_contract_fields(drop_state: Dictionary, applied_source: String, fob_screen) -> void:
	if applied_source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT:
		var setup_unit_ids := PackedStringArray(Array(drop_state.get("mission_setup_unit_ids", drop_state.get("selected_unit_ids", []))))
		var setup_fireteam_ids := PackedStringArray(Array(drop_state.get("mission_setup_fireteam_ids", drop_state.get("selected_fireteam_ids", []))))
		var setup_definitions: Array = Array(drop_state.get("mission_setup_fireteam_definitions", drop_state.get("selected_fireteam_definitions", drop_state.get("fireteam_definitions", [])))).duplicate(true)
		if setup_unit_ids.size() > Array(drop_state.get("selected_unit_ids", [])).size():
			var full_homebase_definitions: Array = Array(drop_state.get("homebase_fireteam_definitions", drop_state.get("fireteam_definitions", []))).duplicate(true)
			if not full_homebase_definitions.is_empty():
				setup_definitions = _filter_fireteam_definitions_by_ids(full_homebase_definitions, setup_fireteam_ids)
		var setup_configs: Array = Array(drop_state.get("mission_setup_team_unit_configs", drop_state.get("selected_team_unit_configs", []))).duplicate(true)
		if _count_matching_unit_configs(setup_configs, setup_unit_ids) < setup_unit_ids.size():
			var full_homebase_configs: Array = Array(drop_state.get("homebase_team_unit_configs", [])).duplicate(true)
			if not full_homebase_configs.is_empty():
				setup_configs = _filter_unit_configs_by_ids(full_homebase_configs, setup_unit_ids)
		var setup_member_loadouts: Dictionary = Dictionary(_mission_planning_state.get("member_loadouts", {})).duplicate(true)
		for loadout_key in Dictionary(drop_state.get("member_loadouts", {})).keys():
			setup_member_loadouts[loadout_key] = Dictionary(drop_state.get("member_loadouts", {})).get(loadout_key)
		for loadout_key in Dictionary(drop_state.get("mission_setup_member_loadouts", {})).keys():
			setup_member_loadouts[loadout_key] = Dictionary(drop_state.get("mission_setup_member_loadouts", {})).get(loadout_key)
		_mission_planning_state["selected_fireteam_definitions"] = setup_definitions
		_mission_planning_state["selected_team_unit_configs"] = setup_configs
		_mission_planning_state["member_loadouts"] = setup_member_loadouts
		return

	if applied_source == MISSION_DROP_SOURCE_FOB:
		var fireteam_definitions: Array = []
		if fob_screen != null and fob_screen.has_method("get_fireteam_definitions"):
			fireteam_definitions = Array(fob_screen.call("get_fireteam_definitions")).duplicate(true)
		_mission_planning_state["selected_fireteam_definitions"] = fireteam_definitions
		if fob_screen != null and fob_screen.has_method("get_selected_unit_configs"):
			_mission_planning_state["selected_team_unit_configs"] = Array(fob_screen.call("get_selected_unit_configs")).duplicate(true)
		else:
			_mission_planning_state["selected_team_unit_configs"] = []
		_mission_planning_state["member_loadouts"] = _build_member_loadouts_from_fireteam_definitions(fireteam_definitions)
		return

	_mission_planning_state["selected_fireteam_definitions"] = []
	_mission_planning_state["selected_team_unit_configs"] = []
	_mission_planning_state["member_loadouts"] = {}


func _apply_homebase_direct_setup_selection_from_drop_cards(drop_state: Dictionary) -> Dictionary:
	var result: Dictionary = drop_state.duplicate(true)
	var setup_unit_ids: PackedStringArray = []
	var setup_fireteam_ids: PackedStringArray = []
	var seen_unit_ids: Dictionary = {}
	var launched_craft_id: String = String(result.get("mission_drop_craft_id", "")).strip_edges()
	for card_variant in Array(result.get("mission_drop_cards", [])):
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		var card_craft_id: String = String(card.get("craft_id", "")).strip_edges()
		if not launched_craft_id.is_empty() and card_craft_id != launched_craft_id:
			continue
		var state: String = String(card.get("state", "")).strip_edges().to_lower()
		if state == "to_fob" or state == "to_homebase":
			continue
		var card_unit_ids: Array = Array(card.get("embarked_unit_ids", []))
		if card_unit_ids.is_empty():
			continue
		var card_fireteam_ids: Array = _build_homebase_direct_card_fireteam_selection(card, card_unit_ids)
		_append_homebase_direct_setup_selection(setup_unit_ids, setup_fireteam_ids, seen_unit_ids, card_unit_ids, card_fireteam_ids)
	if setup_unit_ids.is_empty():
		_append_homebase_direct_setup_selection(
			setup_unit_ids,
			setup_fireteam_ids,
			seen_unit_ids,
			Array(result.get("mission_setup_unit_ids", result.get("selected_unit_ids", []))),
			Array(result.get("mission_setup_fireteam_ids", result.get("selected_fireteam_ids", [])))
		)
	if setup_unit_ids.is_empty():
		return result
	result["mission_setup_unit_ids"] = Array(setup_unit_ids)
	result["mission_setup_fireteam_ids"] = Array(setup_fireteam_ids)
	result["selected_unit_ids"] = Array(setup_unit_ids)
	result["selected_fireteam_ids"] = Array(setup_fireteam_ids)
	_selected_unit_ids = setup_unit_ids.duplicate()
	_selected_fireteam_ids = _normalize_homebase_fireteam_selection(_selected_unit_ids, setup_fireteam_ids)
	return result


func _append_homebase_direct_setup_selection(target_unit_ids: PackedStringArray, target_fireteam_ids: PackedStringArray, seen_unit_ids: Dictionary, unit_ids: Array, fireteam_ids: Array) -> void:
	for unit_index in range(unit_ids.size()):
		var unit_id: String = String(unit_ids[unit_index]).strip_edges()
		if unit_id.is_empty() or seen_unit_ids.has(unit_id):
			continue
		var fireteam_id: String = ""
		if unit_index < fireteam_ids.size():
			fireteam_id = String(fireteam_ids[unit_index]).strip_edges().to_lower()
		seen_unit_ids[unit_id] = true
		target_unit_ids.append(unit_id)
		target_fireteam_ids.append(fireteam_id)


func _build_homebase_direct_card_fireteam_selection(card: Dictionary, unit_ids: Array) -> Array:
	var card_fireteam_ids: Array = Array(card.get("boarded_fireteam_ids", card.get("queued_fireteam_ids", [])))
	if card_fireteam_ids.size() == 1:
		var repeated: Array = []
		for _unit_id in unit_ids:
			repeated.append(String(card_fireteam_ids[0]).strip_edges().to_lower())
		return repeated
	if card_fireteam_ids.size() >= unit_ids.size():
		var paired: Array = []
		for unit_index in range(unit_ids.size()):
			paired.append(String(card_fireteam_ids[unit_index]).strip_edges().to_lower())
		return paired
	var fallback := _build_unassigned_fireteam_selection(PackedStringArray(unit_ids))
	return Array(fallback)


func _filter_fireteam_definitions_by_ids(definitions: Array, fireteam_ids: PackedStringArray) -> Array:
	var lookup: Dictionary = {}
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			lookup[fireteam_id] = true
	if lookup.is_empty():
		return []
	var result: Array = []
	for definition_variant in definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant).duplicate(true)
		var fireteam_id: String = String(definition.get("id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty() or not lookup.has(fireteam_id):
			continue
		result.append(definition)
	return result


func _filter_unit_configs_by_ids(configs: Array, unit_ids: PackedStringArray) -> Array:
	var lookup: Dictionary = {}
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if not unit_id.is_empty():
			lookup[unit_id] = true
	var result: Array = []
	for config_variant in configs:
		if typeof(config_variant) != TYPE_DICTIONARY:
			continue
		var config: Dictionary = Dictionary(config_variant).duplicate(true)
		var unit_id: String = String(config.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or not lookup.has(unit_id):
			continue
		result.append(config)
	return result


func _count_matching_unit_configs(configs: Array, unit_ids: PackedStringArray) -> int:
	var lookup: Dictionary = {}
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if not unit_id.is_empty():
			lookup[unit_id] = true
	var count: int = 0
	for config_variant in configs:
		if typeof(config_variant) != TYPE_DICTIONARY:
			continue
		var unit_id: String = String(Dictionary(config_variant).get("unit_id", "")).strip_edges()
		if lookup.has(unit_id):
			count += 1
	return count


func _sync_fob_payload_selection_from_screen(fob_screen, drop_state: Dictionary) -> void:
	var screen_unit_ids: PackedStringArray = []
	var screen_fireteam_ids: PackedStringArray = []
	if fob_screen != null and fob_screen.has_method("get_team"):
		screen_unit_ids = PackedStringArray(fob_screen.call("get_team"))
	if fob_screen != null and fob_screen.has_method("get_selected_fireteam_ids"):
		screen_fireteam_ids = PackedStringArray(fob_screen.call("get_selected_fireteam_ids"))
	if screen_unit_ids.is_empty():
		screen_unit_ids = PackedStringArray(Array(drop_state.get("embarked_unit_ids", [])))
	if screen_unit_ids.is_empty():
		return

	var next_fireteam_ids: PackedStringArray = _build_unassigned_fireteam_selection(screen_unit_ids)
	for unit_index in range(screen_unit_ids.size()):
		if unit_index < screen_fireteam_ids.size():
			next_fireteam_ids[unit_index] = String(screen_fireteam_ids[unit_index]).strip_edges()
	_selected_unit_ids = screen_unit_ids.duplicate()
	_selected_fireteam_ids = next_fireteam_ids


func _begin_homebase_direct_mission_transfer_from_planning() -> void:
	if not _is_homebase_direct_mission_drop_source():
		return
	var craft_id: String = String(_mission_planning_state.get("mission_drop_craft_id", "")).strip_edges()
	if craft_id.is_empty():
		return
	var existing_transfer: Dictionary = _find_pending_mission_craft_transfer(craft_id)
	if not existing_transfer.is_empty():
		var existing_phase: String = String(existing_transfer.get("phase", "")).strip_edges().to_lower()
		var existing_source: String = String(existing_transfer.get("payload_source", "")).strip_edges().to_lower()
		if existing_phase == "to_mission" and existing_source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT:
			return
	_begin_mission_craft_transfer(craft_id, "to_mission", MISSION_DROPSHIP_TO_MAP_SECONDS, MISSION_DROP_SOURCE_HOMEBASE_DIRECT)


func _sync_mission_drop_transport_fields_from_fob() -> void:
	if _is_homebase_direct_mission_drop_source():
		return
	var fob_screen = _get_fob_screen()
	if fob_screen == null or not fob_screen.has_method("build_mission_drop_state"):
		return

	var drop_state: Dictionary = _apply_selected_mission_drop_card_override(_merge_existing_mission_drop_card_planning_fields(Dictionary(fob_screen.call("build_mission_drop_state")).duplicate(true)))
	_mission_planning_state["drop_ship_staged"] = bool(drop_state.get("drop_ship_staged", false))
	_mission_planning_state["mission_drop_source"] = MISSION_DROP_SOURCE_FOB
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
	_mission_planning_state["mission_drop_cards"] = Array(drop_state.get("mission_drop_cards", [])).duplicate(true)
	_mission_planning_state["meta_transfer_routes"] = _build_homebase_transfer_route_entries()


func _sync_homebase_direct_mission_drop_transport_fields() -> void:
	if not _is_homebase_direct_mission_drop_source():
		return
	var cards: Array = Array(_mission_planning_state.get("mission_drop_cards", [])).duplicate(true)
	var craft_ids: PackedStringArray = _build_homebase_direct_mission_sync_craft_ids(cards)
	if craft_ids.is_empty():
		return

	for craft_id in craft_ids:
		var card: Dictionary = _find_mission_drop_card_in_state({"mission_drop_cards": cards}, String(craft_id))
		var transport_state: Dictionary = _build_homebase_direct_card_transport_state(String(craft_id), card)
		if transport_state.is_empty():
			continue
		cards = _sync_homebase_direct_mission_drop_card_fields(
			cards,
			String(craft_id),
			String(transport_state.get("state", "")).strip_edges().to_lower(),
			float(transport_state.get("progress", 0.0)),
			int(transport_state.get("eta_seconds", 0)),
			int(transport_state.get("passenger_count", 0)),
			Array(transport_state.get("embarked_unit_ids", []))
		)

	_mission_planning_state["drop_ship_staged"] = true
	_mission_planning_state["mission_drop_cards"] = cards
	var selected_craft_id: String = String(_mission_planning_state.get("mission_drop_craft_id", "")).strip_edges()
	if selected_craft_id.is_empty() and not craft_ids.is_empty():
		selected_craft_id = String(craft_ids[0])
		_mission_planning_state["mission_drop_craft_id"] = selected_craft_id
	var selected_card: Dictionary = _find_mission_drop_card_in_state({"mission_drop_cards": cards}, selected_craft_id)
	if not selected_card.is_empty():
		_sync_mission_drop_scalar_fields_from_card(selected_card)
	_mission_planning_state["meta_transfer_routes"] = _build_homebase_transfer_route_entries()


func _build_homebase_direct_mission_sync_craft_ids(cards: Array) -> PackedStringArray:
	var result: PackedStringArray = []
	var selected_craft_id: String = String(_mission_planning_state.get("mission_drop_craft_id", "")).strip_edges()
	if not selected_craft_id.is_empty():
		result.append(selected_craft_id)
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		var craft_id: String = String(card.get("craft_id", "")).strip_edges()
		if craft_id.is_empty() or result.has(craft_id):
			continue
		var source: String = String(card.get("payload_source", _mission_planning_state.get("mission_drop_source", ""))).strip_edges().to_lower()
		if source == MISSION_DROP_SOURCE_HOMEBASE_DIRECT or _should_preserve_existing_mission_drop_card(card):
			result.append(craft_id)
	for transfer_variant in _pending_mission_craft_transfers:
		if typeof(transfer_variant) != TYPE_DICTIONARY:
			continue
		var transfer: Dictionary = Dictionary(transfer_variant)
		if String(transfer.get("payload_source", "")).strip_edges().to_lower() != MISSION_DROP_SOURCE_HOMEBASE_DIRECT:
			continue
		if String(transfer.get("phase", "")) != "to_mission":
			continue
		var transfer_craft_id: String = String(transfer.get("craft_id", "")).strip_edges()
		if not transfer_craft_id.is_empty() and not result.has(transfer_craft_id):
			result.append(transfer_craft_id)
	return result


func _build_homebase_direct_card_transport_state(craft_id: String, card: Dictionary) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return {}
	var transfer_entry: Dictionary = _find_pending_mission_craft_transfer(normalized_craft_id)
	var next_state: String = String(card.get("state", _mission_planning_state.get("mission_drop_state", ""))).strip_edges().to_lower()
	var next_progress: float = clampf(float(card.get("progress", _mission_planning_state.get("mission_drop_progress", 0.0))), 0.0, 100.0)
	var next_eta_seconds: int = maxi(int(card.get("eta_seconds", _mission_planning_state.get("mission_drop_eta_seconds", 0))), 0)
	if not transfer_entry.is_empty():
		next_state = String(transfer_entry.get("phase", next_state)).strip_edges().to_lower()
		var default_duration: float = _get_mission_craft_transfer_default_duration(next_state)
		var duration_seconds: float = maxf(float(transfer_entry.get("duration_seconds", default_duration)), 1.0)
		var elapsed_seconds: float = clampf(float(transfer_entry.get("elapsed_seconds", 0.0)), 0.0, duration_seconds)
		next_progress = clampf((elapsed_seconds / duration_seconds) * 100.0, 0.0, 100.0)
		next_eta_seconds = maxi(int(ceil(duration_seconds - elapsed_seconds)), 0)
	elif next_state == "to_mission" and String(_aircraft_location_by_craft.get(normalized_craft_id, "")).strip_edges().to_lower() == "mission":
		next_state = "waiting"
		next_progress = 100.0
		next_eta_seconds = 0

	var embarked_unit_ids: Array = Array(PackedStringArray(Array(card.get("embarked_unit_ids", []))))
	if embarked_unit_ids.is_empty() and normalized_craft_id == String(_mission_planning_state.get("mission_drop_craft_id", "")).strip_edges():
		embarked_unit_ids = Array(PackedStringArray(Array(_mission_planning_state.get("embarked_unit_ids", []))))
	var passenger_count: int = int(card.get("passenger_count", 0))
	if passenger_count <= 0 and not embarked_unit_ids.is_empty():
		passenger_count = embarked_unit_ids.size()
	return {
		"state": next_state,
		"progress": next_progress,
		"eta_seconds": next_eta_seconds,
		"passenger_count": passenger_count,
		"embarked_unit_ids": embarked_unit_ids,
	}


func _sync_mission_drop_scalar_fields_from_card(card: Dictionary) -> void:
	if card.is_empty():
		return
	_mission_planning_state["mission_drop_craft_id"] = String(card.get("craft_id", _mission_planning_state.get("mission_drop_craft_id", ""))).strip_edges()
	_mission_planning_state["mission_drop_display_name"] = String(card.get("display_name", _mission_planning_state.get("mission_drop_display_name", ""))).strip_edges()
	_mission_planning_state["mission_drop_title_text"] = String(card.get("title_text", _mission_planning_state.get("mission_drop_title_text", ""))).strip_edges()
	_mission_planning_state["mission_drop_texture_path"] = String(card.get("texture_path", _mission_planning_state.get("mission_drop_texture_path", ""))).strip_edges()
	_mission_planning_state["mission_drop_state"] = String(card.get("state", _mission_planning_state.get("mission_drop_state", ""))).strip_edges().to_lower()
	_mission_planning_state["mission_drop_pilot_text"] = String(card.get("pilot_text", _mission_planning_state.get("mission_drop_pilot_text", ""))).strip_edges()
	_mission_planning_state["mission_drop_status_line"] = String(card.get("status_line", _mission_planning_state.get("mission_drop_status_line", ""))).strip_edges()
	_mission_planning_state["mission_drop_progress"] = clampf(float(card.get("progress", _mission_planning_state.get("mission_drop_progress", 0.0))), 0.0, 100.0)
	_mission_planning_state["mission_drop_eta_seconds"] = maxi(int(card.get("eta_seconds", _mission_planning_state.get("mission_drop_eta_seconds", 0))), 0)
	_mission_planning_state["mission_drop_pilot_unit_id"] = String(card.get("pilot_unit_id", _mission_planning_state.get("mission_drop_pilot_unit_id", ""))).strip_edges()
	_mission_planning_state["mission_drop_pilot_display_name"] = String(card.get("pilot_display_name", _mission_planning_state.get("mission_drop_pilot_display_name", ""))).strip_edges()
	_mission_planning_state["mission_drop_pilot_portrait_path"] = String(card.get("pilot_portrait_path", _mission_planning_state.get("mission_drop_pilot_portrait_path", ""))).strip_edges()
	_mission_planning_state["mission_drop_passenger_count"] = int(card.get("passenger_count", _mission_planning_state.get("mission_drop_passenger_count", 0)))
	if card.has("embarked_unit_ids"):
		_mission_planning_state["embarked_unit_ids"] = Array(PackedStringArray(Array(card.get("embarked_unit_ids", []))))
	if card.has("queued_fireteam_ids"):
		_mission_planning_state["drop_queued_fireteam_ids"] = Array(PackedStringArray(Array(card.get("queued_fireteam_ids", []))))
	if card.has("has_lz_position"):
		_mission_planning_state["has_lz_position"] = bool(card.get("has_lz_position", false))
	if card.has("lz_position"):
		_mission_planning_state["lz_position"] = card["lz_position"]
	if card.has("approach_angle"):
		_mission_planning_state["approach_angle"] = String(card.get("approach_angle", _mission_planning_state.get("approach_angle", "NW"))).strip_edges().to_upper()


func _sync_homebase_direct_mission_drop_card_fields(cards: Array, craft_id: String, next_state: String, progress_value: float, eta_seconds: int, passenger_count: int, embarked_unit_ids: Array) -> Array:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return cards
	var updated_cards: Array = []
	var did_update: bool = false
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant).duplicate(true)
		if String(card.get("craft_id", "")).strip_edges() == normalized_craft_id:
			card["payload_source"] = MISSION_DROP_SOURCE_HOMEBASE_DIRECT
			card["state"] = next_state
			card["progress"] = progress_value
			card["eta_seconds"] = eta_seconds
			card["passenger_count"] = passenger_count
			if not embarked_unit_ids.is_empty():
				card["embarked_unit_ids"] = embarked_unit_ids.duplicate()
				if Array(card.get("boarded_fireteam_ids", [])).is_empty():
					card["boarded_fireteam_ids"] = Array(_mission_planning_state.get("drop_queued_fireteam_ids", [])).duplicate()
				if Array(card.get("queued_fireteam_ids", [])).is_empty():
					card["queued_fireteam_ids"] = Array(_mission_planning_state.get("drop_queued_fireteam_ids", [])).duplicate()
			elif passenger_count <= 0:
				card["embarked_unit_ids"] = []
			did_update = true
		updated_cards.append(card)
	if not did_update:
		updated_cards.append(_build_homebase_direct_mission_drop_card_snapshot(normalized_craft_id, next_state, progress_value, eta_seconds, passenger_count, embarked_unit_ids))
	return updated_cards


func _build_homebase_direct_mission_drop_card_snapshot(craft_id: String, next_state: String, progress_value: float, eta_seconds: int, passenger_count: int, embarked_unit_ids: Array) -> Dictionary:
	var display_name: String = String(_mission_planning_state.get("mission_drop_display_name", "Dropship")).strip_edges()
	if display_name.is_empty():
		display_name = "Dropship"
	var queued_fireteam_ids: Array = Array(_mission_planning_state.get("drop_queued_fireteam_ids", [])).duplicate()
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"title_text": String(_mission_planning_state.get("mission_drop_title_text", display_name)).strip_edges(),
		"texture_path": String(_mission_planning_state.get("mission_drop_texture_path", "")).strip_edges(),
		"payload_source": MISSION_DROP_SOURCE_HOMEBASE_DIRECT,
		"state": next_state,
		"pilot_text": String(_mission_planning_state.get("mission_drop_pilot_text", "")).strip_edges(),
		"status_line": String(_mission_planning_state.get("mission_drop_status_line", "")).strip_edges(),
		"progress": progress_value,
		"eta_seconds": eta_seconds,
		"pilot_unit_id": String(_mission_planning_state.get("mission_drop_pilot_unit_id", "")).strip_edges(),
		"pilot_display_name": String(_mission_planning_state.get("mission_drop_pilot_display_name", "")).strip_edges(),
		"pilot_portrait_path": String(_mission_planning_state.get("mission_drop_pilot_portrait_path", "")).strip_edges(),
		"passenger_count": passenger_count,
		"embarked_unit_ids": embarked_unit_ids.duplicate(),
		"boarded_fireteam_ids": queued_fireteam_ids.duplicate(),
		"queued_fireteam_ids": queued_fireteam_ids.duplicate(),
	}


func _apply_selected_mission_drop_card_override(drop_state: Dictionary) -> Dictionary:
	var selected_craft_id: String = String(_mission_planning_state.get("mission_drop_craft_id", "")).strip_edges()
	if selected_craft_id.is_empty():
		return drop_state
	var selected_card: Dictionary = _find_mission_drop_card_in_state(drop_state, selected_craft_id)
	if selected_card.is_empty():
		return drop_state
	var result: Dictionary = drop_state.duplicate(true)
	result["mission_drop_craft_id"] = selected_craft_id
	result["mission_drop_display_name"] = String(selected_card.get("display_name", result.get("mission_drop_display_name", ""))).strip_edges()
	result["mission_drop_title_text"] = String(selected_card.get("title_text", result.get("mission_drop_title_text", ""))).strip_edges()
	result["mission_drop_texture_path"] = String(selected_card.get("texture_path", result.get("mission_drop_texture_path", ""))).strip_edges()
	result["mission_drop_state"] = String(selected_card.get("state", result.get("mission_drop_state", ""))).strip_edges()
	result["mission_drop_pilot_text"] = String(selected_card.get("pilot_text", result.get("mission_drop_pilot_text", ""))).strip_edges()
	result["mission_drop_status_line"] = String(selected_card.get("status_line", result.get("mission_drop_status_line", ""))).strip_edges()
	result["mission_drop_progress"] = float(selected_card.get("progress", result.get("mission_drop_progress", 0.0)))
	result["mission_drop_eta_seconds"] = int(selected_card.get("eta_seconds", result.get("mission_drop_eta_seconds", 0)))
	result["mission_drop_pilot_unit_id"] = String(selected_card.get("pilot_unit_id", result.get("mission_drop_pilot_unit_id", ""))).strip_edges()
	result["mission_drop_pilot_display_name"] = String(selected_card.get("pilot_display_name", result.get("mission_drop_pilot_display_name", ""))).strip_edges()
	result["mission_drop_pilot_portrait_path"] = String(selected_card.get("pilot_portrait_path", result.get("mission_drop_pilot_portrait_path", ""))).strip_edges()
	result["mission_drop_passenger_count"] = int(selected_card.get("passenger_count", result.get("mission_drop_passenger_count", 0)))
	if selected_card.has("embarked_unit_ids"):
		result["embarked_unit_ids"] = Array(PackedStringArray(Array(selected_card.get("embarked_unit_ids", []))))
	if selected_card.has("queued_fireteam_ids"):
		result["queued_fireteam_ids"] = Array(PackedStringArray(Array(selected_card.get("queued_fireteam_ids", []))))
	if selected_card.has("boarded_fireteam_ids"):
		result["boarded_fireteam_ids"] = Array(PackedStringArray(Array(selected_card.get("boarded_fireteam_ids", []))))
	for planning_key in ["has_lz_position", "lz_position", "approach_angle"]:
		if selected_card.has(planning_key):
			result[planning_key] = selected_card[planning_key]
	if selected_card.has("drop_ship_requested"):
		result["drop_ship_requested"] = bool(selected_card.get("drop_ship_requested", false))
	if selected_card.has("drop_ship_staged"):
		result["drop_ship_staged"] = bool(selected_card.get("drop_ship_staged", false))
	return result


func _merge_existing_mission_drop_card_planning_fields(drop_state: Dictionary) -> Dictionary:
	var result: Dictionary = drop_state.duplicate(true)
	var selected_craft_id: String = String(_mission_planning_state.get("mission_drop_craft_id", "")).strip_edges()
	var existing_cards_by_craft: Dictionary = {}
	for existing_variant in Array(_mission_planning_state.get("mission_drop_cards", [])):
		if typeof(existing_variant) != TYPE_DICTIONARY:
			continue
		var existing_card: Dictionary = Dictionary(existing_variant)
		var existing_craft_id: String = String(existing_card.get("craft_id", "")).strip_edges()
		if existing_craft_id.is_empty():
			continue
		existing_cards_by_craft[existing_craft_id] = existing_card
	var merged_cards: Array = []
	var merged_craft_ids: Dictionary = {}
	for card_variant in Array(result.get("mission_drop_cards", [])):
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant).duplicate(true)
		var craft_id: String = String(card.get("craft_id", "")).strip_edges()
		var existing_card: Dictionary = Dictionary(existing_cards_by_craft.get(craft_id, {}))
		var card_state: String = String(card.get("state", "")).strip_edges().to_lower()
		var card_has_empty_return_payload: bool = (card_state == "to_fob" or card_state == "to_homebase") and int(card.get("passenger_count", 0)) <= 0 and Array(card.get("embarked_unit_ids", [])).is_empty()
		for planning_key in ["has_lz_position", "lz_position", "approach_angle", "drop_ship_requested", "drop_ship_staged"]:
			if existing_card.has(planning_key):
				card[planning_key] = existing_card[planning_key]
			elif craft_id == selected_craft_id and _mission_planning_state.has(planning_key):
				card[planning_key] = _mission_planning_state[planning_key]
		if not card_has_empty_return_payload:
			for payload_key in ["embarked_unit_ids", "boarded_fireteam_ids", "queued_fireteam_ids"]:
				if Array(card.get(payload_key, [])).is_empty() and existing_card.has(payload_key) and not Array(existing_card.get(payload_key, [])).is_empty():
					card[payload_key] = Array(existing_card.get(payload_key, [])).duplicate()
		if not card_has_empty_return_payload and int(card.get("passenger_count", 0)) <= 0 and int(existing_card.get("passenger_count", 0)) > 0:
			card["passenger_count"] = int(existing_card.get("passenger_count", 0))
		if not existing_card.is_empty() and card_state.is_empty() and _should_preserve_existing_mission_drop_card(existing_card):
			for transport_key in [
				"payload_source",
				"state",
				"progress",
				"eta_seconds",
				"pilot_text",
				"status_line",
				"pilot_unit_id",
				"pilot_display_name",
				"pilot_portrait_path",
				"passenger_count",
				"drop_ship_requested",
				"drop_ship_staged",
				"has_lz_position",
				"lz_position",
				"approach_angle",
				"drop_sequence_position",
			]:
				if existing_card.has(transport_key):
					card[transport_key] = existing_card[transport_key]
		merged_cards.append(card)
		if not craft_id.is_empty():
			merged_craft_ids[craft_id] = true
	for existing_variant in Array(_mission_planning_state.get("mission_drop_cards", [])):
		if typeof(existing_variant) != TYPE_DICTIONARY:
			continue
		var existing_card: Dictionary = Dictionary(existing_variant).duplicate(true)
		var existing_craft_id: String = String(existing_card.get("craft_id", "")).strip_edges()
		if existing_craft_id.is_empty() or merged_craft_ids.has(existing_craft_id):
			continue
		if _should_preserve_existing_mission_drop_card(existing_card):
			merged_cards.append(existing_card)
	result["mission_drop_cards"] = merged_cards
	return result


func _should_preserve_existing_mission_drop_card(card: Dictionary) -> bool:
	if card.is_empty():
		return false
	var state: String = String(card.get("state", "")).strip_edges().to_lower()
	if [
		"to_mission",
		"waiting",
		"inbound",
		"landed",
		"unloading",
		"complete",
		"outbound",
		"to_fob",
		"to_homebase",
	].has(state):
		return true
	if int(card.get("passenger_count", 0)) > 0:
		return true
	if not Array(card.get("embarked_unit_ids", [])).is_empty():
		return true
	if not Array(card.get("queued_fireteam_ids", [])).is_empty() or not Array(card.get("boarded_fireteam_ids", [])).is_empty():
		return true
	return bool(card.get("drop_ship_requested", false)) or bool(card.get("has_lz_position", false))


func _find_mission_drop_card_in_planning_state(craft_id: String) -> Dictionary:
	if String(_aircraft_location_by_craft.get(craft_id,""))=="mission":
		var instance: Node=get_mission_for_craft(craft_id)
		if instance!=null:
			var card: Dictionary=instance.get_node("TacticalController").call("_find_mission_dropship_card_entry",craft_id)
			if not card.is_empty(): return card.duplicate(true)
	return _find_mission_drop_card_in_state({"mission_drop_cards": Array(_mission_planning_state.get("mission_drop_cards", []))}, craft_id)


func _find_mission_drop_card_in_state(drop_state: Dictionary, craft_id: String) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return {}
	for card_variant in Array(drop_state.get("mission_drop_cards", [])):
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == normalized_craft_id:
			return card
	return {}


func _has_preview_deployed_mission_payload() -> bool:
	return not Array(_mission_planning_state.get("deployed_unit_ids", [])).is_empty()


func _has_mission_start_payload() -> bool:
	var has_waiting_mission_payload: bool = _has_waiting_mission_drop_payload()
	if not bool(_mission_planning_state.get("drop_ship_staged", false)) and not _has_preview_deployed_mission_payload() and not has_waiting_mission_payload:
		return false
	if not Array(_mission_planning_state.get("embarked_unit_ids", [])).is_empty():
		return true
	if has_waiting_mission_payload:
		return true
	return _has_preview_deployed_mission_payload()


func _has_waiting_mission_drop_payload() -> bool:
	if String(_mission_planning_state.get("mission_drop_state", "")).strip_edges().to_lower() == "waiting" and not Array(_mission_planning_state.get("embarked_unit_ids", [])).is_empty():
		return true
	for card_variant in Array(_mission_planning_state.get("mission_drop_cards", [])):
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("state", "")).strip_edges().to_lower() != "waiting":
			continue
		if not Array(card.get("embarked_unit_ids", [])).is_empty():
			return true
	return false


func _should_defer_friendly_runtime_activation() -> bool:
	return not Array(_mission_planning_state.get("embarked_unit_ids", [])).is_empty() or _has_waiting_mission_drop_payload()


func _get_mission_drop_source() -> String:
	return String(_mission_planning_state.get("mission_drop_source", "")).strip_edges().to_lower()


func _is_homebase_direct_mission_drop_source() -> bool:
	return _get_mission_drop_source() == MISSION_DROP_SOURCE_HOMEBASE_DIRECT


func _sync_fob_transfer_selection_from_screen() -> void:
	if _is_homebase_direct_mission_drop_source():
		return
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


func _sync_homebase_direct_staging_from_screen() -> void:
	var homebase_screen = _get_homebase_screen()
	if homebase_screen == null or not homebase_screen.has_method("get_selected_unit_ids") or not homebase_screen.has_method("get_selected_fireteam_ids"):
		return
	var screen_unit_ids := PackedStringArray(homebase_screen.call("get_selected_unit_ids"))
	var screen_fireteam_ids := PackedStringArray(homebase_screen.call("get_selected_fireteam_ids"))
	_homebase_staged_unit_ids = _sanitize_homebase_selection(screen_unit_ids)
	_homebase_staged_fireteam_ids = _normalize_homebase_fireteam_selection(_homebase_staged_unit_ids, screen_fireteam_ids)
	if _homebase_staged_unit_ids.is_empty():
		return
	_selected_unit_ids = _homebase_staged_unit_ids.duplicate()
	_selected_fireteam_ids = _homebase_staged_fireteam_ids.duplicate()


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
	var minutes: int = floori(float(clamped_total_seconds) / 60.0)
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
	var callback: Callable=_on_location_planning_state_changed.bind(mission_instance) if not String(mission_instance.get_meta("location_id","")).is_empty() else _on_mission_planning_state_changed
	if not tactical_controller.planning_state_changed.is_connected(callback):
		tactical_controller.planning_state_changed.connect(callback)


func _apply_planning_state_to_mission(mission_instance: Node) -> void:
	if mission_instance == null:
		return
	var tactical_controller = mission_instance.get_node_or_null("TacticalController")
	if tactical_controller != null and tactical_controller.has_method("set_planning_state"):
		if tactical_controller.has_method("get_planning_state"):
			var current_planning: Dictionary = Dictionary(tactical_controller.call("get_planning_state"))
			var delta: Dictionary = _build_planning_delta(current_planning, _mission_planning_state)
			if _try_apply_mission_transport_delta(mission_instance, delta):
				return
		_full_plan_apply_count += 1
		tactical_controller.call("set_planning_state", _mission_planning_state)


func _build_planning_delta(previous: Dictionary, incoming: Dictionary) -> Dictionary:
	# This is an immediate comparison of existing owners, not retained mission
	# state. Missing keys keep set_planning_state's existing partial-input meaning.
	var delta: Dictionary = {}
	for key in incoming:
		if not previous.has(key) or previous[key] != incoming[key]:
			delta[key] = incoming[key]
	return delta


func _try_apply_mission_transport_delta(mission_instance: Node, delta: Dictionary) -> bool:
	if delta.is_empty():
		_unchanged_plan_skip_count += 1
		return true
	if mission_instance == null:
		return false
	var controller = mission_instance.get_node_or_null("TacticalController")
	if controller == null or not controller.has_method("apply_meta_transport_planning_delta"):
		return false
	if not bool(controller.call("apply_meta_transport_planning_delta", delta)):
		return false
	_transport_delta_apply_count += 1
	return true


func _on_mission_planning_state_changed(planning_state: Dictionary) -> void:
	if planning_state.is_empty():
		return
	_mission_planning_state = DEFAULT_MISSION_PLANNING_STATE.duplicate(true)
	for key_variant in planning_state.keys():
		var key: String = String(key_variant)
		_mission_planning_state[key] = planning_state[key_variant]
	if is_campaign_start() and _active_mission != null:
		var setup: Node = _active_mission.get_node_or_null("MissionSetup")
		var actual_ids: PackedStringArray = PackedStringArray(setup.get("selected_team_unit_ids")) if setup != null else PackedStringArray()
		var location_id := String(_active_mission.get_meta("location_id", ""))
		for card: Dictionary in Array(_mission_planning_state.get("mission_drop_cards", [])):
			var craft_id := String(card.get("craft_id", ""))
			if not location_id.is_empty() and (String(_craft_location_runtime.get(craft_id, "")) != location_id or String(_aircraft_location_by_craft.get(craft_id, "")) != "mission"):
				continue # Historical ready cards are not current pilot ownership.
			var pilot_id: String = String(card.get("pilot_unit_id", ""))
			if actual_ids.has(pilot_id):
				_assigned_aircraft_pilot_by_craft[craft_id] = pilot_id
	var fob_screen = _get_fob_screen()
	var handled_mission_return: bool = _apply_mission_drop_card_return_requests(_mission_planning_state, fob_screen)
	if bool(_mission_planning_state.get("mission_drop_return_requested", false)):
		var mission_craft_id: String = String(_mission_planning_state.get("mission_drop_craft_id", "")).strip_edges()
		var returning_payload_unit_ids: Array = Array(_mission_planning_state.get("embarked_unit_ids", []))
		var returning_passenger_count: int = int(_mission_planning_state.get("mission_drop_passenger_count", returning_payload_unit_ids.size()))
		handled_mission_return = _apply_mission_drop_return_for_craft(mission_craft_id, returning_payload_unit_ids, returning_passenger_count, fob_screen, _get_mission_drop_source()) or handled_mission_return
		_mission_planning_state["mission_drop_return_requested"] = false
	if handled_mission_return:
		if _is_homebase_direct_mission_drop_source():
			_sync_homebase_direct_mission_drop_transport_fields()
		else:
			_sync_fob_dropship_state_into_mission_planning(false, MISSION_DROP_SOURCE_FOB)
	if _preview_mission != null:
		_apply_planning_state_to_mission(_preview_mission)
	if _active_mission != null:
		_apply_planning_state_to_mission(_active_mission)
	# Hidden meta screens rebuild large planning surfaces; the active mission already received the same state above.
	if _active_mission == null:
		_refresh_homebase_screen()
		_refresh_fob_screen()
		_refresh_map_screen()
	_ensure_transport_timer_state()


func _apply_mission_drop_card_return_requests(planning_state: Dictionary, fob_screen) -> bool:
	var handled: bool = false
	var handled_craft_ids: Dictionary = {}
	var payload_source: String = String(planning_state.get("mission_drop_source", "")).strip_edges().to_lower()
	for card_variant in Array(planning_state.get("mission_drop_cards", [])):
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		var card_state: String = String(card.get("state", "")).strip_edges().to_lower()
		if card_state != "to_fob" and card_state != "to_homebase":
			continue
		var craft_id: String = String(card.get("craft_id", "")).strip_edges()
		if craft_id.is_empty() or handled_craft_ids.has(craft_id):
			continue
		handled_craft_ids[craft_id] = true
		var payload_ids: Array = Array(card.get("embarked_unit_ids", []))
		var passenger_count: int = int(card.get("passenger_count", payload_ids.size()))
		handled = _apply_mission_drop_return_for_craft(craft_id, payload_ids, passenger_count, fob_screen, payload_source) or handled
	return handled


func _apply_mission_drop_return_for_craft(craft_id: String, returning_payload_unit_ids: Array, returning_passenger_count: int, fob_screen, payload_source: String = MISSION_DROP_SOURCE_FOB) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return false
	var changed: bool = false
	var returns_to_homebase: bool = payload_source.strip_edges().to_lower() == MISSION_DROP_SOURCE_HOMEBASE_DIRECT
	var clear_return_payload: bool = returning_payload_unit_ids.is_empty() and returning_passenger_count <= 0
	if clear_return_payload and not returns_to_homebase and fob_screen != null and fob_screen.has_method("clear_mission_boarded_payload"):
		fob_screen.call("clear_mission_boarded_payload", normalized_craft_id)
		changed = true
	var destination := "homebase" if returns_to_homebase else "fob"
	if _find_pending_mission_craft_transfer(normalized_craft_id).is_empty() \
			and String(_aircraft_location_by_craft.get(normalized_craft_id, "")) != destination:
		var return_phase: String = "to_homebase" if returns_to_homebase else "to_fob"
		var return_duration: float = MISSION_DROPSHIP_TO_HOMEBASE_SECONDS if returns_to_homebase else MISSION_DROPSHIP_TO_FOB_SECONDS
		_begin_mission_craft_transfer(normalized_craft_id, return_phase, return_duration, payload_source)
		changed = true
	return changed


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
		var focused: bool=is_visible and child==_active_mission
		if child is CanvasItem:
			(child as CanvasItem).visible = focused
		_set_mission_instance_ui_visibility(child, focused)
		_set_mission_overlay_visibility(child, focused)
		var tactical_controller := child.get_node_or_null("TacticalController")
		if tactical_controller != null and tactical_controller.has_method("set_tactical_ui_visible"):
			tactical_controller.call("set_tactical_ui_visible", focused)
			# This controller also advances dropships and tactical execution.
			# Hide only its input; the live mission must continue out of view.
			tactical_controller.set_process_unhandled_input(focused)
		var camera := child.get_node_or_null("MissionCamera")
		if camera != null:
			camera.process_mode = Node.PROCESS_MODE_INHERIT if focused else Node.PROCESS_MODE_DISABLED
		var primary_view := child.get_node_or_null("Primary3DView")
		if primary_view != null:
			primary_view.process_mode = Node.PROCESS_MODE_INHERIT if focused else Node.PROCESS_MODE_DISABLED
			var viewport: SubViewport=primary_view.get_node_or_null("ViewportContainer/SubViewport")
			if viewport!=null: viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS if focused else SubViewport.UPDATE_DISABLED
		child.process_mode = Node.PROCESS_MODE_INHERIT if focused or child == _active_mission or not String(child.get_meta("location_id","")).is_empty() else Node.PROCESS_MODE_DISABLED


func _set_mission_instance_ui_visibility(mission_instance: Node, is_visible: bool) -> void:
	if mission_instance == null:
		return
	# CanvasLayers do not inherit visibility from the mission's Node2D root.
	for layer_path in ["TacticalUI", "Primary3DView"]:
		var layer := mission_instance.get_node_or_null(layer_path) as CanvasLayer
		if layer != null:
			layer.visible = is_visible
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


func _get_mission_definition_by_id(mission_id: String) -> Dictionary:
	var normalized_mission_id: String = mission_id.strip_edges()
	if normalized_mission_id.is_empty():
		return {}
	for mission_variant in _mission_catalog:
		var mission_definition: Dictionary = Dictionary(mission_variant)
		if String(mission_definition.get("mission_id", "")).strip_edges() == normalized_mission_id:
			return _build_resolved_mission_definition(mission_definition)
	return {}


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


func get_singleplayer_snapshot() -> Dictionary:
	return _singleplayer_runtime.call("get_snapshot") if _singleplayer_runtime != null else {}


func _has_space_route_in_progress() -> bool:
	if _singleplayer_runtime == null:
		return false
	var travel: Dictionary = _singleplayer_runtime.call("get_space_travel_snapshot")
	return String(travel.get("phase", "grounded")) in ["orbit", "quantum", "stopped", "approach"]


func _is_space_craft_away(craft_id: String) -> bool:
	if _singleplayer_runtime == null:
		return false
	var travel: Dictionary = _singleplayer_runtime.call("get_space_travel_snapshot",craft_id)
	return String(travel.get("craft_id", "")) == craft_id and String(travel.get("phase", "grounded")) != "grounded"


func _show_star_map() -> void:
	_current_meta_view = "star_map"
	for screen in [_get_homebase_screen(), _get_fob_screen(), _get_debrief_screen()]:
		if screen != null:
			screen.hide()
	if _star_map_screen != null:
		_star_map_screen.show()
		_star_map_screen.call("refresh")
	_sync_mission_host_visibility()
	_set_navigation_visible(false)


func _begin_space_approach(craft_id: String, departure: Dictionary) -> void:
	if not get_surface_departure_retirement_guard(craft_id, String(departure.get("destination_location_id", ""))).ok:
		return
	var previous_location := String(_craft_location_runtime.get(craft_id, ""))
	if _space_approaches.has(craft_id):
		previous_location = String(_space_approaches[craft_id].get("previous_craft_location", previous_location))
		_retire_terrain_preparation(_space_approaches[craft_id])
		_space_approaches.erase(craft_id)
	_surface_preparation_results.erase(craft_id)
	# A new craft visit never inherits another ship's accepted LZ/drop trigger.
	_craft_location_runtime[craft_id]=String(departure.get("destination_location_id",""))
	var visit_planning:=_mission_planning_state.duplicate(true)
	visit_planning["drop_ship_requested"]=false
	visit_planning["has_lz_position"]=false
	visit_planning["mission_drop_craft_id"]=craft_id
	for card: Dictionary in Array(visit_planning.get("mission_drop_cards",[])):
		if String(card.get("craft_id",""))==craft_id:
			card["drop_ship_requested"]=false; card["has_lz_position"]=false
			card["lz_position"]=Vector2.ZERO; card["drop_sequence_position"]=Vector2.ZERO
			card["state"]="to_mission"; card["progress"]=0.0
	_space_approaches[craft_id]={"remaining":0.65,"planning":visit_planning,"mission":_get_selected_mission_definition().duplicate(true),"mission_id":_selected_mission_id,"units":_selected_unit_ids.duplicate(),"teams":_selected_fireteam_ids.duplicate(),"identity":{"craft_id":craft_id,"job_id":String(departure.get("job_id","")),"scenario_id":String(_get_selected_mission_definition().get("scenario_file_path","")).get_file().get_basename(),"location_id":String(departure.get("destination_location_id","")),"departure_token":String(Dictionary(_singleplayer_runtime.get("_departure_token_by_craft")).get(craft_id,"")),"unit_ids":Array(_selected_unit_ids),"fireteam_ids":Array(_selected_fireteam_ids)}}
	var approach: Dictionary = _space_approaches[craft_id]
	approach["started_msec"] = Time.get_ticks_msec()
	approach["previous_craft_location"] = previous_location
	var map_path := String(approach.mission.get("map_file_path", ""))
	var resident: Node = _location_registry.get_location(String(approach.identity.location_id))
	var resident_identity: Dictionary = resident.get_meta("singleplayer_mission_identity", {}) if is_instance_valid(resident) else {}
	var resident_driver: Node = resident.get_node_or_null("CombatLoopDriver") if is_instance_valid(resident) else null
	var reuses_resident := is_instance_valid(resident) and String(resident_identity.get("scenario_id", "")) == String(approach.identity.scenario_id) \
		and (resident_driver == null or not bool(resident_driver.get("_combat_finished")))
	approach["requires_resources"] = map_path in REGIONAL_CAMPAIGN_MAPS
	var resident_view: Node = resident.get_node_or_null("Primary3DView") if reuses_resident else null
	var resident_ready := resident_view != null and resident_view.has_method("get_prepared_terrain_resource_cache") and resident_view.call("get_prepared_terrain_resource_cache") != null
	approach["resident_ready"] = reuses_resident and (not bool(approach.requires_resources) or resident_ready)
	if map_path in REGIONAL_CAMPAIGN_MAPS and not bool(approach.resident_ready):
		var worker := Thread.new()
		var task := Callable(TERRAIN_MAP_DATA_SCRIPT, "load_from_file").bind(map_path)
		if worker.start(task) == OK:
			approach["map_worker"] = worker

	_show_star_map()

func _finish_space_approach(craft_id: String = "") -> void:
	if not _space_approaches.has(craft_id): return
	var entry: Dictionary = _space_approaches[craft_id]
	if not get_surface_departure_retirement_guard(craft_id, String(entry.identity.location_id)).ok:
		return
	var travel: Dictionary = _singleplayer_runtime.call("get_space_travel_snapshot", craft_id)
	if String(travel.get("phase", "")) != "approach" or String(travel.get("location_id", "")) != String(entry.identity.location_id):
		_retire_terrain_preparation(entry)
		_space_approaches.erase(craft_id)
		return
	if Time.get_ticks_msec() - int(entry.get("started_msec", Time.get_ticks_msec())) > TERRAIN_PREPARATION_TIMEOUT_MSEC:
		_cancel_space_approach(craft_id, "preparation_timeout")
		return
	var worker := entry.get("map_worker") as Thread
	if worker != null:
		if worker.is_alive(): return
		entry["prepared_map"] = worker.wait_to_finish()
		entry.erase("map_worker")
	var prepared_map = entry.get("prepared_map")
	var prepared_cache: RefCounted
	if bool(entry.get("requires_resources", false)) and not bool(entry.get("resident_ready", false)):
		if prepared_map == null:
			_cancel_space_approach(craft_id, "terrain_data_unavailable")
			return
		var preloader := entry.get("preloader") as Node
		if not is_instance_valid(preloader):
			# Only one resource builder is admitted; other craft keep real loading state.
			for other_id: String in _space_approaches:
				if other_id != craft_id and is_instance_valid(_space_approaches[other_id].get("preloader")): return
			preloader = load("res://scripts/terrain/terrain_map_3d_view.gd").new()
			preloader.name = "TerrainResourcePreparation_" + craft_id.validate_node_name()
			preloader.hide()
			add_child(preloader)
			entry["preloader"] = preloader
			preloader.call("set_authoring_markers_visible", false)
			preloader.call("configure_terrain_resource_prefill", prepared_map)
		var readiness: Dictionary = preloader.call("get_terrain_resource_preparation_snapshot")
		if String(readiness.status) == "failed":
			_cancel_space_approach(craft_id, String(readiness.reason))
			return
		if not bool(readiness.ready): return
		prepared_cache = preloader.call("get_prepared_terrain_resource_cache")
		if prepared_cache == null:
			_cancel_space_approach(craft_id, "terrain_cache_not_ready")
			return
	var completed := get_surface_preparation_snapshot(craft_id)
	completed["status"] = "ready"
	completed["ready"] = true
	completed["progress"] = 1.0
	completed["cancel_available"] = false
	_surface_preparation_results[craft_id] = completed
	_space_approaches.erase(craft_id)
	_retire_terrain_preparation(entry)
	var previous_view := _current_meta_view
	var previous_context := _capture_location_view_context()
	var previous_result := _last_mission_result.duplicate(true)
	var follow_arrival := previous_view == "star_map" and _get_view_travel_craft_id() == craft_id
	if _active_mission != null: _remember_location(_active_mission)
	_active_mission = null
	_active_singleplayer_identity = entry.identity.duplicate(true)
	_craft_location_runtime[craft_id] = String(entry.identity.location_id)
	_selected_mission_id = String(entry.mission_id)
	_selected_mission_map_path = String(entry.mission.get("map_file_path", DEFAULT_META_MAP_PATH))
	_selected_unit_ids = entry.units.duplicate()
	_selected_fireteam_ids = entry.teams.duplicate()
	_mission_planning_state = entry.planning.duplicate(true)
	_begin_mission_craft_transfer(craft_id, "to_mission", 1.0, MISSION_DROP_SOURCE_HOMEBASE_DIRECT)
	_aircraft_location_by_craft[craft_id] = "starmap"
	_sync_homebase_direct_mission_drop_transport_fields()
	_singleplayer_runtime.call("finish_space_approach", craft_id)
	_last_mission_result.clear()
	_begin_active_mission_timer()
	_start_or_update_active_mission(prepared_map, prepared_cache)
	_ensure_transport_timer_state()
	if not follow_arrival:
		if _active_mission != null: _remember_location(_active_mission)
		_last_mission_result = previous_result
		_restore_location_view_context(previous_context, previous_view, _active_mission)

func _get_star_map_area_projection(craft_id: String) -> Dictionary:
	# Narrow read seam. No Area/Flight lookup or authority is manufactured here.
	if craft_id.is_empty() or not is_instance_valid(_singleplayer_runtime) or not _singleplayer_runtime.has_method("get_space_area_projection"):
		return {"ok":false,"reason":"area_projection_unavailable"}
	var projection: Variant = _singleplayer_runtime.call("get_space_area_projection",craft_id)
	return projection if projection is Dictionary else {"ok":false,"reason":"invalid_area_projection"}

func _get_star_map_snapshot() -> Dictionary:
	var result: Dictionary = _singleplayer_runtime.call("get_snapshot") if _singleplayer_runtime != null else {}
	var craft_id := String(Dictionary(result.get("space_travel", {})).get("craft_id", ""))
	result["map_preparation"] = get_surface_preparation_snapshot(craft_id)
	return result

func _request_star_map_operation(operation: String, payload: Dictionary = {}) -> Dictionary:
	if operation == "open_location_view":
		return open_location_view(String(payload.get("location_id", "")), String(payload.get("craft_id", "")))
	if operation == "space_cancel_approach":
		return _cancel_space_approach(String(payload.get("craft_id", "")), "user_cancel")
	var result: Dictionary = _singleplayer_runtime.call("request_operation", operation, payload) if _singleplayer_runtime != null else {"ok": false, "reason": "runtime_unavailable"}
	if operation == "space_start_quantum" and result.get("ok", false):
		_surface_preparation_results.erase(String(payload.get("craft_id", "")))
	return result

func get_surface_preparation_snapshot(craft_id: String) -> Dictionary:
	if not _space_approaches.has(craft_id):
		return Dictionary(_surface_preparation_results.get(craft_id, {"status": "idle", "progress": 0.0, "ready": false, "cancel_available": false, "error": "", "reason": ""})).duplicate(true)
	var entry: Dictionary = _space_approaches[craft_id]
	var preloader := entry.get("preloader") as Node
	var data: Dictionary = preloader.call("get_terrain_resource_preparation_snapshot") if is_instance_valid(preloader) else {}
	return {"status": String(data.get("status", "loading_data")), "progress": float(data.get("progress", 0.0)),
		"ready": bool(data.get("ready", false)), "cancel_available": true, "error": "", "reason": String(data.get("reason", "")),
		"expected_chunks": int(data.get("expected_chunks", 0)), "prepared_chunks": int(data.get("prepared_chunks", 0)),
		"retained_payload_bytes": int(data.get("retained_payload_bytes", 0)), "max_payload_bytes": int(data.get("max_payload_bytes", 268435456)),
		"memory_static_baseline_bytes": int(data.get("memory_static_baseline_bytes", 0)), "memory_static_peak_bytes": int(data.get("memory_static_peak_bytes", 0)),
		"memory_static_delta_bytes": int(data.get("memory_static_delta_bytes", 0)), "geometry_build_count": int(data.get("geometry_build_count", 0))}

func _cancel_space_approach(craft_id: String, reason: String) -> Dictionary:
	if not _space_approaches.has(craft_id): return {"ok": false, "reason": "approach_not_active"}
	var entry: Dictionary = _space_approaches[craft_id]
	var travel: Dictionary = _singleplayer_runtime.call("get_space_travel_snapshot", craft_id)
	if String(travel.get("phase", "")) != "approach" or String(travel.get("location_id", "")) != String(entry.identity.location_id):
		return {"ok": false, "reason": "stale_approach"}
	var result: Dictionary = _singleplayer_runtime.call("enter_space_orbit", craft_id)
	if not result.get("ok", false): return result
	var snapshot := get_surface_preparation_snapshot(craft_id)
	snapshot["status"] = "cancelled" if reason == "user_cancel" else "failed"
	snapshot["ready"] = false
	snapshot["cancel_available"] = false
	snapshot["reason"] = reason
	snapshot["error"] = "Anflug abgebrochen. Das Schiff bleibt im Orbit." if reason == "user_cancel" else "Ortskarte konnte nicht vollständig vorbereitet werden. Das Schiff bleibt im Orbit."
	_surface_preparation_results[craft_id] = snapshot
	_space_approaches.erase(craft_id)
	var previous := String(entry.get("previous_craft_location", ""))
	if previous.is_empty(): _craft_location_runtime.erase(craft_id)
	else: _craft_location_runtime[craft_id] = previous
	_aircraft_location_by_craft[craft_id] = "starmap"
	_retire_terrain_preparation(entry)
	return {"ok": true, "reason": reason}

func _retire_terrain_preparation(entry: Dictionary) -> void:
	var preloader := entry.get("preloader") as Node
	if is_instance_valid(preloader):
		preloader.set_process(false)
		preloader.queue_free()
	var worker := entry.get("map_worker") as Thread
	if worker != null and worker.is_started():
		if worker.is_alive(): _retired_terrain_workers.append(worker)
		else: worker.wait_to_finish()

func _poll_retired_terrain_workers() -> void:
	for index in range(_retired_terrain_workers.size() - 1, -1, -1):
		var worker: Thread = _retired_terrain_workers[index]
		if not worker.is_alive():
			worker.wait_to_finish()
			_retired_terrain_workers.remove_at(index)


func _exit_tree() -> void:
	for worker: Thread in _retired_terrain_workers:
		if worker.is_started(): worker.wait_to_finish()
	_retired_terrain_workers.clear()
	for approach: Dictionary in _space_approaches.values():
		var worker := approach.get("map_worker") as Thread
		if worker != null and worker.is_started():
			worker.wait_to_finish()



func _prepare_space_surface_departure(craft_id: String) -> Dictionary:
	if _pending_surface_departures.has(craft_id) or String(_aircraft_location_by_craft.get(craft_id, "")) != "mission": return {}
	var instance: Node = get_mission_for_craft(craft_id)
	var owner: Node = instance.get_node_or_null("SimulationRoot") if instance != null else null
	var controller: Node = instance.get_node_or_null("TacticalController") if instance != null else null
	if instance != null and (controller == null or not controller.has_method("retire_location_craft_visit")): return {}
	var requires_receipt: bool = _surface_departure_requires_receipt(instance) if instance != null else false
	if requires_receipt and owner == null: return {}
	var visit: Dictionary = Dictionary(Dictionary(instance.get_meta("singleplayer_visit_identities", {})).get(craft_id, {})) if instance != null else {}
	return {"instance":weakref(instance) if instance != null else null, "root":weakref(owner) if owner != null else null,
		"controller":weakref(controller) if controller != null else null, "visit":visit.duplicate(true),
		"root_context":int(owner.call("get_hex_ground_context_revision")) if owner != null and owner.has_method("get_hex_ground_context_revision") else 0,
		"requires_receipt":requires_receipt, "location_id":String(instance.get_meta("location_id", "")) if instance != null else "",
		"unit_ids":PackedStringArray(visit.get("unit_ids", [])), "binding":{}, "retryable":false, "home_landing_requested":false}


func _register_space_surface_departure(craft_id: String, record: Dictionary) -> bool:
	# A reentrant Travel observer may already have installed a newer record.
	if _pending_surface_departures.has(craft_id): return false
	_surface_departure_serial += 1
	record.transfer_id = "surface_retirement:%d" % _surface_departure_serial
	_pending_surface_departures[craft_id] = record
	_pending_mission_craft_transfers.append({"craft_id":craft_id,"phase":"surface_retirement","transfer_id":record.transfer_id})
	_ensure_transport_timer_state()
	return true


func _finish_space_surface_departure(craft_id: String, retirement_record: Dictionary = {}) -> void:
	var record: Dictionary = retirement_record
	if record.is_empty():
		record = _prepare_space_surface_departure(craft_id)
		if record.is_empty() or not _register_space_surface_departure(craft_id, record): return
	elif _pending_surface_departures.get(craft_id) != record:
		return
	_attempt_space_surface_departure(craft_id, record, true)
	_ensure_transport_timer_state()


func get_surface_departure_retirement_guard(craft_id: String, _location_id: String = "") -> Dictionary:
	# Scope is per craft: independent visitors at the same place remain usable.
	return {"ok":not _pending_surface_departures.has(craft_id), "reason":"surface_retirement_pending" if _pending_surface_departures.has(craft_id) else ""}


func _surface_departure_record_current(craft_id: String, record: Dictionary) -> bool:
	if _pending_surface_departures.get(craft_id) != record: return false
	if record.instance == null: return get_mission_for_craft(craft_id) == null
	var instance: Node = record.instance.get_ref()
	if not is_instance_valid(instance) or get_mission_for_craft(craft_id) != instance: return false
	if String(instance.get_meta("location_id", "")) != record.location_id: return false
	if Dictionary(Dictionary(instance.get_meta("singleplayer_visit_identities", {})).get(craft_id, {})) != record.visit: return false
	var owner: Node = record.root.get_ref() if record.root != null else null
	if record.root != null and not is_instance_valid(owner): return false
	if instance.get_node_or_null("SimulationRoot") != owner: return false
	if owner != null and owner.has_method("get_hex_ground_context_revision") and int(owner.call("get_hex_ground_context_revision")) != record.root_context: return false
	var controller: Node = record.controller.get_ref() if record.controller != null else null
	if record.controller != null and not is_instance_valid(controller): return false
	return instance.get_node_or_null("TacticalController") == controller


func _surface_departure_requires_receipt(instance: Node) -> bool:
	var owner: Node = instance.get_node_or_null("SimulationRoot")
	if owner != null:
		for method: String in ["is_hex_ground_runtime_required", "is_hex_ground_runtime_active"]:
			if owner.has_method(method) and bool(owner.call(method)): return true
	var setup: Node = instance.get_node_or_null("MissionSetup")
	var map_data = setup.get("_loaded_terrain_map_data") if setup != null else null
	return map_data != null and map_data.has_method("get_tactical_grid_rules") and String(map_data.call("get_tactical_grid_rules")) == "hex_tactical_v1"


func _attempt_space_surface_departure(craft_id: String, record: Dictionary, initial: bool = false) -> void:
	if not _surface_departure_record_current(craft_id, record):
		_clear_space_surface_departure(craft_id, record)
		return
	var instance: Node = record.instance.get_ref() if record.instance != null else null
	if instance == null:
		_complete_space_surface_departure(craft_id, instance, record)
		return
	var controller: Node = record.controller.get_ref() if record.controller != null else null
	if controller == null or not controller.has_method("retire_location_craft_visit"): return
	var result: Variant
	if initial:
		result = controller.call("retire_location_craft_visit", craft_id, record.unit_ids)
	else:
		result = controller.call("retire_location_craft_visit", craft_id, record.unit_ids, record.binding)
	if not _surface_departure_record_current(craft_id, record):
		_clear_space_surface_departure(craft_id, record)
		return
	if typeof(result) != TYPE_DICTIONARY:
		if bool(record.requires_receipt): return
	elif String(result.get("status", "")) == "waiting":
		if initial and typeof(result.get("retirement_binding")) == TYPE_DICTIONARY and not Dictionary(result.retirement_binding).is_empty():
			record.binding = result.retirement_binding # Opaque owner ticket: never rewrite or serialize.
			record.retryable = true
		return
	elif String(result.get("status", "")) == "stale":
		_clear_space_surface_departure(craft_id, record)
		return
	elif String(result.get("status", "")) != "committed":
		return
	_complete_space_surface_departure(craft_id, instance, record)


func _clear_space_surface_departure(craft_id: String, record: Dictionary) -> void:
	if _pending_surface_departures.get(craft_id) != record: return
	_pending_surface_departures.erase(craft_id)
	_pending_mission_craft_transfers = _pending_mission_craft_transfers.filter(func(entry: Dictionary) -> bool:
		return not (String(entry.get("craft_id", "")) == craft_id and String(entry.get("phase", "")) == "surface_retirement" and String(entry.get("transfer_id", "")) == record.transfer_id))


func _retry_space_surface_departures() -> void:
	var ids: Array = _pending_surface_departures.keys()
	if ids.is_empty(): return
	var start: int = _surface_departure_retry_cursor % ids.size()
	_surface_departure_retry_cursor = (start + mini(16, ids.size())) % ids.size()
	for offset in range(mini(16, ids.size())):
		var craft_id: String = String(ids[(start + offset) % ids.size()])
		if not _pending_surface_departures.has(craft_id): continue
		var record: Dictionary = _pending_surface_departures[craft_id]
		if not _surface_departure_record_current(craft_id, record): _clear_space_surface_departure(craft_id, record)
		elif bool(record.retryable): _attempt_space_surface_departure(craft_id, record)


func _complete_space_surface_departure(craft_id: String, instance: Node, record: Dictionary) -> void:
	if not _surface_departure_record_current(craft_id, record):
		_clear_space_surface_departure(craft_id, record)
		return
	record.retryable = false
	var identity: Dictionary = {}
	if instance != null:
		identity = Dictionary(instance.get_meta("singleplayer_mission_identity", {})).duplicate(true)
		_remember_location(instance)
	_aircraft_location_by_craft[craft_id]="starmap"
	# A real departure retires its visit, not the player's independent place view.
	# Keep the old non-persistent scene behaviour for compatibility.
	if bool(record.home_landing_requested):
		_finish_space_home_landing(craft_id, record)
	var expected_location: String = "homebase" if bool(record.home_landing_requested) else "starmap"
	if not _surface_departure_record_current(craft_id, record) or String(_aircraft_location_by_craft.get(craft_id, "")) != expected_location:
		_clear_space_surface_departure(craft_id, record)
		return
	_clear_space_surface_departure(craft_id, record)
	if not bool(record.home_landing_requested) and instance==_active_mission and instance != null and String(instance.get_meta("location_id", "")).is_empty():
		_active_mission=null
		_reset_active_mission_timer()
		_show_star_map()
	# Publish the completed Flow projection before observers can admit a new visit.
	if String(identity.get("craft_id", "")) == craft_id and not String(identity.get("job_id", "")).is_empty():
		_singleplayer_runtime.call("record_mission_result", {"result":"aborted","reason":"craft_left_without_objective_completion"}, identity)


func _finish_space_home_landing(craft_id: String, retirement_record: Dictionary = {}) -> void:
	if _pending_surface_departures.has(craft_id):
		var pending: Dictionary = _pending_surface_departures[craft_id]
		if retirement_record != pending or not _surface_departure_record_current(craft_id, pending):
			if retirement_record.is_empty(): pending.home_landing_requested = true
			return
	var follow_arrival := _current_meta_view == "star_map" and _get_view_travel_craft_id() == craft_id
	var returning_mission := get_mission_for_craft(craft_id)
	var release_legacy: bool = _active_mission != null and _active_mission == returning_mission and String(_active_mission.get_meta("location_id", "")).is_empty()
	_restore_returning_visit_membership(craft_id)
	_aircraft_location_by_craft[craft_id] = "homebase"
	_remove_pending_mission_craft_transfer(craft_id)
	if release_legacy:
		_release_active_mission()
		_active_singleplayer_identity.clear()
		_mission_planning_state=DEFAULT_MISSION_PLANNING_STATE.duplicate(true)
		_reset_active_mission_timer()
	_refresh_homebase_screen()
	if follow_arrival or release_legacy: _show_homebase(true)
	_singleplayer_runtime.call("observe_campaign_progress")


func is_campaign_start() -> bool:
	return String(_game_start_request.get("mode", "skirmish")) == "campaign"


func _campaign_load_failed() -> void:
	push_warning("Kampagnenstand ungueltig; kein neuer Stand wird angelegt.")
	get_tree().root.set_meta("campaign_start_error", "Kampagnenstand konnte nicht geladen werden. Vorhandener Stand bleibt erhalten.")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _refresh_singleplayer_services() -> void:
	if _campaign_tutorial!=null: _campaign_tutorial.visible=not bool(get_node("HomebaseScreen").get("_character_sheet_open")) and String(get_node("HomebaseScreen").get("_operations_mode")) != "services"
	if _singleplayer_services == null or _singleplayer_runtime == null: return
	var snapshot: Dictionary = _singleplayer_runtime.call("get_snapshot")
	var at_polisa := _current_meta_view == "mission" and String(get_location_view_snapshot().get("location_id", "")) == "polisa"
	if at_polisa and _polisa_station_screen == null:
		_polisa_station_screen = load("res://scripts/ui/polisa_station_screen.gd").new()
		_singleplayer_services.get_parent().add_child(_polisa_station_screen)
		_polisa_station_screen.call("configure", _singleplayer_runtime)
	if _polisa_station_screen != null:
		_polisa_station_screen.visible = at_polisa
		if at_polisa: _polisa_station_screen.call("refresh", _singleplayer_runtime.call("get_polisa_snapshot", snapshot))
	var presenter: Node=get_node("HomebaseScreen").get("_operations_presenter")
	var base: Node=presenter.get("_base") if presenter!=null else null
	if base!=null and not base.is_connected("world_selection_changed",_on_base_world_selection_changed): base.connect("world_selection_changed",_on_base_world_selection_changed)
	var at_home := _current_meta_view == "homebase" and presenter!=null and String(presenter.get("_mode"))=="base"
	var remote := _current_meta_view == "mission" and not Dictionary(snapshot.get("service_contexts_by_craft_id",{})).is_empty()
	_singleplayer_services.visible = (at_home or remote) and not at_polisa
	if _singleplayer_services.visible:
		_singleplayer_services.call("refresh", snapshot)
		_singleplayer_services.call("fit_to_viewport")


func _request_singleplayer_return(craft_id: String) -> Dictionary:
	var visit: Node=get_mission_for_craft(craft_id)
	if visit == null:
		return {"ok": false, "reason": "no_active_visit", "message": "Kein laufender Ortsbesuch"}
	var controller: Node = visit.get_node_or_null("TacticalController")
	if controller == null:
		return {"ok": false, "reason": "controller_unavailable", "message": "Flugsteuerung nicht bereit"}
	var card: Dictionary = controller.call("_find_mission_dropship_card_entry", craft_id)
	if not bool(controller.call("_can_request_mission_dropship_return", card)):
		return {"ok": false, "reason": "return_blocked", "message": "Trupp und Schiff fuer Rueckflug vorbereiten"}
	if is_campaign_start():
		var boarding: Dictionary = controller.call("request_campaign_crew_boarding", craft_id)
		if not bool(boarding.get("ok", false)):
			return boarding
	var fuel_gate: Dictionary = _singleplayer_runtime.call("authorize_return", craft_id)
	if not bool(fuel_gate.get("ok", false)):
		return fuel_gate
	controller.call("_on_mission_dropship_return_pressed", craft_id)
	return {"ok": true, "message": "Rueckflug angefordert"}


func _finish_singleplayer_visit_if_returned() -> void:
	if _active_mission == null or _active_singleplayer_identity.is_empty():
		return
	for location in _aircraft_location_by_craft.values():
		if String(location) == "mission":
			return
	if not _pending_mission_craft_transfers.is_empty():
		return
	if not String(_active_singleplayer_identity.get("job_id", "")).is_empty():
		_singleplayer_runtime.call("record_mission_result", {"result": "aborted", "reason": "craft_returned_without_objective_completion"}, _active_singleplayer_identity.duplicate(true))
	_release_active_mission()
	_active_singleplayer_identity.clear()
	_mission_planning_state = DEFAULT_MISSION_PLANNING_STATE.duplicate(true)
	_reset_active_mission_timer()
	_refresh_homebase_screen()
	_show_homebase()


# Persistent-location lifecycle. Local SimulationRoots and controllers own state.
const LOCATION_CONTEXT_FIELDS := ["_active_mission","_mission_planning_state","_active_singleplayer_identity","_pending_campaign_mission_result","_selected_unit_ids","_selected_fireteam_ids","_selected_mission_id","_selected_mission_map_path","_active_mission_started_at_msec","_active_mission_time_limit_seconds"]

## These entry points change only the viewed projection and serviceship selection.
func open_location_view(location_id: String, craft_id: String = "") -> Dictionary:
	if location_id not in ["homebase", "star_map"] and _location_registry.get_location(location_id) == null:
		return {"ok":false,"reason":"location_not_loaded","message":"An diesem Ort ist noch keine Laufzeitinstanz geladen"}
	if not craft_id.is_empty():
		var selected := select_location_view_craft(location_id, craft_id)
		if not bool(selected.get("ok", false)): return selected
	if location_id == "homebase":
		_show_homebase(true)
	elif location_id == "star_map":
		_show_star_map()
	else:
		return focus_location(location_id)
	return {"ok":true,"view":get_location_view_snapshot()}

func select_location_view_craft(location_id: String, craft_id: String) -> Dictionary:
	if location_id != "homebase" and _location_registry.get_location(location_id) == null:
		return {"ok":false,"reason":"location_not_loaded","message":"Der Ort ist nicht geladen"}
	if craft_id.is_empty():
		_view_craft_by_location.erase(location_id)
		return {"ok":true}
	if not _is_location_view_craft_present(location_id, craft_id):
		return {"ok":false,"reason":"craft_not_at_location","message":"Dieses Schiff ist nicht an diesem Ort anwesend"}
	_view_craft_by_location[location_id] = craft_id
	return {"ok":true}

func get_location_view_snapshot() -> Dictionary:
	var location_id := "homebase" if _current_meta_view == "homebase" else ""
	if _current_meta_view == "mission" and is_instance_valid(_active_mission):
		location_id = String(_active_mission.get_meta("location_id", ""))
	var craft_id := String(_view_craft_by_location.get(location_id, ""))
	if not _is_location_view_craft_present(location_id, craft_id): craft_id = ""
	return {"view":_current_meta_view,"location_id":location_id,"craft_id":craft_id}

func _is_location_view_craft_present(location_id: String, craft_id: String) -> bool:
	if craft_id.is_empty() or _find_homebase_aircraft_definition(craft_id).is_empty(): return false
	if location_id == "homebase": return String(_aircraft_location_by_craft.get(craft_id, "")) == "homebase"
	return not location_id.is_empty() and _location_registry.get_location(location_id) != null and String(_craft_location_runtime.get(craft_id, "")) == location_id and String(_aircraft_location_by_craft.get(craft_id, "")) == "mission"

func _get_view_travel_craft_id() -> String:
	if _singleplayer_runtime == null: return ""
	var travel: Dictionary = _singleplayer_runtime.call("get_space_travel_snapshot")
	return String(travel.get("craft_id", ""))

func _capture_location_view_context() -> Dictionary:
	var previous := {}
	for key: String in LOCATION_CONTEXT_FIELDS:
		var value: Variant = get(key)
		previous[key] = value.duplicate(true) if value is Dictionary or value is Array else (value.duplicate() if value is PackedStringArray else value)
	return previous

func _restore_location_view_context(previous: Dictionary, view: String, updated_instance: Node) -> void:
	var previous_instance: Node = previous.get("_active_mission")
	if is_instance_valid(previous_instance) and previous_instance == updated_instance:
		# Admission/callback may have changed this same live root while its UI was hidden.
		# Reproject its current Controller/Setup; never replay stale pre-arrival planning.
		_enter_location_context(previous_instance)
	else:
		for key: String in LOCATION_CONTEXT_FIELDS: set(key, previous[key])
	match view:
		"mission": _show_mission()
		"homebase": _show_homebase(true)
		"star_map": _show_star_map()
		"debrief": _show_debrief()
		_:
			_current_meta_view = view
			_sync_mission_host_visibility()

func _location_timer_view_projection(instance: Node, cached: Dictionary) -> Dictionary:
	var started := int(cached.get("started_at_msec", 0))
	var limit := float(cached.get("time_limit_seconds", 0.0))
	var driver := instance.get_node_or_null("CombatLoopDriver")
	if driver != null:
		started = int(driver.get("mission_timer_started_at_msec"))
		limit = float(driver.get("mission_time_limit_seconds"))
	elif instance == _active_mission:
		started = _active_mission_started_at_msec
		limit = _active_mission_time_limit_seconds
	return {"started_at_msec":started,"time_limit_seconds":limit}
func get_mission_for_craft(craft_id: String) -> Node:
	var location_id:=String(_craft_location_runtime.get(craft_id,""))
	if not location_id.is_empty(): return _location_registry.get_location(location_id)
	return _active_mission if String(_active_singleplayer_identity.get("craft_id",""))==craft_id else null

func get_location_runtime_snapshot() -> Array:
	var result: Array=[]
	for id in _location_registry.location_ids():
		var instance: Node=_location_registry.get_location(String(id))
		var visitors: Array=[]
		for craft in _craft_location_runtime:
			if String(_craft_location_runtime[craft])==String(id) and String(_aircraft_location_by_craft.get(craft,""))=="mission": visitors.append(craft)
		result.append({"location_id":id,"instance_id":"location:%s:%d" % [id,instance.get_instance_id()],"craft_ids":visitors,"focused":instance==_active_mission and _current_meta_view=="mission","runtime_active":instance.process_mode!=Node.PROCESS_MODE_DISABLED})
	return result

func _remember_location(instance: Node) -> void:
	if not is_instance_valid(instance): return
	var id:=String(instance.get_meta("location_id",""))
	if id.is_empty(): return
	var controller: Node=instance.get_node_or_null("TacticalController")
	var data: Dictionary=Dictionary(_location_contexts.get(id,{})).duplicate()
	data.merge(_location_timer_view_projection(instance, data), true)
	data["identity"]=Dictionary(instance.get_meta("singleplayer_mission_identity",{})).duplicate(true)
	data["mission_id"]=String(data.get("identity",{}).get("scenario_id",_selected_mission_id))
	var setup: Node=instance.get_node_or_null("MissionSetup")
	data["units"]=PackedStringArray(setup.get("selected_team_unit_ids")) if setup!=null else PackedStringArray()
	data["teams"]=PackedStringArray(setup.get("selected_team_fireteam_ids")) if setup!=null else PackedStringArray()
	if instance==_active_mission: data["pending"]=_pending_campaign_mission_result.duplicate(true)
	_location_contexts[id]=data

func _enter_location_context(instance: Node) -> void:
	var id:=String(instance.get_meta("location_id",""))
	var data: Dictionary=_location_contexts.get(id,{})
	var timer := _location_timer_view_projection(instance, data)
	_active_mission=instance
	_active_mission_started_at_msec = int(timer.started_at_msec)
	_active_mission_time_limit_seconds = float(timer.time_limit_seconds)
	_active_singleplayer_identity=Dictionary(data.get("identity",instance.get_meta("singleplayer_mission_identity",{}))).duplicate(true)
	_mission_planning_state=Dictionary(instance.get_node("TacticalController").call("get_planning_state")).duplicate(true)
	_pending_campaign_mission_result=Dictionary(data.get("pending",{})).duplicate(true)
	_selected_unit_ids=PackedStringArray(data.get("units",[])); _selected_fireteam_ids=PackedStringArray(data.get("teams",[]))
	_selected_mission_id=String(data.get("mission_id",_selected_mission_id))
	_selected_mission_map_path=String(instance.get_node("MissionSetup").get("map_file_path"))

func focus_location(location_id: String) -> Dictionary:
	var instance: Node=_location_registry.get_location(location_id)
	if instance==null: return {"ok":false,"reason":"location_not_loaded","message":"An diesem Ort ist noch keine Laufzeitinstanz geladen"}
	if _active_mission!=null: _remember_location(_active_mission)
	_enter_location_context(instance)
	_show_mission()
	return {"ok":true}

func _on_location_planning_state_changed(planning: Dictionary, instance: Node) -> void:
	_run_location_callback(instance,_on_mission_planning_state_changed,planning)
func _on_location_combat_resolved(result: Dictionary, instance: Node) -> void:
	_run_location_callback(instance,_on_mission_combat_resolved,result)
func _run_location_callback(instance: Node, callback: Callable, payload: Dictionary) -> void:
	if not is_instance_valid(instance) or _location_callback_active: return
	_location_callback_active=true
	var previous := _capture_location_view_context()
	var old_view:=_current_meta_view
	var focused: bool=instance==_active_mission and old_view=="mission"
	_enter_location_context(instance)
	callback.call(payload)
	_remember_location(instance)
	if not focused:
		_restore_location_view_context(previous, old_view, instance)
	_location_callback_active=false

func _admit_existing_location(instance: Node) -> void:
	if not get_surface_departure_retirement_guard(String(_active_singleplayer_identity.get("craft_id", "")), String(instance.get_meta("location_id", ""))).ok:
		return
	var incoming: Dictionary=_planning_for_location(_mission_planning_state,String(instance.get_meta("location_id","")))
	var incoming_identity:=_active_singleplayer_identity.duplicate(true)
	var incoming_units:=_selected_unit_ids.duplicate()
	var incoming_teams:=_selected_fireteam_ids.duplicate()
	_enter_location_context(instance)
	_bind_location_visit(instance,incoming_identity)
	var setup: Node=instance.get_node("MissionSetup")
	var ids:=PackedStringArray(setup.get("selected_team_unit_ids"))
	var teams:=PackedStringArray(setup.get("selected_team_fireteam_ids"))
	for index in range(incoming_units.size()):
		if not ids.has(incoming_units[index]):
			ids.append(incoming_units[index]); teams.append(incoming_teams[index] if index<incoming_teams.size() else "ft1")
	setup.set("selected_team_unit_ids",ids); setup.set("selected_team_fireteam_ids",teams)
	var configs: Array=[]
	for unit: Dictionary in _all_team_units:
		if ids.has(String(unit.get("unit_id",""))): configs.append(unit.duplicate(true))
	setup.set("selected_team_unit_configs",configs)
	var loadouts: Dictionary=Dictionary(setup.get("member_loadouts")).duplicate(true)
	for id in incoming_units:
		loadouts[id]=_get_homebase_screen().call("_get_member_loadout",id)
	setup.set("member_loadouts",loadouts)
	setup.call("apply_runtime_selection_contract",true,incoming_units)
	var controller: Node=instance.get_node("TacticalController")
	var merged: Dictionary=controller.call("get_planning_state")
	var cards: Array=Array(merged.get("mission_drop_cards",[])).duplicate(true)
	for card: Dictionary in Array(incoming.get("mission_drop_cards",[])):
		var replaced:=false
		for index in range(cards.size()):
			if String(cards[index].get("craft_id",""))==String(card.get("craft_id","")): cards[index]=card.duplicate(true); replaced=true; break
		if not replaced: cards.append(card.duplicate(true))
	merged["mission_drop_cards"]=cards
	_mission_planning_state=merged
	_apply_planning_state_to_mission(instance)
	_remember_location(instance)

func _planning_for_location(planning: Dictionary, location_id: String) -> Dictionary:
	var result:=planning.duplicate(true)
	var cards: Array=[]
	var crew: Array=[]
	for card: Dictionary in Array(result.get("mission_drop_cards",[])):
		var craft_id:=String(card.get("craft_id",""))
		if String(_craft_location_runtime.get(craft_id,""))!=location_id: continue
		cards.append(card.duplicate(true))
		for id in Array(card.get("embarked_unit_ids",[])):
			if not crew.has(id): crew.append(id)
	result["mission_drop_cards"]=cards
	result["embarked_unit_ids"]=crew
	if not cards.is_empty():
		var active_id:=String(result.get("mission_drop_craft_id",""))
		if String(_craft_location_runtime.get(active_id,""))!=location_id:
			result["mission_drop_craft_id"]=String(cards[0].get("craft_id",""))
	return result

func _bind_location_visit(instance: Node, identity: Dictionary) -> void:
	if identity.is_empty():
		instance.set_meta("singleplayer_mission_identity",{}); return
	var previous: Dictionary=instance.get_meta("singleplayer_mission_identity",{})
	var visits: Dictionary=Dictionary(instance.get_meta("singleplayer_visit_identities",{})).duplicate(true)
	var id:=String(identity.get("craft_id",""))
	var old_visit: Dictionary=Dictionary(visits.get(id,previous if String(previous.get("craft_id",""))==id else {}))
	visits[id]=identity.duplicate(true); instance.set_meta("singleplayer_visit_identities",visits)
	# Current content has one job per place. A casual visitor does not acquire
	# another craft's job; a fresh job departure binds its own checks/results.
	if not String(identity.get("job_id","")).is_empty() or String(previous.get("job_id","")).is_empty():
		_active_singleplayer_identity=identity.duplicate(true)
		instance.set_meta("singleplayer_mission_identity",identity.duplicate(true))
		var fresh_job:=not String(identity.get("job_id","")).is_empty() and not previous.is_empty() and old_visit!=identity
		if fresh_job:
			_pending_campaign_mission_result.clear()
			var setup: Node=instance.get_node_or_null("MissionSetup")
			var driver: Node=instance.get_node_or_null("CombatLoopDriver")
			if setup!=null and driver!=null: driver.call("reset_for_location_job",String(setup.get("scenario_file_path")))

func _restore_returning_visit_membership(craft_id: String) -> void:
	var instance: Node=get_mission_for_craft(craft_id)
	if instance==null: return
	var visit: Dictionary=Dictionary(Dictionary(instance.get_meta("singleplayer_visit_identities",{})).get(craft_id,{}))
	var ids: Array=visit.get("unit_ids",[]); var teams: Array=visit.get("fireteam_ids",[])
	var pilot:=String(_assigned_aircraft_pilot_by_craft.get(craft_id,""))
	var profiles: Array=[]
	for index in ids.size():
		var id:=String(ids[index])
		if id==pilot or _homebase_staged_unit_ids.has(id): continue
		var profile: Dictionary={}
		for unit: Dictionary in _all_team_units:
			if String(unit.get("unit_id",""))==id: profile=unit; break
		if profile.is_empty(): continue
		profiles.append(profile.duplicate(true)); _homebase_staged_unit_ids.append(id)
		_homebase_staged_fireteam_ids.append(String(teams[index]) if index<teams.size() else "ft1")
	_available_team_units=_merge_missing_units_by_id(_available_team_units,profiles)


func register_campaign_recruit(profile: Dictionary, craft_definition: Dictionary = {}) -> Dictionary:
	var id := String(profile.get("unit_id",""))
	if id.is_empty(): return {"ok":false,"reason":"invalid_recruit"}
	for unit: Dictionary in _all_team_units:
		if String(unit.get("unit_id",""))==id: return {"ok":true,"already_registered":true}
	_all_team_units.append(profile.duplicate(true))
	_available_team_units.append(profile.duplicate(true))
	if not craft_definition.is_empty():
		var craft_id := String(craft_definition.get("craft_id",""))
		if craft_id.is_empty(): return {"ok":false,"reason":"invalid_craft"}
		if _find_homebase_aircraft_definition(craft_id).is_empty(): _homebase_aircraft_definitions.append(craft_definition.duplicate(true))
		_assigned_aircraft_pilot_by_craft[craft_id]=id
		_aircraft_location_by_craft[craft_id]="homebase"
	if _singleplayer_runtime != null:
		_singleplayer_runtime.call("sync_crafts")
		var personnel: Node = _singleplayer_runtime.call("get_base_personnel_runtime")
		if personnel!=null: personnel.call("sync_roster")
	_refresh_homebase_screen()
	return {"ok":true,"unit_id":id}


func remove_skirmish_person(unit_id: String) -> void:
	_all_team_units = _all_team_units.filter(func(unit: Dictionary) -> bool: return String(unit.unit_id) != unit_id)
	_available_team_units = _available_team_units.filter(func(unit: Dictionary) -> bool: return String(unit.unit_id) != unit_id)
	for craft in _assigned_aircraft_pilot_by_craft.keys():
		if String(_assigned_aircraft_pilot_by_craft[craft]) == unit_id:
			_assigned_aircraft_pilot_by_craft.erase(craft)
	if _singleplayer_runtime != null:
		_singleplayer_runtime.call("sync_space_wings")
	var index := _homebase_staged_unit_ids.find(unit_id)
	if index >= 0:
		_homebase_staged_unit_ids.remove_at(index)
		if index < _homebase_staged_fireteam_ids.size(): _homebase_staged_fireteam_ids.remove_at(index)
	index = _selected_unit_ids.find(unit_id)
	if index >= 0:
		_selected_unit_ids.remove_at(index)
		if index < _selected_fireteam_ids.size(): _selected_fireteam_ids.remove_at(index)
	_refresh_homebase_screen()


func remove_skirmish_craft(craft_id: String) -> void:
	_homebase_aircraft_definitions = _homebase_aircraft_definitions.filter(func(craft: Dictionary) -> bool: return String(craft.craft_id) != craft_id)
	_aircraft_location_by_craft.erase(craft_id)
	_selected_aircraft_cargo_by_craft.erase(craft_id)
	_loaded_aircraft_cargo_by_craft.erase(craft_id)


func rename_campaign_person(unit_id: String, display_name: String) -> Dictionary:
	for units in [_all_team_units,_available_team_units]:
		for unit: Dictionary in units:
			if String(unit.get("unit_id",""))==unit_id: unit["display_name"]=display_name
	_refresh_homebase_screen()
	return {"ok":true,"message":"Name geändert"}

func _on_base_world_selection_changed(kind: String, id: String) -> void:
	if kind=="ship":
		select_location_view_craft("homebase", id)
		get_node("HomebaseScreen").call("request_operation","craft",{"craft_id":id})
	_refresh_singleplayer_services()


# Local station lifecycle. No scene/actor admission and no travel on view changes.
func get_polisa_local_ship_purchase_capability() -> Dictionary:
	var base: Node = _singleplayer_runtime.call("get_base_personnel_runtime") if _singleplayer_runtime != null else null
	if base == null or not base.has_method("validate_remote_craft_handoff") or not base.has_method("commit_remote_craft_handoff"):
		return _polisa_lifecycle_reject("personnel_runtime_unavailable", "Lokale Abholung braucht eine verfuegbare Besatzungsverwaltung")
	if _singleplayer_runtime.has_method("_has_live_base_owner") and not bool(_singleplayer_runtime.call("_has_live_base_owner")):
		return _polisa_lifecycle_reject("personnel_runtime_unavailable", "Besatzungsverwaltung ist nicht verbunden")
	var instance: Node = _location_registry.get_location("polisa")
	var controller: Node = instance.get_node_or_null("TacticalController") if is_instance_valid(instance) else null
	for method: String in ["preview_station_craft_admission", "admit_station_craft", "preview_station_crew_handoff", "commit_station_crew_handoff", "finalize_station_craft_update"]:
		if controller == null or not controller.has_method(method):
			return _polisa_lifecycle_reject("station_pickup_unavailable", "Lokale Schiffsabholung ist hier noch nicht verfuegbar")
	return {"ok":true,"available":true,"message":"Abholung auf einem freien Stationspad; ein freies Heimatpad bleibt als Rueckkehrplatz reserviert"}

func prepare_polisa_local_ship_purchase(craft: Dictionary, request_id: String, requested_pad_id: String = "") -> Dictionary:
	var retirement_guard := get_surface_departure_retirement_guard(String(craft.get("craft_id", "")), "polisa")
	if not retirement_guard.ok: return retirement_guard
	if request_id.strip_edges().is_empty(): return _polisa_lifecycle_reject("invalid_request", "Kaufanfrage fehlt")
	var capability := get_polisa_local_ship_purchase_capability()
	if not capability.get("ok", false): return capability
	var id := String(craft.get("craft_id", ""))
	var model := String(craft.get("model_id", ""))
	if id.is_empty() or model not in ["cutlass", "buccaneer"] or not _find_homebase_aircraft_definition(id).is_empty():
		return _polisa_lifecycle_reject("invalid_station_craft", "Schiff ist bereits vorhanden oder nicht fuer die Station verfuegbar")
	var normalized := craft.duplicate(true)
	normalized["crew_capacity"] = 8 if model == "cutlass" else 1
	normalized["seat_capacity"] = normalized.crew_capacity
	if String(normalized.get("craft_type", "")) != ("dropship" if model == "cutlass" else "fighter"):
		return _polisa_lifecycle_reject("invalid_station_craft", "Schiffstyp passt nicht zum Modell")
	var instance: Node = _location_registry.get_location("polisa")
	var admission: Dictionary = instance.get_node("TacticalController").call("preview_station_craft_admission", normalized, requested_pad_id)
	if not admission.get("ok", false): return admission
	var prepared := {"ok":true,"request_id":request_id,"craft_definition":normalized,
		"location_instance_id":instance.get_instance_id(),"acquisition_pad_id":String(admission.get("pad_id", "")),
		"pad_position":admission.get("position", Vector2.INF),
		"visit_identity":{"craft_id":id,"location_id":"polisa","scenario_id":"polisa_visit","job_id":"",
			"origin_kind":"local_station_purchase","origin_receipt_id":request_id,"unit_ids":[],"fireteam_ids":[]}}
	if String(prepared.acquisition_pad_id).is_empty() or not prepared.pad_position is Vector2 or not Vector2(prepared.pad_position).is_finite():
		return _polisa_lifecycle_reject("invalid_station_pad", "Stationspad ist nicht verfuegbar")
	prepared["seal"] = _sign_polisa_purchase(prepared)
	return prepared

func _sign_polisa_purchase(prepared: Dictionary) -> String:
	var content := prepared.duplicate(true)
	content.erase("seal")
	return (_polisa_purchase_seal_key + JSON.stringify(content, "", true)).sha256_text()

func commit_polisa_local_ship_purchase(prepared: Dictionary) -> Dictionary:
	if String(prepared.get("seal", "")) != _sign_polisa_purchase(prepared):
		return _polisa_lifecycle_reject("invalid_station_transaction", "Kaufvorbereitung ist ungueltig")
	var instance: Node = _location_registry.get_location("polisa")
	if not is_instance_valid(instance) or instance.get_instance_id() != int(prepared.get("location_instance_id", 0)):
		return _polisa_lifecycle_reject("station_changed", "Stationszustand hat sich geaendert")
	var craft: Dictionary = prepared.craft_definition
	var id := String(craft.craft_id)
	var retirement_guard := get_surface_departure_retirement_guard(id, "polisa")
	if not retirement_guard.ok: return retirement_guard
	if not _find_homebase_aircraft_definition(id).is_empty() or _craft_location_runtime.has(id):
		return _polisa_lifecycle_reject("craft_already_registered", "Schiff ist bereits registriert")
	# The controller revalidates its actual pad/sequence state before its first write.
	# It publishes no planning signal until the adapter finishes all other owners.
	var admitted: Dictionary = instance.get_node("TacticalController").call("admit_station_craft", craft, String(prepared.acquisition_pad_id), String(prepared.request_id))
	if not admitted.get("ok", false): return admitted
	_craft_location_runtime[id] = "polisa"
	var visits: Dictionary = Dictionary(instance.get_meta("singleplayer_visit_identities", {})).duplicate(true)
	visits[id] = Dictionary(prepared.visit_identity).duplicate(true)
	instance.set_meta("singleplayer_visit_identities", visits)
	_remember_location(instance)
	if _active_mission == instance: _enter_location_context(instance)
	return {"ok":true,"craft_id":id,"acquisition_pad_id":String(prepared.acquisition_pad_id),"pad_position":admitted.get("position", prepared.pad_position),"visit_identity":Dictionary(prepared.visit_identity).duplicate(true)}

func finalize_polisa_local_ship_purchase(craft_id: String) -> void:
	var instance: Node = _location_registry.get_location("polisa")
	if not is_instance_valid(instance) or String(_craft_location_runtime.get(craft_id, "")) != "polisa": return
	instance.get_node("TacticalController").call("finalize_station_craft_update")
	_remember_location(instance)
	if _active_mission == instance: _enter_location_context(instance)
	_refresh_singleplayer_services()

func _polisa_visit_identities(instance: Node) -> Dictionary:
	var visits: Dictionary = Dictionary(instance.get_meta("singleplayer_visit_identities", {})).duplicate(true)
	var controller: Node = instance.get_node_or_null("TacticalController")
	# The legacy campaign start adds its real pilot to Setup after creating the
	# outward visit. Complete that transport projection from exact local evidence.
	for craft_id: String in visits:
		if String(_craft_location_runtime.get(craft_id, "")) != "polisa" or String(_aircraft_location_by_craft.get(craft_id, "")) != "mission": continue
		var pilot := String(_assigned_aircraft_pilot_by_craft.get(craft_id, ""))
		var card: Dictionary = controller.call("_find_mission_dropship_card_entry", craft_id) if controller != null else {}
		var unit: Node = controller.call("_get_campaign_sortie_unit", pilot) if controller != null and not pilot.is_empty() else null
		if unit == null or String(card.get("pilot_unit_id", "")) != pilot: continue
		var ids: Array = Array(visits[craft_id].get("unit_ids", [])).duplicate()
		var teams: Array = Array(visits[craft_id].get("fireteam_ids", [])).duplicate()
		if not ids.has(pilot):
			ids.append(pilot)
			teams.append(String(unit.call("get_fireteam_id")))
			visits[craft_id]["unit_ids"] = ids
			visits[craft_id]["fireteam_ids"] = teams
	return visits

func get_polisa_crew_handoff_snapshot(target_craft_id: String) -> Dictionary:
	var instance: Node = _location_registry.get_location("polisa")
	if not is_instance_valid(instance): return {"sources":[]}
	var controller: Node = instance.get_node_or_null("TacticalController")
	if controller == null: return {"sources":[]}
	var visits := _polisa_visit_identities(instance)
	var sources: Array = []
	for id: String in visits:
		if id == target_craft_id or String(_craft_location_runtime.get(id, "")) != "polisa" or String(_aircraft_location_by_craft.get(id, "")) != "mission": continue
		if not bool(controller.call("_is_parked_campaign_dropship", id)): continue
		var people: Array = []
		for raw_id: Variant in Array(visits[id].get("unit_ids", [])):
			var unit_id := String(raw_id)
			var unit: Node = controller.call("_get_campaign_sortie_unit", unit_id)
			if unit == null or int(unit.call("get_health")) <= 0: continue
			people.append({"unit_id":unit_id,"name":String(unit.call("get_display_name")),"fireteam_id":String(unit.call("get_fireteam_id"))})
		sources.append({"id":id,"name":String(_find_homebase_aircraft_definition(id).get("display_name", id)),"unit_ids":Array(visits[id].get("unit_ids", [])).duplicate(),"people":people})
	return {"sources":sources,"target_craft_id":target_craft_id}

func deploy_polisa_craft_crew(craft_id: String) -> Dictionary:
	var instance: Node = _location_registry.get_location("polisa")
	if not is_instance_valid(instance) or get_mission_for_craft(craft_id) != instance or String(_aircraft_location_by_craft.get(craft_id, "")) != "mission":
		return _polisa_lifecycle_reject("craft_not_at_station", "Schiff ist nicht auf Polisa")
	return instance.get_node("TacticalController").call("request_campaign_crew_deployment", craft_id)

func board_polisa_craft_crew(craft_id: String) -> Dictionary:
	var instance: Node = _location_registry.get_location("polisa")
	if not is_instance_valid(instance) or get_mission_for_craft(craft_id) != instance or String(_aircraft_location_by_craft.get(craft_id, "")) != "mission" or not _find_pending_mission_craft_transfer(craft_id).is_empty():
		return _polisa_lifecycle_reject("craft_not_at_station", "Schiff ist nicht auf Polisa geparkt")
	return instance.get_node("TacticalController").call("request_campaign_crew_boarding", craft_id)

func handoff_polisa_station_crew(source_craft_id: String, target_craft_id: String, unit_ids: PackedStringArray, pilot_id: String, request_id: String) -> Dictionary:
	if request_id.is_empty(): return _polisa_lifecycle_reject("invalid_request", "Besatzungsanfrage fehlt")
	var signature := JSON.stringify([source_craft_id,target_craft_id,Array(unit_ids),pilot_id])
	if _polisa_handoff_requests.has(request_id):
		if String(_polisa_handoff_requests[request_id].signature) != signature: return _polisa_lifecycle_reject("request_id_conflict", "Anfrage-ID ist bereits anders verwendet")
		var replay: Dictionary = _polisa_handoff_requests[request_id].result.duplicate(true)
		replay["replayed"] = true
		return replay
	var instance: Node = _location_registry.get_location("polisa")
	if not is_instance_valid(instance): return _polisa_lifecycle_reject("station_unavailable", "Polisa ist nicht geladen")
	for id: String in [source_craft_id,target_craft_id]:
		if String(_craft_location_runtime.get(id, "")) != "polisa" or String(_aircraft_location_by_craft.get(id, "")) != "mission" or not _find_pending_mission_craft_transfer(id).is_empty():
			return _polisa_lifecycle_reject("craft_not_at_station", "Beide Schiffe muessen auf Polisa geparkt sein")
	var visits := _polisa_visit_identities(instance)
	if not visits.has(source_craft_id) or not visits.has(target_craft_id): return _polisa_lifecycle_reject("visit_missing", "Besatzungszuordnung fehlt")
	var membership := {}
	for id: String in visits:
		if String(_craft_location_runtime.get(id, "")) == "polisa" and String(_aircraft_location_by_craft.get(id, "")) == "mission":
			membership[id] = Array(visits[id].get("unit_ids", [])).duplicate()
	for id: String in _assigned_aircraft_pilot_by_craft:
		if id not in [source_craft_id,target_craft_id] and unit_ids.has(String(_assigned_aircraft_pilot_by_craft[id])):
			return _polisa_lifecycle_reject("pilot_already_assigned", "Person ist einem anderen Schiff als Pilot zugewiesen")
	var controller: Node = instance.get_node("TacticalController")
	var preview: Dictionary = controller.call("preview_station_crew_handoff", source_craft_id,target_craft_id,unit_ids,pilot_id,membership)
	if not preview.get("ok", false): return preview
	var base_personnel: Node = _singleplayer_runtime.call("get_base_personnel_runtime") if _singleplayer_runtime != null else null
	if base_personnel == null or not base_personnel.has_method("validate_remote_craft_handoff"):
		return _polisa_lifecycle_reject("personnel_runtime_unavailable", "Besatzungsverwaltung ist nicht verfuegbar")
	if _singleplayer_runtime.has_method("_has_live_base_owner") and not bool(_singleplayer_runtime.call("_has_live_base_owner")):
		return _polisa_lifecycle_reject("personnel_runtime_unavailable", "Besatzungsverwaltung ist nicht verbunden")
	var base_guard: Dictionary = base_personnel.call("validate_remote_craft_handoff", unit_ids,source_craft_id,target_craft_id)
	if not base_guard.get("ok", false): return base_guard
	var from: Dictionary = visits[source_craft_id]
	var into: Dictionary = visits[target_craft_id]
	var ids: Array = Array(from.get("unit_ids", []))
	var teams: Array = Array(from.get("fireteam_ids", []))
	if ids.size() != teams.size(): return _polisa_lifecycle_reject("invalid_visit_membership", "Besatzungszuordnung ist unvollstaendig")
	var remaining: Array = []
	var remaining_teams: Array = []
	var target_ids: Array = Array(into.get("unit_ids", [])).duplicate()
	var target_teams: Array = Array(into.get("fireteam_ids", [])).duplicate()
	if target_ids.size() != target_teams.size(): return _polisa_lifecycle_reject("invalid_visit_membership", "Zielbesatzung ist unvollstaendig")
	for index in ids.size():
		if unit_ids.has(String(ids[index])):
			target_ids.append(ids[index]); target_teams.append(teams[index])
		else:
			remaining.append(ids[index]); remaining_teams.append(teams[index])
	from["unit_ids"] = remaining; from["fireteam_ids"] = remaining_teams
	into["unit_ids"] = target_ids; into["fireteam_ids"] = target_teams
	var committed: Dictionary = controller.call("commit_station_crew_handoff", source_craft_id,target_craft_id,unit_ids,pilot_id,membership,request_id)
	if not committed.get("ok", false): return committed
	# Controller commit is emit-free and never touches the base owner. Its just-
	# validated remote binding therefore cannot change between these two commits.
	base_personnel.call("commit_remote_craft_handoff", unit_ids,source_craft_id,target_craft_id)
	visits[source_craft_id] = from; visits[target_craft_id] = into
	instance.set_meta("singleplayer_visit_identities", visits)
	if unit_ids.has(String(_assigned_aircraft_pilot_by_craft.get(source_craft_id, ""))): _assigned_aircraft_pilot_by_craft.erase(source_craft_id)
	_assigned_aircraft_pilot_by_craft[target_craft_id] = pilot_id
	var primary: Dictionary = instance.get_meta("singleplayer_mission_identity", {})
	var primary_id := String(primary.get("craft_id", ""))
	if visits.has(primary_id): instance.set_meta("singleplayer_mission_identity", Dictionary(visits[primary_id]).duplicate(true))
	_remember_location(instance)
	if _active_mission == instance: _enter_location_context(instance)
	var result := {"ok":true,"source_craft_id":source_craft_id,"target_craft_id":target_craft_id,"pilot_id":pilot_id,"unit_ids":Array(unit_ids),"message":"Besatzung uebertragen; vor dem Abflug am neuen Schiff einsteigen"}
	_polisa_handoff_requests[request_id] = {"signature":signature,"result":result.duplicate(true)}
	base_personnel.call("finalize_remote_craft_handoff")
	controller.call("finalize_station_craft_update")
	_refresh_singleplayer_services()
	return result

func _polisa_lifecycle_reject(reason: String, message: String) -> Dictionary:
	return {"ok":false,"available":false,"reason":reason,"message":message}
