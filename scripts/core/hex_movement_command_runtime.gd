class_name HexMovementCommandRuntime
extends RefCounted

## Root-owned accepted intent/navigation state. Ground alone owns cell/motion truth.
const PATHFINDER=preload("res://scripts/terrain/terrain_pathfinder.gd")
const PLANNER=preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX=preload("res://scripts/terrain/hex_grid.gd")
const MAX_NAV_JOBS:=4
const MAX_NAV_EXPANSIONS:=96
const MAX_PLAN_REQUESTS:=16
# Producer diagnostics duplicate the effective UnitCommand fields. Retaining
# them as accepted intent would introduce a second, divergent stance snapshot.
const PRODUCER_DIAGNOSTIC_FIELDS := ["behavior_command_type","behavior_tactical_stance","behavior_speed_multiplier","behavior_sight_range_factor","behavior_cover_score_bonus","behavior_attack_bonus","behavior_movement_posture","behavior_weapon_posture","behavior_cover_priority_percent","behavior_aim_readiness_percent","engage_doctrine_id","engage_advance_mode","engage_target_policy","engage_buddy_teams","engage_fire_on_weapon_range","take_doctrine_id","take_advance_mode","take_target_policy","take_buddy_teams","take_area_control_required","local_avoidance_source"]
var _save_binding_epoch:=0
var _save_prepared_restores:Dictionary={}
var _owner_ref:WeakRef
var _registry:Node
var _ground
var _orders:Dictionary={}
var _recovery_watchers:Dictionary={}
var _pending_stops:Dictionary={}
var _serial:=0
var _traffic_epoch:=0
var _ship_mask_signature:=""
var _flushing_stops:=false
var _pathfinder=PATHFINDER.new()
var _audit:Dictionary={}

func configure(owner:Node,registry:Node,ground)->void:
	clear()
	_owner_ref=weakref(owner)
	_registry=registry
	_ground=ground

func clear()->void:
	_save_binding_epoch+=1
	_owner_ref=null
	_registry=null
	_ground=null
	_orders.clear()
	_recovery_watchers.clear()
	_pending_stops.clear()
	_serial=0
	_traffic_epoch=0
	_ship_mask_signature=""
	_flushing_stops=false
	_audit={}

func _owner():
	return _owner_ref.get_ref() if _owner_ref!=null else null

func _live()->bool:
	return is_instance_valid(_owner()) and is_instance_valid(_registry) and _ground!=null

func stage_move(command:Dictionary,actor:Node2D)->Dictionary:
	if not _live():return {"ok":false,"reason":"hex_runtime_unavailable"}
	var id:String=String(command.get("unit_id",""))
	if not _ground.has_unit(id):return {"ok":false,"reason":"hex_unit_not_admitted"}
	var target:Vector2=command.target_position
	if not target.is_finite():return {"ok":false,"reason":"invalid_target_position"}
	var goal:Vector2i=_registry.call("world_to_grid",target)
	var token:String=String(command.get("command_token",command.get("command_id","")))
	var fingerprint:String=JSON.stringify([id,goal,token,command.get("source_command_type",""),command.get("command_type",command.get("type",""))])
	var previous:Dictionary=_orders.get(id,{})
	var stored:Dictionary=command.duplicate(false)
	for key in ["path","_regional_navigation_search","_regional_navigation_route"]:stored.erase(key)
	for key in PRODUCER_DIAGNOSTIC_FIELDS:stored.erase(key)
	if previous.is_empty() or previous.fingerprint!=fingerprint or previous.status=="canceled":
		if not previous.is_empty():_clear_recovery(id,previous)
		if _ground.has_motion_commitments(id):_pending_stops[id]="new_order"
		_serial+=1
		var internal_id:String="hex_move:%d:%s:%d"%[_owner().get_hex_ground_context_revision(),id,_serial]
		_orders[id]={"command_id":internal_id,"source_command_id":token if not token.is_empty() else internal_id,"fingerprint":fingerprint,"goal_grid":goal,"command":stored,
			"status":"active","reason":"","path":[],"path_index":{},"cursor":0,"search":null,"terrain_revision":-1,"blocker_signature":"","wait_ticks":0,"navigation_jobs":0,"last_nav_tick":-1,
			"last_attempt_epoch":-1,"next_attempt_tick":0,"last_faced_segment":"","cost_options":{},"base_step_seconds":[],"duration_estimates":[],"recovery":{}}
		_traffic_epoch+=1
	else:
		previous.command=stored
		if previous.goal_grid!=goal:previous.command.target_position=_registry.call("grid_to_world",previous.goal_grid)
	if actor.has_method("set_target_position"):actor.call("set_target_position",_registry.call("grid_to_world",goal))
	return {"ok":true,"command_id":_orders[id].command_id}

func stage_stop(id:String,reason:String)->void:
	if not _live() or not _ground.has_unit(id):return
	if _orders.has(id):
		_orders[id].status="canceled"
		_orders[id].reason=reason
		_clear_recovery(id,_orders[id])
		_clear_route(_orders[id])
	_pending_stops[id]=reason
	_traffic_epoch+=1

func mark_external_stop(ids:PackedStringArray,reason:String)->void:
	if _flushing_stops:return
	for id in ids:
		if _orders.has(id):
			_orders[id].status="canceled"
			_orders[id].reason=reason
			_clear_recovery(id,_orders[id])
			_clear_route(_orders[id])

func flush_stops()->bool:
	if not _live() or _pending_stops.is_empty():return false
	var ids:=PackedStringArray()
	for id in _pending_stops:
		if _ground.has_unit(id):ids.append(id)
	_pending_stops.clear()
	if ids.is_empty():return false
	_flushing_stops=true
	var result:Dictionary=_owner().stop_hex_ground_units(ids,"runtime_stop")
	_flushing_stops=false
	return result.ok and not result.events.is_empty()

func release_unit(id:String)->void:
	if _orders.has(id):_clear_recovery(id,_orders[id])
	_orders.erase(id)
	_recovery_watchers.erase(id)
	_pending_stops.erase(id)
	_traffic_epoch+=1

func notify_ground_events(events:Array)->void:
	for event in events:
		_traffic_epoch+=1
		if event.event_type=="hex_field_changed":_observe_recovery_passage(event)
		var id:String=String(event.get("unit_id",""))
		if not _orders.has(id):continue
		var order:Dictionary=_orders[id]
		if event.event_type=="hex_field_changed":
			var found:int=int(order.path_index.get(event.to_grid,-1))
			if found>=int(order.cursor):order.cursor=found
		elif event.event_type=="hex_route_cancelled":
			_clear_recovery(id,order)
			_clear_route(order)
			if order.status!="canceled":order.status="active"
		_refresh_arrival(id,order)

