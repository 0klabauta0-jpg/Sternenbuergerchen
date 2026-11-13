extends RefCounted
## Only cell-owned floor meshes use this projection. Split at the original
## rectangle corners and target hex corners, then map each wedge affinely.
## User-directed candidate: thin light metal, not thick white hex buttons.
## Original source meshes/textures stay immutable; only derived floors change.
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const PROFILE_HEIGHT := 0.028
const METAL_TINT := Color("b3b8b5")
var _cache: Dictionary = {}
var _material_cache: Dictionary = {}
var _texture_cache: Dictionary = {}
var _source_vertical_cache:Dictionary={}
var build_count := 0
var material_build_count := 0

static func profile_height(cell_size:float)->float:
	return PROFILE_HEIGHT*cell_size

static func supports(type_id: String) -> bool:
	return type_id == "station_floor_panel" or type_id.begins_with("station_set_floor") or type_id.begins_with("station_set_balcony_floor") or type_id.begins_with("modular_floor") or type_id == "factory_floor"

func adapt_model(model: Node3D, basis: Basis, bounds: Dictionary, cell_size: float) -> void:
	if not bool(bounds.get("valid",false)): return
	var size: Vector3 = Vector3(bounds.max) - Vector3(bounds.min)
	if size.x <= 0.0001 or size.z <= 0.0001: return
	var vertical:Vector2=source_vertical(model)*basis.y.length()
	_adapt_nodes(model,Transform3D.IDENTITY,basis,Vector2(size.x,size.z),cell_size,vertical)

func source_vertical(model:Node3D)->Vector2:
	# Imported render AABBs may pad a zero-thickness plane. Geometry, rather
	# than that conservative culling box, defines the projected floor surface.
	var key:String=str([model.scene_file_path,model.transform]) if not model.scene_file_path.is_empty() else str(model.get_instance_id())
	if _source_vertical_cache.has(key):return _source_vertical_cache[key]
	var result:Vector2=_vertex_vertical(model,Transform3D.IDENTITY)
	_source_vertical_cache[key]=result
	return result

func _vertex_vertical(node:Node,parent:Transform3D)->Vector2:
	var frame:Transform3D=parent*node.transform if node is Node3D else parent
	var result:=Vector2(INF,-INF)
	if node is MeshInstance3D and node.mesh!=null:
		for surface in range(node.mesh.get_surface_count()):
			for point:Vector3 in node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var height:float=(frame*point).y
				result.x=minf(result.x,height);result.y=maxf(result.y,height)
	for child in node.get_children():
		var child_range:Vector2=_vertex_vertical(child,frame)
		result.x=minf(result.x,child_range.x);result.y=maxf(result.y,child_range.y)
	return result

func _adapt_nodes(node: Node, parent: Transform3D, basis: Basis, size: Vector2, cell_size: float, vertical:Vector2) -> void:
	var transform: Transform3D = parent * node.transform if node is Node3D else parent
	if node is MeshInstance3D and node.mesh != null:
		node.mesh = adapt_mesh(node.mesh,Transform3D(basis,Vector3.ZERO)*transform,basis,size,cell_size,vertical)
	for child in node.get_children(): _adapt_nodes(child,transform,basis,size,cell_size,vertical)

