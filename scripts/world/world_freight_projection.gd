extends RefCounted
const Geo=preload("res://scripts/world/world_geometry.gd")
const Heights=preload("res://scripts/core/terrain_layout.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
const Haul=preload("res://scripts/core/cargo_hauling.gd")
var nodes:Dictionary={}
static func box(parent:Node3D,item:String) -> Node3D:
 var root:=Node3D.new();parent.add_child(root)
 var color:=Color("d2dbca") if item=="food" else Color("e6e7db") if item=="medical_supplies" else Color("b2c3c9")
 Geo.box(root,Vector3(0,0.35,0),Vector3(0.95,0.7,0.7),color)
 Geo.box(root,Vector3(0,0.36,0),Vector3(0.16,0.74,0.74),Color("ea9d42"))
 if item=="medical_supplies":
  Geo.box(root,Vector3(0,0.4,0.36),Vector3(0.42,0.12,0.03),Color("bd4343"))
  Geo.box(root,Vector3(0,0.4,0.38),Vector3(0.12,0.42,0.03),Color("bd4343"))
 return root
static func held(model:Node3D,item:String) -> void:
 var node:=model.get_node_or_null("CarriedFreight") as Node3D
 if node!=null and not item.is_empty() and node.get_meta("item","")!=item:
  node.free();node=null
 if node==null:
  node=box(model,item);node.name="CarriedFreight";node.position=Vector3(0,0.55,0.65);node.set_meta("item",item)
 node.visible=not item.is_empty()
func present(map:Node3D,units:Dictionary,objects:Dictionary,state:Dictionary) -> void:
 var visible:Dictionary={}
 for id:String in state.get("freight_world",{"crates":{}}).crates:
  var data:Dictionary=state.freight_world.crates[id]
  if data.area!=Haul.area(state):continue
  visible[id]=true
  if not nodes.has(id):
   var root:=box(map,data.item);root.name=id
   Geo.collider(root,"freight",id,Vector3(1.5,1.2,1.5))
   var title:=Geo.label(root,"",Vector3(0,1.5,0),Color("ffcf87"),18);title.name="Title"
   nodes[id]=root
  var at:=Vector2(data.position[0],data.position[1])
  nodes[id].position=Vector3(at.x,Heights.height_at(state.region,at),at.y)
  nodes[id].get_node("Title").text="%d × %s · AUFNEHMEN"%[int(data.amount),Catalog.item_name(data.item)]
 for id:String in nodes.keys():
  if not visible.has(id):nodes[id].queue_free();nodes.erase(id)
 var loads:Dictionary={}
 for j:Dictionary in state.get("hauling",{"jobs":[]}).jobs:
  if int(j.held)>0 and not str(j.unit).is_empty():loads[j.unit]=j.item
 for id:String in units:held(units[id].get_node("Model"),str(loads.get(id,"")))
 for id:String in state.ground.enemies.get(state.region,{}):
  var data:Dictionary=state.ground.enemies[state.region][id]
  if objects.has(id) and objects[id].has_node("EnemyModel") and data.has("team"):held(objects[id].get_node("EnemyModel"),str(data.get("carrying","")))
