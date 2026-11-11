extends SceneTree

const SIM = preload("res://scripts/core/simulation_root.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const FIRE = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const FOW = preload("res://scripts/core/fog_of_war_system.gd")
const ADAPTER_PATH := "res://scripts/core/hex_sight_runtime_adapter.gd"
var passed := 0
var failed := 0

class Actor extends Node2D:
	var id := ""
	var team := ""
	func get_unit_id() -> String: return id
	func get_team_id() -> String: return team
	func get_vital_state() -> String: return "fit"
	func get_awareness() -> float: return 0.5

class Driver extends DRIVER:
	var units: Dictionary = {}
	func _ready() -> void: pass
	func _resolve_unit_by_id(id: String): return units.get(id)

func _init() -> void: call_deferred("_run")
func _check(value: bool,label: String) -> void:
	if value:
		passed+=1
		print("PASS: ",label)
	else:
		failed+=1
		print("FAIL: ",label)

func _range(_a,_b) -> float: return 1000.0

func _run() -> void:
	_check(ResourceLoader.exists(ADAPTER_PATH),"shared logical sight adapter exists")
	if failed>0:
		_finish()
		return
	var sim=SIM.new()
	sim.name="Simulation"
	sim.set_physics_process(false)
	root.add_child(sim)
	sim.set_physics_process(false)
	var terrain=REGISTRY.new()
	terrain.name="Terrain"
	root.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
	for x in range(-1,3):
		var grid:=Vector2i(x,0)
		terrain.register_tile(TILE.new({"tile_id":"tile_%d"%x,"grid_position":grid,
			"world_position":terrain.grid_to_world(grid),"walkable":true}))
	var map=MAP.create_empty("consumer_fixture",Vector2i(4,1),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	_check(sim.configure_hex_ground_runtime(map,terrain).ok,"real owner configured")
	var batch:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO,"facing_dir":0},
		{"unit_id":"b","grid":Vector2i(1,0),"facing_dir":3},
		{"unit_id":"c","grid":Vector2i(-1,0),"facing_dir":0}]
	_check(sim.admit_hex_ground_units(batch).ok,"exclusive actors admitted")
	var cache=CACHE.new()
	cache.name="Cache"
	root.add_child(cache)
	var driver=Driver.new()
	driver.name="Driver"
	driver.simulation_root_path=NodePath("../Simulation")
	driver.terrain_registry_path=NodePath("../Terrain")
	driver.combat_visibility_cache_path=NodePath("../Cache")
	root.add_child(driver)
	var actors:Array=[]
	for id in ["a","b","c","unknown"]:
		var actor:=Actor.new()
		actor.id=id
		actor.team="alpha" if id=="a" else "bravo"
		actor.position=Vector2(9999,9999) # Render transforms deliberately disagree.
		root.add_child(actor)
		actors.append(actor)
		driver.units[id]=actor
	var adapter=driver.get_hex_sight_adapter()
	_check(adapter.is_active(),"driver shares active adapter")
	_check(driver._has_valid_los(actors[0],actors[1]),"contact sight reads logical cells instead of render positions")
	_check(not driver._has_valid_los(actors[0],actors[2]),"contact sight rejects rear arc")
	_check(not driver._has_valid_los(actors[0],actors[3]),"missing admission cannot fall back to render sight")
	var count:int=cache.get_hex_cache_audit_snapshot().geometry_queries
	var context:Dictionary=driver._build_fire_decision_context({"get_weapon_attack_range":Callable(self,"_range")})
	_check(FIRE.is_target_attackable(actors[0],actors[1],context),"shot reader shares current logical sight")
	_check(not FIRE.is_target_attackable(actors[0],actors[2],context),"shot reader rejects rear target")
	_check(cache.get_hex_cache_audit_snapshot().geometry_queries==count,"contact and shot share one terrain query")
	var fog=FOW.new()
	fog.set_mode_for_team("alpha","explored")
	fog.update_tile_visibility_for_team("alpha",[actors[0]],terrain,cache,1000.0,{"hex_sight_adapter":adapter})
	_check(fog.is_tile_currently_visible("alpha","tile_1") and not fog.is_tile_currently_visible("alpha","tile_-1"),"FoW shares the directed hex cone")
	var after_fog:int=cache.get_hex_cache_audit_snapshot().geometry_queries
	actors[0].position=Vector2(-999,-999)
	var update:Dictionary=fog.request_tile_visibility_update_for_team("alpha",[actors[0]],terrain,cache,1000.0,{"hex_sight_adapter":adapter})
	_check(bool(update.get("completed",false)) and cache.get_hex_cache_audit_snapshot().geometry_queries==after_fog,"render movement does not rebuild logical FoW")
	var full_signature:String=adapter.build_observer_signature(actors[0],1000.0,true)
	var static_signature:String=adapter.build_observer_signature(actors[0],1000.0,false)
	driver.hex_sight_arc_degrees=360.0
	adapter=driver.get_hex_sight_adapter()
	_check(adapter.build_observer_signature(actors[0],1000.0,true)!=full_signature and adapter.build_observer_signature(actors[0],1000.0,false)!=static_signature,"both setup signatures include the effective sight profile")
	fog.update_tile_visibility_for_team("alpha",[actors[0]],terrain,cache,1000.0,{"hex_sight_adapter":adapter})
	_check(fog.is_tile_currently_visible("alpha","tile_-1"),"changed arc profile updates terrain visibility too")
	driver.hex_sight_arc_degrees=120.0
	adapter=driver.get_hex_sight_adapter()
	fog.update_tile_visibility_for_team("alpha",[actors[0]],terrain,cache,1000.0,{"hex_sight_adapter":adapter})
	var replacement=REGISTRY.new()
	replacement.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
	for x in range(-1,3):
		var grid:=Vector2i(x,0)
		replacement.register_tile(TILE.new({"tile_id":"tile_%d"%x,"grid_position":grid,
			"world_position":replacement.grid_to_world(grid),"walkable":true,
			"blocks_los":x==1,"height_level":4 if x==1 else 0}))
	_check(replacement.get_revision()==terrain.get_revision(),"replacement fixture has equal numeric revision")
	sim.configure_hex_ground_runtime(map,replacement)
	sim.admit_hex_ground_units(batch)
	var replacement_work:Dictionary=fog.request_tile_visibility_update_for_team("alpha",[actors[0]],replacement,cache,1000.0,{"hex_sight_adapter":adapter})
	_check(not bool(replacement_work.get("completed",false)),"new registry identity invalidates otherwise identical FoW inputs")
	_check(adapter.build_observer_signature(actors[0],1000.0,true)!=full_signature and adapter.build_observer_signature(actors[0],1000.0,false)!=static_signature,"both setup signatures include owner and registry context")
	fog.process_pending_tile_visibility_work("alpha",128)
	_check(not fog.is_tile_currently_visible("alpha","tile_2"),"replacement terrain blocker cannot reuse previous map sight")
	sim.configure_hex_ground_runtime(map,terrain)
	sim.admit_hex_ground_units(batch)
	# A new facing is supplied through the authoritative context, never a transform.
	batch[0].facing_dir=3
	sim.configure_hex_ground_runtime(map,terrain)
	sim.admit_hex_ground_units(batch)
	fog.request_tile_visibility_update_for_team("alpha",[actors[0]],terrain,cache,1000.0,{"hex_sight_adapter":adapter})
	fog.process_pending_tile_visibility_work("alpha",1)
	_check(fog.is_tile_currently_visible("alpha","tile_1") and not fog.is_tile_currently_visible("alpha","tile_-1"),"partial FoW work retains previous atomic publication")
	var done:=false
	for _step in range(30):
		if bool(fog.process_pending_tile_visibility_work("alpha",128).get("completed",false)):
			done=true
			break
	_check(done and not fog.is_tile_currently_visible("alpha","tile_1") and fog.is_tile_currently_visible("alpha","tile_-1"),"logical facing invalidates FoW and publishes the new cone")
	var hides_forward:=false
	for changed in fog.build_team_state_snapshot("alpha").get("visibility_delta",{}).get("changed_tiles",[]):
		if String(changed.get("tile_id",""))=="tile_1" and not bool(changed.get("visible",true)):
			hides_forward=true
	_check(hides_forward,"context-change delta hides previously published forward tiles")
	batch[0].facing_dir=0
	sim.configure_hex_ground_runtime(map,terrain)
	sim.admit_hex_ground_units(batch)
	driver._current_tick=10
	driver._start_or_continue_detection(actors[0],"a","b")
	var progress:Dictionary=driver.get_detection_progress()
	_check(progress.size()==1,"driver starts one detection episode")
	driver._start_or_continue_detection(actors[0],"a","b")
	_check(driver.get_detection_progress()==progress,"repeat detection does not reroll or double count")
	driver._current_tick=11
	driver._advance_detection_timers()
	_check(int(driver.get_detection_progress().values()[0])==int(progress.values()[0])-1,"deadline advances at existing simulation cadence")
	sim.configure_hex_ground_runtime(map,terrain)
	sim.admit_hex_ground_units(batch)
	_check(driver.get_detection_progress().is_empty(),"new authoritative context clears prior detection episodes")
	driver._start_or_continue_detection(actors[0],"a","b")
	terrain.get_tile_at_grid(Vector2i(1,0)).blocks_los=true
	terrain.get_tile_at_grid(Vector2i(1,0)).height_level=4
	terrain.notify_tile_data_changed([Vector2i(1,0)])
	# Put a blocker BETWEEN observer and a second logical target.
	sim.release_hex_ground_unit("b","fixture")
	var far:Array[Dictionary]=[{"unit_id":"b","grid":Vector2i(2,0),"facing_dir":3}]
	_check(sim.admit_hex_ground_units(far).ok,"fixture moves target through owner admission")
	driver._current_tick=12
	driver._advance_detection_timers()
	_check(driver.get_detection_progress().is_empty() and not driver._is_detection_complete("a","b"),"real sight loss clears episode without confirming contact")
	map.set_tactical_grid_rules("")
	_check(sim.configure_hex_ground_runtime(map,terrain).ok,"fixture can return to legacy")
	driver.combat_visibility_cache_path=NodePath()
	_check(not driver.get_hex_sight_adapter().query_units(actors[0],actors[1],1000.0).handled,"legacy accepts the RefCounted LOS fallback without activating hex sight")
	driver._detection_progress={"a:b":2}
	_check(driver.get_detection_progress()=={"a:b":2},"legacy countdown projection remains compatible")
	for actor in actors: actor.free()
	driver.free()
	cache.free()
	terrain.free()
	replacement.free()
	sim.free()
	_finish()

func _finish() -> void:
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0: print("HEX_SIGHT_CONSUMERS_PASS")
	quit(0 if failed==0 else 1)
