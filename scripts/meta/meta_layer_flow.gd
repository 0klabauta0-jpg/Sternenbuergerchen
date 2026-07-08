extends Node

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const MISSION_PROGRESSION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/mission_progression_resolver.gd")
const PERSONNEL_EVENT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_resolver.gd")
const AIR_ASSET_RECOVERY_STATE_SCRIPT: GDScript = preload("res://scripts/meta/air_asset_recovery_state.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const REAL_WINDOW_FIREFIGHT_SIGHT_REVIEW_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_release_candidate_real_window_firefight_sight_review.gd")
const VISIBLE_FIREFIGHT_FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_release_candidate_visible_firefight_findings.gd")
const FRIENDLY_NODE_NAMES: PackedStringArray = ["UnitAlpha", "UnitBravo", "UnitCharlie", "UnitDelta", "UnitEcho", "UnitFoxtrot", "UnitGolf", "UnitHotel"]
const DEFAULT_META_MAP_PATH: String = "res://maps/Ground_Mission01_32x32.json"
const DEFAULT_META_SCENARIO_PATH: String = "res://data/mission_scenarios/ground_mission01_default.json"
const FRONTIER_VERTICAL_SLICE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
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
var _assigned_aircraft_pilot_by_craft: Dictionary = {}
var _aircraft_location_by_craft: Dictionary = {}
var _selected_aircraft_cargo_by_craft: Dictionary = {}
var _loaded_aircraft_cargo_by_craft: Dictionary = {}
var _pending_homebase_team_transfers: Array = []
var _pending_homebase_pilot_transfers: Array = []
var _pending_homebase_cargo_loads: Array = []
var _pending_mission_craft_transfers: Array = []
var _air_asset_recovery_by_craft: Dictionary = {}
var _transfer_sequence: int = 0
var _preview_mission = null
var _preview_mission_signature: Dictionary = {}
var _mission_planning_state: Dictionary = DEFAULT_MISSION_PLANNING_STATE.duplicate(true)
var _active_mission_started_at_msec: int = 0
var _active_mission_time_limit_seconds: float = 0.0
var _last_meta_timer_text: String = ""
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


func _ready() -> void:
	set_process(true)
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	var debrief_screen = _get_debrief_screen()
	if homebase_screen == null or fob_screen == null or debrief_screen == null:
		push_warning("MetaLayerFlow requires HomebaseScreen, FOBScreen and DebriefScreen children.")
		return

	_load_persistent_player_roster()
	_ensure_singleplayer_release_start_bootstrap()
	META_UI_SKIN_SCRIPT.apply_meta_navigation(self)
	_connect_navigation_buttons()
	_ensure_homebase_aircraft_locations()
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
	_refresh_meta_mission_timer_labels()


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
	await _wait_release_deeplink_frames(3)

	if _active_mission == null:
		var started: bool = await _request_release_start_mission_from_homebase_for_deeplink()
		if not started:
			_release_lz_drop_preview_deeplink_status = "blocked"
			_release_lz_drop_preview_deeplink_reason = "start_mission_failed"
			return
	await _wait_release_deeplink_frames(8)

	var handoff: Dictionary = get_homebase_to_mission_handoff_snapshot()
	var planning: Dictionary = Dictionary(handoff.get("planning", {}))
	var craft_id: String = String(planning.get("mission_drop_craft_id", "")).strip_edges()
	if craft_id.is_empty():
		_release_lz_drop_preview_deeplink_status = "blocked"
		_release_lz_drop_preview_deeplink_reason = "missing_mission_drop_craft_id"
		return
	_complete_release_lz_drop_preview_craft_arrival(craft_id)
	await _wait_release_deeplink_frames(8)

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
	controller.call("_on_mission_dropship_card_drop_pressed", craft_id)
	await _wait_release_deeplink_frames(4)
	controller.call("_complete_drop_sequence_deployment")
	controller.call("_advance_primary_drop_sequence_unloading", 999.0)
	controller.call("_flush_pending_drop_runtime_phase_starts")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_release_deeplink_frames(10)

	var move_target := Vector2(544.0, 288.0)
	if not bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)):
		_release_lz_drop_preview_deeplink_status = "blocked"
		_release_lz_drop_preview_deeplink_reason = "move_preview_failed"
		return
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_release_deeplink_frames(10)

	var snapshot: Dictionary = get_release_lz_drop_preview_deeplink_snapshot(PackedStringArray([RELEASE_SINGLEPLAYER_LZ_DROP_PREVIEW_DEEPLINK_ARG]))
	_release_lz_drop_preview_deeplink_applied = String(snapshot.get("preview_status", "")) == "pass" \
		and String(snapshot.get("first_move_gate", "")) == "pass" \
		and int(snapshot.get("planned_waypoint_count", 0)) > 0
	_release_lz_drop_preview_deeplink_status = "applied" if _release_lz_drop_preview_deeplink_applied else "blocked"
	_release_lz_drop_preview_deeplink_reason = "" if _release_lz_drop_preview_deeplink_applied else "preview_snapshot_not_pass"
	set_meta("release_lz_drop_preview_deeplink_applied", _release_lz_drop_preview_deeplink_applied)


