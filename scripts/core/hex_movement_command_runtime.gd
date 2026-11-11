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
var _owner_ref:WeakRef
var _registry:Node
var _ground
var _orders:Dictionary={}
var _recovery_watchers:Dictionary={}
var _pending_stops:Dictionary={}
var _serial:=0
var _traffic_epoch:=0
var _flushing_stops:=false
var _pathfinder=PATHFINDER.new()
var _audit:Dictionary={}

func configure(owner:Node,registry:Node,ground)->void:
	clear()
	_owner_ref=weakref(owner)
	_registry=registry
	_ground=ground

func clear()->void:
	_owner_ref=null
	_registry=null
	_ground=null
	_orders.clear()
	_recovery_watchers.clear()
	_pending_stops.clear()
	_serial=0
	_traffic_epoch=0
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
	if previous.is_empty() or previous.fingerprint!=fingerprint or previous.status=="canceled":
		if not previous.is_empty():_clear_recovery(id,previous)
		if _ground.has_motion_commitments(id):_pending_stops[id]="new_order"
		_serial+=1
		var internal_id:String="hex_move:%d:%s:%d"%[_owner().get_hex_ground_context_revision(),id,_serial]
		_orders[id]={"command_id":internal_id,"source_command_id":token if not token.is_empty() else internal_id,"fingerprint":fingerprint,"goal_grid":goal,"command":stored,
			"status":"active","reason":"","path":[],"path_index":{},"cursor":0,"search":null,"terrain_revision":-1,"blocker_signature":"","wait_ticks":0,"navigation_jobs":0,"last_nav_tick":-1,
			"last_attempt_epoch":-1,"next_attempt_tick":0,"last_faced_segment":"","cost_options":{},"base_step_seconds":[],"duration_estimates":[],"recovery":{}}
		_traffic_epoch+=1
	else:previous.command=stored
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

func get_audit()->Dictionary:
	return _audit.duplicate(true)

func _score(order:Dictionary)->int:
	return clampi(int(order.command.get("priority",0)),-1000000,1000000)+mini(int(order.wait_ticks),1000000000000)

func tick(delta:float)->void:
	if not _live():return
	var owner=_owner()
	var now:int=owner.tick_counter
	var revision:int=_registry.call("get_revision")
	_audit={"tick":now,"navigation_slices":0,"navigation_jobs_created":0,"navigation_expansions":0,"reservation_requests":0,"accepted_steps":0,"plan_calls":0,"timing_edge_reads":0,"backoff_routes_started":0,"backoff_examined_cells":0}
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
	for grid in snapshot.get("admission_slots_by_grid",{}):blockers[grid]=true
	for id in snapshot.units_by_id:
		if not _orders.has(id) or _orders[id].status in ["arrived","canceled","blocked","waiting_speed","waiting_clearance"]:blockers[snapshot.units_by_id[id].grid]=true
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
				order.search=PATHFINDER.RegionalHexSearch.new(state.grid,navigation_goal,revision,options,_registry)
				order.navigation_jobs+=1
				_audit.navigation_jobs_created+=1
			var allowance:int=mini(24,MAX_NAV_EXPANSIONS-expansions)
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
		var plan:Dictionary=PLANNER.build_hex_plan(requests,snapshot,_registry)
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
