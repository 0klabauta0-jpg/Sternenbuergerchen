extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
var view: Node
var base_view: Node
func _init() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	print("CAPTURE ", name, " ", root.get_texture().get_image().save_png("res://output/home_visual_final_20261112/" + name + ".png"))
func focus(grid: Array, size_value: float) -> void:
	view.set("_camera_size", size_value)
	view.call("focus_world_position",base_view.call("_world_at_grid",grid))
	view.call("_update_camera_transform")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/home_visual_final_20261112"))
	root.size = Vector2i(1280,720)
	START.request_start(self,"campaign","new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	for i in range(5): await process_frame
	var presenter: Node = flow.get_node("HomebaseScreen").get("_operations_presenter")
	presenter.call("_act", "navigate", {"mode":"base"})
	for i in range(5): await process_frame
	base_view = presenter.get("_base"); view = base_view.get("_view")
	base_view.set("_manual_camera", true)
	focus([68,52],34.0)
	await capture("01_overview_after")
	focus([68,52],18.0)
	await capture("02_pad_after")
	focus([40,-28],9.0)
	await capture("03_rocks_after")
	print('PATH_CAPTURE_COMPLETE')
	flow.queue_free(); await process_frame
	quit()