func _request_release_start_mission_from_homebase_for_deeplink() -> bool:
	await _wait_release_deeplink_frames(3)
	if _current_meta_view != "homebase":
		return _current_meta_view == "mission" and _active_mission != null
	var homebase_screen = _get_homebase_screen()
	_ensure_singleplayer_visible_homebase_actionability()
	if homebase_screen == null or not homebase_screen.has_method("request_mission_start"):
		return false
	if not _is_singleplayer_visible_homebase_actionable(homebase_screen):
		return false
	homebase_screen.call("request_mission_start")
	await _wait_release_deeplink_frames(8)
	return _current_meta_view == "mission" and _active_mission != null


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


func _apply_release_first_go_firefight_deeplink(user_args: PackedStringArray = PackedStringArray()) -> void:
	var args: PackedStringArray = user_args if user_args.size() > 0 else _get_release_cmdline_args()
	if not _has_release_first_go_firefight_deeplink_arg(args):
		return
	_release_first_go_firefight_deeplink_requested = true
	_release_first_go_firefight_deeplink_status = "requested"
	_release_first_go_firefight_deeplink_reason = ""
	set_meta("release_first_go_firefight_deeplink_requested", true)

	await _apply_release_lz_drop_preview_deeplink(PackedStringArray([RELEASE_SINGLEPLAYER_LZ_DROP_PREVIEW_DEEPLINK_ARG]))
	await _wait_release_deeplink_frames(8)
	if not _release_lz_drop_preview_deeplink_applied:
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = "lz_drop_preview_failed"
		return

	var active_mission: Node = _active_mission
	var controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var combat_driver: Node = active_mission.get_node_or_null("CombatLoopDriver") if active_mission != null else null
	var simulation_root: Node = active_mission.get_node_or_null("SimulationRoot") if active_mission != null else null
	if controller == null or combat_driver == null or simulation_root == null:
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = "mission_runtime_nodes_missing"
		return

	var pre_go: Dictionary = get_release_candidate_lz_drop_preview_actionability_snapshot()
	var first_move: Dictionary = Dictionary(pre_go.get("first_move", {}))
	var selected_fireteam_id: String = _first_release_fireteam_id(first_move)
	_release_first_go_firefight_pre_go_passed = String(pre_go.get("status", "")) == "pass"
	if not _release_first_go_firefight_pre_go_passed or selected_fireteam_id.is_empty():
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = "pre_go_not_actionable"
		return
	if not bool(controller.call("execute_selected_fireteam_orders")):
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = "go_execution_failed"
		return
	controller.call("_refresh_world_overlays")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_release_deeplink_frames(3)

	var contact_setup: Dictionary = _position_release_first_enemy_near_fireteam(controller, selected_fireteam_id)
	if contact_setup.is_empty():
		_release_first_go_firefight_deeplink_status = "blocked"
		_release_first_go_firefight_deeplink_reason = "contact_setup_failed"
		return
	_prepare_release_fireteam_for_first_engagement(controller, selected_fireteam_id, Vector2(contact_setup.get("enemy_position", Vector2.ZERO)))
	_update_release_contact_tracking(combat_driver)
	_force_release_first_engagement_decision(controller, combat_driver, simulation_root, selected_fireteam_id, contact_setup)
	controller.call("refresh_contact_overlay")
	controller.call("refresh_fireteam_security_state")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_release_deeplink_frames(10)

	var snapshot: Dictionary = get_release_first_go_firefight_deeplink_snapshot(PackedStringArray([RELEASE_SINGLEPLAYER_FIRST_GO_FIREFIGHT_DEEPLINK_ARG]))
	_release_first_go_firefight_deeplink_applied = String(snapshot.get("firefight_status", "")) == "pass" \
		and bool(snapshot.get("go_executed", false)) \
		and int(snapshot.get("selected_contact_count", 0)) > 0 \
		and not String(snapshot.get("engagement_status", "")).strip_edges().is_empty()
	_release_first_go_firefight_deeplink_status = "applied" if _release_first_go_firefight_deeplink_applied else "blocked"
	_release_first_go_firefight_deeplink_reason = "" if _release_first_go_firefight_deeplink_applied else "firefight_snapshot_not_pass"
	set_meta("release_first_go_firefight_deeplink_applied", _release_first_go_firefight_deeplink_applied)


