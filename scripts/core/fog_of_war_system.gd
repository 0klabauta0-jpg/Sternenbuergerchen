class_name FogOfWarSystem
extends RefCounted

const MODE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_mode_contract.gd")

var _visibility_by_team: Dictionary = {}
var _mode_by_team: Dictionary = {}
var _current_visible_tiles_by_team: Dictionary = {}
var _explored_tiles_by_team: Dictionary = {}
var _visible_events_by_team: Dictionary = {}
var _last_known_contacts_by_team: Dictionary = {}
var _peer_team_by_peer_id: Dictionary = {}
var _last_tile_visibility_update: Dictionary = {}


func set_visible(team_id: String, target_id: String, visible: bool) -> void:
	if team_id.is_empty() or target_id.is_empty():
		return

	var visibility_for_team: Dictionary = _visibility_by_team.get(team_id, {})
	visibility_for_team[target_id] = visible
	_visibility_by_team[team_id] = visibility_for_team
	if visible:
		record_last_known_contact(team_id, {"target_id": target_id})


func is_visible(team_id: String, target_id: String) -> bool:
	if team_id.is_empty() or target_id.is_empty():
		return false

	if not _visibility_by_team.has(team_id):
		return false

	return bool(_visibility_by_team[team_id].get(target_id, false))


func set_mode_for_team(team_id: String, mode: String) -> void:
	if team_id.is_empty():
		return
	_mode_by_team[team_id] = MODE_CONTRACT_SCRIPT.call("normalize_mode", mode)


func get_mode_for_team(team_id: String) -> String:
	if team_id.is_empty():
		return String(MODE_CONTRACT_SCRIPT.DEFAULT_MODE)
	return String(_mode_by_team.get(team_id, MODE_CONTRACT_SCRIPT.DEFAULT_MODE))


func set_peer_team(peer_id: int, team_id: String) -> void:
	if peer_id <= 0 or team_id.strip_edges().is_empty():
		return
	_peer_team_by_peer_id[peer_id] = team_id.strip_edges()


func get_peer_team(peer_id: int) -> String:
	return String(_peer_team_by_peer_id.get(peer_id, ""))


func mark_tile_visible(team_id: String, tile_id: String, visible: bool = true) -> void:
	if team_id.is_empty() or tile_id.is_empty():
		return
	var current: Dictionary = _current_visible_tiles_by_team.get(team_id, {})
	current[tile_id] = visible
	_current_visible_tiles_by_team[team_id] = current
	if visible:
		mark_tile_explored(team_id, tile_id)


func mark_tile_explored(team_id: String, tile_id: String) -> void:
	if team_id.is_empty() or tile_id.is_empty():
		return
	var explored: Dictionary = _explored_tiles_by_team.get(team_id, {})
	explored[tile_id] = true
	_explored_tiles_by_team[team_id] = explored


func is_tile_currently_visible(team_id: String, tile_id: String) -> bool:
	if team_id.is_empty() or tile_id.is_empty():
		return false
	return bool(Dictionary(_current_visible_tiles_by_team.get(team_id, {})).get(tile_id, false))


func is_tile_explored(team_id: String, tile_id: String) -> bool:
	if team_id.is_empty() or tile_id.is_empty():
		return false
	return bool(Dictionary(_explored_tiles_by_team.get(team_id, {})).get(tile_id, false))


func get_terrain_visibility_state(team_id: String, tile_id: String) -> String:
	var mode: String = get_mode_for_team(team_id)
	if mode == MODE_CONTRACT_SCRIPT.MODE_OFF:
		return MODE_CONTRACT_SCRIPT.TERRAIN_STATE_VISIBLE
	if is_tile_currently_visible(team_id, tile_id):
		return MODE_CONTRACT_SCRIPT.TERRAIN_STATE_VISIBLE
	if mode == MODE_CONTRACT_SCRIPT.MODE_KNOWN_TERRAIN:
		return MODE_CONTRACT_SCRIPT.TERRAIN_STATE_KNOWN
	if is_tile_explored(team_id, tile_id):
		return MODE_CONTRACT_SCRIPT.TERRAIN_STATE_EXPLORED
	return MODE_CONTRACT_SCRIPT.TERRAIN_STATE_UNKNOWN


