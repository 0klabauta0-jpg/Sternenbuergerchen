extends SceneTree
const PREVIEW = preload("res://scenes/tests/frontier_art_preview.tscn")
var preview
var view
func _initialize() -> void:call_deferred("run")
func capture(id: String) -> void:
	view.call("_request_viewport_redraw",true,60000)
	for i in range(12):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/grafik_20261101/pass07_artifact_"+id+".png")
func run() -> void:
	preview=PREVIEW.instantiate()
	root.add_child(preview)
	view=preview.get("_view")
	preview.get("_sim").set_physics_process(false)
	view.set_process(false)
	view.get_node("ViewportContainer/SubViewport").render_target_update_mode=SubViewport.UPDATE_ALWAYS
	for entry in preview.get("_crew"):
		if entry["player"]:entry["player"].pause()
	preview.call("_set_buildings_closed",false)
	preview.call("_camera_view","crew")
	var dressing: Node3D=preview.get("_stage").get_node("FrontierWorkingGround")
	var paint: Node3D=preview.get("_worklife").get_node("DustBanksAndCompactedApproaches")
	await capture("baseline")
	paint.hide()
	await capture("no_contact_paint")
	paint.show()
	var meshes: Array=dressing.find_children("*","MeshInstance3D",true,false)
	var shadows: Array=[]
	for mesh in meshes:
		shadows.append(mesh.cast_shadow)
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	await capture("no_dressing_shadows")
	for i in range(meshes.size()):meshes[i].cast_shadow=shadows[i]
	dressing.hide()
	await capture("no_dressing")
	dressing.show()
	var subworld: Node3D=view.get_node("ViewportContainer/SubViewport/WorldRoot")
	var lights: Array=subworld.find_children("*","DirectionalLight3D",true,false)
	for light in lights:light.shadow_enabled=false
	await capture("no_global_shadows")
	preview.free()
	await process_frame
	quit()
