extends SceneTree
const RESOLVER = preload("res://scripts/tactical/space_order_resolver.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var target := Vector2i(10, 10)
	var goal: Vector2 = GRID.HEX.axial_to_plane(Vector2(target))
	var order := {"verb":"move", "target_hex":target, "arrival_radius":0.25}
	var world := {"members":{"a":{"position_plane":goal + Vector2(2,0), "velocity_plane":Vector2.ZERO}}}
	var failed := 0
	var moving: Dictionary = RESOLVER.resolve(order, world, 1.0 / 60.0)
	if moving.get("status") != "en_route" or moving.intents.a.target_plane != goal: failed += 1
	world.members.a.position_plane = goal
	world.members.a.velocity_plane = Vector2(1,0)
	if RESOLVER.resolve(order, world, 0.1).status != "arriving": failed += 1
	world.members.a.velocity_plane = Vector2.ZERO
	var completed: Dictionary = RESOLVER.resolve(order, world, 0.1)
	if completed.status != "complete" or not completed.intents.is_empty(): failed += 1
	order.verb = "withdraw"
	if RESOLVER.resolve(order, world, 0.1).status != "complete": failed += 1
	order.verb = "secure"
	if RESOLVER.resolve(order, world, 0.1).status != "holding": failed += 1
	world.members.a.blocked = true
	world.members.a.position_plane += Vector2(2,0)
	var blocked: Dictionary = RESOLVER.resolve(order, world, 0.1)
	if blocked.status != "blocked" or not blocked.intents.is_empty(): failed += 1
	world.members.a.blocked = false
	world.members.a.position_plane = goal
	var patrol := {"verb":"patrol", "waypoints":[target, Vector2i(11,10)], "arrival_radius":0.25, "waypoint_index":0}
	var next: Dictionary = RESOLVER.resolve(patrol, world, 0.1)
	if next.status != "patrolling" or next.next_waypoint_index != 1: failed += 1
	world.members.a.position_plane = GRID.HEX.axial_to_plane(Vector2(11,10))
	patrol.waypoint_index = 1
	if RESOLVER.resolve(patrol, world, 0.1).next_waypoint_index != 0: failed += 1
	if RESOLVER.resolve(order, {"members":{}}, 0.1).get("reason") != "no_members": failed += 1
	if RESOLVER.resolve(order, world, -1.0).get("reason") != "invalid_delta": failed += 1
	var local_cell: Vector2i = GRID.from_offset(Vector2i(400,100))
	var local_order := {"verb":"move", "target_hex":local_cell}
	world["coordinate_frame"] = "local"
	world["space_area_id"] = "orbit_approach:moon"
	if not RESOLVER.resolve(local_order, world, 0.1).get("ok", false): failed += 1
	print("SPACE_COMBAT_AP06_NAVIGATION passed=", 11 - failed, " failed=", failed)
	quit(1 if failed else 0)
