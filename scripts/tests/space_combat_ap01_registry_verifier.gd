extends SceneTree
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const REGISTRY = preload("res://scripts/core/space_ship_registry.gd")

func _initialize() -> void:
	var failed := 0
	var flight = FLIGHT.new()
	flight.configure("npc1", {"position_plane": Vector2.ZERO})
	var registry = REGISTRY.new()
	if not registry.register_actor("npc1", flight): failed += 1
	if registry.register_actor("npc1", flight) or registry.get_actor("npc1") != flight: failed += 1
	var first: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0)]
	if not registry.update_actor_cells("npc1", first): failed += 1
	if registry.query_cells(first) != ["npc1"]: failed += 1
	var second: Array[Vector2i] = [Vector2i(2, 0)]
	registry.update_actor_cells("npc1", second)
	if not registry.query_cells(first).is_empty() or registry.query_cells(second) != ["npc1"]: failed += 1
	if not registry.unregister_actor("npc1") or not registry.query_cells(second).is_empty(): failed += 1
	print("SPACE_COMBAT_AP01_REGISTRY passed=", 6 - failed, " failed=", failed)
	quit(1 if failed else 0)
