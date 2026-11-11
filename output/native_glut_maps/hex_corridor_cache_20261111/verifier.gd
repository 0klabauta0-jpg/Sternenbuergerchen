extends SceneTree

const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const CACHE=preload("res://scripts/terrain/hex_corridor_topology_cache.gd")
var passed:int=0
var failed:int=0

class FixtureRegistry extends Node:
 var graph:Dictionary={}
 var revision:int=1
 var reads:int=0
 var topology:String="hex_axial_v1"
 var mutate_on_read:bool=false
 func is_walkable(grid:Vector2i)->bool: return graph.has(grid)
 func get_revision()->int: return revision
 func get_grid_topology()->String: return topology
 func get_legal_hex_neighbors(grid:Vector2i)->Array:
  reads+=1
  if mutate_on_read: revision+=1; mutate_on_read=false
  return graph.get(grid,[]).duplicate()


class FallbackRegistry extends Node:
 var source:Node
 func is_walkable(grid:Vector2i)->bool: return source.is_walkable(grid)
 func get_revision()->int: return source.get_revision()
 func get_grid_topology()->String: return source.get_grid_topology()
 func get_tile_at_grid(grid:Vector2i): return source.get_tile_at_grid(grid)

func _init()->void: call_deferred("_run")
func _check(value:bool,label:String)->void:
 if value: passed+=1
 else: failed+=1
 print("PASS: " if value else "FAIL: ",label)

func _line(count:int)->FixtureRegistry:
 var registry:=FixtureRegistry.new()
 for x in range(count):
  var links:Array=[]
  if x>0: links.append(Vector2i(x-1,0))
  if x+1<count: links.append(Vector2i(x+1,0))
  registry.graph[Vector2i(x,0)]=links
 return registry

