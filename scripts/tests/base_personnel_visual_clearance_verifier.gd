extends SceneTree
func _init():call_deferred("run")
func run():
 var n=load("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb").instantiate();root.add_child(n);n.scale=Vector3.ONE*.35
 await process_frame
 var player=n.find_children("*","AnimationPlayer",true,false)[0]
 var samples=[]
 var passed=true
 for clip in ["idle","walk"]:
  player.play(clip)
  for sample in range(32):
   var time=float(sample)*player.get_animation(clip).length/32.0
   player.seek(time,true);player.advance(0)
   var bound=AABB();var first=true;var max_radius=0.0;var torso_radius=0.0
   for m in n.find_children("*","MeshInstance3D",true,false):
    var sk=m.get_node_or_null(m.skeleton) as Skeleton3D
    if sk!=null:sk.force_update_all_bone_transforms()
    for s in range(m.mesh.get_surface_count()):
     var arrays=m.mesh.surface_get_arrays(s);var vs=arrays[Mesh.ARRAY_VERTEX];var bones=arrays[Mesh.ARRAY_BONES];var ws=arrays[Mesh.ARRAY_WEIGHTS]
     for i in range(vs.size()):
      var point:Vector3=m.global_transform*vs[i]
      if sk!=null and m.skin!=null and bones!=null and bones.size()>0:
       point=Vector3.ZERO
       for j in range(4):
        var index=i*4+j;var bind=int(bones[index]);var bone=m.skin.get_bind_bone(bind)
        if bone<0:bone=sk.find_bone(m.skin.get_bind_name(bind))
        point+=(sk.global_transform*sk.get_bone_global_pose(bone)*m.skin.get_bind_pose(bind)*vs[i])*float(ws[index])
      if first:bound=AABB(point,Vector3.ZERO);first=false
      else:bound=bound.expand(point)
      max_radius=maxf(max_radius,Vector2(point.x,point.z).length())
      # Torso/hips central 60% of height; extremities separately reported.
      if point.y>.15 and point.y<.48:torso_radius=maxf(torso_radius,Vector2(point.x,point.z).length())
   passed=passed and max_radius<=.18 and bound.size.y<=.65
   samples.append({"clip":clip,"time":time,"radius":max_radius,"height":bound.size.y,"width":bound.size.x})
 var evidence={"ok":passed,"scale":.35,"body_radius":.18,"height":.65,"method":"64 skinned vertex poses using skeleton pose times skin bind; includes every imported mesh vertex","samples":samples}
 FileAccess.open("res://docs/qa/base_real_personnel_20261109/posed-visual-clearance.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t"))
 print("BASE_POSED_CLEARANCE ok=",passed," samples=",samples.size())
 quit(0 if passed else 1)
