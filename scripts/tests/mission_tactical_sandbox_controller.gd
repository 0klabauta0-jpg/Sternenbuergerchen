class_name TacticalInputController
extends Node

const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const NPC_COMPACT_CARD_SCENE: PackedScene = preload("res://scenes/meta/components/npc_compact_card.tscn")
const META_UNIT_PROFILE_BUILDER_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tests/fireteam_behavior_resolver.gd")
const FIRETEAM_ORDER_VISUALIZER_SCRIPT: GDScript = preload("res://scripts/tests/fireteam_order_visualizer.gd")

const FIRETEAM_NAMES: PackedStringArray = ["ALL", "BLUE", "GOLD"]
const REAL_FIRETEAM_IDS: PackedStringArray = ["blue", "gold"]
const LEGACY_PHASE_NAMES: PackedStringArray = ["APPROACH", "ASSAULT", "HOLD"]
const APPROACH_ANGLES: PackedStringArray = ["NW", "NE", "SW", "SE"]
const HOTKEY_LEGEND: String = "LMB Select | RMB Waypoint | CTRL+LMB Add | Drag Lasso | DEL Waypoint | 1 Move | 2 Hold | 3 Flank | 4 Take | Q/E Team | R/F Edit Phase | G Next Phase"
const FRIENDLY_TEAM_ID: String = "team_alpha"
const CARD_REFRESH_INTERVAL_SECONDS: float = 0.35
const UNIT_SELECTION_PICK_RADIUS: float = 34.0
const SELECTION_DRAG_THRESHOLD: float = 10.0
const WAYPOINT_DRAG_THRESHOLD: float = 4.0
const PHASE_WAYPOINT_COMPLETE_RADIUS: float = 26.0
const WAYPOINT_MENU_MOVE_ID: int = 100
const WAYPOINT_MENU_DEFEND_ID: int = 101
const WAYPOINT_MENU_ENGAGE_ID: int = 102
const WAYPOINT_MENU_FLANK_ID: int = 103
const WAYPOINT_MENU_TAKE_ID: int = 104
const WAYPOINT_MENU_DELETE_ID: int = 199
const DROP_STAGING_DISTANCE: float = 560.0
const DROP_SHIP_SPEED: float = 340.0
const DROP_LANDING_HOLD_SECONDS: float = 0.75
const DROP_UNLOAD_INTERVAL_SECONDS: float = 0.45
const DROP_SHIP_RECALL_COOLDOWN_SECONDS: float = 2.5
const DROP_SEQUENCE_INBOUND: String = "inbound"
const DROP_SEQUENCE_LANDED: String = "landed"
const DROP_SEQUENCE_UNLOADING: String = "unloading"
const DROP_SEQUENCE_COMPLETE: String = "complete"
const DROP_SEQUENCE_OUTBOUND: String = "outbound"
const APPROACH_OFFSETS: Dictionary = {
	"NW": Vector2(-180.0, -112.0),
	"NE": Vector2(180.0, -112.0),
	"SW": Vector2(-180.0, 112.0),
	"SE": Vector2(180.0, 112.0),
}
const DROP_UNLOAD_OFFSETS := [
	Vector2(-44.0, 18.0),
	Vector2(-12.0, 6.0),
	Vector2(18.0, -8.0),
	Vector2(46.0, -18.0),
	Vector2(-62.0, 34.0),
	Vector2(64.0, -32.0),
	Vector2(-24.0, 42.0),
	Vector2(26.0, -42.0),
]

signal planning_state_changed(planning_state)

@export var alpha_flow_driver_path: NodePath
@export var bravo_flow_driver_path: NodePath
@export var charlie_flow_driver_path: NodePath
@export var target_marker_path: NodePath
@export var objective_point_path: NodePath
@export var command_feedback_label_path: NodePath
@export var hotkey_legend_label_path: NodePath
@export var move_button_path: NodePath
@export var defend_button_path: NodePath
@export var flank_button_path: NodePath
@export var take_button_path: NodePath

var preview_mode: bool = false

var _current_fireteam_index: int = 0
var _current_phase_index: int = 1
var _current_approach_index: int = 0
var _selected_fireteam_ids: PackedStringArray = []
var _last_command_text: String = "AWAITING INPUT"
var _last_target_position: Vector2 = Vector2.ZERO
var _lz_position: Vector2 = Vector2.ZERO
var _has_lz_position: bool = false
var _is_lz_placement_armed: bool = false
var _is_target_placement_armed: bool = false
var _drop_ship_requested: bool = false
var _drop_ship_cooldown_remaining: float = 0.0
var _card_refresh_time_remaining: float = 0.0
var _drop_sequence_phase: String = ""
var _drop_sequence_units: Array = []
var _drop_sequence_unit_index: int = 0
var _drop_sequence_timer: float = 0.0
var _drop_sequence_position: Vector2 = Vector2.ZERO
var _drop_sequence_fireteam_name: String = "ALL"
var _embarked_unit_ids: Dictionary = {}
var _deployed_unit_ids: Dictionary = {}
var _live_drop_bootstrap_consumed: bool = false
var _character_overlay_open: bool = false
var _character_overlay_unit_id: String = ""
var _selection_press_active: bool = false
var _selection_drag_active: bool = false
var _selection_press_screen_position: Vector2 = Vector2.ZERO
var _selection_drag_screen_position: Vector2 = Vector2.ZERO
var _selection_press_unit_id: String = ""
var _selection_press_ctrl: bool = false
var _order_plans_by_key: Dictionary = {}
var _waypoint_sequence: int = 0
var _waypoint_menu_targets: Array = []
var _focused_waypoint_ref: Dictionary = {}
var _dragged_waypoint_ref: Dictionary = {}
var _dragged_waypoint_press_screen_position: Vector2 = Vector2.ZERO
var _is_dragging_waypoint: bool = false
var _has_dragged_waypoint: bool = false
var _order_visualizer_pending: bool = false
var _phase_execution_by_fireteam: Dictionary = {}
var _active_behavior_profiles_by_fireteam: Dictionary = {}


