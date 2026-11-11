extends SceneTree
const SURFACE = preload("res://scripts/terrain/regional_hex_surface.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const HPA = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const SIM = preload("res://scripts/core/simulation_root.gd")
var passed := 0
var failed := 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	passed += int(ok); failed += int(not ok)
	print("PASS: " if ok else "FAIL: ", label)
func tile(grid: Vector2i, height: int, direction: int = -1):
	return TILE.new({"tile_id":str(grid),"type_id":"ground_flat","grid_position":grid,
		"height_level":height,"explicit_hex_ramps":true,"regional_grade":true,"ramp_direction":direction})
func _run() -> void:
	for direction in range(6):
		var axis: Vector2i = HEX.DIRECTIONS[direction]
		var ramp = tile(Vector2i.ZERO,2,direction)
		var low = tile(-axis,2); var high = tile(axis,3)
		check(TILE.allows_step(low,ramp) and TILE.allows_step(ramp,low),"Lower end reciprocal direction"+str(direction))
		check(TILE.allows_step(high,ramp) and TILE.allows_step(ramp,high),"Upper end reciprocal direction"+str(direction))
		var side = tile(HEX.DIRECTIONS[(direction+1)%6],2)
		check(not TILE.allows_step(ramp,side) and not TILE.allows_step(side,ramp),"Same-height ramp side blocked"+str(direction))
		check(TILE.stand_height(ramp)==2.5 and TILE.endpoint_height(ramp,axis)==3.0,"Authoritative logical heights"+str(direction))
	var band_a = tile(Vector2i.ZERO, 0, 0)
	var band_b = tile(Vector2i(0, 1), 0, 0)
	check(TILE.allows_step(band_a, band_b) and TILE.allows_step(band_b, band_a), "Matching ramp-band lateral seam is reciprocal")
	check(TILE.endpoint_height(band_a, band_b.grid_position) == 0.5, "Ramp-band side uses shared midpoint height")
	var band_lookup := {band_a.grid_position: band_a, band_b.grid_position: band_b}
	var cap_a := SURFACE.profile(band_a, band_lookup)
	var cap_b := SURFACE.profile(band_b, band_lookup)
	for sample in range(3):
		check(is_equal_approx(cap_a[sample], cap_b[8 - sample]), "Broad ramp seam shares corner/midpoint " + str(sample))
	var turned = tile(Vector2i(0, 1), 0, 1)
	band_lookup[turned.grid_position] = turned
	var cap_turn := SURFACE.profile(turned, band_lookup)
	cap_a = SURFACE.profile(band_a, band_lookup)
	check(is_equal_approx(cap_a[1], 0.0), "Turned bank rendered midpoint matches the authoritative H+0.5 side")
	for sample in range(3):
		check(is_equal_approx(cap_a[sample], cap_turn[8 - sample]), "Turned bank seam shares corner/midpoint " + str(sample))

	check(not TILE.allows_step(tile(Vector2i.ZERO,0),tile(Vector2i(1,0),1)),"Plateau one-level cliff remains blocked")
	check(not TILE.allows_step(tile(Vector2i.ZERO,0,0),tile(Vector2i(1,0),0)),"Wrong upper endpoint rejected")
	var invalid = tile(Vector2i.ZERO,8,0)
	check(not invalid.is_valid() and not TILE.allows_step(invalid,tile(Vector2i(1,0),8)),"H8 ramp rejected without becoming traversable")
	var blocked = tile(Vector2i.ZERO,0,0); blocked.walkable=false
	check(not TILE.allows_step(blocked,tile(Vector2i(1,0),1)),"Blocked ramp remains blocked")
	var legacy_low = tile(Vector2i.ZERO,0); var legacy_high = tile(Vector2i(1,0),1)
	legacy_low.explicit_hex_ramps=false; legacy_high.explicit_hex_ramps=false
	check(TILE.allows_step(legacy_low,legacy_high),"Unversioned regional legacy rule retained")
	var original = tile(Vector2i.ZERO,0,0); var copy = TILE.from_dict(original.to_dict())
	check(copy.explicit_hex_ramps and copy.regional_grade and copy.ramp_direction==0,"Internal copy keeps rules and direction")
	var registry = REGISTRY.new(); registry.configure_iso_grid(Vector2.ZERO,1,1,HEX.TOPOLOGY_ID)
	for entry in [tile(Vector2i(1,0),0),tile(Vector2i(2,0),0,0),tile(Vector2i(3,0),1),tile(Vector2i(2,1),0)]:
		entry.world_position=registry.grid_to_world(entry.grid_position);registry.register_tile(entry)
	var pathfinder = PATHFINDER.new()
	check(pathfinder.find_path(Vector2i(1,0),Vector2i(3,0),registry)==[Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)],"Actual Astar crosses only the explicit ramp")
	check(not pathfinder.can_traverse_step(Vector2i(2,0),Vector2i(2,1),registry),"Actual Pathfinder rejects ramp flank")
	var graph=HPA.new();graph.build_from_registry(registry)
	check(graph.are_grids_in_same_component(Vector2i(1,0),Vector2i(3,0)) and not graph.are_grids_in_same_component(Vector2i(2,0),Vector2i(2,1)),"HPA components share the ramp transition owner")
	check(registry.get_stand_height_at(Vector2i(2,0))==0.5,"Registry exposes logical float standing height")
	var sim=SIM.new()
	check(not sim.call("_is_local_avoidance_transition_walkable",registry.grid_to_world(Vector2i(2,0)),registry.grid_to_world(Vector2i(2,1)),registry),"Actual movement correction rejects ramp flank")
	check(sim.call("_is_local_avoidance_transition_walkable",registry.grid_to_world(Vector2i(2,0)),registry.grid_to_world(Vector2i(3,0)),registry),"Actual movement correction accepts ramp axis")
	var revision:int=registry.get_revision()
	registry.get_tile_at_grid(Vector2i(2,0)).ramp_direction=1
	registry.notify_tile_data_changed([Vector2i(2,0)])
	check(registry.get_revision()>revision and not pathfinder.can_traverse_step(Vector2i(2,0),Vector2i(3,0),registry),"Owner direction edit invalidates navigation revision")
	sim.free();registry.free()
	var folder="res://output/native_glut_maps/explicit_ramp_contract/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var source={"map_name":"explicit_ramp_fixture","grid_topology":HEX.TOPOLOGY_ID,"grid_size":{"x":3,"y":1},
		"terrain_height_rules":TILE.EXPLICIT_HEIGHT_RULES,"regional_terrain_version":2,"regional_height_step":0.75,
		"tiles":[{"type_id":"ground_flat","grid_position":{"x":0,"y":0},"height_level":0},
		{"type_id":"ground_flat","grid_position":{"x":1,"y":0},"height_level":0,"ramp_direction":0},
		{"type_id":"ground_flat","grid_position":{"x":2,"y":0},"height_level":1}]}
	var file=FileAccess.open(folder+"source.json",FileAccess.WRITE);file.store_string(JSON.stringify(source));file.close()
	var map=MAP.load_from_file(folder+"source.json")
	check(map.get_tiles().size()==3 and map.get_tile_at_grid(Vector2i(1,0)).explicit_hex_ramps,"Map-level version assigns the runtime flag")
	check(map.save_to_file(folder+"saved.json")==OK,"Map save succeeds")
	var restored=MAP.load_from_file(folder+"saved.json")
	check(restored.get_terrain_height_rules()==TILE.EXPLICIT_HEIGHT_RULES and restored.get_tile_at_grid(Vector2i(1,0)).ramp_direction==0,"Save and reload preserve map rules and ramp direction")
	source.erase("terrain_height_rules");file=FileAccess.open(folder+"legacy.json",FileAccess.WRITE);file.store_string(JSON.stringify(source));file.close()
	var legacy_map=MAP.load_from_file(folder+"legacy.json")
	check(not legacy_map.get_tile_at_grid(Vector2i(1,0)).explicit_hex_ramps,"No implicit activation on old map files")
	print("EXPLICIT_HEX_RAMP_CONTRACT ",passed," passed, ",failed," failed")
	quit(0 if failed==0 else 1)
