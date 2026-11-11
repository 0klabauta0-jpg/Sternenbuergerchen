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


# Pure AP4 entry point. All durable promises belong to HexGroundRuntime.
static func build_hex_plan(requests: Array, ground_snapshot: Dictionary, terrain_registry: Node, options: Dictionary = {}) -> Dictionary:
	var plan: Dictionary = {"ok": false, "reason": "snapshot_incompatible",
		"expected_revision": ground_snapshot.get("revision", -1),
		"terrain_revision": ground_snapshot.get("terrain_revision", -1),
		"accepted_steps": [], "waits": [], "blocked": [], "pending_requests": [],
		"corridor_grants": [], "processed_requests": 0}
	if not _hex_valid_snapshot(ground_snapshot, terrain_registry):
		plan.pending_requests = requests.duplicate(true)
		return plan
	var now: int = ground_snapshot.current_tick
	var units: Dictionary = ground_snapshot.units_by_id
	var schedules: Dictionary = {}
	for id in units: schedules[id] = []
	for segment in ground_snapshot.committed_segments:
		schedules[segment.unit_id].append(segment.duplicate(true))
	for id in schedules:
		schedules[id].sort_custom(func(a: Dictionary,b: Dictionary)->bool: return a.start_tick<b.start_tick)
		if not _hex_valid_schedule(schedules[id], units[id].grid, now, terrain_registry):
			plan.reason = "invalid_committed_segments"
			plan.pending_requests = requests.duplicate(true)
			return plan
	var index: Dictionary = _hex_index(units,schedules,now)
	for id in units:
		if not _hex_conflict(id,units[id].grid,schedules[id],now,index).is_empty():
			plan.reason="conflicting_snapshot"
			plan.pending_requests=requests.duplicate(true)
			return plan
	for grant in ground_snapshot.committed_corridor_grants:
		if _hex_grant_active(grant,units,schedules): plan.corridor_grants.append(grant.duplicate(true))
	var ordered: Array = requests.duplicate(true)
	ordered.sort_custom(func(a:Variant,b:Variant)->bool:
		if not a is Dictionary: return false
		if not b is Dictionary: return true
		var score_a: int = _hex_fairness_score(a)
		var score_b: int = _hex_fairness_score(b)
		if score_a != score_b: return score_a>score_b
		return str(a.get("unit_id",""))+":"+str(a.get("command_id","")) < str(b.get("unit_id",""))+":"+str(b.get("command_id",""))
	)
	var queue: Array = []
	for request in ordered:
		if queue.size()<16: queue.append(request)
		else: plan.pending_requests.append(request)
	plan.processed_requests = queue.size()
	var graph:Dictionary=_hex_local_graph(queue,terrain_registry)
	var corridors:Array=_hex_corridors(graph)
	var seen: Dictionary = {}
	var active: Array = []
	for request in queue:
		var reason: String = _hex_request_error(request,units,terrain_registry)
		var id: String = str(request.get("unit_id","")) if request is Dictionary else ""
		if reason.is_empty() and seen.has(id): reason="duplicate_unit_request"
		seen[id]=true
		if not reason.is_empty():
			plan.blocked.append({"unit_id":id,"command_id":request.get("command_id","") if request is Dictionary else "","reason":reason})
			plan.pending_requests.append(request)
		else: active.append(request)
	active.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var a_inside:bool=_hex_in_corridor(units[a.unit_id].grid,corridors)
		var b_inside:bool=_hex_in_corridor(units[b.unit_id].grid,corridors)
		if a_inside!=b_inside: return a_inside
		var score_a:int=_hex_fairness_score(a); var score_b:int=_hex_fairness_score(b)
		if score_a!=score_b: return score_a>score_b
		return a.unit_id<b.unit_id
	)
	var raw_wait:Variant=options.get("max_wait_ticks",16)
	var max_wait: int = clampi(raw_wait,0,64) if raw_wait is int else 16
	var reasons: Dictionary = {}
	var inherited_grants:Array=plan.corridor_grants.duplicate(true)
	# Retry blocked followers only when another request actually obtained a promise.
	for pass_index in range(16):
		var remaining: Array = []
		var progress: bool = false
		for request in active:
			var id: String = request.unit_id
			var earliest: int=now
			if not schedules[id].is_empty():
				var last: Dictionary=schedules[id].back()
				if last.to_grid!=request.path_grid_points[0]:
					reasons[id]="existing_commitment"
					remaining.append(request)
					continue
				earliest=maxi(now,last.start_tick+last.duration_ticks)
			var exit_conflict:String=_hex_corridor_exit_conflict(request,corridors,index)
			if not exit_conflict.is_empty():
				reasons[id]=exit_conflict; remaining.append(request)
				continue
			var path: Array = request.path_grid_points
			var count: int = mini(3,path.size()-1)
			var chosen: Array = []
			var chosen_wait: int = 0
			for delay in range(max_wait+1):
				var proposed: Array = []
				var tick: int = earliest+delay
				for step_index in range(count):
					var duration: int = request.duration_ticks_by_step[step_index]
					proposed.append({"unit_id":id,"command_id":request.command_id,
						"from_grid":path[step_index],"to_grid":path[step_index+1],
						"start_tick":tick,"duration_ticks":duration,"handoff_tick":tick+ceili(duration/2.0)})
					tick+=duration
				var conflict: String = _hex_conflict(id,units[id].grid,schedules[id]+proposed,now,index)
				if conflict.is_empty(): conflict=_hex_grant_conflict(id,proposed,inherited_grants)
				if conflict.is_empty(): conflict=_hex_new_direction_conflict(proposed,plan.accepted_steps,corridors)
				if conflict.is_empty():
					chosen=proposed; chosen_wait=earliest-now+delay
					break
				reasons[id]=conflict
			if chosen.is_empty():
				remaining.append(request)
				continue
			schedules[id]=schedules[id]+chosen
			plan.accepted_steps.append_array(chosen)
			for cells in corridors:
				if not _hex_segments_touch(chosen,cells): continue
				var existing:int=-1
				for grant_index in range(plan.corridor_grants.size()):
					if plan.corridor_grants[grant_index].cells==cells: existing=grant_index
				if existing<0: plan.corridor_grants.append({"cells":cells.duplicate(),"unit_ids":[id]})
				# A new invocation never adds arrivals to a still-live closed group.
				elif existing>=inherited_grants.size() and not plan.corridor_grants[existing].unit_ids.has(id):
					plan.corridor_grants[existing].unit_ids.append(id)
			index=_hex_index(units,schedules,now)
			progress=true
			if chosen_wait>0: plan.waits.append({"unit_id":id,"command_id":request.command_id,"wait_ticks":chosen_wait,"reason":"reserved_interval"})
			if count<path.size()-1:
				var pending: Dictionary=request.duplicate(true)
				pending.path_grid_points=path.slice(count)
				pending.duration_ticks_by_step=request.duration_ticks_by_step.slice(count)
				plan.pending_requests.append(pending)
		active=remaining
		if not progress or active.is_empty(): break
	var backoff_budget:Dictionary={"remaining":64}
	for request in active:
		plan.pending_requests.append(request)
		var blocked:Dictionary={"unit_id":request.unit_id,"command_id":request.command_id,
			"reason":String(reasons.get(request.unit_id,"no_passing_space"))}
		if blocked.reason=="no_passing_space":
			var backoff:Dictionary=_hex_backoff(request.unit_id,units[request.unit_id].grid,index,graph,backoff_budget)
			blocked.merge(backoff)
			if not backoff.backoff_path_grid_points.is_empty(): blocked.reason="backoff_required"
		plan.blocked.append(blocked)
	plan.ok=true; plan.reason=""
	return plan


