extends RefCounted
## Shared deterministic layout data. No nodes, state mutation or gameplay rules.
static var _obstacle_cache: Dictionary={}
static var _rock_cache: Dictionary={}

static func bounds(region: String) -> float:
	return {"base":480.0,"rust":480.0,"bunker_surface":480.0,"tradepost":480.0,"distribution":640.0,"bunker_depths":64.0,"station":80.0,"space":240.0,"orbit":240.0}.get(region,50.0)

static func ship_profile(model: String) -> Dictionary:
	if model=="vulture": return {"size":[4.04,8.4],"height":2.5,"access":[0.0,5.3],"turret":[0.0,0.0],"turret_height":2.3,"yaw":0.0}
	return {"size":[7.5,11.0],"height":3.5,"access":[0.0,6.8],"turret":[0.0,-0.3],"turret_height":3.0,"yaw":0.0}

static func rooms(region: String="base") -> Dictionary:
	if region=="station":return {"shop":{"label":"Handel / Ausrüstung","center":[-14,-10],"size":[24,22],"door":[-2,-5]},"transit":{"label":"Fracht / Transit","center":[14,-10],"size":[24,22],"door":[2,-5]}}
	return {"quarters":{"label":"Unterkunft","center":[-10.0,-12.0],"size":[12.0,12.0],"door":[-4.0,-10.0]},"storage":{"label":"Lager","center":[-10.0,3.0],"size":[12.0,12.0],"door":[-4.0,3.0]},"workshop":{"label":"Werkstatt","center":[10.0,3.0],"size":[12.0,12.0],"door":[4.0,3.0]},"lounge":{"label":"Aufenthalt","center":[8.0,-12.0],"size":[12.0,12.0],"door":[2.0,-10.0]}}

static func landmarks(region: String) -> Dictionary:
	match region:
		"base":return {"workbench":[10.0,3.0],"storage":[-10.0,3.0],"contracts":[10.0,-14.0],"shuttle":[25.0,22.0],"bed_ida":[-14.5,-16.2],"bed_jaro":[-12.7,-16.2],"bed_3":[-10.9,-16.2],"bed_4":[-9.1,-16.2],"bed_5":[-7.3,-16.2],"bed_6":[-5.5,-16.2],"kitchen":[5.0,-12.0],"expansion_a":[27.0,-12.0],"expansion_b":[27.0,3.0]}
		"rust":return {"shuttle":[-210.0,180.0],"satellite":[145.0,-125.0],"mining_site":[-300.0,-210.0],"derelict":[310.0,250.0]}
		"station":return {"shuttle":[0.0,28.0],"market":[-12.0,-8.0]}
		"orbit":return {"shuttle":[0.0,0.0]}
		"bunker_surface":return {"shuttle":[-65.0,70.0],"bunker_entry":[0.0,12.0],"aa_turret":[28.0,-12.0],"surface_cache":[-34.0,-15.0]}
		"bunker_depths":return {"elevator":[0.0,36.0],"bunker_cache":[-26.0,-8.0],"bunker_terminal":[26.0,-8.0]}
		"distribution":return {"shuttle":[-110.0,120.0],"market":[-25.0,20.0],"distribution_cache":[45.0,-35.0],"distribution_wreck":[90.0,15.0]}
		"tradepost":return {"shuttle":[-45.0,50.0],"market":[0.0,0.0],"tradepost_cache":[150.0,-120.0]}
	return {}

static func furniture(region: String) -> Array:
	var result: Array=[]
	if region=="base":
		result.append(_item("lounge_table","table",[11,-8.5],[3.5,1.6],0.9))
		for x in [9.8,12.2]:
			for z in [-9.8,-7.2]:result.append(_item("chair_%s_%s"%[x,z],"chair",[x,z],[0.8,0.8],0.7))
		for x in [-14.0,-10.0,-6.0]:result.append(_item("crate_%s"%x,"crate-small",[x,7],[1.1,1.2],0.8))
		for x in [-14.2,-5.6]:result.append(_item("locker_%s"%x,"locker",[x,-10.1 if x< -10 else -7.3],[1.2,0.7],2.0))
		for x in [-12.0,-7.0,-2.0]:result.append(_item("solar_%s"%x,"solar",[x,-24],[4.5,5.5],2.8))
		for x in [-30.0,-23.0]:result.append(_item("outside_crate_%s"%x,"crate-wide",[x,18],[3.8,3.6],2.4))
		result.append(_item("base_mast","mast",[-19,-18],[0.35,0.35],8))
	elif region=="station":
		for x in [-24.0,24.0]:
			for z in [-17.0,-10.0,-3.0]:result.append(_item("dock_crate_%s_%s"%[x,z],"crate-wide",[x,z],[2.8,2.2],1.7))
	elif region=="bunker_surface":
		for z in [-62.0,-74.0,-86.0]:result.append(_item("tank_%s"%z,"tank",[-40,z],[6,6],3))
		result.append(_item("bunker_mast","mast",[-34,-36],[0.35,0.35],10))
	elif region=="distribution":
		for x in [-95.0,100.0]:
			for z in [-65.0,55.0]:result.append(_item("depot_mast_%s_%s"%[x,z],"mast",[x,z],[0.35,0.35],8))
	elif region=="tradepost":
		for x in [-12.0,-6.0,0.0]:result.append(_item("solar_%s"%x,"solar",[x,-30],[5,8],2.5))
		result.append(_item("outpost_mast","mast",[-19,-18],[0.35,0.35],9))
	return result

