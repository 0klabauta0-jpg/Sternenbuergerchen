extends SceneTree
func _init():call_deferred("run")
func run():
	var view=load("res://scripts/terrain/terrain_map_3d_view.gd").new();var unit=load("res://scripts/npc/test_unit.gd").new();unit.armor_id="suit";unit.unit_id="inspect"
	var model:Node3D=view.call("_create_unit_proxy",unit);root.add_child(model)
	for helmet:Node3D in model.find_children("HelmetVisual_*","Node3D",true,false):
		var node:Node3D=helmet
		while node!=null:
			print("CHAIN ",node.name," ",node.get_class()," ",node.transform," ",node.bone_name if node is BoneAttachment3D else "")
			node=node.get_parent() as Node3D
	model.free();unit.free();view.free();quit()
