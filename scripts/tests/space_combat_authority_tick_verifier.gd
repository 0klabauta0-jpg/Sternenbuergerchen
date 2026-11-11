extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
class ClientRoot extends "res://scripts/core/simulation_root.gd":
	func _should_skip_local_tick_processing() -> bool: return true
var calls := 0

func _initialize() -> void:
	var sim := ClientRoot.new()
	sim.configure_space_runtime_tick(Callable(self, "_tick"))
	var actor := {"craft_id":"space_fixture_client", "faction_id":"enemy", "control_domain":"enemy", "start_hex":Vector2i(10,10), "footprint_hexes":[Vector2i.ZERO]}
	var failed := 0
	if not sim.admit_space_actor(actor, {"runtime_authorized":true}).get("ok", false): failed += 1
	var flight: RefCounted = sim.get_space_actor(actor.craft_id)
	var new_cell := Vector2i(11,10)
	flight.commit_motion({"expected_revision":flight.get_snapshot().revision, "position_plane":GRID.HEX.axial_to_plane(Vector2(new_cell))}, 1)
	sim._physics_process(1.0 / 60.0)
	if calls != 0 or sim.tick_counter != 0: failed += 1
	var old_cells: Array[Vector2i] = [Vector2i(10,10)]
	var new_cells: Array[Vector2i] = [new_cell]
	if sim.get_space_actors_at(old_cells) != [actor.craft_id] or not sim.get_space_actors_at(new_cells).is_empty(): failed += 1
	sim.free()
	var host = ROOT.new()
	host.configure_space_runtime_tick(Callable(self, "_tick"))
	host._physics_process(1.0 / 60.0)
	if calls != 1 or host.tick_counter != 1: failed += 1
	host.free()
	print("SPACE_COMBAT_AUTHORITY_TICK passed=", 4 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _tick(_delta: float) -> void:
	calls += 1
