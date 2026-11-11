extends SceneTree
const ARMOR = preload("res://scripts/terrain/personnel_armor_visual.gd")
func _init() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1920,960)
	root.content_scale_size=Vector2i(1920,960)
	var columns:=HBoxContainer.new()
	root.add_child(columns)
	var black:=StandardMaterial3D.new()
	black.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color=Color("17232d")
	for index in range(3):
		var col:=VBoxContainer.new()
		col.custom_minimum_size=Vector2(632,960)
		columns.add_child(col)
		var label:=Label.new()
		label.text=["Leicht · ORC reduziert", "Mittel · ORC verstärkt", "Schwer · Morozov-Richtung"][index]
		label.add_theme_font_size_override("font_size",24)
		col.add_child(label)
		var host:=SubViewportContainer.new()
		host.custom_minimum_size=Vector2(632,910)
		host.stretch=true
		col.add_child(host)
		var viewport:=SubViewport.new()
		viewport.size=Vector2i(632,910)
		viewport.own_world_3d=true
		host.add_child(viewport)
		var world:=Node3D.new()
		viewport.add_child(world)
		var env:=WorldEnvironment.new()
		env.environment=Environment.new()
		env.environment.background_mode=Environment.BG_COLOR
		env.environment.background_color=Color("eef0ee")
		world.add_child(env)
		var model:=load("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb").instantiate() as Node3D
		model.scale=Vector3.ONE*.4
		world.add_child(model)
		var result:=ARMOR.apply_to_model(model,["light","medium","heavy"][index])
		if not result.ok: push_error(str(result));quit(1);return
		for player:AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):
			for clip in player.get_animation_list():
				if "idle" in String(clip).to_lower():
					player.play(clip);player.advance(0);player.pause();break
		for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			mesh.material_override=black
		var camera:=Camera3D.new()
		world.add_child(camera)
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL
		camera.size=.95
		camera.position=Vector3(0,.40,3)
		camera.look_at(Vector3(0,.40,0))
	for index in range(8):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/native_glut_maps/armor_three_classes_silhouette.png")
	columns.queue_free()
	await process_frame
	print("ARMOR_SILHOUETTE 3 models PASS")
	quit()
