extends "res://scripts/tests/hex_execution_members_verifier.gd"

const PLAN=preload("res://scripts/command/fireteam_order_plan.gd")
const WAYPOINT=preload("res://scripts/command/fireteam_waypoint.gd")
const AREA=preload("res://scripts/command/area_order.gd")

class AreaResolver extends RefCounted:
	var seen_ids:PackedStringArray=PackedStringArray()
	func resolve_defend_area(area,units:Array,_leader,_terrain)->Dictionary:
		var assignments:Array=[]
		seen_ids.clear()
		for unit in units:
			seen_ids.append(unit.unit_id)
			assignments.append({"unit_id":unit.unit_id,"target_position":unit.global_position})
		return {"assignments":assignments,"center_position":area.center_position}
	func resolve_occupy_area(area,units:Array,leader,terrain)->Dictionary:return resolve_defend_area(area,units,leader,terrain)

class Controller extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var test_units:Array=[]
	var test_units_by_fireteam:Dictionary={}
	var test_terrain
	var test_return_context:Dictionary={}
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _get_fireteam_units(id:String,_hidden:bool=true)->Array:return test_units_by_fireteam.get(id,test_units)
	func _resolve_fireteam_leader_for_behavior(id:String):
		var members:Array=_get_fireteam_units(id)
		return members[0] if not members.is_empty() else null
	func _is_fireteam_runtime_active(_id:String)->bool:return true
	func _get_terrain_registry():return test_terrain
	func _resolve_fireteam_behavior_profile(_id:String,_type:String,_target=null):return null
	func _set_active_behavior_profile(_id:String,_profile)->void:pass
	func _record_recent_movement_trace(_id:String,_state:Dictionary,_reason:String)->void:pass
	func _mirror_flow_driver_order_for_fireteam(_id:String,_target:Vector2,_type:String,_phase:int)->void:pass
	func _campaign_return_context()->Dictionary:return test_return_context.duplicate()
	func _get_live_order_phase_index()->int:return 0
	func _get_selection_anchor_for_fireteam(_id:String)->Node2D:return test_units.back() if not test_units.is_empty() else null
	func _get_target_position()->Vector2:return Vector2.ZERO
	func _resolve_fireteam_visual_anchor_position(_id:String)->Variant:return test_units.back().global_position
	func _build_fireteam_engage_contact_halt_context(_id:String)->Dictionary:return {}
	func get_mission_interaction_use_feedback_snapshot()->Dictionary:return {}
	func _resolve_mission_interaction_feedback_for_intent(_snapshot:Dictionary,_id:String)->Dictionary:return {"status":"usable","can_prompt_use":true}
	func record_tactical_breakout(_trigger:String,_id:String="",_context:Dictionary={},_options:Dictionary={})->Dictionary:return {}
	func _find_friendly_unit_by_id(id:String):
		for actor in test_units:
			if actor.unit_id==id:return actor
		return null
	func _refresh_order_visuals()->void:pass
	func _update_ui(_refresh_commands:bool=true,_refresh_runtime:bool=true)->void:pass
	func _emit_planning_state_changed()->void:pass
	func refresh_fireteam_security_state(_refresh_visuals:bool=true)->bool:return false
	func _get_fireteam_behavior_stance_modifiers(_type:String,_id:String="")->Dictionary:return {}
	func _apply_explicit_fire_rule_to_unit_command(_command,_id:String)->void:pass

func _run()->void:
	_test_members()
	_test_bounding_retirement()
	_test_bounding_retirement("caterpillar")
	_test_bounding_retirement("bounding",true)
	_test_scope_lifetimes()
	_test_controller_members()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_EXECUTION_CONTROLLER_PASS")
	quit(0 if failed==0 else 1)

