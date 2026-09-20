extends RefCounted
## Conservative planar hull clearance at the rendered cruise altitude (4 m).
const Catalog=preload("res://scripts/core/catalog.gd")
const CELL=4.0
static var _cache: Dictionary={}

static func data(region: String, model: String) -> Dictionary:
	var key:=region+":"+model
	if _cache.has(key):return _cache[key]
	var profile: Dictionary=Catalog.ship_profile(model)
	var radius:=Vector2(profile.size[0],profile.size[1]).length()/2.0+0.8
	var rects: Array[Rect2]=[]
	for obstacle: Dictionary in Catalog.obstacles(region).values():
		if float(obstacle.get("height",0.0))<4.0:continue
		var extent:=Vector2(obstacle.size[0],obstacle.size[1])
		rects.append(Rect2(Vector2(obstacle.center[0],obstacle.center[1])-extent/2,extent).grow(radius))
	var bound:=Catalog.bounds(region)-radius
	var count:=ceili(bound*2/CELL)+1
	var grid:=AStarGrid2D.new()
	grid.region=Rect2i(0,0,count,count)
	grid.cell_size=Vector2(CELL,CELL)
	grid.offset=Vector2(-bound,-bound)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for rect: Rect2 in rects:
		var grown:=rect.grow(CELL*0.71)
		var low:=Vector2i(((grown.position-grid.offset)/CELL).floor())
		var high:=Vector2i(((grown.end-grid.offset)/CELL).ceil())
		for x in range(maxi(0,low.x),mini(count,high.x+1)):
			for y in range(maxi(0,low.y),mini(count,high.y+1)):grid.set_point_solid(Vector2i(x,y))
	for x in count:
		for y in count:
			var at:=grid.get_point_position(Vector2i(x,y))
			if absf(at.x)>bound or absf(at.y)>bound:grid.set_point_solid(Vector2i(x,y))
	_cache[key]={"grid":grid,"rects":rects,"bound":bound}
	return _cache[key]

static func clear(region: String,model: String,a: Vector2,b: Vector2) -> bool:
	var d:=data(region,model)
	if absf(a.x)>d.bound or absf(a.y)>d.bound or absf(b.x)>d.bound or absf(b.y)>d.bound:return false
	for rect: Rect2 in d.rects:
		if rect.has_point(a) or rect.has_point(b):return false
		var lo:=0.0;var hi:=1.0;var delta:=b-a
		for axis in 2:
			if absf(delta[axis])<0.000001:
				if a[axis]<rect.position[axis] or a[axis]>rect.end[axis]:lo=2.0;break
			else:
				var t1:float=(rect.position[axis]-a[axis])/delta[axis]
				var t2:float=(rect.end[axis]-a[axis])/delta[axis]
				lo=maxf(lo,minf(t1,t2));hi=minf(hi,maxf(t1,t2))
		if lo<=hi:return false
	return true

static func _anchor(region: String,model: String,at: Vector2) -> Vector2i:
	var grid: AStarGrid2D=data(region,model).grid
	var center:=Vector2i(((at-grid.offset)/CELL).round())
	for radius in range(0,7):
		for x in range(-radius,radius+1):
			for y in range(-radius,radius+1):
				if maxi(absi(x),absi(y))!=radius:continue
				var cell:=center+Vector2i(x,y)
				if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell) and clear(region,model,at,grid.get_point_position(cell)):return cell
	return Vector2i(-1,-1)

static func path(region: String,model: String,from: Vector2,to: Vector2) -> Array:
	if clear(region,model,from,to):return [to]
	if not clear(region,model,from,from) or not clear(region,model,to,to):return []
	var start:=_anchor(region,model,from);var goal:=_anchor(region,model,to)
	if start.x<0 or goal.x<0:return []
	var grid: AStarGrid2D=data(region,model).grid
	var raw:=grid.get_point_path(start,goal)
	if raw.is_empty():return []
	var points: Array=[]
	for point: Vector2 in raw:points.append(point)
	points.append(to)
	var result: Array=[];var cursor:=from;var i:=0
	while i<points.size():
		var furthest:=i
		while furthest+1<points.size() and clear(region,model,cursor,points[furthest+1]):furthest+=1
		if not clear(region,model,cursor,points[furthest]):return []
		cursor=points[furthest];result.append(cursor);i=furthest+1
	return result


static func safe_near(region: String,model: String,point: Vector2) -> Vector2:
	if clear(region,model,point,point):return point
	for radius in range(4,241,4):
		for step in 32:
			var at:=point+Vector2.from_angle(step*TAU/32)*radius
			if clear(region,model,at,at):return at
	return Vector2(INF,INF)
