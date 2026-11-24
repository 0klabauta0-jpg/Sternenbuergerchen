extends SceneTree
## Independent oracle: imported GLB triangles and swept body, never authoring walkmask.
const NAV=preload("res://scripts/meta/base_interior_navigation.gd")
const REGISTRY=preload("res://scripts/terrain/terrain_registry.gd")
const PATHFINDER=preload("res://scripts/terrain/terrain_pathfinder.gd")
var stage:Node3D
var failures:Array=[]
var last_blocker:=""
var body_shape:=CapsuleShape3D.new()
var query:=PhysicsShapeQueryParameters3D.new()
func _init():call_deferred("run")
func run():
 var started=Time.get_ticks_usec()
 var map=NAV.load_map("res://maps/campaign_intro_base.json")
 var layout=NAV.layout("res://maps/campaign_intro_base.json")
 var registry=REGISTRY.new();root.add_child(registry)
 var sizes=map.get_tile_size();registry.configure_iso_grid(map.get_grid_origin(),sizes.half_width,sizes.half_height,map.get_grid_topology())
 for t in map.get_tiles():registry.register_tile(t)
 var graph=NAV.new();graph.configure_graph(registry)
 var init_ms=(Time.get_ticks_usec()-started)/1000.0
 stage=Node3D.new();root.add_child(stage)
 # Ersetzte Gebaeude werden im Spiel nicht geladen: hier ebenfalls nicht; stattdessen die neuen Modelle selbst.
 var replaced:Array=load("res://scripts/meta/structure_model_overrides.gd").replaced_ids()
 for asset in layout.assets:
  if asset.id in replaced:continue
  if asset.id not in ["habitat_cutaway_01","freihafen_hall_01","utility_fuel_01"]:continue
  var n:Node3D=load(asset.path).instantiate();stage.add_child(n)
  n.scale=Vector3.ONE*float(asset.scale);n.position=Vector3(asset.plane[0],0,asset.plane[1])
 var overrides:Node3D=load("res://scripts/meta/structure_model_overrides.gd").new();stage.add_child(overrides)
 overrides.build(layout)
 check(overrides.get_models().size()>=1,"new building models are part of the mesh oracle")
 await process_frame
 for n in stage.get_children():
  for m in n.find_children("*","MeshInstance3D",true,false):
   var b=StaticBody3D.new();b.name=String(n.name)+"__"+String(m.name);stage.add_child(b);b.global_transform=m.global_transform
   var c=CollisionShape3D.new();c.shape=m.mesh.create_trimesh_shape();b.add_child(c)
 await physics_frame
 await physics_frame
 for bed in layout.beds:
  var plane=bed.sleep_plane
  var hit=stage.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(plane[0],1.0,plane[1]-.3),Vector3(plane[0],0,plane[1]-.3)))
  print("MATTRESS ",bed.id," ",hit.get("position"))
 body_shape.radius=.18;body_shape.height=.65;query.shape=body_shape
 var spawn=grid(layout.avatar_spawn_grid)
 var targets=[]
 for room in layout.interiors:
  targets.append({"id":room.id+"_door","grid":room.door_grid})
  targets.append({"id":room.id+"_interior","grid":room.interior_grid})
 for group in ["terminals","beds","landing_pads"]:
  for item in layout[group]:targets.append(item)
 var paths=[];var path_ms=[];var edge_count=0
 for t in targets:
  var begin=Time.get_ticks_usec()
  var world_path: Array=graph.find_world_path(registry.grid_to_world(spawn),registry.grid_to_world(grid(t.grid)))
  var path: Array=[]
  for point in world_path:path.append(registry.world_to_grid(point))
  path_ms.append((Time.get_ticks_usec()-begin)/1000.0)
  check(not path.is_empty(),"reachable "+t.id)
  var previous=NAV.plane_at_grid(spawn)
  for step in path:
   var point=NAV.plane_at_grid(step)
   check(clear_segment(previous,point),"body crosses mesh "+t.id+" "+str(point)+" by "+last_blocker)
   previous=point
  paths.append({"id":t.id,"length":path.size(),"end_plane":str(previous),"grid":t.grid})
 # All neighboring walkable edges near original structures, not only authored routes.
 for tile in map.get_tiles():
  if not tile.walkable:continue
  var p=NAV.plane_at_grid(tile.grid_position)
  if not (Rect2(10,3.5,5,5).has_point(Vector2(p.x,p.z)) or Rect2(24,3.5,7,5).has_point(Vector2(p.x,p.z))):continue
  for dir in [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,1)]:
   var other=tile.grid_position+dir
   # Nur Kanten, die der Wegegraph des Spiels zulaesst (gesperrte Wand-/Moebelfelder der neuen Modelle sind aus dem Graph genommen).
   if registry.is_walkable(other) and graph.is_grid_open(tile.grid_position) and graph.is_grid_open(other):
    edge_count+=1
    check(clear_segment(p,NAV.plane_at_grid(other)),"unsafe arbitrary edge "+str(tile.grid_position)+"->"+str(other))
 check(layout.beds[0].grid!=layout.beds[1].grid,"independent bedside approaches")
 var evidence={"ok":failures.is_empty(),"failures":failures,"init_ms":init_ms,"path_ms":path_ms,"graph":graph.get_graph_diagnostics(),"checked_neighbor_edges":edge_count,"routes":paths,"body_radius":.18,"body_bottom":.22,"body_height":.65,"mesh_oracle":"fresh imported GLB trimesh physics; capsule cast_motion and overlap"}
 DirAccess.make_dir_recursive_absolute("res://docs/qa/base_real_personnel_20261109")
 FileAccess.open("res://docs/qa/base_real_personnel_20261109/geometry.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t"))
 print("BASE_REAL_GEOMETRY ",JSON.stringify(evidence))
 stage.queue_free();registry.queue_free();await process_frame
 quit(0 if failures.is_empty() else 1)
func grid(raw)->Vector2i:return Vector2i(int(raw[0]),int(raw[1]))
func check(ok:bool,message:String):
 if not ok:failures.append(message)
func clear_segment(a:Vector3,b:Vector3)->bool:
 # Koerper: ab 0,22 m ueber der Bezugsebene, 0,65 m hoch (Oberkante 0,87 m). Auf erhoehten Boeden (Pod, Halle) ist die
 # Oberkante hoechstens so hoch wie die echte Spielfigur (0,609 m) ueber dem Boden; sonst stuende der Koerper im 0,66 m
 # hohen Pod-Innenraum in der Decke, obwohl die Figur hineinpasst.
 var top:=minf(.87,minf(NAV.standing_y(a),NAV.standing_y(b))+.609) if minf(NAV.standing_y(a),NAV.standing_y(b))>0.0 else .87
 body_shape.height=top-.22
 query.transform=Transform3D(Basis.IDENTITY,a+Vector3.UP*((.22+top)*.5))
 query.motion=Vector3.ZERO
 var space=stage.get_world_3d().direct_space_state
 var hits=space.intersect_shape(query,1)
 if not hits.is_empty():
  last_blocker=str((hits[0].collider as Node).name);return false
 query.motion=b-a
 var result=space.cast_motion(query)
 if result[0]<.99999:
  query.transform.origin+=(b-a)*result[1];query.motion=(b-a)*.02
  var rest=space.get_rest_info(query)
  last_blocker=str(instance_from_id(int(rest.collider_id)).name) if not rest.is_empty() else "?"
  query.transform.origin-=(b-a)*result[1];query.motion=b-a
  return false
 return true
