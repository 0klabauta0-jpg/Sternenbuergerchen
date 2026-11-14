extends RefCounted
## Read-only local service gate. Caller supplies actual parked craft and owner
## permission; this helper never trusts a requested pad ID or UI location.
const HEX=preload("res://scripts/terrain/hex_grid.gd")
static func at_position(map, registry:Node, position:Vector2, authorized:bool)->Dictionary:
 if not authorized or map==null or registry==null or not position.is_finite():return {}
 var grid:Vector2=registry.call("world_to_grid_float",position)
 var plane:Vector2=HEX.axial_to_plane(grid)
 for service:Dictionary in map.get_place_presentation().get("ground_services",[]):
  if service.get("enabled",false)!=true or service.get("public_access",false)!=true:continue
  var center:Array=service.get("center",[]);var size:Array=service.get("size",[])
  if center.size()!=2 or size.size()!=2:continue
  var bounds:=Rect2(Vector2(float(center[0]),float(center[1]))-Vector2(float(size[0]),float(size[1]))*0.5,Vector2(float(size[0]),float(size[1])))
  if not bounds.has_point(plane):continue
  return {"pad_id":String(service.get("id","")),"services":Array(service.get("services",[])).duplicate(),"cargo_lift_container_id":String(service.get("cargo_lift_container_id","")),"ground_service_verified":true}
 return {}
