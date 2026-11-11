extends SceneTree
const ALLOC = preload("res://scripts/tactical/space_orbit_entry_allocator.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const STATE = preload("res://scripts/core/space_combat_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var a = FLIGHT.new()
	var b = FLIGHT.new()
	a.configure("a", {"position_plane":Vector2.ZERO})
	b.configure("b", {"position_plane":Vector2.ZERO})
	var before_a: Dictionary = a.get_snapshot()
	var state = STATE.new()
	var requests: Array[Dictionary] = [{"craft_id":"b", "flight":b, "footprint_hexes":[Vector2i.ZERO]}, {"craft_id":"a", "flight":a, "footprint_hexes":[Vector2i.ZERO, Vector2i(1,0)]}]
	var failed := 0
	var result: Dictionary = ALLOC.allocate("moon", requests, state)
	if not result.get("ok", false) or result.allocations.size() != 2: failed += 1
	var used := {}
	for id in ["a", "b"]:
		for cell in result.allocations[id].cells:
			if used.has(cell) or GRID.to_offset(cell).y < 224: failed += 1
			used[cell] = true
	if a.get_snapshot() != before_a: failed += 1
	requests.reverse()
	if ALLOC.allocate("moon", requests, state).allocations != result.allocations: failed += 1
	var duplicated: Array[Dictionary] = [requests[0], requests[0]]
	if ALLOC.allocate("moon", duplicated, state).get("reason") != "invalid_request": failed += 1
	var registry: RefCounted = state.get("_registry")
	var occupied = FLIGHT.new()
	occupied.configure("existing", {"position_plane":result.allocations.a.position_plane, "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"})
	registry.register_actor("existing", occupied)
	var occupied_cells: Array[Vector2i] = []
	occupied_cells.assign(result.allocations.a.cells)
	registry.update_actor_cells("existing", occupied_cells)
	var alternate: Dictionary = ALLOC.allocate("moon", requests, state)
	if not alternate.get("ok", false) or alternate.allocations.a.cells == result.allocations.a.cells: failed += 1
	print("SPACE_ORBIT_ENTRY_ALLOCATOR passed=", 6 - failed, " failed=", failed)
	quit(1 if failed else 0)
