extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
const GEOMETRY = preload("res://scripts/meta/modular_base_geometry.gd")
func _init() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	print("CAPTURE ", path, " result=", image.save_png(path))
func run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/modular_native"))
	START.request_start(self,"campaign","new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	for i in range(5): await process_frame
	var adapter: Node = flow.get("_singleplayer_runtime")
	adapter._supply._credits = 1200 # isolated screenshot fixture
	var ops: Node = flow.get_node("HomebaseScreen").get("_operations_presenter")
	ops.call("_act", "navigate", {"mode":"base"})
	for i in range(5): await process_frame
	var base_view: Node = ops.get("_base")
	var view: Node = base_view.get("_view")
	base_view.set("_manual_camera", true)
	view.set("_camera_size", 10.0)
	view.call("focus_world_position",base_view.call("_world_at_grid", [32,28]))
	view.call("_update_camera_transform")
	await capture("res://output/modular_native/original_beds.png")
	view.set("_camera_size", 16.0)
	var grid: Vector2i = GEOMETRY.plane_grid(Vector2(18,36))
	view.call("focus_world_position",base_view.call("_world_at_grid", [grid.x,grid.y]))
	view.call("_update_camera_transform")
	ops.call("_open_base_management", "build")
	for i in range(8): await process_frame
	var services: Node = ops.get("_services_view")
	services.call("refresh", adapter.get_snapshot())
	var builder: Node = services.get("_modular_builder")
	builder.get_node("BuildModularRoom").pressed.emit()
	services.call("refresh", adapter.get_snapshot())
	var room: OptionButton = builder.get("_room")
	if room.item_count<2: print("CAPTURE_FAIL sleeping room ",builder.get("_status").text); quit(1);return
	room.select(1)
	builder.get_node("BuildRoomBed").pressed.emit()
	var plan: Dictionary = adapter._supply.get_supply_snapshot().modular_base
	if plan.beds.size()!=1: print("CAPTURE_FAIL bed ",builder.get("_status").text); quit(1);return
	await capture("res://output/modular_native/build_ui.png")
	var type_selector: OptionButton = builder.get("_type")
	type_selector.select(1)
	var x: SpinBox = builder.get("_x"); x.value=1
	builder.get_node("BuildModularRoom").pressed.emit()
	plan = adapter._supply.get_supply_snapshot().modular_base
	if plan.rooms.size()!=2: print("CAPTURE_FAIL adjacent ",builder.get("_status").text); quit(1);return
	ops.call("_close_workspace_flyout")
	for i in range(8): await process_frame
	await capture("res://output/modular_native/connected_rooms.png")
	view.set("_camera_size", 10.0)
	var bed_grid: Vector2i = GEOMETRY.plane_grid(Vector2(14.15,36.4))
	view.call("focus_world_position",base_view.call("_world_at_grid", [bed_grid.x,bed_grid.y]))
	view.call("_update_camera_transform")
	await capture("res://output/modular_native/modular_bed.png")
	print("MODULAR_NATIVE_CAPTURE_PASS")
	flow.queue_free(); await process_frame; quit(0)
