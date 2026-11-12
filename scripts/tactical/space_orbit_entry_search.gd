extends RefCounted
## Runtime-owned bounded search; candidates are not reservations.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const MAX_CHECKS_PER_STEP := 256
var _layout: Dictionary = {}
var _occupancy: RefCounted
var _requests: Dictionary = {}
var _ids: Array = []
var _index := 0
var _x := 0
var _y := 0
var _reserved := {}
var _allocations := {}
var _body := {}
var _ended := false

func begin(body_id: String, requests: Array[Dictionary], occupancy: RefCounted) -> Dictionary:
	if not _layout.is_empty() or occupancy == null or not occupancy.has_method("preview_footprint") or not occupancy.has_method("query_cells") or not occupancy.has_method("query_navigation_claims") or requests.is_empty() or requests.size() > 64:
		return {"ok":false, "reason":"invalid_request"}
	var layout: Dictionary = LAYOUT.build(body_id)
	if not layout.get("ok", false): return {"ok":false, "reason":"invalid_body"}
	var checked := {}
	for request in requests:
		var id: Variant = request.get("craft_id")
		var flight: Variant = request.get("flight")
		var footprint: Variant = request.get("footprint_hexes")
		if typeof(id) != TYPE_STRING or String(id).strip_edges().is_empty() or checked.has(id) or not flight is RefCounted or not flight.has_method("get_snapshot") or typeof(footprint) != TYPE_ARRAY or footprint.is_empty() or footprint.size() > 64:
			return {"ok":false, "reason":"invalid_request"}
		var seen := {}
		for offset in footprint:
			if typeof(offset) != TYPE_VECTOR2I or seen.has(offset): return {"ok":false, "reason":"invalid_request"}
			seen[offset] = true
		var snapshot: Dictionary = flight.get_snapshot()
		if not seen.has(Vector2i.ZERO) or snapshot.get("craft_id") != id or typeof(snapshot.get("revision")) != TYPE_INT: return {"ok":false, "reason":"invalid_request"}
		if request.has("entry_heading"):
			if typeof(request.entry_heading) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(request.entry_heading)): return {"ok":false, "reason":"invalid_request"}
			snapshot["heading_rad"] = float(request.entry_heading)
		checked[id] = {"flight":flight, "snapshot":snapshot.duplicate(true), "footprint":footprint.duplicate()}
	_layout = layout
	_occupancy = occupancy
	_requests = checked
	_ids = checked.keys()
	_ids.sort()
	_x = layout.entry_band.position.x
	_y = layout.entry_band.end.y - 1
	for cell in layout.body_cells: _body[cell] = true
	return {"ok":true}

func advance(budget: int) -> Dictionary:
	if budget <= 0 or budget > MAX_CHECKS_PER_STEP: return {"ok":false, "reason":"invalid_budget"}
	if _layout.is_empty() or _ended: return {"ok":false, "reason":"search_inactive"}
	for id in _ids:
		if _requests[id].flight.get_snapshot().get("revision") != _requests[id].snapshot.revision:
			_ended = true
			return {"ok":false, "reason":"stale_flight"}
	for attempt in range(budget):
		if _y < _layout.entry_band.position.y:
			_ended = true
			return {"ok":false, "reason":"entry_full"}
		var id: String = _ids[_index]
		var snapshot: Dictionary = _requests[id].snapshot.duplicate(true)
		snapshot["coordinate_frame"] = "local"
		snapshot["space_area_id"] = _layout.body_map_id
		snapshot["position_plane"] = GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(_x, _y))))
		var cells: Array[Vector2i] = _occupancy.preview_footprint(snapshot, _requests[id].footprint)
		_advance_cursor()
		if cells.is_empty(): continue
		var invalid := false
		for cell in cells:
			if not _layout.entry_band.has_point(GRID.to_offset(cell)) or _body.has(GRID.to_offset(cell)) or _reserved.has(cell):
				invalid = true
				break
		if invalid or not _occupancy.query_cells(cells, _layout.body_map_id).is_empty(): continue
		var claimed := false
		for claimant in _occupancy.query_navigation_claims(cells, _layout.body_map_id):
			if claimant != id: claimed = true; break
		if claimed: continue
		for cell in cells: _reserved[cell] = true
		_allocations[id] = {"position_plane":snapshot.position_plane, "cells":cells}
		_index += 1
		if _index < _ids.size():
			_x = _layout.entry_band.position.x
			_y = _layout.entry_band.end.y - 1
			continue
		for allocated_id in _allocations:
			var allocated: Dictionary = _allocations[allocated_id]
			if not _occupancy.query_cells(allocated.cells, _layout.body_map_id).is_empty():
				_ended = true
				return {"ok":false, "reason":"occupancy_changed"}
			for claimant in _occupancy.query_navigation_claims(allocated.cells, _layout.body_map_id):
				if claimant != allocated_id:
					_ended = true
					return {"ok":false, "reason":"occupancy_changed"}
		_ended = true
		return {"ok":true, "status":"complete", "space_area_id":_layout.body_map_id, "allocations":_allocations.duplicate(true)}
	return {"ok":true, "status":"pending"}

func _advance_cursor() -> void:
	_x += 1
	if _x >= _layout.entry_band.end.x:
		_x = _layout.entry_band.position.x
		_y -= 1
