class_name BottleneckReservationResolver
extends RefCounted

const DEFAULT_HORIZON_TICKS: int = 16
const DEFAULT_CELL_STEP_TICKS: int = 1
const DEFAULT_MAX_AGENTS: int = 8

var _last_debug_snapshot: Dictionary = {}


func clear() -> void:
	_last_debug_snapshot.clear()


func get_debug_snapshot() -> Dictionary:
	return _last_debug_snapshot.duplicate(true)


func build_candidate_from_cells(bottleneck_id: String, cells: Array, source: String = "manual", registry = null) -> Dictionary:
	var normalized_id: String = bottleneck_id.strip_edges()
	var normalized_cells: Array = _normalize_cells(cells)
	if normalized_id.is_empty() or normalized_cells.is_empty():
		return {}
	if not _are_cells_walkable(normalized_cells, registry):
		return {
			"bottleneck_id": normalized_id,
			"source": source,
			"cells": normalized_cells,
			"valid": false,
			"reject_reason": "non_walkable_bottleneck_cell",
		}
	return {
		"bottleneck_id": normalized_id,
		"source": source,
		"cells": normalized_cells,
		"valid": true,
		"reject_reason": "",
	}


func build_candidates_from_portals(portal_snapshots: Array, registry = null) -> Array:
	var candidates: Array = []
	for portal_variant in portal_snapshots:
		var portal: Dictionary = Dictionary(portal_variant)
		var portal_id: String = String(portal.get("portal_id", "")).strip_edges()
		if portal_id.is_empty():
			continue
		var cells: Array = [
			Vector2i(portal.get("from_grid", Vector2i.ZERO)),
			Vector2i(portal.get("to_grid", Vector2i.ZERO)),
		]
		var candidate: Dictionary = build_candidate_from_cells("portal:%s" % portal_id, cells, "hpa_portal", registry)
		if not candidate.is_empty():
			candidate["portal_id"] = portal_id
			candidate["from_component"] = String(portal.get("from_component", ""))
			candidate["to_component"] = String(portal.get("to_component", ""))
			candidates.append(candidate)
	return _sort_candidates(candidates)