static func _hex_valid_snapshot(snapshot:Dictionary,registry:Node)->bool:
	if not snapshot.get("reservation_schema_version") is int or snapshot.get("reservation_schema_version",0)!=1 or not snapshot.get("committed_segments") is Array: return false
	for key in ["revision","current_tick","terrain_revision"]:
		if not snapshot.get(key) is int or int(snapshot[key])<0: return false
	if snapshot.current_tick>1000000000000: return false
	if not snapshot.get("committed_corridor_grants") is Array: return false
	for grant in snapshot.committed_corridor_grants:
		if not grant is Dictionary or not grant.get("cells") is Array or not grant.get("unit_ids") is Array: return false
		for grid in grant.cells:
			if not grid is Vector2i: return false
		for id in grant.unit_ids:
			if not id is String: return false
	if not snapshot.get("map_id") is String or snapshot.map_id.is_empty(): return false
	if not snapshot.get("units_by_id") is Dictionary or not snapshot.get("occupant_by_grid") is Dictionary: return false
	if not is_instance_valid(registry): return false
	for method in ["get_grid_topology","get_revision","get_tile_at_grid","is_walkable"]:
		if not registry.has_method(method): return false
	if registry.call("get_grid_topology")!="hex_axial_v1" or registry.call("get_revision")!=snapshot.terrain_revision: return false
	if snapshot.units_by_id.size()!=snapshot.occupant_by_grid.size(): return false
	for id in snapshot.units_by_id:
		if not id is String or id.is_empty() or not snapshot.units_by_id[id] is Dictionary: return false
		var unit:Dictionary=snapshot.units_by_id[id]
		if not unit.get("grid") is Vector2i or snapshot.occupant_by_grid.get(unit.grid)!=id: return false
	for segment in snapshot.committed_segments:
		if not segment is Dictionary or not snapshot.units_by_id.has(segment.get("unit_id")): return false
		if not _hex_valid_segment(segment): return false
	return true