func _first_release_fireteam_id(first_move: Dictionary) -> String:
	for fireteam_id_variant in Array(first_move.get("selected_fireteam_ids", [])):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			return fireteam_id
	return ""


func _position_release_first_enemy_near_fireteam(controller: Node, fireteam_id: String) -> Dictionary:
	var friendly_units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false))
	if enemy_units.is_empty():
		enemy_units = Array(controller.call("_get_all_enemy_units", true))
	if friendly_units.is_empty() or enemy_units.is_empty():
		return {}
	var friendly := friendly_units[0] as Node2D
	var enemy := enemy_units[0] as Node2D
	if friendly == null or enemy == null:
		return {}
	enemy.global_position = friendly.global_position + Vector2(58.0, 0.0)
	if enemy is CanvasItem:
		(enemy as CanvasItem).visible = true
	return {
		"fireteam_id": fireteam_id,
		"friendly_unit_id": _get_release_unit_id(friendly),
		"enemy_unit_id": _get_release_unit_id(enemy),
		"friendly_position": friendly.global_position,
		"enemy_position": enemy.global_position,
	}


func _prepare_release_fireteam_for_first_engagement(controller: Node, fireteam_id: String, enemy_position: Vector2) -> void:
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null:
			continue
		unit.set("skill_accuracy", 1.0)
		if unit.has_method("set_runtime_status"):
			unit.call(
				"set_runtime_status",
				"holding",
				"hold_position",
				30,
				"fire_at_will",
				"defend",
				1.0,
				0.0,
				0.0,
				1,
				enemy_position,
				"engage",
				"aimed",
				"task832_release_first_go_firefight",
				1.0,
				75.0
			)


func _force_release_first_engagement_decision(controller: Node, combat_driver: Node, simulation_root: Node, fireteam_id: String, contact_setup: Dictionary) -> void:
	var enemy_id: String = String(contact_setup.get("enemy_unit_id", "")).strip_edges()
	var detection_progress: Dictionary = Dictionary(combat_driver.get("_detection_progress")).duplicate(true)
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null:
			continue
		var friendly_id: String = _get_release_unit_id(unit)
		if friendly_id.is_empty() or enemy_id.is_empty():
			continue
		detection_progress["%s:%s" % [friendly_id, enemy_id]] = 0
		detection_progress["%s:%s" % [enemy_id, friendly_id]] = 0
	combat_driver.set("_detection_progress", detection_progress)
	combat_driver.set("_current_tick", 120)
	combat_driver.set("_next_attack_tick", 0)
	if combat_driver.has_method("_try_enqueue_attacks"):
		combat_driver.call("_try_enqueue_attacks", simulation_root)


func _update_release_contact_tracking(combat_driver: Node) -> void:
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")
	if combat_driver.has_method("_advance_detection_timers"):
		combat_driver.call("_advance_detection_timers")
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")


