extends RefCounted
## Explicit authored warehouse axes, bounded by the real module/door Hex union.
## No tile relocation or gameplay mutation takes place in this projection.
const HEX=preload("res://scripts/terrain/hex_grid.gd")
var _meshes:Dictionary={}
var build_count:=0
var _map:WeakRef
var _layout:Dictionary={}
var _regions:Array[Dictionary]=[]
var context_read_count:=0

static func supports(type_id:String)->bool:
	return type_id.begins_with("station_set_wall") or type_id.begins_with("station_set_door") or type_id.begins_with("spacekit_pipe_")

func configure(map)->void:
	_map=weakref(map) if map!=null else null
	_layout=map.get_place_presentation().get("station_module_layout",{}) if map!=null else {}
	_regions.clear()
	if _layout.get("schema","")=="warehouse_axes_v1":
		for region in _layout.get("regions",[]):
			if region is Dictionary:_regions.append(region)
		if _regions.is_empty():_regions.append(_layout)
	context_read_count+=1

func context(map,type_id:String,cell:Vector2i)->Dictionary:
	if map==null or not supports(type_id):return {}
	if _map==null or _map.get_ref()!=map:configure(map)
	var layout:Dictionary=layout_for_cell(cell,type_id)
	if layout.is_empty():return {}
	var anchor:int=int(layout.get("row_anchor",0))
	var transition:Array=layout.get("pipe_transition_cell",[])
	var result:Dictionary={"offset_x":0.25 if posmod(cell.y-anchor,2)==0 else -0.25,"transition":type_id=="spacekit_pipe_straight" and transition.size()==2 and cell==Vector2i(int(transition[0]),int(transition[1]))}
	if type_id=="station_set_wall_corner":
		var joins:Dictionary={}
		var center:Vector2=_module_center(cell,anchor)
		for offset:Vector2i in HEX.DIRECTIONS:
			var adjacent=map.get_tile_at_grid(cell+offset)
			if adjacent==null or not String(adjacent.object_type_id).begins_with("station_set_wall"):continue
			var direction:Vector2=(_module_center(cell+offset,anchor)-center).normalized()
			if absf(direction.x)>0.99:joins["east" if direction.x>0 else "west"]=true
			if absf(direction.y)>0.99:joins["south" if direction.y>0 else "north"]=true
		# Source L connects +X/-Z; its arms sit at X=-.25 and Z=+.25.
		if joins.has("east") and joins.has("north"):result.rotation=0.0
		elif joins.has("west") and joins.has("north"):result.rotation=90.0
		elif joins.has("west") and joins.has("south"):result.rotation=180.0
		elif joins.has("east") and joins.has("south"):result.rotation=270.0
		if result.has("rotation"):result.corner_centering=Vector3(0.25,0,-0.25)
	elif type_id.begins_with("station_set_wall") or type_id.begins_with("station_set_door"):
		# A one-metre source was scaled to .9m; restore continuous row pitch
		# inside the already validated physical union, keeping a 2mm seam.
		result.span_scale=0.998/0.9
		if type_id.begins_with("station_set_door"):
			var tile=map.get_tile_at_grid(cell)
			var best_distance:=INF
			for offset:Vector2i in HEX.DIRECTIONS:
				var adjacent=map.get_tile_at_grid(cell+offset)
				if adjacent==null or tile==null or adjacent.height_level!=tile.height_level or not String(adjacent.object_type_id).begins_with("station_set_wall_door"):continue
				var delta:Vector2=_module_center(cell+offset,anchor)-_module_center(cell,anchor)
				if delta.length_squared()<best_distance:
					best_distance=delta.length_squared();result.anchor_delta=delta
					result.rotation=float(adjacent.object_rotation_degrees)
					result.frame_cell=cell+offset
	return result

func layout_for_cell(cell:Vector2i,type_id:String="")->Dictionary:
	# Explicit per-ensemble source regions are cached once with the map. Only
	# the content owner relocates cells; this read never invents a second map.
	for layout:Dictionary in _regions:
		var region:Array=layout.get("source_region",[])
		if region.size()!=4:continue
		var anchor:int=int(layout.get("row_anchor",0))
		var source:=Vector2i(cell.x+floori(float(cell.y-anchor)*0.5),cell.y)
		var rect:=Rect2i(int(region[0]),int(region[1]),int(region[2]),int(region[3]))
		if rect.has_point(source):return layout
		if type_id.begins_with("spacekit_pipe_"):
			for entry:Array in layout.get("pipe_extension_cells",[]):
				if entry.size()==2 and cell==Vector2i(int(entry[0]),int(entry[1])):return layout
	return {}

func floor_bounds(map,cell:Vector2i,cell_size:float)->Rect2:
	if map==null:return Rect2()
	if _map==null or _map.get_ref()!=map:configure(map)
	var layout:Dictionary=layout_for_cell(cell)
	var boundary:Array=layout.get("floor_boundary",[])
	if boundary.size()!=4:return Rect2()
	var anchor:float=float(layout.get("row_anchor",0))
	# The content permutation and alternating quarter-cell projection map
	# source columns exactly to X=q+anchor/2+.25, independent of row parity.
	var minimum:=Vector2(float(boundary[0])+anchor*0.5+0.25,float(boundary[1])*sqrt(3.0)*0.5)*cell_size
	var maximum:=Vector2(float(boundary[2])+anchor*0.5+0.25,float(boundary[3])*sqrt(3.0)*0.5)*cell_size
	return Rect2(minimum,maximum-minimum)

static func _module_center(cell:Vector2i,anchor:int)->Vector2:
	return HEX.axial_to_plane(Vector2(cell))+Vector2(0.25 if posmod(cell.y-anchor,2)==0 else -0.25,0)