static func _hex_valid_segment(segment:Dictionary)->bool:
	for key in ["unit_id","command_id"]:
		if not segment.get(key) is String or String(segment[key]).is_empty(): return false
	for key in ["from_grid","to_grid"]:
		if not segment.get(key) is Vector2i: return false
	for key in ["start_tick","duration_ticks","handoff_tick"]:
		if not segment.get(key) is int: return false
	return segment.start_tick>=0 and segment.start_tick<=1000000000000 and segment.duration_ticks>0 and segment.duration_ticks<=1000000 and segment.handoff_tick==segment.start_tick+ceili(segment.duration_ticks/2.0)


static func _hex_valid_schedule(segments:Array,grid:Vector2i,now:int,registry:Node)->bool:
	var current:Vector2i=grid
	var last_end:int=-1
	for segment in segments:
		if not _hex_legal_step(segment.from_grid,segment.to_grid,registry): return false
		if segment.start_tick<last_end: return false
		last_end=segment.start_tick+segment.duration_ticks
		if last_end<=now: return false # Owner snapshots contain live/future commitments only.
		if segment.handoff_tick<=now:
			if segment.to_grid!=current: return false
		else:
			if segment.from_grid!=current: return false
			current=segment.to_grid
	return true


static func _hex_request_error(request:Variant,units:Dictionary,registry:Node)->String:
	if not request is Dictionary: return "invalid_request"
	for key in ["unit_id","command_id"]:
		if not request.get(key) is String or String(request[key]).is_empty(): return "invalid_request"
	if not request.get("priority") is int: return "invalid_priority"
	if not request.get("wait_ticks",0) is int or int(request.get("wait_ticks",0))<0: return "invalid_wait_ticks"
	if not units.has(request.unit_id): return "unit_not_admitted"
	if not request.get("path_grid_points") is Array or not request.get("duration_ticks_by_step") is Array: return "invalid_path"
	var path:Array=request.path_grid_points
	if path.size()<2 or request.duration_ticks_by_step.size()!=path.size()-1: return "invalid_path"
	if path[0]!=units[request.unit_id].grid: return "path_origin_mismatch"
	for i in range(mini(3,path.size()-1)):
		if not path[i] is Vector2i or not path[i+1] is Vector2i: return "invalid_grid"
		if not request.duration_ticks_by_step[i] is int or request.duration_ticks_by_step[i]<=0 or request.duration_ticks_by_step[i]>1000000: return "invalid_duration"
		if not _hex_legal_step(path[i],path[i+1],registry): return "illegal_terrain_step"
	return ""


static func _hex_legal_step(from:Vector2i,to:Vector2i,registry:Node)->bool:
	var hex=preload("res://scripts/terrain/hex_grid.gd")
	var tile=preload("res://scripts/terrain/terrain_tile_data.gd")
	if not hex.are_neighbors(from,to):return false
	if registry.has_method("get_legal_hex_neighbors"):
		return registry.call("get_legal_hex_neighbors",from).has(to)
	var source=registry.call("get_tile_at_grid",from)
	var target=registry.call("get_tile_at_grid",to)
	var from_walkable:bool=registry.call("is_walkable",from)
	var to_walkable:bool=registry.call("is_walkable",to)
	return tile.allows_registry_step(source,target,from_walkable,to_walkable) and tile.allows_registry_step(target,source,to_walkable,from_walkable)


