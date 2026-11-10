extends "res://scripts/tests/playtest_20261110_extraction_loop.gd"
func _prepare_visit_return(mission: Node) -> bool:
	var services: Control=_flow.get("_singleplayer_services")
	var path:=ProjectSettings.globalize_path("res://output/playtest_20261110/native-service"); DirAccess.make_dir_recursive_absolute(path)
	for resolution in [Vector2i(1280,720),Vector2i(3440,1440),Vector2i(1920,1080)]:
		root.size=resolution
		await create_timer(.3).timeout
		for frame in 12: await process_frame
		var bounds:=services.get_global_rect()
		var viewport:=services.get_viewport_rect()
		_check(bounds.position.x>=0 and bounds.position.y>=0 and bounds.end.x<=viewport.size.x and bounds.end.y<=viewport.size.y and bounds.position.y>=190,"actual service panel remains inside "+str(resolution))
		for id in ["mining_tool_supply","salvage_tool_supply"]:
			var button: Button=services.find_child(id,true,false)
			_check(button!=null and button.is_visible_in_tree() and not button.disabled,"actual tool offer is usable "+id+" "+str(resolution))
		root.get_texture().get_image().save_png(path+"/trade_%dx%d.png" % [resolution.x,resolution.y])
	return await super._prepare_visit_return(mission)
