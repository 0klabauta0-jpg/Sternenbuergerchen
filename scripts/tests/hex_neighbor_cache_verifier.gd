extends SceneTree
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const PLANNER=preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
const HEX=preload("res://scripts/terrain/hex_grid.gd")
class UncachedRegistry extends Node:
	var owner_registry: Node
	func get_grid_topology():return owner_registry.get_grid_topology()
	func get_revision():return owner_registry.get_revision()
	func is_walkable(grid):return owner_registry.is_walkable(grid)
	func get_tile_at_grid(grid):return owner_registry.get_tile_at_grid(grid)
var passed:=0
var failed:=0
func _init() -> void:call_deferred("_run")
func _check(value: bool,label: String) -> void:
	if value:
		passed+=1
		print("PASS: ",label)
	else:
		failed+=1
		print("FAIL: ",label)
func _run() -> void:
	var terrain=REGISTRY.new()
	_check(terrain.has_method("get_legal_hex_neighbors") and terrain.has_method("get_hex_neighbor_cache_audit_snapshot"),"registry exposes a bounded derived legal-neighbor query")
	if failed>0:
		terrain.free()
		_finish()
		return
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(4):
		for y in range(3):
			terrain.register_tile(TILE.new({"tile_id":"%d_%d"%[x,y],"grid_position":Vector2i(x,y),"walkable":true,"explicit_hex_ramps":true}))
	var origin:=Vector2i(1,1)
	terrain.get_tile_at_grid(origin).ramp_direction=0
	terrain.get_tile_at_grid(Vector2i(1,2)).ramp_direction=0
	terrain.get_tile_at_grid(Vector2i(2,1)).height_level=1
	terrain.notify_tile_data_changed([origin,Vector2i(1,2),Vector2i(2,1)])
	var revision:int=terrain.get_revision()
	var neighbors:Array=terrain.get_legal_hex_neighbors(origin)
	_check(neighbors.size()==3 and neighbors.has(Vector2i(2,1)) and neighbors.has(Vector2i(0,1)) and neighbors.has(Vector2i(1,2)),"ramp ends and matching lateral half-height band are legal neighbors")
	_check(not neighbors.has(Vector2i(1,0)),"lateral integer plateau remains a cliff")
	var first:Dictionary=terrain.get_hex_neighbor_cache_audit_snapshot()
	_check(first.builds==1 and first.entry_count==1 and first.derived_only,"first query builds one derived terrain entry")
	neighbors.clear()
	_check(terrain.get_legal_hex_neighbors(origin).size()==3,"returned neighbor arrays cannot mutate the cache")
	_check(terrain.get_hex_neighbor_cache_audit_snapshot().builds==1 and terrain.get_hex_neighbor_cache_audit_snapshot().hits==1,"same-revision query reuses canonical terrain work")
	_check(terrain.get_revision()==revision,"read cache changes no terrain revision")
	for grid in terrain.get_legal_hex_neighbors(origin):
		_check(terrain.get_legal_hex_neighbors(grid).has(origin),"cached foot transition stays bidirectional")
	terrain.get_tile_at_grid(Vector2i(2,1)).walkable=false
	terrain.notify_tile_data_changed([Vector2i(2,1)])
	var before_builds:int=terrain.get_hex_neighbor_cache_audit_snapshot().builds
	_check(not terrain.get_legal_hex_neighbors(origin).has(Vector2i(2,1)) and terrain.get_hex_neighbor_cache_audit_snapshot().builds==before_builds+1,"terrain revision invalidates stale neighbor results")
	for x in range(4097):terrain.get_legal_hex_neighbors(Vector2i(10000+x,10000))
	_check(terrain.get_hex_neighbor_cache_audit_snapshot().entry_count==4096,"neighbor cache remains bounded including missing cells")
	var snapshot:Dictionary={"map_id":"cache_fixture","revision":1,"current_tick":0,"terrain_revision":terrain.get_revision(),
		"units_by_id":{"u":{"grid":origin}},"occupant_by_grid":{origin:"u"},"reservation_schema_version":1,"committed_segments":[],"committed_corridor_grants":[]}
	var requests:Array=[{"unit_id":"u","command_id":"cached","priority":0,"path_grid_points":[origin,Vector2i(0,1)],"duration_ticks_by_step":[2]}]
	var cold:Dictionary=PLANNER.build_hex_plan(requests,snapshot,terrain)
	var cache_before:Dictionary=terrain.get_hex_neighbor_cache_audit_snapshot()
	var warm:Dictionary=PLANNER.build_hex_plan(requests,snapshot,terrain)
	var cache_after:Dictionary=terrain.get_hex_neighbor_cache_audit_snapshot()
	_check(cold==warm and cache_after.builds==cache_before.builds and cache_after.hits>cache_before.hits,"planner reuses same-revision topology without changing proposals")
	var other=REGISTRY.new()
	other.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	other.register_tile(TILE.new({"tile_id":"only","grid_position":origin,"walkable":true}))
	_check(other.get_legal_hex_neighbors(origin).is_empty(),"different registry never reuses another map's neighbors")
	var door=REGISTRY.new()
	door.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	door.register_tile(TILE.new({"tile_id":"floor","grid_position":Vector2i.ZERO,"walkable":true,"explicit_hex_ramps":true}))
	door.register_tile(TILE.new({"tile_id":"door","grid_position":Vector2i(1,0),"walkable":false,"explicit_hex_ramps":true}))
	door.set_runtime_tile_overrides([{"grid_position":Vector2i(1,0),"walkable_override":true,"blocks_los_override":false}])
	_check(door.is_walkable(Vector2i(1,0)) and door.get_legal_hex_neighbors(Vector2i.ZERO).has(Vector2i(1,0)),"opened runtime door honors registry passability in explicit ramp maps")
	var raw_door=door.get_tile_at_grid(Vector2i(1,0))
	var floor_tile=door.get_tile_at_grid(Vector2i.ZERO)
	_check(not TILE.allows_step(floor_tile,raw_door) and is_inf(TILE.endpoint_height(raw_door,Vector2i.ZERO)),"authoring defaults keep raw blocked tiles blocked")
	_check(not TILE.allows_registry_step(floor_tile,raw_door,true,false) and not TILE.allows_registry_step(raw_door,floor_tile,false,true),"runtime entry requires both authoritative passability results")
	var uncached=UncachedRegistry.new()
	uncached.owner_registry=door
	_check(PLANNER._hex_legal_step(Vector2i.ZERO,Vector2i(1,0),uncached) and PLANNER._hex_legal_step(Vector2i(1,0),Vector2i.ZERO,uncached),"uncached planner fallback shares runtime door semantics")
	door.set_runtime_tile_overrides([{"grid_position":Vector2i(1,0),"walkable_override":false}])
	_check(door.get_legal_hex_neighbors(Vector2i.ZERO).is_empty() and not PLANNER._hex_legal_step(Vector2i.ZERO,Vector2i(1,0),uncached),"closing door invalidates cached and uncached transitions")
	var authoring_matches:=true
	var runtime_matches:=true
	for direction in range(6):
		var ramp=TILE.new({"tile_id":"ramp","grid_position":Vector2i.ZERO,"height_level":2,"ramp_direction":direction,"explicit_hex_ramps":true})
		var axis:Vector2i=HEX.DIRECTIONS[direction]
		var high=TILE.new({"tile_id":"high","grid_position":axis,"height_level":3,"explicit_hex_ramps":true})
		var side=TILE.new({"tile_id":"side","grid_position":HEX.DIRECTIONS[(direction+1)%6],"height_level":2,"explicit_hex_ramps":true})
		authoring_matches=authoring_matches and TILE.allows_step(ramp,high) and TILE.allows_step(high,ramp) and not TILE.allows_step(ramp,side) and TILE.endpoint_height(ramp,axis)==3.0
		ramp.walkable=false
		runtime_matches=runtime_matches and not TILE.allows_step(ramp,high) and TILE.allows_registry_step(ramp,high,true,true) and TILE.allows_registry_step(high,ramp,true,true) and not TILE.allows_registry_step(ramp,side,true,true)
	_check(authoring_matches,"all six authoring ramp axes and lateral endpoint rules remain unchanged")
	_check(runtime_matches,"all six opened runtime ramps retain bidirectional axis and lateral cliff rules")
	var invalid_ramp=TILE.new({"tile_id":"invalid","grid_position":Vector2i.ZERO,"height_level":8,"ramp_direction":0,"explicit_hex_ramps":true})
	_check(not TILE.allows_registry_step(invalid_ramp,floor_tile,true,true),"runtime passability cannot make H8 to H9 ramp valid")
	uncached.free()
	var square=REGISTRY.new()
	square.configure_iso_grid(Vector2.ZERO,64,32,"square8")
	_check(square.get_legal_hex_neighbors(origin).is_empty() and square.get_hex_neighbor_cache_audit_snapshot().entry_count==0,"legacy square topology does not activate hex neighbor caching")
	square.free()
	door.free()
	other.free()
	terrain.free()
	_finish()
func _finish() -> void:
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_NEIGHBOR_CACHE_PASS")
	quit(0 if failed==0 else 1)