func _get_release_unit_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id"))
	return unit.name if unit != null else ""


func _wait_release_deeplink_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


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
		"decision_line_first_in_selected_fireteam",
		String(tactical_readability.get("gate", "")) == "pass"
			and String(tactical_readability.get("selected_fireteam_first_line", "")).strip_edges() == String(tactical_readability.get("decision_line", "")).strip_edges()
			and not String(tactical_readability.get("decision_line", "")).strip_edges().is_empty(),
		"critical",
		"Selected Fireteam should lead with the NEXT/WHY decision line."
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
		"selected_fireteam_status_text": String(tactical_real_window.get("selected_fireteam_status_text", "")),
		"checks": checks,
		"failed_count": failed_count,
		"check_count": checks.size(),
		"issues": _build_handoff_issue_list(checks),
		"status": "pass" if failed_count == 0 else "review",
		"recommended_next_task": "TASK_835 - Release Firefight Bottom Dock Density Polish",
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
		if bool(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("is_recovery_active", Dictionary(_air_asset_recovery_by_craft.get(craft_id, {})))):
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
	if not previous_pilot_id.is_empty():
		_append_unit_to_fob(previous_pilot_id)
	_refresh_fob_screen()
	_refresh_homebase_screen()
	_refresh_map_screen()


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


func _start_or_update_active_mission() -> void:
	if _active_mission != null:
		_release_preview_mission()
		_configure_mission_instance(_active_mission, _selected_unit_ids, _selected_fireteam_ids, false)
		_apply_planning_state_to_mission(_active_mission)
		_show_mission()
		return
	_start_mission()


func _configure_mission_instance(mission_instance: Node, selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray, preview_mode: bool) -> void:
	if selected_unit_ids.is_empty():
		selected_unit_ids = _selected_unit_ids.duplicate()
	if selected_fireteam_ids.is_empty():
		selected_fireteam_ids = _selected_fireteam_ids.duplicate()
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
		if not planning_unit_configs.is_empty():
			mission_setup.set("selected_team_unit_configs", planning_unit_configs.duplicate(true))
		else:
			var fob_screen_for_configs: Node = get_node_or_null("FOBScreen")
			if fob_screen_for_configs != null and fob_screen_for_configs.has_method("get_selected_unit_configs"):
				mission_setup.set("selected_team_unit_configs", Array(fob_screen_for_configs.call("get_selected_unit_configs")).duplicate(true))
		mission_setup.set("map_file_path", String(selected_mission.get("map_file_path", DEFAULT_META_MAP_PATH)).strip_edges())
		mission_setup.set("scenario_file_path", String(selected_mission.get("scenario_file_path", NO_SCENARIO_FILE_PATH)).strip_edges())
		mission_setup.set("defer_friendly_runtime_activation", _should_defer_friendly_runtime_activation())
		mission_setup.set("allow_full_roster_when_selection_empty", false)
		var gameplay_settings: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings"))
		mission_setup.set("fog_of_war_mode", String(gameplay_settings.get("fog_of_war_mode", "known_terrain")))

		var planning_member_loadouts: Dictionary = Dictionary(_mission_planning_state.get("member_loadouts", {})).duplicate(true)
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
			tactical_controller.call("set_planning_state", _mission_planning_state)

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
	_last_mission_result = _apply_air_asset_recovery_from_mission_result(_last_mission_result)
	_last_mission_result = _apply_mission_progression_to_roster(_last_mission_result)
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
	var air_asset_status: Dictionary = _extract_air_asset_status_from_mission(mission_instance)
	if not air_asset_status.is_empty():
		merged_result["air_asset_status"] = air_asset_status
	var mini_aar_debrief: Dictionary = _extract_mini_aar_debrief_from_mission(mission_instance)
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
	var save_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", updated_roster, PLAYER_ROSTER_STORE_SCRIPT.DEFAULT_PROFILE_ID))
	result["progression_save_ok"] = bool(save_result.get("ok", false))
	result["progression_save_path"] = String(save_result.get("path", ""))
	result["progression_save_diagnostics"] = PackedStringArray(save_result.get("diagnostics", PackedStringArray()))
	return result