func set_event_visible(team_id: String, event_id: String, visible: bool = true) -> void:
	if team_id.is_empty() or event_id.is_empty():
		return
	var events: Dictionary = _visible_events_by_team.get(team_id, {})
	events[event_id] = visible
	_visible_events_by_team[team_id] = events


func record_last_known_contact(team_id: String, contact: Dictionary) -> void:
	if team_id.is_empty():
		return
	var target_id: String = String(contact.get("target_id", contact.get("unit_id", ""))).strip_edges()
	if target_id.is_empty():
		return
	var contacts: Dictionary = _last_known_contacts_by_team.get(team_id, {})
	var normalized_contact: Dictionary = {
		"target_id": target_id,
		"team_id": String(contact.get("team_id", "")).strip_edges(),
		"last_seen_tick": maxi(int(contact.get("last_seen_tick", 0)), 0),
	}
	if contact.has("last_known_position"):
		normalized_contact["last_known_position"] = contact.get("last_known_position")
	elif contact.has("position"):
		normalized_contact["last_known_position"] = contact.get("position")
	contacts[target_id] = normalized_contact
	_last_known_contacts_by_team[team_id] = contacts


func should_show_dynamic_target(team_id: String, target_id: String) -> bool:
	if get_mode_for_team(team_id) == MODE_CONTRACT_SCRIPT.MODE_OFF:
		return true
	return is_visible(team_id, target_id)


func build_team_state_snapshot(team_id: String, peer_id: int = 0) -> Dictionary:
	return MODE_CONTRACT_SCRIPT.call(
		"normalize_team_state",
		{
			"team_id": team_id,
			"peer_id": peer_id,
			"mode": get_mode_for_team(team_id),
			"visible_tile_ids": _true_keys(Dictionary(_current_visible_tiles_by_team.get(team_id, {}))),
			"explored_tile_ids": _true_keys(Dictionary(_explored_tiles_by_team.get(team_id, {}))),
			"visible_target_ids": _true_keys(Dictionary(_visibility_by_team.get(team_id, {}))),
			"visible_event_ids": _true_keys(Dictionary(_visible_events_by_team.get(team_id, {}))),
			"last_known_contacts": Dictionary(_last_known_contacts_by_team.get(team_id, {})).values(),
		}
	)


func build_peer_state_snapshot(peer_id: int) -> Dictionary:
	var team_id: String = get_peer_team(peer_id)
	return build_team_state_snapshot(team_id, peer_id)


func build_team_visual_state_snapshot(team_id: String, terrain_registry, peer_id: int = 0) -> Dictionary:
	var snapshot: Dictionary = build_team_state_snapshot(team_id, peer_id)
	snapshot["terrain_visibility_counters"] = build_terrain_visibility_counters(team_id, terrain_registry)
	return snapshot


func build_terrain_visibility_counters(team_id: String, terrain_registry) -> Dictionary:
	var counters: Dictionary = {
		"team_id": team_id,
		"mode": get_mode_for_team(team_id),
		"tile_count": 0,
		"visible_tile_count": 0,
		"explored_tile_count": 0,
		"known_tile_count": 0,
		"unknown_tile_count": 0,
	}
	if terrain_registry == null:
		return counters
	var tiles: Array = []
	if terrain_registry.has_method("get_sorted_tiles"):
		tiles = terrain_registry.call("get_sorted_tiles")
	elif terrain_registry.has_method("get_all_tiles"):
		tiles = terrain_registry.call("get_all_tiles")
	elif terrain_registry.has_method("get_tiles"):
		tiles = terrain_registry.call("get_tiles")
	else:
		return counters
	for tile_data in tiles:
		var tile_id: String = _tile_id_for_tile(tile_data)
		if tile_id.is_empty():
			continue
		counters["tile_count"] = int(counters.get("tile_count", 0)) + 1
		match get_terrain_visibility_state(team_id, tile_id):
			MODE_CONTRACT_SCRIPT.TERRAIN_STATE_VISIBLE:
				counters["visible_tile_count"] = int(counters.get("visible_tile_count", 0)) + 1
			MODE_CONTRACT_SCRIPT.TERRAIN_STATE_EXPLORED:
				counters["explored_tile_count"] = int(counters.get("explored_tile_count", 0)) + 1
			MODE_CONTRACT_SCRIPT.TERRAIN_STATE_KNOWN:
				counters["known_tile_count"] = int(counters.get("known_tile_count", 0)) + 1
			_:
				counters["unknown_tile_count"] = int(counters.get("unknown_tile_count", 0)) + 1
	return counters


