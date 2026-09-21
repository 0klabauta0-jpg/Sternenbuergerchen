extends RefCounted
const Heights=preload("res://scripts/core/terrain_layout.gd")
const Geo=preload("res://scripts/world/world_geometry.gd")
## Project legacy authored geometry onto the same surface as navigation.
static func lift(node:Node3D,region:String) -> void:
 for child:Node in node.get_children():
  if not child is Node3D:continue
  var at:Vector3=child.position
  if child is MeshInstance3D and child.mesh is ArrayMesh:
   var mesh:=ArrayMesh.new()
   for i in child.mesh.get_surface_count():
    var arrays:Array=child.mesh.surface_get_arrays(i)
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    for j in vertices.size():vertices[j].y+=Heights.height_at(region,Vector2(vertices[j].x+at.x,vertices[j].z+at.z))
    arrays[Mesh.ARRAY_VERTEX]=vertices
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   child.mesh=mesh
  elif absf(at.x)+absf(at.z)>0.001 or child is MeshInstance3D or child is Label3D:
   child.position.y+=Heights.height_at(region,Vector2(at.x,at.z))
  elif child is StaticBody3D:
   for shape:Node in child.get_children():
    if shape is Node3D:shape.position.y+=Heights.height_at(region,Vector2(shape.position.x,shape.position.z))
  else:lift(child,region)
static func build(parent:Node3D,region:String,color:Color) -> void:
 var patches:Array=Heights.patches(region)
 if patches.is_empty():return
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var prior:Array=[]
 for patch:Dictionary in patches:
  var polygon:PackedVector2Array=Heights.outline(patch)
  var base:=0.0
  for previous:Dictionary in prior:
   if Geometry2D.is_point_in_polygon((patch.rect as Rect2).get_center(),Heights.outline(previous)):base+=float(previous.rise)
  prior.append(patch)
  var top:float=base+patch.rise
  _top_surface(st,polygon,top,color)
  var levels:=maxi(3,ceili(float(patch.rise)/0.8))
  var center:Vector2=(patch.rect as Rect2).get_center()
  # Broken ledges and wider erosion seams retain the exact navigable upper rim.
  for edge in polygon.size():
   var a:Vector2=polygon[edge];var b:Vector2=polygon[(edge+1)%polygon.size()]
   var divisions:=maxi(1,ceili(a.distance_to(b)/7.0))
   for section in divisions:
    var pa:=a.lerp(b,float(section)/divisions);var pb:=a.lerp(b,float(section+1)/divisions)
    for layer in levels:
     var low:=lerpf(base,top,float(layer)/levels);var high:=lerpf(base,top,float(layer+1)/levels)
     var inset:=0.30+0.25*sin(edge*3.1+section*1.7+layer*2.3)
     var ia:Vector2=(center-pa).normalized()*inset
     var ib:Vector2=(center-pb).normalized()*inset
     var aa:=Vector3(pa.x+ia.x,low,pa.y+ia.y);var bb:=Vector3(pb.x+ib.x,low,pb.y+ib.y)
     var cc:=Vector3(pa.x,high-0.12,pa.y);var dd:=Vector3(pb.x,high-0.12,pb.y)
     var cap_a:=Vector3(pa.x,high,pa.y);var cap_b:=Vector3(pb.x,high,pb.y)
     var tint:=color.darkened(0.10+0.045*sin(edge*2.4+section*1.3+layer*1.9))
     for v:Vector3 in [aa,bb,cc,bb,dd,cc]:st.set_color(tint);st.add_vertex(v)
     for v:Vector3 in [cc,dd,cap_a,dd,cap_b,cap_a]:st.set_color(color.darkened(0.27));st.add_vertex(v)
  var ramp:Rect2=patch.ramp
  # Continuous broad ramp, with stratified banks narrowing naturally at its foot.
  var a:=Vector3(ramp.position.x,top,ramp.position.y);var b:=Vector3(ramp.end.x,top,ramp.position.y)
  var c:=Vector3(ramp.position.x,base,ramp.end.y);var d:=Vector3(ramp.end.x,base,ramp.end.y)
  for v:Vector3 in [a,b,c,b,d,c]:st.set_color(color.lightened(0.025));st.add_vertex(v)
  for layer in levels:
   var t0:=float(layer)/levels;var t1:=float(layer+1)/levels
   for side:int in [0,1]:
    var upper:Vector3=a if side==0 else b;var lower:Vector3=c if side==0 else d
    var p0:Vector3=lower.lerp(upper,t0);var p1:Vector3=lower.lerp(upper,t1)
    var q0:=Vector3(upper.x,p0.y,upper.z);var q1:=Vector3(upper.x,p1.y,upper.z)
    for v:Vector3 in [p0,q0,p1,q0,q1,p1]:st.set_color(color.darkened(0.12 if layer%2==0 else 0.20));st.add_vertex(v)
 st.generate_normals()
 var node:=MeshInstance3D.new();node.name="TerracedLandscape";node.mesh=st.commit()
 var mat:=Geo.material(Color.WHITE);mat.vertex_color_use_as_albedo=true;mat.vertex_color_is_srgb=true;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;node.material_override=mat;parent.add_child(node)

static func _top_surface(st:SurfaceTool,polygon:PackedVector2Array,height:float,color:Color) -> void:
 var bounds:=Rect2(polygon[0],Vector2.ZERO)
 for point:Vector2 in polygon:bounds=bounds.expand(point)
 for x in range(floori(bounds.position.x/10)*10,ceili(bounds.end.x),10):
  for z in range(floori(bounds.position.y/10)*10,ceili(bounds.end.y),10):
   var tile:=PackedVector2Array([Vector2(x,z),Vector2(x+10,z),Vector2(x+10,z+10),Vector2(x,z+10)])
   for clipped:PackedVector2Array in Geometry2D.intersect_polygons(polygon,tile):
    var indices:=Geometry2D.triangulate_polygon(clipped)
    var shade:=0.012*sin(x*0.71+z*0.19)
    for i in indices.size():
     var p:Vector2=clipped[indices[i]]
     st.set_color(color.lightened(shade));st.add_vertex(Vector3(p.x,height,p.y))
