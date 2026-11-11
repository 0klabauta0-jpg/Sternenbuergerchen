extends SceneTree
const PREVIEW = preload("res://scripts/tactical/space_area_transition_resolver.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const COMBAT = preload("res://scripts/core/space_combat_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

class OccupiedSpace extends RefCounted:
	var blocked := false
	var delegate = COMBAT.new()
	func preview_footprint(snapshot: Dictionary, footprint: Array) -> Array[Vector2i]:
		return delegate.preview_footprint(snapshot, footprint)
	func query_cells(_cells: Array[Vector2i], _area: String = "") -> Array[String]:
		var result: Array[String] = []
		if blocked: result.append("other")
		return result

func _initialize() -> void:
	var flight = FLIGHT.new()
	flight.configure("a", {"position_plane":Vector2.ZERO, "velocity_plane":Vector2(1,0)})
	var before: Dictionary = flight.get_snapshot()
	var space = OccupiedSpace.new()
	var target := {"position_plane":GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(200,230)))), "heading_rad":0.0}
	var failed := 0
	var result: Dictionary = PREVIEW.preview(flight, 0, "moon", target, [Vector2i.ZERO], space, 1)
	if not result.get("ok", false) or result.get("space_area_id") != "orbit_approach:moon" or flight.get_snapshot() != before: failed += 1
	if PREVIEW.preview(flight, 1, "moon", target, [Vector2i.ZERO], space, 1).get("reason") != "stale_revision": failed += 1
	space.blocked = true
	if PREVIEW.preview(flight, 0, "moon", target, [Vector2i.ZERO], space, 1).get("reason") != "occupied": failed += 1
	space.blocked = false
	target.position_plane = GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(200,100))))
	if PREVIEW.preview(flight, 0, "moon", target, [Vector2i.ZERO], space, 1).get("reason") != "outside_entry_band": failed += 1
	if not flight.get_snapshot() == before: failed += 1
	print("SPACE_COMBAT_AREA_TRANSITION_PREVIEW passed=", 5 - failed, " failed=", failed)
	quit(1 if failed else 0)