func _clear_route(order:Dictionary)->void:
	order.path=[]
	order.path_index={}
	order.cursor=0
	order.search=null
	order.terrain_revision=-1
	order.last_faced_segment=""
	order.base_step_seconds=[]
	order.duration_estimates=[]

func _refresh_arrival(id:String,order:Dictionary)->void:
	if order.status=="canceled":return
	var state:Dictionary=_ground.read_unit(id)
	if state.is_empty():return
	if state.grid==order.goal_grid and not state.route_state.has_commitments and not state.movement_state.moving:
		_clear_recovery(id,order)
		if order.status!="arrived":_clear_route(order)
		order.status="arrived"
		order.reason=""
		return
	_refresh_recovery(id,order,state)

func _clear_recovery(id:String,order:Dictionary)->void:
	for other in order.get("recovery",{}).get("waiters",{}):
		var watchers:Dictionary=_recovery_watchers.get(other,{})
		watchers.erase(id)
		if watchers.is_empty():_recovery_watchers.erase(other)
	order.recovery={}

func _observe_recovery_passage(event:Dictionary)->void:
	var other:String=String(event.unit_id)
	for id in _recovery_watchers.get(other,{}).keys():
		if not _orders.has(id) or not _orders.has(other):continue
		var recovery:Dictionary=_orders[id].recovery
		if recovery.is_empty() or not recovery.waiters.has(other):continue
		if recovery.clearance_grid==event.to_grid and recovery.waiters[other].command_id==_orders[other].command_id:recovery.waiters[other].seen=true

func _refresh_recovery(id:String,order:Dictionary,state:Dictionary)->void:
	var recovery:Dictionary=order.get("recovery",{})
	if recovery.is_empty():return
	if recovery.phase=="moving":
		if state.grid!=recovery.goal_grid or state.route_state.has_commitments or state.movement_state.moving:return
		_clear_route(order)
		recovery.phase="waiting_clearance"
		order.status="waiting_clearance"
		order.reason="yielding_for_passage"
		_traffic_epoch+=1
	var claims:Dictionary=_ground.can_block_cells([recovery.clearance_grid])
	if not claims.ok:
		_abort_recovery(id,order,"backoff_clearance_invalidated")
		return
	var claimers:Dictionary={}
	for blocked in claims.blocked_cells:
		for claimant in blocked.unit_ids:claimers[claimant]=true
	for other in recovery.waiters:
		if not _orders.has(other) or not _ground.has_unit(other):continue
		var competing:Dictionary=_orders[other]
		if competing.command_id!=recovery.waiters[other].command_id:continue
		var pose:Dictionary=_ground.read_unit(other)
		var stationary:bool=not pose.route_state.has_commitments and not pose.movement_state.moving
		if stationary and (pose.grid==competing.goal_grid or competing.status in ["canceled","blocked","waiting_speed"]):continue
		if pose.grid==recovery.clearance_grid:recovery.waiters[other].seen=true
		if not recovery.waiters[other].seen or claimers.has(other):return
	_clear_recovery(id,order)
	_clear_route(order)
	order.status="active"
	order.reason=""
	_traffic_epoch+=1

func _navigation_goal(order:Dictionary)->Vector2i:
	var recovery:Dictionary=order.get("recovery",{})
	return recovery.goal_grid if not recovery.is_empty() else order.goal_grid

func _abort_recovery(id:String,order:Dictionary,reason:String)->void:
	_clear_recovery(id,order)
	_clear_route(order)
	order.status="active"
	order.reason=reason
	_traffic_epoch+=1

func get_readout(id:String)->Dictionary:
	if not _orders.has(id):return {}
	var order:Dictionary=_orders[id]
	return {"command_id":order.command_id,"source_command_id":order.source_command_id,"goal_grid":order.goal_grid,"status":order.status,"reason":order.reason,"navigation_jobs":order.navigation_jobs,"wait_ticks":order.wait_ticks,"cached_route_nodes":order.path.size(),"navigation_pending":order.search!=null,"recovery_phase":String(order.recovery.get("phase","")),"recovery_goal_grid":order.recovery.get("goal_grid",null)}

func has_arrived(id:String,command_id:String)->bool:
	if not _orders.has(id):return false
	var order:Dictionary=_orders[id]
	if order.status!="arrived" or command_id not in [order.command_id,order.source_command_id]:return false
	var state:Dictionary=_ground.read_unit(id)
	return not state.is_empty() and state.grid==order.goal_grid and not state.route_state.has_commitments and not state.movement_state.moving

## Wurde das Ziel dieses Auftrags umgelenkt (Besetzer nicht fit), gilt die Ausweichzelle fuer jede Frage "angekommen?", die noch
## die befohlene Zelle nennt (Speicherpruefung, Einzelsteuerung). Sonst bleibt die Zelle, wie sie ist.
func effective_goal_for(id:String,command_id:String,grid:Vector2i)->Vector2i:
	if not _orders.has(id):return grid
	var order:Dictionary=_orders[id]
	if order.has("redirected_from") and order.redirected_from==grid and command_id in [order.command_id,order.source_command_id]:return order.goal_grid
	return grid

func get_audit()->Dictionary:
	return _audit.duplicate(true)

func _score(order:Dictionary)->int:
	return clampi(int(order.command.get("priority",0)),-1000000,1000000)+mini(int(order.wait_ticks),1000000000000)

