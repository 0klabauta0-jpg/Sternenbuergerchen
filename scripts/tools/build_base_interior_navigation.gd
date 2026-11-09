extends SceneTree
const NAV=preload("res://scripts/meta/base_interior_navigation.gd")
var stage:Node3D
func _init():call_deferred("run")
func run():
 var raw:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://maps/campaign_intro_base.json"))
 var layout:Dictionary=raw.homebase_exploration.duplicate(true)
 stage=Node3D.new();root.add_child(stage)
 for a:Dictionary in layout.assets:
  if a.id not in ["habitat_cutaway_01","freihafen_hall_01","utility_fuel_01"]:continue
  if a.id!="utility_fuel_01":
   a["path"]="res://Assets/curated/base_access_20261109/"+String(a.id)+".glb"
   a["original_path"]="res://Assets/curated/frontier_illustrated_20261101/structures_pass04/"+String(a.id)+".glb"
   a["original_sha256"]=FileAccess.get_sha256(a.original_path)
   a["visual_route"]="furnished_cutaway_with_door_openings"
   a["sha256"]=FileAccess.get_sha256(a.path)
  var n:Node3D=load(a.path).instantiate();stage.add_child(n);n.scale=Vector3.ONE*float(a.scale);n.position=Vector3(a.plane[0],0,a.plane[1])
 await process_frame
 for n in stage.get_children():
  for m in n.find_children("*","MeshInstance3D",true,false):
   var b=StaticBody3D.new();stage.add_child(b);b.global_transform=m.global_transform
   var c=CollisionShape3D.new();c.shape=m.mesh.create_trimesh_shape();b.add_child(c)
 await physics_frame
 await physics_frame
 var capsule=CylinderShape3D.new();capsule.radius=.18;capsule.height=.65
 var query=PhysicsShapeQueryParameters3D.new();query.shape=capsule
 var nav={"map_name":"Authored original room clearance","grid_size":{"x":144,"y":112},"grid_origin":raw.grid_origin,"tile_size":{"half_width":16,"half_height":8},"grid_topology":"hex_axial_v1","tiles":[]}
 var walk:Dictionary={}
 for x in range(144):
  for y in range(112):
   var p=NAV.plane_at_grid(Vector2i(x,y))
   query.transform=Transform3D(Basis.IDENTITY,p+Vector3.UP*.545)
   var allowed=x>=4 and x<=140 and y>=4 and y<=108
   if allowed:allowed=stage.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
   if allowed:walk[Vector2i(x,y)]=true
   nav.tiles.append({"grid_position":{"x":x,"y":y},"type_id":"ground_flat","walkable":allowed,"blocks_los":not allowed,"edge_type":"none","surface_type":"ground"})
 var sweep=PhysicsShapeQueryParameters3D.new()
 var body=CapsuleShape3D.new();body.radius=.18;body.height=.65;sweep.shape=body
 var removed=0
 for g:Vector2i in walk.keys():
  if not walk.has(g):continue
  for direction in [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,1)]:
   var next=g+direction
   if not walk.has(next):continue
   var from=NAV.plane_at_grid(g);var to=NAV.plane_at_grid(next)
   sweep.transform=Transform3D(Basis.IDENTITY,from+Vector3.UP*.545);sweep.motion=to-from
   if stage.get_world_3d().direct_space_state.cast_motion(sweep)[0]<.99999:
    walk.erase(next);removed+=1
 for tile in nav.tiles:
  var allowed=walk.has(Vector2i(int(tile.grid_position.x),int(tile.grid_position.y)))
  tile.walkable=allowed;tile.blocks_los=not allowed
 print("PRUNED_UNSAFE_EDGES ",removed)
 for key in ["avatar_spawn_grid","initial_walk_target_grid","blocked_test_grid"]:layout[key]=[int(layout[key][0])*4,int(layout[key][1])*4]
 for group in ["terminals","landing_pads","expansion_areas"]:
  for item in layout.get(group,[]):item.grid=[int(item.grid[0])*4,int(item.grid[1])*4]
 var points={"personnel":Vector2(11.65,6.6),"jobs":Vector2(12.75,6.05),"team":Vector2(25.8,5.7),"mission":Vector2(29.3,6.7)}
 for t in layout.terminals:
  if points.has(t.id):
   t.grid=nearest(points[t.id],walk);t["use_existing_furniture"]=true;t["model_anchor_plane"]=[points[t.id].x,points[t.id].y]
 layout["beds"]=[{"id":"habitat_bed_01","grid":nearest(Vector2(11.4,6.0),walk),"rest_plane":[11.125,4.825],"sleep_plane":[11.125,5.35],"sleep_y":.61,"rotation_y":-PI*.5,"surface_y":.4763,"room_id":"habitat_cutaway_01"},{"id":"habitat_bed_02","grid":nearest(Vector2(11.9,5.9),walk),"rest_plane":[11.84,4.825],"sleep_plane":[11.84,5.35],"sleep_y":.61,"rotation_y":-PI*.5,"surface_y":.4763,"room_id":"habitat_cutaway_01"}]
 layout.interiors=[{"id":"habitat_cutaway_01","door_grid":nearest(Vector2(12.5,7.75),walk),"interior_grid":nearest(Vector2(12.3,6.2),walk),"title":"Habitat"},{"id":"freihafen_hall_01","door_grid":nearest(Vector2(27.3,7.85),walk),"interior_grid":nearest(Vector2(27.3,6.2),walk),"title":"Werkhalle"}]
 nav["homebase_exploration"]=layout
 nav["clearance"]={"body_radius":.18,"body_height":.65,"body_bottom":.22,"authoring_radius":.18,"cell_spacing":.25,"method":"body-cylinder occupancy plus exact capsule sweep of every neighboring edge; unsafe endpoint pruned","generator":"res://scripts/tools/build_base_interior_navigation.gd"}
 FileAccess.open(NAV.NAV_PATH,FileAccess.WRITE).store_string(JSON.stringify(nav))
 print("NAV_GENERATED tiles=",nav.tiles.size()," walkable=",walk.size()," beds=",layout.beds," rooms=",layout.interiors," terminals=",layout.terminals)
 quit()
func nearest(p:Vector2,walk:Dictionary)->Array:
 var best=Vector2i.ZERO;var distance=INF
 for g:Vector2i in walk:
  var a=NAV.plane_at_grid(g);var d=Vector2(a.x,a.z).distance_squared_to(p)
  if d<distance:distance=d;best=g
 return [best.x,best.y]
