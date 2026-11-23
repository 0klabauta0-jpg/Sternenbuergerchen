extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"
## Small scene/feedback fixtures; actual Controller, Root commands, actor identities,
## interpolation, admission, Hold completion and receipt validation are exercised.
const GUARD=preload("res://scripts/tests/review2_isolated_user_guard.gd")
const ACTOR=preload("res://scripts/npc/test_unit.gd")
const WAYPOINT=preload("res://scripts/command/fireteam_waypoint.gd")
const HUD=preload("res://scripts/tactical/mission_hud_read_model.gd")
const INDEX=preload("res://scripts/tactical/mission_runtime_index.gd")
class SpacingMovement extends "res://scripts/tactical/fireteam_movement_controller.gd":
	var forced_target:Vector2
	func _resolve_spacing_safe_stage_target(state:Dictionary,unit_id:String,desired_target:Vector2,accepted_targets:Dictionary,terrain_registry)->Dictionary:
		if unit_id=="approach_a":return {"target_position":forced_target}
		return super._resolve_spacing_safe_stage_target(state,unit_id,desired_target,accepted_targets,terrain_registry)
class QuietController extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var contact_fixture:Dictionary={}
	var feedback_status:="usable"
	var return_fixture:Dictionary={}
	func _campaign_return_context()->Dictionary:return return_fixture if not return_fixture.is_empty() else super._campaign_return_context()
	func _ready()->void: set_process(false);set_physics_process(false)
	func get_mission_interaction_use_feedback_snapshot()->Dictionary:
		return {"feedback_entries":[{"interaction_id":"computer","status":feedback_status,"can_prompt_use":feedback_status=="usable"}]}
	func _build_fireteam_engage_contact_halt_context(_id:String)->Dictionary:return contact_fixture