func tick(delta:float)->void:
	if not _live():return
	var owner=_owner()
	var now:int=owner.tick_counter
	var revision:int=_registry.call("get_revision")
	_audit={"tick":now,"navigation_slices":0,"native_navigation_slices":0,"gdscript_navigation_slices":0,"navigation_jobs_created":0,"navigation_expansions":0,"reservation_requests":0,"accepted_steps":0,"plan_calls":0,"timing_edge_reads":0,"backoff_routes_started":0,"backoff_examined_cells":0}
	for id in _orders:
		var order:Dictionary=_orders[id]
		if order.status in ["arrived","canceled"]:continue
		var actor=owner._resolve_known_unit_for_contract(id)
		if not is_instance_valid(actor) or not _ground.has_unit(id):
			stage_stop(id,"runtime_unit_unavailable")
			continue
		if actor.has_method("get_vital_state") and actor.call("get_vital_state")!="fit":stage_stop(id,"unit_not_fit")
	flush_stops()
	if delta<=0.0 or not is_finite(delta):return
	var has_active_order:=false
	for order:Dictionary in _orders.values():
		if order.status not in ["arrived","canceled"]:
			has_active_order=true
			break
	if not has_active_order:return
	# Reuse the same accepted ship geometry as ground admission. Landing checks
	# existing ground commitments before publishing a new footprint.
	var ship_mask:Dictionary={"ok":true,"blocked_cells":[],"source_signature":""}
	if owner.has_method("_get_hex_respawn_ship_mask"):ship_mask=owner.call("_get_hex_respawn_ship_mask")
	if not ship_mask.get("ok",false):
		for id in _orders:
			if _orders[id].status not in ["arrived","canceled"]:stage_stop(id,"ground_ship_mask_unavailable")
		flush_stops()
		return
	var ship_signature:String=String(ship_mask.get("source_signature",""))
	if ship_signature!=_ship_mask_signature:
		_ship_mask_signature=ship_signature
		_traffic_epoch+=1
	var eligible:Array=[]
	for id in _orders:
		var order:Dictionary=_orders[id]
		_refresh_arrival(id,order)
		if order.status in ["arrived","canceled","waiting_clearance"]:continue
		var state:Dictionary=_ground.read_unit(id)
		if state.is_empty():continue
		if state.grid==order.goal_grid and not state.route_state.has_commitments:continue
		if state.route_state.has_commitments and int(state.route_state.last_handoff_tick)>now:continue
		if order.status=="blocked" and order.terrain_revision==revision and order.last_attempt_epoch==_traffic_epoch:continue
		if order.status=="waiting_reservation" and order.last_attempt_epoch==_traffic_epoch and int(order.next_attempt_tick)>now:continue
		eligible.append({"id":id,"order":order,"state":state})
	eligible.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var sa:int=_score(a.order);var sb:int=_score(b.order)
		if sa!=sb:return sa>sb
		if a.order.last_nav_tick!=b.order.last_nav_tick:return a.order.last_nav_tick<b.order.last_nav_tick
		return a.id<b.id)
	if eligible.is_empty():
		_face_active_segments()
		return
	var snapshot:Dictionary=_ground.build_planning_snapshot()
	var blockers:Dictionary={}
	for grid in ship_mask.get("blocked_cells",[]):blockers[grid]=true
	for grid in snapshot.get("admission_slots_by_grid",{}):blockers[grid]=true
	for id in snapshot.units_by_id:
		# A unit waiting on an occupied goal stands still until the holder leaves: others must route around it.
		if not _orders.has(id) or _orders[id].status in ["arrived","canceled","blocked","waiting_speed","waiting_clearance"] or (owner.hex_waiting_units_block and _orders[id].status=="waiting_reservation" and _orders[id].reason=="target_occupied"):blockers[snapshot.units_by_id[id].grid]=true
	var blocker_keys:Array=blockers.keys()
	blocker_keys.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return a.x<b.x or (a.x==b.x and a.y<b.y))
	var blocker_signature:String=JSON.stringify(blocker_keys)
	var nav_jobs:=0
	var expansions:=0
	var nav_limit:int=mini(MAX_NAV_JOBS,maxi(0,int(owner.navigation_max_new_path_queries_per_tick))) if owner.navigation_budget_enabled else MAX_NAV_JOBS
	var requests:Array=[]
	for entry in eligible:
		var id:String=entry.id
		var order:Dictionary=entry.order
		var state:Dictionary=entry.state
		var actor=owner._resolve_known_unit_for_contract(id)
		var factor:float=owner._extract_move_speed_factor(order.command,actor)
		if not is_finite(factor) or factor<=0.0:
			if order.status!="waiting_speed":_pending_stops[id]="zero_speed"
			order.status="waiting_speed"
			order.reason="zero_speed"
			continue
		var navigation_goal:Vector2i=_navigation_goal(order)
		if not _registry.call("is_walkable",navigation_goal):
			if not order.recovery.is_empty():_abort_recovery(id,order,"backoff_target_invalidated");continue
			order.status="blocked";order.reason="target_unwalkable";order.terrain_revision=revision;order.last_attempt_epoch=_traffic_epoch
			continue
		var options:Dictionary=owner._build_navigation_cost_options(order.command,_registry)
		var cost_options:Dictionary=options.duplicate(true)
		var own_blockers:Dictionary=blockers.duplicate()
		own_blockers.erase(state.grid)
		options["blocked_grids"]=own_blockers
		# A stationary occupant cannot be crossed at the destination. Keep the
		# accepted intent, but do not spend the shared path budget searching an
		# impossible goal. Its release/movement changes blockers on the next tick.
		if own_blockers.has(navigation_goal) and _redirect_goal_held_by_unfit(id,order,state,own_blockers):
			navigation_goal=_navigation_goal(order)
		if own_blockers.has(navigation_goal):
			if not order.recovery.is_empty():_abort_recovery(id,order,"backoff_target_invalidated");continue
			_clear_route(order)
			order.status="waiting_reservation";order.reason="target_occupied"
			continue
		if order.status=="blocked" and order.terrain_revision==revision and order.blocker_signature==blocker_signature:
			order.last_attempt_epoch=_traffic_epoch
			continue
		var must_reset:bool=order.terrain_revision!=revision or order.cost_options!=cost_options
		if not order.path.is_empty() and order.blocker_signature!=blocker_signature:
			for grid in order.path.slice(int(order.cursor)+1):
				if own_blockers.has(grid):must_reset=true;break
		if order.search!=null and order.blocker_signature!=blocker_signature:must_reset=true
		if order.status=="blocked" and order.blocker_signature!=blocker_signature:must_reset=true
		if must_reset:_clear_route(order)
		order.blocker_signature=blocker_signature
		order.terrain_revision=revision
		order.cost_options=cost_options
		order.last_attempt_epoch=_traffic_epoch
		if order.path.is_empty():
			if nav_jobs>=nav_limit or expansions>=MAX_NAV_EXPANSIONS:
				order.status="path_pending";order.reason="navigation_budget";continue
			nav_jobs+=1
			_audit.navigation_slices=nav_jobs
			if order.search==null:
				order.search=owner.create_regional_navigation_search(state.grid,navigation_goal,_registry,options)
				order.navigation_jobs+=1
				_audit.navigation_jobs_created+=1
			var allowance:int=mini(24,MAX_NAV_EXPANSIONS-expansions)
			var backend:String=owner._note_regional_navigation_backend(order.search)
			order.navigation_backend=backend
			_audit[backend+"_navigation_slices"]+=1
			expansions+=order.search.advance(_pathfinder,_registry,allowance)
			_audit.navigation_expansions=expansions
			order.last_nav_tick=now
			if not order.search.finished:
				order.status="path_pending";order.reason="navigation_pending";continue
			if order.search.path.is_empty() or order.search.path.back()!=navigation_goal:
				if not order.recovery.is_empty():_abort_recovery(id,order,"backoff_unreachable");continue
				order.search=null;order.status="blocked";order.reason="unreachable_target";continue
			order.path=order.search.path.duplicate()
			order.cursor=0
			order.search=null
			_prepare_route_timing(order,factor,delta)
		if int(order.cursor)>=order.path.size() or order.path[int(order.cursor)]!=state.grid:
			_clear_route(order);order.status="active";continue
		if requests.size()>=MAX_PLAN_REQUESTS:order.status="waiting_reservation";order.reason="reservation_budget";continue
		var request:Dictionary=_cached_reservation_request(id,order,factor,delta)
		if request.is_empty():
			_refresh_arrival(id,order)
			continue
		requests.append(request)
	if not requests.is_empty():_supplement_waiting_requests(requests,revision,blocker_signature,delta)
	flush_stops()
	if not requests.is_empty():
		_audit.reservation_requests=requests.size()
		_audit.plan_calls=1
		# Stops above may change coupled occupancy; read one fresh joint snapshot.
		snapshot=_ground.build_planning_snapshot()
		var ship_blockers:Dictionary={}
		for cell in ship_mask.get("blocked_cells",[]):ship_blockers[cell]=true
		var plan:Dictionary=PLANNER.build_hex_plan(requests,snapshot,_registry,{"blocked_grids":ship_blockers})
		if plan.ok:
			var result:Dictionary=owner.commit_hex_ground_plan(plan,int(plan.expected_revision))
			if result.ok:
				_audit.accepted_steps=plan.accepted_steps.size()
				var accepted:Dictionary={}
				for segment in plan.accepted_steps:accepted[segment.unit_id]=true
				if not accepted.is_empty():_traffic_epoch+=1
				for request in requests:
					var order:Dictionary=_orders[request.unit_id]
					if accepted.has(request.unit_id):
						order.status="active"
						order.reason=""
						if order.recovery.is_empty():order.wait_ticks=0
					else:
						order.status="waiting_reservation";order.reason=plan.reason if not String(plan.reason).is_empty() else "reserved"
						for blocked in plan.blocked:
							if blocked.unit_id==request.unit_id:order.reason=blocked.reason
						order.wait_ticks=mini(int(order.wait_ticks)+1,1000000000000)
						order.last_attempt_epoch=_traffic_epoch;order.next_attempt_tick=now+4
				_stage_backoff(plan,requests,blocker_signature,delta)
	_face_active_segments()