static func _item(id: String, asset: String, center: Array, size: Array, height: float) -> Dictionary:
	return {"id":id,"asset":asset,"center":center,"size":size,"height":height,"yaw":0.0,"category":"furniture"}

static func obstacles(region: String) -> Dictionary:
	if _obstacle_cache.has(region):return _obstacle_cache[region]
	var result:=_structures(region)
	for item: Dictionary in furniture(region):result[item.id]=item
	for id in landmarks(region):
		var at: Array=landmarks(region)[id]
		var size: Array=[]; var offset:=[0.0,0.0]
		match id:
			"workbench":size=[2.5,1.3];offset=[0,-0.25]
			"storage":size=[3.4,1.8];offset=[0,-0.25]
			"contracts":size=[1.2,1.2];offset=[0,-0.45]
			"kitchen":size=[2.6,1.3];offset=[0,-0.3]
			"market":size=[8.0,2.6];offset=[0,-0.4]
			"satellite":size=[11.5,7.0];offset=[0,0]
			"derelict","distribution_wreck":size=[15.0,15.0]
			"mining_site":size=[12.0,12.0]
			"aa_turret":size=[5.4,5.4]
			"surface_cache","bunker_cache","distribution_cache","tradepost_cache":size=[4.0,2.6]
			"bunker_terminal":size=[3.5,2.0];offset=[0,-0.5]
			_:
				if str(id).begins_with("bed_"):size=[1.45,2.6];offset=[0,-0.2]
		if not size.is_empty():result["object_"+str(id)]={"center":[at[0]+offset[0],at[1]+offset[1]],"size":size,"category":"landmark","object_id":str(id)}
	for rock: Dictionary in rocks(region):result[rock.id]=rock
	_obstacle_cache[region]=result
	return result