func update_tile_visibility_for_team(
	team_id: String,
	observers: Array,
	terrain_registry,
	los_system = null,
	sight_range_world: float = 640.0,
	options: Dictionary = {}
) -> Dictionary:
	if team_id.is_empty() or terrain_registry == null or not terrain_registry.has_method("get_all_tiles"):
		return {}

	var started_usec: int = Time.get_ticks_usec()
	var mode: String = get_mode_for_team(team_id)
	var visible_tiles: Dictionary = {}
	var visible_count: int = 0
	var explored_before: int = _true_keys(Dictionary(_explored_tiles_by_team.get(team_id, {}))).size()
	var observer_count: int = 0
	var checked_tile_count: int = 0
	var los_blocked_count: int = 0
	var sorted_tiles: Array = terrain_registry.call("get_sorted_tiles") if terrain_registry.has_method("get_sorted_tiles") else terrain_registry.call("get_all_tiles")
	var active_observers: Array = _filter_active_observers(observers, options)
	observer_count = active_observers.size()
	if mode == MODE_CONTRACT_SCRIPT.MODE_OFF:
		for tile_data in sorted_tiles:
			var tile_id: String = _tile_id_for_tile(tile_data)
			if tile_id.is_empty():
				continue
			visible_tiles[tile_id] = true
			mark_tile_explored(team_id, tile_id)
			visible_count += 1
	else:
		for tile_data in sorted_tiles:
			var tile_id: String = _tile_id_for_tile(tile_data)
			if tile_id.is_empty():
				continue
			var tile_visible: bool = false
			for observer_variant in active_observers:
				var observer := observer_variant as Node2D
				if observer == null:
					continue
				checked_tile_count += 1
				if _observer_can_see_tile(observer, tile_data, terrain_registry, los_system, sight_range_world):
					tile_visible = true
					break
				los_blocked_count += 1
			if tile_visible:
				visible_tiles[tile_id] = true
				mark_tile_explored(team_id, tile_id)
				visible_count += 1
	_current_visible_tiles_by_team[team_id] = visible_tiles
	var explored_after: int = _true_keys(Dictionary(_explored_tiles_by_team.get(team_id, {}))).size()
	_last_tile_visibility_update = {
		"team_id": team_id,
		"mode": mode,
		"tile_count": sorted_tiles.size(),
		"observer_count": observer_count,
		"visible_tile_count": visible_count,
		"explored_before": explored_before,
		"explored_after": explored_after,
		"checked_tile_count": checked_tile_count,
		"los_blocked_count": los_blocked_count,
		"duration_usec": Time.get_ticks_usec() - started_usec,
		"sight_range_world": sight_range_world,
		"update_policy": "on_movement_command_tick_budget_or_relevant_state_change",
	}
	return _last_tile_visibility_update.duplicate(true)


func get_last_tile_visibility_update_snapshot() -> Dictionary:
	return _last_tile_visibility_update.duplicate(true)


func get_known_tile_info(team_id: String, tile_id: String, terrain_registry) -> Dictionary:
	var state: String = get_terrain_visibility_state(team_id, tile_id)
	if state == MODE_CONTRACT_SCRIPT.TERRAIN_STATE_UNKNOWN:
		return {
			"known": false,
			"terrain_visibility_state": state,
		}
	if terrain_registry == null or not terrain_registry.has_method("get_tile_by_id"):
		return {
			"known": state != MODE_CONTRACT_SCRIPT.TERRAIN_STATE_UNKNOWN,
			"terrain_visibility_state": state,
		}
	var tile_data = terrain_registry.call("get_tile_by_id", tile_id)
	if tile_data == null:
		return {
			"known": false,
			"terrain_visibility_state": state,
		}
	return {
		"known": true,
		"terrain_visibility_state": state,
		"tile_id": tile_id,
		"grid_position": tile_data.grid_position,
		"height_level": int(tile_data.height_level),
		"object_height": int(tile_data.object_height),
		"cover_value": int(tile_data.cover_value),
		"blocks_los": bool(tile_data.blocks_los),
		"surface_type": String(tile_data.surface_type),
		"edge_type": String(tile_data.edge_type),
	}


