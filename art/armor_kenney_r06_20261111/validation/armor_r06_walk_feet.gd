extends SceneTree
const ARMOR=preload("res://output/native_glut_maps/personnel_armor_visual_r06.gd")
const VIEW=preload("res://scripts/terrain/terrain_map_3d_view.gd")
var models:Array[Node3D]=[]
func _init():call_deferred("run")
func run():
	root.size=Vector2i(1920,1080)
	var grid=GridContainer.new();grid.columns=3;root.add_child(grid)
	var view=VIEW.new();var actor=load("res://scripts/npc/test_unit.gd").new();actor.armor_id="suit";actor.unit_id="r06_walk_foot";actor.team_id="team_alpha"
	for index in range(6):
		var col=VBoxContainer.new();col.custom_minimum_size=Vector2(632,532);grid.add_child(col)
		var label=Label.new();label.text=("Basis " if index<3 else "Einsatz ")+["leicht","mittel","schwer"][index%3];label.add_theme_font_size_override("font_size",22);col.add_child(label)
		var host=SubViewportContainer.new();host.custom_minimum_size=Vector2(632,494);host.stretch=true;col.add_child(host)
		var vp=SubViewport.new();vp.size=Vector2i(632,494);vp.own_world_3d=true;host.add_child(vp)
		var stage=Node3D.new();vp.add_child(stage)
		var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("17353e");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("e2e5ed");env.environment.ambient_light_energy=.65;stage.add_child(env)
		var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-35,0);light.light_energy=1.2;stage.add_child(light)
		var model:Node3D=load("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb").instantiate() if index<3 else view.call("_create_unit_proxy",actor)
		stage.add_child(model)
		if index<3:model.scale=Vector3.ONE*.4
		else:model.rotation.y=PI*.5
		for child in model.get_children():
			if child is MeshInstance3D and child.mesh is CylinderMesh:child.hide()
		for weapon:Node3D in model.find_children("BlasterVisual_*","Node3D",true,false):weapon.hide()
		ARMOR.apply_to_model(model,["light","medium","heavy"][index%3]);models.append(model)
		var camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.34;camera.position=Vector3(.16,.22,1);camera.look_at(Vector3(0,.10,0))
	for phase in [.15,.42,.70]:
		for model in models:
			for player:AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):
				for clip in player.get_animation_list():
					if String(clip).to_lower()=="walk":
						player.stop();player.play(clip);player.advance(phase);player.pause();print("WALK_FEET ",clip," phase ",phase);break
		for i in range(6):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/native_glut_maps/armor_r06_walk_only_feet_%03d.png"%int(phase*100))
	view.free();actor.free();grid.queue_free();await process_frame
	print("R06_WALK_FEET 6 actual actors x 3 real clip phases CAPTURED")
	quit()