static func _structures(region: String) -> Dictionary:
	var result: Dictionary={}
	if region in ["base","station"]:
		var source:=rooms(region)
		for id in source:
			var room: Dictionary=source[id];var c:=Vector2(room.center[0],room.center[1]);var s:=Vector2(room.size[0],room.size[1]);var door:=Vector2(room.door[0],room.door[1]);var east:=c.x>0
			_rect(result,str(id)+"_north",c+Vector2(0,-s.y/2),Vector2(s.x,0.42),"wall",false)
			_rect(result,str(id)+"_south",c+Vector2(0,s.y/2),Vector2(s.x,0.42),"wall",true)
			_rect(result,str(id)+"_outer",c+Vector2(s.x/2 if east else -s.x/2,0),Vector2(0.42,s.y),"wall",east)
			var ix:=c.x-s.x/2 if east else c.x+s.x/2
			for segment in [Vector2(c.y-s.y/2,door.y-1.5),Vector2(door.y+1.5,c.y+s.y/2)]:
				_rect(result,str(id)+"_inner_"+str(segment.x),Vector2(ix,(segment.x+segment.y)/2),Vector2(0.42,segment.y-segment.x),"wall",not east)
		if region=="base":_rect(result,"base_north",Vector2(0,-18),Vector2(4,0.42),"wall",false)
		else:
			for x in [-34.0,34.0]:_rect(result,"station_bulkhead_%s"%x,Vector2(x,-4),Vector2(7,42),"station_bulkhead",false)
	elif region=="bunker_surface":
		_rect(result,"bunker_back",Vector2(0,-29),Vector2(48,2),"wall",false)
		_rect(result,"bunker_left",Vector2(-24,-9),Vector2(2,38),"wall",false)
		_rect(result,"bunker_right",Vector2(24,-9),Vector2(2,38),"wall",true)
		_rect(result,"bunker_front_left",Vector2(-14,11),Vector2(20,2),"wall",true)
		_rect(result,"bunker_front_right",Vector2(14,11),Vector2(20,2),"wall",true)
	elif region=="bunker_depths":
		for x in [-8.0,8.0]:
			for z in [-13.5,13.5]:_rect(result,("west" if x<0 else "east")+("_north" if z<0 else "_south"),Vector2(x,z),Vector2(1,21),"wall",x>0 or z>0)
		for x in [-40.0,40.0]:_rect(result,"depth_outer_%s"%x,Vector2(x,0),Vector2(1,48),"wall",x>0)
		for x in [-24.0,24.0]:
			for z in [-24.0,24.0]:_rect(result,"depth_room_%s_%s"%[x,z],Vector2(x,z),Vector2(32,1),"wall",z>0)
		for x in [-8.0,8.0]:
			for z in [-36.0,36.0]:_rect(result,"depth_hall_%s_%s"%[x,z],Vector2(x,z),Vector2(1,24),"wall",x>0)
		for z in [-48.0,48.0]:_rect(result,"depth_end_%s"%z,Vector2(0,z),Vector2(16,1),"wall",z>0)
	elif region=="distribution":
		_rect(result,"depot_stack_a",Vector2(10,0),Vector2(16,24),"warehouse",false)
		_rect(result,"depot_stack_b",Vector2(60,25),Vector2(18,12),"warehouse",false)
		_rect(result,"depot_stack_c",Vector2(-55,-35),Vector2(24,16),"warehouse",false)
		_rect(result,"security_back",Vector2(50,-56),Vector2(36,1),"wall",false)
		_rect(result,"security_side",Vector2(68,-44),Vector2(1,24),"wall",true)
		_rect(result,"market_back",Vector2(-27,15),Vector2(26,1),"wall",false)
	elif region=="tradepost":
		_rect(result,"outpost_store",Vector2(14,-8),Vector2(8,10),"warehouse",false)
		_rect(result,"market_back",Vector2(-3,-12.5),Vector2(23,1),"wall",false)
		_rect(result,"hab_left",Vector2(-14.5,-2),Vector2(1,21),"wall",false)
		_rect(result,"hab_right",Vector2(8.5,-2),Vector2(1,21),"wall",true)
		_rect(result,"hab_front_left",Vector2(-10,8.5),Vector2(9,1),"wall",true)
		_rect(result,"hab_front_right",Vector2(4,8.5),Vector2(9,1),"wall",true)
	return result

static func _rect(result: Dictionary,id: String,center: Vector2,size: Vector2,kind: String,front: bool) -> void:
	if size.x<=0 or size.y<=0:return
	result[id]={"center":[center.x,center.y],"size":[size.x,size.y],"category":"structure","kind":kind,"front":front}

static func rocks(region: String) -> Array:
	if _rock_cache.has(region):return _rock_cache[region]
	var result: Array=[]
	if region not in ["base","rust","bunker_surface","distribution","tradepost"]:return result
	var rng:=RandomNumberGenerator.new();rng.seed={"base":812,"rust":901,"bunker_surface":972,"distribution":1048,"tradepost":1135}.get(region,901)
	var half:=bounds(region)
	var structures:=_structures(region)
	for i in range(80+160):
		var point:=Vector2(rng.randf_range(-half*0.94,half*0.94),rng.randf_range(-half*0.94,half*0.94))
		var radius:=rng.randf_range(11,27) if i<80 else rng.randf_range(0.7,1.8)
		if _clear_area(region,point,radius):continue
		var blocked:=false
		for at: Array in landmarks(region).values():
			if point.distance_to(Vector2(at[0],at[1]))<radius+17:blocked=true
		for spec: Dictionary in structures.values():
			var size:=Vector2(spec.size[0],spec.size[1]);var rect:=Rect2(Vector2(spec.center[0],spec.center[1])-size/2,size)
			if rect.grow(radius+4).has_point(point):blocked=true
		if blocked:continue
		var height:=radius*rng.randf_range(0.65,1.4) if i<80 else radius*rng.randf_range(0.5,0.9)
		result.append({"id":"rock_%03d"%i,"center":[point.x,point.y],"size":[radius*2.4,radius*1.8],"height":height,"radius":radius,"seed":int(rng.randi()),"category":"rock","kind":"mesa" if i<80 else "stone"})
	_rock_cache[region]=result
	return result

static func _clear_area(region: String,point: Vector2,radius: float) -> bool:
	var rect: Rect2
	match region:
		"base":rect=Rect2(-50,-42,110,94)
		"distribution":rect=Rect2(-130,-105,280,270)
		"bunker_surface":rect=Rect2(-85,-110,160,220)
		"tradepost":rect=Rect2(-62,-45,105,112)
		_:return false
	return rect.grow(radius).has_point(point)