static func _hex_timeline(id:String,grid:Vector2i,segments:Array,now:int)->Array:
	var intervals:Array=[]
	var start:int=now
	var current:Vector2i=grid
	for segment in segments:
		if segment.handoff_tick<=now: continue
		intervals.append({"unit_id":id,"grid":current,"start":start,"end":segment.handoff_tick})
		current=segment.to_grid; start=segment.handoff_tick
	intervals.append({"unit_id":id,"grid":current,"start":start,"end":9223372036854775807})
	return intervals


static func _hex_index(units:Dictionary,schedules:Dictionary,now:int)->Dictionary:
	var index:Dictionary={"cells":{},"edges":{}}
	for id in units:
		for interval in _hex_timeline(id,units[id].grid,schedules[id],now):
			if not index.cells.has(interval.grid): index.cells[interval.grid]=[]
			index.cells[interval.grid].append(interval)
		for segment in schedules[id]:
			var key:String=_hex_edge_key(segment.from_grid,segment.to_grid)
			if not index.edges.has(key): index.edges[key]=[]
			index.edges[key].append(segment)
	return index


static func _hex_conflict(id:String,grid:Vector2i,segments:Array,now:int,index:Dictionary)->String:
	for interval in _hex_timeline(id,grid,segments,now):
		for other in index.cells.get(interval.grid,[]):
			if other.unit_id!=id and interval.start<other.end and other.start<interval.end: return "no_passing_space"
	for segment in segments:
		for other in index.edges.get(_hex_edge_key(segment.to_grid,segment.from_grid),[]):
			if other.unit_id!=id and segment.start_tick<other.start_tick+other.duration_ticks and other.start_tick<segment.start_tick+segment.duration_ticks: return "opposite_edge_interval"
	return ""


static func _hex_edge_key(from:Vector2i,to:Vector2i)->String:
	return "%d,%d>%d,%d"%[from.x,from.y,to.x,to.y]


# Local legal-transition graph, bounded across this invocation; no full-map reads.
static func _hex_local_graph(requests:Array,registry:Node)->Dictionary:
	var graph:Dictionary={}
	var queue:Array=[]
	for request in requests:
		if request is Dictionary and request.get("path_grid_points") is Array:
			for grid in request.path_grid_points.slice(0,4):
				if grid is Vector2i and not queue.has(grid) and queue.size()<64: queue.append(grid)
	var cursor:int=0
	var hex=preload("res://scripts/terrain/hex_grid.gd")
	while cursor<queue.size() and graph.size()<64:
		var grid:Vector2i=queue[cursor]; cursor+=1
		var neighbors:Array=[]
		if registry.has_method("get_legal_hex_neighbors"):
			neighbors=registry.call("get_legal_hex_neighbors",grid)
		else:
			for direction in hex.DIRECTIONS:
				var next:Vector2i=grid+direction
				if _hex_legal_step(grid,next,registry):neighbors.append(next)
		for next in neighbors:
			if not queue.has(next) and queue.size()<64:queue.append(next)
		graph[grid]=neighbors
	return graph


static func _hex_corridors(graph:Dictionary)->Array:
	var visited:Dictionary={}
	var corridors:Array=[]
	for start in graph:
		if visited.has(start) or graph[start].size()>2: continue
		var queue:Array=[start]
		var cells:Array=[]
		visited[start]=true
		var cursor:int=0
		while cursor<queue.size():
			var grid:Vector2i=queue[cursor]; cursor+=1
			cells.append(grid)
			for neighbor in graph[grid]:
				if graph.has(neighbor) and graph[neighbor].size()<=2 and not visited.has(neighbor):
					visited[neighbor]=true; queue.append(neighbor)
		if cells.size()>1:
			var endpoints:Array=[]
			for cell in cells:
				var count:int=0
				for neighbor in graph[cell]:
					if cells.has(neighbor): count+=1
				if count<2: endpoints.append(cell)
			if endpoints.size()!=2: continue
			endpoints.sort_custom(func(a:Vector2i,b:Vector2i)->bool: return a.x<b.x or (a.x==b.x and a.y<b.y))
			var ordered:Array=[endpoints[0]]
			while ordered.size()<cells.size():
				var next:Variant=null
				for neighbor in graph[ordered.back()]:
					if cells.has(neighbor) and not ordered.has(neighbor): next=neighbor; break
				if next==null: break
				ordered.append(next)
			corridors.append(ordered)
	return corridors


