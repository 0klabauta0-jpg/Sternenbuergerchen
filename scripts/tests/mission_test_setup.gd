extends Node

const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_renderer.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const LOADOUT_MODIFIER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/command/loadout_modifier_resolver.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")
const FOG_OF_WAR_MODE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_mode_contract.gd")
const MULTIPLAYER_TERRAIN_FOG = preload("res://scripts/multiplayer/multiplayer_terrain_fog_projection.gd")
const FOG_OF_WAR_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const LINE_OF_SIGHT_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const SIMULATION_ROOT_SCRIPT=preload("res://scripts/core/simulation_root.gd")

const FOW_UPDATE_INTERVAL_SECONDS: float = 0.10
const FOW_DEFAULT_SIGHT_RANGE_WORLD: float = 640.0
const FOW_DEFAULT_WORK_BUDGET_TILES: int = 512
const LEGACY_FALLBACK_BLOCKED_TILES: Array[Vector2i] = [
	Vector2i(4, 1),
	Vector2i(4, 2),
	Vector2i(5, 2),
]
const LEGACY_FALLBACK_LOS_BLOCKING_TILES: Array[Vector2i] = [
	Vector2i(4, 2),
	Vector2i(5, 2),
]
const LEGACY_FALLBACK_COVER_BY_TILE: Dictionary = {
	Vector2i(3, 4): 20,
	Vector2i(4, 4): 20,
	Vector2i(4, 5): 20,
	Vector2i(5, 3): 35,
	Vector2i(2, 5): 35,
}
const LEGACY_FALLBACK_HEIGHT_BY_TILE: Dictionary = {
	Vector2i(3, 3): 1,
	Vector2i(4, 3): 1,
	Vector2i(3, 4): 1,
	Vector2i(5, 4): 1,
	Vector2i(3, 5): 1,
	Vector2i(4, 5): 1,
	Vector2i(5, 5): 1,
	Vector2i(4, 4): 2,
	Vector2i(5, 3): 2,
}
const LEGACY_FALLBACK_SURFACE_BY_TILE: Dictionary = {
	Vector2i(4, 0): "road",
	Vector2i(3, 1): "road",
	Vector2i(3, 2): "road",
	Vector2i(3, 3): "road",
	Vector2i(4, 4): "road",
	Vector2i(3, 5): "road",
	Vector2i(2, 7): "sand",
	Vector2i(2, 6): "sand",
	Vector2i(1, 6): "sand",
	Vector2i(2, 5): "sand",
	Vector2i(5, 3): "rock",
	Vector2i(5, 4): "rock",
}

@export var team_id: String = "team_alpha"
@export var runtime_leader_path: NodePath
@export var unit_registry_path: NodePath
@export var ftl_registry_path: NodePath
@export var target_marker_path: NodePath
@export var spawn_alpha_path: NodePath
@export var spawn_bravo_path: NodePath
@export var objective_point_path: NodePath
@export var unit_paths: Array[NodePath] = []
@export var selected_team_unit_ids: PackedStringArray = []
@export var selected_team_fireteam_ids: PackedStringArray = []
@export var selected_team_unit_configs: Array = []
@export var selected_fireteam_definitions: Array = []
@export var respawn_manager_path: NodePath
@export var enemy_wave_controller_path: NodePath
@export var terrain_registry_path: NodePath
@export var simulation_root_path: NodePath
@export var map_file_path: String = "res://maps/Ground_Mission01_32x32.json"
@export var scenario_file_path: String = ""
@export var defer_friendly_runtime_activation: bool = true
@export var allow_full_roster_when_selection_empty: bool = true
@export var use_2_5d_primary_view: bool = true
@export var fog_of_war_mode: String = FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF
@export var fog_of_war_sight_range_world: float = FOW_DEFAULT_SIGHT_RANGE_WORLD
@export var fog_viewer_team_id: String = ""
@export_range(16, 2048, 16) var fog_of_war_work_budget_tiles: int = FOW_DEFAULT_WORK_BUDGET_TILES
var _fog_frame_timing_debug_enabled: bool = false
var _fog_frame_timing_debug_snapshot: Dictionary = {}
var _fog_visibility_work_debug_snapshot: Dictionary = {}

var member_loadouts: Dictionary = {}
var unit_loadout_modifiers_by_unit_id: Dictionary = {}
var _is_initialized: bool = false
var _terrain_renderer = null
var _terrain_3d_view = null
var _prepared_terrain_resource_cache: RefCounted
var _loaded_terrain_map_data = null
var _loaded_terrain_map_path: String = ""
var _mission_scenario = null
var _scenario_enemy_ids: PackedStringArray = PackedStringArray()
var _scenario_tactical_authoring: Dictionary = {}
var _fog_of_war_system = null
var _fog_of_war_los_system = null
var _fog_observer_unit_nodes: Array = []
var _fog_unit_nodes: Array = []
var _fog_terrain_registry = null
var _fog_runtime_signature: String = ""
var _fog_requested_runtime_signature: String = ""
var _fog_requested_static_signature: String = ""
var _fog_pending_visibility_started_msec: int = 0
var _fog_update_elapsed: float = 0.0
var _fog_network_terrain_cache: Dictionary = {}
var _fog_network_enabled: bool = false
var _fog_replica_terrain: Dictionary = {}
var _fog_replica_visible_ids := PackedStringArray()
var _fog_other_team_work: Dictionary = {}
var _fog_other_team_cursor: int = 0
var _friendly_unit_slot_paths: Array[NodePath] = []
var _hex_setup_required:=false
var force_hex_tactical_runtime := false
var _hex_setup_presentation_only:=false
var _hex_setup_error:Dictionary={}
var _terrain_setup_error:Dictionary={}
var _hex_setup_pending:Array[Dictionary]=[]
var _hex_setup_pending_context:=-1
var _hex_setup_pending_root_id:=0
var _hex_setup_last_stamp:=""
var _hex_setup_elapsed:=0.0
var _hex_setup_attempts:=0
var _hex_selection_applying:=false
var _hex_selection_pending:Dictionary={}
var _hex_selection_active_signature:=""
var _hex_selection_active_binding:Dictionary={}
var _hex_selection_result:Dictionary={}
var _polisa_recruit_spawn: Dictionary = {}
var _polisa_recruit_pending: Dictionary = {}


func _ready() -> void:
	if _terrain_renderer == null:
		_terrain_renderer = TERRAIN_MAP_RENDERER_SCRIPT.new()
	if _is_initialized:
		return

	var runtime_leader = get_node_or_null(runtime_leader_path)
	var unit_registry = get_node_or_null(unit_registry_path)
	var ftl_registry = get_node_or_null(ftl_registry_path)
	var simulation_root = _get_simulation_root()
	if runtime_leader == null or unit_registry == null or ftl_registry == null or simulation_root == null:
		push_warning("MissionTestSetup requires direct references to RuntimeLeader, UnitRegistry, FTLRegistry and SimulationRoot.")
		return

	apply_cmdline_scenario_override()
	apply_cmdline_fog_viewer_team_override()
	_load_mission_scenario_if_available()
	if _should_defer_runtime_enemy_slot_creation():
		call_deferred("_finish_ready_after_scenario_loaded", runtime_leader, unit_registry, ftl_registry, simulation_root)
		return
	_finish_ready_after_scenario_loaded(runtime_leader, unit_registry, ftl_registry, simulation_root)


func apply_cmdline_scenario_override(args: Array = []) -> Dictionary:
	var raw_args: Array = args.duplicate()
	var source := "provided_args"
	if raw_args.is_empty():
		raw_args = OS.get_cmdline_user_args()
		source = "OS.get_cmdline_user_args"
	var previous_path: String = scenario_file_path
	var override_path := ""
	for arg_variant in raw_args:
		var arg := String(arg_variant).strip_edges()
		if arg.begins_with("--scenario-file="):
			override_path = arg.substr("--scenario-file=".length()).strip_edges()
		elif arg.begins_with("--mission-scenario="):
			override_path = arg.substr("--mission-scenario=".length()).strip_edges()
	if not override_path.is_empty():
		scenario_file_path = override_path.replace("\\", "/")
	return {
		"source": source,
		"previous_scenario_file_path": previous_path,
		"scenario_file_path": scenario_file_path,
		"override_applied": not override_path.is_empty(),
		"read_only": false,
		"ui_sets_gameplay_truth": false,
	}


func apply_cmdline_fog_viewer_team_override(args: Array = []) -> Dictionary:
	var raw_args: Array = args.duplicate()
	var source := "provided_args"
	if raw_args.is_empty():
		raw_args = OS.get_cmdline_user_args()
		source = "OS.get_cmdline_user_args"
	var previous_team_id: String = fog_viewer_team_id
	var override_team_id := ""
	for arg_variant in raw_args:
		var arg := String(arg_variant).strip_edges()
		if arg.begins_with("--team="):
			override_team_id = arg.substr("--team=".length()).strip_edges().to_lower()
	if not override_team_id.is_empty():
		fog_viewer_team_id = override_team_id
	return {
		"source": source,
		"previous_team_id": previous_team_id,
		"fog_viewer_team_id": _get_fog_viewer_team_id(),
		"override_applied": not override_team_id.is_empty(),
		"read_only": false,
		"ui_sets_gameplay_truth": false,
	}


func _finish_ready_after_scenario_loaded(runtime_leader: Node, unit_registry: Node, ftl_registry: Node, simulation_root: Node) -> void:
	if _is_initialized:
		return
	var terrain_registry = _setup_terrain_registry()
	if not _terrain_setup_error.is_empty():
		_hex_setup_error=_terrain_setup_error.duplicate(true)
		return
	if _loaded_terrain_map_data!=null:
		_hex_setup_required=not String(_loaded_terrain_map_data.get_tactical_grid_rules()).is_empty()
		var configured:Dictionary=simulation_root.configure_hex_ground_runtime(_loaded_terrain_map_data,terrain_registry)
		_hex_setup_presentation_only=_hex_setup_required and configured.get("reason","")=="not_authority"
		if not configured.ok and configured.get("reason","")!="not_authority":
			_hex_setup_error=configured.duplicate(true)
			return
		_hex_setup_error={}
	elif simulation_root.is_hex_ground_runtime_required():
		_hex_setup_error={"ok":false,"reason":"hex_map_unavailable"}
		return
	else:
		_hex_setup_required=false
		_hex_setup_presentation_only=false
		_hex_setup_error={}
	var runtime_unit_paths: Array = _build_runtime_unit_paths()
	_build_unit_loadout_modifiers()
	var spawn_alpha_marker := _resolve_marker(spawn_alpha_path)
	var spawn_bravo_marker := _resolve_marker(spawn_bravo_path)
	var objective_marker := _resolve_marker(objective_point_path)
	var target_marker := _resolve_marker(target_marker_path)
	_apply_scenario_objective_to_marker(objective_marker)
	if target_marker != null and objective_marker != null:
		target_marker.global_position = objective_marker.global_position

	var first_unit: Node = null
	var friendly_spawn_index: int = 0
	var friendly_slot_index: int = 0
	var enemy_assignment_slot_index: int = 0
	var enemy_spawn_index: int = 0
	var enemy_units: Array = []
	var visual_unit_nodes: Array = []
	for unit_path in runtime_unit_paths:
		var unit = get_node_or_null(unit_path)
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		if use_2_5d_primary_view: _hide_legacy_unit_visual_children(unit)

		var unit_id: String = String(unit.call("get_unit_id"))
		var unit_team_id: String = ""
		var friendly_assignment_slot_index: int = -1
		if unit.has_method("get_team_id"):
			unit_team_id = String(unit.call("get_team_id"))

		if unit_team_id == team_id:
			if not _friendly_unit_slot_paths.has(unit_path):
				_friendly_unit_slot_paths.append(unit_path)
			friendly_assignment_slot_index = friendly_slot_index
			if not _is_friendly_slot_enabled(friendly_slot_index):
				_deactivate_unused_friendly_slot(unit, friendly_slot_index)
				if unit is CanvasItem:
					unit.visible = false
				friendly_slot_index += 1
				continue

			unit_id = _get_selected_unit_id_for_friendly_slot(friendly_slot_index, unit_id)
			friendly_slot_index += 1
		elif unit_team_id != team_id:
			# Explicit peaceful singleplayer scenarios own zero enemy slots.
			# Historical scenarios retain their preplaced fallback roster.
			if _mission_scenario != null and bool(_mission_scenario.call("is_noncombat_singleplayer")):
				unit.process_mode = Node.PROCESS_MODE_DISABLED
				if unit is CanvasItem:
					unit.visible = false
				continue
			unit_id = _get_scenario_enemy_id_for_slot(enemy_assignment_slot_index, unit_id)
			enemy_assignment_slot_index += 1

		_apply_unit_identity_preset(unit, unit_id, unit_team_id)
		_apply_authored_enemy_loadout(unit,unit_id,unit_team_id)
		_apply_fob_loadout_override(unit, unit_id, unit_team_id)
		if unit.has_method("get_unit_id"):
			unit_id = String(unit.call("get_unit_id"))
		if unit.has_method("get_team_id"):
			unit_team_id = String(unit.call("get_team_id"))

		if unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", _get_fireteam_id_for_friendly_slot(friendly_assignment_slot_index, unit_id, unit_team_id))

		var respawn_manager = get_node_or_null(respawn_manager_path)
		if respawn_manager != null and unit.has_method("set_respawn_manager"):
			unit.call("set_respawn_manager", respawn_manager)
		if terrain_registry != null and unit.has_method("set_terrain_registry"):
			unit.call("set_terrain_registry", terrain_registry)

		if simulation_root.has_method("register_known_unit"):
			simulation_root.call("register_known_unit", unit_id, unit)

		if unit is Node2D:
			var unit_node: Node2D = unit
			if unit_team_id == team_id and spawn_alpha_marker != null:
				unit_node.global_position = spawn_alpha_marker.global_position + _get_friendly_spawn_offset(friendly_spawn_index)
				friendly_spawn_index += 1
			elif unit_team_id != team_id:
				unit_node.global_position = _get_enemy_spawn_position(unit_id, spawn_bravo_marker) + _get_enemy_spawn_offset(enemy_spawn_index)
				enemy_spawn_index += 1

			if unit is CanvasItem:
				unit.visible = not _hex_setup_required

			if terrain_registry != null and unit.has_method("refresh_terrain_readability"):
				unit.call("refresh_terrain_readability")

		if unit_team_id == team_id:
			if defer_friendly_runtime_activation:
				if _hex_setup_required:unit.set_meta("dropship_embarked",true)
				if unit is CanvasItem:
					unit.visible = false
			else:
				unit_registry.call("register_unit", unit_id, unit)
				runtime_leader.call("add_unit_member", unit)
				_enqueue_initial_loadout_effect(simulation_root, unit_id)
		else:
			unit_registry.call("register_unit", unit_id, unit)
			enemy_units.append(unit)
		visual_unit_nodes.append(unit)

		if first_unit == null and unit_team_id == team_id:
			first_unit = unit

	if first_unit != null and not defer_friendly_runtime_activation:
		runtime_leader.call("assign", first_unit)

	if not defer_friendly_runtime_activation:
		ftl_registry.call("register_ftl", team_id, runtime_leader)
	_setup_objective_status(simulation_root, objective_marker)
	_apply_scenario_timer_to_combat_driver()

	_setup_respawn_manager(spawn_alpha_marker, spawn_bravo_marker)
	_setup_enemy_waves(enemy_units)
	_admit_hex_setup_nodes(visual_unit_nodes)
	_ensure_primary_3d_view(visual_unit_nodes)
	if not _hex_setup_presentation_only:_initialize_fog_of_war(visual_unit_nodes, terrain_registry)
	# Initial scenario gates can change door/terrain overrides above. Prepare the
	# final revision before this synchronous load releases the first gameplay tick.
	if simulation_root != null and simulation_root.has_method("prewarm_navigation"):
		simulation_root.call("prewarm_navigation", terrain_registry)
	_is_initialized = true
	if _hex_setup_presentation_only and simulation_root.has_method("refresh_multiplayer_replica_presence"):simulation_root.call("refresh_multiplayer_replica_presence")


