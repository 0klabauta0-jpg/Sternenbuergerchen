extends SceneTree
## Offscreen native render. Historical models are used only for the comparison.
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
var stage: Node3D
var camera: Camera3D
func _init() -> void: call_deferred("_run")
func _capture(path: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(path)
	print("CAPTURE ",path," error=",error)
func _clear() -> void:
	for child in stage.get_children(): child.free()
func _run() -> void:
	root.size = Vector2i(960,640)
	var world := Node3D.new(); root.add_child(world)
	stage = Node3D.new(); world.add_child(stage)
	var environment := WorldEnvironment.new(); environment.environment = Environment.new(); world.add_child(environment)
	var profile := PROFILE.new(); profile.apply_environment(environment.environment)
	environment.environment.background_mode = Environment.BG_COLOR
	var light := DirectionalLight3D.new(); world.add_child(light); profile.apply_light(light)
	light.shadow_enabled = true
	camera = Camera3D.new(); world.add_child(camera); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 8.5
	camera.position = Vector3(6,6,9); camera.look_at(Vector3.ZERO)
	var ground := MeshInstance3D.new(); var plane := PlaneMesh.new(); plane.size=Vector2(30,30); ground.mesh=plane
	ground.position.y=-.025; ground.material_override=profile.surface_material_for("ground"); world.add_child(ground)
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/qa/map_save_building_migration_20261110/old_building_bounds.json"))
	var i := 0
	for id in ["factory_building_a","factory_building_d"]:
		var model: Node3D=load(String(old[id].path)).instantiate(); stage.add_child(model)
		model.scale=Vector3.ONE*float(old[id].scale)*.85; model.position.x=-2.5+5.0*i; i+=1
	await _capture("res://docs/qa/map_save_building_migration_20261110/buildings_before.png")
	_clear(); i=0
	for id in ["habitat","hall"]:
		var model: Node3D=load("res://scenes/terrain/frontier_%s_exterior.tscn"%id).instantiate(); stage.add_child(model)
		model.scale=Vector3.ONE*.85; model.position.x=-2.5+5.0*i; i+=1
	await _capture("res://docs/qa/map_save_building_migration_20261110/buildings_after.png")
	var output := "res://Assets/curated/frontier_illustrated_20261101/building_previews/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(384,384)
	for id in ["habitat","hall"]:
		_clear(); var model: Node3D=load("res://scenes/terrain/frontier_%s_exterior.tscn"%id).instantiate(); stage.add_child(model)
		camera.size=5.7; await _capture(output+id+".png")
	quit()
