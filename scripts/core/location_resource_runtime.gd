extends Node
## Local authoritative use bridge. Resource stock stays in long-lived Supply.
var _supply: RefCounted
var _location: String
var _owner: RefCounted
var _controller: Node
var _terrain: Node
var _elapsed:=0.0
var _visuals: Dictionary={}
var last_use_diagnostic: Dictionary={}
func configure(supply: RefCounted, location_id: String) -> void:
	_supply=supply; _location=location_id; _owner=supply.get_location_resources(location_id)
	_controller=get_parent().get_node("TacticalController"); _terrain=get_parent().get_node("TerrainRegistry")
	set_process(_owner!=null)
func _process(delta: float) -> void:
	_elapsed+=delta
	if _elapsed<.25: return
	_elapsed=0.0
	if _owner==null: return
	for id in _owner.get_snapshot():
		var site: Dictionary=_owner.get_site_snapshot(id)
		if not site.discovered:
			for unit in _local_units():
				if unit.position.distance_to(_position(site))>float(site.discovery_radius_world): continue
				var line: Array=_terrain.get_grid_line(_terrain.world_to_grid(unit.position),Vector2i(site.grid[0],site.grid[1]))
				var visible:=true
				for index in range(1,line.size()-1):
					if _terrain.blocks_los_at_grid(line[index]): visible=false; break
				if visible: _owner.discover(id); break
		if _owner.get_site_snapshot(id).discovered: _show_visual(id,site)
func _local_units(team: String="") -> Array:
	var units: Array=[]
	for id in Dictionary(_controller.get("_deployed_unit_ids")):
		var unit: Node=_controller.call("_find_friendly_unit_by_id",String(id))
		if unit==null or (unit.has_method("get_vital_state") and unit.get_vital_state()!="fit"): continue
		if not team.is_empty() and String(_controller.call("_get_deployed_unit_fireteam_id",String(id)))!=team: continue
		units.append(unit)
	return units
func _position(site: Dictionary) -> Vector2:
	return _terrain.grid_to_world(Vector2i(site.grid[0],site.grid[1]))
func project_bindings(snapshot: Dictionary) -> Dictionary:
	if _owner==null: return snapshot
	var result:=snapshot.duplicate(true)
	for id in _owner.get_snapshot():
		var site: Dictionary=_owner.get_site_snapshot(id)
		if not site.discovered: continue
		var selected: PackedStringArray=_controller.get("_selected_fireteam_ids")
		var gate:=_candidate(site,String(selected[0]) if not selected.is_empty() else "",false)
		var complete:=int(site.remaining)==0
		result.bindings.append({"interaction_id":id,"interaction_type":"computer","display_name":site.name,"marker_position":_position(site),"marker_id":"","required_order":"operate","required_team":"player","radius_world":site.radius_world,"duration_seconds":site.duration_seconds,"step_id":"","gate_id":"","status":"complete" if complete else ("available" if gate.get("ok",false) else "blocked"),"complete":complete,"blocked":not complete and not gate.get("ok",false),"blocked_reason":String(gate.get("message","")),"asset_hint":"resource_"+String(site.kind),"read_only":true})
	result.binding_count=result.bindings.size()
	return result
func _candidate(site: Dictionary,team: String,require_range: bool=true) -> Dictionary:
	var reason: Dictionary={"ok":false,"message":"Lokalen Trupp auswählen"}
	if team.is_empty(): return reason
	for unit in _local_units(team):
		if require_range and unit.position.distance_to(_position(site))>float(site.radius_world): continue
		var gate: Dictionary=_supply.preview_resource_collection(_location,String(site.id),String(unit.get_unit_id()))
		if gate.get("ok",false): gate.unit_id=String(unit.get_unit_id()); return gate
		reason=gate
	return reason
func accept_progress(payload: Dictionary,complete: bool) -> Dictionary:
	if _owner==null: return {"accepted":true}
	var id:=String(payload.get("interaction_id","")); var site: Dictionary=_owner.get_site_snapshot(id)
	if site.is_empty(): return {"accepted":true}
	if site.remaining==0: return {"accepted":true}
	var gate:=_candidate(site,String(payload.get("fireteam_id","")))
	last_use_diagnostic={"payload":payload.duplicate(true),"gate":gate.duplicate(true)}
	if not gate.get("ok",false): return {"accepted":false,"complete":false,"reason":String(gate.get("message","Entnahme nicht möglich"))}
	if not complete: return {"accepted":true}
	if float(payload.get("hold_seconds",0))+0.001<float(site.duration_seconds): return {"accepted":false,"complete":false,"reason":"use_duration_incomplete"}
	var command: Dictionary=load("res://scripts/mission/singleplayer_supply_command_contract.gd").build_command("collect_resource",{"unit_id":gate.unit_id,"location_id":_location,"site_id":id},"resource:"+_location+":"+id)
	var result: Dictionary=_supply.apply_command(command,{"resource_authorized":true,"unit_id":gate.unit_id,"location_id":_location,"use_complete":true,"within_radius":true})
	return {"accepted":bool(result.get("ok",false)),"complete":bool(result.get("ok",false)),"reason":String(result.get("message",""))}
func _show_visual(id: String,site: Dictionary) -> void:
	if _visuals.has(id): return
	var view: Node=get_parent().get_node_or_null("Primary3DView")
	if view==null or view.get("_world_root")==null: return
	var node: Node3D=load("res://scripts/terrain/location_resource_visuals.gd").build(site)
	view.get("_world_root").add_child(node)
	node.position=view.call("_world_to_surface_3d_position",_position(site),0.0)
	_visuals[id]=node
