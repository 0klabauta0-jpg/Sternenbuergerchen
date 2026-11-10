extends Node
## Bounded location owner attached to the mission SimulationRoot. UI reads snapshots.
const LOS = preload("res://scripts/core/los_system.gd")
var _mission: Node
var _adapter: Node
var _controller: Node
var _registry: Node
var _terrain: Node
var _location_id := ""
var _definitions: Dictionary = {}
var _stock: RefCounted
var _sites: Dictionary:
	get: return _stock.get_snapshot() if _stock != null else {}
var _visuals: Dictionary = {}
var last_use_diagnostic: Dictionary = {}
var _active: Dictionary = {}
var _pending: Dictionary = {}
var _positions: Dictionary = {}
var _los = LOS.new()
var _clock := 0.0
var _revision := 0
var _message := ""

func configure(mission: Node, runtime_adapter: Node, location_id: String, restored: Dictionary = {}) -> Dictionary:
	_mission=mission
	_adapter=runtime_adapter
	_location_id=location_id
	_controller=mission.get_node_or_null("TacticalController")
	_registry=mission.get_node_or_null("UnitRegistry")
	_terrain=mission.get_node_or_null("TerrainRegistry")
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/location_resources.json"))
	if typeof(raw)!=TYPE_DICTIONARY or _controller==null or _registry==null or _terrain==null:
		return {"ok":false,"reason":"resource_runtime_unavailable"}
	_definitions=Dictionary(raw.get(location_id,{})).duplicate(true)
	_stock = _adapter.call("get_location_resource_stock", location_id)
	if _stock == null: return {"ok":false,"reason":"resource_stock_unavailable"}
	_positions={}
	for id in _definitions:
		var entry: Dictionary=_definitions[id]
		var grid: Array=entry.grid
		_positions[id]=_terrain.call("grid_to_world",Vector2i(int(grid[0]),int(grid[1])))
	if not restored.is_empty():
		var result:=_restore(restored)
		if not result.ok: return result
	var simulation:=mission.get_node_or_null("SimulationRoot")
	if simulation!=null and simulation.has_method("configure_location_resources"):
		simulation.call("configure_location_resources",self)
	set_process(not _definitions.is_empty())
	return {"ok":true}

func _process(delta: float) -> void:
	_clock+=delta
	if _clock<.2: return
	var elapsed:=_clock
	_clock=0.0
	advance(elapsed)

func advance(delta: float) -> void:
	if not is_finite(delta) or delta<=0.0: return
	var units:=_live_units()
	for id in _sites:
		if bool(_sites[id].discovered):
			_show_visual(id,_definitions[id])
			continue
		for unit: Node2D in units:
			if _in_reach(unit,id,float(_definitions[id].get("discovery_radius_world",384.0))):
				_stock.discover(id)
				_revision+=1
				break
		if bool(_sites[id].discovered): _show_visual(id,_definitions[id])
	if _active.is_empty(): return
	var worker: Node2D=_find_worker(String(_active.unit_id),units)
	var site_id:=String(_active.site_id)
	var guard:=_use_guard(site_id,worker)
	if not bool(guard.get("ok",false)):
		_active={}
		_pending={}
		_message="Abgebrochen: "+String(guard.get("message","Person nicht verfügbar"))
		_revision+=1
		return
	_active.elapsed=float(_active.elapsed)+delta
	_revision+=1
	if float(_active.elapsed)<float(_definitions[site_id].get("duration_seconds",4.0)): return
	var definition: Dictionary=_definitions[site_id]
	_pending={"completion_id":"resource:"+_location_id+":"+site_id,"location_id":_location_id,
		"site_id":site_id,"unit_id":String(_active.unit_id),"item_id":String(definition.item_id),"quantity":int(_sites[site_id].remaining)}
	var result: Dictionary=_adapter.call("grant_resource_result",self,_pending.duplicate(true)) if _adapter.has_method("grant_resource_result") else {"ok":false,"message":"Ertragsowner nicht bereit"}
	if bool(result.get("ok",false)):
		_stock.consume(site_id)
		_message="Eingesammelt: %d × %s" % [int(_pending.quantity),String(definition.get("name",definition.item_id))]
	else:
		_message=String(result.get("message","Kein Platz im Rucksack; Quelle bleibt erhalten"))
	_pending={}
	_active={}

func request_use(site_id: String, unit_id: String = "") -> Dictionary:
	var simulation:=_mission.get_node_or_null("SimulationRoot")
	if simulation==null or not simulation.has_method("request_location_resource_command"):
		return {"ok":false,"reason":"resource_authority_unavailable","message":"Ressourcenowner nicht bereit"}
	return simulation.call("request_location_resource_command","start_use",{"site_id":site_id,"unit_id":unit_id})