func build_corridor_candidates(registry, bounds: Rect2i = Rect2i()) -> Array:
	var candidates: Array = []
	if registry == null or not registry.has_method("get_sorted_tiles") or not registry.has_method("is_walkable"):
		return candidates
	for tile_data in Array(registry.call("get_sorted_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		if bounds.size != Vector2i.ZERO and not bounds.has_point(grid):
			continue
		if not bool(registry.call("is_walkable", grid)):
			continue
		var walkable_neighbors: Array = _get_cardinal_walkable_neighbors(grid, registry)
		if walkable_neighbors.size() > 2:
			continue
		var candidate_id: String = "corridor:%d_%d" % [grid.x, grid.y]
		var cells: Array = [grid]
		var candidate: Dictionary = build_candidate_from_cells(candidate_id, cells, "narrow_corridor", registry)
		if not candidate.is_empty():
			candidate["neighbor_count"] = walkable_neighbors.size()
			candidates.append(candidate)
	return _sort_candidates(candidates)


func build_reservation_plan(requests: Array, candidates: Array, options: Dictionary = {}) -> Dictionary:
	var horizon_ticks: int = maxi(int(options.get("horizon_ticks", DEFAULT_HORIZON_TICKS)), 1)
	var step_ticks: int = maxi(int(options.get("cell_step_ticks", DEFAULT_CELL_STEP_TICKS)), 1)
	var start_tick: int = int(options.get("start_tick", 0))
	var max_agents: int = maxi(int(options.get("max_agents", DEFAULT_MAX_AGENTS)), 1)
	var normalized_candidates: Array = _normalize_candidate_list(candidates)
	var normalized_requests: Array = _normalize_request_list(requests, max_agents)
	normalized_requests.sort_custom(_sort_requests)

	var reservations_by_cell_tick: Dictionary = {}
	var reservations_by_edge_tick: Dictionary = {}
	var decisions: Array = []
	var decisions_by_unit_id: Dictionary = {}
	var waiting_unit_ids: Array = []
	var passing_unit_ids: Array = []
	var conflicts: Array = []

	for request_variant in normalized_requests:
		var request: Dictionary = Dictionary(request_variant)
		var unit_id: String = String(request.get("unit_id", ""))
		var match: Dictionary = _find_best_candidate_for_request(request, normalized_candidates)
		if match.is_empty():
			var no_reservation_decision: Dictionary = {
				"unit_id": unit_id,
				"fireteam_id": String(request.get("fireteam_id", "")),
				"bottleneck_id": "",
				"decision": "pass",
				"wait_ticks": 0,
				"conflict_reason": "no_bottleneck_match",
				"reserved_cells": [],
				"reserved_edges": [],
			}
			decisions.append(no_reservation_decision)
			decisions_by_unit_id[unit_id] = no_reservation_decision
			passing_unit_ids.append(unit_id)
			continue

		var route_cells: Array = Array(match.get("route_cells", []))
		var candidate: Dictionary = Dictionary(match.get("candidate", {}))
		var first_conflict: Dictionary = {}
		var chosen_wait: int = -1
		for wait_ticks in range(0, horizon_ticks + 1):
			var conflict: Dictionary = _find_reservation_conflict(
				unit_id,
				route_cells,
				start_tick + wait_ticks,
				step_ticks,
				reservations_by_cell_tick,
				reservations_by_edge_tick
			)
			if conflict.is_empty():
				chosen_wait = wait_ticks
				break
			if first_conflict.is_empty():
				first_conflict = conflict
		var decision_text: String = "wait" if chosen_wait > 0 else "pass"
		if chosen_wait < 0:
			chosen_wait = horizon_ticks
			decision_text = "fallback"
		var reservation_payload: Dictionary = _reserve_route(
			unit_id,
			route_cells,
			start_tick + chosen_wait,
			step_ticks,
			reservations_by_cell_tick,
			reservations_by_edge_tick
		)
		var conflict_reason: String = String(first_conflict.get("reason", ""))
		if decision_text == "fallback" and conflict_reason.is_empty():
			conflict_reason = "horizon_exhausted"
		var decision: Dictionary = {
			"unit_id": unit_id,
			"fireteam_id": String(request.get("fireteam_id", "")),
			"bottleneck_id": String(candidate.get("bottleneck_id", "")),
			"decision": decision_text,
			"wait_ticks": chosen_wait,
			"conflict_reason": conflict_reason,
			"reserved_cells": Array(reservation_payload.get("reserved_cells", [])),
			"reserved_edges": Array(reservation_payload.get("reserved_edges", [])),
			"deadlock_escalated": bool(request.get("deadlock_marked", false)),
		}
		decisions.append(decision)
		decisions_by_unit_id[unit_id] = decision
		if chosen_wait > 0 or decision_text == "fallback":
			waiting_unit_ids.append(unit_id)
		else:
			passing_unit_ids.append(unit_id)
		if not first_conflict.is_empty():
			conflicts.append(first_conflict)

	var ordered_unit_ids: Array = []
	for decision_variant in decisions:
		ordered_unit_ids.append(String(Dictionary(decision_variant).get("unit_id", "")))
	ordered_unit_ids.sort()
	waiting_unit_ids.sort()
	passing_unit_ids.sort()

	var plan: Dictionary = {
		"schema_version": 1,
		"resolver_id": "bottleneck_reservation_resolver_v1",
		"requests_count": normalized_requests.size(),
		"candidate_count": normalized_candidates.size(),
		"decisions": decisions,
		"decisions_by_unit_id": decisions_by_unit_id,
		"ordered_unit_ids": ordered_unit_ids,
		"passing_unit_ids": passing_unit_ids,
		"waiting_unit_ids": waiting_unit_ids,
		"conflicts": conflicts,
		"reservation_count": reservations_by_cell_tick.size(),
		"start_tick": start_tick,
		"horizon_ticks": horizon_ticks,
	}
	_last_debug_snapshot = plan.duplicate(true)
	return plan


func resolve_command(command: Dictionary, bottleneck_cells: Array, tick: int = 0, options: Dictionary = {}) -> Dictionary:
	var candidate: Dictionary = build_candidate_from_cells(
		String(options.get("bottleneck_id", "command_bottleneck")),
		bottleneck_cells,
		String(options.get("source", "command_deadlock")),
		options.get("terrain_registry", null)
	)
	var request: Dictionary = command.duplicate(true)
	if not request.has("path_grid_points"):
		request["path_grid_points"] = bottleneck_cells
	request["queue_index"] = int(request.get("queue_index", 0))
	var plan_options: Dictionary = options.duplicate(true)
	plan_options["start_tick"] = tick
	var plan: Dictionary = build_reservation_plan([request], [candidate], plan_options)
	var decisions_by_unit_id: Dictionary = Dictionary(plan.get("decisions_by_unit_id", {}))
	var unit_id: String = String(request.get("unit_id", ""))
	var decision: Dictionary = Dictionary(decisions_by_unit_id.get(unit_id, {}))
	apply_reservation_metadata(command, decision)
	return decision


func apply_reservation_metadata(command: Dictionary, decision: Dictionary) -> Dictionary:
	if command.is_empty() or decision.is_empty():
		return command
	command["bottleneck_reservation"] = decision.duplicate(true)
	command["bottleneck_reservation_id"] = String(decision.get("bottleneck_id", ""))
	command["bottleneck_wait_ticks"] = int(decision.get("wait_ticks", 0))
	if String(decision.get("decision", "")) == "wait":
		command["movement_wait_reason"] = "bottleneck_reservation"
	return command


func _normalize_candidate_list(candidates: Array) -> Array:
	var result: Array = []
	for candidate_variant in candidates:
		var candidate: Dictionary = Dictionary(candidate_variant)
		if not bool(candidate.get("valid", true)):
			continue
		var cells: Array = _normalize_cells(Array(candidate.get("cells", [])))
		if cells.is_empty():
			continue
		candidate["cells"] = cells
		candidate["valid"] = true
		result.append(candidate)
	return _sort_candidates(result)


func _normalize_request_list(requests: Array, max_agents: int) -> Array:
	var result: Array = []
	for request_variant in requests:
		var request: Dictionary = Dictionary(request_variant)
		var unit_id: String = String(request.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue
		request["unit_id"] = unit_id
		request["fireteam_id"] = String(request.get("fireteam_id", "")).strip_edges()
		request["command_priority"] = int(request.get("command_priority", request.get("priority", 0)))
		request["queue_index"] = int(request.get("queue_index", result.size()))
		request["path_grid_points"] = _extract_path_cells(request)
		request["deadlock_marked"] = bool(request.get("deadlock_marked", request.get("local_avoidance_deadlock", request.get("local_avoidance_repath_requested", false))))
		result.append(request)
		if result.size() >= max_agents:
			break
	return result


func _extract_path_cells(request: Dictionary) -> Array:
	for key in ["path_grid_points", "grid_path", "path"]:
		if request.has(key):
			return _normalize_cells(Array(request.get(key, [])))
	var cells: Array = []
	if request.has("from_grid"):
		cells.append(Vector2i(request.get("from_grid", Vector2i.ZERO)))
	if request.has("to_grid"):
		cells.append(Vector2i(request.get("to_grid", Vector2i.ZERO)))
	return _normalize_cells(cells)


func _find_best_candidate_for_request(request: Dictionary, candidates: Array) -> Dictionary:
	var path_cells: Array = Array(request.get("path_grid_points", []))
	if path_cells.is_empty():
		return {}
	var best_candidate: Dictionary = {}
	var best_route_cells: Array = []
	for candidate_variant in candidates:
		var candidate: Dictionary = Dictionary(candidate_variant)
		var candidate_cells: Array = Array(candidate.get("cells", []))
		var route_cells: Array = []
		for path_cell_variant in path_cells:
			var path_cell: Vector2i = Vector2i(path_cell_variant)
			if _cells_has(candidate_cells, path_cell):
				route_cells.append(path_cell)
		if route_cells.is_empty():
			continue
		if route_cells.size() > best_route_cells.size():
			best_candidate = candidate
			best_route_cells = route_cells
		elif route_cells.size() == best_route_cells.size() and String(candidate.get("bottleneck_id", "")) < String(best_candidate.get("bottleneck_id", "")):
			best_candidate = candidate
			best_route_cells = route_cells
	if best_candidate.is_empty():
		return {}
	return {
		"candidate": best_candidate,
		"route_cells": best_route_cells,
	}


func _find_reservation_conflict(
	unit_id: String,
	route_cells: Array,
	start_tick: int,
	step_ticks: int,
	reservations_by_cell_tick: Dictionary,
	reservations_by_edge_tick: Dictionary
) -> Dictionary:
	var previous_cell: Variant = null
	for index in range(route_cells.size()):
		var cell: Vector2i = Vector2i(route_cells[index])
		var tick: int = start_tick + (index * step_ticks)
		var cell_key: String = "%s@%d" % [_cell_key(cell), tick]
		if reservations_by_cell_tick.has(cell_key):
			return {
				"reason": "same_cell_time",
				"unit_id": unit_id,
				"other_unit_id": String(Dictionary(reservations_by_cell_tick.get(cell_key, {})).get("unit_id", "")),
				"grid": cell,
				"tick": tick,
			}
		if previous_cell != null:
			var previous_grid: Vector2i = Vector2i(previous_cell)
			var reverse_edge_key: String = "%s>%s@%d" % [_cell_key(cell), _cell_key(previous_grid), tick]
			if reservations_by_edge_tick.has(reverse_edge_key):
				return {
					"reason": "opposite_edge_time",
					"unit_id": unit_id,
					"other_unit_id": String(Dictionary(reservations_by_edge_tick.get(reverse_edge_key, {})).get("unit_id", "")),
					"from_grid": previous_grid,
					"to_grid": cell,
					"tick": tick,
				}
		previous_cell = cell
	return {}


func _reserve_route(
	unit_id: String,
	route_cells: Array,
	start_tick: int,
	step_ticks: int,
	reservations_by_cell_tick: Dictionary,
	reservations_by_edge_tick: Dictionary
) -> Dictionary:
	var reserved_cells: Array = []
	var reserved_edges: Array = []
	var previous_cell: Variant = null
	for index in range(route_cells.size()):
		var cell: Vector2i = Vector2i(route_cells[index])
		var tick: int = start_tick + (index * step_ticks)
		var cell_key: String = "%s@%d" % [_cell_key(cell), tick]
		var cell_reservation: Dictionary = {"unit_id": unit_id, "grid": cell, "tick": tick}
		reservations_by_cell_tick[cell_key] = cell_reservation
		reserved_cells.append(cell_reservation)
		if previous_cell != null:
			var previous_grid: Vector2i = Vector2i(previous_cell)
			var edge_key: String = "%s>%s@%d" % [_cell_key(previous_grid), _cell_key(cell), tick]
			var edge_reservation: Dictionary = {"unit_id": unit_id, "from_grid": previous_grid, "to_grid": cell, "tick": tick}
			reservations_by_edge_tick[edge_key] = edge_reservation
			reserved_edges.append(edge_reservation)
		previous_cell = cell
	return {
		"reserved_cells": reserved_cells,
		"reserved_edges": reserved_edges,
	}


func _normalize_cells(cells: Array) -> Array:
	var result: Array = []
	for cell_variant in cells:
		var cell: Vector2i = Vector2i(cell_variant)
		if not _cells_has(result, cell):
			result.append(cell)
	return result


func _cells_has(cells: Array, target: Vector2i) -> bool:
	for cell_variant in cells:
		if Vector2i(cell_variant) == target:
			return true
	return false


func _are_cells_walkable(cells: Array, registry) -> bool:
	if registry == null or not registry.has_method("is_walkable"):
		return true
	for cell_variant in cells:
		if not bool(registry.call("is_walkable", Vector2i(cell_variant))):
			return false
	return true


func _get_cardinal_walkable_neighbors(grid: Vector2i, registry) -> Array:
	var result: Array = []
	for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var neighbor: Vector2i = grid + direction
		if bool(registry.call("is_walkable", neighbor)):
			result.append(neighbor)
	return result


func _sort_candidates(candidates: Array) -> Array:
	var sorted: Array = candidates.duplicate(true)
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("bottleneck_id", "")) < String(b.get("bottleneck_id", ""))
	)
	return sorted


func _sort_requests(a: Dictionary, b: Dictionary) -> bool:
	var priority_a: int = int(a.get("command_priority", 0))
	var priority_b: int = int(b.get("command_priority", 0))
	if priority_a != priority_b:
		return priority_a > priority_b
	var fireteam_a: String = String(a.get("fireteam_id", ""))
	var fireteam_b: String = String(b.get("fireteam_id", ""))
	if fireteam_a != fireteam_b:
		return fireteam_a < fireteam_b
	var unit_a: String = String(a.get("unit_id", ""))
	var unit_b: String = String(b.get("unit_id", ""))
	if unit_a != unit_b:
		return unit_a < unit_b
	return int(a.get("queue_index", 0)) < int(b.get("queue_index", 0))


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]