static func transform(authored:Transform3D,spec:Dictionary,cell_size:float)->Transform3D:
	var projected:=authored
	if spec.has("rotation"):
		projected.basis=Basis(Vector3.UP,deg_to_rad(float(spec.rotation))).scaled(authored.basis.get_scale())
	if spec.has("span_scale"):
		projected.basis=Basis(projected.basis.x*float(spec.span_scale),projected.basis.y,projected.basis.z)
	# Compress only the authored row pitch; body axes remain exactly X/Y/Z.
	projected.basis=projected.basis.scaled(Vector3(1,1,sqrt(3.0)*0.5))
	projected.origin.x+=float(spec.offset_x)*cell_size
	if spec.has("anchor_delta"):
		projected.origin+=Vector3(spec.anchor_delta.x,0,spec.anchor_delta.y)*cell_size
	if bool(spec.transition):
		projected.basis=projected.basis.scaled(Vector3(1.25,1,1))
		projected.origin.x+=0.125*cell_size
	return projected

static func footprint_cells(map,cell:Vector2i)->Array[Vector2i]:
	var result:Array[Vector2i]=[Vector2i.ZERO]
	for offset:Vector2i in HEX.DIRECTIONS:
		var adjacent=map.get_tile_at_grid(cell+offset)
		if adjacent!=null and supports(String(adjacent.object_type_id)):
			result.append(offset)
	return result

func clip_model(model:Node3D,relative_root:Transform3D,cells:Array[Vector2i],cell_size:float)->void:
	_clip_nodes(model,relative_root,cells,cell_size)

func _clip_nodes(node:Node,parent:Transform3D,cells:Array[Vector2i],cell_size:float)->void:
	var frame:Transform3D=parent*node.transform if node is Node3D else parent
	if node is MeshInstance3D and node.mesh!=null:node.mesh=_clip_mesh(node.mesh,frame,cells,cell_size)
	for child in node.get_children():_clip_nodes(child,frame,cells,cell_size)

func _clip_mesh(source:Mesh,frame:Transform3D,cells:Array[Vector2i],cell_size:float)->Mesh:
	var key:String=str([source.get_instance_id(),frame,cells,cell_size])
	if _meshes.has(key):return _meshes[key]
	var result:=ArrayMesh.new()
	var inverse:Transform3D=frame.affine_inverse()
	for surface in range(source.get_surface_count()):
		var arrays:Array=source.surface_get_arrays(surface)
		var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		var uvs:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV]!=null else PackedVector2Array()
		var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR]!=null else PackedColorArray()
		var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var output_uv:=PackedVector2Array();var output_color:=PackedColorArray()
		var seen:Dictionary={}
		for index in range(0,(indices.size() if not indices.is_empty() else points.size())-2,3):
			var triangle:Array=[]
			for corner in range(3):
				var id:int=indices[index+corner] if not indices.is_empty() else index+corner
				triangle.append({"point":frame*points[id],"uv":uvs[id] if uvs.size()==points.size() else Vector2.ZERO,"color":colors[id] if colors.size()==points.size() else Color.WHITE})
			for cell:Vector2i in cells:
				var polygon:Array=triangle
				var center:Vector2=HEX.axial_to_plane(Vector2(cell))*cell_size
				for edge in range(6):polygon=_clip(polygon,Vector2.from_angle(edge*PI/3.0),center,cell_size*0.5)
				for fan in range(1,polygon.size()-1):
					var items:Array=[polygon[0],polygon[fan],polygon[fan+1]]
					var a:Vector3=inverse*items[0].point;var b:Vector3=inverse*items[1].point;var c:Vector3=inverse*items[2].point
					var normal:Vector3=(c-a).cross(b-a)
					if normal.length_squared()<0.00000001:continue
					var identity:Array=[str(a.snapped(Vector3.ONE*0.00001)),str(b.snapped(Vector3.ONE*0.00001)),str(c.snapped(Vector3.ONE*0.00001))];identity.sort()
					if seen.has(str(identity)):continue
					seen[str(identity)]=true
					for item:Dictionary in items:
						vertices.append(inverse*item.point);normals.append(normal.normalized());output_uv.append(item.uv);output_color.append(item.color)
		if vertices.is_empty():continue
		var output:Array=[];output.resize(Mesh.ARRAY_MAX)
		output[Mesh.ARRAY_VERTEX]=vertices;output[Mesh.ARRAY_NORMAL]=normals
		if not uvs.is_empty():output[Mesh.ARRAY_TEX_UV]=output_uv
		if not colors.is_empty():output[Mesh.ARRAY_COLOR]=output_color
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,output)
		result.surface_set_material(result.get_surface_count()-1,source.surface_get_material(surface))
	_meshes[key]=result;build_count+=1
	return result

func _clip(polygon:Array,normal:Vector2,center:Vector2,radius:float)->Array:
	if polygon.is_empty():return []
	var output:Array=[]
	var previous:Dictionary=polygon.back()
	var prior:float=radius-normal.dot(Vector2(previous.point.x,previous.point.z)-center)
	for item:Dictionary in polygon:
		var distance:float=radius-normal.dot(Vector2(item.point.x,item.point.z)-center)
		if (distance>=-0.000001)!=(prior>=-0.000001):
			var fraction:float=prior/(prior-distance)
			output.append({"point":Vector3(previous.point).lerp(item.point,fraction),"uv":Vector2(previous.uv).lerp(item.uv,fraction),"color":Color(previous.color).lerp(item.color,fraction)})
		if distance>=-0.000001:output.append(item)
		previous=item;prior=distance
	return output
