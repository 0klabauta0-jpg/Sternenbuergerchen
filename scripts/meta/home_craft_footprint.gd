extends RefCounted
## Pure projection of the same catalog bounds, scale and rotation as the home
## renderer. These rectangles are conservative horizontal AABBs, not physics.
const SHIPS=preload("res://scripts/terrain/frontier_ship_visuals.gd")
const CLEARANCE:=0.20

static func rect_for_craft(craft:Dictionary,pad:Dictionary)->Dictionary:
	var identity:Dictionary=SHIPS.get_ui_identity(craft)
	var origin:Variant=identity.get("bounds_min")
	var size:Variant=identity.get("bounds_size")
	var plane:Variant=pad.get("plane")
	if not origin is Array or origin.size()!=3 or not size is Array or size.size()!=3 or not plane is Array or plane.size()!=2:return {"ok":false,"reason":"home_craft_geometry_unavailable"}
	var scale:=float(identity.get("scale",0.0))
	var yaw:=deg_to_rad(float(identity.get("root_rotation_y_degrees",0.0)))
	if not is_finite(scale) or scale<=0.0 or not is_finite(yaw):return {"ok":false,"reason":"home_craft_geometry_unavailable"}
	var minimum:=Vector2(INF,INF);var maximum:=Vector2(-INF,-INF)
	for x in [float(origin[0]),float(origin[0])+float(size[0])]:
		for z in [float(origin[2]),float(origin[2])+float(size[2])]:
			var point:=Vector2(x*scale,z*scale).rotated(-yaw)+Vector2(float(plane[0]),float(plane[1]))
			if not point.is_finite():return {"ok":false,"reason":"home_craft_geometry_unavailable"}
			minimum=minimum.min(point);maximum=maximum.max(point)
	if minimum.x>=maximum.x or minimum.y>=maximum.y:return {"ok":false,"reason":"home_craft_geometry_unavailable"}
	return {"ok":true,"rect":Rect2(minimum,maximum-minimum).grow(CLEARANCE)}
