extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"

const BASE_OWNER=preload("res://scripts/core/base_personnel_runtime.gd")
const BASE_ACTOR=preload("res://scripts/core/base_personnel_actor.gd")

class Flow extends Node:
	var _all_team_units:Array=[]
	var _aircraft_location_by_craft:Dictionary={"away_ship":"mission"}
	func _find_pending_mission_craft_transfer(_craft:String)->Dictionary:return {}
	func is_campaign_start()->bool:return false

class Navigation extends RefCounted:
	var searches:=0
	var terrain: Node
	func is_available_world(world:Vector2)->bool:
		# The fixture has no additional ship masks; use actual terrain passability.
		return is_instance_valid(terrain) and world.is_finite() and terrain.is_walkable(terrain.world_to_grid(world))
	func nearest_available_world(world:Vector2)->Vector2:
		if not is_instance_valid(terrain) or not world.is_finite():return world
		return terrain.resolve_walkable_target(world).replacement_position
	func get_ground_clearance_mask() -> Dictionary:
		return {"ok":true,"registry_id":terrain.get_instance_id(),"source_signature":"fixture_clearance","blocked_cells":[]}
	func find_world_path(_from:Vector2,target:Vector2)->Array:
		searches+=1
		return [target]

func _finish()->void:
	var probe=SIM.new()
	_check(probe.has_method("admit_base_ground_people") and probe.has_method("request_base_ground_move"),"real Root exposes dedicated bound base-person admission and movement")
	probe.free()
	if failed==0:
		_test_actual_base_walk()
		_test_base_presence_planning()
		_test_legacy_base_walk()
		_test_unreachable_bed()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_BASE_PERSONNEL_OWNER_PASS")
	quit(0 if failed==0 else 1)

func _base_rig()->Dictionary:
	var rig:Dictionary=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)])
	var flow=Flow.new()
	rig.scene.add_child(flow)
	var base=BASE_OWNER.new()
	rig.scene.add_child(base)
	base._flow=flow
	base._sim=rig.sim
	base._terrain=rig.terrain
	base._registry=rig.units
	base._layout={"beds":[{"id":"bed","grid":[2,0]}]}
	base._navigation_graph=Navigation.new()
	base._navigation_graph.terrain=rig.terrain
	rig.sim.configure_base_personnel(base)
	rig.sim.tick_processed.connect(base._on_tick)
	for id in ["base_person","other"]:
		var actor=BASE_ACTOR.new()
		actor.unit_id=id
		base.add_child(actor)
		rig.units.register_unit(id,actor)
		rig.sim.register_known_unit(id,actor)
		base._states[id]={"unit_id":id,"status":"outside","craft_id":"","bed_id":"","action":{},"last_result":{},"auto_rest_enabled":false}
		rig.actors[id]=actor
	rig.base=base
	return rig

func _test_actual_base_walk()->void:
	var rig:Dictionary=_base_rig()
	var placements:Array[Dictionary]=[{"unit_id":"base_person","grid":Vector2i.ZERO},{"unit_id":"other","grid":Vector2i(0,1)}]
	var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	var foreign=BASE_OWNER.new()
	rig.scene.add_child(foreign)
	_check(not rig.sim.admit_base_ground_people(foreign,placements).ok and rig.sim.get_hex_ground_planning_snapshot()==before,"foreign base owner cannot admit real people")
	var admitted:Dictionary=rig.sim.admit_base_ground_people(rig.base,placements)
	_check(admitted.ok and not rig.actors.base_person.has_method("assign_unit_command") and not rig.sim.get_hex_unit_state("base_person").is_empty(),"actual base projection is admitted without fabricated tactical command capabilities")
	var result:Dictionary=rig.base.request_operation("base_sleep",{"unit_id":"base_person","bed_id":"bed"})
	_check(result.ok and rig.base._states.base_person.status=="moving" and rig.base._beds.get("bed")=="base_person","actual base sleep reserves bed and accepts tokenized Root movement")
	var action:Dictionary=rig.base._states.base_person.action.duplicate(true)
	var rejected:Dictionary=rig.base.request_operation("base_move",{"unit_id":"base_person","target_position":Vector2(INF,0)})
	_check(not rejected.ok and rig.base._states.base_person.action==action and rig.base._beds.get("bed")=="base_person","invalid base move cannot cancel an accepted bed action")
	rig.actors.base_person.position=rig.terrain.grid_to_world(Vector2i(2,0))
	rig.base._on_tick(rig.sim.tick_counter)
	_check(rig.base._states.base_person.status=="moving","fractional or forged render position cannot publish base arrival")
	for i in range(30):rig.sim._physics_process(0.1)
	_check(rig.base._states.base_person.status=="sleeping" and rig.sim.get_hex_unit_state("base_person").grid==Vector2i(2,0),"actual base person reaches bed through shared Ground execution")
	_check(rig.base._navigation_graph.searches==0,"hex base walk never duplicates navigation in the legacy base graph")
	rig.base.request_operation("base_sleep",{"unit_id":"other","bed_id":"bed"})
	var move:Dictionary=rig.base.request_operation("base_move",{"unit_id":"other","target_position":rig.terrain.grid_to_world(Vector2i(1,1))})
	rig.sim._physics_process(0.1)
	rig.sim.stop_hex_ground_units(PackedStringArray(["other"]),"fixture_external_abort")
	rig.base._on_tick(rig.sim.tick_counter)
	_check(move.ok and rig.base._states.other.status=="outside" and rig.base._states.other.action.is_empty(),"actual Base owner clears an externally aborted Ground action")
	var state:Dictionary=rig.base._states.other
	state.status="aboard"
	state.craft_id="away_ship"
	_check(not rig.sim.request_base_ground_move(rig.base,"other",Vector2.ZERO,"remote").ok,"remote aboard base identity cannot command local ground")
	rig.scene.free()

