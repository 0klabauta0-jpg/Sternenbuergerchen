extends SceneTree
const ARMOR=preload("res://output/native_glut_maps/personnel_armor_visual_r07.gd")
func _init():call_deferred("run")
func run():
	var view=load("res://scripts/terrain/terrain_map_3d_view.gd").new()
	var unit=load("res://scripts/npc/test_unit.gd").new()
	unit.unit_id="r07_metrics";unit.armor_id="suit"
	var rows:Array=[]
	for rig in ["base","mission"]:
		var model:Node3D=load("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb").instantiate() if rig=="base" else view.call("_create_unit_proxy",unit)
		root.add_child(model)
		for armor in ["light","medium","heavy"]:
			var result=ARMOR.apply_to_model(model,armor)
			var outfit:MeshInstance3D=model.find_children("ArmorVisual_*","MeshInstance3D",true,false)[0]
			var tris:int=0;var verts:int=0;var materials:Array=[];var influences:Dictionary={}
			for surface in outfit.mesh.get_surface_count():
				var a=outfit.mesh.surface_get_arrays(surface)
				tris+=a[Mesh.ARRAY_INDEX].size()/3;verts+=a[Mesh.ARRAY_VERTEX].size()
				materials.append(outfit.mesh.surface_get_material(surface).resource_name)
				for vertex in a[Mesh.ARRAY_VERTEX].size():
					var count:int=0
					for influence in range(4):
						if a[Mesh.ARRAY_WEIGHTS][vertex*4+influence]>0:count+=1
					influences[str(count)]=true
			rows.append({"rig":rig,"armor":armor,"segments":result.count,"triangles":tris,"exported_vertices":verts,"surfaces":outfit.mesh.get_surface_count(),"materials":materials,"skin_binds":outfit.skin.get_bind_count(),"positive_influence_counts":influences.keys()})
		model.free()
	view.free();unit.free()
	FileAccess.open("res://art/armor_kenney_r07_20261111/runtime_metrics.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
	print(JSON.stringify(rows));quit()
