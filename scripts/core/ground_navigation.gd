extends RefCounted
## Spatially indexed static obstacles and bounded grid A*. Routes live in SimulationRoot.
const Catalog=preload("res://scripts/core/catalog.gd")
const CLEARANCE: float=0.6
const BUCKET: float=16.0
const MAX_VISITS: int=24000
static var _indexes: Dictionary={}
static var searches: int=0
static func reset_cache() -> void:_indexes.clear()
static func _index(region: String) -> Dictionary:
	if _indexes.has(region):return _indexes[region]
	var data: Dictionary={"rects":[],"names":[],"buckets":{},"cells":{}}
	for name: String in Catalog.obstacles(region):
		var spec: Dictionary=Catalog.obstacles(region)[name]
		data.names.append(name)
		var rect: Rect2=_rect(spec)
		var id: int=data.rects.size();data.rects.append(rect)
		var low:=Vector2i(floori(rect.position.x/BUCKET),floori(rect.position.y/BUCKET))
		var high:=Vector2i(floori(rect.end.x/BUCKET),floori(rect.end.y/BUCKET))
		for x in range(low.x,high.x+1):
			for y in range(low.y,high.y+1):
				var key:=Vector2i(x,y)
				if not data.buckets.has(key):data.buckets[key]=[]
				data.buckets[key].append(id)
	_indexes[region]=data
	return data
static func _inside(region: String,p: Vector2) -> bool:
	var bound: float=Catalog.bounds(region)
	if absf(p.x)>bound or absf(p.y)>bound:return false
	if region=="bunker_depths" and not (Rect2(-7.3,-47.3,14.6,94.6).has_point(p) or Rect2(-39.3,-23.3,78.6,46.6).has_point(p)):return false
	return true
static func _ship_rect(region: String,ship: Dictionary) -> Rect2:
	if ship.is_empty() or ship.get("mode")!="landed" or region in ["space","orbit","bunker_depths"]:return Rect2()
	return _rect({"center":ship.position,"size":Catalog.ship_profile(ship.model).size})
static func walkable(region: String,point: Vector2,ship: Dictionary={}) -> bool:
	if not _inside(region,point):return false
	var index: Dictionary=_index(region)
	var bucket:=Vector2i(floori(point.x/BUCKET),floori(point.y/BUCKET))
	for id: int in index.buckets.get(bucket,[]):
		if index.rects[id].has_point(point):return false
	var hull: Rect2=_ship_rect(region,ship)
	return not hull.has_area() or not hull.has_point(point)
static func clear(region: String,a: Vector2,b: Vector2,ship: Dictionary={},ignore: String="") -> bool:
	if not _inside(region,a) or not _inside(region,b):return false
	var index: Dictionary=_index(region)
	var ids: Array=[]
	if a.distance_squared_to(b)>1024.0:
		for id in index.rects.size():ids.append(id)
	else:
		var low:=Vector2i(floori(minf(a.x,b.x)/BUCKET),floori(minf(a.y,b.y)/BUCKET))
		var high:=Vector2i(floori(maxf(a.x,b.x)/BUCKET),floori(maxf(a.y,b.y)/BUCKET))
		var seen: Dictionary={}
		for x in range(low.x,high.x+1):
			for y in range(low.y,high.y+1):
				for id: int in index.buckets.get(Vector2i(x,y),[]):seen[id]=true
		ids=seen.keys()
	for id: int in ids:
		if index.names[id]!=ignore and _intersects(a,b,index.rects[id]):return false
	var hull: Rect2=_ship_rect(region,ship)
	if hull.has_area() and _intersects(a,b,hull):return false
	if region=="bunker_depths":
		for step in range(1,17):
			if not _inside(region,a.lerp(b,float(step)/16.0)):return false
	return true
static func path(region: String,from: Vector2,to: Vector2,ship: Dictionary={}) -> Array:
	searches+=1
	if not walkable(region,to,ship):return []
	if clear(region,from,to,ship):return [to]
	var start: Variant=_grid_near(region,from,ship)
	var goal: Variant=_grid_near(region,to,ship)
	if start==null or goal==null:return []
	var heap: Array=[]
	var costs: Dictionary={start:0.0};var previous: Dictionary={};var closed: Dictionary={}
	_push(heap,start,Vector2(start).distance_to(Vector2(goal)))
	var found: bool=false
	while not heap.is_empty() and closed.size()<MAX_VISITS:
		var point: Vector2i=_pop(heap)
		if closed.has(point):continue
		if point==goal:found=true;break
		closed[point]=true
		for offset: Vector2i in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(-1,-1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(1,1)]:
			var next: Vector2i=point+offset
			if closed.has(next) or not clear(region,Vector2(point),Vector2(next),ship):continue
			var cost: float=costs[point]+Vector2(offset).length()
			if cost>=float(costs.get(next,INF)):continue
			costs[next]=cost;previous[next]=point
			_push(heap,next,cost+1.1*Vector2(next).distance_to(Vector2(goal)))
	if not found:return []
	var grid: Array=[to];var cursor: Vector2i=goal
	while cursor!=start:grid.push_front(Vector2(cursor));cursor=previous[cursor]
	grid.push_front(Vector2(start))
	# Greedy straight segments remove grid stair-steps once per route request.
	var result: Array=[];var anchor: Vector2=from;var index: int=0
	while index<grid.size():
		var far: int=index
		while far+1<grid.size() and clear(region,anchor,grid[far+1],ship):far+=1
		result.append(grid[far]);anchor=grid[far];index=far+1
	return result
static func _grid_near(region: String,p: Vector2,ship: Dictionary) -> Variant:
	var centre:=Vector2i(roundi(p.x),roundi(p.y))
	for radius in range(0,5):
		for x in range(-radius,radius+1):
			for y in range(-radius,radius+1):
				var node:=centre+Vector2i(x,y)
				if walkable(region,Vector2(node),ship) and clear(region,p,Vector2(node),ship):return node
	return null
static func safe_near(region: String,p: Vector2,ship: Dictionary={},distance: int=50) -> Vector2:
	if walkable(region,p,ship):return p
	for radius in range(1,distance+1):
		for step in 24:
			var candidate:=p+Vector2.from_angle(float(step)*TAU/24.0)*radius
			if walkable(region,candidate,ship):return candidate
	return Vector2(INF,INF)
static func landing_clear(region: String,ship: Dictionary) -> bool:
	var hull: Rect2=_ship_rect(region,ship)
	if not hull.has_area():return false
	if not _inside(region,hull.position) or not _inside(region,hull.end):return false
	for rect: Rect2 in _index(region).rects:
		if hull.intersects(rect):return false
	var access: Array=Catalog.ship_access(ship)
	return walkable(region,Vector2(access[0],access[1]),ship)
static func _push(heap: Array,p: Vector2i,score: float) -> void:
	heap.append({"point":p,"score":score})
	var index: int=heap.size()-1
	while index>0:
		var parent: int=(index-1)/2
		if heap[parent].score<=heap[index].score:break
		var swap: Dictionary=heap[parent];heap[parent]=heap[index];heap[index]=swap;index=parent
static func _pop(heap: Array) -> Vector2i:
	var result: Vector2i=heap[0].point
	var last: Dictionary=heap.pop_back()
	if heap.is_empty():return result
	heap[0]=last;var index: int=0
	while index*2+1<heap.size():
		var child: int=index*2+1
		if child+1<heap.size() and heap[child+1].score<heap[child].score:child+=1
		if heap[index].score<=heap[child].score:break
		var swap: Dictionary=heap[index];heap[index]=heap[child];heap[child]=swap;index=child
	return result
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
