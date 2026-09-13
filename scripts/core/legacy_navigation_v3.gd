extends RefCounted
const Catalog=preload("res://scripts/core/legacy_catalog_v3.gd")
const CLEARANCE: float=0.6
static func walkable(region: String,point: Vector2) -> bool:
	if absf(point.x)>Catalog.bounds(region) or absf(point.y)>Catalog.bounds(region):return false
	if region=="bunker_depths" and not (Rect2(-7.3,-47.3,14.6,94.6).has_point(point) or Rect2(-39.3,-23.3,78.6,46.6).has_point(point)):return false
	for spec: Dictionary in Catalog.obstacles(region).values():
		if _rect(spec).has_point(point):return false
	return true
static func path(region: String,from: Vector2,to: Vector2) -> Array:
	if not walkable(region,to):return []
	if clear(region,from,to):return [to]
	var nodes: Array[Vector2]=[from,to]
	for spec: Dictionary in Catalog.obstacles(region).values():
		var rect: Rect2=_rect(spec).grow(0.08)
		for corner: Vector2 in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
			if walkable(region,corner):nodes.append(corner)
	# Door-centre waypoints prevent a shortest route crossing the underground void.
	if region=="bunker_depths":nodes.append(Vector2.ZERO);nodes.append(Vector2(-10,0));nodes.append(Vector2(10,0))
	var distances: Array=[];var previous: Array=[];var visited: Array=[]
	for index in nodes.size():distances.append(INF);previous.append(-1);visited.append(false)
	distances[0]=0.0
	for iteration in nodes.size():
		var chosen: int=-1
		for index in nodes.size():
			if not visited[index] and (chosen<0 or distances[index]<distances[chosen]):chosen=index
		if chosen<0 or is_inf(distances[chosen]):return []
		if chosen==1:break
		visited[chosen]=true
		for index in nodes.size():
			if visited[index] or index==chosen or not clear(region,nodes[chosen],nodes[index]):continue
			var cost: float=distances[chosen]+nodes[chosen].distance_to(nodes[index])
			if cost<distances[index]:distances[index]=cost;previous[index]=chosen
	if previous[1]<0:return []
	var result: Array=[];var cursor: int=1
	while cursor!=0:result.push_front(nodes[cursor]);cursor=previous[cursor]
	return result
static func clear(region: String,from: Vector2,to: Vector2) -> bool:
	# Segment/AABB slab test: no tunnelling even with long point-click commands.
	for spec: Dictionary in Catalog.obstacles(region).values():
		if _intersects(from,to,_rect(spec)):return false
	if region=="bunker_depths":
		for index in range(1,17):
			if not walkable(region,from.lerp(to,float(index)/16.0)):return false
	return true
static func _rect(spec: Dictionary) -> Rect2:
	var size:=Vector2(spec.size[0],spec.size[1])
	return Rect2(Vector2(spec.center[0],spec.center[1])-size*0.5,size).grow(CLEARANCE)
static func _intersects(a: Vector2,b: Vector2,rect: Rect2) -> bool:
	var low: float=0.0;var high: float=1.0;var delta:=b-a
	for axis in 2:
		if absf(delta[axis])<0.00001:
			if a[axis]<rect.position[axis] or a[axis]>rect.end[axis]:return false
		else:
			var t1: float=(rect.position[axis]-a[axis])/delta[axis]
			var t2: float=(rect.end[axis]-a[axis])/delta[axis]
			low=maxf(low,minf(t1,t2));high=minf(high,maxf(t1,t2))
			if low>high:return false
	return true
