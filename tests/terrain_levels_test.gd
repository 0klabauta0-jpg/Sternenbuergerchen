extends SceneTree
const Terrain=preload("res://scripts/core/terrain_layout.gd")
func _initialize() -> void:
 var failures:=0
 for test:Array in [[Terrain.height_at("base",Vector2(0,0))==4.0,"home terrace"],[Terrain.height_at("base",Vector2(25,30))==0.0,"lower landing"],[Terrain.height_at("base",Vector2(0,-70))==9.0,"upper shelf"],[not Terrain.traversable("base",Vector2(40,0),Vector2(70,0)),"cliff blocked"],[Terrain.traversable("base",Vector2(0,10),Vector2(0,42)),"ramp passable"],[not Terrain.level_landing("base",Rect2(-4,17,8,10)),"ramp landing blocked"]]:
  if not test[0]:failures+=1;printerr(test[1])
 print("TERRAIN ",6," checks failures=",failures)
 quit(failures)