func _run()->void:
	if not GUARD.require_isolated_user_data():return
	_test_partial_return_gather()
	_test_occupied_access()
	_test_boundary(false)
	_test_boundary(true)
	await _test_local_waypoint_types()
	await process_frame
	print("REVIEW_HEX_USE passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)

func _test_boundary(reverse:bool)->void:
	var rig:=_admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0)])
	rig.sim.name="SimulationRoot";rig.units.name="UnitRegistry";rig.terrain.name="TerrainRegistry"
	rig.sim.unit_registry_path=rig.sim.get_path_to(rig.units);rig.sim.terrain_registry_path=rig.sim.get_path_to(rig.terrain)
	rig.sim.set_physics_process(false)
	var index:=INDEX.new();index.name="MissionRuntimeIndex";rig.scene.add_child(index)
	var hud:=HUD.new();hud.name="MissionHudReadModel";rig.scene.add_child(hud)
	var controller:=QuietController.new();rig.scene.add_child(controller)
	var actor:=ACTOR.new();actor.unit_id="member";actor.team_id="team_alpha";actor.fireteam_id="ft1";actor.is_fireteam_lead=true
	actor.weapon_1_id="none";actor.weapon_2_id="none";rig.scene.add_child(actor);actor.set_physics_process(false)
	rig.units.register_unit("member",actor);rig.sim.register_known_unit("member",actor)
	var origin:=Vector2i(4,0) if reverse else Vector2i.ZERO
	var destination:=Vector2i.ZERO if reverse else Vector2i(4,0)
	_check(rig.sim.admit_hex_ground_actor_group(PackedStringArray(["member"]),origin).ok,"actual actor admitted for boundary direction %s" % reverse)
	var origin_world:Vector2=rig.terrain.grid_to_world(origin)
	var destination_world:Vector2=rig.terrain.grid_to_world(destination)
	var marker:=origin_world+(destination_world-origin_world).normalized()*100.0
	var waypoint:=WAYPOINT.new();waypoint.waypoint_id="use-boundary";waypoint.target_position=marker;waypoint.command_type="take";waypoint.hold_duration_seconds=3.0
	waypoint.metadata={"source":"mission_interaction_use_intent","interaction_type":"computer","interaction_id":"computer"}
	var state:Dictionary={"hex_execution_scope":controller._new_hex_execution_scope("ft1"),"resolved_target_position":marker,"interaction_marker_position":marker,"interaction_waypoint_id":waypoint.waypoint_id,"interaction_id":"computer","interaction_hold_radius":96.0,"hold_elapsed":0.0}
	controller._phase_execution_by_fireteam["ft1"]=state
	var command:=_command("member",destination_world);command.team_id="team_alpha"
	rig.sim.enqueue_command(command)
	var boundary:=false
	for tick in range(50):
		rig.sim._physics_process(0.025)
		if actor.global_position.distance_to(marker)<96.0 and Vector2(rig.sim.get_hex_logical_unit_position("member")).distance_to(marker)>96.0:
			boundary=true;break
	_check(boundary,"real interpolated pose enters radius before canonical cell direction %s" % reverse)
	var queued:int=rig.sim.command_queue.size()
	_check(not controller._try_start_stationary_interaction("ft1",waypoint,0,state) and not state.has("interaction_arrival_receipt") and rig.sim.command_queue.size()==queued,"boundary pose cannot stop outside cell or publish arrival")
	for tick in range(100):
		rig.sim._physics_process(0.025)
		if controller._hex_interaction_stop_state("ft1",state).in_radius:break
	_check(controller._try_start_stationary_interaction("ft1",waypoint,0,state) and state.get("interaction_stop_pending",false) and not state.has("interaction_arrival_receipt"),"in-radius ownership requests actual Hold but no early receipt")
	_check(controller._try_start_stationary_interaction("ft1",waypoint,0,state) and not state.has("interaction_arrival_receipt") and state.hold_elapsed==0.0,"same-frame repeated Use waits for Root command commit")
	controller.feedback_status="out_of_range"
	for tick in range(100):
		rig.sim._physics_process(0.025)
		controller._try_start_stationary_interaction("ft1",waypoint,0,state)
		if state.has("interaction_arrival_receipt"):break
	_check(state.has("interaction_arrival_receipt") and controller._hex_interaction_stop_state("ft1",state).ready and actor.global_position.distance_to(marker)<=96.0,"actual Hold recenter completes inside unchanged radius before receipt")
	_check(controller._is_interaction_arrival_receipt_valid("ft1",marker,state) and state.hold_elapsed==0.0,"confirmed receipt starts with zero elapsed hold")
	var newcomer:=ACTOR.new();newcomer.unit_id="newcomer";newcomer.team_id="team_alpha";newcomer.fireteam_id="ft1";newcomer.weapon_1_id="none";newcomer.weapon_2_id="none"
	rig.scene.add_child(newcomer);rig.units.register_unit("newcomer",newcomer);rig.sim.register_known_unit("newcomer",newcomer)
	newcomer.global_position=marker+Vector2(1000,1000)
	_check(controller._get_fireteam_units("ft1",true).size()==2 and controller._is_interaction_arrival_receipt_valid("ft1",marker,state),"later same-team actor outside original execution scope cannot invalidate its receipt")
	rig.units.unregister_unit("newcomer");rig.sim.unregister_known_unit("newcomer");newcomer.free()
	var changed:=state.duplicate(true);changed.interaction_waypoint_id="replacement"
	_check(not controller._is_interaction_arrival_receipt_valid("ft1",marker,changed),"replacement waypoint cannot inherit confirmed receipt")
	controller.contact_fixture={"target_unit_id":"enemy"}
	_check(not controller._is_interaction_arrival_receipt_valid("ft1",marker,state),"contact interrupts genuine stationary receipt")
	controller.contact_fixture.clear()
	var replacement:=_command("member",destination_world);replacement.team_id="team_alpha";replacement.command_token="replacement-command";replacement.priority=15
	rig.sim.enqueue_command(replacement);rig.sim._physics_process(0.025)
	_check(not controller._is_interaction_arrival_receipt_valid("ft1",marker,state),"actual replacement Root command invalidates prior Use receipt")
	rig.scene.free()

