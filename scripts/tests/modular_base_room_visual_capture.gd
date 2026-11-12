extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
const GEOMETRY = preload("res://scripts/meta/modular_base_geometry.gd")
const OUTPUT := "res://output/modular_hex_native/"
func _init() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	print("CAPTURE ", name, " ", root.get_texture().get_image().save_png(OUTPUT + name + ".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for rotation in range(2):
		if not await capture_rotation(rotation): quit(1); return
	print("MODULAR_ROOM_VISUAL_CAPTURE_PASS actual actor sleeping/waking; room rotations 0/1; three modules; two separately bought original beds")
	quit(0)
func capture_rotation(rotation: int) -> bool:
	root.size = Vector2i(1280, 720)
	START.request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	for i in range(5): await process_frame
	var adapter: Node = flow.get("_singleplayer_runtime")
	adapter._supply._credits = 2000 # Isolated capture fixture only.
	var rooms: Array = [
		{"request_id":"visual-sleep", "type":"sleep", "x":0, "y":0, "rotation":rotation},
		{"request_id":"visual-hall", "type":"corridor", "x":1, "y":0, "rotation":0},
		{"request_id":"visual-store", "type":"storage", "x":2, "y":0, "rotation":0},
	]
	for room: Dictionary in rooms:
		var result: Dictionary = adapter.request_operation("campaign_build_room", room)
		if not result.get("ok", false): print("CAPTURE_FAIL ", result); return false
	var plan: Dictionary = adapter._supply.get_supply_snapshot().modular_base
	var room_id := String(plan.rooms[0].id)
	for slot in range(2):
		var result: Dictionary = adapter.request_operation("campaign_place_room_bed", {"room_id":room_id, "slot":slot, "request_id":"visual-bed-%d" % slot})
		if not result.get("ok", false): print("CAPTURE_FAIL ", result); return false
	plan = adapter._supply.get_supply_snapshot().modular_base
	var base: Node = adapter.get_base_personnel_runtime()
	var sleep: Dictionary = base.request_operation("base_sleep", {"unit_id":"campaign_leader", "bed_id":plan.beds[0].id})
	if not sleep.get("ok", false): print("CAPTURE_FAIL ", sleep); return false
	var sim: Node = base.get_simulation_root()
	sim.set_physics_process(false)
	for i in range(6000):
		sim.call("_physics_process", 0.05)
		if base.get_snapshot().units[0].status == "sleeping": break
	if base.get_snapshot().units[0].status != "sleeping": print("CAPTURE_FAIL no actual arrival"); return false
	var ops: Node = flow.get_node("HomebaseScreen").get("_operations_presenter")
	ops.call("_act", "navigate", {"mode":"base"})
	for i in range(8): await process_frame
	var base_view: Node = ops.get("_base")
	var view: Node = base_view.get("_view")
	base_view.set("_manual_camera", true)
	base_view.get_node("ExplorationHelp").hide()
	view.set("_camera_size", 21.0)
	var center := GEOMETRY.center(rooms[1])
	var grid := GEOMETRY.plane_grid(center)
	view.call("focus_world_position", base_view.call("_world_at_grid", [grid.x, grid.y]))
	view.call("_update_camera_transform")
	if rotation == 0: await capture("three_modules_front_posefix")
	view.set("_camera_yaw_degrees", 204.0)
	view.call("_update_camera_transform")
	if rotation == 0: await capture("three_modules_rear_posefix")
	view.set("_camera_size", 8.0)
	view.set("_camera_yaw_degrees", 24.0)
	grid = GEOMETRY.plane_grid(GEOMETRY.center(rooms[0]))
	view.call("focus_world_position", base_view.call("_world_at_grid", [grid.x, grid.y]))
	view.call("_update_camera_transform")
	await capture("sleeping_original_beds_r%d_posefix" % rotation)
	var wake: Dictionary = base.request_operation("base_wake", {"unit_id":"campaign_leader"})
	if not wake.get("ok", false): print("CAPTURE_FAIL ", wake); return false
	await capture("awake_original_beds_r%d_posefix" % rotation)
	var model: Node3D = base_view.get("_person_visuals")["campaign_leader"].model
	if not is_zero_approx(model.rotation.x) or not is_zero_approx(model.rotation.z): print("CAPTURE_FAIL wake tilt ", model.rotation); return false
	print("POSE_CAPTURE rotation=", rotation, " sleeping then waking; awake tilt=", model.rotation.x, "/", model.rotation.z)
	if rotation == 0:
		var added: Dictionary = adapter.request_operation("campaign_set_room_door", {"request_id":"visual-add-door", "room_id":room_id, "side":2, "open":true})
		if not added.get("ok", false): print("CAPTURE_FAIL add door ", added); return false
		await capture("door_added_r0")
		var removed: Dictionary = adapter.request_operation("campaign_set_room_door", {"request_id":"visual-remove-door", "room_id":room_id, "side":2, "open":false})
		if not removed.get("ok", false): print("CAPTURE_FAIL remove door ", removed); return false
		await capture("door_removed_r0")
	flow.queue_free(); await process_frame
	return true
