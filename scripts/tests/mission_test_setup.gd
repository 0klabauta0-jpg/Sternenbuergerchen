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
const FOG_OF_WAR_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const LINE_OF_SIGHT_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")

const FOW_UPDATE_INTERVAL_SECONDS: float = 0.35
const FOW_DEFAULT_SIGHT_RANGE_WORLD: float = 640.0
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

var member_loadouts: Dictionary = {}
var unit_loadout_modifiers_by_unit_id: Dictionary = {}
var _is_initialized: bool = false
var _terrain_renderer = null
var _terrain_3d_view = null
var _loaded_terrain_map_data = null
var _mission_scenario = null
var _scenario_enemy_ids: PackedStringArray = PackedStringArray()
var _scenario_tactical_authoring: Dictionary = {}
var _fog_of_war_system = null
var _fog_of_war_los_system = null
var _fog_observer_unit_nodes: Array = []
var _fog_unit_nodes: Array = []
var _fog_terrain_registry = null
var _fog_runtime_signature: String = ""
var _fog_update_elapsed: float = 0.0
var _friendly_unit_slot_paths: Array[NodePath] = []


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
	var runtime_unit_paths: Array = _build_runtime_unit_paths()
	var terrain_registry = _setup_terrain_registry()
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
			unit_id = _get_scenario_enemy_id_for_slot(enemy_assignment_slot_index, unit_id)
			enemy_assignment_slot_index += 1

		_apply_unit_identity_preset(unit, unit_id, unit_team_id)
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
				unit.visible = true

			if terrain_registry != null and unit.has_method("refresh_terrain_readability"):
				unit.call("refresh_terrain_readability")

		if unit_team_id == team_id:
			if defer_friendly_runtime_activation:
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
	_ensure_primary_3d_view(visual_unit_nodes)
	_initialize_fog_of_war(visual_unit_nodes, terrain_registry)
	_is_initialized = true


func _process(delta: float) -> void:
	if _fog_of_war_system == null or _terrain_3d_view == null:
		return
	if String(fog_of_war_mode).strip_edges().to_lower() == FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF:
		return
	_fog_update_elapsed += delta
	if _fog_update_elapsed < FOW_UPDATE_INTERVAL_SECONDS:
		return
	_fog_update_elapsed = 0.0
	_sync_fog_of_war_visual_state(false)


