extends SceneTree
const HEX=preload("res://scripts/terrain/hex_grid.gd")
const LAYOUT=preload("res://scripts/terrain/frontier_gm01_layout.gd")
func _initialize() -> void: call_deferred("run")
func area(p:PackedVector2Array)->float:
 var result:=0.0
 for i in p.size(): result+=p[i].cross(p[(i+1)%p.size()])
 return absf(result)*0.5
func boundary_crosses(a:PackedVector2Array,b:PackedVector2Array)->bool:
 for i in a.size():
  for j in b.size():
   if Geometry2D.segment_intersects_segment(a[i],a[(i+1)%a.size()],b[j],b[(j+1)%b.size()]) != null:return true
 return false
func overlaps(a:PackedVector2Array,b:PackedVector2Array)->bool:
 for p:Vector2 in a:
  if Geometry2D.is_point_in_polygon(p,b):return true
 for p:Vector2 in b:
  if Geometry2D.is_point_in_polygon(p,a):return true
 return boundary_crosses(a,b)
func run()->void:
 var path:="res://maps/Ground_Mission01_32x32.json"
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 var stage:=Node3D.new();root.add_child(stage)
 var built:Dictionary=LAYOUT.build(stage)
 var surfaces:Array[Dictionary]=[]
 for geology:Node in built.root.get_children():
  if geology.has_method("surface_specs"):surfaces.append_array(geology.surface_specs())
 var cells:Array=[]
 var new_blockers:Array=[]
 var inside_count:=0
 for tile:Dictionary in data.tiles:
  var grid:=Vector2(int(tile.grid_position.x),int(tile.grid_position.y))
  var center:Vector2=HEX.axial_to_plane(grid)
  var new_rock:=false
  for blocker:Dictionary in built.blockers:
   if String(blocker.get("id",""))=="edge_LandingMesa" and blocker.rect.has_point(center):new_rock=true;break
  if new_rock:new_blockers.append([int(grid.x),int(grid.y)])
  if not new_rock and tile.get("object_type_id","")!="frontier_scene_solid":continue
  var polygon:=PackedVector2Array()
  for corner:Vector2 in HEX.corners():polygon.append(center+corner)
  for spec:Dictionary in surfaces:
   if not Geometry2D.is_point_in_polygon(center,spec.polygon):continue
   inside_count+=1
   var full:=true
   for point:Vector2 in polygon:
    if not Geometry2D.is_point_in_polygon(point,spec.polygon):full=false;break
   if not full or boundary_crosses(polygon,spec.polygon):continue
   var blocked:=false
   for other:Dictionary in surfaces:
    if float(other.height)<=float(spec.height)+0.001:continue
    if overlaps(polygon,other.polygon):blocked=true
    if blocked:break
   if blocked:continue
   var level:=roundi(float(spec.height)/0.5)
   if level<1 or level>16:push_error("Unsupported rock surface height");quit(1);return
   tile.merge({"height_level":level,"walkable":true,"blocks_los":false,"object_height":0,"cover_value":0,"edge_type":"cliff","surface_type":"rock"},true)
   cells.append([int(grid.x),int(grid.y),level,String(spec.id)])
   break
 if cells.size()<10:push_error("Empty surface revision");quit(1);return
 var file:=FileAccess.open("res://tmp/map_services_rock_cells.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"cells":cells,"surfaces":surfaces.size(),"new_blockers":new_blockers}));file.close()
 print("AUTHOR_ROCK_SURFACES passed=%d failed=0"%cells.size())
 stage.queue_free();await process_frame;quit()