func request_move_to(site_id: String) -> Dictionary:
	if not _sites.has(site_id) or not bool(_sites[site_id].discovered): return {"ok":false,"reason":"unknown_site"}
	var accepted: bool=_controller.call("issue_ad_hoc_order","move",_positions[site_id])
	return {"ok":accepted,"message":"Bewegungsbefehl an ausgewählten Trupp" if accepted else "Zuerst einen verfügbaren Trupp auswählen"}

func apply_operation(operation: String, payload: Dictionary) -> Dictionary:
	if operation=="cancel_use":
		_active={}
		_pending={}
		_revision+=1
		return {"ok":true}
	if operation!="start_use": return {"ok":false,"reason":"unknown_operation"}
	if not _active.is_empty(): return {"ok":false,"reason":"resource_busy","message":"Bergung läuft bereits"}
	var id:=String(payload.get("site_id",""))
	var requested:=String(payload.get("unit_id",""))
	var units:=_live_units()
	var worker: Node2D=_find_worker(requested,units)
	if requested.is_empty():
		for unit: Node2D in units:
			if _use_guard(id,unit).get("ok",false): worker=unit; break
	var guard:=_use_guard(id,worker)
	if not bool(guard.get("ok",false)): return guard
	_active={"site_id":id,"unit_id":String(worker.call("get_unit_id")),"elapsed":0.0}
	_message="Bergung läuft; Person muss am Vorkommen bleiben"
	_revision+=1
	return {"ok":true}

func _use_guard(site_id: String, worker: Node2D) -> Dictionary:
	if not _sites.has(site_id) or not bool(_sites[site_id].discovered): return _reject("unknown_site","Vorkommen noch nicht entdeckt")
	if int(_sites[site_id].remaining)<=0: return _reject("depleted","Vorkommen ist erschöpft")
	if worker==null: return _reject("worker_unavailable","Keine einsatzfähige Person am Boden")
	var definition: Dictionary=_definitions[site_id]
	if not _in_reach(worker,site_id,float(definition.get("radius_world",96.0))): return _reject("out_of_range","Person zum Vorkommen bewegen")
	var id:=String(worker.call("get_unit_id"))
	var snapshot: Dictionary=_adapter.call("get_snapshot")
	var container: Dictionary=Dictionary(Dictionary(snapshot.get("supply",{})).get("inventory",{})).get("unit:"+id+":backpack",{})
	if int(Dictionary(container.get("items",{})).get(String(definition.required_tool),0))<=0:
		return _reject("missing_tool","Passendes Werkzeug muss im persönlichen Rucksack liegen")
	return {"ok":true}

func _live_units() -> Array:
	var result: Array=[]
	if not is_instance_valid(_registry) or not is_instance_valid(_controller): return result
	var deployed: Dictionary=_controller.get("_deployed_unit_ids")
	var team:=String(_controller.call("get_local_command_team_id"))
	for unit in Array(_registry.call("get_all_units")):
		if not is_instance_valid(unit) or not unit is Node2D or not unit.has_method("get_unit_id") or not unit.has_method("get_team_id"): continue
		var id:=String(unit.call("get_unit_id"))
		if not deployed.has(id) or String(unit.call("get_team_id"))!=team or bool(unit.get_meta("dropship_embarked",false)): continue
		if not unit.has_method("get_health") or int(unit.call("get_health"))<=0: continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state"))!="fit": continue
		result.append(unit)
	return result

func _find_worker(unit_id: String, units: Array) -> Node2D:
	for unit in units:
		if String(unit.call("get_unit_id"))==unit_id: return unit
	return null

func _in_reach(unit: Node2D, site_id: String, radius: float) -> bool:
	return _los.has_line_of_sight_between_points(unit.global_position,_positions[site_id],radius,_terrain)

func get_pending_receipt() -> Dictionary:
	if _pending.is_empty() or _active.is_empty(): return {}
	var worker:=_find_worker(String(_active.unit_id),_live_units())
	return _pending.duplicate(true) if _use_guard(String(_active.site_id),worker).get("ok",false) else {}

func get_snapshot() -> Dictionary:
	var visible: Array=[]
	for id in _sites:
		if not bool(_sites[id].discovered): continue
		var entry: Dictionary=_definitions[id].duplicate(true)
		entry.merge({"site_id":String(id),"remaining":int(_sites[id].remaining),"world_position":_positions[id]},true)
		visible.append(entry)
	return {"location_id":_location_id,"sites":visible,"active_use":_active.duplicate(true),"message":_message,"revision":_revision}

