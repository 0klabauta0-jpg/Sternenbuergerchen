extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var flow: Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	var screen: Node=flow.get_node("HomebaseScreen")
	flow.get("_campaign_tutorial").call("hide_hints")
	var path:=ProjectSettings.globalize_path("res://output/playtest_20261110/native-layout")
	DirAccess.make_dir_recursive_absolute(path)
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(3440,1440)]:
		root.size=resolution
		for frame in range(8): await process_frame
		for mode in ["personnel","squad","mission","map","base"]:
			screen.call("request_operation","navigate",{"mode":mode})
			for frame in range(12): await process_frame
			var image:=root.get_texture().get_image()
			image.save_png(path+"/%s_%dx%d.png" % [mode,resolution.x,resolution.y])
			print("NATIVE_LAYOUT ",mode," ",resolution," actual=",image.get_size())
	flow.queue_free(); await process_frame; quit()