static func _hex_segments_touch(segments:Array,cells:Array)->bool:
	for segment in segments:
		if cells.has(segment.from_grid) or cells.has(segment.to_grid): return true
	return false


static func _hex_grant_active(grant:Dictionary,units:Dictionary,schedules:Dictionary)->bool:
	for id in grant.unit_ids:
		if units.has(id) and (grant.cells.has(units[id].grid) or _hex_segments_touch(schedules[id],grant.cells)): return true
	return false


static func _hex_grant_conflict(id:String,segments:Array,grants:Array)->String:
	for grant in grants:
		if grant.unit_ids.has(id) or not _hex_segments_touch(segments,grant.cells): continue
		var from_index:int=grant.cells.find(segments[0].from_grid)
		# A pre-existing outsider may clear towards its nearest endpoint, never enter.
		if from_index>=0:
			var clear_direction:int=-1 if from_index<grant.cells.size()/2.0 else 1
			var previous:int=from_index
			var clearing:bool=true
			for segment in segments:
				var next:int=grant.cells.find(segment.to_grid)
				if previous<0:
					if next>=0: clearing=false
				elif next>=0:
					if next-previous!=clear_direction: clearing=false
				elif (clear_direction<0 and previous!=0) or (clear_direction>0 and previous!=grant.cells.size()-1): clearing=false
				previous=next
			if clearing: continue
		return "corridor_group_active"
	return ""


static func _hex_direction(segments:Array,cells:Array)->int:
	for segment in segments:
		var from:int=cells.find(segment.from_grid)
		var to:int=cells.find(segment.to_grid)
		if from>=0 and to>=0: return 1 if to>from else -1
		if from<0 and to>=0: return 1 if to==0 else -1
		if from>=0 and to<0: return -1 if from==0 else 1
	return 0


static func _hex_new_direction_conflict(proposed:Array,accepted:Array,corridors:Array)->String:
	for cells in corridors:
		var direction:int=_hex_direction(proposed,cells)
		if direction==0: continue
		for segment in accepted:
			var other:int=_hex_direction([segment],cells)
			if other!=0 and other!=direction: return "corridor_direction_conflict"
	return ""


static func _hex_backoff(id:String,start:Vector2i,index:Dictionary,graph:Dictionary,budget:Dictionary)->Dictionary:
	var queue:Array=[start]
	var parents:Dictionary={start:start}
	var cursor:int=0
	var goal:Variant=null
	while cursor<queue.size() and budget.remaining>0:
		var grid:Vector2i=queue[cursor]; cursor+=1; budget.remaining-=1
		var legal:Array=graph.get(grid,[])
		if grid!=start and legal.size()>2:
			goal=grid; break
		for next in legal:
			if parents.has(next) or parents.size()>=64 or not graph.has(next): continue
			var occupied:bool=false
			for interval in index.cells.get(next,[]):
				if interval.unit_id!=id: occupied=true; break
			if not occupied:
				parents[next]=grid; queue.append(next)
	var path:Array=[]
	if goal!=null:
		var current:Vector2i=goal
		while current!=start:
			path.push_front(current); current=parents[current]
		path.push_front(start)
	return {"backoff_path_grid_points":path,"backoff_examined_cells":cursor}


static func _hex_corridor_exit_conflict(request:Dictionary,corridors:Array,index:Dictionary)->String:
	for cells in corridors:
		var touched:bool=false
		var exit_grid:Variant=null
		var path:Array=request.path_grid_points
		for i in range(mini(path.size(),64)):
			if cells.has(path[i]): touched=true; exit_grid=path[i]
			elif touched: exit_grid=path[i]; break
		if not touched: continue
		if path.size()>64 and exit_grid==path[63] and cells.has(exit_grid): return "corridor_budget_exhausted"
		for interval in index.cells.get(exit_grid,[]):
			if interval.unit_id!=request.unit_id and interval.end==9223372036854775807: return "no_passing_space"
	return ""


static func _hex_fairness_score(request:Dictionary)->int:
	var priority:Variant=request.get("priority",0)
	var age:Variant=request.get("wait_ticks",0)
	var bounded_priority:int=clampi(priority,-1000000,1000000) if priority is int else 0
	var bounded_age:int=clampi(age,0,1000000000000) if age is int else 0
	return bounded_priority+bounded_age


static func _hex_in_corridor(grid:Vector2i,corridors:Array)->bool:
	for cells in corridors:
		if cells.has(grid): return true
	return false
