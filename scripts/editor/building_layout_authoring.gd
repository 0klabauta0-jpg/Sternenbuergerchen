extends RefCounted
## Cold authoring transactions on MapData. No UI or live-simulation ownership.
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const CATALOG_PATH := "res://data/frontier_building_visual_catalog.json"
const FIELDS := ["type_id","object_type_id","walkable","blocks_los","cover_value","height_level","surface_type","edge_type","object_height","object_rotation_degrees","object_scale"]
static var _catalog: Dictionary = {}

static func catalog() -> Dictionary:
	if _catalog.is_empty(): _catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	return _catalog

static func supported(asset_id: String) -> bool:
	return catalog().has(asset_id)

static func fields(tile) -> Dictionary:
	var result: Dictionary = {}
	for key in FIELDS: result[key] = tile.get(key)
	return result

static func set_fields(tile, values: Dictionary) -> void:
	for key in FIELDS:
		if values.has(key): tile.set(key, values[key])

static func key_at(grid: Vector2i) -> String:
	return "%d,%d" % [grid.x,grid.y]

static func grid_at(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]),int(parts[1]))

static func plane(map, grid: Vector2i) -> Vector2:
	return HEX.axial_to_plane(Vector2(grid)) if map.get_grid_topology() == HEX.TOPOLOGY_ID else Vector2(grid)

static func hull(prop: Dictionary) -> PackedVector2Array:
	var entry: Dictionary = catalog().get(String(prop.get("asset_id","")),{})
	if entry.is_empty(): return PackedVector2Array()
	var lo: Array = entry.min
	var hi: Array = entry.max
	var center: Array = prop.center
	var transform := Transform2D(-deg_to_rad(float(prop.get("rotation_degrees",0.0))),Vector2(float(center[0]),float(center[1])))
	var scale_value := float(prop.get("scale",1.0))
	var polygon := PackedVector2Array()
	for point in [Vector2(lo[0],lo[2]),Vector2(hi[0],lo[2]),Vector2(hi[0],hi[2]),Vector2(lo[0],hi[2])]:
		polygon.append(transform * (point * scale_value))
	return polygon

static func _area(polygon: PackedVector2Array) -> float:
	var sum := 0.0
	for i in range(polygon.size()): sum += polygon[i].cross(polygon[(i+1)%polygon.size()])
	return absf(sum)*.5

static func _intersects(a: PackedVector2Array,b: PackedVector2Array) -> bool:
	for polygon in Geometry2D.intersect_polygons(a,b):
		if _area(polygon) > .000001: return true
	return false

static func footprint(map, prop: Dictionary) -> Array:
	var polygon := hull(prop)
	var minimum := Vector2(INF,INF)
	var maximum := Vector2(-INF,-INF)
	var hex: bool = map.get_grid_topology()==HEX.TOPOLOGY_ID
	for point in polygon:
		var axial: Vector2 = HEX.plane_to_axial(point) if hex else point
		minimum=minimum.min(axial); maximum=maximum.max(axial)
	var result: Array=[]
	for x in range(floori(minimum.x)-1,ceili(maximum.x)+2):
		for y in range(floori(minimum.y)-1,ceili(maximum.y)+2):
			var grid:=Vector2i(x,y)
			var center:=plane(map,grid)
			var tile_polygon: PackedVector2Array=HEX.corners(center) if hex else PackedVector2Array([center+Vector2(-.5,-.5),center+Vector2(.5,-.5),center+Vector2(.5,.5),center+Vector2(-.5,.5)])
			if _intersects(polygon,tile_polygon): result.append([x,y])
	return result

static func id_at_grid(map, grid: Vector2i) -> String:
	if map==null: return ""
	var best := ""
	var distance := INF
	var point:=plane(map,grid)
	for prop in Array(map.get_place_presentation().get("props",[])):
		if not supported(String(prop.get("asset_id",""))): continue
		var contains:=false
		for cell in Array(prop.get("reserved_grids",[])):
			if Vector2i(int(cell[0]),int(cell[1]))==grid: contains=true; break
		if not contains: continue
		var center: Array=prop.center
		var next: float=point.distance_squared_to(Vector2(center[0],center[1]))
		if next<distance: distance=next; best=String(prop.get("building_id",""))
	return best

