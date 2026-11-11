extends SceneTree
const ARMOR = preload("res://scripts/terrain/personnel_armor_visual.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
var cameras: Array[Camera3D] = []
func _init() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	var columns := HBoxContainer.new()
	root.add_child(columns)
	var view := VIEW.new()
	var actor = load("res://scripts/npc/test_unit.gd").new()
	actor.armor_id = "suit"
	actor.unit_id = "helmet_compare"
	actor.team_id = "team_alpha"
	for index in range(3):
		var column := VBoxContainer.new()
		column.custom_minimum_size = Vector2(632,1080)
		columns.add_child(column)
		var label := Label.new()
		label.text = ["Leicht · ORC reduziert", "Mittel · ORC verstärkt", "Schwer · Morozov-Richtung"][index]
		label.add_theme_font_size_override("font_size",24)
		column.add_child(label)
		var host := SubViewportContainer.new()
		host.custom_minimum_size = Vector2(632,1020)
		host.stretch = true
		column.add_child(host)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(632,1020)
		viewport.own_world_3d = true
		host.add_child(viewport)
		var stage := Node3D.new()
		viewport.add_child(stage)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color("17353e")
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color("e2e5ed")
		environment.environment.ambient_light_energy = .65
		stage.add_child(environment)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-35,-35,0)
		light.light_energy = 1.2
		stage.add_child(light)
		var model: Node3D = view.call("_create_unit_proxy",actor)
		stage.add_child(model)
		model.rotation_degrees.y = 90
		# Modeling comparison: hide only fixture weapon/base, not armor geometry.
		for child in model.get_children():
			if child is MeshInstance3D and child.mesh is CylinderMesh: child.hide()
		for weapon:Node3D in model.find_children("BlasterVisual_*","Node3D",true,false):weapon.hide()
		var result := ARMOR.apply_to_model(model, ["light", "medium", "heavy"][index])
		if not result.ok: push_error(str(result));quit(1);return
		for player: AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):
			if player.has_animation("idle"):
				player.play("idle");player.advance(0);player.pause()
		var camera := Camera3D.new()
		stage.add_child(camera)
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = .90
		camera.position = Vector3(0,.42,3)
		camera.look_at(Vector3(0,.42,0))
		cameras.append(camera)
	for index in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/native_glut_maps/armor_r06_production.png")
	for camera in cameras:
		camera.position = Vector3(2,.70,3)
		camera.look_at(Vector3(0,.42,0))
	for index in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/native_glut_maps/armor_r06_production_quarter.png")
	for entry in [["side",Vector3(3,.42,0)],["rear",Vector3(0,.42,-3)],["top",Vector3(0,3,0)]]:
		for camera in cameras:
			camera.position=entry[1]
			camera.look_at(Vector3(0,.42,0),Vector3.FORWARD if entry[0]=="top" else Vector3.UP)
		for index in range(8):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/native_glut_maps/armor_r06_production_"+String(entry[0])+".png")
	view.free();actor.free();columns.queue_free()
	await process_frame
	print("ARMOR_HELMET_COMPARISON 3 models 5 views PASS")
	quit()
