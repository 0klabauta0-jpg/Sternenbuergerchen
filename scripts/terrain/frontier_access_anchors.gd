extends RefCounted
## Authoring/visual dimensions only. No map, registry or gameplay mutation.
const PAVING_HEIGHT := 0.014
const STEP_TOP := 0.057
const DOOR_RAMP_LENGTH := 0.40

static func door_offset(width: float,hall: bool) -> float:
	return -width*0.10 if hall else 0.0

static func door_width(width: float,hall: bool) -> float:
	return width*(0.54 if hall else 0.25)

static func building(bounds: AABB,hall: bool) -> Dictionary:
	var center := bounds.get_center()
	var step_front := Vector2(center.x+door_offset(bounds.size.x,hall),bounds.end.z+0.198)
	return {"step_front":step_front,"ground":step_front+Vector2(0.0,DOOR_RAMP_LENGTH),
		"outward":Vector2.DOWN,"step_width":door_width(bounds.size.x,hall)+0.23,
		"surface_height":PAVING_HEIGHT,"step_height":STEP_TOP,"bounds":bounds}

static func pad(center: Vector2,size: Vector2,side: float) -> Dictionary:
	return {"ground":center+Vector2(side*(size.x*0.5+0.96),0.0),
		"outward":Vector2(side,0.0),"width":0.90,"surface_height":PAVING_HEIGHT}

static func defaults() -> Dictionary:
	# Frozen source bounds at the authored0.35scale. Real instances pass measured
	# bounds through building(); standalone geometry verifiers use these defaults.
	return {"habitat":building(AABB(Vector3(7.0925,0.0,4.9575),Vector3(2.415,1.05175,2.485)),false),
		"hall":building(AABB(Vector3(11.3625,0.0,4.98375),Vector3(3.675,1.47,2.4325)),true),
		"pad01":pad(Vector2(6.5,10.9),Vector2(5.0,4.4),1.0),
		"pad02":pad(Vector2(19.2,11.8),Vector2(4.2,4.1),-1.0)}
