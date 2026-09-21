extends SceneTree
const Terrain=preload("res://scripts/core/terrain_layout.gd")
func _initialize() -> void:
 var failures:=0
 if not Terrain.new().has_method("flight_floor"):
  printerr("FAIL terrain clearance envelope missing");quit(1);return
 var previous:float=Terrain.new().call("flight_floor","base",Vector2(100,0),8.0)
 for x in range(99,20,-1):
  var at:=Vector2(x,0);var height:float=Terrain.new().call("flight_floor","base",at,8.0)
  if height<Terrain.height_at("base",at) or absf(height-previous)>0.6:failures+=1
  previous=height
 print("FLIGHT TERRAIN failures=",failures);quit(failures)
