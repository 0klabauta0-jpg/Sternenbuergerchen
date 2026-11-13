extends SceneTree
const VIEW=preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const HEX=preload("res://scripts/terrain/hex_grid.gd")
const FRACTURE=preload("res://scripts/terrain/regional_cliff_fracture.gd")
const TILE=preload("res://scripts/terrain/terrain_tile_data.gd")
var passed:=0
var failed:=0
func _initialize()->void:call_deferred("run")
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print(("PASS " if value else "FAIL ")+label)

func face(seed:int,rubble:bool=false,sloped:bool=false)->ArrayMesh:
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	FRACTURE.append_face(tool,Vector3(0,2,0),Vector3(1,1.2 if sloped else 2,0),Vector3.ZERO,Vector3(1,0,0),seed,1.0,rubble)
	return tool.commit()

func run()->void:
	for step_height:float in [0.25,0.5,0.75,1.0,1.24]:
		var step_surface:=SurfaceTool.new();step_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var count:int=FRACTURE.append_face(step_surface,Vector3(0,step_height,0),Vector3(1,step_height,0),Vector3.ZERO,Vector3(1,0,0),11,1.0,true)
		var step_mesh:ArrayMesh=step_surface.commit()
		check(count==2 and step_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()==6,"small terrain steps retain two triangles without unreadable fracture/rubble detail "+str(step_height))
		var expected_corners:Array[Vector3]=[Vector3.ZERO,Vector3(1,0,0),Vector3(0,step_height,0),Vector3(1,step_height,0)]
		var actual_corners:Dictionary={};var exact_geometry:=true
		for point:Vector3 in step_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			exact_geometry=exact_geometry and expected_corners.has(point)
			actual_corners[point]=true
		print("SMALL_CLIFF_BOUNDS height=%s engine_aabb=%s"%[step_height,step_mesh.get_aabb()])
		check(exact_geometry and actual_corners.size()==4,"small step contains exactly the four authoritative corners without extending its face "+str(step_height))
	for seed in [0,11,27,793,3719]:
		for slope in [false,true]:
			var mesh:ArrayMesh=face(seed,false,slope)
			var arrays:Array=mesh.surface_get_arrays(0)
			var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			check(positions.size()<=12,"each fractured cliff face has at most four triangles for the bounded map cache")
			var valid:=true;var recess:=false;var corners:Dictionary={}
			for point in positions:
				valid=valid and point.is_finite() and point.x>=-0.00001 and point.x<=1.00001 and point.y>=-0.00001 and point.y<=2.00001 and point.z>=-0.00001 and point.z<=0.111
				recess=recess or point.z>0.02
				for corner:Vector3 in [Vector3.ZERO,Vector3(1,0,0),Vector3(0,2,0),Vector3(1,1.2 if slope else 2,0)]:
					if point.is_equal_approx(corner):corners[str(corner)]=true
			check(valid and recess and corners.size()==4,"fracture retains original bounds/corners and recesses into volume "+str([seed,slope]))
			var normals_ok:=true
			for normal in arrays[Mesh.ARRAY_NORMAL]:normals_ok=normals_ok and normal.is_finite() and is_equal_approx(normal.length(),1.0) and normal.z<0.0
			check(normals_ok,"fracture normals face outward without degenerate triangles "+str([seed,slope]))
			check(var_to_bytes(arrays)==var_to_bytes(face(seed,false,slope).surface_get_arrays(0)),"fracture is coordinate deterministic "+str([seed,slope]))
	check(var_to_bytes(face(11).surface_get_arrays(0))!=var_to_bytes(face(27).surface_get_arrays(0)),"neighboring cliff faces do not repeat one identical break")
	var rubble_mesh:ArrayMesh=face(11,true)
	check(rubble_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()==24,"selected face uses four fracture and four small foot-rubble triangles")
	check(rubble_mesh.get_aabb().position.y>=-0.00001 and rubble_mesh.get_aabb().position.z>=-0.07,"foot rubble stays on ground within seven centimetres of cliff")
	var view=VIEW.new();var models:=Node3D.new();view.add_child(models);view.set("_map_root",models);view.set("_active_grid_topology","hex_axial_v1")
	var terrain=MAP.create_empty("fracture-owner",Vector2i(3,3),Vector2.ZERO,64,32,3,"hex_axial_v1")
	terrain.get_tile_at_grid(Vector2i(1,1)).height_level=2
	var terrain_before:PackedByteArray=var_to_bytes(terrain.get_tiles().map(func(tile):return tile.to_dict()))
	view.set("_regional_height_step",0.75);view.set("_frontier_art_enabled",true)
	view.call("_rebuild_render_tile_index",terrain.get_tiles());view.call("_add_regional_cliff_faces",terrain.get_tiles())
	var cliff:MeshInstance3D=models.get_node_or_null("RegionalCliffFaces")
	check(cliff!=null and cliff.mesh.get_surface_count()==1 and cliff.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()>36,"actual regional producer batches fractured height faces into one material surface")
	check(cliff!=null and cliff.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,"actual height silhouette retains its cliff shadow caster")
	check(var_to_bytes(terrain.get_tiles().map(func(tile):return tile.to_dict()))==terrain_before,"fractured geometry does not change authoritative height/ramp/tile records")
	for child in models.get_children():child.free()
	view.set("_regional_height_step",0.0)
	for map_id:String in ["station_outpost_64x64","station_outpost_192x192"]:
		var map=MAP.load_from_file("res://maps/"+map_id+".json");view.set("_terrain_map_data",map)
		var before:PackedByteArray=var_to_bytes(map.get_tiles().map(func(tile):return tile.to_dict()))
		var west:Array[float]=[];var east:Array[float]=[];var count:=0
		var source_shift:int=64 if map_id.ends_with("192x192") else 0
		for tile in map.get_tiles():
			var kind:String=tile.object_type_id
			var spec:Dictionary=view.get("_station_module_projection").context(map,kind,tile.grid_position)
			if spec.is_empty():continue
			check(view.call("_add_asset_model_visual",tile,float(tile.height_level)*0.5,kind,true),"real authored warehouse module "+map_id+" "+str(tile.grid_position))
			var model:Node3D=models.get_child(models.get_child_count()-1)
			var axis:Vector3=model.basis.x.normalized()
			check(absf(axis.x)<0.00001 or absf(axis.z)<0.00001,"module body shares actual warehouse World-X/Z axes "+str(tile.grid_position))
			var vertices:Array[Vector3]=[];collect(model,Transform3D.IDENTITY,vertices)
			var inside:=not vertices.is_empty()
			for point in vertices:
				inside=inside and within_authored_union(point,tile,map)
			check(inside,"actual imported module stays inside real blocked/door Hex union "+str(tile.grid_position))
			var source_q:int=tile.grid_position.x+floori(float(tile.grid_position.y-(31+source_shift))*0.5)
			if kind=="station_set_wall" and source_q==24+source_shift:west.append(model.position.x)
			if kind=="station_set_wall" and source_q==39+source_shift:east.append(model.position.x)
			var builds:int=view.get("_station_module_projection").build_count
			view.call("_add_asset_model_visual",tile,float(tile.height_level)*0.5,kind,true)
			check(view.get("_station_module_projection").build_count==builds,"identical authored module reuses clipped source mesh")
			models.get_child(models.get_child_count()-1).free();model.free();count+=1
		var authored_count:int=map.get_tiles().filter(func(tile):return String(tile.object_type_id).begins_with("station_set_wall") or String(tile.object_type_id).begins_with("station_set_door")).size()
		check(count==authored_count and count==(684 if map_id.ends_with("192x192") else 76),"all actual wall/door ensembles, including eight outer regions, are bound after content migration "+map_id)
		check(not map.get_tiles().any(func(tile):return String(tile.object_type_id).begins_with("spacekit_pipe_")),"no removed pipe remains in the actual station visual route "+map_id)
		var read_count:int=view.get("_station_module_projection").context_read_count
		for index in range(1000):view.get("_station_module_projection").context(map,"station_set_wall",Vector2i(24,25))
		check(view.get("_station_module_projection").context_read_count==read_count,"1000 module reads retain one narrow authored layout projection "+map_id)
		check(west.size()>=8 and west.max()-west.min()<0.00001 and east.size()>=4 and east.max()-east.min()<0.00001,"both authored side walls are straight and parallel to warehouse "+map_id)
		check(var_to_bytes(map.get_tiles().map(func(tile):return tile.to_dict()))==before,"native module projection preserves every gameplay tile fact "+map_id)
	for map_id:String in ["satellite_crash_site","trade_outpost","fortified_outpost","Ground_Mission01_32x32","frontier_workyard_24x20","station_outpost_64x64","station_outpost_192x192","Ground_Mission02_128x128","polisa_station","homebase_frontier_exploration"]:
		var map=MAP.load_from_file("res://maps/"+map_id+".json");view.set("_terrain_map_data",map)
		var expected:bool=map_id not in ["Ground_Mission02_128x128","polisa_station","homebase_frontier_exploration"]
		check(view.call("_is_arid_terrain_visual_context")==expected,"actual map semantics select quiet arid palette "+map_id)
	var station=MAP.load_from_file("res://maps/station_outpost_64x64.json");view.set("_terrain_map_data",station)
	for cell:Vector2i in [Vector2i(19,20),Vector2i(20,21),Vector2i(21,19),Vector2i(57,19)]:
		var tile=station.get_tile_at_grid(cell)
		var original:PackedByteArray=var_to_bytes(tile.to_dict())
		check(view.call("_legacy_cliff_visual_kind",tile)=="rock_blocker","reported legacy cliff cell retains visible independent blocker "+str(cell))
		view.call("_add_tile_visual",tile)
		check(models.get_node_or_null("Asset_glut_sandstone_04_%d_%d"%[cell.x,cell.y])!=null and models.get_node_or_null("Asset_%s_%d_%d"%[tile.type_id,cell.x,cell.y])==null,"actual tile route replaces misleading Square cliff with bounded rock "+str(cell))
		check(var_to_bytes(tile.to_dict())==original,"legacy cliff projection preserves exact walk/LOS/cover/height facts "+str(cell))
		for child in models.get_children():child.free()
	check(view.call("_legacy_cliff_visual_kind",station.get_tile_at_grid(Vector2i(57,26)))=="keep","reported independently authored bush/height/cover case remains untouched")
	var ornament=TILE.new(station.get_tile_at_grid(Vector2i(19,20)).to_dict());ornament.walkable=true;ornament.blocks_los=false;ornament.cover_value=0
	check(view.call("_legacy_cliff_visual_kind",ornament)=="height_only","only functionless Square ornament yields entirely to real height faces")
	ornament.cover_value=25
	check(view.call("_legacy_cliff_visual_kind",ornament)=="rock_blocker","independent cover remains visible even on walkable ground")
	ornament.object_height=1
	check(view.call("_legacy_cliff_visual_kind",ornament)=="keep","explicit authored object height excludes terrain-only replacement")
	view.set("_active_grid_topology","square8")
	check(view.call("_legacy_cliff_visual_kind",station.get_tile_at_grid(Vector2i(19,20)))=="keep","legacy Square import preserves original cliff models")
	view.set("_active_grid_topology","hex_axial_v1");view.set("_terrain_map_data",MAP.load_from_file("res://maps/Ground_Mission02_128x128.json"))
	check(view.call("_legacy_cliff_visual_kind",station.get_tile_at_grid(Vector2i(19,20)))=="keep","nonarid biome excludes arid cliff replacement")
	view.free()
	print("REVIEW_CLIFF_STATION passed=%d failed=%d"%[passed,failed]);quit(1 if failed else 0)

func collect(node:Node,parent:Transform3D,points:Array[Vector3])->void:
	var frame:Transform3D=parent*node.transform if node is Node3D else parent
	if node is MeshInstance3D and node.mesh!=null:
		for surface in range(node.mesh.get_surface_count()):
			for point in node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:points.append(frame*point)
	for child in node.get_children():collect(child,frame,points)

func within_authored_union(point:Vector3,tile,map)->bool:
	var cells:Array[Vector2i]=[tile.grid_position]
	for offset in HEX.DIRECTIONS:
		var neighbor=map.get_tile_at_grid(tile.grid_position+offset)
		if neighbor!=null and (String(neighbor.object_type_id).begins_with("station_set_wall") or String(neighbor.object_type_id).begins_with("station_set_door") or String(neighbor.object_type_id).begins_with("spacekit_pipe_")):cells.append(neighbor.grid_position)
	for cell in cells:
		var delta:Vector2=Vector2(point.x,point.z)-HEX.axial_to_plane(Vector2(cell))
		var contained:=true
		for edge in range(6):contained=contained and delta.dot(Vector2.from_angle(edge*PI/3.0))<=0.5001
		if contained:return true
	return false
