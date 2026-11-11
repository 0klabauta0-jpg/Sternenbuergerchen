extends SceneTree
const STATE = preload("res://scripts/core/space_combat_state.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var state = STATE.new()
	var cell: Vector2i = GRID.from_offset(Vector2i(400,100))
	var failed := 0
	var a = _flight("space_fixture_a", "orbit_approach:moon", cell)
	var b = _flight("space_fixture_b", "orbit_approach:planet", cell)
	var c = _flight("space_fixture_c", "orbit_approach:moon", cell)
	var d = _flight("real_ship", "orbit_approach:planet", cell)
	if not state.admit_actor(_definition("space_fixture_a", cell), a, true).get("ok", false): failed += 1
	if not state.admit_actor(_definition("space_fixture_b", cell), b, true).get("ok", false): failed += 1
	if state.admit_actor(_definition("space_fixture_c", cell), c, true).get("reason") != "occupied_or_invalid_footprint": failed += 1
	if state.admit_actor(_definition("real_ship", cell), d, true).get("reason") != "local_area_not_ready": failed += 1
	var cells: Array[Vector2i] = [cell]
	if state.query_cells(cells, "orbit_approach:moon") != ["space_fixture_a"]: failed += 1
	if state.query_cells(cells, "orbit_approach:planet") != ["space_fixture_b"]: failed += 1
	if not state.query_cells(cells).is_empty(): failed += 1
	var next: Vector2i = GRID.from_offset(Vector2i(401,100))
	a.commit_motion({"expected_revision":a.get_snapshot().revision, "position_plane":GRID.HEX.axial_to_plane(Vector2(next))}, 1)
	state.sync_moved_actors()
	var next_cells: Array[Vector2i] = [next]
	if not state.query_cells(cells, "orbit_approach:moon").is_empty() or state.query_cells(next_cells, "orbit_approach:moon") != ["space_fixture_a"]: failed += 1
	print("SPACE_COMBAT_AREA_ADMISSION passed=", 8 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _flight(id: String, area: String, cell: Vector2i) -> RefCounted:
	var flight = FLIGHT.new()
	flight.configure(id, {"position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "coordinate_frame":"local", "space_area_id":area})
	return flight

func _definition(id: String, cell: Vector2i) -> Dictionary:
	return {"craft_id":id, "faction_id":"enemy", "control_domain":"enemy", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}