func _test_legacy_base_walk()->void:
	var rig:Dictionary=_base_rig()
	rig.map.set_tactical_grid_rules("")
	rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
	var move:Dictionary=rig.base.request_operation("base_move",{"unit_id":"base_person","target_position":rig.terrain.grid_to_world(Vector2i(1,0))})
	for i in range(16):rig.sim._physics_process(0.1)
	_check(move.ok and rig.base._navigation_graph.searches==1 and rig.base._states.base_person.status=="outside" and rig.actors.base_person.position==rig.terrain.grid_to_world(Vector2i(1,0)),"unflagged base keeps its actual legacy graph and continuous arrival path")
	rig.scene.free()

func _test_unreachable_bed()->void:
	var rig:Dictionary=_base_rig()
	var placements:Array[Dictionary]=[{"unit_id":"base_person","grid":Vector2i.ZERO}]
	rig.sim.admit_base_ground_people(rig.base,placements)
	rig.terrain.register_tile(TILE.new({"tile_id":"disconnected","grid_position":Vector2i(3,2),"explicit_hex_ramps":true}))
	rig.base._layout.beds.append({"id":"disconnected","grid":[3,2]})
	var result:Dictionary=rig.base.request_operation("base_sleep",{"unit_id":"base_person","bed_id":"disconnected"})
	for i in range(24):rig.sim._physics_process(0.1)
	_check(result.ok and rig.base._states.base_person.status=="outside" and rig.base._states.base_person.action.is_empty() and not rig.base._beds.has("disconnected") and rig.sim.get_hex_unit_state("base_person").grid==Vector2i.ZERO,"bounded unreachable base navigation releases its action and bed without moving or sleeping")
	rig.scene.free()

func _test_base_presence_planning()->void:
	var rig:Dictionary=_base_rig()
	var base=rig.base
	rig.actors.base_person.position=Vector2.ZERO
	rig.actors.other.position=Vector2.ZERO
	_check(base.has_method("_sync_hex_ground_presence"),"base owner provides bounded post-restore physical admission")
	if not base.has_method("_sync_hex_ground_presence"):
		rig.scene.free()
		return
	base._sync_hex_ground_presence()
	var a:Dictionary=rig.sim.get_hex_unit_state("base_person")
	var b:Dictionary=rig.sim.get_hex_unit_state("other")
	_check(not a.is_empty() and not b.is_empty() and a.grid!=b.grid,"actual common spawn admits both people to distinct fields")
	rig.scene.free()
	rig=_base_rig()
	base=rig.base
	rig.actors.base_person.position=Vector2.ZERO
	rig.actors.other.position=rig.terrain.grid_to_world(Vector2i(1,0))
	base._states.other.status="aboard"
	base._states.other.craft_id="home_ship"
	base._flow._aircraft_location_by_craft["home_ship"]="homebase"
	base._sync_hex_ground_presence()
	_check(not rig.sim.get_hex_unit_state("base_person").is_empty() and rig.sim.get_hex_unit_state("other").is_empty(),"restored aboard person has no Ground claim even at home pad")
	rig.scene.free()
	var planner=load(ADMISSION_PATH).new()
	_check(planner.has_method("plan_anchored_group"),"shared pure admission preserves unique checkpoint anchors before redistributing collisions")
	if not planner.has_method("plan_anchored_group"):return
	rig=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(0,1)])
	var candidates:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO},{"unit_id":"b","grid":Vector2i.ZERO},{"unit_id":"saved","grid":Vector2i(1,0)}]
	var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	var plan:Dictionary=planner.plan_anchored_group(candidates,rig.terrain,before)
	var positions:Dictionary={}
	for entry in plan.get("placements",[]):positions[entry.unit_id]=entry.grid
	_check(plan.ok and positions.saved==Vector2i(1,0) and positions.b!=positions.saved and rig.sim.get_hex_ground_planning_snapshot()==before,"collision search cannot steal a later person's unique saved anchor or mutate owner")
	var limited:Dictionary=planner.plan_anchored_group(candidates,rig.terrain,before,1)
	_check(not limited.ok and limited.placements.is_empty() and limited.expanded<=1,"anchored group budget fails atomically before partial placements")
	_add_admission_actor(rig,"foreign")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["foreign"]),Vector2i(0,1))
	var protected:Dictionary=planner.plan_anchored_group(candidates,rig.terrain,rig.sim.get_hex_ground_planning_snapshot())
	var clear:bool=protected.ok
	for entry in protected.get("placements",[]):clear=clear and entry.grid!=Vector2i(0,1)
	_check(clear,"temporary group anchor traversal never releases a foreign occupant")
	rig.scene.free()
	rig=_admission_rig([{"grid_position":Vector2i.ZERO,"height_level":0},{"grid_position":Vector2i(1,0),"height_level":1}])
	var pair:Array[Dictionary]=[{"unit_id":"a","grid":Vector2i.ZERO},{"unit_id":"b","grid":Vector2i.ZERO}]
	_check(not planner.plan_anchored_group(pair,rig.terrain,rig.sim.get_hex_ground_planning_snapshot()).ok,"anchored collision redistribution cannot climb an unconnected plateau")
	rig.terrain.get_tile_at_grid(Vector2i.ZERO).ramp_direction=0
	rig.terrain.notify_tile_data_changed([Vector2i.ZERO])
	_check(planner.plan_anchored_group(pair,rig.terrain,rig.sim.get_hex_ground_planning_snapshot()).ok,"anchored collision redistribution follows the explicit bidirectional ramp contract")
	rig.scene.free()