static func _error(message: String) -> Dictionary:
	return {"ok":false,"error":message}

static func _occupied(props: Array) -> Dictionary:
	var cells: Dictionary={}
	for prop in props:
		if not supported(String(prop.get("asset_id",""))): continue
		for cell in Array(prop.get("reserved_grids",[])): cells[key_at(Vector2i(cell[0],cell[1]))]=true
	return cells

static func _world_grid(map, world: Vector2) -> Vector2i:
	var size: Dictionary=map.get_tile_size()
	var offset: Vector2=world-map.get_grid_origin()
	var axial:=Vector2((offset.x/float(size.half_width)+offset.y/float(size.half_height))*.5,(offset.y/float(size.half_height)-offset.x/float(size.half_width))*.5)
	return HEX.round_axial(HEX.plane_to_axial(axial)) if map.get_grid_topology()==HEX.TOPOLOGY_ID else Vector2i(roundi(axial.x),roundi(axial.y))

static func _protected_points(map) -> Dictionary:
	var result: Dictionary={}
	for id in map.get_marker_ids():
		var grid:=_world_grid(map,map.get_marker_position(id))
		var tile=map.get_tile_at_grid(grid)
		if tile!=null and tile.walkable: result[key_at(grid)]=true
	for points in map.get_patrol_paths().values():
		for point in points: result[key_at(_world_grid(map,Vector2(point)))]=true
	return result

