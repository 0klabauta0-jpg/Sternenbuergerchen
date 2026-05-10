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
@export var map_file_path: String = "res://maps/test_mission_32x32_slots8.json"
@export var scenario_file_path: String = ""
@export var defer_friendly_runtime_activation: bool = true
@export var allow_full_roster_when_selection_empty: bool = true
@export var use_2_5d_primary_view: bool = true

var member_loadouts: Dictionary = {}
var unit_loadout_modifiers_by_unit_id: Dictionary = {}
var _is_initialized: bool = false
var _terrain_renderer = null
var _terrain_3d_view = null
var _loaded_terrain_map_data = null
var _mission_scenario = null
var _scenario_enemy_ids: PackedStringArray = PackedStringArray()
var _scenario_tactical_authoring: Dictionary = {}


func _ready() -> void:
	if _terrain_renderer == null:
		_terrain_renderer = TERRAIN_MAP_RENDERER_SCRIPT.new()
	if _is_initialized:
		return

	var runtime_leader = get_node_or_null(runtime_leader_path)
	var unit_registry = get_node_or_null(unit_registry_path)
	var ftl_registry = get_node_or_null(ftl_registry_path)
	var simulation_root = get_node_or_null("../SimulationRoot")
	if runtime_leader == null or unit_registry == null or ftl_registry == null or simulation_root == null:
		push_warning("MissionTestSetup requires direct references to RuntimeLeader, UnitRegistry, FTLRegistry and SimulationRoot.")
		return

	_load_mission_scenario_if_available()
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
	for unit_path in unit_paths:
		var unit = get_node_or_null(unit_path)
		if unit == null or not unit.has_method("get_unit_id"):
			continue

		var unit_id: String = String(unit.call("get_unit_id"))
		var unit_team_id: String = ""
		var friendly_assignment_slot_index: int = -1
		if unit.has_method("get_team_id"):
			unit_team_id = String(unit.call("get_team_id"))

		if unit_team_id == team_id:
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

	_setup_respawn_manager(spawn_alpha_marker, spawn_bravo_marker)
	_setup_enemy_waves(enemy_units)
	_ensure_primary_3d_view(visual_unit_nodes)
	_is_initialized = true


func get_unit_loadout_modifiers_dict(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	return Dictionary(unit_loadout_modifiers_by_unit_id.get(normalized_unit_id, {})).duplicate(true)


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
		Vector2(-18.0, -10.0),
		Vector2(18.0, 10.0),
	]
	if index >= 0 and index < offsets.size():
		return offsets[index]

	return Vector2(18.0 * float(index), 0.0)


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


func _find_tile_sprite_at(terrain_root: Node, world_position: Vector2) -> Sprite2D:
	var best_sprite: Sprite2D = null
	var best_distance: float = INF
	for child in terrain_root.get_children():
		if not child is Sprite2D:
			continue

		var tile_center: Vector2 = _get_tile_world_center(child)
		var distance: float = tile_center.distance_squared_to(world_position)
		if distance < best_distance:
			best_distance = distance
			best_sprite = child

	return best_sprite


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
		var tile_data = TERRAIN_TILE_DATA_SCRIPT.new(
			{
				"tile_id": "tile_%d_%d" % [grid_position.x, grid_position.y],
				"grid_position": grid_position,
				"world_position": tile_center,
				"walkable": not _is_blocked_tile(grid_position),
				"blocks_los": _blocks_line_of_sight(grid_position),
				"cover_value": _get_cover_value_for_tile(grid_position),
				"height_level": _get_height_level_for_tile(grid_position),
				"surface_type": _get_surface_type_for_tile(grid_position),
			}
		)
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
	unit.set("show_world_event_labels", false)
	for child in unit.get_children():
		if child is Sprite2D or child is Polygon2D or child is Line2D or child is Label:
			(child as CanvasItem).visible = false



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
		return ""

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


func _is_blocked_tile(grid_position: Vector2i) -> bool:
	return grid_position == Vector2i(4, 1) or grid_position == Vector2i(4, 2) or grid_position == Vector2i(5, 2)


func _blocks_line_of_sight(grid_position: Vector2i) -> bool:
	return grid_position == Vector2i(4, 2) or grid_position == Vector2i(5, 2)


func _get_cover_value_for_tile(grid_position: Vector2i) -> int:
	if grid_position == Vector2i(3, 4) or grid_position == Vector2i(4, 4) or grid_position == Vector2i(4, 5):
		return 20

	if grid_position == Vector2i(5, 3) or grid_position == Vector2i(2, 5):
		return 35

	return 0


func _get_height_level_for_tile(grid_position: Vector2i) -> int:
	if grid_position == Vector2i(4, 4) or grid_position == Vector2i(5, 3):
		return 2

	if (
		grid_position == Vector2i(3, 3)
		or grid_position == Vector2i(4, 3)
		or grid_position == Vector2i(3, 4)
		or grid_position == Vector2i(5, 4)
		or grid_position == Vector2i(3, 5)
		or grid_position == Vector2i(4, 5)
		or grid_position == Vector2i(5, 5)
	):
		return 1

	return 0


func _get_surface_type_for_tile(grid_position: Vector2i) -> String:
	if (
		grid_position == Vector2i(4, 0)
		or grid_position == Vector2i(3, 1)
		or grid_position == Vector2i(3, 2)
		or grid_position == Vector2i(3, 3)
		or grid_position == Vector2i(4, 4)
		or grid_position == Vector2i(3, 5)
	):
		return TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD

	if (
		grid_position == Vector2i(2, 7)
		or grid_position == Vector2i(2, 6)
		or grid_position == Vector2i(1, 6)
		or grid_position == Vector2i(2, 5)
	):
		return TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND

	if grid_position == Vector2i(5, 3) or grid_position == Vector2i(5, 4):
		return TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK

	return TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND


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