func _test_local_waypoint_types()->void:
	for kind in ["door","hold_zone","computer"]:
		var cells:Array=[]
		for x in range(7):
			for y in range(3):cells.append(Vector2i(x,y))
		var rig:=_admission_rig(cells)
		rig.sim.name="SimulationRoot";rig.units.name="UnitRegistry";rig.terrain.name="TerrainRegistry"
		rig.sim.unit_registry_path=rig.sim.get_path_to(rig.units);rig.sim.terrain_registry_path=rig.sim.get_path_to(rig.terrain);rig.sim.set_physics_process(false)
		var index:=INDEX.new();index.name="MissionRuntimeIndex";rig.scene.add_child(index)
		var hud:=HUD.new();hud.name="MissionHudReadModel";rig.scene.add_child(hud)
		var controller:=QuietController.new();rig.scene.add_child(controller)
		var actor:=ACTOR.new();actor.unit_id="member";actor.team_id="team_alpha";actor.fireteam_id="ft1";actor.is_fireteam_lead=true
		actor.weapon_1_id="none";actor.weapon_2_id="none";rig.scene.add_child(actor);actor.set_physics_process(false)
		rig.units.register_unit("member",actor);rig.sim.register_known_unit("member",actor)
		rig.sim.admit_hex_ground_actor_group(PackedStringArray(["member"]),Vector2i(0,1))
		controller._deployed_unit_ids["member"]=true
		var waypoint:=WAYPOINT.new();waypoint.waypoint_id="local-"+kind;waypoint.target_position=rig.terrain.grid_to_world(Vector2i(3,1));waypoint.command_type="defend" if kind=="hold_zone" else "take";waypoint.hold_duration_seconds=3.0
		waypoint.metadata={"source":"mission_interaction_use_intent","interaction_type":kind,"interaction_id":"computer","interaction_radius_world":96.0}
		var plan=controller._get_or_create_order_plan("ft1",0);plan.waypoints.append(waypoint)
		_check(controller._activate_next_waypoint_for_plan(plan,"ft1",0),"actual local %s waypoint starts its movement owner" % kind)
		if kind=="computer":
			var resume:Dictionary=controller._phase_execution_by_fireteam["ft1"]
			resume["hex_coordination_resume"]=true;resume["interaction_stop_pending"]=true;resume["hold_elapsed"]=2.0
			controller._on_simulation_tick_for_orders(int(rig.sim.tick_counter),0.1)
			var resumed:Dictionary=controller._phase_execution_by_fireteam["ft1"]
			_check(not resumed.has("interaction_stop_pending") and not resumed.has("interaction_arrival_receipt") and resumed.hold_elapsed==0.0,"explicit coordination resume invalidates the superseded pending stop and timer")
		var first_hold_tick:=-1
		var finished_tick:=-1
		var receipt_seen:=false
		var actual_stage_checked:=false
		var premature_stage:=false
		var stage_count:=0
		var movement=controller._fireteam_movement_controller
		var records:Array=movement._build_member_records([actor],actor)
		var first_stage:Dictionary=movement._execution_by_fireteam.get("ft1",{})
		_check(not first_stage.is_empty() and not movement._are_current_targets_reached(first_stage,records,rig.sim),"%s stage waits for actual Root command admission" % kind)
		for tick in range(600):
			await physics_frame
			rig.sim._physics_process(0.1)
			var stage:Dictionary=movement._execution_by_fireteam.get("ft1",{})
			if not stage.is_empty():
				stage_count=maxi(stage_count,int(stage.get("stage_index",0)))
				var reached:bool=movement._are_current_targets_reached(stage,records,rig.sim)
				var ground:Dictionary=rig.sim.get_hex_unit_state("member")
				premature_stage=premature_stage or (reached and (ground.movement_state.moving or ground.route_state.has_commitments))
				if reached and not actual_stage_checked:
					actual_stage_checked=true
					var wrong_target:=stage.duplicate(true);wrong_target.current_target_positions["member"]=Vector2(wrong_target.current_target_positions["member"])+Vector2(640,320)
					_check(not movement._are_current_targets_reached(wrong_target,records,rig.sim),"%s actual Root arrival rejects a different target" % kind)
					var wrong_token:=stage.duplicate(true);wrong_token.command_revision=int(stage.command_revision)+1
					_check(not movement._are_current_targets_reached(wrong_token,records,rig.sim),"%s actual Root arrival rejects a different stage token" % kind)
			controller._on_simulation_tick_for_orders(int(rig.sim.tick_counter))
			var execution:Dictionary=controller._phase_execution_by_fireteam.get("ft1",{})
			receipt_seen=receipt_seen or execution.has("interaction_arrival_receipt")
			if first_hold_tick<0 and float(execution.get("hold_elapsed",0.0))>0.0:first_hold_tick=tick
			if plan.waypoints.is_empty():finished_tick=tick;break
		if finished_tick<0:
			print("LOCAL_USE_DIAGNOSTIC ",kind," ", {"execution":controller._phase_execution_by_fireteam,"movement":controller.get_fireteam_movement_snapshot(),"ground":rig.sim.get_hex_unit_state("member"),"command":actor.get_current_unit_command().to_dict(),"position":actor.global_position})
		_check(receipt_seen and finished_tick>=0,"local %s completes through real arrival receipt and phase updater" % kind)
		_check(first_hold_tick>=0 and finished_tick-first_hold_tick>=28,"local %s retains full authored three-second hold" % kind)
		_check(not premature_stage,"%s never advances a stage while Root has movement commitments" % kind)
		if kind=="door":
			_check(actual_stage_checked and stage_count>0,"actual Take advances beyond its first quantized bound without an empty buddy stage")
			var legacy:=Actor.new();rig.scene.add_child(legacy);legacy.unit_id="legacy"
			var old_state:Dictionary={"current_moving_unit_ids":PackedStringArray(["legacy"]),"current_target_positions":{"legacy":Vector2.ZERO}}
			var old_records:Array=[{"unit_id":"legacy","unit":legacy}]
			legacy.global_position=Vector2(19,0)
			_check(not movement._are_current_targets_reached(old_state,old_records),"Legacy movement retains its original outside-radius rejection")
			legacy.global_position=Vector2(17,0)
			_check(movement._are_current_targets_reached(old_state,old_records),"Legacy movement retains its original inside-radius arrival")
		rig.scene.free()