func adapt_mesh(source: Mesh, transform: Transform3D, basis: Basis, size: Vector2, cell_size: float, vertical:Vector2) -> Mesh:
	var key: String = str([source.get_instance_id(),transform,basis,size,cell_size,vertical])
	if _cache.has(key): return _cache[key]
	var wedges: Array = _wedges(basis,size,cell_size)
	if wedges.is_empty(): return source
	var result := ArrayMesh.new()
	var inverse: Transform3D = transform.affine_inverse()
	for surface in range(source.get_surface_count()):
		var arrays: Array = source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var out_vertices := PackedVector3Array()
		var out_normals := PackedVector3Array()
		var out_uvs := PackedVector2Array()
		var out_colors := PackedColorArray()
		var count: int = indices.size() if not indices.is_empty() else vertices.size()
		for index in range(0,count-2,3):
			var triangle: Array = []
			for corner in range(3):
				var id: int = indices[index+corner] if not indices.is_empty() else index+corner
				triangle.append({"point":transform*vertices[id],"uv":uvs[id] if uvs.size()==vertices.size() else Vector2.ZERO,"color":colors[id] if colors.size()==vertices.size() else Color.WHITE})
			for wedge: Dictionary in wedges:
				var polygon: Array = _clip(_clip(triangle,wedge.a,true),wedge.b,false)
				if polygon.size()<3: continue
				for corner in range(1,polygon.size()-1):
					var mapped: Array[Vector3] = []
					for point: Dictionary in [polygon[0],polygon[corner],polygon[corner+1]]:
						var flat := Vector2(point.point.x,point.point.z)
						var coefficients: Vector2 = wedge.inverse * flat
						var warped: Vector2 = wedge.target * coefficients
						# The modular/factory source floors are horizontal planes, not
						# volumes. Place that real surface on the shared top, rather
						# than dividing its numerical epsilon into a buried height.
						var fraction:float=1.0 if vertical.y-vertical.x<0.00001 else clampf((float(point.point.y)-vertical.x)/(vertical.y-vertical.x),0.0,1.0)
						var height:float=fraction*profile_height(cell_size)
						mapped.append(inverse*Vector3(warped.x,height,warped.y))
					var normal: Vector3 = (mapped[2]-mapped[0]).cross(mapped[1]-mapped[0])
					if normal.length_squared()<0.0000000001: continue
					for i in range(3):
						out_vertices.append(mapped[i]); out_normals.append(normal.normalized())
					out_uvs.append(polygon[0].uv);out_uvs.append(polygon[corner].uv);out_uvs.append(polygon[corner+1].uv)
					out_colors.append(polygon[0].color);out_colors.append(polygon[corner].color);out_colors.append(polygon[corner+1].color)
		if out_vertices.is_empty(): continue
		var output: Array = [];output.resize(Mesh.ARRAY_MAX)
		output[Mesh.ARRAY_VERTEX]=out_vertices;output[Mesh.ARRAY_NORMAL]=out_normals
		if not uvs.is_empty():output[Mesh.ARRAY_TEX_UV]=out_uvs
		if not colors.is_empty():output[Mesh.ARRAY_COLOR]=out_colors
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,output)
		result.surface_set_material(result.get_surface_count()-1,source.surface_get_material(surface))
	_cache[key]=result
	build_count+=1
	return result

func finish_material(source:Material)->Material:
	var standard:=source as StandardMaterial3D
	if standard==null:return source
	var key:int=source.get_instance_id()
	if _material_cache.has(key):return _material_cache[key]
	var material:StandardMaterial3D=standard.duplicate(false)
	material.albedo_color=standard.albedo_color*METAL_TINT
	material.albedo_texture=_quiet_floor_texture(standard.albedo_texture)
	material.metallic=0.16
	material.roughness=0.9
	_material_cache[key]=material
	material_build_count+=1
	return material

func _quiet_floor_texture(source:Texture2D)->Texture2D:
	if source==null:return null
	var key:int=source.get_instance_id()
	if _texture_cache.has(key):return _texture_cache[key]
	var pixels:Image=source.get_image()
	if pixels==null or pixels.is_empty():return source
	var had_mipmaps:bool=pixels.has_mipmaps()
	pixels=pixels.duplicate()
	if pixels.is_compressed() and pixels.decompress()!=OK:return source
	pixels.convert(Image.FORMAT_RGBA8)
	# Keep the existing UV/color-map layout, but its internal rings must not
	# compete with the actual tactical Hex outline. The source stays immutable.
	for y in range(pixels.get_height()):
		for x in range(pixels.get_width()):
			var original:Color=pixels.get_pixel(x,y)
			var quiet:Color=original.lerp(Color(0.92,0.93,0.90,original.a),0.88)
			pixels.set_pixel(x,y,quiet)
	if had_mipmaps:pixels.generate_mipmaps()
	var texture:=ImageTexture.create_from_image(pixels)
	_texture_cache[key]=texture
	return texture

