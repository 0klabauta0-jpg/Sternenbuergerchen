extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	for i in range(12): await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	screen.call("request_operation", "navigate", {"mode":"base"})
	for i in range(20): await process_frame
	var base: Node = screen.get("_operations_presenter").get("_base")
	var dock: Control = base.get("_person_panel")
	var badges: HBoxContainer = base.get("_person_badges")
	print("DOCK_RECT=",dock.get_global_rect()," VIEWPORT=",root.get_visible_rect()," BADGES=",badges.get_child_count())
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	print("DOCK_CAPTURE=", image.save_png("res://output/modular_native/full_dock.png"))
	flow.queue_free(); await process_frame; quit()
