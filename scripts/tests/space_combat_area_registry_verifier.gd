extends SceneTree
const REGISTRY = preload("res://scripts/core/space_ship_registry.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const COMBAT = preload("res://scripts/core/space_combat_state.gd")

func _initialize() -> void:
	var registry = REGISTRY.new()
	var failed := 0
	var first = FLIGHT.new()
	var second = FLIGHT.new()
	var strategic = FLIGHT.new()
	first.configure("a", {"position_plane":Vector2.ZERO, "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"})
	second.configure("b", {"position_plane":Vector2.ZERO, "coordinate_frame":"local", "space_area_id":"orbit_approach:planet"})
	strategic.configure("c", {"position_plane":Vector2.ZERO})
	for pair in [["a",first], ["b",second], ["c",strategic]]:
		if not registry.register_actor(pair[0], pair[1]): failed += 1
		var cells: Array[Vector2i] = [Vector2i(5,5)]
		if not registry.update_actor_cells(pair[0], cells): failed += 1
	var cells: Array[Vector2i] = [Vector2i(5,5)]
	if registry.query_cells(cells, "orbit_approach:moon") != ["a"]: failed += 1
	if registry.query_cells(cells, "orbit_approach:planet") != ["b"]: failed += 1
	if registry.query_cells(cells) != ["c"]: failed += 1
	if not registry.unregister_actor("a") or not registry.query_cells(cells, "orbit_approach:moon").is_empty(): failed += 1
	if registry.query_cells(cells, "orbit_approach:planet") != ["b"]: failed += 1
	var combat = COMBAT.new()
	var actor := {"craft_id":"a", "faction_id":"enemy", "control_domain":"enemy", "start_hex":Vector2i(0,0), "footprint_hexes":[Vector2i.ZERO]}
	if combat.admit_actor(actor, first).get("reason") != "local_area_not_ready": failed += 1
	print("SPACE_COMBAT_AREA_REGISTRY passed=", 12 - failed, " failed=", failed)
	quit(1 if failed else 0)