## A downed/dead occupant keeps its cell (it may recover or respawn) but must not
## hold a goal forever. Redirect the accepted goal to the nearest free neighbour
## cell; fit occupants still make the order wait.
func _redirect_goal_held_by_unfit(id:String,order:Dictionary,state:Dictionary,own_blockers:Dictionary)->bool:
	if not order.recovery.is_empty():return false
	# Fireteam stage orders (they carry a phase) keep the controller-side repair R-A:
	# the stage target it tracks must stay the cell the member is really sent to.
	if order.command.has("phase"):return false
	var goal:Vector2i=order.goal_grid
	var holder:String=_ground.get_occupant_at(goal)
	if holder.is_empty() or holder==id:return false
	var actor=_owner()._resolve_known_unit_for_contract(holder)
	if not is_instance_valid(actor) or not actor.has_method("get_vital_state") or actor.call("get_vital_state")=="fit":return false
	var ring:Array=[goal]
	var seen:Dictionary={goal:true}
	for depth in range(2):
		var best:Variant=null
		var next_ring:Array=[]
		for cell in ring:
			for neighbor in _registry.call("get_legal_hex_neighbors",cell):
				if seen.has(neighbor):continue
				seen[neighbor]=true
				next_ring.append(neighbor)
				if own_blockers.has(neighbor):continue
				if best==null or _redirect_candidate_better(neighbor,best,state.grid):best=neighbor
		if best!=null:
			# Die Ausweichzelle ist ab hier das wirksame Ziel; die befohlene Zelle merken (effective_goal_for).
			if not order.has("redirected_from"):order["redirected_from"]=order.goal_grid
			order.goal_grid=best
			# Save validation requires the stored target to name the goal cell.
			order.command.target_position=_registry.call("grid_to_world",best)
			_clear_route(order)
			_traffic_epoch+=1
			return true
		ring=next_ring
	return false

func _redirect_candidate_better(candidate:Vector2i,best:Vector2i,origin:Vector2i)->bool:
	var dc:int=HEX.distance(origin,candidate)
	var db:int=HEX.distance(origin,best)
	if dc!=db:return dc<db
	return candidate.x<best.x or (candidate.x==best.x and candidate.y<best.y)

func _cached_reservation_request(id:String,order:Dictionary,factor:float,delta:float)->Dictionary:
	var tail:Array=order.path.slice(int(order.cursor))
	if tail.size()<2:return {}
	# Only the next three durations bind; later values remain provisional.
	for i in range(mini(3,tail.size()-1)):
		var index:int=int(order.cursor)+i
		order.duration_estimates[index]=maxi(1,ceili(float(order.base_step_seconds[index])/(factor*delta)))
	return {"unit_id":id,"command_id":order.command_id,"priority":int(order.command.get("priority",0)),"wait_ticks":order.wait_ticks,"path_grid_points":tail,"duration_ticks_by_step":order.duration_estimates.slice(int(order.cursor))}

func _supplement_waiting_requests(requests:Array,revision:int,blocker_signature:String,delta:float)->void:
	if requests.size()>=MAX_PLAN_REQUESTS:return
	var included:Dictionary={}
	for request in requests:included[request.unit_id]=true
	var candidates:Array=[]
	for id in _orders:
		var order:Dictionary=_orders[id]
		if included.has(id) or order.status!="waiting_reservation" or order.terrain_revision!=revision or order.blocker_signature!=blocker_signature or order.path.size()<2 or _ground.has_motion_commitments(id):continue
		candidates.append({"id":id,"order":order})
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var sa:int=_score(a.order);var sb:int=_score(b.order)
		return sa>sb if sa!=sb else a.id<b.id)
	for candidate in candidates:
		if requests.size()>=MAX_PLAN_REQUESTS:break
		var id:String=candidate.id
		var order:Dictionary=candidate.order
		var state:Dictionary=_ground.read_unit(id)
		if state.is_empty() or order.path[int(order.cursor)]!=state.grid:continue
		var connected:=false
		for request in requests:
			var other:Dictionary=_orders[request.unit_id]
			if int(order.path_index.get(request.path_grid_points[0],-1))>int(order.cursor) or int(other.path_index.get(state.grid,-1))>int(other.cursor):connected=true;break
		if not connected or _owner()._build_navigation_cost_options(order.command,_registry)!=order.cost_options:continue
		var actor=_owner()._resolve_known_unit_for_contract(id)
		var factor:float=_owner()._extract_move_speed_factor(order.command,actor)
		if not is_finite(factor) or factor<=0.0:continue
		var request:Dictionary=_cached_reservation_request(id,order,factor,delta)
		if not request.is_empty():requests.append(request)