func finish_model(node:Node)->void:
	if node is MeshInstance3D and node.mesh!=null:
		# This route only receives the derived 28mm floor skin. It still receives
		# real wall/cliff shadows; casting that skin caused the native stripe bug.
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if node.material_override!=null:node.material_override=finish_material(node.material_override)
		else:
			for surface in range(node.mesh.get_surface_count()):
				node.set_surface_override_material(surface,finish_material(node.get_active_material(surface)))
	for child in node.get_children():finish_model(child)

func _wedges(basis: Basis,size: Vector2,cell_size: float) -> Array:
	var x: Vector3=basis*Vector3(size.x*0.5,0,0)
	var z: Vector3=basis*Vector3(0,0,size.y*0.5)
	var rectangle:=Transform2D(Vector2(x.x,x.z),Vector2(z.x,z.z),Vector2.ZERO)
	if absf(rectangle.determinant())<0.000001:return []
	var inverse:Transform2D=rectangle.affine_inverse()
	# One authored floor tile owns one Hex cell. A tiny seam avoids coplanar
	# shared faces while the original material/frame detail covers the field.
	var fill:float=0.995
	var angles:Array[float]=[]
	for point:Vector2 in HEX.corners():angles.append(fposmod(point.angle(),TAU))
	for corner:Vector2 in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
		var angle:float=fposmod((rectangle*corner).angle(),TAU)
		var duplicate:=false
		for existing in angles:
			if absf(angle-existing)<0.00001:duplicate=true
		if not duplicate:angles.append(angle)
	angles.sort()
	var result:Array=[]
	for index in range(angles.size()):
		var a:=Vector2.from_angle(angles[index]);var b:=Vector2.from_angle(angles[(index+1)%angles.size()])
		var qa:Vector2=inverse*a;var qb:Vector2=inverse*b
		var sa:Vector2=a/maxf(absf(qa.x),absf(qa.y));var sb:Vector2=b/maxf(absf(qb.x),absf(qb.y))
		var ta:Vector2=a*_hex_radius(a,cell_size*fill);var tb:Vector2=b*_hex_radius(b,cell_size*fill)
		result.append({"a":a,"b":b,"inverse":Transform2D(sa,sb,Vector2.ZERO).affine_inverse(),"target":Transform2D(ta,tb,Vector2.ZERO)})
	return result

func _hex_radius(direction:Vector2,diameter:float)->float:
	var projection:=0.0
	for index in range(6):projection=maxf(projection,direction.dot(Vector2.from_angle(index*PI/3.0)))
	return diameter*0.5/projection

func _clip(polygon:Array,ray:Vector2,keep_left:bool)->Array:
	if polygon.is_empty():return []
	var result:Array=[]
	var previous:Dictionary=polygon.back()
	var previous_distance:float=ray.cross(Vector2(previous.point.x,previous.point.z))*(1.0 if keep_left else -1.0)
	for current:Dictionary in polygon:
		var distance:float=ray.cross(Vector2(current.point.x,current.point.z))*(1.0 if keep_left else -1.0)
		if (distance>=-0.000001)!=(previous_distance>=-0.000001):
			var fraction:float=previous_distance/(previous_distance-distance)
			result.append({"point":Vector3(previous.point).lerp(current.point,fraction),"uv":Vector2(previous.uv).lerp(current.uv,fraction),"color":Color(previous.color).lerp(current.color,fraction)})
		if distance>=-0.000001:result.append(current)
		previous=current;previous_distance=distance
	return result