func _test_occupied_access()->void:
	var cells:Array=[]
	for x in range(7):
		for y in range(5):cells.append(Vector2i(x,y))
	var rig:=_admission_rig(cells)
	rig.sim.name="SimulationRoot";rig.units.name="UnitRegistry";rig.terrain.name="TerrainRegistry"
	rig.sim.unit_registry_path=rig.sim.get_path_to(rig.units);rig.sim.terrain_registry_path=rig.sim.get_path_to(rig.terrain);rig.sim.set_physics_process(false)
	for id in ["approach_a","approach_b","waiting_other_team"]:
		var actor:=ACTOR.new();actor.unit_id=id;actor.team_id="team_alpha";actor.fireteam_id="other" if id=="waiting_other_team" else "ft1"
		actor.weapon_1_id="none";actor.weapon_2_id="none";rig.scene.add_child(actor);actor.set_physics_process(false)
		rig.units.register_unit(id,actor);rig.sim.register_known_unit(id,actor)
	var own:=PackedStringArray(["approach_a","approach_b"])
	_check(rig.sim.admit_hex_ground_actor_group(own,Vector2i(0,0)).ok and rig.sim.admit_hex_ground_actor_group(PackedStringArray(["waiting_other_team"]),Vector2i(3,2)).ok,"actual own and foreign waiting crew have distinct Root occupancy")
	var before:Dictionary=rig.sim.get_hex_ground_planning_snapshot()
	var anchor:Vector2=rig.terrain.grid_to_world(Vector2i(3,2))
	var plan:Dictionary=rig.sim.plan_hex_ground_actor_approach(own,anchor,96.0)
	_check(plan.get("ok",false),"foreign unit on access does not prevent bounded free neighboring approach")
	var legal:bool=plan.get("ok",false)
	var used:Dictionary={}
	for id in Dictionary(plan.get("targets",{})):
		var target:Vector2=plan.targets[id];var grid:Vector2i=rig.terrain.world_to_grid(target)
		legal=legal and grid!=Vector2i(3,2) and not used.has(grid) and target.distance_to(anchor)<=96.0
		used[grid]=true
	_check(legal and used.size()==2 and int(plan.get("expanded",65))<=64,"alternative goals remain unique within96 and one64-expansion budget")
	_check(rig.sim.get_hex_ground_planning_snapshot()==before and rig.sim.get_hex_unit_state("waiting_other_team").grid==Vector2i(3,2),"planning preserves waiting foreign crew and every existing Root claim")
	var movement=preload("res://scripts/tactical/fireteam_movement_controller.gd").new()
	var records:Array=[{"unit_id":"approach_a"},{"unit_id":"approach_b"}]
	var free_target:Vector2=rig.terrain.grid_to_world(Vector2i(3,1))
	var desired:Dictionary={"approach_a":anchor,"approach_b":free_target}
	var resolved:Dictionary=movement._resolve_occupied_hex_formation_targets(rig.sim,records,desired,rig.terrain)
	_check(not resolved.is_empty() and resolved.approach_b==free_target and resolved.approach_a!=anchor and resolved.approach_a!=free_target,"normal formation repairs foreign occupied goal while preserving and excluding free member goal")
	_check(movement._resolve_occupied_hex_formation_targets(rig.sim,records,resolved,rig.terrain).is_empty() and desired.approach_a==anchor and rig.sim.get_hex_ground_planning_snapshot()==before,"free formation remains unchanged and repair mutates no Ground claims or input")
	var take:=SpacingMovement.new()
	var take_a=rig.units.get_unit("approach_a");var take_b=rig.units.get_unit("approach_b")
	var cover_grid:Vector2i=rig.sim.get_hex_unit_state("approach_b").grid
	take.forced_target=rig.terrain.grid_to_world(cover_grid)
	var take_started:Dictionary=take.start_execution("take_test","take",0,rig.terrain.grid_to_world(Vector2i(6,4)),null,[take_a,take_b],take_a,rig.sim,rig.terrain)
	var take_state:Dictionary=take._execution_by_fireteam["take_test"]
	take_state.effective_style=take.ADVANCE_STYLE_BOUNDING;take_state.group_cycle=[PackedStringArray(["approach_a"]),PackedStringArray(["approach_b"])];take_state.next_group_index=0
	var take_records:Array=take._build_member_records([take_a,take_b],take_a)
	take._issue_stage(take_state,take_records,rig.sim,rig.terrain)
	rig.sim._physics_process(0.1)
	var take_readout:Dictionary=rig.sim.get_hex_movement_readout("approach_a")
	print("TAKE_COVER_DIAGNOSTIC ",{"started":take_started,"cover":take_state.current_covering_unit_ids,"move":take_state.current_moving_unit_ids,"readout":take_readout,"cover_grid":cover_grid,"b":rig.sim.get_hex_unit_state("approach_b"),"targets":take_state.current_target_positions})
	_check(take_started.get("started",false) and take_state.current_covering_unit_ids.has("approach_b") and take_readout.goal_grid!=cover_grid and rig.sim.get_hex_unit_state("approach_b").grid==cover_grid,"real TAKE bounding stage preserves holding cover member and assigns moving member a distinct legal goal")
	for tick in range(180):rig.sim._physics_process(0.1)
	_check(rig.sim.has_hex_destination_arrived("approach_a",String(take_readout.source_command_id)) and rig.sim.get_hex_unit_state("approach_b").grid==cover_grid,"actual TAKE moving member arrives without displacing its holding cover member")
	var actual:=SpacingMovement.new();actual.forced_target=anchor
	var first=rig.units.get_unit("approach_a");var second=rig.units.get_unit("approach_b")
	var started:Dictionary=actual.start_execution("ft1","move",0,rig.terrain.grid_to_world(Vector2i(6,4)),null,[first,second],first,rig.sim,rig.terrain)
	rig.sim._physics_process(0.1)
	var a:Dictionary=rig.sim.get_hex_movement_readout("approach_a")
	var b:Dictionary=rig.sim.get_hex_movement_readout("approach_b")
	_check(started.get("started",false) and not a.is_empty() and not b.is_empty() and a.goal_grid!=Vector2i(3,2) and a.goal_grid!=b.goal_grid,"actual stage repairs final spacing result before issuing distinct Root movement goals")


	rig.scene.free()