func _ready() -> void:
	set_process(true)
	set_process_unhandled_input(true)
	_last_target_position = _get_target_position()
	if not _has_lz_position:
		_lz_position = _last_target_position
	_apply_hud_skin()
	_connect_button(move_button_path, Callable(self, "issue_move"))
	_connect_button(defend_button_path, Callable(self, "issue_defend"))
	_connect_button(flank_button_path, Callable(self, "issue_flank"))
	_connect_button(take_button_path, Callable(self, "issue_take"))
	_connect_named_button("../TacticalUI/TopNavPanel/NavMargin/NavRow/HomebaseNavButton", Callable(self, "_on_homebase_nav_pressed"))
	_connect_named_button("../TacticalUI/TopNavPanel/NavMargin/NavRow/FOBNavButton", Callable(self, "_on_fob_nav_pressed"))
	_connect_named_button("../TacticalUI/TopNavPanel/NavMargin/NavRow/MissionNavButton", Callable(self, "_on_mission_nav_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/AllButton", Callable(self, "_on_all_fireteam_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/BlueButton", Callable(self, "_on_blue_fireteam_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoldButton", Callable(self, "_on_gold_fireteam_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton", Callable(self, "_on_target_button_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton", Callable(self, "_on_clear_target_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton", Callable(self, "_on_set_lz_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton", Callable(self, "_on_call_dropship_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/PrevEditPhaseButton", Callable(self, "_on_previous_edit_phase_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/AddPhaseButton", Callable(self, "_on_add_phase_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextEditPhaseButton", Callable(self, "_on_next_edit_phase_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextPhaseButton", Callable(self, "_on_next_phase_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NWButton", Callable(self, "_on_approach_nw_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NEButton", Callable(self, "_on_approach_ne_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SWButton", Callable(self, "_on_approach_sw_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SEButton", Callable(self, "_on_approach_se_pressed"))
	_ensure_character_overlay()
	_ensure_selection_overlay()
	_ensure_waypoint_command_menu()
	_ensure_order_visualizer()
	_hide_legacy_phase_buttons()
	_sync_phase_selection_from_controller()
	_ensure_default_fireteam_selection()
	_refresh_selection_visuals()
	_refresh_order_visuals()
	_refresh_button_state()
	_refresh_world_overlays()
	_update_ui()
	_emit_planning_state_changed()
	_maybe_bootstrap_live_drop()


func _process(delta: float) -> void:
	if _drop_ship_cooldown_remaining > 0.0:
		_drop_ship_cooldown_remaining = maxf(_drop_ship_cooldown_remaining - delta, 0.0)
	_update_drop_sequence(delta)
	_update_active_phase_execution(delta)
	_card_refresh_time_remaining -= delta
	if _card_refresh_time_remaining > 0.0:
		return
	_card_refresh_time_remaining = CARD_REFRESH_INTERVAL_SECONDS
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_edit_planning():
		return

	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT and mouse_button_event.pressed:
			if _is_pointer_over_control() or _is_lz_placement_armed or _is_target_placement_armed:
				return
			if _try_open_waypoint_menu_at_position(mouse_button_event.position):
				get_viewport().set_input_as_handled()
			return

		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
			if _is_pointer_over_control():
				return

			if _try_begin_waypoint_drag(mouse_button_event.position):
				get_viewport().set_input_as_handled()
				return

			if _is_lz_placement_armed:
				if _place_lz_from_screen_position(mouse_button_event.position):
					get_viewport().set_input_as_handled()
				return

			if _is_target_placement_armed:
				if try_place_target_from_screen_position(mouse_button_event.position):
					_is_target_placement_armed = false
					_update_ui()
					get_viewport().set_input_as_handled()
				return

			_begin_selection_interaction(mouse_button_event.position, mouse_button_event.ctrl_pressed)
			get_viewport().set_input_as_handled()
			return

		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and not mouse_button_event.pressed:
			if _finish_waypoint_drag(mouse_button_event.position):
				get_viewport().set_input_as_handled()
				return
			if _finish_selection_interaction(mouse_button_event.position):
				get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion:
		if _update_waypoint_drag((event as InputEventMouseMotion).position):
			get_viewport().set_input_as_handled()
			return
		if _update_selection_drag((event as InputEventMouseMotion).position):
			get_viewport().set_input_as_handled()
			return

	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.physical_keycode:
		KEY_DELETE:
			if _delete_focused_waypoint():
				get_viewport().set_input_as_handled()
		KEY_1:
			issue_move()
			get_viewport().set_input_as_handled()
		KEY_2:
			issue_defend()
			get_viewport().set_input_as_handled()
		KEY_3:
			issue_flank()
			get_viewport().set_input_as_handled()
		KEY_4:
			issue_take()
			get_viewport().set_input_as_handled()
		KEY_Q:
			_change_fireteam(-1)
			get_viewport().set_input_as_handled()
		KEY_E:
			_change_fireteam(1)
			get_viewport().set_input_as_handled()
		KEY_R:
			_change_phase(-1)
			get_viewport().set_input_as_handled()
		KEY_F:
			_change_phase(1)
			get_viewport().set_input_as_handled()
		KEY_G:
			if advance_to_next_phase():
				get_viewport().set_input_as_handled()


func issue_move() -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	return _issue_command("move", "MOVE ORDER")


func issue_defend() -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	return _issue_command("defend", "HOLD / DEFEND")


func issue_flank() -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	return _issue_command("flank", "FLANK")


func issue_take() -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	_snap_target_to_objective()
	return _issue_command("take", "TAKE / ENGAGE")


func set_planning_state(planning_state: Dictionary) -> void:
	var uses_global_phase_state: bool = planning_state.has("selected_phase_index") or planning_state.has("active_phase_index") or planning_state.has("phase_states") or planning_state.has("phase_count")
	if planning_state.has("approach_angle"):
		var approach_angle: String = String(planning_state.get("approach_angle", "NW")).strip_edges().to_upper()
		var angle_index: int = APPROACH_ANGLES.find(approach_angle)
		if angle_index != -1:
			_current_approach_index = angle_index
	if planning_state.has("has_lz_position"):
		_has_lz_position = bool(planning_state.get("has_lz_position", false))
	if planning_state.has("lz_position"):
		var next_position = planning_state.get("lz_position", Vector2.ZERO)
		if typeof(next_position) == TYPE_VECTOR2:
			_lz_position = next_position
	if planning_state.has("drop_ship_requested"):
		_drop_ship_requested = bool(planning_state.get("drop_ship_requested", false))
	if planning_state.has("selected_fireteam"):
		var fireteam_name: String = String(planning_state.get("selected_fireteam", _get_fireteam_name())).strip_edges().to_upper()
		var fireteam_index: int = FIRETEAM_NAMES.find(fireteam_name)
		if fireteam_index != -1:
			_current_fireteam_index = fireteam_index
			_selected_fireteam_ids = _selection_ids_for_index(fireteam_index)
	if planning_state.has("selected_fireteams"):
		_set_selected_fireteams(_sanitize_fireteam_ids(PackedStringArray(Array(planning_state.get("selected_fireteams", [])))), false)
	if planning_state.has("order_plans"):
		_load_order_plans_from_state(Array(planning_state.get("order_plans", [])), 1 if not uses_global_phase_state else 0)
	var phase_controller = _get_phase_controller()
	if phase_controller != null and phase_controller.has_method("load_from_planning_state"):
		phase_controller.call("load_from_planning_state", planning_state, _get_max_order_plan_phase(), not uses_global_phase_state)
	_sync_phase_selection_from_controller()
	_phase_execution_by_fireteam.clear()
	_refresh_button_state()
	_refresh_selection_visuals()
	_refresh_order_visuals()
	_refresh_world_overlays()
	_update_ui()
	_maybe_bootstrap_live_drop()


func get_planning_state() -> Dictionary:
	var planning_state: Dictionary = {
		"has_lz_position": _has_lz_position,
		"lz_position": _lz_position,
		"approach_angle": _get_approach_angle_name(),
		"drop_ship_requested": _drop_ship_requested,
		"selected_fireteam": _get_fireteam_name(),
		"selected_fireteams": Array(_selected_fireteam_ids),
		"selected_phase": _get_phase_name(),
		"order_plans": _serialize_order_plans(),
	}
	var phase_controller = _get_phase_controller()
	if phase_controller != null and phase_controller.has_method("build_planning_state_fragment"):
		planning_state.merge(Dictionary(phase_controller.call("build_planning_state_fragment")), true)
	return planning_state


func add_global_phase() -> int:
	var phase_controller = _get_phase_controller()
	if phase_controller == null or not phase_controller.has_method("add_phase"):
		return -1
	var next_phase_index: int = int(phase_controller.call("add_phase"))
	_current_phase_index = int(phase_controller.call("set_selected_phase_index", next_phase_index))
	_last_command_text = "PHASE %s ADDED" % _get_phase_name()
	_refresh_button_state()
	_refresh_order_visuals()
	_update_ui()
	_emit_planning_state_changed()
	return next_phase_index


func advance_to_next_phase() -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	if not _can_issue_local_commands():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return false
	var phase_controller = _get_phase_controller()
	if phase_controller == null or not phase_controller.has_method("advance_to_next_phase"):
		return false
	var next_phase_index: int = int(phase_controller.call("advance_to_next_phase"))
	if next_phase_index < 0:
		_last_command_text = "NO NEXT PHASE"
		_update_ui()
		return false
	_start_active_phase_execution(next_phase_index)
	_refresh_button_state()
	_refresh_order_visuals()
	_update_ui()
	_emit_planning_state_changed()
	return true


func get_phase_state_snapshot() -> Dictionary:
	var phase_controller = _get_phase_controller()
	if phase_controller == null:
		return {}
	return {
		"selected_phase_index": int(phase_controller.call("get_selected_phase_index")),
		"active_phase_index": int(phase_controller.call("get_active_phase_index")),
		"phase_count": int(phase_controller.call("get_phase_count")),
		"phase_states": Array(phase_controller.call("get_phase_states_snapshot")),
	}


func get_active_behavior_profile(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or not _active_behavior_profiles_by_fireteam.has(normalized_fireteam_id):
		return {}
	var profile = _active_behavior_profiles_by_fireteam[normalized_fireteam_id]
	if profile == null:
		return {}
	if profile.has_method("to_dict"):
		return profile.to_dict()
	if typeof(profile) == TYPE_DICTIONARY:
		return Dictionary(profile).duplicate(true)
	return {}


func get_active_behavior_profiles_snapshot() -> Array:
	var result: Array = []
	var fireteam_ids: Array = _active_behavior_profiles_by_fireteam.keys()
	fireteam_ids.sort()
	for fireteam_id in fireteam_ids:
		var profile_dict: Dictionary = get_active_behavior_profile(String(fireteam_id))
		if profile_dict.is_empty():
			continue
		result.append(profile_dict)
	return result


func get_current_fireteam_lead_unit(fireteam_id: String):
	return _resolve_fireteam_leader_for_behavior(fireteam_id)


func try_place_target_from_screen_position(screen_position: Vector2) -> bool:
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	if target_marker == null:
		return false

	var world_position: Vector2 = _screen_to_world_position(screen_position)
	var clamped_position: Vector2 = _clamp_world_position_to_viewport(world_position)
	target_marker.global_position = clamped_position
	_last_target_position = clamped_position
	_last_command_text = "TARGET SET @ %s" % _format_world_position(clamped_position)
	_update_ui()
	return true


func _place_lz_from_screen_position(screen_position: Vector2) -> bool:
	var world_position: Vector2 = _screen_to_world_position(screen_position)
	_lz_position = _clamp_world_position_to_viewport(world_position)
	_has_lz_position = true
	_is_lz_placement_armed = false
	_last_command_text = "LZ SET %s @ %s" % [_get_approach_angle_name(), _format_world_position(_lz_position)]
	_refresh_world_overlays()
	_update_ui()
	_emit_planning_state_changed()
	return true


func _issue_command(command_type: String, display_text: String) -> bool:
	if not _can_issue_local_commands():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return false

	if _selected_fireteam_ids.is_empty():
		_last_command_text = "NO FIRETEAM SELECTED"
		_update_ui()
		return false

	var issued_count: int = 0
	for driver in _get_active_flow_drivers():
		if driver == null or not driver.has_method("issue_command"):
			continue

		if bool(driver.call("issue_command", command_type, _current_phase_index)):
			issued_count += 1

	if issued_count == 0:
		_last_command_text = "%s FAILED" % display_text
		_update_ui()
		return false

	_last_command_text = "%s (%s)" % [display_text, _get_fireteam_name()]
	_update_ui()
	return true


func _change_fireteam(delta: int) -> void:
	var next_index: int = wrapi(_current_fireteam_index + delta, 0, FIRETEAM_NAMES.size())
	_set_selected_fireteams(_selection_ids_for_index(next_index))


func _change_phase(delta: int) -> void:
	var phase_controller = _get_phase_controller()
	if phase_controller == null or not phase_controller.has_method("cycle_selected_phase"):
		_current_phase_index = maxi(_current_phase_index + delta, 1)
	else:
		_current_phase_index = int(phase_controller.call("cycle_selected_phase", delta))
	_refresh_order_visuals()
	_update_ui()
	_emit_planning_state_changed()


func _select_fireteam_by_name(fireteam_name: String) -> void:
	var normalized_name: String = fireteam_name.strip_edges().to_upper()
	var next_index: int = FIRETEAM_NAMES.find(normalized_name)
	if next_index == -1:
		return
	_set_selected_fireteams(_selection_ids_for_index(next_index))


func _select_phase_by_name(phase_name: String) -> void:
	var normalized_name: String = phase_name.strip_edges().to_upper()
	var next_index: int = -1
	if normalized_name.begins_with("P"):
		next_index = maxi(int(normalized_name.substr(1)), 1)
	else:
		var legacy_index: int = LEGACY_PHASE_NAMES.find(normalized_name)
		if legacy_index != -1:
			next_index = legacy_index + 1
	if next_index == -1:
		return
	var phase_controller = _get_phase_controller()
	if phase_controller != null and phase_controller.has_method("set_selected_phase_index"):
		_current_phase_index = int(phase_controller.call("set_selected_phase_index", next_index))
	else:
		_current_phase_index = next_index
	_refresh_order_visuals()
	_update_ui()
	_emit_planning_state_changed()


func _select_approach_angle(angle_name: String) -> void:
	var normalized_name: String = angle_name.strip_edges().to_upper()
	var next_index: int = APPROACH_ANGLES.find(normalized_name)
	if next_index == -1:
		return
	_current_approach_index = next_index
	_last_command_text = "APPROACH %s" % normalized_name
	_refresh_world_overlays()
	_update_ui()
	_emit_planning_state_changed()


func _on_homebase_nav_pressed() -> void:
	_navigate_to_meta_view("homebase")


func _on_fob_nav_pressed() -> void:
	_navigate_to_meta_view("fob")


func _on_mission_nav_pressed() -> void:
	_navigate_to_meta_view("mission")


func _on_all_fireteam_pressed() -> void:
	_select_fireteam_by_name("ALL")


func _on_blue_fireteam_pressed() -> void:
	_select_fireteam_by_name("BLUE")


func _on_gold_fireteam_pressed() -> void:
	_select_fireteam_by_name("GOLD")


func _on_target_button_pressed() -> void:
	_is_lz_placement_armed = false
	_is_target_placement_armed = not _is_target_placement_armed
	_last_command_text = "CLICK MAP FOR TARGET" if _is_target_placement_armed else "TARGET PLACEMENT CANCELLED"
	_update_ui()


func _on_previous_edit_phase_pressed() -> void:
	_change_phase(-1)


func _on_add_phase_pressed() -> void:
	add_global_phase()


func _on_next_edit_phase_pressed() -> void:
	_change_phase(1)


func _on_next_phase_pressed() -> void:
	advance_to_next_phase()


func _on_clear_target_pressed() -> void:
	_snap_target_to_objective()
	_last_command_text = "TARGET RESET TO OBJECTIVE"
	_update_ui()


func _on_set_lz_pressed() -> void:
	if not _can_edit_planning():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return
	_is_lz_placement_armed = not _is_lz_placement_armed
	_last_command_text = "CLICK MAP FOR LZ" if _is_lz_placement_armed else "LZ PLACEMENT CANCELLED"
	_update_ui()


func _on_call_dropship_pressed() -> void:
	if not _can_edit_planning():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return
	if not preview_mode and _drop_ship_cooldown_remaining > 0.0:
		_last_command_text = "DROP COOLDOWN %.1FS" % _drop_ship_cooldown_remaining
		_update_ui()
		return
	if not _has_lz_position:
		_last_command_text = "SET LZ BEFORE DROP CALL"
		_update_ui()
		return
	if preview_mode:
		_drop_ship_requested = true
		_last_command_text = "DROP SHIP CALLED %s" % _get_approach_angle_name()
	elif _is_drop_sequence_active():
		_last_command_text = "DROP ALREADY ACTIVE"
	elif _try_start_drop_sequence():
		_drop_ship_requested = true
		_last_command_text = "DROP SHIP INBOUND %s" % _get_approach_angle_name()
	else:
		_drop_ship_requested = false
		_last_command_text = "NO DROP TEAM AVAILABLE"
	_refresh_world_overlays()
	_update_ui()
	_emit_planning_state_changed()


func _on_approach_nw_pressed() -> void:
	_select_approach_angle("NW")


func _on_approach_ne_pressed() -> void:
	_select_approach_angle("NE")


func _on_approach_sw_pressed() -> void:
	_select_approach_angle("SW")


func _on_approach_se_pressed() -> void:
	_select_approach_angle("SE")


func _navigate_to_meta_view(target_view: String) -> void:
	var mission_root: Node = get_parent()
	if mission_root == null:
		_last_command_text = "META NAV UNAVAILABLE"
		_update_ui()
		return

	var mission_host: Node = mission_root.get_parent()
	if mission_host == null:
		_last_command_text = "META NAV UNAVAILABLE"
		_update_ui()
		return

	var meta_root: Node = mission_host.get_parent()
	if meta_root == null:
		_last_command_text = "META NAV UNAVAILABLE"
		_update_ui()
		return

	match target_view:
		"homebase":
			if meta_root.has_method("_show_homebase"):
				meta_root.call("_show_homebase")
				return
		"fob":
			if meta_root.has_method("_show_fob"):
				meta_root.call("_show_fob")
				return
		"mission":
			if meta_root.has_method("_show_mission"):
				meta_root.call("_show_mission")
				return

	_last_command_text = "META NAV UNAVAILABLE"
	_update_ui()


func _get_active_flow_drivers() -> Array:
	return _get_flow_drivers_for_fireteams(_selected_fireteam_ids)


func _get_flow_drivers_for_fireteam(fireteam_id: String) -> Array:
	return _get_flow_drivers_for_fireteams(PackedStringArray([fireteam_id.strip_edges().to_lower()]))


func _get_flow_drivers_for_fireteams(fireteam_ids: PackedStringArray) -> Array:
	var alpha_driver = get_node_or_null(alpha_flow_driver_path)
	var bravo_driver = get_node_or_null(bravo_flow_driver_path)
	var charlie_driver = get_node_or_null(charlie_flow_driver_path)
	var drivers: Array = []
	if fireteam_ids.has("blue"):
		drivers.append(alpha_driver)
		drivers.append(bravo_driver)
	if fireteam_ids.has("gold"):
		drivers.append(charlie_driver)
	return drivers


func _get_fireteam_name() -> String:
	if _selected_fireteam_ids.is_empty():
		return "NONE"
	if _is_all_fireteams_selected():
		return "ALL"
	if _selected_fireteam_ids.has("blue"):
		return "BLUE"
	if _selected_fireteam_ids.has("gold"):
		return "GOLD"
	return FIRETEAM_NAMES[_current_fireteam_index]


func _get_phase_name() -> String:
	var phase_controller = _get_phase_controller()
	if phase_controller != null and phase_controller.has_method("get_selected_phase_name"):
		return String(phase_controller.call("get_selected_phase_name"))
	return "P%d" % maxi(_current_phase_index, 1)


func _get_approach_angle_name() -> String:
	return APPROACH_ANGLES[_current_approach_index]


func set_tactical_ui_visible(is_visible: bool) -> void:
	for path in [
		"../TacticalUI/MissionTint",
		"../TacticalUI/MissionIdentityPanel",
		"../TacticalUI/TopNavPanel",
		"../TacticalUI/BottomDock",
	]:
		var canvas_item := get_node_or_null(path) as CanvasItem
		if canvas_item != null:
			canvas_item.visible = is_visible
	var overlay := get_node_or_null("../TacticalUI/CharacterOverlay") as Control
	if overlay != null:
		overlay.visible = is_visible and _character_overlay_open


func _update_ui() -> void:
	var command_feedback_label := get_node_or_null(command_feedback_label_path) as Label
	if command_feedback_label != null:
		command_feedback_label.text = "TEAM %s | PHASE %s\nTARGET %s\nLAST %s" % [
			_get_fireteam_name(),
			_get_phase_name(),
			_build_target_text(),
			_last_command_text,
		]

	var hotkey_legend_label := get_node_or_null(hotkey_legend_label_path) as Label
	if hotkey_legend_label != null:
		if preview_mode:
			hotkey_legend_label.text = "PLANNING VIEW | RMB adds waypoint menu | LMB drags waypoint | DEL removes focused waypoint"
		else:
			hotkey_legend_label.text = HOTKEY_LEGEND if _can_issue_local_commands() else "OBSERVER MODE | Host controls mission orders in multiplayer V1"

	var fireteam_status_label := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamStatusLabel") as Label
	if fireteam_status_label != null:
		fireteam_status_label.text = _build_fireteam_status_text()

	var strategic_status_label := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel") as Label
	if strategic_status_label != null:
		strategic_status_label.text = _build_strategic_status_text()

	var phase_status_label := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseStatusLabel") as Label
	if phase_status_label != null:
		phase_status_label.text = _build_phase_status_text()

	var phase_list_label := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseListLabel") as Label
	if phase_list_label != null:
		phase_list_label.text = _build_phase_list_text()

	var set_lz_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton") as Button
	if set_lz_button != null:
		set_lz_button.text = "Click Map..." if _is_lz_placement_armed else "Set LZ"

	var target_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton") as Button
	if target_button != null:
		target_button.text = "Click Map..." if _is_target_placement_armed else "Target"

	var call_dropship_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton") as Button
	if call_dropship_button != null:
		if not preview_mode and _drop_ship_cooldown_remaining > 0.0 and not _is_drop_sequence_active():
			call_dropship_button.text = "Cooldown %ds" % int(ceil(_drop_ship_cooldown_remaining))
		else:
			match _drop_sequence_phase:
				DROP_SEQUENCE_INBOUND:
					call_dropship_button.text = "Inbound"
				DROP_SEQUENCE_LANDED:
					call_dropship_button.text = "Landed"
				DROP_SEQUENCE_UNLOADING:
					call_dropship_button.text = "Deboarding"
				DROP_SEQUENCE_OUTBOUND:
					call_dropship_button.text = "Outbound"
				DROP_SEQUENCE_COMPLETE:
					call_dropship_button.text = "Drop Complete"
				_:
					call_dropship_button.text = "Drop Planned" if _drop_ship_requested else "Call Drop"

	_refresh_dynamic_button_styles()
	_refresh_world_overlays()
	_refresh_fireteam_cards()
	if _character_overlay_open:
		_update_character_overlay()


func _refresh_fireteam_cards() -> void:
	var card_row := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow") as HBoxContainer
	if card_row == null:
		return

	for child in card_row.get_children():
		child.queue_free()

	var units: Array = _get_selected_friendly_units(true)
	if units.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Kein aktives Fireteam im Sichtbereich."
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		empty_label.custom_minimum_size = Vector2(280.0, 58.0)
		META_UI_SKIN_SCRIPT.style_body_label(empty_label, 11)
		card_row.add_child(empty_label)
		return

	for unit in units:
		var card = NPC_COMPACT_CARD_SCENE.instantiate()
		card.custom_minimum_size = Vector2(156.0, 58.0)
		card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		card.call(
			"setup_from_profile",
			_build_profile_from_unit(unit),
			{
				"source_context": "mission_tactical",
				"compact_mode": true,
				"drag_enabled": false,
				"show_lead_indicator": true,
				"is_lead": bool(unit.get("is_fireteam_lead")),
				"selected": _is_unit_selected(unit),
			}
		)
		if not card.card_open_requested.is_connected(_on_fireteam_card_open_requested):
			card.card_open_requested.connect(_on_fireteam_card_open_requested)
		card_row.add_child(card)


func _build_profile_from_unit(unit: Node) -> RefCounted:
	return META_UNIT_PROFILE_BUILDER_SCRIPT.build_from_test_unit(
		unit,
		{
			"secondary_text": _build_unit_secondary_text(unit),
			"status_text": _build_tactical_character_status_text(unit),
		}
	)


func _build_tactical_character_status_text(unit: Node) -> String:
	if unit == null:
		return "Taktische Daten nicht verfuegbar"
	var fireteam_label: String = String(unit.call("get_fireteam_id")).strip_edges().to_upper()
	if fireteam_label.is_empty():
		fireteam_label = "UNASSIGNED"
	var state_bits: PackedStringArray = ["Fireteam %s" % fireteam_label]
	var unit_id: String = String(unit.call("get_unit_id"))
	if _embarked_unit_ids.has(unit_id):
		state_bits.append("Embarked")
	elif _deployed_unit_ids.has(unit_id):
		state_bits.append("Deployed")
	else:
		state_bits.append(String(unit.call("get_vital_state")).capitalize())
	state_bits.append("Phase %s" % _get_phase_name())
	return " | ".join(state_bits)


func _on_fireteam_card_open_requested(unit_id: String, _profile, _source_context: String) -> void:
	_open_character_overlay(unit_id)


func _open_character_overlay(unit_id: String) -> void:
	_character_overlay_unit_id = unit_id.strip_edges()
	_character_overlay_open = true
	_update_character_overlay()
	var overlay := get_node_or_null("../TacticalUI/CharacterOverlay") as Control
	if overlay != null:
		overlay.visible = true


func _close_character_overlay() -> void:
	_character_overlay_open = false
	var overlay := get_node_or_null("../TacticalUI/CharacterOverlay") as Control
	if overlay != null:
		overlay.visible = false


func _update_character_overlay() -> void:
	var host := _get_character_overlay_host()
	if host == null:
		return
	var profile = null
	var unit := _find_friendly_unit_by_id(_character_overlay_unit_id)
	var render_options: Dictionary = {}
	if unit != null:
		profile = _build_profile_from_unit(unit)
		render_options["loadout_text"] = _build_tactical_loadout_text(unit)
		render_options["fireteam_text"] = _build_tactical_fireteam_text(unit)
	CHARACTER_SHEET_VIEW_SCRIPT.render(host, profile, render_options)


func _find_friendly_unit_by_id(unit_id: String) -> Node:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return null
	var mission_root: Node = get_parent()
	if mission_root == null:
		return null
	for child in mission_root.get_children():
		if not child.has_method("get_team_id") or not child.has_method("get_unit_id"):
			continue
		if String(child.call("get_team_id")).strip_edges() != FRIENDLY_TEAM_ID:
			continue
		if String(child.call("get_unit_id")).strip_edges() == normalized_unit_id:
			return child
	return null


func _get_character_overlay_host() -> VBoxContainer:
	var overlay := get_node_or_null("../TacticalUI/CharacterOverlay") as Control
	if overlay == null:
		return null
	return overlay.get_node_or_null("OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox") as VBoxContainer


func _ensure_character_overlay() -> void:
	var tactical_ui := get_node_or_null("../TacticalUI") as CanvasLayer
	if tactical_ui == null or tactical_ui.get_node_or_null("CharacterOverlay") != null:
		return

	var overlay := Control.new()
	overlay.name = "CharacterOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	tactical_ui.add_child(overlay)

	var shade := ColorRect.new()
	shade.name = "OverlayShade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.color = Color(0.02, 0.05, 0.05, 0.72)
	overlay.add_child(shade)

	var panel := PanelContainer.new()
	panel.name = "OverlayPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -210.0
	panel.offset_top = -300.0
	panel.offset_right = 210.0
	panel.offset_bottom = 300.0
	overlay.add_child(panel)
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "frame")

	var margin := MarginContainer.new()
	margin.name = "OverlayMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var overlay_vbox := VBoxContainer.new()
	overlay_vbox.name = "OverlayVBox"
	overlay_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(overlay_vbox)

	var header_row := HBoxContainer.new()
	header_row.name = "OverlayHeaderRow"
	header_row.add_theme_constant_override("separation", 8)
	overlay_vbox.add_child(header_row)

	var header_label := Label.new()
	header_label.name = "OverlayHeaderLabel"
	header_label.text = "Character Sheet"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_header_label(header_label, 12)
	header_row.add_child(header_label)

	var close_button := Button.new()
	close_button.name = "CloseOverlayButton"
	close_button.text = "Close"
	META_UI_SKIN_SCRIPT.style_tactical_button(close_button, false)
	if not close_button.pressed.is_connected(_close_character_overlay):
		close_button.pressed.connect(_close_character_overlay)
	header_row.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.name = "OverlayScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay_vbox.add_child(scroll)

	var content_vbox := VBoxContainer.new()
	content_vbox.name = "OverlayContentVBox"
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(content_vbox)


func _build_unit_secondary_text(unit: Node) -> String:
	var parts: PackedStringArray = []
	var unit_id: String = String(unit.call("get_unit_id"))
	if bool(unit.get("is_fireteam_lead")):
		parts.append("Lead")
	if _embarked_unit_ids.has(unit_id):
		parts.append("Embarked")
	elif _deployed_unit_ids.has(unit_id):
		parts.append("Deployed")
	else:
		parts.append(String(unit.call("get_vital_state")).capitalize())
	var callsign: String = String(unit.call("get_callsign")).strip_edges()
	if not callsign.is_empty():
		parts.append(callsign)
	return " | ".join(parts)


func _build_tactical_loadout_text(unit: Node) -> String:
	if unit == null or not unit.has_method("get_unit_id"):
		return "standard kit"

	var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
	var mission_setup: Node = get_node_or_null("../MissionSetup")
	if mission_setup != null:
		var member_loadouts: Dictionary = mission_setup.get("member_loadouts") if typeof(mission_setup.get("member_loadouts")) == TYPE_DICTIONARY else {}
		if member_loadouts.has(unit_id) and typeof(member_loadouts.get(unit_id)) == TYPE_DICTIONARY:
			var loadout: Dictionary = member_loadouts[unit_id]
			return CHARACTER_SHEET_FORMATTER_SCRIPT.build_loadout_text_from_member_loadout(loadout, "standard kit")

	var armor_id: String = String(unit.call("get_armor_id")).strip_edges() if unit.has_method("get_armor_id") else "medium"
	var weapon_1_id: String = String(unit.call("get_weapon_1_id")).strip_edges() if unit.has_method("get_weapon_1_id") else "rifle"
	var weapon_2_id: String = String(unit.call("get_weapon_2_id")).strip_edges() if unit.has_method("get_weapon_2_id") else "rifle"
	return CHARACTER_SHEET_FORMATTER_SCRIPT.build_loadout_text_from_ids(armor_id, weapon_1_id, weapon_2_id, "standard kit")


func _build_tactical_fireteam_text(unit: Node) -> String:
	if unit == null or not unit.has_method("get_fireteam_id"):
		return "UNASSIGNED"
	var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
	var mission_setup: Node = get_node_or_null("../MissionSetup")
	if mission_setup != null:
		var selected_unit_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_unit_ids"))
		var selected_fireteam_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_fireteam_ids"))
		var unit_index: int = selected_unit_ids.find(unit_id)
		if unit_index >= 0 and unit_index < selected_fireteam_ids.size():
			return CHARACTER_SHEET_FORMATTER_SCRIPT.format_fireteam_label(String(selected_fireteam_ids[unit_index]))
	var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
	return CHARACTER_SHEET_FORMATTER_SCRIPT.format_fireteam_label(fireteam_id)


func _get_selected_friendly_units(include_hidden: bool = true) -> Array:
	if _selected_fireteam_ids.is_empty():
		return []

	var mission_root: Node = get_parent()
	if mission_root == null:
		return []

	var selected_units: Array = []
	var selected_fireteam_id: String = _get_selected_fireteam_id()
	for child in mission_root.get_children():
		if not child.has_method("get_team_id") or not child.has_method("get_unit_id") or not child.has_method("get_fireteam_id"):
			continue
		if String(child.call("get_team_id")).strip_edges() != FRIENDLY_TEAM_ID:
			continue
		var unit_id: String = String(child.call("get_unit_id"))
		if not include_hidden and child is CanvasItem and not (child as CanvasItem).visible and not _embarked_unit_ids.has(unit_id):
			continue
		var child_fireteam_id: String = String(child.call("get_fireteam_id")).strip_edges().to_lower()
		if not selected_fireteam_id.is_empty() and child_fireteam_id != selected_fireteam_id:
			continue
		if selected_fireteam_id.is_empty() and not _selected_fireteam_ids.has(child_fireteam_id):
			continue
		selected_units.append(child)

	selected_units.sort_custom(Callable(self, "_sort_unit_nodes_for_cards"))
	return selected_units


func _sort_unit_nodes_for_cards(a: Node, b: Node) -> bool:
	var a_is_lead: bool = bool(a.get("is_fireteam_lead"))
	var b_is_lead: bool = bool(b.get("is_fireteam_lead"))
	if a_is_lead != b_is_lead:
		return a_is_lead and not b_is_lead
	return String(a.call("get_display_name")) < String(b.call("get_display_name"))


func _get_selected_fireteam_id() -> String:
	if _selected_fireteam_ids.size() == 1:
		return String(_selected_fireteam_ids[0])
	return ""


func _build_fireteam_status_text() -> String:
	if _selected_fireteam_ids.is_empty():
		return "NO SELECTION | 0 Karten | Click unit or drag leaders"

	var units: Array = _get_selected_friendly_units(true)
	var planned_waypoint_count: int = _count_selected_phase_waypoints()
	if units.is_empty():
		return "%s | %d Wegpunkte | keine Einheiten aktiv" % [_get_fireteam_name(), planned_waypoint_count]

	var lead_name: String = "-"
	var embarked_count: int = 0
	var deployed_count: int = 0
	for unit in units:
		var unit_id: String = String(unit.call("get_unit_id"))
		if _embarked_unit_ids.has(unit_id):
			embarked_count += 1
		elif _deployed_unit_ids.has(unit_id):
			deployed_count += 1
		if lead_name == "-" and bool(unit.get("is_fireteam_lead")):
			lead_name = String(unit.call("get_display_name"))
	if lead_name == "-":
		lead_name = String((units[0] as Node).call("get_display_name"))
	var drop_state_text: String = "Lead %s" % lead_name
	if embarked_count > 0:
		drop_state_text = "%d embarked | %d deployed | Lead %s" % [embarked_count, deployed_count, lead_name]
	elif deployed_count > 0:
		drop_state_text = "%d deployed | Lead %s" % [deployed_count, lead_name]
	return "%s | %d Karten | %d Wegpunkte | %s" % [_get_fireteam_name(), units.size(), planned_waypoint_count, drop_state_text]


func _build_strategic_status_text() -> String:
	var lz_text: String = "LZ offen" if not _has_lz_position else "LZ %s" % _format_world_position(_lz_position)
	var ship_text: String = "Drop wartend"
	if _drop_ship_requested:
		ship_text = "Drop aus %s angefordert" % _get_approach_angle_name()
	if not preview_mode and _drop_ship_cooldown_remaining > 0.0 and _drop_sequence_phase.is_empty():
		ship_text = "Drop bereit in %.1fs" % _drop_ship_cooldown_remaining
	if _drop_sequence_phase == DROP_SEQUENCE_INBOUND:
		ship_text = "Dropship inbound"
	elif _drop_sequence_phase == DROP_SEQUENCE_LANDED:
		ship_text = "Dropship gelandet"
	elif _drop_sequence_phase == DROP_SEQUENCE_UNLOADING:
		ship_text = "Deboarding %d/%d" % [_drop_sequence_unit_index, _drop_sequence_units.size()]
	elif _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND:
		ship_text = "Dropship outbound"
	elif _drop_sequence_phase == DROP_SEQUENCE_COMPLETE:
		ship_text = "Fireteam entladen"
	return "%s\nApproach %s\n%s" % [lz_text, _get_approach_angle_name(), ship_text]


func _build_phase_status_text() -> String:
	var phase_controller = _get_phase_controller()
	if phase_controller == null:
		return "Active P0 PRE | Edit %s" % _get_phase_name()
	return "Active %s | Edit %s" % [
		String(phase_controller.call("get_active_phase_name")),
		String(phase_controller.call("get_selected_phase_name")),
	]


func _build_phase_list_text() -> String:
	var phase_controller = _get_phase_controller()
	if phase_controller == null or not phase_controller.has_method("get_phase_list_text"):
		return "Phases P0 PRE | %s" % _get_phase_name()
	return "Phases %s" % String(phase_controller.call("get_phase_list_text"))


func _connect_button(button_path: NodePath, callback: Callable) -> void:
	var button := get_node_or_null(button_path) as BaseButton
	if button == null:
		return
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _connect_named_button(button_path: String, callback: Callable) -> void:
	var button := get_node_or_null(button_path) as BaseButton
	if button == null:
		return
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _is_pointer_over_control() -> bool:
	return get_viewport().gui_get_hovered_control() != null


func _get_target_position() -> Vector2:
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	if target_marker == null:
		return Vector2.ZERO
	return target_marker.global_position


func _build_target_text() -> String:
	var target_position: Vector2 = _get_target_position()
	_last_target_position = target_position
	return _format_world_position(target_position)


func _format_world_position(world_position: Vector2) -> String:
	return "%d, %d" % [int(round(world_position.x)), int(round(world_position.y))]


func _screen_to_world_position(screen_position: Vector2) -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_position


func _clamp_world_position_to_viewport(world_position: Vector2) -> Vector2:
	var visible_rect: Rect2 = get_viewport().get_visible_rect()
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var inverse_transform: Transform2D = canvas_transform.affine_inverse()
	var world_a: Vector2 = inverse_transform * visible_rect.position
	var world_b: Vector2 = inverse_transform * visible_rect.end
	var min_x: float = minf(world_a.x, world_b.x)
	var max_x: float = maxf(world_a.x, world_b.x)
	var min_y: float = minf(world_a.y, world_b.y)
	var max_y: float = maxf(world_a.y, world_b.y)
	return Vector2(
		clampf(world_position.x, min_x, max_x),
		clampf(world_position.y, min_y, max_y)
	)


func _snap_target_to_objective() -> void:
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	var objective_marker := get_node_or_null(objective_point_path) as Node2D
	if target_marker == null or objective_marker == null:
		return

	target_marker.global_position = objective_marker.global_position
	_last_target_position = objective_marker.global_position


func _refresh_button_state() -> void:
	var command_buttons: Array = [
		move_button_path,
		defend_button_path,
		flank_button_path,
		take_button_path,
	]
	for button_path in command_buttons:
		var command_button := get_node_or_null(button_path) as BaseButton
		if command_button == null:
			continue
		command_button.disabled = preview_mode or not _can_issue_local_commands() or _selected_fireteam_ids.is_empty()

	for path in [
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/PrevEditPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/AddPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextEditPhaseButton",
	]:
		var utility_button := get_node_or_null(path) as BaseButton
		if utility_button == null:
			continue
		utility_button.disabled = not _can_edit_planning()

	var call_dropship_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton") as BaseButton
	if call_dropship_button != null:
		call_dropship_button.disabled = not _can_edit_planning() or (not preview_mode and _drop_ship_cooldown_remaining > 0.0)

	var next_phase_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextPhaseButton") as BaseButton
	if next_phase_button != null:
		next_phase_button.disabled = preview_mode or not _can_issue_local_commands() or not _has_pending_global_phase()


func _refresh_world_overlays() -> void:
	var lz_marker := get_node_or_null("../LZMarker") as Node2D
	if lz_marker != null:
		lz_marker.visible = _has_lz_position
		if _has_lz_position:
			lz_marker.global_position = _lz_position

	var dropship_marker := get_node_or_null("../DropshipPlanMarker") as Node2D
	if dropship_marker == null:
		return

	if not _has_lz_position or (not _drop_ship_requested and _drop_sequence_phase.is_empty()):
		dropship_marker.visible = false
		return

	var offset: Vector2 = _get_drop_approach_offset()
	dropship_marker.visible = true
	if _drop_sequence_phase == DROP_SEQUENCE_INBOUND or _drop_sequence_phase == DROP_SEQUENCE_LANDED or _drop_sequence_phase == DROP_SEQUENCE_UNLOADING or _drop_sequence_phase == DROP_SEQUENCE_COMPLETE or _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND:
		dropship_marker.global_position = _drop_sequence_position
	else:
		dropship_marker.global_position = _lz_position + offset
	var approach_line := dropship_marker.get_node_or_null("ApproachLine") as Line2D
	if approach_line != null:
		approach_line.clear_points()
		var line_delta: Vector2 = _lz_position - dropship_marker.global_position
		if line_delta.length_squared() > 4.0:
			approach_line.add_point(Vector2.ZERO)
			approach_line.add_point(line_delta)


func _refresh_dynamic_button_styles() -> void:
	for path in [
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/HomebaseNavButton",
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/FOBNavButton",
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/MissionNavButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/HoldButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FlankButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TakeButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/AllButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/BlueButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoldButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/PrevEditPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/AddPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextEditPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NWButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NEButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SWButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SEButton",
	]:
		var button := get_node_or_null(path) as Button
		if button != null:
			META_UI_SKIN_SCRIPT.style_tactical_button(button, false)

	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/TopNavPanel/NavMargin/NavRow/MissionNavButton") as Button, true)
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/AllButton") as Button, _is_all_fireteams_selected())
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/BlueButton") as Button, _selected_fireteam_ids.has("blue"))
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoldButton") as Button, _selected_fireteam_ids.has("gold"))
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton") as Button, _is_target_placement_armed)
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton") as Button, _is_lz_placement_armed)
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton") as Button, _drop_ship_requested)
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextPhaseButton") as Button, not preview_mode and _can_issue_local_commands() and not _phase_execution_by_fireteam.is_empty())
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/%sButton" % _get_approach_angle_name()) as Button, true)


func _apply_hud_skin() -> void:
	for path in [
		"../TacticalUI/MissionIdentityPanel",
		"../TacticalUI/TopNavPanel",
		"../TacticalUI/BottomDock",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel",
		"../TacticalUI/CharacterOverlay/OverlayPanel",
	]:
		var panel := get_node_or_null(path) as PanelContainer
		if panel == null:
			continue
		META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "frame")

	META_UI_SKIN_SCRIPT.style_tactical_panel(get_node_or_null("../TacticalUI/TopNavPanel") as PanelContainer, "header")
	META_UI_SKIN_SCRIPT.style_tactical_panel(get_node_or_null("../TacticalUI/MissionIdentityPanel") as PanelContainer, "header")
	META_UI_SKIN_SCRIPT.style_tactical_panel(get_node_or_null("../TacticalUI/BottomDock") as PanelContainer, "panel")

	for path in [
		"../TacticalUI/MissionIdentityPanel/MissionIdentityMargin/MissionIdentityVBox/MissionIdentityHeaderLabel",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandHeaderLabel",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicHeaderLabel",
		"../TacticalUI/CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/OverlayHeaderLabel",
	]:
		META_UI_SKIN_SCRIPT.style_header_label(get_node_or_null(path), 12)

	for path in [
		"../TacticalUI/MissionIdentityPanel/MissionIdentityMargin/MissionIdentityVBox/MissionIdentityBodyLabel",
		command_feedback_label_path,
		hotkey_legend_label_path,
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamStatusLabel",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel",
	]:
		META_UI_SKIN_SCRIPT.style_body_label(get_node_or_null(path), 10)

	_refresh_dynamic_button_styles()
	_refresh_button_state()
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/CloseOverlayButton") as Button, false)


func _can_issue_local_commands() -> bool:
	var simulation_root = get_node_or_null("../SimulationRoot")
	if simulation_root == null:
		return true

	if not bool(simulation_root.get("is_server_authoritative")):
		return true

	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return true

	return multiplayer.is_server()


func _can_edit_planning() -> bool:
	if preview_mode:
		return true
	return _can_issue_local_commands()


func _emit_planning_state_changed() -> void:
	planning_state_changed.emit(get_planning_state())


func get_selected_fireteam_ids() -> PackedStringArray:
	return _selected_fireteam_ids.duplicate()


func _ensure_default_fireteam_selection() -> void:
	if not _selected_fireteam_ids.is_empty():
		return
	_set_selected_fireteams(_get_available_fireteam_ids(), false)


func _ensure_selection_overlay() -> void:
	var tactical_ui := get_node_or_null("../TacticalUI") as CanvasLayer
	if tactical_ui == null or tactical_ui.get_node_or_null("SelectionDragOverlay") != null:
		return

	var selection_overlay := ColorRect.new()
	selection_overlay.name = "SelectionDragOverlay"
	selection_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_overlay.visible = false
	selection_overlay.color = Color(0.52, 0.88, 1.0, 0.18)
	selection_overlay.z_index = 20
	tactical_ui.add_child(selection_overlay)


func _begin_selection_interaction(screen_position: Vector2, ctrl_pressed: bool) -> void:
	_selection_press_active = true
	_selection_drag_active = false
	_selection_press_screen_position = screen_position
	_selection_drag_screen_position = screen_position
	_selection_press_ctrl = ctrl_pressed
	var unit = _find_selectable_unit_at_screen_position(screen_position)
	_selection_press_unit_id = String(unit.call("get_unit_id")) if unit != null else ""
	_update_selection_overlay(Rect2())


func _update_selection_drag(screen_position: Vector2) -> bool:
	if not _selection_press_active or _is_lz_placement_armed or _is_target_placement_armed:
		return false
	if not _selection_press_unit_id.is_empty():
		return false

	_selection_drag_screen_position = screen_position
	if not _selection_drag_active and _selection_press_screen_position.distance_to(screen_position) < SELECTION_DRAG_THRESHOLD:
		return false

	_selection_drag_active = true
	_update_selection_overlay(_build_selection_rect(_selection_press_screen_position, screen_position))
	return true


func _finish_selection_interaction(screen_position: Vector2) -> bool:
	if not _selection_press_active:
		return false

	var ctrl_pressed: bool = _selection_press_ctrl
	var unit_id: String = _selection_press_unit_id
	var was_dragging: bool = _selection_drag_active
	_selection_press_active = false
	_selection_drag_active = false
	_selection_press_unit_id = ""
	_update_selection_overlay(Rect2())

	if was_dragging:
		_apply_lasso_selection(_build_selection_rect(_selection_press_screen_position, screen_position), ctrl_pressed)
		return true

	if not unit_id.is_empty():
		var unit = _find_friendly_unit_by_id(unit_id)
		if unit != null:
			_apply_unit_click_selection(unit, ctrl_pressed)
			return true

	if not ctrl_pressed:
		_clear_selection()
		return true

	return false


func _apply_unit_click_selection(unit: Node, ctrl_pressed: bool) -> void:
	if unit == null or not unit.has_method("get_fireteam_id"):
		return
	var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
	if fireteam_id.is_empty():
		return

	var next_selected_fireteam_ids: PackedStringArray = _selected_fireteam_ids.duplicate()
	if ctrl_pressed:
		if not next_selected_fireteam_ids.has(fireteam_id):
			next_selected_fireteam_ids.append(fireteam_id)
	else:
		next_selected_fireteam_ids = PackedStringArray([fireteam_id])

	_set_selected_fireteams(next_selected_fireteam_ids)


func _apply_lasso_selection(selection_rect: Rect2, ctrl_pressed: bool) -> void:
	var lasso_fireteam_ids: PackedStringArray = []
	for fireteam_id in _get_available_fireteam_ids():
		var unit: Node2D = _get_selection_anchor_for_fireteam(fireteam_id)
		if unit == null:
			continue
		var screen_pos: Vector2 = get_viewport().get_canvas_transform() * (unit as Node2D).global_position
		if not selection_rect.has_point(screen_pos):
			continue
		if lasso_fireteam_ids.has(fireteam_id):
			continue
		lasso_fireteam_ids.append(fireteam_id)

	if ctrl_pressed:
		var merged_fireteam_ids: PackedStringArray = _selected_fireteam_ids.duplicate()
		for fireteam_id in lasso_fireteam_ids:
			if not merged_fireteam_ids.has(fireteam_id):
				merged_fireteam_ids.append(fireteam_id)
		_set_selected_fireteams(merged_fireteam_ids)
		return

	_set_selected_fireteams(lasso_fireteam_ids)


func _clear_selection() -> void:
	_set_selected_fireteams(PackedStringArray())


func _set_selected_fireteams(next_selected_fireteam_ids: PackedStringArray, emit_signal: bool = true) -> void:
	_selected_fireteam_ids = _sanitize_fireteam_ids(next_selected_fireteam_ids)
	if _selected_fireteam_ids.is_empty() or _is_all_fireteams_selected():
		_current_fireteam_index = 0
	elif _selected_fireteam_ids.has("blue"):
		_current_fireteam_index = 1
	elif _selected_fireteam_ids.has("gold"):
		_current_fireteam_index = 2
	_refresh_selection_visuals()
	_refresh_order_visuals()
	_refresh_button_state()
	_update_ui()
	if emit_signal:
		_emit_planning_state_changed()


func _refresh_selection_visuals() -> void:
	for unit in _get_all_friendly_units(true):
		if unit == null or not unit.has_method("set_tactical_selected") or not unit.has_method("get_fireteam_id"):
			continue
		var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		unit.call("set_tactical_selected", _selected_fireteam_ids.has(fireteam_id))


func _get_all_friendly_units(include_hidden: bool = true) -> Array:
	var mission_root: Node = get_parent()
	if mission_root == null:
		return []

	var result: Array = []
	for child in mission_root.get_children():
		if not child.has_method("get_team_id") or not child.has_method("get_unit_id") or not child.has_method("get_fireteam_id"):
			continue
		if String(child.call("get_team_id")).strip_edges() != FRIENDLY_TEAM_ID:
			continue
		if not include_hidden and child is CanvasItem and not (child as CanvasItem).visible and not _embarked_unit_ids.has(String(child.call("get_unit_id"))):
			continue
		result.append(child)

	result.sort_custom(Callable(self, "_sort_unit_nodes_for_cards"))
	return result


func _get_fireteam_units(fireteam_id: String, include_hidden: bool = true) -> Array:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return []
	var result: Array = []
	for unit in _get_all_friendly_units(include_hidden):
		if String(unit.call("get_fireteam_id")).strip_edges().to_lower() != normalized_fireteam_id:
			continue
		result.append(unit)
	return result


func _resolve_fireteam_leader_for_behavior(fireteam_id: String):
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return null
	var best_unit = null
	var best_leadership: float = -1.0
	for unit in _get_fireteam_units(normalized_fireteam_id, true):
		var is_fit: bool = not unit.has_method("get_vital_state") or String(unit.call("get_vital_state")) == "fit"
		if not is_fit:
			continue
		if bool(unit.get("is_fireteam_lead")):
			return unit
		var leadership: float = float(unit.call("get_leadership_skill")) if unit.has_method("get_leadership_skill") else 0.0
		if leadership > best_leadership:
			best_leadership = leadership
			best_unit = unit
	if best_unit != null:
		return best_unit
	return _get_selection_anchor_for_fireteam(normalized_fireteam_id)


func _find_selectable_unit_at_screen_position(screen_position: Vector2) -> Node:
	var world_position: Vector2 = _screen_to_world_position(screen_position)
	var best_unit: Node = null
	var best_distance_sq: float = UNIT_SELECTION_PICK_RADIUS * UNIT_SELECTION_PICK_RADIUS
	for unit in _get_all_friendly_units(false):
		if not (unit is Node2D):
			continue
		var distance_sq: float = (unit as Node2D).global_position.distance_squared_to(world_position)
		if distance_sq > best_distance_sq:
			continue
		best_distance_sq = distance_sq
		best_unit = unit
	return best_unit


func _get_selection_anchor_for_fireteam(fireteam_id: String) -> Node2D:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return null

	var first_match: Node2D = null
	for unit in _get_all_friendly_units(true):
		if not (unit is Node2D):
			continue
		if String(unit.call("get_fireteam_id")).strip_edges().to_lower() != normalized_fireteam_id:
			continue
		if first_match == null:
			first_match = unit as Node2D
		if bool(unit.get("is_fireteam_lead")):
			return unit as Node2D

	return first_match


func _is_all_fireteams_selected() -> bool:
	var available_fireteam_ids: PackedStringArray = _get_available_fireteam_ids()
	if available_fireteam_ids.is_empty() or _selected_fireteam_ids.is_empty():
		return false
	for fireteam_id in available_fireteam_ids:
		if not _selected_fireteam_ids.has(fireteam_id):
			return false
	return true


func _get_available_fireteam_ids() -> PackedStringArray:
	var available_fireteam_ids: PackedStringArray = []
	for unit in _get_all_friendly_units(true):
		var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		if fireteam_id.is_empty() or available_fireteam_ids.has(fireteam_id):
			continue
		available_fireteam_ids.append(fireteam_id)
	return _sanitize_fireteam_ids(available_fireteam_ids)


func _sanitize_fireteam_ids(raw_fireteam_ids: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = []
	for fireteam_id in REAL_FIRETEAM_IDS:
		if raw_fireteam_ids.has(fireteam_id):
			result.append(fireteam_id)
	return result


func _selection_ids_for_index(index: int) -> PackedStringArray:
	match index:
		1:
			return PackedStringArray(["blue"])
		2:
			return PackedStringArray(["gold"])
		_:
			return _get_available_fireteam_ids()


func _is_unit_selected(unit: Node) -> bool:
	if unit == null or not unit.has_method("get_fireteam_id"):
		return false
	return _selected_fireteam_ids.has(String(unit.call("get_fireteam_id")).strip_edges().to_lower())


func _build_selection_rect(start_position: Vector2, end_position: Vector2) -> Rect2:
	var top_left := Vector2(minf(start_position.x, end_position.x), minf(start_position.y, end_position.y))
	var size := Vector2(absf(end_position.x - start_position.x), absf(end_position.y - start_position.y))
	return Rect2(top_left, size)


func _update_selection_overlay(selection_rect: Rect2) -> void:
	var overlay := get_node_or_null("../TacticalUI/SelectionDragOverlay") as ColorRect
	if overlay == null:
		return
	if selection_rect.size.x <= 0.0 or selection_rect.size.y <= 0.0:
		overlay.visible = false
		return
	overlay.position = selection_rect.position
	overlay.size = selection_rect.size
	overlay.visible = true


func get_order_plans_snapshot() -> Array:
	return _serialize_order_plans()


func get_visualized_waypoints_snapshot() -> Array:
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer == null or not visualizer.has_method("get_visible_waypoints"):
		return []
	return Array(visualizer.call("get_visible_waypoints"))


func _ensure_waypoint_command_menu() -> void:
	var tactical_ui := get_node_or_null("../TacticalUI") as CanvasLayer
	if tactical_ui == null or tactical_ui.get_node_or_null("WaypointCommandMenu") != null:
		return

	var menu := PopupMenu.new()
	menu.name = "WaypointCommandMenu"
	menu.hide_on_checkable_item_selection = true
	menu.hide_on_item_selection = true
	if not menu.id_pressed.is_connected(_on_waypoint_menu_id_pressed):
		menu.id_pressed.connect(_on_waypoint_menu_id_pressed)
	tactical_ui.add_child(menu)


func _ensure_order_visualizer() -> void:
	var mission_root := get_parent()
	if mission_root == null or mission_root.get_node_or_null("FireteamOrderVisualizer") != null or _order_visualizer_pending:
		return

	var visualizer = FIRETEAM_ORDER_VISUALIZER_SCRIPT.new()
	visualizer.name = "FireteamOrderVisualizer"
	visualizer.z_index = 5
	_order_visualizer_pending = true
	mission_root.call_deferred("add_child", visualizer)
	call_deferred("_finalize_order_visualizer_attach")


func _finalize_order_visualizer_attach() -> void:
	_order_visualizer_pending = false
	_refresh_order_visuals()


func _refresh_order_visuals() -> void:
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer == null:
		return
	visualizer.call("set_phase_index", _current_phase_index)
	visualizer.call("set_selected_fireteam_ids", _selected_fireteam_ids)
	visualizer.call("set_plan_dicts", _serialize_order_plans())


func _try_open_waypoint_menu_at_position(screen_position: Vector2) -> bool:
	var existing_target: Dictionary = _find_waypoint_target_at_screen_position(screen_position)
	if not existing_target.is_empty():
		_focused_waypoint_ref = existing_target.duplicate(true)
		_open_waypoint_command_menu(screen_position, [existing_target], true)
		return true

	if _selected_fireteam_ids.is_empty():
		_last_command_text = "SELECT FIRETEAM FIRST"
		_update_ui()
		return false

	var waypoint_targets: Array = _create_waypoints_for_selected_fireteams(_clamp_world_position_to_viewport(_screen_to_world_position(screen_position)))
	if waypoint_targets.is_empty():
		return false
	_focused_waypoint_ref = Dictionary(waypoint_targets[0]).duplicate(true)
	_open_waypoint_command_menu(screen_position, waypoint_targets, false)
	_last_command_text = "WAYPOINT ADDED (%s)" % _get_phase_name()
	_update_ui()
	_emit_planning_state_changed()
	return true


func _create_waypoints_for_selected_fireteams(world_position: Vector2) -> Array:
	var waypoint_targets: Array = []
	for fireteam_id in _selected_fireteam_ids:
		var waypoint_target: Dictionary = _append_waypoint_to_plan(String(fireteam_id), _current_phase_index, world_position)
		if waypoint_target.is_empty():
			continue
		waypoint_targets.append(waypoint_target)
	_refresh_order_visuals()
	return waypoint_targets


func _append_waypoint_to_plan(fireteam_id: String, phase_index: int, world_position: Vector2) -> Dictionary:
	var plan = _get_or_create_order_plan(fireteam_id, phase_index)
	if plan == null:
		return {}

	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = _next_waypoint_id()
	waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
	waypoint.target_position = world_position
	waypoint.metadata = {"created_phase": phase_index}
	plan.waypoints.append(waypoint)
	return {
		"fireteam_id": fireteam_id,
		"phase": phase_index,
		"waypoint_id": waypoint.waypoint_id,
	}


func _get_or_create_order_plan(fireteam_id: String, phase_index: int):
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var plan_key: String = _build_order_plan_key(normalized_fireteam_id, phase_index)
	if _order_plans_by_key.has(plan_key):
		return _order_plans_by_key[plan_key]

	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "plan_%s_p%d" % [normalized_fireteam_id, maxi(phase_index, 0)]
	plan.fireteam_id = normalized_fireteam_id
	plan.phase = phase_index
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_DRAFT
	_order_plans_by_key[plan_key] = plan
	return plan


func _build_order_plan_key(fireteam_id: String, phase_index: int) -> String:
	return "%s|%d" % [fireteam_id.strip_edges().to_lower(), maxi(phase_index, 0)]


func _next_waypoint_id() -> String:
	_waypoint_sequence += 1
	return "wp_%04d" % _waypoint_sequence


func _serialize_order_plans() -> Array:
	var result: Array = []
	var keys: Array = _order_plans_by_key.keys()
	keys.sort()
	for key in keys:
		var plan = _order_plans_by_key[key]
		if plan == null or not plan.is_valid() or plan.waypoints.is_empty():
			continue
		result.append(plan.to_dict())
	return result


func _load_order_plans_from_state(plan_dicts: Array, phase_offset: int = 0) -> void:
	_order_plans_by_key.clear()
	for plan_variant in plan_dicts:
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		var adjusted_plan_dict: Dictionary = Dictionary(plan_variant).duplicate(true)
		adjusted_plan_dict["phase"] = maxi(int(adjusted_plan_dict.get("phase", 0)) + phase_offset, 0)
		for waypoint_variant in Array(adjusted_plan_dict.get("waypoints", [])):
			if typeof(waypoint_variant) != TYPE_DICTIONARY:
				continue
			var waypoint_dict: Dictionary = Dictionary(waypoint_variant)
			if phase_offset != 0:
				var metadata: Dictionary = Dictionary(waypoint_dict.get("metadata", {})).duplicate(true)
				metadata["legacy_phase_migrated"] = true
				waypoint_dict["metadata"] = metadata
		var plan = FIRETEAM_ORDER_PLAN_SCRIPT.call("from_dict", adjusted_plan_dict)
		if plan == null or not plan.is_valid():
			continue
		_order_plans_by_key[_build_order_plan_key(String(plan.fireteam_id), int(plan.phase))] = plan
		for waypoint_variant in plan.waypoints:
			var waypoint_id: String = String(waypoint_variant.waypoint_id if waypoint_variant is RefCounted else Dictionary(waypoint_variant).get("waypoint_id", ""))
			var waypoint_sequence: int = _extract_waypoint_sequence(waypoint_id)
			if waypoint_sequence > _waypoint_sequence:
				_waypoint_sequence = waypoint_sequence
	_refresh_order_visuals()


func _get_max_order_plan_phase() -> int:
	var max_phase: int = -1
	for plan_key in _order_plans_by_key.keys():
		var plan = _order_plans_by_key[plan_key]
		if plan == null:
			continue
		max_phase = maxi(max_phase, int(plan.phase))
	return max_phase


func _get_phase_controller():
	return get_node_or_null("../PhaseController")


func _sync_phase_selection_from_controller() -> void:
	var phase_controller = _get_phase_controller()
	if phase_controller == null or not phase_controller.has_method("get_selected_phase_index"):
		_current_phase_index = maxi(_current_phase_index, 1)
		return
	_current_phase_index = int(phase_controller.call("get_selected_phase_index"))


func _hide_legacy_phase_buttons() -> void:
	for path in [
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ApproachPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/AssaultPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/HoldPhaseButton",
	]:
		var control := get_node_or_null(path) as Control
		if control != null:
			control.visible = false
		var button := get_node_or_null(path) as BaseButton
		if button != null:
			button.disabled = true


func _has_pending_global_phase() -> bool:
	var phase_controller = _get_phase_controller()
	if phase_controller == null:
		return false
	return int(phase_controller.call("get_active_phase_index")) < int(phase_controller.call("get_phase_count")) - 1


func _get_terrain_registry():
	var terrain_registry = get_node_or_null("../TerrainRegistry")
	if terrain_registry != null:
		return terrain_registry
	var simulation_root = get_node_or_null("../SimulationRoot")
	if simulation_root == null or not simulation_root.has_method("_get_terrain_registry"):
		return null
	return simulation_root.call("_get_terrain_registry")


func _resolve_fireteam_behavior_profile(fireteam_id: String, command_type: String, rough_target_position = null):
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return null
	return FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call(
		"resolve_profile",
		normalized_fireteam_id,
		_get_fireteam_units(normalized_fireteam_id, true),
		_resolve_fireteam_leader_for_behavior(normalized_fireteam_id),
		command_type,
		rough_target_position,
		_get_terrain_registry()
	)


func _set_active_behavior_profile(fireteam_id: String, behavior_profile) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return
	if behavior_profile == null:
		_active_behavior_profiles_by_fireteam.erase(normalized_fireteam_id)
		return
	_active_behavior_profiles_by_fireteam[normalized_fireteam_id] = behavior_profile


func _notify_flank_initiated(fireteam_id: String, rough_target_position: Vector2, resolved_target_position: Vector2, behavior_profile) -> void:
	var event_router = get_node_or_null("../EventRouter")
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	if event_router == null or leader == null or not event_router.has_method("notify_flank_initiated"):
		return
	var profile_dict: Dictionary = behavior_profile.to_dict() if behavior_profile != null and behavior_profile.has_method("to_dict") else {}
	event_router.call(
		"notify_flank_initiated",
		fireteam_id,
		leader,
		{
			"fireteam_id": fireteam_id,
			"leader_unit_id": String(leader.call("get_unit_id")) if leader != null and leader.has_method("get_unit_id") else "",
			"rough_target_position": rough_target_position,
			"resolved_target_position": resolved_target_position,
			"behavior_profile": profile_dict,
		}
	)


func _apply_default_fireteam_behavior(fireteam_id: String, phase_index: int) -> bool:
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	if leader == null or not (leader is Node2D):
		_set_active_behavior_profile(fireteam_id, null)
		return false
	var anchor_position: Vector2 = (leader as Node2D).global_position
	var behavior_profile = _resolve_fireteam_behavior_profile(fireteam_id, "hold_position", anchor_position)
	if behavior_profile == null:
		return false
	var metadata: Dictionary = Dictionary(behavior_profile.metadata).duplicate(true)
	metadata["origin"] = "standard_behavior"
	metadata["phase"] = phase_index
	behavior_profile.metadata = metadata
	_set_active_behavior_profile(fireteam_id, behavior_profile)
	var issued_count: int = 0
	for driver in _get_flow_drivers_for_fireteam(fireteam_id):
		if driver == null or not driver.has_method("issue_command_at_position"):
			continue
		if bool(driver.call("issue_command_at_position", anchor_position, "defend", phase_index)):
			issued_count += 1
	return issued_count > 0


func _start_active_phase_execution(active_phase_index: int) -> void:
	_phase_execution_by_fireteam.clear()
	_active_behavior_profiles_by_fireteam.clear()
	var activated_fireteams: PackedStringArray = []
	var default_fireteams: PackedStringArray = []
	for fireteam_id in _get_available_fireteam_ids():
		var plan = _order_plans_by_key.get(_build_order_plan_key(String(fireteam_id), active_phase_index), null)
		if plan == null or plan.waypoints.is_empty():
			if _apply_default_fireteam_behavior(String(fireteam_id), active_phase_index):
				default_fireteams.append(String(fireteam_id).to_upper())
			continue
		for waypoint in plan.waypoints:
			waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
		plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING
		plan.active_waypoint_index = -1
		if _activate_next_waypoint_for_plan(plan, String(fireteam_id), 0):
			activated_fireteams.append(String(fireteam_id).to_upper())
	if activated_fireteams.is_empty() and default_fireteams.is_empty():
		_last_command_text = "PHASE P%d ACTIVE (NO PLANS)" % active_phase_index
		return
	var phase_bits: PackedStringArray = []
	if not activated_fireteams.is_empty():
		phase_bits.append("ORDERS %s" % ", ".join(activated_fireteams))
	if not default_fireteams.is_empty():
		phase_bits.append("DEFAULT %s" % ", ".join(default_fireteams))
	_last_command_text = "PHASE P%d STARTED (%s)" % [active_phase_index, " | ".join(phase_bits)]


func _activate_next_waypoint_for_plan(plan, fireteam_id: String, waypoint_index: int) -> bool:
	if plan == null or waypoint_index < 0 or waypoint_index >= plan.waypoints.size():
		plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_COMPLETED if plan != null else FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING
		return false
	plan.active_waypoint_index = waypoint_index
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_ACTIVE
	var waypoint = plan.waypoints[waypoint_index]
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE
	var behavior_profile = _resolve_fireteam_behavior_profile(fireteam_id, String(waypoint.command_type), waypoint.target_position)
	if behavior_profile != null:
		var metadata: Dictionary = Dictionary(behavior_profile.metadata).duplicate(true)
		metadata["origin"] = "planned_order"
		metadata["phase"] = int(plan.phase)
		behavior_profile.metadata = metadata
	_set_active_behavior_profile(fireteam_id, behavior_profile)
	var resolved_target_position = waypoint.target_position
	if behavior_profile != null:
		var behavior_metadata: Dictionary = Dictionary(behavior_profile.metadata)
		if typeof(behavior_metadata.get("resolved_target_position", null)) == TYPE_VECTOR2:
			resolved_target_position = Vector2(behavior_metadata.get("resolved_target_position", waypoint.target_position))
	_phase_execution_by_fireteam[fireteam_id] = {
		"phase": int(plan.phase),
		"waypoint_index": waypoint_index,
		"hold_elapsed": 0.0,
		"resolved_target_position": resolved_target_position,
	}
	return _issue_waypoint_for_fireteam(fireteam_id, waypoint, int(plan.phase), behavior_profile)


func _issue_waypoint_for_fireteam(fireteam_id: String, waypoint, phase_index: int, behavior_profile = null) -> bool:
	if waypoint == null or typeof(waypoint.target_position) != TYPE_VECTOR2:
		return false
	var target_position: Vector2 = waypoint.target_position
	if behavior_profile != null:
		var behavior_metadata: Dictionary = Dictionary(behavior_profile.metadata)
		if typeof(behavior_metadata.get("resolved_target_position", null)) == TYPE_VECTOR2:
			target_position = Vector2(behavior_metadata.get("resolved_target_position", waypoint.target_position))
	var issued_count: int = 0
	for driver in _get_flow_drivers_for_fireteam(fireteam_id):
		if driver == null:
			continue
		if driver.has_method("issue_command_at_position"):
			if bool(driver.call("issue_command_at_position", target_position, String(waypoint.command_type), phase_index)):
				issued_count += 1
		elif driver.has_method("issue_command"):
			var target_marker := get_node_or_null(target_marker_path) as Node2D
			var previous_position: Vector2 = target_marker.global_position if target_marker != null else Vector2.ZERO
			if target_marker != null:
				target_marker.global_position = target_position
			if bool(driver.call("issue_command", String(waypoint.command_type), phase_index)):
				issued_count += 1
			if target_marker != null:
				target_marker.global_position = previous_position
	if issued_count > 0 and String(waypoint.command_type) == FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_FLANK:
		_notify_flank_initiated(fireteam_id, waypoint.target_position, target_position, behavior_profile)
	return issued_count > 0


func _update_active_phase_execution(delta: float) -> void:
	if preview_mode or _phase_execution_by_fireteam.is_empty():
		return
	var did_change: bool = false
	for fireteam_id in _phase_execution_by_fireteam.keys().duplicate():
		var execution_state: Dictionary = Dictionary(_phase_execution_by_fireteam.get(fireteam_id, {})).duplicate(true)
		var phase_index: int = int(execution_state.get("phase", -1))
		var plan = _order_plans_by_key.get(_build_order_plan_key(String(fireteam_id), phase_index), null)
		if plan == null:
			_phase_execution_by_fireteam.erase(fireteam_id)
			continue
		var waypoint_index: int = int(execution_state.get("waypoint_index", -1))
		if waypoint_index < 0 or waypoint_index >= plan.waypoints.size():
			_phase_execution_by_fireteam.erase(fireteam_id)
			continue
		var waypoint = plan.waypoints[waypoint_index]
		var anchor := _get_selection_anchor_for_fireteam(String(fireteam_id))
		var resolved_target_position: Vector2 = Vector2(execution_state.get("resolved_target_position", waypoint.target_position))
		if anchor == null or typeof(resolved_target_position) != TYPE_VECTOR2:
			continue
		if anchor.global_position.distance_to(resolved_target_position) > PHASE_WAYPOINT_COMPLETE_RADIUS:
			continue
		execution_state["hold_elapsed"] = float(execution_state.get("hold_elapsed", 0.0)) + delta
		var required_hold: float = maxf(float(waypoint.hold_duration_seconds), 0.0)
		if float(execution_state.get("hold_elapsed", 0.0)) + 0.001 < required_hold:
			_phase_execution_by_fireteam[fireteam_id] = execution_state
			continue
		waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_COMPLETED
		plan.active_waypoint_index = waypoint_index
		_phase_execution_by_fireteam.erase(fireteam_id)
		if waypoint_index + 1 >= plan.waypoints.size():
			plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_COMPLETED
			_apply_default_fireteam_behavior(String(fireteam_id), phase_index)
		else:
			_activate_next_waypoint_for_plan(plan, String(fireteam_id), waypoint_index + 1)
		did_change = true
	if not did_change:
		return
	if _phase_execution_by_fireteam.is_empty():
		var phase_controller = _get_phase_controller()
		if phase_controller != null and phase_controller.has_method("get_active_phase_name"):
			_last_command_text = "%s COMPLETE" % String(phase_controller.call("get_active_phase_name"))
	_refresh_order_visuals()
	_update_ui()
	_emit_planning_state_changed()


func _extract_waypoint_sequence(waypoint_id: String) -> int:
	var parts: PackedStringArray = waypoint_id.strip_edges().split("_")
	if parts.size() < 2:
		return 0
	return int(parts[parts.size() - 1])


func _count_selected_phase_waypoints() -> int:
	var total: int = 0
	for fireteam_id in _selected_fireteam_ids:
		var plan = _order_plans_by_key.get(_build_order_plan_key(String(fireteam_id), _current_phase_index), null)
		if plan == null:
			continue
		total += plan.waypoints.size()
	return total


func _find_waypoint_target_at_screen_position(screen_position: Vector2) -> Dictionary:
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer == null or not visualizer.has_method("get_waypoint_hit"):
		return {}
	var waypoint_data: Dictionary = visualizer.call("get_waypoint_hit", screen_position, get_viewport().get_canvas_transform())
	if waypoint_data.is_empty():
		return {}
	return {
		"fireteam_id": String(waypoint_data.get("fireteam_id", "")).strip_edges().to_lower(),
		"phase": int(waypoint_data.get("phase", _current_phase_index)),
		"waypoint_id": String(waypoint_data.get("waypoint_id", "")).strip_edges(),
	}


func _try_begin_waypoint_drag(screen_position: Vector2) -> bool:
	if _is_lz_placement_armed or _is_target_placement_armed:
		return false
	var waypoint_ref: Dictionary = _find_waypoint_target_at_screen_position(screen_position)
	if waypoint_ref.is_empty():
		return false
	_dragged_waypoint_ref = waypoint_ref.duplicate(true)
	_focused_waypoint_ref = waypoint_ref.duplicate(true)
	_dragged_waypoint_press_screen_position = screen_position
	_is_dragging_waypoint = true
	_has_dragged_waypoint = false
	_hide_waypoint_command_menu()
	return true


func _update_waypoint_drag(screen_position: Vector2) -> bool:
	if not _is_dragging_waypoint or _dragged_waypoint_ref.is_empty():
		return false
	if not _has_dragged_waypoint and _dragged_waypoint_press_screen_position.distance_to(screen_position) < WAYPOINT_DRAG_THRESHOLD:
		return true
	_has_dragged_waypoint = true
	_update_waypoint_targets([_dragged_waypoint_ref], _clamp_world_position_to_viewport(_screen_to_world_position(screen_position)))
	return true


func _finish_waypoint_drag(screen_position: Vector2) -> bool:
	if not _is_dragging_waypoint:
		return false
	if _has_dragged_waypoint:
		_update_waypoint_targets([_dragged_waypoint_ref], _clamp_world_position_to_viewport(_screen_to_world_position(screen_position)))
		_last_command_text = "WAYPOINT MOVED"
		_update_ui()
		_emit_planning_state_changed()
	_is_dragging_waypoint = false
	_has_dragged_waypoint = false
	_dragged_waypoint_ref = {}
	return true


func _delete_focused_waypoint() -> bool:
	if _focused_waypoint_ref.is_empty():
		return false
	var did_delete: bool = _delete_waypoint_targets([_focused_waypoint_ref])
	if did_delete:
		_focused_waypoint_ref = {}
		_hide_waypoint_command_menu()
	return did_delete


func _open_waypoint_command_menu(screen_position: Vector2, waypoint_targets: Array, include_delete_action: bool) -> void:
	var menu := get_node_or_null("../TacticalUI/WaypointCommandMenu") as PopupMenu
	if menu == null:
		return
	_waypoint_menu_targets = []
	for waypoint_target in waypoint_targets:
		_waypoint_menu_targets.append(Dictionary(waypoint_target).duplicate(true))
	menu.clear()
	menu.add_item("Move", WAYPOINT_MENU_MOVE_ID)
	menu.add_item("Defend", WAYPOINT_MENU_DEFEND_ID)
	menu.add_item("Engage", WAYPOINT_MENU_ENGAGE_ID)
	menu.add_item("Flank", WAYPOINT_MENU_FLANK_ID)
	menu.add_item("Take", WAYPOINT_MENU_TAKE_ID)
	if include_delete_action:
		menu.add_separator()
		menu.add_item("Delete", WAYPOINT_MENU_DELETE_ID)
	menu.reset_size()
	menu.position = screen_position + Vector2(10.0, 10.0)
	menu.popup()


func _hide_waypoint_command_menu() -> void:
	var menu := get_node_or_null("../TacticalUI/WaypointCommandMenu") as PopupMenu
	if menu != null:
		menu.hide()
	_waypoint_menu_targets.clear()


func _on_waypoint_menu_id_pressed(item_id: int) -> void:
	match item_id:
		WAYPOINT_MENU_MOVE_ID:
			_set_waypoint_command_for_targets(_waypoint_menu_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE)
		WAYPOINT_MENU_DEFEND_ID:
			_set_waypoint_command_for_targets(_waypoint_menu_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_DEFEND)
		WAYPOINT_MENU_ENGAGE_ID:
			_set_waypoint_command_for_targets(_waypoint_menu_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE)
		WAYPOINT_MENU_FLANK_ID:
			_set_waypoint_command_for_targets(_waypoint_menu_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_FLANK)
		WAYPOINT_MENU_TAKE_ID:
			_set_waypoint_command_for_targets(_waypoint_menu_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_TAKE)
		WAYPOINT_MENU_DELETE_ID:
			_delete_waypoint_targets(_waypoint_menu_targets)
	_hide_waypoint_command_menu()


func _set_waypoint_command_for_targets(waypoint_targets: Array, command_type: String) -> bool:
	var did_change: bool = false
	for waypoint_target in waypoint_targets:
		var waypoint = _get_waypoint_from_ref(Dictionary(waypoint_target))
		if waypoint == null:
			continue
		waypoint.command_type = command_type
		did_change = true
	if not did_change:
		return false
	_refresh_order_visuals()
	_last_command_text = "WAYPOINT %s" % command_type.to_upper()
	_update_ui()
	_emit_planning_state_changed()
	return true


func _update_waypoint_targets(waypoint_targets: Array, world_position: Vector2) -> bool:
	var did_change: bool = false
	for waypoint_target in waypoint_targets:
		var waypoint = _get_waypoint_from_ref(Dictionary(waypoint_target))
		if waypoint == null:
			continue
		waypoint.target_position = world_position
		did_change = true
	if not did_change:
		return false
	_refresh_order_visuals()
	_update_ui()
	return true


func _delete_waypoint_targets(waypoint_targets: Array) -> bool:
	var did_delete: bool = false
	for waypoint_target in waypoint_targets:
		if _remove_waypoint_from_plan(Dictionary(waypoint_target)):
			did_delete = true
	if not did_delete:
		return false
	_refresh_order_visuals()
	_last_command_text = "WAYPOINT DELETED"
	_update_ui()
	_emit_planning_state_changed()
	return true


func _remove_waypoint_from_plan(waypoint_target: Dictionary) -> bool:
	var fireteam_id: String = String(waypoint_target.get("fireteam_id", "")).strip_edges().to_lower()
	var phase_index: int = int(waypoint_target.get("phase", _current_phase_index))
	var plan_key: String = _build_order_plan_key(fireteam_id, phase_index)
	var plan = _order_plans_by_key.get(plan_key, null)
	if plan == null:
		return false
	var waypoint_id: String = String(waypoint_target.get("waypoint_id", "")).strip_edges()
	for index in range(plan.waypoints.size()):
		var waypoint = plan.waypoints[index]
		if String(waypoint.waypoint_id) != waypoint_id:
			continue
		plan.waypoints.remove_at(index)
		if plan.waypoints.is_empty():
			_order_plans_by_key.erase(plan_key)
		return true
	return false


func _get_waypoint_from_ref(waypoint_target: Dictionary):
	var fireteam_id: String = String(waypoint_target.get("fireteam_id", "")).strip_edges().to_lower()
	var phase_index: int = int(waypoint_target.get("phase", _current_phase_index))
	var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, phase_index), null)
	if plan == null:
		return null
	var waypoint_id: String = String(waypoint_target.get("waypoint_id", "")).strip_edges()
	for waypoint in plan.waypoints:
		if String(waypoint.waypoint_id) == waypoint_id:
			return waypoint
	return null


func _maybe_bootstrap_live_drop() -> void:
	if preview_mode or _live_drop_bootstrap_consumed:
		return
	if not _drop_ship_requested or not _has_lz_position:
		return
	if not is_inside_tree():
		return
	if _try_start_drop_sequence():
		_live_drop_bootstrap_consumed = true


func _try_start_drop_sequence() -> bool:
	if preview_mode or not _has_lz_position:
		return false
	if _drop_ship_cooldown_remaining > 0.0:
		return false
	if _live_drop_bootstrap_consumed and _drop_sequence_phase == DROP_SEQUENCE_COMPLETE:
		return false
	if _is_drop_sequence_active():
		return false
	var pending_units: Array = []
	for unit in _get_units_for_drop_operation():
		var unit_id: String = String(unit.call("get_unit_id"))
		if _deployed_unit_ids.has(unit_id):
			continue
		pending_units.append(unit)
	if pending_units.is_empty():
		return false
	_embark_units_for_drop(pending_units)
	_drop_sequence_units = pending_units
	_drop_sequence_fireteam_name = _get_drop_fireteam_name()
	_drop_sequence_unit_index = 0
	_drop_sequence_timer = 0.0
	_drop_sequence_phase = DROP_SEQUENCE_INBOUND
	_drop_sequence_position = _get_drop_staging_position()
	_live_drop_bootstrap_consumed = true
	_refresh_world_overlays()
	_update_ui()
	return true


func _embark_units_for_drop(units: Array) -> void:
	var staging_position: Vector2 = _get_drop_staging_position()
	for index in range(units.size()):
		var unit = units[index]
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		_embarked_unit_ids[unit_id] = true
		if unit is Node2D:
			(unit as Node2D).global_position = staging_position + Vector2(-18.0 * index, 10.0 * index)
		if unit is CanvasItem:
			(unit as CanvasItem).visible = false


func _update_drop_sequence(delta: float) -> void:
	if preview_mode:
		return
	match _drop_sequence_phase:
		DROP_SEQUENCE_INBOUND:
			_drop_sequence_position = _drop_sequence_position.move_toward(_lz_position, DROP_SHIP_SPEED * delta)
			if _drop_sequence_position.distance_to(_lz_position) <= 2.0:
				_drop_sequence_position = _lz_position
				_drop_sequence_phase = DROP_SEQUENCE_LANDED
				_drop_sequence_timer = DROP_LANDING_HOLD_SECONDS
				_last_command_text = "DROPSHIP LANDED"
				_update_ui()
			_refresh_world_overlays()
		DROP_SEQUENCE_LANDED:
			_drop_sequence_timer -= delta
			if _drop_sequence_timer > 0.0:
				return
			_drop_sequence_phase = DROP_SEQUENCE_UNLOADING
			_drop_sequence_timer = 0.0
			_last_command_text = "DEBOARDING %s" % _drop_sequence_fireteam_name
			_update_ui()
		DROP_SEQUENCE_UNLOADING:
			_drop_sequence_timer -= delta
			if _drop_sequence_timer > 0.0:
				return
			if _drop_sequence_unit_index >= _drop_sequence_units.size():
				_drop_sequence_phase = DROP_SEQUENCE_COMPLETE
				_drop_sequence_position = _lz_position
				_last_command_text = "%s DEPLOYED" % _drop_sequence_fireteam_name
				_drop_sequence_timer = 0.2
				_update_ui()
				_refresh_world_overlays()
				return
			_deploy_next_embarked_unit()
			_drop_sequence_timer = DROP_UNLOAD_INTERVAL_SECONDS
		DROP_SEQUENCE_COMPLETE:
			_drop_sequence_timer -= delta
			if _drop_sequence_timer > 0.0:
				return
			_drop_sequence_phase = DROP_SEQUENCE_OUTBOUND
			_last_command_text = "DROPSHIP EXITING"
			_update_ui()
		DROP_SEQUENCE_OUTBOUND:
			var exit_position: Vector2 = _get_drop_exit_position()
			_drop_sequence_position = _drop_sequence_position.move_toward(exit_position, DROP_SHIP_SPEED * delta)
			if _drop_sequence_position.distance_to(exit_position) <= 2.0:
				_drop_ship_cooldown_remaining = DROP_SHIP_RECALL_COOLDOWN_SECONDS
				_drop_ship_requested = false
				_drop_sequence_position = Vector2.ZERO
				_drop_sequence_phase = ""
				_drop_sequence_units = []
				_drop_sequence_unit_index = 0
				_drop_sequence_timer = 0.0
				_drop_sequence_fireteam_name = "ALL"
				_live_drop_bootstrap_consumed = false
				_last_command_text = "DROPSHIP CLEARED"
				_emit_planning_state_changed()
				_update_ui()
				_refresh_world_overlays()
			_refresh_world_overlays()


func _deploy_next_embarked_unit() -> void:
	if _drop_sequence_unit_index >= _drop_sequence_units.size():
		return
	var unit = _drop_sequence_units[_drop_sequence_unit_index]
	var unload_index: int = _drop_sequence_unit_index
	_drop_sequence_unit_index += 1
	if unit == null or not unit.has_method("get_unit_id"):
		return
	var unit_id: String = String(unit.call("get_unit_id"))
	_embarked_unit_ids.erase(unit_id)
	_deployed_unit_ids[unit_id] = true
	if unit is Node2D:
		(unit as Node2D).global_position = _lz_position + _get_unload_offset(unload_index)
	if unit is CanvasItem:
		(unit as CanvasItem).visible = true
	if unit.has_method("set_runtime_status"):
		unit.call("set_runtime_status", "idle")
	if unit.has_method("refresh_terrain_readability"):
		unit.call("refresh_terrain_readability")
	if unit.has_method("show_event_text"):
		unit.call("show_event_text", "DISEMBARK", Color(0.55, 1.0, 0.72, 1.0), 1.5)
	_last_command_text = "DEBOARD %d/%d" % [_drop_sequence_unit_index, _drop_sequence_units.size()]
	_update_ui()


func _is_drop_sequence_active() -> bool:
	return _drop_sequence_phase == DROP_SEQUENCE_INBOUND or _drop_sequence_phase == DROP_SEQUENCE_LANDED or _drop_sequence_phase == DROP_SEQUENCE_UNLOADING or _drop_sequence_phase == DROP_SEQUENCE_COMPLETE or _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND


func _get_drop_approach_offset() -> Vector2:
	return Vector2(APPROACH_OFFSETS.get(_get_approach_angle_name(), Vector2(180.0, -112.0)))


func _get_drop_staging_position() -> Vector2:
	var offset: Vector2 = _get_drop_approach_offset()
	if offset.length_squared() <= 0.001:
		offset = Vector2(180.0, -112.0)
	return _lz_position + offset.normalized() * DROP_STAGING_DISTANCE


func _get_drop_exit_position() -> Vector2:
	return _get_drop_staging_position()


func _get_units_for_drop_operation() -> Array:
	var requested_fireteam_id: String = _get_drop_fireteam_id()
	var result: Array = []
	for unit in _get_selected_friendly_units(true):
		if requested_fireteam_id.is_empty():
			result.append(unit)
			continue
		var unit_fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		if unit_fireteam_id == requested_fireteam_id:
			result.append(unit)
	return result


func _get_drop_fireteam_id() -> String:
	var selected_fireteam_id: String = _get_selected_fireteam_id()
	if not selected_fireteam_id.is_empty():
		return selected_fireteam_id
	var mission_setup: Node = get_node_or_null("../MissionSetup")
	if mission_setup == null:
		return ""
	var meta_fireteam_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_fireteam_ids"))
	var unique_fireteam_ids: Dictionary = {}
	for fireteam_id_variant in meta_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id == "blue" or fireteam_id == "gold":
			unique_fireteam_ids[fireteam_id] = true
	if unique_fireteam_ids.size() == 1:
		return String(unique_fireteam_ids.keys()[0])
	return ""


func _get_drop_fireteam_name() -> String:
	var fireteam_id: String = _get_drop_fireteam_id()
	match fireteam_id:
		"blue":
			return "BLUE"
		"gold":
			return "GOLD"
		_:
			return "ALL"


func _get_unload_offset(index: int) -> Vector2:
	var base_offset: Vector2 = DROP_UNLOAD_OFFSETS[index] if index >= 0 and index < DROP_UNLOAD_OFFSETS.size() else Vector2(28.0 * float(index), 0.0)
	match _get_approach_angle_name():
		"NE":
			return Vector2(-base_offset.y, base_offset.x)
		"SW":
			return Vector2(base_offset.y, -base_offset.x)
		"SE":
			return Vector2(-base_offset.x, -base_offset.y)
		_:
			return base_offset