func get_hex_setup_status()->Dictionary:
	return {"required":_hex_setup_required,"presentation_only":_hex_setup_presentation_only,"pending_count":_hex_setup_pending.size(),"attempts":_hex_setup_attempts,"error":_hex_setup_error.duplicate(true)}


func _admit_hex_setup_nodes(nodes:Array)->void:
	if not _hex_setup_required or _hex_setup_presentation_only:return
	var simulation:Node=_get_simulation_root()
	if simulation==null or not simulation.is_hex_ground_runtime_active():return
	var registry:Node=simulation.get_unit_registry()
	var combined:Dictionary={}
	if _hex_setup_pending_root_id==simulation.get_instance_id() and _hex_setup_pending_context==simulation.get_hex_ground_context_revision():
		for entry in _hex_setup_pending:combined[entry.unit_id]=entry
	for unit in nodes:
		if not is_instance_valid(unit) or not unit is Node2D or not unit.has_method("get_unit_id"):continue
		var id:String=String(unit.call("get_unit_id"))
		if registry.get_unit(id)!=unit or not simulation.get_hex_unit_state(id).is_empty() or bool(unit.get_meta("dropship_embarked",false)):continue
		if not unit.global_position.is_finite():
			_hex_setup_error={"ok":false,"reason":"invalid_setup_position"}
			return
		var placement:Dictionary=_hex_setup_spawn_grid(unit,simulation.get_hex_ground_terrain_registry())
		if not placement.get("ok",false):
			_hex_setup_error=placement
			return
		combined[id]={"unit_id":id,"grid":placement.grid,"identity":simulation.call("_hex_payload_identity",id)}
	_hex_setup_pending.clear()
	for entry in combined.values():_hex_setup_pending.append(entry)
	_hex_setup_pending_context=simulation.get_hex_ground_context_revision()
	_hex_setup_pending_root_id=simulation.get_instance_id()
	_hex_setup_last_stamp=""
	_retry_hex_setup_admission()


func _hex_setup_spawn_grid(unit:Node2D,terrain:Node)->Dictionary:
	if not unit.has_method("get_team_id"):return {"ok":false,"reason":"invalid_setup_actor"}
	var id:String=String(unit.call("get_unit_id"))
	var friendly:bool=String(unit.call("get_team_id"))==team_id
	var desired:Vector2i=terrain.world_to_grid(unit.global_position)
	var marker:Marker2D=_resolve_marker(spawn_alpha_path if friendly else spawn_bravo_path)
	var anchor:Vector2=marker.global_position if marker!=null else Vector2.INF
	if not friendly:
		var group:Dictionary=_find_scenario_enemy_group_for_unit(id)
		if group.has("spawn_position") or not String(group.get("spawn_marker_id","")).is_empty():
			anchor=_get_enemy_spawn_position(id,marker)
	# Authored spawn anchors remain mandatory terrain facts. Legacy pixel offsets
	# only describe the formation and may straddle a Hex wall after conversion.
	if anchor.is_finite():
		var anchor_grid:Vector2i=terrain.world_to_grid(anchor)
		if not terrain.is_walkable(anchor_grid):return {"ok":false,"reason":"invalid_setup_spawn_anchor","unit_id":id,"grid":anchor_grid}
		if not terrain.is_walkable(desired):desired=anchor_grid
	return {"ok":true,"grid":desired}


func _retry_hex_setup_admission()->void:
	if _hex_setup_pending.is_empty() or _hex_setup_presentation_only:return
	var simulation:Node=_get_simulation_root()
	if simulation==null:return
	if _hex_setup_pending_root_id!=simulation.get_instance_id() or _hex_setup_pending_context!=simulation.get_hex_ground_context_revision():
		_hex_setup_pending.clear()
		return
	if not simulation.is_hex_ground_runtime_active():return
	var registry:Node=simulation.get_unit_registry()
	var current:Array[Dictionary]=[]
	for entry in _hex_setup_pending:
		if simulation.call("_is_current_hex_payload",{"unit_id":entry.unit_id,"_hex_lifecycle":entry.identity}) and registry.get_unit(entry.unit_id)!=null and not bool(registry.get_unit(entry.unit_id).get_meta("dropship_embarked",false)):current.append(entry)
	if current.size()!=_hex_setup_pending.size():_hex_setup_last_stamp=""
	_hex_setup_pending=current
	if current.is_empty():return
	var stamp:String=str([simulation.get_hex_ground_context_revision(),simulation.get_hex_ground_revision(),simulation.get_hex_ground_terrain_registry().get_revision()])
	if stamp==_hex_setup_last_stamp:return
	_hex_setup_last_stamp=stamp
	var ids:=PackedStringArray()
	for entry in current:ids.append(entry.unit_id)
	var checked:Dictionary=simulation.call("_validate_hex_ground_actor_group",ids)
	if not checked.ok:
		_hex_setup_error=checked
		return
	for actor in checked.actors.values():actor.visible=false
	_hex_setup_attempts+=1
	var admitted:Dictionary=simulation.admit_hex_ground_setup_actors(current)
	_hex_setup_error={} if admitted.ok else admitted.duplicate(true)
	if admitted.ok:_hex_setup_pending.clear()


func _process(delta: float) -> void:
	if not _hex_selection_applying and not _hex_selection_pending.is_empty():
		var request:Dictionary=_hex_selection_pending
		_hex_selection_pending={}
		var lifetime:WeakRef=weakref(self)
		_run_hex_selection_request(request)
		if not is_instance_valid(lifetime.get_ref()):return
	if _hex_setup_presentation_only:return
	if not _hex_setup_pending.is_empty():
		_hex_setup_elapsed+=maxf(delta,0.0)
		if _hex_setup_elapsed>=0.1:
			_hex_setup_elapsed=0.0
			_retry_hex_setup_admission()
	if _fog_of_war_system == null or _terrain_3d_view == null:
		return
	if String(fog_of_war_mode).strip_edges().to_lower() == FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF:
		return
	var frame_started_usec: int = Time.get_ticks_usec() if _fog_frame_timing_debug_enabled else 0
	_advance_fog_of_war_visibility_work()
	_advance_multiplayer_fog_work()
	var advance_usec: int = Time.get_ticks_usec() - frame_started_usec if _fog_frame_timing_debug_enabled else 0
	_fog_update_elapsed += delta
	if _fog_update_elapsed < FOW_UPDATE_INTERVAL_SECONDS:
		if _fog_frame_timing_debug_enabled:
			_record_fog_frame_timing_debug_snapshot(frame_started_usec, advance_usec, 0)
		return
	_fog_update_elapsed = 0.0
	var sync_started_usec: int = Time.get_ticks_usec() if _fog_frame_timing_debug_enabled else 0
	# The frame already serviced its bounded slice above. A newly requested
	# sample starts next frame rather than doubling work after a completion.
	_sync_fog_of_war_visual_state(false, false)
	_sync_multiplayer_fog_work()
	if _fog_frame_timing_debug_enabled:
		_record_fog_frame_timing_debug_snapshot(frame_started_usec, advance_usec, Time.get_ticks_usec() - sync_started_usec)


func set_fog_frame_timing_debug_enabled(enabled: bool) -> void:
	_fog_frame_timing_debug_enabled = enabled
	if not enabled:
		_fog_frame_timing_debug_snapshot.clear()
		_fog_visibility_work_debug_snapshot.clear()


func get_fog_frame_timing_debug_snapshot() -> Dictionary:
	return _fog_frame_timing_debug_snapshot.duplicate(true)


func _record_fog_frame_timing_debug_snapshot(frame_started_usec: int, advance_usec: int, sync_usec: int) -> void:
	_fog_frame_timing_debug_snapshot = {
		"enabled": true,
		"total_usec": Time.get_ticks_usec() - frame_started_usec,
		"advance_usec": advance_usec,
		"sync_usec": sync_usec,
		"visibility_pending": not _fog_requested_runtime_signature.is_empty(),
		"pending_age_msec": maxi(Time.get_ticks_msec() - _fog_pending_visibility_started_msec, 0) if not _fog_requested_runtime_signature.is_empty() else 0,
		"work_budget_tiles": fog_of_war_work_budget_tiles,
		"last_work": _fog_visibility_work_debug_snapshot.duplicate(true),
		"read_only": true,
		"sets_gameplay_truth": false,
	}


