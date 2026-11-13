extends "res://scripts/tests/review_completion_maps_capture.gd"
## Diagnostic overrides only: actual C pad, identical GL camera in every image.
func run()->void:
	output=OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
	if output.is_empty() or OS.get_environment("SB_REVIEW2_USER_DIR").is_empty() or DisplayServer.get_name()=="headless":quit(2);return
	check(OS.get_user_data_dir().replace("\\","/")==OS.get_environment("SB_REVIEW2_USER_DIR").replace("\\","/"),"private profile")
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var terrain=MAP.load_from_file("res://maps/fortified_outpost.json")
	var spec:Dictionary=terrain.get_place_presentation().pads[0]
	var center:=Vector2(float(spec.center[0]),float(spec.center[1]))
	var view=VIEW.new();root.add_child(view)
	view.configure_from_map(terrain,terrain.get_marker_position("objective_point"),9.0);view.set_authoring_markers_visible(false)
	var axial:Vector2=preload("res://scripts/terrain/hex_grid.gd").plane_to_axial(center/float(view.call("_get_3d_cell_size")))
	view.focus_world_position(view.call("_grid_float_to_world",axial))
	await settle_map(view)
	var pad:Node3D=null
	for child in view.get("_place_dressing_root").get_children():
		if child.get_script()==preload("res://scripts/terrain/frontier_outpost_pad.gd"):pad=child;break
	check(pad!=null,"actual authored pad producer found")
	if pad==null:view.queue_free();await frames();quit(1);return
	var meshes:Array[MeshInstance3D]=[]
	_collect_meshes(pad,meshes)
	var original:Dictionary={}
	for mesh in meshes:original[mesh]=mesh.cast_shadow
	var inset:MeshInstance3D=pad.get_node_or_null("InsetDeck")
	check(inset!=null and not meshes.is_empty(),"actual inset and caster surfaces present")
	if inset==null:view.queue_free();await frames();quit(1);return
	await capture("pad_current",{"camera_size":9.0,"mode":"unaltered product","meshes":meshes.size(),"render":view.get_render_snapshot()})
	for mesh in meshes:mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.call("_request_viewport_redraw",true);await frames(4)
	await capture("pad_no_shadow",{"camera_size":9.0,"mode":"only pad casters OFF"})
	for mesh in meshes:mesh.cast_shadow=original[mesh]
	inset.visible=false;view.call("_request_viewport_redraw",true);await frames(4)
	await capture("pad_no_inset",{"camera_size":9.0,"mode":"only inset deck hidden; original casters"})
	for mesh in meshes:mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.call("_request_viewport_redraw",true);await frames(4)
	await capture("pad_no_shadow_no_inset",{"camera_size":9.0,"mode":"pad casters OFF and inset hidden"})
	view.queue_free();await frames()
	var file:=FileAccess.open(output.path_join("capture_manifest.json"),FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t"));file.close()
	print("REVIEW_PAD_DIAGNOSTIC passed=%d failed=%d"%[passed,failed]);quit(1 if failed else 0)

func _collect_meshes(node:Node,result:Array[MeshInstance3D])->void:
	if node is MeshInstance3D:result.append(node)
	for child in node.get_children():_collect_meshes(child,result)
