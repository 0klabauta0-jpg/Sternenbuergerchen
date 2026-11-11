extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var failed := 0
	var sim = ROOT.new()
	var auth := {"runtime_authorized":true}
	for entry in [["a", Vector2i(10,10)], ["b", Vector2i(11,9)]]:
		if not sim.admit_space_actor({"craft_id":entry[0], "faction_id":"enemy", "control_domain":"enemy", "start_hex":entry[1], "footprint_hexes":[Vector2i.ZERO]}, auth).get("ok", false): failed += 1
	var a: RefCounted = sim.get_space_actor("a")
	var b: RefCounted = sim.get_space_actor("b")
	var before_a: Dictionary = a.get_snapshot()
	var before_b: Dictionary = b.get_snapshot()
	var moves: Array[Dictionary] = [
		{"craft_id":"a", "expected_revision":before_a.revision, "position_plane":GRID.HEX.axial_to_plane(Vector2(12,10))},
		{"craft_id":"b", "expected_revision":before_b.revision, "position_plane":GRID.HEX.axial_to_plane(Vector2(11,11))}
	]
	var bad: Array[Dictionary] = moves.duplicate(true)
	bad[1].expected_revision = -1
	if sim.commit_space_fleet_motion(bad, 1, {}, auth).get("reason") != "stale_revision": failed += 1
	if a.get_snapshot() != before_a or b.get_snapshot() != before_b: failed += 1
	var result: Dictionary = sim.commit_space_fleet_motion(moves, 1, {}, auth)
	if not result.get("ok", false) or result.accepted.size() != 1 or result.rejected.size() != 1: failed += 1
	var rejected_id: String = result.rejected.keys()[0]
	var rejected: RefCounted = sim.get_space_actor(rejected_id)
	if rejected.get_snapshot() != (before_a if rejected_id == "a" else before_b): failed += 1
	var id: String = result.accepted[0]
	var moved: RefCounted = sim.get_space_actor(id)
	var cell: Vector2i = GRID.cell_at(Vector2(moved.get_snapshot().position_plane) / GRID.EXTENT)
	var cells: Array[Vector2i] = [cell]
	if not sim.get_space_actors_at(cells).has(id): failed += 1
	if sim.commit_space_fleet_motion(moves, 2, {}, {}).get("reason") != "runtime_authority_required": failed += 1
	sim.free()
	print("SPACE_COMBAT_AP03_BATCH passed=", 8-failed, " failed=", failed)
	quit(1 if failed else 0)
