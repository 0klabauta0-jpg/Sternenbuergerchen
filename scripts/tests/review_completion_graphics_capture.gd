extends SceneTree
## Comparable native evidence. Only camera/presentation and private fixtures change.
const START = preload("res://scripts/meta/game_start_contract.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const CANVAS = preload("res://scripts/ui/star_map_canvas.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
var passed := 0
var failed := 0
var output := ""
var manifest: Dictionary = {"resolution": [1280, 720], "renderer": "gl_compatibility", "images": []}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func frames(count: int = 8) -> void:
	for index in count: await process_frame

func capture(id: String, facts: Dictionary = {}) -> void:
	await frames(12)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image != null and image.get_size() == Vector2i(1280, 720), id + " native dimensions")
	check(image.save_png(output.path_join(id + ".png")) == OK, id + " written")
	manifest.images.append({"id": id, "facts": facts})

func run() -> void:
	output = OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
	if output.is_empty() or OS.get_environment("SB_REVIEW2_USER_DIR").is_empty() or DisplayServer.get_name() == "headless":
		printerr("Native graphics capture requires isolated review runner and its output directory")
		quit(2)
		return
	check(OS.get_user_data_dir().replace("\\", "/") == OS.get_environment("SB_REVIEW2_USER_DIR").replace("\\", "/"), "private profile")
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	START.request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	current_scene = flow
	await frames(24)
	var screen: Node = flow.get_node("HomebaseScreen")
	var presenter: Node = screen.get("_operations_presenter")
	presenter.call("_act", "navigate", {"mode": "base"})
	await frames()
	var base: Node = presenter.get("_base")
	var view: Node = base.get("_view")
	check(Vector2(presenter.get("_workspace").size).y > 250.0, "base workspace has visible world area")
	check(Vector2(base.get("_host").size).y > 250.0, "base 3D container has visible area")
	base.set("_manual_camera", true)
	for spec in [["home_overview", [68, 52], 34.0], ["home_buildings_pad", [68, 52], 18.0], ["home_rocks", [40, -28], 9.0]]:
		view.set("_camera_size", spec[2])
		view.set("_camera_yaw_degrees", 24.0)
		view.call("focus_world_position", base.call("_world_at_grid", spec[1]))
		view.call("_update_camera_transform")
		await capture(spec[0], {"grid_focus": spec[1], "camera_size": spec[2], "yaw": 24.0, "render": view.call("get_render_snapshot")})
	var operations: Dictionary = screen.call("get_operations_snapshot")
	var unit_id := String(operations.focused_unit.id)
	screen.call("request_operation", "details", {"unit_id": unit_id})
	await frames()
	var popup: Control = screen.get_node("CharacterSheetPopup")
	check(popup.is_visible_in_tree(), "actual personnel details open")
	var preview: Node = popup.find_child("PersonnelBodyPreview", true, false)
	check(preview != null and preview.get_meta("preview_uses_existing_model", false), "actual existing personnel model")
	await capture("personnel_details", {"unit_id": unit_id, "portrait_id": operations.focused_unit.get("portrait_id", "")})
	flow.queue_free()
	current_scene = null
	await frames()
	var travel := TRAVEL.new()
	check(travel.configure("capture_cutlass").get("ok", false), "actual travel owner configured")
	check(travel.apply_command({"contract_category": "singleplayer_space_travel", "operation": "launch_to_orbit", "payload": {"craft_id": "capture_cutlass"}, "request_id": "capture_launch"}, {"runtime_authorized": true}).get("ok", false), "actual travel owner launch")
	var canvas: Control = CANVAS.new()
	root.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.call("set_travel_snapshot", travel.get_snapshot())
	canvas.call("set_selected_ship", "capture_cutlass")
	canvas.call("set_location_snapshot", {"satellite_crash": {"available": true, "name": "Satellitenabsturz", "accepted_job": true}, "trade_outpost": {"available": true, "name": "Außenposten"}, "fortified_outpost": {"available": true, "name": "Befestigter Außenposten"}})
	await frames()
	canvas.call("reset_camera")
	await capture("starmap_overview", canvas.call("get_camera_snapshot"))
	var grid = load("res://scripts/core/strategic_hex_grid.gd")
	var point: Vector2 = canvas.call("map_to_screen", grid.pair(travel.get_snapshot().position))
	canvas.call("zoom_at", point, 4.0)
	await capture("starmap_close", canvas.call("get_camera_snapshot"))
	canvas.queue_free()
	await frames()
	var terrain = MAP.load_from_file("res://maps/Ground_Mission01_32x32.json")
	check(terrain != null, "actual GM01 terrain loaded")
	var terrain_view = VIEW.new()
	root.add_child(terrain_view)
	terrain_view.configure_from_map(terrain, Vector2(0, 768), 32.0)
	await capture("gm01_overview", terrain_view.get_render_snapshot())
	terrain_view.frame_world_positions([Vector2(0, 192), Vector2(512, 1152), Vector2(-512, 768)], 8.0, 26.0, 32.0)
	await capture("gm01_structures", terrain_view.get_render_snapshot())
	terrain_view.queue_free()
	await frames()
	var file := FileAccess.open(output.path_join("capture_manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	print("REVIEW_GRAPHICS_CAPTURE passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
