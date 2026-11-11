extends SceneTree
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
const QUERY_PATH := "res://scripts/core/hex_visibility_query.gd"
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		print("FAIL: ", label)

func _terrain(blocked: bool = false) -> Node:
	var registry: Node = REGISTRY.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, "hex_axial_v1")
	for q in range(-2,3):
		for r in range(-2,3):
			var grid := Vector2i(q,r)
			if HEX.distance(Vector2i.ZERO,grid)>2: continue
			registry.register_tile(TILE.new({"tile_id":"%d_%d" % [q,r],"grid_position":grid,
				"explicit_hex_ramps":true,"height_level":0,"ramp_direction":-1,
				"blocks_los":blocked and grid==Vector2i(1,0),"object_height":1 if blocked else 0}))
	return registry

func _state(grid: Vector2i, terrain: Node, facing: int = 0) -> Dictionary:
	return {"grid":grid,"facing_dir":facing,"stand_height_steps2":roundi(2.0 * terrain.get_stand_height_at(grid))}

func _run() -> void:
	_check(ResourceLoader.exists(QUERY_PATH), "HexVisibilityQuery is implemented")
	if failed > 0:
		_finish()
		return
	var query = load(QUERY_PATH)
	var terrain: Node = _terrain()
	for direction in range(6):
		var observer: Dictionary = _state(Vector2i.ZERO,terrain,direction)
		var ahead: Dictionary = _state(HEX.DIRECTIONS[direction]*2,terrain)
		var edge: Dictionary = _state(HEX.DIRECTIONS[(direction+1)%6]*2,terrain)
		var rear: Dictionary = _state(HEX.DIRECTIONS[(direction+3)%6]*2,terrain)
		_check(query.evaluate(observer,ahead,terrain,{"range_hex":2,"arc_degrees":120.0}).visible,"forward visible in rotated sector")
		_check(query.evaluate(observer,edge,terrain,{"range_hex":2,"arc_degrees":120.0}).visible,"60-degree boundary included")
		_check(not query.evaluate(observer,rear,terrain,{"range_hex":2,"arc_degrees":120.0}).visible,"rear outside rotated sector")
	var source: Dictionary = _state(Vector2i.ZERO,terrain)
	var target: Dictionary = _state(Vector2i(2,0),terrain)
	var profile := {"range_hex":2,"arc_degrees":120.0}
	var cache: Node = CACHE.new()
	cache.begin_tick(1)
	_check(cache.query_hex_visibility(source,target,terrain,profile).visible,"cache initial geometry visible")
	cache.begin_tick(2)
	source.render_position = Vector2(0.2,0.3)
	_check(cache.query_hex_visibility(source,target,terrain,profile).visible and cache.get_hex_cache_audit_snapshot().geometry_queries==1,"same hex geometry reused across tick and render motion")
	source.facing_dir=3
	_check(not cache.query_hex_visibility(source,target,terrain,profile).visible and cache.get_hex_cache_audit_snapshot().geometry_queries==1,"changed facing filtered before cached geometry")
	source.facing_dir=0
	_check(not cache.query_hex_visibility(source,target,terrain,{"range_hex":1,"arc_degrees":120.0}).visible and cache.get_hex_cache_audit_snapshot().geometry_queries==1,"range reduction filtered before cached geometry")
	terrain.set_runtime_tile_overrides([{"grid_position":Vector2i(1,0),"blocks_los_override":true,"object_height_override":1}])
	_check(not cache.query_hex_visibility(source,target,terrain,profile).visible,"door revision blocks formerly visible pair")
	terrain.clear_runtime_tile_overrides()
	_check(cache.query_hex_visibility(source,target,terrain,profile).visible and cache.get_hex_cache_audit_snapshot().geometry_queries==3,"door reopening recomputes current geometry")
	var alternate: Node = _terrain(true)
	_check(not cache.query_hex_visibility(source,target,alternate,profile).visible,"registry identity separates geometry")
	for grid in [Vector2i.ZERO,Vector2i(2,0)]:
		terrain.get_tile_at_grid(grid).ramp_direction=0
	terrain.get_tile_at_grid(Vector2i(1,0)).blocks_los=true
	terrain.notify_tile_data_changed([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0)])
	source=_state(Vector2i.ZERO,terrain)
	target=_state(Vector2i(2,0),terrain)
	_check(source.stand_height_steps2==1 and cache.query_hex_visibility(source,target,terrain,profile).visible,"actual ramp half-height clears lower blocker without int truncation")
	source.stand_height_steps2=0
	target.stand_height_steps2=0
	_check(not cache.query_hex_visibility(source,target,terrain,profile).visible,"changed endpoint height cannot reuse ramp geometry")
	terrain.get_tile_at_grid(Vector2i(1,0)).blocks_los=false
	terrain.notify_tile_data_changed([Vector2i(1,0)])
	cache.set_hex_cache_capacity(2)
	var all_directions := {"range_hex":2,"arc_degrees":360.0}
	var a: Dictionary = _state(Vector2i(2,0),terrain)
	var b: Dictionary = _state(Vector2i(0,2),terrain)
	var c: Dictionary = _state(Vector2i(-2,0),terrain)
	cache.query_hex_visibility(source,a,terrain,all_directions)
	cache.query_hex_visibility(source,b,terrain,all_directions)
	cache.query_hex_visibility(source,a,terrain,all_directions)
	cache.query_hex_visibility(source,c,terrain,all_directions)
	cache.query_hex_visibility(source,a,terrain,all_directions)
	cache.query_hex_visibility(source,b,terrain,all_directions)
	var audit: Dictionary = cache.get_hex_cache_audit_snapshot()
	_check(audit.entry_count==2 and audit.geometry_queries==4 and audit.hits==2,"bounded LRU retains recently used pair and evicts oldest")
	cache.begin_tick(100)
	var from_world: Vector2 = terrain.grid_to_world(Vector2i.ZERO)
	var to_world: Vector2 = terrain.grid_to_world(Vector2i(2,0))
	var legacy_first: bool = cache.has_line_of_sight_between_points(from_world,to_world,-1.0,terrain,"a","b")
	var legacy_second: bool = cache.has_line_of_sight_between_points(from_world,to_world,-1.0,terrain,"a","b")
	_check(legacy_first and legacy_second and cache.get_audit_snapshot().actual_los_check_count==1 and cache.get_audit_snapshot().cache_hit_count==1,"legacy pair reuse remains tick-local")
	cache.begin_tick(101)
	_check(cache.has_line_of_sight_between_points(from_world,to_world,-1.0,terrain,"a","b") and cache.get_audit_snapshot().cache_hit_count==0,"legacy geometry recomputes on next tick")
	_check(cache.get_hex_cache_audit_snapshot().geometry_queries==4,"legacy tick reset does not clear independent hex lifetime")
	_check(not query.evaluate({"grid":Vector2.ZERO},target,terrain,profile).visible,"malformed observer rejected")
	_check(not query.evaluate(source,_state(Vector2i(3,0),terrain),terrain,profile).visible,"missing endpoint cell rejected")
	_check(not query.evaluate(source,target,terrain,{"range_hex":"2"}).visible,"invalid profile rejected")
	var square: Node = REGISTRY.new()
	square.configure_iso_grid(Vector2.ZERO,64.0,32.0,"square8")
	_check(not query.evaluate(source,target,square,profile).visible,"hex query rejects square registry")
	square.free()
	cache.set_hex_cache_capacity(1)
	cache.query_hex_visibility(source,a,terrain,all_directions)
	cache.query_hex_visibility(source,b,terrain,all_directions)
	_check(cache.get_hex_cache_audit_snapshot().entry_count==1 and cache.get_hex_cache_audit_snapshot().geometry_queries==2,"single-entry LRU can evict its own head and tail")
	cache.clear_hex_cache()
	_check(cache.query_hex_visibility(source,a,terrain,all_directions).visible and cache.get_hex_cache_audit_snapshot().entry_count==1,"cleared cache can be filled again")
	cache.free()
	alternate.free()
	terrain.free()
	_finish()

func _finish() -> void:
	print("RESULTS: %d passed, %d failed" % [passed,failed])
	if failed==0: print("HEX_VISIBILITY_PASS")
	quit(0 if failed==0 else 1)
