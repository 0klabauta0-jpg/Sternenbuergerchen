extends RefCounted
## Approved fractured sandstone direction. Static render triangles only.
## The four boundary edges stay exactly on the owning terrain face. Interior
## facets recess into its volume; no new stand, collision, LOS or RNG owner.

static func append_face(surface:SurfaceTool,a:Vector3,b:Vector3,base_a:Vector3,base_b:Vector3,seed:int,cell_size:float=1.0,rubble:bool=true)->int:
	var height:float=maxf(a.y-base_a.y,b.y-base_b.y)
	var tangent:Vector3=Vector3(b.x-a.x,0.0,b.z-a.z)
	if height<=0.00001 or tangent.length()<0.00001:return 0
	var outward:Vector3=Vector3(tangent.z,0.0,-tangent.x).normalized()
	# Small steps have no legible interior fracture at tactical zoom. Keep their
	# exact silhouette with two triangles; reserve facets/rubble for steep faces.
	if height<cell_size*1.25:
		return _triangle(surface,a,base_a,base_b)+_triangle(surface,a,base_b,b)
	var depth:float=minf(cell_size*0.11,height*0.12)
	var key:int=absi(seed)
	var u:float=0.34+float(key%25)*0.01
	var rise:float=0.35+float((key/25)%31)*0.01
	var center:Vector3=base_a.lerp(base_b,u).lerp(a.lerp(b,u),rise)-outward*depth
	var boundary:Array[Vector3]=[a,base_a,base_b,b]
	var triangles:=0
	# Four broad fracture facets retain every outside edge. The former 3x2
	# subdivision used twelve triangles per face and overflowed the actual
	# 512x256 mission resource cache. No per-frame tessellation or terrain edits.
	for edge in range(4):
		triangles+=_triangle(surface,boundary[edge],boundary[(edge+1)%4],center)
	if rubble and height>=cell_size*0.4 and key%11==0:
		var foot:Vector3=base_a.lerp(base_b,0.32+float(key%33)*0.01)
		triangles+=_rubble(surface,foot+outward*cell_size*0.025,tangent.normalized(),outward,cell_size*0.055)
	return triangles

static func _rubble(surface:SurfaceTool,center:Vector3,tangent:Vector3,outward:Vector3,radius:float)->int:
	var ring:Array[Vector3]=[center+tangent*radius,center+outward*radius*0.8,center-tangent*radius*0.75,center-outward*radius*0.55]
	var top:Vector3=center+Vector3.UP*radius*0.85+tangent*radius*0.12
	var triangles:=0
	for edge in range(4):triangles+=_triangle(surface,ring[(edge+1)%4],ring[edge],top)
	return triangles

static func _triangle(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->int:
	var normal:Vector3=(c-a).cross(b-a)
	if normal.length_squared()<0.00000001:return 0
	surface.set_normal(normal.normalized())
	surface.add_vertex(a);surface.add_vertex(b);surface.add_vertex(c)
	return 1
