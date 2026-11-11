extends RefCounted
## Pure geometric flight-side preflight; it does not authorize or commit travel.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")

static func preview(flight: RefCounted, expected_revision: int, body_id: String, target: Dictionary, footprint: Array, occupancy: RefCounted, tick: int) -> Dictionary:
	if flight == null or occupancy == null or not flight.has_method("validate_area_transition") or not occupancy.has_method("preview_footprint") or not occupancy.has_method("query_cells") or not occupancy.has_method("query_navigation_claims"):
		return {"ok":false, "reason":"invalid_context"}
	for key in target:
		if key not in ["position_plane", "heading_rad", "velocity_plane", "angular_velocity"]: return {"ok":false, "reason":"invalid_target"}
	if typeof(target.get("position_plane")) != TYPE_VECTOR2: return {"ok":false, "reason":"invalid_target"}
	var layout: Dictionary = LAYOUT.build(body_id)
	if not layout.get("ok", false): return {"ok":false, "reason":"invalid_body"}
	var before: Dictionary = flight.get_snapshot()
	var proposal: Dictionary = target.duplicate(true)
	proposal.merge({"expected_revision":expected_revision, "coordinate_frame":"local", "space_area_id":layout.body_map_id}, true)
	var validation: Dictionary = flight.validate_area_transition(proposal, tick)
	if not validation.get("ok", false): return validation
	var candidate := before.duplicate(true)
	candidate.merge(proposal, true)
	var cells: Array[Vector2i] = occupancy.preview_footprint(candidate, footprint)
	if cells.is_empty(): return {"ok":false, "reason":"invalid_footprint"}
	var anchor: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(target.position_plane))
	if not layout.entry_band.has_point(GRID.to_offset(anchor)): return {"ok":false, "reason":"outside_entry_band"}
	for cell in cells:
		if not layout.entry_band.has_point(GRID.to_offset(cell)): return {"ok":false, "reason":"outside_entry_band"}
	var body_cells := {}
	for cell in layout.body_cells: body_cells[cell] = true
	for cell in cells:
		if body_cells.has(GRID.to_offset(cell)): return {"ok":false, "reason":"blocked"}
	for id in occupancy.query_cells(cells, layout.body_map_id):
		if id != before.craft_id: return {"ok":false, "reason":"occupied"}
	for id in occupancy.query_navigation_claims(cells, layout.body_map_id):
		if id != before.craft_id: return {"ok":false, "reason":"navigation_claimed"}
	return {"ok":true, "space_area_id":layout.body_map_id, "proposal":proposal, "cells":cells}