func _test_partial_return_gather()->void:
	var cells:Array=[]
	for x in range(8):
		for y in range(5):cells.append(Vector2i(x,y))
	var rig:=_admission_rig(cells)
	rig.sim.name="SimulationRoot";rig.units.name="UnitRegistry";rig.terrain.name="TerrainRegistry"
	rig.sim.unit_registry_path=rig.sim.get_path_to(rig.units);rig.sim.terrain_registry_path=rig.sim.get_path_to(rig.terrain);rig.sim.set_physics_process(false)
	var index:=INDEX.new();index.name="MissionRuntimeIndex";rig.scene.add_child(index)
	var hud:=HUD.new();hud.name="MissionHudReadModel";rig.scene.add_child(hud)
	var controller:=QuietController.new();rig.scene.add_child(controller)
	var actors:Array=[]
	for id in ["near","far"]:
		var actor:=ACTOR.new();actor.unit_id=id;actor.team_id="team_alpha";actor.fireteam_id="ft1";actor.is_fireteam_lead=id=="near"
		actor.weapon_1_id="none";actor.weapon_2_id="none";rig.scene.add_child(actor);actor.set_physics_process(false)
		rig.units.register_unit(id,actor);rig.sim.register_known_unit(id,actor)
		rig.sim.admit_hex_ground_actor_group(PackedStringArray([id]),Vector2i(4,2) if id=="near" else Vector2i.ZERO)
		actors.append(actor)
	var access:Vector2=rig.terrain.grid_to_world(Vector2i(3,2))
	controller.return_fixture={"craft_id":"fixture","position":access,"crew":actors}
	var plan:Dictionary=rig.sim.plan_hex_ground_actor_approach(PackedStringArray(["near","far"]),access,96.0)
	_check(plan.ok and rig.terrain.world_to_grid(plan.targets.far)==Vector2i(4,2),"partially arrived crew fixture assigns far actor the near actor's current cell")
	var waypoint:=WAYPOINT.new();waypoint.waypoint_id="gather";waypoint.metadata={"interaction_id":"ship_return"}
	var state:Dictionary={"phase":0,"hex_execution_scope":controller._new_hex_execution_scope("ft1")}
	_check(controller._start_campaign_return_gather(waypoint,state),"actual Hex gather issues one coherent plan for near and distant members")
	var targets:Dictionary={}
	for command:Dictionary in rig.sim.command_queue:targets[command.unit_id]={"type":command.get("command_type",command.get("type")),"target":command.target_position}
	_check(targets.size()==2 and targets.near.type=="move_to_position" and targets.near.target==plan.targets.near and targets.far.target==plan.targets.far,"near member moves to its planned free cell instead of holding the far member's goal")
	for tick in range(500):
		rig.sim._physics_process(0.05)
		if rig.sim.has_hex_position_arrived("near",plan.targets.near,"campaign-return-gather:gather:near") and rig.sim.has_hex_position_arrived("far",plan.targets.far,"campaign-return-gather:gather:far"):break
	_check(rig.sim.has_hex_position_arrived("near",plan.targets.near,"campaign-return-gather:gather:near") and rig.sim.has_hex_position_arrived("far",plan.targets.far,"campaign-return-gather:gather:far"),"both actual Root actors complete partial-arrival gather with original tokens")
	rig.scene.free()
