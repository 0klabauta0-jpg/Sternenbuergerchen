extends SceneTree
const PLAN = preload("res://scripts/mission/orbit_auto_transit_planner.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var bottom := GRID.from_offset(Vector2i(256, 240))
	var inbound: Dictionary = PLAN.plan("orbit_approach:moon", bottom, "inbound", [Vector2i.ZERO], [], [])
	assert(inbound.ok and GRID.to_offset(inbound.target_hex).y < 10)
	var outbound: Dictionary = PLAN.plan("orbit_approach:moon", inbound.target_hex, "outbound", [Vector2i.ZERO], [], [])
	assert(outbound.ok and GRID.to_offset(outbound.target_hex).y >= 224)
	assert(PLAN.plan("orbit_approach:moon", bottom, "inbound", [Vector2i.ZERO], [], ["hostile"]).reason == "contact_detected")
	var barrier: Array[Vector2i] = []
	for x in range(512): barrier.append(GRID.from_offset(Vector2i(x, 120)))
	assert(PLAN.plan("orbit_approach:moon", bottom, "inbound", [Vector2i.ZERO], barrier, []).reason == "route_blocked")
	print("ORBIT_AUTO_TRANSIT_PLANNER passed")
	quit()
