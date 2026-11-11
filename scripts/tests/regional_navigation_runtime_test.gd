extends SceneTree

const SIM = preload("res://scripts/core/simulation_root.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")

class RegionalFixture extends "res://scripts/terrain/terrain_registry.gd":
	# Small deterministic geometry exercises the production large-hex branch.
	func get_tile_count() -> int:
		return 512 * 256

var _failures := 0
var _checks := 0


func _init() -> void:
	call_deferred("_run")


func _command(id: String, target: Vector2, token: String) -> Dictionary:
	return {"command_type": "move_to_position", "unit_id": id, "team_id": "team_alpha",
		"target_position": target, "move_speed_factor": 1.0, "priority": 12,
		"command_token": token, "requeue_until_target": true}


func _run() -> void:
	var scene := Node.new()
	root.add_child(scene)
	var registry := RegionalFixture.new()
	registry.name = "TerrainRegistry"
	scene.add_child(registry)
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, "hex_axial_v1")
	for q in range(80):
		for r in range(40):
			var grid := Vector2i(q, r)
			registry.register_tile(TILE.new({"tile_id": str(grid), "grid_position": grid,
				"world_position": registry.grid_to_world(grid), "walkable": q != 40}))
	var units := UNITS.new()
	units.name = "UnitRegistry"
	scene.add_child(units)
	var sim := SIM.new()
	sim.name = "SimulationRoot"
	sim.terrain_registry_path = NodePath("../TerrainRegistry")
	sim.unit_registry_path = NodePath("../UnitRegistry")
	sim.unit_minimum_spacing_enabled = false
	scene.add_child(sim)
	sim.set_physics_process(false)
	var actors: Array = []
	for index in range(6):
		var actor := UNIT.new()
		actor.unit_id = "parallel_%d" % index
		actor.team_id = "team_alpha"
		scene.add_child(actor)
		actor.global_position = registry.grid_to_world(Vector2i(0, 2 + index * 5))
		units.register_unit(actor.unit_id, actor)
		actors.append(actor)
		var target := Vector2i(79, 2 + index * 5) if index < 5 else Vector2i(1, 27)
		sim.enqueue_command(_command(actor.unit_id, registry.grid_to_world(target), "go_%d" % index))
	var last_start: Vector2 = actors[5].global_position
	var seen := {}
	for tick in range(8):
		sim.call("_physics_process", 0.1)
		_check(int(sim.get("_regional_navigation_expansions_this_tick")) <= 96, "Shared expansion cap tick " + str(tick))
		for command: Dictionary in sim.command_queue:
			var search: Variant = command.get("_regional_navigation_search")
			if search != null and search.expanded_count > 0:
				seen[command.unit_id] = true
	_check(seen.size() == 5 and actors[5].global_position.distance_to(last_start) > 1.0,
		"Five long unreachable jobs progress while the last short job moves")
	var old_search: Variant
	for command: Dictionary in sim.command_queue:
		if command.unit_id == actors[0].unit_id:
			old_search = command.get("_regional_navigation_search")
	registry.set_runtime_tile_overrides([{"grid_position": Vector2i(40, 2), "walkable_override": true}])
	for tick in range(3):
		sim.call("_physics_process", 0.1)
	var new_search: Variant
	for command: Dictionary in sim.command_queue:
		if command.unit_id == actors[0].unit_id:
			new_search = command.get("_regional_navigation_search")
	_check(old_search != null and new_search != null and old_search != new_search
		and new_search.revision == registry.get_revision(), "Runtime replaces pending search after door revision")
	sim.enqueue_command({"command_type": "hold_position", "unit_id": actors[0].unit_id,
		"team_id": "team_alpha", "command_token": "stop", "priority": 13})
	var expansion_at_hold: int = new_search.expanded_count
	sim.call("_physics_process", 0.1)
	var held: Vector2 = actors[0].global_position
	for tick in range(4):
		sim.call("_physics_process", 0.1)
	_check(actors[0].global_position == held, "Hold supersedes pending GO")
	var old_move_pending := false
	for command: Dictionary in sim.command_queue:
		if command.unit_id == actors[0].unit_id and command.get("command_token") == "go_0":
			old_move_pending = true
	_check(not old_move_pending and new_search.expanded_count == expansion_at_hold, "Hold removes the old move and stops its search")
	sim.enqueue_command(_command(actors[0].unit_id, registry.grid_to_world(Vector2i(8, 2)), "go_again"))
	for tick in range(32):
		sim.call("_physics_process", 0.1)
		if actors[0].global_position.distance_to(held) > 1.0:
			break
	_check(actors[0].global_position.distance_to(held) > 1.0, "Fresh GO after Hold starts a new search")
	var moving_command: Dictionary = {}
	for command: Dictionary in sim.command_queue:
		if command.unit_id == actors[0].unit_id:
			moving_command = command
	_check(not Array(moving_command.get("path", [])).is_empty(), "Fresh route has begun physical movement")
	registry.set_runtime_tile_overrides([{"grid_position": Vector2i(4, 2), "walkable_override": false}])
	for tick in range(3):
		sim.call("_physics_process", 0.1)
	var repaired := false
	for command: Dictionary in sim.command_queue:
		if command.unit_id != actors[0].unit_id:
			continue
		var search: Variant = command.get("_regional_navigation_search")
		repaired = search.revision == registry.get_revision() if search != null else int(command.get("navigation_path_terrain_revision", -1)) == registry.get_revision()
	_check(repaired, "Already moving route is recalculated after a door revision")
	scene.free()
	print("Regional navigation runtime: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