func export_state() -> Dictionary:
	return {"version":1,"location_id":_location_id,"sites":_stock.export_state()}

func _restore(state: Dictionary) -> Dictionary:
	if state.get("version")!=1 or state.get("location_id")!=_location_id or typeof(state.get("sites"))!=TYPE_DICTIONARY or state.sites.size()!=_sites.size(): return _reject("invalid_resource_state","Ortsressourcen passen nicht zur Karte")
	for id in _sites:
		var entry: Variant=state.sites.get(id)
		if typeof(entry)!=TYPE_DICTIONARY or typeof(entry.get("discovered"))!=TYPE_BOOL or typeof(entry.get("remaining")) not in [TYPE_INT,TYPE_FLOAT]: return _reject("invalid_resource_state","Ressourcenstand ungültig")
		var amount:=float(entry.remaining)
		if not is_finite(amount) or amount!=floor(amount) or amount<0 or amount>int(_definitions[id].quantity): return _reject("invalid_resource_state","Ressourcenmenge ungültig")
	if not _stock.restore_state(state.sites): return _reject("invalid_resource_state","Ressourcenstand ungültig")
	return {"ok":true}

func _reject(reason: String, message: String) -> Dictionary:
	return {"ok":false,"reason":reason,"message":message}

func project_bindings(snapshot: Dictionary) -> Dictionary:
	if _stock==null: return snapshot
	var result:=snapshot.duplicate(true)
	for id in _stock.get_snapshot():
		var site: Dictionary=_stock.get_site_snapshot(id)
		if not site.discovered: continue
		var selected: PackedStringArray=_controller.get("_selected_fireteam_ids")
		var gate:=_candidate(site,String(selected[0]) if not selected.is_empty() else "",false)
		var complete:=int(site.remaining)==0
		result.bindings.append({"interaction_id":id,"interaction_type":"computer","display_name":site.name,"marker_position":_positions[id],"marker_id":"","required_order":"operate","required_team":"player","radius_world":site.radius_world,"duration_seconds":site.duration_seconds,"step_id":"","gate_id":"","status":"complete" if complete else ("available" if gate.get("ok",false) else "blocked"),"complete":complete,"blocked":not complete and not gate.get("ok",false),"blocked_reason":String(gate.get("message","")),"asset_hint":"resource_"+String(site.kind),"read_only":true})
	result.binding_count=result.bindings.size()
	return result
func _candidate(site: Dictionary, team: String, require_range: bool=true) -> Dictionary:
	var reason: Dictionary={"ok":false,"message":"Lokalen Trupp auswählen"}
	if team.is_empty(): return reason
	for unit: Node2D in _live_units():
		if String(_controller.call("_get_deployed_unit_fireteam_id",String(unit.call("get_unit_id")))) != team: continue
		if require_range and not _in_reach(unit,String(site.id),float(site.radius_world)): continue
		var gate: Dictionary=_adapter.call("preview_resource_collection",_location_id,String(site.id),String(unit.call("get_unit_id")))
		if gate.get("ok",false): gate.unit_id=String(unit.call("get_unit_id")); return gate
		reason=gate
	return reason

func accept_progress(payload: Dictionary, complete: bool) -> Dictionary:
	var id:=String(payload.get("interaction_id",""))
	var site: Dictionary=_stock.get_site_snapshot(id)
	if site.is_empty() or int(site.remaining)==0: return {"accepted":true}
	var gate:=_candidate(site,String(payload.get("fireteam_id","")))
	last_use_diagnostic={"payload":payload.duplicate(true),"gate":gate.duplicate(true)}
	if not gate.get("ok",false): return {"accepted":false,"complete":false,"reason":String(gate.get("message","Entnahme nicht möglich"))}
	if not complete: return {"accepted":true}
	if float(payload.get("hold_seconds",0))+0.001<float(site.duration_seconds): return {"accepted":false,"complete":false,"reason":"use_duration_incomplete"}
	var result: Dictionary=_adapter.call("collect_location_resource",self,_location_id,id,String(gate.unit_id))
	_revision+=1
	return {"accepted":bool(result.get("ok",false)),"complete":bool(result.get("ok",false)),"reason":String(result.get("message",""))}

func _show_visual(id: String, site: Dictionary) -> void:
	if _visuals.has(id): return
	var view: Node=_mission.get_node_or_null("Primary3DView")
	if view==null or view.get("_world_root")==null: return
	var node: Node3D=load("res://scripts/terrain/location_resource_visuals.gd").build(site)
	view.get("_world_root").add_child(node)
	node.position=view.call("_world_to_surface_3d_position",_positions[id],0.0)
	_visuals[id]=node