func get_unit_loadout_modifiers_dict(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	return Dictionary(unit_loadout_modifiers_by_unit_id.get(normalized_unit_id, {})).duplicate(true)


func apply_runtime_selection_contract() -> void:
	if not _is_initialized:
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
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	if not bool(validation.get("valid", false)):
		push_warning("Mission scenario has authoring issues: %s" % ", ".join(PackedStringArray(validation.get("errors", PackedStringArray()))))
	_mission_scenario = scenario
	_scenario_enemy_ids = PackedStringArray(_mission_scenario.call("get_enemy_ids"))
	_scenario_tactical_authoring = Dictionary(_mission_scenario.call("get_tactical_authoring_config")).duplicate(true)
	var scenario_map_path: String = String(_mission_scenario.get("map_file_path")).strip_edges()
	if not scenario_map_path.is_empty():
		map_file_path = scenario_map_path


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
	if terrain_registry_path.is_empty():
		return null

	var terrain_registry = get_node_or_null(terrain_registry_path)
	if terrain_registry == null:
		return null

	if not terrain_registry.has_method("clear_tiles") or not terrain_registry.has_method("configure_iso_grid") or not terrain_registry.has_method("register_tile"):
		return terrain_registry

	if _try_load_terrain_from_json(terrain_registry):
		return terrain_registry

	_setup_terrain_from_hardcode(terrain_registry)
	return terrain_registry


func _try_load_terrain_from_json(terrain_registry) -> bool:
	if map_file_path.is_empty() or not FileAccess.file_exists(map_file_path):
		return false

	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", map_file_path)
	if terrain_map_data == null or terrain_map_data.call("get_tiles").is_empty():
		return false
	_loaded_terrain_map_data = terrain_map_data

	var tile_size: Dictionary = terrain_map_data.call("get_tile_size")
	terrain_registry.call("clear_tiles")
	terrain_registry.call(
		"configure_iso_grid",
		terrain_map_data.call("get_grid_origin"),
		float(tile_size.get("half_width", 64.0)),
		float(tile_size.get("half_height", 32.0))
	)

	for tile_data in terrain_map_data.call("get_tiles"):
		terrain_registry.call("register_tile", tile_data)

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
	if _loaded_terrain_map_data != null and view.has_method("configure_from_map"):
		view.call("configure_from_map", _loaded_terrain_map_data)
	if view.has_method("set_unit_nodes"):
		view.call("set_unit_nodes", unit_nodes)
	var objective_marker := _resolve_marker(objective_point_path)
	if objective_marker != null and view.has_method("focus_world_position"):
		view.call("focus_world_position", objective_marker.global_position)


func set_fog_of_war_mode(mode: String) -> void:
	fog_of_war_mode = String(FOG_OF_WAR_MODE_CONTRACT_SCRIPT.call("normalize_mode", mode))
	_sync_fog_of_war_visual_state(true)


func get_fog_of_war_runtime_snapshot() -> Dictionary:
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
	call_deferred("_sync_fog_of_war_visual_state", true)


func _sync_fog_of_war_visual_state(force: bool = false) -> void:
	if _fog_of_war_system == null:
		return
	var view = _terrain_3d_view
	if view == null or not is_instance_valid(view) or not view.is_inside_tree():
		call_deferred("_sync_fog_of_war_visual_state", force)
		return
	var mode: String = String(FOG_OF_WAR_MODE_CONTRACT_SCRIPT.call("normalize_mode", fog_of_war_mode))
	var viewer_team_id: String = _get_fog_viewer_team_id()
	_fog_of_war_system.call("set_mode_for_team", viewer_team_id, mode)
	if mode == FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF:
		_fog_runtime_signature = "off"
		if view.has_method("set_fog_of_war_state"):
			view.call("set_fog_of_war_state", {"mode": mode, "team_id": viewer_team_id})
		return
	var next_signature: String = _build_fog_runtime_signature(mode)
	if not force and next_signature == _fog_runtime_signature:
		return
	_fog_runtime_signature = next_signature
	_fog_of_war_system.call(
		"update_tile_visibility_for_team",
		viewer_team_id,
		_fog_observer_unit_nodes,
		_fog_terrain_registry,
		_fog_of_war_los_system,
		fog_of_war_sight_range_world
	)
	_sync_fog_dynamic_target_visibility()
	if view.has_method("set_fog_of_war_state"):
		view.call("set_fog_of_war_state", _fog_of_war_system.call("build_team_visual_state_snapshot", viewer_team_id, _fog_terrain_registry))


func _sync_fog_dynamic_target_visibility() -> void:
	if _fog_of_war_system == null:
		return
	var observers: Array = _get_active_fog_observers()
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
			var has_line_of_sight: bool = _fog_of_war_los_system.call("has_line_of_sight_between_points", observer.global_position, target_position, effective_sight_range_world, _fog_terrain_registry) == true
			if has_line_of_sight:
				visible = true
				break
		_fog_of_war_system.call("set_visible", viewer_team_id, unit_id, visible)
		if visible:
			_fog_of_war_system.call("record_last_known_contact", viewer_team_id, {
				"target_id": unit_id,
				"team_id": String(unit.call("get_team_id")).strip_edges(),
				"last_known_position": target_position,
				"last_seen_tick": Time.get_ticks_msec(),
			})


func _get_active_fog_observers() -> Array:
	var observers: Array = []
	for observer in _fog_observer_unit_nodes:
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


func _build_fog_runtime_signature(mode: String) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append(mode)
	parts.append(_get_fog_viewer_team_id())
	for unit in _fog_unit_nodes:
		if unit == null or not (unit is Node2D) or not unit.has_method("get_unit_id") or not unit.has_method("get_team_id"):
			continue
		var visible_text: String = "1" if not (unit is CanvasItem) or (unit as CanvasItem).visible else "0"
		var grid_text: String = _get_fog_grid_signature((unit as Node2D).global_position)
		var sight_text: String = "%.3f" % _get_fog_unit_sight_range_factor(unit)
		parts.append("%s:%s:%s:%s:%s" % [
			String(unit.call("get_unit_id")).strip_edges(),
			String(unit.call("get_team_id")).strip_edges(),
			visible_text,
			grid_text,
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
	if unit_team_id != team_id:
		return
	if unit == null or not unit.has_method("apply_identity_config"):
		return
	var is_configured_lead: bool = _is_configured_fireteam_lead(unit_id)
	if member_loadouts.is_empty():
		unit.call("apply_identity_config", {"is_fireteam_lead": is_configured_lead})
		return
	if not member_loadouts.has(unit_id):
		unit.call("apply_identity_config", {"is_fireteam_lead": is_configured_lead})
		return

	var loadout: Dictionary = member_loadouts[unit_id]
	if typeof(loadout) != TYPE_DICTIONARY or loadout.is_empty():
		unit.call("apply_identity_config", {"is_fireteam_lead": is_configured_lead})
		return

	var config: Dictionary = {}
	if loadout.has("weapon_1"):
		config["weapon_1_id"] = String(loadout["weapon_1"])
	if loadout.has("weapon_2"):
		config["weapon_2_id"] = String(loadout["weapon_2"])
	if loadout.has("armor"):
		config["armor"] = String(loadout["armor"])
	config["is_fireteam_lead"] = bool(loadout.get("is_fireteam_lead", is_configured_lead))

	if not config.is_empty():
		unit.call("apply_identity_config", config)


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
