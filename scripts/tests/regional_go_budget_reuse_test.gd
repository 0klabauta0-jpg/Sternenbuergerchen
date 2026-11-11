extends SceneTree
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT=preload("res://scripts/npc/test_unit.gd")
const UNITS=preload("res://scripts/registries/unit_registry.gd")
class RegionalFixture extends "res://scripts/terrain/terrain_registry.gd":
 func get_tile_count()->int:return 512*256
class CaptureSim extends "res://scripts/core/simulation_root.gd":
 var first_paths:Dictionary={}
 func _build_regional_path_world_points(cmd:Dictionary,unit,registry,from_grid:Vector2i,to_grid:Vector2i,target:Vector2,options:Dictionary)->Array:
  var path:Array=super._build_regional_path_world_points(cmd,unit,registry,from_grid,to_grid,target,options)
  var id:String=String(cmd.unit_id)
  if not path.is_empty() and not first_paths.has(id):first_paths[id]=path.duplicate(true)
  return path
class Oracle24Sim extends CaptureSim:
 func _prepare_regional_navigation_admissions()->void:
  super._prepare_regional_navigation_admissions()
  for id in _regional_navigation_admissions:_regional_navigation_admissions[id]=24
var checks:=0
var failures:=0
var measurements:Array=[]
func _init():call_deferred("run")
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1
 print("PASS: " if ok else "FAIL: ",label)
func command(id:String,target:Vector2)->Dictionary:
 return {"command_type":"move_to_position","unit_id":id,"team_id":"team_alpha","target_position":target,"move_speed_factor":1.0,"priority":12,"command_token":"go:"+id,"requeue_until_target":true,"local_avoidance_enabled":false}
func fixture(count:int,oracle:bool=false,opening:bool=false)->Dictionary:
 var holder:=Node.new();root.add_child(holder)
 var registry:=RegionalFixture.new();registry.name="TerrainRegistry";holder.add_child(registry)
 registry.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
 for q in range(80):
  for y in range(40):
   var grid:=Vector2i(q,y)
   registry.register_tile(TILE.new({"tile_id":str(grid),"grid_position":grid,"world_position":registry.grid_to_world(grid),"walkable":q!=40 or (opening and y==20)}))
 var units=UNITS.new();units.name="UnitRegistry";holder.add_child(units)
 var sim=Oracle24Sim.new() if oracle else CaptureSim.new();sim.name="SimulationRoot";sim.unit_registry_path=NodePath("../UnitRegistry");sim.terrain_registry_path=NodePath("../TerrainRegistry");sim.unit_minimum_spacing_enabled=false;holder.add_child(sim);sim.set_physics_process(false)
 var actors:Array=[];var starts:Array=[]
 for index in range(count):
  var actor=UNIT.new();actor.unit_id="budget_%d"%index;actor.team_id="team_alpha";holder.add_child(actor)
  actor.global_position=registry.grid_to_world(Vector2i(0,2+index*5));units.register_unit(actor.unit_id,actor)
  actors.append(actor);starts.append(actor.global_position)
  sim.enqueue_command(command(actor.unit_id,registry.grid_to_world(Vector2i(79,2+index*5))))
 return {"holder":holder,"registry":registry,"sim":sim,"actors":actors,"starts":starts}
func searches(sim:Node)->Dictionary:
 var found:Dictionary={}
 for queued:Dictionary in sim.command_queue:
  var search:Variant=queued.get("_regional_navigation_search")
  if search!=null:found[queued.unit_id]=search
 return found
func test_shares(count:int)->void:
 var f=fixture(count);var sim=f.sim
 var t:int=Time.get_ticks_usec();sim.call("_physics_process",1.0/60.0);var cpu:int=Time.get_ticks_usec()-t
 var pending:Dictionary=searches(sim);var admitted:int=mini(count,4);var share:int=96/admitted
 var exact:=pending.size()==admitted
 for index in range(admitted):exact=exact and pending.has("budget_%d"%index) and int(pending["budget_%d"%index].expanded_count)==share
 check(exact,"%d jobs use %d expansions for each of %d admitted searches"%[count,share,admitted])
 check(int(sim.get("_regional_navigation_expansions_this_tick"))==96,"%d jobs respect and consume the shared96 cap"%count)
 check(pending.size()<=4,"%d jobs create no search objects outside four admissions"%count)
 var unmoved:=true
 for index in count:unmoved=unmoved and f.actors[index].global_position==f.starts[index]
 check(unmoved,"%d jobs do not move before complete legal routes"%count)
 var max_expansions:int=int(sim.get("_regional_navigation_expansions_this_tick"))
 for tick in range(3):
  sim.call("_physics_process",1.0/60.0);max_expansions=maxi(max_expansions,int(sim.get("_regional_navigation_expansions_this_tick")))
 check(max_expansions<=96,"%d jobs retain global cap across follow-up ticks"%count)
 if count==6:
  pending=searches(sim);var all_progress:=pending.size()==6
  for search in pending.values():all_progress=all_progress and search.expanded_count>0
  check(all_progress,"Six long jobs retain fair rotating progress")
 measurements.append({"jobs":count,"first_tick_cpu_usec":cpu,"admitted":admitted,"per_job_expansions":share,"max_tick_expansions":max_expansions})
 f.holder.free()