func _run()->void:
 var cache=CACHE.new()
 var registry:=_line(80)
 var first:Dictionary=cache.query(registry,[Vector2i.ZERO,Vector2i(79,0)],64)
 _check(first.ok and not first.complete and first.processed_nodes==64 and first.corridors.is_empty(),"80-node component is not truncated into a published 64-node corridor")
 var second:Dictionary=cache.query(registry,[Vector2i(40,0),Vector2i(79,0)],64)
 _check(second.ok and second.complete and second.processed_nodes==16 and second.corridors.size()==1,"serial component job resumes and deduplicates overlapping pending origins")
 _check(second.corridors[0].cells.size()==80 and second.corridors[0].endpoints==[Vector2i.ZERO,Vector2i(79,0)] and second.corridors[0].directed,"complete path has stable sorted endpoints and exposes an ordered passage axis")
 var reads_before:int=registry.reads
 second.corridors[0].cells.clear(); second.corridors[0].endpoints.clear()
 var warm:Dictionary=cache.query(registry,[Vector2i(20,0)])
 _check(warm.corridors[0].cells.size()==80 and registry.reads==reads_before and warm.processed_nodes==0,"returned arrays are independent and warm lookups read no new terrain")
 var zero_cache=CACHE.new()
 var zero:Dictionary=zero_cache.query(registry,[Vector2i.ZERO],0)
 _check(zero.ok and not zero.complete and zero.processed_nodes==0 and zero.pending_grid_points==[Vector2i.ZERO],"zero budget retains pending work without terrain reads")
 var bounded:Dictionary=zero_cache.query(registry,[],1000000)
 _check(bounded.processed_nodes==64 and not bounded.complete,"caller cannot exceed the 64-new-node ceiling")
 var invalid:Dictionary=cache.query(registry,["bad"])
 _check(not invalid.ok and invalid.reason=="invalid_grid" and registry.reads==reads_before+64,"invalid input is rejected before terrain queries")
 registry.revision+=1
 var refreshed:Dictionary=cache.query(registry,[Vector2i.ZERO],1)
 _check(refreshed.processed_nodes==1 and refreshed.corridors.is_empty() and not refreshed.complete,"revision change invalidates finished components and starts fresh bounded work")
 var other:=_line(2)
 var swapped:Dictionary=cache.query(other,[Vector2i.ZERO])
 _check(swapped.complete and swapped.corridors[0].cells.size()==2 and swapped.registry_id==other.get_instance_id(),"same revision on a different registry never reuses old topology")
 other.mutate_on_read=true; other.revision+=1
 var changed:Dictionary=cache.query(other,[Vector2i.ZERO])
 _check(not changed.ok and changed.reason=="registry_changed" and changed.corridors.is_empty(),"mid-query revision change discards all provisional topology")
 var branch:=_line(5)
 branch.graph[Vector2i(2,0)].append(Vector2i(2,-1)); branch.graph[Vector2i(2,-1)]=[Vector2i(2,0)]
 var branched:Dictionary=cache.query(branch,[Vector2i.ZERO,Vector2i(4,0),Vector2i(2,-1),Vector2i(2,0)])
 var branch_ok:bool=branched.complete and branched.corridors.size()==3
 for corridor in branched.corridors: branch_ok=branch_ok and not corridor.cells.has(Vector2i(2,0))
 _check(branch_ok,"degree-three junction bounds three narrow components instead of merging through it")
 var cycle:=FixtureRegistry.new()
 var ring:Array=[Vector2i(1,0),Vector2i(1,-1),Vector2i(0,-1),Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,1)]
 for i in range(6): cycle.graph[ring[i]]=[ring[(i+5)%6],ring[(i+1)%6]]
 var loop:Dictionary=cache.query(cycle,[ring[0]])
 _check(loop.complete and loop.corridors.size()==1 and loop.corridors[0].cells.size()==6 and loop.corridors[0].is_cycle and not loop.corridors[0].directed and loop.corridors[0].endpoints.is_empty(),"closed six-cell cycle is explicitly undirected and has no invented endpoints")
 var asym:=FixtureRegistry.new()
 asym.graph={Vector2i.ZERO:[Vector2i.RIGHT],Vector2i.RIGHT:[]}
 var rejected:Dictionary=cache.query(asym,[Vector2i.ZERO])
 _check(not rejected.ok and rejected.reason=="invalid_neighbors" and rejected.corridors.is_empty(),"asymmetric helper fixture cannot publish an invented bidirectional component")
 var singleton:=FixtureRegistry.new(); singleton.graph[Vector2i.ZERO]=[]
 var single:Dictionary=cache.query(singleton,[Vector2i.ZERO])
 _check(single.complete and single.corridors[0].cells==[Vector2i.ZERO] and not single.corridors[0].directed,"walkable singleton has no invented passage axis")
 var missing:Dictionary=cache.query(singleton,[Vector2i(9,9)])
 _check(missing.complete and missing.corridors.is_empty(),"unknown or blocked origin never becomes a walkable singleton")
 var real=REGISTRY.new(); real.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
 for spec in [{"grid":Vector2i(-1,0),"height":2,"ramp":-1},{"grid":Vector2i.ZERO,"height":2,"ramp":0},{"grid":Vector2i.RIGHT,"height":3,"ramp":-1}]:
  real.register_tile(TILE.new({"tile_id":str(spec.grid),"grid_position":spec.grid,"height_level":spec.height,"ramp_direction":spec.ramp,"explicit_hex_ramps":true,"walkable":true}))
 var real_result:Dictionary=cache.query(real,[Vector2i.ZERO])
 _check(real_result.ok and real_result.complete and real_result.corridors[0].cells==[Vector2i(-1,0),Vector2i.ZERO,Vector2i.RIGHT],"real TerrainRegistry ramp axis uses canonical H/H+1 legal transitions")
 var fallback:=FallbackRegistry.new(); fallback.source=real
 var fallback_result:Dictionary=cache.query(fallback,[Vector2i.ZERO])
 _check(fallback_result.corridors==real_result.corridors,"explicit fallback agrees with real registry path using both allows_step directions")
 real.register_tile(TILE.new({"tile_id":"bad_side","grid_position":Vector2i(0,1),"height_level":2,"explicit_hex_ramps":true,"walkable":true}))
 var side:Dictionary=cache.query(real,[Vector2i.ZERO,Vector2i(0,1)])
 _check(side.complete and side.corridors.size()==2,"ramp H+0.5 side rejects a plain plateau and remains a separate component")
 registry.free(); other.free(); branch.free(); cycle.free(); asym.free(); singleton.free(); fallback.free(); real.free()
 print("HEX_CORRIDOR_CACHE_PASS" if failed==0 else "HEX_CORRIDOR_CACHE_FAIL"," ",passed,"/",failed)
 quit(0 if failed==0 else 1)
