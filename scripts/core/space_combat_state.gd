extends RefCounted
## Encounter metadata references registered motion; it does not copy positions.
const REGISTRY = preload("res://scripts/core/space_ship_registry.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
var _registry: RefCounted = REGISTRY.new()
var _metadata: Dictionary = {}
var _indexed_revisions: Dictionary = {}
var _flight_controls: Dictionary = {}
var _flight_status: Dictionary = {}

func admit_actor(definition: Dictionary, flight: RefCounted) -> Dictionary:
	# Occupancy and sweep callers still use strategic bounds. Fail closed until
	# the complete local-area admission and navigation path is connected.
	if flight != null and flight.get_snapshot().get("coordinate_frame", "strategic") != "strategic":
		return {"ok":false, "reason":"local_area_not_ready"}
	var craft_id: String = String(definition.get("craft_id", ""))
	var faction: String = String(definition.get("faction_id", ""))
	var domain: String = String(definition.get("control_domain", ""))
	var cell: Variant = definition.get("start_hex")
	var footprint: Variant = definition.get("footprint_hexes")
	if craft_id.strip_edges().is_empty() or faction.strip_edges().is_empty() or domain not in ["player", "neutral", "enemy"] or typeof(cell) != TYPE_VECTOR2I or typeof(footprint) != TYPE_ARRAY or footprint.is_empty() or footprint.size() > 64:
		return {"ok": false, "reason": "invalid_actor"}
	var unique := {}
	for offset in footprint:
		if typeof(offset) != TYPE_VECTOR2I or unique.has(offset):
			return {"ok": false, "reason": "invalid_footprint"}
		unique[offset] = true
	if not unique.has(Vector2i.ZERO):
		return {"ok": false, "reason": "invalid_footprint"}
	var initial_cells: Array[Vector2i] = _occupied_cells(flight.get_snapshot(), footprint)
	if initial_cells.is_empty() or not _registry.query_cells(initial_cells).is_empty():
		return {"ok": false, "reason": "occupied_or_invalid_footprint"}
	if not _registry.register_actor(craft_id, flight):
		return {"ok": false, "reason": "duplicate_or_invalid_actor"}
	if not _registry.update_actor_cells(craft_id, initial_cells):
		_registry.unregister_actor(craft_id)
		return {"ok": false, "reason": "invalid_actor_cell"}
	_metadata[craft_id] = {"faction_id": faction, "control_domain": domain, "footprint_hexes": footprint.duplicate()}
	_indexed_revisions[craft_id] = int(flight.get_snapshot().revision)
	return {"ok": true}

func get_actor(craft_id: String) -> RefCounted:
	return _registry.get_actor(craft_id)

func query_cells(cells: Array[Vector2i]) -> Array[String]:
	return _registry.query_cells(cells)

func update_actor_cell(craft_id: String, cell: Vector2i) -> bool:
	var flight: RefCounted = _registry.get_actor(craft_id)
	if flight == null: return false
	var cells: Array[Vector2i] = _occupied_cells(flight.get_snapshot(), _metadata[craft_id].footprint_hexes)
	if cells.is_empty() or not cells.has(cell): return false
	var updated: bool = _registry.update_actor_cells(craft_id, cells)
	if updated:
		_indexed_revisions[craft_id] = int(_registry.get_actor(craft_id).get_snapshot().revision)
	return updated

func get_flight_snapshots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for craft_id in _metadata:
		var snapshot: Dictionary = _registry.get_actor(craft_id).get_snapshot()
		snapshot["footprint_hexes"] = _metadata[craft_id].footprint_hexes.duplicate()
		result.append(snapshot)
	return result

func preview_actor_cells(craft_id: String, proposal: Dictionary) -> Array[Vector2i]:
	var flight: RefCounted = _registry.get_actor(craft_id)
	if flight == null or not _metadata.has(craft_id): return []
	var snapshot: Dictionary = flight.get_snapshot()
	snapshot.merge(proposal, true)
	return _occupied_cells(snapshot, _metadata[craft_id].footprint_hexes)

func _occupied_cells(snapshot: Dictionary, footprint: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if footprint.size() == 1 and footprint[0] == Vector2i.ZERO:
		var anchor: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(Vector2(snapshot.position_plane)))
		if GRID.contains(anchor): result.append(anchor)
		return result
	var seen := {}
	for offset in footprint:
		var offset_plane: Vector2 = GRID.HEX.axial_to_plane(Vector2(offset)).rotated(float(snapshot.heading_rad))
		var center: Vector2 = Vector2(snapshot.position_plane) + offset_plane
		var nearest: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(center))
		var source: PackedVector2Array = _hex_polygon(center, float(snapshot.heading_rad))
		var candidates: Array[Vector2i] = [nearest]
		for direction in GRID.HEX.DIRECTIONS: candidates.append(nearest + direction)
		for cell in candidates:
			var target := _hex_polygon(GRID.HEX.axial_to_plane(Vector2(cell)), 0.0)
			var intersections: Array[PackedVector2Array] = Geometry2D.intersect_polygons(source, target)
			var overlaps := false
			for polygon in intersections:
				if polygon.size() >= 3 and absf(_polygon_area(polygon)) > 0.00000001:
					overlaps = true
					break
			if not overlaps: continue
			if not GRID.contains(cell): return []
			if not seen.has(cell):
				seen[cell] = true
				result.append(cell)
	return result

func _hex_polygon(center: Vector2, heading: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for corner in 6:
		result.append(center + Vector2.from_angle(heading + PI / 6.0 + corner * PI / 3.0) * GRID.HEX.DEFAULT_RADIUS)
	return result

func _polygon_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	var origin: Vector2 = polygon[0]
	for index in polygon.size():
		area += (polygon[index] - origin).cross(polygon[(index + 1) % polygon.size()] - origin)
	return area * 0.5

func sync_moved_actors() -> void:
	for craft_id in _metadata:
		var flight: RefCounted = _registry.get_actor(craft_id)
		var snapshot: Dictionary = flight.get_snapshot()
		if int(_indexed_revisions.get(craft_id, -1)) == int(snapshot.revision):
			continue
		var cell: Vector2i = GRID.cell_at(Vector2(snapshot.position_plane) / GRID.EXTENT)
		if GRID.contains(cell):
			update_actor_cell(craft_id, cell)

func get_metadata(craft_id: String) -> Dictionary:
	return Dictionary(_metadata.get(craft_id, {})).duplicate(true)

func set_flight_control(craft_id: String, control: Dictionary) -> bool:
	if not _metadata.has(craft_id): return false
	_flight_controls[craft_id] = control.duplicate(true)
	return true

func get_flight_controls() -> Dictionary:
	return _flight_controls.duplicate(true)

func set_flight_status(craft_id: String, status: Dictionary) -> void:
	if _metadata.has(craft_id): _flight_status[craft_id] = status.duplicate(true)

func get_flight_status(craft_id: String) -> Dictionary:
	return Dictionary(_flight_status.get(craft_id, {})).duplicate(true)
