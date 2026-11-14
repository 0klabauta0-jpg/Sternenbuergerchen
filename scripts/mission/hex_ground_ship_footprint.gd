class_name HexGroundShipFootprint
extends RefCounted

## Derived local raster only. Existing landing owner retains position/profile.
const PROFILE=preload("res://scripts/mission/polisa_ground_body_profile.gd")
const BODY=preload("res://scripts/mission/polisa_station_craft_runtime.gd")
const HEX=preload("res://scripts/terrain/hex_grid.gd")
const MAX_CANDIDATES:=4096
const MAX_GRID_COORDINATE:=2147480000.0
const EPSILON:=0.000001

func cells_for_body(registry:Node,craft:Dictionary,position:Vector2,profile:Dictionary,max_candidates:int=4096)->Dictionary:
	if not is_instance_valid(registry) or not registry.has_method("get_grid_topology") or registry.call("get_grid_topology")!="hex_axial_v1":return _reject("invalid_footprint_registry")
	for method in ["grid_to_world","world_to_grid_float","get_tile_at_grid"]:
		if not registry.has_method(method):return _reject("invalid_footprint_registry")
	var checked:Dictionary=PROFILE.read_bound(craft,profile)
	if not checked.ok:return _reject(String(checked.reason))
	var body:Dictionary=BODY.projected_body(position,checked.profile)
	if not body.ok:return _reject(String(body.reason))
	var rect:Rect2=body.footprint
	if not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x<=0.0 or rect.size.y<=0.0:return _reject("invalid_body_projection")
	var polygon:PackedVector2Array=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var minimum:=Vector2(INF,INF)
	var maximum:=Vector2(-INF,-INF)
	for point in polygon:
		var world:=Vector2(64.0*(point.x-point.y),32.0*(point.x+point.y))
		var axial:Vector2=registry.call("world_to_grid_float",world)
		if not axial.is_finite() or absf(axial.x)>MAX_GRID_COORDINATE or absf(axial.y)>MAX_GRID_COORDINATE:return _reject("footprint_coordinate_range")
		minimum=minimum.min(axial)
		maximum=maximum.max(axial)
	var low_q:int=ceili(minimum.x)-1
	var low_r:int=ceili(minimum.y)-1
	var high_q:int=floori(maximum.x)+1
	var high_r:int=floori(maximum.y)+1
	var width:int=high_q-low_q+1
	var height:int=high_r-low_r+1
	var budget:int=mini(MAX_CANDIDATES,max_candidates)
	if budget<1 or width<1 or height<1 or width>budget or height>budget or width*height>budget:return _reject("footprint_budget")
	var origin:Vector2=registry.call("grid_to_world",Vector2i.ZERO)
	var basis_q:Vector2=Vector2(registry.call("grid_to_world",Vector2i(1,0)))-origin
	var basis_r:Vector2=Vector2(registry.call("grid_to_world",Vector2i(0,1)))-origin
	if not origin.is_finite() or not basis_q.is_finite() or not basis_r.is_finite() or is_zero_approx(basis_q.cross(basis_r)):return _reject("invalid_footprint_metric")
	var offsets:=PackedVector2Array()
	for corner in HEX.corners():
		var axial:Vector2=HEX.plane_to_axial(corner)
		offsets.append(BODY.iso_to_plane(basis_q*axial.x+basis_r*axial.y))
	var axes:Array[Vector2]=[Vector2.RIGHT,Vector2.DOWN]
	for i in range(3):
		var edge:Vector2=offsets[i+1]-offsets[i]
		axes.append(Vector2(-edge.y,edge.x).normalized())
	# SAT projections of both convex shapes; only the center offset varies per cell.
	var intervals:Array[Dictionary]=[]
	for axis in axes:
		var shape_min:=INF
		var shape_max:=-INF
		var cell_min:=INF
		var cell_max:=-INF
		for point in polygon:shape_min=minf(shape_min,axis.dot(point));shape_max=maxf(shape_max,axis.dot(point))
		for point in offsets:cell_min=minf(cell_min,axis.dot(point));cell_max=maxf(cell_max,axis.dot(point))
		intervals.append({"axis":axis,"shape_min":shape_min,"shape_max":shape_max,"cell_min":cell_min,"cell_max":cell_max})
	var blocked:Array[Vector2i]=[]
	var examined:=0
	for q in range(low_q,high_q+1):
		for r in range(low_r,high_r+1):
			examined+=1
			var grid:=Vector2i(q,r)
			var center:Vector2=BODY.iso_to_plane(registry.call("grid_to_world",grid))
			var overlaps:=true
			for interval in intervals:
				var shift:float=interval.axis.dot(center)
				if shift+float(interval.cell_max)<float(interval.shape_min)-EPSILON or shift+float(interval.cell_min)>float(interval.shape_max)+EPSILON:overlaps=false;break
			if overlaps:
				if registry.call("get_tile_at_grid",grid)==null:return _reject("footprint_outside_map")
				blocked.append(grid)
	return {"ok":true,"blocked_cells":blocked,"examined":examined,"reason":""}

func _reject(reason:String)->Dictionary:
	var cells:Array[Vector2i]=[]
	return {"ok":false,"blocked_cells":cells,"examined":0,"reason":reason}
