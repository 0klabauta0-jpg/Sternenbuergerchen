extends RefCounted
## Approved fractured sandstone direction. Static render triangles only.
## The four boundary edges stay exactly on the owning terrain face. Interior
## facets recess into its volume; no new stand, collision, LOS or RNG owner.

## detail=true (Grafikpass R3, small maps only): a broken ledge at mid-height,
## a recessed upper block, a bulging lower block and more talus. Ten triangles
## per face instead of four; the four boundary edges still stay on the face.
static func append_face(surface:SurfaceTool,a:Vector3,b:Vector3,base_a:Vector3,base_b:Vector3,seed:int,cell_size:float=1.0,rubble:bool=true,detail:bool=false)->int:
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
	if detail:
		return _detailed_face(surface,a,b,base_a,base_b,outward,tangent.normalized(),height,key,cell_size,rubble)
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

static func _detailed_face(surface:SurfaceTool,a:Vector3,b:Vector3,base_a:Vector3,base_b:Vector3,outward:Vector3,tangent:Vector3,height:float,key:int,cell_size:float,rubble:bool)->int:
	# Pure functions of the cell/edge key: stable across rebuilds and chunks.
	var r0:float=float(key%97)/96.0
	var r1:float=float((key/97)%89)/88.0
	var r2:float=float((key/8633)%83)/82.0
	var r3:float=float((key/716539)%79)/78.0
	# Ledge line: both ends slide along their own boundary edge only.
	var left:Vector3=a.lerp(base_a,0.34+r0*0.26)
	var right:Vector3=b.lerp(base_b,0.34+r1*0.26)
	var ledge:Vector3=left.lerp(right,0.35+r2*0.3)+outward*cell_size*(0.05+r3*0.07)+Vector3.UP*height*(r0-0.5)*0.08
	var upper:Vector3=a.lerp(b,0.3+r1*0.4).lerp(ledge,0.5)-outward*cell_size*(0.06+r2*0.07)
	var lower:Vector3=base_a.lerp(base_b,0.3+r3*0.4).lerp(ledge,0.45)+outward*cell_size*(0.03+r0*0.06)
	var triangles:=0
	var top:Array[Vector3]=[a,left,ledge,right,b]
	for index in range(top.size()):
		triangles+=_triangle(surface,top[index],top[(index+1)%top.size()],upper)
	var bottom:Array[Vector3]=[left,base_a,base_b,right,ledge]
	for index in range(bottom.size()):
		triangles+=_triangle(surface,bottom[index],bottom[(index+1)%bottom.size()],lower)
	if rubble and key%3==0:
		var foot:Vector3=base_a.lerp(base_b,0.2+r2*0.6)
		triangles+=_rubble(surface,foot+outward*cell_size*(0.07+r1*0.06),tangent,outward,cell_size*(0.07+r3*0.07))
		if key%2==0:
			triangles+=_rubble(surface,foot+outward*cell_size*0.2+tangent*cell_size*(r0-0.5)*0.3,tangent,outward,cell_size*(0.04+r2*0.04))
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