func _stage_backoff(plan:Dictionary,requests:Array,blocker_signature:String,delta:float)->void:
	var candidates:Array=[]
	for blocked in plan.blocked:
		_audit.backoff_examined_cells+=int(blocked.get("backoff_examined_cells",0))
		var id:String=String(blocked.unit_id)
		if blocked.reason!="backoff_required" or not _orders.has(id) or _ground.has_motion_commitments(id):continue
		var order:Dictionary=_orders[id]
		var path:Array=blocked.get("backoff_path_grid_points",[])
		if not order.recovery.is_empty() or path.size()<2 or path.size()>64:continue
		var waiters:Dictionary={}
		var obstructs_recovery:=false
		for request in requests:
			var other:String=String(request.unit_id)
			if other==id or int(_orders[other].path_index.get(path[0],-1))<int(_orders[other].cursor):continue
			if not _orders[other].recovery.is_empty():obstructs_recovery=true;break
			waiters[other]={"command_id":_orders[other].command_id,"seen":false}
		if not waiters.is_empty() and not obstructs_recovery:candidates.append({"id":id,"order":order,"path":path,"waiters":waiters})
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var sa:int=_score(a.order);var sb:int=_score(b.order)
		return sa<sb if sa!=sb else a.id>b.id)
	if candidates.is_empty():return
	var selected:Dictionary=candidates[0]
	var order:Dictionary=selected.order
	_clear_route(order)
	order.recovery={"phase":"moving","goal_grid":selected.path.back(),"clearance_grid":selected.path[0],"waiters":selected.waiters}
	for other in selected.waiters:
		if not _recovery_watchers.has(other):_recovery_watchers[other]={}
		_recovery_watchers[other][selected.id]=true
	order.path=selected.path.duplicate()
	order.terrain_revision=int(_registry.call("get_revision"))
	order.blocker_signature=blocker_signature
	order.cost_options=_owner()._build_navigation_cost_options(order.command,_registry)
	var actor=_owner()._resolve_known_unit_for_contract(String(selected.id))
	_prepare_route_timing(order,_owner()._extract_move_speed_factor(order.command,actor),delta)
	order.status="yielding"
	order.reason="clearing_passage"
	order.next_attempt_tick=int(_owner().tick_counter)+1
	_audit.backoff_routes_started=1
	_traffic_epoch+=1

func _prepare_route_timing(order:Dictionary,factor:float,delta:float)->void:
	order.base_step_seconds=[]
	order.duration_estimates=[]
	order.path_index={order.path[0]:0}
	var spacing:float=_registry.call("get_movement_distance",_registry.call("grid_to_world",Vector2i.ZERO),_registry.call("grid_to_world",Vector2i.RIGHT))
	var source=_registry.call("get_tile_at_grid",order.path[0])
	var source_factor:float=TILE.get_surface_speed_factor(source.surface_type) if source!=null else 1.0
	for i in range(order.path.size()-1):
		order.path_index[order.path[i+1]]=i+1
		_audit.timing_edge_reads+=1
		var target=_registry.call("get_tile_at_grid",order.path[i+1])
		var target_factor:float=TILE.get_surface_speed_factor(target.surface_type) if target!=null else 1.0
		var base:float=spacing/float(_owner().MOVE_SPEED_PER_SECOND)*0.5*(1.0/source_factor+1.0/target_factor)
		order.base_step_seconds.append(base)
		order.duration_estimates.append(maxi(1,ceili(base/(factor*delta))))
		source_factor=target_factor

func _face_active_segments()->void:
	for id in _orders:
		var state:Dictionary=_ground.read_unit(id)
		if state.is_empty() or not state.movement_state.moving or state.movement_state.get("phase","")=="centering":continue
		var movement:Dictionary=state.movement_state
		var key:String=JSON.stringify([movement.command_id,movement.start_tick])
		if _orders[id].last_faced_segment==key:continue
		var direction:int=HEX.DIRECTIONS.find(movement.to_grid-movement.from_grid)
		_owner()._commit_hex_movement_facing(id,direction)
		_orders[id].last_faced_segment=key


# AP7 host-only canonical intent subset. No path/search/queue serialization.
const SAVE_COMMAND=preload("res://scripts/npc/unit_command.gd")
class PreparedMovementRestore extends RefCounted:
	pass

func export_state()->Dictionary:
	var issue:=_save_context_issue()
	if not issue.is_empty():return _save_reject(issue)
	var snap:Dictionary=_ground.build_planning_snapshot()
	var intents:Array=[]
	var ids:Array=_orders.keys();ids.sort()
	if ids.size()>64:return _save_reject("movement_save_budget")
	for id in ids:
		var order:Dictionary=_orders[id]
		var packed:Dictionary=_save_pack_command(order.command)
		if not packed.ok:return packed
		var recovery:Dictionary={}
		if not order.recovery.is_empty():
			var waiters:Array=[]
			var other_ids:Array=order.recovery.waiters.keys();other_ids.sort()
			for other in other_ids:waiters.append({"unit_id":other,"command_id":order.recovery.waiters[other].command_id,"seen_passage":order.recovery.waiters[other].seen})
			recovery={"phase":order.recovery.phase,"goal_grid":_save_pair(order.recovery.goal_grid),"clearance_grid":_save_pair(order.recovery.clearance_grid),"waiters":waiters}
		intents.append({"unit_id":id,"command_id":order.command_id,"source_command_id":order.source_command_id,"goal_grid":_save_pair(order.goal_grid),"command_intent":packed.fields,"status":order.status,"reason":order.reason,"wait_ticks":order.wait_ticks,"next_attempt_tick":order.next_attempt_tick,"last_nav_tick":order.last_nav_tick,"recovery":recovery})
	var state:Dictionary={"schema":"hex_movement_v1","map_id":snap.map_id,"terrain_revision":snap.terrain_revision,"tick":snap.current_tick,"serial":_serial,"accepted_intents":intents}
	var checked:Dictionary=_save_validate(state,_ground)
	return state if checked.ok else checked

func prepare_restore_state(state:Dictionary,target_ground=null,target_registry:Node=null)->Dictionary:
	var issue:=_save_context_issue()
	if not issue.is_empty():return _save_reject(issue)
	for key in _save_prepared_restores.keys():
		var old:Dictionary=_save_prepared_restores[key]
		if old.handle.get_ref()==null or old.epoch!=_save_binding_epoch:_save_prepared_restores.erase(key)
	if _save_prepared_restores.size()>=32:return _save_reject("movement_restore_prepare_capacity")
	var target=target_ground if target_ground!=null else _ground
	var checked:Dictionary=_save_validate(state,target,target_registry)
	if not checked.ok:return checked
	var binding:Dictionary=_save_live_binding()
	if not binding.ok:return binding
	var prepared:=PreparedMovementRestore.new()
	_save_prepared_restores[prepared.get_instance_id()]={"handle":weakref(prepared),"epoch":_save_binding_epoch,"state":state.duplicate(true),"binding":binding,"target_ground":target,"target_registry":target_registry,"target_binding":_save_ground_binding(target),"orders":checked.orders,"watchers":checked.watchers,"serial":int(state.serial),"traffic_epoch":_traffic_epoch+1}
	return {"ok":true,"prepared":prepared}