func _test_controller_members()->void:
	var cells:Array=[]
	for x in range(6):
		for y in range(2):cells.append(Vector2i(x,y))
	var rig:Dictionary=_admission_rig(cells)
	rig.sim.name="SimulationRoot"
	var runtime_index=Controller.MISSION_RUNTIME_INDEX_SCRIPT.new()
	runtime_index.name="MissionRuntimeIndex"
	rig.scene.add_child(runtime_index)
	var hud_model=Controller.MISSION_HUD_READ_MODEL_SCRIPT.new()
	hud_model.name="MissionHudReadModel"
	rig.scene.add_child(hud_model)
	var a=_add_admission_actor(rig,"a")
	var b=_add_admission_actor(rig,"b")
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a","b"]),Vector2i.ZERO)
	var controller=Controller.new()
	controller.test_units=[a,b]
	controller.test_terrain=rig.terrain
	rig.scene.add_child(controller)
	var plan=PLAN.new({"plan_id":"plan_ft1_p0","fireteam_id":"ft1","phase":0})
	plan.waypoints=[WAYPOINT.new({"waypoint_id":"wp_1","command_type":"move","target_position":rig.terrain.grid_to_world(Vector2i(3,0))}),WAYPOINT.new({"waypoint_id":"wp_2","command_type":"move","target_position":rig.terrain.grid_to_world(Vector2i(5,0))})]
	_check(controller._activate_next_waypoint_for_plan(plan,"ft1",0),"actual Controller starts first planned waypoint")
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["a"]))
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),Vector2i.ZERO)
	rig.sim.command_queue.clear()
	_check(controller._complete_waypoint_and_activate_next("ft1",plan,0) and not _queued(rig.sim,"a") and _queued(rig.sim,"b"),"actual automatic next waypoint inherits the original member lifetime")
	controller._clear_fireteam_runtime_execution_for_post_drop("ft1")
	_check(not controller._fireteam_movement_controller.has_active_execution("ft1"),"actual full execution clear also resets FMC")
	var resolver=AreaResolver.new()
	controller._area_order_resolver=resolver
	var area=AREA.new({"area_order_id":"area_1","fireteam_id":"ft1","command_type":"defend","center_position":a.global_position})
	controller._area_orders_by_id["area_1"]=area
	_check(controller._start_defend_area_order("ft1",area,0),"actual area execution starts from known resolver assignments")
	var old_assignment:Dictionary=controller._area_defense_execution_by_fireteam.ft1.assignments[0]
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["a"]))
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),Vector2i.ZERO)
	rig.sim.command_queue.clear()
	controller._update_area_defense_execution(0.1)
	var area_state:Dictionary=controller._area_defense_execution_by_fireteam.get("ft1",{})
	_check(not _queued(rig.sim,"a") and _queued(rig.sim,"b") and area_state.get("assignments",[]).size()==1,"actual area completion retires stale assignment while retaining the buddy's hold")
	_check(not controller._issue_area_defense_unit_command("ft1",old_assignment,0,true,"area_1"),"old cached area assignment cannot command a readmitted actor")
	controller._build_attack_area_occupation_assignments("ft1",area_state)
	_check(resolver.seen_ids==PackedStringArray(["b"]),"occupation resolver receives only surviving execution members")
	var public_area:Array=controller.get_active_area_defense_snapshot()
	_check(public_area.size()==1 and not public_area[0].has("hex_execution_scope"),"public area snapshot omits local instance and WeakRef bindings")
	var b_grid:Vector2i=rig.sim.get_hex_unit_state("b").grid
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["b"]))
	_check(rig.sim.admit_hex_ground_actor_group(PackedStringArray(["b"]),b_grid).ok,"terminal-scope fixture readmits the buddy on a free anchor")
	var empty_scope:Dictionary=area_state.hex_execution_scope
	rig.sim.command_queue.clear()
	var terminal_plan=PLAN.new({"plan_id":"plan_ft1_p0","fireteam_id":"ft1","phase":0})
	terminal_plan.waypoints=[WAYPOINT.new({"waypoint_id":"wp_3","command_type":"move","target_position":rig.terrain.grid_to_world(Vector2i(5,0))})]
	_check(not controller._activate_next_waypoint_for_plan(terminal_plan,"ft1",0,empty_scope) and rig.sim.command_queue.is_empty(),"inherited scope with no living member is terminal instead of recapturing roster")
	var fresh:bool=controller._activate_next_waypoint_for_plan(terminal_plan,"ft1",0)
	_check(fresh and _queued(rig.sim,"a") and _queued(rig.sim,"b"),"new explicit Controller order can capture both renewed presences")
	controller._order_plans_by_key[controller._build_order_plan_key("ft1",0)]=terminal_plan
	controller._interrupt_plan_for_suppression("ft1")
	var a_grid:Vector2i=rig.sim.get_hex_unit_state("a").grid
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["a"]))
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),a_grid)
	rig.sim.command_queue.clear()
	controller._try_auto_resume_after_suppression("ft1")
	_check(not _queued(rig.sim,"a") and _queued(rig.sim,"b"),"actual automatic suppression return retains the interrupted execution scope")
	controller._interrupt_active_plan_for_ad_hoc("ft1")
	rig.sim.command_queue.clear()
	_check(controller._start_ad_hoc_order_for_fireteam("ft1","flank",rig.terrain.grid_to_world(Vector2i(3,0))) and _queued(rig.sim,"a") and _queued(rig.sim,"b"),"new explicit AdHoc order may admit the current roster")
	_check(not Dictionary(controller._ad_hoc_order_controller.get_resume_state("ft1")).has("hex_execution_scope"),"portable AdHoc resume data excludes local receiver bindings")
	rig.sim.command_queue.clear()
	controller._return_fireteam_to_plan("ft1",false)
	_check(not _queued(rig.sim,"a") and _queued(rig.sim,"b"),"automatic AdHoc return restores the original restricted plan scope")
	var use_state:Dictionary=controller._phase_execution_by_fireteam.ft1
	var use_waypoint=WAYPOINT.new({"waypoint_id":"use_1","command_type":"take","target_position":b.global_position,"metadata":{"source":"mission_interaction_use_intent","interaction_type":"computer","interaction_id":"computer"}})
	use_state.merge({"interaction_waypoint_id":"use_1","interaction_id":"computer","resolved_target_position":b.global_position,"interaction_hold_radius":128.0,"interaction_marker_position":b.global_position},true)
	rig.sim.command_queue.clear()
	_check(controller._try_start_stationary_interaction("ft1",use_waypoint,0,use_state) and not _queued(rig.sim,"a") and _queued(rig.sim,"b"),"actual stationary computer hold inherits its execution members")
	controller._active_coordination_by_id["coord_1"]={"advance_fireteam_id":"ft2","cover_fireteam_id":"ft1","phase":0}
	controller._clear_fireteam_runtime_execution_for_post_drop("ft1")
	rig.sim.command_queue.clear()
	controller._notify_fireteam_ready_for_coordination("ft2")
	_check(controller._active_coordination_by_id.is_empty() and rig.sim.command_queue.is_empty(),"terminal cover execution is removed from coordination before any later rotation")
	var c=_add_admission_actor(rig,"c")
	var d=_add_admission_actor(rig,"d")
	_check(rig.sim.admit_hex_ground_actor_group(PackedStringArray(["c","d"]),Vector2i(2,0)).ok,"remaining coordination partner has its own admitted actors")
	controller.test_units_by_fireteam["ft2"]=[c,d]
	var partner_plan=PLAN.new({"plan_id":"plan_ft2_p0","fireteam_id":"ft2","phase":0})
	partner_plan.waypoints=[WAYPOINT.new({"waypoint_id":"partner_1","command_type":"move","target_position":rig.terrain.grid_to_world(Vector2i(5,0))})]
	controller._order_plans_by_key[controller._build_order_plan_key("ft2",0)]=partner_plan
	controller._activate_next_waypoint_for_plan(partner_plan,"ft2",0)
	controller._phase_execution_by_fireteam.ft2["hex_coordination_cover"]=true
	controller._fireteam_movement_controller.reset_fireteam("ft2")
	controller._active_coordination_by_id["coord_2"]={"advance_fireteam_id":"ft1","cover_fireteam_id":"ft2","phase":0}
	controller._clear_fireteam_runtime_execution_for_post_drop("ft1")
	rig.sim.command_queue.clear()
	controller._update_active_phase_execution(0.1)
	_check(_queued(rig.sim,"c") and _queued(rig.sim,"d") and not _queued(rig.sim,"a") and not _queued(rig.sim,"b"),"retiring one coordinated team resumes its surviving partner's existing goal")
	var return_state:Dictionary={"phase":0}
	var return_waypoint=WAYPOINT.new({"waypoint_id":"return_1","command_type":"move","target_position":Vector2(256,128),"metadata":{"interaction_id":"ship_return"}})
	controller.test_return_context={"craft_id":"craft","crew":[a,b],"position":Vector2(256,128)}
	_check(controller._start_campaign_return_gather(return_waypoint,return_state),"actual craft-return producer binds its original cross-team crew")
	a_grid=rig.sim.get_hex_unit_state("a").grid
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["a"]))
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),a_grid)
	rig.sim.command_queue.clear()
	_check(controller._start_campaign_return_gather(return_waypoint,return_state) and not _queued(rig.sim,"a") and _queued(rig.sim,"b"),"actual craft-return reissue cannot recapture renewed crew")
	controller.test_units_by_fireteam["ft1"]=[b]
	var return_plan=PLAN.new({"plan_id":"plan_ft1_p0","fireteam_id":"ft1","phase":0})
	return_plan.waypoints=[return_waypoint]
	controller._order_plans_by_key[controller._build_order_plan_key("ft1",0)]=return_plan
	rig.sim.command_queue.clear()
	_check(controller._activate_next_waypoint_for_plan(return_plan,"ft1",0) and _queued(rig.sim,"a") and _queued(rig.sim,"b"),"new return waypoint can bind actual crew beyond its executing fireteam")
	controller._interrupt_plan_for_suppression("ft1")
	a_grid=rig.sim.get_hex_unit_state("a").grid
	rig.sim.embark_hex_ground_actor_group(PackedStringArray(["a"]))
	rig.sim.admit_hex_ground_actor_group(PackedStringArray(["a"]),a_grid)
	rig.sim.command_queue.clear()
	controller._try_auto_resume_after_suppression("ft1")
	_check(not _queued(rig.sim,"a") and _queued(rig.sim,"b"),"actual suppression return also preserves the original cross-team craft crew binding")
	rig.scene.free()