func filter_dynamic_entries_for_team(team_id: String, entries: Array, id_key: String = "unit_id") -> Dictionary:
	var visible_entries: Array = []
	var hidden_count: int = 0
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var target_id: String = String(entry.get(id_key, entry.get("target_id", ""))).strip_edges()
		if target_id.is_empty():
			continue
		if should_show_dynamic_target(team_id, target_id):
			visible_entries.append(entry.duplicate(true))
		else:
			hidden_count += 1
	return {
		"team_id": team_id,
		"mode": get_mode_for_team(team_id),
		"visible_entries": visible_entries,
		"visible_count": visible_entries.size(),
		"hidden_count": hidden_count,
		"last_known_contacts": Array(Dictionary(_last_known_contacts_by_team.get(team_id, {})).values()).duplicate(true),
		"hidden_ids_included": false,
	}


func update_visibility_from_los(
	team_id: String,
	observer: Node2D,
	target_id: String,
	target_position: Vector2,
	los_system,
	max_range: float = 320.0
) -> bool:
	if team_id.is_empty() or target_id.is_empty():
		return false

	if observer == null or los_system == null or not los_system.has_method("has_line_of_sight_to_position"):
		set_visible(team_id, target_id, false)
		return false

	var visible: bool = bool(los_system.call("has_line_of_sight_to_position", observer, target_position, max_range))
	set_visible(team_id, target_id, visible)
	if visible:
		record_last_known_contact(team_id, {"target_id": target_id, "last_known_position": target_position})
	return visible


func clear() -> void:
	_visibility_by_team.clear()
	_mode_by_team.clear()
	_current_visible_tiles_by_team.clear()
	_explored_tiles_by_team.clear()
	_visible_events_by_team.clear()
	_last_known_contacts_by_team.clear()
	_peer_team_by_peer_id.clear()
	_last_tile_visibility_update.clear()


func _true_keys(source: Dictionary) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for key_variant in source.keys():
		if bool(source.get(key_variant, false)):
			result.append(String(key_variant))
	result.sort()
	return result


func _filter_active_observers(observers: Array, options: Dictionary) -> Array:
	var result: Array = []
	var downed_units_reveal: bool = bool(options.get("downed_units_reveal", false))
	for observer_variant in observers:
		var observer := observer_variant as Node2D
		if observer == null:
			continue
		if observer is CanvasItem and not (observer as CanvasItem).visible:
			continue
		if not downed_units_reveal and _observer_is_downed(observer):
			continue
		result.append(observer)
	return result


func _observer_is_downed(observer: Node) -> bool:
	if observer == null or not observer.has_method("get_vital_status"):
		return false
	var vital_status = observer.call("get_vital_status")
	if vital_status == null:
		return false
	var state: String = ""
	if vital_status.has_method("to_dict"):
		state = String(Dictionary(vital_status.call("to_dict")).get("state", ""))
	elif vital_status is Object:
		state = String((vital_status as Object).get("state"))
	return ["down", "dead", "bleedout"].has(state.strip_edges().to_lower())


func _observer_can_see_tile(observer: Node2D, tile_data, terrain_registry, los_system, sight_range_world: float) -> bool:
	if observer == null or tile_data == null:
		return false
	var target_position: Vector2 = tile_data.world_position
	if sight_range_world >= 0.0 and observer.global_position.distance_to(target_position) > sight_range_world:
		return false
	if los_system != null:
		if los_system.has_method("has_line_of_sight_between_points"):
			return bool(los_system.call("has_line_of_sight_between_points", observer.global_position, target_position, sight_range_world, terrain_registry))
		if los_system.has_method("has_line_of_sight_with_terrain"):
			return bool(los_system.call("has_line_of_sight_with_terrain", observer.global_position, target_position, terrain_registry, sight_range_world))
	return true


func _tile_id_for_tile(tile_data) -> String:
	if tile_data == null:
		return ""
	var tile_id: String = String(tile_data.tile_id).strip_edges()
	if not tile_id.is_empty():
		return tile_id
	var grid_position: Vector2i = tile_data.grid_position
	return "tile_%d_%d" % [grid_position.x, grid_position.y]