func validate_prepared_restore(prepared:RefCounted)->Dictionary:
	if prepared==null or not _save_prepared_restores.has(prepared.get_instance_id()):return _save_reject("movement_restore_foreign_preparation")
	var record:Dictionary=_save_prepared_restores[prepared.get_instance_id()]
	if record.handle.get_ref()!=prepared or record.epoch!=_save_binding_epoch:return _save_reject("movement_restore_owner_changed")
	var issue:=_save_context_issue()
	if not issue.is_empty():return _save_reject(issue)
	var binding:Dictionary=_save_live_binding()
	if not binding.ok or binding!=record.binding or _save_ground_binding(record.target_ground)!=record.target_binding:return _save_reject("movement_restore_stale_context")
	var checked:Dictionary=_save_validate(record.state,record.target_ground,record.target_registry)
	if not checked.ok:return checked
	return {"ok":true,"prepared_id":prepared.get_instance_id()}

func publish_prepared_restore(prepared:RefCounted)->Dictionary:
	var checked:Dictionary=validate_prepared_restore(prepared)
	if not checked.ok:return checked
	if _save_prepared_restores[prepared.get_instance_id()].target_ground!=_ground:return _save_reject("movement_restore_joint_publish_required")
	return _publish_prepared_restore(prepared,checked)

# Root may call only after ALL participants validate, then Ground publishes first.
# No getters, signals, callbacks or fallible validation after the first owner write.
func _publish_prepared_restore(prepared:RefCounted,_validation:Dictionary)->Dictionary:
	var record:Dictionary=_save_prepared_restores[prepared.get_instance_id()]
	_orders=record.orders
	_recovery_watchers=record.watchers
	_serial=record.serial
	_traffic_epoch=record.traffic_epoch
	_pending_stops={}
	_audit={}
	_save_binding_epoch+=1
	_save_prepared_restores.erase(prepared.get_instance_id())
	return {"ok":true,"intent_count":_orders.size()}

func _save_context_issue()->String:
	if not _live():return "movement_save_unavailable"
	if _flushing_stops or not _pending_stops.is_empty():return "movement_save_pending_stop"
	if not _owner().has_method("get_hex_ground_context_revision") or not _owner().has_method("_resolve_known_unit_for_contract") or not _owner().has_method("_get_unit_registry"):return "movement_save_owner_capability"
	var units=_owner()._get_unit_registry()
	if not is_instance_valid(units) or not units.has_method("get_unit"):return "movement_save_unit_registry_unavailable"
	return ""

func _save_live_binding()->Dictionary:
	var state:Dictionary=export_state()
	if state.get("schema")!="hex_movement_v1":return state
	var actor_ids:Dictionary={}
	for id in _orders:
		var actor=_save_registered_actor(id)
		if actor==null:return _save_reject("movement_save_actor_unbound")
		actor_ids[id]=actor.get_instance_id()
	return {"ok":true,"runtime_epoch":_save_binding_epoch,"owner_id":_owner().get_instance_id(),"owner_context":_owner().get_hex_ground_context_revision(),"owner_tick":_owner().tick_counter,"registry_id":_registry.get_instance_id(),"unit_registry_id":_owner()._get_unit_registry().get_instance_id(),"ground":_save_ground_binding(_ground),"traffic_epoch":_traffic_epoch,"current_intents":JSON.stringify(state),"actors":actor_ids}

func _save_registered_actor(id:String):
	var registry=_owner()._get_unit_registry()
	if not is_instance_valid(registry) or not registry.has_method("get_unit"):return null
	var registered=registry.call("get_unit",id)
	var known=_owner()._resolve_known_unit_for_contract(id)
	if not is_instance_valid(registered) or not registered is Node2D or known!=registered or not registered.has_method("get_unit_id") or registered.call("get_unit_id")!=id:return null
	return registered

func _save_ground_binding(ground)->Dictionary:
	if ground==null or not is_instance_valid(ground) or not ground.has_method("build_planning_snapshot"):return {}
	var snap:Dictionary=ground.build_planning_snapshot()
	var actors:Dictionary={}
	for id in ground.get_unit_ids():
		var actor=_save_registered_actor(id)
		actors[id]=actor.get_instance_id() if is_instance_valid(actor) else 0
	return {"actors":actors,"id":ground.get_instance_id(),"map_id":snap.map_id,"revision":snap.revision,"tick":snap.current_tick,"terrain_revision":snap.terrain_revision}