func get_unit_loadout_modifiers_dict(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	return Dictionary(unit_loadout_modifiers_by_unit_id.get(normalized_unit_id, {})).duplicate(true)


func apply_runtime_selection_contract(preserve_existing: bool = false, refresh_existing_ids: PackedStringArray = PackedStringArray()) -> void:
	if not _is_initialized:
		return
	if _hex_setup_required:
		var request:Dictionary={"preserve":preserve_existing,"refresh":refresh_existing_ids.duplicate(),"inputs":_hex_selection_inputs()}
		request["signature"]=JSON.stringify(request)
		request["binding"]=_hex_selection_owner_binding()
		if _hex_selection_applying:
			if request.signature!=_hex_selection_active_signature or not _hex_selection_owner_current(_hex_selection_active_binding):_hex_selection_pending=request
			return
		var lifetime:WeakRef=weakref(self)
		_run_hex_selection_request(request)
		if not is_instance_valid(lifetime.get_ref()):return
		if not _hex_selection_pending.is_empty():
			var next:Dictionary=_hex_selection_pending
			_hex_selection_pending={}
			_run_hex_selection_request(next)
		return
	var runtime_leader = get_node_or_null(runtime_leader_path)
	var unit_registry = get_node_or_null(unit_registry_path)
	var simulation_root = _get_simulation_root()
	if runtime_leader == null or unit_registry == null or simulation_root == null:
		return
	_build_unit_loadout_modifiers()
	var friendly_paths: Array = _friendly_unit_slot_paths.duplicate()
	if friendly_paths.is_empty():
		friendly_paths = _build_current_friendly_unit_slot_paths()
	var terrain_registry = get_node_or_null(terrain_registry_path)
	var first_unit: Node = null
	var friendly_spawn_index: int = 0
	for slot_index in range(friendly_paths.size()):
		var unit_path: NodePath = friendly_paths[slot_index]
		var unit = get_node_or_null(unit_path)
		if unit == null or not unit.has_method("get_unit_id") or not unit.has_method("apply_identity_config"):
			continue
		if not _is_friendly_slot_enabled(slot_index):
			var previous_unit_id: String = String(unit.call("get_unit_id")).strip_edges() if unit.has_method("get_unit_id") else ""
			if not previous_unit_id.is_empty() and unit_registry.has_method("unregister_unit") and unit_registry.has_method("has_unit") and bool(unit_registry.call("has_unit", previous_unit_id)):
				unit_registry.call("unregister_unit", previous_unit_id)
			_deactivate_unused_friendly_slot(unit, slot_index)
			if unit is CanvasItem:
				(unit as CanvasItem).visible = false
			continue
		var fallback_unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		var unit_id: String = _get_selected_unit_id_for_friendly_slot(slot_index, fallback_unit_id)
		if preserve_existing and fallback_unit_id==unit_id and unit_registry.has_method("has_unit") and bool(unit_registry.call("has_unit",unit_id)):
			if refresh_existing_ids.has(unit_id):
				_apply_fob_loadout_override(unit,unit_id,team_id)
				if unit.has_method("set_fireteam_id"): unit.call("set_fireteam_id",_get_fireteam_id_for_friendly_slot(slot_index,unit_id,team_id))
				_enqueue_initial_loadout_effect(simulation_root,unit_id)
			continue
		_apply_unit_identity_preset(unit, unit_id, team_id)
		_apply_fob_loadout_override(unit, unit_id, team_id)
		if use_2_5d_primary_view:
			_hide_legacy_unit_visual_children(unit)
		if unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", _get_fireteam_id_for_friendly_slot(slot_index, unit_id, team_id))
		if unit.has_method("set_respawn_manager"):
			var respawn_manager = get_node_or_null(respawn_manager_path)
			if respawn_manager != null:
				unit.call("set_respawn_manager", respawn_manager)
		if terrain_registry != null and unit.has_method("set_terrain_registry"):
			unit.call("set_terrain_registry", terrain_registry)
		if simulation_root.has_method("register_known_unit"):
			simulation_root.call("register_known_unit", unit_id, unit)
		var unit_registered: bool = unit_registry.has_method("has_unit") and bool(unit_registry.call("has_unit", unit_id))
		if unit is Node2D and not unit_registered:
			var spawn_alpha_marker := _resolve_marker(spawn_alpha_path)
			if spawn_alpha_marker != null:
				(unit as Node2D).global_position = spawn_alpha_marker.global_position + _get_friendly_spawn_offset(friendly_spawn_index)
			friendly_spawn_index += 1
		if unit is CanvasItem and not (defer_friendly_runtime_activation and unit_registered):
			(unit as CanvasItem).visible = not defer_friendly_runtime_activation
		if not defer_friendly_runtime_activation:
			if not unit_registered:
				unit_registry.call("register_unit", unit_id, unit)
			runtime_leader.call("add_unit_member", unit)
			_enqueue_initial_loadout_effect(simulation_root, unit_id)
			if first_unit == null:
				first_unit = unit
	if first_unit != null and not defer_friendly_runtime_activation:
		runtime_leader.call("assign", first_unit)
		var ftl_registry = get_node_or_null(ftl_registry_path)
		if ftl_registry != null and ftl_registry.has_method("has_ftl") and ftl_registry.has_method("register_ftl") and not bool(ftl_registry.call("has_ftl", team_id)):
			ftl_registry.call("register_ftl", team_id, runtime_leader)


func get_runtime_selection_status()->Dictionary:
	var result:Dictionary=_hex_selection_result.duplicate(true)
	result["applying"]=_hex_selection_applying
	result["queued"] = not _hex_selection_pending.is_empty()
	return result

## Reserve an existing unused actor slot and admit it at a verified station
## cell. Selection owns identity; SimulationRoot owns registry and hex state.
## A historical identity commit is retained as pending until ground admission.
func request_polisa_recruit_admission(profile: Dictionary, spawn_grid: Vector2i) -> Dictionary:
	var id := String(profile.get("unit_id", ""))
	if not _is_initialized or not _hex_setup_required or _hex_setup_presentation_only or _hex_selection_applying or not _hex_selection_pending.is_empty(): return {"ok":false,"reason":"selection_unavailable"}
	if not (id.begins_with("polisa_recruit_") or id.begins_with("station_shuttle_pilot_")) or selected_team_unit_ids.has(id) or _polisa_recruit_pending.has(id): return {"ok":false,"reason":"invalid_or_duplicate_recruit"}
	var simulation: Node = _get_simulation_root()
	var terrain: Node = get_node_or_null(terrain_registry_path)
	if simulation == null or not simulation.is_hex_ground_runtime_active() or terrain == null or not terrain.is_walkable(spawn_grid): return {"ok":false,"reason":"invalid_station_spawn"}
	var paths: Array = _friendly_unit_slot_paths if not _friendly_unit_slot_paths.is_empty() else _build_current_friendly_unit_slot_paths()
	if selected_team_unit_ids.size() >= paths.size(): return {"ok":false,"reason":"selection_capacity"}
	var old_ids := selected_team_unit_ids.duplicate()
	var old_teams := selected_team_fireteam_ids.duplicate()
	var old_configs := selected_team_unit_configs.duplicate(true)
	var old_defer := defer_friendly_runtime_activation
	selected_team_unit_ids.append(id)
	selected_team_fireteam_ids.append("")
	selected_team_unit_configs.append(profile.duplicate(true))
	_polisa_recruit_spawn[id] = spawn_grid
	_polisa_recruit_pending[id] = spawn_grid
	defer_friendly_runtime_activation = false
	apply_runtime_selection_contract(true, PackedStringArray([id]))
	defer_friendly_runtime_activation = old_defer
	_polisa_recruit_spawn.erase(id)
	var result := get_runtime_selection_status()
	if not result.get("ok", false) and not result.get("historical_committed", false):
		selected_team_unit_ids = old_ids
		selected_team_fireteam_ids = old_teams
		selected_team_unit_configs = old_configs
		_polisa_recruit_pending.erase(id)
		return result
	var admission := get_polisa_recruit_admission(id)
	return {"ok":true,"unit_id":id,"state":"admitted" if admission.ok else "pending","selection":result}

func get_polisa_recruit_admission(id: String) -> Dictionary:
	if not _polisa_recruit_pending.has(id): return {"ok":false,"reason":"unknown_recruit"}
	var simulation: Node = _get_simulation_root()
	var registry: Node = get_node_or_null(unit_registry_path)
	if simulation == null or registry == null: return {"ok":false,"reason":"station_unavailable"}
	var actor: Node = registry.get_unit(id)
	if not is_instance_valid(actor) or actor.is_queued_for_deletion() or not actor.visible or simulation.get_hex_unit_state(id).is_empty(): return {"ok":false,"reason":"admission_pending"}
	return {"ok":true,"unit_id":id,"actor_id":actor.get_instance_id()}

func retry_polisa_recruit_admission(id: String) -> Dictionary:
	if not _polisa_recruit_pending.has(id) or _hex_selection_applying or not _hex_selection_pending.is_empty(): return {"ok":false,"reason":"selection_unavailable"}
	var previous_defer := defer_friendly_runtime_activation
	_polisa_recruit_spawn[id] = _polisa_recruit_pending[id]
	defer_friendly_runtime_activation = false
	apply_runtime_selection_contract(true, PackedStringArray([id]))
	defer_friendly_runtime_activation = previous_defer
	_polisa_recruit_spawn.erase(id)
	return get_polisa_recruit_admission(id)

## Remove only completed service-owned actors from this live station. Existing
## player identities are preserved by the normal identity/registry owner path.
func retire_polisa_service_actors(unit_ids: PackedStringArray) -> Dictionary:
	if get_parent() == null or String(get_parent().get_meta("location_id", "")) != "polisa" or unit_ids.is_empty() or _hex_selection_applying or not _hex_selection_pending.is_empty(): return {"ok":false,"reason":"service_cleanup_unavailable"}
	var simulation: Node = _get_simulation_root()
	var registry: Node = get_node_or_null(unit_registry_path)
	if simulation == null or registry == null or not simulation.is_hex_ground_runtime_active(): return {"ok":false,"reason":"service_cleanup_unavailable"}
	var remove := {}
	var visits: Dictionary = get_parent().get_meta("singleplayer_visit_identities", {})
	for id: String in unit_ids:
		if not (id.begins_with("station_shuttle_pilot_") or id.begins_with("polisa_recruit_")) or remove.has(id): return {"ok":false,"reason":"invalid_service_actor"}
		for visit: Dictionary in visits.values():
			if Array(visit.get("unit_ids", [])).has(id) and String(visit.get("origin_kind", "")) != "station_service": return {"ok":false,"reason":"actor_owned_by_player_visit"}
		var actor: Node = registry.get_unit(id)
		if id.begins_with("polisa_recruit_") and is_instance_valid(actor) and (not bool(actor.get_meta("dropship_embarked", false)) or not simulation.get_hex_unit_state(id).is_empty()): return {"ok":false,"reason":"recruit_not_aboard"}
		if not selected_team_unit_ids.has(id) and (actor != null or simulation._known_units_by_id.has(id) or not simulation.get_hex_unit_state(id).is_empty()): return {"ok":false,"reason":"service_actor_context_changed"}
		remove[id] = true
	var ids := PackedStringArray()
	var teams := PackedStringArray()
	for index in range(selected_team_unit_ids.size()):
		var id := String(selected_team_unit_ids[index])
		if remove.has(id): continue
		ids.append(id)
		teams.append(String(selected_team_fireteam_ids[index]) if index < selected_team_fireteam_ids.size() else "")
	if ids.size() == selected_team_unit_ids.size(): return {"ok":true,"replayed":true}
	var old_ids := selected_team_unit_ids.duplicate()
	var old_teams := selected_team_fireteam_ids.duplicate()
	var old_configs := selected_team_unit_configs.duplicate(true)
	var old_full := allow_full_roster_when_selection_empty
	selected_team_unit_ids = ids; selected_team_fireteam_ids = teams
	selected_team_unit_configs = selected_team_unit_configs.filter(func(config): return not remove.has(String(config.get("unit_id", ""))))
	if ids.is_empty(): allow_full_roster_when_selection_empty = false
	apply_runtime_selection_contract(true)
	var result := get_runtime_selection_status()
	if not result.get("ok", false) and not result.get("historical_committed", false):
		selected_team_unit_ids = old_ids; selected_team_fireteam_ids = old_teams; selected_team_unit_configs = old_configs; allow_full_roster_when_selection_empty = old_full
		return result
	for id: String in unit_ids:
		if registry.get_unit(id) != null or simulation._known_units_by_id.has(id) or not simulation.get_hex_unit_state(id).is_empty(): return {"ok":false,"reason":"service_cleanup_pending","historical_committed":true}
		_polisa_recruit_pending.erase(id)
	return {"ok":true}


func _hex_selection_inputs()->Dictionary:
	return {"ids":selected_team_unit_ids.duplicate(),"fireteams":selected_team_fireteam_ids.duplicate(),"configs":selected_team_unit_configs.duplicate(true),"definitions":selected_fireteam_definitions.duplicate(true),"team":team_id,"defer":defer_friendly_runtime_activation,"allow_full":allow_full_roster_when_selection_empty,"loadouts":member_loadouts.duplicate(true),"recruit_spawn":_polisa_recruit_spawn.duplicate()}


func _hex_selection_owner_binding()->Dictionary:
	var simulation:Node=_get_simulation_root()
	var registry:Node=get_node_or_null(unit_registry_path)
	var leader:Node=get_node_or_null(runtime_leader_path)
	if simulation==null or registry==null or leader==null:return {}
	var binding:Dictionary={"root":weakref(simulation),"registry":weakref(registry),"leader":weakref(leader),"context":simulation.get_hex_ground_context_revision(),"actors":[]}
	var paths:Array=_friendly_unit_slot_paths if not _friendly_unit_slot_paths.is_empty() else _build_current_friendly_unit_slot_paths()
	for path in paths:
		var actor:Node=get_node_or_null(path)
		if actor==null or not actor.has_method("get_unit_id"):return {}
		var id:String=String(actor.call("get_unit_id"))
		binding.actors.append({"actor":weakref(actor),"unit_id":id,"identity":simulation._hex_payload_identity(id)})
	return binding


func _hex_selection_owner_current(binding:Dictionary)->bool:
	if binding.is_empty():return false
	var simulation:Node=binding.root.get_ref()
	if not is_instance_valid(simulation) or simulation.is_queued_for_deletion() or simulation!=_get_simulation_root() or simulation.get_hex_ground_context_revision()!=binding.context:return false
	var registry:Node=binding.registry.get_ref()
	var leader:Node=binding.leader.get_ref()
	if not is_instance_valid(registry) or registry.is_queued_for_deletion() or registry!=get_node_or_null(unit_registry_path) or registry!=simulation.get_unit_registry() or not is_instance_valid(leader) or leader.is_queued_for_deletion() or leader!=get_node_or_null(runtime_leader_path):return false
	for entry in binding.actors:
		var actor:Node=entry.actor.get_ref()
		if not is_instance_valid(actor) or actor.is_queued_for_deletion() or String(actor.call("get_unit_id"))!=entry.unit_id or simulation._hex_payload_identity(entry.unit_id)!=entry.identity:return false
	return true


func _run_hex_selection_request(request:Dictionary)->void:
	if not _hex_selection_owner_current(request.get("binding",{})):
		_hex_selection_result={"ok":false,"reason":"selection_context_changed"}
		return
	var inputs:Dictionary=request.inputs
	selected_team_unit_ids=inputs.ids;selected_team_fireteam_ids=inputs.fireteams
	selected_team_unit_configs=inputs.configs;selected_fireteam_definitions=inputs.definitions
	team_id=inputs.team;defer_friendly_runtime_activation=inputs.defer
	allow_full_roster_when_selection_empty=inputs.allow_full;member_loadouts=inputs.loadouts
	_polisa_recruit_spawn=inputs.recruit_spawn
	_hex_selection_applying=true
	_hex_selection_active_signature=String(request.signature)
	_hex_selection_active_binding=request.binding
	var lifetime:WeakRef=weakref(self)
	var result:Dictionary=_apply_hex_runtime_selection(bool(request.preserve),PackedStringArray(request.refresh))
	if not is_instance_valid(lifetime.get_ref()):return
	_hex_selection_result=result
	_hex_selection_applying=false
	_hex_selection_active_signature=""
	_hex_selection_active_binding={}


func _apply_hex_runtime_selection(preserve_existing:bool,refresh_existing_ids:PackedStringArray)->Dictionary:
	var simulation:Node=_get_simulation_root()
	var registry:Node=get_node_or_null(unit_registry_path)
	var leader:Node=get_node_or_null(runtime_leader_path)
	if simulation==null or registry==null or leader==null or simulation.get_unit_registry()!=registry:return {"ok":false,"reason":"selection_owner_unavailable"}
	if not _hex_setup_presentation_only and not simulation.is_hex_ground_runtime_active():return {"ok":false,"reason":"selection_hex_inactive"}
	if not registry.has_method("apply_lookup_bindings") or not leader.has_method("prepare_unit_member_changes") or not leader.has_method("finalize_unit_member_changes"):return {"ok":false,"reason":"selection_lookup_api_unavailable"}
	var ftls:Node=get_node_or_null(ftl_registry_path)
	if ftls!=null and ftls.has_method("get_ftl") and ftls.call("has_ftl",team_id) and ftls.call("get_ftl",team_id)!=leader:return {"ok":false,"reason":"selection_ftl_conflict"}
	var paths:Array=_friendly_unit_slot_paths.duplicate()
	if paths.is_empty():paths=_build_current_friendly_unit_slot_paths()
	if paths.size()>64 or selected_team_unit_ids.size()>paths.size():return {"ok":false,"reason":"selection_capacity"}
	var pool:Array=[]
	var by_id:Dictionary={}
	for path in paths:
		var actor:Node=get_node_or_null(path)
		if actor==null or not actor is Node2D or not actor.has_method("prepare_runtime_identity_change") or not actor.has_method("get_unit_id"):return {"ok":false,"reason":"selection_actor_unavailable"}
		var id:String=String(actor.call("get_unit_id"))
		if id.is_empty() or by_id.has(id):return {"ok":false,"reason":"selection_actor_alias"}
		var known:Variant=simulation._known_units_by_id.get(id)
		var indexed:Variant=registry.get_unit(id)
		if (known!=null and known!=actor) or (indexed!=null and indexed!=actor):return {"ok":false,"reason":"selection_source_conflict"}
		pool.append(actor);by_id[id]=actor
	var desired:PackedStringArray=PackedStringArray()
	var seen:Dictionary={}
	for index in range(paths.size()):
		if not _is_friendly_slot_enabled(index):continue
		var id:String=_get_selected_unit_id_for_friendly_slot(index,String(pool[index].call("get_unit_id")))
		if selected_team_unit_ids.is_empty() and id.begins_with("__unused_friendly_slot_"):continue
		if id.is_empty() or id!=id.strip_edges() or id.begins_with("__unused_friendly_slot_") or seen.has(id):return {"ok":false,"reason":"selection_duplicate_or_invalid_id"}
		seen[id]=true;desired.append(id)
		var actor:Variant=by_id.get(id)
		if (registry.has_unit(id) and registry.get_unit(id)!=actor) or (simulation._known_units_by_id.has(id) and simulation._known_units_by_id[id]!=actor):return {"ok":false,"reason":"selection_target_conflict"}
	var chosen:Dictionary={}
	var assignments:Array[Dictionary]=[]
	for id in desired:
		if by_id.has(id):chosen[by_id[id].get_instance_id()]=true
	for index in range(desired.size()):
		var id:String=desired[index]
		var actor:Variant=by_id.get(id)
		if actor==null:
			for candidate in pool:
				if not chosen.has(candidate.get_instance_id()):actor=candidate;break
			if actor==null:return {"ok":false,"reason":"selection_capacity"}
			chosen[actor.get_instance_id()]=true
		var same:bool=String(actor.call("get_unit_id"))==id and String(actor.call("get_team_id"))==team_id and simulation._known_units_by_id.get(id)==actor
		assignments.append({"actor":actor,"unit_id":id,"index":index,"same":same})
	var changes:Array[Dictionary]=[]
	var direct:Array=[]
	var marker:Marker2D=_resolve_marker(spawn_alpha_path)
	var spawn_index:=0
	_build_unit_loadout_modifiers()
	for entry in assignments:
		var actor:Node2D=entry.actor
		var id:String=entry.unit_id
		var reset:bool=not bool(entry.same)
		if reset or not preserve_existing or refresh_existing_ids.has(id):
			var config:Dictionary={}
			if reset:
				config=UNIT_ROSTER_PRESETS_SCRIPT.get_preset(id,team_id).duplicate(true)
				config.merge(_get_selected_unit_config(id),true)
			config.merge(_get_fob_loadout_identity_config(id,team_id),true)
			config.merge({"unit_id":id,"team_id":team_id,"fireteam_id":_get_fireteam_id_for_friendly_slot(int(entry.index),id,team_id)},true)
			var dependencies:Dictionary={}
			if not terrain_registry_path.is_empty():dependencies["terrain_registry"]=get_node_or_null(terrain_registry_path)
			if not respawn_manager_path.is_empty():dependencies["respawn_manager"]=get_node_or_null(respawn_manager_path)
			var prepared:Dictionary=actor.call("prepare_runtime_identity_change",simulation,config,reset,dependencies)
			if not prepared.get("ok",false):return prepared
			changes.append({"actor":actor,"old_id":String(actor.call("get_unit_id")),"next_id":id,"prepared":prepared.prepared,"reset":reset,"known_new":true,"register_new":_hex_setup_presentation_only or not defer_friendly_runtime_activation})
		if reset and not defer_friendly_runtime_activation and not _hex_setup_presentation_only:
			var position:Vector2=marker.global_position+_get_friendly_spawn_offset(spawn_index) if marker!=null else actor.global_position
			if _polisa_recruit_spawn.has(id): position = _get_simulation_root().get_hex_ground_terrain_registry().grid_to_world(_polisa_recruit_spawn[id])
			if not position.is_finite():return {"ok":false,"reason":"selection_invalid_spawn"}
			direct.append({"actor":actor,"position":position})
			spawn_index+=1
		elif not reset and _polisa_recruit_spawn.has(id) and simulation.get_hex_unit_state(id).is_empty() and not defer_friendly_runtime_activation:
			direct.append({"actor":actor,"position":simulation.get_hex_ground_terrain_registry().grid_to_world(_polisa_recruit_spawn[id])})
	for index in range(pool.size()):
		var actor:Node=pool[index]
		if chosen.has(actor.get_instance_id()):continue
		var old_id:String=String(actor.call("get_unit_id"))
		var config:Dictionary={"unit_id":"__unused_friendly_slot_%d"%index,"team_id":"team_unused","fireteam_id":"","display_name":"Unused Friendly Slot","is_fireteam_lead":false}
		var prepared:Dictionary=actor.call("prepare_runtime_identity_change",simulation,config,true)
		if not prepared.get("ok",false):return prepared
		changes.append({"actor":actor,"old_id":old_id,"next_id":config.unit_id,"prepared":prepared.prepared,"reset":true,"known_new":false,"register_new":false})
	var removals:Array=[]
	for change in changes:
		if change.reset:removals.append(change.actor)
	var additions:Array=[]
	var preferred_entity:Node=null
	if not _hex_setup_presentation_only:
		for entry in assignments:
			# Station service crew remains a registered Hex actor, but is not
			# subordinate to the player's RuntimeLeader or its group commands.
			if String(entry.unit_id).begins_with("station_shuttle_pilot_"):
				if not removals.has(entry.actor): removals.append(entry.actor)
				continue
			var active:bool=(not bool(entry.same) and not defer_friendly_runtime_activation) or (bool(entry.same) and registry.get_unit(entry.unit_id)==entry.actor and not bool(entry.actor.get_meta("dropship_embarked",false)))
			if active:
				additions.append(entry.actor)
				if preferred_entity==null:preferred_entity=entry.actor
	var member_model:Dictionary=leader.call("prepare_unit_member_changes",removals,additions,preferred_entity)
	if not member_model.get("ok",false) or not leader.call("validate_unit_member_changes",member_model):return {"ok":false,"reason":"selection_leader_changed"}
	var committed:Dictionary=simulation.commit_hex_actor_identity_changes(self,changes,_hex_setup_presentation_only)
	if not committed.get("ok",false):return committed
	leader.call("_publish_unit_member_changes",member_model)
	for actor in pool:
		var id:String=String(actor.call("get_unit_id"))
		committed.actors[id]=actor.get_instance_id()
		committed.identities[id]=simulation._hex_payload_identity(id)
	var scope:Dictionary={"root":weakref(simulation),"receipt":committed,"signature":_hex_selection_active_signature,"inputs":JSON.stringify(_hex_selection_inputs()),"owner":_hex_selection_owner_binding()}
	_hex_selection_active_binding=scope.owner
	var guard:Callable=Callable(self,"_hex_selection_scope_current").bind(scope)
	for change in changes:
		if change.reset:
			change.actor.set_meta("dropship_embarked",false)
			change.actor.visible=false
			if not guard.is_valid() or not guard.call():return {"ok":false,"reason":"selection_context_changed","historical_committed":true}
	for change in changes:
		change.actor.call("finalize_runtime_identity_change",change.prepared,guard)
		if not guard.is_valid() or not guard.call():
			if is_instance_valid(leader) and not leader.is_queued_for_deletion() and is_instance_valid(simulation) and simulation.get_unit_registry() != registry:
				leader.call("discard_stale_unit_member_additions",member_model)
			return {"ok":false,"reason":"selection_context_changed","historical_committed":true}
	for entry in direct:
		entry.actor.global_position=entry.position
		if not guard.is_valid() or not guard.call():return {"ok":false,"reason":"selection_context_changed","historical_committed":true}
	var admission:Array=[]
	for entry in assignments:
		var actor:Node=entry.actor
		var id:String=entry.unit_id
		if use_2_5d_primary_view:_hide_legacy_unit_visual_children(actor)
		if not guard.is_valid() or not guard.call():return {"ok":false,"reason":"selection_context_changed","historical_committed":true}
		if _hex_setup_presentation_only:
			actor.visible=false
			continue
		if registry.get_unit(id)!=actor:continue # Existing staged/aboard persons remain staged.
		if not bool(entry.same) or not preserve_existing or refresh_existing_ids.has(id):_enqueue_initial_loadout_effect(simulation,id)
		if simulation.get_hex_unit_state(id).is_empty() and not bool(actor.get_meta("dropship_embarked",false)):admission.append(actor)
	if not admission.is_empty():_admit_hex_setup_nodes(admission)
	if not guard.is_valid() or not guard.call():return {"ok":false,"reason":"selection_context_changed","historical_committed":true}
	if _hex_setup_presentation_only and simulation.has_method("refresh_multiplayer_replica_presence"):
		simulation.call("refresh_multiplayer_replica_presence")
		if not guard.is_valid() or not guard.call():return {"ok":false,"reason":"selection_context_changed","historical_committed":true}
	if ftls!=null and not additions.is_empty() and ftls.has_method("has_ftl") and not ftls.call("has_ftl",team_id):ftls.call("register_ftl",team_id,leader)
	leader.call("finalize_unit_member_changes",member_model,guard)
	if not guard.is_valid() or not guard.call():return {"ok":false,"reason":"selection_context_changed","historical_committed":true}
	return {"ok":true,"status":"waiting_admission" if not _hex_setup_pending.is_empty() else "committed","pending_count":_hex_setup_pending.size()}


func _hex_selection_scope_current(scope:Dictionary)->bool:
	var owner:Node=scope.root.get_ref()
	return not is_queued_for_deletion() and _hex_selection_pending.is_empty() and _hex_selection_active_signature==scope.signature and JSON.stringify(_hex_selection_inputs())==scope.inputs and _hex_selection_owner_current(scope.owner) and is_instance_valid(owner) and owner==_get_simulation_root() and owner.is_hex_actor_identity_commit_current(scope.receipt)


func _build_current_friendly_unit_slot_paths() -> Array:
	var result: Array = []
	for unit_path in unit_paths:
		var unit = get_node_or_null(unit_path)
		if unit == null or not unit.has_method("get_team_id"):
			continue
		var unit_team_id: String = String(unit.call("get_team_id")).strip_edges()
		if unit_team_id == team_id or unit_team_id == "team_unused":
			result.append(unit_path)
	return result


func _get_simulation_root() -> Node:
	if simulation_root_path.is_empty():
		return null
	return get_node_or_null(simulation_root_path)


func get_expected_unit_presence_snapshot() -> Dictionary:
	var friendly_unit_ids: Array = []
	var inactive_friendly_unit_ids: Array = []
	var enemy_unit_ids: Array = []
	for unit_path in unit_paths:
		var unit = get_node_or_null(unit_path)
		if unit == null or not unit.has_method("get_unit_id") or not unit.has_method("get_team_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		var unit_team_id: String = String(unit.call("get_team_id")).strip_edges()
		if unit_id.is_empty():
			continue
		if unit_team_id == team_id:
			friendly_unit_ids.append(unit_id)
		elif unit_team_id == "team_unused":
			inactive_friendly_unit_ids.append(unit_id)
		else:
			if _mission_scenario != null and bool(_mission_scenario.call("is_noncombat_singleplayer")):
				continue
			enemy_unit_ids.append(unit_id)
	friendly_unit_ids.sort()
	inactive_friendly_unit_ids.sort()
	enemy_unit_ids.sort()
	return {
		"friendly_unit_ids": friendly_unit_ids,
		"inactive_friendly_unit_ids": inactive_friendly_unit_ids,
		"enemy_unit_ids": enemy_unit_ids,
		"defer_friendly_runtime_activation": defer_friendly_runtime_activation,
	}


func get_scenario_tactical_authoring_snapshot() -> Dictionary:
	return _scenario_tactical_authoring.duplicate(true)


func get_scenario_air_asset_risk_context_for_unit(enemy_id: String) -> Dictionary:
	if _mission_scenario == null:
		return {}
	var normalized_enemy_id: String = enemy_id.strip_edges()
	if normalized_enemy_id.is_empty():
		return {}
	for threat_variant in Array(_mission_scenario.call("get_enemy_air_asset_threats", _loaded_terrain_map_data)):
		var threat: Dictionary = Dictionary(threat_variant)
		if Array(threat.get("enemy_ids", [])).has(normalized_enemy_id):
			return threat.duplicate(true)
	return {}


func _build_unit_loadout_modifiers() -> void:
	unit_loadout_modifiers_by_unit_id.clear()
	if member_loadouts.is_empty():
		return
	var resolver = LOADOUT_MODIFIER_RESOLVER_SCRIPT.new()
	if resolver == null or not resolver.has_method("resolve_for_member_loadouts"):
		return
	var resolved: Dictionary = Dictionary(resolver.call("resolve_for_member_loadouts", member_loadouts))
	for unit_id_variant in resolved.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		var modifiers_dict: Dictionary = Dictionary(resolved.get(unit_id_variant, {})).duplicate(true)
		if modifiers_dict.is_empty():
			continue
		unit_loadout_modifiers_by_unit_id[unit_id] = modifiers_dict


func _enqueue_initial_loadout_effect(simulation_root: Node, unit_id: String) -> void:
	if simulation_root == null or not simulation_root.has_method("enqueue_effect"):
		return
	var modifiers_dict: Dictionary = get_unit_loadout_modifiers_dict(unit_id)
	if modifiers_dict.is_empty():
		return
	simulation_root.call(
		"enqueue_effect",
		{
			"effect_type": "apply_loadout_modifiers",
			"unit_id": unit_id,
			"modifiers": modifiers_dict,
		}
	)


func _is_friendly_slot_enabled(slot_index: int) -> bool:
	if selected_team_unit_ids.is_empty():
		return allow_full_roster_when_selection_empty

	return slot_index >= 0 and slot_index < selected_team_unit_ids.size()


func _get_selected_unit_id_for_friendly_slot(slot_index: int, fallback_unit_id: String) -> String:
	if selected_team_unit_ids.is_empty():
		return fallback_unit_id

	if not _is_friendly_slot_enabled(slot_index):
		return fallback_unit_id

	var selected_unit_id: String = String(selected_team_unit_ids[slot_index]).strip_edges()
	if selected_unit_id.is_empty():
		return fallback_unit_id

	return selected_unit_id


func _deactivate_unused_friendly_slot(unit, slot_index: int) -> void:
	if unit == null or not unit.has_method("apply_identity_config"):
		return
	unit.call(
		"apply_identity_config",
		{
			"unit_id": "__unused_friendly_slot_%d" % maxi(slot_index, 0),
			"display_name": "Unused Friendly Slot",
			"team_id": "team_unused",
			"fireteam_id": "",
			"is_fireteam_lead": false,
		}
	)


func _resolve_marker(node_path: NodePath) -> Marker2D:
	if node_path.is_empty():
		return null

	return get_node_or_null(node_path) as Marker2D


func _should_defer_runtime_enemy_slot_creation() -> bool:
	if _scenario_enemy_ids.is_empty():
		return false
	var existing_enemy_count: int = 0
	for unit_path in unit_paths:
		var unit = get_node_or_null(unit_path)
		if unit == null or not unit.has_method("get_team_id"):
			continue
		if String(unit.call("get_team_id")) != team_id:
			existing_enemy_count += 1
	return _scenario_enemy_ids.size() > existing_enemy_count


func _build_runtime_unit_paths() -> Array:
	var result: Array = unit_paths.duplicate()
	if _scenario_enemy_ids.is_empty():
		return result
	var existing_enemy_count: int = 0
	var template_enemy: Node = null
	for unit_path in result:
		var unit = get_node_or_null(unit_path)
		if unit == null or not unit.has_method("get_team_id"):
			continue
		if String(unit.call("get_team_id")) == team_id:
			continue
		existing_enemy_count += 1
		if template_enemy == null:
			template_enemy = unit
	var missing_enemy_count: int = _scenario_enemy_ids.size() - existing_enemy_count
	if missing_enemy_count <= 0 or template_enemy == null:
		return result
	var parent: Node = template_enemy.get_parent()
	if parent == null:
		return result
	for index in range(missing_enemy_count):
		var duplicate_enemy: Node = template_enemy.duplicate()
		duplicate_enemy.name = _make_unique_child_name(parent, "ScenarioEnemySlot%02d" % (existing_enemy_count + index + 1))
		parent.add_child(duplicate_enemy)
		if duplicate_enemy.has_method("apply_identity_config"):
			duplicate_enemy.call("apply_identity_config", {"team_id": String(template_enemy.call("get_team_id")) if template_enemy.has_method("get_team_id") else "team_bravo"})
		var enemy_path: NodePath = get_path_to(duplicate_enemy)
		result.append(enemy_path)
		_append_combat_enemy_unit_path(enemy_path)
	unit_paths = result.duplicate()
	return result


func _make_unique_child_name(parent: Node, base_name: String) -> String:
	var normalized_base: String = base_name.strip_edges()
	if normalized_base.is_empty():
		normalized_base = "ScenarioEnemySlot"
	var candidate: String = normalized_base
	var suffix: int = 2
	while parent.get_node_or_null(candidate) != null:
		candidate = "%s_%02d" % [normalized_base, suffix]
		suffix += 1
	return candidate


func _append_combat_enemy_unit_path(enemy_path: NodePath) -> void:
	var combat_driver = get_node_or_null("../CombatLoopDriver")
	if combat_driver == null:
		return
	var next_paths: Array = Array(combat_driver.get("enemy_unit_paths")).duplicate()
	if next_paths.has(enemy_path):
		return
	next_paths.append(enemy_path)
	combat_driver.set("enemy_unit_paths", next_paths)


func _get_friendly_spawn_offset(index: int) -> Vector2:
	var offsets: Array[Vector2] = [
		Vector2(-24.0, 12.0),
		Vector2(0.0, 0.0),
		Vector2(24.0, -12.0),
		Vector2(-48.0, 24.0),
		Vector2(48.0, -24.0),
		Vector2(-72.0, 36.0),
		Vector2(72.0, -36.0),
		Vector2(0.0, 28.0),
	]
	if index >= 0 and index < offsets.size():
		return offsets[index]

	return Vector2(24.0 * float(index), 0.0)


func _get_enemy_spawn_offset(index: int) -> Vector2:
	var offsets: Array[Vector2] = [
		Vector2(-96.0, -48.0),
		Vector2(-32.0, 16.0),
		Vector2(32.0, -16.0),
		Vector2(96.0, 48.0),
		Vector2(-128.0, 52.0),
		Vector2(128.0, -52.0),
	]
	if index >= 0 and index < offsets.size():
		return offsets[index]

	return Vector2(32.0 * float(index), 0.0)


func _setup_respawn_manager(spawn_alpha: Marker2D, spawn_bravo: Marker2D) -> void:
	var respawn_manager = get_node_or_null(respawn_manager_path)
	if respawn_manager == null or not respawn_manager.has_method("set_spawn_position"):
		return

	if spawn_alpha != null:
		respawn_manager.call("set_spawn_position", team_id, spawn_alpha.global_position)

	if spawn_bravo != null:
		respawn_manager.call("set_spawn_position", "team_bravo", spawn_bravo.global_position)


func _setup_objective_status(simulation_root: Node, objective_marker: Marker2D) -> void:
	if objective_marker == null or not simulation_root.has_method("set_objective_status"):
		return

	var objective_status = OBJECTIVE_STATUS_SCRIPT.new()
	var objective_dict: Dictionary = _get_scenario_objective()
	var objective_marker_id: String = String(objective_dict.get("marker_id", "objective_point")).strip_edges()
	objective_status.objective_id = objective_marker_id if not objective_marker_id.is_empty() else "scenario_objective"
	objective_status.position = _get_scenario_objective_position(objective_marker.global_position)
	objective_status.capture_radius = maxf(float(objective_dict.get("capture_radius", 80.0)), 1.0)
	simulation_root.call("set_objective_status", objective_status)


func _apply_scenario_timer_to_combat_driver() -> void:
	if _mission_scenario == null:
		return
	var combat_driver = get_node_or_null("../CombatLoopDriver")
	if combat_driver == null:
		return
	var scenario_win_condition: String = String(_mission_scenario.get("win_condition")).strip_edges().to_lower()
	if not scenario_win_condition.is_empty():
		_set_property_if_present(combat_driver, "win_condition", scenario_win_condition)
	if combat_driver.has_method("configure_scenario_runtime_gates_from_file"):
		combat_driver.call("configure_scenario_runtime_gates_from_file", scenario_file_path)
	var scenario_time_limit: float = maxf(float(_mission_scenario.get("time_limit_seconds")), 0.0)
	if scenario_time_limit <= 0.0:
		return
	combat_driver.set("mission_time_limit_seconds", scenario_time_limit)


func _setup_enemy_waves(enemy_units: Array) -> void:
	var enemy_wave_controller = get_node_or_null(enemy_wave_controller_path)
	if enemy_wave_controller == null or not enemy_wave_controller.has_method("initialize_enemy_units"):
		return
	if enemy_wave_controller.has_method("set_hex_ground_required"):
		enemy_wave_controller.call("set_hex_ground_required",_hex_setup_required)
	_apply_scenario_wave_config(enemy_wave_controller)
	if enemy_wave_controller.has_method("set_patrol_paths"):
		enemy_wave_controller.call("set_patrol_paths", _build_enemy_patrol_paths())
	if enemy_wave_controller.has_method("set_enemy_tactics"):
		enemy_wave_controller.call("set_enemy_tactics", _build_enemy_tactics_by_unit_id(enemy_units))

	enemy_wave_controller.call("initialize_enemy_units", enemy_units)


func _build_enemy_tactics_by_unit_id(enemy_units: Array) -> Dictionary:
	var result: Dictionary = {}
	var grid_size: Vector2i = _get_loaded_grid_size()
	var default_config: Dictionary = _get_default_enemy_tactics_config()
	if _mission_scenario != null:
		for group_variant in Array(_mission_scenario.get("enemy_groups")):
			var group: Dictionary = Dictionary(group_variant)
			var group_tactics: Dictionary = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", group.get("tactics", default_config), grid_size)
			var group_id: String = String(group.get("group_id", "")).strip_edges()
			if not group_id.is_empty():
				group_tactics["group_id"] = group_id
			for enemy_id_variant in Array(group.get("enemy_ids", [])):
				var enemy_id: String = String(enemy_id_variant).strip_edges()
				if enemy_id.is_empty():
					continue
				result[enemy_id] = group_tactics.duplicate(true)
	for enemy_unit in enemy_units:
		if enemy_unit == null or not enemy_unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(enemy_unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty() or result.has(unit_id):
			continue
		result[unit_id] = default_config.duplicate(true)
	return result


func _get_default_enemy_tactics_config() -> Dictionary:
	if _loaded_terrain_map_data != null and _loaded_terrain_map_data.has_method("get_enemy_team_config"):
		return _loaded_terrain_map_data.call("get_enemy_team_config", "default")
	return ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", _get_loaded_grid_size())


func _get_loaded_grid_size() -> Vector2i:
	if _loaded_terrain_map_data != null and _loaded_terrain_map_data.has_method("get_grid_size"):
		return _loaded_terrain_map_data.call("get_grid_size")
	return Vector2i.ZERO


func _build_enemy_patrol_paths() -> Dictionary:
	var result: Dictionary = {}
	if _loaded_terrain_map_data == null or not _loaded_terrain_map_data.has_method("get_patrol_paths"):
		return result
	if _mission_scenario != null:
		for binding_variant in Array(_mission_scenario.get("patrol_bindings")):
			var binding: Dictionary = Dictionary(binding_variant)
			var target_id: String = String(binding.get("target_id", "")).strip_edges()
			var patrol_path_id: String = String(binding.get("patrol_path_id", "")).strip_edges()
			if target_id.is_empty() or patrol_path_id.is_empty():
				continue
			var bound_path: Array = Array(_loaded_terrain_map_data.call("get_patrol_path", patrol_path_id))
			if bound_path.is_empty():
				continue
			var target_unit_ids: PackedStringArray = _resolve_patrol_binding_targets(target_id)
			for target_unit_id in target_unit_ids:
				result[String(target_unit_id)] = bound_path.duplicate(true)
	var patrol_paths: Dictionary = Dictionary(_loaded_terrain_map_data.call("get_patrol_paths"))
	for spawn_id_variant in patrol_paths.keys():
		var spawn_id: String = String(spawn_id_variant).strip_edges()
		if spawn_id.is_empty() or result.has(spawn_id):
			continue
		result[spawn_id] = Array(patrol_paths.get(spawn_id_variant, [])).duplicate(true)
	return result


func use_prepared_terrain_resource_cache(cache: RefCounted) -> void:
	_prepared_terrain_resource_cache = cache


func use_prepared_terrain(path: String, map) -> void:
	if map != null and not map.get_tiles().is_empty():
		_loaded_terrain_map_path = path
		_loaded_terrain_map_data = map


func _load_mission_scenario_if_available() -> void:
	_mission_scenario = null
	_scenario_enemy_ids = PackedStringArray()
	_scenario_tactical_authoring = {}
	var normalized_path: String = scenario_file_path.strip_edges()
	if normalized_path.is_empty():
		return
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", normalized_path)
	if scenario == null:
		push_warning("MissionTestSetup could not load mission scenario: %s" % normalized_path)
		return
	var scenario_map_path: String = String(scenario.get("map_file_path")).strip_edges()
	if not scenario_map_path.is_empty():
		map_file_path = scenario_map_path
		if _loaded_terrain_map_data == null or _loaded_terrain_map_path != scenario_map_path:
			_loaded_terrain_map_path = scenario_map_path
			_loaded_terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", scenario_map_path)
	var validation: Dictionary = Dictionary(scenario.call("validate", _loaded_terrain_map_data))
	if not bool(validation.get("valid", false)):
		push_warning("Mission scenario has authoring issues: %s" % ", ".join(PackedStringArray(validation.get("errors", PackedStringArray()))))
	_mission_scenario = scenario
	_scenario_enemy_ids = PackedStringArray(_mission_scenario.call("get_enemy_ids"))
	_scenario_tactical_authoring = Dictionary(_mission_scenario.call("get_tactical_authoring_config")).duplicate(true)


func _get_scenario_enemy_id_for_slot(slot_index: int, fallback_unit_id: String) -> String:
	if _scenario_enemy_ids.is_empty() or slot_index < 0 or slot_index >= _scenario_enemy_ids.size():
		return fallback_unit_id
	var scenario_unit_id: String = String(_scenario_enemy_ids[slot_index]).strip_edges()
	if scenario_unit_id.is_empty():
		return fallback_unit_id
	return scenario_unit_id


func _get_enemy_spawn_position(unit_id: String, fallback_marker: Marker2D) -> Vector2:
	var fallback_position: Vector2 = fallback_marker.global_position if fallback_marker != null else Vector2.ZERO
	var group: Dictionary = _find_scenario_enemy_group_for_unit(unit_id)
	if group.has("spawn_position"):
		return _coerce_vector2(group.get("spawn_position", fallback_position), fallback_position)
	var spawn_marker_id: String = String(group.get("spawn_marker_id", "")).strip_edges()
	if not spawn_marker_id.is_empty() and _loaded_terrain_map_data != null and _loaded_terrain_map_data.has_method("get_marker_position"):
		return _loaded_terrain_map_data.call("get_marker_position", spawn_marker_id, fallback_position)
	return fallback_position


func _find_scenario_enemy_group_for_unit(unit_id: String) -> Dictionary:
	if _mission_scenario == null:
		return {}
	var normalized_unit_id: String = unit_id.strip_edges()
	for group_variant in Array(_mission_scenario.get("enemy_groups")):
		var group: Dictionary = Dictionary(group_variant)
		for enemy_id_variant in Array(group.get("enemy_ids", [])):
			if String(enemy_id_variant).strip_edges() == normalized_unit_id:
				return group
	return {}


func _resolve_patrol_binding_targets(target_id: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var normalized_target_id: String = target_id.strip_edges()
	if normalized_target_id.is_empty():
		return result
	if _scenario_enemy_ids.has(normalized_target_id):
		result.append(normalized_target_id)
		return result
	if _mission_scenario != null:
		for group_variant in Array(_mission_scenario.get("enemy_groups")):
			var group: Dictionary = Dictionary(group_variant)
			if String(group.get("group_id", "")).strip_edges() == normalized_target_id or String(group.get("spawn_marker_id", "")).strip_edges() == normalized_target_id:
				for enemy_id_variant in Array(group.get("enemy_ids", [])):
					var enemy_id: String = String(enemy_id_variant).strip_edges()
					if not enemy_id.is_empty() and not result.has(enemy_id):
						result.append(enemy_id)
	if result.is_empty():
		result.append(normalized_target_id)
	return result


func _apply_scenario_wave_config(enemy_wave_controller: Node) -> void:
	if _mission_scenario == null or enemy_wave_controller == null:
		return
	var wave_config: Dictionary = Dictionary(_mission_scenario.get("wave_config"))
	if wave_config.is_empty():
		return
	_set_property_if_present(enemy_wave_controller, "wave_count", maxi(int(wave_config.get("wave_count", enemy_wave_controller.get("wave_count"))), 0))
	_set_property_if_present(enemy_wave_controller, "units_per_wave", maxi(int(wave_config.get("units_per_wave", enemy_wave_controller.get("units_per_wave"))), 1))
	_set_property_if_present(enemy_wave_controller, "first_wave_delay_seconds", maxf(float(wave_config.get("first_wave_delay_seconds", enemy_wave_controller.get("first_wave_delay_seconds"))), 0.0))
	_set_property_if_present(enemy_wave_controller, "wave_delay_seconds", maxf(float(wave_config.get("wave_delay_seconds", enemy_wave_controller.get("wave_delay_seconds"))), 0.0))


func _set_property_if_present(node: Object, property_name: String, value: Variant) -> void:
	if node == null or property_name.is_empty():
		return
	for property_info in node.get_property_list():
		var info: Dictionary = Dictionary(property_info)
		if String(info.get("name", "")) == property_name:
			node.set(property_name, value)
			return


func _apply_scenario_objective_to_marker(objective_marker: Marker2D) -> void:
	if objective_marker == null or _mission_scenario == null:
		return
	objective_marker.global_position = _get_scenario_objective_position(objective_marker.global_position)


func _get_scenario_objective() -> Dictionary:
	if _mission_scenario == null:
		return {}
	return Dictionary(_mission_scenario.get("objective"))


func _get_scenario_objective_position(fallback_position: Vector2) -> Vector2:
	if _mission_scenario == null:
		return fallback_position
	return _mission_scenario.call("get_objective_position", _loaded_terrain_map_data, fallback_position)


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback


func _setup_terrain_registry():
	_terrain_setup_error={}
	if terrain_registry_path.is_empty():
		return null

	var terrain_registry = get_node_or_null(terrain_registry_path)
	if terrain_registry == null:
		return null

	if not terrain_registry.has_method("clear_tiles") or not terrain_registry.has_method("configure_iso_grid") or not terrain_registry.has_method("register_tile"):
		return terrain_registry

	if _try_load_terrain_from_json(terrain_registry):
		return terrain_registry
	if not _terrain_setup_error.is_empty():return null

	_setup_terrain_from_hardcode(terrain_registry)
	return terrain_registry


func _try_load_terrain_from_json(terrain_registry) -> bool:
	if map_file_path.is_empty() or not FileAccess.file_exists(map_file_path):
		return false

	var terrain_map_data = _loaded_terrain_map_data
	if terrain_map_data == null or _loaded_terrain_map_path != map_file_path:
		terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", map_file_path)
	if terrain_map_data!=null and terrain_map_data.has_load_issue():
		_terrain_setup_error={"ok":false,"reason":"map_load_issue"}
		return false
	if terrain_map_data != null:
		var imported: Dictionary = terrain_map_data.activate_hex_tactical_runtime()
		if not imported.get("ok",false):
			_terrain_setup_error = imported
			return false
	if terrain_map_data!=null:
		var context:Dictionary=SIMULATION_ROOT_SCRIPT.validate_hex_ground_map_data(terrain_map_data)
		if not context.ok:
			_terrain_setup_error=context
			return false
		if not String(terrain_map_data.get_tactical_grid_rules()).is_empty() and terrain_map_data.get_tiles().is_empty():
			_terrain_setup_error={"ok":false,"reason":"hex_map_empty"}
			return false
	if terrain_map_data == null or terrain_map_data.call("get_tiles").is_empty():
		return false
	_loaded_terrain_map_data = terrain_map_data
	_loaded_terrain_map_path = map_file_path

	var tile_size: Dictionary = terrain_map_data.call("get_tile_size")
	terrain_registry.call("clear_tiles")
	terrain_registry.call(
		"configure_iso_grid",
		terrain_map_data.call("get_grid_origin"),
		float(tile_size.get("half_width", 64.0)),
		float(tile_size.get("half_height", 32.0)),
		String(terrain_map_data.call("get_grid_topology"))
	)

	for tile_data in terrain_map_data.call("get_tiles"):
		terrain_registry.call("register_tile", tile_data)
	terrain_registry.call("prepare_spatial_queries")

	var map_root: Node = get_node_or_null("../MapRoot")
	if map_root != null and _terrain_renderer != null and not use_2_5d_primary_view:
		_terrain_renderer.render_map(terrain_map_data, map_root)
	_apply_map_marker_positions(terrain_map_data)

	return true


func _setup_terrain_from_hardcode(terrain_registry) -> void:
	_loaded_terrain_map_data = null
	var terrain_root: Node = get_node_or_null("../MapRoot/Terrain")
	if terrain_root == null:
		return

	var terrain_tiles: Array = []
	for child in terrain_root.get_children():
		if child is Sprite2D:
			terrain_tiles.append(child)

	if terrain_tiles.is_empty():
		return

	var first_tile: Sprite2D = terrain_tiles[0]
	var second_tile: Sprite2D = terrain_tiles[1] if terrain_tiles.size() > 1 else null
	var grid_origin_world: Vector2 = _get_tile_world_center(first_tile)
	var half_tile_width: float = 64.0
	var half_tile_height: float = 32.0
	if second_tile != null:
		half_tile_width = absf(second_tile.global_position.x - first_tile.global_position.x)
		half_tile_height = absf(second_tile.global_position.y - first_tile.global_position.y)

	terrain_registry.call("clear_tiles")
	terrain_registry.call("configure_iso_grid", grid_origin_world, half_tile_width, half_tile_height)
	for terrain_tile in terrain_tiles:
		var tile_center: Vector2 = _get_tile_world_center(terrain_tile)
		var grid_position: Vector2i = terrain_registry.call("world_to_grid", tile_center)
		var tile_data = TERRAIN_TILE_DATA_SCRIPT.new(_build_legacy_fallback_tile_payload(grid_position, tile_center))
		terrain_registry.call("register_tile", tile_data)
		_apply_terrain_tile_visual(terrain_tile, tile_data)


func _apply_map_marker_positions(terrain_map_data) -> void:
	if terrain_map_data == null:
		return

	_apply_marker_position("spawn_alpha", _resolve_marker(spawn_alpha_path), terrain_map_data)
	_apply_marker_position("spawn_bravo", _resolve_marker(spawn_bravo_path), terrain_map_data)
	_apply_marker_position("objective_point", _resolve_marker(objective_point_path), terrain_map_data)


func _apply_marker_position(marker_id: String, marker_node: Marker2D, terrain_map_data) -> void:
	if marker_node == null or terrain_map_data == null:
		return
	if not terrain_map_data.has_method("has_marker") or not bool(terrain_map_data.call("has_marker", marker_id)):
		return
	marker_node.global_position = terrain_map_data.call("get_marker_position", marker_id, marker_node.global_position)


func get_primary_3d_view():
	return _terrain_3d_view


func _ensure_primary_3d_view(unit_nodes: Array) -> void:
	if not use_2_5d_primary_view:
		return
	var mission_root := get_parent()
	if mission_root == null:
		return
	var view = mission_root.get_node_or_null("Primary3DView")
	if view == null:
		view = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
		view.name = "Primary3DView"
		mission_root.call_deferred("add_child", view)
	_terrain_3d_view = view
	_hide_legacy_2d_primary_visuals(unit_nodes)
	call_deferred("_configure_primary_3d_view", view, unit_nodes)


func _configure_primary_3d_view(view: Node, unit_nodes: Array) -> void:
	if view == null or not is_instance_valid(view):
		return
	if not view.is_inside_tree():
		call_deferred("_configure_primary_3d_view", view, unit_nodes)
		return
	if _hex_setup_presentation_only:
		view.call("set_fog_of_war_state", get_fog_of_war_runtime_snapshot())
	if view.has_method("set_runtime_terrain_registry"):
		view.call("set_runtime_terrain_registry", get_node_or_null(terrain_registry_path))
	if view.has_method("set_authoring_markers_visible"): view.call("set_authoring_markers_visible",false)
	var regional := _loaded_terrain_map_data != null and float(_loaded_terrain_map_data.get_regional_height_step()) > 0.0
	if _prepared_terrain_resource_cache != null:
		view.call("set_prepared_terrain_resource_cache", _prepared_terrain_resource_cache)
		_prepared_terrain_resource_cache = null
	if _loaded_terrain_map_data != null and view.has_method("configure_from_map"):
		if regional:
			var presentation: Dictionary = _loaded_terrain_map_data.get_place_presentation()
			var initial_size := float(presentation.get("initial_camera_size", 22.0))
			view.call("configure_from_map", _loaded_terrain_map_data, _loaded_terrain_map_data.get_marker_position("spawn_alpha"), initial_size)
		else:
			view.call("configure_from_map", _loaded_terrain_map_data)
	if view.has_method("set_unit_nodes"):
		view.call("set_unit_nodes", unit_nodes)
	if regional or _frame_reference_mission_camera(view):
		return
	var objective_marker := _resolve_marker(objective_point_path)
	if objective_marker != null and view.has_method("focus_world_position"):
		view.call("focus_world_position", objective_marker.global_position)


func _frame_reference_mission_camera(view: Node) -> bool:
	# Mission-only initial composition. The view retains camera math and all
	# subsequent manual navigation; no actor or enemy lookup is needed.
	if view == null or not is_instance_valid(view) or _loaded_terrain_map_data == null:
		return false
	var presentation: Dictionary=_loaded_terrain_map_data.call("get_place_presentation")
	var initial_size: float=float(presentation.get("initial_camera_size",0.0))
	var station_camera: Dictionary = presentation.get("station_initial_camera", {})
	if bool(presentation.get("orbital_station", false)) and not station_camera.is_empty():
		if bool(view.get_meta("place_initial_camera", false)): return true
		view.set("_camera_yaw_degrees", float(station_camera.get("yaw_degrees", 0.0)))
		view.set("_camera_pitch_degrees", clampf(float(station_camera.get("pitch_degrees", 58.0)), 20.0, 85.0))
		var station_limit: float = float(view.call("get_camera_zoom_limit")) if view.has_method("get_camera_zoom_limit") else 280.0
		view.set("_camera_size", clampf(float(station_camera.get("size", initial_size)), 5.5, station_limit))
		view.call("focus_world_position", _loaded_terrain_map_data.get_marker_position(String(station_camera.get("focus_marker", "trade_service"))))
		view.set_meta("place_initial_camera", true)
		return true

	if initial_size>0.0 and is_finite(initial_size):
		if bool(view.get_meta("place_initial_camera",false)): return true
		var points: Array=[]
		for path in [spawn_alpha_path,objective_point_path]:
			var marker:=_resolve_marker(path)
			if marker!=null: points.append(marker.global_position)
		if not points.is_empty():
			view.call("frame_world_positions",points,6.0,clampf(initial_size,5.5,120.0),clampf(initial_size,5.5,120.0))
			view.set_meta("place_initial_camera",true)
			return true
	if not _loaded_terrain_map_data.has_method("get_authored_visual_layout_id") or String(_loaded_terrain_map_data.call("get_authored_visual_layout_id")) != "gm01_frontier_outpost_v1":
		return false
	if bool(view.get_meta("gm01_reference_initial_camera", false)):
		return true
	if not view.has_method("frame_world_positions"):
		return false
	var points: Array = []
	for path in [spawn_alpha_path, objective_point_path]:
		var marker := _resolve_marker(path)
		if marker != null:
			points.append(marker.global_position)
	if points.is_empty():
		return false
	var result: Dictionary = view.call("frame_world_positions", points, 6.0, 22.0, 22.0)
	if not bool(result.get("framed", false)):
		return false
	view.set_meta("gm01_reference_initial_camera", true)
	return true


func set_fog_of_war_mode(mode: String) -> void:
	fog_of_war_mode = String(FOG_OF_WAR_MODE_CONTRACT_SCRIPT.call("normalize_mode", mode))
	_sync_fog_of_war_visual_state(true)
	if _fog_of_war_system != null: _sync_multiplayer_fog_work()


func get_fog_of_war_runtime_snapshot() -> Dictionary:
	if _hex_setup_presentation_only:
		var replica: Dictionary = _fog_replica_terrain.duplicate(true) if not _fog_replica_terrain.is_empty() else FOG_OF_WAR_MODE_CONTRACT_SCRIPT.normalize_team_state({"team_id":_get_fog_viewer_team_id(),"mode":"unexplored_blackout"})
		return MULTIPLAYER_TERRAIN_FOG.for_view(replica,_fog_replica_visible_ids)
	var viewer_team_id: String = _get_fog_viewer_team_id()
	if _fog_of_war_system == null:
		return {
			"mode": FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF,
			"team_id": viewer_team_id,
			"active": false,
		}
	var snapshot: Dictionary = Dictionary(_fog_of_war_system.call("build_team_visual_state_snapshot", viewer_team_id, _fog_terrain_registry))
	snapshot["active"] = String(snapshot.get("mode", FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF)) != FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF
	snapshot["runtime_signature"] = _fog_runtime_signature
	snapshot["observer_count"] = _get_active_fog_observers().size()
	snapshot["pending_visibility_revision"] = not _fog_requested_runtime_signature.is_empty()
	snapshot["pending_visibility_age_msec"] = maxi(Time.get_ticks_msec() - _fog_pending_visibility_started_msec, 0) if not _fog_requested_runtime_signature.is_empty() else 0
	return snapshot


func _initialize_fog_of_war(unit_nodes: Array, terrain_registry) -> void:
	_fog_of_war_system = FOG_OF_WAR_SYSTEM_SCRIPT.new()
	_fog_of_war_los_system = LINE_OF_SIGHT_SYSTEM_SCRIPT.new()
	_fog_terrain_registry = terrain_registry
	_fog_unit_nodes = unit_nodes.duplicate()
	_fog_observer_unit_nodes.clear()
	var viewer_team_id: String = _get_fog_viewer_team_id()
	for unit in _fog_unit_nodes:
		if unit != null and unit.has_method("get_team_id") and String(unit.call("get_team_id")).strip_edges() == viewer_team_id:
			_fog_observer_unit_nodes.append(unit)
	fog_of_war_mode = String(FOG_OF_WAR_MODE_CONTRACT_SCRIPT.call("normalize_mode", fog_of_war_mode))
	_fog_of_war_system.call("set_mode_for_team", viewer_team_id, fog_of_war_mode)
	_fog_network_terrain_cache.clear()
	_fog_other_team_work.clear()
	var root_owner = get_node_or_null("../SimulationRoot")
	_fog_network_enabled = root_owner != null and not root_owner.get_multiplayer_runtime_context().is_empty()
	_cache_multiplayer_terrain(viewer_team_id)
	if _fog_network_enabled:
		for unit in _fog_unit_nodes:
			if unit == null or not unit.has_method("get_team_id"): continue
			var other: String = String(unit.call("get_team_id")).strip_edges()
			if other.is_empty() or other == viewer_team_id or _fog_other_team_work.has(other): continue
			_fog_of_war_system.set_mode_for_team(other,fog_of_war_mode)
			_fog_other_team_work[other] = {"pending":false,"signature":"","static":"","committed":""}
			_cache_multiplayer_terrain(other)
	call_deferred("_sync_fog_of_war_visual_state", true)


func _cache_multiplayer_terrain(team: String) -> void:
	if not _fog_network_enabled: return
	var revision: int = _fog_of_war_system.get_visibility_revision(team)
	var mode: String = _fog_of_war_system.get_mode_for_team(team)
	var previous: Dictionary = _fog_network_terrain_cache.get(team,{})
	if previous.get("visibility_revision",-1) == revision and previous.get("mode") == mode: return
	_fog_network_terrain_cache[team] = MULTIPLAYER_TERRAIN_FOG.project(_fog_of_war_system.build_team_state_snapshot(team))

func get_multiplayer_terrain_fog_revision(team: String) -> String:
	var snapshot: Dictionary = _fog_network_terrain_cache.get(team,{})
	return "%s:%s" % [snapshot.mode,snapshot.visibility_revision] if not snapshot.is_empty() else ""

func get_multiplayer_terrain_fog_snapshot(team: String) -> Dictionary:
	return Dictionary(_fog_network_terrain_cache.get(team,{})).duplicate(true)

func reset_multiplayer_terrain_fog_projection(team: String) -> void:
	_fog_replica_terrain.clear()
	_fog_replica_visible_ids.clear()
	# Before ready this records the authoritative binding for initial setup.
	# A running host keeps its actual Fog owner; clients only reset projection.
	if _fog_of_war_system == null and not team.is_empty(): fog_viewer_team_id = team
	if _hex_setup_presentation_only and is_instance_valid(_terrain_3d_view):
		_terrain_3d_view.set_fog_of_war_state(get_fog_of_war_runtime_snapshot())

func apply_multiplayer_terrain_fog_snapshot(snapshot: Dictionary, visible_ids: PackedStringArray) -> void:
	# Only Root calls this after schema, context, recipient and tick validation.
	# Actor presence stays sourced from the unchanged recipient projection.
	if not _hex_setup_presentation_only: return
	if not snapshot.is_empty() and not MULTIPLAYER_TERRAIN_FOG.validate(snapshot,_get_fog_viewer_team_id()): return
	visible_ids.sort()
	var changed: bool = visible_ids != _fog_replica_visible_ids
	_fog_replica_visible_ids = visible_ids
	if not snapshot.is_empty() and snapshot != _fog_replica_terrain:
		_fog_replica_terrain = snapshot.duplicate(true)
		changed = true
	if changed and is_instance_valid(_terrain_3d_view): _terrain_3d_view.set_fog_of_war_state(get_fog_of_war_runtime_snapshot())

func _sync_multiplayer_fog_work() -> void:
	for team: String in _fog_other_team_work:
		var work: Dictionary = _fog_other_team_work[team]
		var mode: String = FOG_OF_WAR_MODE_CONTRACT_SCRIPT.normalize_mode(fog_of_war_mode)
		_fog_of_war_system.set_mode_for_team(team,mode)
		_cache_multiplayer_terrain(team)
		var signature: String = _build_fog_runtime_signature(mode,true,team)
		var static_signature: String = _build_fog_runtime_signature(mode,false,team)
		if work.pending and work.get("static") == static_signature: continue
		if not work.pending and work.committed == signature: continue
		var requested: Dictionary = _fog_of_war_system.request_tile_visibility_update_for_team(team,_get_active_fog_observers(team),_fog_terrain_registry,_fog_of_war_los_system,fog_of_war_sight_range_world,{"work_budget_tiles":fog_of_war_work_budget_tiles,"hex_sight_adapter":_get_hex_sight_adapter()})
		work.signature = signature
		work["static"] = static_signature
		work.pending = not requested.get("completed",false)
		if not work.pending:
			work.committed = signature
			_cache_multiplayer_terrain(team)

func _advance_multiplayer_fog_work() -> void:
	# At most one extra team's bounded slice per frame, independent of peer count.
	var teams: Array = _fog_other_team_work.keys()
	if teams.is_empty(): return
	_fog_other_team_cursor = (_fog_other_team_cursor + 1) % teams.size()
	var team: String = teams[_fog_other_team_cursor]
	var work: Dictionary = _fog_other_team_work[team]
	if not work.pending: return
	var mode: String = FOG_OF_WAR_MODE_CONTRACT_SCRIPT.normalize_mode(fog_of_war_mode)
	if _build_fog_runtime_signature(mode,false,team) != work.get("static"):
		_sync_multiplayer_fog_work()
		return
	var update: Dictionary = _fog_of_war_system.process_pending_tile_visibility_work(team,fog_of_war_work_budget_tiles)
	if update.get("completed",false):
		work.pending = false
		work.committed = work.signature
		_cache_multiplayer_terrain(team)


func _get_hex_sight_adapter():
	var driver = get_node_or_null("../CombatLoopDriver")
	return driver.call("get_hex_sight_adapter") if driver != null and driver.has_method("get_hex_sight_adapter") else null


func _sync_fog_of_war_visual_state(force: bool = false, advance_work: bool = true) -> void:
	if _fog_of_war_system == null:
		return
	var view = _terrain_3d_view
	if view == null or not is_instance_valid(view) or not view.is_inside_tree():
		call_deferred("_sync_fog_of_war_visual_state", force, advance_work)
		return
	var mode: String = String(FOG_OF_WAR_MODE_CONTRACT_SCRIPT.call("normalize_mode", fog_of_war_mode))
	var viewer_team_id: String = _get_fog_viewer_team_id()
	_fog_of_war_system.call("set_mode_for_team", viewer_team_id, mode)
	_cache_multiplayer_terrain(viewer_team_id)
	if mode == FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF:
		_fog_runtime_signature = "off"
		_fog_requested_runtime_signature = ""
		_fog_requested_static_signature = ""
		_fog_pending_visibility_started_msec = 0
		if view.has_method("set_fog_of_war_state"):
			view.call("set_fog_of_war_state", {"mode": mode, "team_id": viewer_team_id})
		return
	var next_signature: String = _build_fog_runtime_signature(mode)
	var next_static_signature: String = _build_fog_runtime_signature(mode, false)
	# Dynamic targets sample current LOS independently of the terrain job, even
	# while its bounded slices are still running.
	_sync_fog_dynamic_target_visibility()
	if not force and not _fog_requested_runtime_signature.is_empty() and next_static_signature == _fog_requested_static_signature:
		# Keep the frozen positional sample until it completes. Latest positions
		# are read for the next request; walking must not restart every slice.
		if view.has_method("set_fog_of_war_state"):
			var pending_snapshot: Dictionary = _fog_of_war_system.call("build_team_state_snapshot", viewer_team_id)
			pending_snapshot["visibility_pending"] = true
			view.call("set_fog_of_war_state", pending_snapshot)
		return
	if not force and _fog_requested_runtime_signature.is_empty() and next_signature == _fog_runtime_signature:
		# Targets do not contribute to terrain visibility. Refresh their LOS at the
		# normal cadence without replacing terrain work or enumerating map tiles.
		if view.has_method("set_fog_of_war_state"):
			view.call("set_fog_of_war_state", _fog_of_war_system.call("build_team_state_snapshot", viewer_team_id))
		return
	# Returning to a committed observer state must replace a different pending
	# job too; otherwise that obsolete job could later publish its away position.
	var replace_with_committed_state: bool = not _fog_requested_runtime_signature.is_empty() and next_signature == _fog_runtime_signature
	_fog_requested_runtime_signature = next_signature
	_fog_requested_static_signature = next_static_signature
	_fog_pending_visibility_started_msec = Time.get_ticks_msec()
	_fog_of_war_system.call(
		"request_tile_visibility_update_for_team",
		viewer_team_id,
		_get_active_fog_observers(),
		_fog_terrain_registry,
		_fog_of_war_los_system,
		fog_of_war_sight_range_world,
		{"work_budget_tiles": fog_of_war_work_budget_tiles, "force_full": force or replace_with_committed_state,
			"hex_sight_adapter": _get_hex_sight_adapter()}
	)
	# Retain the last complete terrain sample until the next atomic publication
	# (TASK1189). Clearing it here would restart the real overlay on every step.
	# The initial sample has no known tiles and remains safely blacked out;
	# dynamic targets already use current LOS independently of the terrain job.
	if view.has_method("set_fog_of_war_state"):
		var pending_snapshot: Dictionary = _fog_of_war_system.call("build_team_state_snapshot", viewer_team_id)
		pending_snapshot["visibility_pending"] = true
		view.call("set_fog_of_war_state", pending_snapshot)
	if advance_work:
		_advance_fog_of_war_visibility_work()


func _advance_fog_of_war_visibility_work() -> void:
	if _fog_of_war_system == null or _fog_requested_runtime_signature.is_empty():
		return
	# Terrain, mode, active observers and sight changes invalidate before commit.
	# Motion retains the request's atomic sample and coalesces into the next job.
	var mode: String = String(FOG_OF_WAR_MODE_CONTRACT_SCRIPT.call("normalize_mode", fog_of_war_mode))
	if _build_fog_runtime_signature(mode, false) != _fog_requested_static_signature:
		_sync_fog_of_war_visual_state(false)
		return
	var viewer_team_id: String = _get_fog_viewer_team_id()
	var update: Dictionary = Dictionary(_fog_of_war_system.call("process_pending_tile_visibility_work", viewer_team_id, fog_of_war_work_budget_tiles))
	if _fog_frame_timing_debug_enabled:
		_fog_visibility_work_debug_snapshot.clear()
		for key in ["completed", "visibility_revision", "candidate_tile_count", "candidate_scan_pending", "candidate_scan_processed", "processed_tile_count", "processed_in_slice", "slice_duration_usec", "duration_usec", "full_scan"]:
			if update.has(key):
				_fog_visibility_work_debug_snapshot[key] = update[key]
	if not bool(update.get("completed", false)):
		return
	_cache_multiplayer_terrain(viewer_team_id)
	_fog_runtime_signature = _fog_requested_runtime_signature
	_fog_requested_runtime_signature = ""
	_fog_requested_static_signature = ""
	_fog_pending_visibility_started_msec = 0
	_sync_fog_dynamic_target_visibility()
	var view = _terrain_3d_view
	if view != null and is_instance_valid(view) and view.has_method("set_fog_of_war_state"):
		view.call("set_fog_of_war_state", _fog_of_war_system.call("build_team_state_snapshot", viewer_team_id))


func _sync_fog_dynamic_target_visibility() -> void:
	if _fog_of_war_system == null:
		return
	var observers: Array = _get_active_fog_observers()
	var hex_adapter = _get_hex_sight_adapter()
	var viewer_team_id: String = _get_fog_viewer_team_id()
	for unit in _fog_unit_nodes:
		if unit == null or not (unit is Node2D) or not unit.has_method("get_unit_id") or not unit.has_method("get_team_id"):
			continue
		if String(unit.call("get_team_id")).strip_edges() == viewer_team_id:
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		var target_position: Vector2 = (unit as Node2D).global_position
		var visible: bool = false
		for observer_variant in observers:
			var observer := observer_variant as Node2D
			if observer == null:
				continue
			var effective_sight_range_world: float = _get_effective_fog_sight_range_world(observer)
			var has_line_of_sight: bool
			if hex_adapter != null and hex_adapter.is_active():
				has_line_of_sight = bool(hex_adapter.query_units(observer,unit,effective_sight_range_world).get("visible",false))
			else:
				has_line_of_sight = _fog_of_war_los_system.call("has_line_of_sight_between_points", observer.global_position, target_position, effective_sight_range_world, _fog_terrain_registry) == true
			if has_line_of_sight:
				visible = true
				break
		_fog_of_war_system.call("set_visible", viewer_team_id, unit_id, visible)
		if visible:
			if hex_adapter != null and hex_adapter.is_active():
				target_position = Vector2(hex_adapter.build_observer_state(unit,-1.0).get("position",Vector2.ZERO))
			_fog_of_war_system.call("record_last_known_contact", viewer_team_id, {
				"target_id": unit_id,
				"team_id": String(unit.call("get_team_id")).strip_edges(),
				"last_known_position": target_position,
				"last_seen_tick": Time.get_ticks_msec(),
			})


func _get_active_fog_observers(team_override: String = "") -> Array:
	var observers: Array = []
	var source: Array = _fog_observer_unit_nodes if team_override.is_empty() else _fog_unit_nodes
	for observer in source:
		if not team_override.is_empty() and (observer == null or not observer.has_method("get_team_id") or String(observer.call("get_team_id")) != team_override): continue
		if observer == null or not (observer is Node2D):
			continue
		if observer is CanvasItem and not (observer as CanvasItem).visible:
			continue
		if observer.has_method("get_vital_state") and ["down", "dead", "bleedout"].has(String(observer.call("get_vital_state")).strip_edges().to_lower()):
			continue
		observers.append(observer)
	return observers


func _get_effective_fog_sight_range_world(observer: Node) -> float:
	if fog_of_war_sight_range_world < 0.0:
		return fog_of_war_sight_range_world
	var sight_range_factor: float = 1.0
	if observer != null and observer.has_method("get_sight_range_factor"):
		sight_range_factor = float(observer.call("get_sight_range_factor"))
	elif observer != null and observer.has_method("get_runtime_status"):
		var runtime_status = observer.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("to_dict"):
			sight_range_factor = float(Dictionary(runtime_status.call("to_dict")).get("sight_range_factor", 1.0))
	return fog_of_war_sight_range_world * maxf(sight_range_factor, 0.0)


func _build_fog_runtime_signature(mode: String, include_positions: bool = true, team_override: String = "") -> String:
	var parts: PackedStringArray = PackedStringArray()
	var hex_adapter = _get_hex_sight_adapter()
	if hex_adapter != null and hex_adapter.is_active():
		parts.append("hex_context:%s" % hex_adapter.get_context_key())
	parts.append(mode)
	parts.append(_get_fog_viewer_team_id() if team_override.is_empty() else team_override)
	parts.append("base_sight:%s" % str(fog_of_war_sight_range_world))
	if _fog_terrain_registry != null and _fog_terrain_registry.has_method("get_revision"):
		parts.append("terrain_revision:%d" % int(_fog_terrain_registry.call("get_revision")))
	# Only observer inputs affect terrain LOS. Enemy motion is handled by the
	# separate dynamic-target refresh and cannot restart an unfinished full scan.
	for unit in _get_active_fog_observers(team_override):
		if unit == null or not (unit is Node2D) or not unit.has_method("get_unit_id") or not unit.has_method("get_team_id"):
			continue
		var visible_text: String = "1" if not (unit is CanvasItem) or (unit as CanvasItem).visible else "0"
		var position: Vector2 = (unit as Node2D).global_position
		var position_text: String = "%s,%s" % [str(position.x), str(position.y)] if include_positions else ""
		if hex_adapter != null and hex_adapter.is_active():
			position_text = hex_adapter.build_observer_signature(unit,_get_effective_fog_sight_range_world(unit),include_positions)
		var sight_text: String = str(_get_fog_unit_sight_range_factor(unit))
		parts.append("%s:%s:%s:%s:%s" % [
			String(unit.call("get_unit_id")).strip_edges(),
			String(unit.call("get_team_id")).strip_edges(),
			visible_text,
			position_text,
			sight_text,
		])
	parts.sort()
	return "|".join(parts)


func _get_fog_viewer_team_id() -> String:
	var normalized_viewer_team_id: String = fog_viewer_team_id.strip_edges().to_lower()
	return normalized_viewer_team_id if not normalized_viewer_team_id.is_empty() else team_id.strip_edges().to_lower()


func _get_fog_unit_sight_range_factor(unit: Node) -> float:
	if unit == null:
		return 1.0
	if unit.has_method("get_sight_range_factor"):
		return maxf(float(unit.call("get_sight_range_factor")), 0.0)
	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("to_dict"):
			return maxf(float(Dictionary(runtime_status.call("to_dict")).get("sight_range_factor", 1.0)), 0.0)
	return 1.0


func _get_fog_grid_signature(world_position: Vector2) -> String:
	if _fog_terrain_registry != null and _fog_terrain_registry.has_method("world_to_grid"):
		var grid_position: Vector2i = _fog_terrain_registry.call("world_to_grid", world_position)
		return "%d,%d" % [grid_position.x, grid_position.y]
	return "%d,%d" % [roundi(world_position.x / 32.0), roundi(world_position.y / 32.0)]


func _hide_legacy_2d_primary_visuals(unit_nodes: Array) -> void:
	var mission_root := get_parent()
	if mission_root == null:
		return
	for path in [
		"MapRoot",
		"StatusLabel",
		"TargetMarker/TargetVisual",
		"LZMarker",
		"DropshipPlanMarker",
	]:
		var node := mission_root.get_node_or_null(path)
		if node is CanvasItem:
			(node as CanvasItem).visible = false
	var camera := mission_root.get_node_or_null("MissionCamera") as Camera2D
	if camera != null:
		camera.enabled = false
	for unit in unit_nodes:
		_hide_legacy_unit_visual_children(unit)


func _hide_legacy_unit_visual_children(unit: Node) -> void:
	if unit == null:
		return
	if unit.has_method("set_world_debug_labels_visible"):
		unit.call("set_world_debug_labels_visible", false)
	if unit.has_method("set_world_selection_ring_visible"):
		unit.call("set_world_selection_ring_visible", false)
	unit.set("show_world_event_labels", false)
	for child in unit.get_children():
		_hide_legacy_unit_visual_descendant(child)


func _hide_legacy_unit_visual_descendant(node: Node) -> void:
	if node == null:
		return
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	for child in node.get_children():
		_hide_legacy_unit_visual_descendant(child)



func _apply_unit_identity_preset(unit, unit_id: String, unit_team_id: String) -> void:
	if unit == null or not unit.has_method("apply_identity_config"):
		return

	var preset: Dictionary = UNIT_ROSTER_PRESETS_SCRIPT.get_preset(unit_id, unit_team_id)
	var selected_config: Dictionary = _get_selected_unit_config(unit_id)
	if not selected_config.is_empty():
		preset.merge(selected_config, true)
		preset["unit_id"] = unit_id
		if not unit_team_id.strip_edges().is_empty():
			preset["team_id"] = unit_team_id
	if preset.is_empty():
		return

	unit.call("apply_identity_config", preset)


func _apply_fob_loadout_override(unit, unit_id: String, unit_team_id: String) -> void:
	if unit==null or not unit.has_method("apply_identity_config"):return
	var config:Dictionary=_get_fob_loadout_identity_config(unit_id,unit_team_id)
	if not config.is_empty():unit.call("apply_identity_config",config)


func _get_fob_loadout_identity_config(unit_id:String,unit_team_id:String)->Dictionary:
	if unit_team_id!=team_id:return {}
	var config:Dictionary={"is_fireteam_lead":_is_configured_fireteam_lead(unit_id)}
	var loadout:Variant=member_loadouts.get(unit_id,{})
	if not loadout is Dictionary or loadout.is_empty():return config
	for pair in [["weapon_1","weapon_1_id"],["weapon_2","weapon_2_id"],["armor","armor"]]:
		if loadout.has(pair[0]):config[pair[1]]=String(loadout[pair[0]])
	config.is_fireteam_lead=bool(loadout.get("is_fireteam_lead",config.is_fireteam_lead))
	return config


func _get_fireteam_id_for_friendly_slot(slot_index: int, unit_id: String, unit_team_id: String) -> String:
	if unit_team_id != team_id:
		var enemy_group: Dictionary = _find_scenario_enemy_group_for_unit(unit_id)
		return String(enemy_group.get("group_id", "")).strip_edges().to_lower()

	var configured_fireteam_id: String = _get_definition_fireteam_id_for_unit(unit_id)
	if not configured_fireteam_id.is_empty():
		return configured_fireteam_id

	if selected_team_fireteam_ids.size() == selected_team_unit_ids.size() and slot_index >= 0 and slot_index < selected_team_fireteam_ids.size():
		var selected_fireteam_id: String = String(selected_team_fireteam_ids[slot_index]).strip_edges().to_lower()
		if not selected_fireteam_id.is_empty():
			return selected_fireteam_id
	if selected_team_fireteam_ids.size() != selected_team_unit_ids.size() and slot_index >= 0 and slot_index < selected_team_fireteam_ids.size():
		var fallback_selected_fireteam_id: String = String(selected_team_fireteam_ids[slot_index]).strip_edges().to_lower()
		if not fallback_selected_fireteam_id.is_empty():
			return fallback_selected_fireteam_id

	var preset: Dictionary = UNIT_ROSTER_PRESETS_SCRIPT.get_preset(unit_id, unit_team_id)
	return String(preset.get("fireteam_id", "")).strip_edges().to_lower()


func _get_selected_unit_config(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	for config_variant in selected_team_unit_configs:
		if typeof(config_variant) != TYPE_DICTIONARY:
			continue
		var config: Dictionary = Dictionary(config_variant)
		if String(config.get("unit_id", "")).strip_edges() == normalized_unit_id:
			return config.duplicate(true)
	return {}


func _get_definition_fireteam_id_for_unit(unit_id: String) -> String:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return ""
	for definition_variant in selected_fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		var fireteam_id: String = String(definition.get("id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		if String(definition.get("lead_unit_id", "")).strip_edges() == normalized_unit_id:
			return fireteam_id
		var member_loadouts = definition.get("member_loadouts", {})
		if typeof(member_loadouts) == TYPE_DICTIONARY and Dictionary(member_loadouts).has(normalized_unit_id):
			return fireteam_id
	return ""


func _is_configured_fireteam_lead(unit_id: String) -> bool:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return false
	for definition_variant in selected_fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		if String(definition.get("lead_unit_id", "")).strip_edges() == normalized_unit_id:
			return true
	return false


func _get_tile_world_center(tile_sprite: Sprite2D) -> Vector2:
	if tile_sprite == null or tile_sprite.texture == null:
		return Vector2.ZERO

	return tile_sprite.global_position + (tile_sprite.texture.get_size() * 0.5)


func _build_legacy_fallback_tile_payload(grid_position: Vector2i, world_position: Vector2) -> Dictionary:
	return {
		"tile_id": "legacy_tile_%d_%d" % [grid_position.x, grid_position.y],
		"grid_position": grid_position,
		"world_position": world_position,
		"walkable": not LEGACY_FALLBACK_BLOCKED_TILES.has(grid_position),
		"blocks_los": LEGACY_FALLBACK_LOS_BLOCKING_TILES.has(grid_position),
		"cover_value": int(LEGACY_FALLBACK_COVER_BY_TILE.get(grid_position, 0)),
		"height_level": int(LEGACY_FALLBACK_HEIGHT_BY_TILE.get(grid_position, 0)),
		"surface_type": String(LEGACY_FALLBACK_SURFACE_BY_TILE.get(grid_position, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND)),
	}


func _apply_terrain_tile_visual(tile_sprite: Sprite2D, tile_data) -> void:
	if tile_sprite == null or tile_data == null:
		return

	var tile_color: Color = Color(1.0, 1.0, 1.0, 1.0)
	match String(tile_data.surface_type):
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD:
			tile_color = Color(0.82, 0.82, 0.84, 1.0)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND:
			tile_color = Color(1.0, 0.95, 0.72, 1.0)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK:
			tile_color = Color(0.88, 0.78, 0.66, 1.0)

	var height_level: int = int(tile_data.height_level)
	if height_level == 1:
		tile_color = tile_color.lightened(0.08)
	elif height_level >= 2:
		tile_color = tile_color.lightened(0.16)

	if bool(tile_data.blocks_los):
		tile_color = tile_color.darkened(0.1)

	if not bool(tile_data.walkable):
		tile_color = tile_color.darkened(0.14)

	tile_sprite.modulate = tile_color


func _apply_authored_enemy_loadout(unit: Node, unit_id: String, unit_team_id: String) -> void:
	if unit_team_id==team_id or not unit.has_method("apply_identity_config"):return
	# This chapter authors finite defenders; keep historical scenario equipment unchanged.
	if _mission_scenario==null or not bool(Dictionary(_mission_scenario.call("get_vertical_slice")).get("finite_enemy_roster",false)):return
	var group: Dictionary=_find_scenario_enemy_group_for_unit(unit_id)
	var tactics: Dictionary=Dictionary(group.get("tactics",{}))
	var weapon:=String(tactics.get("weapon_id",""))
	if weapon.is_empty():return
	var weapons=load("res://scripts/core/weapon_data.gd")
	if not weapons.WEAPON_CATALOG.has(weapon):return
	unit.call("apply_identity_config",{"weapon_1_id":weapon,"weapon_2_id":"none"})