func test_query_caps()->void:
 for cap in [0,2]:
  var f=fixture(6);f.sim.navigation_max_new_path_queries_per_tick=cap;f.sim.call("_physics_process",1.0/60.0)
  var pending:Dictionary=searches(f.sim)
  check(pending.size()==cap and int(f.sim.get("_regional_navigation_expansions_this_tick"))==(0 if cap==0 else 96),"Explicit query cap%d remains authoritative without extra search setup"%cap)
  f.holder.free()
func route_run(count:int,oracle:bool)->Dictionary:
 var f=fixture(count,oracle,true);var moved:Dictionary={};var cpu_sum:int=0;var cpu_max:int=0;var max_expansions:=0
 for tick in range(300):
  var t:int=Time.get_ticks_usec();f.sim.call("_physics_process",1.0/60.0);var cpu:int=Time.get_ticks_usec()-t
  cpu_sum+=cpu;cpu_max=maxi(cpu_max,cpu);max_expansions=maxi(max_expansions,int(f.sim.get("_regional_navigation_expansions_this_tick")))
  for index in count:
   if not moved.has(f.actors[index].unit_id) and f.actors[index].global_position.distance_to(f.starts[index])>1.0:moved[f.actors[index].unit_id]=tick+1
  if moved.size()==count:break
 var result:Dictionary={"jobs":count,"oracle24":oracle,"first_paths":f.sim.first_paths.duplicate(true),"first_move_ticks":moved,"cpu_sum_usec":cpu_sum,"cpu_max_tick_usec":cpu_max,"max_tick_expansions":max_expansions}
 f.holder.free();return result
func test_routes(count:int)->void:
 var before=route_run(count,true);var after=route_run(count,false)
 check(before.first_paths.size()==count and after.first_paths.size()==count and before.first_paths==after.first_paths,"%d jobs yield identical full routes to the fixed24-slice oracle"%count)
 check(before.first_move_ticks.size()==count and after.first_move_ticks.size()==count,"%d jobs actually begin physical movement in both schedules"%count)
 var earlier:=true
 for id in after.first_move_ticks:earlier=earlier and int(after.first_move_ticks[id])<int(before.first_move_ticks.get(id,0))
 check(earlier,"%d jobs begin sooner in ticks by using the existing unused budget"%count)
 check(before.max_tick_expansions<=96 and after.max_tick_expansions<=96,"%d jobs route comparison never exceeds96 expansions"%count)
 before.erase("first_paths");after.erase("first_paths");measurements.append({"before":before,"after":after})
func test_outside_tick()->void:
 var f=fixture(1);var actor=f.actors[0];var cmd:Dictionary=f.sim.command_queue[0]
 f.sim.call("_build_regional_path_world_points",cmd,actor,f.registry,Vector2i(0,2),Vector2i(79,2),f.registry.grid_to_world(Vector2i(79,2)),{})
 check(cmd.has("_regional_navigation_search") and cmd._regional_navigation_search.expanded_count==24,"Non-physics caller retains its existing24-expansion slice")
 f.holder.free()
func run()->void:
 for count in [1,2,3,4,6]:test_shares(count)
 test_query_caps();test_routes(1);test_routes(2);test_outside_tick()
 print("REGIONAL_GO_BUDGET_DIAGNOSTIC ",JSON.stringify(measurements))
 var file=FileAccess.open("res://output/native_glut_maps/regional_go_budget_reuse/diagnostic.json",FileAccess.WRITE)
 if file!=null:file.store_string(JSON.stringify(measurements,"  "))
 print("REGIONAL_GO_BUDGET_REUSE %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
