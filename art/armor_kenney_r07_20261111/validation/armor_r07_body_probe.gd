extends SceneTree
const OLD=preload("res://output/native_glut_maps/personnel_armor_visual_r06.gd")
const ARMOR=preload("res://output/native_glut_maps/personnel_armor_visual_r07.gd")
var models:Array=[]
var stages:Array=[]
var data:Array=[]
func _init():call_deferred("run")
func run():
	root.size=Vector2i(1920,1080)
	var columns=HBoxContainer.new();root.add_child(columns)
	var view=load("res://scripts/terrain/terrain_map_3d_view.gd").new()
	var actor=load("res://scripts/npc/test_unit.gd").new();actor.unit_id="fit_diag";actor.armor_id="suit";actor.team_id="team_alpha"
	for i in range(4):
		var col=VBoxContainer.new();col.custom_minimum_size=Vector2(476,1080);columns.add_child(col)
		var label=Label.new();label.text=["Basis Körper R06","Basis Körper R07","Einsatz Körper R06","Einsatz Körper R07"][i];col.add_child(label)
		var host=SubViewportContainer.new();host.custom_minimum_size=Vector2(476,1020);host.stretch=true;col.add_child(host)
		var vp=SubViewport.new();vp.size=Vector2i(476,1020);vp.own_world_3d=true;host.add_child(vp)
		var stage=Node3D.new();vp.add_child(stage);stages.append(stage)
		var model:Node3D=load("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb").instantiate() if i<2 else view.call("_create_unit_proxy",actor)
		stage.add_child(model)
		if i<2:model.scale=Vector3.ONE*.4
		else:model.rotation_degrees.y=90
		for child in model.get_children():
			if child is MeshInstance3D and child.mesh is CylinderMesh:child.hide()
		for child in model.find_children("BlasterVisual_*","Node3D",true,false):child.hide()
		for ap:AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):ap.stop()
		var sk:Skeleton3D=model.find_children("*","Skeleton3D",true,false)[0];sk.reset_bone_poses()
		if i%2:ARMOR.apply_to_model(model,"suit")
		else:OLD.apply_to_model(model,"suit")
		for helmet:Node3D in model.find_children("HelmetVisual_*","Node3D",true,false):helmet.hide()
		models.append(model)
		var cam=Camera3D.new();stage.add_child(cam);cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=.94;cam.position=Vector3(0,.42,3);cam.look_at(Vector3(0,.42,0))
		var light=DirectionalLight3D.new();stage.add_child(light);light.rotation_degrees=Vector3(-35,-35,0);light.light_energy=1.2
		var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("17353e");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("e2e5ed");env.environment.ambient_light_energy=.65;stage.add_child(env)
		if i%2:
			var bones={}
			var up=(sk.get_bone_global_rest(sk.find_bone("Head")).origin-sk.get_bone_global_rest(sk.find_bone("Hips")).origin).normalized()
			var right=(sk.get_bone_global_rest(sk.find_bone("LeftArm")).origin-sk.get_bone_global_rest(sk.find_bone("RightArm")).origin).normalized()
			var front=right.cross(up).normalized()
			for pair in [["LeftArm","LeftForeArm"],["LeftForeArm","LeftHand"],["LeftUpLeg","LeftLeg"],["LeftLeg","LeftFoot"]]:
				var start=sk.get_bone_global_rest(sk.find_bone(pair[0])).origin;var end=sk.get_bone_global_rest(sk.find_bone(pair[1])).origin
				var axes=ARMOR._limb_axes((start-end).normalized(),front)
				var b=ARMOR._bone_bounds(model,sk,pair[0],axes)
				bones[pair[0]]={"body_bounds":str(b),"joint_mid_in_axes":str(axes.inverse()*((start+end)*.5)),"joint_length":start.distance_to(end)}
			for key in ["Chest","Spine","Hips"]:
				bones[key]={"body_bounds":str(ARMOR._bone_bounds(model,sk,key,Basis(right,up,front)))}
			data.append({"rig":"base" if i<2 else "mission","bones":bones})
	for phase in ["rest","idle","walk"]:
		for model:Node3D in models:
			if phase!="rest":
				for ap:AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):
					if ap.has_animation(phase):ap.play(phase);ap.advance(0 if phase=="idle" else .32);ap.pause()
		for j in range(5):await process_frame
		for j in range(5):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/native_glut_maps/armor_r07_body_compare_"+phase+".png")
	FileAccess.open("res://output/native_glut_maps/armor_r07_body_compare_bounds.json",FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
	view.free();actor.free();print("R07_BODY_COMPARE_CAPTURED");quit()
