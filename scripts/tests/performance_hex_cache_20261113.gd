extends SceneTree
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
const ADAPTER = preload("res://scripts/core/hex_sight_runtime_adapter.gd")
const QUERY = preload("res://scripts/core/hex_visibility_query.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
var passed := 0
var failed := 0

class UnversionedReader extends Node:
    var source:Node
    func get_grid_topology(): return source.get_grid_topology()
    func get_tile_at_grid(grid:Vector2i): return source.get_tile_at_grid(grid)
    func blocks_los_at_grid(grid:Vector2i): return source.blocks_los_at_grid(grid)
    func get_object_height_at_grid(grid:Vector2i): return source.get_object_height_at_grid(grid)

func _init(): call_deferred("_run")

func _registry() -> Node:
    var registry = REGISTRY.new()
    registry.configure_iso_grid(Vector2.ZERO, 16.0, 8.0, "hex_axial_v1")
    for x in range(-1, 13):
        for y in range(-1, 10):
            var grid := Vector2i(x,y)
            registry.register_tile(TILE.from_dict({"tile_id":"%d:%d"%[x,y],"type_id":"ground_flat", "grid_position":grid,"world_position":registry.grid_to_world(grid),"walkable":true,"height_level":0,"object_height":0,"blocks_los":false}))
    return registry

func _read(cache, registry, observer:Dictionary, target:Dictionary, profile:Dictionary) -> Dictionary:
    return ADAPTER.query_snapshot({"hex_registry_id":registry.get_instance_id(),"hex_state":observer,"hex_profile":profile},target,registry,cache)

func _check(ok:bool, label:String):
    if ok: passed += 1
    else: failed += 1; push_error(label)

func _run():
    var registry = _registry()
    var cache = CACHE.new()
    var observer := {"grid":Vector2i.ZERO,"facing_dir":0,"stand_height_steps2":0}
    var target := {"grid":Vector2i(4,0),"stand_height_steps2":0}
    var profile := {"range_hex":10,"arc_degrees":120.0}
    cache.begin_tick(1)
    _check(cache.has_method("query_hex_visibility"),"Hex adapter must share tick-local terrain results")
    var first := _read(cache,registry,observer,target,profile)
    var duplicate := _read(cache,registry,observer,target,profile)
    _check(first==duplicate and first.visible,"Repeated forward pair matches")
    if cache.has_method("query_hex_visibility"):
        _check(cache.get_audit_snapshot().hex_actual_los_check_count==1,"Duplicate pair traces terrain once")
        observer.facing_dir=3
        _check(_read(cache,registry,observer,target,profile).reason=="outside_arc","Facing changes immediately")
        observer.facing_dir=0
        profile.range_hex=1
        _check(_read(cache,registry,observer,target,profile).reason=="out_of_range","Range changes immediately")
        profile.range_hex=10
        registry.set_runtime_tile_overrides([{"grid_position":Vector2i(2,0),"blocks_los_override":true,"object_height_override":2}])
        _check(not _read(cache,registry,observer,target,profile).visible,"Terrain revision invalidates same-tick answer")
        observer.stand_height_steps2=6; target.stand_height_steps2=6
        _check(_read(cache,registry,observer,target,profile).visible,"Endpoint height changes invalidate")
        observer.stand_height_steps2=0; target.stand_height_steps2=0
        target.grid=Vector2i(0,4); profile.arc_degrees=360.0
        _check(_read(cache,registry,observer,target,profile).visible,"Target cell changes invalidate")
        var other = _registry()
        target.grid=Vector2i(4,0)
        _check(_read(cache,other,observer,target,profile).visible,"Registry identity isolates terrain answers")
        var audit:Dictionary = cache.get_audit_snapshot()
        _check(audit.hex_entry_count<=4096,"Hex cache bounded")
        cache.begin_tick(2)
        _check(cache.get_audit_snapshot().hex_entry_count==0,"Tick transition drops derived entries")
        _read(cache,registry,observer,target,profile)
        _check(cache.get_audit_snapshot().hex_actual_los_check_count==1,"Next tick computes again")
        var exposed := _read(cache,registry,observer,target,profile)
        exposed.visible=true
        _check(not _read(cache,registry,observer,target,profile).visible,"Caller mutation cannot poison cache")
        for height in range(5000):
            observer.stand_height_steps2=height
            _read(cache,registry,observer,target,profile)
        _check(cache.get_audit_snapshot().hex_entry_count<=4096,"Long single tick cannot grow cache without bound")
        for facing in [0,3]:
            for height in [0,3,6]:
                for reach in [1,10]:
                    observer={"grid":Vector2i.ZERO,"facing_dir":facing,"stand_height_steps2":height}
                    target={"grid":Vector2i(4,0),"stand_height_steps2":height}
                    profile={"range_hex":reach,"arc_degrees":120.0}
                    _check(_read(cache,registry,observer,target,profile)==QUERY.evaluate(observer,target,registry,profile),"Cached result equals pure query across facing/height/range combinations")
        var unversioned := UnversionedReader.new()
        unversioned.source=registry
        profile={"range_hex":10,"arc_degrees":360.0}
        var checks_before:int=cache.get_audit_snapshot().hex_actual_los_check_count
        _read(cache,unversioned,observer,target,profile)
        _read(cache,unversioned,observer,target,profile)
        _check(cache.get_audit_snapshot().hex_actual_los_check_count==checks_before+2,"Unversioned terrain never shares an answer")
        unversioned.free()
        other.free()
    registry.clear_runtime_tile_overrides()
    var sources:Array[Dictionary]=[]
    var targets:Array[Dictionary]=[]
    for y in range(8):
        for x in range(8):
            sources.append({"grid":Vector2i(x,y),"facing_dir":0,"stand_height_steps2":0})
            targets.append({"grid":Vector2i(x+4,y),"stand_height_steps2":0})
    var samples:Array[int]=[]
    profile={"range_hex":10,"arc_degrees":120.0}
    for sample in range(35):
        cache.begin_tick(100+sample)
        var started := Time.get_ticks_usec()
        for reader in range(4):
            for pair in range(sources.size()):
                var actual := _read(cache,registry,sources[pair],targets[pair],profile)
                if not actual.visible: failed+=1
        var elapsed := Time.get_ticks_usec()-started
        if sample>=5: samples.append(elapsed)
    print("PERF_SAMPLE ",JSON.stringify({"metric":"hex_visibility_64_pairs_4_readers_cpu","unit":"usec","samples":samples,"pairs":64,"readers":4,"tick_local":true,"renderer":"headless"}))
    cache.free(); registry.free()
    print("PERFORMANCE_REVIEW passed=%d failed=%d"%[passed,failed])
    quit(1 if failed else 0)