func _save_validate(state:Dictionary,target,target_registry:Node=null)->Dictionary:
	var registry:Node=target_registry if target_registry!=null else _registry
	if not _save_keys(state,["schema","map_id","terrain_revision","tick","serial","accepted_intents"]) or state.schema!="hex_movement_v1":return _save_reject("invalid_movement_save_schema")
	if target==null or not is_instance_valid(target) or target.get_script()!=_ground.get_script() or target._registry!=registry:return _save_reject("movement_save_ground_unbound")
	var snap:Dictionary=target.build_planning_snapshot()
	if not _save_text(state.map_id,false) or state.map_id!=snap.map_id or not _save_integer(state.terrain_revision,0,1000000000000) or int(state.terrain_revision)!=snap.terrain_revision or int(state.terrain_revision)!=int(registry.call("get_revision")) or target._reservation_terrain_revision!=snap.terrain_revision:return _save_reject("movement_save_map_context")
	if not _save_integer(state.tick,0,1000000000000) or int(state.tick)!=snap.current_tick or not _save_integer(state.serial,0,1000000000000):return _save_reject("movement_save_clock_context")
	if typeof(state.accepted_intents)!=TYPE_ARRAY or state.accepted_intents.size()>64:return _save_reject("movement_save_budget")
	var orders:Dictionary={};var commands:Dictionary={};var watchers:Dictionary={}
	for value in state.accepted_intents:
		if not _save_keys(value,["unit_id","command_id","source_command_id","goal_grid","command_intent","status","reason","wait_ticks","next_attempt_tick","last_nav_tick","recovery"]):return _save_reject("invalid_movement_save_intent")
		if not _save_text(value.unit_id,false) or orders.has(value.unit_id) or not target.has_unit(value.unit_id):return _save_reject("movement_save_unit_unbound")
		var actor=_save_registered_actor(value.unit_id)
		if actor==null:return _save_reject("movement_save_actor_unbound")
		if not _save_text(value.command_id,false) or not _save_text(value.source_command_id,false) or commands.has(value.command_id):return _save_reject("invalid_movement_save_command_id")
		var suffix:String=String(value.command_id).get_slice(":",String(value.command_id).get_slice_count(":")-1)
		if not String(value.command_id).begins_with("hex_move:") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>int(state.serial):return _save_reject("invalid_movement_save_command_id")
		var goal:Dictionary=_save_vector(value.goal_grid,true)
		var command:Dictionary=_save_unpack_command(value.command_intent)
		if not goal.ok or not command.ok:return _save_reject("invalid_movement_save_command")
		var cmd:Dictionary=command.command
		if cmd.get("unit_id")!=value.unit_id or not cmd.has("target_position"):return _save_reject("movement_save_goal_mismatch")
		var axial:Vector2=registry.call("world_to_grid_float",cmd.target_position)
		if not axial.is_finite() or absf(axial.x)>2147470000.0 or absf(axial.y)>2147470000.0 or registry.call("world_to_grid",cmd.target_position)!=goal.value:return _save_reject("movement_save_goal_mismatch")
		var token:String=String(cmd.get("command_token",cmd.get("command_id","")))
		if value.source_command_id!=(token if not token.is_empty() else value.command_id):return _save_reject("movement_save_source_command_mismatch")
		if not _save_text(value.reason,true) or not value.status in ["active","canceled","arrived","waiting_clearance","blocked","waiting_speed","path_pending","waiting_reservation","yielding"]:return _save_reject("invalid_movement_save_status")
		if not _save_integer(value.wait_ticks,0,1000000000000) or not _save_integer(value.next_attempt_tick,0,1000000000000) or not _save_integer(value.last_nav_tick,-1,1000000000000):return _save_reject("invalid_movement_save_wait")
		var pose:Dictionary=target.read_unit(value.unit_id)
		if pose.route_state.has_commitments and pose.route_state.command_id!=value.command_id:return _save_reject("movement_save_segment_command_mismatch")
		if value.status=="arrived" and (pose.grid!=goal.value or pose.route_state.has_commitments or pose.movement_state.moving):return _save_reject("movement_save_false_arrival")
		var fingerprint:String=JSON.stringify([value.unit_id,goal.value,token,cmd.get("source_command_type",""),cmd.get("command_type",cmd.get("type",""))])
		orders[value.unit_id]={"command_id":String(value.command_id),"source_command_id":String(value.source_command_id),"fingerprint":fingerprint,"goal_grid":goal.value,"command":cmd,"status":String(value.status),"reason":String(value.reason),"path":[],"path_index":{},"cursor":0,"search":null,"terrain_revision":-1,"blocker_signature":"","wait_ticks":int(value.wait_ticks),"navigation_jobs":0,"last_nav_tick":int(value.last_nav_tick),"last_attempt_epoch":_traffic_epoch+1 if value.status=="waiting_reservation" else -1,"next_attempt_tick":int(value.next_attempt_tick),"last_faced_segment":"","cost_options":{},"base_step_seconds":[],"duration_estimates":[],"recovery":{}}
		commands[value.command_id]=true
	# Coverage is bidirectional: Ground horizons must never outlive their intent.
	# Centering has no route commitments and legitimately needs no Moveorder.
	for id in target.get_unit_ids():
		var actual:Dictionary=target.read_unit(id)
		if actual.route_state.has_commitments and not orders.has(id):return _save_reject("movement_save_missing_intent")
	for value in state.accepted_intents:
		var recovery:Variant=value.recovery
		if typeof(recovery)!=TYPE_DICTIONARY:return _save_reject("invalid_movement_save_recovery")
		if recovery.is_empty():
			if value.status in ["yielding","waiting_clearance"]:return _save_reject("movement_save_recovery_missing")
			continue
		if not _save_keys(recovery,["phase","goal_grid","clearance_grid","waiters"]) or not recovery.phase in ["moving","waiting_clearance"] or typeof(recovery.waiters)!=TYPE_ARRAY or recovery.waiters.is_empty() or recovery.waiters.size()>64:return _save_reject("invalid_movement_save_recovery")
		var goal:Dictionary=_save_vector(recovery.goal_grid,true);var clearance:Dictionary=_save_vector(recovery.clearance_grid,true)
		if not goal.ok or not clearance.ok or goal.value==clearance.value or not registry.call("is_walkable",goal.value) or not registry.call("is_walkable",clearance.value):return _save_reject("invalid_movement_save_clearance")
		var pose:Dictionary=target.read_unit(value.unit_id)
		if recovery.phase=="waiting_clearance" and (value.status!="waiting_clearance" or pose.grid!=goal.value or pose.route_state.has_commitments or pose.movement_state.moving):return _save_reject("invalid_movement_save_clearance_phase")
		if recovery.phase=="moving" and value.status not in ["yielding","active","waiting_reservation","path_pending","blocked","waiting_speed"]:return _save_reject("invalid_movement_save_clearance_phase")
		var waiters:Dictionary={}
		for waiter in recovery.waiters:
			if not _save_keys(waiter,["unit_id","command_id","seen_passage"]) or not _save_text(waiter.unit_id,false) or waiter.unit_id==value.unit_id or waiters.has(waiter.unit_id) or not orders.has(waiter.unit_id) or waiter.command_id!=orders[waiter.unit_id].command_id or typeof(waiter.seen_passage)!=TYPE_BOOL:return _save_reject("invalid_movement_save_waiter")
			waiters[waiter.unit_id]={"command_id":String(waiter.command_id),"seen":waiter.seen_passage}
			if not watchers.has(waiter.unit_id):watchers[waiter.unit_id]={}
			watchers[waiter.unit_id][value.unit_id]=true
		orders[value.unit_id].recovery={"phase":String(recovery.phase),"goal_grid":goal.value,"clearance_grid":clearance.value,"waiters":waiters}
	return {"ok":true,"orders":orders,"watchers":watchers}

func _save_command_kind(key:String)->String:
	if key=="security_mode":return "string"
	if key=="security_radius_tiles":return "integer"
	if key=="facing_angle":return "number"
	if key in ["type","command_type","unit_id","team_id","fireteam_id","source_command_type","origin_command_type","command_id","command_token","fire_status","fire_rule","source_task_type","movement_posture","weapon_posture","posture_policy_id","engagement_range_policy","target_area_id"]:return "string"
	if key in ["priority","phase","navigation_blocker_clearance_radius"]:return "integer"
	if key in ["requeue_until_target","navigation_cover_aware","cover_aware_navigation","navigation_corridor_enabled","navigation_lane_enabled","local_avoidance_enabled"]:return "bool"
	if key in ["move_speed_factor","sight_range_factor","cover_score","attack_bonus","engagement_range_factor","contact_initiative_seconds","aim_readiness_percent","team_target_support_percent","navigation_exposure_weight","navigation_cover_weight","navigation_exposure_max_grid_distance","navigation_corridor_half_width_world","navigation_corridor_weight","navigation_lane_offset_world","navigation_lane_weight","navigation_blocker_clearance_weight"]:return "number"
	if key in ["target_position","navigation_corridor_start_position","navigation_corridor_end_position","navigation_lane_sample_position"]:return "vector2"
	if key in ["navigation_threat_grids","threat_grids","danger_grids"]:return "grid_array"
	if key in ["navigation_threat_positions","threat_positions","danger_positions","enemy_positions"]:return "vector2_array"
	return ""