static func plan(map, action: String, payload: Dictionary) -> Dictionary:
	if map==null: return _error("Keine Karte geladen.")
	if map.has_authoring_metadata("homebase_exploration"): return _error("Basisraeume besitzen separate Feinnavigation und bleiben hier geschuetzt.")
	if not map.get_authored_visual_layout_id().is_empty(): return _error("Festes GM01-Ensemble bleibt geschuetzt.")
	var before: Dictionary=map.get_place_presentation()
	var after: Dictionary=before.duplicate(true)
	var props: Array=Array(after.get("props",[])).duplicate(true)
	var metadata: Dictionary=Dictionary(after.get("building_authoring",{})).duplicate(true)
	if not String(before.get("migration_id","")).is_empty() and int(metadata.get("schema_version",0))!=1: return _error("Alt-Layout besitzt noch keine sicheren Untergrunddaten.")
	var base: Dictionary=Dictionary(metadata.get("base_tiles",{})).duplicate(true)
	var old_cells:=_occupied(props)
	for prop in props:
		if supported(String(prop.get("asset_id",""))) and String(prop.get("building_id","")).is_empty(): return _error("Alt-Layout besitzt noch keine sicheren Untergrunddaten.")
	for key in old_cells:
		if not base.has(key): return _error("Untergrunddaten fehlen; Layout bleibt unveraendert.")
	var id: String=payload.get("building_id","")
	var index: int=-1
	for i in range(props.size()):
		if String(props[i].get("building_id",""))==id and not id.is_empty(): index=i; break
	var edited: Dictionary={}
	var affected: Dictionary={}
	if action=="place":
		var asset_id: String=payload.get("asset_id","")
		if not supported(asset_id): return _error("Unbekannte Gebaeudevorlage.")
		var next: int=int(metadata.get("next_id",1))
		id="building_%d"%next
		while props.any(func(p:Dictionary):return String(p.get("building_id",""))==id): next+=1; id="building_%d"%next
		metadata.next_id=next+1
		edited={"building_id":id,"asset_id":asset_id,"path":catalog()[asset_id].model_path,"scale":payload.get("scale",1.0),"rotation_degrees":payload.get("rotation_degrees",0.0)}
		props.append(edited); index=props.size()-1
	elif index<0: return _error("Kein Gebaeude ausgewaehlt.")
	else:
		edited=Dictionary(props[index]).duplicate(true)
		for cell in Array(edited.get("reserved_grids",[])): affected[key_at(Vector2i(cell[0],cell[1]))]=true
	if action not in ["place","move","rotate","remove"]: return _error("Unbekannte Gebaeudeaktion.")
	if action in ["place","move"]:
		var grid: Vector2i=payload.get("grid",Vector2i(-999,-999))
		var anchor=map.get_tile_at_grid(grid)
		if anchor==null: return _error("Gebaeude liegt ausserhalb der Karte.")
		var point:=plane(map,grid)
		edited.center=[point.x,point.y]
		edited.elevation=float(anchor.height_level)*.5
	if action=="rotate": edited.rotation_degrees=float(edited.get("rotation_degrees",0.0))+float(payload.get("delta_degrees",90.0))
	if action=="remove": props.remove_at(index)
	else:
		var scale_value:=float(edited.get("scale",1.0))
		var yaw:=float(edited.get("rotation_degrees",0.0))
		if not is_finite(scale_value) or scale_value<.25 or scale_value>2.5 or not is_finite(yaw): return _error("Ungueltiger Massstab oder Winkel.")
		edited.rotation_degrees=fposmod(yaw,360.0)
		edited.reserved_grids=footprint(map,edited)
		for cell in edited.reserved_grids: affected[key_at(Vector2i(cell[0],cell[1]))]=true
		for other in props:
			if String(other.get("building_id",""))!=id and supported(String(other.get("asset_id",""))) and _intersects(hull(edited),hull(other)): return _error("Gebaeude ueberlappt ein anderes Gebaeude.")
		var protected:=_protected_points(map)
		for cell in edited.reserved_grids:
			var grid:=Vector2i(cell[0],cell[1]); var key:=key_at(grid)
			var tile=map.get_tile_at_grid(grid)
			if tile==null: return _error("Gebaeude reicht ueber den Kartenrand.")
			var substrate: Dictionary=base.get(key,fields(tile))
			if not bool(substrate.walkable) or not String(substrate.object_type_id).is_empty() or String(substrate.surface_type)=="water": return _error("Gebaeude kollidiert mit Terrain oder einem Objekt.")
			if not is_equal_approx(float(substrate.height_level)*.5,float(edited.elevation)): return _error("Gebaeude braucht einen ebenen Untergrund.")
			if protected.has(key) and not old_cells.has(key): return _error("Gebaeude wuerde Marker oder Patrouille blockieren.")
		props[index]=edited
	var new_cells:=_occupied(props)
	var all_cells:=old_cells.duplicate(); all_cells.merge(new_cells)
	var new_base: Dictionary={}
	var changes: Array=[]
	var ordered: Array=all_cells.keys(); ordered.sort()
	for key in ordered:
		var grid:=grid_at(key); var tile=map.get_tile_at_grid(grid)
		var original: Dictionary=fields(tile)
		var substrate: Dictionary=Dictionary(base.get(key,original)).duplicate(true)
		var next: Dictionary=substrate.duplicate(true)
		if new_cells.has(key):
			new_base[key]=substrate
			var height_class:=0
			for prop in props:
				if not supported(String(prop.get("asset_id",""))): continue
				for cell in Array(prop.get("reserved_grids",[])):
					if Vector2i(int(cell[0]),int(cell[1]))==grid:
						height_class=maxi(height_class,mini(3,ceili(float(catalog()[prop.asset_id].max[1])*float(prop.get("scale",1.0))/.42)))
			next.merge({"object_type_id":"frontier_scene_solid","walkable":false,"blocks_los":true,"cover_value":80,"object_height":height_class,"object_rotation_degrees":0.0,"object_scale":1.0},true)
		if not affected.has(key): continue
		changes.append({"grid":grid,"before":original,"after":next})
	metadata.schema_version=1; metadata.base_tiles=new_base
	after.props=props; after.building_authoring=metadata
	return {"ok":true,"building_id":id,"changes":changes,"before":before,"after":after}

static func apply(map, transaction: Dictionary) -> void:
	if not bool(transaction.get("ok",false)): return
	for change in transaction.changes: set_fields(map.get_tile_at_grid(change.grid),change.after)
	map.set_place_presentation(transaction.after)
