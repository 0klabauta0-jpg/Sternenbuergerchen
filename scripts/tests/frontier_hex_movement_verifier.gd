extends SceneTree
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const SIMULATION = preload("res://scripts/core/simulation_root.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", message)

func run() -> void:
	var fixture := Node.new()
	root.add_child(fixture)
	var registry = REGISTRY.new()
	fixture.add_child(registry)
	registry.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
	var map_data = MAP.create_empty("hex_movement",Vector2i(10,10),Vector2.ZERO,64.0,32.0,3,"hex_axial_v1")
	for tile in map_data.get_tiles():
		registry.register_tile(tile)
	var sim = SIMULATION.new()
	fixture.add_child(sim)
	sim.set_physics_process(false)
	sim.set_process(false)
	sim.local_avoidance_enabled = false
	sim.unit_minimum_spacing_enabled = false
	var pathfinder = PATHFINDER.new()
	sim.bottleneck_reservation_enabled = false
	var samples: Array = []
	for avoidance in [false,true]:
		sim.local_avoidance_enabled = avoidance
		for direction in HEX.neighbor_directions():
			var unit := Node2D.new()
			fixture.add_child(unit)
			var start := Vector2i(4,4)
			var target_grid: Vector2i = start + direction * 2
			unit.position = registry.grid_to_world(start)
			var target: Vector2 = registry.grid_to_world(target_grid)
			var path: Array = pathfinder.find_path(start,target_grid,registry)
			var waypoints: Array = []
			for index in range(1,path.size()):
				waypoints.append(registry.grid_to_world(path[index]))
			var command := {"type":"move_to_position","unit_id":"hex_probe","target_position":target,"path":waypoints,"requeue_until_target":false,"local_avoidance_enabled":avoidance}
			var ticks := 0
			while ticks < 600 and not command["path"].is_empty():
				sim.call("_apply_move_command_with_terrain",command,unit,target,1.0,1.0/60.0,registry)
				ticks += 1
			check(ticks < 600 and unit.position.distance_to(target)<0.001,"direction reaches target")
			check(path.size()==3,"two equal Hex steps")
			samples.append({"avoidance":avoidance,"direction":[direction.x,direction.y],"ticks":ticks,"seconds":ticks/60.0})
			unit.free()
	var min_ticks := 600
	var max_ticks := 0
	for sample in samples:
		min_ticks = mini(min_ticks,int(sample["ticks"]))
		max_ticks = maxi(max_ticks,int(sample["ticks"]))
	check(max_ticks-min_ticks <= 1,"all six equal visible routes take equal simulation time within one tick")
	fixture.free()
	var result := {"synthetic_fixture":true,"passed":passed,"failed":failed,"samples":samples,"tick_spread":max_ticks-min_ticks,"engine":Engine.get_version_info()}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/grafik_20261101"))
	FileAccess.open("res://output/grafik_20261101/hex_movement_verification.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("FRONTIER_HEX_MOVEMENT ",JSON.stringify(result))
	quit(1 if failed else 0)
