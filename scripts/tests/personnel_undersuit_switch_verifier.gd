extends SceneTree
const ARMOR=preload("res://scripts/terrain/personnel_armor_visual.gd")
var failures:=0
func _init():call_deferred("run")
func check(value:bool,label:String):
	print(("PASS: " if value else "FAIL: ")+label)
	if not value:failures+=1
func run():
	var model:Node3D=load("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb").instantiate()
	root.add_child(model)
	var body:MeshInstance3D
	for node:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		if String(node.name).to_lower().contains("character"):body=node;break
	check(body!=null,"actual character body exists")
	if body==null:model.free();quit(1);return
	for item:String in ["suit","light","medium","heavy","suit"]:
		var result:Dictionary=ARMOR.apply_to_model(model,item)
		var mat:ShaderMaterial=body.material_override as ShaderMaterial
		check(result.get("ok",false) and String(model.get_meta("worn_armor_id",""))==item,"equipment projects "+item)
		check(mat!=null and bool(mat.get_shader_parameter("visible_suit"))==(item=="suit"),"correct distinct underlayer for "+item)
		check((model.find_children("ArmorVisual_*","MeshInstance3D",true,false).size()==0)==(item=="suit"),"no armor shell on undersuit "+item)
	model.free()
	if failures==0:print("PERSONNEL_UNDERSUIT_SWITCH_PASS")
	quit(0 if failures==0 else 1)