func _save_security_fields_valid(command:Dictionary)->bool:
	if command.has("security_mode"):
		var mode:Variant=command.security_mode
		if not mode is String or (not preload("res://scripts/tactical/tactical_command_rules.gd").ALLOWED_SECURITY_MODES.has(mode) and mode!="directional"):return false
	if command.has("security_radius_tiles") and not _save_integer(command.security_radius_tiles,0,256):return false
	if command.has("facing_angle") and (not _save_number(command.facing_angle) or absf(float(command.facing_angle))>TAU*2.0):return false
	return true

func _save_pack_command(command:Dictionary)->Dictionary:
	if command.size()>80:return _save_reject("movement_save_command_budget")
	if not _save_security_fields_valid(command):return _save_reject("movement_save_invalid_security_fields")
	if command.has("_hex_lifecycle"):
		var stamp:Variant=command._hex_lifecycle
		if not _save_keys(stamp,["context","lifecycle","actor"]):return _save_reject("movement_save_invalid_lifecycle")
		for key in ["context","lifecycle","actor"]:
			if typeof(stamp[key])!=TYPE_INT or stamp[key]<(1 if key=="actor" else 0):return _save_reject("movement_save_invalid_lifecycle")
		if not _owner().has_method("_is_current_hex_payload") or not _owner().call("_is_current_hex_payload",command):return _save_reject("movement_save_stale_lifecycle")
	var fields:Array=[];var keys:Array=command.keys();keys.sort()
	for key in keys:
		if typeof(key)!=TYPE_STRING:return _save_reject("movement_save_unsupported_command_field")
		if key=="_hex_lifecycle":continue # Validated above; never persist inprocess identities.
		var kind:=_save_command_kind(key)
		if kind.is_empty():return {"ok":false,"reason":"movement_save_unsupported_command_field","field":key}
		var value:Variant=command[key]
		if kind=="vector2":
			if typeof(value)!=TYPE_VECTOR2:return _save_reject("invalid_movement_save_vector")
			value=_save_pair(value)
		elif kind in ["grid_array","vector2_array"]:
			if typeof(value)!=TYPE_ARRAY or value.size()>256:return _save_reject("movement_save_command_budget")
			var pairs:Array=[]
			for point in value:
				if typeof(point)!=(TYPE_VECTOR2I if kind=="grid_array" else TYPE_VECTOR2):return _save_reject("invalid_movement_save_vector")
				pairs.append(_save_pair(point))
			value=pairs
		fields.append({"key":key,"kind":kind,"value":value})
	return {"ok":true,"fields":fields}

func _save_unpack_command(fields:Variant)->Dictionary:
	if typeof(fields)!=TYPE_ARRAY or fields.size()>80:return _save_reject("movement_save_command_budget")
	var command:Dictionary={}
	for field in fields:
		if not _save_keys(field,["key","kind","value"]) or typeof(field.key)!=TYPE_STRING or command.has(field.key) or _save_command_kind(field.key).is_empty() or field.kind!=_save_command_kind(field.key):return _save_reject("invalid_movement_save_command_field")
		var value:Variant=field.value
		match field.kind:
			"string":
				if not _save_text(value,true):return _save_reject("invalid_movement_save_command_field")
			"bool":
				if typeof(value)!=TYPE_BOOL:return _save_reject("invalid_movement_save_command_field")
			"integer":
				if not _save_integer(value,-1000000,1000000):return _save_reject("invalid_movement_save_command_field")
				value=int(value)
			"number":
				if not _save_number(value):return _save_reject("invalid_movement_save_command_field")
				value=float(value)
			"vector2":
				var vector:Dictionary=_save_vector(value,false)
				if not vector.ok:return vector
				value=vector.value
			"grid_array","vector2_array":
				if typeof(value)!=TYPE_ARRAY or value.size()>256:return _save_reject("movement_save_command_budget")
				var vectors:Array=[]
				for pair in value:
					var vector:Dictionary=_save_vector(pair,field.kind=="grid_array")
					if not vector.ok:return vector
					vectors.append(vector.value)
				value=vectors
		command[String(field.key)]=value
	if not _save_security_fields_valid(command):return _save_reject("movement_save_invalid_security_fields")
	var status:Dictionary=command.duplicate(false)
	if not status.has("command_type"):status.command_type=status.get("type","")
	if not SAVE_COMMAND.from_dict(status).is_valid():return _save_reject("invalid_movement_save_unit_command")
	return {"ok":true,"command":command}

func _save_keys(value:Variant,keys:Array)->bool:
	if typeof(value)!=TYPE_DICTIONARY or value.size()!=keys.size():return false
	for key in keys:
		if not value.has(key):return false
	return true
func _save_text(value:Variant,empty:bool)->bool:
	return typeof(value)==TYPE_STRING and String(value).length()<=256 and (empty or not String(value).is_empty()) and value==String(value).strip_edges()
func _save_integer(value:Variant,minimum:int,maximum:int)->bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)==floorf(float(value)) and float(value)>=minimum and float(value)<=maximum
func _save_number(value:Variant)->bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and absf(float(value))<=1000000000000.0
func _save_vector(value:Variant,grid:bool)->Dictionary:
	if typeof(value)!=TYPE_ARRAY or value.size()!=2:return _save_reject("invalid_movement_save_vector")
	for number in value:
		if not (_save_integer(number,-2147480000,2147480000) if grid else _save_number(number)):return _save_reject("invalid_movement_save_vector")
	return {"ok":true,"value":Vector2i(int(value[0]),int(value[1])) if grid else Vector2(float(value[0]),float(value[1]))}
func _save_pair(value:Variant)->Array:return [value.x,value.y]
func _save_reject(reason:String)->Dictionary:return {"ok":false,"reason":reason}


# Canonical host intent target only; never expose the private runtime patch.
func get_prepared_restore_state(prepared:RefCounted)->Dictionary:
	if not validate_prepared_restore(prepared).ok:return {}
	return Dictionary(_save_prepared_restores[prepared.get_instance_id()].state).duplicate(true)