func _build_progression_roster_payload() -> Dictionary:
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", PLAYER_ROSTER_STORE_SCRIPT.DEFAULT_PROFILE_ID))
	var roster: Dictionary = Dictionary(load_result.get("roster", {})).duplicate(true) if bool(load_result.get("ok", false)) else {}
	if roster.is_empty():
		roster = {
			"schema_version": 1,
			"generator_id": "meta_layer_progression_runtime",
			"seed": "meta_layer_runtime",
			"player_profile_id": PLAYER_ROSTER_STORE_SCRIPT.DEFAULT_PROFILE_ID,
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

	_refresh_fob_screen()
	if _is_homebase_direct_mission_drop_source():
		_sync_homebase_direct_mission_drop_transport_fields()
	else:
		_sync_mission_drop_transport_fields_from_fob()
	_refresh_homebase_screen()
	_refresh_map_screen()
	_ensure_transport_timer_state()


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
	var fob_screen = _get_fob_screen()
	var fireteam_definitions: Array = []
	if fob_screen != null and fob_screen.has_method("get_fireteam_definitions"):
		fireteam_definitions = Array(fob_screen.call("get_fireteam_definitions")).duplicate(true)
	homebase_screen.setup_roster(_available_team_units, _homebase_staged_unit_ids)
	_homebase_staged_fireteam_ids = _normalize_homebase_fireteam_selection(_homebase_staged_unit_ids, _homebase_staged_fireteam_ids)
	homebase_screen.set_fireteam_context(_homebase_staged_fireteam_ids, fireteam_definitions)
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
		true
	)
	set_meta("singleplayer_bootstrap_payload_seeded", true)


func _ensure_singleplayer_visible_homebase_actionability() -> void:
	if not bool(get_meta("singleplayer_bootstrap_enabled", false)):
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
	if not bool(get_meta("singleplayer_bootstrap_enabled", false)):
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
	return {
		"transfer_id": "mission_craft_%d" % _transfer_sequence,
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
		elif craft_location != "fob" and craft_location != "transit":
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
			else:
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
			"visible_in_homebase": craft_location == "homebase" or recovery_active or (mission_phase == "to_mission" and is_homebase_direct_mission_transfer),
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


func _show_homebase() -> void:
	_current_meta_view = "homebase"
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	var debrief_screen = _get_debrief_screen()
	if not _is_homebase_direct_mission_drop_source():
		_sync_fob_transfer_selection_from_screen()
	if homebase_screen != null:
		homebase_screen.visible = true
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
	if not _is_homebase_direct_mission_drop_source():
		_sync_fob_dropship_state_into_mission_planning(false, MISSION_DROP_SOURCE_FOB)
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
	_append_homebase_direct_setup_selection(
		setup_unit_ids,
		setup_fireteam_ids,
		seen_unit_ids,
		Array(result.get("mission_setup_unit_ids", result.get("selected_unit_ids", []))),
		Array(result.get("mission_setup_fireteam_ids", result.get("selected_fireteam_ids", [])))
	)
	for card_variant in Array(result.get("mission_drop_cards", [])):
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		var state: String = String(card.get("state", "")).strip_edges().to_lower()
		if state == "to_fob" or state == "to_homebase":
			continue
		var card_unit_ids: Array = Array(card.get("embarked_unit_ids", []))
		if card_unit_ids.is_empty():
			continue
		var card_fireteam_ids: Array = _build_homebase_direct_card_fireteam_selection(card, card_unit_ids)
		_append_homebase_direct_setup_selection(setup_unit_ids, setup_fireteam_ids, seen_unit_ids, card_unit_ids, card_fireteam_ids)
	if setup_unit_ids.is_empty():
		return result
	result["mission_setup_unit_ids"] = Array(setup_unit_ids)
	result["mission_setup_fireteam_ids"] = Array(setup_fireteam_ids)
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
	if _find_pending_mission_craft_transfer(normalized_craft_id).is_empty():
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
