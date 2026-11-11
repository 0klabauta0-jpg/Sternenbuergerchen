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
		if _ground.has_motion_commitments(id):_pending_stops[id]="new_order"
		_serial+=1
		var internal_id:String="hex_move:%d:%s:%d"%[_owner().get_hex_ground_context_revision(),id,_serial]
		_orders[id]={"command_id":internal_id,"source_command_id":token if not token.is_empty() else internal_id,"fingerprint":fingerprint,"goal_grid":goal,"command":stored,
			"status":"active","reason":"","path":[],"cursor":0,"search":null,"terrain_revision":-1,"blocker_signature":"","wait_ticks":0,"navigation_jobs":0,"last_nav_tick":-1,
			"last_attempt_epoch":-1,"next_attempt_tick":0,"last_faced_segment":"","cost_options":{},"base_step_seconds":[],"duration_estimates":[]}
		_traffic_epoch+=1
	else:previous.command=stored
	if actor.has_method("set_target_position"):actor.call("set_target_position",_registry.call("grid_to_world",goal))
	return {"ok":true,"command_id":_orders[id].command_id}

func stage_stop(id:String,reason:String)->void:
	if not _live() or not _ground.has_unit(id):return
	if _orders.has(id):
		_orders[id].status="canceled"
		_orders[id].reason=reason
		_clear_route(_orders[id])
	_pending_stops[id]=reason
	_traffic_epoch+=1

func mark_external_stop(ids:PackedStringArray,reason:String)->void:
	if _flushing_stops:return
	for id in ids:
		if _orders.has(id):
			_orders[id].status="canceled"
			_orders[id].reason=reason
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
	_orders.erase(id)
	_pending_stops.erase(id)
	_traffic_epoch+=1

func notify_ground_events(events:Array)->void:
	for event in events:
		_traffic_epoch+=1
		var id:String=String(event.get("unit_id",""))
		if not _orders.has(id):continue
		var order:Dictionary=_orders[id]
		if event.event_type=="hex_field_changed":
			var found:int=order.path.find(event.to_grid,int(order.cursor))
			if found>=0:order.cursor=found
		elif event.event_type=="hex_route_cancelled":
			_clear_route(order)
			if order.status!="canceled":order.status="active"
		_refresh_arrival(id,order)

func _clear_route(order:Dictionary)->void:
	order.path=[]
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
		if order.status!="arrived":_clear_route(order)
		order.status="arrived"
		order.reason=""

func get_readout(id:String)->Dictionary:
	if not _orders.has(id):return {}
	var order:Dictionary=_orders[id]
	return {"command_id":order.command_id,"source_command_id":order.source_command_id,"goal_grid":order.goal_grid,"status":order.status,"reason":order.reason,"navigation_jobs":order.navigation_jobs,"wait_ticks":order.wait_ticks,"cached_route_nodes":order.path.size(),"navigation_pending":order.search!=null}

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
	_audit={"tick":now,"navigation_slices":0,"navigation_jobs_created":0,"navigation_expansions":0,"reservation_requests":0,"accepted_steps":0,"plan_calls":0,"timing_edge_reads":0}
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
		if order.status in ["arrived","canceled"]:continue
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
	for id in snapshot.units_by_id:
		if not _orders.has(id) or _orders[id].status in ["arrived","canceled","blocked","waiting_speed"]:blockers[snapshot.units_by_id[id].grid]=true
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
		if not _registry.call("is_walkable",order.goal_grid):
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
				order.search=PATHFINDER.RegionalHexSearch.new(state.grid,order.goal_grid,revision,options,_registry)
				order.navigation_jobs+=1
				_audit.navigation_jobs_created+=1
			var allowance:int=mini(24,MAX_NAV_EXPANSIONS-expansions)
			expansions+=order.search.advance(_pathfinder,_registry,allowance)
			_audit.navigation_expansions=expansions
			order.last_nav_tick=now
			if not order.search.finished:
				order.status="path_pending";order.reason="navigation_pending";continue
			if order.search.path.is_empty() or order.search.path.back()!=order.goal_grid:
				order.search=null;order.status="blocked";order.reason="unreachable_target";continue
			order.path=order.search.path.duplicate()
			order.cursor=0
			order.search=null
			_prepare_route_timing(order,factor,delta)
		if int(order.cursor)>=order.path.size() or order.path[int(order.cursor)]!=state.grid:
			_clear_route(order);order.status="active";continue
		if requests.size()>=MAX_PLAN_REQUESTS:order.status="waiting_reservation";order.reason="reservation_budget";continue
		var tail:Array=order.path.slice(int(order.cursor))
		if tail.size()<2:
			_refresh_arrival(id,order)
			continue
		# Only the next three durations bind; later values remain provisional.
		# Refresh the binding prefix from cached terrain times/current profile.
		for i in range(mini(3,tail.size()-1)):
			var index:int=int(order.cursor)+i
			order.duration_estimates[index]=maxi(1,ceili(float(order.base_step_seconds[index])/(factor*delta)))
		var durations:Array=order.duration_estimates.slice(int(order.cursor))
		requests.append({"unit_id":id,"command_id":order.command_id,"priority":int(order.command.get("priority",0)),"wait_ticks":order.wait_ticks,"path_grid_points":tail,"duration_ticks_by_step":durations})
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
					if accepted.has(request.unit_id):order.status="active";order.reason="";order.wait_ticks=0
					else:
						order.status="waiting_reservation";order.reason=plan.reason if not String(plan.reason).is_empty() else "reserved"
						for blocked in plan.blocked:
							if blocked.unit_id==request.unit_id:order.reason=blocked.reason
						order.wait_ticks=mini(int(order.wait_ticks)+1,1000000000000)
						order.last_attempt_epoch=_traffic_epoch;order.next_attempt_tick=now+4
	_face_active_segments()

func _prepare_route_timing(order:Dictionary,factor:float,delta:float)->void:
	order.base_step_seconds=[]
	order.duration_estimates=[]
	var spacing:float=_registry.call("get_movement_distance",_registry.call("grid_to_world",Vector2i.ZERO),_registry.call("grid_to_world",Vector2i.RIGHT))
	var source=_registry.call("get_tile_at_grid",order.path[0])
	var source_factor:float=TILE.get_surface_speed_factor(source.surface_type) if source!=null else 1.0
	for i in range(order.path.size()-1):
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
