class_name FogOfWarSystem
extends RefCounted

const MODE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_mode_contract.gd")
const DEFAULT_WORK_BUDGET_TILES: int = 256
const DEFAULT_DIRTY_CHUNK_SIZE: int = 8

var _visibility_by_team: Dictionary = {}
var _mode_by_team: Dictionary = {}
var _current_visible_tiles_by_team: Dictionary = {}
var _explored_tiles_by_team: Dictionary = {}
var _visible_events_by_team: Dictionary = {}
var _last_known_contacts_by_team: Dictionary = {}
var _peer_team_by_peer_id: Dictionary = {}
var _last_tile_visibility_update: Dictionary = {}
var _visibility_revision_by_team: Dictionary = {}
var _last_visibility_delta_by_team: Dictionary = {}
var _committed_observer_states_by_team: Dictionary = {}
var _committed_visibility_mode_by_team: Dictionary = {}
var _committed_terrain_revision_by_team: Dictionary = {}
var _pending_tile_visibility_by_team: Dictionary = {}


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
	var snapshot: Dictionary = MODE_CONTRACT_SCRIPT.call(
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
	# The public mode contract deliberately normalizes only authoritative FoW
	# fields.  Keep the render-only revision metadata outside that normalization
	# so UI consumers can apply a bounded delta without making it gameplay truth.
	snapshot["visibility_revision"] = int(_visibility_revision_by_team.get(team_id, 0))
	snapshot["visibility_delta"] = Dictionary(_last_visibility_delta_by_team.get(team_id, {})).duplicate(true)
	return snapshot


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


func request_tile_visibility_update_for_team(
	team_id: String,
	observers: Array,
	terrain_registry,
	los_system = null,
	sight_range_world: float = 640.0,
	options: Dictionary = {}
) -> Dictionary:
	if team_id.is_empty() or terrain_registry == null or not terrain_registry.has_method("get_all_tiles"):
		return {}

	var mode: String = get_mode_for_team(team_id)
	var active_observers: Array = _filter_active_observers(observers, options)
	var observer_states: Dictionary = _build_observer_states(active_observers, terrain_registry, sight_range_world)
	var terrain_revision: int = int(terrain_registry.call("get_revision")) if terrain_registry.has_method("get_revision") else -1
	var previous_observer_states: Dictionary = Dictionary(_committed_observer_states_by_team.get(team_id, {}))
	var force_full: bool = bool(options.get("force_full", false))
	var full_scan: bool = force_full or not _committed_terrain_revision_by_team.has(team_id) or int(_committed_terrain_revision_by_team.get(team_id, -2)) != terrain_revision or String(_committed_visibility_mode_by_team.get(team_id, "")) != mode
	if not full_scan and _observer_states_equal(previous_observer_states, observer_states):
		return _build_visibility_work_snapshot(team_id, {}, true)
	if not full_scan and _has_unbounded_changed_observer(previous_observer_states, observer_states):
		full_scan = true
	if not full_scan and (not terrain_registry.has_method("get_tile_at_grid") or not terrain_registry.has_method("world_to_grid") or not terrain_registry.has_method("grid_to_world")):
		full_scan = true

	var candidate_tiles: Array = []
	var dirty_regions: Array = []
	if full_scan:
		candidate_tiles = terrain_registry.call("get_sorted_tiles") if terrain_registry.has_method("get_sorted_tiles") else terrain_registry.call("get_all_tiles")
	else:
		dirty_regions = _build_dirty_candidate_regions(previous_observer_states, observer_states, terrain_registry)
	var dirty_chunk_size: int = maxi(int(options.get("dirty_chunk_size", DEFAULT_DIRTY_CHUNK_SIZE)), 1)
	var dirty_chunks: Dictionary = _collect_dirty_chunks(candidate_tiles, dirty_chunk_size)
	var work: Dictionary = {
		"team_id": team_id,
		"mode": mode,
		"terrain_registry": terrain_registry,
		"los_system": los_system,
		"sight_range_world": sight_range_world,
		"terrain_revision": terrain_revision,
		"observer_states": observer_states,
		"candidate_tiles": candidate_tiles,
		"candidate_tile_ids": {},
		"candidate_tile_list": [],
		"candidate_scan_pending": not full_scan,
		"candidate_scan_processed": 0,
		"candidate_scan_region_index": 0,
		"candidate_scan_x": int(Dictionary(dirty_regions[0]).get("min_x", 0)) if not dirty_regions.is_empty() else 0,
		"candidate_scan_y": int(Dictionary(dirty_regions[0]).get("min_y", 0)) if not dirty_regions.is_empty() else 0,
		"dirty_regions": dirty_regions,
		"estimated_candidate_tile_count": _estimate_dirty_candidate_tile_count(dirty_regions),
		"estimated_dirty_chunk_count": _estimate_dirty_chunk_count(dirty_regions, dirty_chunk_size),
		"dirty_chunk_size": dirty_chunk_size,
		"dirty_chunks": dirty_chunks,
		"cursor": 0,
		"processed_tile_count": 0,
		"checked_tile_count": 0,
		"los_blocked_count": 0,
		"next_visible_tiles": Dictionary(_current_visible_tiles_by_team.get(team_id, {})).duplicate(),
		"next_explored_tiles": Dictionary(_explored_tiles_by_team.get(team_id, {})).duplicate(),
		"explored_before": _count_true(Dictionary(_explored_tiles_by_team.get(team_id, {}))),
		"changed_tiles": [],
		"full_scan": full_scan,
		"started_usec": Time.get_ticks_usec(),
		"work_budget_tiles": maxi(int(options.get("work_budget_tiles", DEFAULT_WORK_BUDGET_TILES)), 1),
	}
	_pending_tile_visibility_by_team[team_id] = work
	return _build_visibility_work_snapshot(team_id, work, false)


func process_pending_tile_visibility_work(team_id: String, work_budget_tiles: int = DEFAULT_WORK_BUDGET_TILES) -> Dictionary:
	if team_id.is_empty() or not _pending_tile_visibility_by_team.has(team_id):
		return _build_visibility_work_snapshot(team_id, {}, true)
	var work: Dictionary = Dictionary(_pending_tile_visibility_by_team.get(team_id, {}))
	var started_usec: int = Time.get_ticks_usec()
	if bool(work.get("candidate_scan_pending", false)):
		_collect_pending_dirty_candidate_tiles(work, maxi(work_budget_tiles, 1) * 4)
		_pending_tile_visibility_by_team[team_id] = work
		var collection_snapshot: Dictionary = _build_visibility_work_snapshot(team_id, work, false)
		collection_snapshot["slice_duration_usec"] = Time.get_ticks_usec() - started_usec
		collection_snapshot["processed_in_slice"] = 0
		return collection_snapshot
	var candidate_tiles: Array = Array(work.get("candidate_tiles", []))
	var cursor: int = maxi(int(work.get("cursor", 0)), 0)
	var budget: int = maxi(work_budget_tiles, 1)
	var processed_in_slice: int = 0
	var next_visible_tiles: Dictionary = Dictionary(work.get("next_visible_tiles", {}))
	var next_explored_tiles: Dictionary = Dictionary(work.get("next_explored_tiles", {}))
	var changed_tiles: Array = Array(work.get("changed_tiles", []))
	var checked_tile_count: int = int(work.get("checked_tile_count", 0))
	var los_blocked_count: int = int(work.get("los_blocked_count", 0))
	while cursor < candidate_tiles.size() and processed_in_slice < budget:
		var tile_data = candidate_tiles[cursor]
		cursor += 1
		processed_in_slice += 1
		var tile_id: String = _tile_id_for_tile(tile_data)
		if tile_id.is_empty():
			continue
		var visible_before: bool = bool(next_visible_tiles.get(tile_id, false))
		var explored_before: bool = bool(next_explored_tiles.get(tile_id, false))
		var evaluation: Dictionary = _evaluate_tile_visibility(tile_data, String(work.get("mode", MODE_CONTRACT_SCRIPT.MODE_OFF)), Dictionary(work.get("observer_states", {})), work.get("terrain_registry", null), work.get("los_system", null))
		var visible_after: bool = bool(evaluation.get("visible", false))
		checked_tile_count += int(evaluation.get("checked_tile_count", 0))
		los_blocked_count += int(evaluation.get("los_blocked_count", 0))
		if visible_after:
			next_visible_tiles[tile_id] = true
			next_explored_tiles[tile_id] = true
		else:
			next_visible_tiles.erase(tile_id)
		var explored_after: bool = bool(next_explored_tiles.get(tile_id, false))
		if visible_before != visible_after or explored_before != explored_after:
			changed_tiles.append({"tile_id": tile_id, "visible": visible_after, "explored": explored_after})
	work["cursor"] = cursor
	work["processed_tile_count"] = int(work.get("processed_tile_count", 0)) + processed_in_slice
	work["next_visible_tiles"] = next_visible_tiles
	work["next_explored_tiles"] = next_explored_tiles
	work["changed_tiles"] = changed_tiles
	work["checked_tile_count"] = checked_tile_count
	work["los_blocked_count"] = los_blocked_count
	if cursor < candidate_tiles.size():
		_pending_tile_visibility_by_team[team_id] = work
		var pending_snapshot: Dictionary = _build_visibility_work_snapshot(team_id, work, false)
		pending_snapshot["slice_duration_usec"] = Time.get_ticks_usec() - started_usec
		pending_snapshot["processed_in_slice"] = processed_in_slice
		return pending_snapshot

	_current_visible_tiles_by_team[team_id] = Dictionary(work.get("next_visible_tiles", {}))
	_explored_tiles_by_team[team_id] = Dictionary(work.get("next_explored_tiles", {}))
	_committed_observer_states_by_team[team_id] = Dictionary(work.get("observer_states", {})).duplicate(true)
	_committed_visibility_mode_by_team[team_id] = String(work.get("mode", MODE_CONTRACT_SCRIPT.MODE_OFF))
	_committed_terrain_revision_by_team[team_id] = int(work.get("terrain_revision", -1))
	var visibility_revision: int = int(_visibility_revision_by_team.get(team_id, 0)) + 1
	_visibility_revision_by_team[team_id] = visibility_revision
	var delta: Dictionary = {
		"visibility_revision": visibility_revision,
		"changed_tiles": Array(work.get("changed_tiles", [])).duplicate(true),
		"dirty_chunk_count": Dictionary(work.get("dirty_chunks", {})).size(),
		"candidate_tile_count": candidate_tiles.size(),
		"full_scan": bool(work.get("full_scan", false)),
	}
	_last_visibility_delta_by_team[team_id] = delta
	_last_tile_visibility_update = {
		"team_id": team_id,
		"mode": String(work.get("mode", MODE_CONTRACT_SCRIPT.MODE_OFF)),
		"tile_count": candidate_tiles.size(),
		"observer_count": Dictionary(work.get("observer_states", {})).size(),
		"visible_tile_count": _count_true(Dictionary(_current_visible_tiles_by_team.get(team_id, {}))),
		"explored_before": int(work.get("explored_before", 0)),
		"explored_after": _count_true(Dictionary(_explored_tiles_by_team.get(team_id, {}))),
		"checked_tile_count": int(work.get("checked_tile_count", 0)),
		"los_blocked_count": int(work.get("los_blocked_count", 0)),
		"duration_usec": Time.get_ticks_usec() - int(work.get("started_usec", Time.get_ticks_usec())),
		"sight_range_world": float(work.get("sight_range_world", 0.0)),
		"update_policy": "on_movement_command_tick_budget_dirty_region_or_full_scan_oracle",
		"visibility_revision": visibility_revision,
		"changed_tiles": Array(work.get("changed_tiles", [])).duplicate(true),
		"dirty_chunk_count": Dictionary(work.get("dirty_chunks", {})).size(),
		"full_scan": bool(work.get("full_scan", false)),
	}
	_pending_tile_visibility_by_team.erase(team_id)
	var completed_snapshot: Dictionary = _last_tile_visibility_update.duplicate(true)
	completed_snapshot["completed"] = true
	completed_snapshot["processed_tile_count"] = int(work.get("processed_tile_count", 0))
	completed_snapshot["processed_in_slice"] = processed_in_slice
	completed_snapshot["slice_duration_usec"] = Time.get_ticks_usec() - started_usec
	return completed_snapshot


func update_tile_visibility_for_team(
	team_id: String,
	observers: Array,
	terrain_registry,
	los_system = null,
	sight_range_world: float = 640.0,
	options: Dictionary = {}
) -> Dictionary:
	var request_options: Dictionary = options.duplicate(true)
	request_options["force_full"] = true
	request_options["work_budget_tiles"] = maxi(int(options.get("work_budget_tiles", DEFAULT_WORK_BUDGET_TILES)), 1)
	request_tile_visibility_update_for_team(team_id, observers, terrain_registry, los_system, sight_range_world, request_options)
	var update: Dictionary = process_pending_tile_visibility_work(team_id, 2147483647)
	return update


func _build_visibility_work_snapshot(team_id: String, work: Dictionary, completed: bool) -> Dictionary:
	if work.is_empty():
		return {
			"team_id": team_id,
			"completed": completed,
			"visibility_revision": int(_visibility_revision_by_team.get(team_id, 0)),
			"candidate_tile_count": 0,
			"dirty_chunk_count": 0,
			"processed_tile_count": 0,
			"full_scan": false,
		}
	var candidate_scan_pending: bool = bool(work.get("candidate_scan_pending", false))
	var candidate_tile_count: int = int(work.get("estimated_candidate_tile_count", 0)) if candidate_scan_pending else Array(work.get("candidate_tiles", [])).size()
	var dirty_chunk_count: int = int(work.get("estimated_dirty_chunk_count", 0)) if candidate_scan_pending else Dictionary(work.get("dirty_chunks", {})).size()
	return {
		"team_id": team_id,
		"completed": completed,
		"visibility_revision": int(_visibility_revision_by_team.get(team_id, 0)),
		"candidate_tile_count": candidate_tile_count,
		"dirty_chunk_count": dirty_chunk_count,
		"candidate_scan_pending": candidate_scan_pending,
		"candidate_scan_processed": int(work.get("candidate_scan_processed", 0)),
		"processed_tile_count": int(work.get("processed_tile_count", 0)),
		"full_scan": bool(work.get("full_scan", false)),
	}


func _build_observer_states(observers: Array, terrain_registry, base_sight_range_world: float) -> Dictionary:
	var states: Dictionary = {}
	for observer_variant in observers:
		var observer := observer_variant as Node2D
		if observer == null:
			continue
		var observer_id: String = str(observer.get_instance_id())
		if observer.has_method("get_unit_id"):
			var unit_id: String = String(observer.call("get_unit_id")).strip_edges()
			if not unit_id.is_empty():
				observer_id = unit_id
		var position: Vector2 = observer.global_position
		states[observer_id] = {
			"position": position,
			"grid_position": terrain_registry.call("world_to_grid", position) if terrain_registry.has_method("world_to_grid") else Vector2i.ZERO,
			"sight_range_world": _get_observer_sight_range_world(observer, base_sight_range_world),
		}
	return states


func _observer_states_equal(previous: Dictionary, current: Dictionary) -> bool:
	if previous.size() != current.size():
		return false
	for observer_id_variant in previous.keys():
		var observer_id: String = String(observer_id_variant)
		if not current.has(observer_id):
			return false
		var old_state: Dictionary = Dictionary(previous.get(observer_id, {}))
		var next_state: Dictionary = Dictionary(current.get(observer_id, {}))
		if Vector2(old_state.get("position", Vector2.ZERO)).distance_squared_to(Vector2(next_state.get("position", Vector2.ZERO))) > 0.0001:
			return false
		if not is_equal_approx(float(old_state.get("sight_range_world", 0.0)), float(next_state.get("sight_range_world", 0.0))):
			return false
	return true


func _has_unbounded_changed_observer(previous: Dictionary, current: Dictionary) -> bool:
	var observer_ids: Dictionary = {}
	for observer_id_variant in previous.keys():
		observer_ids[String(observer_id_variant)] = true
	for observer_id_variant in current.keys():
		observer_ids[String(observer_id_variant)] = true
	for observer_id_variant in observer_ids.keys():
		var observer_id: String = String(observer_id_variant)
		var old_state: Dictionary = Dictionary(previous.get(observer_id, {}))
		var next_state: Dictionary = Dictionary(current.get(observer_id, {}))
		if old_state == next_state:
			continue
		if float(old_state.get("sight_range_world", 0.0)) < 0.0 or float(next_state.get("sight_range_world", 0.0)) < 0.0:
			return true
	return false


func _build_dirty_candidate_regions(previous_observers: Dictionary, current_observers: Dictionary, terrain_registry) -> Array:
	var regions: Array = []
	var observer_ids: Dictionary = {}
	for observer_id_variant in previous_observers.keys():
		observer_ids[String(observer_id_variant)] = true
	for observer_id_variant in current_observers.keys():
		observer_ids[String(observer_id_variant)] = true
	var ordered_observer_ids: PackedStringArray = PackedStringArray()
	for observer_id_variant in observer_ids.keys():
		ordered_observer_ids.append(String(observer_id_variant))
	ordered_observer_ids.sort()
	for observer_id in ordered_observer_ids:
		var old_state: Dictionary = Dictionary(previous_observers.get(observer_id, {}))
		var next_state: Dictionary = Dictionary(current_observers.get(observer_id, {}))
		if old_state == next_state:
			continue
		for observer_state in [old_state, next_state]:
			if observer_state.is_empty():
				continue
			var grid_radius: int = _get_observer_reach_grid_radius(observer_state, terrain_registry)
			var center_grid: Vector2i = Vector2i(observer_state.get("grid_position", Vector2i.ZERO))
			regions.append({
				"observer_state": observer_state,
				"min_x": center_grid.x - grid_radius,
				"max_x": center_grid.x + grid_radius,
				"min_y": center_grid.y - grid_radius,
				"max_y": center_grid.y + grid_radius,
			})
	return regions


func _get_observer_reach_grid_radius(observer_state: Dictionary, terrain_registry) -> int:
	var sight_range_world: float = float(observer_state.get("sight_range_world", 0.0))
	if sight_range_world < 0.0:
		return 0
	var origin: Vector2 = terrain_registry.call("grid_to_world", Vector2i.ZERO)
	var axis_x_spacing: float = origin.distance_to(Vector2(terrain_registry.call("grid_to_world", Vector2i(1, 0))))
	var axis_y_spacing: float = origin.distance_to(Vector2(terrain_registry.call("grid_to_world", Vector2i(0, 1))))
	var grid_spacing: float = maxf(minf(axis_x_spacing, axis_y_spacing), 0.001)
	return maxi(ceili(sight_range_world / grid_spacing) + 2, 1)


func _estimate_dirty_candidate_tile_count(regions: Array) -> int:
	var estimated_count: int = 0
	for region_variant in regions:
		var region: Dictionary = Dictionary(region_variant)
		estimated_count += maxi(int(region.get("max_x", -1)) - int(region.get("min_x", 0)) + 1, 0) * maxi(int(region.get("max_y", -1)) - int(region.get("min_y", 0)) + 1, 0)
	return estimated_count


func _estimate_dirty_chunk_count(regions: Array, chunk_size: int) -> int:
	var chunks: Dictionary = {}
	for region_variant in regions:
		var region: Dictionary = Dictionary(region_variant)
		var min_chunk_x: int = floori(float(int(region.get("min_x", 0))) / float(chunk_size))
		var max_chunk_x: int = floori(float(int(region.get("max_x", -1))) / float(chunk_size))
		var min_chunk_y: int = floori(float(int(region.get("min_y", 0))) / float(chunk_size))
		var max_chunk_y: int = floori(float(int(region.get("max_y", -1))) / float(chunk_size))
		for chunk_x in range(min_chunk_x, max_chunk_x + 1):
			for chunk_y in range(min_chunk_y, max_chunk_y + 1):
				chunks[Vector2i(chunk_x, chunk_y)] = true
	return chunks.size()


func _collect_pending_dirty_candidate_tiles(work: Dictionary, lookup_budget_tiles: int) -> void:
	var regions: Array = Array(work.get("dirty_regions", []))
	var region_index: int = maxi(int(work.get("candidate_scan_region_index", 0)), 0)
	var grid_x: int = int(work.get("candidate_scan_x", 0))
	var grid_y: int = int(work.get("candidate_scan_y", 0))
	var candidate_tile_ids: Dictionary = Dictionary(work.get("candidate_tile_ids", {}))
	var candidate_tile_list: Array = Array(work.get("candidate_tile_list", []))
	var terrain_registry = work.get("terrain_registry", null)
	var scanned_tiles: int = 0
	while terrain_registry != null and region_index < regions.size() and scanned_tiles < lookup_budget_tiles:
		var region: Dictionary = Dictionary(regions[region_index])
		var observer_state: Dictionary = Dictionary(region.get("observer_state", {}))
		var tile_data = terrain_registry.call("get_tile_at_grid", Vector2i(grid_x, grid_y))
		if tile_data != null and _tile_is_within_observer_reach(tile_data, observer_state):
			var tile_id: String = _tile_id_for_tile(tile_data)
			if not tile_id.is_empty() and not candidate_tile_ids.has(tile_id):
				candidate_tile_ids[tile_id] = true
				candidate_tile_list.append(tile_data)
		scanned_tiles += 1
		grid_y += 1
		if grid_y > int(region.get("max_y", -1)):
			grid_y = int(region.get("min_y", 0))
			grid_x += 1
			if grid_x > int(region.get("max_x", -1)):
				region_index += 1
				if region_index < regions.size():
					var next_region: Dictionary = Dictionary(regions[region_index])
					grid_x = int(next_region.get("min_x", 0))
					grid_y = int(next_region.get("min_y", 0))
	work["candidate_tile_ids"] = candidate_tile_ids
	work["candidate_tile_list"] = candidate_tile_list
	work["candidate_scan_region_index"] = region_index
	work["candidate_scan_x"] = grid_x
	work["candidate_scan_y"] = grid_y
	work["candidate_scan_processed"] = int(work.get("candidate_scan_processed", 0)) + scanned_tiles
	if region_index < regions.size():
		return
	work["candidate_tiles"] = candidate_tile_list
	work["dirty_chunks"] = _collect_dirty_chunks(candidate_tile_list, maxi(int(work.get("dirty_chunk_size", DEFAULT_DIRTY_CHUNK_SIZE)), 1))
	work["candidate_scan_pending"] = false


func _tile_is_within_observer_reach(tile_data, observer_state: Dictionary) -> bool:
	if tile_data == null:
		return false
	var sight_range_world: float = float(observer_state.get("sight_range_world", 0.0))
	return sight_range_world < 0.0 or Vector2(observer_state.get("position", Vector2.ZERO)).distance_to(Vector2(tile_data.world_position)) <= sight_range_world


func _collect_dirty_chunks(candidate_tiles: Array, chunk_size: int) -> Dictionary:
	var chunks: Dictionary = {}
	for tile_data in candidate_tiles:
		if tile_data == null:
			continue
		var grid_position: Vector2i = Vector2i(tile_data.grid_position)
		chunks[Vector2i(floori(float(grid_position.x) / float(chunk_size)), floori(float(grid_position.y) / float(chunk_size)))] = true
	return chunks


func _evaluate_tile_visibility(tile_data, mode: String, observer_states: Dictionary, terrain_registry, los_system) -> Dictionary:
	if mode == MODE_CONTRACT_SCRIPT.MODE_OFF:
		return {"visible": true, "checked_tile_count": 0, "los_blocked_count": 0}
	if tile_data == null:
		return {"visible": false, "checked_tile_count": 0, "los_blocked_count": 0}
	var checked_tile_count: int = 0
	var los_blocked_count: int = 0
	var target_position: Vector2 = tile_data.world_position
	for observer_state_variant in observer_states.values():
		var observer_state: Dictionary = Dictionary(observer_state_variant)
		var observer_position: Vector2 = Vector2(observer_state.get("position", Vector2.ZERO))
		var sight_range_world: float = float(observer_state.get("sight_range_world", 0.0))
		checked_tile_count += 1
		if sight_range_world >= 0.0 and observer_position.distance_to(target_position) > sight_range_world:
			los_blocked_count += 1
			continue
		if los_system != null:
			if los_system.has_method("has_line_of_sight_between_points") and not bool(los_system.call("has_line_of_sight_between_points", observer_position, target_position, sight_range_world, terrain_registry)):
				los_blocked_count += 1
				continue
			if los_system.has_method("has_line_of_sight_with_terrain") and not bool(los_system.call("has_line_of_sight_with_terrain", observer_position, target_position, terrain_registry, sight_range_world)):
				los_blocked_count += 1
				continue
		return {"visible": true, "checked_tile_count": checked_tile_count, "los_blocked_count": los_blocked_count}
	return {"visible": false, "checked_tile_count": checked_tile_count, "los_blocked_count": los_blocked_count}


func _count_true(source: Dictionary) -> int:
	var count: int = 0
	for value_variant in source.values():
		if bool(value_variant):
			count += 1
	return count


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


func filter_contact_density_sources_for_team(team_id: String, contact_entries: Array, id_key: String = "unit_id") -> Dictionary:
	var filtered: Dictionary = filter_dynamic_entries_for_team(team_id, contact_entries, id_key)
	var source_entries: Array = Array(filtered.get("visible_entries", [])).duplicate(true)
	var seen_target_ids: Dictionary = {}
	for entry_variant in source_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var target_id: String = String(entry.get("target_id", entry.get(id_key, ""))).strip_edges()
		if not target_id.is_empty():
			seen_target_ids[target_id] = true
	var last_known_source_count: int = 0
	for contact_variant in Array(Dictionary(_last_known_contacts_by_team.get(team_id, {})).values()):
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant).duplicate(true)
		var target_id: String = String(contact.get("target_id", contact.get(id_key, ""))).strip_edges()
		if target_id.is_empty() or seen_target_ids.has(target_id):
			continue
		if not contact.has("last_known_position"):
			continue
		contact["fow_last_known"] = true
		contact["detection_state"] = String(contact.get("detection_state", "lost")).strip_edges().to_lower()
		source_entries.append(contact)
		seen_target_ids[target_id] = true
		last_known_source_count += 1
	return {
		"team_id": team_id,
		"mode": get_mode_for_team(team_id),
		"source_entries": source_entries,
		"source_count": source_entries.size(),
		"current_source_count": int(filtered.get("visible_count", 0)),
		"last_known_source_count": last_known_source_count,
		"hidden_count": int(filtered.get("hidden_count", 0)),
		"hidden_ids_included": false,
		"fow_policy": "visible_targets_plus_recorded_last_known_only",
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
	_visibility_revision_by_team.clear()
	_last_visibility_delta_by_team.clear()
	_committed_observer_states_by_team.clear()
	_committed_visibility_mode_by_team.clear()
	_committed_terrain_revision_by_team.clear()
	_pending_tile_visibility_by_team.clear()


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
	var effective_sight_range_world: float = _get_observer_sight_range_world(observer, sight_range_world)
	if effective_sight_range_world >= 0.0 and observer.global_position.distance_to(target_position) > effective_sight_range_world:
		return false
	if los_system != null:
		if los_system.has_method("has_line_of_sight_between_points"):
			return bool(los_system.call("has_line_of_sight_between_points", observer.global_position, target_position, effective_sight_range_world, terrain_registry))
		if los_system.has_method("has_line_of_sight_with_terrain"):
			return bool(los_system.call("has_line_of_sight_with_terrain", observer.global_position, target_position, terrain_registry, effective_sight_range_world))
	return true


func _get_observer_sight_range_world(observer: Node2D, base_sight_range_world: float) -> float:
	if base_sight_range_world < 0.0:
		return base_sight_range_world
	return base_sight_range_world * _get_observer_sight_range_factor(observer)


func _get_observer_sight_range_factor(observer: Node) -> float:
	if observer == null:
		return 1.0
	if observer.has_method("get_sight_range_factor"):
		return maxf(float(observer.call("get_sight_range_factor")), 0.0)
	if observer.has_method("get_runtime_status"):
		var runtime_status = observer.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("to_dict"):
			return maxf(float(Dictionary(runtime_status.call("to_dict")).get("sight_range_factor", 1.0)), 0.0)
	return 1.0


func _tile_id_for_tile(tile_data) -> String:
	if tile_data == null:
		return ""
	var tile_id: String = String(tile_data.tile_id).strip_edges()
	if not tile_id.is_empty():
		return tile_id
	var grid_position: Vector2i = tile_data.grid_position
	return "tile_%d_%d" % [grid_position.x, grid_position.y]
